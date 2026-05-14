## Why

Data needs to be protected with a robust 3-2-1 backup strategy. Soft Serve data is currently only on `local-path` storage on the `rammus` cluster.

## What Changes

- Implement automated warm backup to RustFS via rclone CronJob on `rammus` (15-minute sync)
- Implement automated per-app cold backup to idrive e2 via rustic CronJob on `karma` (6-hour archive with rustic-managed retention)
- Add SOPS-encrypted secret management for backup credentials
- Introduce custom backup tools container image (`ghcr.io/nimser/homelab-backup-tools`)

## Capabilities

### New Capabilities

- `backup-strategy`: 3-2-1 backup implementation with warm RustFS sync and cold idrive e2 archival via CronJobs, and rustic-managed snapshot retention

### Modified Capabilities

<!-- No existing capabilities modified -->

## Impact

- **New backup component (rammus)**: rclone CronJob in `apps/base/soft-serve` syncing to RustFS
- **New backup component (karma)**: Soft Serve specific rustic Cold Backup CronJob deployed to the RustFS cluster
- **New container image**: `images/backup-tools/Dockerfile` for backup tooling
- **New SOPS secrets**: backup configs, idrive e2 credentials
