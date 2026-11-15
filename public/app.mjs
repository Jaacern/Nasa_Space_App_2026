/**
 * OUTPOST RUN · NASA 3D VECTOR PITCH DECK (3 MIN) & JUNIOR ASTRONAUT MISSION TRAINER
 * ==================================================================================
 * - Curva Orbital 3D Real (`THREE.CatmullRomCurve3`): El cohete Saturn V despega de la Tierra,
 *   bordea físicamente la curvatura 3D del Planeta Tierra en órbita baja (LEO) pasando junto a la
 *   torre 39B, Transbordador, Canadarm, ISS y Hubble, y luego ejecuta la inyección translunar
 *   hacia JWST, Bennu, Voyager, la Luna (LRO + Apollo), Marte (Phobos, Deimos + MGS) y el Cráter
 *   Jezero (Hábitat NASA HDU + Rover Perseverance + Helicóptero Ingenuity).
 * - Espacio Vectorial Estilo Blender 4.5 Viewport: Grilla eclíptica 3D, ejes X/Y/Z cromáticos,
 *   nodos de control Bezier/Spline con vectores tangentes, jaulas geodésicas y cámara orbital 360°.
 * - 17 Modelos 3D Oficiales de NASA (`science.nasa.gov/3d-resources`) descomprimidos e integrados
 *   vía Pipeline MCP (`127.0.0.1:9877`).
 */

import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";
import { createMission, getSolContext, loadWorldState, stepSol } from "../src/sim/run.mjs";

let useLiveMode = false;
let world = null;
let balance = null;
let cardsData = null;
let glossary = null;
let flowPlan = null;
let currentMission = null;

let selectedCardId = null;
let selectedPowerMode = "normal";
let selectedUseShelter = false;

let revealAllMode = false;
let autoFlightActive = false;
let pitchStartTime = 0;
let activePortalGlobalIdx = 0;
let flatPortalsList = [];
let syncOutpost3DCallback = null;
let toggleBlenderGridCallback = null;
let setCameraPresetCallback = null;

const esc = (s) =>
  String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

const proxyImg = (url) => {
  if (!url) return "";
  if (url.startsWith("/")) return url;
  return `/api/media-proxy?url=${encodeURIComponent(url)}`;
};

// ============================================================================
// 1. CARGA DE LAS 8 FUENTES NASA / CSA Y PLAN DE 25 PORTALES
// ============================================================================
async function fetchApiJson(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status} en ${url}`);
  return { data: await r.json(), mode: r.headers.get("X-Data-Mode") };
}

async function loadAllData() {
  const q = useLiveMode ? "?live=1" : "";
  const reader = async (file) => {
    const map = {
      "space_weather.json": `/api/space-weather${q}`,
      "space_weather_scenarios.json": "/data/curated/space_weather_scenarios.json",
      "radiation.json": "/api/radiation",
      "osdr_facts.json": "/data/curated/osdr_facts.json",
      "mars_layers.json": "/api/mars-layers",
      "manifest.json": "/api/manifest",
      "mars_weather.json": `/api/mars-weather${q}`,
      "rover_photos.json": `/api/rover-photos${q}`,
      "csa_resources.json": `/api/csa${q}`,
      "apod.json": `/api/apod${q}`,
    };
    const res = await fetch(map[file] ?? `/data/curated/${file}`);
    if (!res.ok) throw new Error(`No se pudo cargar ${file}`);
    return res.json();
  };

  const [w, balRes, cardsRes, glosRes, flowRes] = await Promise.all([
    loadWorldState(reader),
    fetch("/content/game_balance.json").then((r) => r.json()),
    fetch("/content/cards.json").then((r) => r.json()),
    fetch("/content/glossary.json").then((r) => r.json()),
    fetchApiJson(`/api/flow-plan?credits=1050${useLiveMode ? "&live=1" : ""}`),
  ]);

  world = w;
  balance = balRes;
  cardsData = cardsRes;
  glossary = glosRes;
  flowPlan = flowRes.data;

  updateModeIndicator(flowRes.mode || (useLiveMode ? "live" : "snapshot"));
  buildFlatPortalsList();
  renderRoomsDom();
  renderKidGlossaryStrip();
  renderFlowStudioModal();
  renderProvenanceModal();
  renderChallengeModal();
}

function updateModeIndicator(mode) {
  const chip = document.getElementById("btn-data-mode");
  const label = document.getElementById("data-mode-label");
  if (!chip || !label) return;
  const isLive = mode === "live";
  chip.className = `mode-chip ${isLive ? "live" : "snapshot"}`;
  label.textContent = isLive ? "LIVE NASA API" : "SNAPSHOT";
}

function buildFlatPortalsList() {
  flatPortalsList = [];
  if (!flowPlan?.environments) return;
  let globalIdx = 0;
  for (const env of flowPlan.environments) {
    for (const v of env.videos) {
      flatPortalsList.push({
        globalIdx,
        envId: env.environmentId,
        envName: env.name,
        video: v,
        // Posición normalizada a lo largo de la curva vectorial 3D (0.02 a 0.88)
        curveU: 0.025 + (globalIdx / 24) * 0.855,
      });
      globalIdx++;
    }
  }
}

// ============================================================================
// GUION DEL PITCH DE 3 MINUTOS (6 DIAPOSITIVAS × 30 SEGUNDOS)
// Con tipografía editorial (Public Sans + Instrument Serif Italic + IBM Plex Mono)
// ============================================================================
const PITCH_STAGE_META = {
  tierra: {
    eyebrow: "SLIDE 01 · CABO CAÑAVERAL & TIERRA 3D (PAD 39B, SATURN V & ARES GLB)",
    timeWindow: "00:00 – 00:30",
    headline: "El Problema: la educación espacial oculta las <em>decisiones reales</em>.",
    pitchScript:
      "«Los juegos espaciales para niños de 7 a 12 años suelen caer en dos extremos: o son pósters demasiado simples o simuladores técnicos imposibles. Mientras nuestro cohete Saturn V despega de la plataforma 39B y bordea el Planeta Tierra 3D, nace Outpost Run: un entrenador donde cada decisión tiene costo inmediato y diferido.»",
    kpis: () => [
      { val: "7–12 Años", lbl: "AUDIENCIA META" },
      { val: "3 Recursos", lbl: "ENERGÍA · AIRE · ESCUDO" },
      { val: "17 Modelos GLB", lbl: "NASA 3D + MCP" },
    ],
  },
  despegue: {
    eyebrow: "SLIDE 02 · BORDEANDO LA TIERRA EN ÓRBITA LEO (ISS, SHUTTLE, CANADARM & HUBBLE)",
    timeWindow: "00:30 – 01:00",
    headline: "La Solución: orbitar la Tierra con <em>dosimetría real</em> de la ISS.",
    pitchScript:
      "«Al bordear la curvatura de la Tierra junto al Transbordador, el brazo Canadarm de la CSA, la ISS y el telescopio Hubble, el jugador sale del escudo magnético terrestre. Usamos mediciones reales de NASA RadLab en la ISS (4.2 µGy/h) como línea base para comparar el riesgo en la Luna (3.03×) y Marte (3.63×).»",
    kpis: () => [
      { val: "4.20 µGy/h", lbl: "DOSIS BASE ISS" },
      { val: "408 km LEO", lbl: "ARCO ORBITAL TIERRA" },
      { val: "1,050 Cr", lbl: "25 PORTALES VEO 3.1" },
    ],
  },
  universo: {
    eyebrow: "SLIDE 03 · ESPACIO VECTORIAL PROFUNDO (JWST, BENNU GLB, VOYAGER & DONKI)",
    timeWindow: "01:00 – 01:30",
    headline: "Clima Espacial en Vivo: tormentas <em>DONKI</em> y asteroide Bennu.",
    pitchScript:
      "«Tras la inyección translunar pasamos junto al telescopio James Webb, el asteroide real Bennu (1999 RQ36) y la sonda Voyager. No inventamos números: el motor ingiere 386 eventos solares reales de NASA DONKI (como la supertormenta Gannon X8.7 de mayo 2024). Una CME tarda soles en llegar y exige activar el refugio.»",
    kpis: () => [
      { val: `${world?.scenarios?.reduce((a, s) => a + s.count, 0) || 386} Eventos`, lbl: "NASA DONKI REALES" },
      { val: "Clase X8.7", lbl: "TORMENTA GANNON" },
      { val: "492 m", lbl: "BENNU 1999 RQ36" },
    ],
  },
  luna: {
    eyebrow: "SLIDE 04 · INSERCIÓN CISLUNAR (LUNA 3D, SONDA LRO & MÓDULO APOLLO GLB)",
    timeWindow: "01:30 – 02:00",
    headline: "Sitio 1 — Base Lunar: cerca de casa, pero <em>14 días a oscuras</em>.",
    pitchScript:
      "«El cohete bordea ahora la Luna 3D junto a la sonda LRO (12.72 µGy/h, 3.03× ISS) y el módulo Apollo. Aquí la señal a la Tierra tarda solo 1.3 segundos, pero la noche lunar de 14 soles apaga los paneles solares: encender el invernadero OSDR/CSA da oxígeno hoy, pero puede agotar tus baterías mañana.»",
    kpis: () => [
      { val: "12.72 µGy/h", lbl: "DOSÍMETRO LRO CRaTER" },
      { val: "1.3 seg", lbl: "DELAY RADIO TIERRA" },
      { val: "14 Soles", lbl: "NOCHE LUNAR ARTEMIS" },
    ],
  },
  marte: {
    eyebrow: "SLIDE 05 · ÓRBITA DE MARTE 3D (PHOBOS, DEIMOS & SONDA MGS MOLA GLB)",
    timeWindow: "02:00 – 02:30",
    headline: "Sitio 2 — Base Marciana: aislamiento, polvo y <em>costo diferido</em>.",
    pitchScript:
      "«Al bordear Marte junto a sus lunas Phobos y Deimos y el orbitador MGS MOLA (cartografía a 463 m/px), el retraso de radio sube hasta 22 minutos y la dosis a 15.23 µGy/h. Los vientos reales de InSight cubren de polvo tus paneles tras 8 soles, enseñando de forma tangible el costo diferido.»",
    kpis: () => {
      const sol = world?.marsWeather?.sols?.at(-1);
      const t = sol?.tempC?.avg != null ? `${Math.round(sol.tempC.avg)}°C` : "-63°C";
      return [
        { val: "15.23 µGy/h", lbl: "LIULIN-MO TGO" },
        { val: "3–22 min", lbl: "DELAY RADIO MARTE" },
        { val: `${t} / 27m/s`, lbl: "TELEMETRÍA INSIGHT" },
      ];
    },
  },
};

function renderRoomsDom() {
  const container = document.getElementById("rooms-container");
  if (!flowPlan?.environments) return;

  container.innerHTML = flowPlan.environments
    .map((env, envIdx) => {
      const meta = PITCH_STAGE_META[env.environmentId] ?? PITCH_STAGE_META.tierra;
      const kpis = meta.kpis();

      const kpiHtml = kpis
        .map(
          (k) => `
          <div class="bento-kpi">
            <div class="bento-kpi-val">${esc(k.val)}</div>
            <div class="bento-kpi-lbl">${esc(k.lbl)}</div>
          </div>
        `,
        )
        .join("");

      const portalsHtml = env.videos
        .map((v, vIdx) => {
          const gIdx = envIdx * 5 + vIdx;
          const shortTier = v.tier === "veo_3_1_quality" ? "HQ 100C" : v.tier === "veo_3_1_fast" ? "FAST 20C" : "LITE 10C";
          return `
            <div class="portal-node" data-global-portal="${gIdx}" title="Desplazar cohete al Portal #${gIdx + 1} en la curva vectorial 3D">
              <div class="portal-node-left">
                <img class="portal-orb" src="${esc(proxyImg(v.referenceImageUrl))}" alt="${esc(v.title)}" loading="lazy">
                <span class="portal-node-title">${String(gIdx + 1).padStart(2, "0")}. ${esc(v.title)}</span>
              </div>
              <span class="portal-node-tier">${shortTier} ➔</span>
            </div>
          `;
        })
        .join("");

      return `
        <section class="room-section" id="room-${esc(env.environmentId)}" data-room-index="${envIdx}">
          <article class="pitch-card">
            <div class="slide-header-row">
              <span class="pitch-eyebrow">${esc(meta.eyebrow)}</span>
              <span class="pitch-time-pill">${esc(meta.timeWindow)}</span>
            </div>
            <h2 class="pitch-title">${meta.headline}</h2>

            <div class="pitch-script-box">
              <span class="pitch-script-tag">LOCUCIÓN DEL PITCH (30 SEGUNDOS)</span>
              ${esc(meta.pitchScript)}
            </div>

            <div class="bento-kpis">${kpiHtml}</div>

            <div class="portal-nodes-label">
              <span>5 PORTALES EN ARCO VECTORIAL</span>
              <span>SALTAR EN SPLINE</span>
            </div>
            <div class="portal-nodes">${portalsHtml}</div>
          </article>
        </section>
      `;
    })
    .join("");

  container.querySelectorAll(".portal-node").forEach((node) => {
    node.addEventListener("click", () => {
      const gIdx = Number(node.getAttribute("data-global-portal"));
      warpToPortal(gIdx);
    });
  });
}

function warpToPortal(globalIdx) {
  const clamped = Math.max(0, Math.min(24, globalIdx));
  const maxScroll = Math.max(1, document.body.scrollHeight - window.innerHeight);
  const targetRatio = (clamped / 24) * 0.85;
  window.scrollTo({ top: targetRatio * maxScroll, behavior: "smooth" });

  const reticle = document.getElementById("halo-reticle");
  if (reticle) {
    reticle.classList.add("warp-pulse");
    setTimeout(() => reticle.classList.remove("warp-pulse"), 420);
  }
}

function jumpToSlide(slideIdx) {
  const clamped = Math.max(0, Math.min(5, slideIdx));
  if (clamped === 5) {
    document.getElementById("outpost-game")?.scrollIntoView({ behavior: "smooth" });
  } else {
    const sections = document.querySelectorAll(".room-section");
    sections[clamped]?.scrollIntoView({ behavior: "smooth" });
  }
}

// ============================================================================
// 2. SHADERS WEBGL (PORTAL HALO SIN RECUADROS + PLUMA DE DIAMANTES DE MACH + ATMÓSFERA)
// ============================================================================
const HALO_PORTAL_VERTEX = `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    vec3 pos = position;
    float r2 = dot(pos.xy, pos.xy);
    pos.z += r2 * 0.055;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
  }
`;

const HALO_PORTAL_FRAGMENT = `
  uniform sampler2D uTexture;
  uniform float uRevealProgress;
  uniform float uPassFade;
  uniform float uTime;
  uniform vec2 uHoverUv;
  uniform float uHoverActive;
  uniform vec3 uPortalColor;
  varying vec2 vUv;

  vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }
  float snoise(vec2 v){
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
             -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
      + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
      dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
  }

  float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
      v += a * snoise(p);
      p *= 2.02;
      a *= 0.5;
    }
    return v;
  }

  void main() {
    vec2 centered = vUv - 0.5;
    float r = length(centered) * 2.0;
    float angle = atan(centered.y, centered.x);

    float wave = fbm(vec2(cos(angle) * 2.3 + uTime * 0.25, sin(angle) * 2.3 - uTime * 0.2));
    float portalEdge = r + wave * 0.14;

    float outerAlpha = 1.0 - smoothstep(0.68, 0.96, portalEdge);
    if (outerAlpha <= 0.005) discard;

    float zoom = 0.93 + 0.04 * sin(uTime * 0.65);
    vec2 motionUv = (vUv - 0.5) * zoom + 0.5 + vec2(
      snoise(vUv * 2.6 + uTime * 0.15) * 0.008,
      snoise(vUv * 2.6 - uTime * 0.13) * 0.008
    );
    vec4 nasaTex = texture2D(uTexture, clamp(motionUv, 0.01, 0.99));

    float luma = dot(nasaTex.rgb, vec3(0.299, 0.587, 0.114));
    vec3 holoScan = mix(vec3(0.02, 0.06, 0.16), uPortalColor, pow(luma, 0.85));

    float hoverDist = length(vUv - uHoverUv);
    float brushNoise = fbm(vUv * 5.0 + uTime * 0.2) * 0.22;
    float revealRadius = uRevealProgress * 1.15 + uHoverActive * max(0.0, 0.5 - hoverDist);
    float paintMask = 1.0 - smoothstep(revealRadius - 0.18, revealRadius + 0.08, r + brushNoise);

    vec3 coreColor = mix(holoScan, nasaTex.rgb * 1.16, clamp(paintMask, 0.0, 1.0));

    float rimGlow = smoothstep(0.58, 0.82, portalEdge) * (1.0 - smoothstep(0.82, 0.97, portalEdge));
    float innerFlare = smoothstep(0.68, 0.80, portalEdge) * 0.65;

    vec3 finalRgb = coreColor + uPortalColor * (rimGlow * 2.2 + innerFlare);
    float finalAlpha = outerAlpha * uPassFade * 0.92;
    gl_FragColor = vec4(finalRgb, finalAlpha);
  }
`;

// Shader Volumétrico de Propulsión con Diamantes de Mach (Shock Diamonds + Turbulencia de Plasma)
const ROCKET_PLUME_VERTEX = `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;

const ROCKET_PLUME_FRAGMENT = `
  uniform float uTime;
  varying vec2 vUv;

  float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
  }

  float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
      mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), f.x),
      mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
      f.y
    );
  }

  void main() {
    float along = 1.0 - vUv.y;
    float across = abs(vUv.x - 0.5) * 2.0;

    float turb = (noise(vec2(vUv.x * 8.0, along * 14.0 - uTime * 32.0)) - 0.5) * 0.25 * along;
    float widthProfile = mix(0.28, 0.92, pow(along, 0.65));
    float radialDist = (across + turb) / widthProfile;

    if (radialDist > 1.0) discard;

    float machWave = pow(max(0.0, cos(along * 26.0 - uTime * 38.0)), 4.0) * (1.0 - along * 0.75);
    float coreMask = exp(-radialDist * radialDist * 4.2) * (1.0 - pow(along, 1.35));
    float outerPlume = pow(1.0 - radialDist, 1.8) * (1.0 - pow(along, 0.9));

    vec3 whiteHot = vec3(1.0, 0.98, 0.92);
    vec3 amberThrust = vec3(1.0, 0.58, 0.12);
    vec3 cyanIon = vec3(0.05, 0.72, 1.0);

    vec3 col = mix(cyanIon, amberThrust, smoothstep(0.15, 0.65, coreMask + machWave * 0.4));
    col = mix(col, whiteHot, smoothstep(0.55, 0.95, coreMask + machWave * 0.6));

    float alpha = clamp((outerPlume * 0.85 + coreMask * 1.2 + machWave * 0.45) * smoothstep(0.0, 0.08, along), 0.0, 1.0);
    gl_FragColor = vec4(col * 1.8, alpha);
  }
`;

const ATMOSPHERE_VERTEX = `
  varying vec3 vNormal;
  void main() {
    vNormal = normalize(normalMatrix * normal);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;

const ATMOSPHERE_FRAGMENT = `
  uniform vec3 uAtmoColor;
  varying vec3 vNormal;
  void main() {
    float intensity = pow(0.66 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 2.5);
    gl_FragColor = vec4(uAtmoColor, 1.0) * intensity * 1.45;
  }
`;

// ============================================================================
// 3. MOTOR ESPACIAL VECTORIAL 3D (CURVA ORBITAL TIERRA + VIEWPORT BLENDER + 17 GLB)
// ============================================================================
function initThreeSpaceEngine() {
  const canvas = document.getElementById("webgl-canvas");
  if (!canvas) return;

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: "high-performance" });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.32;
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  const scene = new THREE.Scene();
  // Niebla muy sutil para que los planetas, asteroides, grillas vectoriales y satélites se vean a gran distancia
  scene.fog = new THREE.FogExp2(0x030509, 0.0028);

  const pmremGenerator = new THREE.PMREMGenerator(renderer);
  scene.environment = pmremGenerator.fromScene(new RoomEnvironment(), 0.04).texture;

  const camera = new THREE.PerspectiveCamera(56, window.innerWidth / window.innerHeight, 0.1, 650);

  // Iluminación cinemática de alto contraste (Sol + Rim Light + Fill)
  scene.add(new THREE.AmbientLight(0xdbeafe, 1.55));
  const sunLight = new THREE.DirectionalLight(0xfffbeb, 3.8);
  sunLight.position.set(42, 32, 36);
  scene.add(sunLight);

  const rimLight = new THREE.DirectionalLight(0x38bdf8, 2.0);
  rimLight.position.set(-32, -18, -45);
  scene.add(rimLight);

  const texLoader = new THREE.TextureLoader();
  texLoader.setCrossOrigin("anonymous");

  // Como descomprimimos los 17 modelos .glb de la NASA en disco, GLTFLoader los carga directamente al instante
  const gltfLoader = new GLTFLoader();

  const rockDiffuseTex = texLoader.load("/public/assets/textures/deimos_nasa.jpg");
  const lunarDiffuseTex = texLoader.load("/public/assets/textures/moon_nasa.jpg");

  // Contenedor global de elementos vectoriales estilo Blender 4.5 Viewport
  const blenderVectorGroup = new THREE.Group();
  scene.add(blenderVectorGroup);

  /**
   * Crea un gizmo/jaula vectorial estilo Blender alrededor de un modelo 3D espacial
   * (ejes locales X/Y/Z + anillo de selección técnico).
   */
  function createBlenderLocalGizmo(radius = 1.4) {
    const gizmo = new THREE.Group();
    const ringGeo = new THREE.BufferGeometry();
    const segs = 48;
    const pts = [];
    for (let i = 0; i <= segs; i++) {
      const a = (i / segs) * Math.PI * 2;
      pts.push(Math.cos(a) * radius, Math.sin(a) * radius, 0);
    }
    ringGeo.setAttribute("position", new THREE.Float32BufferAttribute(pts, 3));
    const ring = new THREE.Line(
      ringGeo,
      new THREE.LineBasicMaterial({ color: 0x38bdf8, transparent: true, opacity: 0.32 }),
    );
    gizmo.add(ring);

    // Pequeños ejes locales X (rojo), Y (verde), Z (azul) estilo Blender Origin
    const axLen = radius * 0.55;
    const addAxis = (dir, hex) => {
      const g = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(0, 0, 0), dir.multiplyScalar(axLen)]);
      gizmo.add(new THREE.Line(g, new THREE.LineBasicMaterial({ color: hex, transparent: true, opacity: 0.65 })));
    };
    addAxis(new THREE.Vector3(1, 0, 0), 0xff3b5c);
    addAxis(new THREE.Vector3(0, 1, 0), 0x22c55e);
    addAxis(new THREE.Vector3(0, 0, 1), 0x3b82f6);
    return gizmo;
  }

  /**
   * Carga cualquiera de los 17 .glb oficiales de la NASA (ya descomprimidos en disco),
   * calcula su bounding-box exacto, lo centra en (0,0,0), mejora materiales PBR sin textura
   * para que brillen en el espacio y adjunta su gizmo vectorial Blender.
   */
  function loadNasaGlbNormalized(url, targetSize, onReady, options = {}) {
    gltfLoader.load(
      url,
      (gltf) => {
        const raw = gltf.scene;
        raw.traverse((child) => {
          if (child.isMesh && child.geometry) {
            child.geometry.computeBoundingBox();
            if (!child.geometry.attributes.normal) {
              child.geometry.computeVertexNormals();
            }
          }
        });
        raw.updateMatrixWorld(true);

        const box = new THREE.Box3().setFromObject(raw);
        const size = new THREE.Vector3();
        const center = new THREE.Vector3();
        box.getSize(size);
        box.getCenter(center);

        const maxDim = Math.max(size.x, size.y, size.z) || 1;
        const scale = targetSize / maxDim;

        let meshIdx = 0;
        raw.traverse((child) => {
          if (child.isMesh && child.material) {
            const mats = Array.isArray(child.material) ? child.material : [child.material];
            for (const m of mats) {
              m.envMapIntensity = 2.0;
              m.side = THREE.DoubleSide;
              // Si el modelo .glb de NASA no trae textura embebida y su color es muy oscuro/gris plano,
              // le damos acabado PBR aeroespacial (titanio, paneles solares azul profundo y Kapton dorado)
              if (!m.map) {
                const mName = (m.name || "").toLowerCase();
                if (mName.includes("gold") || mName.includes("bronze") || mName.includes("foil")) {
                  m.color = new THREE.Color(0xf59e0b);
                  m.metalness = 0.78;
                  m.roughness = 0.25;
                } else if (mName.includes("solar") || mName.includes("panel") || mName.includes("wing") || meshIdx % 4 === 1) {
                  m.color = new THREE.Color(0x60a5fa);
                  m.metalness = 0.65;
                  m.roughness = 0.28;
                } else if (meshIdx % 3 === 2) {
                  m.color = new THREE.Color(0xfbbf24);
                  m.metalness = 0.72;
                  m.roughness = 0.26;
                } else {
                  m.color = new THREE.Color(0xe2e8f0);
                  m.metalness = 0.52;
                  m.roughness = 0.34;
                }
                if (m.emissive) {
                  m.emissive = new THREE.Color(0x0f172a);
                  m.emissiveIntensity = 0.25;
                }
              }
              m.needsUpdate = true;
            }
            meshIdx++;
          }
        });

        const centeredGroup = new THREE.Group();
        raw.position.set(-center.x * scale, -center.y * scale, -center.z * scale);
        raw.scale.setScalar(scale);
        centeredGroup.add(raw);

        const outerPivot = new THREE.Group();
        outerPivot.add(centeredGroup);

        if (!options.hideGizmo) {
          const gizmo = createBlenderLocalGizmo(targetSize * 0.56);
          outerPivot.add(gizmo);
        }

        onReady(outerPivot, size.multiplyScalar(scale));
      },
      undefined,
      (err) => {
        console.warn("Error cargando GLB:", url, err);
      },
    );
  }

  // ============================================================================
  // A. DEFINICIÓN DE LA CURVA VECTORIAL ORBITAL 3D (`flightCurve`)
  //    1. Fase Tierra (u = 0.00 .. 0.35): El cohete despega del Pad 39B y BORDEA
  //       físicamente el Planeta Tierra 3D (que está en (0, -0.5, -24) con radio 7.8)
  //       describiendo un arco orbital de 240° alrededor de su atmósfera.
  //    2. Fase Espacio Profundo (u = 0.35 .. 0.56): Inyección Translunar pasando por
  //       JWST, Asteroide Bennu, el Sol activo DONKI y Voyager.
  //    3. Fase Luna (u = 0.56 .. 0.74): Bordea la Luna 3D (en (6.2, 0.2, -158))
  //       pasando junto al módulo Apollo y la sonda LRO.
  //    4. Fase Marte (u = 0.74 .. 0.90): Bordea el Planeta Marte 3D (en (-6.4, -0.3, -212))
  //       pasando junto a Phobos, Deimos y la sonda MGS MOLA.
  //    5. Fase Outpost (u = 0.90 .. 1.00): Aterrizaje frente al Hábitat HDU,
  //       el Rover Perseverance y el Helicóptero Ingenuity en el Cráter Jezero.
  // ============================================================================
  const controlPoints = [
    new THREE.Vector3(1.4, -5.4, -12.0),   // P00 (u=0.00): Cabo Cañaveral Pad 39B (frente-abajo de la Tierra)
    new THREE.Vector3(7.8, -3.6, -15.8),   // P01 (u=0.06): Ascenso bordeando el limbo oriental terrestre
    new THREE.Vector3(11.0, 1.4, -21.8),   // P02 (u=0.12): Órbita ecuatorial derecha de la Tierra (junto a Shuttle/Canadarm)
    new THREE.Vector3(9.4, 7.2, -27.2),    // P03 (u=0.18): Hemisferio norte terrestre
    new THREE.Vector3(1.8, 10.2, -31.0),   // P04 (u=0.24): Ápice orbital sobre el polo/corona de la Tierra (junto a ISS)
    new THREE.Vector3(-7.6, 6.8, -29.8),   // P05 (u=0.30): Bordeando el limbo occidental terrestre (junto a Hubble)
    new THREE.Vector3(-9.2, 1.2, -42.0),   // P06 (u=0.36): Quemado de Inyección Translunar (TLI) saliendo de la Tierra
    new THREE.Vector3(-3.4, -1.6, -68.0),  // P07 (u=0.43): Punto de Lagrange L2 (Telescopio James Webb JWST)
    new THREE.Vector3(4.2, 2.0, -96.0),    // P08 (u=0.50): Cinturón de Asteroides, Bennu 1999 RQ36 y Tormenta Solar DONKI
    new THREE.Vector3(-2.6, 0.8, -124.0),  // P09 (u=0.56): Espacio Interplanetario (Sonda Voyager)
    new THREE.Vector3(-1.4, -1.2, -146.0), // P10 (u=0.62): Aproximación Cislunar (Módulo Lunar Apollo)
    new THREE.Vector3(-0.6, 2.8, -159.0),  // P11 (u=0.68): Bordeando la Luna 3D (Sonda LRO Orbiter)
    new THREE.Vector3(3.8, 1.8, -175.0),   // P12 (u=0.74): Salida de órbita lunar rumbo a Marte
    new THREE.Vector3(1.6, -1.0, -196.0),  // P13 (u=0.80): Aproximación a Marte y luna Phobos
    new THREE.Vector3(0.4, 2.4, -212.0),   // P14 (u=0.85): Bordeando el Planeta Marte 3D (Sonda MGS MOLA y Deimos)
    new THREE.Vector3(-2.0, 1.0, -230.0),  // P15 (u=0.90): Entrada atmosférica hacia el Cráter Jezero
    new THREE.Vector3(-0.5, 0.4, -244.0),  // P16 (u=0.95): Planeo final sobre el Cráter Jezero
    new THREE.Vector3(0.0, 0.2, -251.5),   // P17 (u=1.00): Estacionamiento frente al Outpost (HDU + Perseverance + Ingenuity)
  ];

  const flightCurve = new THREE.CatmullRomCurve3(controlPoints, false, "centripetal", 0.5);

  // ============================================================================
  // B. SISTEMA DE ESPACIO VECTORIAL BLENDER 3D (GRILLAS, EJES X/Y/Z, HANDLES BEZIER)
  // ============================================================================
  function buildBlenderVectorEnvironment() {
    // 1. Grillas eclípticas subdivididas estilo Blender Viewport en cada sector planetario
    const gridZones = [
      { z: -24, y: -9.2, size: 44, div: 22, label: "EARTH_ORBIT_GRID" },
      { z: -96, y: -7.5, size: 52, div: 26, label: "DEEP_SPACE_GRID" },
      { z: -158, y: -7.0, size: 42, div: 21, label: "LUNAR_ORBIT_GRID" },
      { z: -212, y: -7.2, size: 44, div: 22, label: "MARS_ORBIT_GRID" },
      { z: -256, y: -2.38, size: 32, div: 32, label: "OUTPOST_CONSTRUCTION_GRID" },
    ];

    for (const gz of gridZones) {
      const grid = new THREE.GridHelper(gz.size, gz.div, 0x38bdf8, 0x1e293b);
      grid.position.set(0, gz.y, gz.z);
      grid.material.transparent = true;
      grid.material.opacity = gz.z === -256 ? 0.42 : 0.24;
      blenderVectorGroup.add(grid);
    }

    // 2. Ejes Globales de Coordenadas Blender (X Rojo #ff3b5c, Y Verde #22c55e, Z Azul #3b82f6)
    const addWorldAxis = (p1, p2, color, opacity = 0.45) => {
      const geo = new THREE.BufferGeometry().setFromPoints([p1, p2]);
      const line = new THREE.Line(geo, new THREE.LineBasicMaterial({ color, transparent: true, opacity }));
      blenderVectorGroup.add(line);
    };
    // Eje X en el origen orbital de la Tierra (z = -24)
    addWorldAxis(new THREE.Vector3(-35, -0.5, -24), new THREE.Vector3(35, -0.5, -24), 0xff3b5c, 0.42);
    // Eje Y vertical en la Tierra (z = -24)
    addWorldAxis(new THREE.Vector3(0, -25, -24), new THREE.Vector3(0, 25, -24), 0x22c55e, 0.42);
    // Eje Z profundo a lo largo de todo el corredor interplanetario
    addWorldAxis(new THREE.Vector3(0, -0.5, 10), new THREE.Vector3(0, -0.5, -275), 0x3b82f6, 0.38);

    // 3. Tubo y Línea de la Curva Spline 3D (`flightCurve`) + Anillos Vectoriales Transversales
    const splinePoints = flightCurve.getPoints(320);
    const splineGeo = new THREE.BufferGeometry().setFromPoints(splinePoints);
    const splineLine = new THREE.Line(
      splineGeo,
      new THREE.LineBasicMaterial({ color: 0x38bdf8, transparent: true, opacity: 0.65 }),
    );
    blenderVectorGroup.add(splineLine);

    // Riel secundario paralelo (como doble riel vectorial de navegación en Blender)
    const tubeGeo = new THREE.TubeGeometry(flightCurve, 220, 0.045, 6, false);
    const tubeMesh = new THREE.Mesh(
      tubeGeo,
      new THREE.MeshBasicMaterial({ color: 0x00f0ff, wireframe: true, transparent: true, opacity: 0.22 }),
    );
    blenderVectorGroup.add(tubeMesh);

    // 4. Nodos de Control Bezier/Spline y Vectores Tangentes (Handles Naranjas estilo Curva en Edit Mode de Blender)
    const handleNodeGeo = new THREE.OctahedronGeometry(0.22, 0);
    const handleNodeMat = new THREE.MeshBasicMaterial({ color: 0xfc3d21 });
    const handleTipMat = new THREE.MeshBasicMaterial({ color: 0xf59e0b });

    controlPoints.forEach((pt, idx) => {
      const uApprox = idx / (controlPoints.length - 1);
      const tan = flightCurve.getTangentAt(uApprox).normalize();

      const nodeMesh = new THREE.Mesh(handleNodeGeo, handleNodeMat);
      nodeMesh.position.copy(pt);
      blenderVectorGroup.add(nodeMesh);

      // Brazos de tangente Bezier [-T, +T] como cuando editas una curva en Blender
      const handleLen = 2.2;
      const h1 = pt.clone().addScaledVector(tan, -handleLen);
      const h2 = pt.clone().addScaledVector(tan, handleLen);
      const hGeo = new THREE.BufferGeometry().setFromPoints([h1, h2]);
      blenderVectorGroup.add(
        new THREE.Line(hGeo, new THREE.LineBasicMaterial({ color: 0xf59e0b, transparent: true, opacity: 0.55 })),
      );

      const tip1 = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.14, 0.14), handleTipMat);
      tip1.position.copy(h1);
      const tip2 = tip1.clone();
      tip2.position.copy(h2);
      blenderVectorGroup.add(tip1, tip2);
    });

    // 5. Costillas vectoriales perpendiculares a lo largo de la curva (cada 2.5% del recorrido)
    const ribRingGeo = new THREE.RingGeometry(1.85, 1.9, 32);
    const ribRingMat = new THREE.MeshBasicMaterial({
      color: 0x38bdf8,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.14,
      depthWrite: false,
    });
    for (let i = 1; i < 40; i++) {
      const u = i / 40;
      const p = flightCurve.getPointAt(u);
      const t = flightCurve.getTangentAt(u);
      const rib = new THREE.Mesh(ribRingGeo, ribRingMat);
      rib.position.copy(p);
      rib.lookAt(p.clone().add(t));
      blenderVectorGroup.add(rib);
    }
  }

  buildBlenderVectorEnvironment();

  // ============================================================================
  // C. CAMPO ESTELAR PROFUNDO + CONSTELACIONES VECTORIALES
  // ============================================================================
  const starCount = 5400;
  const starGeo = new THREE.BufferGeometry();
  const starPos = new Float32Array(starCount * 3);
  const starColors = new Float32Array(starCount * 3);
  for (let i = 0; i < starCount; i++) {
    const angle = Math.random() * Math.PI * 2;
    const radius = 14.0 + Math.random() * 85;
    starPos[i * 3] = Math.cos(angle) * radius;
    starPos[i * 3 + 1] = Math.sin(angle) * radius * 0.78;
    starPos[i * 3 + 2] = 24 - Math.random() * 330;

    const c =
      i % 5 === 0
        ? [0.22, 0.74, 0.98]
        : i % 7 === 0
          ? [0.99, 0.75, 0.25]
          : i % 11 === 0
            ? [0.98, 0.35, 0.25]
            : [0.92, 0.96, 1.0];
    starColors[i * 3] = c[0];
    starColors[i * 3 + 1] = c[1];
    starColors[i * 3 + 2] = c[2];
  }
  starGeo.setAttribute("position", new THREE.BufferAttribute(starPos, 3));
  starGeo.setAttribute("color", new THREE.BufferAttribute(starColors, 3));
  scene.add(
    new THREE.Points(starGeo, new THREE.PointsMaterial({ size: 0.22, vertexColors: true, transparent: true, opacity: 0.92 })),
  );

  // ============================================================================
  // D. SECTOR 01 & 02: PLANETA TIERRA 3D EN EL CENTRO DEL ARCO ORBITAL
  //    El cohete despega del Pad 39B y BORDEA físicamente toda la esfera de la Tierra
  //    pasando junto a: Mobile Launcher (.glb), Ares I (.glb), Space Shuttle (.glb),
  //    Canadarm CSA (.glb), ISS (.glb) y Hubble (.glb).
  // ============================================================================
  const earthGroup = new THREE.Group();
  earthGroup.position.set(0, -0.5, -24.0);
  scene.add(earthGroup);

  const earthTex = texLoader.load("/public/assets/textures/earth_nasa.jpg");
  const earthMat = new THREE.MeshStandardMaterial({
    map: earthTex,
    bumpMap: earthTex,
    bumpScale: 0.16,
    roughness: 0.44,
    metalness: 0.16,
  });

  const earthRadius = 7.6;
  const earthSphere = new THREE.Mesh(new THREE.SphereGeometry(earthRadius, 64, 64), earthMat);
  earthGroup.add(earthSphere);

  // Jaula geodésica vectorial sutil sobre la Tierra (meridianos y paralelos estilo Blender/NASA)
  const earthWireCage = new THREE.Mesh(
    new THREE.SphereGeometry(earthRadius * 1.015, 24, 16),
    new THREE.MeshBasicMaterial({ color: 0x38bdf8, wireframe: true, transparent: true, opacity: 0.08 }),
  );
  blenderVectorGroup.add(earthWireCage);
  earthWireCage.position.copy(earthGroup.position);

  // Atmósfera Rayleigh 3D alrededor de la Tierra
  const earthAtmo = new THREE.Mesh(
    new THREE.SphereGeometry(earthRadius * 1.11, 64, 64),
    new THREE.ShaderMaterial({
      vertexShader: ATMOSPHERE_VERTEX,
      fragmentShader: ATMOSPHERE_FRAGMENT,
      uniforms: { uAtmoColor: { value: new THREE.Color(0x00b4ff) } },
      blending: THREE.AdditiveBlending,
      side: THREE.BackSide,
      transparent: true,
      depthWrite: false,
    }),
  );
  earthGroup.add(earthAtmo);

  // Anillos vectoriales ecuatorial y polar alrededor de la Tierra
  const eqRing = new THREE.Mesh(
    new THREE.TorusGeometry(earthRadius + 2.2, 0.035, 16, 128),
    new THREE.MeshBasicMaterial({ color: 0x38bdf8, transparent: true, opacity: 0.42 }),
  );
  eqRing.rotation.x = Math.PI / 2 + 0.35;
  earthGroup.add(eqRing);

  const polarRing = new THREE.Mesh(
    new THREE.TorusGeometry(earthRadius + 2.8, 0.025, 16, 128),
    new THREE.MeshBasicMaterial({ color: 0xfc3d21, transparent: true, opacity: 0.32 }),
  );
  polarRing.rotation.y = 0.55;
  earthGroup.add(polarRing);

  // 1. Mobile Launcher Pad 39B (.glb) junto al punto de despegue en Cabo Cañaveral (P00)
  const launchPadHolder = new THREE.Group();
  launchPadHolder.position.set(3.2, -5.2, -13.2);
  scene.add(launchPadHolder);
  loadNasaGlbNormalized("/public/assets/models/mobile_launcher.glb", 2.8, (model) => {
    launchPadHolder.add(model);
  });

  // 2. Cohete Ares I (.glb) en ascenso inicial junto al limbo oriental terrestre (P01)
  const aresStageHolder = new THREE.Group();
  aresStageHolder.position.set(9.8, -3.2, -16.8);
  aresStageHolder.rotation.z = -0.35;
  scene.add(aresStageHolder);
  loadNasaGlbNormalized("/public/assets/models/ares_rocket.glb", 4.2, (model) => {
    aresStageHolder.add(model);
  });

  // 3. Transbordador Espacial NASA Space Shuttle (.glb) bordeando el ecuador derecho de la Tierra (P02)
  const shuttleHolder = new THREE.Group();
  shuttleHolder.position.set(12.6, 1.8, -22.5);
  shuttleHolder.rotation.set(0.3, -0.4, 0.25);
  scene.add(shuttleHolder);
  loadNasaGlbNormalized("/public/assets/models/space_shuttle.glb", 3.6, (model) => {
    shuttleHolder.add(model);
  });

  // 4. Brazo Robótico Canadarm CSA (.glb) operando en órbita terrestre (P03)
  const canadarmHolder = new THREE.Group();
  canadarmHolder.position.set(10.8, 7.8, -27.8);
  scene.add(canadarmHolder);
  loadNasaGlbNormalized("/public/assets/models/canadarm_csa.glb", 3.0, (model) => {
    canadarmHolder.add(model);
  });

  // 5 & 6. Estación Espacial Internacional ISS Detailed (.glb) + ISS Base (.glb) en el ápice superior de la Tierra (P04)
  const issHolder = new THREE.Group();
  issHolder.position.set(1.8, 12.2, -31.8);
  scene.add(issHolder);
  loadNasaGlbNormalized("/public/assets/models/iss_detailed.glb", 5.2, (model) => {
    issHolder.add(model);
  });

  const issRelayHolder = new THREE.Group();
  issRelayHolder.position.set(-3.4, 11.4, -31.2);
  scene.add(issRelayHolder);
  loadNasaGlbNormalized("/public/assets/models/iss_station.glb", 3.2, (model) => {
    issRelayHolder.add(model);
  });

  // 7. Telescopio Espacial Hubble (.glb) en el limbo occidental terrestre antes del salto TLI (P05)
  const hubbleHolder = new THREE.Group();
  hubbleHolder.position.set(-10.2, 6.4, -30.2);
  scene.add(hubbleHolder);
  loadNasaGlbNormalized("/public/assets/models/hubble_telescope.glb", 3.6, (model) => {
    hubbleHolder.add(model);
  });

  // ============================================================================
  // E. SECTOR 03: ESPACIO PROFUNDO VECTORIAL (JWST, BENNU, SOL DONKI, VOYAGER + 95 ROCAS PBR)
  // ============================================================================
  // 8. Telescopio Espacial James Webb JWST (.glb) en el punto de Lagrange L2 (P07)
  const jwstHolder = new THREE.Group();
  jwstHolder.position.set(-6.4, -1.2, -68.5);
  scene.add(jwstHolder);
  loadNasaGlbNormalized("/public/assets/models/jwst_telescope.glb", 4.6, (model) => {
    jwstHolder.add(model);
  });

  // Sol Activo DONKI + Corona + Onda de Choque CME
  const sunGroup = new THREE.Group();
  const sunTex = texLoader.load(
    proxyImg("https://images-assets.nasa.gov/image/GSFC_20171208_Archive_e001435/GSFC_20171208_Archive_e001435~orig.jpg"),
  );
  const sunSphere = new THREE.Mesh(
    new THREE.SphereGeometry(6.2, 48, 48),
    new THREE.MeshBasicMaterial({ map: sunTex, color: 0xffedd5 }),
  );
  sunGroup.add(sunSphere);

  const coronaRing = new THREE.Mesh(
    new THREE.RingGeometry(6.3, 9.5, 64),
    new THREE.MeshBasicMaterial({
      color: 0xf59e0b,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.45,
      depthWrite: false,
    }),
  );
  sunGroup.add(coronaRing);
  sunGroup.position.set(14.5, 4.8, -98.0);
  scene.add(sunGroup);

  // 9. Asteroide Oficial NASA Bennu (1999 RQ36 .glb con UVs esféricos y relieve de cráteres) junto a P08
  const bennuGroup = new THREE.Group();
  bennuGroup.position.set(0.4, 2.2, -96.5);
  scene.add(bennuGroup);
  loadNasaGlbNormalized("/public/assets/models/asteroid_bennu.glb", 4.8, (model) => {
    model.traverse((c) => {
      if (c.isMesh) {
        c.material = new THREE.MeshStandardMaterial({
          map: rockDiffuseTex,
          bumpMap: rockDiffuseTex,
          bumpScale: 0.24,
          roughness: 0.85,
          metalness: 0.15,
        });
      }
    });
    bennuGroup.add(model);
  });

  // 10. Sonda Interplanetaria Voyager (.glb) en P09
  const voyagerHolder = new THREE.Group();
  voyagerHolder.position.set(-5.8, 1.2, -124.5);
  scene.add(voyagerHolder);
  loadNasaGlbNormalized("/public/assets/models/voyager_probe.glb", 4.2, (model) => {
    voyagerHolder.add(model);
  });

  // Partículas de tormenta solar DONKI (CME)
  const cmeCount = 480;
  const cmeGeo = new THREE.BufferGeometry();
  const cmePos = new Float32Array(cmeCount * 3);
  for (let i = 0; i < cmeCount; i++) {
    cmePos[i * 3] = (Math.random() - 0.5) * 26;
    cmePos[i * 3 + 1] = (Math.random() - 0.5) * 18;
    cmePos[i * 3 + 2] = -70 - Math.random() * 175;
  }
  cmeGeo.setAttribute("position", new THREE.BufferAttribute(cmePos, 3));
  const cmeParticles = new THREE.Points(
    cmeGeo,
    new THREE.PointsMaterial({ color: 0xf97316, size: 0.32, transparent: true, opacity: 0.68 }),
  );
  scene.add(cmeParticles);

  // Cinturón de 95 Asteroides y Rocas Espaciales con texturas PBR y relieve distribuidos alrededor de la curva
  const asteroidGroup = new THREE.Group();
  const rockGeo1 = new THREE.DodecahedronGeometry(0.75, 2);
  const rockGeo2 = new THREE.IcosahedronGeometry(0.62, 1);
  const pbrRockMat = new THREE.MeshStandardMaterial({
    map: rockDiffuseTex,
    bumpMap: rockDiffuseTex,
    bumpScale: 0.18,
    roughness: 0.86,
    metalness: 0.14,
  });

  for (let i = 0; i < 95; i++) {
    const u = 0.08 + (i / 95) * 0.82;
    const centerPt = flightCurve.getPointAt(u);
    const m = new THREE.Mesh(i % 2 === 0 ? rockGeo1 : rockGeo2, pbrRockMat);
    const side = i % 2 === 0 ? 1 : -1;
    const xOff = side * (4.2 + (i % 5) * 1.4);
    const yOff = ((i % 7) - 3) * 1.25;
    m.position.set(centerPt.x + xOff, centerPt.y + yOff, centerPt.z);
    m.scale.set(0.45 + (i % 4) * 0.3, 0.35 + (i % 3) * 0.25, 0.4 + (i % 5) * 0.24);
    m.rotation.set(i * 0.7, i * 1.1, i * 0.5);
    asteroidGroup.add(m);
  }
  scene.add(asteroidGroup);

  // ============================================================================
  // F. SECTOR 04: PLANETA LUNA 3D (EL COHETE BORDEA LA LUNA JUNTO A APOLLO Y LRO)
  // ============================================================================
  const moonGroup = new THREE.Group();
  moonGroup.position.set(5.4, 0.2, -159.0);
  scene.add(moonGroup);

  const moonMat = new THREE.MeshStandardMaterial({
    map: lunarDiffuseTex,
    bumpMap: lunarDiffuseTex,
    bumpScale: 0.18,
    roughness: 0.88,
    metalness: 0.08,
  });
  const moonRadius = 4.8;
  const moonSphere = new THREE.Mesh(new THREE.SphereGeometry(moonRadius, 64, 64), moonMat);
  moonGroup.add(moonSphere);

  // Jaula geodésica vectorial sobre la Luna
  const moonWire = new THREE.Mesh(
    new THREE.SphereGeometry(moonRadius * 1.02, 20, 14),
    new THREE.MeshBasicMaterial({ color: 0xe2e8f0, wireframe: true, transparent: true, opacity: 0.1 }),
  );
  moonWire.position.copy(moonGroup.position);
  blenderVectorGroup.add(moonWire);

  // 11. Módulo Lunar Apollo / Artemis (.glb) en la entrada cislunar (P10)
  const landerHolder = new THREE.Group();
  landerHolder.position.set(-4.2, -1.0, -146.5);
  scene.add(landerHolder);
  loadNasaGlbNormalized("/public/assets/models/apollo_lander.glb", 3.4, (model) => {
    landerHolder.add(model);
  });

  // 12. Sonda Lunar Reconnaissance Orbiter LRO (.glb) orbitando entre el cohete y la Luna (P11)
  const lroHolder = new THREE.Group();
  lroHolder.position.set(1.8, 4.2, -159.5);
  scene.add(lroHolder);
  loadNasaGlbNormalized("/public/assets/models/lro_orbiter.glb", 3.6, (model) => {
    lroHolder.add(model);
  });

  // ============================================================================
  // G. SECTOR 05: PLANETA MARTE 3D + PHOBOS Y DEIMOS + SONDA MGS MOLA (.GLB)
  // ============================================================================
  const marsGroup = new THREE.Group();
  marsGroup.position.set(-5.8, -0.2, -212.0);
  scene.add(marsGroup);

  const marsTex = texLoader.load("/public/assets/textures/mars_nasa.jpg");
  const marsMat = new THREE.MeshStandardMaterial({
    map: marsTex,
    bumpMap: marsTex,
    bumpScale: 0.2,
    roughness: 0.76,
    metalness: 0.12,
  });
  const marsRadius = 5.2;
  const marsSphere = new THREE.Mesh(new THREE.SphereGeometry(marsRadius, 64, 64), marsMat);
  marsGroup.add(marsSphere);

  const marsWire = new THREE.Mesh(
    new THREE.SphereGeometry(marsRadius * 1.02, 22, 16),
    new THREE.MeshBasicMaterial({ color: 0xfc3d21, wireframe: true, transparent: true, opacity: 0.12 }),
  );
  marsWire.position.copy(marsGroup.position);
  blenderVectorGroup.add(marsWire);

  const marsAtmo = new THREE.Mesh(
    new THREE.SphereGeometry(marsRadius * 1.09, 48, 48),
    new THREE.ShaderMaterial({
      vertexShader: ATMOSPHERE_VERTEX,
      fragmentShader: ATMOSPHERE_FRAGMENT,
      uniforms: { uAtmoColor: { value: new THREE.Color(0xf97316) } },
      blending: THREE.AdditiveBlending,
      side: THREE.BackSide,
      transparent: true,
      depthWrite: false,
    }),
  );
  marsGroup.add(marsAtmo);

  // Luna Phobos 3D con relieve real
  const phobosTex = texLoader.load("/public/assets/textures/phobos_nasa.jpg");
  const phobosMesh = new THREE.Mesh(
    new THREE.DodecahedronGeometry(0.95, 3),
    new THREE.MeshStandardMaterial({ map: phobosTex, bumpMap: phobosTex, bumpScale: 0.18, roughness: 0.88 }),
  );
  phobosMesh.scale.set(1.35, 0.95, 1.05);
  phobosMesh.position.set(marsRadius + 2.4, 1.8, 1.5);
  marsGroup.add(phobosMesh);

  // 13. Sonda Mars Global Surveyor MGS MOLA (.glb) bordeando Marte en P14
  const mgsHolder = new THREE.Group();
  mgsHolder.position.set(-1.6, 3.8, -212.5);
  scene.add(mgsHolder);
  loadNasaGlbNormalized("/public/assets/models/mars_mgs_orbiter.glb", 3.6, (model) => {
    mgsHolder.add(model);
  });

  // ============================================================================
  // H. SECTOR 06: SUPERFICIE DEL CRÁTER JEZERO (HDU + PERSEVERANCE + INGENUITY)
  // ============================================================================
  const outpostGroup = new THREE.Group();
  outpostGroup.position.set(0, -1.85, -258.5);
  scene.add(outpostGroup);

  const groundMat = new THREE.MeshStandardMaterial({
    map: marsTex,
    bumpMap: marsTex,
    bumpScale: 0.25,
    color: 0xd97706,
    roughness: 0.9,
  });
  const groundDisk = new THREE.Mesh(new THREE.CylinderGeometry(11.5, 13.0, 0.6, 64), groundMat);
  groundDisk.position.y = -0.35;
  outpostGroup.add(groundDisk);

  for (let i = 0; i < 18; i++) {
    const b = new THREE.Mesh(rockGeo1, pbrRockMat);
    const a = (i / 18) * Math.PI * 2;
    const r = 5.6 + (i % 3) * 1.4;
    b.position.set(Math.cos(a) * r, 0.15, Math.sin(a) * r);
    b.scale.set(0.6 + (i % 3) * 0.35, 0.4 + (i % 2) * 0.25, 0.55);
    b.rotation.set(i, i * 2, 0);
    outpostGroup.add(b);
  }

  // 14. Hábitat Oficial NASA HDU (.glb con textura HDU_01 sin transparencia accidental)
  const hduHolder = new THREE.Group();
  hduHolder.position.set(0, 1.15, 0);
  outpostGroup.add(hduHolder);
  loadNasaGlbNormalized("/public/assets/models/nasa_habitat_hdu.glb", 3.8, (model) => {
    hduHolder.add(model);
  });

  // 15. Rover Mars 2020 Perseverance (.glb con 40 texturas oficiales NASA) explorando junto al hábitat
  const perseveranceHolder = new THREE.Group();
  perseveranceHolder.position.set(-3.2, 0.65, 2.2);
  perseveranceHolder.rotation.y = 0.65;
  outpostGroup.add(perseveranceHolder);
  loadNasaGlbNormalized("/public/assets/models/perseverance_rover.glb", 2.6, (model) => {
    perseveranceHolder.add(model);
  });

  // 16. Helicóptero Ingenuity Mars (.glb) volando sobre el Outpost
  const ingenuityHolder = new THREE.Group();
  ingenuityHolder.position.set(2.5, 2.6, 1.6);
  outpostGroup.add(ingenuityHolder);
  loadNasaGlbNormalized("/public/assets/models/ingenuity_mars.glb", 1.85, (model) => {
    ingenuityHolder.add(model);
  });

  const dynamicModules = new THREE.Group();
  outpostGroup.add(dynamicModules);

  syncOutpost3DCallback = (missionState) => {
    if (!missionState) return;
    groundMat.color.setHex(missionState.siteId === "moon" ? 0x94a3b8 : 0xd97706);

    while (dynamicModules.children.length > 0) {
      dynamicModules.remove(dynamicModules.children[0]);
    }

    const counts = {};
    for (const inst of missionState.installed) {
      counts[inst.id] = (counts[inst.id] || 0) + 1;
    }

    for (let i = 0; i < (counts["solar-panel"] || 0); i++) {
      const panel = new THREE.Mesh(
        new THREE.BoxGeometry(1.5, 0.06, 0.9),
        new THREE.MeshStandardMaterial({ color: 0x0284c7, metalness: 0.88, roughness: 0.15 }),
      );
      panel.position.set(-3.8 - i * 1.35, 0.5, -1.2 - i * 0.4);
      panel.rotation.x = 0.35;
      dynamicModules.add(panel);
    }

    if (counts["regolith-wall"]) {
      const arch = new THREE.Mesh(
        new THREE.TorusGeometry(2.3 + counts["regolith-wall"] * 0.22, 0.3, 18, 48, Math.PI),
        new THREE.MeshStandardMaterial({
          map: rockDiffuseTex,
          bumpMap: rockDiffuseTex,
          bumpScale: 0.15,
          color: missionState.siteId === "moon" ? 0xcbd5e1 : 0xb45309,
          roughness: 0.92,
        }),
      );
      arch.position.set(0, 0.1, 0);
      dynamicModules.add(arch);
    }

    for (let i = 0; i < (counts["greenhouse"] || 0); i++) {
      const dome = new THREE.Mesh(
        new THREE.SphereGeometry(1.05, 24, 16, 0, Math.PI * 2, 0, Math.PI / 2),
        new THREE.MeshStandardMaterial({
          color: 0x10b981,
          emissive: 0x059669,
          emissiveIntensity: 0.5,
          transparent: true,
          opacity: 0.85,
        }),
      );
      dome.position.set(3.2 + i * 2.1, 0, 0.8);
      dynamicModules.add(dome);
    }

    for (let i = 0; i < (counts["water-recycler"] || 0); i++) {
      const tank = new THREE.Mesh(
        new THREE.CylinderGeometry(0.48, 0.48, 1.2, 24),
        new THREE.MeshStandardMaterial({ color: 0x38bdf8, metalness: 0.75, roughness: 0.2 }),
      );
      tank.position.set(-2.3, 0.55, -2.4 - i * 1.15);
      dynamicModules.add(tank);
    }

    if (counts["storm-shelter"]) {
      const shieldDome = new THREE.Mesh(
        new THREE.SphereGeometry(4.5, 32, 20, 0, Math.PI * 2, 0, Math.PI / 2),
        new THREE.MeshBasicMaterial({
          color: 0x38bdf8,
          wireframe: true,
          transparent: true,
          opacity: 0.34,
        }),
      );
      dynamicModules.add(shieldDome);
    }

    if (counts["big-antenna"]) {
      const dish = new THREE.Mesh(
        new THREE.ConeGeometry(1.0, 0.5, 24, 1, true),
        new THREE.MeshStandardMaterial({ color: 0xfacc15, metalness: 0.8, roughness: 0.2, side: THREE.DoubleSide }),
      );
      dish.position.set(2.8, 1.55, -2.3);
      dish.rotation.x = -0.6;
      dynamicModules.add(dish);
    }
  };

  // ============================================================================
  // I. COHETE PRINCIPAL NASA #17 (`saturn_v_rocket.glb`) + PLUMA VOLUMÉTRICA
  //    Sigue tangencialmente la curva orbital 3D (`flightCurve`), bordeando la Tierra
  // ============================================================================
  const shipGroup = new THREE.Group();
  const rocketHullHolder = new THREE.Group();
  shipGroup.add(rocketHullHolder);

  loadNasaGlbNormalized(
    "/public/assets/models/saturn_v_rocket.glb",
    2.5,
    (wrapper) => {
      // Con Object3D.lookAt(target), el eje +Z local apunta hacia adelante (hacia target)
      // y -Z apunta hacia atrás (cola). Rotamos +Math.PI / 2 en X para que la nariz (+Y original)
      // apunte hacia +Z (adelante) y las 5 toberas F-1 (-Y original) queden en -Z (atrás).
      wrapper.rotation.x = Math.PI / 2;
      rocketHullHolder.add(wrapper);
    },
    { hideGizmo: false },
  );

  const plumeMaterial = new THREE.ShaderMaterial({
    vertexShader: ROCKET_PLUME_VERTEX,
    fragmentShader: ROCKET_PLUME_FRAGMENT,
    uniforms: { uTime: { value: 0 } },
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
  });

  // En el sistema local de shipGroup (con lookAt hacia adelante = +Z), la cola está en z = -1.25
  const plumeGroup = new THREE.Group();
  plumeGroup.position.set(0, 0, -2.1);

  const plumePlaneGeo = new THREE.PlaneGeometry(0.65, 1.75);
  for (let i = 0; i < 3; i++) {
    const pMesh = new THREE.Mesh(plumePlaneGeo, plumeMaterial);
    pMesh.rotation.x = -Math.PI / 2;
    pMesh.rotation.y = (i * Math.PI) / 3;
    plumeGroup.add(pMesh);
  }
  shipGroup.add(plumeGroup);

  const nozzleGlow = new THREE.Mesh(
    new THREE.SphereGeometry(0.19, 16, 16),
    new THREE.MeshBasicMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.95,
      blending: THREE.AdditiveBlending,
    }),
  );
  nozzleGlow.scale.set(1.1, 1.1, 0.5);
  nozzleGlow.position.set(0, 0, -1.22);
  shipGroup.add(nozzleGlow);

  const engineLight = new THREE.PointLight(0x38bdf8, 4.5, 18);
  engineLight.position.set(0, 0, -1.5);
  shipGroup.add(engineLight);

  scene.add(shipGroup);

  // ============================================================================
  // J. LOS 25 PORTALES CURVOS SIN RECUADROS ALINEADOS A LA CURVA VECTORIAL 3D
  // ============================================================================
  const portalMeshes = [];
  const portalRings = [];
  const portalDiskGeo = new THREE.CircleGeometry(3.2, 64);
  const gyroRingGeo = new THREE.TorusGeometry(2.95, 0.022, 16, 100);

  const envColors = {
    tierra: new THREE.Color(0x38bdf8),
    despegue: new THREE.Color(0x60a5fa),
    universo: new THREE.Color(0xf59e0b),
    luna: new THREE.Color(0xe2e8f0),
    marte: new THREE.Color(0xfc3d21),
  };

  flatPortalsList.forEach((item, idx) => {
    const u = item.curveU;
    const splinePos = flightCurve.getPointAt(u);
    const tangent = flightCurve.getTangentAt(u).normalize();

    // Desplazamos cada portal ligeramente hacia el exterior de la curva para dejar libre la vista del planeta
    const sideDir = new THREE.Vector3().crossVectors(tangent, new THREE.Vector3(0, 1, 0)).normalize();
    const lateralOffset = (idx % 2 === 0 ? 1 : -1) * 1.85;
    const portalPos = splinePos.clone().addScaledVector(sideDir, lateralOffset);

    const pColor =
      item.video.tier === "veo_3_1_quality"
        ? new THREE.Color(0xf59e0b)
        : (envColors[item.envId] ?? new THREE.Color(0x38bdf8));

    const mat = new THREE.ShaderMaterial({
      vertexShader: HALO_PORTAL_VERTEX,
      fragmentShader: HALO_PORTAL_FRAGMENT,
      transparent: true,
      depthWrite: false,
      side: THREE.DoubleSide,
      uniforms: {
        uTexture: { value: new THREE.Texture() },
        uRevealProgress: { value: 0.6 },
        uPassFade: { value: 1.0 },
        uTime: { value: 0 },
        uHoverUv: { value: new THREE.Vector2(0.5, 0.5) },
        uHoverActive: { value: 0.0 },
        uPortalColor: { value: pColor },
      },
    });

    if (item.video.referenceImageUrl) {
      texLoader.load(proxyImg(item.video.referenceImageUrl), (tex) => {
        tex.minFilter = THREE.LinearFilter;
        mat.uniforms.uTexture.value = tex;
      });
    }

    const portalMesh = new THREE.Mesh(portalDiskGeo, mat);
    portalMesh.position.copy(portalPos);
    portalMesh.lookAt(portalPos.clone().sub(tangent));
    portalMesh.userData = { ...item, curveU: u };
    scene.add(portalMesh);
    portalMeshes.push(portalMesh);

    const ringMat = new THREE.MeshBasicMaterial({
      color: pColor,
      transparent: true,
      opacity: 0.45,
      depthWrite: false,
    });
    const ringMesh = new THREE.Mesh(gyroRingGeo, ringMat);
    ringMesh.position.copy(portalPos);
    ringMesh.lookAt(portalPos.clone().sub(tangent));
    scene.add(ringMesh);
    portalRings.push(ringMesh);
  });

  if (currentMission) syncOutpost3DCallback?.(currentMission.state);

  // ============================================================================
  // K. CONTROLES INTERACTIVOS DE VIEWPORT BLENDER (ARRASTRAR PARA ORBITAR + PRESETS X/Y/Z)
  // ============================================================================
  const mouse = new THREE.Vector2(0, 0);
  const raycaster = new THREE.Raycaster();

  let isDraggingViewport = false;
  let prevPointer = { x: 0, y: 0 };
  let userOrbitYaw = 0;
  let userOrbitPitch = 0.12;

  const webglContainer = document.getElementById("webgl-container");
  webglContainer?.addEventListener("pointerdown", (e) => {
    isDraggingViewport = true;
    prevPointer = { x: e.clientX, y: e.clientY };
  });

  window.addEventListener("pointerup", () => {
    isDraggingViewport = false;
  });

  window.addEventListener("pointermove", (e) => {
    mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;

    if (isDraggingViewport) {
      const dx = (e.clientX - prevPointer.x) * 0.0065;
      const dy = (e.clientY - prevPointer.y) * 0.0055;
      userOrbitYaw = Math.max(-1.6, Math.min(1.6, userOrbitYaw - dx));
      userOrbitPitch = Math.max(-0.85, Math.min(1.15, userOrbitPitch + dy));
      prevPointer = { x: e.clientX, y: e.clientY };
    }
  });

  toggleBlenderGridCallback = () => {
    blenderVectorGroup.visible = !blenderVectorGroup.visible;
    return blenderVectorGroup.visible;
  };

  setCameraPresetCallback = (axis) => {
    if (axis === "x") {
      userOrbitYaw = 1.15;
      userOrbitPitch = 0.15;
    } else if (axis === "y") {
      userOrbitYaw = 0.0;
      userOrbitPitch = 1.05;
    } else {
      userOrbitYaw = 0.0;
      userOrbitPitch = 0.12;
    }
  };

  window.addEventListener("resize", () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  let currentU = 0.0;
  const clock = new THREE.Clock();

  function animate() {
    requestAnimationFrame(animate);
    const t = clock.getElapsedTime();

    plumeMaterial.uniforms.uTime.value = t;
    nozzleGlow.scale.setScalar(0.95 + Math.sin(t * 45) * 0.12);

    if (autoFlightActive) {
      const elapsedSec = (performance.now() - pitchStartTime) / 1000;
      const pitchRatio = Math.min(1, elapsedSec / 180);
      const maxScroll = Math.max(1, document.body.scrollHeight - window.innerHeight);
      window.scrollTo({ top: pitchRatio * maxScroll, behavior: "instant" });

      const mins = Math.floor(elapsedSec / 60);
      const secs = String(Math.floor(elapsedSec % 60)).padStart(2, "0");
      const slideNum = Math.min(6, Math.floor(pitchRatio * 6) + 1);
      const badge = document.getElementById("pitch-timer-badge");
      if (badge) badge.textContent = `PITCH 0${mins}:${secs} / 03:00 · SLIDE 0${slideNum}/06`;

      if (pitchRatio >= 1) {
        autoFlightActive = false;
        const autoBtn = document.getElementById("btn-auto-flight");
        if (autoBtn) {
          autoBtn.classList.remove("active");
          autoBtn.textContent = "▶ INICIAR PITCH 3 MIN";
        }
      }
    }

    const maxScroll = Math.max(1, document.body.scrollHeight - window.innerHeight);
    const scrollRatio = Math.min(1, Math.max(0, window.scrollY / maxScroll));

    // Suavizado cinemático a lo largo de la curva vectorial 3D (`flightCurve`)
    const targetU = Math.min(0.996, Math.max(0.002, scrollRatio * 0.994));
    currentU += (targetU - currentU) * 0.08;

    const shipPos = flightCurve.getPointAt(currentU);
    const shipTan = flightCurve.getTangentAt(currentU).normalize();

    // Pequeño desplazamiento interactivo del cohete con el cursor
    const rightVec = new THREE.Vector3().crossVectors(shipTan, new THREE.Vector3(0, 1, 0)).normalize();
    const upVec = new THREE.Vector3().crossVectors(rightVec, shipTan).normalize();

    const finalShipPos = shipPos
      .clone()
      .addScaledVector(rightVec, mouse.x * 0.65)
      .addScaledVector(upVec, mouse.y * 0.45 - 0.22);

    shipGroup.position.copy(finalShipPos);

    // Orientar el cohete exactamente a lo largo del vector tangente de la curva orbital 3D
    const lookTarget = finalShipPos.clone().add(shipTan);
    shipGroup.lookAt(lookTarget);

    // Cámara de persecución vectorial con soporte de órbita estilo Blender (userOrbitYaw / userOrbitPitch)
    const camDist = 6.2;
    const backVec = shipTan.clone().negate();
    const cosP = Math.cos(userOrbitPitch);
    const sinP = Math.sin(userOrbitPitch);
    const cosY = Math.cos(userOrbitYaw);
    const sinY = Math.sin(userOrbitYaw);

    const orbitOffset = new THREE.Vector3()
      .addScaledVector(backVec, cosP * cosY * camDist)
      .addScaledVector(rightVec, cosP * sinY * camDist)
      .addScaledVector(upVec, sinP * camDist + 0.55);

    const desiredCamPos = finalShipPos.clone().add(orbitOffset);
    camera.position.lerp(desiredCamPos, 0.12);

    // En la fase de órbita terrestre (currentU < 0.34), sesgamos suavemente la mirada hacia la Tierra
    // para que el espectador vea cómo el cohete bordea la enorme esfera del Planeta Tierra 3D
    const camLookTarget = finalShipPos.clone().addScaledVector(shipTan, 3.8);
    if (currentU < 0.34) {
      const earthBias = (1.0 - currentU / 0.34) * 0.24;
      camLookTarget.lerp(earthGroup.position, earthBias);
    }
    camera.lookAt(camLookTarget);

    // Actualizar los 25 portales a lo largo de la curva
    let closestPortalIdx = 0;
    let bestDist = Infinity;

    portalMeshes.forEach((mesh, idx) => {
      const u = mesh.material.uniforms;
      u.uTime.value = t;

      const dU = mesh.userData.curveU - currentU;
      const dist3D = mesh.position.distanceTo(finalShipPos);
      if (dist3D < bestDist) {
        bestDist = dist3D;
        closestPortalIdx = idx;
      }

      const approachFactor = Math.max(0, 1 - dist3D / 24);
      const scale = 0.72 + approachFactor * 0.48;
      mesh.scale.setScalar(scale);
      portalRings[idx].scale.setScalar(scale);
      portalRings[idx].rotation.z = t * (idx % 2 === 0 ? 0.35 : -0.35);

      const targetReveal = revealAllMode ? 1.0 : Math.min(1.0, 0.42 + approachFactor * 0.95);
      u.uRevealProgress.value += (targetReveal - u.uRevealProgress.value) * 0.1;

      if (dU < -0.015) {
        u.uPassFade.value = Math.max(0, 1 - (-0.015 - dU) * 28);
      } else if (dU > 0.22) {
        u.uPassFade.value = Math.max(0.08, 1 - (dU - 0.22) * 4.5);
      } else {
        u.uPassFade.value = 1.0;
      }
      portalRings[idx].material.opacity = u.uPassFade.value * (0.18 + approachFactor * 0.55);
    });

    raycaster.setFromCamera(mouse, camera);
    const hits = raycaster.intersectObjects(portalMeshes);
    if (hits.length > 0 && hits[0].uv) {
      const hitMesh = hits[0].object;
      hitMesh.material.uniforms.uHoverUv.value.copy(hits[0].uv);
      hitMesh.material.uniforms.uHoverActive.value = 1.0;
    }

    // Rotaciones cinemáticas de planetas y de los 17 modelos oficiales NASA .GLB
    earthSphere.rotation.y = t * 0.12;
    earthWireCage.rotation.y = t * 0.12;
    aresStageHolder.rotation.y = t * 0.35;
    shuttleHolder.rotation.y = -0.4 + Math.sin(t * 0.5) * 0.18;
    canadarmHolder.rotation.y = t * 0.28;
    issHolder.rotation.y = t * 0.18;
    issRelayHolder.rotation.y = -t * 0.25;
    hubbleHolder.rotation.z = t * 0.22;

    jwstHolder.rotation.y = Math.sin(t * 0.3) * 0.35;
    sunSphere.rotation.y = t * 0.08;
    coronaRing.scale.setScalar(1 + Math.sin(t * 2.5) * 0.06);
    cmeParticles.position.z = (t * 14) % 40;

    bennuGroup.rotation.y = t * 0.32;
    bennuGroup.rotation.x = t * 0.16;
    voyagerHolder.rotation.y = t * 0.24;

    moonSphere.rotation.y = t * 0.09;
    moonWire.rotation.y = t * 0.09;
    lroHolder.rotation.y = t * 0.35;
    landerHolder.rotation.y = Math.sin(t * 0.4) * 0.25;

    marsSphere.rotation.y = t * 0.14;
    marsWire.rotation.y = t * 0.14;
    mgsHolder.rotation.y = -t * 0.38;
    phobosMesh.position.x = Math.cos(t * 0.55) * (marsRadius + 2.4);
    phobosMesh.position.z = Math.sin(t * 0.55) * (marsRadius + 2.4);

    outpostGroup.rotation.y = Math.sin(t * 0.18) * 0.12;
    ingenuityHolder.position.y = 2.5 + Math.sin(t * 3.4) * 0.35;
    ingenuityHolder.position.x = 2.4 + Math.cos(t * 1.4) * 0.85;
    ingenuityHolder.rotation.y = t * 2.8;

    asteroidGroup.children.forEach((r, idx) => {
      r.rotation.x += 0.004 * ((idx % 3) + 1);
      r.rotation.y += 0.005 * ((idx % 2) + 1);
    });

    // Actualizar Telemetría Vectorial estilo Blender en tiempo real
    updateBlenderVectorHud(finalShipPos, shipTan, currentU);

    if (closestPortalIdx !== activePortalGlobalIdx) {
      activePortalGlobalIdx = closestPortalIdx;
      updateCockpitHud(closestPortalIdx, currentU);
    }

    const activeStage = scrollRatio > 0.86 ? 5 : Math.min(4, Math.floor((scrollRatio / 0.86) * 5));
    document.querySelectorAll(".room-pill").forEach((btn) => {
      btn.classList.toggle("active", Number(btn.getAttribute("data-room")) === activeStage);
    });

    if (!autoFlightActive) {
      const badge = document.getElementById("pitch-timer-badge");
      if (badge) badge.textContent = `PITCH 03:00 · SLIDE 0${activeStage + 1}/06`;
    }

    renderer.render(scene, camera);
  }

  animate();
}

function updateBlenderVectorHud(pos, tan, uVal) {
  const posEl = document.getElementById("hud-vec-pos");
  const tanEl = document.getElementById("hud-vec-tan");
  if (posEl) {
    const fx = (pos.x >= 0 ? "+" : "") + pos.x.toFixed(2);
    const fy = (pos.y >= 0 ? "+" : "") + pos.y.toFixed(2);
    const fz = (pos.z >= 0 ? "+" : "") + pos.z.toFixed(2);
    posEl.textContent = `VEC POS [X: ${fx}  Y: ${fy}  Z: ${fz}]`;
  }
  if (tanEl) {
    const phaseLabel =
      uVal < 0.35
        ? "BORDEANDO PLANETA TIERRA (ARCO LEO)"
        : uVal < 0.56
          ? "INYECCIÓN PROFUNDA (JWST · BENNU · VOYAGER)"
          : uVal < 0.74
            ? "BORDEANDO LUNA 3D (APOLLO · LRO)"
            : uVal < 0.9
              ? "BORDEANDO MARTE 3D (PHOBOS · MGS MOLA)"
              : "CRÁTER JEZERO (HDU · PERSEVERANCE · INGENUITY)";
    tanEl.textContent = `TAN (${tan.x.toFixed(2)}, ${tan.y.toFixed(2)}, ${tan.z.toFixed(2)}) · ${phaseLabel}`;
  }
}

function updateCockpitHud(portalIdx, uVal) {
  const item = flatPortalsList[portalIdx];
  if (!item) return;
  const idxEl = document.getElementById("hud-portal-idx");
  const titleEl = document.getElementById("hud-portal-title");
  const zEl = document.getElementById("hud-z-coord");

  if (idxEl) idxEl.textContent = `PORTAL ${String(portalIdx + 1).padStart(2, "0")}/25`;
  if (titleEl) titleEl.textContent = `${item.envName.split("(")[0].trim()} · ${item.video.title}`;
  if (zEl) zEl.textContent = `SPLINE: ${Math.round(uVal * 100)}%`;

  document.querySelectorAll(".portal-node").forEach((n) => {
    n.classList.toggle("active-portal", Number(n.getAttribute("data-global-portal")) === portalIdx);
  });
}

// ============================================================================
// 4. ENTRENADOR DE MISIÓN DE ASTRONAUTA JUNIOR (7–12 AÑOS · 30 SOLES)
// ============================================================================
function renderKidGlossaryStrip() {
  const strip = document.getElementById("kid-glossary-strip");
  if (!strip || !glossary?.terms) return;
  strip.innerHTML =
    `<span style="font-family:var(--font-mono); font-size:0.58rem; color:#93c5fd; font-weight:600;">GLOSARIO EN CONTEXTO (7–12 AÑOS):</span>` +
    glossary.terms
      .map(
        (t) => `
        <span class="btn" style="padding:0.18rem 0.5rem; font-size:0.64rem;" title="${esc(t.es.text)}">
          <strong>${esc(t.es.term)}:</strong> <span style="color:var(--text-secondary); font-weight:400;">${esc(t.es.text)}</span>
        </span>
      `,
      )
      .join("");
}

function startNewGame() {
  if (!world || !balance || !cardsData) return;
  const siteId = document.getElementById("select-site")?.value || "mars";
  const scenarioId = document.getElementById("select-scenario")?.value || "gannon-2024-05";

  currentMission = createMission({
    world,
    balance,
    cardsData,
    siteId,
    scenarioId,
    seed: Date.now() & 0xffff,
  });

  selectedCardId = null;
  selectedPowerMode = "normal";
  selectedUseShelter = false;
  syncOutpost3DCallback?.(currentMission.state);
  renderGameUI();
}

function renderGameUI() {
  if (!currentMission) return;
  const { state } = currentMission;
  const ctx = getSolContext(currentMission);

  const timelineEl = document.getElementById("sol-timeline");
  if (timelineEl) {
    const cells = [];
    for (let s = 0; s < state.totalSols; s++) {
      const evs = state.scheduled.filter(
        (e) => e.hitsSite && ((e.arrivalSol != null && e.arrivalSol === s) || (e.arrivalSol == null && e.sol === s)),
      );
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
  const delayStr = ctx.commDelaySec < 10 ? `${ctx.commDelaySec.toFixed(1)}s` : `${Math.round(ctx.commDelaySec / 60)} min`;

  statsEl.innerHTML = `
    <div class="stat-box">
      <div class="stat-label"><span>SOL DE MISIÓN</span><span>DELAY ${esc(delayStr)}</span></div>
      <div class="stat-value">${Math.min(state.totalSols, state.sol + (state.ended ? 0 : 1))}/${state.totalSols}</div>
      <div class="progress-track"><div class="progress-fill" style="width:${(state.sol / state.totalSols) * 100}%; background:var(--cyan-halo);"></div></div>
    </div>
    <div class="stat-box">
      <div class="stat-label"><span>1. ENERGÍA</span><span>MÁX 100</span></div>
      <div class="stat-value" style="color:#fde047;">${state.power}</div>
      <div class="progress-track"><div class="progress-fill" style="width:${state.power}%; background:#eab308;"></div></div>
    </div>
    <div class="stat-box">
      <div class="stat-label"><span>2. AIRE Y VIDA</span><span>MÁX 100</span></div>
      <div class="stat-value" style="color:#38bdf8;">${state.air}</div>
      <div class="progress-track"><div class="progress-fill" style="width:${state.air}%; background:#0ea5e9;"></div></div>
    </div>
    <div class="stat-box">
      <div class="stat-label"><span>3. BLINDAJE</span><span>MÁX 5</span></div>
      <div class="stat-value" style="color:#c084fc;">Nv ${state.shield}</div>
      <div class="progress-track"><div class="progress-fill" style="width:${(state.shield / 5) * 100}%; background:#a855f7;"></div></div>
    </div>
    <div class="stat-box">
      <div class="stat-label"><span>DOSIS RADLAB</span><span>LÍM 100</span></div>
      <div class="stat-value" style="color:${state.dose > 60 ? "#f43f5e" : "#10b981"};">${state.dose.toFixed(1)}</div>
      <div class="progress-track"><div class="progress-fill" style="width:${Math.min(100, state.dose)}%; background:${state.dose > 60 ? "#f43f5e" : "#10b981"};"></div></div>
    </div>
    <div class="stat-box">
      <div class="stat-label"><span>CIENCIA OSDR</span><span>${state.profile.doseMultiplierVsIss}× ISS</span></div>
      <div class="stat-value" style="color:#6ee7b7;">${state.science}</div>
      <div class="progress-track"><div class="progress-fill" style="width:${Math.min(100, state.science * 4)}%; background:#10b981;"></div></div>
    </div>
  `;

  const alertsEl = document.getElementById("game-alerts-area");
  const banners = [];
  if (ctx.activeEvents.length > 0 && !state.ended) {
    banners.push(`
      <div class="alert-banner">
        <strong>ALERTA TORMENTA SOLAR REAL (NASA DONKI) HOY:</strong>
        ${ctx.activeEvents.map((e) => `${esc(e.type)} (${esc(e.label)} · amenaza ${e.threat})`).join(" · ")}
        — <em>Tu blindaje Nv ${state.shield} absorbe un ${Math.round((1 - 1 / (1 + 0.6 * state.shield)) * 100)}% de la radiación.</em>
      </div>
    `);
  }
  if (ctx.warnings.length > 0 && !state.ended) {
    banners.push(`
      <div class="warn-banner">
        <strong>SATÉLITE DONKI DETECTA CME EN CAMINO:</strong> Impacto en Sol ${ctx.warnings[0].arrivalSol + 1} (${ctx.warnings[0].warningSols} soles de preaviso).
      </div>
    `);
  }
  alertsEl.innerHTML = banners.join("");

  const decisionEl = document.getElementById("game-decision-area");
  const reportEl = document.getElementById("game-report-area");

  if (state.ended) {
    decisionEl.style.display = "none";
    reportEl.style.display = "block";
    const won = state.outcome === "victory";
    reportEl.innerHTML = `
      <div style="background: rgba(11,61,145,0.22); border: 1px solid var(--cyan-halo); border-radius: 12px; padding: 1.05rem;">
        <h3 style="font-family: var(--font-display); font-size: 1.15rem;">
          ${won ? `Misión de 30 Soles Superada (${state.stars}/3 Estrellas)` : "Misión Interrumpida: Analicemos las decisiones"}
        </h3>
        <p style="font-size: 0.8rem; color: var(--text-secondary); margin: 0.35rem 0 0.7rem;">
          Dosis acumulada: <strong>${state.dose.toFixed(1)}</strong> · Instrumento real NASA RadLab (${esc(state.profile.measuredAt.instrumentId)}): <strong>${state.profile.absorbedDoseRate_uGyPerH.typical} µGy/h</strong> (${state.profile.doseMultiplierVsIss}× ISS).
          Módulos 3D construidos: <strong>${state.installed.length}</strong> · Estudios NASA OSDR desbloqueados: <strong>${state.factsUnlocked.length}</strong>.
        </p>
        <button id="btn-play-again" class="btn btn-halo">JUGAR OTRA ESTRATEGIA</button>
      </div>
    `;
    document.getElementById("btn-play-again")?.addEventListener("click", startNewGame);
    return;
  }

  decisionEl.style.display = "grid";
  reportEl.style.display = "none";

  const cardsHtml = state.offeredCards
    .map((c) => {
      const cost = c.immediateCost?.power ?? 0;
      const canAfford = state.power >= cost;
      const isSel = selectedCardId === c.id;
      const count = state.installed.filter((x) => x.id === c.id).length;
      const benefitText = c.benefit?.perSol?.power
        ? `+${c.benefit.perSol.power} Energía/sol`
        : c.benefit?.perSol?.air
          ? `+${c.benefit.perSol.air} Aire/sol`
          : c.benefit?.shield
            ? `+${c.benefit.shield} Blindaje`
            : c.benefit?.unlocksShelter
              ? `Desbloquea Refugio`
              : `Señal clara`;

      return `
        <div class="game-card ${isSel ? "selected" : ""} ${!canAfford ? "disabled" : ""}" data-card-id="${esc(c.id)}">
          <div>
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <strong style="font-size:0.8rem;">${esc(c.name.es)}</strong>
              <span class="card-badge">${count}/${c.stackLimit}</span>
            </div>
            <div class="card-cost-list">
              <div class="cost-good">+ Beneficio: ${esc(benefitText)}</div>
              <div class="cost-now">- Costo hoy: -${cost} Energía</div>
              <div class="cost-deferred">! Sol +${c.deferredCost?.afterSols ?? 1}: ${esc(c.deferredCost?.note?.es ?? "")}</div>
            </div>
          </div>
          <div class="card-teaches">${esc(c.teaches?.es ?? "")}</div>
        </div>
      `;
    })
    .join("");

  const lastLog = state.history.at(-1);
  decisionEl.innerHTML = `
    <div>
      <div class="cards-row">${cardsHtml}</div>
      <div style="display:flex; flex-wrap:wrap; gap:0.45rem; align-items:center; justify-content:space-between; margin-top:0.65rem;">
        <div style="display:flex; gap:0.3rem; flex-wrap:wrap;">
          <button class="btn mode-select-btn ${selectedPowerMode === "save" ? "btn-halo" : ""}" data-mode="save">AHORRO (+4 ENERGÍA)</button>
          <button class="btn mode-select-btn ${selectedPowerMode === "normal" ? "btn-halo" : ""}" data-mode="normal">NORMAL (+1 CIENCIA)</button>
          <button class="btn mode-select-btn ${selectedPowerMode === "science" ? "btn-halo" : ""}" data-mode="science">CIENCIA (+3 CIENCIA)</button>
        </div>
        <div style="display:flex; gap:0.4rem; flex-wrap:wrap;">
          ${
            state.shelterUnlocked
              ? `<button id="btn-toggle-shelter" class="btn ${selectedUseShelter ? "btn-halo" : ""}">
                   ${selectedUseShelter ? "REFUGIO: ACTIVO" : "ACTIVAR REFUGIO"}
                 </button>`
              : ""
          }
          <button id="btn-advance-sol" class="btn btn-halo">AVANZAR AL SOL ${state.sol + 1} ➔</button>
          <button id="btn-fast-sim" class="btn" title="Avanzar 5 soles automáticamente para el pitch">+5 SOLES (DEMO PITCH)</button>
        </div>
      </div>
    </div>

    <div style="background:rgba(255,255,255,0.025); border:1px solid var(--glass-border); border-radius:10px; padding:0.75rem; font-size:0.72rem;">
      <div style="font-family:var(--font-mono); font-size:0.58rem; color:#93c5fd; margin-bottom:0.3rem;">
        OUTPOST 3D: HDU + PERSEVERANCE + INGENUITY (${state.installed.length} MÓDULOS)
      </div>
      ${
        lastLog
          ? `<div><strong>Sol ${lastLog.sol}:</strong> Energía ${lastLog.power} · Aire ${lastLog.air} · Dosis ${lastLog.dose}<br><span style="color:var(--text-dim);">${lastLog.notes.map(esc).join(" · ") || "Operación nominal."}</span></div>`
          : `<div style="color:var(--text-dim);">Cada carta instala módulos 3D junto al hábitat NASA HDU, el rover Perseverance y el helicóptero Ingenuity en el cráter.</div>`
      }
      ${
        state.factsUnlocked.length > 0
          ? `<div style="margin-top:0.45rem; padding-top:0.4rem; border-top:1px solid rgba(255,255,255,0.08);">
               <span style="color:#6ee7b7; font-family:var(--font-mono); font-size:0.58rem;">ESTUDIO REAL NASA OSDR:</span><br>
               <a href="${esc(state.factsUnlocked.at(-1).url)}" target="_blank" rel="noopener" style="color:var(--cyan-halo); font-weight:600;">
                 ${esc(state.factsUnlocked.at(-1).accession)}: ${esc(state.factsUnlocked.at(-1).title)}
               </a>
             </div>`
          : ""
      }
    </div>
  `;

  decisionEl.querySelectorAll(".game-card").forEach((el) => {
    el.addEventListener("click", () => {
      if (el.classList.contains("disabled")) return;
      const cid = el.getAttribute("data-card-id");
      selectedCardId = selectedCardId === cid ? null : cid;
      renderGameUI();
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
    syncOutpost3DCallback?.(currentMission.state);
    renderGameUI();
  });

  document.getElementById("btn-fast-sim")?.addEventListener("click", () => {
    for (let i = 0; i < 5 && !currentMission.state.ended; i++) {
      const c = getSolContext(currentMission);
      const autoCard = currentMission.state.power >= 25 ? currentMission.state.offeredCards[0]?.id : null;
      stepSol(currentMission, {
        cardId: autoCard,
        powerMode: currentMission.state.power < 35 ? "save" : "normal",
        useShelter: c.activeEvents.some((e) => e.threat >= 0.6),
      });
    }
    selectedCardId = null;
    selectedUseShelter = false;
    syncOutpost3DCallback?.(currentMission.state);
    renderGameUI();
  });
}

// ============================================================================
// 5. MODALES DE AUDITORÍA (FLOW 1050C + 17 GLB MCP + CHALLENGE)
// ============================================================================
function renderFlowStudioModal() {
  if (!flowPlan) return;
  const filterEnv = document.getElementById("filter-flow-env")?.value || "all";
  const summaryEl = document.getElementById("flow-budget-summary");
  const container = document.getElementById("flow-cards-container");
  if (!summaryEl || !container) return;

  const b = flowPlan.budget;
  summaryEl.textContent = `${b.totalVideos} Portales · ${b.usedCredits}/${b.maxCredits} créditos (Reserva: ${b.remainingCredits}c)`;

  const items = [];
  for (const env of flowPlan.environments) {
    if (filterEnv !== "all" && env.environmentId !== filterEnv) continue;
    for (const v of env.videos) items.push({ envName: env.name, ...v });
  }

  container.innerHTML = items
    .map(
      (v) => `
      <div class="flow-card">
        <img class="flow-card-thumb" src="${esc(proxyImg(v.referenceImageUrl))}" alt="${esc(v.title)}" loading="lazy">
        <div class="flow-card-body">
          <div style="display:flex; justify-content:space-between; font-family:var(--font-mono); font-size:0.58rem; color:var(--cyan-halo);">
            <span>${esc(v.id.toUpperCase())}</span>
            <span>${v.credits} CR</span>
          </div>
          <strong style="font-size:0.78rem;">${esc(v.title)}</strong>
          <div style="color:var(--text-dim); font-size:0.65rem; line-height:1.3;">
            ${esc(v.prompt?.slice(0, 105))}…
          </div>
        </div>
      </div>
    `,
    )
    .join("");
}

function renderProvenanceModal() {
  const body = document.getElementById("provenance-modal-body");
  if (!body || !world?.manifest) return;

  const nasa3dModels = [
    { name: "Saturn V Rocket (Cohete Principal)", file: "saturn_v_rocket.glb", roblox: "SM_Saturn_V_Rocket_LOD0.glb", tris: "34,814", stage: "Vuelo Orbital Continuo + Mach Plume" },
    { name: "Mobile Launcher Pad 39B", file: "mobile_launcher.glb", roblox: "SM_Mobile_Launcher_LOD0.glb", tris: "19,296", stage: "01 Cabo Cañaveral (Tierra)" },
    { name: "Ares I Crew Launch Vehicle", file: "ares_rocket.glb", roblox: "SM_Ares_Rocket_LOD0.glb", tris: "4,664", stage: "01 Limbo Oriental Tierra" },
    { name: "Space Shuttle Orbiter", file: "space_shuttle.glb", roblox: "SM_Space_Shuttle_LOD0.glb", tris: "212,970", stage: "02 Órbita Ecuatorial Tierra" },
    { name: "CSA Canadarm Robotic Arm", file: "canadarm_csa.glb", roblox: "SM_Canadarm_CSA_LOD0.glb", tris: "1,080", stage: "02 Órbita Baja LEO" },
    { name: "ISS International Space Station (Detailed)", file: "iss_detailed.glb", roblox: "SM_ISS_Detailed_LOD0.glb", tris: "174,440", stage: "02 Ápice Orbital Tierra (408 km)" },
    { name: "ISS Modular Truss Array", file: "iss_station.glb", roblox: "SM_ISS_Station_LOD0.glb", tris: "6,642", stage: "02 Órbita Baja LEO" },
    { name: "Hubble Space Telescope", file: "hubble_telescope.glb", roblox: "SM_Hubble_Telescope_LOD0.glb", tris: "7,672", stage: "02 Limbo Occidental Tierra" },
    { name: "James Webb Space Telescope (JWST)", file: "jwst_telescope.glb", roblox: "SM_JWST_Telescope_LOD0.glb", tris: "99,239", stage: "03 Punto Lagrange L2" },
    { name: "Asteroid 1999 RQ36 Bennu", file: "asteroid_bennu.glb", roblox: "SM_Asteroid_Bennu_LOD0.glb", tris: "18,240", stage: "03 Cinturón de Asteroides" },
    { name: "Voyager Interplanetary Probe", file: "voyager_probe.glb", roblox: "SM_Voyager_Probe_LOD0.glb", tris: "29,911", stage: "03 Espacio Interplanetario" },
    { name: "Apollo / Artemis Lunar Module", file: "apollo_lander.glb", roblox: "SM_Apollo_Lander_LOD0.glb", tris: "97,588", stage: "04 Aproximación Cislunar" },
    { name: "Lunar Reconnaissance Orbiter (LRO)", file: "lro_orbiter.glb", roblox: "SM_LRO_Orbiter_LOD0.glb", tris: "76,349", stage: "04 Bordeando la Luna 3D" },
    { name: "Mars Global Surveyor (MGS MOLA)", file: "mars_mgs_orbiter.glb", roblox: "SM_Mars_MGS_Orbiter_LOD0.glb", tris: "19,314", stage: "05 Bordeando Marte 3D" },
    { name: "NASA Habitat Demonstration Unit (HDU)", file: "nasa_habitat_hdu.glb", roblox: "SM_NASA_Habitat_HDU_LOD0.glb", tris: "2,264", stage: "06 Base Cráter Jezero" },
    { name: "Mars 2020 Perseverance Rover", file: "perseverance_rover.glb", roblox: "SM_Perseverance_Rover_LOD0.glb", tris: "199,521", stage: "06 Exploración Superficie" },
    { name: "Ingenuity Mars Helicopter", file: "ingenuity_mars.glb", roblox: "SM_Ingenuity_Mars_LOD0.glb", tris: "9,124", stage: "06 Vuelo Autónomo Outpost" },
  ];

  const modelsHtml = nasa3dModels
    .map(
      (m) => `
      <div style="background:rgba(11,61,145,0.2); border:1px solid rgba(56,189,248,0.3); border-radius:10px; padding:0.65rem;">
        <div style="font-family:var(--font-mono); font-size:0.56rem; color:#93c5fd;">${esc(m.stage)} · ${esc(m.tris)} TRIS</div>
        <strong style="font-size:0.78rem;">${esc(m.name)}</strong>
        <div style="font-family:var(--font-mono); font-size:0.6rem; color:var(--text-secondary); margin-top:0.2rem;">
          WebGL: <code>/public/assets/models/${esc(m.file)}</code><br>
          MCP/Roblox: <code>${esc(m.roblox)}</code>
        </div>
      </div>
    `,
    )
    .join("");

  const sourcesHtml = (world.manifest.sources || [])
    .map(
      (s) => `
      <div style="background:rgba(255,255,255,0.03); border:1px solid var(--glass-border); border-radius:10px; padding:0.75rem;">
        <div style="font-family:var(--font-mono); font-size:0.58rem; color:#6ee7b7;">API OFICIAL NASA / CSA</div>
        <strong style="font-size:0.82rem;">${esc(s.name)}</strong>
        <p style="font-size:0.7rem; color:var(--text-secondary); margin:0.25rem 0 0.45rem;">${esc(s.gameRole)}</p>
        <a href="${esc(s.url)}" target="_blank" rel="noopener" style="font-family:var(--font-mono); font-size:0.62rem; color:var(--cyan-halo);">
          ${esc(s.url)} ↗
        </a>
      </div>
    `,
    )
    .join("");

  body.innerHTML = `
    <div style="margin-bottom:0.5rem; font-family:var(--font-mono); font-size:0.66rem; color:#93c5fd;">
      17 MODELOS 3D OFICIALES DE NASA DESCOMPRIMIDOS E INTEGRADOS VÍA BLENDER MCP BRIDGE (PORT 9877)
    </div>
    <div style="display:grid; grid-template-columns:repeat(auto-fill, minmax(240px, 1fr)); gap:0.6rem; margin-bottom:1.2rem;">
      ${modelsHtml}
    </div>
    <div style="margin-bottom:0.5rem; font-family:var(--font-mono); font-size:0.66rem; color:#6ee7b7;">
      8 PORTALES Y APIS CIENTÍFICAS EN TIEMPO REAL / SNAPSHOT
    </div>
    <div style="display:grid; grid-template-columns:repeat(auto-fill, minmax(260px, 1fr)); gap:0.65rem;">
      ${sourcesHtml}
    </div>
    <p style="margin-top:0.9rem; font-family:var(--font-mono); font-size:0.64rem; color:var(--text-dim);">
      ${esc(world.manifest.disclaimer)}
    </p>
  `;
}

function renderChallengeModal() {
  const body = document.getElementById("challenge-modal-body");
  if (!body) return;
  body.innerHTML = `
    <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(260px, 1fr)); gap:0.75rem; font-size:0.76rem; line-height:1.45;">
      <div style="background:rgba(255,255,255,0.03); border:1px solid var(--glass-border); border-radius:10px; padding:0.85rem;">
        <div style="font-family:var(--font-mono); font-size:0.6rem; color:#93c5fd;">1. RECORRIDO ORBITAL 3D + VIEWPORT VECTORIAL BLENDER</div>
        <strong style="font-size:0.88rem; display:block; margin:0.2rem 0;">El Cohete bordea el Planeta Tierra y viaja por el Sistema Solar</strong>
        <p style="color:var(--text-secondary);">
          La trayectoria usa una curva spline 3D (<code>THREE.CatmullRomCurve3</code>) que despega de Cabo Cañaveral, bordea físicamente la esfera de la Tierra en órbita LEO y viaja hacia Bennu, la Luna y Marte dentro de un espacio vectorial interactivo estilo Blender.
        </p>
      </div>
      <div style="background:rgba(255,255,255,0.03); border:1px solid var(--glass-border); border-radius:10px; padding:0.85rem;">
        <div style="font-family:var(--font-mono); font-size:0.6rem; color:#fde047;">2. COMPROMISOS COMPUESTOS (TRADE-OFFS)</div>
        <strong style="font-size:0.88rem; display:block; margin:0.2rem 0;">Costo Inmediato Hoy vs. Costo Diferido Mañana</strong>
        <p style="color:var(--text-secondary);">
          Cada carta exige un sacrificio real: el <em>Invernadero CSA</em> produce +6 de aire hoy pero consume -4 de energía por sol tras 3 soles; los <em>Paneles Solares</em> sufren acumulación de polvo marciano tras 8 soles.
        </p>
      </div>
      <div style="background:rgba(255,255,255,0.03); border:1px solid var(--glass-border); border-radius:10px; padding:0.85rem;">
        <div style="font-family:var(--font-mono); font-size:0.6rem; color:#6ee7b7;">3. ACCESIBILIDAD INFANTIL (7–12 AÑOS)</div>
        <strong style="font-size:0.88rem; display:block; margin:0.2rem 0;">3 Recursos Centrales + Glosario en Contexto</strong>
        <p style="color:var(--text-secondary);">
          Interfaz enfocada en 3 variables claras (<strong>Energía, Aire y Blindaje</strong>) con píldoras de glosario para niños (<em>Sol, CME, Regolito, µGy/h</em>) e instalación visual de módulos 3D junto a Perseverance e Ingenuity.
        </p>
      </div>
    </div>
  `;
}

// ============================================================================
// 6. EVENTOS DE INTERFAZ Y NAVEGACIÓN POR TECLADO (← / →)
// ============================================================================
function bindEvents() {
  document.getElementById("btn-data-mode")?.addEventListener("click", async () => {
    useLiveMode = !useLiveMode;
    await loadAllData();
    startNewGame();
  });

  document.getElementById("btn-toggle-reveal")?.addEventListener("click", (e) => {
    revealAllMode = !revealAllMode;
    e.currentTarget.textContent = revealAllMode ? "PORTAL: 100% HD" : "PORTAL: VIVO";
  });

  document.getElementById("btn-toggle-blender-grid")?.addEventListener("click", (e) => {
    const visible = toggleBlenderGridCallback?.();
    e.currentTarget.textContent = visible ? "GRID 3D: ON" : "GRID 3D: OFF";
  });

  document.querySelectorAll("[data-cam-preset]").forEach((btn) => {
    btn.addEventListener("click", () => {
      setCameraPresetCallback?.(btn.getAttribute("data-cam-preset"));
    });
  });

  document.getElementById("btn-auto-flight")?.addEventListener("click", (e) => {
    autoFlightActive = !autoFlightActive;
    if (autoFlightActive) {
      const maxScroll = Math.max(1, document.body.scrollHeight - window.innerHeight);
      const currentRatio = window.scrollY / maxScroll;
      const startOffsetMs = currentRatio > 0.96 ? 0 : currentRatio * 180 * 1000;
      if (currentRatio > 0.96) window.scrollTo({ top: 0, behavior: "instant" });
      pitchStartTime = performance.now() - startOffsetMs;
    }
    e.currentTarget.classList.toggle("active", autoFlightActive);
    e.currentTarget.textContent = autoFlightActive ? "⏸ PAUSAR PITCH" : "▶ INICIAR PITCH 3 MIN";
  });

  document.querySelectorAll(".room-pill").forEach((btn) => {
    btn.addEventListener("click", () => {
      autoFlightActive = false;
      const autoBtn = document.getElementById("btn-auto-flight");
      if (autoBtn) {
        autoBtn.classList.remove("active");
        autoBtn.textContent = "▶ INICIAR PITCH 3 MIN";
      }
      const idx = Number(btn.getAttribute("data-room"));
      jumpToSlide(idx);
    });
  });

  document.getElementById("btn-prev-slide")?.addEventListener("click", () => {
    const active = Number(document.querySelector(".room-pill.active")?.getAttribute("data-room") || 0);
    jumpToSlide(Math.max(0, active - 1));
  });

  document.getElementById("btn-next-slide")?.addEventListener("click", () => {
    const active = Number(document.querySelector(".room-pill.active")?.getAttribute("data-room") || 0);
    jumpToSlide(Math.min(5, active + 1));
  });

  window.addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT" || e.target.tagName === "SELECT") return;
    if (e.key === "ArrowRight") {
      const active = Number(document.querySelector(".room-pill.active")?.getAttribute("data-room") || 0);
      jumpToSlide(Math.min(5, active + 1));
    } else if (e.key === "ArrowLeft") {
      const active = Number(document.querySelector(".room-pill.active")?.getAttribute("data-room") || 0);
      jumpToSlide(Math.max(0, active - 1));
    }
  });

  document.getElementById("select-site")?.addEventListener("change", startNewGame);
  document.getElementById("select-scenario")?.addEventListener("change", startNewGame);
  document.getElementById("btn-new-run")?.addEventListener("click", startNewGame);

  const flowModal = document.getElementById("flow-modal");
  document.getElementById("btn-open-flow")?.addEventListener("click", () => flowModal?.classList.add("open"));
  document.getElementById("btn-close-flow")?.addEventListener("click", () => flowModal?.classList.remove("open"));

  const provModal = document.getElementById("provenance-modal");
  document.getElementById("btn-open-provenance")?.addEventListener("click", () => provModal?.classList.add("open"));
  document.getElementById("btn-close-provenance")?.addEventListener("click", () => provModal?.classList.remove("open"));

  const challengeModal = document.getElementById("challenge-modal");
  document.getElementById("btn-open-challenge")?.addEventListener("click", () => challengeModal?.classList.add("open"));
  document.getElementById("btn-close-challenge")?.addEventListener("click", () => challengeModal?.classList.remove("open"));

  document.getElementById("btn-recalc-flow")?.addEventListener("click", async () => {
    const credits = Number(document.getElementById("input-flow-credits")?.value) || 1050;
    const res = await fetchApiJson(`/api/flow-plan?credits=${credits}${useLiveMode ? "&live=1" : ""}`);
    flowPlan = res.data;
    renderFlowStudioModal();
  });

  document.getElementById("filter-flow-env")?.addEventListener("change", renderFlowStudioModal);
}

// ============================================================================
// BOOTSTRAP
// ============================================================================
(async function init() {
  bindEvents();
  await loadAllData();
  startNewGame();
  initThreeSpaceEngine();
})();
