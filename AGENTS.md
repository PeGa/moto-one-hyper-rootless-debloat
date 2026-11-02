<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# AGENTS.md — Smartphone Debloat Practices

> **Public edition (2026-11).** The working contract used for the rootless debloat of a Motorola One Hyper (XT2027-1, `RPFS31.Q1-21-20-10`, Android 11) documented in this repository. It is written for an AI coding agent operating a phone over ADB from a host shell, and for the person supervising it. Copy it into your working directory and adapt it: the practices are generic, while `[observed]` facts hold for this build only. Section numbers are stable; the docs link to them.

Scope: debloating a personal Android phone over ADB, from a host shell. Target OS: **Android 11 (API 30)**. See §3 for version-specific notes.

**Nature of this file:** a toolbox, not a rulebook. Everything below is a default or an option. If you see a better path for the situation in front of you, take it, and log what you did and why. Nothing here forbids anything that's not explicitly listed as an antipattern. Antipatterns live in §1.3 (`pm hide`, with a user-requested exception) and §4 (git).

You start with no package lists, no device config, no prior state. Build them from the device itself.

**Pin the device first.** `export ANDROID_SERIAL=<serial>` (or use `adb -s <serial>` everywhere). With USB and wireless both attached, an unpinned `adb` fails mid-batch with "more than one device".

---

## 0. Working directory & log layout (default)

`DBL_DIR` defaults to `./debloat-log/`. Override freely.

```
$DBL_DIR/
├── device.txt              # copy of the newest snapshot's device.txt, identifier props filtered out (see §4)
├── snapshots/
│   └── <UTC-ts>/           # raw state at a point in time: device.txt, package lists, dumpsys dumps
│                           # evidence, not the rollback source; can be multi-MB per snapshot
├── lists/
│   ├── baseline/           # name lists from the baseline snapshot (gone, disabled, suspended); committed, see 1.1
│   ├── installed.txt       # present for user 0
│   ├── uninstalled.txt     # removed since baseline (baseline-relative, see 1.1)
│   ├── disabled.txt        # disabled since baseline (inverse: pm enable)
│   ├── suspended.txt       # suspended since baseline (inverse: pm unsuspend)
│   ├── frozen.txt          # union of disabled.txt + suspended.txt, convenience view
│   ├── hidden.txt          # hidden on explicit user request only (inverse: pm unhide), see 1.3
│   ├── no_factory_copy.txt # removed preloads with no factory copy: install-existing can't restore them, see 1.2
│   ├── keep_running.txt    # packages exempt from periodic bucket re-application, see 1.4
│   └── sf_modes.tsv        # expected freezer mode per app label, if a freezer app is used (1.3)
├── actions.jsonl           # append-only: every state-changing command
├── permissions.jsonl       # append-only: every permission / appop / standby / idle alteration
└── notes.md                # free-form: reasoning, breakage, oddities
```

Lists: one package name per line, `sort -u`, no decoration. Diff them with `comm`. Sort and compare under `LC_ALL=C`: the baseline is compared against for weeks, possibly from another shell or locale, and a collation mismatch makes `comm` wrong.

---

## 1. Practices

### 1.1 Baseline snapshot (before the first change, and after any batch)

The first snapshot is the **baseline**. Everything the factory image shipped as uninstalled or disabled is part of it, so the lists below are defined relative to it. History from before the baseline can't be reconstructed from the device.

Raw state, timestamped under `snapshots/<ts>/`. Name lists are built **without** `-f`:

```bash
export LC_ALL=C
S=snapshots/$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$S"
lp() { adb shell -n pm list packages "$@" | sed 's/^package://' | tr -d '\r' | sort -u; }

adb shell -n getprop                         > "$S/device.txt"
lp --user 0                                  > "$S/present.txt"
lp -u --user 0                               > "$S/all_u.txt"        # includes uninstalled-for-user
lp -d --user 0                               > "$S/disabled.txt"     # DISABLED, DISABLED_USER, DISABLED_UNTIL_USED
lp -s --user 0                               > "$S/system.txt"
lp -3 --user 0                               > "$S/thirdparty.txt"
lp --apex-only                               > "$S/apex.txt"
adb shell -n pm list packages -f -u --user 0 > "$S/raw_f_u.txt"      # raw dump only; never split it on '='
adb shell -n dumpsys package                 > "$S/dumpsys_package.txt"
adb shell -n dumpsys role                    > "$S/dumpsys_role.txt"
adb shell -n cmd deviceidle whitelist        > "$S/deviceidle_whitelist.txt"
# suspended packages (pm list has no suspended filter on Android 11). Sketch; verify the dumpsys format on-device.
# Skips the "Hidden system packages:" section (original records of updated system apps), which has its own Package [ headers:
awk '/^[A-Za-z]/{h=($0 ~ /^Hidden system packages:/)}
     !h && /^  Package \[/{p=$2; gsub(/[\[\]]/,"",p)}
     !h && /^    User 0:.*suspended=true/{print p}' \
    "$S/dumpsys_package.txt" | sort -u       > "$S/suspended.txt"
```

Per package, when you touch it: `cmd appops get <pkg>`, `dumpsys package <pkg>`, `am get-standby-bucket <pkg>`.

Why not split `-f` output on `=`: on Android 11, `/data/app` paths look like `~~<b64>==/<pkg>-<b64>==/base.apk`, so they contain `=`. If you must extract names from `-f` output, `sed 's/.*=//'` keeps what follows the last `=`.

Derived lists. `$S` is the current snapshot dir; `$B` holds the baseline name lists:

```bash
export LC_ALL=C
comm -23 "$S/all_u.txt" "$S/present.txt" > "$S/gone.txt"    # not installed for user 0 right now, per snapshot

# once, right after the baseline snapshot: persist its name lists (small; committed, unlike snapshots/)
#   mkdir -p lists/baseline && cp "$S"/{gone,disabled,suspended}.txt lists/baseline/
B=lists/baseline

# uninstalled = gone now, minus gone at baseline (factory-uninstalled variants/overlays excluded)
comm -23 "$S/gone.txt"      "$B/gone.txt"      > lists/uninstalled.txt
# disabled / suspended since baseline (factory-disabled excluded); kept apart because the inverses differ
comm -23 "$S/disabled.txt"  "$B/disabled.txt"  > lists/disabled.txt
comm -23 "$S/suspended.txt" "$B/suspended.txt" > lists/suspended.txt
sort -u lists/disabled.txt lists/suspended.txt > lists/frozen.txt
cp "$S/present.txt" lists/installed.txt
```

`lists/baseline/` is the one thing the baseline-relative lists can't be rebuilt without: the factory's uninstalled/disabled state isn't recoverable from the device once you've changed it. Keep it, commit it, don't regenerate it. If you deliberately re-baseline (e.g. after a factory reset), say so in `notes.md`.

Cross-check `uninstalled.txt` and `frozen.txt` against `actions.jsonl`. Anything in the list but not in the log was changed by something else (user, OTA, another package); note it.

Fingerprint changes between snapshots' `device.txt` (`ro.build.fingerprint`) are how an OTA is detected (see §3.5).

### 1.2 Soft uninstall (default removal method)

```bash
adb shell pm uninstall -k --user 0 <pkg>
```

- `-k` keeps data/cache; `--user 0` removes only for the primary user. The APK stays on the system partition.
- Reversible without root: `adb shell pm install-existing --user 0 <pkg>` (or `cmd package install-existing`).
- Also reverts on factory reset.
- Expect `Success`. Anything else (`DELETE_FAILED_*`, exceptions): log it, don't assume state, re-query `pm list packages`.
- If the package is an updated system app, `install-existing` brings back the **updated** version, since a `--user 0` removal keeps the update (see §3.1).
- **[observed]** Preloads that setup/Play installed into `/data/app` with **no factory copy** (no entry under `Hidden system packages:` and a codePath under `/data/app`) lose their APK on a `--user 0` removal, even with `-k`. The package record stays (still listed by `-u`), but `install-existing` has nothing to restore. Check codePath before removing; record such names in `lists/no_factory_copy.txt` so they can be refetched elsewhere.

### 1.3 Freezing (softer than removal)

Options, from lightest to heaviest:

| Method | Command | Undo |
|---|---|---|
| suspend | `pm suspend --user 0 <pkg>` | `pm unsuspend --user 0 <pkg>` |
| disable-user | `pm disable-user --user 0 <pkg>` | `pm enable --user 0 <pkg>` |
| soft uninstall | see 1.2 | `pm install-existing` |

Separate lever, not a package state: **stopped** (`am force-stop <pkg>`; undo: the user opens the app). **[observed]** It survives a framework reboot and blocks boot-time spawns until the app is opened again. `BOOT_COMPLETED` is only delivered after the first unlock, so run boot-spawn checks after unlocking. It isn't covered by the lists: read `stopped=` on the `User 0:` line. A freezer app (e.g. SuperFreezZ) can re-apply it after use.

**`pm hide` is an antipattern for the agent.** It adds no capability over `disable-user` or a soft uninstall, and it creates a state the method can't see straight: a hidden package drops out of the plain `pm list packages` output but stays installed (`hidden=true` on its `User 0:` line; **[observed]** the field is present on this build), so the baseline-relative lists count it as uninstalled and the list rollback replays `pm install-existing` instead of its real inverse, `pm unhide`. It hides exactly the evidence the logs exist to keep. Use it only when the user explicitly asks; then log it as `"action":"hide"` with inverse `pm unhide --user 0 <pkg>`, track it in its own `lists/hidden.txt`, and keep those packages out of `uninstalled.txt`.

Frozen = anything in the first two states. They're tracked as `lists/disabled.txt` and `lists/suspended.txt` (inverses differ), with `lists/frozen.txt` as their union. Some OEM builds refuse `disable-user` on certain packages; fall back to another row.

**Method ladder (default order):** soft uninstall → `disable-user` only if the uninstall is refused → appops/standby/idle restriction (1.4) only if both are refused. **[observed]** Refusal messages and what they block:

| Message | Uninstall `--user 0` | `disable-user` |
|---|---|---|
| `DELETE_FAILED_DEVICE_POLICY_MANAGER` | refused | allowed |
| `Failure: package is non-disable` | refused | refused |
| `Failure: package is protected` / `Cannot disable a protected package` | refused | refused |

**[observed]** `pm disable --user 0 <pkg>/<component>` fails from shell for system and user apps alike (`SecurityException: Shell cannot change component state`), so per-component freezes need root. Likewise `cmd notification disallow_listener` works, but an OEM default listener can be re-granted at boot.

Suspend notes:
- Suspensions are tracked per suspending package. `pm suspend` suspends as `com.android.shell`, and `pm unsuspend` from shell only removes shell's own suspension. A package suspended by something else (e.g. a wellbeing or parental-control app) stays suspended. Record the suspender when `dumpsys` shows it.
- Suspend blocks user interaction only. Services, receivers and jobs may keep running. As a battery or privacy freeze it is cosmetic unless combined with `RUN_ANY_IN_BACKGROUND ignore` (see 1.4).

### 1.4 Permission / appop alteration

Capture **before** state, apply, capture **after**, log both plus the inverse. "State" means everything you'd need to restore:

| Kind | Capture | Apply | Inverse |
|---|---|---|---|
| runtime permission | `granted` and `flags=[...]` from `dumpsys package <pkg>` | `pm revoke --user 0 <pkg> <perm>` | `pm grant --user 0 <pkg> <perm>`; re-read flags afterwards and log if they differ |
| appop | `cmd appops get <pkg>`: both the `Uid mode:` lines and the package entries | `cmd appops set --user 0 <pkg> <OP> <mode>` | `cmd appops set --user 0 <pkg> <OP> <before_mode>` (same `--uid` form if you changed uid mode) |
| standby bucket | `am get-standby-bucket <pkg>` | `am set-standby-bucket <pkg> restricted` | `am set-standby-bucket <pkg> <before_bucket>` |
| doze whitelist | `cmd deviceidle whitelist` (list) | `cmd deviceidle whitelist -<pkg>` | `cmd deviceidle whitelist +<pkg>` |
| doze system whitelist | `cmd deviceidle sys-whitelist` (list) | `cmd deviceidle sys-whitelist -<pkg>` | `cmd deviceidle sys-whitelist +<pkg>` |

Notes:
- Appops have uid-level and package-level modes. A package-mode `set` doesn't override a restrictive uid mode. Check both.
- `RUN_ANY_IN_BACKGROUND` is the real "Background restriction" toggle. `RUN_IN_BACKGROUND` only affects legacy apps (targetSdk below 26); treat it as redundant on modern apps.
- The system re-evaluates standby buckets as the app is used, so `restricted` may not stick. Re-read it after the batch.
- `deviceidle whitelist -<pkg>` fails for entries from the OS's own allowlist (sysconfig). That's expected, not a failure; use the `sys-whitelist` row. Re-check system-whitelist removals after a reboot. **[observed]** The removal of the `system` entry survived reboots; `system-excidle` stays. Losing the allowlist also drops the exemption from the background-service start limit, so an app whose boot receiver calls `startService()` will crash with `IllegalStateException: Not allowed to start service` once per boot.
- Use mode `ignore`, not `deny`, for `RUN_ANY_IN_BACKGROUND`/`RUN_IN_BACKGROUND`: `ignore` is silent, while `deny` surfaces as exceptions in the app.
- **[observed]** To undo a `RUN_ANY_IN_BACKGROUND`/`RUN_IN_BACKGROUND` change when the before state was unset (`No operations.`), set `allow`, **not** `default`. `default` stores MODE_DEFAULT explicitly, and the foreground-service check treats anything but MODE_ALLOWED as restricted (`Service.startForeground() not allowed due to bg restriction`). `allow` returns the op to `No operations.`.
- **[observed]** Anything that must start a foreground service on a system event (incoming-call UI, alarms, navigation projected to a car) can't take `RUN_ANY_IN_BACKGROUND ignore`: Android 11 refuses `startForeground()` unless the app is on top. Keep those apps out of the background restriction.
- **[observed]** Restrictions erode. Using an app moves it out of `restricted` (to 10, then normal decay); the Settings toggle App info → Battery → Background restriction clears `RUN_ANY_IN_BACKGROUND`; app updates reset AOT compilation. Re-apply periodically, taking the desired state from the last logged `after` per package (the maintenance script, `maint.sh`).
- **[observed]** `am set-standby-bucket <pkg> restricted` lands on 40 (RARE) unless `settings global enable_restricted_bucket` is `1`. With it set, 45 persists across reboots. PERSISTENT apps stay at 10, and role holders may be bumped back up by the system.
- Background network has no rootless per-app switch for Wi-Fi. `cmd netpolicy add restrict-background-blacklist <uid>` (inverse: `remove`) covers metered networks only. Wi-Fi needs a VPN-slot firewall (e.g. NetGuard). Rootless, there is one VPN slot. **[observed]** Always-on lockdown made the VPN firewall see the network as disconnected; Android Auto refuses to start when its own traffic goes through a VPN; a VPN app that isn't direct-boot aware can't start before the first unlock, so earlier traffic bypasses it. Details: `docs/02-restrictions-and-network.md`, `docs/03-android-auto-and-forensics.md`.
- Non-revocable (fixed/system) permissions reject `pm revoke`; try the appop route instead.

**Destructive commands** (no single-step inverse; snapshot the full state first and say so in `reason`):

```bash
adb shell pm reset-permissions                    # all runtime permissions, all packages: no inverse
adb shell cmd appops reset --user 0 <pkg>         # every op on the package, not just the one you changed
```

Before `pm reset-permissions`, save grant + flags for every package (from `dumpsys package`) so there is something to restore from.

Read state, runtime permissions only (cut by indentation, since the section doesn't necessarily end on a blank line):

```bash
adb shell -n dumpsys package <pkg> | awk '/^ +runtime permissions:/{match($0,/^ */); n=RLENGTH; f=1; next} f{match($0,/^ */); if (RLENGTH<=n) f=0; else print}'
adb shell -n cmd appops get <pkg>
```

### 1.5 Pre-removal sanity checks (optional but cheap)

- Roles: `dumpsys role` for the full holder map (e.g. `android.app.role.HOME`, `.DIALER`, `.SMS`, `.BROWSER`, `.ASSISTANT`). **[observed]** Android 11's `cmd role` only has `add-role-holder`, `remove-role-holder` and `clear-role-holders` (`[--user N] ROLE [PKG]`); there's no `get-role-holders` and no `list`. Read holders from `dumpsys role`. Don't remove the current holder of a role without a replacement in place.
- **[observed]** Replacing DIALER/SMS: check the replacement's flags in `dumpsys package <pkg>`. One that is only `PARTIALLY_DIRECT_BOOT_AWARE` can't show incoming calls before the first unlock after a reboot; Telecom falls back to the system dialer, so keep the stock dialer installed, restricted but with background execution allowed (1.4).
- **[observed]** Recents/overview is served by the stock launcher's Quickstep component (`dumpsys activity service com.android.systemui` → `recentsComponentName`). A third-party HOME can't provide it, so keep the stock launcher installed (restricted) when replacing HOME. Re-check the HOME role after any launcher install or restore.
- IME and WebView are not roles: `settings get secure default_input_method`, `settings get secure enabled_input_methods`, `dumpsys webviewupdate`.
- `pm path <pkg>`, `dumpsys package <pkg>`: look at what the package provides (shared UID, providers, services others bind to). **[observed]** Side effects with no visible link: removing `com.android.printspooler` hung Settings → Connection preferences (the screen queries pending print jobs); removing the OEM ambient-display app (`com.motorola.motodisplay`) disabled double-tap-to-wake (it puts the touch controller in gesture mode).
- `pm resolve-activity` needs a real intent, e.g. `pm resolve-activity --brief -a android.intent.action.VIEW -d https://example.com`. A bare package name does nothing.
- Shared UID packages share fate; check `sharedUser` in `dumpsys package`.
- The OEM's OTA/updater client is a special case: removing or freezing it blocks system updates. Make that a deliberate decision and write it in `notes.md`.
- Small batches. After each batch: re-snapshot, reboot, then check before the next batch:
  - **Reboot via the framework:** `adb shell svc power reboot` (or the power menu). **[observed]** `adb reboot` sets `sys.powerctl` directly and skips the framework shutdown. Per-user package state changed since the last framework shutdown (uninstall, disable-user, suspend) was lost and the packages came back. Once a framework shutdown has flushed it, `adb reboot` is harmless.
  - **Drift:** packages whose last logged action is a successful removal but which are present again.
  - **Crashes:** read `dumpsys dropbox` (it persists across reboots) rather than only `logcat -b crash` (RAM, wiped on reboot; crashes after a short check window are missed). **[observed]** `dumpsys dropbox --print` takes one tag per call (`system_app_crash`, `data_app_crash`, `system_app_anr`, `data_app_anr`, `SYSTEM_TOMBSTONE`, `system_server_crash`); several tags in one call print nothing. **[observed]** The logd main buffer is 256K by default (minutes of history); `logcat -b main -G 16M` is runtime-only (a reboot resets it) and `persist.logd.size.main` can't be set from shell.
  - **Load:** loadavg, `MemAvailable`/swap, a live `top` sample, and memory kills. `am_kill … empty #N` / `empty for Ns` is ActivityManager trimming cached processes, not memory pressure; lmkd logs its own kills as `killinfo` in the events buffer, which spans hours. `dumpsys activity exit-info` (reason 3 = LOW_MEMORY, up to 16 entries per app) keeps days.

### 1.6 Rollback

Every action is logged with its inverse (see 2.1), so rollback = replay inverses in reverse order. Whole-list restore:

```bash
while read -r p; do adb shell -n pm install-existing --user 0 "$p"; done < lists/uninstalled.txt
while read -r p; do adb shell -n pm enable    --user 0 "$p"; done < lists/disabled.txt
while read -r p; do adb shell -n pm unsuspend --user 0 "$p"; done < lists/suspended.txt
while read -r p; do adb shell -n pm unhide    --user 0 "$p"; done < lists/hidden.txt   # only if the user requested hides
```

Whole-list restore is the blunt option; replaying `actions.jsonl` inverses is the precise one (it also covers update strips, permissions and anything else not captured by a list).

- `adb shell` reads stdin. Inside any `while read ... < file` loop, without `-n` (or `</dev/null`) the first iteration eats the rest of the file and only one package gets restored. The same applies to `dbl` (2.5) when called in a read loop.
- `lists/uninstalled.txt` must be the baseline-relative list. A raw "not installed for user 0" list would also install packages the factory image never installed for this device.

---

## 2. Logging specs

### 2.1 `actions.jsonl` (one JSON object per line, append-only)

```json
{"ts":"2026-10-12T21:36:08Z","action":"soft_uninstall","pkg":"com.example.app","cmd":"pm uninstall -k --user 0 com.example.app","rc":0,"out":"Success","inverse":"pm install-existing --user 0 com.example.app","reason":"optional free text","state_after":"User 0: ... installed=false ..."}
```

`action` ∈ `soft_uninstall | restore | disable | enable | suspend | unsuspend | hide | unhide | strip_update | other`. Add your own if needed. Permission, appop, standby and idle changes go to `permissions.jsonl` (2.2).

`inverse` may be `null` (e.g. `strip_update`). Say why in `reason`. `state_after` is read back from the device, not taken from the command's output. For `strip_update` it is `pm path <pkg>` plus the `versionCode=` line, since the `User 0:` line doesn't change on a strip.

### 2.2 `permissions.jsonl`

`before` / `after` hold the full state being restored, as objects:

```json
{"ts":"2026-10-13T13:22:59Z","pkg":"com.example.app","kind":"runtime","name":"android.permission.READ_CONTACTS","before":{"granted":true,"flags":["USER_SET"]},"after":{"granted":false,"flags":["USER_SET"]},"cmd":"pm revoke --user 0 com.example.app android.permission.READ_CONTACTS","inverse":"pm grant --user 0 com.example.app android.permission.READ_CONTACTS","src":"agent"}
```

- `kind` ∈ `runtime | appop | standby | idle | other`.
- `before`/`after` shape by kind: runtime `{granted, flags}`; appop `{uid_mode, pkg_mode}`; standby `{bucket}`; idle `{user_whitelist, sys_whitelist}`; netpolicy goes under `other` with `name` = `netpolicy restrict-background-blacklist uid=<uid>` and shape `{blacklisted}`.
- Read `before`/`after` from the device, not from the command's return.
- Optional `src` ∈ `agent | system | user | unknown`. Use `system` for changes you find in a snapshot diff that you didn't make (e.g. auto-reset, 3.3).

### 2.3 Lists

Regenerate `installed.txt` / `uninstalled.txt` / `disabled.txt` / `suspended.txt` / `frozen.txt` from device state after each batch (1.1) rather than editing by hand. Device state is the source of truth; the lists are a cache. If they disagree with the device, the device wins and the discrepancy goes in `notes.md`.

### 2.4 `notes.md`

Free-form. Log breakage, surprises, OEM quirks, probe outcomes, things that looked safe and weren't, things that looked scary and were fine.

### 2.5 Optional wrapper (small, auditable)

```bash
DBL_DIR=${DBL_DIR:-./debloat-log}; mkdir -p "$DBL_DIR"

# dbl <action> <pkg> <inverse|-> <reason> <device command and args...>
dbl() {
  local act=$1 pkg=$2 inv=$3 why=$4; shift 4
  local cmd out rc after
  cmd=$(printf '%q ' "$@")                       # adb shell re-parses args on the device (mksh, not bash): keep args plain
  out=$(adb shell -n "$cmd" 2>&1); rc=$?
  if [ "$act" = strip_update ]; then             # the "User 0:" line doesn't change on a strip; record where the package lives now
    after=$(adb shell -n "pm path $pkg; dumpsys package $pkg | grep -m1 versionCode=" 2>/dev/null | tr '\n' ' ')
  else
    after=$(adb shell -n dumpsys package "$pkg" 2>/dev/null | grep -m1 'User 0:')
  fi
  jq -nc --arg ts "$(date -u +%FT%TZ)" --arg a "$act" --arg p "$pkg" \
         --arg c "$cmd" --arg o "$out" --arg i "$inv" --arg w "$why" \
         --arg s "$after" --argjson rc "$rc" \
    '{ts:$ts,action:$a,pkg:$p,cmd:$c,rc:$rc,out:$o,inverse:(if $i=="-" then null else $i end),reason:$w,state_after:$s}' \
    >> "$DBL_DIR/actions.jsonl"
  printf '%s\n' "$out"
}

# usage
dbl soft_uninstall com.example.app \
    "pm install-existing --user 0 com.example.app" "optional reason" \
    pm uninstall -k --user 0 com.example.app
```

Exit codes propagate with the shell protocol v2 (default on any modern adb and a device on Android N or later; `adb shell -x` disables it). Still check `out` for `Success` / `Failure`, since `pm` failure output varies.

---

## 3. Android 11 (API 30) notes

Platform facts that shape your options. Nothing here forbids anything that's not explicitly listed as an antipattern. Tags:

- **[confirmed]**: documented by Android docs or reported consistently across independent sources.
- **[probe]**: reported by one source, or version-dependent. Try it, log the outcome in `notes.md`, and move on. A failed probe is data, not a stop sign.
- **[observed]**: seen on the target device (Motorola One Hyper XT2027-1, `RPFS31.Q1-21-20-10`, Android 11). Likely OEM/build-specific; re-verify on other devices.

### 3.1 Removal & freezing

- **[confirmed]** `pm uninstall -k --user 0 <pkg>` and `pm install-existing --user 0 <pkg>` (or `cmd package install-existing <pkg>`) work rootless on Android 11. Reported on Samsung, TCL and AOSP-derived builds.
- **[confirmed]** `pm disable-user --user 0 <pkg>` needs no root (root was only needed before Android 6.0).
- `pm hide`: antipattern for the agent; see 1.3 for the rationale and the user-requested exception.
- **[probe]** `pm suspend --user 0 <pkg>`: supported since 7.0, but shell-user permission varies by build. **[observed]** Works from shell on this build (`new suspended state: true`); like any per-user state, it is lost on an `adb reboot` before a framework shutdown (1.5). See 1.3 for suspend semantics.
- **Updated system apps** carry an update layer (`/data/app`) on top of the factory APK; there is at most one.
  - **Stripping the update is destructive.** `adb uninstall <pkg>` reverts to the factory version for all users, and without `-k` it removes the app's data. Confirm per package, and say so in `reason`. **[probe]** `adb uninstall -k <pkg>` to keep data; check whether it is honored. *Untested on the target device: no update was stripped.*
  - `adb uninstall [-k] <pkg>` is the host-side spelling of `pm uninstall [-k] <pkg>` (no `--user`). Through `dbl` (2.5), which runs device-side, use the `pm` form so the logged `cmd` is what actually ran.
  - One strip should be enough. Verify read-only: `pm path <pkg>` pointing at the system partition, and `codePath=` / `versionCode=` in `dumpsys package <pkg>` matching the factory entry. Don't verify by issuing a second uninstall: what a no-`--user` uninstall does to a system app with no update left is build-dependent, and on some builds it may remove the package for all users. The store may reinstall the update later.
  - **[probe]** `cmd package uninstall-system-updates <pkg>` is reported as an alternative. Check `cmd package help` on-device. *Untested on the target device.*
  - Ordering matters for rollback. A `--user 0` removal of an updated app keeps the update, so `install-existing` restores the **updated** version. If you strip first and then soft-uninstall, `install-existing` restores the **factory** version.
  - Log each step as its own entry. The strip has no shell inverse: `"action":"strip_update"`, `"inverse": null`, and the reason says so.
- **[confirmed]** The `-k --user 0` removal leaves the APK on the system partition, so a factory reset restores the package.

### 3.2 Enumeration extras

- **[confirmed]** Useful `pm list packages` flags: `-u`, `-d`, `-e`, `-s`, `-3`, `-a`, `-i`, `-U`, `--user 0`, `--show-versioncode`, `--apex-only`.
- APEX/Mainline modules (`--apex-only`, `com.android.*`) are updated via Play system updates or OEM OTA. Their activation is system-wide, so a per-user removal doesn't apply to them. Treat them as inventory only.
- **[confirmed]** `adb shell dumpsys package queries` → `forceQueryable` section lists packages the system keeps visible to all apps. A hint for what other apps lean on, nothing more.
- **[confirmed]** Android 11 filters what apps targeting API 30+ can see of other packages. This applies to app-side PackageManager calls. **[probe]** The shell uid (2000) is below the app UID range, so the filter is expected not to apply to `adb shell pm`. If a list looks short, cross-check against `dumpsys package`. *Not specifically tested on the target device.* `pm log-visibility --enable <pkg>` makes the filter log `AppsFilter ... BLOCKED` lines to logcat, which helps when an app acts as if another package vanished.

### 3.3 Permissions on Android 11

- **[confirmed]** `dumpsys package <pkg>` lists runtime permissions as `granted=<bool>, flags=[...]`. Record the flags (`USER_SET`, `USER_FIXED`, ...) in `permissions.jsonl`, not just the boolean (2.2).
- **[probe]** `pm clear-permission-flags` / `pm set-permission-flags` are documented for recent Android and may not exist on Android 11; confirm with `pm help` on-device. If they're missing, log any flag difference after a revoke/grant round trip instead of trying to restore it. *Untested on the target device.*
- **[confirmed]** One-time permissions (location, microphone, camera, "Only this time") are temporary grants. Re-read state immediately before recording `before`.
- **[confirmed]** Background location is a separate permission (`ACCESS_BACKGROUND_LOCATION`). Log and revoke it independently from fine/coarse.
- **[confirmed]** Permission sets vary by a package's targetSdk (e.g. `READ_PHONE_NUMBERS` vs `READ_PHONE_STATE`). Enumerate permissions per package from `dumpsys`; don't hardcode names.
- **[confirmed]** **Auto-reset:** Android 11 resets runtime permissions of unused apps. On by default for apps targeting API 30+; users can enable it for apps targeting 23+. Active device admins and enterprise-fixed permissions are exempt. UI toggle: App info → Permissions → "Remove permissions if app isn't used".
  - Permission state can change with no agent action. When a snapshot diff shows a revoke you didn't make, log it with `"src":"system"` (2.2).
  - **[probe]** The per-package lever is very likely an appop: `AUTO_REVOKE_PERMISSIONS_IF_UNUSED` (`allow` = auto-revoke on, `ignore` = off for that package), plus `AUTO_REVOKE_MANAGED_BY_INSTALLER`. Check with `cmd appops get <pkg> | grep -i auto_revoke`; if present, use it. **[observed]** The op exists on this build and accepts `allow`; whether auto-revoke then fired was not verified (the apps it was set on had no grants yet).
- **[confirmed]** App hibernation (`device_config put app_hibernation ...`) is Android 12+. Not applicable here.

### 3.4 Transport

- **[confirmed]** Wireless debugging is native in Android 11: Developer options → Wireless debugging → "Pair device with pairing code", then `adb pair <ip>:<pair-port>` (6-digit code), then `adb connect <ip>:<connect-port>`. The connect port differs from the pairing port.
- **[probe]** The connect port is randomized each time wireless debugging is enabled, and the feature may switch itself off on reboot or a Wi-Fi network change. Pairing is expected to persist. Recovery: toggle it on, read the current port from the device screen or `adb mdns services`, then `adb connect`. Re-pair only if the connect is rejected. Sources disagree here, so log what you observe. *Untested on the target device: all work ran over USB.*
- USB avoids all of this and is the better choice for batches.
- If the connection drops mid-batch, don't log an in-flight command as success. Re-query device state and log what's actually there.
- **[observed]** An interrupted, timed-out or rejected command may still have run, fully or in part. Before anything else, re-read the device state and the logs, and record what actually happened.

### 3.5 Persistence across updates

- **[confirmed]** Removed/disabled packages can come back after an OTA or major OS update; some vendor packages (e.g. Samsung Knox components) are reported to re-enable on update. Other reports show disabled apps staying disabled, so it varies by vendor and build.
- After any OTA: re-snapshot, diff `installed.txt` / `uninstalled.txt` / `disabled.txt` / `suspended.txt` against device state, and re-apply from the lists. The fingerprint change in `device.txt` marks the OTA.
- If the OEM's OTA client was removed or frozen (1.5), updates won't arrive at all; that is the decision to record.

---

## 4. Git & repo behavior

The repository that holds the logs is the user's. These clauses are explicitly listed antipatterns, so the "nothing is forbidden" default does not apply to them.

- **`git add`, `git commit`, `git pull` and `git push` are anti patterns, strictly forbidden.**
- **Every action on the git repo is read-only.** Inspecting is fine: `git status`, `git diff`, `git log`, `git show`, `git blame`, `git ls-files`, `git branch --list`. Anything that writes to the index, history, refs, config, stash or a remote is an anti pattern. That covers `checkout`/`switch` that change the tree, `reset`, `restore`, `stash`, `merge`, `rebase`, `cherry-pick`, `tag`, `fetch`, `remote add`, `config` writes and the like. Creating or editing ordinary files (logs, lists, notes) is normal work; staging and committing them is the user's job.
- **Nothing reaches a remote without the user.** No pushes, no CI triggers, no hosting-service CLI calls (`gh` and the like) unless the user asks for that specific action. Device logs reveal app inventories and habits: treat the repository as private until the user decides otherwise.
- **Snapshots stay out of commits.** `snapshots/` holds multi-MB raw dumps. Keep it out of what the user commits (an entry in `.gitignore` is an ordinary file edit). `lists/` (including `lists/baseline/`), the two `.jsonl` logs and `notes.md` are what carry the rollback.
- **Identifiers.** `getprop` output includes device identifiers (e.g. `ro.serialno`). The raw dump stays inside `snapshots/` (not committed). The root `device.txt` is a filtered copy. A starting filter, to be checked against the real `getprop` output and extended if something slips through:

  ```bash
  grep -viE 'serial|imei|meid|iccid|imsi|mac|bt.*addr|bdaddr|ro\.boot\.cid|wifi.*addr' "$S/device.txt" > device.txt
  ```

  Keep whatever filter you end up with consistent between runs and note changes to it in `notes.md`. Scrub before publishing anything.
- **When a commit is needed, hand over the message instead of making the commit.** "Needed" means a natural checkpoint: end of a batch, lists regenerated, before something risky, or the user asks. Put the message in the reply and keep working; the user commits when they choose.
  - Style: succinct, professional, technical, bulleted.
  - Shape: imperative subject line (about 72 chars max), blank line, then one bullet per change. State what changed and, where it matters, why. No narration, no filler.
  - Mention counts and mechanisms (`pm uninstall -k --user 0`, `pm suspend`, `appops`) and which logs and lists were touched.

Example message:

```
Debloat batch 3: soft-uninstall OEM apps, restrict background activity

- Soft-uninstall <n> packages via `pm uninstall -k --user 0`
- Suspend <n> packages via `pm suspend --user 0`
- Revoke READ_CONTACTS on <n> packages; set RUN_ANY_IN_BACKGROUND ignore on <n>
- Regenerate installed/uninstalled/frozen lists from device state
- Append entries to actions.jsonl and permissions.jsonl; add breakage notes to notes.md
```

---

## 5. Overrides

Different log format, different directory, `uiautomator`/`settings` tweaks, root-only methods, a different freeze mechanism (anything not explicitly listed as an antipattern), skipping snapshots on a trivial change: all fine. Keep the property that matters: **after you're done, someone with only the log and the device can tell what changed and put it back.**
