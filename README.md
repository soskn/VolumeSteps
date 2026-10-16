# Volume Steps

A KernelSU / Magisk module that tunes Android **volume step counts** — how many
"clicks" each volume key press maps to. / 一个用于调整 Android **音量阶梯数量**（每次按音量键对应的档位细分）的 KernelSU / Magisk 模块。

> Tested on a Xiaomi 13 (nuwa) running Android 16 (API 36) with KernelSU.
> / 已在 Xiaomi 13（nuwa）、Android 16（API 36）、KernelSU 环境实测通过。

---

## Features / 功能

- Raise the number of steps for **Media** (music/video/games), **Alarm**,
  **System** and **In-call** volume. / 提升 **媒体**（音乐/视频/游戏）、**闹钟**、**系统**、**通话** 音量的档位数量。
- Adjust **Ringtone** and **Notification** steps as well. / 同时可调整 **铃声** 与 **通知** 的档位数量。
- All values are configurable in a single file (`config.sh`). / 所有数值都在单个文件（`config.sh`）中配置。
- No system files are modified; fully systemless and reversible. / 不修改系统文件，完全 systemless、可逆。
- Clean uninstall — the overlays it creates are fully removed. / 卸载干净——模块创建的叠加层会被彻底移除。

## How it works / 工作原理

This module mirrors how the ROM's own `AudioService` reads volume steps. / 本模块复刻了 ROM 自身 `AudioService` 读取音量阶梯的方式。

| Stream / 音频流 | Source of truth / 来源 | Applied / 生效时机 |
| --- | --- | --- |
| Media / Alarm / System / Call / 媒体·闹钟·系统·通话 | System properties `ro.config.*_vol_steps` / 系统属性 | Same boot / 本次开机 |
| Ringtone / Notification / 铃声·通知 | framework-res integer resources `config_audio_ring_vol_steps`, `config_audio_notif_vol_steps` / framework-res 整型资源 | Next boot / 下次开机 |

- **Properties** are set with `resetprop -n` in the `post-fs-data` stage, before
  Zygote / `system_server` starts. / **属性**在 `post-fs-data` 阶段用 `resetprop -n` 设置，早于 Zygote / `system_server`。
- **Ringtone / Notification** are framework resources, not properties, so they
  are changed with a **root-fabricated Runtime Resource Overlay** (`cmd overlay fabricate`).
  Because `AudioService` caches these at boot, the change is visible from the
  **second boot** after installation. / **铃声/通知**是 framework 资源而非属性，因此通过 **root 直接 fabricate 的 RRO 叠加层**（`cmd overlay fabricate`）修改。由于 `AudioService` 会在开机时缓存这两项，安装后的 **第二次开机** 才会生效。

> Why not ship an overlay APK in `/product/overlay`? KernelSU only mounts a
> module's `system/` folder when a **metamodule** (e.g. `meta-overlayfs`) is
> installed. To stay dependency-free, this module fabricates the overlay at
> runtime with root instead. / 为什么不直接在 `/product/overlay` 放一个叠加层 APK？因为只有安装了 **metamodule**（如 `meta-overlayfs`）时 KernelSU 才会挂载模块的 `system/` 目录。为免依赖，本模块改用 root 在运行时直接 fabricate 叠加层。

## Requirements / 环境要求

- KernelSU (or Magisk) with root. / 已 root 的 KernelSU（或 Magisk）。
- Android 11+ (tested on 16). / Android 11+（已在 16 上测试）。
- The ROM must derive these values the same way (the standard AOSP
  `AudioService` behaviour). / ROM 需采用相同机制（标准 AOSP `AudioService` 行为）。

## Installation / 安装

1. Download the latest `VolumeSteps-*.zip` from the Releases page. / 从 Releases 页面下载最新的 `VolumeSteps-*.zip`。
2. Install it in the KernelSU (or Magisk) manager, then reboot. / 在 KernelSU（或 Magisk）管理器中安装，然后重启。
3. （可选）编辑 `/data/adb/modules/volumesteps/config.sh` 调整数值，再重启。

CLI install / 命令行安装:

```sh
adb push VolumeSteps-1.0.zip /data/local/tmp/
adb shell 'su -c "/data/adb/ksud module install /data/local/tmp/VolumeSteps-1.0.zip"'
adb reboot
```

## Configuration / 配置

Edit `/data/adb/modules/volumesteps/config.sh`: / 编辑 `/data/adb/modules/volumesteps/config.sh`：

```sh
MEDIA_VOL_STEPS=30     # media / 媒体
ALARM_VOL_STEPS=15     # alarm / 闹钟
SYSTEM_VOL_STEPS=15    # system / 系统
VOICE_VOL_STEPS=15     # in-call / 通话
RING_VOL_STEPS=20      # ringtone / 铃声
NOTIF_VOL_STEPS=20     # notification / 通知
```

Reboot to apply. Ringtone/Notification need one extra reboot (see above). / 重启生效；铃声/通知需额外重启一次（见上）。

## Uninstall / 卸载

Remove the module in the manager (or delete
`/data/adb/modules/volumesteps`) and reboot. The
`uninstall.sh` hook disables and fully unregisters the fabricated overlays. /
在管理器中移除模块（或删除 `/data/adb/modules/volumesteps`）并重启。
`uninstall.sh` 会停用并彻底注销所创建的叠加层。

## Building / 构建

```sh
# 1) (Only needed if you change the helper) rebuild the DEX / 仅在改动辅助程序时需要
D8=/path/to/d8 ./tools/build-dex.sh

# 2) Build the flashable zip / 构建可刷入 zip
./build.sh            # -> dist/VolumeSteps-<version>.zip
```

## Repository layout / 仓库结构

```
.
├── build.sh                     # package the module / 打包模块
├── module/                      # module payload (goes into the zip)
│   ├── module.prop
│   ├── config.sh                # user configuration / 用户配置
│   ├── customize.sh             # installer hook / 安装钩子
│   ├── post-fs-data.sh          # set properties / 设置属性
│   ├── service.sh               # create ring/notif overlay / 创建铃声通知叠加层
│   ├── uninstall.sh             # cleanup / 清理
│   └── bin/unregister.dex       # compiled helper / 编译后的辅助程序
├── tools/
│   ├── RmOv.java                # source of the overlay unregister helper / 辅助程序源码
│   └── build-dex.sh             # compile the helper / 编译辅助程序
└── .github/workflows/release.yml
```

## Notes / 注意事项

- On this ROM the resource is named `config_audio_ring_vol_steps` /
  `config_audio_notif_vol_steps`; other ROMs may name them differently. / 本 ROM 中资源名为 `config_audio_ring_vol_steps` / `config_audio_notif_vol_steps`，其他 ROM 可能不同。
- `resetprop` must run before `system_server`, which is why it lives in
  `post-fs-data.sh` and uses `-n` (plain `setprop` deadlocks the boot). / `resetprop` 必须在 `system_server` 之前运行，因此放在 `post-fs-data.sh` 且使用 `-n`（普通 `setprop` 会导致开机死锁）。

## Credits / 致谢

- KernelSU / Magisk for the module framework. / 模块框架来自 KernelSU / Magisk。
- AOSP `AudioService` for the volume-step logic. / 音量阶梯逻辑参考 AOSP `AudioService`。

## License / 许可

MIT — see [LICENSE](LICENSE). / MIT，见 [LICENSE](LICENSE)。
