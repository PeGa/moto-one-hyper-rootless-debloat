<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# Log format

Two append-only JSON Lines files under `$DBL_DIR`, one object per state change. Spec: [`AGENTS.md`](../AGENTS.md) §2. Writers: `tools/dbl-env.sh`, `tools/maint.sh`. Examples below use `com.example.app`; timestamps fall in the project's timeline.

## `actions.jsonl`: package state

Keys: `ts` (UTC), `action`, `pkg`, `cmd` (what ran, device side), `rc`, `out`, `inverse` (null when there is none; say why in `reason`), `reason`, `state_after` (read back from the device: the `User 0:` line, or `pm path` + `versionCode=` for `strip_update`).

`action` ∈ `soft_uninstall | restore | disable | enable | suspend | unsuspend | hide | unhide | strip_update | other`.

```json
{"ts":"2026-10-12T21:36:08Z","action":"soft_uninstall","pkg":"com.example.app","cmd":"pm uninstall -k --user 0 com.example.app","rc":0,"out":"Success","inverse":"pm install-existing --user 0 com.example.app","reason":"batch 1: preloads","state_after":"User 0: ceDataInode=0 installed=false hidden=false suspended=false stopped=true notLaunched=true enabled=0"}
{"ts":"2026-10-12T21:57:22Z","action":"disable","pkg":"com.example.app","cmd":"pm disable-user --user 0 com.example.app","rc":0,"out":"Package com.example.app new state: disabled-user","inverse":"pm enable --user 0 com.example.app","reason":"uninstall refused (DELETE_FAILED_DEVICE_POLICY_MANAGER)","state_after":"User 0: installed=true hidden=false suspended=false stopped=false enabled=3"}
{"ts":"2026-10-13T04:07:16Z","action":"restore","pkg":"com.example.app","cmd":"pm install-existing --user 0 com.example.app","rc":0,"out":"Package com.example.app installed for user: 0","inverse":"pm uninstall -k --user 0 com.example.app","reason":"provides Recents (Quickstep)","state_after":"User 0: installed=true hidden=false suspended=false stopped=false enabled=0"}
```

## `permissions.jsonl`: permissions, appops, buckets, netpolicy, deviceidle

Keys: `ts`, `pkg`, `kind`, `name`, `before`, `after` (both read from the device), `cmd`, `inverse`, `out`, `src` (`agent | system | user | unknown`), `reason`.

| `kind` | `name` | `before` / `after` shape |
|---|---|---|
| `runtime` | permission | `{granted, flags}` |
| `appop` | op | `{uid_mode, pkg_mode}` (`unset` = `No operations.`) |
| `standby` | `bucket` | `{bucket}` |
| `idle` | `deviceidle` | `{user_whitelist, sys_whitelist}` |
| `other` | `netpolicy restrict-background-blacklist uid=<uid>` | `{blacklisted}` |

```json
{"ts":"2026-10-13T01:11:50Z","pkg":"com.example.app","kind":"appop","name":"RUN_ANY_IN_BACKGROUND","before":{"uid_mode":null,"pkg_mode":"unset"},"after":{"uid_mode":null,"pkg_mode":"ignore"},"cmd":"cmd appops set com.example.app RUN_ANY_IN_BACKGROUND ignore","inverse":"cmd appops set com.example.app RUN_ANY_IN_BACKGROUND allow","out":"","src":"agent","reason":"bg policy"}
{"ts":"2026-10-13T01:11:51Z","pkg":"com.example.app","kind":"standby","name":"bucket","before":{"bucket":"10"},"after":{"bucket":"45"},"cmd":"am set-standby-bucket com.example.app restricted","inverse":"am set-standby-bucket com.example.app 10","out":"","src":"agent","reason":"all levels"}
{"ts":"2026-10-13T04:21:00Z","pkg":"com.example.app","kind":"other","name":"netpolicy restrict-background-blacklist uid=10123","before":{"blacklisted":false},"after":{"blacklisted":true},"cmd":"cmd netpolicy add restrict-background-blacklist 10123","inverse":"cmd netpolicy remove restrict-background-blacklist 10123","out":"","src":"agent","reason":"bg mobile data off (metered only)"}
{"ts":"2026-10-13T06:17:30Z","pkg":"com.example.app","kind":"runtime","name":"android.permission.ACCESS_MEDIA_LOCATION","before":{"granted":true,"flags":["USER_SET"]},"after":{"granted":false,"flags":["USER_SET"]},"cmd":"pm revoke --user 0 com.example.app android.permission.ACCESS_MEDIA_LOCATION","inverse":"pm grant --user 0 com.example.app android.permission.ACCESS_MEDIA_LOCATION","out":"","src":"agent","reason":"all levels"}
{"ts":"2026-10-13T01:11:51Z","pkg":"com.example.app","kind":"idle","name":"deviceidle","before":{"user_whitelist":false,"sys_whitelist":"system system-excidle"},"after":{"user_whitelist":false,"sys_whitelist":"system-excidle"},"cmd":"cmd deviceidle sys-whitelist -com.example.app","inverse":"cmd deviceidle sys-whitelist +com.example.app","out":"","src":"agent","reason":"protected package: last rung"}
```

## Reading the logs

```bash
# last logged action per package (what drift compares against the device)
jq -r '[.pkg,.action,.out]|@tsv' actions.jsonl | awk -F'\t' '{l[$1]=$2"\t"$3} END{for(p in l) print p"\t"l[p]}'
# replay inverses, newest first (review before running)
tac actions.jsonl | jq -r 'select(.inverse!=null)|.inverse'
```
