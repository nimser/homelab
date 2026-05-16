## Why

The individual components (Talos migration, PXE, health monitoring, cloud failover) work in isolation but need to be orchestrated into an automated end-to-end recovery system. When a node goes down, the system should attempt local recovery first (Shelly power cycle), then escalate to cloud failover if recovery fails - all with notifications at each stage. This change ties all the pieces together into a cohesive automated system.

## What Changes

- Implement the Cloudflare Worker that receives healthchecks.io webhooks and triggers recovery actions
- Implement escalation logic: power cycle → wait → failover
- Implement auto-fallback detection: when home recovers, notify and offer manual failback
- End-to-end testing of all failure scenarios
- Documentation: recovery runbook for parents (with pictures)

## Capabilities

### New Capabilities
- `failover-orchestration`: End-to-end automated failover orchestration from health check detection through recovery or cloud failover

### Modified Capabilities
_(none)_

## Impact

- Requires Cloudflare Workers deployment
- Recovery timing depends on health check interval (1 minute) and escalation delays (5 min power cycle, 15 min failover)
- Full failover takes approximately 20-30 minutes from outage detection to cloud access
- Parents need a printed runbook with pictures for physical tasks (swapping ThinkPads)
