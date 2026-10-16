# Development & Maintenance Notes

**English** | [简体中文](DEVELOPMENT.zh-CN.md)

This document records **how the module was designed, why, and how to debug or
fix it**. Read this first if the module stops working.

---

## 1. Target device / environment

| Item | Value |
| --- | --- |
| Device | Xiaomi 13 Pro (`nuwa`) |
| ROM | crDroid / LineageOS-based, Android 16, API 36 |
| Root | KernelSU, `ksud 4.2.0`, `su` version 40900 |
| Metamodule | **none installed** (see §3) |
| Overlays on device | `org.lineageos.frameworkresoverlay.{xiaomi,nuwa}` (platform-signed) |

Verified volume steps at the start of development:

```sh
adb shell dumpsys audio | grep -E '^- STREAM_|Max:'
# MUSIC Max=25, VOICE_CALL Max=15, ALARM Max=15, SYSTEM Max=15, RING/NOTIF Max=7
```

## 2. How the ROM computes volume steps (the core finding)

The values come from `frameworks/base/services/core/java/com/android/server/audio/AudioService.java`
(read at `system_server` startup, roughly lines **1531–1637**):

- **Properties** (read once at boot, priority over resources):
  - `ro.config.media_vol_steps` / `ro.config.media_vol_default`
  - `ro.config.alarm_vol_steps` / `ro.config.alarm_vol_default`
  - `ro.config.system_vol_steps` / `ro.config.system_vol_default`
  - `ro.config.vc_call_vol_steps` / `ro.config.vc_call_vol_default`
  - `ro.config.assistant_vol_min`
- **framework-res integer resources** (package `android`):
  - `config_audio_ring_vol_steps` (`0x010e002d`, default 7)
  - `config_audio_notif_vol_steps` (`0x010e002b`, default 7)
  - `config_audio_alarm_min_vol` (`0x010e0029`)
  - defined in `frameworks/base/core/res/res/values/config.xml`

> Note: this ROM has **no `config_volume_steps` array**, unlike some AOSP/older
> builds. The steps are purely the props + the two ring/notif resources above.

## 3. Design decisions

**Props for Media/Alarm/System/Call → `post-fs-data.sh` + `resetprop -n`.**

- These are read by `system_server`, so they must be set **before Zygote**.
- `post-fs-data` runs before Zygote. Plain `setprop` **deadlocks** the boot in
  this stage, so `resetprop -n` (direct property-area write) is required.
- Result: effective on the **same boot**.

**Ring/Notification → runtime RRO via `cmd overlay fabricate` (`service.sh`).**

- They are resources, not props, so they need an overlay.
- The obvious approach (drop a platform-signed RRO APK in `/product/overlay`)
  does **not** work here: KernelSU only mounts a module's `system/` folder when
  a **metamodule** (e.g. `meta-overlayfs`) is installed, and this device has
  none. So `system/product/overlay/*.apk` would never appear.
- Instead we fabricate the overlay as root at runtime — no mounting, no APK, no
  signature, no extra dependency.
- **Caveat:** `AudioService` caches these at boot, and `service.sh`
  (late_start) runs *after* `system_server`. So the new ring/notif values are
  applied from the **next boot** onward.

**Why the overlay can skip `android:targetName` / platform signing.**

- A **fabricated** overlay is created by root directly through the OverlayManager
  service, bypassing PackageManager scan checks. It is owned by
  `com.android.shell` (hardcoded by AOSP's `OverlayManagerShellCommand`).
- Relevant AOSP shell code: `frameworks/base/services/core/server/om/OverlayManagerShellCommand.java`
  (`runFabricate`, `addOverlayValue`). Note `fabricate` only accepts encoded
  type ids for integers (there is no `"int"` in `TYPE_MAP`); `0x10` ==
  `TypedValue.TYPE_INT_DEC`.

## 4. Live verification / debugging cookbook

Run these while debugging. All are reversible.

```sh
# --- current effective steps ---
adb shell 'dumpsys audio | grep -E "^- STREAM_|Max:"'

# --- properties ---
adb shell 'for p in media alarm system vc_call; do echo "$p=$(getprop ro.config.${p}_vol_steps)"; done'

# --- property write test (KernelSU) ---
adb shell 'su -c "resetprop -n ro.config.media_vol_steps 30; getprop ro.config.media_vol_steps"'

# --- overlay: is it enabled? what value does the framework see? ---
adb shell 'cmd overlay list android | grep volsteps'
adb shell 'cmd overlay lookup android android:integer/config_audio_ring_vol_steps'

# --- fabricate manually (one resource per call; 0x10 = TYPE_INT_DEC) ---
adb shell 'cmd overlay fabricate --target android --name dbg_ring \
    android:integer/config_audio_ring_vol_steps 0x10 20'
adb shell 'cmd overlay enable com.android.shell:dbg_ring'
# cleanup a probe (disable + unregister), see tools/RmOv.java:
adb shell 'su -c "CLASSPATH=/data/local/tmp/unregister.dex app_process /system/bin RmOv com.android.shell:dbg_ring"'
```

Run a module script out of band (root) to test it without installing:

```sh
adb push module /data/local/tmp/vstest
adb shell 'su -c "sh /data/local/tmp/vstest/post-fs-data.sh"'
adb shell 'su -c "sh /data/local/tmp/vstest/service.sh"'
adb shell 'su -c "sh /data/local/tmp/vstest/uninstall.sh"'
```

## 5. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Media/alarm/system/call unchanged | prop not set before `system_server`, or ROM uses a different name | check `getprop`; confirm names in AudioService |
| `resetprop: not found` | not in PATH during script | script falls back to `/data/adb/ksu/bin/resetprop` |
| Ring/notification unchanged | enabled late / `AudioService` cached old value | **reboot once more**; verify with `cmd overlay lookup` |
| `cmd overlay fabricate` fails | resource name wrong for your ROM | confirm `config_audio_ring_vol_steps` exists (see §2) |
| Overlay not applied after install | no metamodule → `system/` not mounted | this module deliberately avoids `system/`, check `service.sh` ran |
| Boot hang | `setprop` used in `post-fs-data` | must use `resetprop -n` |

Useful logs:

```sh
adb logcat -d | grep -iE 'AudioService|OverlayManager|volsteps'
```

## 6. Reverting all changes manually

```sh
# remove module, then reboot — OR, live:
adb shell 'su -c "sh /data/adb/modules/volumesteps/uninstall.sh"'
# props are in-memory only (resetprop -n) and reset on reboot; to force now:
adb shell 'su -c "resetprop -n ro.config.media_vol_steps 25"   # etc.'
adb shell 'su -c "resetprop -d ro.config.media_vol_default"'    # if it did not exist before
rm -f /data/resource-cache/*volsteps_ring* 2>/dev/null
```

## 7. Known limitations

- Ring/notification need one extra reboot after (re)configuring.
- The `unregister.dex` helper is only needed for a tidy uninstall; if it fails,
  the overlays are simply left **disabled** (harmless).
- Resource names are ROM-specific; other ROMs may differ.

## 8. Implementation history

1. Located the ROM's volume-step source in `AudioService.java`.
2. Confirmed values via `dumpsys audio`; found props + two ring/notif resources.
3. Proved overlayability: `cmd overlay fabricate` succeeded and
   `cmd overlay lookup` returned the new value.
4. Found no metamodule ⇒ an `/product/overlay` RRO APK would not mount ⇒ chose
   the runtime `fabricate` path.
5. Built the module: props in `post-fs-data.sh`, overlay in `service.sh`,
   reflection-based unregister helper in `tools/RmOv.java`.
6. Validated every script live on-device, then reverted the device to stock.
