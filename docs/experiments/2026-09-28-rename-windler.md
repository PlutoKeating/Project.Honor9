# 实验：运行基座由 Amani 更名为 Windler

日期：2026-09-28

## 目的

运行基座原名 Amani，与智能体 Amani（神谷薰）同名，违背「基座不与具体 agent 名字耦合」的原则。这次把基座完整更名为 **Windler**。智能体的身份不变：Amani / 神谷薰，标识符 `amani`。灵魂仓库 `amani.soul` 没有任何改动。

## 步骤

1. **GitHub**：
   - 原有的私有仓库 `Project.Windler` 改名为 `Archieved.Project.Windler`。
   - 然后把 `Project.Amani` 改名为 `Project.Windler`（旧地址由 GitHub 自动重定向）。
2. **基座仓库**（Project.Windler `b487cfb`、`d869cb5`）：
   - 文档、技能和代码里的名称全部改为 Windler，技术标识符也一并改掉：
     - 环境变量 `WINDLER_HOME` / `WINDLER_ADAPTER`，默认目录 `~/windler`
     - `windler.json`、`windler.db`、`windler-core`
     - 应用 ID `xyz.windler.console`，应用名「Windler」
     - 点火通道与 runit 服务 `windler`
   - 对话和审计里代表 agent 的标记 `amani` 改为通用的 `agent`。
   - 兼容旧版本：
     - 旧的 `amani.json` 优先合并进新配置，然后删除；
     - 旧的 `amani.db` 改名沿用；
     - 旧记录里的标记统一改为 `agent`。
   - 新增更名测试，测试共 35 个，全部通过。
3. **本仓库**：
   - 子模块的名称、路径、地址，以及 `.git/modules` 下的目录，都改为 `Project.Windler`。
   - 部署脚本改名：`windler-release.sh`、`windler-run`、`windler-log-run`、`boot-windler`。
   - 适配器环境变量改为 `WINDLER_*`，主机 ssh 密钥改名为 `~/.ssh/windler_honor9`。
   - 新增 `migrate-to-windler.sh`。
4. **设备**：先执行 `migrate-to-windler.sh`，再执行 `windler-release.sh`。

## 遇到的问题

- **配置被新文件遮挡**：发布脚本在基座启动前预先写入了只含身体名与时区的 `windler.json`。第一版兼容逻辑「新文件不存在才沿用旧文件」因此跳过了旧的 `amani.json`，灵魂同步地址等配置暂时没有生效。
  - 修复：旧配置优先合并，并补了测试。修复后灵魂同步地址恢复。
- **旧进程重建了空的 `~/amani`**：旧进程退出时重新写出了一个空的 `~/amani`（空数据库、默认配置、无密钥）。
  - 确认为空后删除。
  - 迁移脚本改为先确认旧进程已退出，再判断这个目录是否为空，为空才删除。
- **迁移脚本杀掉了自己**：`pkill -f "amani/current"` 匹配到了迁移脚本自身的 ssh 命令行，导致退出码 255。
  - 改用 `[a]mani` 写法。之后迁移脚本可以安全地重复执行。

## 结果

| 验证项 | 结果 |
|---|---|
| 设备目录 | `~/windler` 保留全部数据：灵魂、密钥、令牌、6 条对话、18 条时间线、63 条审计；`~/amani`、旧服务、旧开机脚本已移除 |
| 服务 | runit 服务 `windler` 运行中，健康检查通过，发布版本 `20260928-093956-d869cb5` |
| 数据迁移 | 对话角色为 `user` / `agent`，审计者为 `agent` / `控制台` |
| 配置 | 灵魂同步地址等原配置已合并进 `windler.json` |
| 端到端 | 经网关对话：她调用 shell 并回复，约 15 秒完成 |
| 灵魂同步 | 身份仍为 神谷薰；推送到 `amani.soul` 成功，无错误 |
| 控制台 | 旧的 `xyz.amani.console` 已卸载，新的「Windler」`xyz.windler.console` 已安装，RUN_COMMAND 已授予并放行后台 |

## 需要人工操作

- 解锁手机，打开「Windler」控制台，重新配对一次。新应用没有旧的连接档案。

## 回滚

- 设备：
  1. `sv down $PREFIX/var/service/windler`
  2. `mv ~/windler ~/amani`
  3. 用 git 取回旧的服务脚本，再执行旧版发布脚本。
- 数据：旧版运行时会读取 `config/amani.json`、`data/amani.db`，需要把这两个文件改回旧名。
- GitHub：按相反顺序改回两个仓库的名字。

## 后续：彻底废弃旧名称（同日）

按要求，旧链接直接废弃，也不保留旧名称的兼容：

- **GitHub 跳转**：GitHub 改名后会自动保留旧地址的跳转，平台没有关闭它的开关。唯一的办法是在旧名字上重新建一个仓库。做法是先建一个空的私有仓库 `Project.Amani` 占住旧名字，再删掉它。验证结果：网页 404，API 404，`git clone` 失败，不再跳转。`Project.Windler` 与 `amani.soul` 不受影响。
- **基座**（Project.Windler `a299918`）：
  - 删除读取 `amani.json` / `amani.db` 和转换旧标记的兼容代码，以及对应的测试和升级说明。
  - 基座仓库里已经不再出现旧名称。
  - 测试 33/33 通过。
- **本仓库**：删除一次性的 `migrate-to-windler.sh`，设备档案里也不再写旧名称。本文上面的记录保留历史原貌。
- **设备**：
  - 发布 `20260928-094801-a299918`；
  - 删除更名前构建的旧版本，现存版本全部是 Windler 构建；
  - 全盘检查，除灵魂仓库外没有任何带旧名称的文件或目录。
- **影响**：其他机器上若有通过旧地址 `Project.Amani` 克隆的 soul-bridge，旧地址已失效，需要把 remote 改为 `Project.Windler`。

回滚部分中「改回旧名」的内容作废：旧版运行时已无法对接。
