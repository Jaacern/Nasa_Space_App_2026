# API local y saneado de datos

Capa intermedia entre las APIs de NASA/CSA y `Outpost Run`. El juego pide datos a **su propio servidor local** (`127.0.0.1:8787`); el servidor consulta, sanea, valida el contrato y entrega JSON con formato fijo:

- `NASA_API_KEY` nunca llega al navegador;
- el frontend evita las diferencias de CORS entre fuentes;
- si una llamada externa falla o rompe el esquema, el servidor responde con el snapshot guardado;
- cada respuesta declara `meta.mode` (`"live"` o `"snapshot"`) y la cabecera `X-Data-Mode`.

## Arrancar y comprobar

```bash
npm run api            # http://127.0.0.1:8787 (abre / para ver el catálogo)
npm test               # 23 pruebas sin red (unitarias + integración API)
npm run check          # valida contenido, catálogo y snapshots en disco
npm run check:live     # además prueba fuentes reales y busca fugas de claves
```

Variables opcionales (`.env`, ignorado por Git): `NASA_API_KEY`, `PORT`, `HOST`.

## Endpoints

Todos usan `GET` (o `HEAD`). Sin parámetros devuelven los snapshots de `data/curated/` y funcionan sin red.

| Endpoint | Parámetros | Devuelve |
|---|---|---|
| `/api/catalog` | | Catálogo de las 8 fuentes y su uso en el juego |
| `/api/health` | | Estado del servidor, si hay `NASA_API_KEY` configurada (nunca su valor) y estado de `manifest.json` |
| `/api/space-weather` | `live=1`, `days=1..30` | Eventos de clima espacial normalizados (DONKI) |
| `/api/scenarios` | | Lista de 4 escenarios rejugables con dificultad |
| `/api/scenarios/:id` | | Un escenario específico con todos sus eventos |
| `/api/radiation` | | Dosis medidas por sitio (ISS, órbita lunar, Orion, órbita de Marte) |
| `/api/osdr` | `topic=bone\|muscle\|immune\|radiation\|plants\|sleep` | Lista de temas o los estudios de un tema |
| `/api/mars-layers` | | Plantilla de teselas WMTS de Mars Trek |
| `/api/mars-weather` | `live=1` | Temperatura, presión y viento en Marte (InSight, archivo congelado de 2020) |
| `/api/rover-photos` | `live=1` | Fotos crudas reales de Perseverance y Curiosity (`mars.nasa.gov`) |
| `/api/apod` | `live=1` | Imagen astronómica del día (APOD; verificar `apod.reusable`) |
| `/api/csa` | `live=1` | Títulos y enlaces educativos de la CSA |
| `/api/manifest` | | Resultado de la última ingesta por fuente |

`live=1` intenta la fuente real con caché en memoria de `10` minutos (`/api/space-weather`) o `60` minutos (`/api/mars-weather`, `/api/rover-photos`, `/api/apod`, `/api/csa`). Si falla, responde el snapshot con `meta.fallbackReason`.

### Forma de la respuesta

```json
{
  "meta": {
    "source": "NASA CCMC DONKI",
    "mode": "snapshot",
    "retrievedAt": "2026-11-14T14:40:15.422Z",
    "sourceUrl": "https://ccmc.gsfc.nasa.gov/DONKI/api/",
    "fallbackReason": "solo aparece si live=1 falló"
  },
  "summary": { "maxThreat": 0.488, "marsImpacts": 10, "earthImpacts": 3 },
  "events": [ { "id": "...", "type": "CME", "time": "2026-10-15T20:24Z", "threat": 0.058 } ]
}
```

Errores: `{ "error": { "code": "unknown_topic", "message": "..." } }` con estado `400`, `404`, `405`, `429` o `503`. Los mensajes pasan por `redact()` y nunca exponen URLs con claves.

### Ejemplo real: fotos de rovers (`/api/rover-photos`)

```bash
curl "http://127.0.0.1:8787/api/rover-photos?live=1"
```

```json
{
  "meta": {
    "source": "NASA Mars Raw Images (Perseverance, Curiosity)",
    "mode": "snapshot",
    "retrievedAt": "2026-11-14T15:29:21.742Z",
    "sourceUrl": "https://mars.nasa.gov/rss/api/",
    "warnings": []
  },
  "count": 6,
  "photos": [
    {
      "id": "...",
      "rover": "Perseverance",
      "sol": 2024,
      "earthDate": "2026-10-30",
      "camera": "MCZ_LEFT",
      "title": "Mars Perseverance Sol 2024: Left Mastcam-Z Camera",
      "imageUrl": "https://mars.nasa.gov/...jpg",
      "pageUrl": "https://mars.nasa.gov/..."
    }
  ]
}
```

El adaptador `getRoverPhotos` no copia el JSON crudo: filtra solo cámaras de paisaje (`SCENERY_CAMERA`), convierte `http` a `https`, exige dominio `nasa.gov`, elimina posibles parámetros de clave en `safeUrl()` y valida `ROVER_PHOTOS_SCHEMA`.

## Consumir desde el juego

Si abres el juego desde este servidor (`http://127.0.0.1:8787/public/index.html`), no requiere configuración adicional de CORS:

```js
const res = await fetch("/api/scenarios/gannon-2024-05");
const { scenario, meta } = await res.json();
// meta.mode === "snapshot": muéstralo como "copia guardada", nunca como "en vivo"
```

También se sirve de forma estática `/src/`, `/data/curated/`, `/content/` y `/public/` para cargar `src/data/worldState.mjs` directamente (ver [`docs/PLAN-JUEGO-Y-DATOS.md`](PLAN-JUEGO-Y-DATOS.md), sección 3.4). Cualquier otra ruta (`.env`, `scripts/`, `package.json`) devuelve `404` y se verifica en `test/server.test.mjs`.

## Qué se sanea y dónde

Todo lo externo pasa por [`src/api/sanitize.mjs`](../src/api/sanitize.mjs) antes de persistirse o servirse:

| Riesgo | Defensa |
|---|---|
| Clave en una URL o en un error | `redact()` oculta `api_key`, `apikey`, `access_token` y el valor real de `NASA_API_KEY` |
| Clave dentro de un enlace o fragmento | `safeUrl()` elimina parámetros secretos incluso dentro de `#/?...` |
| HTML o texto largo | `cleanText()` quita etiquetas y recorta longitud |
| Número inválido (`"NaN"`, fuera de rango) | `num()` devuelve `null` si no es finito o sale de límites |
| Enlace fuera de dominios confiables | `safeUrl()` valida la lista blanca de hosts y fuerza `https` |
| Cambio inesperado en una API | `assertValid()` valida el contrato; si falla, el servidor cae al snapshot |
| Evento DONKI sin id, tipo o fecha | `sanitizeEvent()` lo descarta |

Las pruebas de `test/api.test.mjs` cubren saneado, respuestas "hostiles" inline (p. ej. URLs con `api_key` inyectada en `getRoverPhotos`), contratos de `APOD`, `InSight`, `DONKI` y parser HTML de `CSA` usando fixtures en `test/fixtures/`.

## Añadir una fuente nueva

1. Registra la fuente y su `gameUse` en `CATALOG` (`src/api/catalog.mjs`).
2. Copia el patrón de `getRoverPhotos` en `src/api/sources.mjs` y define su esquema de contrato (como `ROVER_PHOTOS_SCHEMA` o `APOD_SCHEMA`).
3. Añade un fixture en `test/fixtures/` y pruebas unitarias en `test/api.test.mjs`.
4. Expón el endpoint en `server/api.mjs` mediante `liveOrSnapshot`.
5. Si requiere snapshot offline, añade su trabajo en `JOBS` (`scripts/ingest.mjs`, siguiendo `ingestRover`) y su validación en `scripts/check.mjs`.

## Límites conocidos

- **`api.nasa.gov/mars-photos`:** la API heredada devolvió 404 `"No such app"` (verificado el `14-11-2026`); se reemplazó por los feeds oficiales de `mars.nasa.gov` sin clave.
- **`DEMO_KEY`:** límite bajo observado (10/hora en pruebas, propensa a `HTTP 429`). APOD requiere clave propia en `.env`.
- **RadLab:** solo se consulta por lotes en `npm run ingest` con intervalo de fechas; sin ventana temporal devuelve `HTTP 504`.
- **InSight:** archivo congelado de 2020 (`frozenArchive: true`, último sol `2020-10-25`); nunca presentarlo como clima actual.
- **Estado en memoria:** tanto la caché de respuestas como el limitador de `120` peticiones/minuto por IP viven en memoria de proceso.
