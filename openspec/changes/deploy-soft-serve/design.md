## Context

The homelab runs a Kubernetes cluster managed via GitOps (FluxCD) with existing applications (audiobookshelf, linkding) deployed through Kustomize overlays. Infrastructure controllers (cert-manager, renovate) are deployed via HelmRelease. Secrets are managed with SOPS using age encryption. The cluster uses `local-path` as the default storage provisioner.

There is currently no internal Git server. Gopass password stores need a private, version-controlled backend. External Git services introduce unnecessary trust boundaries for secret material.

## Goals / Non-Goals

**Goals:**
- Deploy Soft Serve as a private Git server accessible only via Tailscale
- Implement FIDO2-based SSH authentication for passwordless, hardware-backed access
- Establish a 3-2-1 backup strategy with warm (RustFS) and cold (idrive e2) targets
- Integrate with existing FluxCD GitOps workflows and SOPS secret management
- Zero port forwarding; all access through Tailscale's zero-trust network
- Dual-layer alerting: detect both immediate failures and total host outages via Healthchecks.io + ntfy.sh

**Non-Goals:**
- No HTTP/TUI exposure (port 23232 remains cluster-internal only)
- No Ingress or NodePort resources for Soft Serve
- No multi-replica deployment (Soft Serve is single-instance with PVC storage)
- No automated backup image builds (manual build; Renovate handles tag bumps)

## Decisions

### 1. Soft Serve over Gitea/GitLab
**Decision:** Use Soft Serve instead of heavier Git servers.
**Rationale:** Soft Serve is purpose-built for CLI-first Git hosting with native FIDO2 support, minimal resource footprint, and simple configuration. Gitea/GitLab add unnecessary complexity for a single-purpose password store backend.
**Alternatives considered:** Gitea (heavier, web UI focus), bare git-daemon (no auth features).

### 2. Tailscale Operator over Ingress + WireGuard
**Decision:** Use Tailscale Kubernetes Operator to expose Soft Serve on a dedicated Tailscale IP.
**Rationale:** Eliminates port forwarding entirely, provides built-in ACL-based access control, and integrates with the existing Tailscale tailnet. No need to manage WireGuard peers or open firewall ports.
**Alternatives considered:** Ingress with mTLS (complex cert management), NodePort + WireGuard (manual peer management).

### 3. SOPS-Encrypted SSH Host Keys via initContainer
**Decision:** Pre-generate SSH host keys, encrypt with SOPS, and mount via initContainer.
**Rationale:** Soft Serve regenerates host keys on each startup if none exist, causing clients to see host key changes. Persisting keys via PVC with an initContainer that copies from SOPS-encrypted secrets ensures stable host keys across pod restarts.
**Alternatives considered:** Persistent host keys in PVC (lost on first deploy), external secret manager (overkill for homelab).

### 4. Dual Backup Strategy (RustFS + idrive e2)
**Decision:** Implement warm sync to RustFS (15-min CronJob on the apps cluster) and a per-app cold backup to idrive e2 (6-hour CronJob on the RustFS cluster) with rustic-managed retention.
**Rationale:** RustFS provides fast recovery for recent data. A per-app cold backup running directly on the RustFS cluster reads the synced data and pushes it to idrive e2, minimizing network load on the main apps cluster and allowing app-specific retention schedules. Together they satisfy a 3-2-1 backup strategy (3 copies, 2 media types, 1 offsite) with managed snapshot lifecycle.
**Alternatives considered:** Single backup target (insufficient redundancy), Whole-drive cold backup (inflexible schedules and recovery).

### 5. Custom Backup Image
**Decision:** Build a custom Docker image (`ghcr.io/nimser/homelab-backup-tools`) containing rclone and rustic.
**Rationale:** Neither rclone nor rustic are available in the Soft Serve image. A shared backup image avoids duplicating tooling across CronJobs and allows Renovate to manage version bumps via image tag.
**Alternatives considered:** Sidecar containers (resource waste), init containers per job (complexity).

### 6. Base Manifests Without Namespaces
**Decision:** Base Kustomize manifests omit `namespace` field; staging overlay injects it.
**Rationale:** Follows existing homelab convention (see audiobookshelf pattern). Enables reuse across environments without duplication.

### 7. Dual-Layer Alerting: Healthchecks.io + ntfy.sh
**Decision:** Use Healthchecks.io heartbeat checks for absence detection and ntfy.sh push notifications for immediate failure alerts.

**Architecture:**
- **Healthchecks.io** (3 checks): `homelab-alive` (5-min heartbeat from homelab k3s), `rustfs-alive` (5-min heartbeat from RustFS host's separate k3s), `soft-serve-backup` (pinged by idrivee2 CronJob on success, 7-hour period)
- **ntfy.sh**: Direct push from backup scripts — `priority=3` (urgent) on failure, `priority=1` (silent) on success
- Healthchecks.io configured to send alerts via ntfy.sh as its notification channel

**Rationale:** Two complementary detection models — Healthchecks.io detects "didn't report in" (covers total power cuts, dead hosts), ntfy.sh provides immediate push for "something broke right now" (RustFS unreachable, API errors). The 3-check budget leaves 17 of 20 free for future homelab monitoring. RustFS runs on a separate host with its own k3s cluster, so its heartbeat is independent.

**Alternatives considered:** Prometheus Alertmanager only (can't alert when homelab is dead), ntfy.sh only (no absence detection), Healthchecks.io only (15-minute email spam when RustFS is down).

**Self-hosting path:** Both Healthchecks.io and ntfy.sh are open source and self-hostable. Healthchecks.io can be added later as a self-hosted instance; ntfy.sh is a single Go binary. The CronJob scripts only reference base URLs, so migration requires no code changes.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| `local-path` PVC is node-local; pod reschedule to different node loses access | The cluster is single-node, so pod scheduling will always find the volume |
| Concurrent PVC access between Soft Serve and backup CronJobs | `local-path` supports concurrent readers; CronJobs mount PVC `readOnly: true` with `concurrencyPolicy: Forbid` |
| Tailscale OAuth credentials rotation | Credentials stored as SOPS-encrypted Secret; rotation requires re-encrypting and re-applying |
| Backup image build is manual | Document build process in README; Renovate monitors and bumps tags automatically |
| FIDO2 key loss locks out admin access | Admin keys stored in SOPS-encrypted Secret; recovery requires re-encrypting with new public key |
| Healthchecks.io SaaS outage | ntfy.sh push notifications still work independently; HC is only for absence detection |
| ntfy.sh topic discovered by attacker | Topic is not a secret; sensitive data should not be included in notification payloads |
