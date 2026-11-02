#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# build-hosts.sh [--push]: merge hosts blocklists into one file for NetGuard's hosts filtering, apply local allow/block lists.
# Sources as of 2026-10 (URLs move: HaGeZi dropped its hosts folder once). Downloads them with curl.
# Output: $DBL_DIR/hosts/hosts_merged.txt (DBL_DIR as in dbl-env.sh, outside this repository).
# allow.txt / block.txt there: one domain per line. --push copies the result to /sdcard/Download/ on the device.
set -euo pipefail
export LC_ALL=C
R=$(cd "$(dirname "$0")/.." && pwd)
case ${DBL_DIR:-} in /*) ;; '') DBL_DIR=$PWD/debloat-log;; *) DBL_DIR=$PWD/$DBL_DIR;; esac
case "$DBL_DIR/" in "$R"/*) echo "build-hosts: DBL_DIR=$DBL_DIR is inside the repository clone; cd elsewhere or set DBL_DIR." >&2; exit 1;; esac
D=$DBL_DIR/hosts; mkdir -p "$D/src"
declare -A SRC=(
  [adaway]="https://adaway.org/hosts.txt"
  [stevenblack]="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  [peterlowe]="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
  [hagezi_light]="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/light-onlydomains.txt"
)
for k in "${!SRC[@]}"; do curl -fsSL --max-time 60 -o "$D/src/$k.txt" "${SRC[$k]}"; printf '%-12s %8s lines\n' "$k" "$(wc -l < "$D/src/$k.txt")"; done
norm() { sed 's/\r//; s/#.*//' "$@" | awk 'NF>=2 && ($1=="0.0.0.0"||$1=="127.0.0.1"){for(i=2;i<=NF;i++)print tolower($i); next} NF==1 && $1 ~ /^[A-Za-z0-9._-]+\.[A-Za-z]{2,}$/{print tolower($1)}' \
         | { grep -vxE 'localhost|localhost\.localdomain|local|broadcasthost|0\.0\.0\.0|ip6-.*' || true; } ; }
touch "$D/allow.txt" "$D/block.txt"
plain() { sed 's/\r//; s/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' "$1" | { grep -v '^$' || true; } | tr 'A-Z' 'a-z' | sort -u; }
{ norm "$D"/src/*.txt; plain "$D/block.txt"; } | sort -u | comm -23 - <(plain "$D/allow.txt") > "$D/.domains"
{ echo "# NetGuard hosts: AdAway + StevenBlack + Peter Lowe + HaGeZi Light, merged $(date -u +%FT%TZ)"; echo "# allow: $(plain "$D/allow.txt" | wc -l)  extra block: $(plain "$D/block.txt" | wc -l)"
  echo "127.0.0.1 localhost"; sed 's/^/127.0.0.1 /' "$D/.domains"; } > "$D/hosts_merged.txt"
rm -f "$D/.domains"
echo "merged: $(($(wc -l < "$D/hosts_merged.txt")-3)) domains -> $D/hosts_merged.txt ($(du -h "$D/hosts_merged.txt" | cut -f1))"
if [ "${1:-}" = --push ]; then adb push "$D/hosts_merged.txt" /sdcard/Download/hosts_merged.txt | tail -1; fi
