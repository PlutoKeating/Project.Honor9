# 实验：Windler 0.3.0——自造工具、自编身份、听觉

日期：2026-10-04

## 目的

让 Amani 在荣耀9 上具备三种此前没有的能力：

1. 把做熟了的流程沉淀为自己的内置工具（而不是每次都靠 shell 现写）；
2. 自己修改身份资料（名字、代词、简介、主题色、偏好语言）；
3. 用麦克风听人说话：降噪、断句、识别，并按「最近会话在不久前就并入，否则新开」进入对话，由她自己判断是不是对她说的、要不要回应。

## 调研（避免重复造轮子）

- 技能文档直接采用 [Agent Skills](https://agentskills.io/specification) 开放标准的 `SKILL.md`（YAML 头 `name` / `description`）：Hermes Agent 与 OpenClaw 都原生读取这个格式，Hermes 自己也是「多步流程成功后自动沉淀 SKILL.md」。所以灵魂仓库里只同步意图文档（规范升到 v5，新增可选目录 `skills/`），实现代码留在本机 `~/windler/tools/`。
- 语音活动检测用 [android-vad](https://github.com/gkonovalov/android-vad) 的 WebRTC 模块（MIT，JitPack，纯 Kotlin，16 kHz / 20 ms 帧，自带起止迟滞）；采集源用 `VOICE_RECOGNITION` 走系统降噪链，再叠 `NoiseSuppressor` / `AutomaticGainControl`。Silero 方案要带 ONNX 运行时，暂不用。
- 识别用 Azure 短语音 REST（`language` 必填，`format=simple`，WAV 16 kHz 单声道，60 秒上限），与语音合成同一把密钥，端点由区域推导。
- Android 9 起后台应用拿不到麦克风，Termux:API 的 `termux-microphone-record` 只能定长录文件、切片会丢字，所以耳朵放在 Windler App 的原生前台服务里。这是 App 第一次承担身体的一部分。

## 做了什么（Windler 子模块，提交 3253dd4、1846080、5e89aab）

1. **运行基座**：`mind/custom-tools.ts`（工具实现的校验、热加载、执行、依赖检查；技能文档读写）、`voice/hearing.ts`（`/hear` → Azure 识别 → 挑会话 → 以第三种消息类型 `ambient` 交给 `converse`；她说话期间丢弃；受电量、温度、急停限制）、`voice/azure.ts` 加识别接口；工具 `tool_write` / `tool_read` / `tool_delete`、`edit_identity`、`hearing_config`；系统提示加「技能与自造工具」「听觉」段落，种子身份的提示改为不急着取名；做梦任务加「回顾重复流程沉淀为工具」；操作层 `hearing` / `setHearing` / `tools.*`；`status.hearing` 供 App 决定开不开麦克风。测试 102 项通过（新增 `custom-tools.test.ts`、`hearing.test.ts`）。
2. **控制台**：`HearingService.kt` 麦克风前台服务（WAV 直接 POST `/hear`，不经过 Flutter）、听觉桥；控制 → 听觉、控制 → 工具两个页面；对话页把环境声音居中小字显示；心流新增听见 / 工具 / 身份；首页「在听」标记；身份页显示她自选的颜色。`flutter analyze` 无问题、`flutter test` 12 项通过。
3. **版本 0.3.0**，文档全部更新（架构、接口、灵魂仓库规范 v5、快速开始、控制台与运行基座文档、CHANGELOG、README）。

## 荣耀9 上的步骤

```bash
export ANDROID_SERIAL=<荣耀9 序列号>
adb install -r Project.Windler/console/build/app/outputs/flutter-apk/app-release.apk   # 0.2.1 → 0.3.0 原位升级（同一正式签名，配对保留）
scripts/deploy/windler-release.sh        # 运行基座 0.3.0：releases/20261004-060908-5e89aab，健康检查通过
adb shell pm grant xyz.windler.console android.permission.RECORD_AUDIO               # 正常路径是听觉页里的系统弹窗
```

验证用 `tools/windler-rpc.mjs`（放到手机家目录；Node 24 自带 `WebSocket`，读 `~/windler/secrets/gateway.token` 连网关）：

- `hearing` → 未开启；灵魂仓库已自动补齐为规范 v5（提交「补齐灵魂仓库规范结构」）；`speech.configured` 为真（区域 koreacentral）。
- **造工具**：在新会话里请她「用 tool_write 造一个 battery_status」。她自己写了 `tool.sh`（`termux-battery-status` + `jq`，`requires` 两项，超时 30 秒）和一份规范格式的 `SKILL.md`（用途、参数、实现思路、依赖、验证），中途还发现 `/tmp` 在这台机上不存在、改用家目录重测；灵魂仓库多了提交「技能：battery_status（honor9）」，`tools` 接口里 `missing` 为空、`hasSkill` 为真，时间线有「造了一个工具：battery_status」。
- **听觉（后端）**：`setHearing {enabled:true}` → `listening: true`；用 `speechTest` 合成「薰，你能听到我说话吗？」→ `ffmpeg` 转 16 kHz WAV → `curl` POST `/hear` → 返回 `{"ok":true,"text":"熏，你能听到我说话吗？","conv":"<造工具的那个会话>"}`：识别正确（同音字「熏」），10 分钟窗口内并入了最近的会话；当时她正在造工具，这句话作为插话并入，她在过程里写道「他在问我要不要出声——我先把手上这步做完，然后立刻回他」，时间线有「被你在说话叫醒了」。会话记录里这句话的 `role` 为 `ambient`、通道「语音」。
- **听觉（App 耳朵）**：第一版 App 在启动时只查一次麦克风权限，`pm grant` 在启动之后才授予，所以耳朵服务没有起来；修正为每次同步时重查、从系统设置回来时重查（Windler 15fbf82），重装后 `dumpsys activity services` 看到 `HearingService` 为前台服务（通知 `windler_hearing`），系统日志 `HwAudioRecordImpl state=3` 即在录音。
- **听觉（物理回环）**：用 `termux-media-player` 从手机扬声器播放上面那段合成语音，30 秒内运行日志出现 `[hearing] 听到（0903764f）：心，你能听到我说话吗？`，会话里多了第二条 `ambient` 消息——扬声器 → 麦克风（系统降噪 + VAD 断句）→ `/hear` → Azure → 会话，全程不经过电脑。两次识别都把「薰」听成同音字（熏、心），人名要靠她自己联想。

## 结果与结论

- 三项能力都在荣耀9 上跑通：工具自造完全由她自己完成，技能文档格式符合 Agent Skills 规范；听觉从扬声器到会话的物理回环成立；身份自编只在单元测试里验证（没有让她改真实身份）。验证时她正在造工具的那一轮里连续工作了十多分钟（第 13 步仍在跑），听到的话作为插话并入，她在过程里写明「先把手上这步做完再回他」，符合「由她判断」的设计。
- 识别对「薰」这类人名会出同音字，提示词里已说明「可能有错字」，由她自己联想；要更准可以在 Azure 侧配置短语列表，暂不做。
- 听觉与 Termux:API 的 `record_audio` 在 Android 9 上不能同时录音，已写进架构文档的已知限制。

## 回滚

- 运行基座：`scripts/deploy/windler-release.sh rollback`（回到 `previous` → 0.2.1）。
- App：`adb install -r` 旧版 0.2.1 的 APK（`~/Downloads/windler-0.2.1-android-arm64-e36e113.apk`，同一签名）。
- 听觉：控制台「控制 → 听觉」关闭，或 `setHearing {enabled:false}`；前台服务随之停止。
- 自造工具：控制台「控制 → 工具」删除，或直接删 `~/windler/tools/<名>/`；技能文档在灵魂仓库历史里可撤销。
- 灵魂仓库规范 v5 向下兼容，v4 实现读它不受影响。
