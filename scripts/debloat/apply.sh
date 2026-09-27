#!/usr/bin/env bash
# 用法：scripts/debloat/apply.sh <清单文件> [disable|uninstall|restore]
# 逐行处理清单（# 开头为注释）。disable: pm disable-user；uninstall: pm uninstall -k；restore: 两者都回滚。
set -u
list=$1; mode=${2:-disable}
grep -vE '^\s*(#|$)' "$list" | while read -r p; do
  case $mode in
    disable)   r=$(adb shell -n pm disable-user --user 0 "$p" </dev/null 2>&1) ;;
    uninstall) r=$(adb shell -n pm uninstall -k --user 0 "$p" </dev/null 2>&1) ;;
    restore)   r=$(adb shell -n cmd package install-existing "$p" 2>&1; adb shell -n pm enable "$p" </dev/null 2>&1) ;;
  esac
  echo "$p: $(echo "$r" | tr '\n' ' ')"
done
