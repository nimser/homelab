## Why

The homelab currently runs k3s on manually-provisioned Debian/Ubuntu ThinkPads. This makes disaster recovery slow and error-prone - reinstalling the OS, configuring k3s, and bootstrapping Flux requires physical access and manual steps. Talos Linux provides immutable, API-managed infrastructure where the entire OS and k3s configuration is a declarative YAML file in git. This is the foundation for location-independent provisioning: the same machine config can provision a ThinkPad at home or a Hetzner VM in the cloud.

## What Changes

- Replace Debian/Ubuntu on rammus and karma ThinkPads with Talos Linux
- Create Talos machine configs (version-controlled YAML) for rammus and karma
- Install Talos Tailscale extension for OS-level remote access (independent of k8s health)
- Verify all existing workloads (Soft Serve, Audiobookshelf, Linkding, RustFS, monitoring) run identically on Talos
- Migrate SOPS/Age keys and ensure Flux reconciliation works on Talos
- Document the Talos installation and migration procedure

## Capabilities

### New Capabilities
- `talos-node-provisioning`: Declarative machine config provisioning for Talos Linux nodes (rammus, karma)
- `talos-remote-access`: OS-level Tailscale access to Talos nodes for remote management independent of k8s health

### Modified Capabilities
- `tailscale-operator`: Migrate from k8s-only Tailscale operator to include OS-level Tailscale extension on nodes

## Impact

- All existing k8s workloads must be verified on Talos (Soft Serve, Audiobookshelf, Linkding, RustFS, cert-manager, kube-prometheus-stack, Renovate)
- SOPS/Age key management must work with Talos (no shell access for manual key placement)
- FluxCD reconciliation must work on Talos k3s
- Physical access required for initial Talos installation (USB boot)
- Tailscale operator configuration may need adjustments for Talos networking
