# 实验：关闭省电优化 + 第一轮系统精简（2026-09-27）

## 目的
1. 全局关闭省电优化，保证智能体进程常驻不被 Doze / 待机分组冻结。
2. 在 shell 权限内移除无用的预装软件。

## 备份
`backups/20260927-204652/`（本地，不入库）：全部包及 APK 路径、第三方包、deviceidle 白名单、电源相关设置。

## 步骤
- 省电：`scripts/deploy/power-no-optimize.sh`
  - `settings put global low_power 0`、`app_standby_enabled 0`、`adaptive_battery_management_enabled 0`
  - `dumpsys deviceidle disable`（关闭 Doze 的深度和轻度空闲）
  - 把所有已启用的包加入 deviceidle 白名单（电池优化白名单）
- 精简：`scripts/debloat/apply.sh <清单> uninstall`，清单见 `configs/packages/`
  - `debloat-01-thirdparty.txt`：12 个预装第三方应用
  - `debloat-02-apps.txt`：华为/系统面向人的应用、商店、云服务、推广
  - `debloat-03-services.txt`：遥测、推送、GMS 周边等后台服务
  - `keep.txt`：刻意保留的核心包
- 开机后：`scripts/debloat/post-boot.sh`

## 结果
- 包数量：251 → **108**。重启后开机正常，SystemUI、桌面和电话都在运行，60 秒内没有应用崩溃。
- 空闲内存：重启后约 3.8 GB（Free RAM）。

## 踩坑与经验（重要）
1. **`adb shell` 放在 `while read` 循环里会吃掉 stdin**，导致清单只处理第一行。解决：用 `adb shell -n`，或者加 `</dev/null`。
2. **EMUI 开机时会复原部分状态**：
   - `pm disable-user` 的状态在重启后全部被清除，而且报告成功却不生效，所以改用 `pm uninstall -k --user 0`。
   - `/preas` 里的 12 个第三方应用和 `com.huawei.tips` 每次开机都会被重装；`pm suspend`、`pm hide` 对 shell 都不可用。所以每次开机后要运行 `post-boot.sh`。
   - `deviceidle disable` 重启后失效，也由 `post-boot.sh` 重新执行。
3. **可删除预装（`/system/delapp`、`/data/hw_init` 等）被 `uninstall --user 0` 后会整个消失**（`pm list packages -u` 里也查不到），`install-existing` 无法恢复，只能 `pm install -r --user 0 <原 APK 路径>`。路径见备份里的 `packages-all.txt`。
4. **误判“无限重启”**：大量改动后 dex2oat 负载很高，ADB USB 连接每隔几秒断开一次，被误判成无限重启，于是回滚了批次 02/03。实际上 `uptime` 一直在增长，`sys.boot.reason=reboot,adb`。判断是否重启要看 uptime 和 boot reason，不要看 adb 是否断开。
5. `ohos.distributedschedule.foundation` 提供 HarmonyOS core SA。移除后出现 `failed to attach Application, the coreSa are not ready yet` 崩溃（联系人、时钟），因此列入保留。同时保留 `com.huawei.hwid` 和 `featureframework`。
6. 无法移除：`com.google.android.gms`（设备管理器）；`parentcontrol`、`hwouc`、`hwstartupguide`（受保护，`DELETE_FAILED_INTERNAL_ERROR`）。
7. 华为内核的 load average 常驻 40+，是统计口径问题，CPU 实际空闲。

## 回滚
- 一般包：`scripts/debloat/apply.sh configs/packages/debloat-0X-*.txt restore`
- 整个消失的可删除预装：`adb shell pm install -r --user 0 <备份中的 APK 路径>`
- 省电：`scripts/deploy/power-no-optimize.sh restore`
