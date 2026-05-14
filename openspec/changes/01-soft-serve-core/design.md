## Context

The homelab runs a Kubernetes cluster managed via GitOps (FluxCD). The cluster uses `local-path` as the default storage provisioner. There is currently no internal Git server.

## Goals / Non-Goals

**Goals:**
- Deploy Soft Serve as a private Git server
- Implement FIDO2-based SSH authentication for passwordless, hardware-backed access
- Integrate with existing FluxCD GitOps workflows and SOPS secret management

**Non-Goals:**
- No HTTP/TUI exposure
- No external/Tailscale access (handled in a later change)
- No backups (handled in a later change)
- No multi-replica deployment

## Decisions

### 1. Soft Serve over Gitea/GitLab
**Decision:** Use Soft Serve instead of heavier Git servers.
**Rationale:** Soft Serve is purpose-built for CLI-first Git hosting with native FIDO2 support, minimal resource footprint, and simple configuration.

### 2. SOPS-Encrypted SSH Host Keys via initContainer
**Decision:** Pre-generate SSH host keys, encrypt with SOPS, and mount via initContainer.
**Rationale:** Soft Serve regenerates host keys on each startup if none exist. Persisting keys via PVC with an initContainer that copies from SOPS-encrypted secrets ensures stable host keys across pod restarts.

### 3. Initial Admin FIDO2 Key via Env Var
**Decision:** Inject the initial administrator's FIDO2 public key using the `SOFT_SERVE_INITIAL_ADMIN_KEYS` environment variable.
**Rationale:** Simplifies initial bootstrapping without requiring complex config map merges.

### 4. NodePort for Initial Internal Access
**Decision:** Expose Soft Serve on a `NodePort` (e.g., 30022) and map `ss.lan.nwo.pm` to the physical node's LAN IP.
**Rationale:** Since Tailscale will be added in a subsequent change, a NodePort allows immediate verification of the deployment and Git push/pull functionality on the local network.

### 5. Base Manifests Without Namespaces
**Decision:** Base Kustomize manifests omit `namespace` field; staging overlay injects it.
**Rationale:** Follows existing homelab convention. Enables reuse across environments without duplication.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| `local-path` PVC is node-local; pod reschedule to different node loses access | The cluster is single-node, so pod scheduling will always find the volume |
| FIDO2 key loss locks out admin access | Admin keys stored in SOPS-encrypted Secret; recovery requires re-encrypting with new public key |
