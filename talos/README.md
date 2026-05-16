# Talos Machine Configs

Declarative Talos Linux machine configs for the homelab clusters.

Talos runs **standard Kubernetes** (not k3s) as system containers managed by the Talos API.

## Structure

```
talos/
├── rammus/
│   └── controlplane.yaml    # Base config for rammus cluster
├── karma/
│   └── controlplane.yaml    # Base config for karma cluster
├── patches/
│   ├── network.yaml          # Shared: DNS, NTP
│   ├── tailscale.yaml        # OS-level Tailscale extension
│   └── sops-age.yaml         # SOPS/Age key for Flux secret decryption
└── README.md
```

## Quick Provision (karma)

```bash
# Boot node from Talos ISO, then run:
./scripts/provision-karma.sh <node-ip>
```

## Manual Provision

```bash
# Generate a new config with secrets filled in
talosctl gen config <cluster-name> https://<node-ip>:6443 \
  --output-dir /tmp/talos-gen \
  --with-cluster-discovery=false \
  --with-docs=false \
  --with-examples=false \
  --kubernetes-version v1.32.4

# Apply machine config with patches
talosctl apply-config \
  --insecure \
  --nodes <node-ip> \
  --file /tmp/talos-gen/controlplane.yaml \
  --config-patch @talos/patches/network.yaml

# Bootstrap Kubernetes
talosctl bootstrap

# Get kubeconfig
talosctl kubeconfig /tmp/<cluster>-kubeconfig

# Bootstrap Flux
export GITHUB_TOKEN=$(gh auth token)
flux bootstrap github \
  --owner=nimser \
  --repository=homelab \
  --branch=main \
  --path=clusters/<cluster-name>
```

### Remote management via Tailscale

```bash
# Once Tailscale extension is active, access node via Tailscale IP
talosctl --nodes <tailscale-ip> get members
```

## Patches

| Patch | Purpose |
|---|---|
| `network.yaml` | DNS servers (1.1.1.1, 1.0.0.1, 8.8.8.8), NTP (time.cloudflare.com) |
| `tailscale.yaml` | Tailscale extension for OS-level remote access (TODO: needs auth key) |
| `sops-age.yaml` | SOPS Age key for Flux secret decryption (TODO: needs key) |

## Network Configuration

| Setting | Value |
|---|---|
| Kubernetes | Standard k8s v1.32.4 (NOT k3s) |
| Pod CIDR | `10.42.0.0/16` |
| Service CIDR | `10.43.0.0/16` |
| DNS Domain | `cluster.local` |
| Upstream DNS | `1.1.1.1`, `1.0.0.1`, `8.8.8.8` |

## Known Issues

- **Tolerations required**: Single-node clusters need `node-role.kubernetes.io/control-plane` tolerations on all workloads. The Flux tolerations patch is in `clusters/karma/flux-system/patches/controller-tolerations.yaml`.
- **PodSecurity**: The `local-path-storage` namespace needs `privileged` PodSecurity labels for the local-path provisioner to work with hostPath volumes.
- **Tailscale extension**: The patch template exists but needs a Tailscale auth key to be functional.
