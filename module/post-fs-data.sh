#!/system/bin/sh
# =====================================================================
#  Volume Steps - post-fs-data stage / 开机 post-fs-data 阶段脚本
#
#  EN: Runs BEFORE Zygote / system_server. AudioService reads these
#      properties during system_server startup, so they must be set here
#      to take effect on THIS boot.
#  CN: 在 Zygote / system_server 启动之前运行。AudioService 会在
#      system_server 启动时读取这些属性，因此必须在此处设置，
#      才能在“本次开机”生效。
# =====================================================================

MODDIR=${0%/*}
# EN: Load user configuration. / CN: 加载用户配置。
[ -f "$MODDIR/config.sh" ] && . "$MODDIR/config.sh"

# EN: Locate resetprop (KernelSU ships it as a symlink to ksud).
# CN: 定位 resetprop（KernelSU 中是指向 ksud 的软链接）。
RESETPROP="$(command -v resetprop 2>/dev/null)"
[ -z "$RESETPROP" ] && [ -x /data/adb/ksu/bin/resetprop ] && RESETPROP=/data/adb/ksu/bin/resetprop
[ -z "$RESETPROP" ] && [ -x /data/adb/magisk/resetprop ] && RESETPROP=/data/adb/magisk/resetprop
[ -z "$RESETPROP" ] && exit 0

# EN: resetprop -n writes straight to the property area.
#     (setprop would deadlock the boot process in this stage.)
# CN: resetprop -n 直接写入属性内存区。
#     （此阶段用 setprop 会导致开机死锁。）
set_prop() {
    [ -n "$2" ] && "$RESETPROP" -n "$1" "$2"
}

set_prop ro.config.media_vol_steps     "$MEDIA_VOL_STEPS"
set_prop ro.config.media_vol_default   "$MEDIA_VOL_DEFAULT"
set_prop ro.config.alarm_vol_steps     "$ALARM_VOL_STEPS"
set_prop ro.config.alarm_vol_default   "$ALARM_VOL_DEFAULT"
set_prop ro.config.system_vol_steps    "$SYSTEM_VOL_STEPS"
set_prop ro.config.system_vol_default  "$SYSTEM_VOL_DEFAULT"
set_prop ro.config.vc_call_vol_steps   "$VOICE_VOL_STEPS"
set_prop ro.config.vc_call_vol_default "$VOICE_VOL_DEFAULT"

exit 0
