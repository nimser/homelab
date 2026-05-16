# Talos Machine Configs

Declarative Talos Linux machine configs for the homelab clusters.

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

## Usage

### Generate secrets and apply config

```bash
# Generate a new config with secrets filled in
talosctl gen config rammus https://<node-ip>:6443 \
  --output-dir /tmp/talos-gen \
  --with-cluster-discovery=false \
  --with-docs=false \
  --with-examples=false

# Merge patches into the generated config
# (Patches are applied via talosctl apply-config --config-patch)
```

### Provision a new node

```bash
# 1. Boot node from Talos ISO
# 2. Apply machine config with patches
talosctl apply-config \
  --insecure \
  --nodes <node-ip> \
  --file talos/rammus/controlplane.yaml \
  --config-patch @talos/patches/network.yaml \
  --config-patch @talos/patches/tailscale.yaml \
  --config-patch @talos/patches/sops-age.yaml

# 3. Bootstrap k3s (Talos handles this automatically)
# 4. Bootstrap Flux
flux bootstrap github \
  --owner=nimser \
  --repository=homelab \
  --branch=main \
  --path=clusters/rammus
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
| `tailscale.yaml` | Tailscale extension for OS-level remote access |
| `sops-age.yaml` | SOPS Age key for Flux secret decryption |

## Network Configuration

| Setting | Value |
|---|---|
| Pod CIDR | `10.42.0.0/16` (k3s default) |
| Service CIDR | `10.43.0.0/16` (k3s default) |
| DNS Domain | `cluster.local` |
| Upstream DNS | `1.1.1.1`, `1.0.0.1`, `8.8.8.8` |
