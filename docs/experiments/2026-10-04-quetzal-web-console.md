# 实验：Quetzal 0.5.0——网页控制台与桌面外壳

日期：2026-10-04

## 目的

所有者指出：Linux 用户不该借手机、更不该借 Termux；`npx @plutokeating/quetzal` 装完应当直接在电脑浏览器里配置和使用。决定复用现有 Flutter 控制台构建 Web 版（不重写一套 TypeScript 前端），但桌面布局从头构思，组件与对话行为照用；并否决了另建「路人沙箱」的做法——所有者直接在本机安装验证。

## 做了什么（Quetzal 子模块，提交 1f1e431 … 157851d，标签 v0.5.0）

1. **运行基座** `runtime/src/web.ts`：网关托管 `current/web/`（`QUETZAL_WEB_DIR` 可覆盖；单页回退、ETag、目录穿越防护）；`GET /auth/local` 只给回环地址 + 本机 Host（+ 本机 Origin）的浏览器发令牌，免配对码且不扩大信任边界（本机进程本来读得到令牌文件），ssh 隧道转发算本机。
2. **控制台**：`lib/platform/` 条件导入隔离安卓与浏览器（dart:io / XMLHttpRequest、URL #片段、字体加载、Mermaid 的 WebView / iframe，同一份 `view.html` 用 postMessage 桥）；`PageFrame` / `showSheet` / `PaneWidth` 让每个页面在手机与桌面两种外壳里都成立；`shell/desktop.dart` 四栏：导航栏 72 · 列表栏 280 · 主区（最宽 820，嵌套 Navigator）· 她此刻 320（光团、一句话、进行中的醒来、待审批、戳一下、内在、身体，永远在那里）；`setUrlStrategy(null)` 让 Flutter 不改写 URL，`#/chat/<会话>` 等由 `shell/nav.dart` 管理；自带 GB2312 子集的 Noto Sans CJK SC（3 MB，`tool/gen-cjk-font.py`），CanvasKit 不走 CDN、只留必要变体（`tool/build-web.sh`）。桌面上 Enter 发送、Shift+Enter 换行。
3. **npm 安装器**：`web/` 随版本目录放入，装完自动 `xdg-open`（`--no-open`），新增 `open`，`status` 显示网页控制台地址；包 11 MB。
4. 版本 0.5.0；文档与官网全面更新（另见 Honor9 日志）。

## 验证

- 运行基座 120 项、控制台 12 项、cli 5 项测试通过；`flutter analyze` 零问题。
- Playwright（Chromium 1440×900）截图核对对话 / 心流 / 记忆 / 控制 / 身份页与手机宽度布局；真实发消息验证实时过程与标题同步（无模型时她回「尚未配置可用的模型」）；Mermaid iframe 桥回报高度；启动占位在首帧后移除。
- 隔离家目录 `npx` 安装 → `/` 200 → `/auth/local` 200 → `uninstall --purge`，主机未留痕；安卓 debug APK 可构建（需临时挪开 `~/.gradle/init.gradle` 的镜像，已复原）。
- 发布：`v0.5.0` 发版工作流一次通过，GitHub Release（正式签名 APK）、npm `@plutokeating/quetzal@0.5.0`（含 `runtime/web/` 51 个文件）、GitHub Packages。

## 没做 / 已知限制

- 网页版没有麦克风与安装器：听觉仍在手机 App；升级在装它的机器上再运行一次 npx。
- 手机上的运行基座不带 `web/`（APK 不装网页版），所以电脑浏览器连不到手机上的网页控制台；需要时可把 Web 构建放到手机的 `current/web/`，网关同样托管。
- 荣耀9 本身不受影响：发布脚本只复制 `main.cjs` 与 `termux.mjs`。

## 回滚

Quetzal 里 `git revert` 对应提交；Linux 机器上 `npx @plutokeating/quetzal rollback` 或 `uninstall --purge`。
