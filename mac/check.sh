#!/usr/bin/env bash
set -euo pipefail

DOMAINS=(
  chatgpt.com
  api.openai.com
  claude.ai
  gemini.google.com
  copilot.microsoft.com
  grok.com
  elevenlabs.io
)

HOSTS_FILE="/etc/hosts"

printf '%-24s %-16s %-16s\n' "Domain" "HostsEntry" "CurrentResolve"
printf '%-24s %-16s %-16s\n' "------" "----------" "--------------"

for domain in "${DOMAINS[@]}"; do
  hosts_entry="$(awk -v d="$domain" '$1 !~ /^#/ { for (i = 2; i <= NF; i++) if ($i == d) { print $1; exit } }' "$HOSTS_FILE")"
  current="$(dscacheutil -q host -a name "$domain" 2>/dev/null | awk '/ip_address:/ { print $2; exit }')"
  printf '%-24s %-16s %-16s\n' "$domain" "${hosts_entry:-missing}" "${current:-missing}"
done
