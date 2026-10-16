#!/system/bin/sh
# =====================================================================
#  Volume Steps - late_start service stage / 开机 late_start 服务阶段脚本
#
#  EN: Runs AFTER system_server is up. Creates and enables the
#      ringtone/notification RRO overlay via root 'cmd overlay'.
#  CN: 在 system_server 启动完成后运行。通过 root 的 'cmd overlay'
#      创建并启用铃声/通知的 RRO 叠加层。
# =====================================================================

MODDIR=${0%/*}
# EN: Load user configuration. / CN: 加载用户配置。
[ -f "$MODDIR/config.sh" ] && . "$MODDIR/config.sh"

# EN: Feature toggle. / CN: 功能开关。
[ "$ENABLE_RING_NOTIF_OVERLAY" = "true" ] || exit 0

# EN: Fall back to sane defaults if not set. / CN: 未设置时使用默认值。
RING_VOL_STEPS=${RING_VOL_STEPS:-20}
NOTIF_VOL_STEPS=${NOTIF_VOL_STEPS:-20}

# EN: Wait until the overlay service (part of system_server) is ready.
# CN: 等待叠加层服务（属于 system_server）就绪。
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 60 ]; do
    sleep 2
    i=$((i + 1))
done

# EN: Fabricate one overlay per resource
#     (0x10 == TypedValue.TYPE_INT_DEC, i.e. a decimal integer).
#     The overlay owner is always com.android.shell (hardcoded by AOSP).
# CN: 为每个资源各 fabricate 一个叠加层
#     （0x10 == TypedValue.TYPE_INT_DEC，即十进制整数）。
#     叠加层的所有者固定为 com.android.shell（AOSP 中写死）。
cmd overlay fabricate --target android --name volsteps_ring \
    android:integer/config_audio_ring_vol_steps 0x10 "$RING_VOL_STEPS" >/dev/null 2>&1
cmd overlay fabricate --target android --name volsteps_notif \
    android:integer/config_audio_notif_vol_steps 0x10 "$NOTIF_VOL_STEPS" >/dev/null 2>&1

# EN: Enable them (idempotent; safe to run every boot).
# CN: 启用它们（幂等操作，每次开机运行都安全）。
cmd overlay enable com.android.shell:volsteps_ring  >/dev/null 2>&1
cmd overlay enable com.android.shell:volsteps_notif >/dev/null 2>&1

exit 0
