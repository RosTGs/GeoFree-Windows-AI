#!/usr/bin/env bash
set -euo pipefail

SOURCE_URL="${SOURCE_URL:-https://raw.githubusercontent.com/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/hosts}"
FALLBACK_IPS="${FALLBACK_IPS:-80.74.24.165}"

TARGET_DOMAINS=(
  chatgpt.com
  api.openai.com
  auth.openai.com
  platform.openai.com
  claude.ai
  api.claude.ai
  gemini.google.com
  copilot.microsoft.com
  grok.com
  elevenlabs.io
)

PROBE_URLS=(
  https://chatgpt.com/
  https://api.openai.com/v1/models
  https://claude.ai/
  https://gemini.google.com/
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo /bin/bash "$0" "$@"
  fi
}

flush_dns() {
  dscacheutil -flushcache 2>/dev/null || true
  killall -HUP mDNSResponder 2>/dev/null || true
}

resolved_ip() {
  dscacheutil -q host -a name "$1" 2>/dev/null | awk '/ip_address:/ { print $2; exit }'
}

https_ok() {
  local url="$1" code
  code="$(curl -L -sS -o /dev/null --connect-timeout 8 --max-time 15 -w '%{http_code}' "$url" 2>/dev/null || true)"
  [[ "$code" != "000" && -n "$code" ]]
}

candidate_passes() {
  local ip="$1" resolved ok_count=0 url
  flush_dns
  sleep 2

  resolved="$(resolved_ip chatgpt.com || true)"
  log "DNS chatgpt.com -> ${resolved:-missing}"
  [[ "$resolved" == "$ip" ]] || return 1

  for url in "${PROBE_URLS[@]}"; do
    if https_ok "$url"; then
      log "  $url -> ok"
      ok_count=$((ok_count + 1))
    else
      log "  $url -> failed"
    fi
  done

  [[ "$ok_count" -eq "${#PROBE_URLS[@]}" ]]
}

require_root "$@"

TMP_SOURCE="$(mktemp)"
trap 'rm -f "$TMP_SOURCE"' EXIT

log "Downloading hosts source:"
log "$SOURCE_URL"
curl -fsSL --connect-timeout 15 --max-time 45 "$SOURCE_URL" -o "$TMP_SOURCE"

CANDIDATES=()

add_candidate() {
  local ip="$1" existing
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 0
  [[ "$ip" == "0.0.0.0" || "$ip" == "127.0.0.1" ]] && return 0
  for existing in "${CANDIDATES[@]:-}"; do
    [[ "$existing" == "$ip" ]] && return 0
  done
  CANDIDATES+=("$ip")
}

for domain in "${TARGET_DOMAINS[@]}"; do
  while read -r ip host _; do
    [[ "${host:-}" == "$domain" ]] && add_candidate "$ip"
  done < "$TMP_SOURCE"
done

for ip in $FALLBACK_IPS; do
  add_candidate "$ip"
done

[[ "${#CANDIDATES[@]}" -gt 0 ]] || die "No candidate IPs found."

log "Candidate IPs: ${CANDIDATES[*]}"

for ip in "${CANDIDATES[@]}"; do
  log ""
  log "Trying $ip ..."
  /bin/bash "$SCRIPT_DIR/apply-hosts.sh" "$ip"

  if candidate_passes "$ip"; then
    log ""
    log "GeoFree is working with $ip"
    exit 0
  fi
done

die "No candidate passed. The last candidate remains applied in /etc/hosts."
