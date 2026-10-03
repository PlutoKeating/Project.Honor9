#!/usr/bin/env bash
# 用法：scripts/debloat/post-boot.sh [清单目录]（默认 configs/packages 即荣耀9；P9 传 configs/packages/eva-al10）
# 每次开机后运行：EMUI 会在开机时从 /preas 重装预装第三方应用（荣耀9 / EMUI 9），并恢复 Doze，
# shell 权限无法阻止，所以开机后重新执行卸载和关闭省电优化。
set -u
lists=${1:-configs/packages}  # 清单目录；P9 用 configs/packages/eva-al10
cd "$(dirname "$0")/../.."
adb wait-for-device
until [ "$(adb shell -n getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 3; done
now=$(adb shell -n pm list packages | tr -d '\r' | sed 's/package://')
cat "$lists"/debloat-0*.txt | grep -vE '^\s*(#|$)' | while read -r p; do
  echo "$now" | grep -qx "$p" && echo "$p: $(adb shell -n pm uninstall -k --user 0 "$p" </dev/null 2>&1 | tail -1)"
done
scripts/deploy/power-no-optimize.sh
scripts/debloat/block-ota.sh
