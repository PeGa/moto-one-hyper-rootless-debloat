<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# 01 · Baseline and removal

Scope: XT2027-1, `RPFS31.Q1-21-20-10`, Android 11 (API 30), no root. Contract: [`AGENTS.md`](../AGENTS.md) §0–§2. Story: [parte 1](https://blog.pega.sh/me-divorcie-de-google-1/).

## Baseline

Fresh factory reset, setup completed, no account: 329 packages present for user 0, 23 of them factory-disabled, 9 third-party preloads, 21 APEX modules. `pm list packages -u` showed nothing beyond the present list: no factory-uninstalled entries, so `lists/baseline/gone.txt` and `suspended.txt` are empty on this build. Data: [`reference/`](../reference/).

Name lists, without `-f` (AGENTS §1.1):

```bash
export LC_ALL=C
lp() { adb shell -n pm list packages "$@" | sed 's/^package://' | tr -d '\r' | sort -u; }

lp --user 0     > present.txt      # installed for user 0
lp -u --user 0  > all_u.txt        # includes uninstalled-for-user
lp -d --user 0  > disabled.txt
comm -23 all_u.txt present.txt > gone.txt
```

`tools/dbl-env.sh` → `snap` does this plus the raw dumps, creates `lists/baseline/` on the first run only, and derives the baseline-relative lists afterwards.

Traps:

- **`LC_ALL=C`.** `comm` needs both inputs sorted in the same collation. Lists are compared for weeks, from different shells; a locale change reorders them and `comm` returns wrong results without error.
- **`adb shell -n`.** `adb shell` reads stdin. In a `while read … < file` loop the first call consumes the rest of the file; the loop processes one package and exits cleanly.
- **`pm list packages -f`.** Android 11 `/data/app` paths look like `~~<b64>==/<pkg>-<b64>==/base.apk`. Splitting on `=` returns garbage; `sed 's/.*=//'` keeps what follows the last one.
- **Baseline-relative lists.** "Removed/disabled/suspended" are computed against the baseline, so factory state is never attributed to the project and a whole-list restore never enables what the factory shipped disabled.

## Logged changes

Every state change goes through a wrapper (`dbl`, AGENTS §2.5) that records the command, output, inverse and the state read back from the device. Rollback is replaying inverses in reverse order. Format: [`log-format.md`](log-format.md).

## Removal ladder

```bash
adb shell pm uninstall -k --user 0 <pkg>        # default: removed for user 0, APK and data kept
adb shell pm install-existing --user 0 <pkg>    # inverse
```

Order: soft uninstall → `pm disable-user --user 0` only if refused → appops / standby bucket / netpolicy (doc 02) only if both are refused. `pm hide` is not used (AGENTS §1.3).

Refusals seen on this build:

| Message | Uninstall `--user 0` | `disable-user` | Packages |
|---|---|---|---|
| `Failure [DELETE_FAILED_DEVICE_POLICY_MANAGER]` | refused | allowed | `com.roaming.android.gsimbase`, `com.roaming.android.gsimcontentprovider` |
| `Failure: package is non-disable` | refused | refused | `com.amazon.appmanager` (factory-disabled), `com.motorola.launcherconfig` |
| `Failure: package is protected` / `SecurityException: Cannot disable a protected package` | refused | refused | `com.motorola.ccc.ota`, `com.motorola.paks`, `com.google.android.apps.work.oobconfig` |

Protected packages end on the last rung (doc 02 levers). For `com.motorola.ccc.ota`: background execution `ignore` and removal from the system deviceidle allowlist (its standby bucket stays 5, exempt). Its boot receiver then crashes once per boot (`IllegalStateException: Not allowed to start service`); contained, no respawn.

## Batch order used

Batches of about a dozen packages, each followed by a framework reboot, a drift check and a crash check.

1. **Preloads with no role** (Facebook stub and services, Google preloads installed by setup): no dependents, lowest risk.
2. **Google apps with a factory copy** (YouTube, Gmail, Maps, Duo, Assistant, ARCore…): updated system apps; `install-existing` restores the updated version.
3. **OEM apps with no role** (demo, help, game mode, widgets, hub, test menus).
4. **Telemetry, OTA and provisioning** (OEM/Lenovo/carrier metrics, update clients, region leftovers), after the apps; the OTA client is a recorded decision.
5. **Replacements:** install the replacement, move the role (`cmd role add-role-holder`), then remove the stock app (dialer, SMS, launcher, browser, assistant, gallery, keyboard, contacts, clock, calendar…). Play Store went out in this batch. For dialer/SMS, see direct boot in doc 02.
6. **Google services stack, last of the Google pieces:** after a dependency check (no account, no device admin, no remaining push requesters): GMS + GSF together (shared uid), setup and restore helpers.
7. **AOSP extras and provisioning** (easter egg, screensaver, tracing, print, bookmarks, managed provisioning).
8. **Carrier/IMS cleanup only after a SIM test** (calls, SMS, data in both directions); telephony-uid packages split into their own batch.
9. **Left alone:** overlays, themes and resource packages (no process, nothing to gain), mainline modules, WebView.

Restores followed the needs that appeared later (doc 02, doc 03).

## Observed on this build

- **No factory copy.** The 8 Google preloads setup installs land in `/data/app` with no system copy. `pm uninstall -k --user 0` deletes their codePath; the package record stays (listed by `-u`), `install-existing` has nothing to restore. Check codePath and `Hidden system packages:` before removing; record such names in `lists/no_factory_copy.txt`.
- **`adb reboot` loses per-user state.** `adb reboot` sets `sys.powerctl` and skips the framework shutdown. Per-user package state changed since the last framework shutdown (uninstall, disable-user, suspend) was lost: Motorola, Lenovo and AT&T packages reappeared, while earlier Google/Facebook removals survived (unexplained). After any state change the first reboot is `adb shell svc power reboot` (`tools/dbl-env.sh` → `rb`); once a framework shutdown has flushed the state, `adb reboot` is harmless.
- **Recents.** Overview is served by the stock launcher's Quickstep component (`dumpsys activity service com.android.systemui` → `recentsComponentName`). Removing `com.motorola.launcher3` with a third-party HOME breaks Recents; `install-existing` restores it. After the restore the HOME role came back empty and had to be re-pinned (`cmd role add-role-holder --user 0 android.app.role.HOME <pkg>`).
- **Network name.** Removing `com.google.android.carrier` left registration intact (LTE, full signal) while SystemUI showed "No service": it supplies the network-name display config on this build. Restored, then disabled: the name stayed (it may revert on a carrier-config reload, e.g. a SIM swap).
- **Play Store without an account** keeps updating itself and system apps. It was soft-uninstalled the same night.
- **OTA client.** `com.motorola.ccc.ota` is protected; neutralizing it blocks system updates (patch level stays 2022-01-01). Recorded as a deliberate decision.
