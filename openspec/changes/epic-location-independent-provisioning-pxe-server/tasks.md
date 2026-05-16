## 1. Odroid C2 Setup

- [ ] 1.1 Install Armbian on Odroid C2
- [ ] 1.2 Configure static IP on Odroid C2
- [ ] 1.3 Install and configure dnsmasq (proxyDHCP + TFTP)
- [ ] 1.4 Install and configure HTTP server for Talos images and configs
- [ ] 1.5 Install Tailscale on Odroid C2 for remote management

## 2. iPXE Configuration

- [ ] 2.1 Build or download iPXE binary for T440p (x86_64 UEFI)
- [ ] 2.2 Create iPXE boot script with MAC address matching, menu, and timeout logic
- [ ] 2.3 Configure default 5-second timeout to boot from local disk
- [ ] 2.4 Serve rammus and karma Talos machine configs via HTTP
- [ ] 2.5 Serve Talos installer kernel and initramfs via HTTP

## 3. MAC Address Registry

- [ ] 3.1 Collect MAC addresses from all 5 spare T440p ThinkPads
- [ ] 3.2 Create MAC address registry mapping MACs to cluster roles (rammus/karma)
- [ ] 3.3 Add registry to git (dnsmasq config format)
- [ ] 3.4 Label each spare ThinkPad with its assigned cluster role

## 4. Recovery Environment

- [ ] 4.1 Build minimal Alpine/Debian recovery image with Tailscale and disk tools
- [ ] 4.2 Configure iPXE to offer recovery boot option in menu
- [ ] 4.3 Test recovery boot on a spare ThinkPad

## 5. ThinkPad BIOS Configuration

- [ ] 5.1 Document BIOS settings (PXE OpROM enable, boot order, power-on-after-AC)
- [ ] 5.2 Configure BIOS on rammus ThinkPad
- [ ] 5.3 Configure BIOS on karma ThinkPad
- [ ] 5.4 Configure BIOS on all 5 spare ThinkPads

## 6. Testing

- [ ] 6.1 Test PXE boot of a pre-registered spare ThinkPad → auto-provision as rammus
- [ ] 6.2 Test PXE boot of unknown MAC → menu appears, 5s timeout → local disk boot
- [ ] 6.3 Test recovery boot environment and remote Tailscale SSH
- [ ] 6.4 Test Shelly power cycle → ThinkPad boots to PXE → times out → boots from local disk (normal operation)
- [ ] 6.5 Document end-to-end procedure for parents: "unplug broken one, plug in spare, press power"
