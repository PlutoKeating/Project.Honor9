#!/usr/bin/env bash
# 构建并发布 Amani 到荣耀9：核心（子模块 Project.Amani/runtime）+ 身体适配器（adapters/honor9）。
# 每个版本放在 ~/amani/releases/<版本>/，current 指向运行中的版本；健康检查失败自动回滚到上一版本。
# 用法：amani-release.sh [rollback]
set -eu
cd "$(dirname "$0")/../.."
. scripts/deploy/lib.sh
R='$HOME/amani/releases'
SV='$PREFIX/var/service/amani'

health() { dssh 'for i in $(seq 1 20); do curl -sf http://127.0.0.1:7788/health && exit 0; sleep 1; done; exit 1'; }
switch_to() { dssh "ln -sfn $R/$1 \$HOME/amani/current && rm -f $SV/down && sv restart $SV >/dev/null 2>&1 || sv up $SV"; }

if [ "${1:-}" = rollback ]; then
  prev=$(dssh "readlink \$HOME/amani/previous | xargs basename")
  echo "回滚到 $prev"; switch_to "$prev"; health; exit
fi

( cd Project.Amani/runtime && { [ -d node_modules ] || npm ci --silent; } && npm test --silent >/dev/null && npm run build --silent )
( cd adapters/honor9 && { [ -d node_modules ] || npm ci --silent; } && npm run build --silent )
V="$(date +%Y%m%d-%H%M%S)-$(git -C Project.Amani rev-parse --short HEAD)"
echo "发布 $V"

# 服务脚本（幂等更新）
dscp scripts/deploy/termux/amani-run localhost:../usr/var/service/amani/run
dscp scripts/deploy/termux/boot-amani localhost:.termux/boot/amani
dssh "chmod 700 $SV/run .termux/boot/amani && mkdir -p $R/$V"
dscp Project.Amani/runtime/dist/main.cjs Project.Amani/runtime/dist/main.cjs.map adapters/honor9/dist/honor9.mjs "localhost:amani/releases/$V/"

cur=$(dssh 'readlink $HOME/amani/current || true')
[ -n "$cur" ] && dssh "ln -sfn $cur \$HOME/amani/previous"
# 设备配置：身体名称与时区（只写这两项，其余配置由控制台管理）
dssh "mkdir -p \$HOME/amani/config && node -e '
const f=process.env.HOME+\"/amani/config/amani.json\",fs=require(\"fs\");
let c={};try{c=JSON.parse(fs.readFileSync(f))}catch{}
c.body=\"honor9\";c.timezone=c.timezone||\"Asia/Shanghai\";fs.writeFileSync(f,JSON.stringify(c,null,2))'"
switch_to "$V"
if health; then
  echo; echo "发布成功：$V"
  dssh "cd $R && ls -1t | tail -n +4 | xargs -r rm -rf"   # 只保留最近 3 个版本
else
  echo "健康检查失败，回滚"
  [ -n "$cur" ] && switch_to "$(basename "$cur")" && health
  exit 1
fi
