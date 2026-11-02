<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# tools

Helpers used during the debloat, ported with guards for public use. Contract: [`AGENTS.md`](../AGENTS.md).
Requirements: Linux host with GNU coreutils (the only host tested), bash >= 4, adb, jq; Python 3 with sqlite3 for `ng2rethink.py`; curl for `build-hosts.sh`.

**Working data lives outside this repository.** `DBL_DIR` (logs, lists, snapshots, hosts builds) defaults to `./debloat-log` under the current directory; the shell tools refuse a `DBL_DIR` inside the clone.

| Tool | Purpose | Device side effects | Safe mode |
|---|---|---|---|
| `dbl-env.sh` | Session helpers, sourced: `lp`, `dbl` (logged command with inverse), `snap` (snapshot + baseline-relative lists), `rb` (framework reboot), `drift`, `crashes`, `load`, `bgr`/`unbgr`/`netbl`/`rbucket`/`allr` (background policy, logged with before/after/inverse) | `dbl`, `rb` and the policy helpers write; the rest only read | read-only helpers |
| `maint.sh` | Re-applies the logged background policy: appops, netpolicy, standby bucket 45, full AOT compile, log buffer size; reports stopped keep-running apps, drift, crashes | writes only with `--apply`; `--sf` drives the UI | default is a dry run; refuses without `$DBL_DIR/permissions.jsonl` |
| `bench.sh` | Settings scroll jank, cold-launch times, shade and launcher-drawer jank | launches, force-stops, injects input; bumps standby buckets | `--check` validates the screen size only |
| `build-hosts.sh` | Merges AdAway, StevenBlack, Peter Lowe and HaGeZi Light into one hosts file for NetGuard | none (`--push` copies the file to `/sdcard/Download/`) | — |
| `ng2rethink.py` | Translates a NetGuard export into RethinkDNS per-app rules (AppInfo table) | none (host-side) | writes a copy; the input DB is never modified |
| `ui.sh` | `uidump`, `uitexts`, `tap`, `shot`: UI driving via uiautomator | writes `/data/local/tmp/ui.xml`; `tap` injects input | — |

Versions these were written against: NetGuard 2.337, RethinkDNS 0.5.8, SuperFreezZ 1.1, Android 11 (`RPFS31.Q1-21-20-10`).
