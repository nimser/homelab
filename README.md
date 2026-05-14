# Homelab

GitOps-managed homelab infrastructure using Kubernetes (k3s), FluxCD, and SOPS.

## Applications

### Soft Serve (`ss.tn.nwo.pm`)

Private, self-hosted Git server for securely hosting Gopass password stores.
Accessible via Tailscale zero-trust network.

- **Endpoint**: `ssh://ss.tn.nwo.pm:22`
- **Authentication**: FIDO2 SSH keys (`sk-ssh-ed25519`)
- **Storage**: local-path PVC (10Gi)
- **Namespace**: `soft-serve`
- **Network**: Tailscale (no port forwarding required)

#### Prerequisites

- Tailscale client installed and connected to the tailnet
- Appropriate ACL tags configured for access

#### SSH Config

Add to `~/.ssh/config`:

```
Host ss.tn.nwo.pm
  Port 22
  IdentityAgent ~/.ssh-agent
  IdentitiesOnly yes
```

#### Gopass Remote

```bash
gopass remotes add ssh://ss.tn.nwo.pm/gopass.git
```

### Audiobookshelf

Self-hosted audiobook and podcast server.

### Linkding

Self-hosted bookmark manager.

## Architecture

- **Clusters**: staging (k3s)
- **GitOps**: FluxCD
- **Secrets**: SOPS + Age encryption
- **Storage**: local-path provisioner
- **Networking**: Tailscale zero-trust network for service exposure
