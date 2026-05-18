# Talos Machine Configs

Declarative Talos Linux machine configs for the homelab clusters.

Talos runs **standard Kubernetes** (not k3s) as system containers managed by the Talos API.

## Structure

```
talos/
├── patches/
│   ├── network.yaml          # Shared: DNS, NTP
│   ├── podsecurity.yaml      # Cluster-wide privileged PodSecurity admission (matches k3s behavior)
│   └── sops-age.sops.yaml    # SOPS/Age key for Flux secret decryption (SOPS-encrypted)
└── README.md
```

Base configs are generated dynamically by `scripts/provision-node.sh` using `talosctl gen config` and patched with the files above.

## Reset and Reprovision

To wipe a node and prepare it for reprovisioning (destroys all data and reboots):

```bash
# After provisioning, the talosconfig is automatically merged into ~/.talos/config
# No need to pass --talosconfig for subsequent commands
talosctl --nodes <node-ip> reset --graceful=false --reboot
```

After reset, boot from Talos ISO and run `provision-node.sh` again. The script will generate fresh CAs, encrypt the new configs, and update `~/.talos/config`.

## Persistent USB for Remote Reprovisioning

If you leave the Talos USB plugged in, you can reprovision remotely without physical access. However, **boot order matters**:

- **BIOS set to disk first** → Normal reboots boot into the installed Talos OS. USB is ignored unless disk fails.
- **BIOS set to USB first** → Every reboot (including `talosctl reboot`) boots into the ISO, not the installed OS.

**Recommended setup:** Set BIOS boot order to **disk first**, keep USB plugged in as fallback. To reprovision remotely:

1. Run `talosctl reset --graceful=false --reboot` — this wipes the disk and reboots
2. Since disk is now empty, BIOS falls through to USB and boots the ISO
3. Run `provision-node.sh` to reinstall

If your BIOS is set to USB first, a normal `talosctl reboot` will boot back into the ISO. To boot into the installed OS instead, you must either change the BIOS boot order (via IPMI/BMC if available) or remove the USB.

## Manual Provision

```bash
# Generate a new config with secrets filled in
talosctl gen config <cluster-name> https://<node-ip>:6443 \
  --output-dir /tmp/talos-gen \
  --with-cluster-discovery=false \
  --with-docs=false \
  --with-examples=false \
  --kubernetes-version v1.32.4

# Apply machine config with patches (network + hostname + optional secrets)
talosctl apply-config \
  --insecure \
  --nodes <node-ip> \
  --file /tmp/talos-gen/controlplane.yaml \
  --config-patch @talos/patches/network.yaml \
  --config-patch @<(cat <<EOF
machine:
  network:
    hostname: <cluster-name>
EOF
)

# Bootstrap Kubernetes
talosctl bootstrap

# Get kubeconfig
talosctl kubeconfig /tmp/<cluster-name>-kubeconfig
kubectx <cluster-name>=admin@<cluster-name>

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

## Managing Multiple Clusters

After provisioning, each cluster's context is automatically merged into `~/.talos/config`. Switch between clusters using `talosctl config context`:

```bash
talosctl config context rammus
talosctl config context karma
```

To easily switch between the `rammus` and `karma` Kubernetes clusters, you can use `kubectx`.

Since the kubeconfigs are generated dynamically in `/tmp` and reset when your environment is rebuilt, we recommend managing the `KUBECONFIG` path in a local `.envrc` file (which is ignored by git).

Create or edit your `.envrc` file at the root of the project to look like this:

```bash
export KUBECONFIG=/tmp/rammus-kubeconfig:/tmp/karma-kubeconfig
```

## Recovering Cluster Access (Lost Kubeconfig)

If you lose your local dev environment, you do not need to reprovision the cluster. You can recover access using the SOPS-encrypted `talosconfig` backed up in this repository.

```bash
# 1. Decrypt the cluster's talosconfig using your SOPS Age key
sops -d clusters/karma/talosconfig.sops.yaml > /tmp/talosconfig

# 2. Fetch a fresh kubeconfig from the node
talosctl --talosconfig /tmp/talosconfig kubeconfig /tmp/karma-kubeconfig --nodes <node-ip>

# 3. Rename the context for easier switching
kubectx karma=admin@karma
```

## Patches

| Patch                 | Purpose                                                                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `network.yaml`        | DNS servers (1.1.1.1, 1.0.0.1, 8.8.8.8), NTP (time.cloudflare.com)                                                                         |
| `podsecurity.yaml`    | Cluster-wide PodSecurity admission set to `privileged` — matches k3s behavior, no per-namespace labels needed                              |
| `sops-age.sops.yaml`  | SOPS Age key for Flux secret decryption                                                                                                    |

## Network Configuration

| Setting      | Value                           |
| ------------ | ------------------------------- |
| Kubernetes   | Standard k8s v1.32.4 (NOT k3s)  |
| Pod CIDR     | `10.42.0.0/16`                  |
| Service CIDR | `10.43.0.0/16`                  |
| DNS Domain   | `cluster.local`                 |
| Upstream DNS | `1.1.1.1`, `1.0.0.1`, `8.8.8.8` |

## Known Issues

- **Tolerations required**: Single-node clusters need `node-role.kubernetes.io/control-plane` tolerations on all workloads. The Flux tolerations patch is in `clusters/karma/flux-system/patches/controller-tolerations.yaml`.

## Tailscale Configuration

### Stable Machine Names and IPs

When reprovisioning a cluster, Tailscale machines can multiply (old entries persist). To prevent this:

1. **Automatic cleanup**: `provision-node.sh` runs `cleanup-tailscale.sh` before provisioning to remove stale machines with matching names.
2. **Consistent hostnames**: The `TS_HOSTNAME` environment variable is injected during provisioning, ensuring machines always register with the cluster name (e.g., `rammus`, `karma`).
3. **Stable DNS via MagicDNS**: Tailscale IPs change on reprovision. Use MagicDNS names instead of IPs for stable DNS bindings:
   - Talos nodes: `<cluster-name>.<tailnet>.ts.net` (e.g., `rammus.example.ts.net`)
   - Soft-serve service: `soft-serve.<tailnet>.ts.net`
   - Find your tailnet name at https://login.tailscale.com/admin/dns

### Required Environment Variables

No environment variables are strictly required to be exported for `provision-node.sh` to run the Tailscale cleanup.

Cleanup authentication uses **OAuth only** — credentials are automatically extracted
from `infrastructure/configs/<cluster>/tailscale-operator/oauth-credentials.sops.yaml`
and used to generate a short-lived API token. No manual API key management needed.

The OAuth client requires these scopes:
- **Devices > Devices write** — to list and delete machines
- **Auth Keys > Auth Keys write** — to generate auth keys (used by the operator)

Create the OAuth client at: https://login.tailscale.com/admin/settings/keys
Select scopes: `devices:write`, `auth_keys:write`. Tag it with `tag:k8s-operator`.

### Manual Cleanup

```bash
./scripts/cleanup-tailscale.sh <cluster-name>
```
