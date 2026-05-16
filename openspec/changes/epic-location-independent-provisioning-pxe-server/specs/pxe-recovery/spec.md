## ADDED Requirements

### Requirement: Recovery boot environment
The PXE server SHALL provide a minimal Linux recovery environment bootable via iPXE for diagnostics and data recovery.

#### Scenario: Booting into recovery environment
- **WHEN** a node boots into the recovery environment via iPXE menu
- **THEN** the node SHALL start a minimal Linux system with Tailscale connectivity and disk mounting tools

#### Scenario: Remote data recovery
- **WHEN** a node is in the recovery environment and connected via Tailscale
- **THEN** the user SHALL be able to SSH into the node remotely and mount local disks for data recovery

#### Scenario: Disk health check
- **WHEN** a node is in the recovery environment
- **THEN** the user SHALL be able to run disk diagnostics (smartctl, fsck) on local storage via remote SSH
