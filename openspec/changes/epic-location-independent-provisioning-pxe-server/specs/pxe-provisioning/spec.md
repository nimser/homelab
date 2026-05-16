## ADDED Requirements

### Requirement: MAC address auto-provisioning
The PXE server SHALL map known MAC addresses to Talos machine configs, enabling zero-touch node provisioning when a pre-registered ThinkPad boots from the network.

#### Scenario: Pre-registered ThinkPad boots
- **WHEN** a ThinkPad with a pre-registered MAC address PXE-boots on the LAN
- **THEN** the PXE server SHALL serve the Talos machine config matching that MAC's assigned cluster role (rammus or karma)

#### Scenario: Unknown MAC address boots
- **WHEN** a ThinkPad with an unknown MAC address PXE-boots on the LAN
- **THEN** the PXE server SHALL present a boot menu with options to provision as rammus, karma, recovery, or boot from local disk (5-second timeout, defaulting to local disk)

### Requirement: Talos machine config serving via iPXE
The PXE server SHALL serve Talos machine config YAML files via HTTP, integrated with the iPXE boot flow.

#### Scenario: Serving rammus machine config
- **WHEN** iPXE chains to the Talos installer for rammus
- **THEN** the correct rammus machine config YAML SHALL be provided via HTTP with the kernel and initramfs

### Requirement: proxyDHCP mode
The PXE server SHALL operate in proxyDHCP mode, responding only to PXE boot requests while the Freebox router handles all other DHCP.

#### Scenario: Non-PXE device requests DHCP
- **WHEN** a non-PXE device (phone, laptop) requests a DHCP lease
- **THEN** the PXE server SHALL NOT respond, allowing the Freebox router to handle it

#### Scenario: PXE-booting device requests DHCP
- **WHEN** a PXE-booting device sends a DHCP request with PXE client class identifier
- **THEN** the PXE server SHALL respond with the boot filename and TFTP server address
