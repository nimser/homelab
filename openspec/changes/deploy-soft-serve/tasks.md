## 1. Preparation and Secret Generation

- [ ] 1.1 Generate SSH host keys (RSA 4096-bit and Ed25519) using `ssh-keygen`
- [ ] 1.2 Create plaintext `soft-serve-admin-keys.yaml` with FIDO2 public key and encrypt with SOPS
- [ ] 1.3 Create plaintext `soft-serve-ssh-hostkeys.yaml` with generated host keys and encrypt with SOPS
- [ ] 1.4 Create plaintext `backup-rclone-config.yaml` with rclone.conf containing RustFS and idrive e2 credentials and encrypt with SOPS
- [ ] 1.5 Create plaintext `backup-rustic-env.yaml` with idrive e2 AWS credentials and repository password and encrypt with SOPS
- [ ] 1.6 Create plaintext `oauth-credentials.yaml` with Tailscale OAuth Client ID and Secret and encrypt with SOPS
- [ ] 1.7 Create Healthchecks.io account and create checks: `homelab-alive` (5-min), `soft-serve-backup` (7-hour)
- [ ] 1.8 Create plaintext `alerting-config.yaml` with ntfy.sh topic and Healthchecks.io ping URLs and encrypt with SOPS

## 2. Backup Tools Image

- [ ] 2.1 Create `images/backup-tools/Dockerfile` with rclone, rustic, and curl installed
- [ ] 2.2 Build and push the image to `ghcr.io/nimser/homelab-backup-tools`
- [ ] 2.3 Add backup image build documentation to README.md

## 3. Tailscale Kubernetes Operator

- [ ] 3.1 Create `infrastructure/controllers/base/tailscale-operator/namespace.yaml`
- [ ] 3.2 Create `infrastructure/controllers/base/tailscale-operator/repository.yaml` (HelmRepository for Tailscale)
- [ ] 3.3 Create `infrastructure/controllers/base/tailscale-operator/release.yaml` (HelmRelease with `valuesFrom` for OAuth credentials and `tag:tpad-k8s`)
- [ ] 3.4 Create `infrastructure/controllers/base/tailscale-operator/kustomization.yaml`
- [ ] 3.5 Create `infrastructure/configs/staging/tailscale-operator/kustomization.yaml`
- [ ] 3.6 Create `infrastructure/configs/staging/tailscale-operator/oauth-credentials.yaml` (SOPS-encrypted secret reference)
- [ ] 3.7 Add `tailscale-operator` to `infrastructure/controllers/staging/kustomization.yaml`
- [ ] 3.8 Add `tailscale-operator` to `infrastructure/configs/staging/kustomization.yaml`

## 4. Soft Serve Application Deployment

- [ ] 4.1 Create `apps/base/soft-serve/namespace.yaml`
- [ ] 4.2 Create `apps/base/soft-serve/storage.yaml` (PVC without `storageClassName`)
- [ ] 4.3 Create `apps/base/soft-serve/service.yaml` (Type LoadBalancer for Tailscale)
- [ ] 4.4 Create `apps/base/soft-serve/deployment.yaml` with initContainer for host key injection and FIDO2 auth config
- [ ] 4.5 Create `apps/base/soft-serve/backup-cronjob.yaml` (warm and cold backup CronJobs)
- [ ] 4.6 Create `apps/base/soft-serve/kustomization.yaml`
- [ ] 4.7 Create `apps/staging/soft-serve/kustomization.yaml` referencing base and SOPS secrets
- [ ] 4.8 Create `apps/staging/soft-serve/soft-serve-admin-keys.yaml` (SOPS-encrypted secret reference)
- [ ] 4.9 Create `apps/staging/soft-serve/soft-serve-ssh-hostkeys.yaml` (SOPS-encrypted secret reference)
- [ ] 4.10 Create `apps/staging/soft-serve/backup-rclone-config.yaml` (SOPS-encrypted secret reference)
- [ ] 4.11 Create `apps/staging/soft-serve/backup-rustic-env.yaml` (SOPS-encrypted secret reference)
- [ ] 4.12 Add `soft-serve` to `apps/staging/kustomization.yaml`

## 5. Alerting Configuration

- [ ] 5.1 Create `apps/base/soft-serve/homelab-heartbeat-cronjob.yaml` (lightweight CronJob pinging Healthchecks.io every 5 minutes)
- [ ] 5.2 Update `apps/base/soft-serve/backup-cronjob.yaml` to include ntfy.sh push on failure (priority=3) and success (priority=1)
- [ ] 5.3 Update `apps/base/soft-serve/backup-cronjob.yaml` to ping Healthchecks.io `soft-serve-backup` check on idrivee2 success
- [ ] 5.4 Add `alerting-config` Secret reference to `apps/staging/soft-serve/kustomization.yaml`

## 6. Verification and Client Configuration

- [ ] 6.1 Apply changes and wait for FluxCD reconciliation
- [ ] 6.2 Retrieve the Tailscale IP assigned to the Soft Serve service
- [ ] 6.3 Create Cloudflare DNS A record `ss.tn.nwo.pm` pointing to the Tailscale IP
- [ ] 6.4 Update local `~/.ssh/config` to route `ss.tn.nwo.pm` via FIDO2 identity
- [ ] 6.5 Test SSH connection to Soft Serve using FIDO2 key
- [ ] 6.6 Verify warm backup CronJob executes successfully and sends ntfy p1 notification
- [ ] 6.7 Verify cold backup CronJob executes successfully, pings Healthchecks.io, and sends ntfy p1 notification
- [ ] 6.8 Verify homelab heartbeat CronJob pings Healthchecks.io
- [ ] 6.9 Simulate RustFS unreachable and verify ntfy p3 notification is received
- [ ] 6.10 Set up `rustfs-alive` Healthchecks.io check on the RustFS host's k3s cluster
