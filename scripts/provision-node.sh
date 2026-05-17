#!/usr/bin/env bash
set -euo pipefail

# Provision a Talos node and bootstrap FluxCD for a cluster.
# Usage: ./scripts/provision-node.sh <cluster-name> <node-ip>
#
# Prerequisites:
#   - talosctl installed
#   - flux CLI installed
#   - gh CLI authenticated to GitHub
#   - sops installed (for talosconfig persistence)
#   - Node booted from Talos ISO and reachable at <node-ip>
#
# Config persistence:
#   On first provision, the generated talosconfig and machine config are
#   SOPS-encrypted and stored in clusters/<name>/. Subsequent provisions
#   reuse these configs, preserving the cluster CA and identity across
#   hardware swaps and cloud migrations.

CLUSTER_NAME="${1:?Usage: $0 <cluster-name> <node-ip>}"
NODE_IP="${2:?Usage: $0 <cluster-name> <node-ip>}"

K8S_VERSION="v1.32.4"
TALOS_VERSION="v1.13.2"
REPO_OWNER="nimser"
REPO_NAME="homelab"
REPO_BRANCH="main"
CLUSTER_PATH="clusters/${CLUSTER_NAME}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TALOS_DIR="${SCRIPT_DIR}/../talos/${CLUSTER_NAME}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

check_deps() {
  for cmd in talosctl flux gh kubectl sops; do
    command -v "$cmd" >/dev/null 2>&1 || error "$cmd is required but not installed"
  done
}

wait_for_node() {
  info "Waiting for Talos API at ${NODE_IP}:50000..."
  for i in $(seq 1 60); do
    if timeout 2 bash -c "echo > /dev/tcp/${NODE_IP}/50000" 2>/dev/null; then
      info "Node is reachable"
      return 0
    fi
    sleep 2
  done
  error "Node not reachable after 2 minutes"
}

load_or_generate_config() {
  local talosconfig_sops="${TALOS_DIR}/talosconfig.sops.yaml"
  local controlplane_sops="${TALOS_DIR}/controlplane.sops.yaml"
  local tmpdir
  tmpdir=$(mktemp -d)

  if [ -f "${talosconfig_sops}" ] && [ -f "${controlplane_sops}" ]; then
    info "Loading existing Talos config for ${CLUSTER_NAME}..."
    sops -d "${talosconfig_sops}" > "${tmpdir}/talosconfig"
    sops -d "${controlplane_sops}" > "${tmpdir}/controlplane.yaml"
    info "Reusing existing cluster identity (CA preserved)"
  else
    info "Generating new Talos machine config..."

    talosctl gen config "${CLUSTER_NAME}" "https://${NODE_IP}:6443" \
      --output-dir "${tmpdir}" \
      --with-cluster-discovery=false \
      --with-docs=false \
      --with-examples=false \
      --kubernetes-version "${K8S_VERSION}" \
      -f >/dev/null 2>&1

    # Remove fields not supported by this Talos version
    sed -i '/grubUseUKICmdline/d' "${tmpdir}/controlplane.yaml"
    # Remove the HostnameConfig document (not needed, hostname set via patch)
    sed -i '/^---$/,/^$/d' "${tmpdir}/controlplane.yaml"

    # Encrypt and persist configs for future reuse
    mkdir -p "${TALOS_DIR}"

    # Encrypt talosconfig as a Kubernetes Secret
    local talosconfig_secret_tmp
    talosconfig_secret_tmp=$(mktemp --suffix .yaml)
    cat > "${talosconfig_secret_tmp}" <<TCEOF
apiVersion: v1
kind: Secret
metadata:
  name: talosconfig
  namespace: flux-system
type: Opaque
stringData:
  talosconfig: |
$(sed 's/^/    /' "${tmpdir}/talosconfig")
TCEOF

    sops --encrypt --encrypted-regex '^(data|stringData)$' --input-type yaml --output-type yaml \
      "${talosconfig_secret_tmp}" > "${talosconfig_sops}"
    rm -f "${talosconfig_secret_tmp}"

    # Encrypt entire controlplane.yaml (contains CAs, secrets, tokens throughout)
    sops --encrypt --encrypted-regex '.*' --input-type yaml --output-type yaml \
      "${tmpdir}/controlplane.yaml" > "${controlplane_sops}"

    info "Encrypted configs saved to ${CLUSTER_DIR}/"
  fi

  # Inject hostname patch
  local hostname_patch
  hostname_patch=$(mktemp)
  cat > "$hostname_patch" <<EOF
machine:
  network:
    hostname: ${CLUSTER_NAME}
EOF

  echo "${tmpdir} ${hostname_patch}"
}

apply_config() {
  local config_dir="$1"
  local hostname_patch="$2"
  local config_file="${config_dir}/controlplane.yaml"

  info "Preparing Talos patches..."
  local patch_flags=(
    "--config-patch" "@${SCRIPT_DIR}/../talos/patches/network.yaml"
    "--config-patch" "@${SCRIPT_DIR}/../talos/patches/podsecurity.yaml"
    "--config-patch" "@${hostname_patch}"
  )

  local ts_patch
  if ts_patch=$(sops -d "${SCRIPT_DIR}/../talos/patches/tailscale.sops.yaml" 2>/dev/null); then
    local ts_tmp
    ts_tmp=$(mktemp)
    echo "$ts_patch" > "$ts_tmp"
    patch_flags+=("--config-patch" "@${ts_tmp}")
    info "Included Tailscale patch"
  else
    warn "Could not decrypt tailscale.sops.yaml. Ensure SOPS age key is available."
  fi

  local age_patch
  if age_patch=$(sops -d "${SCRIPT_DIR}/../talos/patches/sops-age.sops.yaml" 2>/dev/null); then
    local age_tmp
    age_tmp=$(mktemp)
    echo "$age_patch" > "$age_tmp"
    patch_flags+=("--config-patch" "@${age_tmp}")
    info "Included SOPS age key patch"
  else
    warn "Could not decrypt sops-age.sops.yaml. Ensure SOPS age key is available."
  fi

  info "Applying Talos configuration..."
  talosctl apply-config --insecure --nodes "${NODE_IP}" \
    --file "${config_file}" \
    "${patch_flags[@]}"

  info "Configuration applied, waiting for node to reboot..."
  sleep 30

  # Wait for Talos API to come back
  for i in $(seq 1 60); do
    if timeout 2 bash -c "echo > /dev/tcp/${NODE_IP}/50000" 2>/dev/null; then
      info "Node is back online"
      break
    fi
    sleep 2
  done
}

bootstrap_k8s() {
  local talosconfig="$1"

  # Set endpoints in talosconfig
  talosctl config endpoint --talosconfig "${talosconfig}" "${NODE_IP}" >/dev/null
  talosctl config node --talosconfig "${talosconfig}" "${NODE_IP}" >/dev/null

  info "Waiting for etcd to be ready..."
  for i in $(seq 1 60); do
    if talosctl --talosconfig "${talosconfig}" --nodes "${NODE_IP}" services 2>/dev/null | grep -q "etcd"; then
      info "etcd is healthy"
      break
    fi
    sleep 2
  done

  info "Bootstrapping Kubernetes..."
  talosctl --talosconfig "${talosconfig}" bootstrap 2>/dev/null || true

  info "Waiting for control plane to be ready..."
  sleep 30

  # Get kubeconfig
  local kubeconfig="/tmp/${CLUSTER_NAME}-kubeconfig"
  talosctl --talosconfig "${talosconfig}" kubeconfig "${kubeconfig}" --force >/dev/null
  export KUBECONFIG="${kubeconfig}"
  kubectl config rename-context "admin@${CLUSTER_NAME}" "${CLUSTER_NAME}" >/dev/null 2>&1 || true

  # Wait for node to be Ready
  for i in $(seq 1 60); do
    if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
      info "Node is Ready"
      kubectl get nodes -o wide
      break
    fi
    sleep 2
  done
}

bootstrap_flux() {
  export KUBECONFIG="/tmp/${CLUSTER_NAME}-kubeconfig"

  info "Bootstrapping FluxCD..."
  export GITHUB_TOKEN=$(gh auth token)
  flux bootstrap github \
    --owner="${REPO_OWNER}" \
    --repository="${REPO_NAME}" \
    --branch="${REPO_BRANCH}" \
    --path="${CLUSTER_PATH}" \
    --toleration-keys="node-role.kubernetes.io/control-plane" \
    --personal

  info "Waiting for Flux reconciliation..."
  sleep 30

  # Remove control-plane taint for single-node scheduling
  # Done after Flux bootstrap so the node state is completely stable
  local node_name
  node_name=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
  if [ -n "${node_name}" ]; then
    kubectl taint nodes "${node_name}" node-role.kubernetes.io/control-plane:NoSchedule- 2>/dev/null || true
    info "Removed control-plane taint from ${node_name}"
  fi

  info "Waiting for Flux controllers to stabilize..."
  sleep 30

  # Force reconciliation
  flux reconcile source git flux-system -n flux-system 2>/dev/null || true
  sleep 60

  # Verify all kustomizations are ready
  info "Verifying reconciliation..."
  for i in $(seq 1 30); do
    local not_ready
    not_ready=$(kubectl get kustomizations -A -o jsonpath='{range .items[?(@.status.conditions[0].status!="True")]}{.metadata.name}{"\n"}{end}' 2>/dev/null | grep -v '^$' || true)
    if [ -z "${not_ready}" ]; then
      info "All kustomizations reconciled successfully"
      break
    fi
    warn "Waiting for: ${not_ready}"
    sleep 10
  done

  info "Flux reconciliation complete"
}

show_status() {
  export KUBECONFIG="/tmp/${CLUSTER_NAME}-kubeconfig"

  echo ""
  info "=== Cluster Status ==="
  kubectl get nodes -o wide
  echo ""
  info "=== Flux Kustomizations ==="
  kubectl get kustomizations -A
  echo ""
  info "=== All Pods ==="
  kubectl get pods -A
  echo ""
  info "=== PVCs ==="
  kubectl get pvc -A 2>/dev/null || warn "No PVCs found"
}

main() {
  check_deps
  wait_for_node

  local config_result
  config_result=$(load_or_generate_config)
  local config_dir hostname_patch
  config_dir=$(echo "$config_result" | awk '{print $1}')
  hostname_patch=$(echo "$config_result" | awk '{print $2}')

  apply_config "${config_dir}" "${hostname_patch}"
  bootstrap_k8s "${config_dir}/talosconfig"
  bootstrap_flux
  show_status

  # Merge talosconfig into ~/.talos/config for easy access
  # Replaces stale context for this cluster, preserves other contexts (e.g. karma)
  mkdir -p ~/.talos
  touch ~/.talos/config
  chmod 600 ~/.talos/config
  talosctl config merge "${config_dir}/talosconfig" >/dev/null 2>&1
  talosctl config endpoint "${NODE_IP}" >/dev/null 2>&1
  talosctl config node "${NODE_IP}" >/dev/null 2>&1
  info "Merged talosconfig into ~/.talos/config"

  info "${CLUSTER_NAME} cluster provisioning complete!"
  info "Kubeconfig: /tmp/${CLUSTER_NAME}-kubeconfig"
  info "Talos config: ${config_dir}/talosconfig"
}

main "$@"
