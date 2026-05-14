## Why

The homelab needs a private, self-hosted Git server to securely host Gopass password stores. Currently there is no internal Git infrastructure, forcing reliance on external services for secret management versioning. Deploying Soft Serve provides a CLI-first Git server that integrates with existing FluxCD GitOps workflows. This change sets up the core application on local-path storage with an internal DNS name.

## What Changes

- Deploy Soft Serve as a K8s Deployment on the `staging` cluster with FIDO2 SSH authentication
- Add SOPS-encrypted secret management for SSH host keys and admin keys
- Create Cloudflare A record `ss.lan.nwo.pm` pointing to the internal cluster IP

## Capabilities

### New Capabilities

- `soft-serve-deployment`: Soft Serve Git server deployment with FIDO2 authentication, SSH host key management, and local-path storage

### Modified Capabilities

<!-- No existing capabilities modified -->

## Impact

- **New application**: `apps/base/soft-serve/` and `apps/staging/soft-serve/` (Deployment, Service, PVC)
- **New SOPS secrets**: SSH host keys, admin keys
- **DNS**: Cloudflare A record `ss.lan.nwo.pm` pointing to internal IP
- **Client config**: SSH config update for FIDO2 identity routing and remote updates
