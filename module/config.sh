# =====================================================================
#  Volume Steps - user configuration / 用户配置
#
#  EN: Edit the values below, then reboot. This file is sourced by the
#      module's boot scripts; lines starting with '#' are ignored.
#  CN: 修改下面的数值后重启即可。该文件会被模块的启动脚本 source，
#      以 '#' 开头的行会被忽略。
# =====================================================================

# ----- Media (music / video / games) / 媒体（音乐/视频/游戏）-----
# EN: AOSP default is 15. Higher = finer volume granularity.
# CN: AOSP 默认值为 15，数值越大音量档位越细。
MEDIA_VOL_STEPS=30
# EN: Default index applied at boot (0 .. MEDIA_VOL_STEPS).
# CN: 开机时使用的默认档位（0 .. MEDIA_VOL_STEPS）。
MEDIA_VOL_DEFAULT=15

# ----- Alarm / 闹钟 -----
ALARM_VOL_STEPS=15
ALARM_VOL_DEFAULT=10

# ----- System (UI sounds, camera shutter, ...) / 系统音（按键、快门等）-----
SYSTEM_VOL_STEPS=15
SYSTEM_VOL_DEFAULT=15

# ----- In-call (voice call) / 通话音 -----
VOICE_VOL_STEPS=15
VOICE_VOL_DEFAULT=10

# =====================================================================
#  Ringtone / Notification / 铃声与通知
#
#  EN: These two are framework resources, not properties, so they are set
#      through a root-fabricated Runtime Resource Overlay (RRO).
#      NOTE: AudioService caches them at boot, so the new values take
#      effect from the SECOND boot onward (the overlay is created on the
#      first boot after installing the module).
#  CN: 这两项是 framework 资源而非属性，因此通过 root 直接 fabricate 的
#      RRO 叠加层来修改。
#      注意：AudioService 会在开机时缓存这两项，因此新数值从“第二次开机”
#      起生效（模块安装后的第一次开机才会创建该叠加层）。
# =====================================================================
ENABLE_RING_NOTIF_OVERLAY=true
RING_VOL_STEPS=20
NOTIF_VOL_STEPS=20
