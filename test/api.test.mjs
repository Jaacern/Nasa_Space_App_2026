// Pruebas sin red: node --test test/   (o: npm test)
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { redact, cleanText, safeUrl, num, isoDate, validate, findSecretLeaks } from "../src/api/sanitize.mjs";
import { getApod, getMarsSurfaceWeather, getRoverPhotos, getSpaceWeatherLive, parseCsaPage } from "../src/api/sources.mjs";
import { sanitizeEvent } from "../src/api/normalize.mjs";

const dir = path.dirname(fileURLToPath(import.meta.url));
const fixture = async (n) => JSON.parse(await readFile(path.join(dir, "fixtures", n), "utf8"));
process.env.NASA_API_KEY = "TESTKEY12345";

test("redact oculta api_key y el valor real de NASA_API_KEY", () => {
  assert.equal(redact("https://x.gov/a?api_key=ABC123&b=1"), "https://x.gov/a?api_key=***&b=1");
  assert.ok(!redact("error con TESTKEY12345 dentro").includes("TESTKEY12345"));
});

test("cleanText quita HTML, controla longitud", () => {
  assert.equal(cleanText("<b>Hola</b>\n  mundo<script>x</script>"), "Hola mundo x");
  assert.ok(cleanText("a".repeat(500), 50).length <= 50);
});

test("safeUrl: https, host NASA, sin claves", () => {
  assert.equal(safeUrl("http://ssd.jpl.nasa.gov/x?api_key=ZZZ&a=1"), "https://ssd.jpl.nasa.gov/x?a=1");
  assert.equal(safeUrl("https://evil.example.com/x"), null);
  assert.equal(safeUrl("javascript:alert(1)"), null);
  assert.equal(safeUrl("https://nasa.gov.evil.com/x"), null);
});

test("num e isoDate rechazan valores inválidos", () => {
  assert.equal(num("abc"), null);
  assert.equal(num(null), null);
  assert.equal(num("7.2674", { digits: 2 }), 7.27);
  assert.equal(num(-5, { min: 0 }), null);
  assert.equal(isoDate("2026-02-30"), null);
  assert.equal(isoDate("2026-11-14"), "2026-11-14");
});

test("validate detecta contratos rotos", () => {
  assert.deepEqual(validate({ a: 1 }, { a: "number" }), []);
  assert.ok(validate({ a: "x" }, { a: "number" }).length === 1);
  assert.ok(validate({}, { a: "number?" }).length === 0);
});

test("fotos de Marte: datos reales guardados, una por cámara de paisaje, solo nasa.gov", async () => {
  const feeds = { mars2020: await fixture("rover_raw_mars2020.json"), msl: await fixture("rover_raw_msl.json") };
  const out = await getRoverPhotos({ fetchJson: async (u) => feeds[/category=(\w+)/.exec(u)[1]] });
  assert.ok(out.count >= 2);
  for (const p of out.photos) {
    assert.match(p.imageUrl, /^https:\/\/mars\.nasa\.gov\/.+\.jpe?g$/i);
    assert.match(p.camera, /NAV|MCZ|MAST|HAZ/i);
  }
  const keys = out.photos.map((p) => `${p.rover}/${p.camera}`);
  assert.equal(new Set(keys).size, keys.length, "una foto por cámara y rover");
  assert.deepEqual(findSecretLeaks(out), []);
});

test("fotos de Marte: respuesta hostil se sanea", async () => {
  const bad = (over) => ({ sol: 1, imageid: "X1", date_taken_utc: "2026-11-01T00:00:00", title: "<b>t</b>", camera: { instrument: "NAV_LEFT_B" }, image_files: { medium: "https://mars.nasa.gov/a.jpg" }, ...over });
  const raw = {
    images: [
      bad({ image_files: { medium: "https://evil.example.com/a.jpg" } }),
      bad({ camera: { instrument: "MCZ_LEFT" }, image_files: { medium: "http://mars.nasa.gov/b.jpg?api_key=TESTKEY12345" } }),
      bad({ camera: { instrument: "MAST_X" }, image_files: { medium: "https://mars.nasa.gov/c.png" } }),
      bad({ camera: { instrument: "FHAZ" }, date_taken_utc: "no-es-fecha" }),
    ],
  };
  const out = await getRoverPhotos({ missions: ["msl"], fetchJson: async () => raw });
  assert.equal(out.count, 1);
  assert.equal(out.photos[0].imageUrl, "https://mars.nasa.gov/b.jpg", "http pasa a https y se quita la clave");
  assert.deepEqual(findSecretLeaks(out), []);
  await assert.rejects(getRoverPhotos({ missions: ["msl"], fetchJson: async () => ({ images: [] }) }), /sin fotos/);
});

test("APOD: un video o una imagen con copyright no se marca como reutilizable", async () => {
  const base = { date: "2026-11-14", title: "<b>Titulo</b>", explanation: "texto", media_type: "image", url: "https://apod.nasa.gov/apod/image/x.jpg" };
  const ok = await getApod({ fetchJson: async () => base });
  assert.equal(ok.apod.title, "Titulo");
  assert.equal(ok.apod.reusable, true);
  const vid = await getApod({ fetchJson: async () => ({ ...base, media_type: "video", url: "https://www.youtube.com/embed/abc", copyright: "Alguien" }) });
  assert.equal(vid.apod.url, null, "YouTube no pasa la lista de dominios");
  assert.equal(vid.apod.reusable, false);
  await assert.rejects(getApod({ fetchJson: async () => ({ ...base, date: "ayer" }) }), /contrato roto/);
  const logo = { ...base, title: "NASA Science", url: "https://science.nasa.gov/wp-content/themes/nasa-child/assets/images/nasa-logo@2x.png" };
  await assert.rejects(getApod({ fetchJson: async () => logo }), /marcador de posición/);
});

test("CSA: extrae secciones y enlaces, descarta ruido y dominios ajenos", () => {
  const html = `<html><nav><a href="/eng/nav">Navegación</a></nav><h1>Kit de comida</h1><main>
    <h2>Lecturas</h2><a href="/eng/a.asp">Comer en el espacio</a><a href="/eng/a.asp">Repetido</a>
    <a href="https://letstalkscience.ca/x">Cultivar comida</a><a href="https://evil.example.com/x">Malo</a>
    <a href="mailto:a@b.c">Correo</a><a href="javascript:alert(1)">JS</a>
    <h2>Actividades</h2><a href="/eng/b.asp"><span>Master Chef</span> Marte</a>
    <h2>Explore further</h2><a href="/eng/c.asp">Ruido</a></main></html>`;
  const { title, sections } = parseCsaPage(html, "https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/");
  assert.equal(title, "Kit de comida");
  assert.deepEqual(sections.map((s) => s.name), ["Lecturas", "Actividades"]);
  assert.deepEqual(sections[0].items.map((i) => i.title), ["Comer en el espacio", "Cultivar comida"]);
  assert.equal(sections[0].items[1].external, true);
  assert.equal(sections[1].items[0].gameSystem, "food");
});

test("clima de Marte (InSight): contrato y archivo congelado", async () => {
  const raw = await fixture("insight_weather.sample.json");
  const out = await getMarsSurfaceWeather({ fetchJson: async () => raw });
  assert.ok(out.sols.length >= 1);
  assert.equal(out.meta.frozenArchive, true, "los datos son de 2020: no se presentan como actuales");
  for (const s of out.sols) {
    assert.ok(s.tempC.min <= s.tempC.avg && s.tempC.avg <= s.tempC.max);
    assert.match(s.firstUtc, /^\d{4}-\d{2}-\d{2}T/);
  }
  assert.deepEqual(findSecretLeaks(out), []);
});

test("DONKI en vivo: normaliza, ordena y descarta eventos rotos", async () => {
  const link = "https://ccmc.gsfc.nasa.gov/DONKI/view/FLR/1/-1";
  const data = {
    CME: [
      {
        activityID: "2026-11-01T19:00:00-CME-001",
        startTime: "2026-11-01T19:00Z",
        link,
        cmeAnalyses: [{ isMostAccurate: true, speed: 1000, halfAngle: 30, enlilList: [{ impactList: [{ location: "Mars", arrivalTime: "2026-11-07T06:00Z" }] }] }],
      },
    ],
    FLR: [
      { flrID: "2026-11-01T10:00:00-FLR-001", classType: "M5.1", peakTime: "2026-11-01T10:10Z", link },
      { classType: "X1.0", peakTime: "2026-11-02T10:10Z" }, // sin id: se descarta
    ],
    GST: [{ gstID: "2026-11-02T00:00:00-GST-001", startTime: "2026-11-02T00:00Z", allKpIndex: [{ kpIndex: 6.33 }], link }],
    SEP: [],
    IPS: [],
  };
  const out = await getSpaceWeatherLive({ days: 7, end: "2026-11-14", fetchJson: async (u) => data[/get\/(\w+)\?/.exec(u)[1]] });
  assert.equal(out.events.length, 3);
  assert.deepEqual(out.events.map((e) => e.type), ["FLR", "CME", "GST"], "ordenados por hora");
  const cme = out.events.find((e) => e.type === "CME");
  assert.equal(cme.arrivals.mars, "2026-11-07T06:00Z");
  assert.ok(cme.threat > 0.3 && cme.threat < 0.33);
  assert.equal(out.summary.marsImpacts, 1);
  assert.ok(out.events.every((e) => e.threat >= 0 && e.threat <= 1));
});

test("sanitizeEvent rechaza tipos desconocidos y tiempos inválidos", () => {
  assert.equal(sanitizeEvent({ id: "x", type: "XYZ", time: "2026-11-01T00:00Z", threat: 0.2 }), null);
  assert.equal(sanitizeEvent({ id: "x", type: "CME", time: "ayer", threat: 0.2 }), null);
  const ok = sanitizeEvent({ id: "x", type: "CME", time: "2026-11-01T00:00Z", threat: 7, link: "http://evil.com", label: { es: "<i>hola</i>" } });
  assert.equal(ok.threat, 0, "threat fuera de 0..1 => 0");
  assert.equal(ok.link, null);
  assert.equal(ok.label.es, "hola");
});
