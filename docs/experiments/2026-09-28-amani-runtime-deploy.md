# 实验：部署 Amani 运行基座（Termux + runit + 身体适配器 + 控制台）

日期：2026-09-28

## 目的

让 Amani 在这台未 root 的荣耀9 上稳定常驻：不被 EMUI 查杀，崩溃自动恢复，重启后无需电脑自动启动，并能通过控制台 App 与飞书管理。

## 步骤

1. **屏幕超时**：`settings put system screen_off_timeout 600000`（原为 30000）。
2. **系统准备**：`scripts/deploy/prepare-system.sh apply`
   - 备份包列表与省电白名单到 `backups/`；
   - `pm uninstall -k --user 0 com.huawei.powergenie`（Success）；
   - Termux、Termux:Boot、Termux:API、控制台：省电白名单、`RUN_IN_BACKGROUND allow`、待机分组 `active`。
3. **安装 Termux 三件套**（GitHub 版）：Termux v0.118.3、Termux:Boot v0.8.1、Termux:API v0.53.0，`adb install -g`。
4. **首次引导**：`scripts/deploy/termux-bootstrap.sh`，自动安装 openssh、nodejs-lts（v24.18.0）、termux-services、termux-api、git、rsync，配置 sshd（仅 127.0.0.1:8022、公钥登录）、`allow-external-apps=true`、开机脚本与 runit 服务。
   - 问题：第一次模拟输入被华为输入法吞掉，因为终端没有输入焦点。解决：输入前先点击一次终端区域（已写入脚本）。
5. **发布**：`scripts/deploy/amani-release.sh`（运行基座测试 12/12 通过 → 构建 → 推送 → 切换 → 健康检查）。
6. **控制台**：安装 `xyz.amani.console`，`pm grant xyz.amani.console com.termux.permission.RUN_COMMAND`。

## 结果

| 验证项 | 结果 |
|---|---|
| 健康检查 `/health` | 通过 |
| 身体孪生 | 电量 100%（USB 充电）、体温 31°C、光照 0 lux（夜间）、运动 0.22 m/s²，感受：黑暗、安静 |
| 强杀 node（`kill -9`） | runit 立即以新 PID 拉起，网关恢复 |
| 控制台配对 | 配对码以系统通知送达；错误码被拒（403），正确码换得令牌 |
| 端到端（模拟模型，经 `adb reverse`） | 连通测试、对话、工具调用（写入常驻记忆）、自主醒来（内省 → 工具 → finish → 日记 → 灵魂仓库 git 提交）全部通过 |
| 测试数据 | 已清理：删除模拟供应商、测试记忆、时间线与灵魂目录，保留网关令牌与加密主密钥 |
| 重启后自启 | 未测：手机有锁屏密码，按 FBE 机制需首次解锁后 Termux:Boot 才会执行，待解锁后验证 |
| 控制台界面 | 解锁后验证：探活、申请配对码、输入配对码、进入「此刻」页（在线，显示驱动力与「尚未配置模型」抑制）、控制页、模型页（公共目录加载正常）。发现并修复一个缺陷：依赖状态的组件为 const 实例不重建，导致一直显示「连接中」（锁屏为密码 + 人脸，期间未做任何绕过） |

另外确认：充电节点（`/sys/class/power_supply/*`、`/sys/class/hw_power`）对 shell 不可读写，无法设置充电上限。

## 回滚

- 服务：`dssh 'sv down $PREFIX/var/service/amani'`，或 `scripts/deploy/amani-release.sh rollback` 回到上一版本。
- 系统准备：`scripts/deploy/prepare-system.sh rollback`（恢复 PowerGenie、移除白名单与后台许可）。
- 卸载：`adb uninstall xyz.amani.console com.termux.api com.termux.boot com.termux`（会删除 Termux 内的一切，包括 Amani 的家目录）。
- 屏幕超时：`adb shell settings put system screen_off_timeout 30000`。
