# Homelab

GitOps-managed homelab infrastructure using Kubernetes (k3s), FluxCD, and SOPS.

## Architecture

This homelab uses a **dual-cluster** setup with distinct purposes:

### Rammus (`rammus`) - Application Cluster

Main application cluster running user-facing services.

- **Path**: `clusters/rammus`
- **Apps**: `apps/rammus`
- **Infrastructure**: `infrastructure/controllers/rammus`, `infrastructure/configs/rammus`
- **Monitoring**: `monitoring/controllers/rammus`, `monitoring/configs/rammus`

### Karma (`karma`) - Storage/Backup Cluster

Single-node cluster dedicated to running RustFS as a backup storage target.

- **Path**: `clusters/karma`
- **Apps**: `apps/karma`
- **Infrastructure**: `infrastructure/configs/karma`

#### Provisioning

The karma host is provisioned using Talos Linux:

1. Boot the physical host using the Talos Linux ISO
2. Run the provisioning script from the repository root:
   ```bash
   ./scripts/provision-karma.sh
   ```
   This script will apply the machine config, bootstrap Kubernetes, and install FluxCD.

## Applications

### Soft Serve (`ss.tn.nwo.pm`)

Private, self-hosted Git server for securely hosting Gopass password stores.
Accessible via Tailscale zero-trust network.

- **Endpoint**: `ssh://ss.tn.nwo.pm:22`
- **Authentication**: FIDO2 SSH keys (`sk-ssh-ed25519`)
- **Storage**: local-path PVC (10Gi)
- **Namespace**: `soft-serve`
- **Network**: Tailscale (no port forwarding required)
- **Cluster**: rammus

#### Prerequisites

- Tailscale client installed and connected to the tailnet
- Appropriate ACL tags configured for access

#### Gopass Remote

```bash
gopass remotes add ssh://ss.tn.nwo.pm/gopass.git
```

### Audiobookshelf

Self-hosted audiobook and podcast server.

- **Cluster**: rammus

### Linkding

Self-hosted bookmark manager.

- **Cluster**: rammus

### RustFS

Rust-based file storage service for backup targets.

- **Cluster**: karma
- **Namespace**: rustfs
- **Storage**: local-path PVC (100Gi)

## Infrastructure

- **GitOps**: FluxCD
- **Secrets**: SOPS + Age encryption
- **Storage**: local-path provisioner
- **Networking**: Tailscale zero-trust network for service exposure

## Node Management (Talos)

Both `rammus` and `karma` nodes are managed using Talos Linux.

### Remote Access via Tailscale

Nodes are accessible via their Tailscale IP addresses at the OS level (independent of Kubernetes health).
Ensure you have the Tailscale client connected and use `talosctl` targeting the node's Tailscale IP.

### Common `talosctl` Commands

```bash
# Retrieve node status and health
talosctl --nodes <NODE_IP> get machineconfig
talosctl --nodes <NODE_IP> health --wait=false

# View system logs
talosctl --nodes <NODE_IP> logs

# View Kubernetes logs directly from the node
talosctl --nodes <NODE_IP> containers -k

# Upgrade Talos OS
talosctl --nodes <NODE_IP> upgrade --image ghcr.io/siderolabs/installer:v1.9.5

# Upgrade Kubernetes
talosctl --nodes <NODE_IP> upgrade-k8s --to 1.32.4
```
