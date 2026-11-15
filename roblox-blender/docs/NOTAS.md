# Notas técnicas

Bitácora corta. Última actualización: 15-11-2026.
Regla: borra lo que ya no aplique (prompt maestro, sección 2.7).

## 1. Estructura del código

| Carpeta en disco | Destino en Studio | Rol |
|---|---|---|
| `game/src/shared/` | `ReplicatedStorage/Shared` | Módulos compartidos: `Balance`, `Content`, `NasaData`, `Visuals` y subcarpeta `Meshes/` (30 mallas) |
| `game/src/server/` | `ServerScriptService/Server` | Autoridad: `Session`, `Combat`, `Enemies`, `Loot`, `SaveService`, `WorldBuilder`, `Main.server` |
| `game/src/client/` | `StarterPlayer/StarterPlayerScripts/Client` | Dibujo, entrada, cámara, interfaz: `Renderer`, `MeshFactory`, `Scenery`, `Fx`, `Hud`, `Ui`, `Main.client` |

Convención de nombres: `X.luau` es un `ModuleScript`. `X.server.luau` es un `Script`. `X.client.luau` es un `LocalScript`.

Comunicación: dos `RemoteEvent` en `ReplicatedStorage/Remotes`.

- `Sync`: servidor a cliente. Lleva la instantánea (10 Hz) y los eventos.
- `Cmd`: cliente a servidor. Lleva intenciones (`ready`, `start`, `tutorial`, `skill`, `choose`, `continue`, `pause`, `menu`, `buy`, `debug`). El servidor limita a 20 comandos por segundo y valida cada argumento.

## 2. Cómo sincronizar disco a Studio

La fuente de verdad es `roblox-blender/game/src/`. Studio es una copia. En lugares ya guardados en la nube de Roblox (`placeId: 114817072312952`), la sincronización por HTTP local queda bloqueada: usa `tools/studio/push.py` (sin HTTP) o herramientas MCP de Roblox Studio. Para lugares locales sin publicar sigue disponible el método HTTP:

1. Abre una terminal en la raíz del proyecto.
2. Arranca el servidor local, solo en localhost:
   `python -m http.server 8765 --bind 127.0.0.1 --directory game/src`
3. Abre el lugar en Studio, en modo Edit.
4. Ejecuta el contenido de `tools/sync/sync_studio.luau` en Studio (por ejemplo, con la herramienta MCP `execute_luau` o pegándolo en la barra de comandos).
5. El script devuelve la lista de cambios: `N cambios: ...`.
6. Detén el servidor local al terminar.

Cómo trabaja el sincronizador:

- Recorre recursivamente cada carpeta (incluida `shared/Meshes/`) y descarga cada archivo `.luau`.
- Crea o actualiza los `Script`, `LocalScript` y `ModuleScript` (creando carpetas intermedias como `Shared/Meshes`) y borra los scripts que ya no existen en disco.
- `game/src/sync_studio.lua` es una copia idéntica de `tools/sync/sync_studio.luau` colocada en la raíz servida para poder cargarla con `HttpService:GetAsync("http://127.0.0.1:8765/sync_studio.lua")` desde la barra de comandos de Studio; el sincronizador la omite al crear scripts (solo procesa `.luau`).
- Necesita que `HttpService` pueda llamar a `127.0.0.1`. No se cambió ningún ajuste de Studio. Si falla, revisa los permisos de HTTP del lugar `VERIFICAR EN STUDIO`.

## 3. Cómo probar en Studio

1. Sincroniza (sección 2).
2. Pulsa Play. Revisa la Salida: no debe haber errores rojos.
3. En el menú elige "Demo rápida". Dura unos 3,6 minutos de reloj real.
4. Comprueba, en orden: oleadas numeradas, cambio de bioma a los 72 s y a los 144 s (reloj real de la demo), minijefes a los 48, 108 y 168 s, jefe final a los 204 s, pieza recuperada tras cada jefe, despegue e informe de misión.
5. Para la misión completa elige "Iniciar misión" (18 minutos).
6. Para el tutorial elige "Tutorial y práctica".

Lista de verificación (actualizada al 15-11-2026 en Studio, lugar `114817072312952`):

- [x] Arranque sin errores (incluidas 30/30 mallas de Blender vía `EditableMesh` `FixedSize = true`, con `Rover` e `Insignia`).
- [x] Bucle completo en modo demo (`MISIÓN CUMPLIDA`): 4 jefes, 4 piezas con fichas NTRS verificadas (`20150005587`, `20040084278`, `20205007222`, `20240003648`), despegue e informe de misión.
- [x] Subida de nivel con cartas («DATO REAL» contrastado con NASA), tutorial (`PRÁCTICA`, `TUTORIAL 1/8`) y movimiento con `WASD` + flechas del teclado.
- [x] HUD y menús mejorados (fuentes `Bangers`/`Michroma`, diseño por color/etapa, «Forma humana» del menú principal, panel de Ajustes y Controles, `TextFits` OK en Studio).
- [ ] Móvil real.
- [x] Sondeo en Studio con 92–98 enemigos (`docs/perf/RENDIMIENTO.md`; Studio en segundo plano estuvo capado a 15 FPS; pendiente repetir a 60 FPS en primer plano y móvil).
- [ ] DataStore verificado en lugar publicado (acceso a API en Studio ya activado y verificado; falta publicación definitiva cuando el equipo lo pida).
- [ ] Escucha humana de la mezcla de audio (`P-12`: 3 pistas musicales con licencia y 12 SFX con EQ ya cargados).

## 4. Comando de depuración (solo Studio)

El servidor acepta `debug` solo si `RunService:IsStudio()` es verdadero (`game/src/server/Session.luau`, función `onCmd`). En un servidor publicado se ignora.

Uso desde el cliente, durante una prueba Play:

```lua
game.ReplicatedStorage.Remotes.Cmd:FireServer("debug", "<accion>", valor)
```

Ejecútalo en la barra de comandos con el contexto del cliente `VERIFICAR EN STUDIO`.

| Acción | Valor | Efecto | Requiere partida |
|---|---|---|---|
| `invincible` | `true` o `false` | Activa o quita la invulnerabilidad (`Balance.Debug.Invincible`) | No |
| `time` | número (segundos de misión) | Fija el reloj de misión `R.t` | Sí |
| `xp` | número | Suma XP (se multiplica por el bono de XP) | Sí |
| `item` | id de objeto, por ejemplo `"plasma"` | Entrega un objeto de `Balance.Items` | Sí |
| `bosshp` | número | Baja la vida del jefe vivo a ese valor como máximo | Sí, con un jefe vivo |
| `hp` | número | Fija la vida del héroe | Sí |
| `science` | número | Suma datos científicos | No (solo desde el menú) |

Ejemplos:

```lua
local cmd = game.ReplicatedStorage.Remotes.Cmd
cmd:FireServer("debug", "invincible", true)
cmd:FireServer("debug", "xp", 100)
cmd:FireServer("debug", "item", "plasma")
cmd:FireServer("debug", "bosshp", 50)
cmd:FireServer("debug", "science", 500) -- solo en el menú
```

Cuidado con `time`: el director elige el jefe según el orden (`R.bossIdx`), no según el reloj. Si pones `time` en 1020 con 0 piezas, aparece primero el minijefe 1, luego el 2 y el 3, y solo después el final. Para llegar al jefe final: derrota o reduce cada jefe con `bosshp` y avanza.
`Balance.Debug.StartMinute` tiene el mismo efecto al arrancar la partida.

## 5. Datos NASA en el juego

- Copia local en `game/src/shared/NasaData.luau`. Origen: `data/curated/space_weather.json` del repositorio del equipo, capturado el 14-11-2026.
- Para actualizarla: regenera el JSON con la ingesta del repositorio del equipo, copia los valores a `NasaData.luau` y cambia `retrievedAt`. Mantén el contrato: `source`, `sourceUrl`, `retrievedAt`, `mode`, `attribution`, `dataKind`.
- El juego no llama a NASA. Una llamada en vivo exige activar HttpService y un proxy del equipo. Reglas: `docs/NASA_APIS.md` y prompt maestro, sección 13.5.
- Texto de créditos obligatorio: "Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto."
- No escribas "según NASA" en textos del juego.

## 6. Guardado

- DataStore `AresForgeMeta_v1`, clave `u_<UserId>` (`game/src/server/SaveService.luau`).
- Se guarda al terminar una misión, al comprar una mejora, al abrir el cofre del tutorial por primera vez, al salir el jugador y al cerrar el servidor.
- Si la carga falla, el jugador juega en memoria y no se guarda nada (`offline = true`).
- En Studio sin publicar el lugar, no hay DataStore: se juega en memoria. Verificación en lugar publicado: P-03.

## 7. Limitaciones conocidas

1. Rendimiento medido en Roblox Studio con 92–98 enemigos (`docs/perf/RENDIMIENTO.md`), pero bajo capado a 15 FPS por ventana en segundo plano; falta medir a 60 FPS en primer plano y en móvil real.
2. Audio pendiente de validación humana (`P-12`): `Balance.Audio.Music` ya cuenta con 3 pistas del catálogo con licencia (`calm`, `combat`, `boss`) y `Balance.Audio.Sfx` con 12 claves (`shoot`…`warn`, más `buff`) filtradas por `AresSfx` (`docs/assets/AUDIO.md`). Falta escucha humana en partida y balance de mezcla.
3. Las 30 mallas low-poly de Blender (`30` FBX en `assets/export/` y `30` previews PNG en `docs/assets/previews/`, incluyendo `Rover.luau` e `Insignia.luau`) están integradas mediante `EditableMesh` (`FixedSize = true`) en cliente, con respaldo automático en `Templates`.
4. `Lighting.Technology = Future` se pone a mano en Studio (`P-01`). En la inspección MCP del 15-11-2026 sobre `game.Lighting`, Studio reportó `RBX_OriginalTechnologyOnFileLoad = 3` (`ShadowMap`, frente a `Future = 4`) con migración Unified Lighting activa: pendiente de confirmar/ajustar a mano en Studio.
5. Los números de daño (`game/src/client/Fx.luau`) ya usan `Enum.Font.Bangers` (`Ui.Fonts.impact`), alineados con la cabecera de oleada, nivel, menú y superposiciones.
6. Las 4 piezas recuperables (`Content.Pieces[1..4]`) ya tienen fichas NTRS verificadas (`20150005587`, `20040084278`, `20205007222`, `20240003648`).
7. Los enemigos con contacto (élites y jefes) usan el intervalo de golpe del Remolino (`Balance.Enemies.chaser.hitCd`, 0,8 s). No tienen un valor propio.
8. El tiempo de aparición de cofres usa reloj real, no tiempo de misión. En la demo rápida no se acelera.
9. La demo rápida otorga la misma ciencia que la misión completa (riesgo R-07).
10. `Balance.Debug.LogPerf` existe y ningún sistema lo usa todavía.
11. El tutorial no tiene límite de 60 s (Q19).
12. Sin cooperativo: una sesión por jugador. Varios jugadores en el mismo servidor comparten solo la arena, no la simulación.
13. Hay una clave de NASA expuesta en una sesión anterior. Se debe rotar (P-04). No la guardes en el repositorio.

## 8. Archivos relacionados

- Decisiones y pendientes: `docs/DECISIONES.md`
- Números: `docs/BALANCE_V0.md`
- Seguridad del puente de Blender: `docs/SEGURIDAD_MCP.md`
- Procesos de los servidores MCP: `docs/PROCESOS_MCP.md`
- Catálogo de APIs de NASA: `docs/NASA_APIS.md`

## 9. Estado al 15-11-2026 (prueba en Studio)

- Demo rápida con jugador automático: llegó a nivel 19 y a la pieza 2 de 4. Equipo visible, rótulo de nivel y sonidos cargados. Consola limpia salvo el aviso esperado de DataStore.
- **Sin verificar:** las capturas automáticas del menú salieron con el fondo 3D en blanco de forma intermitente. Una captura sin interfaz mostró la escena correcta. Parece fallo de la captura con Studio sin foco. Una persona debe mirar el menú en Studio.
- **Guardado en Studio:** el lugar `Place1` nunca se ha guardado. Hay que hacerlo una vez a mano (Archivo > Guardar en archivo o en Roblox). Después se puede guardar por MCP con `save_place`.
- **Insignia NASA:** su uso requiere permiso de NASA. El equipo declaró tenerlo. Si no hay permiso escrito, pon `Balance.Branding.NasaInsignia = false`.
- Cómo manejar Studio desde cualquier IA o terminal: `tools/studio/README.md`.
- Pulido de combate (15-11-2026, segunda tanda): el enemigo golpeado retrocede e inclina un instante (`Balance.Juice.KickTime`, `KickDist`; `Renderer.hit` y `Renderer.update`). Fuente de impacto Bangers (`Ui.Fonts.impact`) en alertas, título de subida de nivel, pausa y resumen. Probado 75 s en demo: consola limpia.
- Cartas de mejora con «DATO REAL» (15-11-2026, tercera tanda): campo `fact` en `Content.Upgrades`, visible en la carta. Fuentes y aviso de revisión en `docs/NASA_APIS.md` sección 10.
- **Lugar publicado:** el usuario guardó el lugar en Roblox como «Núcleo de Ares» (placeId `114817072312952`). `save_place` ya funciona. Consecuencias:
  - La sincronización por HTTP local queda bloqueada. Usar `tools/studio/push.py` (sin HTTP).
  - **Bloqueante:** las 30 mallas fallan con `EditableMesh is not accessible`. Hay que activar *Allow Mesh / Image APIs* en Experience Settings > Security. Mientras tanto el juego usa modelos básicos de respaldo.
  - DataStore pide activar *Enable Studio Access to API Services* en la misma pantalla (P de guardado).
- Cuarta tanda (15-11-2026): el usuario activó *Allow Mesh / Image APIs* y el acceso de Studio a API. Verificado: consola limpia, las 30 mallas cargan, el guardado de progreso responde y el menú muestra la insignia girando sobre la nave con cielo ocre (captura correcta). Añadido destello de boca del arma (`Renderer.shot`, `MUZZLE_TIME`) y sacudida en disparos explosivos. El bloqueante de mallas queda resuelto.
- Quinta tanda (15-11-2026): los 12 datos de las cartas se contrastaron con `science.nasa.gov` y se reescribieron para ceñirse a la fuente. Tabla con citas en `docs/NASA_APIS.md` sección 10.
- Sexta tanda (15-11-2026): retroceso de cámara al disparar (`Fx.kickBack`, `Fx.kickUpdate`; se dispara en `Renderer.shot`). Probado 40 s de demo en Studio: consola limpia; lugar guardado. Encargo a DeepSeek no completado (solo búsquedas, saldo mensual crítico); el cambio se hizo a mano.
- Séptima tanda (15-11-2026), revisión de interfaz: los subtítulos del menú pasan dentro de cada botón (alineados a la derecha, textos más cortos, contraste oscuro en botones claros); el contador de enfriamiento de habilidades ya no deja ver la tecla debajo. Probado en Studio: menú sin choques, consola limpia, lugar guardado.
- Octava tanda (15-11-2026), coherencia visual, fuentes y flechas en Studio:
  - Rescatada en disco (`game/src/client/Hud.luau`) la estética «Forma humana» de los botones del menú que vivía en Studio (esquinas redondeadas de `10` px, chip numérico `01..06` y labio inferior), ampliada con acentos por sección (`gold`, `orange`, `cyanHi`, `violet`, `green`), bordes en botones fantasma y ajuste `TextScaled` en subtítulos para evitar choques.
  - Sistema visual y tipográfico (`Ui.luau` + `Hud.luau`): `Ui.panel` acepta `TagColor` para teñir cabecera/esquinas/borde y `Ui.button` suma variantes `"violet"` y `"green"`. Aplicada fuente `Ui.Fonts.impact` (`Bangers`) + trazos oscuros legibles y colores por función/bioma (`ETAPA 1..3 · <bioma>`, `OLEADA`, `NIVEL`) en el HUD, subtítulo del menú, Hangar (filas codificadas por color), Ajustes y Controles (recuadro con esquema completo), Créditos, cartas de nivel (título coloreado por rareza + recuadro «DATO REAL»), ficha de pieza recuperada, Pausa e Informe de misión.
  - Movimiento con flechas del teclado (`game/src/client/Main.client.luau` + `Content.luau`): `ContextActionService:BindActionAtPriority("AresArrowKeys", ...)` intercepta `↑ ↓ ← →` en partida activa para evitar el giro clásico de cámara de Roblox, y el bucle `AresMain` combina `WASD` + flechas mediante `player:Move(Vector3.new(kx, 0, kz), true)` relativo a cámara. Actualizados `Content.Tutorial[1]`, `Content.Controls` y `Content.Credits` (incluye `Bangers`).
  - Verificado en Roblox Studio (`placeId: 114817072312952`): los `4` scripts sincronizados coinciden byte a byte con disco (`Adler-32`), prueba `Play` con demo lanzada (`ArrowBound = true`, `HudVisible = true`, `TextIssuesCount = 0` en todas las etiquetas de `AresHud` tras ampliar alturas de `PAUSA`/`sumTitle`/`levelTitle`), consola limpia (`0` errores) y lugar guardado en Roblox con `save_place` (versión `14`, sin publicar). `inspect_instance` sobre `game.Lighting` confirmó `RBX_OriginalTechnologyOnFileLoad = 3` (`ShadowMap`) con migración Unified Lighting, por lo que `P-01` sigue pendiente de revisión manual.

## 10. Menú principal: columna izquierda humanizada (15-11-2026)

- **Diseño anterior superado:** la cuadrícula de 2 columnas con chips `01..06` chocaba con la barra superior de Roblox (`CoreGui`) en ventanas bajas y cubría el cohete y el logo de NASA.
- **Nuevo diseño (`game/src/client/Hud.luau`):** columna única a la izquierda (`MenuColumn`, `368 × 504 px`) con degradado lateral acotado (`36 %` del ancho), auto-escala bajo `topSafe` (`64 px` reales) y ancho máximo del `35 %` para dejar el `65 %` derecho despejado.
- **Jerarquía de juego real:** cabecera limpia (`CRÁTER JEZERO · SOL 01`, `ARES FORGE`, `SUPERVIVENCIA EN MARTE`), botón principal destacado `INICIAR MISIÓN`, fila doble `DEMO RÁPIDA` + `TUTORIAL`, tarjeta `HANGAR DEL TRAJE` con pastilla viva de ciencia, fila compacta `AJUSTES Y MANDOS` + `CRÉDITOS Y FUENTES` y `HOJA DE SERVICIO` en 3 columnas.
- **Cámara del menú (`game/src/client/Main.client.luau`):** enfoque elevado a `ship + Vector3.new(0, 11, 0)` con desplazamiento `-14` para encuadrar nítidamente la nave, el astronauta y `InsigniaVisual` en el lado derecho.
- **Verificación en Studio (`placeId: 114817072312952`, versión `15`):** `Hud` (`55497 B`, Adler-32 `13246b79`) y `Main` (`14207 B`, Adler-32 `9cfbcece`) verificados en `Play` (`812 × 473`): `ScreenTopY = 66` (`>= 58` de `TopInsetY`), `MenuRightFrac = 0.378` (`< 0.42`), `InsigniaLeftX = 464` (separación libre de `157 px` respecto al menú), `InsigniaTopY = 140`, `MenuTextIssuesCount = 0`, consola vacía (`0` errores), captura visual correcta y guardado en nube con `save_place` (versión `15`, sin publicar).

## 11. Compatibilidad multiplataforma, controles y calidad gráfica adaptativa (15-11-2026)

- **Calidad gráfica adaptativa por especificaciones e FPS (`Fx.luau`, `Renderer.luau`, `Main.client.luau`, `Hud.luau`):** modo por defecto `AUTO` (`qualityMode = "auto" | "high" | "med" | "low"`). Lee `SavedQualityLevel` / perfil táctil en el arranque y vigila FPS reales con EMA e histéresis (`2,5 s` bajo `42 FPS` baja nivel; `7,0 s` sobre `57 FPS` recupera), escalando densidad de partículas (`100 % / 65 % / 35 %`), sacudida de cámara (`1 / 0,85 / 0,55`), límite de rótulos de daño flotantes en nivel `low`, decimación alterna para enemigos lejanos (`> 70` studs en `low`, `> 100` en `med`), `BloomEffect` e iluminación `GlobalShadows`. Control manual en `AJUSTES Y CONTROLES` (`CALIDAD GRÁFICA`).
- **Maquetación responsive sin choques (`Hud.luau`):** lectura real de `GuiService:GetGuiInset()` (`topSafe >= 60 px` reales), escalado adaptativo (`uiScale` `0.48..1.8` + `cornerScale`), modo estrecho/vertical (`v.X < 1080` y `v.X < v.Y` con menú inferior centrado y degradado vertical en móvil retrato), modales (`Shop`, `Settings`, `Credits`, `LevelUp`, `Piece`, `Pause`, `Summary`) ajustados al área segura y reposicionamiento automático del ticker y botones de habilidad en modo táctil lejos del joystick virtual y del botón de salto.
- **Controles adaptados en tiempo real (`Main.client.luau`, `Hud.luau`, `Content.luau`):** detección viva por `UserInputService.LastInputTypeChanged` entre `"kb"`, `"gamepad"` y `"touch"`, actualizando etiquetas de habilidades/cartas, guía inferior, insignia `MODO ACTIVO` y tabla de `AJUSTES Y CONTROLES`. Consola/Mando añade foco automático `GuiService.SelectedObject`, navegación con `B` atrás, `X/L1` (RCS), `B/R1` (Pulso), cruceta `◀/▲/▶` para cartas, `R3` zoom cíclico y `Start` pausa; Móvil/Táctil excluye la zona inferior izquierda del joystick al girar cámara y soporta pellizco (`TouchPinch`) para zoom.
- **Panel web de telemetría (`public/index.html`):** rediseño responsive (*Dark Telemetry*) compatible con escritorio, móvil y consola/TV con guía de controles por plataforma y soporte `prefers-reduced-motion: reduce`, manteniendo `#mode`, `#list` y `/api/scenarios`.
- **Verificación en Studio (`placeId: 114817072312952`, versión `17`):** sincronizados y verificados por byte y `Adler-32` (`Content.luau` `10744 B / 526ce712`, `Fx.luau` `7889 B / c2a0dd51`, `Renderer.luau` `15689 B / 1414b53d`, `Main.client.luau` `18953 B / 6d52e8ac`, `Hud.luau` `67601 B / f3294c0a`). En `Play` (`812 × 473`, `topInsetY = 58`, `uiScale = 0.657`): menú (`menuScreenTopY = 97.2`, `textIssuesCount = 0`), ajustes (`panelScreenTopY = 97.9`, `CALIDAD GRÁFICA = AUTO (ALTA)`, `MODO ACTIVO: PC / WEB`, `textIssuesCount = 0`) y HUD en partida probado en `"kb"`, `"gamepad"` y `"touch"` (`11` paneles visibles, `0` solapamientos, `0` violaciones de `topSafe`, `textIssuesCount = 0` en los 3 modos, `Fx.setQuality("low"/"med"/"high")` validado). Consola limpia (`0` errores), capturas visuales correctas de menú, ajustes y HUD, y lugar guardado en Roblox con `save_place` (versión `17`, sin publicar).
