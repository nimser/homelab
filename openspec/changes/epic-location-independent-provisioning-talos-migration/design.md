## Context

The homelab runs two single-node k3s clusters (rammus = apps, karma = storage) on ThinkPad T440p hardware at the user's parents' home. Currently running Debian/Ubuntu with manual OS provisioning. The user travels full-time in a motorhome and needs remote management and disaster recovery capabilities. Talos Linux is the chosen OS because it provides immutable, API-managed infrastructure with declarative machine configs that can provision any hardware identically.

## Goals / Non-Goals

**Goals:**
- Migrate both clusters (rammus and karma) from Debian/Ubuntu to Talos Linux
- Create version-controlled Talos machine configs for each node
- Enable OS-level Tailscale access (independent of k8s health) via Talos extensions
- Ensure all existing workloads run identically on Talos
- Make node provisioning reproducible from git-tracked configs

**Non-Goals:**
- Cloud failover (handled in a separate change)
- PXE boot infrastructure (handled in a separate change)
- Automated health monitoring and recovery (handled in a separate change)
- Multi-node clustering (remaining single-node per cluster)

## Decisions

**1. Talos Linux over Debian + Ansible**
- Talos provides immutable OS with declarative machine configs in git
- Same config provisions ThinkPad or Hetzner VM (enables cloud failover later)
- No SSH = no configuration drift
- Atomic upgrades and rollback
- Alternative (Ansible on Debian) would still require manual OS install and is prone to drift

**2. Talos Tailscale extension for remote access**
- Provides OS-level access even when k8s is down
- Pre-authenticated via Tailscale auth key baked into machine config
- Enables `talosctl` access from anywhere in the world
- Alternative (VPN/port-forwarding) would require home network access

**3. k3s (not k8s) on Talos**
- Staying with k3s to maintain compatibility with existing manifests
- Talos supports k3s as a container runtime option
- Minimizes migration risk by keeping the same k8s distribution

**4. Machine config structure**
- Each node gets its own machine config YAML in git (`talos/rammus/controlplane.yaml`, `talos/karma/controlplane.yaml`)
- Shared configuration via Talos patches (networking, Tailscale, SOPS)
- Cloud machine configs will extend home configs with different network settings

**5. SOPS/Age key management**
- Age private key stored securely (password manager)
- Applied via Talos machine config during provisioning (not manual placement)
- Flux reconciliation uses SOPS decrypt as before

## Risks / Trade-offs

- **Migration requires physical access** for initial Talos USB boot → Mitigation: plan migration for when user is home, or ship USB to parents
- **No SSH access** → Mitigation: `talosctl` provides equivalent access; Tailscale extension enables remote access
- **Hardware compatibility** with T440p → Mitigation: Talos supports x86_64 well; T440p has standard Intel NIC and storage
- **Learning curve** for Talos → Mitigation: user is technical; Talos API is well-documented
- **k3s on Talos** is less common than k8s → Mitigation: Talos officially supports k3s; community is active
