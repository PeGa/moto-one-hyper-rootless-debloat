<!-- SPDX-License-Identifier: CC-BY-NC-SA-4.0 -->
# Stock packages by function: XT2027-1, `RPFS31.Q1-21-20-10`

Technical inventory of the 329 packages present for user 0 at baseline (fresh factory reset, setup completed). Not a recipe: "removed" records what this project removed, not what anyone should remove.

Columns: **d** = disabled at the factory; **u** = updated system app at baseline (update layer in `/data/app` over the factory APK, listed under `Hidden system packages:`; `install-existing` after a `--user 0` removal restores the updated version, AGENTS §3.1); **r** = removed for user 0 in this project (`pm uninstall -k --user 0`, still removed at the end); **refusal** = refusal message observed (see `docs/01-baseline-and-removal.md`); **third-party** = listed by `pm list packages -3`. Notes only where the project established the fact.

## AOSP framework, providers and system apps (71)

| Package | d | u | r | refusal | note |
|---|---|---|---|---|---|
| `android` |  |  |  |  |  |
| `com.android.backupconfirm` |  |  |  |  |  |
| `com.android.bips` |  |  |  |  | default print service |
| `com.android.bluetooth` |  |  |  |  |  |
| `com.android.bluetoothmidiservice` |  |  | r |  |  |
| `com.android.bookmarkprovider` |  |  | r |  |  |
| `com.android.calllogbackup` |  |  |  |  |  |
| `com.android.carrierconfig` |  |  |  |  |  |
| `com.android.carrierdefaultapp` |  |  |  |  |  |
| `com.android.cellbroadcastreceiver` |  |  |  |  |  |
| `com.android.certinstaller` |  |  |  |  |  |
| `com.android.chrome` |  | u | r |  |  |
| `com.android.companiondevicemanager` |  |  |  |  |  |
| `com.android.cts.ctsshim` |  |  |  |  |  |
| `com.android.cts.priv.ctsshim` |  |  |  |  |  |
| `com.android.dreams.basic` |  |  | r |  |  |
| `com.android.dynsystem` |  |  | r |  |  |
| `com.android.egg` |  |  | r |  |  |
| `com.android.emergency` |  |  |  |  |  |
| `com.android.externalstorage` |  |  |  |  |  |
| `com.android.hotwordenrollment.okgoogle` |  |  | r |  |  |
| `com.android.hotwordenrollment.xgoogle` |  |  | r |  |  |
| `com.android.htmlviewer` |  |  |  |  |  |
| `com.android.inputdevices` |  |  |  |  |  |
| `com.android.keychain` |  |  |  |  |  |
| `com.android.localtransport` |  |  |  |  |  |
| `com.android.location.fused` |  |  |  |  |  |
| `com.android.managedprovisioning` |  |  | r |  | managed device/profile provisioning |
| `com.android.mms.service` |  |  |  |  |  |
| `com.android.mtp` |  |  |  |  |  |
| `com.android.nfc` |  |  |  |  |  |
| `com.android.ons` |  |  |  |  |  |
| `com.android.pacprocessor` |  |  |  |  |  |
| `com.android.phone` |  |  |  |  |  |
| `com.android.printspooler` |  |  |  |  | print spooler; Settings → Connection preferences queries it |
| `com.android.providers.blockednumber` |  |  |  |  |  |
| `com.android.providers.calendar` |  |  |  |  |  |
| `com.android.providers.contacts` |  |  |  |  |  |
| `com.android.providers.downloads` |  |  |  |  |  |
| `com.android.providers.downloads.ui` |  |  |  |  |  |
| `com.android.providers.media` |  |  |  |  |  |
| `com.android.providers.partnerbookmarks` |  |  | r |  |  |
| `com.android.providers.settings` |  |  |  |  |  |
| `com.android.providers.telephony` |  |  |  |  |  |
| `com.android.providers.userdictionary` |  |  |  |  |  |
| `com.android.proxyhandler` |  |  |  |  |  |
| `com.android.se` |  |  |  |  |  |
| `com.android.server.telecom` |  |  |  |  |  |
| `com.android.service.ims` |  |  | r |  |  |
| `com.android.settings` |  |  |  |  |  |
| `com.android.settings.intelligence` |  |  |  |  |  |
| `com.android.sharedstoragebackup` |  |  |  |  |  |
| `com.android.shell` |  |  |  |  |  |
| `com.android.simappdialog` |  |  |  |  |  |
| `com.android.soundpicker` |  |  |  |  |  |
| `com.android.statementservice` |  |  |  |  |  |
| `com.android.stk` |  |  |  |  |  |
| `com.android.storagemanager` |  |  |  |  |  |
| `com.android.systemui` |  |  |  |  |  |
| `com.android.systemui.plugin.globalactions.wallet` |  |  | r |  |  |
| `com.android.systemuiattoverlay` |  |  |  |  |  |
| `com.android.systemuisprintoverlay` |  |  |  |  |  |
| `com.android.systemuitmooverlay` |  |  |  |  |  |
| `com.android.systemuiusccoverlay` |  |  |  |  |  |
| `com.android.systemuivzwoverlay` |  |  |  |  |  |
| `com.android.traceur` |  |  | r |  |  |
| `com.android.vpndialogs` |  |  |  |  |  |
| `com.android.wallpaper` |  |  |  |  |  |
| `com.android.wallpaper.livepicker` |  |  | r |  |  |
| `com.android.wallpaperbackup` |  |  |  |  |  |
| `com.android.wallpapercropper` |  |  |  |  |  |

## Google platform: mainline modules, WebView, Play services (22)

| Package | d | u | r | refusal | note |
|---|---|---|---|---|---|
| `com.android.vending` |  | u | r |  | Play Store; self-updates and updates system apps without an account |
| `com.google.android.captiveportallogin` |  |  |  |  |  |
| `com.google.android.cellbroadcastreceiver` |  |  |  |  |  |
| `com.google.android.cellbroadcastservice` |  |  |  |  |  |
| `com.google.android.documentsui` |  |  |  |  |  |
| `com.google.android.ext.services` |  |  |  |  |  |
| `com.google.android.ext.shared` |  |  |  |  |  |
| `com.google.android.gms` |  | u |  |  | Google Play services; shared uid with GSF |
| `com.google.android.gms.location.history` |  |  | r |  |  |
| `com.google.android.gsf` |  |  |  |  | Google Services Framework; shared uid with GMS |
| `com.google.android.hotspot2.osulogin` |  |  |  |  |  |
| `com.google.android.modulemetadata` |  |  |  |  |  |
| `com.google.android.networkstack` |  |  |  |  |  |
| `com.google.android.networkstack.permissionconfig` |  |  |  |  |  |
| `com.google.android.networkstack.tethering` |  |  |  |  |  |
| `com.google.android.packageinstaller` |  |  |  |  |  |
| `com.google.android.permissioncontroller` |  |  |  |  |  |
| `com.google.android.providers.media.module` |  |  |  |  |  |
| `com.google.android.tag` |  |  |  |  |  |
| `com.google.android.webview` |  | u |  |  | WebView provider (standalone) |
| `com.google.android.wifi.resources` |  |  |  |  |  |
| `com.google.mainline.telemetry` |  |  | r |  |  |

## Google apps (48)

| Package | d | u | r | refusal | note |
|---|---|---|---|---|---|
| `com.google.android.apps.carrier.carrierwifi` |  | u | r |  |  |
| `com.google.android.apps.chromecast.app` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.docs` |  | u | r |  |  |
| `com.google.android.apps.docs.editors.docs` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.docs.editors.sheets` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.docs.editors.slides` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.fitness` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.googleassistant` |  | u | r |  |  |
| `com.google.android.apps.magazines` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.maps` |  | u |  |  |  |
| `com.google.android.apps.messaging` |  | u | r |  |  |
| `com.google.android.apps.nbu.files` |  | u | r |  |  |
| `com.google.android.apps.photos` |  | u | r |  |  |
| `com.google.android.apps.restore` |  |  | r |  |  |
| `com.google.android.apps.subscriptions.red` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.tachyon` |  | u | r |  |  |
| `com.google.android.apps.turbo` |  |  | r |  |  |
| `com.google.android.apps.walletnfcrel` |  |  | r |  | third-party; preload installed by setup into /data/app; no factory copy |
| `com.google.android.apps.wallpaper` |  |  |  |  |  |
| `com.google.android.apps.wellbeing` |  | u | r |  |  |
| `com.google.android.apps.work.oobconfig` |  |  |  | protected | zero-touch provisioning; crashes once at boot without GSF |
| `com.google.android.apps.youtube.music` |  | u | r |  |  |
| `com.google.android.apps.youtube.music.setupwizard` |  |  | r |  |  |
| `com.google.android.as` |  | u | r |  |  |
| `com.google.android.calculator` |  | u | r |  |  |
| `com.google.android.calendar` |  | u | r |  |  |
| `com.google.android.carrier` |  |  |  |  | carrier settings; supplies the network-name display config |
| `com.google.android.configupdater` |  |  | r |  |  |
| `com.google.android.contacts` |  | u | r |  |  |
| `com.google.android.deskclock` |  | u |  |  |  |
| `com.google.android.dialer` |  | u |  |  | Telecom system-dialer fallback before the first unlock |
| `com.google.android.feedback` |  |  | r |  |  |
| `com.google.android.gm` |  | u | r |  |  |
| `com.google.android.googlequicksearchbox` |  | u |  |  | Google app; Android Auto voice |
| `com.google.android.ims` | d | u | r |  |  |
| `com.google.android.inputmethod.latin` |  | u | r |  |  |
| `com.google.android.marvin.talkback` |  | u | r |  |  |
| `com.google.android.onetimeinitializer` |  |  | r |  |  |
| `com.google.android.partnersetup` |  | u | r |  |  |
| `com.google.android.printservice.recommendation` |  |  | r |  |  |
| `com.google.android.projection.gearhead` |  | u |  |  | Android Auto |
| `com.google.android.setupwizard` |  |  | r |  |  |
| `com.google.android.syncadapters.contacts` |  |  | r |  |  |
| `com.google.android.tts` |  | u |  |  | Speech Services; Android Auto checks for it by package name |
| `com.google.android.videos` |  | u | r |  |  |
| `com.google.android.wfcactivation` |  |  | r |  |  |
| `com.google.android.youtube` |  | u | r |  |  |
| `com.google.ar.core` |  | u | r |  |  |

## Qualcomm (17)

| Package | d | u | r | refusal | note |
|---|---|---|---|---|---|
| `com.qti.qualcomm.datastatusnotification` |  |  |  |  |  |
| `com.qualcomm.atfwd` |  |  |  |  |  |
| `com.qualcomm.embms` |  |  | r |  |  |
| `com.qualcomm.location` |  |  | r |  | Qualcomm network location provider (Izat) |
| `com.qualcomm.qcrilmsgtunnel` |  |  |  |  |  |
| `com.qualcomm.qti.cne` |  |  |  |  |  |
| `com.qualcomm.qti.devicestatisticsservice` |  |  |  |  |  |
| `com.qualcomm.qti.dynamicddsservice` |  |  | r |  |  |
| `com.qualcomm.qti.remoteSimlockAuth` |  |  | r |  |  |
| `com.qualcomm.qti.telephonyservice` |  |  |  |  |  |
| `com.qualcomm.qti.uceShimService` |  |  | r |  |  |
| `com.qualcomm.qti.uim` |  |  |  |  |  |
| `com.qualcomm.qti.uimGbaApp` |  |  | r |  |  |
| `com.qualcomm.timeservice` |  |  |  |  |  |
| `org.codeaurora.ims` |  |  | r |  |  |
| `vendor.qti.hardware.cacert.server` |  |  |  |  |  |
| `vendor.qti.iwlan` |  |  | r |  |  |

## Motorola (68)

| Package | d | u | r | refusal | note |
|---|---|---|---|---|---|
| `android.autoinstalls.config.motorola.layout` |  | u | r |  |  |
| `com.motorola.VirtualUiccPayment` |  |  | r |  |  |
| `com.motorola.actions` |  |  |  |  | Moto gestures (chop flashlight) |
| `com.motorola.android.fmradio` |  |  |  |  |  |
| `com.motorola.android.fota` |  |  | r |  |  |
| `com.motorola.android.jvtcmd` |  |  |  |  |  |
| `com.motorola.android.nativedropboxagent` |  |  | r |  |  |
| `com.motorola.android.providers.chromehomepage` |  |  | r |  |  |
| `com.motorola.android.providers.settings` |  |  |  |  |  |
| `com.motorola.android.provisioning` |  |  | r |  |  |
| `com.motorola.appdirectedsmsproxy` |  |  | r |  |  |
| `com.motorola.att.phone.extensions` | d |  | r |  |  |
| `com.motorola.attvowifi` |  |  | r |  |  |
| `com.motorola.bach.modemstats` |  |  | r |  |  |
| `com.motorola.brapps` |  |  | r |  |  |
| `com.motorola.bug2go` |  |  | r |  |  |
| `com.motorola.callredirectionservice` |  |  | r |  |  |
| `com.motorola.camera2` |  |  |  |  |  |
| `com.motorola.camera2.content.ai` |  |  |  |  |  |
| `com.motorola.carrierconfig` | d |  |  |  |  |
| `com.motorola.carriersettingsext` |  |  |  |  | carrier/channel customization |
| `com.motorola.ccc.devicemanagement` |  |  | r |  |  |
| `com.motorola.ccc.mainplm` |  |  | r |  |  |
| `com.motorola.ccc.notification` |  | u | r |  |  |
| `com.motorola.ccc.ota` |  |  |  | protected | OTA client; boot receiver crashes once per boot when background-restricted and off the system allowlist |
| `com.motorola.contacts.preloadcontacts` |  |  | r |  |  |
| `com.motorola.coresettingsext` |  |  |  |  |  |
| `com.motorola.demo` |  |  | r |  |  |
| `com.motorola.dolby.dolbyui` |  |  |  |  | Dolby audio UI |
| `com.motorola.dynamicvolume` |  |  |  |  |  |
| `com.motorola.easyprefix` | d |  | r |  |  |
| `com.motorola.entitlement` |  |  | r |  |  |
| `com.motorola.fmplayer` |  |  |  |  |  |
| `com.motorola.gamemode` |  | u | r |  |  |
| `com.motorola.genie` |  | u | r |  |  |
| `com.motorola.gesture` |  |  | r |  |  |
| `com.motorola.help` |  | u | r |  |  |
| `com.motorola.hiddenmenuapp` |  |  | r |  |  |
| `com.motorola.imagertuning_V2` |  | u |  |  |  |
| `com.motorola.invisiblenet` |  |  | r |  |  |
| `com.motorola.iqimotmetrics` | d |  | r |  |  |
| `com.motorola.launcher3` |  |  |  |  | stock launcher; provides Recents (Quickstep `recentsComponentName`) |
| `com.motorola.launcherconfig` |  |  |  | non-disable |  |
| `com.motorola.lifetimedata` |  |  | r |  |  |
| `com.motorola.livewallpaper3` |  |  | r |  |  |
| `com.motorola.moto` |  |  | r |  |  |
| `com.motorola.motocare` |  |  | r |  |  |
| `com.motorola.motocit` |  |  | r |  |  |
| `com.motorola.motodisplay` |  | u |  |  | ambient display; puts the touch controller in gesture mode (double-tap-to-wake) |
| `com.motorola.motolights.rearlights` |  |  | r |  |  |
| `com.motorola.motosignature.app` | d |  | r |  |  |
| `com.motorola.msimsettings` |  |  |  |  |  |
| `com.motorola.nfc` |  |  |  |  |  |
| `com.motorola.nfwlocationattribution` |  |  |  |  |  |
| `com.motorola.omadm.service` |  |  | r |  |  |
| `com.motorola.omadm.vzw` | d |  | r |  |  |
| `com.motorola.paks` | d |  |  | protected |  |
| `com.motorola.photoeditor` |  |  | r |  |  |
| `com.motorola.rcsConfigService` |  |  | r |  |  |
| `com.motorola.screenshoteditor` |  |  |  |  |  |
| `com.motorola.settings` | d |  | r |  |  |
| `com.motorola.setup` |  |  | r |  |  |
| `com.motorola.slpc_sys` |  |  |  |  |  |
| `com.motorola.systemserver` |  |  |  |  |  |
| `com.motorola.telprov` |  |  |  |  |  |
| `com.motorola.timeweatherwidget` |  | u | r |  |  |
| `com.motorola.vzw.pco.extensions.pcoreceiver` |  |  | r |  |  |
| `com.motorola.wifi.motowifimetrics` |  |  | r |  |  |

## Other vendors and preloads (11)

| Package | d | u | r | refusal | note |
|---|---|---|---|---|---|
| `com.amazon.appmanager` | d |  |  | non-disable |  |
| `com.att.iqi` | d |  | r |  |  |
| `com.dolby.daxservice` |  |  |  |  | Dolby audio service; PERSISTENT (standby bucket stays 10) |
| `com.facebook.appmanager` | d |  | r |  |  |
| `com.facebook.katana` |  |  | r |  | third-party; stub preload on /product |
| `com.facebook.services` | d |  | r |  |  |
| `com.facebook.system` | d |  | r |  |  |
| `com.lenovo.lsf.user` |  |  | r |  |  |
| `com.roaming.android.gsimbase` |  |  |  | DEVICE_POLICY_MANAGER |  |
| `com.roaming.android.gsimcontentprovider` |  |  |  | DEVICE_POLICY_MANAGER |  |
| `com.summit.motorola.rcs` |  |  | r |  |  |

## Overlays and resource packages (92)

| Package | d | u | r | refusal | note |
|---|---|---|---|---|---|
| `android.auto_generated_rro_product__` |  |  |  |  |  |
| `android.auto_generated_rro_vendor__` |  |  |  |  |  |
| `com.android.cellbroadcast.overlay` |  |  |  |  |  |
| `com.android.cellbroadcastservice.overlay` |  |  |  |  |  |
| `com.android.internal.display.cutout.emulation.corner` |  |  |  |  |  |
| `com.android.internal.display.cutout.emulation.double` |  |  |  |  |  |
| `com.android.internal.display.cutout.emulation.hole` |  |  |  |  |  |
| `com.android.internal.display.cutout.emulation.noCutout` |  |  |  |  |  |
| `com.android.internal.display.cutout.emulation.tall` |  |  |  |  |  |
| `com.android.internal.display.cutout.emulation.waterfall` |  |  |  |  |  |
| `com.android.internal.systemui.navbar.gestural` |  |  |  |  |  |
| `com.android.internal.systemui.navbar.gestural_extra_wide_back` |  |  |  |  |  |
| `com.android.internal.systemui.navbar.gestural_narrow_back` |  |  |  |  |  |
| `com.android.internal.systemui.navbar.gestural_wide_back` |  |  |  |  |  |
| `com.android.internal.systemui.navbar.threebutton` |  |  |  |  |  |
| `com.android.phone.overlay.carriersettings` |  |  |  |  |  |
| `com.android.phone.overlay.common` |  |  |  |  |  |
| `com.android.phone.overlay.motcommon` |  |  |  |  |  |
| `com.android.providers.settings.auto_generated_rro_product__` |  |  |  |  |  |
| `com.android.providers.settings.auto_generated_rro_vendor__` |  |  |  |  |  |
| `com.android.providers.telephony.overlay.carriersettings` |  |  |  |  |  |
| `com.android.settings.auto_generated_rro_product__` |  |  |  |  |  |
| `com.android.settings.auto_generated_rro_vendor__` |  |  |  |  |  |
| `com.android.settings.overlay.filesgoogle` |  |  |  |  |  |
| `com.android.systemui.auto_generated_rro_product__` |  |  |  |  |  |
| `com.android.systemui.auto_generated_rro_vendor__` |  |  |  |  |  |
| `com.android.theme.color.black` |  |  |  |  |  |
| `com.android.theme.color.brown` |  |  |  |  |  |
| `com.android.theme.color.cherry` |  |  |  |  |  |
| `com.android.theme.color.cinnamon` |  |  |  |  |  |
| `com.android.theme.color.darklake` |  |  |  |  |  |
| `com.android.theme.color.dorange` |  |  |  |  |  |
| `com.android.theme.color.dpurple` |  |  |  |  |  |
| `com.android.theme.color.green` |  |  |  |  |  |
| `com.android.theme.color.lgreen` |  |  |  |  |  |
| `com.android.theme.color.magentahaze` |  |  |  |  |  |
| `com.android.theme.color.ocean` |  |  |  |  |  |
| `com.android.theme.color.orchid` |  |  |  |  |  |
| `com.android.theme.color.parasailing` |  |  |  |  |  |
| `com.android.theme.color.purple` |  |  |  |  |  |
| `com.android.theme.color.saffron` |  |  |  |  |  |
| `com.android.theme.color.slate` |  |  |  |  |  |
| `com.android.theme.color.space` |  |  |  |  |  |
| `com.android.theme.font.barlowsource` |  |  |  |  |  |
| `com.android.theme.font.notoserifsource` |  |  |  |  |  |
| `com.android.theme.font.quicksandsource` |  |  |  |  |  |
| `com.android.theme.icon.pebble` |  |  |  |  |  |
| `com.android.theme.icon.roundedrect` |  |  |  |  |  |
| `com.android.theme.icon.squircle` |  |  |  |  |  |
| `com.android.theme.icon.taperedrect` |  |  |  |  |  |
| `com.android.theme.icon.teardrop` |  |  |  |  |  |
| `com.android.theme.icon.vessel` |  |  |  |  |  |
| `com.android.theme.icon_pack.circular.android` |  |  |  |  |  |
| `com.android.theme.icon_pack.circular.launcher` |  |  |  |  |  |
| `com.android.theme.icon_pack.circular.settings` |  |  |  |  |  |
| `com.android.theme.icon_pack.circular.systemui` |  |  |  |  |  |
| `com.android.theme.icon_pack.circular.themepicker` |  |  |  |  |  |
| `com.android.theme.icon_pack.filled.android` |  |  |  |  |  |
| `com.android.theme.icon_pack.filled.launcher` |  |  |  |  |  |
| `com.android.theme.icon_pack.filled.settings` |  |  |  |  |  |
| `com.android.theme.icon_pack.filled.systemui` |  |  |  |  |  |
| `com.android.theme.icon_pack.filled.themepicker` |  |  |  |  |  |
| `com.android.theme.icon_pack.rounded.android` |  |  |  |  |  |
| `com.android.theme.icon_pack.rounded.launcher` |  |  |  |  |  |
| `com.android.theme.icon_pack.rounded.settings` |  |  |  |  |  |
| `com.android.theme.icon_pack.rounded.systemui` |  |  |  |  |  |
| `com.android.theme.icon_pack.rounded.themepicker` |  |  |  |  |  |
| `com.android.wifi.resources.overlay.motCommon` |  |  |  |  |  |
| `com.google.android.overlay.gmsconfig.common` |  |  |  |  |  |
| `com.google.android.overlay.gmsconfig.comms` |  |  |  |  |  |
| `com.google.android.overlay.gmsconfig.gsa` |  |  |  |  |  |
| `com.google.android.overlay.gmsconfig.photos` |  |  |  |  |  |
| `com.google.android.overlay.modules.documentsui` |  |  |  |  |  |
| `com.google.android.overlay.modules.ext.services` |  |  |  |  |  |
| `com.google.android.overlay.modules.modulemetadata.forframework` |  |  |  |  |  |
| `com.google.android.overlay.modules.permissioncontroller` |  |  |  |  |  |
| `com.google.android.overlay.modules.permissioncontroller.forframework` |  |  |  |  |  |
| `com.motorola.android.networkstack.tethering.overlay.motCommon` |  |  |  |  |  |
| `com.motorola.android.providers.settings.auto_generated_rro_product__` |  |  |  |  |  |
| `com.motorola.android.providers.settings.auto_generated_rro_vendor__` |  |  |  |  |  |
| `com.motorola.common.overlay` |  |  |  |  |  |
| `com.motorola.launcherconfig.overlay.amxar` | d |  | r |  |  |
| `com.motorola.launcherconfig.overlay.amxbr` | d |  | r |  |  |
| `com.motorola.launcherconfig.overlay.amxcl` | d |  | r |  |  |
| `com.motorola.launcherconfig.overlay.amxco` | d |  | r |  |  |
| `com.motorola.launcherconfig.overlay.amxla` | d |  | r |  |  |
| `com.motorola.launcherconfig.overlay.amxmx` | d |  | r |  |  |
| `com.motorola.launcherconfig.overlay.amxpe` | d |  | r |  |  |
| `com.motorola.overlay.googledps` |  |  |  |  |  |
| `com.motorola.setup.auto_generated_rro_vendor__` |  |  |  |  |  |
| `com.motorola.setup.overlay.amx` | d |  | r |  |  |
| `com.motorola.setup.overlay.pai` | d |  | r |  |  |
