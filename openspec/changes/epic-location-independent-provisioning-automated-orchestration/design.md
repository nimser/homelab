## Context

Phases 1-4 built the individual components: Talos for declarative provisioning, PXE for bare metal recovery, health monitoring for detection, and cloud failover for running in the cloud. This phase orchestrates them into an automated system. The Cloudflare Worker is the brain: it receives healthchecks.io webhooks, decides on recovery actions, triggers Shelly power cycles or Hetzner provisioning, and sends notifications.

## Goals / Non-Goals

**Goals:**
- Automated detection → power cycle → failover escalation
- ntfy.sh notifications at every step
- Manual confirmation for failback to home
- End-to-end testing of all failure scenarios
- Printed runbook for parents

**Non-Goals:**
- Active-active multi-site (not needed for single-node clusters)
- Automated failback without confirmation (too risky)
- Monitoring dashboards (Prometheus/Grafana already deployed)

## Decisions

**1. Cloudflare Worker as orchestrator**
- Always available (not dependent on home network)
- Free tier sufficient (100k requests/day)
- Receives healthchecks.io webhooks
- Triggers Shelly Cloud API, hcloud CLI, and ntfy.sh
- Alternative (always-on Hetzner VM) costs money even when idle

**2. Escalation timeline**
- 0-1 min: Outage detected, notification sent
- 1-5 min: Check if fiber is up (is Odroid C2 also down?). If up, Shelly power cycle. If down, skip to cloud failover evaluation.
- 5-15 min: Wait for recovery after power cycle
- 15+ min: Trigger cloud failover

**3. Manual failback confirmation**
- When home comes back online (healthchecks.io "up" webhook), send ntfy.sh notification
- User responds via ntfy.sh to confirm failback
- Then trigger failover-back-home.sh
- Prevents thrashing if home fiber is intermittent

**4. State management in Cloudflare Worker**
- Worker uses Cloudflare KV for state persistence
- Track: which clusters are up/down, which are failed over, power cycle attempts
- Prevents duplicate actions on repeated webhooks

## Risks / Trade-offs

- **Cloudflare Worker cold starts** → Mitigation: minimal (usually <50ms); healthchecks.io retries on failure
- **Cloudflare Worker statelessness** → Mitigation: use Cloudflare KV for state; simple key-value store sufficient
- **Hetzner API rate limits** → Mitigation: very generous limits; rarely creating more than 2 VMs
- **False positive failover** → Mitigation: 15-minute wait period; manual confirmation for failback
