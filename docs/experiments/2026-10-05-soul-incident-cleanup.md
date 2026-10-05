# 实验：灵魂仓库误推事故的彻底清理与根因修复

日期：2026-10-05

## 目的

当天发现：本机正式安装（0.6.7）上的 Amani 推送失败后，自己用 shell 在灵魂目录里跑 git（把 `origin` 改成 Project.Quetzal 的公开地址、`pull --rebase`、`reset --hard origin/main`），醒来结束时基座照常推送，一个灵魂提交（`cc71da0`）进了公开的 Quetzal 仓库；改回地址后，基座又把 Quetzal 的代码历史合并进了私有灵魂仓库，两具身体（本机、荣耀9）都拉到了被污染的历史。所有者的决定：

1. 把 `cc71da0` 从公开仓库抹掉；
2. 彻底清理灵魂仓库，找到根因并从源头修复，保证灵魂仓库与 Quetzal 源代码完全解耦（灵魂仓库应当由每个用户自己创建）；
3. 恢复 reset 时丢掉的本地提交；
4. 加上防护（含系统提示里的红线，让 agent 自主行为也不会再这样做）；
5. 纳入 1.0.0，打标签发布，本机与荣耀9 都装正式发布版。

## 步骤

1. **备份**（`backups/soul-incident-<时间>/`，不入库）：灵魂仓库的完整 bundle，两具身体灵魂目录的 tgz。
2. **公开仓库**：在本地把 `cc71da0` 从 Quetzal 的 main 上去掉，经所有者二次确认后强制推送（`d81c267...fdd111f`）。本地留了一个备份分支。
3. **灵魂仓库**：用 graft 切断合并提交里 Quetzal 那一侧的父提交，`filter-branch` 删掉 Quetzal 的路径，核对删掉的 395 个文件全部来自 Quetzal，历史里只剩两个灵魂根提交。把 reflog 里找回的两个提交（硬件与能力清单）摘回来，`MEMORY.md` 的冲突按条目合并。经所有者确认后强制推送（`4bf2777...1a2e060`）。
4. **两具身体**：先停服务（本机 `systemctl --user stop quetzal`，荣耀9 `sv down`），旧灵魂目录改名为 `soul.contaminated-<时间>` 保留，再重新克隆。
5. **根因修复**（子模块 `9c0f2e8`，灵魂仓库规范升 v9）：
   - 每个克隆记下灵魂仓库的根提交（`.git/quetzal-soul-roots.json`），之后出现陌生根提交就停止同步（不合并、不推送）并提醒；
   - agent 的 `shell` 工具拦下所有针对灵魂目录的 git 命令；
   - 主 agent 与子 agent 的系统提示新增「红线」：不在灵魂目录里运行 git；灵魂仓库与任何代码仓库（包括 Quetzal 源代码）无关；同步出错不要自己修；不可逆或对外的操作先问人；
   - git 设置 `GIT_CEILING_DIRECTORIES`，灵魂目录的 `.git` 丢失时不会退到上层目录里的别的仓库；
   - 规范 §1 写明灵魂仓库由部署者自己新建、不得与代码仓库共用；灵魂桥的安装技能写明同样的红线。
   - 前一个提交已有的两道防线：推送前把 `origin` 校正为配置的地址；远端没有 `agent.json` 却有规范以外的内容时拒绝合并。
6. **发布与安装**：打 `v1.0.0` 标签，发版工作流全部成功（APK、Linux 控制台、npm 包）。本机用官方安装命令 `curl -fsSL https://quetzal.plutokeating.beer/install | bash -s -- --version 1.0.0 --no-open` 从 0.6.7 升级。荣耀9：`adb install -r` 发布的 APK（SHA256 与 Release 一致）；手机锁着 PIN，没法点 App 里的安装向导，所以从这个 APK 里取出自带的 `main.cjs`、`termux.mjs` 等（与向导安装的是同一组字节，`sha256sum` 两端一致），按向导的约定放进 `~/quetzal/releases/1.0.0/`，切换 `current`，启动服务，40 秒健康检查。
7. **验证**：两边都从控制台接口触发一次「立即同步」。

## 结果

| 项 | 结果 |
|---|---|
| Quetzal 公开仓库 | main 上已没有 `醒来了一会儿` 这个提交。GitHub 可能还按 SHA 缓存这个对象，直到垃圾回收；要彻底清掉需要找 GitHub 支持 |
| 灵魂仓库远端 | 只有 `835085c`、`220cb09` 两个根提交；顶层只有规范里的条目和她自己的 `ops/`（她以前写的运维脚本，不是 Quetzal 源码） |
| 本机 | 运行基座 1.0.0，网状层组件就绪；同步成功，`lastError` 为空，没有待推送的改动；记下的根提交就是上面两个 |
| 荣耀9 | App 1.0.0，运行基座 1.0.0（`previous` 为 0.6.3），健康检查通过；同步成功，记下的根提交相同，与远端没有差异 |
| 测试 | runtime 158、bridge 15、sync 15、cli 6、console 17 项，全部通过 |

## 回滚

- 运行基座：荣耀9 运行 `ln -sfn ~/quetzal/releases/0.6.3 ~/quetzal/current && sv restart $PREFIX/var/service/quetzal`；本机重新运行安装命令，带 `--version 0.6.7`。
- 灵魂仓库：`backups/soul-incident-<时间>/` 里的 bundle 就是清理前的完整历史；两具身体的 `soul.contaminated-*` 目录也还在。确认不再需要后再删掉，同时删掉 Quetzal 本地的备份分支。
