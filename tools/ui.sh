# shellcheck shell=bash
# SPDX-License-Identifier: MIT
# ui.sh: minimal UI driving over adb (uiautomator dump + input tap). Source it.
# Side effects: writes /data/local/tmp/ui.xml on the device; tap() injects input. Requires: bash, adb; phone unlocked.
uidump() { adb shell -n uiautomator dump /data/local/tmp/ui.xml >/dev/null 2>&1; adb shell -n cat /data/local/tmp/ui.xml | tr -d '\r'; }
uitexts() { uidump | grep -oE '(text|content-desc)="[^"]+"' | sed -E 's/^(text|content-desc)=//' | tr '\n' ' '; echo; }
# tap <exact text or content-desc>
tap() { local b; b=$(uidump | tr '>' '\n' | grep -E "(text|content-desc)=\"$1\"" | head -1 | grep -oE 'bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' | grep -oE '[0-9]+' | tr '\n' ' ')
  [ -z "$b" ] && { echo "tap: '$1' not found"; return 1; }; set -- $b; adb shell -n input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 )); echo "tapped '$1'"; }
shot() { adb exec-out screencap -p > "$1"; }
