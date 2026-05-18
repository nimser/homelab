# Homelab

GitOps-managed homelab infrastructure using Kubernetes (Talos), FluxCD, and SOPS.

## Getting Started

When setting up a new dev environment or reprovisioning nodes, you'll need the right secrets and tools.

### 1. Secrets Management (.sops.env & direnv)

We use SOPS and Age for secret management. Environment configuration is stored in a `.env` file (gitignored) and encrypted as `.sops.env` (tracked in VCS).

To decrypt and load secrets automatically in your terminal:
1. Ensure you have your SOPS Age key configured.
2. Edit or view secrets using `sops`:
   ```bash
   sops .sops.env
   ```
3. Use `direnv` to automatically load secrets by adding this to your `.envrc`:
   ```bash
   eval "$(sops -d .sops.env)"
   export KUBECONFIG=/tmp/rammus-kubeconfig:/tmp/karma-kubeconfig
   ```

### 2. Node Provisioning

Both `rammus` and `karma` nodes are managed using Talos Linux. To provision a node:

1. Boot the physical host using the Talos Linux ISO.
2. Run the unified provisioning script from the repository root:
   ```bash
   ./scripts/provision-node.sh <cluster-name> <node-ip>
   ```
   *Note: This script automatically handles Tailscale machine cleanup, Talos machine config generation, Kubernetes bootstrapping, and FluxCD installation.*

For detailed information on Talos administration, recovering cluster access, patching, or network configuration, see the [Talos README](talos/README.md).

---

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

## Applications

### Soft Serve (`ss.tn.example.com`)

Private, self-hosted Git server for securely hosting Gopass password stores.
Accessible via Tailscale zero-trust network.

- **Endpoint**: `ssh://ss.tn.example.com:22`
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
gopass remotes add ssh://ss.tn.example.com/gopass.git
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
