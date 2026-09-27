#!/usr/bin/env bash
# 每次开机后运行：EMUI 会在开机时从 /preas 重装预装第三方应用，并恢复 Doze，
# shell 权限无法阻止，所以开机后重新执行卸载和关闭省电优化。
set -u
cd "$(dirname "$0")/../.."
adb wait-for-device
until [ "$(adb shell -n getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 3; done
now=$(adb shell -n pm list packages | tr -d '\r' | sed 's/package://')
cat configs/packages/debloat-0*.txt | grep -vE '^\s*(#|$)' | while read -r p; do
  echo "$now" | grep -qx "$p" && echo "$p: $(adb shell -n pm uninstall -k --user 0 "$p" </dev/null 2>&1 | tail -1)"
done
scripts/deploy/power-no-optimize.sh
