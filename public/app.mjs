/**
 * CODE OR DIE · PITCH ESPACIAL WEBGL2 EN TIEMPO REAL (NASA SPACE APPS 2026)
 * ==============================================================================
 * Un solo viaje continuo sobre una `THREE.CatmullRomCurve3` con 6 paradas físicas:
 *   01 Pad 39B (Cabo Cañaveral)  → despegue estilo Google Earth desde la superficie
 *   02 Estación LEO              → ISS + Shuttle + Canadarm + Hubble con Earthshine
 *   03 Bennu / JWST / Voyager    → campo de asteroides y clima espacial DONKI
 *   04 Base lunar                → islote de regolito con Apollo y LRO en órbita
 *   05 Órbita de Marte           → planeta PBR con Fobos, Deimos y MGS
 *   06 Cráter Jezero             → islote marciano 2K con HDU, Perseverance e Ingenuity
 * Entre paradas: portales gravitacionales volumétricos 100 % GLSL (sin aros ni marcos).
 *
 * Pipeline de render (estilo UE5): HDRI real + PMREM, MSAA 4x en HalfFloat, ACES,
 * sombras PCF 2048, bloom HDR selectivo y pase óptico (grano, viñeta, aberración).
 * Toda la UI es diegética (hologramas CanvasTexture) o píldoras Aero Glass en esquinas.
 */

import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { RGBELoader } from "three/addons/loaders/RGBELoader.js";
import * as SkeletonUtils from "three/addons/utils/SkeletonUtils.js";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { ShaderPass } from "three/addons/postprocessing/ShaderPass.js";
import { OutputPass } from "three/addons/postprocessing/OutputPass.js";
import { createMission, getSolContext, stepSol } from "../src/sim/run.mjs";
import { loadWorldState } from "../src/data/worldState.mjs";

// ============================================================================
// 0. ESTADO GLOBAL Y UTILIDADES
// ============================================================================
const PREFERS_REDUCED_MOTION = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches ?? false;
// Rutas relativas al propio módulo: funcionan igual en el servidor local y en GitHub Pages.
const ASSETS = new URL("./assets", import.meta.url).href;
const SITE_ROOT = new URL("../", import.meta.url);
const siteUrl = (path) => new URL(path, SITE_ROOT).href;
const MODELS = `${ASSETS}/models`;
const TEX = `${ASSETS}/textures`;

let useLiveMode = false;
let world = null;
let balance = null;
let cardsData = null;
let glossary = null;
let sourceCatalog = [];
let currentMission = null;

let selectedCardId = null;
let selectedPowerMode = "normal";
let selectedUseShelter = false;
let siteTouchedByUser = false;

/** Puente UI → motor 3D (se rellena en initEngine). */
const engine = {
  goToStop: null,
  startLaunch: null,
  syncOutpost: null,
  getStopIndex: () => 0,
};

const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
const clamp01 = (v) => Math.max(0, Math.min(1, v));
const lerp = (a, b, t) => a + (b - a) * t;
const easeInOut = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
const easeOut = (t) => 1 - Math.pow(1 - t, 3);
const fmt = (n, d = 2) => Number(n).toLocaleString("es-CL", { minimumFractionDigits: d, maximumFractionDigits: d });

// ============================================================================
// 1. DATOS NASA / CSA (API local saneada, con copia curada sin red)
// ============================================================================
let apiAvailable = true;
async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status} en ${url}`);
  return res.json();
}
async function loadAllData() {
  const q = useLiveMode ? "?live=1" : "";
  // Con servidor local se usa la API saneada; en hosting estático (GitHub Pages) o sin red
  // se cae a la copia curada de data/curated/ sin interrumpir el pitch.
  const apiRoutes = {
    "space_weather.json": `api/space-weather${q}`,
    "radiation.json": "api/radiation",
    "mars_layers.json": "api/mars-layers",
    "manifest.json": "api/manifest",
    "mars_weather.json": `api/mars-weather${q}`,
    "rover_photos.json": `api/rover-photos${q}`,
    "csa_resources.json": `api/csa${q}`,
    "apod.json": `api/apod${q}`,
  };
  const reader = async (file) => {
    if (apiAvailable && apiRoutes[file]) {
      try {
        return await fetchJson(siteUrl(apiRoutes[file]));
      } catch {
        apiAvailable = false;
      }
    }
    return fetchJson(siteUrl(`data/curated/${file}`));
  };

  const [w, balRes, cardsRes, glosRes] = await Promise.all([
    loadWorldState(reader),
    fetchJson(siteUrl("content/balance.json")),
    fetchJson(siteUrl("content/cards.json")),
    fetchJson(siteUrl("content/glossary.json")),
  ]);
  world = w;
  balance = balRes;
  cardsData = cardsRes;
  glossary = glosRes;
  sourceCatalog = apiAvailable ? await fetchJson(siteUrl("api/catalog")).then((j) => j.sources || []).catch(() => []) : [];

  updateModeIndicator(world?.spaceWeather?.meta?.mode === "live" ? "live" : "snapshot");
  renderKidGlossaryStrip();
  renderSourcesList();
}

function updateModeIndicator(mode) {
  const chip = document.getElementById("btn-data-mode");
  const label = document.getElementById("data-mode-label");
  if (!chip || !label) return;
  const isLive = mode === "live";
  chip.classList.toggle("live", isLive);
  chip.classList.toggle("snapshot", !isLive);
  label.textContent = isLive ? "LIVE NASA API" : "SNAPSHOT";
}

/** Lecturas reales (RadLab, DONKI, InSight) con respaldo a los valores publicados. */
function telemetryFacts() {
  const rad = world?.radiation;
  const site = (id) => rad?.sites?.find((s) => s.id === id)?.instruments?.[0]?.absorbedDoseRate;
  const iss = site("leo-iss");
  const lro = site("moon-orbit-lro");
  const artemis = site("moon-orion-artemis1");
  const liulin = site("mars-orbit-liulin");
  const ratios = rad?.ratiosToLeoIss ?? {};
  const scenarios = world?.scenarios?.scenarios ?? [];
  const donkiTotal = scenarios.reduce((a, s) => a + (s.events?.length || 0), 0) || 386;
  const gannon = scenarios.find((s) => s.id === "gannon-2024-05");
  const live = world?.spaceWeather;
  const sol = world?.marsWeather?.sols?.at(-1);
  return {
    issDose: iss?.mean ?? 4.195,
    issP50: iss?.p50 ?? 3.587,
    lroDose: lro?.mean ?? 12.721,
    lroRatio: ratios["moon-orbit-lro"] ?? 3.03,
    artemisDose: artemis?.mean ?? 16.344,
    liulinDose: liulin?.mean ?? 15.231,
    liulinRatio: ratios["mars-orbit-liulin"] ?? 3.63,
    donkiTotal,
    gannonEvents: gannon?.events?.length ?? 163,
    liveEvents: live?.events?.length ?? 104,
    liveCme: live?.summary?.counts?.CME ?? 88,
    liveFlr: live?.summary?.counts?.FLR ?? 13,
    marsTemp: sol?.tempC?.avg ?? -62.4,
    marsTempMin: sol?.tempC?.min ?? -95.4,
    marsPressure: sol?.pressurePa?.avg ?? 743.5,
    marsWindMax: 27,
    marsSol: sol?.sol ?? 681,
  };
}

// ============================================================================
// 2. LAS 6 PARADAS: TÍTULOS, TELEMETRÍA DEL HUD Y TABLEROS HOLOGRÁFICOS (ES)
// ============================================================================
/** Tripulación CODE OR DIE: etiquetas exactas de los astronautas y créditos del HUD. */
const TEAM = [
  { key: "javier", name: "JAVIER", role: "Estudiante Ingeniería Informática" },
  { key: "gonzalo", name: "GONZALO", role: "Psicólogo" },
  { key: "cristobal", name: "CRISTÓBAL", role: "Estudiante" },
];
// Cada tablero: un párrafo breve + 3 viñetas escaneables (aprendizaje incidental, sin jerga técnica).
const STOPS = [
  {
    id: "pad39b",
    short: "CONTEXTO",
    title: "01 · CONTEXTO Y EQUIPO (Cabo Cañaveral · Pad 39B)",
    color: 0x38bdf8,
    window: "00:00–00:15",
    hud: () => "DESAFÍO NASA SPACE APPS 2026 · KENNEDY SPACE CENTER PAD 39B",
    board: () => ({
      eyebrow: "01 · CONTEXTO Y EQUIPO",
      place: "CABO CAÑAVERAL · PAD 39B",
      title: "CODE OR DIE · Entrenador Espacial",
      intro: "En los últimos años ha caído el interés infantil por la lectura y la ciencia tradicional. Transformamos el desafío Junior Astronaut Mission Trainer en un videojuego interactivo en Roblox para niños de 7 a 12 años.",
      bullets: [
        "Alcance real: Roblox conecta con más de 85 millones de usuarios diarios (40 % menores de 13 años).",
        "Equipo: Javier (Estudiante Ingeniería Informática), Gonzalo (Psicólogo) y Cristóbal (Estudiante).",
        "Propósito: Convertir ciencia real de la NASA en exploración viva y significativa.",
      ],
      footer: "DESAFÍO NASA SPACE APPS 2026 · KENNEDY SPACE CENTER PAD 39B",
    }),
  },
  {
    id: "leo",
    short: "EL PROBLEMA",
    title: "02 · EL PROBLEMA (Órbita Baja Terrestre · ISS)",
    color: 0x60a5fa,
    window: "00:15–00:30",
    hud: () => "FUENTE REAL: NASA RADLAB & OSDR (ESTACIÓN ESPACIAL INTERNACIONAL)",
    board: () => ({
      eyebrow: "02 · EL PROBLEMA",
      place: "ÓRBITA BAJA TERRESTRE · ISS",
      title: "Por qué fallan los métodos tradicionales",
      intro: "Los libros y carteles presentan datos abstractos que aburren, mientras los juegos espaciales comunes ocultan las verdaderas leyes físicas que mantienen viva a una tripulación.",
      bullets: [
        "Brecha de atención: Sin interacción ni consecuencias, los niños desconectan de la lectura científica.",
        "Ficción sin criterio: Simplificar el espacio impide comprender los riesgos reales de una misión.",
        "Dato real NASA (RadLab ISS): A 400 km de altura, la radiación base sube a 4.20 µGy/h.",
      ],
      footer: "FUENTE REAL: NASA RADLAB & OSDR (ESTACIÓN ESPACIAL INTERNACIONAL)",
    }),
  },
  {
    id: "deep",
    short: "APRENDIZAJE",
    title: "03 · APRENDIZAJE INCIDENTAL (Espacio Profundo · Bennu & JWST)",
    color: 0xf59e0b,
    window: "00:30–00:45",
    hud: () => "FUENTE REAL: API NASA DONKI & MISIÓN OSIRIS-REX (BENNU)",
    board: () => ({
      eyebrow: "03 · APRENDIZAJE INCIDENTAL",
      place: "ESPACIO PROFUNDO · BENNU & JWST",
      title: "Aprender jugando de forma implícita",
      intro: "Aplicamos el aprendizaje incidental o implícito: los niños absorben vocabulario científico, pensamiento crítico y datos reales de manera indirecta mediante recursos audiovisuales y juego activo.",
      bullets: [
        "Diseño cognitivo (Gonzalo): Cero muros de texto; el conocimiento se integra en la acción.",
        "Causa y efecto real: Ahorrar energía hoy puede costar reservas de oxígeno mañana.",
        "Clima espacial vivo: Tormentas solares reales (API NASA DONKI) obligan a decidir en segundos.",
      ],
      footer: "FUENTE REAL: API NASA DONKI & MISIÓN OSIRIS-REX (BENNU)",
    }),
  },
  {
    id: "moon",
    short: "SOLUCIÓN",
    title: "04 · NUESTRA SOLUCIÓN (Base Lunar · Mare Tranquillitatis)",
    color: 0xe2e8f0,
    window: "00:45–01:00",
    hud: () => "FUENTE REAL: NASA ARTEMIS & LRO CRaTER (13.72 µGy/h)",
    board: () => ({
      eyebrow: "04 · NUESTRA SOLUCIÓN",
      place: "BASE LUNAR · MARE TRANQUILLITATIS",
      title: "Simulador de Misión en Roblox",
      intro: "Creamos un puesto avanzado interactivo alimentado por mediciones oficiales de la NASA, donde cada decisión de ingeniería transforma la supervivencia del equipo.",
      bullets: [
        "Equilibrio de 3 pilares: Gestiona Energía, Soporte Vital y Blindaje sin abrumar al jugador.",
        "Entorno lunar auténtico: En la Luna la radiación sube a 13.72 µGy/h (3.3× la órbita terrestre).",
        "Experimentación segura: Equivocarse enseña física real y motiva a probar nuevas estrategias.",
      ],
      footer: "FUENTE REAL: NASA ARTEMIS & LRO CRaTER (13.72 µGy/h)",
    }),
  },
  {
    id: "marsorbit",
    short: "DESAFÍO MARTE",
    title: "05 · DESAFÍO EN MARTE (Órbita de Marte · Fobos y Deimos)",
    color: 0xfb923c,
    window: "01:00–01:15",
    hud: () => "FUENTE REAL: MARS RECONNAISSANCE ORBITER & MGS MOLA",
    board: () => ({
      eyebrow: "05 · DESAFÍO EN MARTE",
      place: "ÓRBITA DE MARTE · FOBOS Y DEIMOS",
      title: "Aislamiento extremo a millones de km",
      intro: "En el espacio profundo no existe rescate inmediato desde la Tierra: la anticipación y el criterio científico del jugador son el único soporte vital de la base.",
      bullets: [
        "Retraso real de señal: Las comunicaciones con la Tierra tardan entre 3 y 22 minutos.",
        "Radiación triplicada: En Marte la exposición alcanza 15.23 µGy/h (3.63× la ISS).",
        "Ciencia comprensible: Cada concepto técnico se vive en contexto, sin jerga innecesaria.",
      ],
      footer: "FUENTE REAL: MARS RECONNAISSANCE ORBITER & MGS MOLA",
    }),
  },
  {
    id: "jezero",
    short: "EVIDENCIA",
    title: "06 · EVIDENCIA Y AGRADECIMIENTOS (Cráter Jezero · Marte)",
    color: 0xfc3d21,
    window: "01:15–01:30",
    hud: () => "GRACIAS · NASA INSIGHT, PERSEVERANCE & INGENUITY",
    board: () => ({
      eyebrow: "06 · EVIDENCIA Y AGRADECIMIENTOS",
      place: "CRÁTER JEZERO · MARTE",
      title: "30 soles de ciencia real · Gracias",
      intro: "Nuestro prototipo demuestra cómo datos reales de Marte entrenan a futuros exploradores. ¡Muchas gracias al jurado y mentores de NASA Space Apps Challenge 2026!",
      bullets: [
        "Tormentas marcianas: Vientos reales de 27 m/s (InSight) cubren los paneles y reducen energía.",
        "Agradecimientos: A NASA Space Apps, nuestras familias y comunidad educativa por impulsar la ciencia.",
        "Equipo CODE OR DIE: Javier, Gonzalo y Cristóbal — listos para el demo en vivo.",
      ],
      footer: "GRACIAS · NASA INSIGHT, PERSEVERANCE & INGENUITY",
    }),
  },
];

// ============================================================================
// 3. SHADERS GLSL PROPIOS
// ============================================================================
const GLSL_NOISE = `
  float hash12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
  float vnoise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
  }
  float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * vnoise(p); p = p * 2.03 + vec2(17.1, 9.7); a *= 0.5; } return v; }
`;

/* --- Tierra: océano con glint solar, luces de ciudad nocturnas, crepúsculo y borde Fresnel --- */
const EARTH_VERT = `
  varying vec2 vUv; varying vec3 vNormalW; varying vec3 vPosW;
  void main() {
    vUv = uv;
    vNormalW = normalize(mat3(modelMatrix) * normal);
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vPosW = wp.xyz;
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;
const EARTH_FRAG = `
  uniform sampler2D uDay; uniform vec3 uSunDir; uniform float uTime;
  varying vec2 vUv; varying vec3 vNormalW; varying vec3 vPosW;
  ${GLSL_NOISE}
  void main() {
    vec3 N = normalize(vNormalW);
    vec3 L = normalize(uSunDir);
    vec3 V = normalize(cameraPosition - vPosW);
    float NdL = dot(N, L);
    vec3 albedo = texture2D(uDay, vUv).rgb;
    float ocean = clamp((albedo.b - max(albedo.r, albedo.g)) * 9.0, 0.0, 1.0);
    float land = 1.0 - ocean;

    float dayLight = max(NdL, 0.0);
    vec3 col = albedo * (0.012 + 1.35 * dayLight);

    // Glint especular del Sol sobre el océano
    vec3 H = normalize(L + V);
    float spec = pow(max(dot(N, H), 0.0), 220.0) * ocean * smoothstep(0.0, 0.18, NdL);
    col += vec3(1.0, 0.95, 0.82) * spec * 2.4;
    float sheen = pow(max(dot(N, H), 0.0), 14.0) * ocean * smoothstep(0.0, 0.25, NdL);
    col += vec3(0.55, 0.7, 0.9) * sheen * 0.18;

    // Crepúsculo cálido en el terminador
    float twilight = exp(-pow((NdL - 0.03) / 0.11, 2.0));
    col += vec3(0.95, 0.5, 0.18) * twilight * 0.14;

    // Luces de ciudad: cúmulos sobre tierra firme, solo en el lado nocturno
    float lum = dot(albedo, vec3(0.3, 0.59, 0.11));
    float density = fbm(vUv * vec2(26.0, 13.0) + 3.1);
    float detail = fbm(vUv * vec2(300.0, 150.0));
    float cities = smoothstep(0.58, 0.88, detail) * smoothstep(0.42, 0.7, density) * land * smoothstep(0.05, 0.22, lum);
    float night = 1.0 - smoothstep(-0.2, 0.04, NdL);
    col += vec3(1.0, 0.78, 0.46) * cities * night * 2.6;
    col += albedo * 0.02 * night;

    // Borde Fresnel atmosférico (Rayleigh) integrado a la superficie
    float fres = pow(1.0 - max(dot(N, V), 0.0), 3.2);
    col += vec3(0.28, 0.58, 1.0) * fres * (0.18 + 0.82 * smoothstep(-0.1, 0.3, NdL)) * 0.9;
    gl_FragColor = vec4(col, 1.0);
  }
`;

/* --- Nubes a la deriva (fbm animado, iluminación solar). Se abren sobre el complejo de lanzamiento --- */
const CLOUD_FRAG = `
  uniform vec3 uSunDir; uniform float uTime; uniform vec3 uPadPos;
  varying vec2 vUv; varying vec3 vNormalW; varying vec3 vPosW;
  ${GLSL_NOISE}
  void main() {
    vec3 N = normalize(vNormalW);
    float NdL = dot(N, normalize(uSunDir));
    vec2 p = vUv * vec2(9.0, 4.5) + vec2(uTime * 0.0045, 0.0);
    float n = fbm(p) * 0.65 + fbm(p * 2.7 + 11.0) * 0.35;
    float cloud = smoothstep(0.5, 0.76, n);
    float lit = 0.015 + 1.25 * max(NdL, 0.0);
    vec3 col = vec3(1.0, 0.98, 0.96) * lit;
    float clearSky = smoothstep(9.0, 17.0, distance(vPosW, uPadPos));
    gl_FragColor = vec4(col, cloud * 0.9 * clearSky);
  }
`;

/* --- Atmósfera: borde Fresnel fino. El brillo crece hacia el limbo y se desvanece
       hasta cero en la silueta de la concha, así nunca se dibuja un aro sólido. --- */
const ATMO_VERT = `
  varying vec3 vNormalW; varying vec3 vPosW;
  void main() {
    vNormalW = normalize(mat3(modelMatrix) * normal);
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vPosW = wp.xyz;
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;
const ATMO_FRAG = `
  uniform vec3 uSunDir; uniform vec3 uDayColor; uniform vec3 uNightColor;
  uniform float uPower; uniform float uFalloff; uniform float uStrength; uniform float uLimb;
  varying vec3 vNormalW; varying vec3 vPosW;
  void main() {
    vec3 N = normalize(vNormalW);
    vec3 V = normalize(cameraPosition - vPosW);
    vec3 L = normalize(uSunDir);
    float f = 1.0 - clamp(abs(dot(N, V)), 0.0, 1.0);
    float inner = pow(clamp(f / uLimb, 0.0, 1.0), uPower);
    float outer = pow(clamp((1.0 - f) / (1.0 - uLimb), 0.0, 1.0), uFalloff);
    float rim = f < uLimb ? inner : outer;
    float lit = smoothstep(-0.35, 0.5, dot(N, L));
    vec3 col = mix(uNightColor, uDayColor, lit);
    col += vec3(1.0, 0.86, 0.64) * pow(max(dot(-V, L), 0.0), 12.0) * 0.5 * lit;
    gl_FragColor = vec4(col * rim * uStrength, 1.0);
  }
`;

/* --- Corona solar óptica (billboard aditivo) --- */
const SUN_FRAG = `
  uniform float uTime;
  varying vec2 vUv;
  ${GLSL_NOISE}
  void main() {
    vec2 d = vUv - 0.5;
    float r = length(d) * 2.0;
    float a = atan(d.y, d.x);
    float disc = 1.0 - smoothstep(0.045, 0.075, r);
    float glow = exp(-r * 7.5) * 1.6 + exp(-r * 2.2) * 0.35;
    float rays = pow(max(0.0, fbm(vec2(a * 3.2, r * 2.0 + uTime * 0.03))), 2.2) * exp(-r * 4.0) * 0.9;
    float streak = (exp(-pow(d.y * 120.0, 2.0)) + exp(-pow(d.x * 120.0, 2.0))) * exp(-r * 3.0) * 0.35;
    vec3 col = vec3(1.0, 0.97, 0.9) * (disc * 6.0 + glow) + vec3(1.0, 0.82, 0.55) * (rays + streak);
    float alpha = clamp(disc + glow + rays + streak, 0.0, 1.0) * (1.0 - smoothstep(0.85, 1.0, r));
    gl_FragColor = vec4(col, alpha);
  }
`;

/* --- Portal gravitacional volumétrico: vórtice de nebulosa en capas con paralaje,
       filamentos aditivos y borde 100% suave. Sin aros mecánicos ni marcos cuadrados. --- */
const PORTAL_FRAG = `
  uniform float uTime; uniform float uIntensity; uniform float uLayer; uniform vec3 uColorA; uniform vec3 uColorB;
  varying vec2 vUv;
  ${GLSL_NOISE}
  void main() {
    vec2 d = (vUv - 0.5) * 2.0;
    float r = length(d);
    if (r > 1.0) discard;
    float ang = atan(d.y, d.x);
    float spin = uTime * (0.5 + uLayer * 0.16) * (mod(uLayer, 2.0) < 0.5 ? 1.0 : -0.7);
    float twist = ang + spin + (2.4 + uLayer * 0.5) / (r + 0.22) + uLayer * 1.9;
    vec2 sw = vec2(cos(twist), sin(twist)) * r;
    float filA = fbm(sw * 3.1 + vec2(uTime * 0.14, -uTime * 0.1) + uLayer * 7.3);
    float filB = fbm(sw * 7.7 - vec2(uTime * 0.22, uTime * 0.08) + uLayer * 3.1);
    float filaments = smoothstep(0.4, 0.82, filA) * 0.95 + smoothstep(0.54, 0.92, filB) * 0.5;
    float vortex = exp(-pow((r - 0.3) / 0.34, 2.0)) * (0.6 + 0.4 * sin(ang * 3.0 + spin * 2.4 + r * 9.0));
    float core = exp(-pow(r / 0.2, 2.0)) * (uLayer < 0.5 ? 1.5 : 0.25);
    float fade = pow(max(1.0 - smoothstep(0.18, 1.0, r), 0.0), 1.35);
    vec3 col = mix(uColorB, uColorA, smoothstep(0.1, 0.8, r)) * (filaments * 0.9 + vortex * 0.5 + 0.05);
    col += vec3(0.82, 0.92, 1.0) * vortex * 0.4;
    col += vec3(0.96, 0.99, 1.0) * core;
    float layerGain = 1.0 / (1.0 + uLayer * 0.55);
    gl_FragColor = vec4(col * fade * uIntensity * layerGain, 1.0);
  }
`;

/* --- Halo difuso de la galaxia espiral: mismos brazos logarítmicos que sus 26 000 estrellas --- */
const GALAXY_FRAG = `
  uniform float uTime; uniform vec3 uColorA; uniform vec3 uColorB; uniform vec3 uColorC;
  varying vec2 vUv;
  ${GLSL_NOISE}
  void main() {
    vec2 d = (vUv - 0.5) * 2.6;
    float r = length(d);
    if (r > 1.3) discard;
    float ang = atan(-d.y, d.x);
    float rn = clamp((r - 0.1) / 0.9, 0.0, 1.0);
    float phase = ang - log(1.0 + rn * 5.0) * 3.4;
    float arms = pow(max(cos(2.0 * phase) * 0.5 + 0.5, 0.0), 1.7);
    float minor = pow(max(cos(2.0 * phase + 3.14159) * 0.5 + 0.5, 0.0), 4.0) * 0.28;
    float clouds = fbm(d * 4.2 + 3.0);
    float dust = fbm(d * 11.0 - 7.0);
    float disc = 1.0 - smoothstep(0.2, 1.08, r);
    float band = (arms + minor) * (0.35 + 0.65 * clouds) * disc * smoothstep(0.05, 0.22, r);
    float lanes = smoothstep(0.48, 0.78, dust) * arms;
    float core = exp(-r * 9.0) * 1.5 + exp(-r * 3.2) * 0.3;
    vec3 col = mix(uColorB, uColorA, smoothstep(0.1, 0.85, r)) * band * (1.0 - lanes * 0.65) * 0.5;
    col += uColorC * core;
    gl_FragColor = vec4(col, 1.0);
  }
`;

/* --- Nebulosa de emisión: fbm deformado, dos gases y caída radial suave --- */
const NEBULA_FRAG = `
  uniform float uTime; uniform vec3 uColorA; uniform vec3 uColorB; uniform float uSeed; uniform float uGain;
  varying vec2 vUv;
  ${GLSL_NOISE}
  void main() {
    vec2 d = (vUv - 0.5) * 2.0;
    float r = length(d);
    if (r > 1.0) discard;
    vec2 q = d * 2.2 + uSeed;
    vec2 warp = vec2(fbm(q + vec2(0.0, uTime * 0.006)), fbm(q + vec2(5.2, 1.3 - uTime * 0.004)));
    float n = fbm(q * 1.4 + warp * 1.8);
    float wisps = smoothstep(0.4, 0.88, n);
    float fil = smoothstep(0.56, 0.9, fbm(q * 3.6 + warp * 2.6)) * 0.55;
    float fade = pow(max(1.0 - smoothstep(0.05, 1.0, r), 0.0), 1.7);
    vec3 col = mix(uColorA, uColorB, smoothstep(0.3, 0.75, fbm(q * 0.9 + 9.0))) * (wisps + fil) * fade * uGain;
    gl_FragColor = vec4(col, 1.0);
  }
`;

/* --- Gigante gaseoso: bandas zonales turbulentas, Gran Mancha Roja y sombra de anillos --- */
const GIANT_FRAG = `
  uniform vec3 uSunDir; uniform float uTime; uniform vec3 uBandA; uniform vec3 uBandB; uniform vec3 uBandC;
  uniform float uBands; uniform float uSpot; uniform float uSeed;
  uniform vec3 uCenter; uniform float uRadius; uniform vec3 uRingNormal; uniform float uRingInner; uniform float uRingOuter;
  varying vec2 vUv; varying vec3 vNormalW; varying vec3 vPosW;
  ${GLSL_NOISE}
  void main() {
    vec3 N = normalize(vNormalW);
    vec3 L = normalize(uSunDir);
    vec3 V = normalize(cameraPosition - vPosW);
    float lat = vUv.y, lon = vUv.x;
    float turb = fbm(vec2(lon * 14.0 + uTime * 0.004, lat * uBands * 1.3 + uSeed)) - 0.5;
    float turb2 = fbm(vec2(lon * 46.0 - uTime * 0.006, lat * uBands * 4.0 + uSeed * 2.0)) - 0.5;
    float y = lat + turb * 0.035 + turb2 * 0.009;
    float band = sin(y * uBands * 6.2831) * 0.5 + 0.5;
    float band2 = sin(y * uBands * 2.3 * 6.2831 + 1.7) * 0.5 + 0.5;
    vec3 col = mix(uBandA, uBandB, smoothstep(0.25, 0.75, band));
    col = mix(col, uBandC, smoothstep(0.55, 0.95, band2) * 0.45);
    col *= 0.86 + 0.28 * fbm(vec2(lon * 90.0, lat * 60.0 + uSeed));
    vec2 sd = vec2((lon - 0.3) * 9.0, (lat - 0.36) * 16.0);
    col = mix(col, vec3(0.72, 0.3, 0.18), uSpot * exp(-dot(sd, sd) * 1.6) * 0.85);
    float NdL = dot(N, L);
    float diffuse = smoothstep(-0.08, 0.55, NdL);
    float NdV = max(dot(N, V), 0.0);
    col *= (0.015 + 1.2 * diffuse) * mix(0.5, 1.0, pow(NdV, 0.5));
    col += uBandA * 0.22 * pow(1.0 - NdV, 4.0) * diffuse;
    if (uRingOuter > 0.0) {
      vec3 P = vPosW - uCenter;
      float denom = dot(L, uRingNormal);
      float tt = -dot(P, uRingNormal) / (abs(denom) < 1e-4 ? 1e-4 : denom);
      if (tt > 0.0) {
        float rr = length(P + L * tt) / uRadius;
        float inRing = smoothstep(uRingInner, uRingInner + 0.08, rr) * (1.0 - smoothstep(uRingOuter - 0.08, uRingOuter, rr));
        col *= 1.0 - 0.55 * inRing;
      }
    }
    gl_FragColor = vec4(col, 1.0);
  }
`;

/* --- Anillos de Saturno: C tenue, B denso, división de Cassini, anillo A y sombra del planeta --- */
const RING_FRAG = `
  uniform vec3 uSunDir; uniform vec3 uCenter; uniform float uPlanetR; uniform float uInner; uniform float uOuter; uniform vec3 uColor;
  varying vec2 vUv; varying vec3 vNormalW; varying vec3 vPosW;
  ${GLSL_NOISE}
  void main() {
    vec3 P = vPosW - uCenter;
    float x = (length(P) - uInner) / (uOuter - uInner);
    if (x < 0.0 || x > 1.0) discard;
    float dens = (0.55 + 0.45 * vnoise(vec2(x * 46.0, 0.5))) * (0.7 + 0.3 * vnoise(vec2(x * 190.0, 3.7)));
    float edges = smoothstep(0.0, 0.05, x) * (1.0 - smoothstep(0.95, 1.0, x));
    float cRing = mix(0.22, 1.0, smoothstep(0.16, 0.24, x));
    float cassini = 1.0 - smoothstep(0.6, 0.625, x) * (1.0 - smoothstep(0.665, 0.69, x));
    float a = dens * edges * cRing * cassini;
    vec3 L = normalize(uSunDir);
    float b = dot(P, L);
    float shadow = (b < 0.0 && dot(P, P) - b * b < uPlanetR * uPlanetR) ? 0.1 : 1.0;
    vec3 col = uColor * (0.75 + 0.35 * vnoise(vec2(x * 23.0, 9.1))) * shadow * 1.1;
    gl_FragColor = vec4(col, a * 0.92);
  }
`;

/* --- Cono de proyección del holograma: del astronauta a las 4 esquinas de la pantalla --- */
const BEAM_FRAG = `
  uniform float uTime; uniform vec3 uColor; uniform float uOpacity;
  varying vec2 vUv;
  void main() {
    float along = clamp(vUv.y, 0.0, 1.0);
    float scan = 0.7 + 0.3 * sin(along * 64.0 - uTime * 5.0);
    float a = mix(0.6, 0.05, pow(along, 0.55)) * scan;
    gl_FragColor = vec4(uColor * a * uOpacity, 1.0);
  }
`;
/* --- Pluma del cohete con diamantes de Mach --- */
const PLUME_VERT = `
  uniform float uIntensity;
  varying vec2 vUv;
  void main() {
    vUv = uv;
    vec3 p = position;
    p.y = -1.0 + (p.y + 1.0) * mix(0.22, 1.0, uIntensity);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
  }
`;
const PLUME_FRAG = `
  uniform float uTime; uniform float uIntensity;
  varying vec2 vUv;
  ${GLSL_NOISE}
  void main() {
    float along = vUv.y;
    float across = abs(vUv.x - 0.5) * 2.0;
    float turb = (vnoise(vec2(vUv.x * 8.0, along * 14.0 - uTime * 34.0)) - 0.5) * 0.26 * along;
    float width = mix(0.26, 0.95, pow(along, 0.62));
    float rd = (across + turb) / width;
    if (rd > 1.0) discard;
    float mach = pow(max(0.0, cos(along * 28.0 - uTime * 40.0)), 5.0) * (1.0 - along * 0.8);
    float core = exp(-rd * rd * 4.4) * (1.0 - pow(along, 1.3));
    float outer = pow(1.0 - rd, 1.9) * (1.0 - pow(along, 0.9));
    vec3 white = vec3(1.0, 0.98, 0.93);
    vec3 amber = vec3(1.0, 0.55, 0.12);
    vec3 cyan = vec3(0.1, 0.72, 1.0);
    vec3 col = mix(cyan, amber, smoothstep(0.12, 0.65, core + mach * 0.4));
    col = mix(col, white, smoothstep(0.5, 0.95, core + mach * 0.7));
    float alpha = clamp((outer * 0.8 + core * 1.25 + mach * 0.5) * smoothstep(0.0, 0.08, along), 0.0, 1.0) * uIntensity;
    gl_FragColor = vec4(col * (1.9 + mach * 1.4), alpha);
  }
`;

/* --- Tablero holográfico: textura canvas + scanlines + parpadeo + borde suave --- */
const HOLO_FRAG = `
  uniform sampler2D uMap; uniform float uTime; uniform float uOpacity; uniform vec3 uTint;
  varying vec2 vUv;
  void main() {
    vec4 t = texture2D(uMap, vUv);
    float scan = 0.94 + 0.06 * sin(vUv.y * 560.0 + uTime * 5.0);
    float flicker = 0.975 + 0.025 * sin(uTime * 21.0) * sin(uTime * 6.3);
    float edge = smoothstep(0.0, 0.035, vUv.x) * smoothstep(1.0, 0.965, vUv.x) * smoothstep(0.0, 0.035, vUv.y) * smoothstep(1.0, 0.965, vUv.y);
    vec3 col = (t.rgb * 1.3 + uTint * 0.03) * scan * flicker;
    float alpha = t.a * edge * uOpacity;
    gl_FragColor = vec4(col, alpha);
  }
`;

/* --- Estelas de estrellas al cruzar un portal (segmentos que se estiran en Z de cámara) --- */
const STREAK_VERT = `
  attribute float aEnd; attribute float aSeed;
  uniform float uWarp; uniform float uTime;
  varying float vAlpha;
  void main() {
    vec3 p = position;
    float speed = 18.0 + aSeed * 30.0;
    p.z += aEnd * uWarp * speed;
    p.z = mod(p.z + uTime * 40.0 * uWarp + aSeed * 90.0, 140.0) - 150.0;
    vAlpha = (1.0 - aEnd * 0.85) * uWarp;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
  }
`;
const STREAK_FRAG = `
  varying float vAlpha;
  void main() { gl_FragColor = vec4(0.75, 0.88, 1.0, vAlpha * 0.9); }
`;

/* --- Partículas suaves (humo criogénico, chispas) --- */
const PARTICLE_VERT = `
  attribute float aSize; attribute float aLife; attribute vec3 aColor;
  varying float vLife; varying vec3 vColor;
  void main() {
    vLife = aLife; vColor = aColor;
    vec4 mv = modelViewMatrix * vec4(position, 1.0);
    gl_PointSize = aSize * (300.0 / -mv.z);
    gl_Position = projectionMatrix * mv;
  }
`;
const PARTICLE_FRAG = `
  uniform float uOpacity;
  varying float vLife; varying vec3 vColor;
  void main() {
    float d = length(gl_PointCoord - 0.5) * 2.0;
    float a = smoothstep(1.0, 0.1, d) * vLife * uOpacity;
    if (a < 0.002) discard;
    gl_FragColor = vec4(vColor, a);
  }
`;

/* --- Pase óptico de cine: grano ultrafino, viñeta y aberración cromática ligada a la velocidad --- */
const CINEMA_FRAG = `
  uniform sampler2D tDiffuse; uniform float uTime; uniform float uGrain; uniform float uVignette; uniform float uAberration;
  varying vec2 vUv;
  float hash(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
  void main() {
    vec2 d = vUv - 0.5;
    float r2 = dot(d, d);
    vec3 col;
    float k = uAberration * (0.25 + r2 * 3.0);
    col.r = texture2D(tDiffuse, vUv + d * k).r;
    col.g = texture2D(tDiffuse, vUv).g;
    col.b = texture2D(tDiffuse, vUv - d * k).b;
    col *= 1.0 - uVignette * smoothstep(0.18, 1.0, r2 * 2.6);
    float g = hash(vUv * vec2(1920.0, 1080.0) + fract(uTime * 7.0) * vec2(31.7, 17.3)) - 0.5;
    col += g * uGrain * (0.35 + 0.65 * clamp(1.0 - dot(col, vec3(0.333)), 0.0, 1.0));
    gl_FragColor = vec4(col, 1.0);
  }
`;
const BASIC_UV_VERT = `
  varying vec2 vUv;
  void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }
`;

// ============================================================================
// 4. MOTOR 3D
// ============================================================================
function initEngine() {
  const canvas = document.getElementById("webgl-canvas");
  const container = document.getElementById("webgl-container");
  if (!canvas) return;

  // ---- 4.1 Renderer y pipeline de post-proceso (MSAA 4x HalfFloat → Bloom HDR → Cine → ACES) ----
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: false, alpha: false, powerPreference: "high-performance", stencil: false });
  const pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
  renderer.setPixelRatio(pixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.08;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.setClearColor(0x020408, 1);
  const maxAniso = renderer.capabilities.getMaxAnisotropy();

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(46 /* = BASE_FOV */, window.innerWidth / window.innerHeight, 0.1, 4000);
  scene.add(camera);

  const msaaTarget = new THREE.WebGLRenderTarget(window.innerWidth * pixelRatio, window.innerHeight * pixelRatio, {
    type: THREE.HalfFloatType,
    samples: 4,
    depthBuffer: true,
  });
  const composer = new EffectComposer(renderer, msaaTarget);
  composer.setPixelRatio(pixelRatio);
  composer.setSize(window.innerWidth, window.innerHeight);
  composer.addPass(new RenderPass(scene, camera));
  const bloomPass = new UnrealBloomPass(new THREE.Vector2(window.innerWidth, window.innerHeight), 0.42, 0.65, 1.18);
  composer.addPass(bloomPass);
  const cinemaPass = new ShaderPass(
    new THREE.ShaderMaterial({
      uniforms: {
        tDiffuse: { value: null },
        uTime: { value: 0 },
        uGrain: { value: PREFERS_REDUCED_MOTION ? 0.0 : 0.028 },
        uVignette: { value: 0.3 },
        uAberration: { value: 0.0 },
      },
      vertexShader: BASIC_UV_VERT,
      fragmentShader: CINEMA_FRAG,
    }),
  );
  composer.addPass(cinemaPass);
  composer.addPass(new OutputPass());

  // ---- 4.2 Iluminación: Sol duro cálido (key), rebote terrestre cian (rim), relleno mínimo ----
  const SUN_DIR = new THREE.Vector3(0.82, 0.36, 0.44).normalize();
  const sunLight = new THREE.DirectionalLight(0xfff1dc, 3.3);
  sunLight.castShadow = true;
  sunLight.shadow.mapSize.set(2048, 2048);
  sunLight.shadow.camera.near = 1;
  sunLight.shadow.camera.far = 260;
  sunLight.shadow.camera.left = sunLight.shadow.camera.bottom = -30;
  sunLight.shadow.camera.right = sunLight.shadow.camera.top = 30;
  sunLight.shadow.bias = -0.00045;
  sunLight.shadow.normalBias = 0.02;
  scene.add(sunLight, sunLight.target);

  const earthRim = new THREE.DirectionalLight(0x6fb6ff, 0.9);
  earthRim.position.set(0, -60, 10);
  scene.add(earthRim, earthRim.target);
  scene.add(new THREE.AmbientLight(0x0b1426, 0.42));
  scene.fog = new THREE.FogExp2(0x020408, 0.0105);

  // ---- 4.3 Gestor de carga y texturas ----
  const manager = new THREE.LoadingManager();
  const loaderBar = document.getElementById("loader-bar");
  const loaderLabel = document.getElementById("loader-label");
  manager.onProgress = (url, loaded, total) => {
    if (loaderBar) loaderBar.style.width = `${Math.round((loaded / Math.max(1, total)) * 100)}%`;
    if (loaderLabel) loaderLabel.textContent = `${loaded}/${total} · ${url.split("/").pop()?.slice(0, 46) ?? ""}`;
  };
  manager.onLoad = () => {
    const ov = document.getElementById("cinema-loader");
    if (ov) {
      const bar = document.getElementById("loader-bar");
      const label = document.getElementById("loader-label");
      if (bar) bar.style.width = "100%";
      if (label) label.textContent = "Secuencia lista · despegando";
      ov.classList.add("is-done");
      setTimeout(() => ov.remove(), 1150);
    }
    document.getElementById("hint-toast")?.classList.remove("hidden");
    setTimeout(() => document.getElementById("hint-toast")?.classList.add("hidden"), 9000);
  };
  manager.onError = (url) => console.warn(`[assets] No se pudo cargar: ${url}`);

  const texLoader = new THREE.TextureLoader(manager);
  function loadTex(url, { srgb = true, repeat = null } = {}) {
    const t = texLoader.load(url, undefined, undefined, () => console.warn(`[assets] Textura ausente: ${url}`));
    t.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
    t.anisotropy = maxAniso;
    if (repeat) {
      t.wrapS = t.wrapT = THREE.RepeatWrapping;
      t.repeat.set(repeat[0], repeat[1]);
    }
    return t;
  }
  const earthTex = loadTex(`${TEX}/earth_nasa.jpg`);
  const moonTex = loadTex(`${TEX}/moon_nasa.jpg`);
  const marsTex = loadTex(`${TEX}/mars_nasa.jpg`);
  const phobosTex = loadTex(`${TEX}/phobos_nasa.jpg`);
  const deimosTex = loadTex(`${TEX}/deimos_nasa.jpg`);
  const starmapTex = loadTex(`${TEX}/starmap_hipparcos.jpg`);
  const marsGroundColor = loadTex(`${TEX}/pbr/mars_ground_color.jpg`, { repeat: [3, 3] });
  const marsGroundNormal = loadTex(`${TEX}/pbr/mars_ground_normal.jpg`, { srgb: false, repeat: [3, 3] });
  const marsGroundRough = loadTex(`${TEX}/pbr/mars_ground_roughness.jpg`, { srgb: false, repeat: [3, 3] });
  const scifiColor = loadTex(`${TEX}/pbr/scifi_metal_color.jpg`, { repeat: [2, 2] });
  const scifiNormal = loadTex(`${TEX}/pbr/scifi_metal_normal.jpg`, { srgb: false, repeat: [2, 2] });
  const scifiRough = loadTex(`${TEX}/pbr/scifi_metal_roughness.jpg`, { srgb: false, repeat: [2, 2] });
  // Variantes para planetas (relieve fino en esferas con UV equirectangular)
  const regolithNormal = loadTex(`${TEX}/pbr/mars_ground_normal.jpg`, { srgb: false, repeat: [5, 5] });
  const planetDetailNormal = loadTex(`${TEX}/pbr/mars_ground_normal.jpg`, { srgb: false, repeat: [6, 3] });

  // ---- 4.4 Entorno HDRI real (PMREM) con respaldo procedural ----
  const pmrem = new THREE.PMREMGenerator(renderer);
  pmrem.compileEquirectangularShader();
  function proceduralEnvironment() {
    const envScene = new THREE.Scene();
    envScene.background = new THREE.Color(0x02040a);
    const sunBall = new THREE.Mesh(new THREE.SphereGeometry(6, 16, 16), new THREE.MeshBasicMaterial({ color: new THREE.Color(14, 12, 9) }));
    sunBall.position.copy(SUN_DIR).multiplyScalar(60);
    envScene.add(sunBall);
    const earthBall = new THREE.Mesh(new THREE.SphereGeometry(30, 24, 24), new THREE.MeshBasicMaterial({ color: new THREE.Color(0.08, 0.28, 0.75) }));
    earthBall.position.set(0, -60, 0);
    envScene.add(earthBall);
    const starGeo = new THREE.BufferGeometry();
    const sp = new Float32Array(900 * 3);
    for (let i = 0; i < 900; i++) {
      const v = new THREE.Vector3().randomDirection().multiplyScalar(80);
      sp.set([v.x, v.y, v.z], i * 3);
    }
    starGeo.setAttribute("position", new THREE.BufferAttribute(sp, 3));
    envScene.add(new THREE.Points(starGeo, new THREE.PointsMaterial({ color: 0xffffff, size: 0.6 })));
    return pmrem.fromScene(envScene, 0.02).texture;
  }
  scene.environment = proceduralEnvironment();
  scene.environmentIntensity = 0.9;
  new RGBELoader(manager).load(
    `${TEX}/space_env_2k.hdr`,
    (hdr) => {
      hdr.mapping = THREE.EquirectangularReflectionMapping;
      const env = pmrem.fromEquirectangular(hdr).texture;
      scene.environment = env;
      scene.environmentIntensity = 1.0;
      hdr.dispose();
    },
    undefined,
    () => console.warn("[assets] HDRI ausente: se mantiene el entorno procedural"),
  );

  // ---- 4.5 Carga de GLB con mejora PBR calibrada ----
  const gltfLoader = new GLTFLoader(manager);
  const loadedModels = new Map();

  function upgradeMaterials(root, { kind = "metal" } = {}) {
    root.traverse((child) => {
      if (!child.isMesh) return;
      child.castShadow = true;
      child.receiveShadow = true;
      if (child.geometry && !child.geometry.attributes.normal) child.geometry.computeVertexNormals();
      const hasUV = Boolean(child.geometry?.attributes?.uv);
      const mats = Array.isArray(child.material) ? child.material : [child.material];
      for (const m of mats) {
        if (!m) continue;
        for (const slot of ["map", "normalMap", "roughnessMap", "metalnessMap", "emissiveMap", "aoMap"]) {
          if (m[slot]) m[slot].anisotropy = maxAniso;
        }
        if (!m.isMeshStandardMaterial) continue;
        m.envMapIntensity = 1.45;
        m.side = THREE.DoubleSide;
        const name = (m.name || "").toLowerCase();
        const isGold = /gold|foil|kapton|mli|bronze|brass/.test(name);
        const isSolar = /solar|panel|cell|array/.test(name);
        const isGlass = /glass|trans|lens|visor/.test(name);
        if (isGlass) {
          m.metalness = 0.05;
          m.roughness = 0.08;
          m.transparent = true;
          m.opacity = Math.min(m.opacity ?? 1, 0.55);
        } else if (!m.map) {
          if (hasUV && kind === "metal") {
            m.map = scifiColor;
            m.normalMap = scifiNormal;
            m.roughnessMap = scifiRough;
            m.normalScale = new THREE.Vector2(0.55, 0.55);
          }
          const lum = m.color.r * 0.3 + m.color.g * 0.59 + m.color.b * 0.11;
          if (isGold) {
            m.color.set(0xd9a73f);
            m.metalness = 1.0;
            m.roughness = 0.3;
          } else if (isSolar) {
            m.color.set(0x1b2b52);
            m.metalness = 0.6;
            m.roughness = 0.28;
          } else {
            if (lum < 0.1) m.color.setScalar(0.42);
            else if (lum > 0.9) m.color.setScalar(0.85);
            m.metalness = Math.max(m.metalness ?? 0.5, 0.74);
            m.roughness = THREE.MathUtils.clamp(m.roughness ?? 0.5, 0.26, 0.58);
          }
        } else {
          if (!m.normalMap && hasUV) {
            m.normalMap = scifiNormal;
            m.normalScale = new THREE.Vector2(0.2, 0.2);
          }
          m.roughness = THREE.MathUtils.clamp(m.roughness ?? 0.6, 0.3, 0.82);
          m.metalness = THREE.MathUtils.clamp(m.metalness ?? 0.2, 0.08, 0.9);
        }
        if (m.emissive && m.emissive.getHex() !== 0 && m.emissiveIntensity > 0.25 && !/beacon|light|holo|core|conduit/.test(name)) {
          m.emissiveIntensity = 0.25;
        }
        m.needsUpdate = true;
      }
    });
  }

  /**
   * Carga un .glb oficial NASA, lo centra en el origen con su base en y=0 (o centrado),
   * lo escala a `targetSize` (dimensión mayor) y devuelve el pivote + clips de animación.
   */
  function loadGlb(file, targetSize, onReady, { ground = false, kind = "metal", upgrade = true } = {}) {
    gltfLoader.load(
      `${MODELS}/${file}`,
      (gltf) => {
        const raw = gltf.scene;
        raw.updateMatrixWorld(true);
        const box = new THREE.Box3().setFromObject(raw);
        const size = box.getSize(new THREE.Vector3());
        const center = box.getCenter(new THREE.Vector3());
        const scale = targetSize / (Math.max(size.x, size.y, size.z) || 1);
        if (upgrade) upgradeMaterials(raw, { kind });
        const pivot = new THREE.Group();
        raw.scale.setScalar(scale);
        raw.position.set(-center.x * scale, ground ? -box.min.y * scale : -center.y * scale, -center.z * scale);
        pivot.add(raw);
        pivot.userData.size = size.multiplyScalar(scale);
        pivot.userData.clips = gltf.animations ?? [];
        loadedModels.set(file, pivot);
        onReady(pivot, gltf.animations ?? []);
      },
      undefined,
      (err) => console.warn("[assets] Error cargando GLB:", file, err?.message ?? err),
    );
  }

  const mixers = [];
  const satelliteRigs = [];
  const glintTexture = (() => {
    const cv = document.createElement("canvas");
    cv.width = cv.height = 64;
    const g2 = cv.getContext("2d");
    const gr = g2.createRadialGradient(32, 32, 0, 32, 32, 32);
    gr.addColorStop(0, "rgba(255,255,255,1)");
    gr.addColorStop(0.22, "rgba(210,240,255,0.85)");
    gr.addColorStop(1, "rgba(120,200,255,0)");
    g2.fillStyle = gr;
    g2.fillRect(0, 0, 64, 64);
    return new THREE.CanvasTexture(cv);
  })();
  /** Registra paneles solares y destellos de propulsor de un satélite. */
  function registerSatellite(holder, root, color = 0x7dd3fc) {
    const arrays = [];
    root.traverse((o) => {
      if (!o.isMesh) return;
      const mats = Array.isArray(o.material) ? o.material : [o.material];
      const nm = `${o.name} ${mats.map((m) => m?.name ?? "").join(" ")}`.toLowerCase();
      if (/solar|array|panel|wing|photovolt/.test(nm)) {
        arrays.push({ mesh: o, baseX: o.rotation.x, baseY: o.rotation.y, baseZ: o.rotation.z });
      }
    });
    const glint = new THREE.Sprite(new THREE.SpriteMaterial({ map: glintTexture, color: new THREE.Color(color), transparent: true, opacity: 0, depthWrite: false, blending: THREE.AdditiveBlending }));
    glint.scale.set(0.24, 0.24, 1);
    glint.position.set(0.9, 0.45, 0.35);
    holder.add(glint);
    satelliteRigs.push({ holder, arrays, glint, phase: Math.random() * Math.PI * 2, baseY: holder.rotation.y });
  }
  function playClips(root, clips, { names, loop = THREE.LoopRepeat, speed = 1 } = {}) {
    if (!clips?.length) return null;
    const mixer = new THREE.AnimationMixer(root);
    mixer.timeScale = speed;
    const chosen = names ? clips.filter((c) => names.includes(c.name)) : clips;
    for (const clip of chosen) {
      const action = mixer.clipAction(clip);
      action.setLoop(loop, Infinity);
      action.play();
    }
    mixers.push(mixer);
    return mixer;
  }

  // ---- 4.6 Tableros holográficos 1600×1000 (relación 1.6, anisotropía 16) ----
  const HOLO_W = 1600;
  const HOLO_H = 1000;
  function wrapCanvasText(ctx, text, maxWidth) {
    const words = String(text).split(/\s+/);
    const lines = [];
    let line = "";
    for (const word of words) {
      const test = line ? `${line} ${word}` : word;
      if (ctx.measureText(test).width > maxWidth && line) {
        lines.push(line);
        line = word;
      } else {
        line = test;
      }
    }
    if (line) lines.push(line);
    return lines;
  }
  function drawHologramCanvas(ctx, data, accentHex) {
    const W = HOLO_W, H = HOLO_H, M = 76;
    ctx.clearRect(0, 0, W, H);
    ctx.textAlign = "start";
    const accent = `#${accentHex.toString(16).padStart(6, "0")}`;
    // Fondo oscuro translúcido de alto contraste: el texto se lee nítido contra cualquier planeta.
    ctx.fillStyle = "rgba(5, 10, 22, 0.90)";
    roundRect(ctx, 18, 18, W - 36, H - 36, 34);
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = "rgba(160, 220, 255, 0.6)";
    roundRect(ctx, 18, 18, W - 36, H - 36, 34);
    ctx.stroke();
    ctx.fillStyle = accent;
    ctx.fillRect(M, 50, 150, 8);
    ctx.textBaseline = "top";

    // Encabezado de parada + lugar a la derecha.
    ctx.fillStyle = accent;
    ctx.font = "400 30px 'Nasalization', 'Michroma', 'Inter', sans-serif";
    ctx.fillText(String(data.eyebrow).toUpperCase(), M, 74);
    if (data.place) {
      ctx.textAlign = "right";
      ctx.fillStyle = "rgba(203, 225, 255, 0.85)";
      ctx.font = "500 24px 'DM Mono', 'IBM Plex Mono', monospace";
      ctx.fillText(String(data.place).toUpperCase(), W - M, 78);
      ctx.textAlign = "start";
    }

    // Pie con la fuente real NASA (≥30 px) en una franja propia.
    ctx.font = "500 30px 'DM Mono', 'IBM Plex Mono', monospace";
    const footerLines = wrapCanvasText(ctx, data.footer, W - M * 2 - 34).slice(0, 2);
    const footH = footerLines.length * 38 + 30;
    const footTop = H - 48 - footH;
    ctx.fillStyle = "rgba(120, 190, 255, 0.12)";
    roundRect(ctx, M, footTop, W - M * 2, footH, 14);
    ctx.fill();
    ctx.fillStyle = accent;
    ctx.fillRect(M, footTop, 8, footH);
    ctx.fillStyle = "#dbeafe";
    footerLines.forEach((line, k) => ctx.fillText(line, M + 30, footTop + 16 + k * 38));

    // Tipografía base (título 58, párrafo 36, viñetas 34); se amplía hasta 1.4× mientras todo quepa.
    const bodyBottom = footTop - 20;
    const bullets = data.bullets ?? data.lines ?? [];
    const colW = W - M * 2;
    let layout = null;
    for (let scale = 1.4; scale >= 1.0; scale -= 0.04) {
      const titlePx = Math.round(58 * scale), introPx = Math.round(36 * scale), bulletPx = Math.round(34 * scale);
      ctx.font = `800 ${titlePx}px 'Inter', 'Public Sans', sans-serif`;
      const titleLines = wrapCanvasText(ctx, data.title, colW).slice(0, 2);
      ctx.font = `500 ${introPx}px 'Inter', 'Public Sans', sans-serif`;
      const introLines = data.intro ? wrapCanvasText(ctx, data.intro, colW) : [];
      ctx.font = `600 ${bulletPx}px 'Inter', 'Public Sans', sans-serif`;
      const bulletBlocks = bullets.map((entry) => wrapCanvasText(ctx, String(entry), colW - 44));
      const titleH = titleLines.length * Math.round(titlePx * 1.12);
      const introLH = Math.round(introPx * 1.3), bulletLH = Math.round(bulletPx * 1.26);
      const gap = Math.round(bulletPx * 0.42);
      const top = 126;
      const total = titleH + 26 + introLines.length * introLH + (introLines.length ? 26 : 0)
        + bulletBlocks.reduce((acc, bl) => acc + bl.length * bulletLH, 0) + Math.max(0, bulletBlocks.length - 1) * gap;
      layout = { titlePx, introPx, bulletPx, titleLines, introLines, bulletBlocks, titleH, introLH, bulletLH, gap, top };
      if (top + total <= bodyBottom) break;
    }
    let y = layout.top;
    ctx.fillStyle = "#ffffff";
    ctx.font = `800 ${layout.titlePx}px 'Inter', 'Public Sans', sans-serif`;
    layout.titleLines.forEach((line, k) => ctx.fillText(line, M, y + k * Math.round(layout.titlePx * 1.12)));
    y += layout.titleH + 8;
    const grad = ctx.createLinearGradient(M, 0, W - M, 0);
    grad.addColorStop(0, accent);
    grad.addColorStop(0.3, "rgba(160, 220, 255, 0.45)");
    grad.addColorStop(1, "rgba(160, 220, 255, 0.05)");
    ctx.fillStyle = grad;
    ctx.fillRect(M, y, colW, 4);
    y += 18;
    ctx.fillStyle = "#e6f0ff";
    ctx.font = `500 ${layout.introPx}px 'Inter', 'Public Sans', sans-serif`;
    for (const line of layout.introLines) {
      ctx.fillText(line, M, y);
      y += layout.introLH;
    }
    if (layout.introLines.length) y += 26;
    ctx.font = `600 ${layout.bulletPx}px 'Inter', 'Public Sans', sans-serif`;
    for (const block of layout.bulletBlocks) {
      ctx.fillStyle = accent;
      ctx.fillRect(M, y + layout.bulletPx * 0.3, 12, 12);
      // "Etiqueta: texto" → la etiqueta va resaltada en el color de la parada.
      const first = block[0];
      const colon = first.indexOf(":");
      block.forEach((line, k) => {
        let x = M + 44;
        if (k === 0 && colon > 0 && colon < 34) {
          const head = line.slice(0, colon + 1);
          ctx.fillStyle = accent;
          ctx.fillText(head, x, y);
          x += ctx.measureText(`${head} `).width;
          ctx.fillStyle = "#f8fbff";
          ctx.fillText(line.slice(colon + 1).trimStart(), x, y);
        } else {
          ctx.fillStyle = "#f8fbff";
          ctx.fillText(line, x, y);
        }
        y += layout.bulletLH;
      });
      y += layout.gap;
    }
  }
  function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  const hologramBoards = [];
  function createHologramBoard(stop, width = 2.8) {
    const cv = document.createElement("canvas");
    cv.width = HOLO_W;
    cv.height = HOLO_H;
    const ctx = cv.getContext("2d");
    drawHologramCanvas(ctx, stop.board(), stop.color);
    const tex = new THREE.CanvasTexture(cv);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.anisotropy = Math.min(16, maxAniso);
    tex.minFilter = THREE.LinearMipmapLinearFilter;
    tex.generateMipmaps = true;
    const mat = new THREE.ShaderMaterial({
      uniforms: { uMap: { value: tex }, uTime: { value: 0 }, uOpacity: { value: 1 }, uTint: { value: new THREE.Color(stop.color) } },
      vertexShader: BASIC_UV_VERT,
      fragmentShader: HOLO_FRAG,
      transparent: true,
      depthWrite: false,
      side: THREE.DoubleSide,
    });
    const height = width / (HOLO_W / HOLO_H);
    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(width, height), mat);
    mesh.userData.width = width;
    mesh.userData.height = height;
    mesh.userData.redraw = () => {
      drawHologramCanvas(ctx, stop.board(), stop.color);
      tex.needsUpdate = true;
    };
    hologramBoards.push(mesh);
    return mesh;
  }
  // Redibujar cuando lleguen Nasalization y las demás tipografías locales.
  document.fonts?.ready?.then(() => hologramBoards.forEach((b) => b.userData.redraw()));
  document.fonts?.load?.("400 28px Nasalization").then(() => hologramBoards.forEach((b) => b.userData.redraw())).catch(() => {});

  // Botón diegético 3D "INICIAR VIAJE"
  function createLaunchButton() {
    const cv = document.createElement("canvas");
    cv.width = 1024;
    cv.height = 256;
    const ctx = cv.getContext("2d");
    const draw = (hot) => {
      ctx.clearRect(0, 0, 1024, 256);
      ctx.fillStyle = hot ? "rgba(56, 189, 248, 0.42)" : "rgba(8, 20, 46, 0.72)";
      roundRect(ctx, 8, 8, 1008, 240, 120);
      ctx.fill();
      ctx.lineWidth = 6;
      ctx.strokeStyle = hot ? "#e0f2fe" : "#38bdf8";
      roundRect(ctx, 8, 8, 1008, 240, 120);
      ctx.stroke();
      ctx.fillStyle = "#ffffff";
      ctx.font = "600 78px 'Michroma', 'Inter', 'Public Sans', sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText("INICIAR VIAJE", 512, 132);
      ctx.textAlign = "start";
    };
    draw(false);
    const tex = new THREE.CanvasTexture(cv);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.anisotropy = maxAniso;
    const mat = new THREE.ShaderMaterial({
      uniforms: { uMap: { value: tex }, uTime: { value: 0 }, uOpacity: { value: 1 }, uTint: { value: new THREE.Color(0x38bdf8) } },
      vertexShader: BASIC_UV_VERT,
      fragmentShader: HOLO_FRAG,
      transparent: true,
      depthWrite: false,
      side: THREE.DoubleSide,
    });
    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(2.4, 0.6), mat);
    mesh.userData.setHot = (hot) => {
      draw(hot);
      tex.needsUpdate = true;
    };
    document.fonts?.ready?.then(() => mesh.userData.setHot(false));
    return mesh;
  }

  // ---- 4.7 Geometría de islotes (malla polar desplazada con faldón rocoso) ----
  function jsNoise(x, z) {
    const h = (a, b) => {
      const s = Math.sin(a * 127.1 + b * 311.7) * 43758.5453;
      return s - Math.floor(s);
    };
    const xi = Math.floor(x), zi = Math.floor(z);
    const xf = x - xi, zf = z - zi;
    const u = xf * xf * (3 - 2 * xf), v = zf * zf * (3 - 2 * zf);
    return lerp(lerp(h(xi, zi), h(xi + 1, zi), u), lerp(h(xi, zi + 1), h(xi + 1, zi + 1), u), v);
  }
  function fbmJs(x, z, oct = 4) {
    let a = 0.5, f = 1, s = 0;
    for (let i = 0; i < oct; i++) {
      s += a * jsNoise(x * f + 7.3 * i, z * f + 3.1 * i);
      a *= 0.5;
      f *= 2.1;
    }
    return s;
  }
  function crater(x, z, cx, cz, R, depth, rim) {
    const d = Math.hypot(x - cx, z - cz) / R;
    const bowl = -depth * (1 - THREE.MathUtils.smoothstep(d, 0.55, 1.0)) * (0.35 + 0.65 * (1 - d * d));
    const ring = rim * Math.exp(-Math.pow((d - 1.0) / 0.22, 2));
    return bowl + ring;
  }
  /**
   * Casquete esférico: una porción de superficie que se curva con el planeta y se funde
   * con él en el borde (alfa por vértice con costa irregular). Sin discos ni cilindros.
   */
  function buildSphericalCapGeometry(R, maxR, { rings = 72, sectors = 180, heightFn = null, fadeFrom = 1 } = {}) {
    const pos = [], uv = [], col = [], idx = [];
    const push = (x, z) => {
      const r = Math.hypot(x, z);
      pos.push(x, Math.sqrt(Math.max(0, R * R - r * r)) - R + (heightFn ? heightFn(x, z) : 0), z);
      // v crece hacia -Z: lo pintado en el lienzo se lee derecho desde la cámara (+Z).
      uv.push((x / maxR) * 0.5 + 0.5, 0.5 - (z / maxR) * 0.5);
      const edge = fadeFrom + (fbmJs(x * 0.55 + 9, z * 0.55 + 2) - 0.5) * 0.2;
      col.push(1, 1, 1, fadeFrom >= 1 ? 1 : 1 - THREE.MathUtils.smoothstep(r / maxR, Math.min(edge, 0.94), 1));
    };
    push(0, 0);
    for (let r = 1; r <= rings; r++) {
      const rad = (r / rings) * maxR;
      for (let s = 0; s < sectors; s++) {
        const a = (s / sectors) * Math.PI * 2;
        push(Math.cos(a) * rad, Math.sin(a) * rad);
      }
    }
    const ringIndex = (r, s) => (r === 0 ? 0 : 1 + (r - 1) * sectors + (s % sectors));
    for (let s = 0; s < sectors; s++) idx.push(0, ringIndex(1, s + 1), ringIndex(1, s));
    for (let r = 1; r < rings; r++) {
      for (let s = 0; s < sectors; s++) {
        const a = ringIndex(r, s), b = ringIndex(r, s + 1), c = ringIndex(r + 1, s), d = ringIndex(r + 1, s + 1);
        idx.push(a, d, c, a, b, d);
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    geo.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
    geo.setAttribute("color", new THREE.Float32BufferAttribute(col, 4));
    geo.setIndex(idx);
    geo.computeVertexNormals();
    return geo;
  }
  function buildIslandGeometry(R, heightFn, { rings = 56, sectors = 144, skirt = 2.4 } = {}) {
    const pos = [], uv = [], idx = [];
    const push = (x, y, z) => {
      pos.push(x, y, z);
      uv.push((x / R) * 0.5 + 0.5, (z / R) * 0.5 + 0.5);
    };
    // Centro
    push(0, heightFn(0, 0), 0);
    for (let r = 1; r <= rings; r++) {
      const rad = (r / rings) * R;
      for (let s = 0; s < sectors; s++) {
        const a = (s / sectors) * Math.PI * 2;
        const x = Math.cos(a) * rad, z = Math.sin(a) * rad;
        push(x, heightFn(x, z), z);
      }
    }
    // Faldón: dos anillos descendentes con relieve rocoso
    for (let k = 1; k <= 2; k++) {
      for (let s = 0; s < sectors; s++) {
        const a = (s / sectors) * Math.PI * 2;
        const wob = 1 + (fbmJs(Math.cos(a) * 3 + 10, Math.sin(a) * 3) - 0.5) * 0.08 * k;
        const rad = R * (k === 1 ? 1.04 : 0.96) * wob;
        push(Math.cos(a) * rad, -skirt * (k === 1 ? 0.5 : 1.0), Math.sin(a) * rad);
      }
    }
    const ringIndex = (r, s) => (r === 0 ? 0 : 1 + (r - 1) * sectors + (s % sectors));
    for (let s = 0; s < sectors; s++) idx.push(0, ringIndex(1, s + 1), ringIndex(1, s));
    const totalRings = rings + 2;
    for (let r = 1; r < totalRings; r++) {
      for (let s = 0; s < sectors; s++) {
        const a = ringIndex(r, s), b = ringIndex(r, s + 1), c = ringIndex(r + 1, s), d = ringIndex(r + 1, s + 1);
        idx.push(a, d, c, a, b, d);
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
    geo.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
    geo.setIndex(idx);
    geo.computeVertexNormals();
    return geo;
  }

  // Rocas irregulares instanciadas (icosaedro desplazado)
  function makeRockGeometry(seed) {
    const geo = new THREE.IcosahedronGeometry(0.5, 2);
    const p = geo.attributes.position;
    const v = new THREE.Vector3();
    for (let i = 0; i < p.count; i++) {
      v.fromBufferAttribute(p, i);
      const n = Math.sin(v.x * 4.1 * seed + v.y * 2.3) * 0.16 + Math.sin(v.y * 6.7 + v.z * 3.9 * seed) * 0.11 + Math.sin(v.z * 9.3 + v.x * 5.1) * 0.07;
      v.multiplyScalar(1 + n);
      p.setXYZ(i, v.x, v.y, v.z);
    }
    geo.computeVertexNormals();
    return geo;
  }
  const rockGeoA = makeRockGeometry(1.0);
  const rockGeoB = makeRockGeometry(1.7);
  function scatterRocks(parent, count, { radiusMin, radiusMax, scale = 1, color = 0x6b625a, y = 0, heightFn = null, seed = 1 }) {
    const mat = new THREE.MeshStandardMaterial({ map: deimosTex, color, normalMap: regolithNormal, normalScale: new THREE.Vector2(0.6, 0.6), roughness: 0.96, metalness: 0.02, envMapIntensity: 0.5 });
    const inst = new THREE.InstancedMesh(seed % 2 ? rockGeoA : rockGeoB, mat, count);
    const d = new THREE.Object3D();
    for (let i = 0; i < count; i++) {
      const a = i * 2.399963 + seed;
      const r = radiusMin + (radiusMax - radiusMin) * ((Math.sin(i * 12.9898 + seed) * 43758.5453) % 1 + 1) % 1;
      const x = Math.cos(a) * r, z = Math.sin(a) * r;
      const s = scale * (0.35 + (((i * 7) % 5) / 5) * 0.9);
      d.position.set(x, (heightFn ? heightFn(x, z) : 0) + y + s * 0.18, z);
      d.rotation.set(i * 0.7, i * 1.3, i * 0.4);
      d.scale.set(s, s * 0.7, s * 0.85);
      d.updateMatrix();
      inst.setMatrixAt(i, d.matrix);
    }
    inst.castShadow = true;
    inst.receiveShadow = true;
    parent.add(inst);
    return inst;
  }

  // ---- 4.8 Sistema de partículas CPU (humo criogénico y chispas) ----
  class ParticleSystem {
    constructor(count, { color = [1, 1, 1], size = 1, blending = THREE.NormalBlending } = {}) {
      this.count = count;
      this.pos = new Float32Array(count * 3);
      this.vel = new Float32Array(count * 3);
      this.life = new Float32Array(count);
      this.maxLife = new Float32Array(count);
      this.sizes = new Float32Array(count);
      this.colors = new Float32Array(count * 3);
      this.baseSize = size;
      this.baseColor = color;
      this.cursor = 0;
      const geo = new THREE.BufferGeometry();
      geo.setAttribute("position", new THREE.BufferAttribute(this.pos, 3));
      geo.setAttribute("aSize", new THREE.BufferAttribute(this.sizes, 1));
      geo.setAttribute("aLife", new THREE.BufferAttribute(this.life, 1));
      geo.setAttribute("aColor", new THREE.BufferAttribute(this.colors, 3));
      this.mesh = new THREE.Points(
        geo,
        new THREE.ShaderMaterial({
          uniforms: { uOpacity: { value: 1 } },
          vertexShader: PARTICLE_VERT,
          fragmentShader: PARTICLE_FRAG,
          transparent: true,
          depthWrite: false,
          blending,
        }),
      );
      this.mesh.frustumCulled = false;
    }
    emit(origin, { spread = 0.3, velocity = [0, 1, 0], jitter = 0.5, life = 2, size = 1, color = null, count = 1 } = {}) {
      for (let n = 0; n < count; n++) {
        const i = this.cursor;
        this.cursor = (this.cursor + 1) % this.count;
        this.pos[i * 3] = origin.x + (Math.random() - 0.5) * spread;
        this.pos[i * 3 + 1] = origin.y + (Math.random() - 0.5) * spread * 0.4;
        this.pos[i * 3 + 2] = origin.z + (Math.random() - 0.5) * spread;
        this.vel[i * 3] = velocity[0] + (Math.random() - 0.5) * jitter;
        this.vel[i * 3 + 1] = velocity[1] + (Math.random() - 0.5) * jitter;
        this.vel[i * 3 + 2] = velocity[2] + (Math.random() - 0.5) * jitter;
        this.life[i] = 1;
        this.maxLife[i] = life * (0.7 + Math.random() * 0.6);
        this.sizes[i] = size * (0.6 + Math.random() * 0.8);
        const c = color ?? this.baseColor;
        this.colors[i * 3] = c[0];
        this.colors[i * 3 + 1] = c[1];
        this.colors[i * 3 + 2] = c[2];
      }
    }
    update(dt, { gravity = 0, drag = 0.98, grow = 0 } = {}) {
      for (let i = 0; i < this.count; i++) {
        if (this.life[i] <= 0) continue;
        this.life[i] -= dt / this.maxLife[i];
        this.vel[i * 3 + 1] += gravity * dt;
        this.vel[i * 3] *= drag;
        this.vel[i * 3 + 1] *= drag;
        this.vel[i * 3 + 2] *= drag;
        this.pos[i * 3] += this.vel[i * 3] * dt;
        this.pos[i * 3 + 1] += this.vel[i * 3 + 1] * dt;
        this.pos[i * 3 + 2] += this.vel[i * 3 + 2] * dt;
        this.sizes[i] += grow * dt;
        if (this.life[i] < 0) this.life[i] = 0;
      }
      const g = this.mesh.geometry;
      g.attributes.position.needsUpdate = true;
      g.attributes.aLife.needsUpdate = true;
      g.attributes.aSize.needsUpdate = true;
      g.attributes.aColor.needsUpdate = true;
    }
  }

  // ============================================================================
  // 5. DISTRIBUCIÓN DEL MUNDO: 6 PARADAS, 4 PORTALES Y LA CURVA DE VUELO
  // ============================================================================
  const EARTH_R = 24;
  const EARTH_C = new THREE.Vector3(0, -EARTH_R, 0);
  const V3 = (x, y, z) => new THREE.Vector3(x, y, z);
  const Y_UP = new THREE.Vector3(0, 1, 0);
  const BASE_FOV = 46;
  const HALF_TAN = Math.tan(THREE.MathUtils.degToRad(BASE_FOV / 2));
  const VIEW_ASPECT = THREE.MathUtils.clamp(window.innerWidth / Math.max(1, window.innerHeight), 1.45, 2.1);

  // Centro físico de cada parada. La ruta mide ~1100 u (antes 720): cada salto es un viaje de verdad.
  const SITE = {
    leo: V3(8, 12, 22),
    deep: V3(48, 18, -270),
    moon: V3(72, 4, -530),
    mars: V3(22, -4, -830),
    jezero: V3(0, 0, -1110),
  };
  const RIG = [
    { focus: V3(2.4, 2.0, 0.6), offset: V3(0.3, 1.5, 14.4) },
    { focus: SITE.leo.clone().add(V3(2.4, 0.2, 0)), offset: V3(5, 2.4, 13) },
    { focus: SITE.deep.clone().add(V3(2.6, 0.1, 0)), offset: V3(4.5, 2.2, 13.5) },
    { focus: SITE.moon.clone().add(V3(0.9, 1.3, 0)), offset: V3(0.9, 0.2, 9.4) },
    { focus: SITE.mars.clone().add(V3(9, 1.0, 0)), offset: V3(9, 5, 38) },
    { focus: SITE.jezero.clone().add(V3(-0.2, 1.3, 0)), offset: V3(0.9, 1.0, 11.8) },
  ];
  const PARK = [
    V3(0.9, 0.1, 0.35),
    SITE.leo.clone().add(V3(-4.2, -3.4, 0.5)),
    SITE.deep.clone().add(V3(-5.5, -3.0, 1.5)),
    SITE.moon.clone().add(V3(-5.5, 3.0, -2.5)),
    SITE.mars.clone().add(V3(2, 8.5, 14)),
    SITE.jezero.clone().add(V3(-7, 4.6, -1)),
  ];
  const GATES = [0, 1, 2, 3].map((i) => PARK[i + 1].clone().lerp(PARK[i + 2], 0.5).add(V3(i % 2 ? -4 : 4, 3, 0)));
  const GATE_COLORS = [
    [0x1d4ed8, 0x7dd3fc],
    [0x7c3aed, 0xfbbf24],
    [0x0e7490, 0xe0f2fe],
    [0xb91c1c, 0xfdba74],
  ];

  /** Marco de cámara de una parada y punto del mundo que cae en (sx, sy) de pantalla a `dist` metros. */
  const rigFrame = (i) => {
    const cam = RIG[i].focus.clone().add(RIG[i].offset);
    const fwd = RIG[i].focus.clone().sub(cam).normalize();
    const right = new THREE.Vector3().crossVectors(fwd, Y_UP).normalize();
    const up = new THREE.Vector3().crossVectors(right, fwd).normalize();
    return { cam, fwd, right, up };
  };
  function viewPoint(i, dist, sx, sy) {
    const f = rigFrame(i);
    return f.cam.clone().addScaledVector(f.fwd, dist).addScaledVector(f.right, sx * dist * HALF_TAN * VIEW_ASPECT).addScaledVector(f.up, sy * dist * HALF_TAN);
  }

  const flightCurve = new THREE.CatmullRomCurve3(
    [PARK[0], V3(0.9, 6, 0.5), V3(1.6, 10.5, 8), PARK[1], GATES[0], PARK[2], GATES[1], PARK[3], GATES[2], PARK[4], GATES[3], PARK[5]],
    false,
    "centripetal",
    0.5,
  );
  // u exacto de cada parada y portal (muestreo por longitud de arco)
  const SAMPLES = 3600;
  const samplePts = flightCurve.getSpacedPoints(SAMPLES);
  const nearestU = (p) => {
    let best = 0, bd = Infinity;
    for (let i = 0; i <= SAMPLES; i++) {
      const d = samplePts[i].distanceToSquared(p);
      if (d < bd) { bd = d; best = i; }
    }
    return best / SAMPLES;
  };
  const STOP_U = PARK.map(nearestU);
  STOP_U[0] = 0;
  STOP_U[5] = 1;
  const GATE_U = GATES.map(nearestU);

  const softDotTex = (() => {
    const cv = document.createElement("canvas");
    cv.width = cv.height = 64;
    const g2 = cv.getContext("2d");
    const gr = g2.createRadialGradient(32, 32, 0, 32, 32, 32);
    gr.addColorStop(0, "rgba(255,255,255,1)");
    gr.addColorStop(0.4, "rgba(255,255,255,0.5)");
    gr.addColorStop(1, "rgba(255,255,255,0)");
    g2.fillStyle = gr;
    g2.fillRect(0, 0, 64, 64);
    return new THREE.CanvasTexture(cv);
  })();

  // ---- 5.1 Cielo: mapa estelar Hipparcos + estrellas puntuales + corona solar ----
  const skyGroup = new THREE.Group();
  scene.add(skyGroup);
  const starSphere = new THREE.Mesh(
    new THREE.SphereGeometry(1500, 48, 32),
    new THREE.MeshBasicMaterial({ map: starmapTex, side: THREE.BackSide, color: new THREE.Color(0.55, 0.6, 0.72), depthWrite: false }),
  );
  starSphere.renderOrder = -20;
  skyGroup.add(starSphere);
  {
    const count = 4200;
    const pos = new Float32Array(count * 3);
    const col = new Float32Array(count * 3);
    const temps = [[0.66, 0.76, 1.0], [0.84, 0.9, 1.0], [1.0, 0.98, 0.93], [1.0, 0.86, 0.64], [1.0, 0.7, 0.48]];
    for (let i = 0; i < count; i++) {
      const v = new THREE.Vector3().randomDirection().multiplyScalar(900 + Math.random() * 450);
      pos.set([v.x, v.y, v.z], i * 3);
      const t = Math.random();
      const c = temps[t < 0.06 ? 0 : t < 0.2 ? 1 : t < 0.62 ? 2 : t < 0.86 ? 3 : 4];
      const l = 0.45 + Math.random() * 0.55;
      col.set([c[0] * l, c[1] * l, c[2] * l], i * 3);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.BufferAttribute(pos, 3));
    g.setAttribute("color", new THREE.BufferAttribute(col, 3));
    skyGroup.add(new THREE.Points(g, new THREE.PointsMaterial({ size: 3.2, map: softDotTex, vertexColors: true, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, sizeAttenuation: true })));
  }

  // ---- 5.1b Vía Láctea vecina: galaxia espiral 3D (26 000 soles en brazos logarítmicos) + nebulosas ----
  const galaxyGroup = new THREE.Group();
  const skyShaderMats = [];
  {
    const GAL_R = 235;
    galaxyGroup.position.copy(new THREE.Vector3(-0.16, 0.25, -0.95).normalize()).multiplyScalar(1180);
    galaxyGroup.rotation.set(0.95, 0, 0.35);
    skyGroup.add(galaxyGroup);
    const COUNT = 26000, ARMS = 2, TWIST = 3.4;
    const pos = new Float32Array(COUNT * 3), col = new Float32Array(COUNT * 3);
    let seed = 7;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    const gauss = () => (rnd() + rnd() + rnd() + rnd() - 2) * 0.7;
    for (let i = 0; i < COUNT; i++) {
      let x, y, z, c;
      if (i < COUNT * 0.2) {
        // Bulbo central cálido
        const r = Math.pow(rnd(), 1.6) * GAL_R * 0.2;
        const th = rnd() * Math.PI * 2, ph = Math.acos(2 * rnd() - 1);
        x = r * Math.sin(ph) * Math.cos(th);
        z = r * Math.sin(ph) * Math.sin(th);
        y = r * Math.cos(ph) * 0.55;
        c = [1.0, 0.86, 0.62];
      } else {
        const rn = Math.pow(rnd(), 0.72);
        const r = (0.1 + 0.9 * rn) * GAL_R;
        const arm = Math.floor(rnd() * ARMS) + (rnd() < 0.26 ? 0.5 : 0);
        const ang = (arm / ARMS) * Math.PI * 2 + Math.log(1 + rn * 5.0) * TWIST + gauss() * (0.16 + 0.22 * rn);
        x = Math.cos(ang) * r;
        z = Math.sin(ang) * r;
        y = gauss() * GAL_R * 0.012 * (1.4 - rn);
        const hot = rnd();
        c = hot < 0.12 ? [1.0, 0.55, 0.72] : hot < 0.55 ? [0.62, 0.76, 1.0] : [0.92, 0.94, 1.0];
        const warm = Math.max(0, 1 - rn * 2.2);
        c = [lerp(c[0], 1.0, warm), lerp(c[1], 0.86, warm), lerp(c[2], 0.62, warm)];
      }
      const l = 0.3 + rnd() * 0.7;
      pos.set([x, y, z], i * 3);
      col.set([c[0] * l, c[1] * l, c[2] * l], i * 3);
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.BufferAttribute(pos, 3));
    geo.setAttribute("color", new THREE.BufferAttribute(col, 3));
    const stars = new THREE.Points(geo, new THREE.PointsMaterial({ size: 6.5, map: softDotTex, vertexColors: true, transparent: true, opacity: 0.8, depthWrite: false, blending: THREE.AdditiveBlending, sizeAttenuation: true }));
    stars.renderOrder = -11;
    galaxyGroup.add(stars);
    const hazeMat = new THREE.ShaderMaterial({
      uniforms: { uTime: { value: 0 }, uColorA: { value: new THREE.Color(0x2b3fa8) }, uColorB: { value: new THREE.Color(0x9a5bd6) }, uColorC: { value: new THREE.Color(0xffd7a0) } },
      vertexShader: BASIC_UV_VERT,
      fragmentShader: GALAXY_FRAG,
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide,
    });
    const haze = new THREE.Mesh(new THREE.PlaneGeometry(GAL_R * 2.6, GAL_R * 2.6), hazeMat);
    haze.rotation.x = -Math.PI / 2;
    haze.renderOrder = -12;
    galaxyGroup.add(haze);
    skyShaderMats.push(hazeMat);

    // Nebulosas de emisión repartidas por el cielo (siempre detrás de los planetas: respetan la profundidad).
    const nebulaDefs = [
      { dir: [0.82, 0.14, -0.55], size: 880, a: 0x7c3aed, b: 0xdb2777, gain: 0.3, seed: 1.7 },
      { dir: [-0.86, -0.08, -0.5], size: 820, a: 0x0e7490, b: 0x2563eb, gain: 0.28, seed: 6.1 },
      { dir: [0.25, 0.3, 0.92], size: 1000, a: 0xb45309, b: 0x7c3aed, gain: 0.26, seed: 11.4 },
      { dir: [0.1, -0.55, -0.83], size: 700, a: 0x1d4ed8, b: 0x0f766e, gain: 0.2, seed: 3.3 },
    ];
    for (const def of nebulaDefs) {
      const mat = new THREE.ShaderMaterial({
        uniforms: { uTime: { value: 0 }, uColorA: { value: new THREE.Color(def.a) }, uColorB: { value: new THREE.Color(def.b) }, uSeed: { value: def.seed }, uGain: { value: def.gain } },
        vertexShader: BASIC_UV_VERT,
        fragmentShader: NEBULA_FRAG,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide,
      });
      const neb = new THREE.Mesh(new THREE.PlaneGeometry(def.size, def.size), mat);
      neb.position.copy(new THREE.Vector3(...def.dir).normalize()).multiplyScalar(1300);
      neb.lookAt(0, 0, 0);
      neb.renderOrder = -13;
      skyGroup.add(neb);
      skyShaderMats.push(mat);
    }
  }
  const sunMat = new THREE.ShaderMaterial({
    uniforms: { uTime: { value: 0 } },
    vertexShader: BASIC_UV_VERT,
    fragmentShader: SUN_FRAG,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });
  const sunBillboard = new THREE.Mesh(new THREE.PlaneGeometry(420, 420), sunMat);
  sunBillboard.position.copy(SUN_DIR).multiplyScalar(900);
  sunBillboard.renderOrder = -10;
  skyGroup.add(sunBillboard);

  // ---- 5.1c Planetas lejanos fotorrealistas: Júpiter y Saturno con anillos ----
  const giants = [];
  function makeGiant({ position, radius, bandA, bandB, bandC, bands, spot = 0, seed = 1, tilt = [0, 0, 0], ring = null }) {
    const group = new THREE.Group();
    group.position.copy(position);
    group.rotation.set(...tilt);
    scene.add(group);
    group.updateMatrixWorld(true);
    const ringNormal = new THREE.Vector3(0, 1, 0).applyQuaternion(group.quaternion);
    const mat = new THREE.ShaderMaterial({
      uniforms: {
        uSunDir: { value: SUN_DIR }, uTime: { value: 0 },
        uBandA: { value: new THREE.Color(bandA) }, uBandB: { value: new THREE.Color(bandB) }, uBandC: { value: new THREE.Color(bandC) },
        uBands: { value: bands }, uSpot: { value: spot }, uSeed: { value: seed },
        uCenter: { value: position.clone() }, uRadius: { value: radius }, uRingNormal: { value: ringNormal },
        uRingInner: { value: ring ? ring.inner : 0 }, uRingOuter: { value: ring ? ring.outer : 0 },
      },
      vertexShader: EARTH_VERT,
      fragmentShader: GIANT_FRAG,
    });
    const body = new THREE.Mesh(new THREE.SphereGeometry(radius, 96, 64), mat);
    body.rotation.y = 2.2; // la costura del mapa queda en la cara oculta
    group.add(body);
    if (ring) {
      const ringMat = new THREE.ShaderMaterial({
        uniforms: { uSunDir: { value: SUN_DIR }, uCenter: { value: position.clone() }, uPlanetR: { value: radius }, uInner: { value: ring.inner * radius }, uOuter: { value: ring.outer * radius }, uColor: { value: new THREE.Color(ring.color) } },
        vertexShader: EARTH_VERT,
        fragmentShader: RING_FRAG,
        transparent: true,
        depthWrite: false,
        side: THREE.DoubleSide,
      });
      const ringMesh = new THREE.Mesh(new THREE.RingGeometry(ring.inner * radius, ring.outer * radius, 160, 1), ringMat);
      ringMesh.rotation.x = -Math.PI / 2;
      group.add(ringMesh);
    }
    group.add(makeAtmosphere(radius * 1.03, 1.03, bandA, 0x05070c, 5.0, 2.2, 0.35, THREE.BackSide));
    giants.push({ body, mat });
    return group;
  }

  // ---- 5.2 Tierra nivelada: Florida en el cénit, luces nocturnas, glint oceánico, nubes y atmósfera ----
  const earthGroup = new THREE.Group();
  earthGroup.position.copy(EARTH_C);
  scene.add(earthGroup);
  const earthMat = new THREE.ShaderMaterial({
    uniforms: { uDay: { value: earthTex }, uSunDir: { value: SUN_DIR }, uTime: { value: 0 } },
    vertexShader: EARTH_VERT,
    fragmentShader: EARTH_FRAG,
  });
  const earthMesh = new THREE.Mesh(new THREE.SphereGeometry(EARTH_R, 192, 128), earthMat);
  // Orientación: Cabo Cañaveral (28,5° N · 80,6° O) exactamente arriba (+Y)
  {
    const lat = THREE.MathUtils.degToRad(28.5), lon = THREE.MathUtils.degToRad(-80.6);
    const phi = Math.PI / 2 - lat, theta = lon + Math.PI;
    const d = new THREE.Vector3(-Math.cos(theta) * Math.sin(phi), Math.cos(phi), Math.sin(theta) * Math.sin(phi)).normalize();
    earthMesh.quaternion.setFromUnitVectors(d, new THREE.Vector3(0, 1, 0));
  }
  earthGroup.add(earthMesh);
  const cloudMat = new THREE.ShaderMaterial({
    uniforms: { uSunDir: { value: SUN_DIR }, uTime: { value: 0 }, uPadPos: { value: new THREE.Vector3(0, 0, 0) } },
    vertexShader: EARTH_VERT,
    fragmentShader: CLOUD_FRAG,
    transparent: true,
    depthWrite: false,
  });
  const cloudMesh = new THREE.Mesh(new THREE.SphereGeometry(EARTH_R * 1.014, 128, 96), cloudMat);
  cloudMesh.renderOrder = 2;
  earthGroup.add(cloudMesh);
  /** Concha atmosférica con borde Fresnel suave. `k` = radio de la concha / radio del planeta. */
  function makeAtmosphere(radius, k, dayColor, nightColor, power, falloff, strength, side = THREE.BackSide) {
    return new THREE.Mesh(
      new THREE.SphereGeometry(radius, 96, 64),
      new THREE.ShaderMaterial({
        uniforms: {
          uSunDir: { value: SUN_DIR },
          uDayColor: { value: new THREE.Color(dayColor) },
          uNightColor: { value: new THREE.Color(nightColor) },
          uPower: { value: power },
          uFalloff: { value: falloff },
          uStrength: { value: strength },
          uLimb: { value: 1 - Math.sqrt(1 - 1 / (k * k)) },
        },
        vertexShader: ATMO_VERT,
        fragmentShader: ATMO_FRAG,
        blending: THREE.AdditiveBlending,
        side,
        transparent: true,
        depthWrite: false,
      }),
    );
  }
  // Halo cian exterior (el brillo interior del limbo ya lo integra el shader de la superficie).
  earthGroup.add(makeAtmosphere(EARTH_R * 1.07, 1.07, 0x4fb3ff, 0x0a1a46, 3.0, 2.4, 1.15, THREE.BackSide));

  makeGiant({ position: V3(-60, 120, -900), radius: 48, bandA: 0xd9b48a, bandB: 0x9c6b47, bandC: 0xf1e3c8, bands: 7, spot: 1, seed: 3.1, tilt: [0.05, 0, 0.06] });
  makeGiant({ position: V3(88, 72, -1497), radius: 42, bandA: 0xe6d3a3, bandB: 0xc9a86a, bandC: 0xf4ecd2, bands: 9, seed: 8.4, tilt: [0.42, 0, 0.25], ring: { inner: 1.24, outer: 2.28, color: 0xd9c9a3 } });

  // ---- 5.3 PARADA 01 · Complejo costero del Pad 39B sobre el horizonte de la Tierra ----
  const padGroup = new THREE.Group();
  scene.add(padGroup);
  const PAD_R = 7.2;
  const ROCKET_X = 0.9, ROCKET_Z = 0.35;

  // Textura del complejo: marisma costera, crawlerway, hardstand de hormigón, foso de llamas
  // y "NASA" en rojo (Nasalization) pintado sobre el suelo, alargado como una marca de pista.
  const PAD_TEX_SIZE = 2048;
  const padCv = document.createElement("canvas");
  padCv.width = padCv.height = PAD_TEX_SIZE;
  const padCtx = padCv.getContext("2d");
  const m2px = (m) => (m / (PAD_R * 2)) * PAD_TEX_SIZE;
  const cx = (x) => (x / (PAD_R * 2) + 0.5) * PAD_TEX_SIZE;
  const cz = (z) => (z / (PAD_R * 2) + 0.5) * PAD_TEX_SIZE; // +Z (hacia la cámara) queda abajo del lienzo
  const drawPadTexture = () => {
    const S = PAD_TEX_SIZE, c = padCtx;
    let seed = 11;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    c.setTransform(1, 0, 0, 1, 0, 0);
    c.shadowBlur = 0;
    c.fillStyle = "#4e5f3e";
    c.fillRect(0, 0, S, S);
    for (let i = 0; i < 620; i++) {
      const x = rnd() * S, y = rnd() * S, r = 20 + rnd() * 95, tone = rnd();
      const rgb = tone < 0.4 ? "74, 92, 58" : tone < 0.68 ? "156, 144, 104" : tone < 0.88 ? "56, 74, 48" : "36, 68, 84";
      const g = c.createRadialGradient(x, y, 0, x, y, r);
      g.addColorStop(0, `rgba(${rgb}, 0.6)`);
      g.addColorStop(1, `rgba(${rgb}, 0)`);
      c.fillStyle = g;
      c.fillRect(x - r, y - r, r * 2, r * 2);
    }
    const road = (pts, w, color) => {
      c.strokeStyle = color;
      c.lineWidth = m2px(w);
      c.lineCap = c.lineJoin = "round";
      c.beginPath();
      pts.forEach(([x, z], i) => (i ? c.lineTo(cx(x), cz(z)) : c.moveTo(cx(x), cz(z))));
      c.stroke();
    };
    // Crawlerway de grava (dos carriles con mediana verde) hacia el VAB y camino de servicio.
    const crawler = [[0.4, -2.2], [-0.4, -4.0], [-2.6, -5.6], [-5.8, -7.4]];
    road(crawler, 1.5, "#8f8672");
    road(crawler, 0.42, "#55633f");
    road([[4.4, 1.5], [6.2, 1.9], [7.4, 3.2]], 0.5, "#7d7a70");
    // Hardstand de hormigón con juntas de dilatación y manchas de servicio.
    const hx = cx(-3.9), hz = cz(-2.6), hw = m2px(8.7), hh = m2px(8.3);
    c.save();
    roundRect(c, hx, hz, hw, hh, m2px(0.6));
    c.clip();
    const base = c.createLinearGradient(hx, hz, hx + hw, hz + hh);
    base.addColorStop(0, "#8b8880");
    base.addColorStop(0.5, "#a09d94");
    base.addColorStop(1, "#827f77");
    c.fillStyle = base;
    c.fillRect(hx, hz, hw, hh);
    for (let i = 0; i < 16000; i++) {
      const l = Math.round(60 + rnd() * 70);
      c.fillStyle = `rgba(${l},${l},${l - 4},${0.05 + rnd() * 0.12})`;
      c.fillRect(hx + rnd() * hw, hz + rnd() * hh, 1 + rnd() * 4, 1 + rnd() * 4);
    }
    c.strokeStyle = "rgba(40, 40, 38, 0.5)";
    c.lineWidth = 3;
    for (let m = -4; m <= 5; m += 0.8) {
      c.beginPath(); c.moveTo(cx(m), hz); c.lineTo(cx(m), hz + hh); c.stroke();
      c.beginPath(); c.moveTo(hx, cz(m + 0.8)); c.lineTo(hx + hw, cz(m + 0.8)); c.stroke();
    }
    // Hollín radial alrededor del foso de llamas.
    const soot = c.createRadialGradient(cx(ROCKET_X), cz(ROCKET_Z), m2px(0.3), cx(ROCKET_X), cz(ROCKET_Z), m2px(2.6));
    soot.addColorStop(0, "rgba(20, 20, 22, 0.75)");
    soot.addColorStop(1, "rgba(20, 20, 22, 0)");
    c.fillStyle = soot;
    c.fillRect(hx, hz, hw, hh);
    c.restore();
    c.lineWidth = 8;
    c.strokeStyle = "rgba(240, 240, 230, 0.75)";
    roundRect(c, hx + 10, hz + 10, hw - 20, hh - 20, m2px(0.55));
    c.stroke();
    // Foso de llamas y círculo de seguridad amarillo.
    c.fillStyle = "#17191c";
    c.fillRect(cx(ROCKET_X - 0.42), cz(-2.5), m2px(0.84), m2px(3.6));
    c.beginPath();
    c.arc(cx(ROCKET_X), cz(ROCKET_Z), m2px(2.15), 0, Math.PI * 2);
    c.lineWidth = 14;
    c.strokeStyle = "#e3b53c";
    c.stroke();
    c.setLineDash([26, 20]);
    c.beginPath();
    c.arc(cx(ROCKET_X), cz(ROCKET_Z), m2px(1.6), 0, Math.PI * 2);
    c.lineWidth = 5;
    c.strokeStyle = "rgba(245, 245, 235, 0.7)";
    c.stroke();
    c.setLineDash([]);
    // "NASA" en rojo sobre el suelo del pad, frente al cohete.
    const paint = (text, x, z, widthM, stretch, fill) => {
      c.save();
      c.translate(cx(x), cz(z));
      c.font = "400 200px 'Nasalization', 'Michroma', 'Arial Black', sans-serif";
      c.textAlign = "center";
      c.textBaseline = "middle";
      const k = m2px(widthM) / Math.max(1, c.measureText(text).width);
      c.scale(k, k * stretch);
      c.fillStyle = fill;
      c.fillText(text, 0, 0);
      c.restore();
    };
    paint("NASA", -0.6, 4.2, 4.5, 2.3, "#e0220f");
    paint("39B", 3.55, -1.75, 1.3, 1.9, "rgba(245, 245, 235, 0.88)");
  };
  drawPadTexture();
  const padTexture = new THREE.CanvasTexture(padCv);
  padTexture.colorSpace = THREE.SRGBColorSpace;
  padTexture.anisotropy = Math.min(16, maxAniso); // anisotropy = 16 en GPU que lo soportan
  const repaintPad = () => { drawPadTexture(); padTexture.needsUpdate = true; };
  document.fonts?.ready?.then(repaintPad);
  document.fonts?.load?.("400 200px Nasalization").then(repaintPad).catch(() => {});

  // Casquete que sigue la curvatura de la Tierra y se funde con ella en una costa irregular.
  const padRelief = (x, z) => 0.05 + (fbmJs(x * 0.5 + 4, z * 0.5) - 0.5) * 0.03;
  const padSurfaceY = (x, z) => Math.sqrt(Math.max(0, EARTH_R * EARTH_R - x * x - z * z)) - EARTH_R + padRelief(x, z);
  const apronMesh = new THREE.Mesh(
    buildSphericalCapGeometry(EARTH_R, PAD_R, { rings: 72, sectors: 192, heightFn: padRelief, fadeFrom: 0.82 }),
    new THREE.MeshStandardMaterial({ map: padTexture, normalMap: regolithNormal, normalScale: new THREE.Vector2(0.16, 0.16), roughness: 0.86, metalness: 0.02, envMapIntensity: 0.6, vertexColors: true, transparent: true }),
  );
  apronMesh.receiveShadow = true;
  apronMesh.renderOrder = 1;
  padGroup.add(apronMesh);
  const onPad = (obj, x, z, lift = 0) => {
    obj.position.set(x, padSurfaceY(x, z) + lift, z);
    padGroup.add(obj);
    return obj;
  };
  const steelMat = new THREE.MeshStandardMaterial({ map: scifiColor, normalMap: scifiNormal, roughnessMap: scifiRough, color: 0xc4c8cf, metalness: 0.8, roughness: 0.42 });
  const whiteMat = new THREE.MeshStandardMaterial({ color: 0xeef0f2, metalness: 0.15, roughness: 0.45 });
  {
    const mount = new THREE.Mesh(new THREE.BoxGeometry(1.3, 0.16, 1.3), new THREE.MeshStandardMaterial({ color: 0x2a2d31, roughness: 0.85, metalness: 0.3 }));
    mount.receiveShadow = mount.castShadow = true;
    onPad(mount, ROCKET_X, ROCKET_Z, 0.04);
  }
  // Torre Mobile Launcher + brazos umbilicales retráctiles
  const TOWER_X = -0.75, TOWER_Z = 0.25;
  const towerAnchor = new THREE.Group();
  onPad(towerAnchor, TOWER_X, TOWER_Z, 0.05);
  loadGlb("mobile_launcher.glb", 3.1, (m) => towerAnchor.add(m), { ground: true });
  const umbilicalArms = [];
  for (const h of [1.05, 1.75, 2.45]) {
    const pivot = new THREE.Group();
    pivot.position.set(0.32, h, 0.1);
    const arm = new THREE.Mesh(new THREE.BoxGeometry(1.15, 0.07, 0.09), steelMat);
    arm.position.x = 0.575;
    arm.castShadow = true;
    pivot.add(arm);
    const tip = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.16, 0.18), new THREE.MeshStandardMaterial({ color: 0xfc3d21, metalness: 0.4, roughness: 0.5 }));
    tip.position.x = 1.12;
    pivot.add(tip);
    towerAnchor.add(pivot);
    umbilicalArms.push(pivot);
  }
  // Balizas rojas (parpadeo HDR → bloom), torres pararrayos, tanques criogénicos esféricos y focos.
  const beaconMat = new THREE.MeshBasicMaterial({ color: new THREE.Color(6, 0.5, 0.3) });
  const beacons = [];
  const addBeacon = (x, y, z) => {
    const b = new THREE.Mesh(new THREE.SphereGeometry(0.045, 10, 10), beaconMat.clone());
    onPad(b, x, z, y);
    beacons.push(b);
  };
  addBeacon(TOWER_X, 3.3, TOWER_Z);
  for (const [x, z] of [[4.25, -1.1], [-3.55, -2.1]]) {
    const mast = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.045, 4.3, 8), whiteMat);
    mast.castShadow = true;
    onPad(mast, x, z, 2.15);
    addBeacon(x, 4.35, z);
  }
  for (const [x, z, r] of [[4.05, 0.9, 0.46], [3.5, -2.4, 0.38]]) {
    const tank = new THREE.Mesh(new THREE.SphereGeometry(r, 32, 20), whiteMat);
    tank.castShadow = tank.receiveShadow = true;
    onPad(tank, x, z, r + 0.16);
    const legs = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.72, r * 0.8, 0.3, 16, 1, true), steelMat);
    onPad(legs, x, z, 0.15);
  }
  // Ares I en la plataforma vecina
  const aresHolder = new THREE.Group();
  onPad(aresHolder, -2.9, -1.4, 0.03);
  loadGlb("ares_rocket.glb", 2.7, (m) => aresHolder.add(m), { ground: true });

  // Botón diegético "INICIAR VIAJE"
  const launchButton = createLaunchButton();
  const LAUNCH_BTN_Y = 1.0;
  launchButton.position.set(-4.9, LAUNCH_BTN_Y, 4.2);
  launchButton.renderOrder = 25;
  padGroup.add(launchButton);

  // Partículas: vapor criogénico + chispas de ignición
  const steam = new ParticleSystem(1400, { color: [0.92, 0.94, 0.97], size: 1.0 });
  const sparks = new ParticleSystem(500, { color: [1.0, 0.55, 0.15], size: 0.25, blending: THREE.AdditiveBlending });
  scene.add(steam.mesh, sparks.mesh);

  // ---- 5.4 Tripulación chilena: JAVIER, GONZALO y CRISTÓBAL (3 astronautas articulados) ----
  const CREW = [
    { key: "javier", name: TEAM[0].name, role: TEAM[0].role, color: "#38bdf8", start: V3(-1.95, 0, 2.55), tagY: 1.62 },
    { key: "gonzalo", name: TEAM[1].name, role: TEAM[1].role, color: "#a78bfa", start: V3(-0.75, 0, 2.95), tagY: 1.3 },
    { key: "cristobal", name: TEAM[2].name, role: TEAM[2].role, color: "#fbbf24", start: V3(-3.15, 0, 2.05), tagY: 1.94 },
  ];
  const astroState = { phase: "wave", t0: 0, boardDur: 6.5, clips: null, root: null, fallback: false, members: [] };
  const HATCH = V3(ROCKET_X - 0.3, 2.62, ROCKET_Z + 0.08);
  const idleAstronautSlots = [];
  let astronautTemplate = null;

  // Bandera de Chile compartida por toda la tripulación.
  const chileFlagTexture = (() => {
    const cv = document.createElement("canvas");
    cv.width = 300; cv.height = 200;
    const c = cv.getContext("2d");
    c.fillStyle = "#ffffff"; c.fillRect(0, 0, 300, 100);
    c.fillStyle = "#0039a6"; c.fillRect(0, 0, 100, 100);
    c.fillStyle = "#d52b1e"; c.fillRect(0, 100, 300, 100);
    c.fillStyle = "#ffffff";
    c.beginPath();
    for (let i = 0; i < 10; i++) {
      const r = i % 2 ? 14 : 34, a = (i / 10) * Math.PI * 2 - Math.PI / 2;
      c.lineTo(50 + Math.cos(a) * r, 50 + Math.sin(a) * r);
    }
    c.fill();
    const tex = new THREE.CanvasTexture(cv);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.anisotropy = Math.min(8, maxAniso);
    return tex;
  })();
  function makeCrewFlag() {
    const flag = new THREE.Mesh(
      new THREE.PlaneGeometry(0.42, 0.28, 12, 6),
      new THREE.MeshStandardMaterial({ map: chileFlagTexture, side: THREE.DoubleSide, roughness: 0.8, envMapIntensity: 0.7 }),
    );
    flag.position.set(-0.24, 0.98, 0.02);
    flag.rotation.y = 0.18;
    flag.userData.isCrewFlag = true;
    return flag;
  }
  // Etiqueta 3D flotante en una línea: "JAVIER · Estudiante Ingeniería Informática".
  function makeCrewTag(member) {
    const cv = document.createElement("canvas");
    cv.width = 1800; cv.height = 176;
    const c = cv.getContext("2d");
    const drawTag = () => {
      c.clearRect(0, 0, 1800, 176);
      c.textBaseline = "middle";
      c.font = "400 56px 'Nasalization', 'Michroma', 'Inter', sans-serif";
      const nameW = c.measureText(member.name).width;
      c.font = "600 46px 'Inter', 'Public Sans', sans-serif";
      const roleText = ` · ${member.role}`;
      const total = 92 + nameW + c.measureText(roleText).width + 40;
      const x0 = (1800 - total) / 2;
      c.fillStyle = "rgba(2, 8, 18, 0.9)";
      roundRect(c, x0, 14, total, 148, 74); c.fill();
      c.strokeStyle = member.color; c.lineWidth = 5;
      roundRect(c, x0, 14, total, 148, 74); c.stroke();
      c.fillStyle = member.color;
      c.beginPath(); c.arc(x0 + 52, 88, 16, 0, Math.PI * 2); c.fill();
      c.fillStyle = "#ffffff";
      c.font = "400 56px 'Nasalization', 'Michroma', 'Inter', sans-serif";
      c.fillText(member.name, x0 + 86, 90);
      c.fillStyle = "rgba(219, 234, 254, 0.98)";
      c.font = "600 46px 'Inter', 'Public Sans', sans-serif";
      c.fillText(roleText, x0 + 86 + nameW, 92);
    };
    drawTag();
    const tex = new THREE.CanvasTexture(cv);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.anisotropy = Math.min(8, maxAniso);
    const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false, depthTest: false }));
    sprite.scale.set(2.9, 0.284, 1);
    sprite.position.set(0, member.tagY ?? 1.4, 0);
    sprite.renderOrder = 30;
    const redraw = () => { drawTag(); tex.needsUpdate = true; };
    document.fonts?.ready?.then(redraw);
    document.fonts?.load?.("400 56px Nasalization").then(redraw).catch(() => {});
    return sprite;
  }
  function decorateCrewFigure(fig, member) {
    fig.add(makeCrewFlag());
    fig.add(makeCrewTag(member));
    fig.userData.member = member;
    return fig;
  }
  function buildFallbackAstronaut(member = CREW[0]) {
    const g = new THREE.Group();
    const suit = new THREE.MeshStandardMaterial({ color: 0xe8ecf2, roughness: 0.55, metalness: 0.05 });
    const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.14, 0.32, 6, 12), suit);
    body.position.y = 0.42;
    const helmet = new THREE.Mesh(new THREE.SphereGeometry(0.13, 20, 16), new THREE.MeshStandardMaterial({ color: 0xc9a227, metalness: 1, roughness: 0.15 }));
    helmet.position.y = 0.78;
    const pack = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.3, 0.12), suit);
    pack.position.set(0, 0.5, -0.17);
    const armPivot = new THREE.Group();
    armPivot.position.set(0.17, 0.62, 0);
    const arm = new THREE.Mesh(new THREE.CapsuleGeometry(0.045, 0.3, 4, 8), suit);
    arm.position.y = -0.15;
    armPivot.add(arm);
    g.add(body, helmet, pack, armPivot);
    decorateCrewFigure(g, member);
    g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
    g.userData.armPivot = armPivot;
    return g;
  }
  function setupCrewActions(member, root, clips) {
    member.root = root;
    member.clips = clips;
    member.actions = {};
    if (!clips?.length) {
      member.fallback = true;
      member.armPivot = root.userData.armPivot ?? null;
      return;
    }
    const mixer = new THREE.AnimationMixer(root);
    for (const name of ["wave", "board", "idle"]) {
      const clip = clips.find((c) => c.name === name) ?? clips[0];
      const a = mixer.clipAction(clip);
      a.setLoop(name === "board" ? THREE.LoopOnce : THREE.LoopRepeat, Infinity);
      a.clampWhenFinished = true;
      member.actions[name] = a;
    }
    member.actions.wave?.play();
    member.mixer = mixer;
    mixers.push(mixer);
  }
  // Tres holders en el pad: saludan, caminan a la torre, suben en el ascensor y cruzan el brazo de acceso.
  astroState.members = CREW.map((member, idx) => {
    const holder = new THREE.Group();
    const start = member.start.clone();
    start.y = padSurfaceY(start.x, start.z) + 0.02;
    holder.position.copy(start);
    padGroup.add(holder);
    const liftX = TOWER_X + 0.42, liftZ = TOWER_Z + 0.5 + idx * 0.12;
    const groundY = padSurfaceY(liftX, liftZ) + 0.05;
    const path = [start.clone(), V3(liftX + 0.3, groundY, liftZ + 0.9), V3(liftX, groundY, liftZ), V3(liftX, HATCH.y, liftZ), HATCH.clone()];
    const lens = [0];
    for (let k = 1; k < path.length; k++) lens.push(lens[k - 1] + path[k].distanceTo(path[k - 1]));
    return { ...member, idx, holder, start, boardPath: path, boardLens: lens, phase: "wave", actions: {}, root: null };
  });
  function placeIdleAstronauts() {
    for (const slot of idleAstronautSlots) {
      if (slot.filled) continue;
      let fig;
      if (astronautTemplate && !astroState.fallback) {
        fig = SkeletonUtils.clone(astronautTemplate);
        decorateCrewFigure(fig, slot.member);
        if (astroState.clips?.length) {
          const mixer = new THREE.AnimationMixer(fig);
          const idle = astroState.clips.find((c) => c.name === "idle") ?? astroState.clips[0];
          const a = mixer.clipAction(idle);
          a.time = Math.random() * idle.duration;
          a.play();
          mixers.push(mixer);
        }
      } else {
        fig = buildFallbackAstronaut(slot.member);
      }
      slot.parent.add(fig);
      slot.filled = true;
      slot.fig = fig;
    }
  }
  loadGlb(
    "astronaut_guide.glb",
    1.0,
    (m, clips) => {
      astronautTemplate = m;
      astroState.clips = clips;
      for (const member of astroState.members) {
        const fig = SkeletonUtils.clone(m);
        decorateCrewFigure(fig, member);
        member.holder.add(fig);
        setupCrewActions(member, fig, clips);
      }
      astroState.root = astroState.members[0]?.root ?? null;
      astroState.fallback = astroState.members.every((mbr) => mbr.fallback);
      placeIdleAstronauts();
    },
    { ground: true, kind: "suit" },
  );
  // Si el GLB no llega en 20 s (fallo de red), tres figuras articuladas de respaldo con bandera de Chile
  setTimeout(() => {
    if (astroState.root) return;
    for (const member of astroState.members) {
      const fb = buildFallbackAstronaut(member);
      member.holder.add(fb);
      setupCrewActions(member, fb, []);
    }
    astroState.root = astroState.members[0]?.root ?? null;
    astroState.fallback = true;
    placeIdleAstronauts();
  }, 20000);
  /** Tres exploradores que recorren y escanean el terreno (haz aditivo de su color) en Luna y Jezero. */
  function addExplorers(parent, center, heightFn) {
    CREW.forEach((member, idx) => {
      const h = new THREE.Group();
      parent.add(h);
      const scanGeo = new THREE.ConeGeometry(0.2, 0.95, 20, 1, true);
      scanGeo.translate(0, -0.475, 0);
      const scan = new THREE.Mesh(scanGeo, new THREE.MeshBasicMaterial({ color: new THREE.Color(member.color), transparent: true, opacity: 0.16, side: THREE.DoubleSide, depthWrite: false, blending: THREE.AdditiveBlending }));
      scan.position.set(0, 0.66, 0.16);
      h.add(scan);
      idleAstronautSlots.push({
        parent: h, scan, member, heightFn, filled: false,
        center: V3(center.x + (idx - 1) * 1.15, 0, center.z + (idx % 2) * 0.8),
        radius: 0.5 + idx * 0.14,
        speed: (idx % 2 ? -1 : 1) * (0.2 + idx * 0.04),
        phase: idx * 2.1,
      });
    });
  }

  // ---- 5.5 Narradores: el astronauta guía (GLB con esqueleto) proyecta la pantalla de 3.1 × 1.95 m ----
  const BOARD_W = 3.1;
  const narrators = [];
  const guideSlots = [];
  let guideTemplate = null;
  let guideClips = [];
  function spawnGuides() {
    if (!guideTemplate) return;
    for (const slot of guideSlots) {
      if (slot.filled) continue;
      const fig = SkeletonUtils.clone(guideTemplate);
      slot.parent.add(fig);
      slot.fig = fig;
      const idle = guideClips.find((c) => c.name === "idle") ?? guideClips[0];
      if (idle) {
        const mixer = new THREE.AnimationMixer(fig);
        const action = mixer.clipAction(idle);
        action.time = Math.random() * idle.duration;
        action.play();
        mixers.push(mixer);
      }
      slot.filled = true;
    }
  }
  loadGlb("astronaut_guide.glb", 1.55, (m, clips) => {
    guideTemplate = m;
    guideClips = clips;
    spawnGuides();
  }, { ground: true, kind: "suit" });

  function addNarrator(stopIndex, feet, { zeroG = false, side = 1 } = {}) {
    const stop = STOPS[stopIndex];
    const cam = rigFrame(stopIndex).cam;
    const holder = new THREE.Group();
    holder.position.copy(feet);
    holder.rotation.y = Math.atan2(cam.x - feet.x, cam.z - feet.z);
    scene.add(holder);
    const guideHolder = new THREE.Group();
    guideHolder.rotation.y = side * 0.3;
    holder.add(guideHolder);
    const slot = { parent: guideHolder, filled: false, fig: null, projector: null };
    guideSlots.push(slot);

    const board = createHologramBoard(stop, BOARD_W);
    board.position.set(side * (BOARD_W / 2 + 0.5), 1.78, -0.12);
    board.rotation.y = -side * 0.2;
    board.renderOrder = 22;
    holder.add(board);
    board.updateMatrix();
    const hw = BOARD_W / 2, hh = board.userData.height / 2;
    const corners = [[-hw, -hh], [hw, -hh], [hw, hh], [-hw, hh]].map(([x, y]) => new THREE.Vector3(x, y, 0).applyMatrix4(board.matrix));
    const apex = new THREE.Vector3(side * 0.1, 0.85, 0.35);
    const positions = new Float32Array(36), uvs = new Float32Array(24);
    for (let k = 0; k < 4; k++) {
      const a = corners[k], b = corners[(k + 1) % 4];
      positions.set([apex.x, apex.y, apex.z, a.x, a.y, a.z, b.x, b.y, b.z], k * 9);
      uvs.set([0.5, 0, 0, 1, 1, 1], k * 6);
    }
    const beamGeo = new THREE.BufferGeometry();
    beamGeo.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    beamGeo.setAttribute("uv", new THREE.BufferAttribute(uvs, 2));
    const beam = new THREE.Mesh(
      beamGeo,
      new THREE.ShaderMaterial({
        uniforms: { uTime: { value: 0 }, uColor: { value: new THREE.Color(stop.color) }, uOpacity: { value: 0.2 } },
        vertexShader: BASIC_UV_VERT,
        fragmentShader: BEAM_FRAG,
        transparent: true,
        depthWrite: false,
        side: THREE.DoubleSide,
        blending: THREE.AdditiveBlending,
      }),
    );
    beam.frustumCulled = false;
    beam.renderOrder = 21;
    holder.add(beam);
    const lens = new THREE.Sprite(new THREE.SpriteMaterial({ map: glintTexture, color: new THREE.Color(stop.color), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    lens.scale.setScalar(0.4);
    lens.position.copy(apex);
    holder.add(lens);
    narrators.push({ holder, slot, beam, lens, apex, baseY: feet.y, zeroG, phase: stopIndex * 1.7 });
    return holder;
  }
  /** Punto de pantalla estándar del narrador: astronauta abajo al centro, pantalla ocupando el tercio derecho. */
  const narratorSpot = (i) => viewPoint(i, 5.0, -0.01, -0.76);

  // PARADA 01: el narrador flota en gravedad cero frente al complejo de lanzamiento.
  addNarrator(0, narratorSpot(0), { zeroG: true });

  // ---- 5.6 PARADA 02 · Complejo orbital LEO ----
  const leoGroup = new THREE.Group();
  leoGroup.position.copy(SITE.leo);
  scene.add(leoGroup);
  const issHolder = new THREE.Group();
  const issTilt = new THREE.Group();
  issTilt.rotation.set(0.5, 0, 0.18);
  issTilt.add(issHolder);
  leoGroup.add(issTilt);
  loadGlb("iss_detailed.glb", 6.4, (m) => { issHolder.add(m); registerSatellite(issHolder, m, 0x9fd4ff); });
  const canadarmHolder = new THREE.Group();
  canadarmHolder.position.set(2.9, 1.5, 0.9);
  canadarmHolder.rotation.set(0.3, 0.6, 0.2);
  leoGroup.add(canadarmHolder);
  loadGlb("canadarm_csa.glb", 2.7, (m) => { canadarmHolder.add(m); registerSatellite(canadarmHolder, m, 0x67e8f9); });
  const shuttleHolder = new THREE.Group();
  shuttleHolder.position.set(-6.2, 2.9, -3.4);
  shuttleHolder.rotation.set(0.25, 0.9, 0.3);
  leoGroup.add(shuttleHolder);
  loadGlb("space_shuttle.glb", 3.9, (m) => { shuttleHolder.add(m); registerSatellite(shuttleHolder, m, 0xffd7a0); });
  // Hubble orbita la estación en un plano inclinado que nunca cruza la cámara.
  const hubbleOrbit = new THREE.Group();
  hubbleOrbit.rotation.set(Math.PI / 2 - 0.42, 0, 0.3);
  hubbleOrbit.position.z = -2.5;
  leoGroup.add(hubbleOrbit);
  const hubbleHolder = new THREE.Group();
  hubbleHolder.position.set(7.6, 0, 0);
  hubbleOrbit.add(hubbleHolder);
  loadGlb("hubble_telescope.glb", 3.0, (m) => { hubbleHolder.add(m); registerSatellite(hubbleHolder, m, 0x93c5fd); });
  addNarrator(1, narratorSpot(1), { zeroG: true });
  // Balizas de navegación de la estación (rojo/verde, bloom)
  const stationBeacons = [];
  for (const [x, y, z, hex] of [[-3.1, 0.2, 0.0, [6, 0.4, 0.3]], [3.1, 0.2, 0.0, [0.3, 6, 0.8]], [0, 1.9, -0.6, [6, 5, 3]]]) {
    const b = new THREE.Mesh(new THREE.SphereGeometry(0.05, 10, 10), new THREE.MeshBasicMaterial({ color: new THREE.Color(...hex) }));
    b.position.set(x, y, z);
    leoGroup.add(b);
    stationBeacons.push(b);
  }
  const earthshine = new THREE.PointLight(0x5aa9ff, 60, 60, 1.6);
  earthshine.position.set(-4, -9, 6);
  leoGroup.add(earthshine);

  // ---- 5.7 PARADA 03 · Bennu, JWST, Voyager y campo de rocas ----
  const deepGroup = new THREE.Group();
  deepGroup.position.copy(SITE.deep);
  scene.add(deepGroup);
  const bennuHolder = new THREE.Group();
  deepGroup.add(bennuHolder);
  loadGlb("asteroid_bennu.glb", 5.4, (m) => {
    m.traverse((c) => {
      if (c.isMesh) {
        c.material = new THREE.MeshStandardMaterial({ map: deimosTex, color: 0xe3dbcf, bumpMap: deimosTex, bumpScale: 0.35, normalMap: regolithNormal, normalScale: new THREE.Vector2(0.9, 0.9), roughness: 0.97, metalness: 0.0, envMapIntensity: 0.45 });
        c.castShadow = c.receiveShadow = true;
      }
    });
    bennuHolder.add(m);
  }, { upgrade: false });
  // JWST describe su órbita de halo alrededor de L2; Voyager rodea Bennu en un plano inclinado.
  const jwstHalo = new THREE.Group();
  jwstHalo.position.set(-7.4, 2.6, 1.6);
  deepGroup.add(jwstHalo);
  const jwstHolder = new THREE.Group();
  jwstHolder.rotation.set(0.2, 0.7, -0.1);
  jwstHalo.add(jwstHolder);
  loadGlb("jwst_telescope.glb", 4.6, (m) => { jwstHolder.add(m); registerSatellite(jwstHolder, m, 0xffe08a); });
  const voyagerOrbit = new THREE.Group();
  voyagerOrbit.rotation.set(Math.PI / 2 - 0.5, 0, -0.4);
  voyagerOrbit.position.z = -4;
  deepGroup.add(voyagerOrbit);
  const voyagerHolder = new THREE.Group();
  voyagerHolder.position.set(9.6, 0, 0);
  voyagerOrbit.add(voyagerHolder);
  loadGlb("voyager_probe.glb", 3.8, (m) => { voyagerHolder.add(m); registerSatellite(voyagerHolder, m, 0xc4b5fd); });
  const deepNarratorPos = narratorSpot(2);
  {
    // Campo de rocas: se despeja el pasillo entre la cámara y el holograma.
    const mat = new THREE.MeshStandardMaterial({ map: deimosTex, color: 0x5e5751, normalMap: regolithNormal, normalScale: new THREE.Vector2(0.8, 0.8), roughness: 0.98, metalness: 0.0, envMapIntensity: 0.4 });
    const count = 90;
    const inst = new THREE.InstancedMesh(rockGeoA, mat, count);
    const d = new THREE.Object3D();
    const camLocal = rigFrame(2).cam.sub(SITE.deep);
    const aim = deepNarratorPos.clone().sub(SITE.deep).add(V3(1.6, 1.6, 0));
    const corridor = new THREE.Line3(camLocal, camLocal.clone().lerp(aim, 1.6));
    const closest = new THREE.Vector3();
    for (let i = 0; i < count; i++) {
      const a = i * 2.39996 + 0.7, r = 7 + ((i * 37) % 17);
      d.position.set(Math.cos(a) * r, ((i * 13) % 11) - 5.5, Math.sin(a) * r * 0.8 - 2);
      corridor.closestPointToPoint(d.position, true, closest);
      const s = closest.distanceTo(d.position) < 4.2 || d.position.distanceTo(camLocal) < 5 ? 0.0001 : 0.4 + ((i * 7) % 6) * 0.35;
      d.scale.set(s, s * 0.75, s * 0.9);
      d.rotation.set(i * 0.7, i * 1.1, i * 0.5);
      d.updateMatrix();
      inst.setMatrixAt(i, d.matrix);
    }
    inst.castShadow = inst.receiveShadow = true;
    deepGroup.add(inst);
  }
  addNarrator(2, deepNarratorPos, { zeroG: true });
  // Partículas CME (viento solar) a la deriva
  const cmeGeo = new THREE.BufferGeometry();
  {
    const n = 420, p = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) p.set([(Math.random() - 0.5) * 60, (Math.random() - 0.5) * 30, (Math.random() - 0.5) * 60], i * 3);
    cmeGeo.setAttribute("position", new THREE.BufferAttribute(p, 3));
  }
  const cmeParticles = new THREE.Points(cmeGeo, new THREE.PointsMaterial({ map: softDotTex, color: new THREE.Color(2.2, 1.1, 0.4), size: 0.35, transparent: true, opacity: 0.55, depthWrite: false, blending: THREE.AdditiveBlending, sizeAttenuation: true }));
  deepGroup.add(cmeParticles);
  const deepFill = new THREE.PointLight(0xffe6c8, 260, 70, 1.5);
  deepFill.position.set(7, 6, 15);
  deepGroup.add(deepFill);

  // ---- 5.8 PARADA 04 · Luna: la base se apoya en un casquete que sigue la curvatura (sin cilindros) ----
  const MOON_R = 16;
  const moonGroup = new THREE.Group();
  moonGroup.position.copy(SITE.moon).add(V3(0, -MOON_R, 0));
  scene.add(moonGroup);
  const moonMesh = new THREE.Mesh(
    new THREE.SphereGeometry(MOON_R, 160, 112),
    new THREE.MeshStandardMaterial({ map: moonTex, bumpMap: moonTex, bumpScale: 0.3, normalMap: planetDetailNormal, normalScale: new THREE.Vector2(0.3, 0.3), roughness: 0.94, metalness: 0.0, envMapIntensity: 0.35 }),
  );
  moonMesh.rotation.set(0.5, 1.1, 0.25);
  moonMesh.receiveShadow = true;
  moonGroup.add(moonMesh);
  const moonIsland = new THREE.Group();
  moonIsland.position.copy(SITE.moon);
  scene.add(moonIsland);
  const MOON_CAP_R = 8.2;
  const LANDER_XZ = [-1.0, -1.1];
  const moonDetail = (x, z) => {
    let h = (fbmJs(x * 0.9 + 20, z * 0.9 + 5) - 0.5) * 0.26;
    h += crater(x, z, -4.4, 1.2, 1.5, 0.4, 0.2);
    h += crater(x, z, 3.4, -2.6, 1.2, 0.32, 0.16);
    h += crater(x, z, 0.9, 2.4, 0.7, 0.2, 0.1);
    h += crater(x, z, -2.4, -4.4, 0.9, 0.24, 0.12);
    const flat = THREE.MathUtils.smoothstep(Math.hypot(x - LANDER_XZ[0], z - LANDER_XZ[1]), 1.3, 2.8);
    // El relieve se levanta sobre la esfera y se desvanece hacia el borde: nunca asoma la malla de debajo.
    const taper = 1 - THREE.MathUtils.smoothstep(Math.hypot(x, z), MOON_CAP_R * 0.55, MOON_CAP_R * 0.95);
    return 0.03 + taper * (0.5 + h * (0.15 + 0.85 * flat));
  };
  const moonHeight = (x, z) => Math.sqrt(Math.max(0, MOON_R * MOON_R - x * x - z * z)) - MOON_R + moonDetail(x, z);
  const moonIsleMesh = new THREE.Mesh(
    buildSphericalCapGeometry(MOON_R, MOON_CAP_R, { rings: 84, sectors: 192, heightFn: moonDetail, fadeFrom: 0.8 }),
    new THREE.MeshStandardMaterial({ map: deimosTex, color: 0xb9b8b3, normalMap: regolithNormal, normalScale: new THREE.Vector2(0.8, 0.8), roughness: 0.97, metalness: 0.0, envMapIntensity: 0.4, vertexColors: true, transparent: true }),
  );
  moonIsleMesh.receiveShadow = true;
  moonIsleMesh.renderOrder = 1;
  moonIsland.add(moonIsleMesh);
  scatterRocks(moonIsland, 46, { radiusMin: 2.4, radiusMax: 6.6, scale: 0.4, color: 0x8f8d88, heightFn: moonHeight, seed: 3 });
  const apolloHolder = new THREE.Group();
  apolloHolder.position.set(LANDER_XZ[0], moonHeight(LANDER_XZ[0], LANDER_XZ[1]), LANDER_XZ[1]);
  apolloHolder.rotation.y = 0.5;
  moonIsland.add(apolloHolder);
  loadGlb("apollo_lander.glb", 2.5, (m) => apolloHolder.add(m), { ground: true });
  const lroOrbit = new THREE.Group();
  lroOrbit.rotation.set(0.5, 0, 0.35);
  moonGroup.add(lroOrbit);
  const lroHolder = new THREE.Group();
  lroHolder.position.set(MOON_R + 3.2, 0, 0);
  lroOrbit.add(lroHolder);
  loadGlb("lro_orbiter.glb", 2.5, (m) => { lroHolder.add(m); registerSatellite(lroHolder, m, 0xdbeafe); });
  {
    const spot = narratorSpot(3).sub(SITE.moon);
    addNarrator(3, SITE.moon.clone().add(V3(spot.x, moonHeight(spot.x, spot.z), spot.z)));
  }
  addExplorers(moonIsland, V3(-2.3, 0, 2.2), moonHeight);
  const moonModules = new THREE.Group();
  moonModules.position.set(2.2, moonHeight(2.2, -3.6), -3.6);
  moonIsland.add(moonModules);
  // Rover lunar: instancia escalada del Perseverance real (se rellena al cargar el GLB).
  const lunarRover = new THREE.Group();
  moonIsland.add(lunarRover);
  const lunarRoverDrive = { center: V3(LANDER_XZ[0], 0, LANDER_XZ[1]), radius: 2.75, angle: 0.6, speed: 0.1 };

  // ---- 5.9 PARADA 05 · Marte orbital con Fobos, Deimos y MGS ----
  const MARS_R = 12;
  const marsGroup = new THREE.Group();
  marsGroup.position.copy(SITE.mars);
  scene.add(marsGroup);
  const marsMesh = new THREE.Mesh(
    new THREE.SphereGeometry(MARS_R, 160, 112),
    new THREE.MeshStandardMaterial({ map: marsTex, bumpMap: marsTex, bumpScale: 0.42, normalMap: planetDetailNormal, normalScale: new THREE.Vector2(0.35, 0.35), roughness: 0.92, metalness: 0.0, envMapIntensity: 0.4 }),
  );
  marsMesh.receiveShadow = true;
  marsGroup.add(marsMesh);
  // Atmósfera marciana real: un velo Fresnel finísimo en el limbo, sin aro naranja.
  marsGroup.add(makeAtmosphere(MARS_R * 1.028, 1.028, 0xe9b98f, 0x1a0a05, 2.4, 2.6, 0.5, THREE.BackSide));
  marsGroup.add(makeAtmosphere(MARS_R * 1.012, 1.012, 0xd99a6c, 0x120703, 7.0, 3.0, 0.28, THREE.FrontSide));
  function makeMoonlet(tex, radius, stretch) {
    const geo = new THREE.DodecahedronGeometry(radius, 3);
    const p = geo.attributes.position;
    const v = new THREE.Vector3();
    for (let i = 0; i < p.count; i++) {
      v.fromBufferAttribute(p, i);
      v.multiplyScalar(1 + (fbmJs(v.x * 2.2, v.z * 2.2 + v.y) - 0.5) * 0.35);
      p.setXYZ(i, v.x * stretch[0], v.y * stretch[1], v.z * stretch[2]);
    }
    geo.computeVertexNormals();
    const m = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ map: tex, bumpMap: tex, bumpScale: 0.25, normalMap: regolithNormal, normalScale: new THREE.Vector2(0.5, 0.5), roughness: 0.95, metalness: 0.0, envMapIntensity: 0.4 }));
    m.castShadow = m.receiveShadow = true;
    return m;
  }
  const phobos = makeMoonlet(phobosTex, 1.15, [1.35, 0.95, 1.05]);
  const deimos = makeMoonlet(deimosTex, 0.72, [1.2, 0.9, 1.0]);
  marsGroup.add(phobos, deimos);
  const mgsOrbit = new THREE.Group();
  mgsOrbit.rotation.x = 0.9;
  marsGroup.add(mgsOrbit);
  const mgsHolder = new THREE.Group();
  mgsHolder.position.set(MARS_R + 3.6, 0, 0);
  mgsOrbit.add(mgsHolder);
  loadGlb("mars_mgs_orbiter.glb", 2.4, (m) => { mgsHolder.add(m); registerSatellite(mgsHolder, m, 0xfdba74); });
  addNarrator(4, narratorSpot(4), { zeroG: true });

  // ---- 5.10 PARADA 06 · Islote del cráter Jezero (PBR 2K) ----
  const jezero = new THREE.Group();
  jezero.position.copy(SITE.jezero);
  scene.add(jezero);
  // Planeta de soporte: el diorama de Jezero se apoya en una superficie marciana real.
  const jezPlanet = new THREE.Mesh(
    new THREE.SphereGeometry(46, 160, 112),
    new THREE.MeshStandardMaterial({ map: marsTex, bumpMap: marsTex, bumpScale: 0.5, normalMap: planetDetailNormal, normalScale: new THREE.Vector2(0.3, 0.3), roughness: 0.95, metalness: 0.0, envMapIntensity: 0.35 }),
  );
  jezPlanet.position.y = -46;
  jezPlanet.receiveShadow = true;
  jezero.add(jezPlanet);
  const JEZ_R = 9.2;
  const jezHeight = (x, z) => {
    let h = (fbmJs(x * 0.55 + 3, z * 0.55 + 9) - 0.5) * 0.5 + (fbmJs(x * 2.2, z * 2.2) - 0.5) * 0.08;
    h += crater(x, z, -2.8, 2.6, 3.0, 0.6, 0.42);
    h += crater(x, z, 4.6, -4.2, 1.2, 0.3, 0.18);
    const flat = THREE.MathUtils.smoothstep(Math.hypot(x + 1.6, z + 2.6), 2.4, 4.2);
    return h * (0.1 + 0.9 * flat);
  };
  const jezMesh = new THREE.Mesh(
    buildIslandGeometry(JEZ_R, jezHeight, { skirt: 3.0 }),
    new THREE.MeshStandardMaterial({ map: marsGroundColor, normalMap: marsGroundNormal, roughnessMap: marsGroundRough, normalScale: new THREE.Vector2(1.0, 1.0), roughness: 1.0, metalness: 0.0, envMapIntensity: 0.45 }),
  );
  jezMesh.castShadow = jezMesh.receiveShadow = true;
  jezero.add(jezMesh);
  scatterRocks(jezero, 70, { radiusMin: 4.6, radiusMax: 8.6, scale: 0.55, color: 0x8a5a3c, heightFn: jezHeight, seed: 5 });
  const hduHolder = new THREE.Group();
  hduHolder.position.set(-3.9, jezHeight(-3.9, -2.5), -2.5);
  hduHolder.rotation.y = 0.5;
  jezero.add(hduHolder);
  loadGlb("nasa_habitat_hdu.glb", 3.7, (m) => hduHolder.add(m), { ground: true });

  /**
   * El GLB oficial trae las 6 ruedas en una sola malla. Se separan por racimos (lado × eje)
   * y cada una recibe su propio pivote sobre el eje real para poder girar de verdad.
   */
  function splitRoverWheels(root) {
    const node = root.getObjectByName("Wheels_objs");
    if (!node) return;
    const meshes = [];
    node.traverse((o) => { if (o.isMesh && o.geometry?.index && o.geometry.attributes.position) meshes.push(o); });
    if (!meshes.length) return;
    const tris = [];
    let zMin = Infinity, zMax = -Infinity;
    for (const mesh of meshes) {
      const p = mesh.geometry.attributes.position, ix = mesh.geometry.index;
      for (let t = 0; t < ix.count; t += 3) {
        const a = ix.getX(t), b = ix.getX(t + 1), c = ix.getX(t + 2);
        const x = (p.getX(a) + p.getX(b) + p.getX(c)) / 3, z = (p.getZ(a) + p.getZ(b) + p.getZ(c)) / 3;
        tris.push({ mesh, a, b, c, x, z });
        zMin = Math.min(zMin, z);
        zMax = Math.max(zMax, z);
      }
    }
    const axle = [zMin, (zMin + zMax) / 2, zMax];
    const nearestAxle = (z) => (Math.abs(z - axle[0]) < Math.abs(z - axle[1]) ? (Math.abs(z - axle[0]) < Math.abs(z - axle[2]) ? 0 : 2) : Math.abs(z - axle[1]) < Math.abs(z - axle[2]) ? 1 : 2);
    for (let it = 0; it < 6; it++) {
      const sum = [0, 0, 0], n = [0, 0, 0];
      for (const t of tris) { const k = nearestAxle(t.z); sum[k] += t.z; n[k]++; }
      for (let k = 0; k < 3; k++) if (n[k]) axle[k] = sum[k] / n[k];
    }
    const boxes = Array.from({ length: 6 }, () => new THREE.Box3());
    const v = new THREE.Vector3();
    for (const t of tris) {
      t.k = (t.x < 0 ? 0 : 3) + nearestAxle(t.z);
      const p = t.mesh.geometry.attributes.position;
      for (const i of [t.a, t.b, t.c]) boxes[t.k].expandByPoint(v.fromBufferAttribute(p, i));
    }
    for (const mesh of meshes) {
      const container = new THREE.Group();
      container.position.copy(mesh.position);
      container.quaternion.copy(mesh.quaternion);
      container.scale.copy(mesh.scale);
      mesh.parent.add(container);
      for (let k = 0; k < 6; k++) {
        const idx = [];
        for (const t of tris) if (t.mesh === mesh && t.k === k) idx.push(t.a, t.b, t.c);
        if (!idx.length) continue;
        const geo = new THREE.BufferGeometry();
        for (const [name, attr] of Object.entries(mesh.geometry.attributes)) geo.setAttribute(name, attr);
        geo.setIndex(idx);
        const center = boxes[k].getCenter(new THREE.Vector3());
        const pivot = new THREE.Group();
        pivot.position.copy(center);
        pivot.userData.isWheel = true;
        const wheel = new THREE.Mesh(geo, mesh.material);
        wheel.position.copy(center).negate();
        wheel.castShadow = wheel.receiveShadow = true;
        pivot.add(wheel);
        container.add(pivot);
      }
      mesh.visible = false;
    }
  }
  const collectWheels = (root) => {
    const out = [];
    root.traverse((o) => { if (o.userData?.isWheel) out.push(o); });
    return out;
  };
  const perseveranceHolder = new THREE.Group();
  jezero.add(perseveranceHolder);
  let perseveranceWheels = [];
  let lunarWheels = [];
  loadGlb("perseverance_rover.glb", 2.3, (m) => {
    try {
      splitRoverWheels(m);
    } catch (err) {
      console.warn("[assets] No se pudieron separar las ruedas del rover:", err?.message ?? err);
    }
    perseveranceHolder.add(m);
    perseveranceWheels = collectWheels(m);
    // Mismo modelo oficial, a escala reducida, patrullando la base lunar.
    const twin = SkeletonUtils.clone(m);
    twin.scale.setScalar(0.72);
    lunarRover.add(twin);
    lunarWheels = collectWheels(twin);
  }, { ground: true });
  const perseveranceDrive = { center: V3(-1.2, 0, 3.0), radius: 1.9, angle: 0.7, speed: 0.11 };
  const ingenuityHolder = new THREE.Group();
  const INGENUITY_BASE = V3(-4.6, 2.9, 1.2);
  ingenuityHolder.position.copy(INGENUITY_BASE);
  jezero.add(ingenuityHolder);
  const ingenuityRotors = [];
  loadGlb("ingenuity_mars.glb", 1.25, (m) => {
    ingenuityHolder.add(m);
    for (const name of ["rotors_01", "rotors_02"]) {
      const rotor = m.getObjectByName(name);
      if (rotor) ingenuityRotors.push(rotor);
    }
  });
  {
    const spot = narratorSpot(5).sub(SITE.jezero);
    addNarrator(5, SITE.jezero.clone().add(V3(spot.x, jezHeight(spot.x, spot.z), spot.z)));
  }
  addExplorers(jezero, V3(0.5, 0, 0.6), jezHeight);
  const marsModules = new THREE.Group();
  marsModules.position.set(0.4, jezHeight(0.4, -2.8), -2.8);
  jezero.add(marsModules);
  // Luz cálida del hábitat
  const hduLight = new THREE.PointLight(0xffc98a, 18, 14, 1.8);
  hduLight.position.set(-3.9, 2.2, -2.5);
  jezero.add(hduLight);

  // ---- 5.11 Portales: nebulosa-vórtice volumétrica 100% GLSL (4 capas con paralaje, sin toros ni marcos) ----
  const portals = [];
  GATES.forEach((pos, i) => {
    const u = GATE_U[i];
    const tangent = flightCurve.getTangentAt(u).normalize();
    const holder = new THREE.Group();
    holder.position.copy(pos);
    holder.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), tangent);
    scene.add(holder);
    const [a, b] = GATE_COLORS[i];
    const mats = [];
    for (let layer = 0; layer < 4; layer++) {
      const mat = new THREE.ShaderMaterial({
        uniforms: { uTime: { value: 0 }, uIntensity: { value: 1 }, uLayer: { value: layer }, uColorA: { value: new THREE.Color(a) }, uColorB: { value: new THREE.Color(b) } },
        vertexShader: BASIC_UV_VERT,
        fragmentShader: PORTAL_FRAG,
        transparent: true,
        depthWrite: false,
        side: THREE.DoubleSide,
        blending: THREE.AdditiveBlending,
      });
      const size = 10.5 + layer * 2.6;
      const disc = new THREE.Mesh(new THREE.PlaneGeometry(size, size), mat);
      disc.position.z = -layer * 1.5;
      disc.renderOrder = 15 - layer;
      holder.add(disc);
      mats.push(mat);
    }
    const light = new THREE.PointLight(b, 90, 48, 1.7);
    light.position.z = 1.2;
    holder.add(light);
    portals.push({ holder, mats, light, u });
  });
  // ---- 5.12 Cohete protagonista (Saturn V) + pluma con diamantes de Mach ----
  const ship = new THREE.Group();
  const rocketPivot = new THREE.Group();
  ship.add(rocketPivot);
  scene.add(ship);
  loadGlb("saturn_v_rocket.glb", 3.6, (m) => rocketPivot.add(m), { ground: true });
  const plumeMat = new THREE.ShaderMaterial({
    uniforms: { uTime: { value: 0 }, uIntensity: { value: 0 } },
    vertexShader: PLUME_VERT,
    fragmentShader: PLUME_FRAG,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
  });
  const plumeGroup = new THREE.Group();
  plumeGroup.position.set(0, 0, -1.25);
  for (let i = 0; i < 3; i++) {
    const p = new THREE.Mesh(new THREE.PlaneGeometry(0.78, 2.5), plumeMat);
    p.rotation.x = -Math.PI / 2;
    p.rotation.y = (i * Math.PI) / 3;
    p.rotateOnAxis(new THREE.Vector3(0, 1, 0), 0);
    plumeGroup.add(p);
  }
  // Orientamos el grupo: las planchas se extienden hacia -Z local del cohete
  plumeGroup.rotation.set(0, 0, 0);
  ship.add(plumeGroup);
  const engineLight = new THREE.PointLight(0xffb36b, 0, 26, 1.6);
  engineLight.position.set(0, 0, -0.9);
  ship.add(engineLight);
  const nozzleGlow = new THREE.Mesh(new THREE.SphereGeometry(0.2, 16, 16), new THREE.MeshBasicMaterial({ color: new THREE.Color(5, 3.2, 1.6), transparent: true, opacity: 0, depthWrite: false, blending: THREE.AdditiveBlending }));
  nozzleGlow.scale.set(1.1, 1.1, 0.45);
  nozzleGlow.position.z = -0.05;
  ship.add(nozzleGlow);

  // ---- 5.13 Estelas de warp (hijas de la cámara) ----
  const streakMat = new THREE.ShaderMaterial({
    uniforms: { uWarp: { value: 0 }, uTime: { value: 0 } },
    vertexShader: STREAK_VERT,
    fragmentShader: STREAK_FRAG,
    transparent: true,
    depthWrite: false,
    depthTest: false,
    blending: THREE.AdditiveBlending,
  });
  {
    const n = 420;
    const pos = new Float32Array(n * 2 * 3);
    const end = new Float32Array(n * 2);
    const seed = new Float32Array(n * 2);
    for (let i = 0; i < n; i++) {
      const x = (Math.random() - 0.5) * 70, y = (Math.random() - 0.5) * 44, z = -Math.random() * 140;
      const s = Math.random();
      pos.set([x, y, z, x, y, z], i * 6);
      end.set([0, 1], i * 2);
      seed.set([s, s], i * 2);
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.BufferAttribute(pos, 3));
    g.setAttribute("aEnd", new THREE.BufferAttribute(end, 1));
    g.setAttribute("aSeed", new THREE.BufferAttribute(seed, 1));
    const streaks = new THREE.LineSegments(g, streakMat);
    streaks.frustumCulled = false;
    streaks.renderOrder = 50;
    camera.add(streaks);
  }

  // ---- 5.14 Módulos dinámicos del simulador (cartas instaladas) ----
  const moduleMetal = new THREE.MeshStandardMaterial({ map: scifiColor, normalMap: scifiNormal, roughnessMap: scifiRough, color: 0xc7ccd4, metalness: 0.85, roughness: 0.35, envMapIntensity: 1.45 });
  function buildModules(parent, state, siteId) {
    while (parent.children.length) parent.remove(parent.children[0]);
    const counts = {};
    for (const inst of state.installed) counts[inst.id] = (counts[inst.id] || 0) + 1;
    const add = (mesh) => { mesh.castShadow = mesh.receiveShadow = true; parent.add(mesh); return mesh; };
    for (let i = 0; i < (counts["solar-panel"] || 0); i++) {
      const panel = add(new THREE.Mesh(new THREE.BoxGeometry(1.4, 0.05, 0.85), new THREE.MeshStandardMaterial({ color: 0x14264a, metalness: 0.7, roughness: 0.18, envMapIntensity: 1.6 })));
      panel.position.set(-1.6 - i * 1.25, 0.55, -0.4 - i * 0.35);
      panel.rotation.set(0.42, 0.1, 0);
      const post = add(new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.5, 8), moduleMetal));
      post.position.set(-1.6 - i * 1.25, 0.25, -0.4 - i * 0.35);
    }
    if (counts["regolith-wall"]) {
      const wall = add(new THREE.Mesh(
        new THREE.TorusGeometry(2.0 + counts["regolith-wall"] * 0.2, 0.28, 14, 48, Math.PI * 1.1),
        new THREE.MeshStandardMaterial({ map: siteId === "moon" ? moonTex : marsGroundColor, normalMap: regolithNormal, normalScale: new THREE.Vector2(0.8, 0.8), color: siteId === "moon" ? 0xbfc0bb : 0xb06a3f, roughness: 0.98 }),
      ));
      wall.position.set(0.4, 0.08, 0.3);
      wall.rotation.set(Math.PI / 2, 0, 0.6);
    }
    for (let i = 0; i < (counts["greenhouse"] || 0); i++) {
      const dome = add(new THREE.Mesh(
        new THREE.SphereGeometry(0.75, 28, 18, 0, Math.PI * 2, 0, Math.PI / 2),
        new THREE.MeshPhysicalMaterial({ color: 0x8ff2c0, transmission: 0.6, thickness: 0.4, roughness: 0.08, metalness: 0.0, transparent: true, opacity: 0.85, emissive: 0x16a34a, emissiveIntensity: 0.6 }),
      ));
      dome.position.set(1.9 + i * 1.7, 0.02, 0.9);
      const glow = add(new THREE.Mesh(new THREE.SphereGeometry(0.12, 10, 10), new THREE.MeshBasicMaterial({ color: new THREE.Color(0.8, 4.5, 2.0) })));
      glow.position.set(1.9 + i * 1.7, 0.4, 0.9);
    }
    for (let i = 0; i < (counts["water-recycler"] || 0); i++) {
      const tank = add(new THREE.Mesh(new THREE.CylinderGeometry(0.36, 0.36, 0.95, 24), new THREE.MeshStandardMaterial({ map: scifiColor, normalMap: scifiNormal, color: 0x7fc7ff, metalness: 0.8, roughness: 0.25, envMapIntensity: 1.5 })));
      tank.position.set(-1.2, 0.5, 1.4 + i * 0.9);
    }
    if (counts["storm-shelter"]) {
      const shield = add(new THREE.Mesh(
        new THREE.SphereGeometry(2.9, 36, 20, 0, Math.PI * 2, 0, Math.PI / 2),
        new THREE.MeshPhysicalMaterial({ color: 0x38bdf8, transparent: true, opacity: 0.12, roughness: 0.2, metalness: 0.0, side: THREE.DoubleSide, emissive: 0x38bdf8, emissiveIntensity: 0.35, depthWrite: false }),
      ));
      shield.position.set(0.4, 0, 0.3);
    }
    if (counts["big-antenna"]) {
      const mast = add(new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.05, 1.5, 10), moduleMetal));
      mast.position.set(2.4, 0.75, -1.6);
      const dish = add(new THREE.Mesh(new THREE.SphereGeometry(0.62, 28, 14, 0, Math.PI * 2, 0, Math.PI / 3), new THREE.MeshStandardMaterial({ color: 0xf5f5f0, metalness: 0.3, roughness: 0.35, side: THREE.DoubleSide, envMapIntensity: 1.4 })));
      dish.position.set(2.4, 1.55, -1.6);
      dish.rotation.set(-1.1, 0.4, 0);
      const tip = add(new THREE.Mesh(new THREE.SphereGeometry(0.04, 8, 8), new THREE.MeshBasicMaterial({ color: new THREE.Color(6, 0.6, 0.3) })));
      tip.position.set(2.4, 1.62, -1.6);
    }
  }
  engine.syncOutpost = (state) => {
    if (!state) return;
    buildModules(state.siteId === "moon" ? moonModules : marsModules, state, state.siteId);
    const other = state.siteId === "moon" ? marsModules : moonModules;
    while (other.children.length) other.remove(other.children[0]);
  };
  if (currentMission) engine.syncOutpost(currentMission.state);

  // ============================================================================
  // 6. ESTADO DE VUELO, SECUENCIA DE DESPEGUE Y NAVEGACIÓN ENTRE PARADAS
  // ============================================================================
  rocketPivot.rotation.x = Math.PI / 2; // la nariz (+Y del modelo) apunta a +Z local = dirección de vuelo
  const Z_AXIS = new THREE.Vector3(0, 0, 1);
  const Y_AXIS = new THREE.Vector3(0, 1, 0);

  const flight = {
    u: 0,
    stop: 0, // parada actual (o de origen durante un tránsito)
    toStop: 0,
    travelling: false,
    fromU: 0,
    toU: 0,
    t0: 0,
    dur: 1,
    progress: 0,
    launched: false,
    launching: false,
    launchT0: 0,
    queuedStop: null,
    manual: false, // la rueda del ratón controla u directamente
    seg: -1,
  };
  const throttle = { vel: 0 };
  const THROTTLE_MAX = 0.03; // fracción de la trayectoria por segundo (≈ 33 s de punta a punta)
  const THROTTLE_GAIN = 0.02; // por cada 100 px de rueda
  const fx = { warp: 0, flash: 0, shake: 0, plume: 0 };
  const orbit = { yaw: 0, pitch: 0, targetYaw: 0, targetPitch: 0, dragging: false, moved: 0, px: 0, py: 0 };
  const pointer = new THREE.Vector2(-2, -2);
  const raycaster = new THREE.Raycaster();
  let launchHot = false;
  let readyAt = null;
  let lastPortalSide = GATE_U.map(() => -1);

  // ---- 6.1 HUD compacto: insignia de parada + puntos de ruta ----
  const hudIndex = document.getElementById("hud-stop-index");
  const hudTitle = document.getElementById("hud-stop-title");
  const hudTelemetry = document.getElementById("hud-stop-telemetry");
  const hudBadge = document.getElementById("hud-stop-badge");
  const routeDots = document.getElementById("route-dots");
  const btnPrev = document.getElementById("btn-prev-stop");
  const btnNext = document.getElementById("btn-next-stop");
  const heroBrand = document.getElementById("hero-brand");
  if (routeDots) routeDots.innerHTML = STOPS.map(() => `<span class="route-dot"></span>`).join("");

  function updateHud(transitTo = null) {
    const i = transitTo ?? flight.stop;
    const stop = STOPS[i];
    if (hudIndex) hudIndex.textContent = transitTo != null ? `EN TRÁNSITO → PARADA 0${i + 1} / 06` : `PARADA 0${i + 1} / 06 · ${stop.window}`;
    if (hudTitle) hudTitle.textContent = stop.title;
    if (hudTelemetry) hudTelemetry.textContent = stop.hud();
    // La marca héroe solo habita la parada 01 para no tapar el resto del pitch.
    heroBrand?.classList.toggle("is-hidden", i !== 0);
    if (hudBadge) {
      hudBadge.classList.remove("is-updating");
      void hudBadge.offsetWidth; // reinicia la animación CSS
      hudBadge.classList.add("is-updating");
    }
    routeDots?.querySelectorAll(".route-dot").forEach((d, k) => {
      d.classList.toggle("done", k < i);
      d.classList.toggle("active", k === i);
    });
    if (btnPrev) btnPrev.disabled = flight.stop === 0 && !flight.travelling;
    if (btnNext) {
      btnNext.disabled = flight.stop === STOPS.length - 1 && !flight.travelling;
      btnNext.textContent = !flight.launched && !flight.launching ? "INICIAR VIAJE ▶" : "SIGUIENTE ▶";
    }
  }

  // ---- 6.1b Tarjeta final de agradecimientos (Parada 06) ----
  const thanksCard = document.getElementById("thanks-card");
  let thanksTimer = 0;
  function setThanks(show) {
    if (!thanksCard) return;
    clearTimeout(thanksTimer);
    if (!show) {
      thanksCard.classList.remove("show");
      thanksCard.setAttribute("aria-hidden", "true");
      return;
    }
    // Entra con calma: primero se lee el tablero de la parada, luego aparece el cierre.
    thanksTimer = setTimeout(() => {
      thanksCard.classList.add("show");
      thanksCard.setAttribute("aria-hidden", "false");
    }, PREFERS_REDUCED_MOTION ? 0 : 1800);
  }

  // ---- 6.2 Tránsitos sobre la curva ----
  function beginTravel(toStop, duration = null) {
    const from = flight.u;
    const to = STOP_U[toStop];
    flight.manual = false;
    throttle.vel = 0;
    setThanks(false);
    if (Math.abs(to - from) < 1e-4) { flight.travelling = false; return; }
    flight.travelling = true;
    flight.fromU = from;
    flight.toU = to;
    flight.toStop = toStop;
    flight.t0 = performance.now();
    // Duración proporcional a la distancia: un viaje se siente como viaje (4–9 s por tramo; recorrido completo ≈ 90 s)
    const legs = Math.abs(toStop - flight.stop) || 1;
    flight.dur = duration ?? (PREFERS_REDUCED_MOTION ? 600 : THREE.MathUtils.clamp(5600 * Math.sqrt(legs), 4500, 9500));
    flight.progress = 0;
    lastPortalSide = GATE_U.map((gu) => Math.sign(flight.u - gu) || -1);
    orbit.targetYaw = 0;
    orbit.targetPitch = 0;
    updateHud(toStop);
  }

  function arrive() {
    flight.travelling = false;
    flight.manual = false;
    flight.hudStop = null;
    flight.stop = flight.toStop;
    flight.u = flight.toU;
    updateHud();
    onStopArrived(flight.stop);
    setThanks(flight.stop === STOPS.length - 1);
    if (flight.queuedStop != null && flight.queuedStop !== flight.stop) {
      const q = flight.queuedStop;
      flight.queuedStop = null;
      beginTravel(q);
    } else {
      flight.queuedStop = null;
    }
  }

  function startLaunch(travelMs = 8500) {
    if (flight.launched || flight.launching) return;
    const now = performance.now();
    // Si la tripulación aún saluda, aborda a paso rápido; la ignición espera a que cierren la escotilla.
    if (astroState.phase === "wave") {
      astroState.boardDur = 3.2;
      setAstronautPhase("board");
    }
    flight.launching = true;
    flight.launchTravelMs = travelMs;
    flight.launchT0 = now + crewBoardingRemaining(now) * 1000;
    launchButton.userData.setHot(true);
    container?.classList.remove("hover-ui");
    document.getElementById("hint-toast")?.classList.add("hidden");
    heroBrand?.classList.add("is-hidden");
    updateHud();
  }

  function goToStop(i) {
    const target = THREE.MathUtils.clamp(i, 0, STOPS.length - 1);
    if (!flight.launched) {
      if (target > 0) {
        flight.queuedStop = target > 1 ? target : null;
        startLaunch();
      }
      return;
    }
    if (flight.launching) {
      flight.queuedStop = target;
      return;
    }
    if (flight.travelling) {
      // Redirige el tránsito en curso desde la posición actual
      flight.stop = flight.u > flight.fromU ? Math.max(0, STOP_U.findLastIndex((su) => su <= flight.u + 1e-4)) : flight.toStop;
      beginTravel(target);
      return;
    }
    if (target === flight.stop) return;
    beginTravel(target);
  }
  engine.goToStop = goToStop;
  engine.startLaunch = startLaunch;
  engine.getStopIndex = () => (flight.travelling ? flight.toStop : flight.stop);
  const pitchBtn = document.getElementById("btn-pitch");
  const pitchLabel = document.getElementById("pitch-label");
  // Auto-piloto del pitch: 90 s = 6 ventanas de 15 s. Cada tránsito sale antes para llegar justo al abrir la ventana.
  const PITCH_TOTAL = 90, PITCH_SLOT = 15, PITCH_TRAVEL_MS = 6500, PITCH_LAUNCH_MS = 8500;
  const pitch = { active: false, t0: 0 };
  function pitchButtonLabel(remaining = PITCH_TOTAL) {
    const r = Math.max(0, Math.ceil(remaining));
    const text = pitch.active ? `PITCH ${Math.floor(r / 60)}:${String(r % 60).padStart(2, "0")}` : "PITCH 1:30";
    if (pitchLabel) {
      if (pitchLabel.textContent !== text) pitchLabel.textContent = text;
    } else if (pitchBtn && pitchBtn.textContent !== text) {
      pitchBtn.textContent = text;
    }
    pitchBtn?.classList.toggle("is-running", pitch.active);
    pitchBtn?.setAttribute("aria-pressed", String(pitch.active));
  }
  function stopPitch() {
    if (!pitch.active) return;
    pitch.active = false;
    pitchButtonLabel();
  }
  function togglePitch() {
    if (pitch.active) {
      stopPitch();
      return;
    }
    pitch.active = true;
    // Si ya se viajó a mano, el cronómetro retoma desde la ventana de la parada actual.
    const current = flight.travelling ? flight.toStop : flight.stop;
    pitch.t0 = performance.now() - (flight.launched ? current * PITCH_SLOT * 1000 : 0);
    pitchButtonLabel(PITCH_TOTAL - (flight.launched ? current * PITCH_SLOT : 0));
  }
  function updatePitch(now) {
    if (!pitch.active) return;
    const elapsed = (now - pitch.t0) / 1000;
    pitchButtonLabel(PITCH_TOTAL - elapsed);
    if (elapsed >= PITCH_TOTAL) {
      stopPitch();
      return;
    }
    const current = flight.travelling ? flight.toStop : flight.stop;
    const next = Math.min(STOPS.length - 1, Math.floor(elapsed / PITCH_SLOT) + 1);
    if (!flight.launched) {
      // Parada 01: la tripulación saluda, aborda a los 3 s y el Saturn V despega para llegar a LEO en 0:15.
      if (astroState.phase === "wave" && elapsed > 1.5) setAstronautPhase("board");
      if (!flight.launching && elapsed >= PITCH_SLOT - 2.5 - PITCH_LAUNCH_MS / 1000) startLaunch(PITCH_LAUNCH_MS);
      return;
    }
    if (!flight.launching && !flight.travelling && current < next && elapsed >= next * PITCH_SLOT - PITCH_TRAVEL_MS / 1000) {
      beginTravel(next, PREFERS_REDUCED_MOTION ? 600 : PITCH_TRAVEL_MS);
    }
  }
  engine.togglePitch = togglePitch;
  engine.stopPitch = stopPitch;
  engine.refreshData = () => {
    hologramBoards.forEach((b) => b.userData.redraw());
    updateHud(flight.travelling ? flight.toStop : null);
  };

  /** Salto directo a una parada (enlace ?stop=N para ensayar el pitch o retomar tras un corte). */
  function jumpToStop(i) {
    const target = THREE.MathUtils.clamp(i, 0, STOPS.length - 1);
    if (target === 0) return;
    flight.launched = true;
    flight.launching = false;
    flight.travelling = false;
    flight.stop = flight.toStop = target;
    flight.u = flight.fromU = flight.toU = STOP_U[target];
    launchButton.visible = false;
    setAstronautPhase("aboard");
    camTarget.copy(RIG[target].focus);
    camOffset.copy(RIG[target].offset);
    updateHud();
    onStopArrived(target);
    setThanks(target === STOPS.length - 1);
  }
  engine.jumpToStop = jumpToStop;

  // ---- 6.3 Tripulación chilena: saludan, abordan (ascensor + brazo de acceso) y exploran ----
  function setAstronautPhase(phase) {
    if (astroState.phase === phase) return;
    const prevPhase = astroState.phase;
    astroState.phase = phase;
    astroState.t0 = performance.now();
    for (const member of astroState.members) {
      const prev = member.actions?.[prevPhase];
      const next = member.actions?.[phase];
      if (next) {
        next.reset();
        next.play();
        if (prev && prev !== next) prev.crossFadeTo(next, 0.45, false);
      }
    }
  }
  const crewStagger = 0.45;
  /** Segundos que faltan para que toda la tripulación esté dentro de la cápsula. */
  function crewBoardingRemaining(now) {
    if (astroState.phase === "aboard") return 0;
    if (astroState.phase === "wave") return astroState.boardDur + crewStagger * 2;
    return Math.max(0, astroState.boardDur + crewStagger * 2 - (now - astroState.t0) / 1000);
  }
  const pathPoint = new THREE.Vector3();
  const pathDir = new THREE.Vector3();
  function updateAstronaut(now, t) {
    if (readyAt == null) return;
    for (const member of astroState.members) {
      if (!member.root) continue;
      const holder = member.holder;
      if (astroState.phase === "wave") {
        holder.visible = !flight.launched;
        const toCam = Math.atan2(camera.position.x - holder.position.x, camera.position.z - holder.position.z);
        holder.rotation.y = lerp(holder.rotation.y, toCam, 0.06);
        if (member.fallback && member.armPivot) member.armPivot.rotation.z = -2.4 + Math.sin(t * 6 + member.idx) * 0.45;
      } else if (astroState.phase === "board") {
        const p = clamp01(((now - astroState.t0) / 1000 - member.idx * crewStagger) / astroState.boardDur);
        const lens = member.boardLens, path = member.boardPath;
        const d = easeInOut(p) * lens.at(-1);
        let seg = 0;
        while (seg < path.length - 2 && d > lens[seg + 1]) seg++;
        const k = clamp01((d - lens[seg]) / Math.max(1e-4, lens[seg + 1] - lens[seg]));
        holder.position.copy(pathPoint.lerpVectors(path[seg], path[seg + 1], k));
        pathDir.subVectors(path[seg + 1], path[seg]);
        if (Math.hypot(pathDir.x, pathDir.z) > 0.05) holder.rotation.y = lerp(holder.rotation.y, Math.atan2(pathDir.x, pathDir.z), 0.14);
        if (member.fallback && member.armPivot) member.armPivot.rotation.z = lerp(member.armPivot.rotation.z, 0, 0.1);
        // Al cruzar la escotilla entran en la cápsula.
        holder.scale.setScalar(p > 0.92 ? Math.max(0.001, 1 - (p - 0.92) / 0.08) : 1);
        holder.visible = p < 1;
      } else {
        holder.visible = false;
      }
      holder.children.forEach((child) => child.children?.forEach((part) => {
        if (part.userData?.isCrewFlag) part.rotation.y = 0.18 + Math.sin(t * 3.2 + member.idx * 1.3) * 0.25;
      }));
    }
    if (astroState.phase === "board" && crewBoardingRemaining(now) <= 0) setAstronautPhase("aboard");

    // Exploradores en Luna y Jezero: recorren el terreno y lo barren con su escáner.
    for (const slot of idleAstronautSlots) {
      const ang = t * slot.speed + slot.phase;
      const px = slot.center.x + Math.cos(ang) * slot.radius;
      const pz = slot.center.z + Math.sin(ang) * slot.radius;
      slot.parent.position.set(px, slot.heightFn(px, pz) + 0.02, pz);
      const dir = Math.sign(slot.speed);
      slot.parent.rotation.y = Math.atan2(-Math.sin(ang) * dir, Math.cos(ang) * dir);
      slot.scan.rotation.set(-1.0 + Math.sin(t * 1.1 + slot.phase) * 0.12, 0, Math.sin(t * 2.3 + slot.phase) * 0.45);
      slot.scan.material.opacity = 0.04 + 0.06 * (0.5 + 0.5 * Math.sin(t * 5 + slot.phase));
      if (!slot.fig) continue;
      if (slot.fig.userData?.armPivot) slot.fig.userData.armPivot.rotation.z = -0.9 + Math.sin(t * 2.2 + slot.phase) * 0.35;
      slot.fig.children.forEach((child) => {
        if (child.userData?.isCrewFlag) child.rotation.y = 0.18 + Math.sin(t * 3.2 + slot.phase) * 0.25;
      });
    }
  }
  // ---- 6.4 Entrada: órbita de cámara, clic en el botón 3D, rueda y teclado ----
  function setPointer(e) {
    const r = canvas.getBoundingClientRect();
    pointer.set(((e.clientX - r.left) / r.width) * 2 - 1, -(((e.clientY - r.top) / r.height) * 2 - 1));
  }
  function launchButtonHit() {
    if (flight.launched || flight.launching || flight.stop !== 0 || !launchButton.visible) return false;
    raycaster.setFromCamera(pointer, camera);
    return raycaster.intersectObject(launchButton, false).length > 0;
  }
  canvas.addEventListener("pointerdown", (e) => {
    orbit.dragging = true;
    orbit.moved = 0;
    orbit.px = e.clientX;
    orbit.py = e.clientY;
    canvas.setPointerCapture?.(e.pointerId);
  });
  canvas.addEventListener("pointermove", (e) => {
    setPointer(e);
    if (orbit.dragging) {
      const dx = e.clientX - orbit.px, dy = e.clientY - orbit.py;
      orbit.moved += Math.abs(dx) + Math.abs(dy);
      orbit.px = e.clientX;
      orbit.py = e.clientY;
      orbit.targetYaw = THREE.MathUtils.clamp(orbit.targetYaw - dx * 0.0055, -1.35, 1.35);
      orbit.targetPitch = THREE.MathUtils.clamp(orbit.targetPitch + dy * 0.004, -0.32, 0.75);
    } else {
      const hot = launchButtonHit();
      if (hot !== launchHot) {
        launchHot = hot;
        launchButton.userData.setHot(hot);
        container?.classList.toggle("hover-ui", hot);
      }
    }
  });
  const endDrag = (e) => {
    if (!orbit.dragging) return;
    orbit.dragging = false;
    canvas.releasePointerCapture?.(e.pointerId);
    if (orbit.moved < 6) {
      setPointer(e);
      if (launchButtonHit()) startLaunch();
    }
  };
  canvas.addEventListener("pointerup", endDrag);
  canvas.addEventListener("pointercancel", endDrag);
  canvas.addEventListener("dblclick", () => {
    orbit.targetYaw = 0;
    orbit.targetPitch = 0;
  });
  // Rueda del ratón = acelerador del cohete: hacia abajo acelera, hacia arriba frena y retrocede.
  canvas.addEventListener(
    "wheel",
    (e) => {
      e.preventDefault();
      if (flight.launching) return;
      const delta = e.deltaY * (e.deltaMode === 1 ? 33 : e.deltaMode === 2 ? 400 : 1);
      if (Math.abs(delta) < 1) return;
      engine.stopPitch?.();
      if (!flight.launched) {
        if (delta > 0) goToStop(1); // el primer avance inicia la secuencia de despegue
        return;
      }
      if (flight.travelling && !flight.manual) {
        // El usuario toma el mando de un tránsito automático.
        flight.manual = true;
        flight.seg = -1;
        throttle.vel = (flight.toU >= flight.fromU ? 1 : -1) * Math.max(0.008, THROTTLE_MAX * Math.sin(Math.PI * flight.progress) * 0.5);
      }
      flight.manual ||= true;
      throttle.vel = THREE.MathUtils.clamp(throttle.vel + (delta / 100) * THROTTLE_GAIN, -THROTTLE_MAX, THROTTLE_MAX);
    },
    { passive: false },
  );

  // ---- 6.5 Poses de cámara: plano fijo por parada ↔ persecución cinematográfica en tránsito ----
  const camTarget = RIG[0].focus.clone();
  const camOffset = RIG[0].offset.clone();
  const tmpTarget = new THREE.Vector3();
  const tmpOffset = new THREE.Vector3();
  const tmpRight = new THREE.Vector3();
  const shipTangent = new THREE.Vector3(0, 1, 0);
  const shipQuat = new THREE.Quaternion();
  const flatBack = new THREE.Vector3(0, 0, 1);
  camera.position.copy(camTarget).add(camOffset);
  camera.lookAt(camTarget);

  const PULLBACK_OFFSET = new THREE.Vector3(9, 7, 34);
  function chasePose(outTarget, outOffset) {
    // Dirección "hacia atrás" aplanada: en el ascenso vertical la cámara acompaña de lado, no por debajo
    tmpRight.copy(shipTangent);
    tmpRight.y = 0;
    if (tmpRight.length() < 0.55) tmpRight.add(new THREE.Vector3(0, 0, -0.6));
    tmpRight.normalize();
    flatBack.lerp(tmpRight.clone().negate(), 0.08).normalize();
    outTarget.copy(ship.position).addScaledVector(shipTangent, 1.6);
    outOffset.copy(flatBack).multiplyScalar(9.5);
    outOffset.y += 2.7;
    outOffset.addScaledVector(tmpRight.set(-flatBack.z, 0, flatBack.x), 2.2);
  }

  // ---- 6.6 Bucle de render ----
  const clock = new THREE.Clock();
  const phobosPivot = { a: 0.6 }, deimosPivot = { a: 2.4 };
  const nozzleWorld = new THREE.Vector3();

  function animate() {
    requestAnimationFrame(animate);
    const dt = Math.min(clock.getDelta(), 0.05);
    const t = clock.elapsedTime;
    const now = performance.now();
    if (readyAt == null && !document.getElementById("cinema-loader")) {
      readyAt = now;
      astroState.t0 = now;
    }

    updatePitch(now);

    // --- Despegue: ignición → brazos umbilicales → liberación ---
    let ignition = 0;
    if (flight.launching) {
      const el = (now - flight.launchT0) / 1000;
      ignition = clamp01(el / 2.6);
      umbilicalArms.forEach((arm, k) => (arm.rotation.y = lerp(arm.rotation.y, -1.35, 0.03 + k * 0.01)));
      launchButton.material.uniforms.uOpacity.value = THREE.MathUtils.clamp(1 - el * 1.4, 0, 1);
      if (el > 0.4) {
        ship.getWorldPosition(nozzleWorld);
        steam.emit(nozzleWorld, { spread: 1.4, velocity: [0, 0.5, 0], jitter: 3.4, life: 3.2, size: 2.2, count: 9 });
        sparks.emit(nozzleWorld, { spread: 0.5, velocity: [0, -1.2, 0], jitter: 4.5, life: 0.7, size: 0.22, count: 6 });
      }
      fx.shake = Math.max(fx.shake, ignition * 0.5);
      if (el > 3.0) {
        flight.launching = false;
        flight.launched = true;
        launchButton.visible = false;
        beginTravel(1, PREFERS_REDUCED_MOTION ? 600 : flight.launchTravelMs ?? 8500);
      }
    }

    // --- Acelerador de la rueda: u avanza con velocidad amortiguada a lo largo de toda la trayectoria ---
    if (flight.manual && flight.launched && !flight.launching) {
      throttle.vel *= Math.exp(-dt * 0.9);
      const uMin = STOP_U[1], uMax = 1;
      flight.u = THREE.MathUtils.clamp(flight.u + throttle.vel * dt, uMin, uMax);
      if (flight.u === uMin && throttle.vel < 0) throttle.vel = 0;
      if (flight.u === uMax && throttle.vel > 0) throttle.vel = 0;
      const a = THREE.MathUtils.clamp(STOP_U.findLastIndex((su) => su <= flight.u + 1e-6), 0, STOPS.length - 2);
      if (a !== flight.seg) {
        flight.seg = a;
        flight.stop = a;
        flight.toStop = a + 1;
        flight.fromU = STOP_U[a];
        flight.toU = STOP_U[a + 1];
        lastPortalSide = GATE_U.map((gu) => Math.sign(flight.u - gu) || -1);
        setThanks(false);
      }
      flight.travelling = true;
      flight.progress = clamp01((flight.u - flight.fromU) / (flight.toU - flight.fromU));
      // Cerca de una parada y casi sin velocidad, el cohete se acopla suavemente a ella.
      const nearest = STOP_U.reduce((best, su, i) => (Math.abs(su - flight.u) < Math.abs(STOP_U[best] - flight.u) ? i : best), 0);
      const dist = STOP_U[nearest] - flight.u;
      if (nearest >= 1 && Math.abs(throttle.vel) < 0.0025 && Math.abs(dist) < 0.012) {
        flight.u += dist * (1 - Math.exp(-dt * 2.4));
        if (Math.abs(dist) < 0.0008) {
          flight.u = STOP_U[nearest];
          flight.toStop = nearest;
          flight.toU = flight.u;
          throttle.vel = 0;
          arrive();
        }
      }
      if (flight.manual) {
        const heading = throttle.vel >= 0 ? flight.toStop : flight.stop;
        if (flight.hudStop !== heading) {
          flight.hudStop = heading;
          updateHud(heading);
        }
      }
    }

    // --- Avance sobre la curva ---
    if (flight.travelling && !flight.manual) {
      flight.progress = clamp01((now - flight.t0) / flight.dur);
      // Curva cúbica de entrada y salida en todos los tramos: el despegue arranca lento y frena suave en órbita.
      const k = easeInOut(flight.progress);
      flight.u = lerp(flight.fromU, flight.toU, k);
      if (flight.progress >= 1) arrive();
    }
    const u = THREE.MathUtils.clamp(flight.u, 0, 1);
    flightCurve.getPointAt(u, ship.position);
    flightCurve.getTangentAt(Math.min(0.9995, Math.max(0.0005, u)), shipTangent).normalize();
    if (flight.toU < flight.fromU && flight.travelling && !flight.manual) shipTangent.negate(); // viaje de regreso
    if (u < 0.002 && !flight.travelling) shipTangent.set(0, 1, 0); // vertical en el pad
    shipQuat.setFromUnitVectors(Z_AXIS, shipTangent);
    ship.quaternion.slerp(shipQuat, flight.travelling ? 0.12 : 0.06);

    // --- Motores ---
    const throttleLevel = clamp01(Math.abs(throttle.vel) / THROTTLE_MAX);
    const speed = flight.manual ? throttleLevel : flight.travelling ? Math.sin(Math.PI * flight.progress) : 0;
    // En modo manual la columna de motor crece con la velocidad: casi apagada en ralentí, plena a todo gas.
    const plumeTarget = flight.launching ? ignition * 0.75 : flight.manual ? 0.1 + throttleLevel * 0.95 : flight.travelling ? 0.55 + speed * 0.45 : flight.launched && flight.stop > 0 ? 0.1 : 0;
    fx.plume = lerp(fx.plume, plumeTarget, 0.08);
    plumeMat.uniforms.uTime.value = t;
    plumeMat.uniforms.uIntensity.value = fx.plume;
    plumeGroup.visible = fx.plume > 0.01;
    engineLight.intensity = fx.plume * 140;
    nozzleGlow.material.opacity = fx.plume * (0.85 + Math.sin(t * 46) * 0.15);
    if (flight.travelling && flight.fromU === 0 && flight.progress < 0.22) {
      ship.getWorldPosition(nozzleWorld);
      steam.emit(nozzleWorld, { spread: 0.9, velocity: [0, -1.4, 0], jitter: 2.6, life: 2.6, size: 2.0, count: 5 });
    }
    steam.update(dt, { gravity: 0.25, drag: 0.972, grow: 0.9 });
    sparks.update(dt, { gravity: -3.2, drag: 0.985 });

    // --- FX de cruce de portal: túnel de estelas, aberración, golpe de FOV y destello ---
    let warpTarget = 0;
    portals.forEach((p, i) => {
      const d = Math.abs(u - p.u);
      const near = 1 - THREE.MathUtils.smoothstep(d, 0.0, 0.05);
      for (const mat of p.mats) {
        mat.uniforms.uTime.value = t;
        mat.uniforms.uIntensity.value = 1.0 + near * 2.4;
      }
      p.light.intensity = 90 + near * 420;
      if (flight.travelling) {
        warpTarget = Math.max(warpTarget, 1 - THREE.MathUtils.smoothstep(d, 0.0, 0.032));
        const side = Math.sign(u - p.u) || -1;
        if (side !== lastPortalSide[i]) {
          lastPortalSide[i] = side;
          fx.flash = 1; // destello al atravesar el horizonte del portal
          fx.shake = 1;
        }
      }
    });
    const warpGoal = PREFERS_REDUCED_MOTION ? warpTarget * 0.25 : warpTarget;
    fx.warp = lerp(fx.warp, warpGoal, warpGoal > fx.warp ? 0.1 : 0.045);
    fx.flash *= 0.92;
    fx.shake *= 0.94;
    streakMat.uniforms.uWarp.value = fx.warp;
    streakMat.uniforms.uTime.value = t;
    cinemaPass.uniforms.uTime.value = t;
    cinemaPass.uniforms.uAberration.value = 0.0015 + speed * 0.004 + fx.warp * 0.03 + fx.flash * 0.02;
    cinemaPass.uniforms.uVignette.value = 0.3 + fx.warp * 0.35;
    bloomPass.strength = 0.42 + fx.warp * 0.75 + fx.flash * 1.4;
    renderer.toneMappingExposure = 1.08 + fx.flash * 1.5;
    const fovGoal = BASE_FOV + (PREFERS_REDUCED_MOTION ? 0 : fx.warp * 30 + speed * 5);
    if (Math.abs(camera.fov - fovGoal) > 0.05) {
      camera.fov = lerp(camera.fov, fovGoal, 0.1);
      camera.updateProjectionMatrix();
    }

    // --- Cámara: plano fijo de parada ↔ persecución ---
    orbit.yaw = lerp(orbit.yaw, orbit.targetYaw, 0.09);
    orbit.pitch = lerp(orbit.pitch, orbit.targetPitch, 0.09);
    if (flight.travelling) {
      const p = flight.progress;
      const from = RIG[flight.stop], to = RIG[flight.toStop];
      chasePose(tmpTarget, tmpOffset);
      const inEnd = 0.16;
      if (flight.fromU === 0) {
        // Despegue estilo Google Earth: la cámara acompaña al cohete y se aleja con curva cúbica
        // hasta descubrir la Tierra entera; luego encuadra la estación.
        tmpTarget.lerpVectors(from.focus, ship.position, easeInOut(clamp01(p / 0.3)));
        tmpOffset.lerpVectors(from.offset, PULLBACK_OFFSET, easeInOut(clamp01(p / 0.78)));
        if (p > 0.78) {
          const k = easeInOut((p - 0.78) / 0.22);
          tmpTarget.lerp(to.focus, k);
          tmpOffset.lerp(to.offset, k);
        }
      } else if (p < inEnd) {
        const k = easeInOut(p / inEnd);
        tmpTarget.lerpVectors(from.focus, tmpTarget, k);
        tmpOffset.lerpVectors(from.offset, tmpOffset, k);
      } else if (p > 0.8) {
        const k = easeInOut((p - 0.8) / 0.2);
        tmpTarget.lerp(to.focus, k);
        tmpOffset.lerp(to.offset, k);
      }
    } else if (flight.launching) {
      tmpTarget.copy(RIG[0].focus);
      tmpOffset.copy(RIG[0].offset);
    } else {
      tmpTarget.copy(RIG[flight.stop].focus);
      tmpOffset.copy(RIG[flight.stop].offset);
    }
    const follow = 1 - Math.exp(-dt * (flight.travelling ? 3.4 : 2.2));
    camTarget.lerp(tmpTarget, follow);
    camOffset.lerp(tmpOffset, follow);
    // Órbita del usuario alrededor del foco (arrastre) + respiración sutil de cámara en reposo
    tmpOffset.copy(camOffset).applyAxisAngle(Y_AXIS, orbit.yaw + (PREFERS_REDUCED_MOTION ? 0 : Math.sin(t * 0.18) * 0.025));
    tmpRight.crossVectors(Y_AXIS, tmpOffset).normalize();
    tmpOffset.applyAxisAngle(tmpRight, -orbit.pitch);
    camera.position.copy(camTarget).add(tmpOffset);
    if (!PREFERS_REDUCED_MOTION && fx.shake > 0.01) {
      const s = fx.shake * (0.05 + fx.warp * 0.12);
      camera.position.x += (Math.random() - 0.5) * s;
      camera.position.y += (Math.random() - 0.5) * s;
    }
    camera.lookAt(camTarget);
    skyGroup.position.copy(camera.position);

    // --- Luz solar y sombras siguen al foco ---
    sunLight.target.position.copy(camTarget);
    sunLight.position.copy(camTarget).addScaledVector(SUN_DIR, 120);

    // --- Vida del mundo ---
    earthMat.uniforms.uTime.value = t;
    cloudMat.uniforms.uTime.value = t;
    sunMat.uniforms.uTime.value = t;
    for (const m of skyShaderMats) m.uniforms.uTime.value = t;
    galaxyGroup.rotateY(dt * 0.004);
    for (const g of giants) {
      g.mat.uniforms.uTime.value = t;
      g.body.rotation.y += dt * 0.0035;
    }
    sunBillboard.quaternion.copy(camera.quaternion);
    cloudMesh.rotation.y = t * 0.004;
    hologramBoards.forEach((b) => (b.material.uniforms.uTime.value = t));
    if (launchButton.visible) {
      launchButton.material.uniforms.uTime.value = t;
      launchButton.quaternion.copy(camera.quaternion);
      launchButton.position.y = LAUNCH_BTN_Y + Math.sin(t * 1.6) * 0.05;
    }
    beacons.forEach((b, k) => b.material.color.setRGB(...(Math.sin(t * 3 + k * 1.7) > 0.2 ? [6, 0.5, 0.3] : [0.25, 0.02, 0.02])));
    stationBeacons.forEach((b, k) => (b.visible = Math.sin(t * 2.2 + k * 2.1) > -0.3));
    // Satélites siempre en órbita: ISS rota, Hubble la rodea, JWST traza su halo en L2, Voyager circunda Bennu.
    issHolder.rotation.y = 1.25 + t * 0.02;
    hubbleOrbit.rotation.y = 2.2 + t * 0.07;
    hubbleHolder.rotation.y = t * 0.05;
    bennuHolder.rotation.y = t * 0.06;
    jwstHolder.position.set(Math.cos(t * 0.16) * 1.3, Math.sin(t * 0.16) * 0.9, Math.sin(t * 0.16) * 0.8);
    jwstHolder.rotation.y = 0.7 + Math.sin(t * 0.2) * 0.15;
    voyagerOrbit.rotation.y = 3.6 - t * 0.05;
    voyagerHolder.rotation.z = 0.3 + Math.sin(t * 0.25) * 0.1;
    cmeParticles.rotation.y = t * 0.02;
    cmeParticles.position.x = Math.sin(t * 0.1) * 2;
    lroOrbit.rotation.y = t * 0.16;
    marsMesh.rotation.y = t * 0.008;
    mgsOrbit.rotation.y = t * 0.14;
    phobosPivot.a += dt * 0.22;
    deimosPivot.a += dt * 0.09;
    phobos.position.set(Math.cos(phobosPivot.a) * (MARS_R + 4.6), 1.2, Math.sin(phobosPivot.a) * (MARS_R + 4.6));
    deimos.position.set(Math.cos(deimosPivot.a) * (MARS_R + 8.2), -1.6, Math.sin(deimosPivot.a) * (MARS_R + 8.2));
    phobos.rotation.y = t * 0.2;
    deimos.rotation.y = t * 0.12;
    // Ingenuity: vuelo estacionario con deriva en ocho y rotores coaxiales contrarrotantes.
    ingenuityHolder.position.set(INGENUITY_BASE.x + Math.sin(t * 0.31) * 1.1, INGENUITY_BASE.y + Math.sin(t * 1.3) * 0.16, INGENUITY_BASE.z + Math.sin(t * 0.62) * 0.7);
    ingenuityHolder.rotation.y = Math.sin(t * 0.31) * 0.6;
    ingenuityRotors.forEach((rotor, k) => rotor.rotateX(dt * 38 * (k % 2 ? -1 : 1)));

    // Satélites: seguimiento solar de paneles y microdestellos de propulsor.
    for (const rig of satelliteRigs) {
      rig.arrays.forEach((a, k) => {
        a.mesh.rotation.y = a.baseY + Math.sin(t * 0.32 + rig.phase + k * 0.7) * 0.16;
        a.mesh.rotation.z = a.baseZ + Math.cos(t * 0.27 + rig.phase + k) * 0.05;
      });
      rig.glint.material.opacity = 0.08 + 0.9 * Math.pow(Math.max(0, Math.sin(t * 2.1 + rig.phase)), 10);
      rig.glint.scale.setScalar(0.18 + 0.12 * Math.max(0, Math.sin(t * 2.1 + rig.phase)));
    }

    // Perseverance recorre Jezero y su gemelo patrulla la base lunar: avanzan de frente y sus ruedas giran.
    const driveRover = (drive, holder, wheels, heightFn, wheelRadius) => {
      drive.angle += dt * drive.speed;
      const px = drive.center.x + Math.cos(drive.angle) * drive.radius;
      const pz = drive.center.z + Math.sin(drive.angle) * drive.radius;
      holder.position.set(px, heightFn(px, pz) + 0.02, pz);
      holder.rotation.y = -drive.angle;
      const spin = (dt * drive.speed * drive.radius) / wheelRadius;
      for (const wheel of wheels) wheel.rotation.x += spin;
    };
    driveRover(perseveranceDrive, perseveranceHolder, perseveranceWheels, jezHeight, 0.2);
    driveRover(lunarRoverDrive, lunarRover, lunarWheels, moonHeight, 0.145);

    // Narradores: flotación en gravedad cero y cono de proyección anclado al astronauta guía.
    for (const n of narrators) {
      if (n.zeroG) {
        n.holder.position.y = n.baseY + Math.sin(t * 0.55 + n.phase) * 0.07;
        n.holder.rotation.z = Math.sin(t * 0.4 + n.phase) * 0.02;
      }
      n.beam.material.uniforms.uTime.value = t;
      n.lens.material.opacity = 0.75 + 0.25 * Math.sin(t * 7 + n.phase);
    }

    updateAstronaut(now, t);
    for (const m of mixers) m.update(dt);
    for (const n of narrators) {
      if (!n.slot.projector) continue;
      n.holder.worldToLocal(n.slot.projector.getWorldPosition(n.apex));
      const p = n.beam.geometry.attributes.position;
      for (let k = 0; k < 4; k++) p.setXYZ(k * 3, n.apex.x, n.apex.y, n.apex.z);
      p.needsUpdate = true;
      n.lens.position.copy(n.apex);
    }
    composer.render();
  }

  // ---- 6.7 Redimensionado ----
  window.addEventListener("resize", () => {
    const w = window.innerWidth, h = window.innerHeight;
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    renderer.setSize(w, h);
    composer.setSize(w, h);
  });

  updateHud();
  if (new URLSearchParams(location.search).has("debug")) window.__codeOrDie = { THREE, scene, camera, renderer, flight, engine };
  const jump = Number(new URLSearchParams(location.search).get("stop"));
  if (jump >= 2 && jump <= STOPS.length) jumpToStop(jump - 1);
  animate();
}

// ============================================================================
// 7. ENTRENADOR DE MISIÓN (30 SOLES) EN EL CAJÓN LATERAL
// ============================================================================
function renderKidGlossaryStrip() {
  const strip = document.getElementById("kid-glossary-strip");
  if (!strip || !glossary?.terms) return;
  strip.innerHTML = glossary.terms
    .map((t) => `<span class="glossary-chip" title="${esc(t.es.text)}"><strong>${esc(t.es.term)}:</strong> ${esc(t.es.text)}</span>`)
    .join("");
}

function renderSourcesList() {
  const el = document.getElementById("sources-list");
  if (!el) return;
  el.innerHTML = sourceCatalog
    .map((s) => `<a class="source-link" href="${esc(s.officialUrl)}" target="_blank" rel="noopener" title="${esc(s.gameUse)}">${esc(s.name)}</a>`)
    .join("");
}

function startNewGame() {
  if (!world || !balance || !cardsData) return;
  const siteId = document.getElementById("select-site")?.value || "mars";
  const scenarioId = document.getElementById("select-scenario")?.value || "gannon-2024-05";
  try {
    currentMission = createMission({ world, balance, cardsData, siteId, scenarioId, seed: Date.now() & 0xffff });
  } catch (err) {
    console.warn("[sim] No se pudo crear la misión:", err?.message ?? err);
    return;
  }
  selectedCardId = null;
  selectedPowerMode = "normal";
  selectedUseShelter = false;
  engine.syncOutpost?.(currentMission.state);
  renderGameUI();
}

/** Al llegar a la base lunar o a Jezero, el simulador se sitúa allí (si el usuario no eligió sitio a mano). */
function onStopArrived(stopIndex) {
  if (siteTouchedByUser) return;
  const wanted = STOPS[stopIndex]?.id === "moon" ? "moon" : STOPS[stopIndex]?.id === "jezero" ? "mars" : null;
  const select = document.getElementById("select-site");
  if (!wanted || !select || select.value === wanted) return;
  // No se pisa una partida ya empezada
  if (currentMission && currentMission.state.sol > 0 && !currentMission.state.ended) return;
  select.value = wanted;
  startNewGame();
}

function benefitLabel(c) {
  const b = c.benefit ?? {};
  if (b.perSol?.power) return `+${b.perSol.power} Energía/sol`;
  if (b.perSol?.air) return `+${b.perSol.air} Aire/sol`;
  if (b.shield) return `+${b.shield} Blindaje`;
  if (b.unlocksShelter) return "Desbloquea el refugio";
  return "Señal clara con la Tierra";
}

function renderGameUI() {
  if (!currentMission) return;
  const { state } = currentMission;
  const ctx = getSolContext(currentMission);

  const timelineEl = document.getElementById("sol-timeline");
  if (timelineEl) {
    const cells = [];
    for (let s = 0; s < state.totalSols; s++) {
      const evs = state.scheduled.filter((e) => e.hitsSite && ((e.arrivalSol != null && e.arrivalSol === s) || (e.arrivalSol == null && e.sol === s)));
      const maxT = evs.reduce((m, e) => Math.max(m, e.threat), 0);
      let cls = "sol-cell";
      if (s < state.sol) cls += " done";
      else if (s === state.sol && !state.ended) cls += " current";
      if (maxT >= 0.7) cls += " has-major-event";
      else if (maxT > 0) cls += " has-event";
      cells.push(`<div class="${cls}" title="Sol ${s + 1}">${s + 1}</div>`);
    }
    timelineEl.innerHTML = cells.join("");
  }

  const statsEl = document.getElementById("game-stats-grid");
  const delayStr = ctx.commDelaySec < 10 ? `${ctx.commDelaySec.toFixed(1)} s` : `${Math.round(ctx.commDelaySec / 60)} min`;
  const bar = (pct, color = "") => `<div class="progress-track"><div class="progress-fill" style="width:${Math.max(0, Math.min(100, pct))}%;${color ? `background:${color};` : ""}"></div></div>`;
  const doseHigh = state.dose > 60;
  if (statsEl) {
    statsEl.innerHTML = `
      <div class="stat-box"><div class="stat-label"><span>Sol</span><span>Radio ${esc(delayStr)}</span></div><div class="stat-value">${Math.min(state.totalSols, state.sol + (state.ended ? 0 : 1))}/${state.totalSols}</div>${bar((state.sol / state.totalSols) * 100)}</div>
      <div class="stat-box"><div class="stat-label"><span>Energía</span><span>máx 100</span></div><div class="stat-value">${state.power}</div>${bar(state.power)}</div>
      <div class="stat-box"><div class="stat-label"><span>Aire y vida</span><span>máx 100</span></div><div class="stat-value">${state.air}</div>${bar(state.air)}</div>
      <div class="stat-box"><div class="stat-label"><span>Blindaje</span><span>máx 5</span></div><div class="stat-value">Nv ${state.shield}</div>${bar((state.shield / 5) * 100)}</div>
      <div class="stat-box"><div class="stat-label"><span>Dosis RadLab</span><span>lím 100</span></div><div class="stat-value" style="color:${doseHigh ? "var(--nasa-red)" : "inherit"}">${state.dose.toFixed(1)}</div>${bar(state.dose, doseHigh ? "var(--nasa-red)" : "")}</div>
      <div class="stat-box"><div class="stat-label"><span>Ciencia OSDR</span><span>${state.profile.doseMultiplierVsIss}× ISS</span></div><div class="stat-value">${state.science}</div>${bar(state.science * 4)}</div>
    `;
  }

  const alertsEl = document.getElementById("game-alerts-area");
  const banners = [];
  if (ctx.activeEvents.length > 0 && !state.ended) {
    banners.push(`
      <div class="alert-banner">
        <strong>Tormenta solar real hoy (NASA DONKI):</strong>
        ${ctx.activeEvents.map((e) => `${esc(e.type)} · ${esc(e.label?.es ?? e.label)} · amenaza ${e.threat}`).join(" — ")}.
        <em>Tu blindaje Nv ${state.shield} absorbe un ${Math.round((1 - 1 / (1 + 0.6 * state.shield)) * 100)} % de la radiación.</em>
      </div>`);
  }
  if (ctx.warnings.length > 0 && !state.ended) {
    banners.push(`
      <div class="warn-banner">
        <strong>DONKI detecta una CME en camino:</strong> impacto en el sol ${ctx.warnings[0].arrivalSol + 1} (${ctx.warnings[0].warningSols} soles de preaviso).
      </div>`);
  }
  if (alertsEl) alertsEl.innerHTML = banners.join("");

  const decisionEl = document.getElementById("game-decision-area");
  const reportEl = document.getElementById("game-report-area");
  if (!decisionEl || !reportEl) return;

  if (state.ended) {
    decisionEl.style.display = "none";
    reportEl.style.display = "block";
    const won = state.outcome === "victory";
    reportEl.innerHTML = `
      <div class="report-card">
        <h3>${won ? `Misión de 30 soles superada · ${state.stars}/3 estrellas` : "Misión interrumpida: revisemos las decisiones"}</h3>
        <p>
          Dosis acumulada: <strong>${state.dose.toFixed(1)}</strong>. Instrumento real NASA RadLab (${esc(state.profile.measuredAt.instrumentId)}):
          <strong>${state.profile.absorbedDoseRate_uGyPerH.typical} µGy/h</strong> (${state.profile.doseMultiplierVsIss}× ISS).
          Módulos 3D construidos: <strong>${state.installed.length}</strong>. Estudios NASA OSDR desbloqueados: <strong>${state.factsUnlocked.length}</strong>.
        </p>
        <button id="btn-play-again" class="glass-pill glass-btn glass-btn-accent">PROBAR OTRA ESTRATEGIA</button>
      </div>`;
    document.getElementById("btn-play-again")?.addEventListener("click", startNewGame);
    return;
  }

  decisionEl.style.display = "";
  reportEl.style.display = "none";

  const cardsHtml = state.offeredCards
    .map((c) => {
      const cost = c.immediateCost?.power ?? 0;
      const canAfford = state.power >= cost;
      const count = state.installed.filter((x) => x.id === c.id).length;
      return `
        <div class="game-card ${selectedCardId === c.id ? "selected" : ""} ${canAfford ? "" : "disabled"}" data-card-id="${esc(c.id)}" role="button" tabindex="0" aria-pressed="${selectedCardId === c.id}">
          <div class="card-head"><span class="card-name">${esc(c.name.es)}</span><span class="card-badge">${count}/${c.stackLimit}</span></div>
          <div class="card-cost-list">
            <div class="cost-good">+ Beneficio: ${esc(benefitLabel(c))}</div>
            <div class="cost-now">− Costo hoy: ${cost} de energía</div>
            <div class="cost-deferred">! Sol +${c.deferredCost?.afterSols ?? 1}: ${esc(c.deferredCost?.note?.es ?? "")}</div>
          </div>
          <div class="card-teaches">${esc(c.teaches?.es ?? "")}</div>
        </div>`;
    })
    .join("");

  const modeBtn = (mode, label) => `<button class="glass-pill glass-btn glass-btn-sm mode-select-btn ${selectedPowerMode === mode ? "is-active" : ""}" data-mode="${mode}">${label}</button>`;
  const lastLog = state.history.at(-1);
  const fact = state.factsUnlocked.at(-1);
  decisionEl.innerHTML = `
    <div class="cards-row">${cardsHtml}</div>
    <div class="decision-row">
      <div class="group">
        ${modeBtn("save", "AHORRO · +4 ENERGÍA")}
        ${modeBtn("normal", "NORMAL · +1 CIENCIA")}
        ${modeBtn("science", "CIENCIA · +3")}
      </div>
      <div class="group">
        ${state.shelterUnlocked ? `<button id="btn-toggle-shelter" class="glass-pill glass-btn glass-btn-sm ${selectedUseShelter ? "is-active" : ""}">${selectedUseShelter ? "REFUGIO ACTIVO" : "ACTIVAR REFUGIO"}</button>` : ""}
        <button id="btn-fast-sim" class="glass-pill glass-btn glass-btn-sm" title="Avanza 5 soles con una estrategia automática">+5 SOLES</button>
        <button id="btn-advance-sol" class="glass-pill glass-btn glass-btn-sm glass-btn-accent">AVANZAR AL SOL ${state.sol + 2 > state.totalSols ? state.totalSols : state.sol + 2} ▶</button>
      </div>
    </div>
    <div class="decision-log">
      <div class="log-eyebrow">BASE 3D · ${state.installed.length} MÓDULOS INSTALADOS EN ${state.siteId === "moon" ? "EL ISLOTE LUNAR" : "EL CRÁTER JEZERO"}</div>
      ${
        lastLog
          ? `<div><strong>Sol ${lastLog.sol}:</strong> energía ${lastLog.power} · aire ${lastLog.air} · dosis ${lastLog.dose}<br>${lastLog.notes.map(esc).join(" · ") || "Operación nominal."}</div>`
          : `<div>Elige una carta (o ninguna), un modo de energía y avanza al siguiente sol. Cada carta aparece como un módulo 3D en la base.</div>`
      }
      ${fact ? `<div style="margin-top:0.4rem"><span class="log-eyebrow">ESTUDIO REAL NASA OSDR</span><br><a href="${esc(fact.url)}" target="_blank" rel="noopener">${esc(fact.accession)}: ${esc(fact.title)}</a></div>` : ""}
    </div>`;

  decisionEl.querySelectorAll(".game-card").forEach((el) => {
    const pick = () => {
      if (el.classList.contains("disabled")) return;
      const cid = el.getAttribute("data-card-id");
      selectedCardId = selectedCardId === cid ? null : cid;
      renderGameUI();
    };
    el.addEventListener("click", pick);
    el.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        pick();
      }
    });
  });
  decisionEl.querySelectorAll(".mode-select-btn").forEach((b) => {
    b.addEventListener("click", () => {
      selectedPowerMode = b.getAttribute("data-mode");
      renderGameUI();
    });
  });
  document.getElementById("btn-toggle-shelter")?.addEventListener("click", () => {
    selectedUseShelter = !selectedUseShelter;
    renderGameUI();
  });
  document.getElementById("btn-advance-sol")?.addEventListener("click", () => {
    stepSol(currentMission, { cardId: selectedCardId, powerMode: selectedPowerMode, useShelter: selectedUseShelter });
    selectedCardId = null;
    selectedUseShelter = false;
    engine.syncOutpost?.(currentMission.state);
    renderGameUI();
  });
  document.getElementById("btn-fast-sim")?.addEventListener("click", () => {
    for (let i = 0; i < 5 && !currentMission.state.ended; i++) {
      const c = getSolContext(currentMission);
      const st = currentMission.state;
      const affordable = st.offeredCards.find((card) => st.power - (card.immediateCost?.power ?? 0) >= 25);
      stepSol(currentMission, {
        cardId: affordable?.id ?? null,
        powerMode: st.power < 35 ? "save" : "normal",
        useShelter: st.shelterUnlocked && c.activeEvents.some((e) => e.threat >= 0.6),
      });
    }
    selectedCardId = null;
    selectedUseShelter = false;
    engine.syncOutpost?.(currentMission.state);
    renderGameUI();
  });
}

// ============================================================================
// 8. EVENTOS DE UI, TECLADO Y ARRANQUE
// ============================================================================
function setDrawerOpen(open) {
  const drawer = document.getElementById("sim-drawer");
  const btn = document.getElementById("btn-toggle-drawer");
  if (!drawer) return;
  drawer.classList.toggle("open", open);
  drawer.setAttribute("aria-hidden", String(!open));
  btn?.setAttribute("aria-expanded", String(open));
  document.body.classList.toggle("drawer-open", open);
  if (open) document.getElementById("btn-close-drawer")?.focus({ preventScroll: true });
  else btn?.focus({ preventScroll: true });
}
const isDrawerOpen = () => document.getElementById("sim-drawer")?.classList.contains("open") ?? false;

function bindEvents() {
  document.getElementById("btn-toggle-drawer")?.addEventListener("click", () => setDrawerOpen(!isDrawerOpen()));
  document.getElementById("btn-close-drawer")?.addEventListener("click", () => setDrawerOpen(false));
  document.getElementById("btn-pitch")?.addEventListener("click", () => engine.togglePitch?.());
  document.getElementById("btn-thanks-sim")?.addEventListener("click", () => setDrawerOpen(true));
  document.getElementById("btn-thanks-replay")?.addEventListener("click", () => { location.href = `${location.pathname}`; });
  document.getElementById("btn-prev-stop")?.addEventListener("click", () => { engine.stopPitch?.(); engine.goToStop?.(engine.getStopIndex() - 1); });
  document.getElementById("btn-next-stop")?.addEventListener("click", () => { engine.stopPitch?.(); engine.goToStop?.(engine.getStopIndex() + 1); });

  document.getElementById("select-site")?.addEventListener("change", () => {
    siteTouchedByUser = true;
    startNewGame();
  });
  document.getElementById("select-scenario")?.addEventListener("change", startNewGame);
  document.getElementById("btn-new-run")?.addEventListener("click", startNewGame);

  document.getElementById("btn-data-mode")?.addEventListener("click", async () => {
    useLiveMode = !useLiveMode;
    const label = document.getElementById("data-mode-label");
    if (label) label.textContent = "CARGANDO…";
    try {
      await loadAllData();
    } catch (err) {
      console.warn("[datos] Sin conexión con la fuente en vivo; se mantiene la copia curada.", err?.message ?? err);
      useLiveMode = false;
      await loadAllData().catch(() => {});
    }
    engine.refreshData?.();
    if (!currentMission || currentMission.state.sol === 0) startNewGame();
  });

  window.addEventListener("keydown", (e) => {
    const tag = e.target?.tagName;
    if (tag === "INPUT" || tag === "SELECT" || tag === "TEXTAREA") return;
    if (e.key === "Escape") {
      if (isDrawerOpen()) setDrawerOpen(false);
      return;
    }
    if (isDrawerOpen() && (tag === "BUTTON" || e.target?.closest?.("#sim-drawer"))) return;
    if (e.key === "ArrowRight" || e.key === "PageDown") {
      e.preventDefault();
      engine.stopPitch?.();
      engine.goToStop?.(engine.getStopIndex() + 1);
    } else if (e.key === "ArrowLeft" || e.key === "PageUp") {
      e.preventDefault();
      engine.stopPitch?.();
      engine.goToStop?.(engine.getStopIndex() - 1);
    } else if ((e.key === "Enter" || e.key === " ") && tag !== "BUTTON" && engine.getStopIndex() === 0) {
      e.preventDefault();
      engine.startLaunch?.();
    } else if (/^[1-6]$/.test(e.key)) {
      engine.stopPitch?.();
      engine.goToStop?.(Number(e.key) - 1);
    } else if (e.key === "p" || e.key === "P") {
      engine.togglePitch?.();
    } else if (e.key === "s" || e.key === "S") {
      setDrawerOpen(!isDrawerOpen());
    }
  });
}

async function init() {
  bindEvents();
  try {
    initEngine();
  } catch (err) {
    console.error("[motor] No se pudo iniciar WebGL:", err);
    const label = document.getElementById("loader-label");
    if (label) label.textContent = "Este navegador no pudo iniciar WebGL2. Prueba con Chrome, Edge o Firefox actualizados.";
    document.getElementById("cinema-loader")?.classList.add("is-done");
  }
  try {
    await loadAllData();
    engine.refreshData?.();
    startNewGame();
  } catch (err) {
    console.error("[datos] No se pudieron cargar los datos NASA/CSA:", err);
  }
}

init();
