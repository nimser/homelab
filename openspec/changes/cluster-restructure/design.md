## Context

We are separating concerns by moving backup storage (RustFS) to its own isolated single-node cluster (`karma`), separate from the main application cluster (`rammus`, formerly `staging`). 

## Goals / Non-Goals

**Goals:**
- Rename existing `staging` cluster to `rammus`
- Bootstrap `karma` cluster for RustFS
- Keep FluxCD configuration consistent across both clusters

**Non-Goals:**
- Implement the actual backups to RustFS (handled in a later change)

## Decisions

### 1. Repository Structure
**Decision:** Maintain parallel folders in `clusters/` and `apps/` for each cluster.
**Rationale:** Standard GitOps practice. `clusters/rammus` and `clusters/karma` will define what applications and infrastructure run on each respective cluster.

### 2. Manual Host Provisioning
**Decision:** The OS (Debian/Ubuntu) and k3s will be installed manually on the physical `karma` host, rather than via automated IaC tools (e.g., Ansible).
**Rationale:** Simplifies this specific architecture transition without requiring a heavy upfront investment in automation tools for a single node.

### 3. Centralized Architecture Documentation
**Decision:** Maintain the source of truth for homelab architecture, cluster layout, and app mapping entirely within the main repository `README.md`.
**Rationale:** Ensures developers have a single, immediately visible entry point to understand the homelab's state without digging through a `docs/` folder.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Broken references during rename | Use search/replace carefully and test Flux reconciliation |
