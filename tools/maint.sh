#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# maint.sh [--apply] [--sf]: periodic re-apply of the logged background policy (AGENTS.md §1.4, "restrictions erode").
# Default is a dry run: it reads the device and reports what it would fix. --apply writes (and logs every fix).
# Refuses to run without $DBL_DIR/permissions.jsonl: the policy comes from your own log, never from someone else's.
# Requires: bash >= 4, adb, jq; phone attached and unlocked. DBL_DIR as in dbl-env.sh.
# Device-verified (XT2027-1, 2026-11, read-only): the dry run matches the pre-port version line for line; logs untouched.
# Desired state = the last logged `after` per package in permissions.jsonl, so nothing here needs hand-keeping:
#   - RUN_ANY_IN_BACKGROUND / RUN_IN_BACKGROUND: re-set if the current mode differs
#   - netpolicy restrict-background-blacklist: re-add/remove if the uid's membership differs
#   - full AOT compile: packages whose last logged `cmd package compile` was `-m speed` get recompiled if an update reset them
#   - standby bucket: back to 45 (restricted) for packages whose last logged bucket is 45 (use bumps them to 10),
#     except lists/keep_running.txt
#   - main log buffer: 16M (runtime only; a reboot resets it to 256K)
#   A logged `default` mode is treated as unset: maint never writes `default` (AGENTS §1.4).
# Report only: lists/keep_running.txt packages that are stopped (never force-stops or unfreezes anything), drift, crashes.
# --sf: also scrape SuperFreezZ's main screen (written against SuperFreezZ 1.1; phone unlocked; drives the UI ~20 s,
#   even in a dry run) and compare each app's mode
#   with lists/sf_modes.tsv (unlisted = always). Report only. SF_DUMP=<file> saves the scraped label/mode table.
# With --apply, every fix is logged to permissions.jsonl / actions.jsonl (reason "maint").
# (no set -u: dbl-env.sh tests unset vars)
source "$(dirname "${BASH_SOURCE[0]}")/dbl-env.sh" || exit 2
DRY=1; SF=0
for a in "$@"; do case $a in --apply) DRY=0;; -n|--dry-run) DRY=1;; --sf) SF=1;; *) echo "usage: maint.sh [--apply] [--sf]" >&2; exit 1;; esac; done
L=$DBL_DIR/permissions.jsonl
[ -s "$L" ] || { echo "maint: no policy log at $L (set DBL_DIR to your debloat working dir)" >&2; exit 2; }
[ $DRY = 1 ] && echo "maint: dry run (pass --apply to write)"
adb get-state >/dev/null 2>&1 || { echo "maint: no device" >&2; exit 1; }
present=$(lp --user 0)
inst() { grep -qx "$1" <<<"$present"; }
# alive <value>...: abort the run if adb dropped or a device read came back empty (never log a command that didn't run, AGENTS §3.4)
alive() { local v; for v in "$@"; do [ -n "$v" ] || { echo "maint: empty device read, stopping" >&2; exit 2; }; done
  [ "$(adb get-state 2>/dev/null)" = device ] || { echo "maint: device lost, stopping (state re-read on next run)" >&2; exit 2; }; }
fixes=0

echo "== appops (RUN_ANY / RUN_IN_BACKGROUND)"
while IFS=$'\t' read -r p op want; do
  inst "$p" || continue
  case "$want" in "No operations."|default|*": default") want="unset";; esac   # never write `default` back (AGENTS §1.4)
  cur=$(_op "$p" "$op"); alive "$cur"; [ "$cur" = default ] && cur="unset"
  [ "$cur" = "$want" ] && continue
  set_to=$want; [ "$want" = unset ] && set_to=allow       # allow returns the op to "No operations." (AGENTS §1.4)
  echo "  $p $op: $cur -> $want"; fixes=$((fixes+1)); [ $DRY = 1 ] && continue
  o=$(adb shell -n cmd appops set "$p" "$op" "$set_to" 2>&1 | tr -d '\r'); a=$(_op "$p" "$op")
  _plog "$p" appop "$op" "{\"uid_mode\":null,\"pkg_mode\":\"$cur\"}" "{\"uid_mode\":null,\"pkg_mode\":\"$a\"}" \
    "cmd appops set $p $op $set_to" "cmd appops set $p $op $(_inv "$cur")" "$o" "maint: re-apply logged policy"
done < <(jq -r 'select(.kind=="appop" and (.name=="RUN_ANY_IN_BACKGROUND" or .name=="RUN_IN_BACKGROUND")) | [.pkg,.name,.after.pkg_mode] | @tsv' "$L" \
         | awk -F'\t' '{k=$1"\t"$2; l[k]=$3} END{for(k in l) print k"\t"l[k]}' | sort)

echo "== netpolicy background mobile data"
alive "$present"
bl=" $(adb shell -n cmd netpolicy list restrict-background-blacklist | tr -d '\r' | sed 's/.*://') "
while IFS=$'\t' read -r p want; do
  inst "$p" || continue
  u=$(_uid "$p"); alive "$u"; case "$bl" in *" $u "*) cur=true;; *) cur=false;; esac
  [ "$cur" = "$want" ] && continue
  verb=add; inv=remove; [ "$want" = false ] && { verb=remove; inv=add; }
  echo "  $p uid=$u blacklisted: $cur -> $want"; fixes=$((fixes+1)); [ $DRY = 1 ] && continue
  o=$(adb shell -n cmd netpolicy $verb restrict-background-blacklist "$u" 2>&1 | tr -d '\r'); a=$(_nbl "$u")
  _plog "$p" other "netpolicy restrict-background-blacklist uid=$u" "{\"blacklisted\":$cur}" "{\"blacklisted\":$a}" \
    "cmd netpolicy $verb restrict-background-blacklist $u" "cmd netpolicy $inv restrict-background-blacklist $u" "$o" "maint: re-apply logged policy"
done < <(jq -r 'select(.kind=="other" and (.name|startswith("netpolicy restrict-background-blacklist"))) | [.pkg,(.after.blacklisted|tostring)] | @tsv' "$L" \
         | awk -F'\t' '{l[$1]=$2} END{for(p in l) print p"\t"l[p]}' | sort)

echo "== standby bucket (restricted = 45)"
buckets=$(adb shell -n am get-standby-bucket | tr -d '\r')
keep=$( [ -f "$DBL_DIR/lists/keep_running.txt" ] && cat "$DBL_DIR/lists/keep_running.txt" )
while read -r p; do
  inst "$p" || continue
  grep -qx "$p" <<<"$keep" && continue                    # exceptions keep whatever bucket use gives them (e.g. Google dialer)
  cur=$(awk -v p="$p:" '$1==p{print $2}' <<<"$buckets"); [ -z "$cur" ] && cur=$(adb shell -n am get-standby-bucket "$p" | tr -d '\r')
  alive "$cur"; [ "$cur" -ge 45 ] 2>/dev/null && continue
  echo "  $p bucket: $cur -> 45"; fixes=$((fixes+1)); [ $DRY = 1 ] && continue
  o=$(adb shell -n am set-standby-bucket "$p" restricted 2>&1 | tr -d '\r'); a=$(adb shell -n am get-standby-bucket "$p" | tr -d '\r')
  _plog "$p" standby bucket "{\"bucket\":\"$cur\"}" "{\"bucket\":\"$a\"}" "am set-standby-bucket $p restricted" "am set-standby-bucket $p $cur" "$o" "maint: re-apply logged policy"
done < <(jq -r 'select(.kind=="standby") | [.pkg,.after.bucket] | @tsv' "$L" | awk -F'\t' '{l[$1]=$2} END{for(p in l) if(l[p]=="45") print p}' | sort)

echo "== full AOT compile (speed) kept after app updates"
dx=$(adb shell -n dumpsys package dexopt | tr -d '\r' | awk '/^  \[/{p=$1; gsub(/[\[\]]/,"",p); f=1; next} f&&/status=/{match($0,/status=[a-z-]+/); print p, substr($0,RSTART+7,RLENGTH-7); f=0}')
while read -r p; do
  inst "$p" || continue
  cur=$(awk -v p="$p" '$1==p{print $2; exit}' <<<"$dx"); alive "$cur"
  [ "$cur" = speed ] && continue
  echo "  $p dexopt: $cur -> speed"; fixes=$((fixes+1)); [ $DRY = 1 ] && continue
  o=$(adb shell -n cmd package compile -m speed -f "$p" 2>&1 | tr -d '\r' | tail -1)
  jq -nc --arg ts "$(date -u +%FT%TZ)" --arg p "$p" --arg o "$o" --arg b "$cur" '{ts:$ts,action:"other",pkg:$p,cmd:("cmd package compile -m speed -f "+$p),rc:0,out:$o,inverse:("cmd package compile -m speed-profile -f "+$p),reason:("maint: re-apply full AOT compile (was "+$b+", likely app update)"),state_after:null}' >> "$DBL_DIR/actions.jsonl"
done < <(jq -r 'select((.cmd // "")|test("^cmd package compile -m (speed|speed-profile) -f ")) | [.pkg, (.cmd|capture("-m (?<m>[a-z-]+) ").m)] | @tsv' "$DBL_DIR/actions.jsonl" \
         | awk -F'\t' '{l[$1]=$2} END{for(p in l) if(l[p]=="speed") print p}' | sort)
# app updates recompile to speed-profile; a logged `compile -m speed-profile -f` (the inverse) opts a package out

echo "== main log buffer (16M keeps ~3.5 h; runtime only, a reboot resets it to 256K)"
lb=$(adb logcat -b main -g 2>/dev/null | tr -d '\r' | grep -oE 'ring buffer is [0-9]+ [KM]' | awk '{print $4 $5}'); alive "$lb"
if [ "$lb" != 16M ]; then
  echo "  main: $lb -> 16M"; fixes=$((fixes+1))
  if [ $DRY = 0 ]; then
    o=$(adb logcat -b main -G 16M 2>&1 | tr -d '\r')
    jq -nc --arg ts "$(date -u +%FT%TZ)" --arg o "$o" --arg b "$lb" '{ts:$ts,action:"other",pkg:"logd",cmd:"logcat -b main -G 16M",rc:0,out:$o,inverse:("logcat -b main -G "+$b),reason:"maint: re-apply main log buffer size (reset by reboot)",state_after:"main 16M"}' >> "$DBL_DIR/actions.jsonl"
  fi
fi

echo "== keep-running apps that are stopped (open them; SuperFreezZ: Never freeze)"
dp=$(adb shell -n dumpsys package packages | tr -d '\r' | awk '/^  Package \[/{p=$2; gsub(/[\[\]]/,"",p)} /^    User 0:.*stopped=true/{n=($0 ~ /notLaunched=true/)?" (never launched)":""; print p n}')
while read -r p; do grep -E "^$p( |$)" <<<"$dp" | sed 's/^/  /'; done <<<"$keep"

if [ $SF = 1 ]; then
  echo "== SuperFreezZ modes vs lists/sf_modes.tsv"
  if [ "$(adb shell -n dumpsys window | tr -d '\r' | grep -o 'isKeyguardShowing=[a-z]*' | head -1)" != isKeyguardShowing=false ]; then
    echo "  skipped: phone locked"
  else
    adb shell -n am start --activity-clear-task -n superfreeze.tool.android/.userInterface.mainActivity.MainActivity >/dev/null; sleep 2
    raw=""; prev=""
    for _ in $(seq 1 40); do       # status text per row: Freeze off = never, Frozen/Pending Freeze = always, F-Droid app = intelligent (exempt)
      cur=$(adb shell -n 'uiautomator dump /data/local/tmp/sf.xml >/dev/null 2>&1; cat /data/local/tmp/sf.xml' | tr -d '\r' \
        | grep -oE 'text="[^"]*" resource-id="superfreeze.tool.android:id/(txtAppName|txtExplanation|textView)"' \
        | sed -E 's/text="([^"]*)" resource-id="superfreeze.tool.android:id\/([a-zA-Z]*)"/\2\t\1/')
      [ "$cur" = "$prev" ] && break; raw+=$'SCREEN\t\n'$cur$'\n'; prev=$cur   # a row cut at the top edge has no name: never pair across screens
      adb shell -n input swipe 540 1900 540 900 1500; sleep 0.6   # slow drag: no fling, rows overlap between screens
    done
    adb shell -n input keyevent HOME
    obs=$(awk -F'\t' '$1=="textView"{sec=$2} $1=="txtAppName"{n=$2} $1=="textView"||$1=="SCREEN"{n=""} $1=="txtExplanation" && sec=="ALL APPS" && n!=""{
            m=($2=="Freeze off")?"never":($2=="Frozen"||$2=="Pending Freeze")?"always":($2=="F-Droid app")?"intelligent":"?"$2; print n"\t"m; n=""}' <<<"$raw" | sort -u \
          | awk -F'\t' '{a[$1]=a[$1]?a[$1]","$2:$2} END{for(k in a) print k"\t"a[k]}' | sort)
    [ -n "${SF_DUMP:-}" ] && printf "%s\n" "$obs" > "$SF_DUMP"
    [ -z "$obs" ] && { echo "  scrape failed (no rows)"; } || {
      echo "  apps seen: $(grep -c . <<<"$obs")"
      exp=$( [ -f "$DBL_DIR/lists/sf_modes.tsv" ] && grep -v '^#' "$DBL_DIR/lists/sf_modes.tsv" )
      while IFS=$'\t' read -r n m; do
        e=$(awk -F'\t' -v n="$n" '$1==n{print $2}' <<<"$exp"); [ -z "$e" ] && e=always
        [ "$(tr , '\n' <<<"$m" | sort | paste -sd,)" = "$(tr , '\n' <<<"$e" | sort | paste -sd,)" ] || echo "  MISMATCH $n: is $m, expected $e"
      done <<<"$obs"
      while IFS=$'\t' read -r n e; do grep -qP "^\Q$n\E\t" <<<"$obs" || echo "  missing from SuperFreezZ list: $n (expected $e)"; done <<<"$exp"
    }
  fi
fi

echo "== drift"; drift | sed 's/^/  /'
echo "== crashes this boot"
boot=$(adb shell -n 'date -d @$(( $(date +%s) - $(cut -d. -f1 /proc/uptime) )) "+%Y-%m-%d %H:%M:%S"' | tr -d '\r')
crashes "$boot" | sed 's/^/  /'
echo "== $( [ $DRY = 1 ] && echo "would fix" || echo fixed ): $fixes"
