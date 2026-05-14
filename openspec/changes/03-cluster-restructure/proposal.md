## Why

The homelab architecture is evolving to include multiple physical locations or nodes with distinct purposes. We need to rename the existing `staging` cluster to `rammus` and bootstrap a new single-node cluster named `karma` that will host the RustFS backup target.

## What Changes

- Rename the existing `staging` cluster folder to `rammus` and update all references
- Scaffold a new cluster folder structure for `karma`
- Deploy the base RustFS application to the `karma` cluster

## Capabilities

### New Capabilities

- `cluster-restructure`: Multi-cluster GitOps layout with `rammus` (apps) and `karma` (RustFS target)

### Modified Capabilities

<!-- No existing capabilities modified -->

## Impact

- **Folder renames**: `clusters/staging` -> `clusters/rammus`, `apps/staging` -> `apps/rammus`, `infrastructure/*/staging` -> `infrastructure/*/rammus`
- **New cluster structure**: `clusters/karma`, `apps/karma`
- **New application**: RustFS base deployment in `apps/base/rustfs` and `apps/karma/rustfs`
