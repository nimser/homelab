## ADDED Requirements

### Requirement: OS-Level Remote Reboot
The system SHALL provide a mechanism to gracefully reboot nodes at the OS level (via `talosctl`) when Kubernetes is unresponsive but the Talos API is still functioning.

#### Scenario: Kubernetes hangs, Talos responsive
- **WHEN** the Kubernetes API server is unresponsive
- **THEN** the user SHALL use `talosctl reboot` via Tailscale to restart the node gracefully

### Requirement: Hard Power Cycle via Battery Depletion
The system SHALL rely on battery depletion via Shelly smart plugs for hard power cycles when nodes are completely unresponsive (Talos API unreachable).

#### Scenario: Node completely unresponsive
- **WHEN** the node is completely hung and the Talos API is unreachable
- **THEN** the user SHALL turn off the Shelly smart plug, waiting for the laptop battery to deplete to trigger a hard shutdown

### Requirement: Wake-on-LAN Recovery
The system SHALL support Wake-on-LAN (WoL) from the Odroid C2 PXE server to wake nodes that have shut down after battery depletion and power restoration.

#### Scenario: Waking a depleted node
- **WHEN** the Shelly smart plug restores power to a node with a depleted battery
- **THEN** the user SHALL trigger a Wake-on-LAN magic packet from the Odroid C2 to power on the node, which will then network-boot via the PXE server