#!/system/bin/sh
# =====================================================================
#  Volume Steps - uninstall hook / 卸载脚本
#
#  EN: Runs when KernelSU/Magisk removes the module. Neutralises and
#      fully unregisters the fabricated ringtone/notification overlay so
#      nothing is left behind in the OverlayManager settings.
#  CN: 在 KernelSU/Magisk 卸载模块时运行。停用并彻底注销之前 fabricate
#      的铃声/通知叠加层，避免在 OverlayManager 设置里留下残留。
# =====================================================================

MODDIR=${0%/*}

# EN: Disable first. / CN: 先停用。
cmd overlay disable com.android.shell:volsteps_ring  >/dev/null 2>&1
cmd overlay disable com.android.shell:volsteps_notif >/dev/null 2>&1

# EN: Fully unregister the fabricated overlays using the bundled
#     root-only reflection helper (tools/RmOv.java -> bin/unregister.dex).
# CN: 使用随附的 root 反射小工具彻底注销这些叠加层
#     （源码 tools/RmOv.java -> 编译产物 bin/unregister.dex）。
if [ -f "$MODDIR/bin/unregister.dex" ]; then
    CLASSPATH="$MODDIR/bin/unregister.dex" \
        /system/bin/app_process /system/bin RmOv \
        com.android.shell:volsteps_ring com.android.shell:volsteps_notif >/dev/null 2>&1
fi

# EN: Remove any orphaned overlay cache files. / CN: 清理孤立的叠加层缓存文件。
rm -f /data/resource-cache/*volsteps_ring* \
      /data/resource-cache/*volsteps_notif* 2>/dev/null

exit 0
