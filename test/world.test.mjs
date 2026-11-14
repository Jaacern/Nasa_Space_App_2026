// La capa de datos del juego sobre los snapshots reales (requiere data/curated/; ver npm run ingest).
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { loadWorldState, getScenario, scheduleEvents, siteProfile, commDelaySec, pickFact, makeRng, attributionLines } from "../src/data/worldState.mjs";

const dir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../data/curated");
const state = await loadWorldState(async (n) => JSON.parse(await readFile(path.join(dir, n), "utf8")));

test("calendario: eventos reales repartidos en 30 soles", () => {
  const sc = getScenario(state, "gannon-2024-05");
  const sched = scheduleEvents(sc, "mars", { sols: 30, minThreat: 0.3 });
  assert.ok(sched.length > 10);
  assert.ok(sched.every((e) => e.sol >= 0 && e.sol <= 29 && typeof e.hitsSite === "boolean"));
  assert.deepEqual(sched.map((e) => e.sol), [...sched.map((e) => e.sol)].sort((a, b) => a - b), "ordenado por sol");
  assert.throws(() => getScenario(state, "no-existe"));
});

test("perfil del sitio: dosis real y retraso de radio", () => {
  const mars = siteProfile(state, "mars");
  const moon = siteProfile(state, "moon");
  assert.ok(mars.doseMultiplierVsIss > 1 && moon.doseMultiplierVsIss > 1, "en el espacio profundo la dosis supera a la de la ISS");
  assert.ok(commDelaySec("moon", 5) < 2);
  const d = [0, 100, 200, 300, 400, 500, 600, 700].map((s) => commDelaySec("mars", s));
  assert.ok(Math.min(...d) >= 180 && Math.max(...d) <= 1340, "entre ~3 y ~22 minutos");
});

test("datos curiosos: solo se muestra texto infantil revisado", () => {
  const fact = pickFact(state, "bone", makeRng(1));
  assert.ok(fact.accession.startsWith("OSD-"));
  assert.equal(fact.text, null, "sin revisión humana no hay texto para niños");
  assert.deepEqual(pickFact(state, "bone", makeRng(7)), pickFact(state, "bone", makeRng(7)), "misma semilla, mismo resultado");
});

test("atribución visible y honesta", () => {
  const text = attributionLines(state).join("\n");
  assert.match(text, /no en vivo/);
  assert.match(text, /no está patrocinado/);
});
