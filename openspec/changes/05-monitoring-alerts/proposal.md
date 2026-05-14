## Why

Silent failures in automated jobs (like backups) or cluster downtimes can lead to data loss. We need a dual-layer alerting system to detect both immediate failures and total host outages.

## What Changes

- Implement dual-layer alerting: Healthchecks.io heartbeat checks for absence detection and ntfy.sh push notifications for immediate failure alerts
- Add SOPS-encrypted secret management for ntfy.sh topic and Healthchecks.io ping URLs

## Capabilities

### New Capabilities

- `monitoring-alerts`: Dual-layer alerting (Healthchecks.io + ntfy.sh)

### Modified Capabilities

- `backup-strategy`: Backup CronJobs updated to push notifications and ping heartbeats

## Impact

- **Modified CronJobs**: Existing backup CronJobs on both `rammus` and `karma` updated to use `curl` for alerts
- **New CronJobs**: Lightweight cluster heartbeat CronJobs on both clusters
- **New SOPS secrets**: ntfy.sh topic, Healthchecks.io ping URLs
