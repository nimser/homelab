## ADDED Requirements

### Requirement: Talos machine config for each cluster node
The system SHALL provide version-controlled Talos machine config YAML files for rammus and karma nodes, defining OS configuration, k3s settings, networking, and extensions.

#### Scenario: Provisioning rammus from machine config
- **WHEN** a Talos machine config for rammus is applied to a bare metal node
- **THEN** the node SHALL boot into Talos Linux with k3s, configured networking, and all specified extensions

#### Scenario: Provisioning karma from machine config
- **WHEN** a Talos machine config for karma is applied to a bare metal node
- **THEN** the node SHALL boot into Talos Linux with k3s, configured networking, and all specified extensions

### Requirement: Talos machine config patches for shared configuration
The system SHALL use Talos config patches to share common configuration (networking, extensions, SOPS) across nodes, avoiding duplication.

#### Scenario: Applying shared network patch
- **WHEN** a shared network patch is defined
- **THEN** all machine configs that include this patch SHALL inherit the network configuration

### Requirement: k3s compatibility on Talos
The system SHALL configure Talos to run k3s as the Kubernetes distribution, maintaining compatibility with existing FluxCD manifests and workloads.

#### Scenario: FluxCD reconciliation on Talos k3s
- **WHEN** FluxCD is bootstrapped on a Talos k3s node
- **THEN** all existing workloads SHALL reconcile and run identically to the current Debian/k3s setup

### Requirement: SOPS/Age key integration with Talos
The system SHALL apply SOPS/Age keys via Talos machine config during node provisioning, enabling FluxCD to decrypt secrets without manual key placement.

#### Scenario: Flux decrypts SOPS secrets on Talos
- **WHEN** FluxCD reconciles a SOPS-encrypted secret on a Talos node
- **THEN** the secret SHALL be decrypted successfully using the Age key provided in the machine config
