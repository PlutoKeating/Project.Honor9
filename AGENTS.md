# AGENTS.md · 项目规则（每次会话必读）

本文件（`CLAUDE.md` 是指向它的软链接）记录 Project.Honor9 的项目意图和必须遵守的规则。新会话开始时先读本文件，再读 `docs/vision.md` 和 `docs/device/honor9-profile.md`。

## 项目意图

- 目标设备：一台通过 USB ADB 连接到本机的**荣耀9 (STF-AL10)** 实验机。设备详情见 `docs/device/honor9-profile.md`。
- 目的：尽可能裁剪和精简设备上用不到的功能、软件和服务，把它改造成 AI-Native 时代的**智能体工坊**，并在上面培育名为 **「Amani（神谷薰）」** 的智能体（相关内容放在 `agent/amani/`）。
- 智能体命名：英文名 **Amani**，中文名 **神谷薰**，代码与目录标识符统一用 `amani`。
- 本仓库记录工作情况和实验经验，也存放维护过程中写的脚本和工具。
- 仓库托管在 https://github.com/PlutoKeating/Project.Honor9（**公开仓库**），许可证为 **AGPLv3**。

## 必须遵守的规则

### 1. 敏感信息绝不入库（最重要）

仓库是公开的，下面这些**本机特有**的信息只能写进本地的 `private/` 目录（已加入 .gitignore）：

- 序列号（`ro.serialno`、adb serial）、IMEI/MEID、Android ID
- Wi-Fi / 蓝牙 MAC 地址、局域网 IP / IPv6 地址、主机 USB 端口路径
- 账号、令牌、密钥、Wi-Fi 密码，以及其他能定位到这台具体设备或具体人的标识

提交到仓库的文档和脚本里只能用 `<SERIAL>` 这样的占位符，或者用 `ANDROID_SERIAL` 环境变量，**不得硬编码**。
**每次提交前**都要运行 `scripts/check-secrets.sh`，确认没有命中。它会拿 `private/` 里登记的值和通用的 MAC/IP 格式去比对暂存区。新克隆的仓库要先安装钩子：`ln -sf ../../scripts/check-secrets.sh .git/hooks/pre-commit`。
型号、SoC、内存、系统版本这类**非唯一**的硬件和软件信息可以公开记录，而且应当充分记录。

### 2. 设备信息要充分记录

- 设备的公开档案维护在 `docs/device/honor9-profile.md`，敏感标识维护在 `private/device-identifiers.md`。
- 重新采集用 `scripts/adb/collect-device-info.sh`，它会自动把公开信息和敏感信息分开输出。
- 系统升级、改动配置、精简应用之后，都要同步更新设备档案。

### 3. 操作要可逆，先备份再改动

- 只在 ADB shell 权限（uid 2000）范围内操作。优先用 `pm disable-user --user 0`，其次用 `pm uninstall -k --user 0`。不刷机，不改系统分区。
- 每一批改动之前，先把当前的包状态导出到 `backups/`（不入库）。
- 每次实验都写进 `docs/experiments/`，写明目的、步骤、结果和回滚方法。当天的工作概要写进 `docs/journal/YYYY-MM-DD.md`。

### 4. 定位与免责

- 本项目**仅用于学习和研究**，只操作我们自己拥有的设备。不编写、不提供破坏或入侵他人计算机系统的方法，不以牟利为目的。
- 这一定位已经写在 README 的免责声明里，新增内容不得违背。

### 5. 文档与风格

- 文档用中文。目录结构的说明见 README。
- Git 提交信息用中文。只有在用户要求时才推送到远程。
