# 实验：Windler 作为开源产品——用户只装 Termux，其余由 App 自动完成

日期：2026-10-03

## 目的

把 Windler 从「靠电脑 ADB/ssh 手工搭起来的运行环境」变成任何人都能在一台旧安卓手机上装好的产品：用户只需要装 Termux 三件套与 Windler App，运行基座的安装、服务注册、开机自启、升级与回滚全部由 App 完成，全程不需要电脑，也不需要配对码。

## 现状核查（手机只读巡检）

- 运行中的基座 0.1.0 健康（`/health` 正常，常驻内存 162 MB，峰值 282 MB）。
- 必要组件：Termux 基础环境、`nodejs-lts`（v24.18.0）、`termux-services`（runit）、`termux-api` + Termux:API App、`git`、`openssh`（只用到 `ssh-keygen` 与 `ssh`）、Termux:Boot、`allow-external-apps=true`、`main.cjs` + 适配器 + `config/windler.json`。这组依赖在手机上实测 61 个包、下载 39 MB、占用 175 MB（含基础环境里已有的包）。
- 可选：`ffmpeg`（连依赖 92 MB）/ `imagemagick`（65 MB，拉进 ghostscript、llvm、python）只用于缩图；`pdftotext` 等只用于读文档，都有兜底。官方源的 libc++ 已到 30，此前为修 ffmpeg 手动升 libc++ 的补丁不再需要。
- 非必要（运维通道或她为业务自装）：`sshd`、`ssh-agent`、`rsync`、`gh`、`jq`、`tesseract`、`sox`、`espeak`、`lsof`、`python`、`wrangler`、`agently-cli`；runit 下的 `dnsproxy`、`probe`、`seccmptest`；`~/bin` 与家目录里的工具和测试文件。前缀目录 1.5 GB、305 个包，产品真正需要的不到 200 MB。
- 这台手机没有任何系统 TTS 引擎（`termux-tts-engines` 挂起无输出）。
- Windler App 已持有 `RUN_COMMAND` 权限（`granted=true`），当初 `pm grant` 只是图省事，正常路径是系统弹窗。

## 链路可行性结论

Termux 出于安全设计，默认拒绝外部应用下发命令（`allow-external-apps`），这个开关只能在 Termux 自己的终端里打开，所以用户至少要打开 Termux 一次、粘贴一行。其余全部可由 App 通过 Termux 的 `RUN_COMMAND` 自动完成。

## 做了什么（Windler 子模块，提交 a8df698、6c11777、8ca4d35）

1. **Termux 身体适配器进子模块**（`runtime/adapters/termux`，构建为 `dist/termux.mjs`）：传感器按名字探测、机型只作描述，替代本仓库的 `adapters/honor9`。本仓库的适配器目录已删除。
2. **缩图兜底**：没有 ffmpeg / ImageMagick 时 JPEG 用纯 JS 的 jpeg-js 缩小，手机上不必再装这两个包。
3. **配置缺省**：时区取系统；相机、麦克风、定位、操作屏幕默认「每次询问」（只影响新装；这台机的配置文件已有显式值，不受影响）。
4. **App 安装器**：App 在 127.0.0.1 开临时 HTTP 服务提供安装脚本与内置的 `main.cjs` / `termux.mjs`、接收进度；脚本通过 `RUN_COMMAND` 执行：装软件包（可选中国大陆镜像）→ 放入版本目录 → 注册 runit 服务、开机脚本 → 写机型与时区 → 切换版本并启动 → 40 秒健康检查，失败切回上一版 → 把网关令牌交给 App（同机不需要配对码）。
5. **安装向导**（五步）：三件套检测与下载链接 → 授权 → 复制那一行并打开 Termux、回连检测 → 安装进度 → 保活引导（忽略电池优化、电池优化名单、各厂商自启动管理页、打开一次 Termux:Boot）。服务页「升级 / 重装」与 App 升级后的顶部横幅复用同一向导。
6. **正式签名**从 `key.properties` 读取（不入库），没有时退回 debug。版本 0.2.0。

设备端目录与服务约定与本仓库 `scripts/deploy/` 完全一致（`~/windler/releases/<版本>`、`current` / `previous`、`$PREFIX/var/service/windler`、`~/.termux/boot/windler`），两条路径可以互相接管。

## 验证

| 项 | 结果 |
|---|---|
| runtime `npm test` | 92 项通过（新增 Termux 适配器探测、jpeg-js 缩图） |
| runtime `npm run build` | `main.cjs` 6.2 MB、`termux.mjs` 7.6 KB |
| console `flutter analyze` / `flutter test` | 无问题 / 12 项通过（新增安装器命令、进度解析、本机 HTTP 服务） |
| console `flutter build apk --release` | 23.3 MB（内置运行基座后） |
| `install.sh` | `bash -n` 语法通过；真机升级见下 |

## 真机验证（2026-10-03 21:18，通过 uiautomator 驱动 App）

1. `adb install -r` 新 APK（0.2.0+2）后打开 App：首页顶部出现「App 内置的运行基座是 0.2.0，正在运行的是 0.1.0」横幅与「升级」按钮。
2. 点「升级」进入向导：三件套版本检测正确（0.118.3 / 0.53.0 / 0.8.1），第 2 步显示「已授权」，第 3 步回连探测通过，第 4 步「升级到 0.2.0」可点。
3. 点下后约 10 秒完成：`install.log` 依次 pkg（已有，跳过安装）→ runtime → service → config（`body honor9 timezone Asia/Shanghai`，原值保留）→ start（`sv restart` 成功）→ health；向导显示「完成：运行基座 0.2.0 已启动，控制台已自动连接」。
4. 核验：`/health` 版本 0.2.0；`current → releases/0.2.0`，`previous → releases/20261001-142312-89f9185`（ssh 发布的旧版本，可回滚）；`run` 已改为 `WINDLER_ADAPTER=…/termux.mjs`；日志 `[body] 身体：termux（一台 STF-AL10 安卓手机…有相机、麦克风、扬声器、光线与运动传感器）`；网关令牌未变（控制台无需重新配对）；飞书重新连上。返回首页横幅消失、状态在线。
5. **灵魂仓库**：同一版本带入规范 v4（不再检查内容）。通过网关触发 `syncSoul`：`补齐灵魂仓库规范结构` + `控制台 触发同步` 两次提交，10-02 以来被挡住的全部记忆改动已推送到远端，`lastError` 为空，工作区干净。

未验证：第一次打开 Termux 尚未初始化完成时向导的提示是否清楚（这台机早已初始化）。

## 回滚

- 子模块：`git -C Project.Windler checkout 89f9185`，本仓库 `git checkout <上一提交> -- .`。
- 手机：`scripts/deploy/windler-release.sh rollback` 切回 `previous`（ssh 发布的 0.1.0），或在 App 服务页重新「升级 / 重装」。规范 v4 的仓库文件 `.soul-spec.json` 回到 v3 实现也能读。
