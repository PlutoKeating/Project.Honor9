// 在手机上直接调用 Quetzal 网关（运维用，不需要控制台）。放到 Termux 家目录后：
//   node quetzal-rpc.mjs <方法> ['<参数 JSON>']      例：node quetzal-rpc.mjs hearing / node quetzal-rpc.mjs setHearing '{"enabled":true}'
//   node quetzal-rpc.mjs --watch <事件名> [秒数]     例：node quetzal-rpc.mjs --watch hearing 60（打印推送事件，默认 60 秒）
// 从主机：. scripts/deploy/lib.sh && dscp tools/quetzal-rpc.mjs localhost:quetzal-rpc.mjs && dssh "node quetzal-rpc.mjs status"
// Node 22+ 自带 WebSocket；令牌读自 ~/quetzal/secrets/gateway.token，只在手机本机有效。方法与事件见 Project.Quetzal/docs/API.md。
import fs from "node:fs";
const token = fs.readFileSync(process.env.HOME + "/quetzal/secrets/gateway.token", "utf8").trim();
const ws = new WebSocket(`ws://127.0.0.1:7788/rpc?token=${encodeURIComponent(token)}`);
const [method, params, extra] = process.argv.slice(2);
if (method === "--watch") {
  const secs = Number(extra) || 60;
  ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.event === params) console.log(new Date().toISOString().slice(11, 19), JSON.stringify(m.data)); };
  setTimeout(() => process.exit(0), secs * 1000);
} else {
  ws.onopen = () => ws.send(JSON.stringify({ id: 1, method, params: params ? JSON.parse(params) : {} }));
  ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id === 1) { console.log(JSON.stringify(m.result ?? m.error, null, 1)); process.exit(0); } };
  setTimeout(() => process.exit(2), 180000);
}
