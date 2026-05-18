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
#   TAILSCALE_TAILNET  - Your tailnet name (e.g., "example.com" or "ts-abc123")
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

TAILNET="${TAILSCALE_TAILNET:-}"
[ -z "${TAILNET}" ] && error "TAILSCALE_TAILNET not set (e.g., 'example.com' or 'ts-abc123')"

info "Fetching Tailscale machines for tailnet: ${TAILNET}"

# --- Authentication: OAuth only ---
# Try env vars first, then extract from SOPS
OAUTH_CLIENT_ID="${TAILSCALE_OAUTH_CLIENT_ID:-}"
OAUTH_CLIENT_SECRET="${TAILSCALE_OAUTH_CLIENT_SECRET:-}"

if [ -z "${OAUTH_CLIENT_ID}" ] || [ -z "${OAUTH_CLIENT_SECRET}" ]; then
  for oauth_file in \
    "${SCRIPT_DIR}/../infrastructure/configs/${CLUSTER_NAME}/tailscale-operator/oauth-credentials.sops.yaml" \
    "${SCRIPT_DIR}/../infrastructure/configs/rammus/tailscale-operator/oauth-credentials.sops.yaml"; do
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

ACCESS_TOKEN=$(echo "${token_response}" | yq -r '.access_token' 2>/dev/null)
[ -z "${ACCESS_TOKEN}" ] && error "OAuth response missing access_token"

info "Token acquired (expires in $(echo "${token_response}" | yq -r '.expires_in' 2>/dev/null)s)"

# --- Fetch machines ---
machines=$(curl -sf \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "https://api.tailscale.com/api/v2/tailnet/${TAILNET}/devices" \
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
    "https://api.tailscale.com/api/v2/tailnet/${TAILNET}/device/${device_id}" \
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
  local machines_json
  machines_json=$(echo "${machines}" | yq -o json "[.devices[] | select(.name | startswith(\"${prefix}\"))]" 2>/dev/null || echo "[]")

  local count
  count=$(echo "${machines_json}" | yq 'length' 2>/dev/null || echo "0")
  [ "${count}" -le 0 ] && info "  No machines matching ${prefix}*" && return
  [ "${count}" -eq 1 ] && info "  One machine: $(echo "${machines_json}" | yq -r '.[0].name') (keeping)" && return

  info "  Found ${count} machines matching ${prefix}*"

  local connected_id
  connected_id=$(echo "${machines_json}" | yq -r '[.devices[] | select(.connected == true) | .id] | .[0]' 2>/dev/null || true)
  [ -n "${connected_id}" ] && info "  Connected: $(echo "${machines_json}" | yq -r ".devices[] | select(.id == \"${connected_id}\") | .name") (keeping)"

  local stale
  stale=$(echo "${machines_json}" | yq -r '[.devices[] | select(.connected != true) | {id: .id, name: .name}]' 2>/dev/null || echo "[]")
  local stale_count
  stale_count=$(echo "${stale}" | yq 'length' 2>/dev/null || echo "0")
  [ "${stale_count}" -gt 0 ] && for i in $(seq 0 $((stale_count - 1))); do
    local sid sname
    sid=$(echo "${stale}" | yq -r ".[${i}].id")
    sname=$(echo "${stale}" | yq -r ".[${i}].name")
    [ -n "${sid}" ] && delete_machine "${sid}" "${sname}"
  done
}

info "Scanning for stale machines..."
process_machines "${CLUSTER_NAME}"
process_machines "soft-serve"
process_machines "tailscale-operator"
process_machines "talos-"
process_machines "${CLUSTER_NAME}-"

info "Cleanup complete. Deleted ${DELETED_COUNT} stale machines."