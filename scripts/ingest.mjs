#!/usr/bin/env node
/**
 * Pipeline de ingesta de datos NASA para el juego del outpost.
 *
 * Descarga datos reales (DONKI, RadLab, OSDR, Mars Trek, APOD), los normaliza
 * y los guarda como JSON estáticos en data/curated/. El juego lee esos archivos
 * y nunca llama a las APIs directamente (varias no permiten CORS desde el navegador).
 *
 * Uso:
 *   node scripts/ingest.mjs                      # todo, últimos 30 días de DONKI
 *   node scripts/ingest.mjs --days=14            # ventana de DONKI
 *   node scripts/ingest.mjs --end=2026-11-01     # fijar la fecha final (reproducible)
 *   node scripts/ingest.mjs --only=donki,radlab  # fuentes: donki,radlab,osdr,mars,rover,insight,apod,csa
 *
 * Requisitos: Node 20+ (fetch nativo). Sin dependencias.
 * Variable opcional: NASA_API_KEY (solo APOD). Nunca se imprime ni se guarda.
 */
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { normCME, normFLR, normGST, normSEP, normIPS, difficultyTier, sanitizeEvent } from "../src/api/normalize.mjs";
import { getRoverPhotos, getMarsSurfaceWeather, getApod, getCsaResources } from "../src/api/sources.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const OUT_DIR = path.join(ROOT, "data", "curated");

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v = "true"] = a.replace(/^--/, "").split("=");
    return [k, v];
  }),
);
const DAYS = Number(args.days ?? 30);
const END = args.end ?? new Date().toISOString().slice(0, 10);
const ONLY = args.only ? args.only.split(",") : null;
const wants = (name) => !ONLY || ONLY.includes(name);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const round = (x, d = 3) => (x == null || !Number.isFinite(x) ? null : Number(x.toFixed(d)));
const addDays = (iso, n) => new Date(Date.parse(iso + "T00:00:00Z") + n * 86400000).toISOString().slice(0, 10);

/** GET con timeout y reintentos con espera exponencial. Oculta api_key en errores. */
async function request(url, { as = "json", timeoutMs = 60000, retries = 3 } = {}) {
  let last;
  for (let i = 0; i <= retries; i++) {
    try {
      const res = await fetch(url, {
        signal: AbortSignal.timeout(timeoutMs),
        headers: { "User-Agent": "nasa-space-apps-2026-outpost/0.1 (educational prototype)" },
      });
      if (res.status === 429 || res.status >= 500) throw new Error(`HTTP ${res.status}`);
      if (!res.ok) {
        const e = new Error(`HTTP ${res.status}`);
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
  throw new Error(`${url.replace(/api_key=[^&]+/, "api_key=***")} -> ${last.message}`);
}

function meta(extra) {
  return {
    generatedBy: "scripts/ingest.mjs",
    retrievedAt: new Date().toISOString(),
    // "snapshot": copia guardada de datos reales. No se presenta como "en vivo" en el juego.
    mode: "snapshot",
    ...extra,
  };
}

async function writeJson(name, obj) {
  await mkdir(OUT_DIR, { recursive: true });
  await writeFile(path.join(OUT_DIR, name), JSON.stringify(obj, null, 2) + "\n");
}

// ---------------------------------------------------------------------------
// 1. DONKI: eventos de clima espacial
// ---------------------------------------------------------------------------
const DONKI = "https://ccmc.gsfc.nasa.gov/DONKI-API/get/";

const DONKI_NOTE =
  "Información experimental de investigación; la fuente oficial de pronósticos es NOAA SWPC. Los valores de 'threat' son una heurística de juego.";

async function fetchDonkiWindow(start, end) {
  const query = `?startDate=${start}&endDate=${end}`;
  const plan = [
    ["CME", normCME],
    ["FLR", normFLR],
    ["GST", normGST],
    ["SEP", normSEP],
    ["IPS", normIPS],
  ];
  const events = [];
  const counts = {};
  for (const [type, norm] of plan) {
    const raw = await request(DONKI + type + query);
    counts[type] = raw.length;
    for (const item of raw) {
      const ev = sanitizeEvent(norm(item));
      if (ev) events.push(ev);
    }
  }
  events.sort((a, b) => Date.parse(a.time) - Date.parse(b.time));
  const summary = {
    counts,
    maxThreat: Math.max(0, ...events.map((e) => e.threat)),
    marsImpacts: events.filter((e) => e.arrivals?.mars).length,
    earthImpacts: events.filter((e) => e.arrivals?.earth).length,
  };
  return { events, summary };
}

// Ventanas históricas reales para rejugar. Solo se descargan eventos de DONKI de esas fechas.
const SCENARIOS = [
  { id: "quiet-recent", name: { es: "Semana tranquila (reciente)", en: "Quiet week (recent)" }, start: addDays(END, -7), end: END },
  { id: "sep-2017-storms", name: { es: "Tormentas de septiembre de 2017", en: "September 2017 storms" }, start: "2017-09-03", end: "2017-09-13" },
  { id: "gannon-2024-05", name: { es: "Tormenta de mayo de 2024", en: "May 2024 storm" }, start: "2024-05-07", end: "2024-05-14" },
  { id: "oct-2024-x9", name: { es: "Octubre de 2024: erupción X9", en: "October 2024: X9 flare" }, start: "2024-10-01", end: "2024-10-11" },
];

async function ingestDonki() {
  const start = addDays(END, -DAYS);
  const { events, summary } = await fetchDonkiWindow(start, END);
  await writeJson("space_weather.json", {
    meta: meta({ source: "NASA CCMC DONKI", sourceUrl: "https://ccmc.gsfc.nasa.gov/DONKI/api/", windowStart: start, windowEnd: END, note: DONKI_NOTE }),
    summary,
    events,
  });

  const scenarios = [];
  const failures = [];
  for (const s of SCENARIOS) {
    try {
      const w = await fetchDonkiWindow(s.start, s.end);
      scenarios.push({ id: s.id, name: s.name, windowStart: s.start, windowEnd: s.end, difficulty: difficultyTier(w.events), ...w });
    } catch (e) {
      failures.push(`${s.id}: ${e.message}`);
    }
  }
  await writeJson("space_weather_scenarios.json", {
    meta: meta({ source: "NASA CCMC DONKI (archivo histórico)", sourceUrl: "https://ccmc.gsfc.nasa.gov/DONKI/api/", note: DONKI_NOTE, errors: failures }),
    scenarios,
  });
  return {
    count: events.length,
    detail: { counts: summary.counts, scenarios: Object.fromEntries(scenarios.map((s) => [s.id, `${s.difficulty} (max ${s.summary.maxThreat}, ${s.events.length} ev)`])) },
  };
}

// ---------------------------------------------------------------------------
// 2. RadLab: dosimetría real (ISS, órbita lunar, Orion/Artemis I, órbita de Marte)
// ---------------------------------------------------------------------------
const RADLAB = "https://visualization.osdr.nasa.gov/radlab/api/";
// IMPORTANTE: siempre ventana de tiempo corta; sin ella el servidor responde 504.
const RADLAB_SITES = [
  { id: "leo-iss", label: { es: "Estación Espacial Internacional (órbita baja terrestre)", en: "International Space Station (low Earth orbit)" }, query: { spacecraft: "ISS", instrument: "Lidal" }, start: "2023-01-01", days: 3 },
  { id: "moon-orbit-lro", label: { es: "Órbita lunar (sonda LRO, instrumento CRaTER)", en: "Lunar orbit (LRO, CRaTER)" }, query: { celestial_body: "Moon", spacecraft: "LRO" }, start: "2019-01-05", days: 3 },
  { id: "moon-orion-artemis1", label: { es: "Cápsula Orion en Artemis I (vuelo lunar)", en: "Orion capsule, Artemis I (lunar flyby)" }, query: { celestial_body: "Moon", spacecraft: "Orion" }, start: "2022-11-20", days: 1 },
  { id: "mars-orbit-liulin", label: { es: "Órbita de Marte (instrumento Liulin-MO)", en: "Mars orbit (Liulin-MO)" }, query: { instrument_id: "Liulin-MO-AB-Orbit" }, start: "2018-06-01", days: 3 },
];

async function radlabRows(site) {
  const parts = Object.entries(site.query).map(([k, v]) => `${k}=${encodeURIComponent(v)}`);
  parts.push(`timestamp%3E=${site.start}`, `timestamp%3C${addDays(site.start, site.days)}`);
  parts.push("absorbed_dose_rate", "dose_equivalent_rate", "format=json");
  const json = await request(`${RADLAB}?${parts.join("&")}`, { timeoutMs: 120000 });
  return json.data.map((row) => Object.fromEntries(json.columns.map((c, i) => [c, row[i]])));
}

function percentile(sorted, p) {
  if (!sorted.length) return null;
  const idx = (sorted.length - 1) * p;
  const lo = Math.floor(idx);
  const hi = Math.ceil(idx);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (idx - lo);
}

function stats(values) {
  const v = values.filter((x) => typeof x === "number" && Number.isFinite(x) && x >= 0).sort((a, b) => a - b);
  if (!v.length) return null;
  return {
    n: v.length,
    min: round(v[0]),
    p50: round(percentile(v, 0.5)),
    mean: round(v.reduce((s, x) => s + x, 0) / v.length),
    p95: round(percentile(v, 0.95)),
    max: round(v[v.length - 1]),
  };
}

function hourly(rows, field) {
  const buckets = new Map();
  for (const r of rows) {
    const v = r[field];
    if (typeof v !== "number" || !Number.isFinite(v) || v < 0) continue;
    const key = String(r.timestamp).slice(0, 13);
    const b = buckets.get(key) ?? { s: 0, n: 0 };
    b.s += v;
    b.n += 1;
    buckets.set(key, b);
  }
  return [...buckets.entries()].sort().map(([t, b]) => ({ t, v: round(b.s / b.n) }));
}

async function ingestRadlab() {
  const sites = [];
  const errors = [];
  for (const site of RADLAB_SITES) {
    try {
      const rows = await radlabRows(site);
      const byInstrument = new Map();
      for (const r of rows) {
        if (!byInstrument.has(r.instrument_id)) byInstrument.set(r.instrument_id, []);
        byInstrument.get(r.instrument_id).push(r);
      }
      const instruments = [...byInstrument.entries()].map(([id, rs]) => ({
        instrumentId: id,
        // Unidades distintas: NO se pueden sumar ni tratar como equivalentes.
        absorbedDoseRate: { unit: "uGy/h", ...stats(rs.map((r) => r.absorbed_dose_rate)) },
        doseEquivalentRate: stats(rs.map((r) => r.dose_equivalent_rate)) && { unit: "uSv/h", ...stats(rs.map((r) => r.dose_equivalent_rate)) },
        hourlyAbsorbedDoseRate: hourly(rs, "absorbed_dose_rate"),
      })).filter((i) => i.absorbedDoseRate?.n);
      const means = instruments.map((i) => i.absorbedDoseRate.mean).sort((a, b) => a - b);
      sites.push({
        id: site.id,
        label: site.label,
        query: site.query,
        window: { start: site.start, endExclusive: addDays(site.start, site.days) },
        rowCount: rows.length,
        medianOfInstrumentMeans_uGyPerH: round(percentile(means, 0.5)),
        instruments,
      });
    } catch (e) {
      errors.push(`${site.id}: ${e.message}`);
    }
  }
  if (!sites.length) throw new Error(errors.join(" | "));

  const base = sites.find((s) => s.id === "leo-iss")?.medianOfInstrumentMeans_uGyPerH;
  const ratios = Object.fromEntries(
    sites.map((s) => [s.id, base ? round(s.medianOfInstrumentMeans_uGyPerH / base, 2) : null]),
  );
  await writeJson("radiation.json", {
    meta: meta({
      source: "NASA OSDR RadLab",
      sourceUrl: "https://visualization.osdr.nasa.gov/radlab/gui/data-api/",
      errors,
    }),
    caveats: [
      "Cada sitio usa instrumentos, años y fases del ciclo solar distintos. Las razones entre sitios son orientativas, no una medición comparable.",
      "RadLab no contiene mediciones de superficie lunar ni marciana en estas consultas; son órbita o vuelo.",
      "Dosis absorbida (uGy/h) y dosis equivalente (uSv/h) son magnitudes distintas.",
    ],
    ratiosToLeoIss: ratios,
    sites,
  });
  return { count: sites.length, detail: ratios, errors };
}

// ---------------------------------------------------------------------------
// 3. OSDR: evidencia biológica por tema del juego
// ---------------------------------------------------------------------------
const OSDR_SEARCH = "https://osdr.nasa.gov/osdr/data/search";
// `match` filtra coincidencias casuales del buscador: el estudio debe tratar realmente el tema.
const OSDR_TOPICS = [
  { id: "bone", term: "bone density spaceflight", gameSystem: "crew-health", match: /bone|skelet|osteo|vertebra|femur|trabecul/i },
  { id: "muscle", term: "muscle atrophy spaceflight", gameSystem: "crew-health", match: /muscle|myo|atroph|soleus|sarcopen/i },
  { id: "immune", term: "immune spaceflight", gameSystem: "crew-health", match: /immun|inflamm|cytokine|lymph|leukocyte/i },
  { id: "radiation", term: "space radiation", gameSystem: "shielding", match: /radiat|cosmic ray|proton|heavy ion|HZE|gamma|dosimet|GCR/i },
  { id: "plants", term: "plant growth spaceflight", gameSystem: "food-air", match: /plant|arabidopsis|seed|root|crop|lettuce|greenhouse|vegetable/i },
  { id: "sleep", term: "sleep spaceflight", gameSystem: "crew-health", match: /sleep|circadian|wake/i },
];

/** 0 = descartar. Más alto = más pertinente al tema del juego. */
function relevance(topic, src) {
  const title = String(src["Study Title"] ?? "");
  const text = `${src["Study Description"] ?? ""} ${src["Study Protocol Description"] ?? ""}`;
  const inTitle = topic.match.test(title);
  const inText = (text.match(new RegExp(topic.match.source, "gi")) ?? []).length;
  if (!inTitle && inText < 2) return 0;
  const organism = Array.isArray(src.organism) ? src.organism.join(" ") : String(src.organism ?? "");
  const human = /homo sapiens|human/i.test(`${organism} ${src["Material Type"] ?? ""}`);
  const flown = /spaceflight/i.test(String(src["Project Type"] ?? "")) || Boolean(src["Flight Program"]);
  return (inTitle ? 5 : 0) + Math.min(inText, 4) + (flown ? 1 : 0) + (human ? 2 : 0);
}

const clean = (s, n = 320) => String(s ?? "").replace(/\s+/g, " ").trim().slice(0, n);

function normStudy(src, id) {
  const acc = src.Accession || id;
  const organism = Array.isArray(src.organism) ? src.organism.join(", ") : src.organism || src.Organism || null;
  const released = typeof src["Study Public Release Date"] === "number" ? new Date(src["Study Public Release Date"] * 1000).toISOString().slice(0, 10) : null;
  const human = /homo sapiens|human/i.test(`${organism ?? ""} ${src["Material Type"] ?? ""}`);
  return {
    accession: acc,
    title: clean(src["Study Title"], 200),
    organism,
    material: clean(src["Material Type"], 80) || null,
    mission: clean(src.Mission?.Name, 80) || null,
    flightProgram: clean(src["Flight Program"], 80) || null,
    projectType: src["Project Type"] || null,
    released,
    summaryOriginal: clean(src["Study Description"] || src["Study Protocol Description"]),
    evidenceNote: human
      ? "Estudio con muestras o datos humanos."
      : "No es una medición directa en astronautas: no presentar como efecto exacto en personas.",
    url: `https://osdr.nasa.gov/bio/repo/data/studies/${acc}`,
    // Se rellena en el paso editorial con IA + revisión humana (ver docs/ia/PROMPTS.md)
    kidSummary: { es: null, en: null, reviewedByHuman: false },
  };
}

async function ingestOsdr() {
  const topics = [];
  for (const t of OSDR_TOPICS) {
    const json = await request(`${OSDR_SEARCH}?term=${encodeURIComponent(t.term)}&size=50`);
    const seen = new Set();
    const ranked = [];
    for (const h of json.hits?.hits ?? []) {
      const src = h._source ?? {};
      const acc = src.Accession || h._id;
      if (!/^OSD-\d+$/.test(acc) || seen.has(acc)) continue; // solo estudios NASA OSDR, no GEO/PRIDE
      const spaceRelated = /space/i.test(`${src["Project Type"] ?? ""} ${src["Space Program"] ?? ""} ${src["Flight Program"] ?? ""}`);
      const score = spaceRelated ? relevance(t, src) : 0;
      if (!score) continue;
      seen.add(acc);
      ranked.push({ score, study: normStudy(src, h._id) });
    }
    const studies = ranked.sort((a, b) => b.score - a.score).slice(0, 5).map((r) => r.study);
    topics.push({ id: t.id, searchTerm: t.term, gameSystem: t.gameSystem, totalHits: json.hits?.total ?? null, studies });
  }
  await writeJson("osdr_facts.json", {
    meta: meta({ source: "NASA OSDR search", sourceUrl: "https://osdr.nasa.gov/bio/repo/", license: "Revisar la licencia indicada en cada estudio (p. ej. CC0-1.0)" }),
    topics,
  });
  return { count: topics.reduce((s, t) => s + t.studies.length, 0), detail: Object.fromEntries(topics.map((t) => [t.id, t.studies.length])) };
}

// ---------------------------------------------------------------------------
// 4. Mars Trek: capas WMTS para el mapa del sitio
// ---------------------------------------------------------------------------
const MARS_LAYERS = [
  {
    id: "mola-color",
    title: "Mars MGS MOLA color shaded relief (463 m)",
    capabilities: "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/WMTSCapabilities.xml",
    credit: "NASA/JPL-Caltech, Mars Trek, MGS MOLA",
  },
];

async function ingestMars() {
  const layers = [];
  for (const l of MARS_LAYERS) {
    const xml = await request(l.capabilities, { as: "text" });
    const pick = (re) => re.exec(xml)?.[1] ?? null;
    const template = pick(/template="([^"]+)"/)?.replace(/([^:])\/\//g, "$1/");
    const levels = [...xml.matchAll(/<TileMatrix><ows:Identifier>(\d+)</g)].length;
    layers.push({
      id: l.id,
      title: l.title,
      credit: l.credit,
      capabilitiesUrl: l.capabilities,
      tileUrlTemplate: template, // sustituir {Style},{TileMatrixSet},{TileMatrix},{TileRow},{TileCol}
      style: pick(/<Style[^>]*>\s*<ows:Title>[^<]*<\/ows:Title>\s*<ows:Identifier>([^<]+)</),
      tileMatrixSet: pick(/<TileMatrixSet>([^<]+)<\/TileMatrixSet>/),
      format: pick(/<Format>([^<]+)<\/Format>/),
      crs: pick(/<ows:SupportedCRS>([^<]+)</),
      zoomLevels: levels,
      note: "CRS marciano (EPSG:104905), no Web Mercator terrestre. Nivel 0 = 2 columnas x 1 fila. Una tesela ausente = sin datos.",
    });
  }
  await writeJson("mars_layers.json", {
    meta: meta({ source: "NASA Mars Trek WMTS", sourceUrl: "https://trek.nasa.gov/tiles/apidoc/trekAPI.html?body=mars" }),
    layers,
  });
  return { count: layers.length };
}

// ---------------------------------------------------------------------------
// 5. Fuentes de api.nasa.gov y CSA: usan los adaptadores de src/api/sources.mjs (misma ruta que el modo en vivo)
// ---------------------------------------------------------------------------
async function ingestRover() {
  const d = await getRoverPhotos({});
  await writeJson("rover_photos.json", { ...d, meta: meta({ source: d.meta.source, sourceUrl: d.meta.sourceUrl, warnings: d.meta.warnings }) });
  return { count: d.count };
}

async function ingestApod() {
  const d = await getApod({});
  await writeJson("apod.json", { ...d, meta: meta({ source: d.meta.source, sourceUrl: d.meta.sourceUrl, note: "Si apod.reusable es false, no usar la imagen en el juego." }) });
  return { count: 1 };
}

async function ingestCsa() {
  const d = await getCsaResources({});
  await writeJson("csa_resources.json", { ...d, meta: meta({ source: d.meta.source, sourceUrl: d.meta.sourceUrl, license: d.meta.license }) });
  return { count: d.pages.reduce((n, p) => n + p.sections.reduce((m, s) => m + s.items.length, 0), 0), detail: Object.fromEntries(d.pages.map((p) => [p.id, p.sections.map((s) => `${s.name}:${s.items.length}`)])) };
}

// Clima de superficie de Marte (InSight): archivo congelado; el pipeline lo marca como tal.
async function ingestInsight() {
  const d = await getMarsSurfaceWeather({});
  await writeJson("mars_weather.json", {
    ...d,
    meta: meta({ source: d.meta.source, sourceUrl: d.meta.sourceUrl, frozenArchive: d.meta.frozenArchive, latestDataUtc: d.meta.latestDataUtc }),
  });
  return { count: d.sols.length, detail: { frozenArchive: d.meta.frozenArchive, latestDataUtc: d.meta.latestDataUtc } };
}

const JOBS = [
  ["donki", ingestDonki],
  ["radlab", ingestRadlab],
  ["osdr", ingestOsdr],
  ["mars", ingestMars],
  ["rover", ingestRover],
  ["insight", ingestInsight],
  ["apod", ingestApod],
  ["csa", ingestCsa],
];

// Conserva el estado de fuentes no ejecutadas en esta corrida (p. ej. con --only).
let previous = {};
try {
  previous = JSON.parse(await readFile(path.join(OUT_DIR, "manifest.json"), "utf8")).sources ?? {};
} catch {
  /* primera ejecución */
}
const manifest = { generatedAt: new Date().toISOString(), params: { days: DAYS, end: END }, sources: {} };
let okCount = 0;
for (const [name, job] of JOBS) {
  if (!wants(name)) {
    manifest.sources[name] = previous[name] ?? { status: "skipped" };
    continue;
  }
  const t0 = Date.now();
  try {
    const r = await job();
    manifest.sources[name] = { status: "ok", ms: Date.now() - t0, ...r };
    okCount++;
    console.log(`[ok]   ${name} (${Date.now() - t0} ms) ${JSON.stringify(r.detail ?? r.count)}`);
  } catch (e) {
    // Si falla, NO se sobrescribe el archivo anterior: el juego sigue con el último snapshot bueno.
    manifest.sources[name] = { status: "error", error: e.message };
    console.error(`[fail] ${name}: ${e.message}`);
  }
}
await mkdir(OUT_DIR, { recursive: true });
await writeFile(path.join(OUT_DIR, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");
console.log(`\nListo: ${okCount} fuentes OK. Salida en data/curated/`);
process.exit(okCount > 0 ? 0 : 1);
