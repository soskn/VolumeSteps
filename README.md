# Volume Steps

**English** | [简体中文](README.zh-CN.md)

A KernelSU / Magisk module that tunes Android **volume step counts** — how many
"clicks" each volume-key press maps to.

> Tested on a Xiaomi 13 Pro (nuwa) running Android 16 (API 36) with KernelSU.

---

## Features

- Raise the number of steps for **Media** (music/video/games), **Alarm**,
  **System** and **In-call** volume.
- Adjust **Ringtone** and **Notification** steps as well.
- All values are configurable in a single file (`config.sh`).
- No system files are modified; fully systemless and reversible.
- Clean uninstall — the overlays it creates are fully removed.

## How it works

This module mirrors how the ROM's own `AudioService` reads volume steps.

| Stream | Source of truth | Applied |
| --- | --- | --- |
| Media / Alarm / System / Call | System properties `ro.config.*_vol_steps` | Same boot |
| Ringtone / Notification | framework-res integers `config_audio_ring_vol_steps`, `config_audio_notif_vol_steps` | Next boot |

- **Properties** are set with `resetprop -n` in the `post-fs-data` stage, before
  Zygote / `system_server` starts.
- **Ringtone / Notification** are framework resources, not properties, so they
  are changed with a **root-fabricated Runtime Resource Overlay**
  (`cmd overlay fabricate`). Because `AudioService` caches these at boot, the
  change is visible from the **second boot** after installation.

> Why not ship an overlay APK in `/product/overlay`? KernelSU only mounts a
> module's `system/` folder when a **metamodule** (e.g. `meta-overlayfs`) is
> installed. To stay dependency-free, this module fabricates the overlay at
> runtime with root instead.

## Requirements

- KernelSU (or Magisk) with root.
- Android 11+ (tested on 16).
- The ROM must derive these values the same way (the standard AOSP
  `AudioService` behaviour).

## Disclaimer / 兼容性与风险

This module has only been tested on the author's device/ROM (for example: Xiaomi 13 Pro, Android 16, KernelSU). Use at your own risk. Back up your device before installing. Installation or use may cause system instability or render the device unbootable. The author and contributors are not liable for any damage, data loss, or other loss that may result from using this software.

兼容性与风险说明

- 测试范围：本模块仅在作者用于开发测试的设备/ROM（例如：Xiaomi 13 Pro，Android 16，KernelSU）上验证。不同厂商或定制 ROM 可能使用不同的资源名或实现，从而导致不兼容或副作用。
- 操作风险：模块在引导阶段修改系统属性并通过 RRO 修改 framework 资源。错误使用可能导致系统声音异常或更严重的问题（包括无法开机）。安装前请备份重要数据或完整镜像（例如 TWRP 备份）。
- 免责声明：本项目按“原样”提供；作者对因使用本模块造成的任何损失不承担责任。
- 报告问题：请在 issue 中提供设备型号、Android 版本、ROM 名称/构建号、模块版本以及相关日志（logcat、dmesg、bootlog）。

Some parts of this repository were developed with assistance from an AI code assistant (e.g., GitHub Copilot). The author reviewed and tested the resulting code.

本仓库的部分实现/帮助由智能体（例如：GitHub Copilot）辅助完成。最终代码由作者审查并测试。

## Maintenance / 维护状态

This project is maintained as "low maintenance". The author does not plan to actively maintain it long-term. Contributions (issues and pull requests) are welcome; maintainers may prioritize pull requests that include device/ROM-specific testing or fixes. Issues without sufficient diagnostic information may be closed if they cannot be investigated.

本项目处于“低维护”状态。作者不打算长期主动维护，但欢迎贡献（Issue/PR）。带有设备/ROM 测试信息或复现步骤的 PR 会更受欢迎；缺少诊断信息的 Issue 可能会被关闭。

## Installation

1. Download the latest `VolumeSteps-*.zip` from the Releases page.
2. Install it in the KernelSU (or Magisk) manager, then reboot.
3. (Optional) Edit `/data/adb/modules/volumesteps/config.sh` to change values,
   then reboot.

CLI install:

```sh
adb push VolumeSteps-1.0.zip /data/local/tmp/
adb shell 'su -c "/data/adb/ksud module install /data/local/tmp/VolumeSteps-1.0.zip"'
adb reboot
```

## Configuration

Edit `/data/adb/modules/volumesteps/config.sh`:

```sh
MEDIA_VOL_STEPS=30     # media
ALARM_VOL_STEPS=15     # alarm
SYSTEM_VOL_STEPS=15    # system
VOICE_VOL_STEPS=15     # in-call
RING_VOL_STEPS=20      # ringtone
NOTIF_VOL_STEPS=20     # notification
```

Reboot to apply. Ringtone/Notification need one extra reboot (see above).

## Uninstall

Remove the module in the manager (or delete
`/data/adb/modules/volumesteps`) and reboot. The `uninstall.sh` hook disables
and fully unregisters the fabricated overlays.

## Building

```sh
# 1) (Only needed if you change the helper) rebuild the DEX
D8=/path/to/d8 ./tools/build-dex.sh

# 2) Build the flashable zip
./build.sh            # -> dist/VolumeSteps-<version>.zip
```

## Repository layout

```
.
├── build.sh                     # package the module
├── module/                      # module payload (goes into the zip)
│   ├── module.prop
│   ├── config.sh                # user configuration
│   ├── customize.sh             # installer hook
│   ├── post-fs-data.sh          # set properties
│   ├── service.sh               # create ring/notif overlay
│   ├── uninstall.sh             # cleanup
│   └── bin/unregister.dex       # compiled helper
├── tools/
│   ├── RmOv.java                # source of the overlay unregister helper
│   └── build-dex.sh             # compile the helper
└── .github/workflows/release.yml
```

## Notes

- On this ROM the resources are named `config_audio_ring_vol_steps` /
  `config_audio_notif_vol_steps`; other ROMs may name them differently.
- `resetprop` must run before `system_server`, which is why it lives in
  `post-fs-data.sh` and uses `-n` (plain `setprop` deadlocks the boot).

## Credits

- KernelSU / Magisk for the module framework.
- AOSP `AudioService` for the volume-step logic.

## License

MIT — see [LICENSE](LICENSE).
