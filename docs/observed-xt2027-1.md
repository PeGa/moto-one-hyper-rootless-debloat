<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# `[observed]` index: XT2027-1, `RPFS31.Q1-21-20-10`

Facts seen on this build only. Re-verify on anything else.

| Topic | Where |
|---|---|
| Preloads with no factory copy lose their APK on `--user 0` removal | AGENTS §1.2, doc 01 |
| `pm suspend` works from shell | AGENTS §3.1 |
| Stopped state survives a framework reboot; `BOOT_COMPLETED` only after first unlock | AGENTS §1.3, doc 02 |
| `hidden=` present on the `User 0:` line | AGENTS §1.3 |
| Refusal messages and what they block | AGENTS §1.3, doc 01 |
| `pm disable <pkg>/<component>` refused for shell, system and user apps | AGENTS §1.3, doc 02 |
| OEM default notification listener re-granted at boot | AGENTS §1.3 |
| System-allowlist removal survives reboot; boot receivers then hit the background-service start limit | AGENTS §1.4, doc 01 |
| `default` ≠ `allow` for `RUN_ANY_IN_BACKGROUND` | AGENTS §1.4, doc 02 |
| Foreground services on system events can't take the background restriction | AGENTS §1.4, doc 02 |
| Restrictions erode (use, Settings toggle, app updates) | AGENTS §1.4, doc 02 |
| `restricted` bucket needs `enable_restricted_bucket=1` | AGENTS §1.4, doc 02 |
| Lockdown, Android Auto and direct boot vs a VPN firewall | AGENTS §1.4, docs 02–03 |
| `cmd role` verbs on Android 11 | AGENTS §1.5 |
| Partially direct-boot-aware dialer/SMS and the Telecom fallback | AGENTS §1.5, doc 02 |
| Recents served by the stock launcher's Quickstep | AGENTS §1.5, doc 01 |
| Print spooler ↔ Settings hang; ambient display ↔ double-tap-to-wake | AGENTS §1.5, doc 02 |
| `adb reboot` skips the framework shutdown; per-user state lost | AGENTS §1.5, doc 01 |
| `dumpsys dropbox --print` takes one tag per call | AGENTS §1.5 |
| logd main buffer 256K; `-G` runtime only; persist prop refused | AGENTS §1.5, doc 03 |
| `AUTO_REVOKE_PERMISSIONS_IF_UNUSED` op present | AGENTS §3.3 |
| Interrupted or rejected commands may have run | AGENTS §3.4 |
| Carrier settings package supplies the network-name display | doc 01 |
| Play Store updates itself and system apps without an account | doc 01 |
| No STA+AP concurrency (hotspot disables the Wi-Fi client) | doc 03 |
| Head unit doesn't retry after a failed wireless start | doc 03 |
| Android Auto checks for Speech Services by package name | doc 02 |
| GMS network location stays disabled without account/consent | doc 02 |
