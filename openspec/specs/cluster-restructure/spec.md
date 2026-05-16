## ADDED Requirements

### Requirement: Cluster Rename
The system SHALL rename all references of the `staging` cluster to `rammus` across the GitOps repository.

#### Scenario: Staging folders renamed
- **WHEN** the `clusters/staging`, `apps/staging`, and `infrastructure/*/staging` directories exist
- **THEN** they are renamed to `rammus`

#### Scenario: Kustomization references updated
- **WHEN** FluxCD reconciles the cluster
- **THEN** it looks for Kustomizations in the `rammus` paths and successfully syncs

### Requirement: Karma Cluster Scaffold
The system SHALL establish a folder structure for a new `karma` cluster matching the existing GitOps pattern, and document the required manual bootstrap steps.

#### Scenario: Karma folders exist
- **WHEN** the user inspects the repository
- **THEN** `clusters/karma/`, `apps/karma/`, and relevant `infrastructure` folders exist

#### Scenario: Flux is manually bootstrapped
- **WHEN** the user is ready to sync the cluster
- **THEN** they execute the manual `flux bootstrap github` command targeting the `clusters/karma` path

### Requirement: Homelab Documentation
The system SHALL reflect the dual-cluster architecture in the root `README.md`.

#### Scenario: Architecture is documented
- **WHEN** a user reads the `README.md`
- **THEN** the distinct roles of `rammus` (apps) and `karma` (backups) are clearly explained

### Requirement: RustFS Base Deployment
The system SHALL deploy RustFS to the `karma` cluster as a base capability for future backup targets.

#### Scenario: RustFS is deployed
- **WHEN** the `karma` cluster is provisioned and reconciled by FluxCD
- **THEN** RustFS is deployed and running on the `karma` cluster
