## ADDED Requirements

### Requirement: Cloudflare tunnel failover
The system SHALL switch Cloudflare tunnel traffic from home to cloud VMs during failover using a single API call.

#### Scenario: Switching tunnel to cloud
- **WHEN** cloud failover is triggered for a cluster
- **THEN** the Cloudflare DNS CNAME SHALL be updated to point to the cloud tunnel endpoint within 1 minute

#### Scenario: Switching tunnel back to home
- **WHEN** failback to home is triggered for a cluster
- **THEN** the Cloudflare DNS CNAME SHALL be updated to point to the home tunnel endpoint within 1 minute

### Requirement: Cloud failover tunnel token
The system SHALL store a Cloudflare tunnel token for the failover tunnel in SOPS, deployable to cloud VMs via FluxCD.

#### Scenario: Bootstrapping cloudflared on cloud VM
- **WHEN** FluxCD reconciles on a cloud VM during failover
- **THEN** cloudflared SHALL start with the failover tunnel token and connect to Cloudflare edge
