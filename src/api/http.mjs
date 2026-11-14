import { redact } from "./sanitize.mjs";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export class UpstreamError extends Error {
  constructor(message, status = null) {
    super(message);
    this.name = "UpstreamError";
    this.status = status;
  }
}

/**
 * GET con timeout y reintentos (429 y 5xx con espera exponencial).
 * Los mensajes de error nunca incluyen claves.
 */
export async function request(url, { as = "json", timeoutMs = 30000, retries = 2 } = {}) {
  let last;
  for (let i = 0; i <= retries; i++) {
    try {
      const res = await fetch(url, {
        signal: AbortSignal.timeout(timeoutMs),
        headers: { "User-Agent": "nasa-space-apps-2026-outpost/0.1 (educational prototype)" },
      });
      if (res.status === 429 || res.status >= 500) throw new UpstreamError(`HTTP ${res.status}`, res.status);
      if (!res.ok) {
        const e = new UpstreamError(`HTTP ${res.status}`, res.status);
        e.fatal = true;
        throw e;
      }
      return as === "json" ? await res.json() : await res.text();
    } catch (e) {
      last = e;
      if (e.fatal || i === retries) break;
      await sleep(1000 * 2 ** i);
    }
  }
  throw new UpstreamError(`${redact(url)} -> ${redact(last?.message)}`, last?.status ?? null);
}
