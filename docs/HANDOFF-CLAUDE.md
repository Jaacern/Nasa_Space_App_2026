# Handoff completo para continuar en Claude Code

Última actualización: `14-11-2026` · Rama activa: `audit/actualizacion-completa` (origin: `https://github.com/Jaacern/Nasa_Space_App_2026.git`).

Este documento resume el estado real auditado, todos los cambios ya aplicados y verificados, el mapa técnico de ambos subproyectos y la lista exacta de tareas pendientes para continuar sin perder contexto.

---

## 1. Estado de Git y estructura actual

- **Base remota original:** `origin/main` en `c203130` (*"Add files via upload"*).
- **Rama de trabajo creada y subida:** `audit/actualizacion-completa`, que mantiene la historia intacta e incluye:
  - **`ffa4b7e`** — Limpieza de los `8` archivos añadidos en raíz por `c203130` (`.mcp.json` y `BLENDER_PIPELINE.md` con rutas `C:\Users\black\...`, `MEGA_CONTEXTO_MIS_SKILLS.md` de `85 651` líneas y `5` copias duplicadas de `roblox-blender/`) + `__pycache__/` y `*.pyc` agregados a [`.gitignore`](../.gitignore).
  - **`84cb466`** — Arreglos técnicos puntuales: exportación de `APOD_SCHEMA` en [`src/api/sources.mjs`](../src/api/sources.mjs) y validación en [`scripts/check.mjs`](../scripts/check.mjs); normalización de [`data/curated/apod.json`](../data/curated/apod.json) (`hdUrl`, `explanation`, `reusable: false` sobre el placeholder del logo de NASA); purga de entradas vencidas en el `Map` `hits` de [`server/api.mjs`](../server/api.mjs); escape HTML + manejo de errores en [`public/index.html`](../public/index.html); corrección `docs/IA.md` -> `docs/ia/PROMPTS.md` en [`scripts/ingest.mjs`](../scripts/ingest.mjs); ajuste de subtítulo en [`roblox-blender/game/src/client/Hud.luau`](../roblox-blender/game/src/client/Hud.luau) (`"7 pasos · recomendado"`).
  - **`e6828bd`** — Sincronización completa de [`README.md`](../README.md), [`docs/API-LOCAL.md`](API-LOCAL.md), [`docs/PENDIENTES-MANUALES.md`](PENDIENTES-MANUALES.md), [`docs/PLAN-JUEGO-Y-DATOS.md`](PLAN-JUEGO-Y-DATOS.md), [`content/cards.json`](../content/cards.json), [`roblox-blender/docs/NASA_APIS.md`](../roblox-blender/docs/NASA_APIS.md) y [`roblox-blender/docs/DECISIONES.md`](../roblox-blender/docs/DECISIONES.md) + creación de [`docs/ia/REGISTRO.md`](ia/REGISTRO.md).
  - **Commit documental para Claude:** agrega [`CLAUDE.md`](../CLAUDE.md), [`roblox-blender/CLAUDE.md`](../roblox-blender/CLAUDE.md) y este traspaso (`docs/HANDOFF-CLAUDE.md`).
- **Pendiente de Git:** revisar y fusionar `audit/actualizacion-completa` en `main` mediante PR en GitHub (<https://github.com/Jaacern/Nasa_Space_App_2026/pull/new/audit/actualizacion-completa>), o seguir trabajando directamente en esta rama.
- **Nota de plataforma:** `.env` NO existe ni debe subirse al repo. La configuración local de usuario Git no se modificó (`git config user.name/email` globales vacíos en esta máquina; si hace falta, configurar identidad local/global).

---

## 2. Inventario técnico verificado

### 2.1 Subproyecto raíz: `Outpost Run` (Node `>=22.9`, ESM sin dependencias)

- **Scripts en [`package.json`](../package.json):** `api`, `ingest`, `check`, `check:live`, `test`.
- **Catálogo (`src/api/catalog.mjs`):** `8` fuentes declaradas (`donki`, `radlab`, `osdr`, `mars-trek`, `rover-photos`, `apod`, `insight`, `csa`).
- **API local (`server/api.mjs`, `127.0.0.1:8787`):**
  - `13` rutas `GET` (`/api/catalog`, `/api/health`, `/api/space-weather`, `/api/scenarios`, `/api/scenarios/:id`, `/api/radiation`, `/api/osdr`, `/api/mars-layers`, `/api/mars-weather`, `/api/rover-photos`, `/api/apod`, `/api/csa`, `/api/manifest`) + archivos estáticos para `/src/`, `/data/curated/`, `/content/`, `/public/`.
  - Limitador de `120` req/min por IP en memoria con purga al superar `256` entradas.
  - Respuestas saneadas vía `src/api/sanitize.mjs` (`redact`, `cleanText`, `num`, `isoDate`, `isoTime`, `safeUrl`, `validate`, `assertValid`, `findSecretLeaks`).
- **Snapshots (`data/curated/`):** `9` archivos JSON + `manifest.json` (`2026-11-14T15:32:04.516Z`).
  - `7` fuentes en `ok`: DONKI (`104` eventos + `4` escenarios), RadLab (`4` sitios), OSDR (`26` estudios), Mars Trek (`1` capa WMTS), Rover Photos (`6` fotos vía `mars.nasa.gov`), InSight (`7` sols, `frozenArchive: true` 2020) y CSA (`64` enlaces).
  - `apod` falló en la última ingesta (`HTTP 500`); `apod.json` quedó como placeholder normalizado con `reusable: false`.
- **Capa de juego y contenido lista:** `src/data/worldState.mjs`, `content/balance.json`, `content/cards.json` (`6` cartas), `content/glossary.json` (`6` términos borrador), `public/index.html` (solo pantalla de prueba de API).
- **Qué NO existe aún en `Outpost Run`:** `src/sim/` (motor de 30 soles), `src/ui/` (interfaz real y pantalla de fuentes), archivo `LICENSE` y resúmenes infantiles revisados para OSDR (`26` estudios pendientes).

### 2.2 Subproyecto `roblox-blender/`: `ARES FORGE` (Roblox Studio + Blender 4.5)

- **Código Luau (`game/src/`):**
  - `shared/`: `Balance.luau`, `Content.luau`, `NasaData.luau` (verificado contra `data/curated/space_weather.json`: conteos `CME: 88, FLR: 13, GST: 1, SEP: 0, IPS: 2` y `7` eventos coinciden), `Visuals.luau` y `Meshes/` (`28` mallas exportadas desde Blender).
  - `server/`: `Main.server.luau`, `Session.luau`, `Combat.luau`, `Enemies.luau`, `Loot.luau`, `SaveService.luau` (`DataStore` `AresForgeMeta_v1`), `WorldBuilder.luau`.
  - `client/`: `Main.client.luau`, `Renderer.luau` (pooling), `MeshFactory.luau` (`EditableMesh` con `FixedSize = true` para evitar el límite de memoria a partir de la 9.ª submalla), `Scenery.luau`, `Fx.luau`, `Hud.luau` (subtítulo corregido a `"7 pasos · recomendado"`), `Ui.luau`.
- **Herramientas (`tools/`):**
  - `tools/blender/` (`ares_lib.py`, `build_assets.py`, `export_assets.py`) -> generan `.blend`, `28` `.fbx` en `assets/export/`, `28` previews `512x512` en `docs/assets/previews/` y `28` módulos en `game/src/shared/Meshes/`.
  - `tools/blender_mcp/` (`server.py`, `bridge_addon.py`, `selftest.py`, `config.json`) -> puente MCP local con token de 256 bits.
  - `tools/sync/sync_studio.luau` == `game/src/sync_studio.lua` (verificado por hash idéntico).
- **Observación del entorno Claude/MCP:** `roblox-blender/.mcp.json` y `tools/blender_mcp/config.json` contienen marcadores `<RUTA_...>`. El archivo `.claude/settings.json` mencionado en `BLENDER_PIPELINE.md` y `SEGURIDAD_MCP.md` **no está en Git**; si se crea en local, seguir el JSON de `docs/SEGURIDAD_MCP.md` sección 6a. El binario `assets/blend/ares_assets.blend` conserva internamente la ruta histórica de Blender `C:\Users\black\...` (propia del archivo binario).

---

## 3. Verificación registrada

Comprobado sobre el último estado de código:
- `npm test`: **`23/23` pasan** (`0` fallos, `0` omitidos).
- `npm run check`: **salida `0`** (`OK: 6 cartas, 6 términos, 9 snapshots, 8 fuentes.`), con los dos avisos esperados (`26 estudios OSDR sin resumen infantil revisado` y `apod.json marcado reusable: false`).
- `node --check`: **OK** en todos los `.mjs` (`src/`, `server/`, `scripts/`, `test/`).
- `python -B -m py_compile`: **OK** en los `6` archivos `.py` bajo `roblox-blender/tools/` (`Python 3.13.14`).

**No probado en esta sesión (requiere entorno local/vivo):**
- `npm run check:live` / `npm run ingest` (sin `.env` ni `NASA_API_KEY` rotada).
- Sincronización y ejecución en **Roblox Studio** tras editar `roblox-blender/game/src/client/Hud.luau:291`.

---

## 4. Hoja de ruta priorizada para continuar en Claude Code

### Prioridad `P0` — Arranque inmediato y seguridad
1. **Git:** revisar/fusionar `audit/actualizacion-completa` -> `main` (o continuar commiteando sobre `audit/actualizacion-completa`).
2. **Clave NASA (`P-04`):** rotar la clave expuesta anteriormente, crear `.env` a partir de `.env.example` y correr `npm run check:live` + `npm run ingest -- --only=apod`.
3. **Licencia:** crear `LICENSE` en raíz tras acuerdo del equipo.
4. **Si vas a usar MCPs en `ARES FORGE`:** abrir Claude Code dentro de `roblox-blender/`, activar *Enable Studio as MCP server* en Roblox Studio, completar rutas locales en `roblox-blender/.mcp.json` y `tools/blender_mcp/config.json` **sin subirlas a Git**, y re-sincronizar Studio con `http://127.0.0.1:8765/sync_studio.lua` para aplicar el ajuste de `Hud.luau`.

### Prioridad `P1` — Completar `Outpost Run` (Node/Web)
1. Construir `src/sim/` (bucle de 30 soles usando `scheduleEvents`, `siteProfile`, `commDelaySec` y `content/cards.json`) y `src/ui/` reemplazando el stub `public/index.html`.
2. Implementar la pantalla "De dónde vienen los datos" con `attributionLines()`, fechas de snapshot y aviso de no patrocinio NASA/CSA.
3. Curar manualmente los estudios OSDR relevantes, generar resúmenes infantiles con [`docs/ia/PROMPTS.md`](ia/PROMPTS.md), revisar a mano poniendo `reviewedByHuman: true` (`26` pendientes) y anotarlo en [`docs/ia/REGISTRO.md`](ia/REGISTRO.md).
4. Elegir sitio marciano y capas WMTS en Mars Trek (`scripts/ingest.mjs` -> `MARS_LAYERS`), validar física de `content/balance.json`, completar `content/glossary.json`, revisar términos de licencia CSA, probar en navegador real y testear con niños de 7–12 años.

### Prioridad `P2` — Cerrar `ARES FORGE` (`roblox-blender/`)
Lista completa con dueños en [`roblox-blender/docs/DECISIONES.md`](../roblox-blender/docs/DECISIONES.md#L131-L153):
1. **Studio y publicación:** `P-01` fijar `Lighting.Technology = Future`; `P-02` guardar y publicar lugar; `P-03` comprobar `DataStore` (`AresForgeMeta_v1`) en lugar publicado.
2. **Rendimiento y UX:** `P-05` medir FPS reales en primer plano (sin capado de 15 FPS en segundo plano, usando `Balance.Debug.LogPerf` si conviene); `P-11` probar en móvil real (`30 FPS`, botones >= `44 px`); `P-10` medir sacudida de cámara vs límite `4 px`; evaluar tipografía de daño en `Fx.luau` (`GothamBlack`).
3. **Balance y contenido:** `F5` correr y registrar `5` partidas de prueba (`0/5` en `BALANCE_V0.md`); `P-08` definir alcance `Q10`; `P-06` verificar fichas NTRS para antena y generador de oxígeno; `P-07` decidir proxy en vivo vs snapshot; `P-15` alinear nombres de biomas en prompts; agregar consejo de "kitear" a `Content.Tutorial`.
4. **Audio, demo y concurso:** `P-12` producir `3` pistas musicales (`Balance.Audio.Music`) + SFX propios; `P-14` confirmar reglas y fecha oficiales del concurso; `P-13` lograr `3` ensayos seguidos sin fallos (`DEMO_GUION.md`) y grabar video respaldo + tráiler (`TRAILER.md`).
