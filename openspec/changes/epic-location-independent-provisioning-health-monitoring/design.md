## Context

The user travels full-time and needs automated detection of outages, recovery attempts, and notifications. Three layers of health monitoring provide redundancy: healthchecks.io (external, internet-level), Odroid C2 (local, LAN-level), and ntfy.sh (push notifications). Recovery escalates from Shelly power cycle to cloud failover based on duration of outage.

## Goals / Non-Goals

**Goals:**
- Detect outages within 5 minutes
- Automatically attempt Shelly power cycle recovery when fiber is up
- Trigger cloud failover after 15 minutes of sustained outage
- Notify the user via ntfy.sh at each stage
- Provide redundancy: healthchecks.io for internet-level monitoring, Odroid C2 for LAN-level
- Monitor the monitor: Odroid C2 has its own health check

**Non-Goals:**
- Cloud failover automation (separate change)
- PXE provisioning (separate change)
- Application-level metrics/alerting (Prometheus/Grafana already exists)

## Decisions

**1. healthchecks.io as primary monitor**
- External service, always reachable
- Supports webhooks on up/down/triggered
- Free tier: 20 checks, 1-minute granularity
- Alternative (self-hosted healthchecks) adds maintenance burden

**2. Odroid C2 as secondary monitor**
- Checks health from the LAN perspective
- Detects outages that healthchecks.io can't (e.g., Kubernetes down but internet up)
- Pushes ntfy.sh notifications directly
- Runs as a simple shell script + cron, no complex monitoring stack

**3. ntfy.sh for notifications**
- Simple HTTP-based push notifications
- Free, no account required
- Can be self-hosted if desired
- Alternative (Telegram bot, Discord webhook) adds complexity

**4. Escalation timeline**
- 0-1 min: Outage detected, ntfy notification sent
- 1-5 min: Shelly power cycle attempt (if fiber is up, detected by Odroid C2 pings healthchecks.io)
- 5-15 min: Wait for recovery after power cycle
- 15+ min: Trigger cloud failover

**5. Webhooks via Cloudflare Worker (separate change)**
- healthchecks.io webhooks need a reachable endpoint
- Cannot deliver to home network (might be down)
- Cloudflare Worker provides always-available endpoint
- Worker triggers Shelly Cloud API or hcloud CLI

## Risks / Trade-offs

- **healthchecks.io reliability** → Mitigation: Odroid C2 provides redundant monitoring
- **Shelly Cloud API requires internet at home** → Mitigation: if fiber is down, skip power cycle and go straight to cloud failover
- **False positive outages** → Mitigation: 1-minute grace period before power cycling
- **Cloudflare Worker costs** → Mitigation: free tier (100k requests/day) is more than enough
