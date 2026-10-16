# Volume Steps

[English](README.md) | **简体中文**

用于调整 Android **音量阶梯数量**（每次按音量键对应的档位细分）的 KernelSU / Magisk 模块。

> 已在 Xiaomi 13（nuwa）、Android 16（API 36）、KernelSU 环境实测通过。

---

## 功能

- 提升 **媒体**（音乐/视频/游戏）、**闹钟**、**系统**、**通话** 音量的档位数量。
- 同时可调整 **铃声** 与 **通知** 的档位数量。
- 所有数值都在单个文件（`config.sh`）中配置。
- 不修改系统文件，完全 systemless、可逆。
- 卸载干净——模块创建的叠加层会被彻底移除。

## 工作原理

本模块复刻了 ROM 自身 `AudioService` 读取音量阶梯的方式。

| 音频流 | 来源 | 生效时机 |
| --- | --- | --- |
| 媒体 / 闹钟 / 系统 / 通话 | 系统属性 `ro.config.*_vol_steps` | 本次开机 |
| 铃声 / 通知 | framework-res 整型资源 `config_audio_ring_vol_steps`、`config_audio_notif_vol_steps` | 下次开机 |

- **属性**在 `post-fs-data` 阶段用 `resetprop -n` 设置，早于 Zygote / `system_server` 启动。
- **铃声/通知**是 framework 资源而非属性，因此通过 **root 直接 fabricate 的 RRO 叠加层**（`cmd overlay fabricate`）修改。由于 `AudioService` 会在开机时缓存这两项，安装后的 **第二次开机** 才会生效。

> 为什么不直接在 `/product/overlay` 放一个叠加层 APK？因为只有安装了 **metamodule**（如 `meta-overlayfs`）时 KernelSU 才会挂载模块的 `system/` 目录。为免依赖，本模块改用 root 在运行时直接 fabricate 叠加层。

## 环境要求

- 已 root 的 KernelSU（或 Magisk）。
- Android 11+（已在 16 上测试）。
- ROM 需采用相同机制（标准 AOSP `AudioService` 行为）。

## 安装

1. 从 Releases 页面下载最新的 `VolumeSteps-*.zip`。
2. 在 KernelSU（或 Magisk）管理器中安装，然后重启。
3. （可选）编辑 `/data/adb/modules/volumesteps/config.sh` 调整数值，再重启。

命令行安装：

```sh
adb push VolumeSteps-1.0.zip /data/local/tmp/
adb shell 'su -c "/data/adb/ksud module install /data/local/tmp/VolumeSteps-1.0.zip"'
adb reboot
```

## 配置

编辑 `/data/adb/modules/volumesteps/config.sh`：

```sh
MEDIA_VOL_STEPS=30     # 媒体
ALARM_VOL_STEPS=15     # 闹钟
SYSTEM_VOL_STEPS=15    # 系统
VOICE_VOL_STEPS=15     # 通话
RING_VOL_STEPS=20      # 铃声
NOTIF_VOL_STEPS=20     # 通知
```

重启生效。铃声/通知需额外重启一次（见上）。

## 卸载

在管理器中移除模块（或删除 `/data/adb/modules/volumesteps`）并重启。
`uninstall.sh` 会停用并彻底注销所创建的叠加层。

## 构建

```sh
# 1)（仅在改动辅助程序时需要）重新编译 DEX
D8=/path/to/d8 ./tools/build-dex.sh

# 2) 构建可刷入 zip
./build.sh            # -> dist/VolumeSteps-<version>.zip
```

## 仓库结构

```
.
├── build.sh                     # 打包模块
├── module/                      # 模块负载（进入 zip）
│   ├── module.prop
│   ├── config.sh                # 用户配置
│   ├── customize.sh             # 安装钩子
│   ├── post-fs-data.sh          # 设置属性
│   ├── service.sh               # 创建铃声/通知叠加层
│   ├── uninstall.sh             # 清理
│   └── bin/unregister.dex       # 编译后的辅助程序
├── tools/
│   ├── RmOv.java                # 叠加层注销辅助程序源码
│   └── build-dex.sh             # 编译辅助程序
└── .github/workflows/release.yml
```

## 注意事项

- 本 ROM 中资源名为 `config_audio_ring_vol_steps` / `config_audio_notif_vol_steps`，其他 ROM 可能不同。
- `resetprop` 必须在 `system_server` 之前运行，因此放在 `post-fs-data.sh` 且使用 `-n`（普通 `setprop` 会导致开机死锁）。

## 致谢

- 模块框架来自 KernelSU / Magisk。
- 音量阶梯逻辑参考 AOSP `AudioService`。

## 许可

MIT，见 [LICENSE](LICENSE)。
