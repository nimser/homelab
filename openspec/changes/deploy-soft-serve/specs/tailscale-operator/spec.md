## ADDED Requirements

### Requirement: Tailscale Operator Deployment
The system SHALL deploy the Tailscale Kubernetes Operator via a HelmRelease in the `infrastructure` namespace, configured with the `tag:tpad-k8s` tag.

#### Scenario: Operator is deployed via HelmRelease
- **WHEN** the infrastructure Kustomization is applied
- **THEN** the Tailscale Operator HelmRelease is installed in the `infrastructure` namespace

#### Scenario: Operator uses correct tag
- **WHEN** the operator creates Tailscale services
- **THEN** the services are tagged with `tpad-k8s`

### Requirement: OAuth Credentials Injection
The system SHALL inject Tailscale OAuth Client ID and Secret into the HelmRelease via `valuesFrom` referencing a SOPS-encrypted Secret.

#### Scenario: OAuth credentials are loaded from Secret
- **WHEN** the HelmRelease reconciles
- **THEN** the OAuth Client ID and Secret are read from the `oauth-credentials` Secret

#### Scenario: OAuth credentials are SOPS-encrypted
- **WHEN** the `oauth-credentials.yaml` file is viewed in the repository
- **THEN** the `data` or `stringData` fields are encrypted with SOPS

### Requirement: Tailscale Service Exposure
The system SHALL expose Soft Serve via a Tailscale IP by configuring the Soft Serve Service as Type `LoadBalancer`, which the Tailscale Operator provisions as a Tailscale service.

#### Scenario: Soft Serve gets a Tailscale IP
- **WHEN** the Soft Serve Service of type LoadBalancer is created
- **THEN** the Tailscale Operator assigns a dedicated Tailscale IP to the service

#### Scenario: SSH is accessible via Tailscale IP
- **WHEN** a user on the tailnet connects to the Tailscale IP on port 22
- **THEN** the SSH connection reaches the Soft Serve pod

### Requirement: No Ingress or NodePort
The system SHALL NOT create Ingress or NodePort resources for Soft Serve networking.

#### Scenario: Only LoadBalancer service is used
- **WHEN** the soft-serve resources are applied
- **THEN** no Ingress or NodePort resources exist for Soft Serve
