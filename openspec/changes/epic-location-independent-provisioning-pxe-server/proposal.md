## Why

When a ThinkPad fails or needs to be replaced, someone at home must manually install an OS and configure it. With 5 spare T440ps available, a PXE/iPXE boot server enables zero-touch reprovisioning: a spare ThinkPad boots from the network, receives the correct Talos machine config based on its MAC address, and becomes the replacement node automatically. This also enables recovery scenarios where a hung machine can be PXE-booted into a diagnostics environment.

## What Changes

- Set up Odroid C2 as PXE/iPXE boot server (Armbian + dnsmasq in proxyDHCP mode)
- Create iPXE boot scripts that auto-select Talos machine configs based on MAC address
- Pre-register all 5 spare ThinkPad MAC addresses with their intended cluster role
- Configure all ThinkPad BIOS settings (PXE OpROM, boot order, power-on-after-AC)
- Create a recovery boot option in iPXE for diagnostics (Linux environment with Tailscale)

## Capabilities

### New Capabilities
- `pxe-provisioning`: Network boot server that auto-provisions Talos nodes based on MAC address mapping
- `pxe-recovery`: Network boot option for diagnostics and data recovery

### Modified Capabilities
_(none)_

## Impact

- Freebox router needs no configuration changes (proxyDHCP mode)
- Odroid C2 needs Armbian installation and network connectivity
- All ThinkPad BIOS settings need one-time manual configuration
- Home network adds a TFTP/DHCP-proxy service on the LAN
PXE2_EOF
