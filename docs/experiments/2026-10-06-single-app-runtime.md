# 实验：只装一个 App（运行基座内置进 Quetzal App）

日期：2026-10-06

## 目的

所有者要求新用户只装一个 Quetzal App，不再装 Termux、Termux:API、Termux:Boot，也不在 Termux 里粘贴命令。做法（子模块 `console/tool/android-runtime/`）：用 termux-packages 以 App 自己的前缀 `/data/data/xyz.quetzal.console/files/usr` 从源码重编 Node.js、git、openssh、proot；可执行文件改名为 `lib*.so` 放进 APK 的 jniLibs（安装时解压到 nativeLibraryDir，Android 10+ 唯一允许 App 执行的位置），其余文件打成 `rootfs.tar`。App 的前台服务 `RuntimeService` 运行运行基座，`BodyServer` 代替 Termux:API 提供身体能力。本实验在荣耀9 上验证这条路。

## 准备：清空旧环境（所有者要求「完全卸载，形成崭新的测试环境」）

1. 先导出包状态到 `backups/`（不入库）：全部包、已禁用包、四个相关包的版本与首次安装时间。
2. `pm uninstall` 卸载 `xyz.quetzal.console`（1.0.3）、`com.termux.boot`、`com.termux.api`、`com.termux`（0.118.3）。Termux 里的运行基座家目录（对话记录、模型 Key 密文、部署私钥）随之删除；人格与记忆在灵魂仓库（GitHub 私有仓库）里，不受影响。
3. 共享存储里没有 Termux / Quetzal 的残留（`/sdcard/ui.xml` 是早前 uiautomator 的界面转储，与此无关，没动）。

## 步骤

1. 主机上 `build-packages.sh`（termux-packages 锁定提交 `ce59c5e`，Docker 构建镜像）→ `pack.sh`（依赖闭包 34 个包；白名单 8 个可执行文件：node、git、git-remote-http、ssh、ssh-keygen、proot 与它的两个 loader；node-datachannel 按锁定的 sha512 下载核对后剥掉调试信息）→ `bundle-runtime.sh` → debug APK，`adb install`。
2. 打开 App → 「在这台手机上安装 Quetzal」→「安装」；再从清空数据（`pm clear`）开始重复一次完整的新用户流程，包括身体权限的系统弹窗。
3. 经 `adb forward` 调网关 RPC 与身体接口（令牌从 App 数据目录读取，只在内存与终端里，未写进任何文件）逐项验证。

## 结果

| 项 | 结果 |
|---|---|
| 运行环境解压 | 首次约 0.9 秒；App 升级后 nativeLibraryDir 换路径，自动重新解压、重建链接 |
| 运行基座 | 1.0.4 在 App 的前台服务里启动；Node v24.18.0、`node:sqlite` 可用；安卓适配器识别出机型与光线、运动传感器 |
| 安装向导 | 点「安装」约 30 秒内显示「已启动，控制台已自动连接」，进主界面「在线 · 尚未配置模型」；不需要配对码 |
| 沙箱 | proot，探针验证通过：密钥、配置目录与 App 的私有数据（`shared_prefs` 等）对她的命令不可见 |
| 网状层 | node-datachannel 加载成功（`available: true`），同步服务缺省为官方 |
| git / ssh | 灵魂目录里正常提交；`ssh-keygen` 生成部署密钥；ssh 连 GitHub 得到预期的 `Permission denied (publickey)`；git 走 https 访问 gitee 正常，访问 GitHub 的 https 在读数据时被对端断开（网络原因，ssh 正常） |
| 身体接口 | 电池、光线、加速度、传感器列表、通知、振动、手电、剪贴板读写、拍照（前置 2048×1536）、录音、播放全部正常；家目录以外的路径被拒绝；错误令牌被拒绝 |
| 定位 | 本机没有网络定位提供者（无谷歌服务），室内 GPS 60 秒内无定位：改为退回最近一次已知位置并注明多久以前（实测返回了约 4 天前的位置）。坐标未记录 |
| 身体名 | 首次启动按机型写成 `stf-al10`（旧的 Termux 安装时是手动起的 `honor9`，需要时在控制台改） |
| 升级后自启 | `MY_PACKAGE_REPLACED` 广播被 EMUI 系统管家拦下（应用未在「自启动管理」放行）：升级后要打开一次 App 才会拉起；放行后应与开机自启一样自动 |
| 旧进程 | `adb install -r` 升级时 App 进程与 node 子进程一并被系统清掉，没有残留抢端口 |

测试拍的照片与录音只用于确认功能，已从手机与主机上删除。

## 回滚

- 卸载新 App：`adb shell pm uninstall xyz.quetzal.console`（会删掉 App 数据目录里的运行基座家目录；灵魂仓库不受影响）。
- 恢复旧方案：按 `backups/` 里记下的版本重新安装 Termux 三件套与 Quetzal App 1.0.3，在 Termux 里接回同一个灵魂仓库。

## 后续

- 在 EMUI「自启动管理」里放行 Quetzal 后复测开机自启与升级后自启。
- 接入灵魂仓库与模型后让她实际调用一次身体工具（拍照、定位）走完整的闸门与审计。
- Android 10+ 真机（W^X 限制）上复测：本机是 Android 9，没有覆盖到「数据目录不可执行」的限制。
