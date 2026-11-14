/**
 * Capa de datos del juego. Convierte los JSON de data/curated/ en cosas que el
 * motor de juego puede usar: calendario de eventos, perfil del sitio y datos curiosos.
 *
 * Módulo ESM sin dependencias; funciona en el navegador y en Node.
 * Las constantes marcadas como "valor de juego" son decisiones del equipo, no datos NASA.
 */

const CURATED_FILES = {
  spaceWeather: "space_weather.json",
  scenarios: "space_weather_scenarios.json",
  radiation: "radiation.json",
  osdr: "osdr_facts.json",
  marsLayers: "mars_layers.json",
  manifest: "manifest.json",
};
// Opcionales: si falta el archivo, el valor queda en null y el juego sigue sin esa decoración.
const OPTIONAL_FILES = {
  marsWeather: "mars_weather.json",
  roverPhotos: "rover_photos.json",
  csa: "csa_resources.json",
  apod: "apod.json",
};

/** Lector para el navegador. `base` debe apuntar a donde sirves data/curated/. */
export function browserReader(base = "./data/curated/") {
  return async (name) => {
    const res = await fetch(base + name);
    if (!res.ok) throw new Error(`No se pudo leer ${name}: HTTP ${res.status}`);
    return res.json();
  };
}

/** Carga todos los snapshots. `read(nombre)` devuelve el JSON parseado. */
export async function loadWorldState(read) {
  const required = Object.entries(CURATED_FILES).map(async ([k, f]) => [k, await read(f)]);
  const optional = Object.entries(OPTIONAL_FILES).map(async ([k, f]) => [k, await read(f).catch(() => null)]);
  return Object.fromEntries(await Promise.all([...required, ...optional]));
}

/** Atribución visible para la pantalla de créditos / pie del juego. */
export function attributionLines(state) {
  const day = (m) => String(m?.retrievedAt ?? "").slice(0, 10);
  return [
    `Eventos solares: NASA CCMC DONKI (copia del ${day(state.spaceWeather.meta)}, no en vivo)`,
    `Radiación: NASA OSDR RadLab (mediciones históricas, copia del ${day(state.radiation.meta)})`,
    `Biología espacial: NASA Open Science Data Repository (copia del ${day(state.osdr.meta)})`,
    "Mapa de Marte: NASA/JPL Mars Trek",
    "Este juego no está patrocinado ni respaldado por NASA ni por la CSA.",
  ];
}

// --- Sitios ---------------------------------------------------------------
const C_KM_S = 299792.458;
export const SITES = {
  moon: {
    id: "moon",
    name: { es: "Base lunar", en: "Lunar outpost" },
    radiationSiteIds: ["moon-orbit-lro", "moon-orion-artemis1"],
    // Distancia media Tierra-Luna / velocidad de la luz (~1,3 s).
    commDelaySec: { min: 384400 / C_KM_S, max: 384400 / C_KM_S },
    // DONKI modela la Tierra y Marte, no la Luna: se usa la Tierra como aproximación.
    eventProxy: "earth",
  },
  mars: {
    id: "mars",
    name: { es: "Base marciana", en: "Mars outpost" },
    radiationSiteIds: ["mars-orbit-liulin"],
    // Distancia Tierra-Marte ~54,6 a ~401 millones de km => ~3 a ~22 minutos (un solo sentido).
    commDelaySec: { min: 54.6e6 / C_KM_S, max: 401e6 / C_KM_S },
    eventProxy: "mars",
  },
};

const SYNODIC_DAYS = 779.94; // Tierra y Marte vuelven a la misma posición relativa cada ~780 días

/** Retraso de comunicación (un solo sentido) en un sol dado. Aproximación sinusoidal. */
export function commDelaySec(siteId, sol, { phase = 0 } = {}) {
  const { min, max } = SITES[siteId].commDelaySec;
  if (min === max) return min;
  const mid = (min + max) / 2;
  const amp = (max - min) / 2;
  return mid + amp * Math.cos((2 * Math.PI * sol) / SYNODIC_DAYS + phase);
}

/**
 * Perfil de radiación del sitio. Son mediciones en órbita o en vuelo, no en superficie.
 * `doseMultiplierVsIss` compara contra la ISS (valor orientativo; ver caveats en radiation.json).
 */
export function siteProfile(state, siteId) {
  const site = SITES[siteId];
  const measured = state.radiation.sites.filter((s) => site.radiationSiteIds.includes(s.id));
  if (!measured.length) throw new Error(`Sin datos de radiación para ${siteId}`);
  const best = measured[0];
  const inst = best.instruments[0];
  return {
    siteId,
    name: site.name,
    measuredAt: { label: best.label, window: best.window, instrumentId: inst.instrumentId },
    absorbedDoseRate_uGyPerH: { typical: inst.absorbedDoseRate.p50, mean: inst.absorbedDoseRate.mean, p95: inst.absorbedDoseRate.p95, max: inst.absorbedDoseRate.max },
    doseMultiplierVsIss: state.radiation.ratiosToLeoIss[best.id] ?? null,
    commDelaySec: site.commDelaySec,
    caveats: state.radiation.caveats,
  };
}

// --- Eventos --------------------------------------------------------------
function hitsSite(e, siteId) {
  const proxy = SITES[siteId].eventProxy;
  switch (e.type) {
    case "CME":
      return Boolean(e.arrivals?.[proxy]);
    case "IPS":
      return (e.detail?.location ?? "").toLowerCase() === proxy;
    case "GST": // la tormenta es en la Tierra; el control de misión está allí, así que afecta a ambos sitios
    case "FLR": // simplificación: los rayos X solares llegan a ambos (dependen de la geometría real)
    case "SEP": // simplificación: igual que arriba
      return true;
    default:
      return false;
  }
}

/** Devuelve el escenario "live" (últimos días) o uno archivado por id. */
export function getScenario(state, id = "live") {
  if (id === "live") {
    const sw = state.spaceWeather;
    return { id: "live", name: { es: "Semana real reciente (copia guardada)", en: "Recent real period (saved copy)" }, windowStart: sw.meta.windowStart, windowEnd: sw.meta.windowEnd, difficulty: null, events: sw.events, summary: sw.summary };
  }
  const s = state.scenarios.scenarios.find((x) => x.id === id);
  if (!s) throw new Error(`Escenario desconocido: ${id}`);
  return s;
}

/**
 * Reparte los eventos reales en `sols` días de juego, conservando el orden y la
 * separación relativa. `warningSols` = días de aviso entre la erupción y la llegada.
 */
export function scheduleEvents(scenario, siteId, { sols = 30, minThreat = 0.1 } = {}) {
  const t0 = Date.parse(scenario.windowStart + "T00:00:00Z");
  const t1 = Date.parse(scenario.windowEnd + "T23:59:59Z");
  const span = t1 - t0;
  const toSol = (iso) => Math.min(sols - 1, Math.max(0, Math.floor(((Date.parse(iso) - t0) / span) * sols)));
  const proxy = SITES[siteId].eventProxy;
  return scenario.events
    .filter((e) => e.threat >= minThreat)
    .map((e) => {
      const arrival = e.arrivals?.[proxy];
      const sol = toSol(e.time);
      return {
        ...e,
        sol,
        hitsSite: hitsSite(e, siteId),
        arrivalSol: arrival ? toSol(arrival) : null,
        warningSols: arrival ? Math.max(0, toSol(arrival) - sol) : null,
      };
    })
    .sort((a, b) => a.sol - b.sol || b.threat - a.threat);
}

// --- Datos curiosos reales (OSDR) --------------------------------------------
/** Aleatorio con semilla (mulberry32): misma semilla => misma partida. */
export function makeRng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Elige un estudio real de un tema ("bone", "muscle", "immune", "radiation", "plants", "sleep"). */
export function pickFact(state, topicId, rng = Math.random) {
  const topic = state.osdr.topics.find((t) => t.id === topicId);
  if (!topic?.studies.length) return null;
  const s = topic.studies[Math.floor(rng() * topic.studies.length)];
  return {
    accession: s.accession,
    title: s.title,
    url: s.url,
    organism: s.organism,
    mission: s.mission,
    text: s.kidSummary?.reviewedByHuman ? s.kidSummary : null, // solo se muestra texto infantil revisado
    evidenceNote: s.evidenceNote,
  };
}

/** Qué tema OSDR relacionar con cada tipo de efecto de juego. */
export const EFFECT_TO_TOPIC = { radiation: "radiation", "radio-blackout": "radiation", warning: "radiation", comms: "sleep" };
