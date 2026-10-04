#!/usr/bin/env bash
# 开发者路径：从主机经 ssh 构建并发布 Quetzal 运行基座到荣耀9（核心 main.cjs + Termux 身体适配器 termux.mjs，均来自子模块 Project.Quetzal/runtime）。
# 使用者路径是手机上 Quetzal App 的安装向导（见 Project.Quetzal/docs/QUICK_START.md），两者的目录与服务约定一致。
# 每个版本放在 ~/quetzal/releases/<版本>/，current 指向运行中的版本；健康检查失败自动回滚到上一版本。
# 用法：quetzal-release.sh [rollback]
set -eu
cd "$(dirname "$0")/../.."
. scripts/deploy/lib.sh
R='$HOME/quetzal/releases'
SV='$PREFIX/var/service/quetzal'

health() { dssh 'for i in $(seq 1 20); do curl -sf http://127.0.0.1:7788/health && exit 0; sleep 1; done; exit 1'; }
switch_to() { dssh "ln -sfn $R/$1 \$HOME/quetzal/current && rm -f $SV/down && sv restart $SV >/dev/null 2>&1 || sv up $SV"; }

if [ "${1:-}" = rollback ]; then
  prev=$(dssh "readlink \$HOME/quetzal/previous | xargs basename")
  echo "回滚到 $prev"; switch_to "$prev"; health; exit
fi

( cd Project.Quetzal/runtime && { [ -d node_modules ] || npm ci --silent; } && npm test --silent >/dev/null && npm run build --silent )
V="$(date +%Y%m%d-%H%M%S)-$(git -C Project.Quetzal rev-parse --short HEAD)"
echo "发布 $V"

# 服务脚本（幂等更新）
dssh "mkdir -p $SV/log \$PREFIX/var/log/sv/quetzal .termux/boot"
dscp scripts/deploy/termux/quetzal-run localhost:../usr/var/service/quetzal/run
dscp scripts/deploy/termux/quetzal-log-run localhost:../usr/var/service/quetzal/log/run
dscp scripts/deploy/termux/boot-quetzal localhost:.termux/boot/quetzal
dssh "chmod 700 $SV/run $SV/log/run .termux/boot/quetzal && mkdir -p $R/$V"
dscp Project.Quetzal/runtime/dist/main.cjs Project.Quetzal/runtime/dist/main.cjs.map Project.Quetzal/runtime/dist/termux.mjs "localhost:quetzal/releases/$V/"

cur=$(dssh 'readlink $HOME/quetzal/current || true')
[ -n "$cur" ] && dssh "ln -sfn $cur \$HOME/quetzal/previous"
# 设备配置：身体名称与时区（只写这两项，其余配置由控制台管理）
dssh "mkdir -p \$HOME/quetzal/config && node -e '
const f=process.env.HOME+\"/quetzal/config/quetzal.json\",fs=require(\"fs\");
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
