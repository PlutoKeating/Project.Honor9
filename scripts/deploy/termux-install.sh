#!/usr/bin/env bash
# 安装 Termux、Termux:Boot、Termux:API（GitHub 版，签名一致）。APK 放在 backups/apks/（不入库）。
set -eu
cd "$(dirname "$0")/../.."
dir=backups/apks
( cd "$dir" && sha256sum -c SHA256SUMS )
for apk in "$dir"/termux-app_*.apk "$dir"/termux-boot-app_*.apk "$dir"/termux-api-app_*.apk; do
  echo "安装 $apk"; adb install -r -g "$apk"
done
# 启动一次 Termux:Boot，使其注册开机广播（Android 要求应用至少被打开过一次）
adb shell am start -n com.termux.boot/.BootActivity >/dev/null 2>&1 || true
