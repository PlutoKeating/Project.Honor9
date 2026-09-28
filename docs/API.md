# 接口：适配器与部署脚本

Windler 的网关 API 与适配器接口定义见子模块 [`Project.Windler/docs/API.md`](../Project.Windler/docs/API.md)。本文只描述本仓库提供的实现。

## 1. 身体适配器 `adapters/honor9`

构建：`cd adapters/honor9 && npm ci && npm run build` → `dist/honor9.mjs`（单文件 ES 模块）。只 `import type` 子模块中的 `BodyAdapter` 类型。

**采样 `sample()`**

| 字段 | 来源 |
|---|---|
| `battery.level / charging / tempC / health` | `termux-battery-status` |
| `lux` | `termux-sensor` 光线传感器（BH1745） |
| `motion` | 加速度计（BMI160）合加速度与重力之差 |
| `extra.充电方式 / 电池健康` | `termux-battery-status` |

**表达**：`notify()` → `termux-notification`（带「打开控制台」按钮）；`speak()` → `termux-tts-speak`；`playAudio(file)` → `termux-media-player play`（播放 Azure 语音合成的音频，后台播放、立即返回）。

**工具**

| 工具 | 能力类别 | 实现 |
|---|---|---|
| `speak` | device | `termux-tts-speak -l zh` |
| `take_photo` | camera | `termux-camera-photo`，保存到 `~/windler/data/media/` |
| `record_audio` | microphone | `termux-microphone-record`（≤120 秒） |
| `location` | location | `termux-location -p network`（坐标保留 3 位小数） |
| `vibrate` / `torch` / `clipboard` | device | `termux-vibrate` / `termux-torch` / `termux-clipboard-*` |
| `read_sensor` | device | `termux-sensor` |

环境变量：`WINDLER_HOME`（媒体保存位置）、`WINDLER_CONSOLE_ACTIVITY`（通知按钮打开的界面，默认 `xyz.windler.console/.MainActivity`）。

## 2. 部署脚本 `scripts/deploy/`

| 脚本 | 用法 | 作用 |
|---|---|---|
| `prepare-system.sh` | `apply` / `rollback` / `status` | 卸载 PowerGenie；为 Termux 系列与控制台加省电白名单、允许后台、待机分组 active（先备份到 `backups/`） |
| `termux-install.sh` | — | 校验 sha256 后安装 Termux、Termux:Boot、Termux:API（GitHub 版，签名一致，APK 在 `backups/apks/`） |
| `termux-bootstrap.sh` | — | 首次引导：推送引导文件到 `/sdcard/Download/windler-bootstrap/`，在 Termux 界面模拟输入执行 `termux/bootstrap.sh`，完成后通过 ssh 验证 |
| `windler-release.sh` | 无参数 / `rollback` | 测试、构建并发布运行基座与适配器，健康检查失败自动回滚 |
| `lib.sh` | 被引用 | `dssh` / `dscp`：经 USB 端口转发连接 Termux 的 ssh |
| `power-no-optimize.sh` | 无参数 / `restore` | 全局关闭省电优化（第一轮精简时引入） |

设备端文件（`scripts/deploy/termux/`）：`bootstrap.sh`（安装 openssh、nodejs-lts、termux-services、termux-api、git、rsync，配置 sshd 与外部调用）、`boot-windler`（开机脚本）、`windler-run`（runit 服务）、`windler-log-run`（日志服务）。

ssh 密钥默认 `~/.ssh/windler_honor9`（可用 `WINDLER_SSH_KEY` 覆盖），只存在于主机。
