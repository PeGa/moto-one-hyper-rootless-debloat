#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# bench.sh [--check]: scroll jank in Settings, cold-launch times (TotalTime ms), notification-shade and launcher-drawer jank.
# NOT read-only: launches and force-stops apps and injects swipes/keys, which also bumps their standby buckets.
# Swipe coordinates assume a 1080-wide screen at least 1950 tall (XT2027-1: 1080x2340); other sizes are refused.
# --check: only validate the screen size and exit (device-verified on XT2027-1, 2026-11). Requires: bash, adb; phone attached and unlocked.
# BENCH_LAUNCH: space-separated pkg=component pairs to cold-launch (default: Settings only).
a() { adb shell -n "$@" | tr -d '\r'; }
sz=$(a wm size | awk -F': ' '/Physical size/{p=$2} /Override size/{o=$2} END{print (o!="" ? o : p)}')
w=${sz%x*}; h=${sz#*x}
if [ "$w" != 1080 ] || [ "${h:-0}" -lt 1950 ] 2>/dev/null || [ -z "$h" ]; then echo "bench: screen is '${sz:-unknown}'; coordinates assume 1080x>=1950. Edit them first." >&2; exit 2; fi
[ "${1:-}" = --check ] && { echo "bench: screen $sz OK"; exit 0; }
jank() { # $1 pkg, $2 component
  a am start -S -W -n "$2" >/dev/null; sleep 2; a dumpsys gfxinfo "$1" reset >/dev/null
  for _ in 1 2 3 4 5 6; do a input swipe 540 1900 540 500 150; sleep 0.6; a input swipe 540 500 540 1900 150; sleep 0.6; done
  a dumpsys gfxinfo "$1" | grep -E "Total frames|Janky|90th percentile|99th percentile|High input|Slow UI" | grep -v gpu | tr -s ' ' | paste -sd'|'
}
launch() { local t=0 n=3 v; for _ in $(seq $n); do a am force-stop "$1"; sleep 1; v=$(a am start -W -n "$2" | awk '/TotalTime/{print $2}'); t=$((t+v)); a input keyevent HOME; sleep 1.5; done; echo "$1 cold avg: $((t/n)) ms"; a am force-stop "$1"; }
echo "settings scroll: $(jank com.android.settings com.android.settings/.Settings)"; a input keyevent HOME; sleep 1
for pc in ${BENCH_LAUNCH:-com.android.settings=com.android.settings/.Settings}; do launch "${pc%%=*}" "${pc#*=}"; done
# UI jank: notification shade (System UI) and app drawer (Moto launcher). adb-injected input inflates "high input latency": compare runs, not absolutes.
ui() { a dumpsys gfxinfo "$1" | grep -E 'Total frames|Janky|90th percentile|99th percentile|Slow UI|deadline' | grep -v gpu | tr -s ' ' | paste -sd'|'; }
a input keyevent HOME; sleep 1; a dumpsys gfxinfo com.android.systemui reset >/dev/null
for _ in 1 2 3 4 5 6; do a cmd statusbar expand-notifications; sleep 1; a cmd statusbar collapse; sleep 1; a input swipe 540 5 540 1400 250; sleep 1; a input keyevent BACK; sleep 1; done
echo "systemui shade: $(ui com.android.systemui)"
home=$(a cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1 | cut -d/ -f1)
a input keyevent HOME; sleep 1; a dumpsys gfxinfo "$home" reset >/dev/null
for _ in 1 2 3 4 5 6; do a input swipe 540 1900 540 600 200; sleep 1.2; a input keyevent BACK; sleep 1; done
echo "launcher drawer ($home): $(ui "$home")"; a input keyevent HOME
