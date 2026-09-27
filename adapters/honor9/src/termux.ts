// 调用 Termux:API 命令行工具，带超时。
import { execFile } from "node:child_process";

export function run(cmd: string, args: string[] = [], timeoutMs = 20_000): Promise<{ code: number; out: string }> {
  return new Promise((resolve) => execFile(cmd, args, { timeout: timeoutMs, maxBuffer: 8 << 20 }, (e: any, out) =>
    resolve({ code: e ? (typeof e.code === "number" ? e.code : 1) : 0, out: String(out) })));
}

export async function json<T = any>(cmd: string, args: string[] = [], timeoutMs = 15_000): Promise<T | undefined> {
  const r = await run(cmd, args, timeoutMs);
  if (r.code !== 0) return undefined;
  try { return JSON.parse(r.out); } catch { return undefined; }
}
