<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# moto-one-hyper-rootless-debloat

[Versión en español](#en-español)

Rootless, reversible degoogling of a Motorola One Hyper (XT2027-1) on Android 11, driven over ADB, with every state change logged together with its inverse.

Companion technical reference for the blog series *Me divorcié de Google*. Reference only: no support, issues and pull requests are not monitored.

## Scope

- **Device:** Motorola One Hyper XT2027-1, retail AR software channel (`retar`), build `RPFS31.Q1-21-20-10`, Android 11 (API 30), security patch 2022-01-01.
- **Constraints:** no root, no bootloader unlock, no flashing, no Google account at any point.
- **Validity:** findings tagged `[observed]` were seen on that build only. Re-verify on anything else.
- **Stack as used in October 2026:** NetGuard 2.337, RethinkDNS 0.5.8, SuperFreezZ 1.1, Aurora Store 4.8.4.

## Method

1. **Baseline before the first change:** per-user package state (present, uninstalled-for-user, disabled, suspended), role holders, `dumpsys package`. Every removed/disabled/suspended list is computed against it under `LC_ALL=C`.
2. **Logged changes:** every state-changing command runs through a wrapper that records the command, its output, the inverse, and the state read back from the device: `actions.jsonl` for package state, `permissions.jsonl` for runtime permissions, appops, standby buckets, netpolicy and deviceidle.
3. **Removal ladder:** `pm uninstall -k --user 0`, then `pm disable-user --user 0` if the uninstall is refused, then appops / standby bucket / netpolicy restriction if both are refused. `pm hide` was not used (AGENTS §1.3).
4. **Small batches.** After each one: framework reboot (`svc power reboot`), drift check (log vs. device), crash check (`dumpsys dropbox`, one tag per call), load check.
5. **The device wins.** When log and device disagree, the device state is recorded and the discrepancy investigated.

Invariant: anyone with only the logs and the device can tell what changed and revert it.

Outcome on this device at experiment close (2026-10-31): 228 logged package actions, 640 logged policy changes (runtime permissions, appops, standby buckets, netpolicy, deviceidle, firewall rules), 13 restores, 123 stock packages removed for user 0. The blog posts count 124; the extra one is a sideloaded, non-stock package.

## Getting started

Host: Linux with GNU coreutils, bash ≥ 4, adb, jq (tested there only). Phone with USB debugging authorized.

```bash
cd ~/work                                         # any directory outside this clone; DBL_DIR=./debloat-log
source /path/to/moto-one-hyper-rootless-debloat/tools/dbl-env.sh   # pins the device when exactly one is attached
snap                                              # first run: snapshot + baseline (lists/baseline)
dbl soft_uninstall <pkg> "pm install-existing --user 0 <pkg>" "reason" pm uninstall -k --user 0 <pkg>
rb                                                # framework reboot after each batch
snap; drift; crashes                              # re-snapshot, drift check, crash check
allr <pkg> "reason"                               # background restriction, all levels, logged
/path/to/moto-one-hyper-rootless-debloat/tools/maint.sh             # periodic: dry run; --apply re-applies the logged policy
```

Read [`AGENTS.md`](AGENTS.md) first; to run the process with an AI agent, place it in the agent's working directory as its instructions.

## Contents

| Path | Content |
|---|---|
| `AGENTS.md` | The working contract the process ran under (public edition, 2026-11). |
| `tools/` | Session helpers, policy re-application, hosts merge, NetGuard → RethinkDNS rule translation, jank/launch bench, uiautomator helpers. |
| `docs/` | Baseline and removal; background restrictions and network filtering; Android Auto and log-less forensics; log format; `[observed]` index. |
| `reference/` | XT2027-1 `RPFS31.Q1-21-20-10` package data: 329 stock packages at baseline, 23 factory-disabled, 123 removed. Technical data, not a recipe. |
| `examples/` | Working-directory skeleton with synthetic log entries. |

## How it was built

Built with an AI coding agent working under `AGENTS.md`: the agent did the heavy lifting, debugging above all; I designed the process, held the wheel and drove the engineering decisions.

## Disclaimer

- Reference only. No support.
- Not affiliated with Motorola, Lenovo or Google. Product names are trademarks of their respective owners.
- These commands change device state. Some changes have no single-step inverse (update strips, `pm reset-permissions`, `cmd appops reset`). Read `AGENTS.md` before running anything. Use at your own risk.

## License

| Path | License |
|---|---|
| `tools/` and any other code | MIT, see [`LICENSE`](LICENSE) |
| `AGENTS.md`, `docs/`, `reference/`, `examples/`, this README | CC BY-NC-SA 4.0, see [`LICENSE-docs`](LICENSE-docs) |

Copyright © 2026 Pablo G. (PeGa!). Commercial use of the CC BY-NC-SA material requires prior permission from the author. `LICENSE-docs` holds the full legal code.

## Blog series (Spanish)

- [Me divorcié de Google: Prólogo](https://blog.pega.sh/Acercamiento-al-celular-libre-prologo/) (2019)
- [Parte 1: Cuando cambian las reglas del juego](https://blog.pega.sh/me-divorcie-de-google-1/)
- [Parte 2: Lo que no se puede sacar](https://blog.pega.sh/me-divorcie-de-google-2/)
- [Parte 3: El enemigo final](https://blog.pega.sh/me-divorcie-de-google-3/)

---

## En español

Desgoogleado sin root y reversible de un Motorola One Hyper (XT2027-1) con Android 11, ejecutado por ADB, con cada cambio de estado registrado junto con su inverso.

Referencia técnica de la serie *Me divorcié de Google*. Sólo referencia: sin soporte; issues y pull requests no se atienden.

### Alcance

- **Dispositivo:** Motorola One Hyper XT2027-1, canal `retar`, build `RPFS31.Q1-21-20-10`, Android 11 (API 30), parche 2022-01-01.
- **Restricciones:** sin root, sin desbloquear el bootloader, sin flashear, sin cuenta de Google.
- **Validez:** lo marcado `[observed]` se observó sólo en ese build. Reverificar en cualquier otro.
- **Stack a octubre de 2026:** NetGuard 2.337, RethinkDNS 0.5.8, SuperFreezZ 1.1, Aurora Store 4.8.4.

### Método

1. **Baseline antes del primer cambio:** estado de paquetes por usuario (presentes, desinstalados para el usuario, deshabilitados, suspendidos), titulares de roles, `dumpsys package`. Toda lista de removidos/deshabilitados/suspendidos se calcula contra el baseline, con `LC_ALL=C`.
2. **Cambios registrados:** todo comando que cambia estado pasa por un wrapper que registra el comando, su salida, el inverso y el estado leído del dispositivo: `actions.jsonl` para estado de paquetes, `permissions.jsonl` para permisos runtime, appops, standby buckets, netpolicy y deviceidle.
3. **Escalera de remoción:** `pm uninstall -k --user 0`; `pm disable-user --user 0` si el uninstall es rechazado; restricción por appops / standby bucket / netpolicy si ambos son rechazados. `pm hide` no se usó (AGENTS §1.3).
4. **Tandas chicas.** Después de cada una: reinicio por framework (`svc power reboot`), chequeo de drift (log vs. dispositivo), chequeo de crashes (`dumpsys dropbox`, un tag por llamada), chequeo de carga.
5. **El dispositivo manda.** Si log y dispositivo no coinciden, se registra el estado del dispositivo y se investiga la diferencia.

Invariante: con sólo los logs y el dispositivo, cualquiera puede saber qué cambió y revertirlo.

Resultado en este dispositivo al cierre del experimento (2026-10-31): 228 acciones de paquetes, 640 cambios de políticas registrados (permisos runtime, appops, standby buckets, netpolicy, deviceidle, reglas de firewall), 13 restauraciones, 123 paquetes de stock removidos para el usuario 0. Los posts cuentan 124; el adicional es un paquete sideloadeado, no de stock.

### Primeros pasos

Host: Linux con GNU coreutils, bash ≥ 4, adb, jq (probado sólo ahí). Teléfono con depuración USB autorizada.

```bash
cd ~/work                                         # cualquier directorio fuera de este clon; DBL_DIR=./debloat-log
source /path/to/moto-one-hyper-rootless-debloat/tools/dbl-env.sh   # fija el dispositivo si hay exactamente uno conectado
snap                                              # primera corrida: snapshot + baseline (lists/baseline)
dbl soft_uninstall <pkg> "pm install-existing --user 0 <pkg>" "motivo" pm uninstall -k --user 0 <pkg>
rb                                                # reinicio por framework después de cada tanda
snap; drift; crashes                              # re-snapshot, chequeo de drift, chequeo de crashes
allr <pkg> "motivo"                               # restricción de segundo plano en todos los niveles, registrada
/path/to/moto-one-hyper-rootless-debloat/tools/maint.sh             # periódico: dry run; --apply re-aplica la política registrada
```

Leé [`AGENTS.md`](AGENTS.md) primero; para correr el proceso con un agente de IA, ubicalo en el directorio de trabajo del agente como sus instrucciones.

### Contenido

- `AGENTS.md`: el contrato de trabajo bajo el que corrió el proceso (edición pública, 2026-11).
- `tools/`: helpers de sesión, re-aplicación de políticas, merge de hosts, traducción de reglas NetGuard → RethinkDNS, bench de jank/lanzamiento, helpers de uiautomator.
- `docs/`: baseline y remoción; restricciones de segundo plano y filtrado de red; Android Auto y forense sin logs; formato de logs; índice `[observed]`.
- `reference/`: datos de paquetes de XT2027-1 `RPFS31.Q1-21-20-10`: 329 de stock en el baseline, 23 deshabilitados de fábrica, 123 removidos. Datos técnicos, no una receta.
- `examples/`: esqueleto del directorio de trabajo con entradas de log sintéticas.

### Cómo se hizo

Con un agente de IA trabajando bajo `AGENTS.md`: el agente hizo el trabajo pesado, sobre todo el debugging; yo diseñé el proceso, decidí cada paso del mismo y tomé las decisiones de ingeniería.

### Descargo

- Sólo referencia. Sin soporte.
- Sin afiliación con Motorola, Lenovo ni Google. Los nombres de productos son marcas de sus respectivos dueños.
- Estos comandos cambian el estado del dispositivo. Algunos cambios no tienen inverso en un paso (strip de updates, `pm reset-permissions`, `cmd appops reset`). Leé `AGENTS.md` antes de ejecutar nada. Bajo tu propio riesgo.

### Licencia

- `tools/` y todo otro código: MIT ([`LICENSE`](LICENSE)).
- `AGENTS.md`, `docs/`, `reference/`, `examples/` y este README: CC BY-NC-SA 4.0 ([`LICENSE-docs`](LICENSE-docs)).
- Copyright © 2026 Pablo G. (PeGa!). El uso comercial del material CC BY-NC-SA requiere permiso previo del autor. `LICENSE-docs` contiene el texto legal completo.
