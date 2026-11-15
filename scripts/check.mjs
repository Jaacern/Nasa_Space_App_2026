#!/usr/bin/env node
/**
 * Comprobaciones del proyecto.
 *   npm run check          # sin red: contenido, snapshots, catálogo y relevancia de los datos
 *   npm run check:live     # además prueba las fuentes reales con el saneado y busca fugas de clave
 *
 * Regla de relevancia: todo archivo de data/curated/ debe pertenecer a una fuente del catálogo
 * (src/api/catalog.mjs), y cada fuente declara para qué sirve en el juego. Así no entran datos "porque sí".
 */
import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { CATALOG } from "../src/api/catalog.mjs";
import { APOD_SCHEMA, getApod, getCsaResources, getMarsSurfaceWeather, getRoverPhotos, getSpaceWeatherLive } from "../src/api/sources.mjs";
import { request } from "../src/api/http.mjs";
import { findSecretLeaks, redact, validate } from "../src/api/sanitize.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const load = async (p) => JSON.parse(await readFile(path.join(ROOT, p), "utf8"));
const errors = [];
const warns = [];
const err = (m) => errors.push(m);

// --- 1. Contenido del juego -------------------------------------------------
const { cards } = await load("content/cards.json");
const balance = await load("content/balance.json");
const { terms } = await load("content/glossary.json");
const ids = new Set();
for (const c of cards) {
  if (ids.has(c.id)) err(`carta duplicada: ${c.id}`);
  ids.add(c.id);
  for (const lang of ["es", "en"]) if (!c.name?.[lang]) err(`${c.id}: falta name.${lang}`);
  if (!c.benefit || !Object.keys(c.benefit).length) err(`${c.id}: sin beneficio`);
  if (!c.immediateCost || !Object.values(c.immediateCost).some((v) => v > 0)) err(`${c.id}: sin costo inmediato (carta gratis)`);
  if (!c.deferredCost?.effect) err(`${c.id}: sin costo diferido`);
  if (!c.deferredCost?.note?.es || !c.deferredCost?.note?.en) err(`${c.id}: costo diferido sin nota es/en`);
  if (!c.teaches?.es || !c.teaches?.en) err(`${c.id}: falta 'teaches' es/en`);
  if (!Number.isInteger(c.stackLimit) || c.stackLimit < 1) err(`${c.id}: stackLimit inválido`);
  if (!(c.sites ?? []).length || c.sites.some((s) => !["moon", "mars"].includes(s))) err(`${c.id}: sites inválido`);
}
if (cards.length < 6) warns.push(`solo ${cards.length} cartas (mínimo recomendado: 6)`);
for (const k of ["run", "start", "caps", "perSol", "powerModes", "sites", "dose", "scoring"]) if (!balance[k]) err(`balance.json: falta '${k}'`);
for (const t of terms) if (!t.es?.text || !t.en?.text) err(`glosario ${t.id}: falta texto es/en`);

// --- 2. Snapshots y catálogo --------------------------------------------------
const files = (await readdir(path.join(ROOT, "data", "curated"))).filter((f) => f.endsWith(".json") && f !== "manifest.json");
const declared = new Set(CATALOG.flatMap((s) => s.snapshots));
for (const f of files) if (!declared.has(f)) err(`data/curated/${f} no pertenece a ninguna fuente del catálogo (¿dato irrelevante? bórralo o añádelo con su uso en el juego)`);
for (const s of CATALOG) {
  if (!s.gameUse) err(`catálogo ${s.id}: sin 'gameUse'`);
  for (const f of s.snapshots) {
    if (!files.includes(f)) {
      (s.optional ? warns : errors).push(`${s.id}: falta data/curated/${f}${s.needsKey ? " (necesita NASA_API_KEY: npm run ingest)" : ""}`);
      continue;
    }
    const d = await load(`data/curated/${f}`);
    if (!d.meta?.source) err(`${f}: sin meta.source`);
    if (!d.meta?.retrievedAt) err(`${f}: sin meta.retrievedAt`);
    if (d.meta?.mode !== "snapshot") err(`${f}: meta.mode debe ser "snapshot"`);
  }
}
const sw = await load("data/curated/space_weather_scenarios.json").catch(() => null);
for (const s of sw?.scenarios ?? []) {
  if (!s.events.length) err(`escenario ${s.id} sin eventos`);
  if (s.events.some((e) => !(e.threat >= 0 && e.threat <= 1))) err(`escenario ${s.id}: threat fuera de 0..1`);
}
const osdr = await load("data/curated/osdr_facts.json").catch(() => null);
if (osdr) {
  const all = osdr.topics.flatMap((t) => t.studies);
  const pending = all.filter((s) => !s.kidSummary?.reviewedByHuman).length;
  for (const t of osdr.topics) if (!t.studies.length) err(`osdr: tema '${t.id}' sin estudios`);
  if (pending) warns.push(`${pending} estudios OSDR sin resumen infantil revisado (el juego los ocultará)`);
}
const photos = await load("data/curated/rover_photos.json").catch(() => null);
if (photos && photos.photos.some((p) => !/^https:\/\/[^/]*nasa\.gov\//i.test(p.imageUrl))) err("rover_photos: imagen fuera de nasa.gov");
const apod = await load("data/curated/apod.json").catch(() => null);
if (apod) {
  for (const p of validate(apod, APOD_SCHEMA, "$")) err(`apod.json: ${p}`);
  if (!apod.apod?.reusable) warns.push("apod.json marcado reusable: false (provisional o con copyright; regenerar con NASA_API_KEY si se usará en pantalla)");
}

// --- 3. Fuentes en vivo (opcional) ----------------------------------------------
if (process.argv.includes("--live")) {
  const usingDemo = !process.env.NASA_API_KEY;
  console.log(`Clave NASA: ${usingDemo ? "NO configurada (DEMO_KEY, límite muy bajo)" : "configurada"}\n`);
  const live = [
    ["DONKI", false, async () => { const d = await getSpaceWeatherLive({ days: 3 }); return [d, `${d.events.length} eventos`]; }],
    ["RadLab", false, async () => {
      const j = await request("https://visualization.osdr.nasa.gov/radlab/api/?spacecraft=ISS&instrument=Lidal&timestamp%3E=2023-01-01&timestamp%3C2023-01-02&absorbed_dose_rate&format=json", { timeoutMs: 90000 });
      if (!Array.isArray(j.columns) || !Array.isArray(j.data)) throw new Error("formato inesperado");
      return [{ rows: j.data.length }, `${j.data.length} filas`];
    }],
    ["OSDR", false, async () => {
      const j = await request("https://osdr.nasa.gov/osdr/data/search?term=bone%20density&size=3");
      if (!j?.hits?.hits) throw new Error("formato inesperado");
      return [{ total: j.hits.total }, `${j.hits.total} resultados`];
    }],
    ["Mars Trek", false, async () => {
      const xml = await request("https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/WMTSCapabilities.xml", { as: "text" });
      if (!xml.includes("<Capabilities")) throw new Error("no es WMTS");
      return [{ ok: true }, "capabilities OK"];
    }],
    ["Rover Photos", true, async () => { const d = await getRoverPhotos({ perRover: 3 }); return [d, `${d.count} fotos`]; }],
    ["APOD", true, async () => { const d = await getApod({}); return [d, `${d.apod.date}${d.apod.reusable ? "" : " (con copyright)"}`]; }],
    ["InSight", true, async () => { const d = await getMarsSurfaceWeather({}); return [d, `${d.sols.length} sols, congelado: ${d.meta.frozenArchive}`]; }],
    ["CSA", false, async () => { const d = await getCsaResources({}); return [d, `${d.pages.map((p) => p.sections.reduce((n, s) => n + s.items.length, 0)).join(" + ")} enlaces`]; }],
  ];
  for (const [name, needsKey, run] of live) {
    const t0 = Date.now();
    try {
      const [out, info] = await run();
      const leaks = findSecretLeaks(out);
      if (leaks.length) err(`${name}: fuga de clave (${leaks.join(", ")})`);
      console.log(`${leaks.length ? "[FALLO]" : "[ok]   "} ${name.padEnd(13)} ${String(Date.now() - t0).padStart(5)} ms  ${info}`);
    } catch (e) {
      const limited = /429/.test(e.message) && needsKey && usingDemo;
      (limited ? warns : errors).push(`${name}: ${redact(e.message).slice(0, 140)}${limited ? " (DEMO_KEY agotada: pon tu clave en .env)" : ""}`);
      console.log(`${limited ? "[aviso]" : "[FALLO]"} ${name.padEnd(13)} ${String(Date.now() - t0).padStart(5)} ms  ${redact(e.message).slice(0, 100)}`);
    }
  }
  console.log("");
}

for (const w of warns) console.log("[aviso]", w);
if (errors.length) {
  for (const e of errors) console.error("[error]", e);
  process.exit(1);
}
console.log(`OK: ${cards.length} cartas, ${terms.length} términos, ${files.length} snapshots, ${CATALOG.length} fuentes.`);
