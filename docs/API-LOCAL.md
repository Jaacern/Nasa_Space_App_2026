# API local y saneado de datos

Una capa entre las APIs de NASA y el juego. El juego pide datos a **tu propio servidor**; el servidor llama a NASA, limpia la respuesta y la entrega con un formato fijo. Así:

- la clave de NASA nunca llega al navegador;
- el juego no sufre las diferencias de CORS entre fuentes;
- una respuesta mal formada no rompe la pantalla (se usa el snapshot);
- cada respuesta dice si es **en vivo** o **copia guardada**.

## Arrancar

```bash
npm run api            # http://127.0.0.1:8787  (abre / para ver la lista)
npm test               # 15 pruebas sin red
npm run check:apis     # prueba las 6 fuentes en vivo
```

Variables opcionales (archivo `.env`, que Git ignora): `NASA_API_KEY`, `PORT`, `HOST`.

## Endpoints

Todos son `GET`. Sin parámetros devuelven el snapshot de `data/curated/` y funcionan sin red.

| Endpoint | Parámetros | Devuelve |
|---|---|---|
| `/api/health` | | Estado, si hay clave configurada (nunca su valor) y estado de cada fuente |
| `/api/space-weather` | `live=1`, `days=1..30` | Eventos de clima espacial normalizados |
| `/api/scenarios` | | Lista de escenarios rejugables con dificultad |
| `/api/scenarios/:id` | | Un escenario con todos sus eventos |
| `/api/radiation` | | Dosis medidas por sitio (ISS, órbita lunar, Orion, órbita de Marte) |
| `/api/osdr` | `topic=bone\|muscle\|immune\|radiation\|plants\|sleep` | Temas, o los estudios de un tema |
| `/api/mars-weather` | `live=1` | Temperatura, presión y viento de InSight |
| `/api/mars-layers` | | Plantilla de teselas WMTS de Mars Trek |
| `/api/asteroids` | `date=YYYY-MM-DD`, `live=1` | Ejemplo de estructura con NeoWs |
| `/api/manifest` | | Resultado de la última ingesta por fuente |

`live=1` intenta la fuente real durante una caché de 10 a 60 minutos. Si falla, responde con el snapshot y añade `meta.fallbackReason`.

### Forma de la respuesta

```json
{
  "meta": {
    "source": "NASA CCMC DONKI",
    "mode": "snapshot",
    "retrievedAt": "2026-11-14T14:34:34.798Z",
    "sourceUrl": "https://ccmc.gsfc.nasa.gov/DONKI/api/",
    "fallbackReason": "solo aparece si live=1 falló"
  },
  "summary": { "maxThreat": 0.488, "marsImpacts": 10, "earthImpacts": 3 },
  "events": [ { "id": "...", "type": "CME", "time": "2026-10-15T20:24Z", "threat": 0.058 } ]
}
```

Errores: `{ "error": { "code": "unknown_topic", "message": "..." } }` con estado 400, 404, 405, 429 o 503. Los mensajes nunca incluyen URLs con claves.

### Ejemplo: asteroides (la estructura de referencia)

```bash
curl "http://127.0.0.1:8787/api/asteroids?live=1&date=2026-11-14"
```

```json
{
  "meta": { "source": "NASA NeoWs", "mode": "live", "retrievedAt": "..." },
  "date": "2026-11-14",
  "count": 5,
  "hazardousCount": 0,
  "objects": [
    {
      "id": "…", "name": "(2020 AB)", "hazardous": false,
      "diameterM": { "min": 10.1, "max": 22.5 },
      "missDistanceKm": 15974992, "missDistanceLunar": 41.54,
      "velocityKmS": 7.27, "approachTime": "2026-Nov-14 03:38",
      "jplUrl": "https://ssd.jpl.nasa.gov/…"
    }
  ]
}
```

La respuesta cruda de NeoWs trae `links.next` con la clave dentro (`api_key=...`). El adaptador **no copia** esos campos: arma el objeto de salida desde cero.

## Consumir desde el juego

Si abres el juego desde este mismo servidor (la página de prueba `public/index.html` se ve en `http://127.0.0.1:8787/public/index.html`), no hay CORS que configurar:

```js
const res = await fetch("/api/scenarios/gannon-2024-05");
const { scenario, meta } = await res.json();
// meta.mode === "snapshot": muéstralo como "copia guardada", nunca como "en vivo"
```

Si prefieres no usar el servidor, `src/data/worldState.mjs` lee directamente `data/curated/*.json` (ver `docs/PLAN-JUEGO-Y-DATOS.md`, sección 3.4).

El servidor sirve estas carpetas como archivos estáticos: `/src/`, `/data/curated/`, `/content/` y `/public/`. Cualquier otra ruta (`.env`, `scripts/`, `package.json`) devuelve 404; hay una prueba que lo comprueba.

## Qué se sanea y dónde

Todo lo externo pasa por `src/api/sanitize.mjs` antes de existir en el proyecto.

| Riesgo | Defensa |
|---|---|
| Clave en una URL o en un error | `redact()` oculta `api_key` y el valor real de `NASA_API_KEY` |
| Clave dentro de un enlace de la respuesta | `safeUrl()` quita parámetros secretos, incluso dentro del fragmento `#/?...` |
| HTML o texto largo en un nombre | `cleanText()` quita etiquetas y limita la longitud |
| Número inválido (`"NaN"`, `-5`, `99999`) | `num()` devuelve `null` si no es finito o está fuera de rango |
| Enlace a un dominio ajeno | `safeUrl()` solo acepta `nasa.gov` y lo fuerza a `https` |
| Cambio de formato de la API | `assertValid()` comprueba el contrato; si falla, se sirve el snapshot |
| Evento sin id, hora o tipo | `sanitizeEvent()` lo descarta |

Las pruebas de `test/api.test.mjs` incluyen una respuesta "hostil" (`test/fixtures/neows_feed.hostile.json`) y una prueba real de InSight. Una de ellas encontró un fallo real el primer día (la clave seguía en el fragmento de una URL) y ya está corregido.

## Añadir una fuente nueva

1. Copia el patrón de `getAsteroids` en `src/api/sources.mjs`.
2. Define su esquema de contrato (`ASTEROIDS_SCHEMA` es el modelo).
3. Añade un ejemplo en `test/fixtures/` y una prueba en `test/api.test.mjs`.
4. Añade el endpoint en `server/api.mjs` con `liveOrSnapshot`.
5. Si debe tener copia guardada, añade un trabajo en `scripts/ingest.mjs` (`ingestNeo` es el modelo).

## Límites conocidos

- **`DEMO_KEY`:** observamos un límite de 10 solicitudes por hora y se agotó en las pruebas. Usa tu clave.
- **RadLab:** solo se consulta por lotes en `npm run ingest`, siempre con rango de fechas. No hay modo `live` porque sin rango da 504.
- **InSight:** es un archivo congelado de 2020; la respuesta marca `frozenArchive: true` y no debe presentarse como clima actual.
- **Una instancia, sin base de datos:** la caché es de memoria. Suficiente para el hackatón; para producción hace falta otro diseño.
