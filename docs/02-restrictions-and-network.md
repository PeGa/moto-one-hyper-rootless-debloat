<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# 02 · Background restrictions and network filtering

Scope: XT2027-1, `RPFS31.Q1-21-20-10`, Android 11 (API 30), no root. Contract: [`AGENTS.md`](../AGENTS.md) §1.3–§1.5. Story: [parte 2](https://blog.pega.sh/me-divorcie-de-google-2/).

## Levers

| Lever | Apply | Inverse | Notes |
|---|---|---|---|
| Background execution | `cmd appops set --user 0 <pkg> RUN_ANY_IN_BACKGROUND ignore` (+ `RUN_IN_BACKGROUND` for targetSdk < 26) | `… allow` | `ignore` is silent; `deny` surfaces as exceptions. Never `default` (below) |
| Standby bucket | `am set-standby-bucket <pkg> restricted` | `am set-standby-bucket <pkg> <before>` | 40 unless `settings put global enable_restricted_bucket 1`; then 45, persistent. PERSISTENT apps stay at 10; role holders get bumped back |
| Mobile background data | `cmd netpolicy add restrict-background-blacklist <uid>` | `… remove …` | metered networks only |
| Background location | `pm revoke --user 0 <pkg> android.permission.ACCESS_BACKGROUND_LOCATION` | `pm grant …` | separate from fine/coarse |
| Auto-revoke | `cmd appops set --user 0 <pkg> AUTO_REVOKE_PERMISSIONS_IF_UNUSED allow` | `… <before>` | op present on this build |
| Stopped state | `am force-stop <pkg>` | the user opens the app | survives a framework reboot; 0 boot spawns until opened |
| Wi-Fi background network | — | — | no rootless per-app control: VPN-slot firewall (below) |

Policy groups used: **all levels** (execution, bucket, mobile data, background location); **mobile background data only** (dialer, messaging, keyboards, clock, FM: they must react to system events); **hostile** (all levels + auto-revoke + stopped state, re-frozen by a freezer app); **untouchable** (sync/push stack, app stores, the firewall itself).

Implementation: `tools/dbl-env.sh` (`bgr`, `unbgr`, `netbl`, `rbucket`, `allr`), every change logged with before/after/inverse.

## `default` is not `allow`

`cmd appops set <pkg> RUN_ANY_IN_BACKGROUND default` stores MODE_DEFAULT explicitly. `ActiveServices` allows `startForeground()` only for MODE_ALLOWED, so the app stays background-restricted: `Service.startForeground() not allowed due to bg restriction`. `allow` returns the op to `No operations.`. Inverses of an unset op are `allow`.

Rule: anything that must start a foreground service on a system event (incoming-call UI, alarms, navigation projected to a car) can't take `RUN_ANY_IN_BACKGROUND ignore`.

## Direct boot

Before the first unlock after a reboot, only direct-boot-aware components run. A replacement dialer/SMS app that is only `PARTIALLY_DIRECT_BOOT_AWARE` can't show incoming calls in that window; Telecom falls back to the system dialer. With the stock dialer removed: vibration, no call UI, missed call. Fix: keep `com.google.android.dialer` installed as the fallback, background execution allowed (see the rule above), network blocked.

## Side effects of removals

- `com.motorola.motodisplay` (ambient display) puts the touch controller in gesture mode: removing it disables double-tap-to-wake.
- `com.android.printspooler`: removing it makes Settings → Connection preferences hang (ANR in `PrintSettingPreferenceController.getSummary` → `IPrintManager.getPrintJobInfos`).

## Erosion and re-application

Restrictions decay: use moves an app out of `restricted`; Settings → App info → Battery → Background restriction clears `RUN_ANY_IN_BACKGROUND`; app updates reset AOT compilation. `tools/maint.sh` takes the desired state from the last logged `after` per package and re-applies it (dry run by default, `--apply` to write).

## Google Play services for Android Auto

Android Auto needs GMS; Google Maps too. microG has no Android Auto support and needs root. Restored with `pm install-existing --user 0`: `com.google.android.gsf` + `com.google.android.gms` (shared uid), `com.google.android.projection.gearhead`, `com.google.android.apps.maps`; later `com.google.android.tts` (Android Auto refuses to start without it and checks the package name) and `com.google.android.googlequicksearchbox` (Android Auto voice; no account needed). No Google account at any point.

- GMS: 16 runtime permissions revoked; kept location (+ background), `ACTIVITY_RECOGNITION`, `RECORD_AUDIO`; `READ_PHONE_STATE` is `SYSTEM_FIXED`.
- No background-execution or bucket restriction on the Android Auto path: navigation projected to the car runs as a foreground service.
- The GMS network location provider stays `enabled=false allowed=false` (no account, no consent): fixes remain GPS.
- Overnight idle drain with this setup: ~0.65 %/h (battery at 76 % of design capacity).

## Network: NetGuard → RethinkDNS

Rootless, Android has one VPN slot; a VPN-slot firewall is the only per-app Wi-Fi control.

**NetGuard 2.337:** default-block on Wi-Fi and mobile, `manage_system`, per-app allow list, hosts filtering (`tools/build-hosts.sh`: AdAway, StevenBlack, Peter Lowe, HaGeZi Light → 88,036 domains). With filtering on, all name resolution failed. Causes, in order:

1. Always-on **lockdown**: NetGuard saw `Connected=false` and allowed nothing.
2. **IPv6** offered in the tunnel on an IPv4-only network: `connect error 101`.
3. A network that refuses outbound DNS to external resolvers: custom VPN DNS can't work; use each network's own DNS.
4. `lan=true`: LAN DNS routed outside the tunnel, fallback to blocked resolvers.
5. A browser with "secure DNS" on and no provider.

**RethinkDNS 0.5.8:** one VPN slot for firewall + DNS blocklists with subdomain matching + WireGuard. Rules migrated with `tools/ng2rethink.py`. A Rethink backup (`.rbk`) is a zip holding `bravedns.db` (per-app rules in table `AppInfo`), `rethink_logs.db`, `shared_prefs_backup.txt` and `rethink_backup.txt`:

```bash
unzip backup.rbk -d rbk
python3 tools/ng2rethink.py netguard_export.xml rbk/bravedns.db rbk/new.db && mv rbk/new.db rbk/bravedns.db
(cd rbk && zip -q ../rules.rbk bravedns.db rethink_logs.db shared_prefs_backup.txt rethink_backup.txt)
```

Restore `rules.rbk` from Rethink's UI; a restore leaves the VPN stopped, so start it again. Preferences such as `block_new_apps` travel in `shared_prefs_backup.txt`. Lists: HaGeZi Light 62,151, StevenBlack Unified 73,638, Peter Lowe 3,569. `block_new_apps` on: every new install starts without network.

Not filterable rootless:

- traffic before the first unlock (Rethink is only `PARTIALLY_DIRECT_BOOT_AWARE`; lockdown would block it, but on Android 11 lockdown also blocks VPN-excluded apps);
- Android Auto's own uid (doc 03);
- data handed between apps over IPC (an offline app passing data to an online one);
- per-component boot receivers (`pm disable <pkg>/<component>` is refused for shell, user apps included).
