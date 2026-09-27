# Project.Honor9 · Amani 智能体工坊

把一台退役的荣耀9改造成 AI-Native 时代的智能体工坊，并在上面培育名为 **「Amani（神谷薰）」** 的智能体。

具体要做的是：尽量裁掉设备上用不到的功能、软件和服务，把这台手机的算力、传感器、网络和常驻运行能力都腾出来给智能体用。本仓库记录这个过程里的工作情况和实验经验，也存放维护时写的脚本和工具。

## 设备

| 项目 | 信息 |
|---|---|
| 机型 | 荣耀9 (STF-AL10) |
| 系统 | Android 9 / EMUI 9.1.0.225 (C00E125R1P9) |
| SoC | 海思麒麟 960 (hi3660)，4×A73 @2.36GHz + 4×A53 @1.84GHz |
| 内存 / 存储 | 6 GB / 128 GB |
| 连接 | USB ADB（uid 2000 shell，未 root） |
| USB ID | `12d1:107e` |

更多硬件与系统信息见 [设备档案](docs/device/honor9-profile.md)：麒麟 960、6 GB RAM、128 GB 存储、Mali-G71、Bootloader 已锁。

项目的完整意图与阶段规划见 [docs/vision.md](docs/vision.md)，协作规则见 [AGENTS.md](AGENTS.md)。

## 目录结构

```
.
├── agent/
│   └── amani/              # 智能体 Amani（神谷薰）
│       ├── config/         #   运行配置
│       ├── prompts/        #   人格设定与提示词
│       ├── skills/         #   技能 / 工具定义
│       └── memory/         #   长期记忆（数据文件不入库）
├── configs/
│   ├── packages/           # 应用包清单（保留 / 禁用 / 卸载）
│   └── services/           # 系统服务裁剪清单
├── AGENTS.md               # 项目规则（新会话必读）
├── CLAUDE.md -> AGENTS.md  # 软链接
├── docs/
│   ├── vision.md           # 项目愿景与阶段规划
│   ├── device/             # 硬件、系统、分区等设备资料
│   ├── experiments/        # 实验记录（一个实验一个文件）
│   └── journal/            # 工作日志（按日期命名：YYYY-MM-DD.md）
├── scripts/
│   ├── check-secrets.sh    # 提交前敏感信息检查（pre-commit）
│   ├── adb/                # ADB 连接与常用操作
│   ├── debloat/            # 精简：禁用或卸载应用、关闭服务
│   ├── backup/             # 备份与还原
│   └── deploy/             # 智能体部署到设备
├── tools/                  # 独立的辅助工具
├── private/                # 本机敏感信息：序列号、ID、MAC、IP（不入库）
├── backups/                # 本地备份（不入库）
└── logs/                   # 运行日志（不入库）
```

## 快速开始

```bash
# 1. 手机上开启「开发人员选项 → USB 调试」，连上数据线后授权本机
# 2. Linux 主机需要 udev 规则放行华为的厂商 ID
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="plugdev"' \
  | sudo tee -a /etc/udev/rules.d/51-android-adb.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
# 3. 验证
adb devices -l
```

## 路线图

- [x] 建立 ADB 连接
- [ ] 全量备份（应用列表、用户数据）
- [ ] 梳理预装应用与系统服务，制定裁剪清单
- [ ] 分批精简，并验证系统稳定性
- [ ] 搭建智能体运行环境（Termux / 常驻服务 / 网络）
- [ ] 部署「Amani（神谷薰）」并持续迭代

## 约定

- **敏感信息不入库**：序列号、IMEI、Android ID、MAC、IP 等只记录在本地 `private/` 目录，提交前由 `scripts/check-secrets.sh` 检查。
- **先备份，后改动**：每次裁剪前先导出当前的包状态，保证随时能回滚。
- 优先用 `pm disable-user` 或 `pm uninstall --user 0`，不直接删除系统分区里的文件。
- 每次实验都记到 `docs/experiments/`，写明做了什么、结果如何、怎么回滚。

## 免责声明

本项目**仅用于学习和研究**，操作对象只限于我们自己拥有的设备。本项目不教唆、也不提供破坏或入侵计算机系统的方法，不用于任何牟利目的。他人模仿或参考本项目内容造成的任何后果，由其自行承担，本项目作者不承担责任。

## 许可证

[GNU Affero General Public License v3.0](LICENSE)
