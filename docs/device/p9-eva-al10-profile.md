# 华为 P9 (EVA-AL10) 设备档案

> 第二台实验机，2026-10-04 通过 ADB shell 采集（未 root）。
> 序列号、MAC、Android ID、IP 等敏感信息记录在本地 `private/device-identifiers.md`，不入库。
> 重新采集：`ANDROID_SERIAL=<SERIAL> scripts/adb/collect-device-info.sh`（两台手机同时连接时必须指定）。

## 基本信息

| 项目 | 值 |
|---|---|
| 市场名 | HUAWEI P9 |
| 型号 / 代号 | EVA-AL10 / HWEVA |
| 品牌 / 制造商 | HUAWEI / HUAWEI |
| 首发 API 级别 | 23（Android 6.0） |

## SoC 与算力

| 项目 | 值 |
|---|---|
| SoC | 海思麒麟 955（平台 `hi3650`） |
| CPU | 8 核 big.LITTLE，AArch64 |
| 小核 | 4 × Cortex-A53（part `0xd03`），480 MHz – 1.805 GHz |
| 大核 | 4 × Cortex-A72（part `0xd08`），480 MHz – 2.516 GHz |
| 指令集特性 | fp asimd evtstrm aes pmull sha1 sha2 crc32（**不支持** dotprod、fp16、sve） |
| ABI | arm64-v8a，armeabi-v7a，armeabi |
| GPU | ARM Mali-T880（驱动 r20p0），OpenGL ES 3.2，Vulkan 1.0 |
| NPU | 无 |

> 比荣耀9 的麒麟 960 老一代，内存也少 2 GB。同样只适合做云端模型的执行终端和传感器节点。

## 内存与存储

| 项目 | 值 |
|---|---|
| RAM | 4 GB（MemTotal 3,805,444 kB） |
| Swap（zram） | 2.2 GB |
| 精简并重启后的可用内存 | 约 2.9 GB（MemAvailable） |
| 存储 | 64 GB，`/data` 可用 50 GB，已用 2.7 GB |

## 系统

| 项目 | 值 |
|---|---|
| Android | 8.0.0（SDK 26） |
| EMUI | EmotionUI 8.0.0，版本号 EVA-AL10 8.0.0.550(C00) |
| EMUI API 级别 | 14 |
| 安全补丁 | 2020-07-01 |
| 内核 | Linux 4.4.23+，编译于 2022-11-22 |
| 构建类型 | user / release-keys |
| Treble | 已启用 |
| 区域 | zh-Hans-CN（国行 C00） |

## 安全状态

| 项目 | 值 | 说明 |
|---|---|---|
| Bootloader | 已锁定（`flash.locked=1`） | |
| Verified Boot | GREEN | 系统未经改动 |
| SELinux | Enforcing | |
| 加密 | FDE（全盘加密，`ro.crypto.type=block`） | 与荣耀9 的 FBE 不同：开机后需在加密界面输入密码，系统才继续启动；本机未设锁屏密码时为默认密码，自动解密 |
| ro.secure / ro.debuggable | 1 / 0 | 无法 `adb root` |
| ADB 权限 | shell（uid 2000） | 可用 `pm uninstall -k --user 0` |

## 显示

| 项目 | 值 |
|---|---|
| 物理分辨率 | 1080 × 1920（FHD），5.2 英寸，480 dpi |
| 当前覆盖分辨率 | 720 × 1280，320 dpi（EMUI 智能分辨率，`wm size` Override） |

## 电池（采集时）

| 项目 | 值 |
|---|---|
| 类型 | Li-poly，额定容量 3000 mAh |
| 电量 / 电压 / 温度 | 52% / 3.792 V / 34.0 °C |
| 健康状态 | Good |
| 充电方式 | USB |

> `/sys/class/power_supply/Battery/charge_full*` 对 shell 不可读，与荣耀9 一样无法设置充电上限。

## 传感器

| 传感器 | 型号 / 厂商 |
|---|---|
| 加速度计 + 陀螺仪 | LSM6DS3 / ST |
| 磁力计 | AK09911 / AKM |
| 光线 | BH1745 / ROHM |
| 距离 | TXC |
| 霍尔 | Huawei |
| SensorHub 虚拟传感器 | 计步、显著运动、重力、线性加速度、旋转矢量、通话传感器等 |

另有：前置摄像头、后置徕卡双摄、闪光灯、麦克风、NFC、指纹（后置）、BLE、Wi-Fi Direct；没有红外。

## 连接

| 项目 | 状态 |
|---|---|
| Wi-Fi | wlan0，已连接局域网 |
| USB | 12d1:107e，当前配置 `hisuite,mtp,mass_storage,adb,hdb` |
| 蜂窝 | 全网通（GSM / CDMA 特性都在），未插卡 |

> 开启 USB 调试前，USB 接口里只有 HiSuite、U 盘存储和华为私有调试接口（ff/48/01），`adb devices` 看不到它。开启后多出 `ff/42/01` 的 ADB 接口。

## 软件包概况（2026-10-04 第一轮精简后）

| 类别 | 数量 |
|---|---|
| 全部 | 85（精简前 196，见实验记录 `docs/experiments/2026-10-04-p9-debloat.md`） |
| 第三方 | 0（接手时就是恢复出厂的状态） |
| 已禁用 | 0（沿用荣耀9 经验，直接 `uninstall -k --user 0`） |

清单在 `configs/packages/eva-al10/`。与荣耀9 不同：EMUI 8 重启后**不会**重装被卸载的预装包，`com.huawei.parentcontrol` 也可以卸载。

## 已保留的有用组件

| 包 | 用途 |
|---|---|
| `com.svox.pico` | 自带离线 TTS 引擎（荣耀9 没有），可供智能体说话 |
| `com.baidu.input_huawei` | 本机唯一的完整输入法 |
| `com.google.android.webview` | 本机唯一的 WebView |
| `com.huawei.powergenie` | 暂留；部署 Quetzal 时由 `scripts/deploy/prepare-system.sh apply` 卸载 |

## 电源策略（2026-10-04 起）

Doze、App Standby、自适应电池都已关闭，已启用的包都在 deviceidle 白名单中（HwOUC 除外）。屏幕超时已是无限。重启后 Doze 会恢复，需要运行 `scripts/debloat/post-boot.sh configs/packages/eva-al10`。HwOUC 已按 `scripts/debloat/block-ota.sh` 屏蔽（Android 8.0 没有 `RUN_ANY_IN_BACKGROUND` 这个 appops，脚本会报一行错，其余生效）。
