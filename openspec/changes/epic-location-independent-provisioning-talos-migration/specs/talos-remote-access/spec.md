## ADDED Requirements

### Requirement: OS-level Tailscale access on Talos nodes
The system SHALL install the Tailscale Talos extension on all nodes, providing remote access at the OS level independent of Kubernetes health.

#### Scenario: Accessing node when k8s is down
- **WHEN** Kubernetes is unresponsive on a Talos node
- **THEN** the node SHALL still be reachable via its Tailscale IP address for `talosctl` commands

#### Scenario: Accessing node from remote location
- **WHEN** the user is traveling and needs to manage a node
- **THEN** the node SHALL be accessible via Tailscale without VPN or port forwarding

### Requirement: Tailscale auth key in machine config
The system SHALL include a Tailscale auth key in the Talos machine config (stored in SOPS) to enable automatic Tailscale connection on boot.

#### Scenario: Node joins Tailscale network on boot
- **WHEN** a Talos node boots with the Tailscale extension configured
- **THEN** the node SHALL automatically join the Tailscale network without manual intervention
