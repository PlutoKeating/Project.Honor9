#!/usr/bin/env bash
# 首次引导 Termux：推送引导文件到 /sdcard，在 Termux 界面里模拟输入执行，完成后即可通过 ssh 运维。
# 前提：已运行 termux-install.sh，手机亮屏解锁。
set -eu
cd "$(dirname "$0")/../.."
KEY=${AMANI_SSH_KEY:-$HOME/.ssh/amani_honor9}
[ -f "$KEY" ] || ssh-keygen -t ed25519 -N '' -C amani-host -f "$KEY"
D=/sdcard/Download/amani-bootstrap
adb shell "rm -rf $D; mkdir -p $D"
adb push scripts/deploy/termux/. "$D/" >/dev/null
adb push "$KEY.pub" "$D/authorized_keys" >/dev/null
adb shell 'input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard; am start -n com.termux/.HomeActivity' >/dev/null
sleep 3
adb shell input tap 540 600   # 让终端获得输入焦点
sleep 1
adb shell input text "bash%s$D/bootstrap.sh"
adb shell input keyevent KEYCODE_ENTER
echo "等待引导完成（下载软件包需要几分钟）..."
until adb shell "cat $D/done 2>/dev/null" | grep -q AMANI_BOOTSTRAP_OK; do sleep 10; done
adb forward tcp:8022 tcp:8022
ssh -i "$KEY" -p 8022 -o StrictHostKeyChecking=accept-new localhost 'echo ssh ok; node -v'
