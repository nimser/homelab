## 1. healthchecks.io Setup

- [ ] 1.1 Create healthchecks.io account and project
- [ ] 1.2 Create check for rammus (1-minute interval, 5-minute grace)
- [ ] 1.3 Create check for karma (1-minute interval, 5-minute grace)
- [ ] 1.4 Create check for Odroid C2 (1-minute interval, 5-minute grace)
- [ ] 1.5 Configure webhook integrations on each check (down/up endpoints)
- [ ] 1.6 Store healthchecks.io API keys in SOPS

## 2. Kubernetes CronJobs

- [ ] 2.1 Create CronJob manifest for rammus health ping (every 1 minute)
- [ ] 2.2 Create CronJob manifest for karma health ping (every 1 minute)
- [ ] 2.3 Deploy and verify CronJobs are sending pings

## 3. Odroid C2 Local Monitor

- [ ] 3.1 Write shell script for local health monitor (ping rammus/karma on LAN + check k8s health)
- [ ] 3.2 Configure ntfy.sh notifications for state changes
- [ ] 3.3 Set up script as systemd timer or cron on Odroid C2
- [ ] 3.4 Add Odroid C2 self-health ping to healthchecks.io

## 4. Webhook Integration (Cloudflare Worker)

- [ ] 4.1 Create Cloudflare Worker project for healthcheck webhooks
- [ ] 4.2 Implement webhook handler: receive healthchecks.io down/up events
- [ ] 4.3 Implement Shelly Cloud API power cycle trigger
- [ ] 4.4 Implement hcloud failover trigger (stub for Phase 4)
- [ ] 4.5 Implement ntfy.sh notification on each webhook event
- [ ] 4.6 Deploy Cloudflare Worker and test webhook delivery

## 5. Escalation Logic

- [ ] 5.1 Implement escalation timeline in Cloudflare Worker (1min → power cycle, 15min → failover)
- [ ] 5.2 Implement fiber-up detection (check if Odroid C2 is still pinging healthchecks.io)
- [ ] 5.3 Test full escalation chain: outage → power cycle → recovery
- [ ] 5.4 Test fiber-outage scenario: skip power cycle → direct failover trigger

## 6. ntfy.sh Configuration

- [ ] 6.1 Create ntfy.sh topic for homelab notifications
- [ ] 6.2 Configure ntfy.sh on mobile devices for push notifications
- [ ] 6.3 Integrate ntfy.sh calls into Cloudflare Worker, Odroid C2 monitor, and CronJobs
