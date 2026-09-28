// Windler 身体适配器：荣耀9（Android 9 / EMUI 9.1，Termux + Termux:API，无 root）。
// 只依赖 Project.Windler 的适配器类型定义（构建时擦除），与核心实现完全解耦。
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { BodyAdapter, AdapterTool, RawSample } from "../../../Project.Windler/runtime/src/body/adapter.ts";
import { run, json } from "./termux.ts";

const MEDIA = path.join(process.env.WINDLER_HOME ?? path.join(os.homedir(), "windler"), "data", "media");
const CONSOLE_ACTIVITY = process.env.WINDLER_CONSOLE_ACTIVITY ?? "xyz.windler.console/.MainActivity";
let sensors: { light?: string; accel?: string } = {};

async function readSensor(name?: string): Promise<number[] | undefined> {
  if (!name) return undefined;
  const j = await json<Record<string, { values: number[] }>>("termux-sensor", ["-s", name, "-n", "1"], 10_000);
  await run("termux-sensor", ["-c"], 5_000);
  return j ? Object.values(j)[0]?.values : undefined;
}

const obj = (props: Record<string, unknown>, required: string[] = []) => ({ type: "object", properties: props, required });
const stamp = () => new Date().toISOString().replace(/[:.]/g, "-");

const tools: AdapterTool[] = [
  {
    name: "speak", permission: "device", description: "用手机扬声器把一段话说出来（中文 TTS）。",
    parameters: obj({ text: { type: "string" } }, ["text"]),
    handler: async (a) => ((await run("termux-tts-speak", ["-l", "zh", a.text], 120_000)).code === 0 ? "说完了" : "TTS 失败"),
  },
  {
    name: "take_photo", permission: "camera", description: "用手机相机拍一张照片（camera 0 后置，1 前置），返回文件路径。",
    parameters: obj({ camera: { type: "number", enum: [0, 1] } }),
    handler: async (a) => {
      fs.mkdirSync(MEDIA, { recursive: true });
      const f = path.join(MEDIA, `photo-${stamp()}.jpg`);
      const r = await run("termux-camera-photo", ["-c", String(a.camera ?? 0), f], 30_000);
      return r.code === 0 && fs.existsSync(f) ? `已拍摄：${f}（${Math.round(fs.statSync(f).size / 1024)} KB）` : "拍照失败";
    },
  },
  {
    name: "record_audio", permission: "microphone", description: "用麦克风录一段声音（秒），返回文件路径。",
    parameters: obj({ seconds: { type: "number" } }, ["seconds"]),
    handler: async (a) => {
      fs.mkdirSync(MEDIA, { recursive: true });
      const f = path.join(MEDIA, `audio-${stamp()}.m4a`);
      const s = Math.max(1, Math.min(120, Number(a.seconds) || 5));
      await run("termux-microphone-record", ["-f", f, "-l", String(s)], 10_000);
      await new Promise((r) => setTimeout(r, (s + 1) * 1000));
      await run("termux-microphone-record", ["-q"], 5_000);
      return fs.existsSync(f) ? `已录制 ${s} 秒：${f}` : "录音失败";
    },
  },
  {
    name: "location", permission: "location", description: "获取手机的大致位置（网络定位）。",
    parameters: obj({}),
    handler: async () => {
      const j = await json("termux-location", ["-p", "network", "-r", "once"], 60_000);
      return j ? `纬度 ${j.latitude?.toFixed(3)}，经度 ${j.longitude?.toFixed(3)}，精度约 ${Math.round(j.accuracy ?? 0)} 米` : "定位失败";
    },
  },
  {
    name: "vibrate", permission: "device", description: "让手机振动（毫秒）。",
    parameters: obj({ ms: { type: "number" } }),
    handler: async (a) => ((await run("termux-vibrate", ["-d", String(Math.min(3000, Number(a.ms) || 500)), "-f"])).code === 0 ? "振动了" : "失败"),
  },
  {
    name: "torch", permission: "device", description: "打开或关闭手电筒。",
    parameters: obj({ on: { type: "boolean" } }, ["on"]),
    handler: async (a) => ((await run("termux-torch", [a.on ? "on" : "off"])).code === 0 ? (a.on ? "手电筒开了" : "手电筒关了") : "失败"),
  },
  {
    name: "clipboard", permission: "device", description: "读取（不给 text）或写入手机剪贴板。",
    parameters: obj({ text: { type: "string" } }),
    handler: async (a) => a.text != null ? ((await run("termux-clipboard-set", [a.text])).code === 0 ? "已写入剪贴板" : "失败") : (await run("termux-clipboard-get")).out || "（剪贴板为空）",
  },
  {
    name: "read_sensor", permission: "device", description: "读取一个传感器的当前数值；不给 name 时列出所有传感器。",
    parameters: obj({ name: { type: "string" } }),
    handler: async (a) => {
      if (!a.name) return ((await json("termux-sensor", ["-l"]))?.sensors ?? []).join("\n");
      const v = await readSensor(a.name);
      return v ? `${a.name}: ${v.join(", ")}` : "读取失败";
    },
  },
];

const adapter: BodyAdapter = {
  name: "honor9",
  describe: "一台 2017 年的荣耀9 手机（麒麟 960、6 GB 内存、Android 9），通常插着电放在桌上；有相机、麦克风、扬声器、光线与运动传感器",
  async init() {
    const list: string[] = (await json("termux-sensor", ["-l"]))?.sensors ?? [];
    sensors = { light: list.find((s) => /light/i.test(s)), accel: list.find((s) => /accel/i.test(s)) };
  },
  async sample(): Promise<RawSample> {
    const bat = await json("termux-battery-status");
    const lux = await readSensor(sensors.light);
    const acc = await readSensor(sensors.accel);
    return {
      battery: bat ? { level: bat.percentage, charging: bat.status === "CHARGING" || bat.status === "FULL", tempC: bat.temperature, health: bat.health } : undefined,
      lux: lux ? Math.round(lux[0]) : undefined,
      motion: acc ? Math.round(Math.abs(Math.hypot(...acc) - 9.81) * 100) / 100 : undefined,
      extra: bat ? { 充电方式: bat.plugged, 电池健康: bat.health } : undefined,
    };
  },
  async notify(title, text) {
    await run("termux-notification", ["--id", "windler-say", "--title", title, "--content", text, "--priority", "high",
      "--button1", "打开控制台", "--button1-action", `am start -n ${CONSOLE_ACTIVITY}`]);
  },
  async speak(text) { await run("termux-tts-speak", ["-l", "zh", text], 120_000); },
  tools,
  // hands：看屏幕与操作其他应用——预留，尚未实现（需要无障碍服务或 shell 身份）
};

export default adapter;
