# adapters/honor9 · 荣耀9 身体适配器

实现 [Project.Windler](../../Project.Windler) 的 `BodyAdapter` 接口，让 Amani 通过 Termux:API 感知和使用这台荣耀9：电量与体温、光线、运动、系统通知、语音、相机、麦克风、定位、振动、手电筒、剪贴板、传感器。

- 只 `import type` 子模块中的接口类型，构建时擦除，与核心实现完全解耦。
- 构建：`npm ci && npm run build` → `dist/honor9.mjs`，由 `scripts/deploy/windler-release.sh` 发布到手机。
- 字段与工具清单见 [docs/API.md](../../docs/API.md)。
- `hands`（看屏幕、操作其他应用）尚未实现，接口已预留。
