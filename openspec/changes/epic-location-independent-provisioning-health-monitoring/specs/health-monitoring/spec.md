## ADDED Requirements

### Requirement: Kubernetes CronJob health checks
The system SHALL deploy CronJobs on rammus and karma clusters that ping healthchecks.io at regular intervals to report cluster health.

#### Scenario: Healthy cluster pings healthchecks.io
- **WHEN** a cluster is healthy and running
- **THEN** the CronJob SHALL ping healthchecks.io every 1 minute to signal the node is alive

#### Scenario: Unhealthy cluster stops pinging
- **WHEN** a cluster becomes unresponsive (k8s down, node hung)
- **THEN** healthchecks.io SHALL stop receiving pings and register the node as down after the configured grace period

### Requirement: Odroid C2 local health monitor
The system SHALL run a health monitoring script on the Odroid C2 that checks rammus and karma on the LAN and sends ntfy.sh notifications on state changes.

#### Scenario: Node goes down on LAN
- **WHEN** the Odroid C2 detects that rammus or karma is unreachable on the LAN
- **THEN** the monitor SHALL send a ntfy.sh notification to the user

#### Scenario: Node comes back online
- **WHEN** a previously down node becomes reachable again
- **THEN** the monitor SHALL send a ntfy.sh notification that the node has recovered

### Requirement: Odroid C2 self-health check
The Odroid C2 SHALL have its own health check ping to healthchecks.io, enabling detection of Odroid C2 outages.

#### Scenario: Odroid C2 goes down
- **WHEN** the Odroid C2 stops pinging healthchecks.io
- **THEN** the user SHALL be notified that the monitoring system itself may be down

### Requirement: ntfy.sh notification integration
The system SHALL send push notifications via ntfy.sh for all health state changes (node down, node up, power cycle attempted, failover triggered).

#### Scenario: Node detected as down
- **WHEN** any health check detects a node as down
- **THEN** a ntfy.sh notification SHALL be sent with the node name and type of outage

#### Scenario: Failover triggered
- **WHEN** cloud failover is triggered
- **THEN** a ntfy.sh notification SHALL be sent indicating which cluster is failing over to cloud
