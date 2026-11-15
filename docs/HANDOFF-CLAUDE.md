# Handoff completo para continuar en Claude Code

Última actualización: `15-11-2026` · Rama activa de juego y auditoría: `audit/actualizacion-completa` (origin: `https://github.com/Jaacern/Nasa_Space_App_2026.git`). Repo Git restaurado y sincronizado sobre `origin/audit/actualizacion-completa`.

Este documento resume el estado real auditado, todos los cambios ya aplicados y verificados, el mapa técnico de ambos subproyectos y la lista exacta de tareas pendientes para continuar sin perder contexto.

---

## 1. Estado de Git y estructura actual

- **Relación de ramas en `origin` (`https://github.com/Jaacern/Nasa_Space_App_2026.git`):**
  - **`main` (`fe0e2fa`):** divergió desde `c203130` con `4` commits del colaborador `@jaacern` (`08d3ece`, `e5414fb`, `1ba9836`, `fe0e2fa`) dedicados al pitch web 3D (`public/`, `ui-ux/`, `landing-template-itom/`). No reescribir ni hacer force-push sobre `main`.
  - **`audit/actualizacion-completa`:** concentra toda la consolidación técnica de **ARES FORGE** (`roblox-blender/`), el cierre de seguridad sin secretos/rutas locales y las pruebas de la capa NASA de `Outpost Run`.
- **Commits clave en `audit/actualizacion-completa`:**
  - **`ffa4b7e`** — Limpieza de los `8` archivos/carpetas duplicados añadidos en raíz por `c203130` (`.mcp.json` y `BLENDER_PIPELINE.md` con rutas locales, `MEGA_CONTEXTO_MIS_SKILLS.md` y copias duplicadas de `roblox-blender/`) + `__pycache__/` y `*.pyc` en [`.gitignore`](../.gitignore).
  - **`84cb466`** — Exportación de `APOD_SCHEMA`, validación en `scripts/check.mjs`, normalización de `apod.json` (`reusable: false`), purga del `Map` de rate-limit en `server/api.mjs` y escape HTML en `public/index.html`.
  - **`e6828bd` .. `3d59475` .. `554a91e`** — Sincronización de documentación, traspaso `CLAUDE.md`/`HANDOFF-CLAUDE.md`, `Rover` + `Insignia` (`30` mallas), fichas NTRS verificadas, lugar en la nube «Núcleo de Ares» (`placeId: 114817072312952`), retroceso de cámara y revisión inicial de menú.
  - **`2fea3be`** — Documentación del agente opcional DeepSeek en `AGENTS.md`.
  - **`5388d5c`** — Menú principal «Forma humana» en `Hud.luau` y sección `10` de `NOTAS.md`.
  - **Actualización `15-11-2026` (commit actual):** restauración del repo `.git` en esta máquina sobre `audit/actualizacion-completa`, limpieza de duplicados residuales en raíz, octava tanda en `Content.luau`/`Ui.luau`/`Hud.luau`/`Main.client.luau` (tipografía `Bangers`/`Michroma`, paleta por sección/bioma, movimiento con flechas `↑ ↓ ← →`, `TextIssuesCount = 0`, versión `29` guardada en Studio) y unificación de documentación para colaboradores.
- **Pendiente de Git:** mantener el desarrollo de `ARES FORGE` e interfaz Roblox sobre `audit/actualizacion-completa` y coordinar en equipo cuándo integrar `audit/actualizacion-completa` y `main`.
- **Nota de seguridad:** `.env` NO existe ni debe subirse al repo. La identidad local del repo quedó configurada para `audit/actualizacion-completa`; cualquier marcador `<RUTA_...>` de MCP se rellena solo en local sin commitear.

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

> La fuente de verdad del juego vive exclusivamente en `roblox-blender/game/src/` (las copias duplicadas heredadas en raíz se eliminaron para evitar divergencias).

- **Código Luau (`roblox-blender/game/src/`):**
  - `shared/`: `Balance.luau`, `Content.luau` (`4/4` piezas con NTRS verificadas: `20150005587`, `20040084278`, `20205007222`, `20240003648`; tutorial/controles actualizados con `WASD / Flechas`), `NasaData.luau`, `Visuals.luau` y `Meshes/` (`30` mallas exportadas desde Blender, incluidas `Rover.luau` e `Insignia.luau`).
  - `server/`: `Main.server.luau`, `Session.luau`, `Combat.luau`, `Enemies.luau`, `Loot.luau`, `SaveService.luau` (`DataStore` `AresForgeMeta_v1`), `WorldBuilder.luau`.
  - `client/`: `Main.client.luau` (cámara orbital + `ContextActionService` `AresArrowKeys` para movimiento 8-direccional con flechas), `Renderer.luau` (pooling, retroceso e inclinación de enemigos y destello de boca), `MeshFactory.luau` (`EditableMesh` `FixedSize = true`), `Scenery.luau` (Fobos/Deimos, Rover e Insignia), `Fx.luau` (`Enum.Font.Bangers`, `AresSfx`, `AresMusic` y retroceso de cámara), `Hud.luau` (estética «Forma humana», fuente `Bangers` + colores por bioma/función, recuadro de controles, `TextFits` OK), `Ui.luau` (`TagColor` en paneles y variantes `violet`/`green` en botones).
- **Audio (`Balance.Audio`):** `3` pistas con licencia del catálogo de Roblox (`calm`, `combat`, `boss`) y `12` claves SFX con EQ (`AresSfx`); pendiente de validación por escucha humana (`P-12`).
- **Herramientas (`roblox-blender/tools/`):**
  - `tools/blender/` (`ares_lib.py`, `build_assets.py`, `export_assets.py`) -> generan `.blend`, `30` `.fbx` en `assets/export/`, `30` previews `512x512` en `docs/assets/previews/` y `30` módulos en `game/src/shared/Meshes/`.
  - `tools/studio/` (`push.py` y `README.md`) -> sincronización directa hacia el lugar guardado en la nube (`placeId: 114817072312952`) sin servidor HTTP local.
  - `tools/blender_mcp/` (`server.py`, `bridge_addon.py`, `selftest.py`, `config.json`) -> puente MCP local con marcadores `<RUTA_...>`.
  - `tools/sync/sync_studio.luau` == `game/src/sync_studio.lua` (reservado a lugares locales sin nube).
- **Estado en Roblox Studio (`15-11-2026`):** lugar guardado en nube como «Núcleo de Ares» (`placeId: 114817072312952`, `universeId: 10776867729`, versión `29` sin publicar), con *Allow Mesh / Image APIs* y *Enable Studio Access to API Services* activos. Verificado en `Play`: `30` mallas cargan, `AresArrowKeys` enlazado, `0` recortes `TextFits` y consola limpia. `inspect_instance` sobre `game.Lighting` mostró `RBX_OriginalTechnologyOnFileLoad = 3` (`ShadowMap`) con migración Unified Lighting, quedando `P-01` (`Future`) para revisión manual.
- Actualización 15-11-2026 (tarde): pulido de interfaz (textos cortos, tamaño mínimo de letra 12, HUD oculto con paneles abiertos, bono de zona en el panel del traje), demo de pitch de 2 minutos, y arreglos de pausa en cliente, checkpoints, guardado coalescido y avisos. Verificado en Play con bot: victoria en 95 s de juego, consola limpia. Lugar guardado en versión 29.
- **Observación del entorno MCP:** `roblox-blender/.mcp.json` y `tools/blender_mcp/config.json` contienen marcadores `<RUTA_...>`. El archivo `.claude/settings.json` mencionado en `BLENDER_PIPELINE.md` y `SEGURIDAD_MCP.md` no está en Git; si se crea en local, seguir `docs/SEGURIDAD_MCP.md` sección 6a.

---

## 3. Verificación registrada

Comprobado sobre el último estado de código:
- `npm test`: **`23/23` pasan** (`0` fallos, `0` omitidos).
- `npm run check`: **salida `0`** (`OK: 6 cartas, 6 términos, 9 snapshots, 8 fuentes.`), con los dos avisos esperados (`26 estudios OSDR sin resumen infantil revisado` y `apod.json marcado reusable: false`).
- `node --check`: **OK** en todos los `.mjs` (`src/`, `server/`, `scripts/`, `test/`).
- `python -B -m py_compile`: **OK** en los `6` archivos `.py` bajo `roblox-blender/tools/` (`Python 3.13.14`).

**Verificado en Roblox Studio (`15-11-2026`, `placeId: 114817072312952`):**
- Sincronización exacta (misma longitud LF y `Adler-32`) entre `roblox-blender/game/src/` y Studio para `Content`, `Ui`, `Hud` y `Main`.
- Arranque y demo lanzada en `Play`: `30/30` mallas, acción `AresArrowKeys` activa, `0` recortes `TextFits`, consola limpia y lugar guardado con `save_place` (versión `29`, sin publicar).

**No probado / pendiente:**
- `npm run check:live` / `npm run ingest` (sin `.env` ni `NASA_API_KEY` rotada).
- Móvil real y prueba a 60 FPS en primer plano sin capado en segundo plano.
- Escucha humana del audio definitivo (`P-12`) y revisión manual de `Lighting.Technology = Future` (`P-01`).
- Móvil y mando reales tras el pulido (solo probado en ventana de Studio 812×473).

---

## 4. Hoja de ruta priorizada para continuar en Claude Code

### Prioridad `P0` — Arranque inmediato y seguridad
1. **Git:** revisar/fusionar `audit/actualizacion-completa` -> `main` (o continuar commiteando sobre `audit/actualizacion-completa`).
2. **Clave NASA (`P-04`):** rotar la clave expuesta anteriormente, crear `.env` a partir de `.env.example` y correr `npm run check:live` + `npm run ingest -- --only=apod`.
3. **Licencia:** crear `LICENSE` en raíz tras acuerdo del equipo.
4. **Si vas a trabajar con `ARES FORGE`:** abrir el lugar guardado en la nube («Núcleo de Ares», `placeId: 114817072312952`), usar herramientas MCP de Roblox Studio o `roblox-blender/tools/studio/push.py` tras editar en `roblox-blender/game/src/` (sin rutas locales en archivos versionados) y guardar con `save_place` sin publicar salvo pedido explícito del equipo.

### Prioridad `P1` — Completar `Outpost Run` (Node/Web)
1. Construir `src/sim/` (bucle de 30 soles usando `scheduleEvents`, `siteProfile`, `commDelaySec` y `content/cards.json`) y `src/ui/` reemplazando el stub `public/index.html`.
2. Implementar la pantalla "De dónde vienen los datos" con `attributionLines()`, fechas de snapshot y aviso de no patrocinio NASA/CSA.
3. Curar manualmente los estudios OSDR relevantes, generar resúmenes infantiles con [`docs/ia/PROMPTS.md`](ia/PROMPTS.md), revisar a mano poniendo `reviewedByHuman: true` (`26` pendientes) y anotarlo en [`docs/ia/REGISTRO.md`](ia/REGISTRO.md).
4. Elegir sitio marciano y capas WMTS en Mars Trek (`scripts/ingest.mjs` -> `MARS_LAYERS`), validar física de `content/balance.json`, completar `content/glossary.json`, revisar términos de licencia CSA, probar en navegador real y testear con niños de 7–12 años.

### Prioridad `P2` — Cerrar `ARES FORGE` (`roblox-blender/`)
Lista completa con dueños en [`roblox-blender/docs/DECISIONES.md`](../roblox-blender/docs/DECISIONES.md):
1. **Studio y publicación:** `P-01` revisar y fijar manualmente `Lighting.Technology = Future` (en inspección MCP figura `ShadowMap = 3` con Unified Lighting); `P-02` publicar el lugar cuando el equipo lo pida (ya guardado en nube `placeId: 114817072312952` v29); `P-03` comprobar `DataStore` (`AresForgeMeta_v1`) en servidor publicado.
2. **Rendimiento y UX:** `P-05` medir FPS reales en primer plano (sin capado de 15 FPS en segundo plano); `P-11` probar en móvil real (`30 FPS`, botones >= `44 px`); `P-10` medir sacudida de cámara vs límite `4 px`.
3. **Balance y contenido:** `F5` correr y registrar `5` partidas de prueba (`0/5` en `BALANCE_V0.md`); `P-08` definir alcance `Q10`; `P-07` decidir proxy en vivo vs snapshot; `P-15` alinear nombres de biomas en prompts; agregar consejo de "kitear" a `Content.Tutorial`. (`P-06` de 4 fichas NTRS y unificación de `Bangers` en `Fx.luau` + HUD/menús ya completos.)
4. **Audio, demo y concurso:** `P-12` validar por escucha humana las `3` pistas con licencia (`Balance.Audio.Music`) y los `12` SFX con EQ en `AresSfx`; `P-14` confirmar reglas y fecha oficiales del concurso; `P-13` lograr `3` ensayos seguidos sin fallos (`DEMO_GUION.md`) y grabar video respaldo + tráiler (`TRAILER_BRIEF_FABLE.md`).
