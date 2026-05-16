## 1. Cloudflare Worker Development

- [ ] 1.1 Create Cloudflare Worker project structure
- [ ] 1.2 Implement webhook handler for healthchecks.io down/up events
- [ ] 1.3 Implement Cloudflare KV state management (cluster status, power cycle attempts, failover state)
- [ ] 1.4 Implement Shelly Cloud API integration for power cycling
- [ ] 1.5 Implement hcloud CLI integration for VM provisioning (call failover-to-cloud.sh)
- [ ] 1.6 Implement ntfy.sh notification on each state change
- [ ] 1.7 Implement escalation timeline (1min wait, power cycle, 15min wait, failover)

## 2. Orchestration Logic

- [ ] 2.1 Implement fiber status detection (check if Odroid C2 is still pinging healthchecks.io)
- [ ] 2.2 Implement power cycle attempt tracking in KV (prevent duplicate power cycles)
- [ ] 2.3 Implement failover state tracking (which clusters are currently failed over to cloud)
- [ ] 2.4 Implement failback confirmation flow (ntfy.sh notification → user response → failover-back-home.sh)

## 3. End-to-End Testing

- [ ] 3.1 Test: Node hang → power cycle → recovery (happy path)
- [ ] 3.2 Test: Node hang → power cycle → still down → cloud failover
- [ ] 3.3 Test: Fiber outage → skip power cycle → cloud failover
- [ ] 3.4 Test: Fiber recovery → ntfy.sh notification → manual failback
- [ ] 3.5 Test: False positive → node recovers after 1 minute → no power cycle or failover
- [ ] 3.6 Test: Simultaneous rammus and karma outage → both failover

## 4. Documentation and Runbook

- [ ] 4.1 Create recovery runbook for parents: "unplug broken ThinkPad, plug in spare, press power" with photos
- [ ] 4.2 Create operator runbook: common `talosctl` commands for remote management
- [ ] 4.3 Create failover runbook: manual failover and failback commands
- [ ] 4.4 Create architecture diagram showing all components and data flows
- [ ] 4.5 Print and laminate parent runbook
