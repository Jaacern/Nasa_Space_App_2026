#!/usr/bin/env node
/**
 * Generador de prompts y calculadora Precio/Calidad para Google Flow (Veo 3.1).
 * Lee los snapshots reales de NASA en data/curated/ y el plan maestro en content/flow_video_plan.json.
 *
 * Uso:
 *   npm run flow:plan                         # Plan completo para 1050 créditos (25 videos: 5x5)
 *   node scripts/flow-prompts.mjs --credits=600   # Recalcula tiers para otro presupuesto
 *   node scripts/flow-prompts.mjs --env=marte     # Filtra por entorno (tierra|despegue|universo|luna|marte)
 */
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { enrichPlanWithSnapshots, optimizeFlowBudget } from "../src/data/flowPlanner.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const loadJson = async (rel) => JSON.parse(await readFile(path.join(ROOT, rel), "utf8").catch(() => "{}"));

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v = "true"] = a.replace(/^--/, "").split("=");
    return [k, v];
  }),
);

const credits = Number(args.credits ?? 1050);
const filterEnv = args.env ? String(args.env).toLowerCase() : null;

const rawPlan = await loadJson("content/flow_video_plan.json");
const snapshots = {
  roverPhotos: await loadJson("data/curated/rover_photos.json"),
  marsWeather: await loadJson("data/curated/mars_weather.json"),
  spaceWeather: await loadJson("data/curated/space_weather.json"),
  radiation: await loadJson("data/curated/radiation.json"),
};

const enriched = enrichPlanWithSnapshots(rawPlan, snapshots);
const result = optimizeFlowBudget(enriched, { credits });
const b = result.budget;

console.log("================================================================================");
console.log(" 🚀 GOOGLE FLOW (VEO 3.1) - OPTIMIZADOR PRECIO/CALIDAD + NASA API ASSETS");
console.log("================================================================================");
console.log(` Presupuesto disponible : ${b.availableCredits} créditos`);
console.log(` Gasto planificado (25v): ${b.plannedSpendCredits} créditos (${b.withinLimit ? "DENTRO DEL LÍMITE" : "EXCEDE LÍMITE"})`);
console.log(` Reserva de seguridad   : ${b.remainingReserveCredits} créditos (equivale a ${b.retryCapacity.extraFastRetries} reintentos en Fast o ${b.retryCapacity.extraLiteRetries} en Lite)`);
console.log("--------------------------------------------------------------------------------");
console.log(` Distribución óptima para los ${b.totalVideos} videos (5 entornos x 5 videos):`);
console.log(`   • Veo 3.1 Quality (100 cr) : ${String(b.tierBreakdown.quality_100cr.count).padStart(2)} videos = ${String(b.tierBreakdown.quality_100cr.credits).padStart(4)} cr  (Hero Shots principales)`);
console.log(`   • Veo 3.1 Fast    ( 20 cr) : ${String(b.tierBreakdown.fast_20cr.count).padStart(2)} videos = ${String(b.tierBreakdown.fast_20cr.credits).padStart(4)} cr  (Frames-to-Video con fotos NASA)`);
console.log(`   • Veo 3.1 Lite    ( 10 cr) : ${String(b.tierBreakdown.lite_10cr.count).padStart(2)} videos = ${String(b.tierBreakdown.lite_10cr.credits).padStart(4)} cr  (Loops ambientales / fondos 3D)`);
console.log("================================================================================\n");

for (const env of result.environments) {
  if (filterEnv && env.environmentId !== filterEnv) continue;
  const envCost = env.videos.reduce((s, v) => s + v.credits, 0);
  console.log(`### [${env.order}/5] ENTORNO: ${env.environmentName.toUpperCase()} (${env.scrollRange} Scroll | Subtotal: ${envCost} cr)`);
  console.log(`    Rol 3D Web: ${env.threeJsSetup}\n`);
  for (const v of env.videos) {
    console.log(`  🎬 ${v.id} — ${v.title}`);
    console.log(`     • Modelo / Costo : ${v.tierLabel} (${v.credits} créditos) | Modo: ${v.flowMode}`);
    console.log(`     • Fuente NASA    : ${v.nasaSource}${v.liveDataContext ? ` [${v.liveDataContext}]` : ""}`);
    if (v.referenceImageUrl) {
      console.log(`     • Frame Inicial  : ${v.referenceImageUrl}`);
    }
    console.log(`     • Cámara / Rol   : ${v.cameraMotion} -> ${v.webAssetRole}`);
    console.log(`     • Prompt (Flow)  : "${v.promptEn}"\n`);
  }
}
