#!/usr/bin/env node
/**
 * API local del proyecto. Sirve datos NASA/CSA YA SANEADOS al juego (mismo origen => sin problemas de CORS).
 *
 *   npm run api            # http://127.0.0.1:8787  (abre / para ver el catálogo de endpoints)
 *
 * Por defecto responde con los snapshots de data/curated/ (funciona sin red).
 * Con ?live=1 intenta la fuente real; si falla, devuelve el snapshot y lo indica en meta.fallbackReason.
 * Cada respuesta lleva meta.mode = "live" | "snapshot" y la cabecera X-Data-Mode: el juego debe mostrarlo.
 * La clave de NASA vive solo aquí (variable de entorno) y nunca llega al navegador.
 */
import http from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { getApod, getCsaResources, getMarsSurfaceWeather, getRoverPhotos, getSpaceWeatherLive } from "../src/api/sources.mjs";
import { CATALOG } from "../src/api/catalog.mjs";
import { redact } from "../src/api/sanitize.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const CURATED = path.join(ROOT, "data", "curated");

class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const isTrue = (v) => v === "1" || v === "true";
const cache = new Map();
async function cached(key, ttlMs, loader) {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.t < ttlMs) return hit.value;
  const value = await loader();
  cache.set(key, { t: Date.now(), value });
  return value;
}

async function readCurated(name) {
  try {
    return JSON.parse(await readFile(path.join(CURATED, name), "utf8"));
  } catch {
    throw new ApiError(503, "snapshot_missing", `Falta data/curated/${name}. Ejecuta: npm run ingest`);
  }
}

/** Intenta la fuente real (si se pidió); si falla, usa el snapshot y explica por qué. */
async function liveOrSnapshot({ live, key, ttl, loader, snapshot }) {
  let reason = null;
  if (live) {
    try {
      return await cached(key, ttl, loader);
    } catch (e) {
      reason = redact(e.message).slice(0, 200);
    }
  }
  const body = await readCurated(snapshot);
  return reason ? { ...body, meta: { ...body.meta, fallbackReason: reason } } : body;
}

const HOUR = 60 * 60_000;
const simple = (snapshot, loader, ttl = HOUR) => (q) => liveOrSnapshot({ live: isTrue(q.get("live")), key: snapshot, ttl, loader, snapshot });

// --- Endpoints (cada uno corresponde a una fuente de src/api/catalog.mjs) --------
const routes = {
  "/api/catalog": () => ({ sources: CATALOG }),
  "/api/health": async () => {
    const manifest = await readCurated("manifest.json").catch(() => null);
    return { ok: true, time: new Date().toISOString(), node: process.version, nasaKeyConfigured: Boolean(process.env.NASA_API_KEY), sources: manifest?.sources ?? null };
  },
  "/api/space-weather": (q) =>
    liveOrSnapshot({
      live: isTrue(q.get("live")),
      key: `sw:${q.get("days") ?? 7}`,
      ttl: 10 * 60_000,
      loader: () => getSpaceWeatherLive({ days: Number(q.get("days") ?? 7) }),
      snapshot: "space_weather.json",
    }),
  "/api/scenarios": async () => {
    const d = await readCurated("space_weather_scenarios.json");
    return { meta: d.meta, scenarios: d.scenarios.map((s) => ({ id: s.id, name: s.name, difficulty: s.difficulty, windowStart: s.windowStart, windowEnd: s.windowEnd, summary: s.summary })) };
  },
  "/api/radiation": () => readCurated("radiation.json"),
  "/api/mars-layers": () => readCurated("mars_layers.json"),
  "/api/mars-weather": simple("mars_weather.json", () => getMarsSurfaceWeather({})),
  "/api/rover-photos": simple("rover_photos.json", () => getRoverPhotos({})),
  "/api/apod": simple("apod.json", () => getApod({})),
  "/api/csa": simple("csa_resources.json", () => getCsaResources({})),
  "/api/osdr": async (q) => {
    const d = await readCurated("osdr_facts.json");
    const topic = q.get("topic");
    if (!topic) return { meta: d.meta, topics: d.topics.map((t) => ({ id: t.id, gameSystem: t.gameSystem, studies: t.studies.length })) };
    const t = d.topics.find((x) => x.id === topic);
    if (!t) throw new ApiError(404, "unknown_topic", `Temas: ${d.topics.map((x) => x.id).join(", ")}`);
    return { meta: d.meta, topic: t };
  },
  "/api/manifest": () => readCurated("manifest.json"),
};

async function handleApi(pathname, q) {
  if (routes[pathname]) return routes[pathname](q);
  const m = /^\/api\/scenarios\/([a-z0-9-]{1,40})$/.exec(pathname);
  if (m) {
    const d = await readCurated("space_weather_scenarios.json");
    const s = d.scenarios.find((x) => x.id === m[1]);
    if (!s) throw new ApiError(404, "unknown_scenario", `Escenarios: ${d.scenarios.map((x) => x.id).join(", ")}`);
    return { meta: d.meta, scenario: s };
  }
  throw new ApiError(404, "not_found", "Endpoint desconocido. Abre / para ver el catálogo.");
}

// --- Archivos estáticos (solo carpetas públicas) ------------------------------
const STATIC_PREFIXES = ["/src/", "/data/curated/", "/content/", "/public/"];
const MIME = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".mjs": "text/javascript; charset=utf-8", ".json": "application/json; charset=utf-8", ".css": "text/css; charset=utf-8", ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg", ".webp": "image/webp" };

async function serveStatic(pathname, res) {
  const decoded = decodeURIComponent(pathname);
  if (!STATIC_PREFIXES.some((p) => decoded.startsWith(p))) return false;
  const file = path.resolve(ROOT, "." + decoded);
  if (!file.startsWith(ROOT + path.sep)) throw new ApiError(400, "bad_path", "Ruta no permitida");
  try {
    const buf = await readFile(file);
    res.writeHead(200, { "Content-Type": MIME[path.extname(file)] ?? "application/octet-stream", "X-Content-Type-Options": "nosniff" });
    res.end(buf);
    return true;
  } catch {
    throw new ApiError(404, "not_found", "Archivo no encontrado");
  }
}

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
const indexHtml = () => `<!doctype html><meta charset="utf-8"><title>API local - Outpost</title>
<style>body{font:16px system-ui;max-width:820px;margin:2rem auto;padding:0 1rem}code{background:#eee;padding:2px 5px;border-radius:4px}li{margin:.5rem 0}small{color:#555}</style>
<h1>API local del juego</h1><p>Datos NASA/CSA saneados. Agrega <code>?live=1</code> para intentar la fuente real (con respaldo al snapshot). Lista completa en <a href="/api/catalog">/api/catalog</a>.</p>
<ul>${CATALOG.map((s) => `<li><strong>${esc(s.name)}</strong>${s.needsKey ? " (requiere clave NASA)" : ""}<br>${s.endpoints.map((e) => `<a href="${esc(e.replace(":id", "gannon-2024-05"))}"><code>${esc(e)}</code></a>`).join(" ")}<br><small>${esc(s.gameUse)}</small></li>`).join("")}</ul>
<p><a href="/api/health">/api/health</a> · <a href="/api/manifest">/api/manifest</a> · <a href="/public/index.html">página de prueba</a></p>`;

// --- Servidor ----------------------------------------------------------------
const hits = new Map();
function pruneExpiredHits(now) {
  for (const [k, v] of hits) {
    if (now > v.reset) hits.delete(k);
  }
}
function limited(ip) {
  const now = Date.now();
  const h = hits.get(ip);
  if (!h || now > h.reset) {
    if (h) hits.delete(ip);
    if (hits.size >= 256) pruneExpiredHits(now);
    hits.set(ip, { n: 1, reset: now + 60_000 });
    return false;
  }
  return ++h.n > 120; // 120 peticiones por minuto por IP: protege la clave de NASA
}

export function createApp() {
  return http.createServer(async (req, res) => {
    const base = { "Access-Control-Allow-Origin": "*", "X-Content-Type-Options": "nosniff" };
    try {
      if (req.method !== "GET" && req.method !== "HEAD") throw new ApiError(405, "method_not_allowed", "Solo GET");
      if (limited(req.socket.remoteAddress ?? "?")) throw new ApiError(429, "rate_limited", "Demasiadas peticiones; espera un minuto");
      const url = new URL(req.url, "http://localhost");
      if (url.pathname === "/") {
        res.writeHead(200, { ...base, "Content-Type": "text/html; charset=utf-8" });
        return res.end(indexHtml());
      }
      if (url.pathname.startsWith("/api/")) {
        const body = await handleApi(url.pathname.replace(/\/$/, ""), url.searchParams);
        res.writeHead(200, { ...base, "Content-Type": "application/json; charset=utf-8", "Cache-Control": "public, max-age=60", "X-Data-Mode": body?.meta?.mode ?? "n/a" });
        return res.end(JSON.stringify(body));
      }
      if (await serveStatic(url.pathname, res)) return;
      throw new ApiError(404, "not_found", "No encontrado");
    } catch (e) {
      const status = e instanceof ApiError ? e.status : 500;
      // Nunca se devuelven detalles internos ni URLs con claves.
      const message = e instanceof ApiError ? e.message : "Error interno";
      if (!(e instanceof ApiError)) console.error("[error]", redact(e?.stack ?? e));
      res.writeHead(status, { ...base, "Content-Type": "application/json; charset=utf-8" });
      res.end(JSON.stringify({ error: { code: e.code ?? "internal", message } }));
    }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT) || 8787;
  const host = process.env.HOST || "127.0.0.1";
  createApp().listen(port, host, () => console.log(`API local en http://${host}:${port}  (clave NASA: ${process.env.NASA_API_KEY ? "configurada" : "no, se usará DEMO_KEY"})`));
}
