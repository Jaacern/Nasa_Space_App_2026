#!/usr/bin/env node
/**
 * Descarga las fuentes, íconos e imágenes de NASA del kit ORBITAL UI.
 *
 *   node ui-ux/scripts/download-assets.mjs
 *
 * - Tipografías: Google Fonts (SIL Open Font License), subset latin + latin-ext.
 * - Íconos: Lucide Static (ISC).
 * - Imágenes: NASA Images API (dominio público, con atribución).
 * - Escribe ui-ux/assets/img/credits.json y ui-ux/css/fonts.css.
 *
 * Requiere red. Los archivos descargados se versionan en el repositorio para
 * que la maqueta funcione sin conexión (misma filosofía que data/curated/).
 */
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const KIT = path.resolve(HERE, "..");
const FONTS_DIR = path.join(KIT, "assets", "fonts");
const ICONS_DIR = path.join(KIT, "assets", "icons");
const IMG_DIR = path.join(KIT, "assets", "img");
const UA =
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";

const FONT_FAMILIES = [
  // Sistema de diseño web de NASA (USWDS) + HDS
  { family: "Public Sans", slug: "public-sans", query: "Public+Sans:ital,wght@0,400;0,600;0,700;1,400" },
  { family: "Inter", slug: "inter", query: "Inter:wght@400;600;800" },
  { family: "DM Mono", slug: "dm-mono", query: "DM+Mono:wght@400;500" },
  // Telemetría y datos del proyecto
  { family: "IBM Plex Mono", slug: "ibm-plex-mono", query: "IBM+Plex+Mono:wght@400;600" },
  // Display aeroespacial / póster de misión
  { family: "Michroma", slug: "michroma", query: "Michroma" },
  { family: "Chakra Petch", slug: "chakra-petch", query: "Chakra+Petch:wght@400;600;700" },
  { family: "Bungee", slug: "bungee", query: "Bungee" },
  // Contraste editorial
  { family: "Instrument Serif", slug: "instrument-serif", query: "Instrument+Serif:ital@0;1" },
];

// Nombres de archivo Lucide (ISC). Si alguno no existe, se omite sin romper.
const ICONS = [
  "rocket", "satellite", "orbit", "telescope", "moon-star", "sun", "zap",
  "shield-check", "shield", "wind", "gauge", "compass", "star", "sparkles",
  "globe", "target", "crosshair", "radar", "signal", "timer", "flame",
  "cloud-sun", "waves", "cpu", "database", "scan-line", "maximize",
  "circle-dot", "hexagon", "triangle", "arrow-up-right", "chevron-right",
  "play", "pause", "rotate-ccw", "check", "x", "alert-triangle", "info",
  "download", "external-link", "menu", "search", "map-pin", "battery-charging",
  "thermometer", "droplet", "activity", "box", "settings", "radio", "antenna",
];

// Imágenes de NASA Images API. `size` = rendición preferida (se usa la primera disponible).
const NASA_IMAGES = [
  { id: "art002e009280b", slug: "earthrise-artemis", size: ["large", "orig", "medium"] },
  { id: "carina_nebula", slug: "carina-nebula", size: ["large", "medium"] },
  { id: "PIA24542", slug: "perseverance-selfie", size: ["large", "medium"] },
  { id: "SLS_MAF_20260401_ArtemisIILaunch_05", slug: "artemis-ii-launch", size: ["large", "medium"] },
  { id: "jsc2004e52772", slug: "apollo-17-panorama", size: ["large", "medium"] },
  { id: "jsc2026e020490", slug: "mission-control-2026", size: ["medium", "orig"] },
  { id: "PIA20332", slug: "mars-vista", size: ["large", "medium"] },
  { id: "PIA12110", slug: "hubble-deep-field", size: ["orig", "large", "medium"] },
];

const log = (...a) => console.log("·", ...a);

async function get(url, as = "text") {
  const res = await fetch(url, { headers: { "User-Agent": UA, Accept: "*/*" } });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${url}`);
  return as === "json" ? res.json() : as === "buffer" ? Buffer.from(await res.arrayBuffer()) : res.text();
}

async function downloadFonts() {
  await mkdir(FONTS_DIR, { recursive: true });
  let css = `/* ============================================================================
   ORBITAL UI · Tipografías descargadas de Google Fonts (SIL OFL 1.1)
   Generado por scripts/download-assets.mjs — no editar a mano.
   Subsets: latin + latin-ext (cubre español: á é í ó ú ü ñ ¿ ¡).
   ============================================================================ */\n\n`;

  for (const fam of FONT_FAMILIES) {
    const url = `https://fonts.googleapis.com/css2?family=${fam.query}&display=swap`;
    const raw = await get(url);
    const blocks = [...raw.matchAll(/\/\*\s*([a-z-]+)\s*\*\/\s*@font-face\s*\{([^}]+)\}/g)];
    let count = 0;
    for (const [, subset, body] of blocks) {
      if (!["latin", "latin-ext"].includes(subset)) continue;
      const style = /font-style:\s*([^;]+);/.exec(body)?.[1].trim() ?? "normal";
      const weight = /font-weight:\s*([^;]+);/.exec(body)?.[1].trim() ?? "400";
      const src = /url\((https:\/\/fonts\.gstatic\.com\/[^)]+\.woff2)\)/.exec(body)?.[1];
      const range = /unicode-range:\s*([^;]+);/.exec(body)?.[1].trim();
      if (!src) continue;
      const file = `${fam.slug}-${weight}${style === "italic" ? "-italic" : ""}-${subset}.woff2`;
      await writeFile(path.join(FONTS_DIR, file), await get(src, "buffer"));
      css += `@font-face {
  font-family: "${fam.family}";
  font-style: ${style};
  font-weight: ${weight};
  font-display: swap;
  src: url("../assets/fonts/${file}") format("woff2");
  unicode-range: ${range};
}\n\n`;
      count++;
    }
    log(`fuente ${fam.family}: ${count} archivos woff2`);
  }
  await writeFile(path.join(KIT, "css", "fonts.css"), css);
  log("escrito css/fonts.css");
}

async function downloadIcons() {
  await mkdir(ICONS_DIR, { recursive: true });
  let ok = 0;
  for (const name of ICONS) {
    try {
      const svg = await get(`https://unpkg.com/lucide-static@0.545.0/icons/${name}.svg`);
      await writeFile(path.join(ICONS_DIR, `${name}.svg`), svg);
      ok++;
    } catch {
      log(`  (sin ícono: ${name})`);
    }
  }
  log(`íconos Lucide: ${ok}/${ICONS.length}`);
}

async function downloadNasaImages() {
  await mkdir(IMG_DIR, { recursive: true });
  const credits = [];
  for (const item of NASA_IMAGES) {
    const asset = await get(`https://images-api.nasa.gov/asset/${item.id}`, "json");
    const hrefs = asset.collection.items.map((i) => i.href.replace("http://", "https://"));
    const href =
      item.size.map((s) => hrefs.find((h) => h.endsWith(`~${s}.jpg`))).find(Boolean) ??
      hrefs.find((h) => h.endsWith(".jpg"));
    if (!href) {
      log(`  (sin imagen: ${item.id})`);
      continue;
    }
    const buf = await get(href, "buffer");
    await writeFile(path.join(IMG_DIR, `${item.slug}.jpg`), buf);

    let meta = {};
    try {
      const s = await get(`https://images-api.nasa.gov/search?nasa_id=${encodeURIComponent(item.id)}`, "json");
      meta = s.collection.items?.[0]?.data?.[0] ?? {};
    } catch {}
    credits.push({
      nasaId: item.id,
      file: `assets/img/${item.slug}.jpg`,
      title: meta.title ?? item.id,
      description: (meta.description ?? "").slice(0, 400),
      center: meta.center ?? "NASA",
      dateCreated: meta.date_created ?? null,
      source: `https://images.nasa.gov/details/${item.id}`,
      assetUrl: href,
      credit: "NASA",
      license: "NASA Media Usage Guidelines — https://www.nasa.gov/nasa-brand-center/images-and-media/",
    });
    log(`imagen ${item.slug}: ${Math.round(buf.length / 1024)} KB`);
  }
  await writeFile(path.join(IMG_DIR, "credits.json"), JSON.stringify({ source: "NASA Images API", retrievedAt: new Date().toISOString(), images: credits }, null, 2));
  log("escrito assets/img/credits.json");
}

try {
  await downloadFonts();
  await downloadIcons();
  await downloadNasaImages();
  log("listo.");
} catch (e) {
  console.error("Error:", e.message);
  process.exitCode = 1;
}
