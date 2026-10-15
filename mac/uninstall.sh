#!/usr/bin/env bash
set -euo pipefail

HOSTS_FILE="/etc/hosts"
START_MARKER="# --- GEOFREE START ---"
END_MARKER="# --- GEOFREE END ---"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

if [[ "$(id -u)" -ne 0 ]]; then
  die "Run with sudo: sudo ./uninstall.sh"
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${HOSTS_FILE}.backup.${STAMP}"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

cp -p "$HOSTS_FILE" "$BACKUP_FILE"

awk -v start="$START_MARKER" -v end="$END_MARKER" '
  $0 == start { skip = 1; next }
  $0 == end { skip = 0; next }
  !skip { print }
' "$HOSTS_FILE" > "$TMP_FILE"

cat "$TMP_FILE" > "$HOSTS_FILE"
dscacheutil -flushcache 2>/dev/null || true
killall -HUP mDNSResponder 2>/dev/null || true

printf 'Removed GeoFree block.\n'
printf 'Backup: %s\n' "$BACKUP_FILE"
