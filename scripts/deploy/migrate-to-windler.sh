#!/usr/bin/env bash
# 一次性迁移：运行基座由 Amani 更名为 Windler 后，把手机上的部署原样搬到新名字下（可重复执行）。
#   - 停止旧服务 amani，把 ~/amani 整体改名为 ~/windler（灵魂、配置、数据、令牌、历史版本全部保留），修正 current / previous 链接
#   - 移除旧的 runit 服务、日志目录与开机脚本；新的由 windler-release.sh 安装
#   - 控制台：卸载 xyz.amani.console，安装新构建的 xyz.windler.console，授予 RUN_COMMAND 并放行后台（需重新配对一次）
# 之后执行 scripts/deploy/windler-release.sh 发布。回滚见 docs/experiments/2026-09-28-rename-windler.md。
set -eu
cd "$(dirname "$0")/../.."
. scripts/deploy/lib.sh
APK=Project.Windler/console/build/app/outputs/flutter-apk/app-release.apk

dssh 'set -e
S=$PREFIX/var/service
if [ -d $S/amani ]; then sv down $S/amani || true; sv exit $S/amani 2>/dev/null || true; rm -rf $S/amani; fi
pkill -f "[a]mani/current" 2>/dev/null || true; sleep 2   # 确认旧进程已退出，避免它在退出时重新写出 ~/amani
rm -f ~/.termux/boot/amani
[ -d $PREFIX/var/log/sv/amani ] && [ ! -d $PREFIX/var/log/sv/windler ] && mv $PREFIX/var/log/sv/amani $PREFIX/var/log/sv/windler
rm -rf $PREFIX/var/log/sv/amani
# 旧进程退出时可能重新写出一个空的 ~/amani（空数据库、默认配置、无密钥）：确认为空后删除
if [ -d ~/amani ] && [ -d ~/windler ] && [ -z "$(find ~/amani/soul ~/amani/secrets -mindepth 1 2>/dev/null | head -1)" ]; then rm -rf ~/amani; fi
if [ -d ~/amani ] && [ ! -e ~/windler ]; then mv ~/amani ~/windler; fi
for l in current previous; do
  t=$(readlink ~/windler/$l 2>/dev/null || true)
  [ -n "$t" ] && ln -sfn ~/windler/releases/$(basename "$t") ~/windler/$l
done
echo "设备端：$(ls -d ~/windler) 已就绪"'

if adb shell pm list packages | tr -d '\r' | grep -qx package:xyz.amani.console; then adb uninstall xyz.amani.console; fi
adb install -r "$APK"
adb shell pm grant xyz.windler.console com.termux.permission.RUN_COMMAND
scripts/deploy/prepare-system.sh apply
