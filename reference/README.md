<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# reference

Package data for Motorola One Hyper XT2027-1, retail AR (`retar`), build `RPFS31.Q1-21-20-10`, Android 11, after a factory reset with setup completed and no account. Technical data, **not a recipe**.

| File | Content | Count |
|---|---|---|
| `stock-packages.txt` | present for user 0 at baseline (`pm list packages --user 0`) | 329 |
| `factory-disabled.txt` | disabled at baseline (`pm list packages -d --user 0`) | 23 |
| `removed-stock.txt` | stock packages removed for user 0 (`pm uninstall -k --user 0`) and still removed at the end of the project | 123 |
| `stock-classification.md` | the 329, grouped by function, with factory-disabled / updated-system-app / removed / refusal flags | 329 |

Factory-uninstalled (`pm list packages -u` beyond the present list) and factory-suspended: none on this build.

One package per line, `LC_ALL=C sort -u`. Everything in this directory is CC BY-NC-SA 4.0 (`LICENSE-docs`).
