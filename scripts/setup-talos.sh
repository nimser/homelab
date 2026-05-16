#!/usr/bin/env bash
set -euo pipefail

# This script recovers the talosconfigs from the SOPS encrypted files
# and merges them into the local dev environment.

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

command -v sops >/dev/null 2>&1 || error "sops is required"
command -v yq >/dev/null 2>&1 || error "yq is required"

# Check for SOPS Age key
if [ -z "${SOPS_AGE_KEY:-}" ] && [ ! -f ~/.config/sops/age/keys.txt ]; then
  error "SOPS Age key not found!\n\nPlease provide your Age private key either by:\n1. Setting the SOPS_AGE_KEY environment variable\n2. Creating the file: ~/.config/sops/age/keys.txt"
fi

mkdir -p ~/.talos
touch ~/.talos/config
chmod 600 ~/.talos/config

found=0
for config_file in clusters/*/talosconfig.sops.yaml; do
  if [ -f "$config_file" ]; then
    cluster=$(basename "$(dirname "$config_file")")
    info "Recovering ${cluster} talosconfig..."
    
    tmp_config=$(mktemp)
    sops -d "$config_file" | yq '.stringData.talosconfig' > "$tmp_config"
    
    talosctl config merge "$tmp_config"
    rm -f "$tmp_config"
    
    info "Merged ${cluster} context"
    found=$((found+1))
  fi
done

if [ $found -eq 0 ]; then
  error "No talosconfig.sops.yaml files found in clusters/*/"
else
  info "Successfully merged $found talosconfig(s) into ~/.talos/config"
fi
