## 1. Preparation and Secret Generation

- [x] 1.1 Generate SSH host keys (RSA 4096-bit and Ed25519) using `ssh-keygen`
- [x] 1.2 Create plaintext `soft-serve-admin-keys.yaml` as a Kubernetes Secret with `SOFT_SERVE_INITIAL_ADMIN_KEYS` containing all your public keys (separated by newlines) and encrypt with SOPS
- [x] 1.3 Create plaintext `soft-serve-ssh-hostkeys.yaml` with generated host keys and encrypt with SOPS

## 2. Application Manifests

- [x] 2.1 Create `apps/base/soft-serve/namespace.yaml`
- [x] 2.2 Create `apps/base/soft-serve/storage.yaml` (PVC without `storageClassName`)
- [x] 2.3 Create `apps/base/soft-serve/service.yaml` (Type NodePort, port 22 -> targetPort 22, nodePort 30022)
- [x] 2.4 Create `apps/base/soft-serve/deployment.yaml` with initContainer for host key injection and env referencing the admin keys secret
- [x] 2.5 Create `apps/base/soft-serve/kustomization.yaml`
- [x] 2.6 Create `apps/staging/soft-serve/kustomization.yaml` referencing base and SOPS secrets
- [x] 2.7 Create `apps/staging/soft-serve/soft-serve-admin-keys.yaml` (SOPS-encrypted secret reference)
- [x] 2.8 Create `apps/staging/soft-serve/soft-serve-ssh-hostkeys.yaml` (SOPS-encrypted secret reference)
- [x] 2.9 Add `soft-serve` to `apps/staging/kustomization.yaml`

## 3. DNS and Client Configuration

- [x] 3.1 Retrieve the LAN IP of the `staging` k3s node
- [x] 3.2 Create Cloudflare DNS A record `ss.lan.nwo.pm` pointing to the LAN IP
- [x] 3.3 Update local `~/.ssh/config` to route `ss.lan.nwo.pm` via FIDO2 identity with port 30022

## 4. Verification and Documentation

- [x] 4.1 Apply changes and wait for FluxCD reconciliation
- [x] 4.2 Test SSH connection: `ssh -p 30022 ss.lan.nwo.pm` using FIDO2 key
- [x] 4.3 Configure a Gopass remote to use `ssh://ss.lan.nwo.pm:30022/gopass.git` and verify sync
- [x] 4.4 Update the repository `README.md` to document the Soft Serve deployment, its purpose, and the internal `ss.lan.nwo.pm` endpoint
