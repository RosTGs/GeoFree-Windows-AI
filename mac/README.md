# GeoFree Mac M1 package

[Пошаговая инструкция на русском](START_RU.md).

Portable macOS package for applying AI service hosts entries from GeoHideDNS.

It works on Apple Silicon Macs, including MacBook M1. No architecture-specific binary is used; the scripts are plain shell scripts.

## Quick start

Copy this folder to the Mac, open Terminal inside it, then run:

```bash
chmod +x *.sh *.command
sudo ./auto-geofree.sh
```

You can also run:

```bash
./run-geofree.command
```

The auto script downloads:

```text
https://raw.githubusercontent.com/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/hosts
```

Then it tries candidate IPs from that file and fallback IPs until one passes DNS and HTTPS checks.

## Manual IP

```bash
sudo ./apply-hosts.sh 80.74.24.165
./check.sh
```

## Remove GeoFree block

```bash
sudo ./uninstall.sh
```

## What changes

The scripts replace this marked block and existing lines containing target domains in `/etc/hosts`:

```text
# --- GEOFREE START ---
# --- GEOFREE END ---
```

Before every apply or uninstall operation, a backup is created next to `/etc/hosts`:

```text
/etc/hosts.backup.YYYYMMDD_HHMMSS
```

After changes, macOS DNS cache is flushed with:

```bash
dscacheutil -flushcache
killall -HUP mDNSResponder
```

Restart browsers and apps after applying.
