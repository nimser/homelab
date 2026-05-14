# Homelab

GitOps-managed homelab infrastructure using Kubernetes (k3s), FluxCD, and SOPS.

## Applications

### Soft Serve (`ss.lan.nwo.pm`)

Private, self-hosted Git server for securely hosting Gopass password stores.

- **Endpoint**: `ssh://ss.lan.nwo.pm:30022`
- **Authentication**: FIDO2 SSH keys (`sk-ssh-ed25519`)
- **Storage**: local-path PVC (10Gi)
- **Namespace**: `soft-serve`

#### SSH Config

Add to `~/.ssh/config`:

```
Host ss.lan.nwo.pm
  Port 30022
  IdentityAgent ~/.ssh-agent
  IdentitiesOnly yes
```

#### Gopass Remote

```bash
gopass remotes add ssh://ss.lan.nwo.pm:30022/gopass.git
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
