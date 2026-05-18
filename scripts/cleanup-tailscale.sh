#!/usr/bin/env bash
set -euo pipefail

# Clean up stale Tailscale machines for a cluster before reprovisioning.
# Authentication is via OAuth: credentials are extracted from SOPS-encrypted
# config and used to generate a short-lived API token.
#
# Usage: ./scripts/cleanup-tailscale.sh <cluster-name>
#
# Required OAuth scopes: devices:write (to delete machines)
#
# Environment:
#   TAILSCALE_OAUTH_CLIENT_ID     - OAuth client ID (or auto-extracted from SOPS)
#   TAILSCALE_OAUTH_CLIENT_SECRET - OAuth client secret (or auto-extracted from SOPS)

CLUSTER_NAME="${1:?Usage: $0 <cluster-name>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

info "Fetching Tailscale machines for tailnet"

# --- Authentication: OAuth only ---
# Try env vars first, then extract from SOPS
OAUTH_CLIENT_ID="${TAILSCALE_OAUTH_CLIENT_ID:-}"
OAUTH_CLIENT_SECRET="${TAILSCALE_OAUTH_CLIENT_SECRET:-}"

if [ -z "${OAUTH_CLIENT_ID}" ] || [ -z "${OAUTH_CLIENT_SECRET}" ]; then
  for oauth_file in \
    "${SCRIPT_DIR}/../infrastructure/configs/${CLUSTER_NAME}/tailscale-operator/oauth-credentials.sops.yaml" \
    "${SCRIPT_DIR}/../infrastructure/configs/${CLUSTER_NAME}/tailscale-operator/oauth-credentials.yaml" \
    "${SCRIPT_DIR}/../infrastructure/configs/rammus/tailscale-operator/oauth-credentials.sops.yaml" \
    "${SCRIPT_DIR}/../infrastructure/configs/rammus/tailscale-operator/oauth-credentials.yaml"; do
    if [ -f "${oauth_file}" ] && creds=$(sops -d "${oauth_file}" 2>/dev/null); then
      OAUTH_CLIENT_ID=$(echo "${creds}" | yq -r '.stringData.client_id' 2>/dev/null)
      OAUTH_CLIENT_SECRET=$(echo "${creds}" | yq -r '.stringData.client_secret' 2>/dev/null)
      [ -n "${OAUTH_CLIENT_ID}" ] && [ -n "${OAUTH_CLIENT_SECRET}" ] && break
    fi
    OAUTH_CLIENT_ID=""
    OAUTH_CLIENT_SECRET=""
  done
fi

[ -z "${OAUTH_CLIENT_ID}" ] || [ -z "${OAUTH_CLIENT_SECRET}" ] && \
  error "OAuth credentials not found. Set TAILSCALE_OAUTH_CLIENT_ID and TAILSCALE_OAUTH_CLIENT_SECRET, or ensure SOPS files exist."

info "Generating API token from OAuth credentials"
token_response=$(curl -sf -X POST "https://api.tailscale.com/api/v2/oauth/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=${OAUTH_CLIENT_ID}" \
  -d "client_secret=${OAUTH_CLIENT_SECRET}" 2>/dev/null) || \
  error "Failed to get OAuth token"

ACCESS_TOKEN=$(echo "${token_response}" | jq -r '.access_token' 2>/dev/null)
[ -z "${ACCESS_TOKEN}" ] || [ "${ACCESS_TOKEN}" = "null" ] && error "OAuth response missing access_token"

info "Token acquired (expires in $(echo "${token_response}" | jq -r '.expires_in' 2>/dev/null)s)"

# --- Fetch machines ---
# We use the special "-" shorthand for the tailnet name, which automatically
# uses the tailnet associated with the OAuth credentials.
machines=$(curl -sf \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "https://api.tailscale.com/api/v2/tailnet/-/devices" \
  -H "Content-Type: application/json") || error "Failed to fetch machines"

DELETED_COUNT=0

delete_machine() {
  local device_id="$1"
  local name="$2"

  info "Deleting stale machine: ${name} (${device_id})"
  local http_code
  http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
    -X DELETE \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    "https://api.tailscale.com/api/v2/device/${device_id}" \
    -H "Content-Type: application/json" 2>/dev/null || true)

  if [ "${http_code}" = "200" ]; then
    info "  -> Deleted"
    DELETED_COUNT=$((DELETED_COUNT + 1))
  else
    warn "  -> Failed (HTTP ${http_code})"
  fi
}

process_machines() {
  local prefix="$1"
  local filtered_devices
  
  # Filter devices that start with prefix
  filtered_devices=$(echo "${machines}" | jq -c "[.devices[] | select(.name | startswith(\"${prefix}\"))]" 2>/dev/null || echo "[]")

  local count
  count=$(echo "${filtered_devices}" | jq 'length' 2>/dev/null || echo "0")
  [ "${count}" -le 0 ] && info "  No machines matching ${prefix}*" && return
  [ "${count}" -eq 1 ] && info "  One machine: $(echo "${filtered_devices}" | jq -r '.[0].name') (keeping)" && return

  info "  Found ${count} machines matching ${prefix}*"

  local connected_id
  connected_id=$(echo "${filtered_devices}" | jq -r '[.[] | select(.connected == true) | .id] | .[0]' 2>/dev/null)
  [ "${connected_id}" = "null" ] && connected_id=""

  if [ -n "${connected_id}" ]; then
    info "  Connected: $(echo "${filtered_devices}" | jq -r ".[] | select(.id == \"${connected_id}\") | .name") (keeping)"
  fi

  local stale_ids
  stale_ids=$(echo "${filtered_devices}" | jq -r ".[] | select(.connected != true) | .id" 2>/dev/null)
  
  for sid in $stale_ids; do
    [ -z "${sid}" ] && continue
    [ "${sid}" = "${connected_id}" ] && continue
    local sname
    sname=$(echo "${filtered_devices}" | jq -r ".[] | select(.id == \"${sid}\") | .name")
    delete_machine "${sid}" "${sname}"
  done
}

info "Scanning for stale machines..."
process_machines "${CLUSTER_NAME}"
process_machines "soft-serve"
process_machines "tailscale-operator"
process_machines "talos-"
process_machines "${CLUSTER_NAME}-"

info "Cleanup complete. Deleted ${DELETED_COUNT} stale machines."