## ADDED Requirements

### Requirement: Backup Failure Handling
The system SHALL exit with a non-zero exit code when any backup operation fails (RustFS unreachable, rclone error, rustic error), and SHALL send an ntfy.sh push notification with `priority=3` (urgent) on failure and `priority=1` (silent) on success.

#### Scenario: Failure exits non-zero
- **WHEN** a backup operation encounters an error
- **THEN** the CronJob exits with a non-zero exit code

#### Scenario: Failure sends urgent push notification
- **WHEN** a backup operation fails
- **THEN** an ntfy.sh push notification is sent with `priority=3`

#### Scenario: Success sends silent notification
- **WHEN** a backup operation completes successfully
- **THEN** an ntfy.sh push notification is sent with `priority=1`

### Requirement: External Heartbeat Monitoring
The system SHALL use Healthchecks.io heartbeat checks to detect when backup jobs or the homelab clusters fail to report in. The idrivee2 cold backup CronJob SHALL ping its dedicated Healthchecks.io check on success. Separate lightweight heartbeat CronJobs SHALL run on both the `rammus` and `karma` clusters every 5 minutes to confirm they are alive.

#### Scenario: idrivee2 backup pings Healthchecks.io on success
- **WHEN** the idrivee2 cold backup completes successfully
- **THEN** the CronJob sends a success ping to its Healthchecks.io check URL

#### Scenario: Healthchecks.io detects missed idrivee2 backup
- **WHEN** no ping is received within the expected period (7 hours)
- **THEN** Healthchecks.io triggers an alert via its configured notification channel

#### Scenario: Homelab heartbeats ping Healthchecks.io
- **WHEN** the lightweight heartbeat CronJobs run every 5 minutes on `rammus` and `karma`
- **THEN** they send pings to their respective Healthchecks.io check URLs

#### Scenario: Healthchecks.io detects dead cluster
- **WHEN** no ping is received from a cluster check within 10 minutes
- **THEN** Healthchecks.io triggers an alert via its configured notification channel

### Requirement: Alerting Credentials Management
The system SHALL store alerting configurations (ntfy.sh topic and Healthchecks.io ping URLs) in SOPS-encrypted Secrets mounted into the CronJob pods.

#### Scenario: Alerting config is available to jobs
- **WHEN** a backup or heartbeat CronJob runs
- **THEN** the `alerting-config` Secret is mounted and the relevant URLs/topics are accessible as environment variables
