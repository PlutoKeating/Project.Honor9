# 接口：适配器与部署脚本

Windler 的网关 API 与适配器接口定义见子模块 [`Project.Windler/docs/API.md`](../Project.Windler/docs/API.md)。本文只描述本仓库提供的实现。

## 1. 身体适配器

荣耀9 使用子模块自带的 Termux 适配器（`Project.Windler/runtime/adapters/termux`，构建产物 `dist/termux.mjs`），没有本仓库专属的适配器代码。它在这台机上探测到的传感器：光线 `light-bh1745`、加速度 `accelerometer-bmi160`；机型描述 `STF-AL10`。字段与工具清单见子模块的 API 文档。这台手机没有安装任何系统 TTS 引擎（`termux-tts-engines` 无输出），说话由运行基座的 `voice_speak`（Azure）完成。

## 2. 部署脚本 `scripts/deploy/`（开发者路径）

| 脚本 | 用法 | 作用 |
|---|---|---|
| `prepare-system.sh` | `apply` / `rollback` / `status` | 卸载 PowerGenie；为 Termux 系列与控制台加省电白名单、允许后台、待机分组 active（先备份到 `backups/`） |
| `termux-install.sh` | — | 校验 sha256 后安装 Termux、Termux:Boot、Termux:API（GitHub 版，签名一致，APK 在 `backups/apks/`） |
| `termux-bootstrap.sh` | — | 首次引导：推送引导文件到 `/sdcard/Download/windler-bootstrap/`，在 Termux 界面模拟输入执行 `termux/bootstrap.sh`，完成后通过 ssh 验证 |
| `windler-release.sh` | 无参数 / `rollback` | 测试、构建并发布运行基座 `main.cjs` 与 Termux 适配器 `termux.mjs`，健康检查失败自动回滚 |
| `lib.sh` | 被引用 | `dssh` / `dscp`：经 USB 端口转发连接 Termux 的 ssh |
| `power-no-optimize.sh` | 无参数 / `restore` | 全局关闭省电优化（第一轮精简时引入） |

设备端文件（`scripts/deploy/termux/`）：`bootstrap.sh`（安装 openssh、nodejs-lts、termux-services、termux-api、git、rsync、ffmpeg、imagemagick（后两者可选：运行基座缩小大图片时优先用它们，没有时 JPEG 用内置的 jpeg-js），配置 sshd 与外部调用）、`boot-windler`（开机脚本）、`windler-run`（runit 服务，以 `WINDLER_ADAPTER=$HOME/windler/current/termux.mjs` 启动）、`windler-log-run`（日志服务）。与 App 安装器写入的文件内容一致。

ssh 密钥默认 `~/.ssh/windler_honor9`（可用 `WINDLER_SSH_KEY` 覆盖），只存在于主机。

## 3. 精简脚本 `scripts/debloat/`

| 脚本 | 用法 | 作用 |
|---|---|---|
| `apply.sh` | `<清单文件> [disable\|uninstall\|restore]` | 逐行处理包清单；清单在 `configs/packages/`（荣耀9）与 `configs/packages/eva-al10/`（P9） |
| `block-ota.sh` | 无参数 / `clear` / `restore` | 屏蔽 EMUI 系统更新 HwOUC（受保护无法卸载），`clear` 同时清掉已下载的更新包 |
| `post-boot.sh` | `[清单目录]`，默认 `configs/packages` | 每次开机后运行：重新卸载被 EMUI 重装的包、重新关闭省电优化、重新屏蔽 HwOUC。P9 传 `configs/packages/eva-al10` |

多台手机同时连接时先 `export ANDROID_SERIAL=<序列号>`，脚本内部都用 `adb shell -n`，会继承该变量。
