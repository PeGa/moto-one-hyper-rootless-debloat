# shellcheck shell=bash
# SPDX-License-Identifier: MIT
# dbl-env.sh: debloat session helpers. Source it: `source tools/dbl-env.sh`. Implements AGENTS.md §0, §1.1, §1.4, §1.5, §2.5.
# Requires: bash >= 4, adb, jq; a device with USB debugging authorized.
# DBL_DIR (working dir for logs, lists, snapshots) defaults to ./debloat-log under the current directory and must live
# outside this repository: device data never goes into the clone. `snap` and `drift` expect to run from $DBL_DIR.
# Device side effects: read-only except dbl, rb (reboot), bgr/unbgr/netbl/rbucket/allr (appops, netpolicy, buckets, revokes).
# Device is pinned at source time when exactly one is attached; the serial is never written to disk.
# Device-verified (XT2027-1, 2026-11): lp, _rperm, snap, drift, crashes (parity with the pre-port versions on the real project).
# dbl and the policy helpers send the same device commands as the versions used on the device; new: log-writable guard,
# runtime permission flags in bgr. First-run paths verified on the device too (host writes only): baseline bootstrap, missing-baseline
# refusal, unwritable-log guard (nothing sent).
export LC_ALL=C
_dbl_repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
case ${DBL_DIR:-} in /*) ;; '') DBL_DIR=$PWD/debloat-log;; *) DBL_DIR=$PWD/$DBL_DIR;; esac
case "$DBL_DIR/" in "$_dbl_repo"/*)
  echo "dbl-env: DBL_DIR=$DBL_DIR is inside the repository clone ($_dbl_repo); device data must live outside it. cd elsewhere or set DBL_DIR." >&2
  return 1 2>/dev/null || exit 1;; esac
export DBL_DIR
mkdir -p "$DBL_DIR" || { echo "dbl-env: cannot create DBL_DIR=$DBL_DIR" >&2; return 1 2>/dev/null || exit 1; }
# _logok <file>: the log must be appendable before anything is sent to the device (never run a command unlogged)
_logok() { : >> "$DBL_DIR/$1" 2>/dev/null || { echo "dbl-env: cannot append to $DBL_DIR/$1; nothing sent to the device" >&2; return 1; }; }
if [ -z "$ANDROID_SERIAL" ]; then
  n=$(adb devices | awk 'NR>1 && $2=="device"' | wc -l)
  # shellcheck disable=SC2155  # adb devices' exit status is irrelevant here; $n already gated it
  [ "$n" = 1 ] && export ANDROID_SERIAL=$(adb devices | awk 'NR>1 && $2=="device"{print $1}') || echo "dbl-env: pin ANDROID_SERIAL ($n devices attached)" >&2
fi

lp() { adb shell -n pm list packages "$@" | sed 's/^package://' | tr -d '\r' | sort -u; }

# dbl <action> <pkg> <inverse|-> <reason> <device command and args...>
dbl() {
  local act=$1 pkg=$2 inv=$3 why=$4; shift 4
  _logok actions.jsonl || return 1
  local cmd out rc after
  cmd=$(printf '%q ' "$@")
  out=$(adb shell -n "$cmd" 2>&1); rc=$?
  if [ "$act" = strip_update ]; then
    after=$(adb shell -n "pm path $pkg; dumpsys package $pkg | grep -m1 versionCode=" 2>/dev/null | tr '\n' ' ')
  else
    after=$(adb shell -n dumpsys package "$pkg" 2>/dev/null | grep -m1 'User 0:')
  fi
  jq -nc --arg ts "$(date -u +%FT%TZ)" --arg a "$act" --arg p "$pkg" --arg c "$cmd" --arg o "$out" --arg i "$inv" --arg w "$why" --arg s "$after" --argjson rc "$rc" \
    '{ts:$ts,action:$a,pkg:$p,cmd:$c,rc:$rc,out:$o,inverse:(if $i=="-" then null else $i end),reason:$w,state_after:$s}' >> "$DBL_DIR/actions.jsonl"
  printf '%s\n' "$out"
}

# snap: raw snapshot + baseline-relative lists, inside $DBL_DIR whatever the current directory (AGENTS §1.1).
# First run only (no earlier snapshot, no actions.jsonl): this snapshot becomes the baseline, noted in notes.md.
# A missing baseline on a later run is refused: it can't be rebuilt from an already-changed device; re-baseline by hand.
snap() ( cd "$DBL_DIR" || exit 1
  # shellcheck disable=SC2155  # date can't fail meaningfully here
  local S=snapshots/$(date -u +%Y%m%dT%H%M%SZ) B=lists/baseline first=0
  [ -d snapshots ] || [ -s actions.jsonl ] || first=1
  mkdir -p "$S" lists
  adb shell -n getprop | tr -d '\r' > "$S/device.txt"
  lp --user 0 > "$S/present.txt"; lp -u --user 0 > "$S/all_u.txt"; lp -d --user 0 > "$S/disabled.txt"
  lp -s --user 0 > "$S/system.txt"; lp -3 --user 0 > "$S/thirdparty.txt"; lp --apex-only > "$S/apex.txt"
  adb shell -n pm list packages -f -u --user 0 | tr -d '\r' > "$S/raw_f_u.txt"
  adb shell -n dumpsys package | tr -d '\r' > "$S/dumpsys_package.txt"
  adb shell -n dumpsys role | tr -d '\r' > "$S/dumpsys_role.txt"
  adb shell -n cmd deviceidle whitelist | tr -d '\r' > "$S/deviceidle_whitelist.txt"
  awk '/^[A-Za-z]/{h=($0 ~ /^Hidden system packages:/)} !h && /^  Package \[/{p=$2; gsub(/[\[\]]/,"",p)} !h && /^    User 0:.*suspended=true/{print p}' "$S/dumpsys_package.txt" | sort -u > "$S/suspended.txt"
  comm -23 "$S/all_u.txt" "$S/present.txt" > "$S/gone.txt"
  if [ ! -d "$B" ]; then
    if [ $first = 1 ]; then mkdir -p "$B"; cp "$S"/{gone,disabled,suspended}.txt "$B"/
      printf '\n- %s baseline created from %s (first snapshot; lists/baseline is now the reference, don'"'"'t regenerate it).\n' "$(date -u +%FT%TZ)" "$S" >> notes.md
      echo "snap: baseline created from $S"
    else echo "snap: $DBL_DIR/$B is missing and this isn't the first run; it can't be rebuilt from the device. Snapshot kept in $S, lists not derived. Re-baseline by hand and say so in notes.md (AGENTS §1.1)." >&2; exit 1; fi
  fi
  comm -23 "$S/gone.txt" "$B/gone.txt" > lists/uninstalled.txt
  comm -23 "$S/disabled.txt" "$B/disabled.txt" > lists/disabled.txt
  comm -23 "$S/suspended.txt" "$B/suspended.txt" > lists/suspended.txt
  sort -u lists/disabled.txt lists/suspended.txt > lists/frozen.txt
  cp "$S/present.txt" lists/installed.txt
  grep -viE 'serial|imei|meid|iccid|imsi|mac|bt.*addr|bdaddr|ro\.boot\.cid|wifi.*addr' "$S/device.txt" > device.txt
  echo "$DBL_DIR/$S"
)

# rb: framework reboot (never `adb reboot` with unflushed state, §1.5)
rb() {
  adb shell -n svc power reboot; sleep 10; adb wait-for-device
  until [ "$(adb shell -n getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 2; done; sleep 15
  echo "boot: $(adb shell -n getprop sys.boot.reason.last | tr -d '\r') $(adb shell -n uptime | tr -d '\r')"
}
# drift: last soft_uninstall/restore per package decides expected state
drift() {
  comm -12 <(jq -r 'select(.action=="soft_uninstall" or .action=="restore") | [.pkg, .action, ((.out//"Success")|tostring)] | @tsv' "$DBL_DIR/actions.jsonl" \
             | awk -F'\t' '{if($2=="restore") s[$1]="restore"; else if($3 ~ /^Success/) s[$1]="gone"} END{for(p in s) if(s[p]=="gone") print p}' | sort -u) \
           <(lp --user 0) | grep . && echo "^^ DRIFT: logged removed but present" || echo "drift: none"
}
# crashes [since "YYYY-MM-DD HH:MM:SS"]: dropbox, one tag per call
crashes() { local m=${1:-0}; for t in system_app_crash data_app_crash system_app_anr data_app_anr SYSTEM_TOMBSTONE system_server_crash; do
  adb shell -n dumpsys dropbox --print $t 2>/dev/null | tr -d '\r' | grep -E '^20[0-9-]+ [0-9:]+ |^Process:|Caused by' | awk -v m="$m" '/^20/{s=($1" "$2>m)} s' | cut -c1-170; done; }
# load: CPU + RAM health
load() {
  adb shell -n 'echo "loadavg: $(cat /proc/loadavg)"; grep -E "MemAvailable|SwapFree" /proc/meminfo | tr -s " " | tr "\n" " "; echo' | tr -d '\r'
  adb shell -n 'top -b -n 2 -d 2 -m 6 -o %CPU,RES,NAME' | tr -d '\r' | awk '/%cpu/{n++} n==2' | head -8
  # am_kill "empty #N" / "empty for Ns" is ActivityManager housekeeping, not memory pressure; lmkd logs its kills as killinfo.
  # The events buffer spans hours; `dumpsys activity exit-info` (reason=3 LOW_MEMORY) keeps days.
  echo "lmkd kills in events buffer (since $(adb logcat -d -b events -v time | awk 'NR==2{print $1, substr($2,1,5)}')): $(adb logcat -d -b events | grep -c ' killinfo: ')"
}

# ---- background policy ----
_plog() { jq -nc --arg ts "$(date -u +%FT%TZ)" --arg p "$1" --arg k "$2" --arg n "$3" --argjson b "$4" --argjson a "$5" --arg c "$6" --arg i "$7" --arg o "$8" --arg w "$9" \
   '{ts:$ts,pkg:$p,kind:$k,name:$n,before:$b,after:$a,cmd:$c,inverse:$i,out:$o,src:"agent",reason:$w}' >> "$DBL_DIR/permissions.jsonl"; }
# _op prints the raw mode; "No operations." = unset (effective allow). Inverse of an unset op is `allow`, never `default` (AGENTS §1.4).
_op() { adb shell -n cmd appops get "$1" "$2" | tr -d '\r' | head -1 | sed 's/^No operations\.$/unset/;s/^[A-Z_]*: //;s/;.*//'; }
_inv() { [ "$1" = unset ] && echo allow || echo "$1"; }
_uid() { adb shell -n dumpsys package "$1" | tr -d '\r' | grep -m1 -oE 'userId=[0-9]+' | cut -d= -f2; }
# _rperm <pkg> <perm>: runtime permission state as {"granted":bool,"flags":[...]} (AGENTS §1.4, §2.2); empty if not requested
_rperm() { adb shell -n dumpsys package "$1" | tr -d '\r' \
  | awk '/^ +runtime permissions:/{match($0,/^ */); n=RLENGTH; f=1; next} f{match($0,/^ */); if (RLENGTH<=n) f=0; else print}' \
  | grep -m1 -E "^ *$2: granted=" | sed -E 's/^ *[^:]+: granted=(true|false), flags=\[(.*)\]$/\1\t\2/' \
  | awk -F'\t' '{n=split($2,a,/[ |]+/); s=""; for(i=1;i<=n;i++) if(a[i]!="") s=s (s?",":"") "\"" a[i] "\""; printf "{\"granted\":%s,\"flags\":[%s]}", $1, s}'; }
_nbl() { adb shell -n cmd netpolicy list restrict-background-blacklist | tr -d '\r' | grep -qw "$1" && echo true || echo false; }
bgr() { local p=$1 why="bg policy: $2" b a o u
  _logok permissions.jsonl || return 1
  for op in RUN_ANY_IN_BACKGROUND RUN_IN_BACKGROUND; do
    b=$(_op $p $op); o=$(adb shell -n cmd appops set $p $op ignore 2>&1 | tr -d '\r'); a=$(_op $p $op)
    _plog $p appop $op "{\"uid_mode\":null,\"pkg_mode\":\"$b\"}" "{\"uid_mode\":null,\"pkg_mode\":\"$a\"}" "cmd appops set $p $op ignore" "cmd appops set $p $op $(_inv $b)" "$o" "$why"; echo "  $op: $b -> $a"; done
  b=$(_rperm $p android.permission.ACCESS_BACKGROUND_LOCATION)
  if [[ $b == *'"granted":true'* ]]; then
    o=$(adb shell -n pm revoke --user 0 $p android.permission.ACCESS_BACKGROUND_LOCATION 2>&1 | tr -d '\r'); a=$(_rperm $p android.permission.ACCESS_BACKGROUND_LOCATION)
    _plog $p runtime android.permission.ACCESS_BACKGROUND_LOCATION "$b" "${a:-null}" "pm revoke --user 0 $p android.permission.ACCESS_BACKGROUND_LOCATION" "pm grant --user 0 $p android.permission.ACCESS_BACKGROUND_LOCATION" "$o" "$why"; echo "  BG_LOCATION revoked"; fi
  netbl $p "$2"; }
unbgr() { local p=$1 why="bg policy exception: $2" b a o u
  _logok permissions.jsonl || return 1
  for op in RUN_ANY_IN_BACKGROUND RUN_IN_BACKGROUND; do
    b=$(_op $p $op); o=$(adb shell -n cmd appops set $p $op allow 2>&1 | tr -d '\r'); a=$(_op $p $op)
    _plog $p appop $op "{\"uid_mode\":null,\"pkg_mode\":\"$b\"}" "{\"uid_mode\":null,\"pkg_mode\":\"$a\"}" "cmd appops set $p $op allow" "cmd appops set $p $op $b" "$o" "$why"; echo "  $op: $b -> $a"; done
  u=$(_uid $p); b=$(_nbl $u); o=$(adb shell -n cmd netpolicy remove restrict-background-blacklist $u 2>&1 | tr -d '\r'); a=$(_nbl $u)
  _plog $p other "netpolicy restrict-background-blacklist uid=$u" "{\"blacklisted\":$b}" "{\"blacklisted\":$a}" "cmd netpolicy remove restrict-background-blacklist $u" "cmd netpolicy add restrict-background-blacklist $u" "$o" "$why"; echo "  netbl uid=$u: $b -> $a"; }
netbl() { local p=$1 u b a o; _logok permissions.jsonl || return 1; u=$(_uid $p); b=$(_nbl $u); o=$(adb shell -n cmd netpolicy add restrict-background-blacklist $u 2>&1 | tr -d '\r'); a=$(_nbl $u)
  _plog $p other "netpolicy restrict-background-blacklist uid=$u" "{\"blacklisted\":$b}" "{\"blacklisted\":$a}" "cmd netpolicy add restrict-background-blacklist $u" "cmd netpolicy remove restrict-background-blacklist $u" "$o" "bg mobile data off (metered only): $2"; echo "  netbl uid=$u: $b -> $a"; }
rbucket() { local p=$1 b a o; _logok permissions.jsonl || return 1; b=$(adb shell -n am get-standby-bucket $p | tr -d '\r'); o=$(adb shell -n am set-standby-bucket $p restricted 2>&1 | tr -d '\r'); a=$(adb shell -n am get-standby-bucket $p | tr -d '\r')
  _plog $p standby bucket "{\"bucket\":\"$b\"}" "{\"bucket\":\"$a\"}" "am set-standby-bucket $p restricted" "am set-standby-bucket $p $b" "$o" "all-levels: $2"; echo "  bucket: $b -> $a"; }
allr() { local p=$1; [ "$(_op $p RUN_ANY_IN_BACKGROUND)" = ignore ] && [ "$(_nbl "$(_uid $p)")" = true ] && echo "  bgr: already" || bgr $p "$2"; rbucket $p "$2"; }
