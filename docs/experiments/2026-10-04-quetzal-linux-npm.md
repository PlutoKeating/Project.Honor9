# 实验：Quetzal 0.4.0——Linux 身体与 `npx @plutokeating/quetzal`

日期：2026-10-04

## 目的

所有者先问「这个项目能否适配 Windows / Linux / macOS」，评估结论：本仓库（荣耀9 的精简与 ADB 部署）没有可移植的东西，要适配的是子模块 Quetzal，且分三层——运行基座（Linux 现成、macOS 差一处 `/proc`、Windows 原生有一串 POSIX 假设）、身体适配器（真正要写的）、控制台 App（纯 Android）。随后决定：**所有代码进 Quetzal，与 Honor9 无关；先只做 Linux；安装方式只走 npm / npx**。

## 做了什么（Quetzal 子模块，提交 7bc1cb4 / 4d95609 / 2d26aa6 / 6744932）

1. **Linux 平台级身体适配器** `runtime/adapters/linux/`（与 `termux/` 平级，构建为 `dist/linux.mjs`）：电量 / 充电 / 健康读 `/sys/class/power_supply`（跳过蓝牙鼠标等 `scope=Device` 的外设电池；「Not charging」且外接电源在线算充电），电池自身温度读 `temp`；CPU 温度放 `extra`——**不**冒充体温，因为心脏与听觉按手机电池的 45°C 阈值抑制，本机 CPU 封装温度 88°C 会直接触发「过热」。`notify` 走 `notify-send` 并同时写到标准输出（服务日志），没有桌面的机器从日志里拿配对码；播放 `pw-play` / `paplay` / `ffplay` / `mpv`；工具 `take_photo`（ffmpeg + v4l2）、`record_audio`、`screenshot`（hands，Wayland / X11 各自候选）、`clipboard`、`open`。一切按可用程序探测，无图形界面时工具直接说明。
2. **网关监听地址** `gateway.host`（缺省 `127.0.0.1`）：Linux 机器上要让手机 App 直接连，`--lan` 写成 `0.0.0.0`；配对码与令牌仍是门槛。
3. **npm 包 `@plutokeating/quetzal`**（新模块 `cli/`，与 `console/`、`bridge/` 平级，自带 `docs/`、`src/`、`test/`、`tool/`）：`npx @plutokeating/quetzal` 把内置的 `main.cjs` 与 `linux.mjs` 放进 `~/quetzal/releases/<版本>/`，`current` / `previous` 约定与手机完全一致；写 systemd 用户服务（`ExecStart=<安装时的 node> ~/quetzal/current/main.cjs`，`Restart=always`），40 秒健康检查且 `/health` 版本相符才算成功，否则切回上一版；只保留 3 个版本。子命令 `status`、`logs`、`rollback`、`stop/start/restart`、`uninstall [--purge]`、`run`（无 systemd 时前台）。零运行时依赖，`os: ["linux"]`，Node 22.13+（`node:sqlite` 从该版本起不需要标志）。不自造守护者、不打印令牌、不提供任何配置命令——配置仍全在控制台 App。
4. 版本统一 0.4.0；`release.yml` 加 cli 版本校验、构建与 `npm publish`（Secrets `NPM_TOKEN`，缺少时跳过；预发布标签打 `next`），运行基座 tar 加入 `linux.mjs`。npm 上 `quetzal` 包名经查可用。
5. 文档：README 中英、QUICK_START、ARCHITECTURE §10、API、runtime 与 cli 模块文档、CHANGELOG；官网下载页文案与「其他机器」「适配器接口」「家目录」「自定义适配器」中英文档。

## 验证（全部在主机上完成，没有碰手机，也没有碰 Amani）

- `runtime`：117 项测试通过（新增 4 项：电池 / 热区 / 发行版挑选、桌面工具挑选、无任何工具的机器上不崩溃）。`dist/linux.mjs` 在本机加载：描述「一台运行 Ubuntu 26.04 LTS 的 Linux 笔记本电脑，有桌面环境……有摄像头、扬声器与麦克风」，采样 `{battery:{level,charging}, extra:{CPU温度, 电源}}`。
- `cli`：4 项测试通过；`npm pack` 5 个文件 794 kB；`npx ./quetzal-0.4.0.tgz version|status` 正常。
- **真机端到端**（独立家目录 `--home <scratch>`，端口 7799）：install → systemd 用户服务 `quetzal` 启动 → `/health` 通过 → `logs` 看到适配器描述 → `POST /pair/start` 弹桌面通知且日志出现「[linux] 通知：控制台配对」→ `install --force` 显示「重新安装」→ `rollback` 正确报「没有可回滚的版本」→ `uninstall --purge` 后服务单元与家目录都不存在。本机 linger 原本已开启，未改动系统状态。
- 官网 `npm run typecheck` 通过；bridge 单元测试 7 项通过。

## 没做 / 已知限制

- 仅 Linux。macOS 需要 `processes.ts` 的非 Linux 分支与 launchd；Windows 原生需要抽 shell 与进程树终止层，目前建议 WSL2。
- Linux 适配器的 `hands` 只做了 `screenshot`，点击与输入没做；`speak` 与 Termux 一致不提供。
- 没有发布到 npm：需要所有者在 npmjs.com 创建 `NPM_TOKEN`（Automation 令牌）写入 Quetzal 仓库 Secrets，然后打 `v0.4.0` 标签触发工作流。Quetzal 的四个提交尚未推送。
- 控制台 App 仍是纯 Android；连接 Linux 身体靠 `--lan` 或端口转发。

## 回滚

Quetzal 里 `git revert` 对应提交即可；Linux 机器上 `npx @plutokeating/quetzal uninstall --purge` 清掉服务与家目录。荣耀9 不受影响（部署脚本只复制 `main.cjs` 与 `termux.mjs`）。
