// 在手机上直接调用 Windler 网关（运维用，不需要控制台）。放到 Termux 家目录后：
//   node windler-rpc.mjs <方法> ['<参数 JSON>']      例：node windler-rpc.mjs hearing / node windler-rpc.mjs setHearing '{"enabled":true}'
// 从主机：. scripts/deploy/lib.sh && dscp tools/windler-rpc.mjs localhost:windler-rpc.mjs && dssh "node windler-rpc.mjs status"
// Node 22+ 自带 WebSocket；令牌读自 ~/windler/secrets/gateway.token，只在手机本机有效。方法见 Project.Windler/docs/API.md。
import fs from "node:fs";
const token = fs.readFileSync(process.env.HOME + "/windler/secrets/gateway.token", "utf8").trim();
const ws = new WebSocket(`ws://127.0.0.1:7788/rpc?token=${encodeURIComponent(token)}`);
const [method, params] = process.argv.slice(2);
ws.onopen = () => ws.send(JSON.stringify({ id: 1, method, params: params ? JSON.parse(params) : {} }));
ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id === 1) { console.log(JSON.stringify(m.result ?? m.error, null, 1)); process.exit(0); } };
setTimeout(() => process.exit(2), 180000);
