# Pendientes manuales y procesos abiertos del proyecto

Estado de `Outpost Run` auditado el `14-11-2026` y de `ARES FORGE` (`roblox-blender/`) actualizado al `15-11-2026`.

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

Detalle completo y dueños en [`roblox-blender/docs/DECISIONES.md`](../roblox-blender/docs/DECISIONES.md). Resumen de lo ya integrado al `15-11-2026` vs lo abierto:

- **Integrado y verificado en Studio (`placeId: 114817072312952`, guardado versión `14` sin publicar):** `30/30` mallas Blender (`EditableMesh` `FixedSize = true`, con *Allow Mesh / Image APIs* activo, `Rover` e `Insignia`), `4/4` piezas con fichas NTRS (`20150005587`, `20040084278`, `20205007222`, `20240003648`), `12` datos de cartas contrastados con `science.nasa.gov`, acceso de Studio a APIs activo (`DataStore` responde en Studio), tipografía `Bangers` unificada en `Fx.luau` + HUD/menús, diseño «Forma humana» en botones del menú y movimiento dual `WASD / Flechas ↑↓←→` (`AresArrowKeys`), con `0` errores de consola y `0` recortes `TextFits`.
- [ ] **Publicación y Studio (`P-01`, `P-02`, `P-03`):** confirmar/fijar `Lighting.Technology = Future` manualmente en Studio (en inspección MCP al `15-11-2026` figura `RBX_OriginalTechnologyOnFileLoad = 3` = `ShadowMap` con migración Unified Lighting), publicar el lugar cuando el equipo lo pida y comprobar `DataStore` (`AresForgeMeta_v1`) en servidor publicado.
- [ ] **Rendimiento y móvil (`P-05`, `P-10`, `P-11`):** medir FPS en primer plano sin el capado de 15 FPS de Studio en segundo plano (meta: 60 FPS PC / 30 FPS móvil; `roblox-blender/docs/perf/RENDIMIENTO.md`), probar controles táctiles >= 44 px y medir sacudida de cámara frente a 4 px.
- [ ] **Balance y alcance (`F5`, `P-08`):** completar 5 partidas de prueba registradas (`0/5` hechas en `BALANCE_V0.md`) y decidir alcance definitivo de Q10 (héroes/objetos desbloqueables vs 8 mejoras actuales).
- [ ] **Contenido NASA en vivo y diseño (`P-07`, `P-15`):** decidir llamada en vivo a DONKI (proxy + `HttpService`) vs mantener snapshot local, alinear nombres de biomas en documentación con `Content.Biomes` y completar consejo de «kitear» si falta en `Content.Tutorial`.
- [ ] **Audio por escucha humana, demo y concurso (`P-12`, `P-13`, `P-14`):** validar por escucha humana las `3` pistas con licencia ya cargadas en `Balance.Audio.Music` y los `12` SFX con EQ en `AresSfx` (`AUDIO.md`), confirmar fecha/reglas/formato de entrega del concurso, completar 3 ensayos seguidos sin fallos (`DEMO_GUION.md`) y grabar video respaldo + tráiler (`TRAILER_BRIEF_FABLE.md`).
- [ ] **Entorno local opcional (`BLENDER_PIPELINE.md`, `tools/studio/README.md`):** usar `tools/studio/push.py` o MCP de Roblox Studio para sincronizar cambios hacia el lugar en nube (`sync_studio.luau` HTTP queda reservado a lugares locales) y reemplazar marcadores `<RUTA_...>` si se levanta el puente Blender MCP en un equipo nuevo.
