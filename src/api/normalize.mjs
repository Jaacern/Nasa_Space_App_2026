/**
 * Normalizadores de eventos DONKI -> eventos del juego. Fuente única de verdad:
 * la usan tanto scripts/ingest.mjs (snapshots) como src/api/sources.mjs (modo en vivo).
 * Los valores de 'threat' son una heurística del equipo, NO una escala oficial NASA/NOAA.
 */
import { cleanText, num, isoTime, safeUrl } from "./sanitize.mjs";

const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const round = (x, d = 3) => (x == null || !Number.isFinite(x) ? null : Number(x.toFixed(d)));

// Mapa (heurística del equipo, NO un estándar NASA/NOAA) de evento -> amenaza 0..1.
const FLARE_SCALE = { A: [0.02, 0.02], B: [0.05, 0.05], C: [0.15, 0.15], M: [0.4, 0.25], X: [0.7, 0.3] };

export function flareThreat(cls) {
  const m = /^([ABCMX])(\d+(?:\.\d+)?)?/.exec(cls || "");
  if (!m) return 0.1;
  const [base, span] = FLARE_SCALE[m[1]];
  return clamp(base + (span * Math.min(parseFloat(m[2] ?? "1"), 10)) / 10);
}

export function normCME(e) {
  const analyses = e.cmeAnalyses || [];
  const best = analyses.find((a) => a.isMostAccurate) ?? analyses[0] ?? {};
  let earth = null;
  let mars = null;
  for (const en of analyses.flatMap((a) => a.enlilList || [])) {
    if ((en.isEarthGB || en.isEarthMinorImpact) && en.estimatedShockArrivalTime) earth = en.estimatedShockArrivalTime;
    for (const imp of en.impactList || []) {
      if (imp.location === "Mars") mars = imp.arrivalTime;
      if (imp.location === "Earth") earth = earth ?? imp.arrivalTime;
    }
  }
  const speed = best.speed ?? null;
  return {
    id: e.activityID,
    type: "CME",
    time: e.startTime,
    threat: round(speed == null ? 0.1 : clamp((speed - 300) / 2200, 0.05, 1)),
    gameEffect: "warning", // llega en horas/días: da tiempo para prepararse
    label: {
      es: `Nube de plasma solar (CME)${speed ? ` a ${Math.round(speed)} km/s` : ""}`,
      en: `Coronal mass ejection (CME)${speed ? ` at ${Math.round(speed)} km/s` : ""}`,
    },
    detail: { speedKmS: speed, halfAngleDeg: best.halfAngle ?? null, sourceLocation: e.sourceLocation || null },
    arrivals: { earth, mars },
    link: e.link,
  };
}

export function normFLR(e) {
  return {
    id: e.flrID,
    type: "FLR",
    time: e.peakTime || e.beginTime,
    threat: round(flareThreat(e.classType)),
    gameEffect: "radio-blackout", // los rayos X llegan en ~8 min: casi sin aviso
    label: { es: `Erupción solar clase ${e.classType}`, en: `Solar flare class ${e.classType}` },
    detail: { classType: e.classType, sourceLocation: e.sourceLocation || null },
    arrivals: {},
    link: e.link,
  };
}

export function normGST(e) {
  const kp = Math.max(0, ...(e.allKpIndex || []).map((k) => k.kpIndex));
  const g = kp >= 9 ? 5 : kp >= 8 ? 4 : kp >= 7 ? 3 : kp >= 6 ? 2 : kp >= 5 ? 1 : 0;
  return {
    id: e.gstID,
    type: "GST",
    time: e.startTime,
    threat: round(clamp((kp - 4) / 5)),
    gameEffect: "comms", // tormenta geomagnética: afecta a la Tierra (comunicaciones, redes)
    label: { es: `Tormenta geomagnética G${g} (Kp ${kp})`, en: `Geomagnetic storm G${g} (Kp ${kp})` },
    detail: { kpMax: kp, gScale: g },
    arrivals: {},
    link: e.link,
  };
}

export function normSEP(e) {
  return {
    id: e.sepID,
    type: "SEP",
    time: e.eventTime,
    threat: 0.7, // DONKI no da magnitud aquí; se trata como evento de radiación serio
    gameEffect: "radiation", // protones energéticos: el peligro directo para la tripulación
    label: { es: "Tormenta de protones solares (SEP)", en: "Solar energetic particle event (SEP)" },
    detail: {},
    arrivals: {},
    link: e.link,
  };
}

export function normIPS(e) {
  return {
    id: e.activityID,
    type: "IPS",
    time: e.eventTime,
    threat: 0.3,
    gameEffect: "warning",
    label: { es: "Llegada de un choque interplanetario", en: "Interplanetary shock arrival" },
    detail: { location: e.location || null },
    arrivals: {},
    link: e.link,
  };
}

/** Nivel de dificultad del escenario (idea "difficulty clock" de Risk of Rain 2). */
export function difficultyTier(events) {
  // Umbrales calibrados con las ventanas de abajo: 0 eventos fuertes / pocos / muchos.
  const strong = events.filter((e) => e.threat >= 0.6).length;
  if (strong >= 15) return "monsoon";
  if (strong >= 1) return "rainstorm";
  return "drizzle";
}


const TYPES = new Set(["CME", "FLR", "GST", "SEP", "IPS"]);
const EFFECTS = new Set(["warning", "radio-blackout", "comms", "radiation"]);

function sanitizeDetail(d = {}) {
  const out = {};
  for (const [k, v] of Object.entries(d ?? {})) {
    if (!/^[A-Za-z]{1,24}$/.test(k)) continue;
    out[k] = typeof v === "number" ? num(v) : typeof v === "string" ? cleanText(v, 40) : null;
  }
  return out;
}

/** Deja el evento con campos conocidos y valores válidos. Devuelve null si no es utilizable. */
export function sanitizeEvent(e) {
  if (!e || typeof e !== "object") return null;
  const id = cleanText(e.id, 60);
  const time = isoTime(e.time);
  if (!id || !time || !TYPES.has(e.type)) return null;
  const arrivals = {};
  for (const k of ["earth", "mars"]) if (e.arrivals && k in e.arrivals) arrivals[k] = isoTime(e.arrivals[k]);
  return {
    id,
    type: e.type,
    time,
    threat: num(e.threat, { min: 0, max: 1, digits: 3 }) ?? 0,
    gameEffect: EFFECTS.has(e.gameEffect) ? e.gameEffect : "warning",
    label: { es: cleanText(e.label?.es, 120), en: cleanText(e.label?.en, 120) },
    detail: sanitizeDetail(e.detail),
    arrivals,
    link: safeUrl(e.link),
  };
}
