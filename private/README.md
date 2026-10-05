# private/

本目录用来保存本机特有的敏感信息，例如序列号、各类 ID、MAC 地址、IP、账号等，**除本说明文件外全部不入库**。
提交到仓库的文档中只能用 `<SERIAL>` 这类占位符指代。

- `release-signing-ed25519.pem` / `.pub`：Quetzal 发版签名密钥（2026-10-06 生成）。私钥同时存在 GitHub 仓库 Secret `RELEASE_SIGNING_KEY`；公钥写死在安装脚本、App 与灵魂桥里。丢了私钥就要换钥并发新版本更新所有内置公钥。
