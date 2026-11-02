#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Translate NetGuard rules (export XML) into a RethinkDNS bravedns.db (AppInfo table), written to a copy.
Usage: ng2rethink.py <netguard_export.xml> <bravedns.db> [out.db]   (default out: <bravedns.db>.new; the input is never modified)
Written against NetGuard 2.337 exports and RethinkDNS 0.5.8 (codes from upstream FirewallManager.kt).
Put the edited DB back into a Rethink backup and restore it from Rethink's UI; a restore leaves the VPN stopped, start it again.

NetGuard semantics (whitelist_wifi/other=true): wifi/mobile key True = blocked, absent = blocked (default-deny,
manage_system=true). screen_on-only allowances map to blocked (Rethink has no per-app screen-on rule).
Rethink codes: firewallStatus EXCLUDE=3 NONE=5; connectionStatus BOTH=0 (blocked both), UNMETERED=1 (blocked on Wi-Fi),
METERED=2 (blocked on mobile), ALLOW=3. Rules are per uid: shared-uid groups get the most permissive member rule.
"""
import shutil, sqlite3, sys, xml.etree.ElementTree as ET

# ---- configuration: example from the author's setup; adapt before use ----
EXCLUDE = {  # outside the VPN entirely. Android Auto refuses to start when its own uid goes through a VPN;
             # LAN printing needs mDNS. Play services and the Google app worked inside the VPN.
    "com.google.android.projection.gearhead", "com.android.bips", "com.android.printspooler"}
OVERRIDE = {  # packages the NetGuard export doesn't cover: pkg -> (wifi_blocked, mobile_blocked)
    "eu.faircode.netguard": (True, True)}
KEEP = {"com.celzero.bravedns"}             # never touched (Rethink itself)
ALLOW_UIDS = {0, 1013, 1020, 1021, 1051}    # package-less system uids: root, media, mDNS, GPS/XTRA, DNS
# ---------------------------------------------------------------------------

if len(sys.argv) not in (3, 4):
    sys.exit(__doc__)
src_db = sys.argv[2]
out_db = sys.argv[3] if len(sys.argv) == 4 else src_db + ".new"
if out_db == src_db:
    sys.exit("ng2rethink: refusing to write over the input DB")
shutil.copy2(src_db, out_db)

ng = {sec.tag: {s.get("key"): s.get("value") == "true" for s in sec} for sec in ET.parse(sys.argv[1]).getroot()}
db = sqlite3.connect(out_db)
rows = db.execute("select packageName, uid from AppInfo where tombstoneTs=0").fetchall()
def want(p):
    if p in OVERRIDE: return OVERRIDE[p]
    return ng["wifi"].get(p, True), ng["mobile"].get(p, True)
byuid = {}
for p, u in rows: byuid.setdefault(u, []).append(p)
stats = {}
for u, pkgs in byuid.items():
    if set(pkgs) & KEEP: continue
    if u in ALLOW_UIDS: fw, cs = 5, 3
    elif set(pkgs) & EXCLUDE: fw, cs = 3, 3
    else:
        ws = [want(p) for p in pkgs]
        wb = all(w for w, _ in ws); mb = all(m for _, m in ws)   # most permissive in the uid group
        fw, cs = 5, {(True, True): 0, (True, False): 1, (False, True): 2, (False, False): 3}[(wb, mb)]
    db.execute("update AppInfo set firewallStatus=?, connectionStatus=? where uid=?", (fw, cs, u))
    stats[(fw, cs)] = stats.get((fw, cs), 0) + 1
db.commit()
label = {(3, 3): "excluded", (5, 0): "blocked", (5, 1): "Wi-Fi blocked", (5, 2): "mobile blocked", (5, 3): "allowed"}
print("uids:", ", ".join(f"{label[k]}={v}" for k, v in sorted(stats.items())))
print(f"written: {out_db} (input unchanged)")
