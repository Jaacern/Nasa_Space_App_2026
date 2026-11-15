# Datos: fuentes, API local y saneado

Todo lo que el juego necesita de NASA y la CSA, ya descargado, limpio y servido con un formato fijo. Verificado el **14 de noviembre de 2026**.

**Regla de relevancia:** una fuente solo existe en el proyecto si sirve a una mecánica del juego. El catálogo (`src/api/catalog.mjs`) declara el uso de cada una, y `npm run check` falla si aparece un archivo en `data/curated/` que no pertenece a ninguna fuente del catálogo.

## 1. Los recursos del desafío y su estado

| Recurso de la pestaña Resources | Estado | Clave | Endpoint local | Uso en el juego |
|---|---|---|---|---|
| **DONKI** | Funciona | No | `/api/space-weather`, `/api/scenarios` | Calendario de eventos solares reales (avisos, apagones, partículas) |
| **RadLab** | Funciona | No | `/api/radiation` | Dosis medida en la ISS, órbita lunar, Orion (Artemis I) y órbita de Marte |
| **OSDR** (búsqueda) | Funciona | No | `/api/osdr` | Estudios reales por tema: hueso, músculo, inmunidad, radiación, plantas, sueño |
| **Mars Trek** | Funciona | No | `/api/mars-layers` | Mapa de relieve de Marte para el sitio del outpost |
| **NASA Open APIs: Mars Rover Photos** | **Cambió** (ver abajo) | No | `/api/rover-photos` | Fotos reales de Perseverance y Curiosity |
| **NASA Open APIs: APOD** | Funciona a ratos | Sí | `/api/apod` | Imagen del día para el arranque. Opcional |
| **CSA: recursos STEM** | Funciona | No | `/api/csa` | Actividades enlazadas desde el informe final |
| **CSA: producción de alimentos** | Funciona | No | `/api/csa` | Lecturas y actividades para la carta Invernadero |
| *InSight (no está en la pestaña)* | Funciona, archivo de 2020 | Sí | `/api/mars-weather` | El enunciado pide datos ambientales de Marte: temperatura, presión, viento |

Lo que **no** se incluyó a propósito: asteroides (NeoWs), fotos de la Tierra (EPIC) y cualquier otra API de `api.nasa.gov` que no sirva a una mecánica del outpost.

### Dos hallazgos que cambian cómo usar la pestaña

1. **La API "Mars Rover Photos" de `api.nasa.gov` ya no existe.** Responde `404 No such app` (comprobado con clave válida; su mantenedor dejó de sostenerla). Se sustituyó por los feeds oficiales de imágenes crudas de `mars.nasa.gov`, que son la fuente original, no necesitan clave y tenían fotos del 13 de noviembre de 2026 (Curiosity, sol 5073).
2. **APOD es inestable.** Respondió `500` varias veces y una vez devolvió el logo de NASA como "imagen del día". El adaptador rechaza ese marcador de posición y no hay snapshot hasta que la API devuelva una imagen real. Para el juego es decorativo: no dependas de ella.

## 2. Cómo consumir

### A. API local (recomendado para el juego)

```bash
npm run api          # http://127.0.0.1:8787  (abre / para ver el catálogo)
```

```js
const res = await fetch("/api/scenarios/gannon-2024-05");
const { scenario, meta } = await res.json();
// meta.mode === "snapshot": muéstralo como "copia guardada", nunca como "en vivo"
```

La página de prueba `public/index.html` se abre en `http://127.0.0.1:8787/public/index.html`. Al servir el juego desde este mismo servidor no hay CORS que configurar.

| Endpoint | Parámetros | Devuelve |
|---|---|---|
| `/api/catalog` | | Las fuentes, su uso en el juego y sus endpoints |
| `/api/health`, `/api/manifest` | | Estado, si hay clave configurada (nunca su valor) y resultado de la última ingesta |
| `/api/space-weather` | `live=1`, `days=1..30` | Eventos normalizados de los últimos días |
| `/api/scenarios`, `/api/scenarios/:id` | | Escenarios rejugables (`quiet-recent`, `sep-2017-storms`, `gannon-2024-05`, `oct-2024-x9`) |
| `/api/radiation` | | Dosis por sitio, con avisos (`caveats`) |
| `/api/osdr` | `topic=bone\|muscle\|immune\|radiation\|plants\|sleep` | Temas, o los estudios de un tema |
| `/api/mars-weather` | `live=1` | Temperatura, presión y viento por sol |
| `/api/mars-layers` | | Plantilla de teselas WMTS |
| `/api/rover-photos` | `live=1` | Fotos recientes por cámara |
| `/api/csa` | `live=1` | Secciones y enlaces de las dos páginas de la CSA |
| `/api/apod` | `live=1` | Imagen del día (puede no existir) |

Sin parámetros, todo responde con el snapshot y **funciona sin red**. Con `live=1` intenta la fuente real y, si falla, devuelve el snapshot con `meta.fallbackReason`.

Forma de toda respuesta:

```json
{ "meta": { "source": "...", "mode": "snapshot", "retrievedAt": "2026-11-14T14:34:34Z", "sourceUrl": "..." }, "...datos": "..." }
```

Errores: `{ "error": { "code": "unknown_topic", "message": "..." } }`, con estado 400, 404, 405, 429 o 503. Nunca incluyen URLs con claves.

### B. Leer los archivos directamente

`src/data/worldState.mjs` lee `data/curated/*.json` y entrega lo que usa el motor del juego:

```js
import { browserReader, loadWorldState, getScenario, scheduleEvents, siteProfile, commDelaySec, pickFact, makeRng, attributionLines } from "./src/data/worldState.mjs";

const state = await loadWorldState(browserReader("./data/curated/"));
const schedule = scheduleEvents(getScenario(state, "gannon-2024-05"), "mars", { sols: 30, minThreat: 0.3 });
const profile = siteProfile(state, "mars");        // dosis base, múltiplo respecto a la ISS, retraso de radio
const delay = commDelaySec("mars", currentSol);    // segundos, un solo sentido
const fact = pickFact(state, "radiation", makeRng(seed)); // estudio OSDR real; texto infantil solo si fue revisado
```

| Función | Para qué |
|---|---|
| `getScenario(state, id)` | `"live"` o un escenario archivado |
| `scheduleEvents(escenario, sitio, {sols, minThreat})` | Reparte eventos reales en soles. Añade `sol`, `hitsSite`, `arrivalSol`, `warningSols` |
| `siteProfile(state, sitio)` | Dosis medida, múltiplo respecto a la ISS, retraso de radio, avisos |
| `commDelaySec(sitio, sol)` | Retraso de radio de un sentido: Luna ~1,3 s, Marte de ~3 a ~22 min |
| `pickFact(state, tema, rng)` | Estudio OSDR; `text` es `null` hasta que una persona revise el resumen infantil |
| `makeRng(seed)` | Aleatorio con semilla: misma semilla, misma partida |
| `attributionLines(state)` | Créditos listos para la interfaz |

### C. Actualizar los datos

```bash
cp .env.example .env        # y pega tu NASA_API_KEY (solo hace falta para APOD e InSight)
npm run ingest              # todo
npm run ingest -- --only=donki,rover   # fuentes concretas: donki,radlab,osdr,mars,rover,insight,apod,csa
npm run ingest -- --end=2026-11-01     # fijar la fecha de DONKI para que todo el equipo tenga lo mismo
npm run check:live          # prueba las 8 fuentes reales con el saneado
```

Si una fuente falla, **no se pisa su archivo anterior**: el juego sigue con el último snapshot bueno y `manifest.json` registra el error. Antes de la demo: última ingesta, `npm run check`, commit de `data/curated/`.

## 3. Datos por fuente

### DONKI
- API oficial: `https://ccmc.gsfc.nasa.gov/DONKI-API/get/{CME|FLR|GST|SEP|IPS}?startDate=&endDate=`. Desde el **30 de septiembre de 2026** reemplaza a `kauai.ccmc...` y a `api.nasa.gov/DONKI`. Sin clave ni CORS.
- Cada evento se normaliza a `{ id, type, time, threat 0..1, gameEffect, label{es,en}, detail, arrivals{earth,mars}, link }`.
- `threat` es **una heurística del equipo**, no una escala NASA/NOAA (reglas en `src/api/normalize.mjs`). DONKI marca su contenido como experimental; la fuente oficial de pronósticos es NOAA SWPC.
- `arrivals.mars` y `arrivals.earth` salen de las simulaciones de DONKI. La Luna se aproxima con la Tierra, porque DONKI no modela la Luna.
- Los escenarios archivados tienen dificultad según cuántos eventos fuertes traen: `drizzle` (0), `rainstorm` (1 a 14) y `monsoon` (15 o más). Son ids internos; en la interfaz usen nombres propios.

### RadLab
- `https://visualization.osdr.nasa.gov/radlab/api/`. Sin clave. **Siempre con rango de fechas**: sin él responde 504.
- Sitios incluidos: ISS (instrumento Lidal), órbita lunar (LRO CRaTER), Orion en Artemis I y órbita de Marte (Liulin-MO).
- Dosis absorbida mediana por sitio: ISS 4,2; órbita lunar 12,7; Orion 17,2; órbita de Marte 15,2 μGy/h. Equivale a 3 a 4 veces la ISS.
- Son mediciones **en órbita o en vuelo, no en superficie**, de años y fases solares distintos. La comparación es orientativa y el JSON lo dice en `caveats`.
- μGy/h (dosis absorbida) y μSv/h (dosis equivalente) son magnitudes distintas: no se suman.

### OSDR
- Búsqueda: `https://osdr.nasa.gov/osdr/data/search?term=...`. El filtro del pipeline descarta coincidencias casuales y estudios de GEO/PRIDE, y ordena por pertinencia al tema.
- Casi todos los estudios son en ratones, ratas o plantas. Cada uno lleva `evidenceNote`: **no presentarlo como efecto exacto en astronautas**.
- `kidSummary` empieza vacío; una persona lo revisa antes de que se muestre (ver `docs/IA.md`).
- Para datos y archivos de un estudio existe la API biológica v2 (`https://visualization.osdr.nasa.gov/biodata/api/v2/`), con salida JSON, CSV y TSV. No hace falta para el prototipo.

### Mars Trek
- Teselas WMTS: `mars_layers.json` trae la plantilla lista (`tileUrlTemplate`). Permiten CORS, así que el navegador las carga directo.
- Usa el CRS marciano `EPSG:104905`, no Web Mercator. El nivel 0 tiene 2 columnas y 1 fila. Una tesela ausente significa "sin datos".
- Hoy hay una capa (relieve MOLA). Elegir sitio y capas adicionales se hace explorando <https://trek.nasa.gov/mars/>; añadir la capa en `MARS_LAYERS` de `scripts/ingest.mjs`.

### Fotos de Marte
- `https://mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020|msl&feedtype=json&order=sol+desc`. Sin clave. Se guardan las cámaras de paisaje (navegación, mástil, riesgos) y una foto por cámara. Crédito: NASA/JPL-Caltech.

### InSight
- Clima de superficie: temperatura, presión y viento por sol. Los datos son de **octubre de 2020**; la respuesta trae `frozenArchive: true` y no debe presentarse como clima actual.

### CSA
- Se guardan **solo títulos y enlaces**. Los [términos de la CSA](https://www.asc-csa.gc.ca/eng/terms.asp) permiten reproducir su contenido con fines personales, educativos o informativos sin fines de lucro si se verifica la exactitud, se cita a la CSA como fuente y no se sugiere su respaldo. El logotipo de la CSA no se puede usar sin permiso escrito.
- Los enlaces externos (Let's Talk Science, Ingenium) quedan marcados con `external: true` y tienen sus propias condiciones.

## 4. Saneado

Todo lo externo pasa por `src/api/sanitize.mjs` antes de existir en el proyecto.

| Riesgo | Defensa |
|---|---|
| Clave en una URL o en un error | `redact()` oculta `api_key` y el valor real de `NASA_API_KEY` |
| Clave dentro de un enlace de la respuesta, incluso en el fragmento `#/?...` | `safeUrl()` quita parámetros secretos |
| HTML o texto largo | `cleanText()` quita etiquetas y limita la longitud |
| Número inválido (`"NaN"`, `-5`, `99999`) | `num()` devuelve `null` si no es finito o está fuera de rango |
| Enlace a un dominio ajeno | `safeUrl()` acepta solo dominios permitidos y fuerza `https` |
| La API cambia de formato | `assertValid()` comprueba el contrato; si falla, se sirve el snapshot |
| Evento sin id, hora o tipo | `sanitizeEvent()` lo descarta |
| La API devuelve un marcador de posición | El adaptador de APOD lo rechaza |
| Servidor expone archivos privados | Solo se sirven `/src/`, `/data/curated/`, `/content/` y `/public/` |

## 5. Añadir una fuente

1. Justifica su uso en el juego y regístrala en `src/api/catalog.mjs`. Sin eso, `npm run check` rechaza su archivo.
2. Copia el patrón de `getRoverPhotos` en `src/api/sources.mjs` (pedir, quedarse con campos conocidos, contrato, `meta.mode = "live"`).
3. Añade un ejemplo real en `test/fixtures/` y una prueba en `test/api.test.mjs`.
4. Añade el endpoint en `server/api.mjs` con `simple()` o `liveOrSnapshot()`.
5. Añade un trabajo en `scripts/ingest.mjs` (`ingestRover` es el modelo).

## 6. Límites

- **Claves:** `DEMO_KEY` mostró un límite de 10 por hora y se agotó. APOD e InSight necesitan clave propia.
- **Caché:** la del servidor es de memoria; sirve para el hackatón, no para producción.
- **CORS:** verificado leyendo cabeceras con Node, no desde un navegador. DONKI no envía cabecera CORS y el buscador OSDR solo permite `osdr.nasa.gov`; por eso el juego lee snapshots o la API local. Las teselas de Mars Trek permiten CORS.
