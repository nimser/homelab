## Context

Soft Serve is currently deployed on the internal cluster. We want to expose it to clients securely without opening inbound ports on the router.

## Goals / Non-Goals

**Goals:**
- Expose Soft Serve on a dedicated Tailscale IP
- Zero port forwarding; all access through Tailscale's zero-trust network

**Non-Goals:**
- No Ingress or NodePort resources

## Decisions

### 1. Tailscale Operator over Ingress + WireGuard
**Decision:** Use Tailscale Kubernetes Operator to expose Soft Serve on a dedicated Tailscale IP.
**Rationale:** Eliminates port forwarding entirely, provides built-in ACL-based access control, and integrates with the existing Tailscale tailnet. No need to manage WireGuard peers or open firewall ports.

### 2. Replace NodePort with LoadBalancer
**Decision:** Modify the existing Soft Serve Service from type `NodePort` to `LoadBalancer` annotated for Tailscale, dropping the `ss.lan.nwo.pm` internal route.
**Rationale:** Enforces a zero-trust model where all access must traverse Tailscale, simplifying network security.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Tailscale OAuth credentials rotation | Credentials stored as SOPS-encrypted Secret; rotation requires re-encrypting and re-applying |
