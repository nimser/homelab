## ADDED Requirements

### Requirement: Automated failover detection and escalation
The system SHALL automatically detect outages, attempt local recovery, and escalate to cloud failover based on configurable timelines.

#### Scenario: Node down, fiber up (power cycle recovery)
- **WHEN** healthchecks.io reports rammus is down AND Odroid C2 is still pinging (fiber is up)
- **THEN** the system SHALL wait 1 minute, then trigger a Shelly power cycle, then wait 5 minutes for recovery, and send ntfy.sh notifications at each step

#### Scenario: Node down, fiber down (immediate failover)
- **WHEN** healthchecks.io reports rammus is down AND Odroid C2 is also not pinging (fiber is down)
- **THEN** the system SHALL skip power cycling and proceed directly to cloud failover evaluation after 15 minutes

#### Scenario: Sustained outage after power cycle
- **WHEN** a Shelly power cycle has been attempted AND the node is still down after 15 minutes
- **THEN** the system SHALL trigger cloud failover and send an ntfy.sh notification

### Requirement: Cloudflare Worker orchestrator
The system SHALL run a Cloudflare Worker that receives healthchecks.io webhooks and orchestrates recovery actions.

#### Scenario: Receiving down webhook
- **WHEN** the Cloudflare Worker receives a "down" webhook from healthchecks.io
- **THEN** it SHALL update Cloudflare KV state, check fiber status, and begin the escalation timeline

#### Scenario: Receiving up webhook
- **WHEN** the Cloudflare Worker receives an "up" webhook from healthchecks.io
- **THEN** it SHALL update Cloudflare KV state, send ntfy.sh notification that the node is back, and wait for manual failback confirmation

### Requirement: Manual failback confirmation
The system SHALL require manual user confirmation before failing back from cloud to home.

#### Scenario: Home network recovers after failover
- **WHEN** the home network recovers and healthchecks.io reports the home node as up
- **THEN** the system SHALL send an ntfy.sh notification asking the user to confirm failback, and wait for a response before proceeding

#### Scenario: User confirms failback
- **WHEN** the user confirms failback via ntfy.sh
- **THEN** the system SHALL trigger the failover-back-home.sh script for the appropriate cluster
