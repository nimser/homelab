## 1. Secret Generation

- [ ] 1.1 Create a new topic on ntfy.sh (e.g., a long random string)
- [ ] 1.2 Create a Healthchecks.io account and configure three checks: `homelab-alive` (5-min), `rustfs-alive` (5-min), and `soft-serve-backup` (7-hour)
- [ ] 1.3 Link the Healthchecks.io project to the ntfy.sh topic via Webhooks/Integrations
- [ ] 1.4 Create plaintext `alerting-config.yaml` containing the ntfy.sh topic URL and Healthchecks.io ping URLs, then encrypt with SOPS for both clusters

## 2. Backup Alerting Injection

- [ ] 2.1 Update the `images/backup-tools/Dockerfile` to ensure `curl` is installed (if not already)
- [ ] 2.2 Update the `rclone` warm sync CronJob on `rammus` to send a `curl` push to ntfy.sh on failure (priority=3) and success (priority=1)
- [ ] 2.3 Update the `rustic` cold backup CronJob on `karma` to send `curl` pushes to ntfy.sh (p3 fail / p1 success)
- [ ] 2.4 Update the `rustic` cold backup CronJob to send a `curl` ping to the `soft-serve-backup` Healthchecks.io URL upon success

## 3. Cluster Heartbeats

- [ ] 3.1 Create `apps/base/cluster-heartbeat/cronjob.yaml` that runs `curl` against a provided Healthchecks.io URL every 5 minutes
- [ ] 3.2 Deploy the heartbeat CronJob to `apps/rammus/cluster-heartbeat/` targeting the `homelab-alive` check
- [ ] 3.3 Deploy the heartbeat CronJob to `apps/karma/cluster-heartbeat/` targeting the `rustfs-alive` check

## 4. Verification and Documentation

- [ ] 4.1 Apply changes and wait for FluxCD reconciliation
- [ ] 4.2 Verify the `homelab-alive` and `rustfs-alive` checks turn green in the Healthchecks.io dashboard
- [ ] 4.3 Trigger the `rustic` CronJob and verify the `soft-serve-backup` check turns green
- [ ] 4.4 Intentionally break a backup configuration and verify an urgent (priority 3) ntfy.sh push notification is received
- [ ] 4.5 Update the repository `README.md` to document the dual-layer alerting strategy (immediate pushes vs absence detection)
