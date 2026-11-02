<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# 03 · Android Auto and log-less forensics

Scope: XT2027-1, `RPFS31.Q1-21-20-10`, Android 11 (API 30), no root. Story: [parte 3](https://blog.pega.sh/me-divorcie-de-google-3/).

## Wireless Android Auto chain

1. Bluetooth link to the head unit; `com.google.android.projection.gearhead` starts its foreground service.
2. gearhead requests the car's Wi-Fi (`WifiNetworkSpecifier`, `NOT_VPN`) and adds the network config (visible in the WifiConfigManager local log).
3. The phone joins the car's access point.
4. Projection stream: hundreds of MB per session (~28 MB in 104 s at a normal rate).

## Failure modes

- **VPN.** Android Auto refuses to start when its own uid goes through a VPN: "Communication error 21 - Being connected to a VPN may prevent Android Auto from starting". "Do not route private IPs" doesn't help. Only gearhead is excluded from the firewall; GMS and the Google app work inside it.
- **Mobile data.** A firewall-wide "block on metered networks" plus the netpolicy background blacklist on gearhead, GMS/GSF and the Google app: everything that runs with the screen off had no data on the road.
- **Hotspot.** No STA+AP concurrency on this phone: hotspot on means Wi-Fi client off, so there is no car link.
- **Head unit stuck.** After a failed start the head unit keeps showing "not available" even while the phone is connected and streaming. Only a fresh Bluetooth connection or a cable resets it.
- **Rate.** In the logs that survived: 8 wireless starts, 2 failed; more went unlogged. Cable: no failures.
- **Battery.** Wireless projection + navigation + audio ≈ 22 %/h; gearhead's estimate: Wi-Fi 583 of 642 mAh.
- **GPS.** Every Android Auto restart starts a new GPS request from the map app; GNSS detail lives in the main log buffer and didn't survive the reboot.

Hardening applied: gearhead on the deviceidle user whitelist (bucket 5); Android Auto excluded from automatic updates in Aurora Store 4.8.4 (menu → Blacklist manager → filter: System apps).

## Forensics without logs

The logd main buffer holds minutes by default; by the time a failure in a car can be examined, it's gone. Evidence comes from what persists:

| Source | Keeps | Command |
|---|---|---|
| logd main buffer | 256K by default (minutes); `logcat -b main -G 16M` ≈ 3.5 h, runtime only, reset by reboot; `persist.logd.size.main` refused for shell | `logcat -b main -g` |
| system buffer | ~20 h (ActivityManager, Wi-Fi framework) | `logcat -b system -d` |
| Wi-Fi | WifiConfigManager local log (car network added/removed per session), WifiMetrics byte counters, WifiController messages | `dumpsys wifi` |
| Bluetooth | last 20 state-machine records | `dumpsys bluetooth_manager` |
| App exits | ≤ 16 entries per app, persisted, with reason (3 = LOW_MEMORY) | `dumpsys activity exit-info` |
| Usage | 24 h of events | `dumpsys usagestats` |
| Crashes | persisted across reboots; one tag per call | `dumpsys dropbox --print <tag>` |
| Location | request history, GNSS_KPI | `dumpsys location` |
| App ops | last access and duration (e.g. microphone during a call) | `cmd appops get <pkg>` |

WifiController message ids: 155656 `CMD_WIFI_TOGGLED`, 155658 `CMD_SET_AP`, 155663 `AP_STOPPED`, 155668 `STA_STOPPED`.

Pitfalls:

- `am_kill … empty #N` / `empty for Ns` is ActivityManager trimming cached processes, not memory pressure; lmkd logs its own kills as `killinfo`. `exit-info` is the durable view.
- Theory before data: "the first wireless start after an Android Auto update fails" fit one failure until the exact failure time showed two clean starts after that update.

`tools/maint.sh` re-applies the 16M main buffer after reboots.

## Restores (13)

- Google pieces for Android Auto (6): GMS, GSF, Android Auto, Maps, Speech Services, Google app.
- System plumbing (5): stock launcher (Recents), carrier settings (network name), ambient display (double-tap-to-wake), print spooler + default print service.
- Other (2): Google dialer (pre-unlock call UI, later default), Google Clock.
