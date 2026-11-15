# Pendientes manuales y procesos abiertos del proyecto

Estado auditado el `14-11-2026` para **ambos subproyectos** (`Outpost Run` en raíz y `ARES FORGE` en `roblox-blender/`).

---

## Qué ya está automatizado y verificado (`Outpost Run`)

Comprobado con `npm test` (`23/23` OK) y `npm run check` (`8` fuentes en `CATALOG`, `9` snapshots presentes en `data/curated/`):

| Fuente | Acceso | Estado en `manifest.json` |
|---|---|---|
| DONKI (clima espacial) | Sin clave (`ccmc.gsfc.nasa.gov`) | OK (`104` eventos + `4` escenarios) |
| RadLab (radiación orbital) | Sin clave (`visualization.osdr.nasa.gov`) | OK (`4` sitios) |
| OSDR (biología y salud espacial) | Sin clave (`osdr.nasa.gov`) | OK (`26` estudios) |
| Mars Trek (capas WMTS) | Sin clave (`trek.nasa.gov`) | OK (`1` capa base MOLA) |
| Rover Photos (Perseverance y Curiosity) | Sin clave (`mars.nasa.gov`) | OK (`6` fotos) |
| InSight (clima de Marte 2020) | Clave NASA (`api.nasa.gov`) | OK (`7` sols, archivo congelado) |
| CSA (STEM y producción de alimentos) | Sin clave (`asc-csa.gc.ca`) | OK (`64` enlaces) |
| APOD (imagen astronómica del día) | Clave NASA (`api.nasa.gov`) | Error `HTTP 500` en última ingesta; snapshot `apod.json` en estado provisional (`reusable: false`) |

---

## Parte A — Pendientes de `Outpost Run` (raíz Node/Web)

### 1. Credenciales, licencia y repo

- [ ] **Rotar `NASA_API_KEY` expuesta (P-04)** y configurar `.env` local.
  - Cómo: solicitar clave nueva en <https://api.nasa.gov/>, copiar `.env.example` a `.env` y pegar `NASA_API_KEY=...`.
  - Después ejecutar `npm run check:live` y `npm run ingest -- --only=apod` para reemplazar el snapshot provisional de APOD.
- [ ] **Definir archivo `LICENSE`** en la raíz del repositorio (decisión abierta del equipo; ver `roblox-blender/README.md`).

### 2. Desarrollo de juego y UI faltantes

- [ ] **Implementar bucle de juego (`src/sim/`) e interfaz jugable (`src/ui/`)** reemplazando la pantalla mínima de prueba [`public/index.html`](../public/index.html).
- [ ] **Crear la pantalla "De dónde vienen los datos"** usando `attributionLines()` (`src/data/worldState.mjs`), fechas de snapshot y aviso de no patrocinio de NASA/CSA.
- [ ] **Probar el frontend en navegador real** contra `npm run api` (`/api/...` y teselas WMTS de Mars Trek).

### 3. Curación de contenido y verificaciones externas

- [ ] **Elegir manualmente los estudios OSDR** por tema y redactar/aprobar resúmenes infantiles con [`docs/ia/PROMPTS.md`](ia/PROMPTS.md), dejando `reviewedByHuman: true` (hoy hay **26** estudios pendientes que `pickFact()` oculta).
- [ ] **Registrar el uso de IA** en [`docs/ia/REGISTRO.md`](ia/REGISTRO.md) si las reglas del evento lo exigen.
- [ ] **Revisar reglas del desafío (Resources + IA)** y **"Notices and copyright" de la CSA** (<https://www.asc-csa.gc.ca/eng/terms.asp> / `eng/about/`). Mientras no se confirme licencia por recurso, solo enlazar y no copiar textos o imágenes.
- [ ] **Elegir región y capas finales de Mars Trek** en <https://trek.nasa.gov/mars/> y actualizar `MARS_LAYERS` en `scripts/ingest.mjs`.
- [ ] **Validar valores físicos de [`content/balance.json`](../content/balance.json)** frente a fuentes NASA y completar [`content/glossary.json`](../content/glossary.json) (actualmente borrador de 6 términos).
- [ ] **Probar el prototipo con público de 7 a 12 años** para validar comprensión de cartas, textos y reglas.
- [ ] **Ejecutar ingesta final pre-demo** (`npm run ingest`, luego `npm run check`) y commitear `data/curated/` antes de presentar.

---

## Parte B — Pendientes de `ARES FORGE` (`roblox-blender/`)

Detalle completo y dueños en [`roblox-blender/docs/DECISIONES.md`](../roblox-blender/docs/DECISIONES.md#L131-L153). Resumen de lo abierto:

- [ ] **Publicación y Studio (`P-01`, `P-02`, `P-03`):** fijar `Lighting.Technology = Future` manualmente en Studio, guardar y publicar el lugar, y comprobar guardado/carga real de `DataStore` (`AresForgeMeta_v1`).
- [ ] **Rendimiento y móvil (`P-05`, `P-10`, `P-11`):** medir FPS en primer plano sin el capado de 15 FPS de Studio en segundo plano (meta: 60 FPS PC / 30 FPS móvil; `roblox-blender/docs/perf/RENDIMIENTO.md`), probar controles táctiles >= 44 px y medir sacudida de cámara frente a 4 px.
- [ ] **Balance y alcance (`F5`, `P-08`):** completar 5 partidas de prueba registradas (`0/5` hechas en `BALANCE_V0.md`) y decidir alcance definitivo de Q10 (héroes/objetos desbloqueables vs 8 mejoras actuales).
- [ ] **Contenido NASA y diseño (`P-06`, `P-07`, `P-15`, `REFERENCIAS.md`):** verificar fichas NTRS para antena de alta ganancia y generador de oxígeno, decidir llamada en vivo (proxy + `HttpService`) vs mantener snapshot DONKI, alinear nombres de biomas del prompt maestro con `Content.Biomes`, agregar consejo de "kitear" en `Content.Tutorial` y decidir si `Fx.luau` reemplaza `GothamBlack`.
- [ ] **Audio, demo y concurso (`P-12`, `P-13`, `P-14`):** incorporar 3 pistas musicales en `Balance.Audio.Music` y SFX propios (`AUDIO.md`), confirmar fecha/reglas/formato de entrega del concurso, completar 3 ensayos seguidos sin fallos (`DEMO_GUION.md`) y grabar video respaldo + tráiler (`TRAILER.md`).
- [ ] **Entorno MCP local (`BLENDER_PIPELINE.md`):** reemplazar marcadores `<RUTA_...>` en `roblox-blender/.mcp.json` y `tools/blender_mcp/config.json`, activar *Enable Studio as MCP server* y validar `roblox-export` en Studio.
