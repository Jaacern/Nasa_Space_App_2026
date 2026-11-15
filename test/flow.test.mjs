// Pruebas sin red para el planificador Precio/Calidad de Google Flow (Veo 3.1) y el endpoint /api/flow-plan
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { enrichPlanWithSnapshots, optimizeFlowBudget } from "../src/data/flowPlanner.mjs";
import { loadWorldState } from "../src/data/worldState.mjs";
import { createMission, getSolContext, stepSol } from "../src/sim/run.mjs";
import { createApp } from "../server/api.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const load = async (rel) => JSON.parse(await readFile(path.join(ROOT, rel), "utf8"));

test("Google Flow: 25 videos (5 entornos x 5 videos) dentro del límite de 1050 créditos", async () => {
  const plan = await load("content/flow_video_plan.json");
  const out = optimizeFlowBudget(plan, { credits: 1050 });
  assert.equal(out.budget.totalVideos, 25);
  assert.equal(out.environments.length, 5);
  for (const env of out.environments) {
    assert.equal(env.videos.length, 5, `${env.environmentId} debe tener exactamente 5 videos`);
  }
  assert.ok(out.budget.withinLimit, "el gasto debe estar dentro de los 1050 créditos");
  assert.ok(out.budget.plannedSpendCredits <= 1050);
  assert.ok(out.budget.remainingReserveCredits >= 150, "debe dejar margen de reserva para reintentos");
});

test("Google Flow: adapta el costo si el presupuesto baja (ej. 500 créditos)", async () => {
  const plan = await load("content/flow_video_plan.json");
  const out = optimizeFlowBudget(plan, { credits: 500 });
  assert.equal(out.budget.totalVideos, 25);
  assert.ok(out.budget.withinLimit);
  assert.ok(out.budget.plannedSpendCredits <= 500);
});

test("Google Flow: inyecta snapshots reales de Perseverance, Curiosity, InSight y DONKI", async () => {
  const plan = await load("content/flow_video_plan.json");
  const roverPhotos = await load("data/curated/rover_photos.json");
  const marsWeather = await load("data/curated/mars_weather.json");
  const spaceWeather = await load("data/curated/space_weather.json");
  const radiation = await load("data/curated/radiation.json");

  const enriched = enrichPlanWithSnapshots(plan, { roverPhotos, marsWeather, spaceWeather, radiation });
  const marsEnv = enriched.journeyFlow.find((e) => e.environmentId === "marte");
  const mars02 = marsEnv.videos.find((v) => v.id === "mars-02");
  const mars03 = marsEnv.videos.find((v) => v.id === "mars-03");

  assert.match(mars02.referenceImageUrl, /^https:\/\/mars\.nasa\.gov\//);
  assert.match(mars02.liveDataContext, /Perseverance/);
  assert.match(mars03.liveDataContext, /Curiosity/);
  assert.ok(enriched.masterPromptTemplate.itomArchitectureMapping.roomsMapping.length === 5);
});

test("Servidor API: /api/flow-plan responde con el plan optimizado", async () => {
  const server = createApp();
  await new Promise((r) => server.listen(0, "127.0.0.1", r));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    const res = await fetch(`${base}/api/flow-plan?credits=1050`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.budget.availableCredits, 1050);
    assert.equal(body.environments.length, 5);
    assert.equal(body.budget.totalVideos, 25);

    // Verifica que los 25 videos tengan referenceImageUrl HTTPS oficial de NASA
    for (const env of body.environments) {
      for (const v of env.videos) {
        assert.ok(v.referenceImageUrl, `Falta referenceImageUrl en ${v.id}`);
        assert.match(v.referenceImageUrl, /^https:\/\/(images-assets\.nasa\.gov|mars\.nasa\.gov|trek\.nasa\.gov)\//);
      }
    }

    // Verifica que /api/media-proxy rechace dominios ajenos a NASA
    const badProxy = await fetch(`${base}/api/media-proxy?url=${encodeURIComponent("https://evil.example.com/a.jpg")}`);
    assert.equal(badProxy.status, 400);
  } finally {
    server.close();
  }
});

test("Motor de partida Outpost Run (src/sim/run.mjs): simula 30 soles con cartas y refugio", async () => {
  const world = await loadWorldState((f) => load(`data/curated/${f}`));
  const balance = await load("content/balance.json");
  const cardsData = await load("content/cards.json");

  const mission = createMission({
    world,
    balance,
    cardsData,
    siteId: "mars",
    scenarioId: "gannon-2024-05",
    seed: 2026,
  });

  // Instalar Muro de regolito, Panel solar y Refugio de tormenta en los primeros soles
  stepSol(mission, { cardId: "regolith-wall", powerMode: "save" });
  stepSol(mission, { cardId: "solar-panel", powerMode: "normal" });
  stepSol(mission, { cardId: "storm-shelter", powerMode: "save" });

  assert.equal(mission.state.shield, 1);
  assert.equal(mission.state.shelterUnlocked, true);

  while (!mission.state.ended) {
    const ctx = getSolContext(mission);
    const hasMajorStorm = ctx.activeEvents.some((e) => e.threat >= 0.5);
    stepSol(mission, {
      cardId: mission.state.power > 45 ? mission.state.offeredCards[0]?.id : null,
      powerMode: mission.state.power < 35 ? "save" : "normal",
      useShelter: hasMajorStorm && mission.state.power >= 25,
    });
  }

  assert.ok(mission.state.sol <= 30);
  assert.ok(["victory", "air_depleted", "radiation_limit"].includes(mission.state.outcome));
  assert.ok(mission.state.history.length > 0);
});
