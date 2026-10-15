#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
chmod +x ./*.sh
sudo ./auto-geofree.sh

printf '\nDone. Press Enter to close this window.'
read -r _
