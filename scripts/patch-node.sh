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
for cmd in talosctl sops yq; do
  command -v "$cmd" >/dev/null 2>&1 || error "$cmd is required but not installed"
done

TALOS_FLAGS=("--context" "${CLUSTER_NAME}" "--endpoints" "${NODE_IP}" "--nodes" "${NODE_IP}")

info "Fetching live configuration from node..."
tmp_config=$(mktemp)
talosctl get machineconfig v1alpha1 -o yaml "${TALOS_FLAGS[@]}" | yq '.spec' > "$tmp_config"

# 1. Handle Tailscale Extension patch (it uses ExtensionServiceConfig)
info "Applying Tailscale patch securely..."
if ts_patch=$(sops -d "$(dirname "$0")/../talos/patches/tailscale.sops.yaml" 2>/dev/null); then
  # For Tailscale, it is applied as a separate YAML document or via `talosctl patch` directly.
  # Since it's a completely separate document (ExtensionServiceConfig), we can just use `talosctl patch` safely
  # but since we are refactoring for absolute security, we will apply it directly via a tmp file.
  ts_tmp=$(mktemp)
  echo "$ts_patch" > "$ts_tmp"
  # We use talosctl patch specifically for tailscale because it doesn't cause array duplicate issues
  talosctl patch machineconfig "${TALOS_FLAGS[@]}" --patch @"${ts_tmp}" >/dev/null
  shred -u "${ts_tmp}"
  info "Tailscale patch applied successfully"
else
  warn "Failed to decrypt tailscale.sops.yaml (or missing key)"
fi

# 2. Handle SOPS Age patch (idempotent array merge)
info "Applying SOPS Age patch securely..."
if age_patch=$(sops -d "$(dirname "$0")/../talos/patches/sops-age.sops.yaml" 2>/dev/null); then
  # Extract the raw secret manifest string
  export AGE_MANIFEST=$(echo "$age_patch" | yq '.cluster.inlineManifests[0].contents')
  
  # Check if the inlineManifest already exists
  if yq eval '.cluster.inlineManifests[].name' "$tmp_config" 2>/dev/null | grep -q "flux-sops-age"; then
    # It exists, so we safely UPDATE the contents without duplicating the array item
    yq eval -i '(select(documentIndex == 0) | .cluster.inlineManifests[] | select(.name == "flux-sops-age") | .contents) = strenv(AGE_MANIFEST)' "$tmp_config"
  else
    # It does not exist, so we safely APPEND it
    yq eval -i '(select(documentIndex == 0) | .cluster.inlineManifests) += [{"name": "flux-sops-age", "contents": strenv(AGE_MANIFEST)}]' "$tmp_config"
  fi
  
  # Apply the updated config back to the node
  talosctl apply-config "${TALOS_FLAGS[@]}" --file "$tmp_config" >/dev/null
  info "SOPS Age patch applied successfully"
else
  warn "Failed to decrypt sops-age.sops.yaml (or missing key)"
fi

# Clean up
shred -u "$tmp_config"
unset AGE_MANIFEST

info "Done! Node may restart some services."

