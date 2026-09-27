#!/data/data/com.termux/files/usr/bin/bash
# 在 Termux 内执行的一次性引导（由主机 termux-bootstrap.sh 推送并触发）。
# 结果：sshd（仅 127.0.0.1:8022，公钥登录）、nodejs、runit 服务框架、开机脚本、允许外部应用 RUN_COMMAND。
set -e
SRC=/sdcard/Download/amani-bootstrap
yes | pkg update -y -o Dpkg::Options::=--force-confnew
pkg install -y -o Dpkg::Options::=--force-confnew openssh nodejs-lts termux-services termux-api git rsync

mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat "$SRC/authorized_keys" > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
cfg=$PREFIX/etc/ssh/sshd_config
grep -q '^ListenAddress 127.0.0.1' "$cfg" || printf 'ListenAddress 127.0.0.1\nPasswordAuthentication no\n' >> "$cfg"

mkdir -p ~/.termux
touch ~/.termux/termux.properties
grep -q '^allow-external-apps' ~/.termux/termux.properties || echo 'allow-external-apps=true' >> ~/.termux/termux.properties

mkdir -p ~/.termux/boot
cp "$SRC/boot-amani" ~/.termux/boot/amani && chmod 700 ~/.termux/boot/amani

# runit 服务：sshd 与 amani
. $PREFIX/etc/profile.d/start-services.sh || true
sleep 2
sv-enable sshd || true
mkdir -p $PREFIX/var/service/amani/log
cp "$SRC/amani-run" $PREFIX/var/service/amani/run && chmod 700 $PREFIX/var/service/amani/run
cp "$SRC/amani-log-run" $PREFIX/var/service/amani/log/run && chmod 700 $PREFIX/var/service/amani/log/run
mkdir -p $PREFIX/var/log/sv/amani ~/amani
touch $PREFIX/var/service/amani/down   # 未部署前不启动
termux-wake-lock
echo AMANI_BOOTSTRAP_OK > "$SRC/done"
