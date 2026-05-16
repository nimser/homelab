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

#### Manual Provisioning

The karma host requires manual setup:

1. Install base OS (Debian/Ubuntu) on the physical host
2. Install k3s: `curl -sfL https://get.k3s.io | sh -`
3. Retrieve kubeconfig from `/etc/rancher/k3s/k3s.yaml` on the node
4. Bootstrap Flux: `flux bootstrap github --owner=<owner> --repository=homelab --branch=main --path=clusters/karma`

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
