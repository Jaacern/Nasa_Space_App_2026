# Assets de ARES FORGE

Fecha: 15-11-2026.
Estados: **Hecho** (listo para la v1), **Provisional** (funciona y se reemplazará), **Pendiente** (no existe).
El catálogo de modelos de Blender lo escribe otra persona del equipo: `docs/assets/CATALOGO_BLENDER.md`. Este documento no lo duplica.

## 1. Modelos 3D

Los 30 modelos low-poly facetados de Blender (`28` base + `Rover` + `Insignia`) están integrados en el cliente con `EditableMesh` (`game/src/client/MeshFactory.luau` + `game/src/shared/Meshes/<nombre>.luau`), con respaldo automático en `ReplicatedStorage/Templates` (`game/src/shared/Visuals.luau`). Además hay `30` FBX en `assets/export/`, `30` renders `512x512` en `docs/assets/previews/` y el catálogo detallado vive en `docs/assets/CATALOGO_BLENDER.md`.

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
| Rover Perseverance (`Rover`) | Hecho (carga verificada en Studio el 15-11-2026) | `game/src/shared/Meshes/Rover.luau`, colocado por `Scenery.luau` (`refreshRover`) | 800 tris, 4 materiales. Hito visual fuera del borde jugable. Modelado propio con medidas del GLB oficial; ver `docs/assets/NASA_ROVER.md` |
| Pipeline Blender (30 modelos, previews PNG y catálogo) | Hecho | `tools/blender/`, `assets/blend/ares_assets.blend`, `docs/assets/previews/` | 30 módulos `.luau` y 30 renders PNG; ver `docs/assets/CATALOGO_BLENDER.md` |
| FBX exportados | Hecho | `assets/export/*.fbx` | 30 archivos FBX (no se suben a Roblox) |

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
| Números de daño con pooling | Hecho | `game/src/client/Fx.luau` | Usan `Enum.Font.Bangers` (`Ui.Fonts.impact`), alineados con el HUD |
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
| Tipografías Michroma, Bangers, Titillium Web y Roboto Mono | Hecho | `game/src/client/Ui.luau`, `Hud.luau`, `Fx.luau` | Incluidas en Roblox. Sustituyen a Bahnschrift, Satoshi y Space Mono |
| Menú («Forma humana»), hangar, ajustes y controles, créditos | Hecho | `game/src/client/Hud.luau` | Botones con chip `01..06` y color por sección; ajustes de FOV, sensibilidad y efectos bajos + recuadro `WASD / Flechas ↑↓←→` |
| HUD de misión (vida, XP, `ETAPA 1..3`, oleada, jefe, telemetría) | Hecho | `game/src/client/Hud.luau` | Colores por bioma y cabeceras `Bangers` |
| Cartas de subida de nivel (1 de 3, con rareza y «DATO REAL») | Hecho | `game/src/client/Hud.luau` | Teclas 1, 2 y 3; título con color de rareza |
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
| Efectos: 12 claves (`shoot` … `warn`, más `buff`) | Hecho (falta escucha humana) | `Balance.Audio.Sfx` | Catálogo con licencia de Roblox e integrados. Grupo `AresSfx` con ecualizador suave |
| Música calma, combate y jefe | Hecho (falta escucha humana) | `Balance.Audio.Music` | Una pista a la vez con fundido. Grupo `AresMusic` |

## 6. Datos de NASA en el juego

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| Copia local de DONKI (clima espacial) | Hecho | `game/src/shared/NasaData.luau` | Capturada el 14-11-2026. Ventana: 15-10-2026 a 14-11-2026. Modo `snapshot` |
| Textos "En la realidad" de las 4 piezas | Hecho | `game/src/shared/Content.luau` | Sin cifras |
| Referencia NTRS 20150005587 (MMRTG) | Hecho | `Content.Pieces[1]` | Verificada |
| Referencia NTRS 20040084278 (antena de alta ganancia MER) | Hecho | `Content.Pieces[2]` | Verificada en `ntrs.nasa.gov` |
| Referencia NTRS 20205007222 (generador de oxígeno MOXIE) | Hecho | `Content.Pieces[3]` | Verificada en `ntrs.nasa.gov` |
| Referencia NTRS 20240003648 (propulsión de Orion) | Hecho | `Content.Pieces[4]` | Verificada |
| Llamada en vivo a NASA | Pendiente | | Exige HttpService y un proxy (P-07) |

## 7. Herramientas y archivos de apoyo

| Asset | Estado | Dónde vive |
|---|---|---|
| Sincronizador disco a Studio | Hecho | `tools/sync/sync_studio.luau` y `game/src/sync_studio.lua` |
| Puente de Blender (código propio) | Hecho | `tools/blender_mcp/` |
| Scripts de modelado y exportación de Blender | Hecho | `tools/blender/` (`ares_lib.py`, `build_assets.py`, `export_assets.py`) |
| Mediciones de rendimiento en Studio | Hecho | `docs/perf/RENDIMIENTO.md` (PC Studio; móvil pendiente) |

## 8. Añadidos del 15-11-2026

| Asset | Estado | Dónde vive | Notas |
|---|---|---|---|
| `Insignia` (asset 30) | Hecho | `tools/blender/build_assets.py` (`build_Insignia`), `Meshes/Insignia.luau` | Insignia NASA extruida desde `assets/src/nasa/NASA_logo.svg`, 6028 tris. Gira a 0,3 rad/s sobre la nave solo en el menú (`Scenery.setMenu`, `INSIGNIA_HEIGHT = 29`). Se apaga con `Balance.Branding.NasaInsignia = false` |
| Lunas Fobos y Deimos | Hecho | `client/Scenery.luau` (`refreshMoons`) | Reutilizan `RockB` y `RockC` a gran escala en el cielo |
| Equipo visible | Hecho | `client/Scenery.luau` (`buildGear`, `Scenery.gear`) | Cada mejora elegida añade piezas `Gear_<id>` al personaje: blaster, damage, rate, multishot, pierce, armor, speed, magnet, cooldown, crit, aura |
| Estímulos de nivel y mejora | Hecho | `client/Hud.luau` (`Hud.levelFlash`, `Hud.buff`), `client/Fx.luau` (`Fx.celebrate`) | Destello cian, rótulo «¡NIVEL N!» en fuente Bangers y cartel «MEJORA ACTIVA» |
| Color y cielo | Hecho | `server/WorldBuilder.luau` | Contraste 0,17, saturación 0,26, rayos de sol suaves, cielo ocre |
