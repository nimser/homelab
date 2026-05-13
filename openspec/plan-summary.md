# Comprehensive Execution Plan: Soft Serve Git Server with Tailscale K8s Operator

## 1. Context and Goals
The objective is to deploy a private Git server (Soft Serve) within the existing K8s homelab (`~/code/homelab`) to host Gopass password stores.
The deployment must integrate natively with existing GitOps workflows (FluxCD), use Tailscale for secure, zero-port-forwarding access, and implement a robust 3-2-1-1-0 backup strategy using RustFS (warm mirror) and idrive e2 (cold immutable archive).

## 2. Architecture Overview
- **Application:** Soft Serve v2 (K8s Deployment)
- **Storage:** `local-path` PersistentVolumeClaim (`repos`)
- **Network Access:** Tailscale Kubernetes Operator exposing Soft Serve on a dedicated Tailscale IP (port 22). No Ingress or NodePorts.
- **Authentication:** FIDO2 `sk-ssh-ed25519` (natively supported by Soft Serve).
- **Host Keys:** Pre-generated RSA and Ed25519 keys, SOPS-encrypted, mounted via `initContainer` to survive pod restarts.
- **Backup (Warm):** `rclone sync` to RustFS (`rustfs:repos.soft-serve.tlab`) every 15 minutes via K8s CronJob.
- **Backup (Cold):** `rustic backup` to idrive e2 (`idrivee2:repos.soft-serve.tlab`) every 6 hours via K8s CronJob.
- **Backup Image:** Custom image `ghcr.io/nimser/homelab-backup-tools` (manually built; Renovate handles tag bumps).

## 3. Implementation Steps

### Phase 1: Preparation (Manual Steps for User/Agent)
1. **Generate SSH Host Keys:**
   Run `ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N ""` and `ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N ""` locally.
2. **Create SOPS Secrets:** Create plaintext YAML files for the four required secrets, populate them with the generated/provided data, and encrypt them using `sops --encrypt --in-place <file>`.
   - `soft-serve-admin-keys.yaml` (contains user's FIDO2 public key)
   - `soft-serve-ssh-hostkeys.yaml` (contains the generated RSA/Ed25519 private and public keys)
   - `backup-rclone-config.yaml` (contains `rclone.conf` with RustFS and idrive e2 credentials)
   - `backup-rustic-env.yaml` (contains idrive e2 AWS credentials and repository password)
   - `oauth-credentials.yaml` (contains the Tailscale Client ID and Secret)
3. **Build Backup Image:** Create the Dockerfile (detailed below), build, and push to `ghcr.io/nimser/homelab-backup-tools`.

### Phase 2: K8s Infrastructure (Tailscale Operator)
1. Create `infrastructure/controllers/base/tailscale-operator/` with `namespace.yaml`, `repository.yaml` (HelmRepository), and `release.yaml` (HelmRelease).
2. The HelmRelease must use `valuesFrom` to inject the OAuth Client ID and Secret from the SOPS-encrypted `oauth-credentials.yaml`.
3. Configure the Tailscale Operator to use `tag:tpad-k8s` (this is the tag the OAuth client was authorized to use).
4. Update Kustomizations:
   - Add to `infrastructure/controllers/staging/kustomization.yaml`
   - Add to `infrastructure/configs/staging/kustomization.yaml` (for the SOPS secret)

### Phase 3: Application Deployment (Soft Serve)
1. Create `apps/base/soft-serve/` with `namespace.yaml`, `storage.yaml` (PVC, omit `storageClassName`), `service.yaml` (Type `LoadBalancer`), `deployment.yaml` (with `initContainer` for host keys), and `backup-cronjob.yaml`.
2. Create `apps/staging/soft-serve/` with `kustomization.yaml` (referencing base and SOPS secrets).
3. Update `apps/staging/kustomization.yaml` to include `soft-serve`.

### Phase 4: Verification & Client Config
1. Wait for FluxCD to reconcile.
2. Retrieve the Tailscale IP assigned to the Soft Serve service.
3. Update Cloudflare DNS: Create A record `ss.tn.nwo.pm` pointing to the Tailscale IP.
4. Update local `~/.ssh/config` to route `ss.tn.nwo.pm` via the FIDO2 identity.

## 4. File Structure to be Created/Modified

```text
~/code/homelab/
├── README.md (New - document backup image build process)
├── images/backup-tools/Dockerfile (New)
├── infrastructure/
│   ├── controllers/base/tailscale-operator/ (New files: kustomization, namespace, repository, release)
│   ├── controllers/staging/kustomization.yaml (Modified)
│   └── configs/staging/
│       ├── kustomization.yaml (Modified)
│       └── tailscale-operator/ (New files: kustomization, oauth-credentials.yaml [SOPS])
├── apps/
│   ├── base/soft-serve/ (New files: kustomization, namespace, deployment, service, storage, backup-cronjob)
│   └── staging/
│       ├── kustomization.yaml (Modified)
│       └── soft-serve/ (New files: kustomization, soft-serve-admin-keys.yaml [SOPS], soft-serve-ssh-hostkeys.yaml [SOPS], backup-rclone-config.yaml [SOPS], backup-rustic-env.yaml [SOPS])
```

## 5. Critical Constraints & Notes
- **Namespaces:** Base Kustomize manifests must NOT specify namespaces. Namespaces are injected via the staging `kustomization.yaml`.
- **SOPS:** All files containing sensitive data MUST be encrypted in place using `sops --encrypt --in-place <filename>` before commit.
- **Flags:** Always use longform flags in commands (e.g., `--encrypt`, `--in-place`).
- **HTTP/TUI:** Soft Serve's HTTP interface (port 23232) is internal only. No Ingress or Tailscale exposure for HTTP.
- **Concurrency:** The backup CronJobs run with `concurrencyPolicy: Forbid` and mount the PVC `readOnly: true`. Concurrent access with the main Soft Serve pod is safe because `local-path` supports concurrent readers on the same node.
