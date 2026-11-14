// Prueba de la API local sin red: usa los snapshots de data/curated/ (requiere haber ejecutado npm run ingest).
import test from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../server/api.mjs";

let server;
let base;
test.before(async () => {
  server = createApp();
  await new Promise((r) => server.listen(0, "127.0.0.1", r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => server.close());

const get = async (p) => {
  const r = await fetch(base + p);
  return { status: r.status, mode: r.headers.get("x-data-mode"), cors: r.headers.get("access-control-allow-origin"), body: await r.json().catch(() => null) };
};

test("health no expone la clave", async () => {
  process.env.NASA_API_KEY = "TESTKEY12345";
  const r = await get("/api/health");
  assert.equal(r.status, 200);
  assert.equal(r.body.nasaKeyConfigured, true);
  assert.ok(!JSON.stringify(r.body).includes("TESTKEY12345"));
});

test("space-weather devuelve snapshot con modo y CORS", async () => {
  const r = await get("/api/space-weather");
  assert.equal(r.status, 200);
  assert.equal(r.mode, "snapshot");
  assert.equal(r.cors, "*");
  assert.ok(Array.isArray(r.body.events) && r.body.events.length > 0);
});

test("cada endpoint del catálogo responde con meta de procedencia", async () => {
  const { sources } = (await get("/api/catalog")).body;
  assert.ok(sources.length >= 8);
  for (const s of sources) {
    for (const ep of s.endpoints) {
      const r = await get(ep.replace(":id", "gannon-2024-05"));
      if (r.status === 503 && s.optional) continue; // fuente opcional sin snapshot todavía
      assert.equal(r.status, 200, `${s.id} ${ep}`);
      assert.ok(r.body.meta?.source && r.body.meta?.retrievedAt, `${s.id} ${ep}: falta meta.source/retrievedAt`);
    }
  }
});

test("escenarios: lista y detalle", async () => {
  const list = await get("/api/scenarios");
  assert.ok(list.body.scenarios.length >= 3);
  const one = await get("/api/scenarios/gannon-2024-05");
  assert.equal(one.status, 200);
  assert.ok(one.body.scenario.events.length > 0);
});

test("errores controlados", async () => {
  assert.equal((await get("/api/scenarios/no-existe")).status, 404);
  assert.equal((await get("/api/osdr?topic=nada")).status, 404);
  assert.equal((await get("/api/asteroids")).status, 404, "las fuentes irrelevantes no existen");
  assert.equal((await get("/api/no-existe")).status, 404);
});

test("no sirve archivos privados ni sube de carpeta", async () => {
  assert.equal((await get("/.env")).status, 404);
  assert.equal((await get("/package.json")).status, 404);
  assert.equal((await get("/scripts/ingest.mjs")).status, 404);
  assert.notEqual((await get("/src/../.env")).status, 200);
  assert.notEqual((await get("/src/%2e%2e/.env")).status, 200);
});

test("sirve la capa de datos al navegador", async () => {
  const r = await fetch(base + "/src/data/worldState.mjs");
  assert.equal(r.status, 200);
  assert.match(r.headers.get("content-type"), /javascript/);
});
