<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# examples

`debloat-log/`: the working-directory layout from AGENTS.md §0 with synthetic content (`com.example.app`; timestamps from the project's timeline). Copy it outside this repository and point `DBL_DIR` at the copy, or let `tools/dbl-env.sh` create a fresh one: `snap` writes the baseline on the first run.

`lists/baseline/` is empty on purpose: it only ever comes from your own first snapshot.
