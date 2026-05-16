#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:?Usage: $0 <cluster-name> <node-ip>}"
NODE_IP="${2:?Usage: $0 <cluster-name> <node-ip>}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# Check dependencies
for cmd in talosctl sops; do
  command -v "$cmd" >/dev/null 2>&1 || error "$cmd is required but not installed"
done

# Try to decrypt Tailscale patch
info "Applying Tailscale patch..."
if ts_patch=$(sops -d "$(dirname "$0")/../talos/patches/tailscale.sops.yaml" 2>/dev/null); then
  ts_tmp=$(mktemp)
  echo "$ts_patch" > "$ts_tmp"
  talosctl patch machineconfig --context "${CLUSTER_NAME}" --nodes "${NODE_IP}" --patch @"${ts_tmp}"
  rm -f "${ts_tmp}"
  info "Tailscale patch applied successfully"
else
  warn "Failed to decrypt tailscale.sops.yaml (or missing key)"
fi

# Try to decrypt SOPS age patch
info "Applying SOPS Age patch..."
if age_patch=$(sops -d "$(dirname "$0")/../talos/patches/sops-age.sops.yaml" 2>/dev/null); then
  age_tmp=$(mktemp)
  echo "$age_patch" > "$age_tmp"
  talosctl patch machineconfig --context "${CLUSTER_NAME}" --nodes "${NODE_IP}" --patch @"${age_tmp}"
  rm -f "${age_tmp}"
  info "SOPS Age patch applied successfully"
else
  warn "Failed to decrypt sops-age.sops.yaml (or missing key)"
fi

info "Done! Node may restart some services."
