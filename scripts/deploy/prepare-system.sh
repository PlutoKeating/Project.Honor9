#!/usr/bin/env bash
# Amani 运行基座的系统准备：去掉 EMUI 查杀、给 Termux 系列与控制台放行后台。
# 用法：prepare-system.sh apply | rollback | status
# 原理与说明见 docs/architecture/amani-runtime.md 第 2 节。
set -u
PKGS="com.termux com.termux.boot com.termux.api xyz.amani.console"
KILLERS="com.huawei.powergenie"
sh_() { adb shell -n "$@" </dev/null; }
installed() { sh_ pm list packages | tr -d '\r' | grep -qx "package:$1"; }

case "${1:-status}" in
apply)
  ts=$(date +%Y%m%d-%H%M%S); mkdir -p backups
  sh_ pm list packages > "backups/$ts-packages.txt"
  sh_ dumpsys deviceidle whitelist > "backups/$ts-deviceidle.txt"
  for k in $KILLERS; do installed "$k" && echo "$k: $(sh_ pm uninstall -k --user 0 "$k")"; done
  for p in $PKGS; do
    installed "$p" || continue
    sh_ dumpsys deviceidle whitelist +"$p" >/dev/null
    sh_ cmd appops set "$p" RUN_IN_BACKGROUND allow
    sh_ am set-standby-bucket "$p" active
    echo "$p: 已放行"
  done ;;
rollback)
  for k in $KILLERS; do sh_ cmd package install-existing "$k"; done
  for p in $PKGS; do
    installed "$p" || continue
    sh_ dumpsys deviceidle whitelist -"$p" >/dev/null
    sh_ cmd appops set "$p" RUN_IN_BACKGROUND default
  done ;;
status)
  for k in $KILLERS; do installed "$k" && echo "$k: 仍在" || echo "$k: 已卸载"; done
  wl=$(sh_ dumpsys deviceidle whitelist | tr -d '\r')
  for p in $PKGS; do
    installed "$p" || { echo "$p: 未安装"; continue; }
    echo "$p: 白名单=$(echo "$wl" | grep -q ",$p," && echo 是 || echo 否) 后台=$(sh_ cmd appops get "$p" RUN_IN_BACKGROUND | tr -d '\r')"
  done ;;
*) echo "用法: $0 apply|rollback|status"; exit 1 ;;
esac
