# 部署脚本公共函数：通过 USB 端口转发 ssh 到 Termux（仅 127.0.0.1:8022，公钥登录）。
KEY=${AMANI_SSH_KEY:-$HOME/.ssh/amani_honor9}
dssh() { adb forward tcp:8022 tcp:8022 >/dev/null && ssh -q -i "$KEY" -p 8022 -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 localhost "$@"; }
dscp() { adb forward tcp:8022 tcp:8022 >/dev/null && scp -q -i "$KEY" -P 8022 -o StrictHostKeyChecking=accept-new "$@"; }
