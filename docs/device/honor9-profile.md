# 荣耀9 (STF-AL10) 设备档案

> 采集时间：2026-09-27，通过 ADB shell 采集（未 root）。
> 序列号、MAC、Android ID、IP 等敏感信息记录在本地 `private/device-identifiers.md`，不入库。
> 重新采集：`scripts/adb/collect-device-info.sh`

## 基本信息

| 项目 | 值 |
|---|---|
| 市场名 | Honor 9 |
| 型号 / 代号 | STF-AL10 / HWSTF（主板 STF） |
| 品牌 / 制造商 | HONOR / HUAWEI |
| 首发 API 级别 | 24（Android 7.0） |

## SoC 与算力

| 项目 | 值 |
|---|---|
| SoC | 海思麒麟 960（平台 `hi3660`） |
| CPU | 8 核 big.LITTLE，AArch64 |
| 小核 | 4 × Cortex-A53（part `0xd03`），533 MHz – 1.844 GHz |
| 大核 | 4 × Cortex-A73，903 MHz – 2.362 GHz |
| 指令集特性 | fp asimd evtstrm aes pmull crc32（**不支持** dotprod、fp16、sve） |
| ABI | arm64-v8a，armeabi-v7a，armeabi |
| GPU | ARM Mali-G71（驱动 r14p0），OpenGL ES 3.2 |
| NPU | 无（麒麟 970 开始才有 NPU） |

> 对智能体的意义：本机没有 NPU，CPU 也不支持 dotprod，因此在本地跑大模型推理会很吃力，只适合跑很小的量化模型。本机更适合做云端模型的**执行终端和传感器节点**。

## 内存与存储

| 项目 | 值 |
|---|---|
| RAM | 6 GB（MemTotal 5,862,864 kB） |
| Swap（zram） | 2.2 GB |
| 采集时可用内存 | 约 2.7 GB |
| 存储 | 128 GB eMMC，`/data` 可用 111 GB，已用 4.6 GB |
| Dalvik 堆 | heapsize 512m |

分区挂载：`/`、`/vendor`、`/odm`、`/product`、`/cust`、`/preas` 等都是 dm-verity 保护的只读分区，已用满 100%，属于正常现象。

## 系统

| 项目 | 值 |
|---|---|
| Android | 9（SDK 28） |
| EMUI | EmotionUI 9.1.0，版本号 9.1.0.225 (C00E125R1P9) |
| 安全补丁 | 2020-05-01 |
| 内核 | Linux 4.9.148，SMP PREEMPT，编译于 2022-04-21 |
| 构建类型 | user / release-keys |
| Treble | 已启用 |
| Zygote | zygote64_32 |
| 区域 | zh-Hans-CN（国行 C00） |

## 安全状态

| 项目 | 值 | 说明 |
|---|---|---|
| Bootloader | 已锁定（`flash.locked=1`） | 华为已停止提供解锁码 |
| Verified Boot | green | 系统未经改动 |
| SELinux | Enforcing | |
| 加密 | FBE（文件级加密） | |
| ro.secure / ro.debuggable | 1 / 0 | 生产版本，无法用 `adb root` |
| ADB 权限 | shell（uid 2000） | 可以使用 `pm disable-user`、`pm uninstall --user 0` |

> 因此，精简工作只能在 shell 权限范围内进行，也就是按用户禁用或卸载应用，不改动系统分区。

## 显示

| 项目 | 值 |
|---|---|
| 分辨率 | 1080 × 1920（FHD），5.15 英寸 |
| 密度 | 480 dpi |

## 电池（采集时）

| 项目 | 值 |
|---|---|
| 类型 | Li-poly，额定容量 3200 mAh |
| 电量 / 电压 / 温度 | 93% / 4.363 V / 31.0 °C |
| 健康状态 | Good |
| 充电方式 | USB，500 mA |

> 设备会长期插电运行，需要关注电池鼓包风险和温度，后续可以考虑限制充电上限。

## 传感器

| 传感器 | 型号 / 厂商 |
|---|---|
| 加速度计 + 陀螺仪 | BMI160 / Bosch |
| 磁力计 | AK09911 / AKM |
| 光线 | BH1745 / ROHM |
| 距离 | PA224 / TXC |
| 霍尔 | Huawei |
| SensorHub 虚拟传感器 | 计步、显著运动、倾斜、重力、线性加速度、旋转矢量等 |

另有：前后摄像头（后置 20MP + 12MP 双摄）、麦克风、NFC、红外遥控、指纹（前置）。

## 连接

| 项目 | 状态 |
|---|---|
| Wi-Fi | wlan0，已连接局域网 |
| USB | 12d1:107e，当前配置 `hisuite,mtp,mass_storage,adb` |
| 蜂窝 | 基带已识别（全网通） |

## 软件包概况

| 类别 | 数量 |
|---|---|
| 全部 | 108（精简前 251，见实验记录 2026-09-27） |
| 系统预装 | 239 |
| 第三方 | 12 |
| 已禁用 | 0（EMUI 重启会清除 disable-user，改用 uninstall --user 0） |

> 239 个系统包是精简工作的主要对象，清单会放到 `configs/packages/`。

## Quetzal 运行环境（2026-09-28 起）

| 项目 | 值 |
|---|---|
| Termux / Termux:Boot / Termux:API | v0.118.3 / v0.8.1 / v0.53.0（GitHub 版） |
| Node.js | v24.18.0（Termux `nodejs-lts`） |
| 图片工具 | ffmpeg 8.1.3、ImageMagick 7.1.2（可选：运行基座缩小大图片时优先用它们，没有时 JPEG 用内置的 jpeg-js；2026-09-28 曾手动升 libc++ 修 ffmpeg，官方源现已是 libc++ 30） |
| Quetzal App | `xyz.quetzal.console` 1.0.3（2026-10-06：从 GitHub Release `v1.0.3` 下载，先用发版公钥验证 `SHA256SUMS.sig`、再核对 APK 的 sha256，经 `adb install -r` 覆盖升级；证书 CN=Quetzal；已授予 Termux RUN_COMMAND 与 RECORD_AUDIO 权限；「控制 → 账户」可管理同步服务上的账户） |
| 运行基座 | Quetzal 1.0.3（2026-10-06 正式版：手机锁屏，暂由已验签 APK 内置的 `main.cjs` / `termux.mjs` 经 ssh 按 App 向导的约定放进 `~/quetzal/releases/1.0.3/`，文件与发布版逐字节一致，`previous` 为 1.0.1；解锁后再经 App 的官方向导重装。命令沙箱为 proot（Termux 新装 `proot`），密钥目录、配置、版本目录与服务目录对她的命令隐藏；网状层协议 v2，与本机局域网直连，首次见到的公钥已钉住；同步服务 `https://sync.quetzal.plutokeating.beer`），家目录 `~/quetzal`，runit 服务 `quetzal`，身体适配器 `termux.mjs`（身体名 `honor9`） |
| 灵魂仓库 | 规范 v9（2026-10-05：误推事故清理后重新克隆，每个克隆在 `.git/quetzal-soul-roots.json` 记下两个灵魂根提交；顶层允许她自己的目录如 `ops/`） |
| 飞书 | `com.ss.android.lark` 8.1.12（官方签名，已安装未打开） |
| 已卸载的查杀组件 | `com.huawei.powergenie`（`pm uninstall -k --user 0`） |
| 屏幕超时 | 无限（`2147483647`，2026-09-28 起；原 10 分钟，出厂 30 秒） |
| 锁屏 | 密码 + 人脸解锁（FBE：重启后需首次解锁，Quetzal 才会自启） |
| 充电控制 | 充电节点不可写，无法设置充电上限 |

部署与架构见 `docs/ARCHITECTURE.md`。

## 电源策略（2026-09-27 起）

Doze（深度和轻度）、App Standby、自适应电池都已关闭，所有包都在 deviceidle 白名单中。重启后 Doze 会自动恢复，需要运行 `scripts/debloat/post-boot.sh`。
