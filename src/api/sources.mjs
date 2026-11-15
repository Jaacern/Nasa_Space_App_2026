/**
 * Adaptadores de fuentes NASA/CSA en modo "en vivo". Solo hay fuentes relevantes para el juego
 * (ver src/api/catalog.mjs: cada fuente declara para qué sirve en el juego).
 *
 * Patrón de cada adaptador (cópialo para añadir una fuente):
 *   1. Pedir a la API (src/api/http.mjs: timeout, reintentos, errores sin claves).
 *   2. Quedarse SOLO con los campos conocidos, saneados (src/api/sanitize.mjs).
 *   3. Comprobar el contrato con assertValid(). Si se rompe, lanza error y el servidor
 *      responde con el snapshot guardado en data/curated/.
 *   4. Devolver { meta, ...datos } con meta.mode = "live".
 *
 * Todos aceptan fetchJson / fetchText para poder probarse sin red (test/).
 */
import { request } from "./http.mjs";
import { assertValid, cleanText, isoDate, isoTime, num, redact, safeUrl } from "./sanitize.mjs";
import { normCME, normFLR, normGST, normSEP, normIPS, sanitizeEvent } from "./normalize.mjs";

const apiKey = () => globalThis.process?.env?.NASA_API_KEY || "DEMO_KEY";
const todayIso = () => new Date().toISOString().slice(0, 10);
const addDays = (iso, n) => new Date(Date.parse(iso + "T00:00:00Z") + n * 86400000).toISOString().slice(0, 10);
const liveMeta = (extra) => ({ mode: "live", retrievedAt: new Date().toISOString(), ...extra });
const NASA_API = "https://api.nasa.gov/";

// ---------------------------------------------------------------------------
// Fotos reales de Marte (Perseverance y Curiosity). Pestaña Resources: "Mars Rover Photos".
// OJO: la API api.nasa.gov/mars-photos ya no existe (responde 404 "No such app", verificado el 2026-11-14;
// su mantenedor dejó de sostenerla). Se usan los feeds oficiales de imágenes crudas de mars.nasa.gov,
// que son la fuente original, no requieren clave y tienen fotos de ayer.
// Uso: galería del sitio marciano y ambientación.
// ---------------------------------------------------------------------------
const RAW_IMAGES = "https://mars.nasa.gov/rss/api/?feed=raw_images&feedtype=json&order=sol+desc";
const ROVERS = { mars2020: "Perseverance", msl: "Curiosity" };
// Cámaras que muestran paisaje; se descartan micro-imágenes de rocas, láser, etc.
const SCENERY_CAMERA = /NAV|MCZ|MAST|HAZ|PANCAM|LCAM/i;
const ROVER_PHOTOS_SCHEMA = {
  meta: { source: "string", mode: "string", retrievedAt: "string" },
  count: "number",
  photos: ["array", { id: "string", rover: "string", sol: "number", earthDate: "string", camera: "string", title: "string", imageUrl: "string" }],
};

export async function getRoverPhotos({ missions = Object.keys(ROVERS), perRover = 4, fetchJson = request } = {}) {
  const photos = [];
  const warnings = [];
  for (const mission of missions.filter((m) => ROVERS[m])) {
    try {
      const raw = await fetchJson(`${RAW_IMAGES}&category=${mission}&num=60&page=0`);
      const seen = new Set(); // una foto por cámara: más variedad
      for (const p of Array.isArray(raw?.images) ? raw.images : []) {
        const camera = cleanText(p?.camera?.instrument, 30);
        const imageUrl = safeUrl(p?.image_files?.medium);
        const earthDate = isoDate(String(p?.date_taken_utc ?? "").slice(0, 10));
        const sol = num(p?.sol, { min: 0, max: 100000 });
        const id = cleanText(p?.imageid, 80);
        if (!camera || !SCENERY_CAMERA.test(camera) || !/\.jpe?g$/i.test(imageUrl ?? "") || !earthDate || sol == null || !id || seen.has(camera)) continue;
        seen.add(camera);
        photos.push({ id, rover: ROVERS[mission], sol, earthDate, camera, title: cleanText(p?.title, 120), imageUrl, pageUrl: safeUrl(p?.link) });
        if (seen.size >= perRover) break;
      }
    } catch (e) {
      warnings.push(`${mission}: ${redact(e.message).slice(0, 120)}`);
    }
  }
  if (!photos.length) throw new Error(`rover-photos: sin fotos. ${warnings.join(" | ")}`);
  const out = { meta: liveMeta({ source: "NASA Mars Raw Images (Perseverance, Curiosity)", sourceUrl: "https://mars.nasa.gov/rss/api/", warnings }), count: photos.length, photos };
  return assertValid(out, ROVER_PHOTOS_SCHEMA, "rover-photos");
}

// ---------------------------------------------------------------------------
// Imagen astronómica del día (APOD). Uso: pantalla de arranque. Requiere clave.
// ---------------------------------------------------------------------------
export const APOD_SCHEMA = {
  meta: { source: "string", mode: "string", retrievedAt: "string" },
  apod: { date: "string", title: "string", mediaType: "string", url: "string?", reusable: "boolean", explanation: "string" },
};

export async function getApod({ fetchJson = request } = {}) {
  const a = await fetchJson(`${NASA_API}planetary/apod?api_key=${encodeURIComponent(apiKey())}`);
  const copyright = cleanText(a?.copyright, 80) || null;
  const out = {
    meta: liveMeta({ source: "NASA APOD", sourceUrl: NASA_API }),
    apod: {
      date: isoDate(a?.date),
      title: cleanText(a?.title, 120),
      mediaType: a?.media_type === "video" ? "video" : "image",
      url: safeUrl(a?.url), // los videos suelen estar en YouTube: no pasan la lista de dominios y quedan en null
      hdUrl: safeUrl(a?.hdurl),
      copyright,
      reusable: copyright === null, // si trae copyright, NO usar la imagen en el juego sin permiso
      explanation: cleanText(a?.explanation, 400),
    },
  };
  return assertValid(out, APOD_SCHEMA, "apod");
}

// ---------------------------------------------------------------------------
// Clima en la superficie de Marte (InSight). Archivo congelado: sols de 2020.
// El enunciado pide "datos ambientales de misiones en Marte": sirve para el perfil del sitio.
// ---------------------------------------------------------------------------
const MARS_WEATHER_SCHEMA = {
  meta: { source: "string", mode: "string", retrievedAt: "string", frozenArchive: "boolean" },
  sols: [
    "array",
    {
      sol: "number",
      firstUtc: "string",
      season: "string",
      tempC: { avg: "number", min: "number", max: "number" },
      pressurePa: { avg: "number?", min: "number?", max: "number?" },
      windMs: { avg: "number?", max: "number?" },
    },
  ],
};

export async function getMarsSurfaceWeather({ fetchJson = request } = {}) {
  const raw = await fetchJson(`${NASA_API}insight_weather/?api_key=${encodeURIComponent(apiKey())}&feedtype=json&ver=1.0`);
  const keys = Array.isArray(raw?.sol_keys) ? raw.sol_keys.filter((k) => /^\d{1,5}$/.test(k)) : [];
  const t = (v) => num(v, { min: -200, max: 60, digits: 1 });
  const sols = keys
    .map((k) => {
      const s = raw[k] ?? {};
      const firstUtc = isoTime(s.First_UTC);
      const tempC = { avg: t(s.AT?.av), min: t(s.AT?.mn), max: t(s.AT?.mx) };
      if (!firstUtc || Object.values(tempC).some((v) => v == null)) return null; // sin temperatura válida => se descarta
      const pa = (v) => num(v, { min: 0, max: 2000, digits: 1 });
      const ws = (v) => num(v, { min: 0, max: 150, digits: 1 });
      return {
        sol: Number(k),
        firstUtc,
        season: cleanText(s.Season, 12).toLowerCase(),
        tempC,
        pressurePa: { avg: pa(s.PRE?.av), min: pa(s.PRE?.mn), max: pa(s.PRE?.mx) },
        windMs: { avg: ws(s.HWS?.av), max: ws(s.HWS?.mx) },
      };
    })
    .filter(Boolean);
  const newest = sols.at(-1)?.firstUtc;
  // Honestidad: si los datos son de hace más de un año, no se presentan como actuales.
  const frozenArchive = !newest || Date.now() - Date.parse(newest) > 365 * 86400000;
  return assertValid(
    { meta: liveMeta({ source: "NASA InSight Weather API", sourceUrl: NASA_API, frozenArchive, latestDataUtc: newest ?? null }), sols },
    MARS_WEATHER_SCHEMA,
    "mars-weather",
  );
}

// ---------------------------------------------------------------------------
// Clima espacial (DONKI, API oficial de CCMC desde 2026-09-30). No requiere clave.
// ---------------------------------------------------------------------------
const DONKI = "https://ccmc.gsfc.nasa.gov/DONKI-API/get/";
const SPACE_WEATHER_SCHEMA = {
  meta: { source: "string", mode: "string", retrievedAt: "string", windowStart: "string", windowEnd: "string" },
  summary: { maxThreat: "number", marsImpacts: "number", earthImpacts: "number" },
  events: ["array", { id: "string", type: "string", time: "string", threat: "number", gameEffect: "string" }],
};

export async function getSpaceWeatherLive({ days = 7, end, fetchJson = request } = {}) {
  const endDate = isoDate(end) ?? todayIso();
  const nDays = Math.min(30, Math.max(1, Number.isFinite(days) ? Math.floor(days) : 7));
  const startDate = addDays(endDate, -nDays);
  const plan = [["CME", normCME], ["FLR", normFLR], ["GST", normGST], ["SEP", normSEP], ["IPS", normIPS]];
  const events = [];
  const counts = {};
  for (const [type, norm] of plan) {
    const raw = await fetchJson(`${DONKI}${type}?startDate=${startDate}&endDate=${endDate}`);
    if (!Array.isArray(raw)) throw new Error(`DONKI ${type}: respuesta inesperada`);
    counts[type] = raw.length;
    for (const item of raw) {
      const ev = sanitizeEvent(norm(item));
      if (ev) events.push(ev);
    }
  }
  events.sort((a, b) => Date.parse(a.time) - Date.parse(b.time));
  const out = {
    meta: liveMeta({
      source: "NASA CCMC DONKI",
      sourceUrl: "https://ccmc.gsfc.nasa.gov/DONKI/api/",
      windowStart: startDate,
      windowEnd: endDate,
      note: "Información experimental de investigación; la fuente oficial de pronósticos es NOAA SWPC. 'threat' es una heurística de juego.",
    }),
    summary: {
      counts,
      maxThreat: Math.max(0, ...events.map((e) => e.threat)),
      marsImpacts: events.filter((e) => e.arrivals?.mars).length,
      earthImpacts: events.filter((e) => e.arrivals?.earth).length,
    },
    events,
  };
  return assertValid(out, SPACE_WEATHER_SCHEMA, "space-weather");
}

// ---------------------------------------------------------------------------
// Recursos educativos de la CSA (solo títulos y enlaces; el contenido NO se copia).
// Términos CSA: uso educativo no comercial permitido citando a la CSA y sin sugerir respaldo.
// ---------------------------------------------------------------------------
export const CSA_PAGES = [
  { id: "food-production", url: "https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/" },
  { id: "stem-youth", url: "https://www.asc-csa.gc.ca/eng/youth-educators/resources-stem-and-youth-organizations.asp" },
];
const CSA_HOSTS = [/(^|\.)asc-csa\.gc\.ca$/i, /(^|\.)letstalkscience\.ca$/i, /(^|\.)ingeniumcanada\.org$/i];
const CSA_SKIP_SECTIONS = /^(explore further|follow us|about this site|language selection|search|menu|you are here)/i;
const SYSTEM_RULES = [
  [/food|farm|garden|tomato|meal|chef|menu|eat|lunch|nutrition|agricultur|crop|spinach|chili|jam|grow/i, "food"],
  [/water|recycl|oxygen|air /i, "air"],
  [/radiation|shield|solar|sun /i, "shielding"],
  [/health|medic|fitness|sleep|exercise/i, "crew-health"],
];
const decode = (s) => String(s).replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'").replace(/&ndash;/g, "–");
const systemFor = (t) => SYSTEM_RULES.find(([re]) => re.test(t))?.[1] ?? "general";

const CSA_SCHEMA = {
  meta: { source: "string", mode: "string", retrievedAt: "string" },
  pages: ["array", { id: "string", title: "string", url: "string", sections: ["array", { name: "string", items: ["array", { title: "string", url: "string", external: "boolean", gameSystem: "string" }] }] }],
};

export function parseCsaPage(html, pageUrl) {
  const main = html.match(/<main[\s\S]*?<\/main>/i)?.[0] ?? html;
  const title = cleanText(decode((html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i) ?? [])[1] ?? ""), 120);
  const sections = [];
  let current = { name: "General", items: [] };
  const seen = new Set();
  const flush = () => current.items.length && sections.push(current);
  for (const m of main.matchAll(/<(h[2-4])[^>]*>([\s\S]*?)<\/\1>|<a\s[^>]*?href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/gi)) {
    if (m[1]) {
      flush();
      current = { name: cleanText(decode(m[2]), 80) || "General", items: [] };
      continue;
    }
    if (CSA_SKIP_SECTIONS.test(current.name)) continue;
    const href = decode(m[3]);
    const text = cleanText(decode(m[4]), 110);
    if (!text || /^(#|mailto:|javascript:)/i.test(href)) continue;
    let abs;
    try {
      abs = new URL(href, pageUrl);
    } catch {
      continue;
    }
    const url = safeUrl(abs.toString(), CSA_HOSTS);
    if (!url || seen.has(url)) continue;
    seen.add(url);
    current.items.push({ title: text, url, external: !/(^|\.)asc-csa\.gc\.ca$/i.test(abs.hostname), gameSystem: systemFor(`${current.name} ${text}`) });
  }
  flush();
  return { title, sections };
}

export async function getCsaResources({ pages = CSA_PAGES, fetchText = (u) => request(u, { as: "text" }) } = {}) {
  const out = [];
  for (const p of pages) {
    const { title, sections } = parseCsaPage(await fetchText(p.url), p.url);
    out.push({ id: p.id, title: title || p.id, url: p.url, sections });
  }
  const result = {
    meta: liveMeta({
      source: "Canadian Space Agency (CSA)",
      sourceUrl: "https://www.asc-csa.gc.ca/eng/youth-educators/",
      license: "Uso educativo no comercial permitido citando a la CSA y sin sugerir respaldo (https://www.asc-csa.gc.ca/eng/terms.asp). Aquí solo se guardan títulos y enlaces.",
    }),
    pages: out,
  };
  if (!out.some((p) => p.sections.some((s) => s.items.length))) throw new Error("csa: no se encontraron enlaces (¿cambió la página?)");
  return assertValid(result, CSA_SCHEMA, "csa");
}
