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

### Requirement: Talos Image Factory for system extensions
The system SHALL use Talos Image Factory Schematic IDs to bake system extensions (like Tailscale) directly into the installer and OS images, as required by Talos v1.13+.

#### Scenario: Installing Talos with extensions
- **WHEN** a node is installed or upgraded
- **THEN** it SHALL use a custom image reference containing the Image Factory Schematic ID that includes the required extensions.

### Requirement: Generalized provisioning and patching
The system SHALL provide generalized provisioning (`provision-node.sh`) and patching (`patch-node.sh`) scripts that accept a cluster name and IP, ensuring idempotency and safe multi-node management via `yq` array merging.

#### Scenario: Applying a patch idempotently
- **WHEN** a configuration patch (like a SOPS key) is applied to a live node
- **THEN** the script SHALL safely merge the patch into the existing configuration without duplicating array elements.

### Requirement: Ephemeral dev environment access recovery
The system SHALL securely backup the `talosconfig` generated during provisioning as a SOPS-encrypted Kubernetes Secret, allowing ephemeral development environments (like Devcontainers) to seamlessly restore API access.

#### Scenario: Restoring access in a new Devcontainer
- **WHEN** a new development container is launched with the SOPS Age key present
- **THEN** the `setup-talos.sh` script SHALL decrypt and merge all cluster `talosconfig`s into the local `~/.talos/config`.
