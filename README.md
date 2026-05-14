# Homelab

GitOps-managed homelab infrastructure using Kubernetes (k3s), FluxCD, and SOPS.

## Applications

### Soft Serve (`ss.lan.example.com`)

Private, self-hosted Git server for securely hosting Gopass password stores.

- **Endpoint**: `ssh://ss.lan.example.com:30022`
- **Authentication**: FIDO2 SSH keys (`sk-ssh-ed25519`)
- **Storage**: local-path PVC (10Gi)
- **Namespace**: `soft-serve`

#### SSH Config

Add to `~/.ssh/config`:

```
Host ss.lan.example.com
  Port 30022
  IdentityAgent ~/.ssh-agent
  IdentitiesOnly yes
```

#### Gopass Remote

```bash
gopass remotes add ssh://ss.lan.example.com:30022/gopass.git
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

## Contributing

This repository is a mirror of a private one. It publishes the paths its allowlist names, so it may be a
subset of the project, and its history is regenerated from the source: tags are absent and commits can be
replaced. Pull requests cannot land here.
