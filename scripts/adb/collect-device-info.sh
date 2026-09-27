#!/usr/bin/env bash
# 采集设备信息，分成两份输出：
#   公开部分 -> logs/device-info-<时间戳>.txt（logs/ 不入库，可以人工整理后写进 docs/device/）
#   敏感部分 -> private/device-identifiers-<时间戳>.txt（private/ 不入库）
# 用法：scripts/adb/collect-device-info.sh   （多台设备时先 export ANDROID_SERIAL=...）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
PUB="$ROOT/logs/device-info-$TS.txt"
PRI="$ROOT/private/device-identifiers-$TS.txt"
mkdir -p "$ROOT/logs" "$ROOT/private"

adb get-state >/dev/null

PUBLIC_PROPS="ro.product.brand ro.product.manufacturer ro.product.model ro.product.device
ro.config.marketing_name ro.board.platform ro.product.cpu.abilist
ro.build.version.release ro.build.version.sdk ro.build.version.security_patch
ro.build.display.id ro.build.version.emui ro.build.type ro.boot.verifiedbootstate
ro.boot.flash.locked ro.secure ro.debuggable ro.crypto.type ro.treble.enabled
ro.product.first_api_level ro.sf.lcd_density ro.opengles.version sys.usb.config"

{
  echo "# 采集时间 $(date -Is)"
  echo "## props"
  for p in $PUBLIC_PROPS; do echo "$p=$(adb shell getprop "$p" | tr -d '\r')"; done
  echo "## cpu"
  adb shell 'for c in /sys/devices/system/cpu/cpu[0-9]*; do echo "${c##*/} $(cat $c/cpufreq/cpuinfo_min_freq) $(cat $c/cpufreq/cpuinfo_max_freq)"; done'
  adb shell 'grep -m1 Features /proc/cpuinfo; grep "CPU part" /proc/cpuinfo | sort | uniq -c'
  echo "## memory"
  adb shell 'grep -E "^(MemTotal|MemAvailable|SwapTotal|SwapFree)" /proc/meminfo'
  echo "## storage"
  adb shell df -h /data /system 2>/dev/null || true
  echo "## display"
  adb shell 'wm size; wm density'
  echo "## kernel / selinux"
  adb shell 'uname -r; getenforce'
  echo "## gpu"
  adb shell dumpsys SurfaceFlinger | grep -m1 GLES || true
  echo "## battery"
  adb shell dumpsys battery | grep -E "level|voltage|temperature|health|technology"
  echo "## sensors"
  adb shell dumpsys sensorservice | grep -E '^0x[0-9a-f]+\) ' | cut -d'|' -f1-3 || true
  echo "## packages"
  echo "all=$(adb shell pm list packages | wc -l) system=$(adb shell pm list packages -s | wc -l) third=$(adb shell pm list packages -3 | wc -l) disabled=$(adb shell pm list packages -d | wc -l)"
} | tr -d '\r' > "$PUB"

{
  echo "# 敏感标识 · 仅本地 · $(date -Is)"
  echo "serialno=$(adb shell getprop ro.serialno)"
  echo "android_id=$(adb shell settings get secure android_id)"
  echo "bluetooth_address=$(adb shell settings get secure bluetooth_address)"
  echo "baseband=$(adb shell getprop gsm.version.baseband)"
  echo "## net"
  adb shell ip -o addr | awk '{print $2, $3, $4}'
} | tr -d '\r' > "$PRI"
chmod 600 "$PRI"

echo "公开信息: $PUB"
echo "敏感信息: $PRI"
