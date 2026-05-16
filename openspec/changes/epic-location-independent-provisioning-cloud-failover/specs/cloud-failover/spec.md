## ADDED Requirements

### Requirement: On-demand Hetzner VM provisioning
The system SHALL provide a script to provision a Hetzner Cloud VM with Talos Linux pre-configured for a given cluster (rammus or karma).

#### Scenario: Provisioning rammus cloud VM
- **WHEN** the failover script is run for rammus
- **THEN** a Hetzner CX22 VM SHALL be created with Talos Linux, the rammus-cloud machine config applied, k3s bootstrapped, and FluxCD reconciling within 15 minutes

#### Scenario: Provisioning karma cloud VM
- **WHEN** the failover script is run for karma
- **THEN** a Hetzner CX22 VM SHALL be created with Talos Linux, the karma-cloud machine config applied, k3s bootstrapped, and FluxCD reconciling within 15 minutes

### Requirement: Cluster failover script
The system SHALL provide a failover-to-cloud.sh script that provisions cloud VMs and redirects Cloudflare tunnels in one command.

#### Scenario: Full failover triggered
- **WHEN** failover-to-cloud.sh is run for a cluster
- **THEN** the script SHALL provision a Hetzner VM, wait for Talos to be ready, bootstrap FluxCD, restore data from iDrive e2, and switch Cloudflare tunnel traffic to the cloud VM

### Requirement: Cluster failback script
The system SHALL provide a failover-back-home.sh script that syncs data back to home and destroys cloud VMs.

#### Scenario: Failback to home
- **WHEN** failover-back-home.sh is run for a cluster
- **THEN** the script SHALL sync RustFS data from cloud to home, switch Cloudflare tunnel to home, and destroy the Hetzner VM

### Requirement: RustFS data restore from iDrive e2
The system SHALL restore RustFS data from iDrive e2 backup during cloud failover.

#### Scenario: Restoring RustFS data on cloud VM
- **WHEN** a cloud VM is provisioned for karma
- **THEN** RustFS data SHALL be restored from iDrive e2 using rustic before apps are started
