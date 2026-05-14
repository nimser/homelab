## ADDED Requirements

### Requirement: Warm Backup to RustFS
The system SHALL run a Kubernetes CronJob that executes `rclone sync` from the Soft Serve repos PVC to a RustFS backend via SFTP (`karma:rammus/soft-serve`) every 15 minutes.

#### Scenario: Warm backup runs on schedule
- **WHEN** 15 minutes elapse since the last run
- **THEN** the CronJob starts and executes `rclone sync` via SFTP to the RustFS backend into a cluster-specific directory (`rammus/soft-serve`)

#### Scenario: Backup uses read-only PVC access
- **WHEN** the CronJob pod starts
- **THEN** the Soft Serve repos PVC is mounted with `readOnly: true`

#### Scenario: Concurrent runs are prevented
- **WHEN** a previous backup job is still running
- **THEN** the CronJob skips the new run due to `concurrencyPolicy: Forbid`

### Requirement: Cold Backup to idrive e2
The system SHALL run a Kubernetes CronJob on the RustFS cluster (`karma`) that executes `rustic backup` targeting the Soft Serve specific synced directory to an idrive e2 backend (`idrivee2:repos.soft-serve.tlab`) every 6 hours, with `rustic forget` and `rustic prune` applied in the same job to manage stale snapshots.

#### Scenario: Cold backup runs on schedule from RustFS cluster
- **WHEN** 6 hours elapse since the last run
- **THEN** the CronJob on the RustFS cluster starts and executes `rustic backup` against the synced Soft Serve data

#### Scenario: Stale snapshots are pruned after backup
- **WHEN** the backup completes successfully
- **THEN** the job runs `rustic forget` with a retention policy and `rustic prune` to remove stale snapshots

### Requirement: Backup Tools Image
The system SHALL use a custom Docker image `ghcr.io/nimser/homelab-backup-tools` containing both `rclone` and `rustic` for all backup CronJobs.

#### Scenario: Backup jobs use the custom image
- **WHEN** a backup CronJob pod is created
- **THEN** the pod uses `ghcr.io/nimser/homelab-backup-tools` as its container image

#### Scenario: Image contains required tools
- **WHEN** the backup image is built
- **THEN** both `rclone` and `rustic` binaries are available in the image

### Requirement: Backup Credentials Management
The system SHALL store backup credentials (rclone config, idrive e2 AWS credentials, rustic repository password) in SOPS-encrypted Secrets mounted into the backup CronJob pods.

#### Scenario: rclone config is available to warm backup
- **WHEN** the warm backup CronJob runs
- **THEN** the `backup-rclone-config` Secret is mounted and `rclone.conf` is accessible

#### Scenario: idrive e2 credentials are available to cold backup
- **WHEN** the cold backup CronJob runs
- **THEN** the `backup-rustic-env` Secret is mounted and AWS credentials plus repository password are accessible as environment variables

### Requirement: Backup Image Build Documentation
The system SHALL document the process for building and pushing the `ghcr.io/nimser/homelab-backup-tools` image in the repository README.

#### Scenario: Build instructions are documented
- **WHEN** a user reads the README
- **THEN** step-by-step instructions for building and pushing the backup image are present
