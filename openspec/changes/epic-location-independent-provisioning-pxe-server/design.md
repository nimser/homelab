## Context

The user has 5 spare ThinkPad T440ps at their parents' home. When the active rammus or karma node fails, a parent should be able to swap in a spare by simply plugging in cables and pressing power. The PXE server (on an Odroid C2) will automatically provision the correct Talos machine config based on the ThinkPad's MAC address. The user travels full-time, so remote reprovisioning via Shelly power cycle + PXE is critical.

## Goals / Non-Goals

**Goals:**
- Auto-provision Talos nodes from network boot based on MAC address
- Provide recovery/diagnostics boot option for data recovery scenarios
- Configure proxyDHCP so Freebox router remains the primary DHCP server
- Zero-touch reprovisioning: plug in spare → boot → working node

**Non-Goals:**
- Automated BIOS configuration (one-time manual setup per ThinkPad)
- Cloud failover (separate change)
- Health monitoring (separate change)

## Decisions

**1. proxyDHCP mode (not full DHCP)**
- Freebox router continues handling IP address assignment for all LAN devices
- Odroid C2 only responds to PXE boot requests (DHCP option 60/77)
- Less disruptive: no need to reconfigure the entire home network
- Alternative (full DHCP on Odroid) would require disabling Freebox DHCP

**2. iPXE over plain PXE**
- iPXE supports scripting, HTTP transfers (faster than TFTP), and conditional boot logic
- Enables MAC-based auto-provisioning and boot menus
- Plain PXE only supports simple TFTP boot without intelligence

**3. dnsmasq for all PXE services**
- Single lightweight daemon handles proxyDHCP, TFTP, and DNS
- Runs easily on Odroid C2 (ARM64, 2GB RAM)
- Alternative (separate dhcpd + tftpd) adds unnecessary complexity

**4. Recovery environment via iPXE menu**
- Default boot: local disk (5-second timeout)
- Menu option: Talos provisioning (auto-selected if MAC is known)
- Menu option: Recovery Linux with Tailscale
- Recovery Linux is a minimal Alpine/Debian with Tailscale pre-configured for remote SSH access

**5. MAC address registry in git**
- All ThinkPad MAC addresses mapped to rammus/karma roles in version-controlled config
- Parents label each spare ThinkPad with "RAMMUS" or "KARMA"
- When a pre-registered MAC PXE-boots, it auto-provisions without menu interaction

## Risks / Trade-offs

- **Odroid C2 as single point of failure** → Mitigation: if PXE server is down, ThinkPads fall through to local disk boot (5-second timeout); recovery requires fixing/replacing Odroid C2
- **Freebox router DHCP conflicts** → Mitigation: proxyDHCP mode avoids conflicts; thorough testing on LAN before production
- **BIOS configuration requires physical access** → Mitigation: one-time setup; documented in runbook for parents
- **T440p PXE OpROM support** → Mitigation: verified Intel I217-V NIC supports PXE; BIOS option exists in Config → Network
