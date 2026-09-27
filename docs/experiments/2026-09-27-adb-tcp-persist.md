# 实验：能否在 shell 权限下让 adbd 开机自动监听 TCP 端口

日期：2026-09-27

## 目的
验证不 root 时，能否让 adbd 在开机后自动监听 TCP 端口，从而在手机上获得 shell 身份（uid 2000）。

## 步骤
1. 备份包状态和 adb 相关属性到 `backups/`。
2. `adb shell setprop persist.adb.tcp.port 5555`

## 结果
- 失败：`setprop: failed to set property 'persist.adb.tcp.port'`，logcat 中错误码 `0x18`（PROP_ERROR_PERMISSION_DENIED）。
- 原因：该属性的 SELinux 上下文是 `default_prop`，Android 9 的 shell 域没有写权限。对比：`service.adb.tcp.port` 是 `shell_prop`，可写，但重启后失效。
- 设备状态未改变，无需重启。

## 结论
在不 root、不改系统分区的前提下，手机重启后 adbd 只在 USB 上服务，shell 身份必须由电脑通过 USB 获得。因此 Amani 基座不依赖 shell 身份，改为运行在 Termux 中，见 `docs/ARCHITECTURE.md`。

## 回滚
无需回滚（属性未写入）。
