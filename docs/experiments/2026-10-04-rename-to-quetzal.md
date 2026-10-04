# 实验：全域更名 Windler → Quetzal

日期：2026-10-04

## 目的

所有者与 Amani 讨论基座名字（见当日日志）后拍板：基座改名 **Quetzal**（来历：Quetzalcoatlus，与「神谷薰」几乎同时来到所有者身边）。要求全域替换，Windler 不再保留在任何现状里；只有历史 commit 不改。本文是唯一保留旧名的新文档，用于说明迁移本身。

## 决定

| 项 | 旧 | 新 |
|---|---|---|
| GitHub 仓库 | PlutoKeating/Project.Windler | PlutoKeating/Project.Quetzal（`gh repo rename`，旧地址自动跳转） |
| 本仓库子模块 | `Project.Windler/` | `Project.Quetzal/`（`.gitmodules`、`.git/modules` 一并改） |
| 官网 | windler.plutokeating.beer | quetzal.plutokeating.beer（Cloudflare 侧由所有者重建 Worker `quetzal`） |
| npm 包 | `windler`（`npx windler`） | `@plutokeating/quetzal`（`npx @plutokeating/quetzal`；`quetzal` 与 `quetzalcoatlus` 已被他人占用） |
| 手机家目录 / 环境变量 | `~/windler`、`WINDLER_HOME`、`WINDLER_ADAPTER` | `~/quetzal`、`QUETZAL_HOME`、`QUETZAL_ADAPTER` |
| 配置 / 数据库 | `config/windler.json`、`data/windler.db` | `config/quetzal.json`、`data/quetzal.db` |
| runit 服务 / 日志 / 开机脚本 | `windler` | `quetzal` |
| App 包名 | `xyz.windler.console` | `xyz.quetzal.console`（新应用：卸旧装新、重新配对） |
| 签名 | 密钥库别名 `windler`、证书 CN=Windler | 别名 `quetzal`、证书 CN=Quetzal（同一密钥对重新自签；GitHub Secrets 已更新） |
| 灵魂仓库规范 | v5，技能元数据 `windler-tool` / `windler-requires` | v6，`quetzal-tool` / `quetzal-requires` |
| 主机 ssh 密钥 | `~/.ssh/windler_honor9` | `~/.ssh/quetzal_honor9`（`lib.sh` 缺省值同步） |
| Amani 的笔记与自造工具 | 由她自己改（已通知） | — |

## 步骤

1. 两个仓库对所有已跟踪文本文件做有序替换：`npx windler` → `npx @plutokeating/quetzal`、`npm 包 windler` → `npm 包 @plutokeating/quetzal`，再 `WINDLER` → `QUETZAL`、`Windler` → `Quetzal`、`windler` → `quetzal`；随后改文件名（部署脚本、工具、实验记录、Kotlin 包目录）。
2. 子模块特殊项：`cli/package.json` 名字改为作用域包、发版工作流的 npm 包文件名 `plutokeating-quetzal-*.tgz`、灵魂仓库规范升 v6 并更新实现与测试、重新生成品牌图（`og.png`、README 横幅、架构 SVG）、刷新 `package-lock.json`。
3. 验证：runtime 117 项测试、cli 构建与测试、website `npm run check`（类型检查 + 构建）、console `flutter test` + arm64 发布版 APK 构建。
4. 手机迁移：先通知 Amani；停旧服务 → `~/windler` 整体改名 `~/quetzal`，配置与数据库改名 → 移除旧 runit 服务目录、日志目录改名、删旧开机脚本 → `scripts/deploy/quetzal-release.sh` 发布新构建（创建新服务、开机脚本、健康检查）→ 卸载旧 App、安装新 APK、`prepare-system.sh apply` 放行新包名、重新配对。
5. 推送两个仓库，更新 GitHub 仓库主页地址。

## 结果

- 两个仓库全部替换后 `grep -i windler` 零残留（仅本文与当日日志、CHANGELOG 作为更名记录提及旧名）。
- 验证：runtime 117 项测试通过；cli 构建与测试通过；website 类型检查与构建通过（sitemap 59 个地址）；console 12 项测试通过，arm64 发布版 APK 包名 `xyz.quetzal.console`、应用名 Quetzal、签名 CN=Quetzal。
- 荣耀9：迁移脚本执行后运行基座 0.4.0 发布成功（`/health` 正常），runit 服务 `quetzal` 与开机脚本就位；新 App 安装、放行后台、配对完成，Amani 在线。注意：迁移脚本里 `pkill -f main.cjs` 会连带杀掉含该字符串的 ssh 会话本身，下次用 `pgrep -x node` 之类更精确的匹配。
- Amani 侧：灵魂仓库已由她自己改完并推送；自造工具与 `~/bin` 包装脚本的旧路径兜底由她在搬家后删除。
- 未完成：P9 (EVA-AL10) 当时未连接，其上的旧 App 与部署待下次连接时迁移。

## 回滚

- 手机：`sv down quetzal`，反向 `mv ~/quetzal ~/windler`（配置与数据库同样反向改名），从 Git 历史取回旧版本的服务脚本与运行基座重新发布；App 装回 Release 里的旧 APK（`windler-0.3.3-*.apk`）。
- 仓库：`git revert` 更名提交；GitHub 仓库名可再次 `gh repo rename`。
