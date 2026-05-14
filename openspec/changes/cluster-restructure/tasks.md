## 1. Directory and Reference Renaming (`staging` -> `rammus`)

- [ ] 1.1 Rename `clusters/staging` to `clusters/rammus`
- [ ] 1.2 Rename `apps/staging` to `apps/rammus`
- [ ] 1.3 Rename `infrastructure/controllers/staging` to `infrastructure/controllers/rammus`
- [ ] 1.4 Rename `infrastructure/configs/staging` to `infrastructure/configs/rammus`
- [ ] 1.5 Update Kustomization paths in `clusters/rammus/apps.yaml`, `infrastructure.yaml`, and `monitoring.yaml`
- [ ] 1.6 Verify no leftover `staging` string references exist in yaml files using grep

## 2. Karma Cluster Provisioning (Manual Steps)

- [ ] 2.1 Manually install base OS (Debian/Ubuntu) on the new physical RustFS host
- [ ] 2.2 Manually install k3s on the host: `curl -sfL https://get.k3s.io | sh -`
- [ ] 2.3 Retrieve the k3s kubeconfig from the `karma` node to the local machine

## 3. Karma Repository Scaffold & Flux Bootstrap

- [ ] 3.1 Create `clusters/karma/apps.yaml` pointing to `apps/karma`
- [ ] 3.2 Create `clusters/karma/infrastructure.yaml` pointing to `infrastructure/configs/karma`
- [ ] 3.3 Create `apps/karma/kustomization.yaml`
- [ ] 3.4 Execute manual Flux bootstrap against the new node: `flux bootstrap github --owner=<owner> --repository=homelab --branch=main --path=clusters/karma`

## 4. RustFS Base Deployment

- [ ] 4.1 Create `apps/base/rustfs/namespace.yaml`
- [ ] 4.2 Create `apps/base/rustfs/storage.yaml` (local-path PVC)
- [ ] 4.3 Create `apps/base/rustfs/deployment.yaml` and `service.yaml`
- [ ] 4.4 Create `apps/base/rustfs/kustomization.yaml`
- [ ] 4.5 Create `apps/karma/rustfs/kustomization.yaml` referencing the base
- [ ] 4.6 Add `rustfs` to `apps/karma/kustomization.yaml`

## 5. Verification and Documentation

- [ ] 5.1 Verify Flux reconciles the `rammus` cluster successfully after the rename
- [ ] 5.2 Verify Flux reconciles the `karma` cluster and RustFS is deployed
- [ ] 5.3 Update the root `README.md` to document the new dual-cluster architecture, explaining the distinct purposes of `rammus` (apps) and `karma` (storage/backups), along with manual provisioning instructions.
