#!/usr/bin/env bash
# 全局关闭省电优化（Doze、App Standby、省电模式），并把所有第三方与指定包加入电池优化白名单。
# 注意：deviceidle disable 重启后失效，开机后需重跑。回滚：scripts/deploy/power-no-optimize.sh restore
set -u
if [ "${1:-}" = restore ]; then
  adb shell dumpsys deviceidle enable
  adb shell settings delete global app_standby_enabled
  adb shell settings delete global adaptive_battery_management_enabled
  exit
fi
adb shell settings put global low_power 0
adb shell settings put global low_power_sticky 0
adb shell settings put global app_standby_enabled 0
adb shell settings put global adaptive_battery_management_enabled 0
adb shell settings put global stay_on_while_plugged_in 0
adb shell dumpsys deviceidle unforce
adb shell dumpsys deviceidle disable
for p in $(adb shell pm list packages -e | sed 's/package://' | tr -d '\r'); do
  adb shell dumpsys deviceidle whitelist +"$p" >/dev/null
done
adb shell dumpsys deviceidle enabled
adb shell dumpsys deviceidle whitelist | wc -l
