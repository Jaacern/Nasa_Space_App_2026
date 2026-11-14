# Assets de ARES FORGE

Fecha: 14-11-2026.
Estados: **Hecho** (listo para la v1), **Provisional** (funciona y se reemplazará), **Pendiente** (no existe).
El catálogo de modelos de Blender lo escribe otra persona del equipo: `docs/assets/CATALOGO_BLENDER.md`. Este documento no lo duplica.

## 1. Modelos 3D

Los 28 modelos low-poly facetados de Blender están integrados en el cliente con `EditableMesh` (`game/src/client/MeshFactory.luau` + `game/src/shared/Meshes/<nombre>.luau`), con respaldo automático en `ReplicatedStorage/Templates` (`game/src/shared/Visuals.luau`). Además se exportan los FBX en `assets/export/` y el catálogo detallado vive en `docs/assets/CATALOGO_BLENDER.md`.

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| Héroe (casco `Helmet` y mochila `Backpack`) | Hecho | `game/src/shared/Meshes/`, montados en `Scenery.luau` | Reemplazan las piezas provisionales de `WorldBuilder.dress`; conservan el anillo cian bajo los pies |
| Remolino de polvo (`chaser`) | Hecho | `game/src/shared/Meshes/chaser.luau` | 398 tris; respaldo en `Visuals.luau` |
| Gólem de regolito (`tank`) | Hecho | `game/src/shared/Meshes/tank.luau` | 480 tris; respaldo en `Visuals.luau` |
| Centinela iónico (`ranged`) | Hecho | `game/src/shared/Meshes/ranged.luau` | 168 tris; respaldo en `Visuals.luau` |
| Meteoroide inestable (`kamikaze`) | Hecho | `game/src/shared/Meshes/kamikaze.luau` | 344 tris; respaldo en `Visuals.luau` |
| Élites `elite1`, `elite2`, `elite3` | Hecho | `game/src/shared/Meshes/elite1..3.luau` | Formas propias (708, 500 y 324 tris) |
| Jefes `boss1`, `boss2`, `boss3`, `final` | Hecho | `game/src/shared/Meshes/boss1..3.luau`, `final.luau` | 1328, 848, 508 y 824 tris |
| Proyectil del héroe (`shot`) | Hecho | `game/src/shared/Meshes/shot.luau` | 36 tris; rayo cian |
| Proyectil enemigo (`eshot`) | Hecho | `game/src/shared/Meshes/eshot.luau` | 144 tris; núcleo magenta |
| Dron orbital (`drone`) | Hecho | `game/src/shared/Meshes/drone.luau` | 268 tris |
| Muestra de XP (`gem`) | Hecho | `game/src/shared/Meshes/gem.luau` | 60 tris |
| Cofre (`chest`) | Hecho | `game/src/shared/Meshes/chest.luau` | 60 tris; con flecha de guía en el HUD |
| Nave estrellada (`Ship`) | Hecho | `game/src/shared/Meshes/Ship.luau` y `Scenery.luau` | 760 tris; anclajes `MOUNTS` para `Piece1..4` |
| Pieza 1: MMRTG (`Piece1`) | Hecho | `game/src/shared/Meshes/Piece1.luau` | 216 tris |
| Pieza 2: antena de alta ganancia (`Piece2`) | Hecho | `game/src/shared/Meshes/Piece2.luau` | 432 tris |
| Pieza 3: generador de oxígeno (`Piece3`) | Hecho | `game/src/shared/Meshes/Piece3.luau` | 128 tris |
| Pieza 4: propulsor de retorno (`Piece4`) | Hecho | `game/src/shared/Meshes/Piece4.luau` | 560 tris |
| Pipeline Blender (28 modelos, previews PNG y catálogo) | Hecho | `tools/blender/`, `assets/blend/ares_assets.blend`, `docs/assets/previews/` | Ver `docs/assets/CATALOGO_BLENDER.md` (28/28 PASS) |
| FBX exportados | Hecho | `assets/export/*.fbx` | 28 archivos FBX del flujo clásico (no se suben a Roblox) |

Plantillas en tiempo de ejecución: `ReplicatedStorage/Templates` (creadas por `WorldBuilder.build()`).

## 2. Escenario y luz

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| Arena circular (suelo, muros invisibles) | Hecho | `game/src/server/WorldBuilder.luau` | Radio 210 (`Balance.Sim.ArenaRadius`) |
| Cráteres, rocas y sierra del horizonte | Hecho | `game/src/client/Scenery.luau` + `WorldBuilder.luau` | Cráteres (`WorldBuilder`) + mallas Blender `RockA/B/C` y `RidgeA/B` instanciadas con semilla 2026 (`ClientDecor`) |
| 3 biomas (color de suelo, atmósfera, hora, brillo) | Hecho | `game/src/client/Main.client.luau`, tabla `BIOMES` | Cambian con una transición de 3 s |
| Atmósfera, Bloom y ColorCorrection | Hecho | `game/src/server/WorldBuilder.luau` | Bloom se apaga con efectos bajos |
| `Lighting.Technology = Future` | Pendiente | Studio, ajuste manual | Un script no puede cambiarlo (P-01) |
| Terreno y props de escenario en Blender | Hecho | `game/src/shared/Meshes/RockA..C.luau`, `RidgeA..B.luau` | Incluidos en `CATALOGO_BLENDER.md` e integrados en `Scenery.luau` |

## 3. Efectos (FX)

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| Números de daño con pooling | Hecho | `game/src/client/Fx.luau` | Usan la fuente `GothamBlack`, fuera del sistema tipográfico |
| Partículas de chispas y muerte | Hecho | `game/src/client/Fx.luau` | `ParticleEmitter` con modo de efectos bajos |
| Sacudida de cámara, hitstop y destello | Hecho | `game/src/client/Fx.luau`, `game/src/client/Renderer.luau` | Valores en `Balance.Juice` |
| Avisos de ataque en el suelo (círculos y líneas naranjas) | Hecho | `game/src/client/Renderer.luau` | Con pooling |
| Despegue de la nave en la victoria | Hecho | `game/src/client/Renderer.luau` | Cinemática de 5,5 s |
| Efecto de piezas recuperadas en la nave | Hecho | `game/src/client/Renderer.luau` | |
| Efectos de habilidad (Impulso RCS y Pulso) | Provisional | `game/src/client/Renderer.luau` | Mejorar en F5 |

## 4. Interfaz

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| Sistema "Dark Telemetry" (colores y paneles) | Hecho | `game/src/client/Ui.luau` | `#070B14`, `#0B132B`, `#00B4D8`, `#00D2FF`, `#FF6B35` |
| Tipografías Michroma, Titillium Web y Roboto Mono | Hecho | `game/src/client/Ui.luau` | Incluidas en Roblox. Sustituyen a Bahnschrift, Satoshi y Space Mono |
| Menú, ajustes, créditos y fuentes | Hecho | `game/src/client/Hud.luau` | Ajustes: FOV, sensibilidad y efectos |
| HUD de misión (vida, XP, oleada, bioma, jefe, telemetría) | Hecho | `game/src/client/Hud.luau` | |
| Cartas de subida de nivel (1 de 3, con rareza) | Hecho | `game/src/client/Hud.luau` | Teclas 1, 2 y 3 |
| Panel "Pieza recuperada" con texto "En la realidad" | Hecho | `game/src/client/Hud.luau` | Textos en `game/src/shared/Content.luau` |
| Informe de misión (victoria y derrota) | Hecho | `game/src/client/Hud.luau` | |
| Tutorial guiado (7 pasos y práctica) | Hecho | `game/src/client/Hud.luau`, `Content.Tutorial` | |
| Iconos de habilidades, objetos y cartas | Pendiente | | El HUD usa texto corto (RCS, PULSO) |
| Prueba de interfaz en móvil real | Pendiente | | Botones de 44 px o más (P-11) |
| Pantalla de créditos con fecha de cada copia NASA | Hecho | `game/src/shared/Content.luau` | Incluye la frase obligatoria |

## 5. Audio

La tabla de sonidos está en `game/src/shared/Balance.luau`, grupo `Audio`, y su documentación vive en `docs/assets/AUDIO.md`.

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| Efectos: `shoot`, `hit`, `kill`, `boom`, `hurt`, `gem`, `level`, `chest`, `ui`, `skill`, `warn` | Provisional | `Balance.Audio.Sfx` | Sonidos integrados de Roblox (`rbxasset://sounds/...`). Variación de tono ±5 % |
| Música calma, combate y jefe (3 capas por intensidad) | Pendiente | `Balance.Audio.Music` | Hay 3 ranuras con Id vacío; en silencio. La mezcla por intensidad está en `Fx.setMusic` |
| Efectos propios (disparo, explosión, pieza recuperada) | Pendiente | | |

## 6. Datos de NASA en el juego

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| Copia local de DONKI (clima espacial) | Hecho | `game/src/shared/NasaData.luau` | Capturada el 14-11-2026. Ventana: 15-10-2026 a 14-11-2026. Modo `snapshot` |
| Textos "En la realidad" de las 4 piezas | Hecho | `game/src/shared/Content.luau` | Sin cifras |
| Referencia NTRS 20150005587 (MMRTG) | Hecho | `Content.Pieces[1]` | Verificada |
| Referencia NTRS 20240003648 (propulsión de Orion) | Hecho | `Content.Pieces[4]` | Verificada |
| Referencia NTRS de antena y generador de oxígeno | Pendiente | `Content.Pieces[2]` y `[3]` | `[PENDIENTE]` (P-06) |
| Llamada en vivo a NASA | Pendiente | | Exige HttpService y un proxy (P-07) |

## 7. Herramientas y archivos de apoyo

| Asset | Estado | Dónde vive |
|---|---|---|
| Sincronizador disco a Studio | Hecho | `tools/sync/sync_studio.luau` y `game/src/sync_studio.lua` |
| Puente de Blender (código propio) | Hecho | `tools/blender_mcp/` |
| Scripts de modelado y exportación de Blender | Hecho | `tools/blender/` (`ares_lib.py`, `build_assets.py`, `export_assets.py`) |
| Mediciones de rendimiento en Studio | Hecho | `docs/perf/RENDIMIENTO.md` (PC Studio; móvil pendiente) |
