# Recovery Strategy

What is backed up, where the copies live, and how to restore each app.

Nodes are disposable by design: reprovisioning is
`./scripts/provision-node.sh <cluster> <node-ip>` (see [talos.md](talos.md)),
after which Flux reconciles every manifest. **Only data needs restoring** —
everything else in this repo rebuilds itself.

## Backup tiers

| Tier | Where | What | Retention |
|---|---|---|---|
| Warm | RustFS on karma, bucket `cnpg-backups` | Teable base backups + WAL mirrored from e2 every 5min | 30d |
| Cold | offsite S3, bucket `cnpg-backups` | Postgres base backups + WAL | 30d |
| Cold | offsite S3, bucket `offsite-objects` | RustFS objects (Teable attachments) | 30d of noncurrent versions |

Teable uses one CloudNativePG barman-cloud plugin targeting `offsite-store`:
base backups run daily at 04:10 UTC and WAL archiving uses PostgreSQL's
`archive_timeout=5min`. The upload takes additional time; idle segments with
no writes do not rotate just to meet that interval.

`apps/karma/postgres-mirror/` mirrors only `cnpg-backups/teable-db` from e2 to
RustFS every five minutes. It copies payloads before Barman catalogs, checks
the result, then writes `cnpg-backups/teable-db/_last-mirror`. A concurrent
backup can fail the check and be completed by a retry. The RustFS writer is
scoped to that prefix; the e2 credentials are shared with the Barman writer
and scoped to the `cnpg-backups` bucket. The mirror only reads e2.
The source declares SSE-KMS because its ETags are not plaintext MD5 hashes;
RustFS uploads use multipart checksums. The final check compares sizes when
no common hash is available, not a full byte-for-byte download verification.

Both copies support **point-in-time recovery** within the available WAL
window. Karma can lag e2 by five minutes plus the mirror duration; interrupted
runs extend that delay. Confirm a recent successful mirror and the selected
backup's files before recovery. The first synchronization transfers the
existing backup history; subsequent runs transfer changed objects only.

Barman manages the 30-day retention on e2; the mirror propagates expiry to
Karma. The `cnpg-backups` buckets are **not** versioned and carry no lifecycle
rules or Object Lock, so neither copy is immutable.

`offsite-objects` is the inverse: versioning on, lifecycle expiring noncurrent
versions after 30d, written by a nightly `rclone sync`. Versioning is what
makes sync-propagated deletions recoverable.

Both offsite S3 keys are scoped to a single bucket and verified unable to read
the other.

## Coverage per app

| App | State | Backed up | Gap |
|---|---|---|---|
| **teable** | CNPG `teable-db`; attachments in RustFS `attachments-public`/`attachments-private`; Redis PVC (cache) | DB: e2 daily + WAL, mirrored to Karma every 5min. Attachments: cold nightly | Redis is a disposable cache; Karma DB mirror depends on e2 |
| **nocodb** | CNPG `nocodb-db`; `nocodb-data-pvc` (5Gi) | DB: warm + cold; suspended while stopped | **PVC not backed up** — attachments live on local disk, not S3. Stopped: app at 0 replicas, DB hibernated, backups suspended (`apps/rammus/nocodb/kustomization.yaml` patches); remove the patches to restart |
| **linkding** | `linkding-data-pvc` (1Gi, SQLite) | nothing | **No backup** |
| **audiobookshelf** | config + metadata PVCs (500Mi each), audiobooks + podcasts PVCs (50Gi each) | nothing | **No backup**; media is reacquirable, config/metadata is not |
| **soft-serve** | `repos` PVC (10Gi, Gopass store) | nothing | **No backup** — planned in `openspec/changes/backup-strategy`, never implemented. Mitigated only by every clone being a full copy |
| **litellm** | CNPG `litellm-db` (keys, users, prompt and response logs) | nothing | **No backup**, decision postponed in `contracts/litellm-db-backup.md`: node loss loses every log and spend counter; `provision` recreates users and keys |
| **rustfs** | `rustfs-data-pvc` (220Gi) — the object tier itself | Teable buckets only, cold | `cnpg-backups` bucket is a backup target, not backed up further (the offsite copy is the second copy) |

## Restoring Postgres

Recovery bootstraps a **new** cluster from an object store; it never writes
back into an existing one. Replace `teable`/`teable-db` as needed, and pick
`offsite-store` or `rustfs-store` as the source.

Scale the app to zero first so nothing writes during recovery:

```bash
kubectl scale deployment/teable -n teable --replicas=0
```

Delete the existing `Cluster` if it is present but corrupt, then apply:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: teable-db
  namespace: teable
spec:
  instances: 1
  storage:
    size: 5Gi
  bootstrap:
    recovery:
      source: recovery-source
      # Omit recoveryTarget to recover to the end of the WAL stream.
      # For PITR, or to match the attachment mirror, set a target time:
      # recoveryTarget:
      #   targetTime: "2026-07-28 22:54:04+00"
  externalClusters:
    - name: recovery-source
      plugin:
        name: barman-cloud.cloudnative-pg.io
        parameters:
          barmanObjectName: offsite-store
          serverName: teable-db
  plugins:
    - name: barman-cloud.cloudnative-pg.io
      isWALArchiver: true
      parameters:
        barmanObjectName: offsite-store
```

`serverName` must match the original cluster name — it is the directory
inside `destinationPath`, not the name of the new cluster.

Watch it come up, then scale the app back:

```bash
kubectl get cluster -n teable -w
kubectl scale deployment/teable -n teable --replicas=1
```

Once healthy, restore the manifest in git to its normal (non-recovery) form
so Flux does not fight the bootstrapped cluster.

## Restoring RustFS objects

The offsite layout mirrors bucket names 1:1, so restore is the backup command
with the arguments swapped. Run it from the sync CronJob's own image and
credentials:

```bash
kubectl create job --from=cronjob/offsite-sync restore-shell -n rustfs
```

Or run `rclone` directly with the same env (see
`apps/karma/offsite-sync/sync-cronjob.yaml`):

```bash
rclone sync dst:offsite-objects/attachments-private src:attachments-private
```

**Note:** the sync user is deliberately read-only on RustFS. Restores need
write access, so use the RustFS root credentials
(`apps/karma/rustfs/rustfs-credentials.sops.yaml`) for the destination.

### Point-in-time restore

`offsite-objects` is versioned, so any state within the 30d window is reachable:

```bash
rclone sync --s3-version-at 2026-07-20T05:20:00Z dst:offsite-objects/attachments-private src:attachments-private
```

### Keeping the database and attachments coherent

WAL archiving is continuous but attachment sync is nightly, so a plain
restore of both can leave up to 24h of rows referencing attachments that were
never mirrored.

The sync job writes `s3://offsite-objects/_last-sync` containing the UTC timestamp
of the run's **start**, which is the newest instant the mirror is guaranteed
to cover:

```bash
rclone cat dst:offsite-objects/_last-sync
```

Use that value as the Postgres `recoveryTarget.targetTime`. The database then
never references an attachment the object store lacks.

If instead you want the newest possible data and can tolerate a few broken
attachment links, recover Postgres to the end of the WAL stream and accept
the discrepancy.

## Full cluster loss

1. Reprovision the node: `./scripts/provision-node.sh rammus <ip>`
2. Wait for Flux to reconcile; apps come up empty
3. Restore Postgres per app (above), using `offsite-store` if karma is also gone
4. Restore objects (above) — required only if karma's RustFS PVC was lost
5. Scale apps back up

If **karma** is lost, RustFS buckets are recreated declaratively by
`apps/karma/rustfs/provision-job.yaml` (buckets, policies, CORS, IAM users),
and `apps/karma/offsite-sync/bucket-config-job.yaml` reasserts the offsite
bucket's versioning and lifecycle. Only object *contents* need restoring.

## Secrets

Every secret in this repo is SOPS-encrypted to a single age key, held in
gopass behind a TPM plugin (`bg/age/homelab/age1s4h...`).

**Without that key nothing above is recoverable** — not the database
credentials, not the object store keys. It is the single point of failure for
the entire recovery strategy and warrants an offline copy stored separately
from the machine holding the TPM. Listing the gopass entry and successfully
using it to decrypt SOPS verifies access, not the existence of an independent
offline recovery copy.

Operator-generated Secrets, such as Prometheus's scrape configuration, are
recreated from declarative resources rather than restored from gopass. A stale
pod-mounted copy does not mean the API Secret or its credentials were lost.
Grafana credentials are SOPS-encrypted in Git; compare decrypted and live values
in memory without logging them. Follow the [monitoring recovery procedure](monitoring.md#secrets-and-safe-recovery)
to refresh a stale configuration without deleting credential Secrets.

## Known gaps

- **Soft Serve, linkding, audiobookshelf, nocodb's PVC have no backup.**
  Local-path PVCs on a single-node cluster: node loss means data loss.
- **`DeleteObjectVersion` is permitted** on `offsite-objects`. Accidental deletions
  are still fully recoverable (`rclone sync` only issues plain deletes, which
  create delete markers), but a holder of the key could purge version history
  deliberately. offsite S3 scoping is bucket-level, and a scoped key cannot set
  a bucket policy on itself; closing this needs console/root action.
- **Attachment RPO is 24h**; PostgreSQL e2 lag is up to 5min plus upload time
  while archiving is healthy. The Karma mirror adds up to 5min plus transfer time.
- **Karma's Teable database copy depends on e2** for new backups and WAL.
- **No backup freshness notification is configured.** Check Barman status and
  `teable-postgres-mirror` jobs until external alerting is implemented.
