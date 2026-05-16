## ADDED Requirements

### Requirement: Automated Shelly power cycle on outage
The system SHALL attempt a Shelly smart plug power cycle when a node is detected as down, as an automated recovery attempt before escalating to cloud failover.

#### Scenario: Node down for 1 minute with fiber up
- **WHEN** healthchecks.io detects a node is down AND the home fiber connection is verified as up (Odroid C2 is still pinging)
- **THEN** the system SHALL trigger a Shelly power cycle on the node's smart plug and notify via ntfy.sh

#### Scenario: Node down with fiber also down
- **WHEN** healthchecks.io detects a node is down AND the home fiber connection appears down (Odroid C2 also not pinging)
- **THEN** the system SHALL skip power cycling and proceed directly to cloud failover evaluation

### Requirement: Cloud failover trigger on sustained outage
The system SHALL trigger cloud failover when a node remains down for 15 minutes after recovery attempts.

#### Scenario: Sustained outage after power cycle
- **WHEN** a node has been down for 15 minutes AND a Shelly power cycle has been attempted
- **THEN** the system SHALL trigger the cloud failover process and notify via ntfy.sh

#### Scenario: Fiber outage (no power cycle possible)
- **WHEN** home fiber is down for 15 minutes
- **THEN** the system SHALL trigger the cloud failover process and notify via ntfy.sh
