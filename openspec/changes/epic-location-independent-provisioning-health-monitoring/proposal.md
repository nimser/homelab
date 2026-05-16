## Why

When the homelab goes down while the user is traveling, they need to know immediately and have automated recovery attempts. Currently there is no monitoring or alerting system - the user would only discover an outage when they try to access a service. Automated health checks with intelligent recovery (Shelly power cycle, cloud failover) and notifications (ntfy.sh) are essential for location-independent resilience.

## What Changes

- Add healthchecks.io pings from k8s CronJobs on rammus and karma
- Set up Odroid C2 as local health monitor (LAN-level checks + ntfy.sh alerts)
- Configure healthchecks.io webhooks for automated Shelly power cycling
- Configure healthchecks.io webhooks for cloud failover triggering
- Create ntfy.sh notification integration for all state changes
- Add Odroid C2 health monitor ping to healthchecks.io (to detect Odroid C2 outages)

## Capabilities

### New Capabilities
- `health-monitoring`: Automated health checks with escalation and notifications (healthchecks.io + Odroid C2 local + ntfy.sh)
- `automated-recovery`: Shelly power cycle and cloud failover triggered by health check failures

### Modified Capabilities
_(none)_

## Impact

- Requires healthchecks.io account (free tier supports 20 checks)
- Requires ntfy.sh (free, self-hosted option available)
- Requires Shelly Cloud API access (already have smart plugs)
- Odroid C2 needs to be always-on
- Adds CronJobs to rammus and karma clusters
