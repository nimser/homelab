## 1. Preparation

- [ ] 1.1 Generate Tailscale OAuth Client ID and Secret with appropriate ACL tags
- [ ] 1.2 Create plaintext `oauth-credentials.yaml` with the OAuth credentials and encrypt with SOPS

## 2. Tailscale Operator Deployment

- [ ] 2.1 Create `infrastructure/controllers/base/tailscale-operator/namespace.yaml`
- [ ] 2.2 Create `infrastructure/controllers/base/tailscale-operator/repository.yaml` (HelmRepository for Tailscale)
- [ ] 2.3 Create `infrastructure/controllers/base/tailscale-operator/release.yaml` (HelmRelease with `valuesFrom` for OAuth credentials and `tag:tpad-k8s`)
- [ ] 2.4 Create `infrastructure/controllers/base/tailscale-operator/kustomization.yaml`
- [ ] 2.5 Create `infrastructure/configs/staging/tailscale-operator/kustomization.yaml`
- [ ] 2.6 Create `infrastructure/configs/staging/tailscale-operator/oauth-credentials.yaml` (SOPS-encrypted secret reference)
- [ ] 2.7 Add `tailscale-operator` to `infrastructure/controllers/staging/kustomization.yaml`
- [ ] 2.8 Add `tailscale-operator` to `infrastructure/configs/staging/kustomization.yaml`

## 3. Service Reconfiguration

- [ ] 3.1 Update `apps/base/soft-serve/service.yaml` to change type from `NodePort` to `LoadBalancer`
- [ ] 3.2 Remove the `nodePort: 30022` specification from the service

## 4. Verification and Documentation

- [ ] 4.1 Apply changes and wait for FluxCD reconciliation
- [ ] 4.2 Retrieve the Tailscale IP assigned to the Soft Serve LoadBalancer service
- [ ] 4.3 Update Cloudflare DNS A record to create `ss.tn.nwo.pm` pointing to the Tailscale IP
- [ ] 4.4 Update local `~/.ssh/config` to route `ss.tn.nwo.pm` to port 22
- [ ] 4.5 Update Gopass remotes to use `ssh://ss.tn.nwo.pm/gopass.git` and verify sync works
- [ ] 4.6 Update the repository `README.md` to reflect the transition from LAN access to Tailscale zero-trust access
