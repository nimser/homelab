#!/usr/bin/env bash
set -euo pipefail

# Provision a Talos node and bootstrap FluxCD for a cluster.
# Usage: ./scripts/provision-node.sh <cluster-name> <node-ip>
#
# Prerequisites:
#   - talosctl installed
#   - flux CLI installed
#   - gh CLI authenticated to GitHub
#   - Node booted from Talos ISO and reachable at <node-ip>

CLUSTER_NAME="${1:?Usage: $0 <cluster-name> <node-ip>}"
NODE_IP="${2:?Usage: $0 <cluster-name> <node-ip>}"

K8S_VERSION="v1.32.4"
TALOS_VERSION="v1.13.2"
REPO_OWNER="nimser"
REPO_NAME="homelab"
REPO_BRANCH="main"
CLUSTER_PATH="clusters/${CLUSTER_NAME}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

check_deps() {
  for cmd in talosctl flux gh kubectl; do
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

generate_config() {
  local tmpdir
  tmpdir=$(mktemp -d)
  info "Generating Talos machine config..."

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

  echo "${tmpdir}"
}

apply_config() {
  local config_dir="$1"
  local config_file="${config_dir}/controlplane.yaml"

  info "Preparing Talos patches..."
  local patch_flags=("--config-patch" "@$(dirname "$0")/../talos/patches/network.yaml")

  local ts_patch
  if ts_patch=$(sops -d "$(dirname "$0")/../talos/patches/tailscale.sops.yaml" 2>/dev/null); then
    local ts_tmp
    ts_tmp=$(mktemp)
    echo "$ts_patch" > "$ts_tmp"
    patch_flags+=("--config-patch" "@${ts_tmp}")
    info "Included Tailscale patch"
  else
    warn "Could not decrypt tailscale.sops.yaml. Ensure SOPS age key is available."
  fi

  local age_patch
  if age_patch=$(sops -d "$(dirname "$0")/../talos/patches/sops-age.sops.yaml" 2>/dev/null); then
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

  # Set privileged PodSecurity for local-path-provisioner
  kubectl label namespace local-path-storage \
    pod-security.kubernetes.io/enforce=privileged \
    pod-security.kubernetes.io/audit=privileged \
    pod-security.kubernetes.io/warn=privileged \
    --overwrite 2>/dev/null || true

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
  info "=== RustFS PVC ==="
  kubectl get pvc -n rustfs 2>/dev/null || warn "RustFS PVC not yet created (waiting for reconciliation)"
}

main() {
  check_deps
  wait_for_node

  local config_dir
  config_dir=$(generate_config)

  apply_config "${config_dir}"
  bootstrap_k8s "${config_dir}/talosconfig"
  bootstrap_flux
  show_status

  info "${CLUSTER_NAME} cluster provisioning complete!"
  info "Kubeconfig: /tmp/${CLUSTER_NAME}-kubeconfig"
  info "Talos config: ${config_dir}/talosconfig"
}

main "$@"
