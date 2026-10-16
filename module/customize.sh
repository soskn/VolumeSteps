#!/system/bin/sh
# =====================================================================
#  Volume Steps - installer customization / 安装时定制脚本
#
#  EN: Sourced by the KernelSU/Magisk module installer after extraction.
#  CN: 由 KernelSU/Magisk 的模块安装器在解压后 source 执行。
# =====================================================================

ui_print "********************************************"
ui_print "  Volume Steps  (KernelSU / Magisk module)"
ui_print "  Volume Steps  (KernelSU / Magisk 模块)"
ui_print "********************************************"

# EN: Normalise permissions for the module tree.
# CN: 统一设置模块目录权限。
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/config.sh"          0 0 0755
set_perm "$MODPATH/post-fs-data.sh"    0 0 0755
set_perm "$MODPATH/service.sh"         0 0 0755
set_perm "$MODPATH/uninstall.sh"       0 0 0755
set_perm "$MODPATH/bin/unregister.dex" 0 0 0644

ui_print "- Media/Alarm/System/Call steps are applied via properties."
ui_print "- 媒体/闹钟/系统/通话 阶梯通过系统属性设置。"
ui_print "- Ringtone/Notification overlay is created on boot."
ui_print "- 铃声/通知 叠加层在开机时创建。"
ui_print ""
ui_print "- Tune values in / 修改数值:"
ui_print "    /data/adb/modules/volumesteps/config.sh"
ui_print "- Reboot after editing (ring/notification need one extra reboot)."
ui_print "- 修改后请重启（铃声/通知需多重启一次生效）。"
