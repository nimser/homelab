## 1. Directory and Reference Renaming (`staging` -> `rammus`)

- [x] 1.1 Rename `clusters/staging` to `clusters/rammus`
- [x] 1.2 Rename `apps/staging` to `apps/rammus`
- [x] 1.3 Rename `infrastructure/controllers/staging` to `infrastructure/controllers/rammus`
- [x] 1.4 Rename `infrastructure/configs/staging` to `infrastructure/configs/rammus`
- [x] 1.5 Update Kustomization paths in `clusters/rammus/apps.yaml`, `infrastructure.yaml`, and `monitoring.yaml`
- [x] 1.6 Verify no leftover `staging` string references exist in yaml files using grep

## 2. Karma Cluster Provisioning

> **Superseded by** `epic-location-independent-provisioning-talos-migration`.
> Karma will be provisioned directly with Talos Linux instead of Debian/k3s.
> Tasks removed — no unchecked items remain.

## 3. Karma Repository Scaffold & Flux Bootstrap

- [x] 3.1 Create `clusters/karma/apps.yaml` pointing to `apps/karma`
- [x] 3.2 Create `clusters/karma/infrastructure.yaml` pointing to `infrastructure/configs/karma`
- [x] 3.3 Create `apps/karma/kustomization.yaml`
- [x] 3.4 ~~Execute manual Flux bootstrap~~ → handled by `epic-location-independent-provisioning-talos-migration`

## 4. RustFS Base Deployment

- [x] 4.1 Create `apps/base/rustfs/namespace.yaml`
- [x] 4.2 Create `apps/base/rustfs/storage.yaml` (local-path PVC)
- [x] 4.3 Create `apps/base/rustfs/deployment.yaml` and `service.yaml`
- [x] 4.4 Create `apps/base/rustfs/kustomization.yaml`
- [x] 4.5 Create `apps/karma/rustfs/kustomization.yaml` referencing the base
- [x] 4.6 Add `rustfs` to `apps/karma/kustomization.yaml`

## 5. Verification and Documentation

- [x] 5.1 Verify Flux reconciles the `rammus` cluster successfully after the rename
- [x] 5.2 ~~Verify Flux reconciles the `karma` cluster and RustFS is deployed~~ → handled by `epic-location-independent-provisioning-talos-migration`
- [x] 5.3 Update the root `README.md` to document the new dual-cluster architecture, explaining the distinct purposes of `rammus` (apps) and `karma` (storage/backups), along with manual provisioning instructions.
