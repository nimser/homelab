## Why

Soft Serve is currently deployed but only accessible internally on the local network (`ss.lan.nwo.pm`). We need to securely expose it to authorized clients without opening firewall ports, allowing external secure access.

## What Changes

- Integrate Tailscale Kubernetes Operator for secure service exposure
- Assign a dedicated Tailscale IP to the Soft Serve service
- Create Cloudflare A record `ss.tn.nwo.pm` pointing to the Tailscale IP
- Update remotes to use the new Tailscale URL

## Capabilities

### New Capabilities

- `tailscale-operator`: Tailscale Kubernetes Operator deployment for zero-trust service exposure with dedicated Tailscale IP

### Modified Capabilities

<!-- No existing capabilities modified -->

## Impact

- **New infrastructure**: `infrastructure/controllers/base/tailscale-operator/` (HelmRelease, HelmRepository)
- **New SOPS secrets**: Tailscale OAuth credentials
- **DNS**: Cloudflare A record `ss.tn.nwo.pm` pointing to Tailscale IP
