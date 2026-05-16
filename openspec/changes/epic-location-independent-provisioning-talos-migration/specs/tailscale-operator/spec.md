## MODIFIED Requirements

### Requirement: Tailscale operator integration
The system SHALL deploy the Tailscale operator via FluxCD HelmRelease on Talos nodes, in addition to the OS-level Tailscale extension. The operator manages k8s-native Tailscale resources (LoadBalancer services, VPN connectivity) while the extension provides OS-level access.

#### Scenario: Tailscale operator on Talos
- **WHEN** the Tailscale operator is deployed on a Talos k3s cluster
- **THEN** it SHALL function identically to the current Debian/k3s deployment, creating LoadBalancer services and managing k8s Tailscale resources
