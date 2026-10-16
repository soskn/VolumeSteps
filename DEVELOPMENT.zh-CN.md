# 开发与维护笔记

[English](DEVELOPMENT.md) | **简体中文**

本文档记录**模块是如何设计的、为什么这么设计、以及如何调试或修复**。
如果模块日后失效，请先看这里。

---

## 1. 目标设备 / 环境

| 项目 | 值 |
| --- | --- |
| 设备 | Xiaomi 13 Pro（`nuwa`） |
| ROM | 基于 crDroid / LineageOS，Android 16，API 36 |
| Root | KernelSU，`ksud 4.2.0`，`su` 版本 40900 |
| Metamodule | **未安装**（见 §3） |
| 设备上的叠加层 | `org.lineageos.frameworkresoverlay.{xiaomi,nuwa}`（平台签名） |

开发开始时实测的音量阶梯：

```sh
adb shell dumpsys audio | grep -E '^- STREAM_|Max:'
# MUSIC Max=25, VOICE_CALL Max=15, ALARM Max=15, SYSTEM Max=15, RING/NOTIF Max=7
```

## 2. ROM 如何计算音量阶梯（核心结论）

数值来自 `frameworks/base/services/core/java/com/android/server/audio/AudioService.java`
（在 `system_server` 启动时读取，约 **1531–1637** 行）：

- **属性**（开机读取一次，优先级高于资源）：
  - `ro.config.media_vol_steps` / `ro.config.media_vol_default`
  - `ro.config.alarm_vol_steps` / `ro.config.alarm_vol_default`
  - `ro.config.system_vol_steps` / `ro.config.system_vol_default`
  - `ro.config.vc_call_vol_steps` / `ro.config.vc_call_vol_default`
  - `ro.config.assistant_vol_min`
- **framework-res 整型资源**（包名 `android`）：
  - `config_audio_ring_vol_steps`（`0x010e002d`，默认 7）
  - `config_audio_notif_vol_steps`（`0x010e002b`，默认 7）
  - `config_audio_alarm_min_vol`（`0x010e0029`）
  - 定义在 `frameworks/base/core/res/res/values/config.xml`

> 注意：本 ROM **没有 `config_volume_steps` 数组**（不同于部分 AOSP/旧版本）。
> 阶梯完全由上面的属性 + 两个铃声/通知资源决定。

## 3. 设计决策

**媒体/闹钟/系统/通话 → `post-fs-data.sh` + `resetprop -n`。**

- 这些由 `system_server` 读取，因此必须在 **Zygote 之前** 设置。
- `post-fs-data` 早于 Zygote。此阶段用普通 `setprop` 会**导致开机死锁**，
  因此必须用 `resetprop -n`（直接写属性内存区）。
- 结果：**本次开机即生效**。

**铃声/通知 → 运行时 RRO：`cmd overlay fabricate`（`service.sh`）。**

- 它们是资源而非属性，必须用叠加层。
- 直观方案（往 `/product/overlay` 放平台签名的 RRO APK）在**本机不成立**：
  只有安装了 **metamodule**（如 `meta-overlayfs`）时 KernelSU 才会挂载模块的
  `system/` 目录，而本机没有安装。因此 `system/product/overlay/*.apk` 根本不会出现。
- 于是改为以 root 在运行时直接 fabricate 叠加层——无需挂载、无需 APK、
  无需签名、无额外依赖。
- **代价：** `AudioService` 会在开机时缓存这两个值，而 `service.sh`
  （late_start）在 `system_server` 之后才运行，因此新的铃声/通知值
  **从下次开机起生效**。

**为什么叠加层可以省去 `android:targetName` / 平台签名。**

- **fabricate** 出来的叠加层由 root 直接经 OverlayManager 服务创建，
  绕过了 PackageManager 的扫描校验；其所有者固定为 `com.android.shell`
  （AOSP 的 `OverlayManagerShellCommand` 写死）。
- 相关 AOSP 代码：`frameworks/base/services/core/server/om/OverlayManagerShellCommand.java`
  （`runFabricate`、`addOverlayValue`）。注意 `fabricate` 对整数只接受编码类型 id
  （`TYPE_MAP` 里没有 `"int"`）；`0x10` == `TypedValue.TYPE_INT_DEC`。

## 4. 现场验证 / 调试速查

以下命令均可随时运行，且可逆。

```sh
# --- 当前生效的阶梯 ---
adb shell 'dumpsys audio | grep -E "^- STREAM_|Max:"'

# --- 属性 ---
adb shell 'for p in media alarm system vc_call; do echo "$p=$(getprop ro.config.${p}_vol_steps)"; done'

# --- 属性写入测试（KernelSU）---
adb shell 'su -c "resetprop -n ro.config.media_vol_steps 30; getprop ro.config.media_vol_steps"'

# --- 叠加层：是否启用？framework 看到的值是多少？---
adb shell 'cmd overlay list android | grep volsteps'
adb shell 'cmd overlay lookup android android:integer/config_audio_ring_vol_steps'

# --- 手动 fabricate（每次一个资源；0x10 = TYPE_INT_DEC）---
adb shell 'cmd overlay fabricate --target android --name dbg_ring \
    android:integer/config_audio_ring_vol_steps 0x10 20'
adb shell 'cmd overlay enable com.android.shell:dbg_ring'
# 清理探针（停用 + 注销），见 tools/RmOv.java：
adb shell 'su -c "CLASSPATH=/data/local/tmp/unregister.dex app_process /system/bin RmOv com.android.shell:dbg_ring"'
```

不安装模块、直接以 root 运行脚本进行测试：

```sh
adb push module /data/local/tmp/vstest
adb shell 'su -c "sh /data/local/tmp/vstest/post-fs-data.sh"'
adb shell 'su -c "sh /data/local/tmp/vstest/service.sh"'
adb shell 'su -c "sh /data/local/tmp/vstest/uninstall.sh"'
```

## 5. 故障排查

| 现象 | 可能原因 | 处理 |
| --- | --- | --- |
| 媒体/闹钟/系统/通话未变 | 属性未在 `system_server` 前设置，或 ROM 用了别的名字 | 查 `getprop`；核对 AudioService 中的名称 |
| `resetprop: not found` | 脚本执行时不在 PATH | 脚本会回退到 `/data/adb/ksu/bin/resetprop` |
| 铃声/通知未变 | 启用太晚 / `AudioService` 已缓存旧值 | **再重启一次**；用 `cmd overlay lookup` 确认 |
| `cmd overlay fabricate` 失败 | 你的 ROM 资源名不同 | 确认 `config_audio_ring_vol_steps` 存在（见 §2） |
| 安装后叠加层未生效 | 无 metamodule → `system/` 未挂载 | 本模块刻意不用 `system/`，确认 `service.sh` 已执行 |
| 开机卡住 | 在 `post-fs-data` 用了 `setprop` | 必须用 `resetprop -n` |

常用日志：

```sh
adb logcat -d | grep -iE 'AudioService|OverlayManager|volsteps'
```

## 6. 手动还原全部改动

```sh
# 移除模块后重启 —— 或者即时执行：
adb shell 'su -c "sh /data/adb/modules/volumesteps/uninstall.sh"'
# 属性仅存在于内存（resetprop -n），重启即恢复；若想立即恢复：
adb shell 'su -c "resetprop -n ro.config.media_vol_steps 25"   # 其余同理'
adb shell 'su -c "resetprop -d ro.config.media_vol_default"'    # 若原先不存在
rm -f /data/resource-cache/*volsteps_ring* 2>/dev/null
```

## 7. 已知限制

- 铃声/通知在（重新）配置后需额外重启一次生效。
- `unregister.dex` 辅助程序只用于「卸载干净」；即使它失败，叠加层也只是被
  停用（无害）。
- 资源名与 ROM 相关，其他 ROM 可能不同。

## 8. 实现过程记录

1. 在 `AudioService.java` 中定位本 ROM 的音量阶梯来源。
2. 用 `dumpsys audio` 确认数值；发现属性 + 两个铃声/通知资源。
3. 验证可叠加性：`cmd overlay fabricate` 成功，`cmd overlay lookup` 返回新值。
4. 发现没有 metamodule ⇒ `/product/overlay` 的 RRO APK 不会被挂载
   ⇒ 改用运行时 `fabricate`。
5. 完成模块：`post-fs-data.sh` 设属性、`service.sh` 建叠加层、
   `tools/RmOv.java`（反射注销辅助程序）。
6. 在真机上逐一验证所有脚本，随后把设备还原到原始状态。
