## Why

The homelab needs a private, self-hosted Git server to securely host Gopass password stores. Currently there is no internal Git infrastructure, forcing reliance on external services for secret management versioning. Deploying Soft Serve with Tailscale integration provides a zero-trust, zero-port-forwarding Git server that integrates with existing FluxCD GitOps workflows and implements a robust 3-2-1 backup strategy with dual-layer alerting.

## What Changes

- Deploy Soft Serve as a K8s Deployment with FIDO2 SSH authentication
- Integrate Tailscale Kubernetes Operator for secure service exposure (no Ingress or NodePorts)
- Implement automated warm backup to RustFS via CronJob on apps cluster (15-minute sync)
- Implement automated per-app cold backup to idrive e2 via CronJob on RustFS cluster (6-hour archive with rustic-managed retention)
- Implement dual-layer alerting: Healthchecks.io heartbeat checks for absence detection and ntfy.sh push notifications for immediate failure alerts
- Add SOPS-encrypted secret management for SSH host keys, admin keys, and backup credentials
- Introduce custom backup tools container image (`ghcr.io/nimser/homelab-backup-tools`)

## Capabilities

### New Capabilities

- `soft-serve-deployment`: Soft Serve Git server deployment with FIDO2 authentication, SSH host key management, and local-path storage
- `tailscale-operator`: Tailscale Kubernetes Operator deployment for zero-trust service exposure with dedicated Tailscale IP
- `backup-strategy`: 3-2-1 backup implementation with warm RustFS sync and cold idrive e2 archival via CronJobs, rustic-managed snapshot retention, and dual-layer alerting (Healthchecks.io + ntfy.sh)

### Modified Capabilities

<!-- No existing capabilities modified -->

## Impact

- **New infrastructure**: `infrastructure/controllers/base/tailscale-operator/` (HelmRelease, HelmRepository)
- **New application**: `apps/base/soft-serve/` and `apps/staging/soft-serve/` (Deployment, Service, PVC, Warm Backup CronJob)
- **New backup component**: Soft Serve specific Cold Backup CronJob deployed to the RustFS cluster
- **New container image**: `images/backup-tools/Dockerfile` for backup tooling
- **New SOPS secrets**: OAuth credentials, SSH host keys, admin keys, backup configs, ntfy.sh topic, Healthchecks.io ping URLs
- **RustFS host**: Separate machine on same LAN, runs its own k3s cluster with a lightweight heartbeat CronJob
- **DNS**: Cloudflare A record `ss.tn.nwo.pm` pointing to Tailscale IP
- **Client config**: SSH config update for FIDO2 identity routing
