# soft-serve-deployment Specification

## Purpose
TBD - created by archiving change soft-serve-core. Update Purpose after archive.
## Requirements
### Requirement: Soft Serve Deployment
The system SHALL deploy Soft Serve as a Kubernetes Deployment with a single replica, running in a dedicated namespace, with SSH access exposed internally via a NodePort Service.

#### Scenario: Deployment is created and running
- **WHEN** the FluxCD HelmRelease or Kustomization is applied
- **THEN** a Soft Serve Deployment with 1 replica is running in the `soft-serve` namespace

#### Scenario: NodePort is exposed
- **WHEN** the Soft Serve Service is created
- **THEN** it uses type `NodePort` mapping port 22 to a static node port (e.g., 30022)

### Requirement: Initial Admin Bootstrapping
The system SHALL inject the initial administrator's public key via an environment variable.

#### Scenario: Admin key injected
- **WHEN** the Soft Serve pod starts
- **THEN** the `SOFT_SERVE_INITIAL_ADMIN_KEYS` environment variable is populated from a SOPS-encrypted Secret

### Requirement: FIDO2 SSH Authentication
The system SHALL authenticate SSH users using FIDO2 `sk-ssh-ed25519` public keys configured in the Soft Serve admin settings.

#### Scenario: User authenticates with FIDO2 key
- **WHEN** a user with a registered FIDO2 public key connects via SSH
- **THEN** the user is authenticated after FIDO2 device verification

#### Scenario: Unregistered key is rejected
- **WHEN** a user with an unregistered SSH key connects
- **THEN** the connection is denied

### Requirement: SSH Host Key Persistence
The system SHALL maintain stable SSH host keys across pod restarts by copying SOPS-encrypted host keys from a Secret into the data volume via an initContainer.

#### Scenario: Host keys persist across restarts
- **WHEN** the Soft Serve pod is restarted
- **THEN** the same RSA and Ed25519 host keys are used and clients do not see host key changes

#### Scenario: InitContainer copies host keys
- **WHEN** the pod starts
- **THEN** the initContainer copies host keys from the `soft-serve-ssh-hostkeys` Secret to the shared volume before Soft Serve starts

### Requirement: Local-Path Storage
The system SHALL use a `local-path` PersistentVolumeClaim named `repos` for repository storage, without specifying `storageClassName` in the base manifest.

#### Scenario: PVC is created without storageClassName
- **WHEN** the base storage manifest is applied
- **THEN** a PVC is created without an explicit `storageClassName` field

#### Scenario: Repositories persist on the volume
- **WHEN** a user pushes a repository to Soft Serve
- **THEN** the repository data is stored on the `repos` PVC

