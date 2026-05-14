## Context

CronJobs for backups have been implemented but fail silently. Total cluster loss is also currently undetected.

## Goals / Non-Goals

**Goals:**
- Dual-layer alerting: detect both immediate failures and total host outages via Healthchecks.io + ntfy.sh

## Decisions

### 1. Dual-Layer Alerting: Healthchecks.io + ntfy.sh
**Decision:** Use Healthchecks.io heartbeat checks for absence detection and ntfy.sh push notifications for immediate failure alerts.

**Architecture:**
- **Healthchecks.io** (3 checks): `homelab-alive` (5-min heartbeat from `rammus`), `rustfs-alive` (5-min heartbeat from `karma`), `soft-serve-backup` (pinged by idrivee2 CronJob on success, 7-hour period)
- **ntfy.sh**: Direct push from backup scripts — `priority=3` (urgent) on failure, `priority=1` (silent) on success
- Healthchecks.io configured to send alerts via ntfy.sh as its notification channel

**Rationale:** Two complementary detection models — Healthchecks.io detects "didn't report in" (covers total power cuts, dead hosts), ntfy.sh provides immediate push for "something broke right now" (RustFS unreachable, API errors).

**Self-hosting path:** Both Healthchecks.io and ntfy.sh are open source and self-hostable. The CronJob scripts only reference base URLs, so migration requires no code changes.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Healthchecks.io SaaS outage | ntfy.sh push notifications still work independently; HC is only for absence detection |
| ntfy.sh topic discovered by attacker | Topic is not a secret; sensitive data should not be included in notification payloads |
