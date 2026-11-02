<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# notes

Free-form, newest at the bottom (AGENTS.md §2.4): breakage, surprises, OEM quirks, probe outcomes, decisions that have no command (e.g. neutralizing the OTA client), re-baselines.

## YYYY-MM-DD — baseline (snapshot <UTC-ts>)

- Device, build fingerprint, patch level, transport.
- Counts: present / factory-disabled / third-party / APEX.
- Role holders, IME, WebView provider.

## YYYY-MM-DD — batch N, snapshot <UTC-ts>

- What ran (counts and mechanisms), refusals, pre-checks.
- After `svc power reboot`: drift, crashes (dropbox), load.
