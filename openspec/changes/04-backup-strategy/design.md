## Context

Soft Serve data resides on `rammus`. The backup target, RustFS, is deployed on `karma`. We need offsite backups to idrive e2 to fulfill the 3-2-1 backup rule.

## Goals / Non-Goals

**Goals:**
- Establish a 3-2-1 backup strategy with warm (RustFS) and cold (idrive e2) targets
- Implement per-app schedules and retentions

## Decisions

### 1. Dual Backup Strategy (RustFS + idrive e2)
**Decision:** Implement warm sync to RustFS (15-min CronJob on the apps cluster) and a per-app cold backup to idrive e2 (6-hour CronJob on the RustFS cluster) with rustic-managed retention.
**Rationale:** RustFS provides fast recovery for recent data. A per-app cold backup running directly on the RustFS cluster reads the synced data and pushes it to idrive e2, minimizing network load on the main apps cluster and allowing app-specific retention schedules. Together they satisfy a 3-2-1 backup strategy (3 copies, 2 media types, 1 offsite) with managed snapshot lifecycle.
**Alternatives considered:** Single backup target (insufficient redundancy), Whole-drive cold backup (inflexible schedules and recovery).

### 2. Custom Backup Image
**Decision:** Build a custom Docker image (`ghcr.io/nimser/homelab-backup-tools`) containing rclone and rustic.
**Rationale:** Neither rclone nor rustic are available in the base images. A shared backup image avoids duplicating tooling across CronJobs and allows Renovate to manage version bumps via image tag.

### 3. rclone Transport: SFTP/SSH
**Decision:** The warm sync from `rammus` to `karma` will use `rclone` over the SFTP protocol, requiring an SSH server on the RustFS node/pod.
**Rationale:** SFTP provides encrypted transit out-of-the-box and integrates securely with existing SSH key pairs, avoiding the need for an unauthenticated WebDAV or NFS share across the local network.

### 4. RustFS Directory Structure
**Decision:** Data on the RustFS backend will be organized by source cluster, e.g., `/mnt/rustfs/rammus/soft-serve`.
**Rationale:** As the homelab grows, this prevents naming collisions if multiple clusters run applications with the same name.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Concurrent PVC access between Soft Serve and backup CronJobs | `local-path` supports concurrent readers; CronJobs on `rammus` mount PVC `readOnly: true` with `concurrencyPolicy: Forbid` |
| Backup image build is manual | Document build process in README; Renovate monitors and bumps tags automatically |
