# Notas técnicas

Bitácora corta. Última actualización: 14-11-2026.
Regla: borra lo que ya no aplique (prompt maestro, sección 2.7).

## 1. Estructura del código

| Carpeta en disco | Destino en Studio | Rol |
|---|---|---|
| `game/src/shared/` | `ReplicatedStorage/Shared` | Módulos compartidos: `Balance`, `Content`, `NasaData`, `Visuals` y subcarpeta `Meshes/` (28 mallas) |
| `game/src/server/` | `ServerScriptService/Server` | Autoridad: `Session`, `Combat`, `Enemies`, `Loot`, `SaveService`, `WorldBuilder`, `Main.server` |
| `game/src/client/` | `StarterPlayer/StarterPlayerScripts/Client` | Dibujo, entrada, cámara, interfaz: `Renderer`, `MeshFactory`, `Scenery`, `Fx`, `Hud`, `Ui`, `Main.client` |

Convención de nombres: `X.luau` es un `ModuleScript`. `X.server.luau` es un `Script`. `X.client.luau` es un `LocalScript`.

Comunicación: dos `RemoteEvent` en `ReplicatedStorage/Remotes`.

- `Sync`: servidor a cliente. Lleva la instantánea (10 Hz) y los eventos.
- `Cmd`: cliente a servidor. Lleva intenciones (`ready`, `start`, `tutorial`, `skill`, `choose`, `continue`, `pause`, `menu`, `buy`, `debug`). El servidor limita a 20 comandos por segundo y valida cada argumento.

## 2. Cómo sincronizar disco a Studio

La fuente de verdad es `game/src/`. Studio es una copia.

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

Lista de verificación (resultado del 14-11-2026 en Studio):

- [x] Arranque sin errores (incluidas 28/28 mallas de Blender vía `EditableMesh` `FixedSize = true`).
- [x] Bucle completo en modo demo (`MISIÓN CUMPLIDA`): 4 jefes, 4 piezas, despegue e informe de misión.
- [x] Subida de nivel con cartas y tutorial (`PRÁCTICA`, `TUTORIAL 1/8`).
- [x] HUD (con ocultamiento de `Wave`/`Timer`/`Biome` bajo modales).
- [ ] Móvil real.
- [x] Sondeo en Studio con 92–98 enemigos (`docs/perf/RENDIMIENTO.md`; Studio en segundo plano estuvo capado a 15 FPS; pendiente repetir a 60 FPS en primer plano y móvil).
- [ ] DataStore en lugar publicado.
- [ ] Audio definitivo.

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
2. Audio provisional: sonidos integrados de Roblox. La música tiene 3 ranuras vacías (`docs/assets/AUDIO.md`).
3. Las 28 mallas low-poly de Blender ya están integradas mediante `EditableMesh` (`FixedSize = true`) en cliente, con respaldo automático en `Templates`.
4. `Lighting.Technology = Future` se pone a mano en Studio.
5. Los números de daño (`game/src/client/Fx.luau`) usan `GothamBlack`, no el sistema tipográfico.
6. Los enemigos con contacto (élites y jefes) usan el intervalo de golpe del Remolino (`Balance.Enemies.chaser.hitCd`, 0,8 s). No tienen un valor propio.
7. El tiempo de aparición de cofres usa reloj real, no tiempo de misión. En la demo rápida no se acelera.
8. La demo rápida otorga la misma ciencia que la misión completa (riesgo R-07).
9. `Balance.Debug.LogPerf` existe y ningún sistema lo usa todavía.
10. El tutorial no tiene límite de 60 s (Q19).
11. Sin cooperativo: una sesión por jugador. Varios jugadores en el mismo servidor comparten solo la arena, no la simulación.
12. Hay una clave de NASA expuesta en una sesión anterior. Se debe rotar (P-04). No la guardes en el repositorio.

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
