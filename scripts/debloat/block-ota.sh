#!/usr/bin/env bash
# 屏蔽 EMUI 系统更新（HwOUC）。HwOUC 受保护，无法卸载，也无法禁用包或组件，
# 所以改为：清掉数据（含已下载的更新包）、关闭自动下载设置、禁止后台/唤醒/通知/悬浮窗、
# 禁止后台联网、移出电池白名单。
# 回滚：scripts/debloat/block-ota.sh restore
set -u
P=com.huawei.android.hwouc
U=$(adb shell -n pm list packages -U $P | tr -d '\r' | sed -n 's/.*uid://p')
OPS="RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK POST_NOTIFICATION SYSTEM_ALERT_WINDOW"
if [ "${1:-}" = restore ]; then
  for op in $OPS; do adb shell -n cmd appops set $P $op allow; done
  adb shell -n cmd netpolicy remove restrict-background-blacklist "$U"
  adb shell -n settings put global hw_system_update_auto_download 1
  adb shell -n settings put global hwouc_display_night_details 1
  exit
fi
adb shell -n am force-stop $P
[ "${1:-}" = clear ] && adb shell -n pm clear $P
adb shell -n settings put global hw_system_update_auto_download 0
adb shell -n settings put global ota_disable_automatic_update 1
adb shell -n settings put global hwouc_display_night_details 0
adb shell -n settings put secure hw_upgrade_remind 0
for op in $OPS; do adb shell -n cmd appops set $P $op ignore; done
adb shell -n cmd netpolicy add restrict-background-blacklist "$U"
adb shell -n dumpsys deviceidle whitelist -$P >/dev/null
adb shell -n pm uninstall -k --user 0 com.google.android.configupdater >/dev/null 2>&1
echo "HwOUC 已屏蔽（uid $U）"
