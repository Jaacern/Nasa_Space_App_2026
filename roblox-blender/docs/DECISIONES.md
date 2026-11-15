# Decisiones de ARES FORGE

Última actualización: 15-11-2026.
Fuente de las decisiones Q1 a Q20: `PROMPT_FABLE_PARA_PEGAR_v3.md`, sección 3.
Fuente de los números: `game/src/shared/Balance.luau`.

## 1. Decisiones Q1 a Q20 (prompt maestro v3)

La columna "Estado en el código" compara cada decisión con el juego real del 15-11-2026. Las desviaciones se explican en la sección 2.

| # | Tema | Decisión (tal como figura en el prompt maestro) | Estado en el código |
|---|---|---|---|
| Q1 | Plataformas | PC y móvil | Entrada táctil y de ratón en `game/src/client/Main.client.luau`. Móvil real sin probar |
| Q2 | Jugadores por partida | Un jugador. El cooperativo queda fuera de la v1 | Cumple. Una sesión independiente por jugador (`game/src/server/Session.luau`) |
| Q3 | Cámara | Cenital 3/4 | **Desviación D-03:** ahora es tercera persona con cámara orbital libre |
| Q4 | Duración de partida | 15 a 25 minutos | Misión completa: 18 oleadas de 60 s = 18 min. Demo rápida: unos 3,6 min |
| Q5 | Progresión dentro de la partida | XP, mejoras al subir de nivel y objetos de cofres | Cumple. Cartas 1 de 3 y 15 objetos de cofre |
| Q6 | Ataques | Automático, más 1 o 2 habilidades activas | Cumple. Impulso RCS (Q) y Pulso de escudo (E) |
| Q7 | Enemigos simultáneos | 50 a 100 | Tope de 100 (`Balance.Sim.MaxEnemies`). Rendimiento con 100 sin medir |
| Q8 | Jefes | Un mini-jefe cada 5 minutos y un jefe final | **Desviación (ver sección 3):** minijefes a los 4, 9 y 14 minutos de misión; jefe final a los 17 |
| Q9 | Escenarios en la v1 | 3 biomas | Cumple. 3 biomas que cambian en 6:00 y 12:00 |
| Q10 | Meta-progresión | Héroes y objetos que se desbloquean entre partidas | **Desviación (ver P-08):** hay 1 héroe y 8 mejoras permanentes; no hay desbloqueo de héroes ni de objetos |
| Q11 | Tema | Espacio NASA, con referencias NTRS verificadas (sección 12) | Cumple. Cuatro fichas NTRS verificadas en uso (`Content.Pieces[1..4]`: `20150005587`, `20040084278`, `20205007222`, `20240003648`). Ver `docs/NASA_APIS.md` |
| Q12 | Estilo visual | 3D estilizado tipo Risk of Rain 2 | 30 mallas Blender integradas en Studio mediante `EditableMesh` (`FixedSize = true`, ver D-11 y D-13) |
| Q13 | Paleta | Oscura con acentos saturados por función | Cumple. Jugador cian, enemigos rojo o magenta, recompensas doradas, peligro naranja (`game/src/shared/Visuals.luau`) |
| Q14 | Reparto Blender / Roblox | Blender: personajes, jefes y props. Roblox: escenario, luz, interfaz y efectos | Cumple. 30 modelos Blender exportados e integrados en cliente (`docs/ASSETS.md`, D-11) |
| Q15 | Rendimiento | 60 FPS en PC, 30 FPS en móvil | **Sin medir a 60 FPS.** Sondeo inicial en `docs/perf/RENDIMIENTO.md` capado a 15 FPS en segundo plano (P-05) |
| Q16 | Audio | Música por intensidad con 3 capas | `Balance.Audio.Music` tiene 3 pistas del catálogo con licencia (`calm`, `combat`, `boss`) y `Balance.Audio.Sfx` 12 claves en `AresSfx`; falta escucha humana (P-12) |
| Q17 | Interfaz | Estilo telemetría NASA, con iconos grandes | Cumple. Sistema "Dark Telemetry" (D-09) |
| Q18 | Impacto visual y sonoro (juice) | Alto | Hitstop, sacudida, números de daño, destello y pausa de nivel en `Balance.Juice` |
| Q19 | Tutorial | 60 segundos guiados y arena de práctica | 7 pasos guiados y una práctica libre. No hay límite de 60 s |
| Q20 | Criterios para ganar | Game feel y pulido; innovación técnica; impacto educativo; presentación y demo | Vigente. Orden de prioridad sin cambios |

## 2. Decisiones de producción del 14-11-2026

Cada decisión tiene un identificador `D-nn`, un motivo y una consecuencia.

### D-01. El servidor simula con números; el cliente dibuja

- **Decisión.** El servidor simula posiciones, vida y daño con un paso fijo de 1/20 s (20 pasos por segundo). Envía instantáneas de posiciones a 10 Hz (`Balance.Sim.Step` y `Balance.Sim.SnapshotEvery`). El cliente dibuja enemigos y proyectiles con modelos reciclados (pooling) y los interpola. El cliente nunca decide daño.
- **Motivo.** Con 100 enemigos, crear una instancia de Roblox por enemigo en el servidor cuesta demasiado. Simular con números es barato. El servidor autoritativo también cumple la regla de la sección 7.2 del prompt maestro.
- **Consecuencia.** Los enemigos no existen como objetos en el servidor. Las pruebas de colisión usan círculos en el plano. Las plantillas visuales viven en el cliente (ver D-02). El Impulso RCS mueve el personaje en el cliente; el servidor valida el uso y el daño.

### D-02. Las plantillas visuales viven en `ReplicatedStorage/Templates`

- **Decisión.** Las plantillas de enemigos, proyectiles y efectos se crean en `ReplicatedStorage/Templates`, no en `ServerStorage/Templates`. `WorldBuilder.build()` las construye al arrancar el servidor.
- **Motivo.** El que dibuja es el cliente. Un cliente no puede leer `ServerStorage`.
- **Consecuencia.** Desviación registrada de la sección 7.1 del prompt maestro. Las plantillas son visibles para el cliente. No contienen datos de balance, así que no hay riesgo.

### D-03. Cámara en tercera persona con giro libre

- **Decisión.** Cámara orbital libre: ratón, arrastre táctil o stick derecho. Campo de visión (FOV) 80, ajustable de 60 a 100. Salto habilitado (`Balance.Hero.JumpPower = 34`). Gravedad de Marte: 0,38 g, es decir 74,5 studs/s² (`Balance.World.Gravity`). Antes era cámara cenital 3/4 (Q3).
- **Motivo.** Petición del usuario. El género de referencia (ver D-04) usa tercera persona.
- **Consecuencia.** Se pierde algo de legibilidad frente a la cámara cenital. Se compensa con avisos de ataque en el suelo (anillos y líneas naranjas) y con el zoom de la rueda del ratón (14 a 42 studs). Q3 queda reemplazada.

### D-04. Referencias de diseño: Final Swarm, Megabonk y Risk of Rain 2

- **Decisión.** Se toman solo mecánicas, sin copiar nombres, arte ni assets. Detalle y fuentes en `docs/REFERENCIAS.md`. Se adoptan: tercera persona, oleadas numeradas con jefes, cartas 1 de 3 con rareza (común, rara, épica, legendaria), mejoras permanentes en árbol, consejo de "kitear", ajuste de FOV y modo de efectos bajos. No se adoptan: llaves o cofres de pago, tablas de clasificación ni nombres de armas.
- **Motivo.** Acelera el diseño con mecánicas ya probadas por el público objetivo. La regla de la sección 4 del prompt maestro prohíbe copiar material.
- **Consecuencia.** Las cifras de las guías de fans son aproximadas y no se usan como cifras del juego. Todos los números salen de `Balance.luau`.

### D-05. Estructura de la misión

- **Decisión.** 18 oleadas de 60 s (`Balance.Run.WaveLength`, `TotalWaves`). Minijefes al inicio de las oleadas 5, 10 y 15 (segundos 240, 540 y 840). Jefe final en la oleada 18 (segundo 1020). 3 biomas que cambian a los 360 y 720 s de misión, es decir en 6:00 y 12:00. Cada jefe suelta una pieza de la nave (MMRTG, antena, generador de oxígeno, propulsor). La cuarta pieza da la victoria y el despegue.
- **Motivo.** Un ritmo claro de oleadas numeradas ayuda al jugador a medir su avance. La pieza por jefe da una meta narrativa y un hueco para contenido educativo.
- **Consecuencia.** Desviación respecto de Q8 (ver sección 3). La partida dura unos 17 minutos hasta el jefe final.

### D-06. Modo "Demo rápida"

- **Decisión.** Modo `demo` con `TimeScale = 12` y `XpMult = 2.6` (`Balance.Modes`), jefes con 22 % de vida, sin briefing ni checkpoints y un «Protocolo de emergencia» gratis. La demo dura unos 2 minutos de juego (victoria en 95 s medidos con bot el 15-11-2026). El jefe final aparece a los 85 s.
- **Motivo.** El pitch dura 3 minutos. Una partida de 18 minutos no cabe.
- **Consecuencia.** La demo rápida otorga la misma ciencia que la misión completa (la fórmula usa tiempo de misión, no reloj real). Ver riesgo R-07 en `docs/BRIEF_PRODUCCION.md`.

### D-07. Datos NASA: copia local (snapshot) de DONKI

- **Decisión.** El juego incluye una copia local de DONKI tomada de `data/curated/space_weather.json` del repositorio del equipo (`game/src/shared/NasaData.luau`, `retrievedAt` 14-11-2026, modo `snapshot`). Se muestra en la telemetría del HUD y como alertas de clima espacial con eventos reales fechados. El juego **no** llama a NASA en vivo. Hacerlo exige activar HttpService y un proxy del equipo.
- **Motivo.** Regla 13.5 del prompt maestro: "snapshot primero" y "NASA nunca se llama desde el cliente". Roblox no alcanza el servidor local del equipo.
- **Consecuencia.** Los datos son de una ventana de 30 días (15-10-2026 a 14-11-2026). Los efectos (daño, velocidad) son de diseño. El texto dice "evento real del [fecha]". Llamada en vivo: `[PENDIENTE]` P-07.

### D-08. Fichas NTRS verificadas de las 4 piezas

- **Decisión.** Las 4 piezas recuperables de `Content.Pieces` tienen ficha NTRS verificada en `ntrs.nasa.gov`: `20150005587` (MMRTG), `20040084278` (antena de alta ganancia del programa MER), `20205007222` (generador de oxígeno MOXIE) y `20240003648` (propulsión del módulo de servicio de Orion). Además, los 12 «DATO REAL» de las cartas se contrastaron con `science.nasa.gov` (`docs/NASA_APIS.md` sección 10). Frase obligatoria de créditos: "Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto." (`Content.Credits`).
- **Motivo.** Sección 13 del prompt maestro: todo dato técnico presentado al jugador debe tener fuente verificable.
- **Consecuencia.** Queda resuelto el pendiente P-06 para todas las piezas recuperables.

### D-09. Interfaz "Dark Telemetry", tipografía Bangers y controles duales

- **Decisión.** Colores `#070B14`, `#0B132B`, `#00B4D8`, `#00D2FF`, `#FF6B35`, acentos por bioma (`ETAPA 1..3`) y función (`gold`, `orange`, `cyanHi`, `violet`, `green`). Tipografías Michroma (título principal), Bangers (`Ui.Fonts.impact` en subtítulos, oleada, nivel, alertas, cartas, pieza, pausa, resumen y números de daño en `Fx.luau`), Titillium Web (texto) y Roboto Mono (datos y etiquetas técnicas), todas incluidas en Roblox (`game/src/client/Ui.luau`). En teclado, el jugador se mueve indistintamente con `WASD` o con las flechas `↑ ↓ ← →` (`ContextActionService:BindActionAtPriority("AresArrowKeys", ...)` en `Main.client.luau` + `player:Move(..., true)`).
- **Motivo.** El dossier pedía Bahnschrift, Satoshi y Space Mono (ausentes en Roblox). La combinación con `Bangers`, acentos por sección y botones «Forma humana» mejora legibilidad e identidad de arcade espacial; las flechas amplían accesibilidad sin interferir con la cámara.
- **Consecuencia.** Sustitución registrada y unificada en todo el cliente (sin dependencias residuales de `GothamBlack` en `Fx.luau`). `Content.Tutorial[1]`, `Content.Controls` y `Ajustes y Controles` documentan `WASD` y flechas.

### D-10. Flujo de código: `game/src/` es la fuente de verdad

- **Decisión.** El código vive en disco en `roblox-blender/game/src/`. Para lugares en la nube de Roblox (`placeId: 114817072312952`) el servidor HTTP local queda bloqueado por permisos de red en lugar publicado/Team Create, así que se sincroniza sin HTTP con `tools/studio/push.py` o herramientas MCP de Roblox Studio (`multi_edit` / `execute_luau`). Para lugares locales sin nube sigue disponible `tools/sync/sync_studio.luau` sobre `127.0.0.1:8765`.
- **Motivo.** Permite versionar el código y trabajar en equipo respetando la restricción sin red local en el lugar guardado en la nube.
- **Consecuencia.** Studio es una copia. Si alguien edita una mejora visual directamente en Studio (como la «Forma humana» del menú el 15-11-2026), debe trasladarse de inmediato a `game/src/` para no perderla en sincronizaciones futuras.

### D-11. Assets 3D como mallas generadas en el cliente

- **Decisión.** Los 30 modelos (incluyendo `Rover.luau` e `Insignia.luau`) se construyen con `tools/blender/` y se integran en Roblox como mallas generadas en el cliente mediante `game/src/client/MeshFactory.luau` a partir de módulos de datos en `game/src/shared/Meshes/`. No se suben assets FBX a Roblox. También se exportan 30 FBX a `assets/export/` y 30 renders 512×512 a `docs/assets/previews/`. El catálogo está en `docs/assets/CATALOGO_BLENDER.md`.
- **Motivo.** Subir assets exige permiso, créditos y moderación. Las mallas en código se versionan con el repositorio.
- **Consecuencia.** Para evitar el límite de memoria de `EditableMesh` dinámicos (que fallaba a partir de la novena submalla), `MeshFactory.luau` convierte cada `EditableMesh` a `FixedSize = true` con `CreateEditableMeshAsync` y destruye el temporal inmediatamente (`em:Destroy()`). En el lugar en la nube se activó *Allow Mesh / Image APIs* en Experience Settings > Security.

### D-12. Guardado de la meta-progresión

- **Decisión.** DataStore `AresForgeMeta_v1`, con `pcall`, hasta 4 intentos (1 en Studio) y espera creciente (1, 2, 4 s). Si la carga falla, la sesión se juega en memoria y no se guarda, para no pisar datos reales (`game/src/server/SaveService.luau`).
- **Motivo.** Sección 7.2 del prompt maestro.
- **Consecuencia.** Con *Enable Studio Access to API Services* activado en Experience Settings, el guardado ya responde en Studio en el lugar `114817072312952`; queda por verificar en un servidor publicado definitivo (P-03).

### D-13. Pruebas hechas y no hechas

- **Hecho en Studio al 15-11-2026 (`placeId: 114817072312952`, versión guardada `14`).** Construcción de las 30 mallas Blender en cliente sin errores (con `Rover` e `Insignia`), bucle completo en modo demo (`MISIÓN CUMPLIDA`, 4 jefes, 4 piezas con fichas NTRS, despegue e informe de misión), tutorial guiado (`PRÁCTICA`, `TUTORIAL 1/8`), retroceso/inclinación de enemigos, destello de boca y retroceso de cámara, acceso a APIs y DataStore en Studio, enlace de flechas `AresArrowKeys`, auditoría `TextFits` (`0` textos recortados en `AresHud`) y ensayo de carga en Studio con 92→98 enemigos (`docs/perf/RENDIMIENTO.md`).
- **No verificado.** Móvil real. PC en primer plano a 60 FPS sin capado en segundo plano (el viewport de Studio en segundo plano estuvo capado a 15 FPS). DataStore en servidor publicado definitivo. Escucha humana del audio definitivo (`P-12`). Revisión manual de `Lighting.Technology = Future` (`P-01`).
- **Audio.** `Balance.Audio.Music` tiene 3 pistas del catálogo con licencia de Roblox (`calm`, `combat`, `boss`) y `Balance.Audio.Sfx` 12 claves con ecualizador en `AresSfx`. Contrato en `docs/assets/AUDIO.md`. Falta validación por escucha humana (`P-12`).

## 3. Contradicciones entre el prompt maestro y el código

El prompt maestro es la intención. El código es la realidad. Estas son las diferencias detectadas el 14-11-2026.

| Id | Prompt maestro | Código | Propuesta |
|---|---|---|---|
| Q3 | Q3: cámara cenital 3/4 | Tercera persona orbital | Actualizar Q3 en el prompt |
| Q8 | Q8: mini-jefe cada 5 minutos | Minijefes a los 4, 9 y 14 minutos | Aceptar la estructura por oleadas y actualizar Q8 |
| Q10 | Q10: héroes y objetos que se desbloquean | Un héroe; 8 mejoras de estadísticas | Decidir: ampliar o reducir Q10 (P-08) |
| D-02 | Sección 7.1: `ServerStorage/Templates` | `ReplicatedStorage/Templates` | Ya registrada |
| Q18 | Sección 9: sacudida de 4 px | `ShakeMax = 0.35` studs | Medir en pantalla y ajustar (P-10) |
| Q19 | 60 segundos guiados | 7 pasos guiados + práctica libre (`Hud.luau` actualizado a `"7 pasos · recomendado"`) | Coherente; medir duración real en ensayo |
| Q5 | 3 rarezas de objeto | Objetos con 3 rarezas; cartas con 4 | Ya coherente: las 4 rarezas son de las cartas |
| `docs/NASA_APIS.md` | Citaba "sección 14" y al repo como ajeno | Actualizado a "sección 13.5" y alineado con el repo raíz | Corregido |

## 4. Pendientes

Los dueños son roles. Las fechas objetivo son una propuesta revisada al 15-11-2026 y el equipo debe confirmarlas. La fecha del evento es `[PENDIENTE]`.

| Id | Pendiente | Dueño (rol) | Fecha objetivo |
|---|---|---|---|
| P-01 | Poner `Lighting.Technology = Future` a mano en Studio (un script no puede; al 15-11-2026 `game.Lighting` figura con `RBX_OriginalTechnologyOnFileLoad = 3` = `ShadowMap` y migración Unified Lighting) | Programación Roblox | 15-11-2026 |
| P-02 | Publicar el lugar en Roblox cuando el equipo lo pida (lugar ya guardado en nube «Núcleo de Ares», `placeId: 114817072312952`, versión `29`) | Programación Roblox | 15-11-2026 |
| P-03 | Verificar DataStore en el lugar publicado (en Studio ya responde con *Enable Studio Access to API Services*; falta validar en servidor publicado) | Programación Roblox | 16-11-2026 |
| P-04 | Rotar la clave de NASA expuesta en una sesión anterior y crear una clave propia en el entorno del servidor | Arquitectura web | 15-11-2026 |
| P-05 | Medir rendimiento con 100 enemigos en PC y móvil; guardar en `docs/perf/` | Programación Roblox | En progreso (`docs/perf/RENDIMIENTO.md` creado en Studio PC con 92–98 enemigos; falta medición sin capado 15 FPS y móvil real) |
| P-06 | Referencia NTRS de la antena de alta ganancia y del generador de oxígeno | Arquitectura web | **Hecho** (`20040084278` y `20205007222` integradas en `Content.Pieces[2..3]`; 4/4 piezas con NTRS) |
| P-07 | Llamada en vivo a NASA: activar HttpService y montar un proxy del equipo (o dejar solo snapshot) | Arquitectura web | 19-11-2026 |
| P-08 | Decidir el alcance de la meta-progresión (Q10): héroes y objetos desbloqueables o solo mejoras | Diseño y arte, con dirección | 16-11-2026 |
| P-09 | Hacer que el sincronizador entre en subcarpetas (`shared/Meshes/`) y crear `tools/blender/`, `assets/export/` y las mallas | Programación Roblox y diseño y arte | **Hecho** (30/30 mallas integradas en Studio, incluye `Rover` e `Insignia`) |
| P-10 | Medir la sacudida de cámara frente al límite de 4 px del prompt | Diseño y arte | 19-11-2026 |
| P-11 | Probar en móvil real: controles táctiles, tamaños de botón (44 px o más), 30 FPS | Programación Roblox | 18-11-2026 |
| P-12 | Audio definitivo: validar por escucha humana las 3 pistas con licencia (`Balance.Audio.Music`) y los 12 SFX con EQ (`AresSfx`) | Diseño y arte | 20-11-2026 |
| P-13 | Ensayar la demo 3 veces seguidas sin fallos (criterio F6) | Todo el equipo | 21-11-2026 |
| P-14 | Fecha y reglas del concurso (prompt maestro, sección 1) | Dirección | `[PENDIENTE]` |
| P-15 | Nombre y tema definitivos de cada bioma en el prompt (el juego usa los de `Content.Biomes`) | Diseño y arte | 16-11-2026 |
| P-16 | Archivo `docs/assets/AUDIO.md`, citado en un comentario de `Balance.luau` | Programación Roblox | **Hecho** el 14-11-2026 (`docs/assets/AUDIO.md`) |
| P-17 | Gestionar `game/src/sync_studio.lua`, copia servida por HTTP de `tools/sync/sync_studio.luau` | Programación Roblox | **Resuelto** el 14-11-2026 (se conserva como endpoint HTTP para sincronizar en Studio y el sincronizador solo lee `.luau`) |
