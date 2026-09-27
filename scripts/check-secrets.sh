#!/usr/bin/env bash
# 提交前检查：暂存区里不能出现 private/ 中记录的本机敏感值，也不能出现通用的 MAC / 局域网 IP 格式。
# 作为 pre-commit 钩子安装：ln -sf ../../scripts/check-secrets.sh .git/hooks/pre-commit
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"
DIFF="$(git diff --cached -U0 --no-color | grep '^+' | grep -v '^+++')"
fail=0
# 1) private/ 表格与 key=value 文件中登记过的具体值
vals=$( { grep -hoE '^\|[^|]+\| *[^|]+ *\|' "$ROOT"/private/*.md 2>/dev/null | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}';
          grep -hoE '^[a-z_]+=.+' "$ROOT"/private/*.txt 2>/dev/null | cut -d= -f2-; } \
        | tr ',' '\n' | grep -E '^[A-Za-z0-9:._/-]{8,}$' | sort -u)
for v in $vals; do
  if grep -qiF -- "$v" <<<"$DIFF"; then echo "✗ 暂存区包含本地敏感值: ${v:0:4}****"; fail=1; fi
done
# 2) 通用格式
if grep -qiE '([0-9a-f]{2}:){5}[0-9a-f]{2}' <<<"$DIFF"; then echo "✗ 疑似 MAC 地址"; fail=1; fi
if grep -qE '\b(192\.168|10\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]+\.[0-9]+' <<<"$DIFF"; then echo "✗ 疑似局域网 IP"; fail=1; fi
[ $fail -eq 0 ] && echo "✓ 未发现敏感信息" || { echo "请移到 private/ 后重试"; exit 1; }
