# Guion de la demo de 3 minutos (F6)

Fecha: 14-11-2026. Estado: guion escrito. **Ningún tiempo está ensayado ni medido.** Los tiempos son un objetivo. Se ajustan en los ensayos (P-13).
Criterio de la fase F6: la demo corre sin fallos en 3 ensayos seguidos.

## 1. Idea central

La demo usa el modo **Demo rápida**: el tiempo de misión corre ×5 y la XP sube ×3,2 (`Balance.Modes.demo`). La misión completa dura unos 3,6 minutos de reloj real (jefe final a los 204 s), sin contar las pausas de cartas y de piezas. Eso no cabe en 3 minutos con comentarios. Por eso el guion usa los atajos de depuración de Studio para saltar entre jefes (`docs/NOTAS.md`, sección 4).

Una persona habla. Una segunda persona maneja el juego si es posible.

## 2. Preparación (10 minutos antes)

Lista de verificación:

- [ ] Studio abierto con el lugar sincronizado desde `game/src/` (`docs/NOTAS.md`, sección 2). Servidor local detenido.
- [ ] `Lighting.Technology = Future` puesto a mano (P-01).
- [ ] Salida de Studio limpia: sin errores rojos.
- [ ] Una prueba rápida de 30 s en Demo rápida, y volver al menú.
- [ ] Pantalla en 1920×1080. Sonido encendido. Notificaciones del sistema apagadas.
- [ ] Barra de comandos de Studio lista, con las líneas de depuración copiadas (sección 5).
- [ ] Vídeo de respaldo grabado y abierto en otra ventana (plan B). **Pendiente de grabar.**
- [ ] Segunda ventana con `docs/PITCH.md` abierto.
- [ ] El equipo sabe quién habla, quién juega y quién vigila el reloj.

## 3. Guion cronometrado

Los tiempos son del reloj de la presentación (de 0:00 a 3:00). "Demo" indica el estado del juego. Las líneas entre comillas son lo que se dice.

| Tiempo | Qué se ve | Acción | Qué decir |
|---|---|---|---|
| 0:00 a 0:15 | Menú con la nave estrellada y la órbita lenta de la cámara | Nadie toca nada. Mostrar el título | "Esto es ARES FORGE. Tu nave cayó en Marte. Debes recuperar sus 4 piezas y volver a casa." |
| 0:15 a 0:25 | Menú | Pulsar DEMO RÁPIDA | "Esta es la demo rápida: el tiempo corre cinco veces más rápido. Una misión completa dura 18 minutos." |
| 0:25 a 0:50 | Oleadas 1 a 3. Enemigos en grupo, números de daño | Moverse en círculos. Esquivar con Q una vez | "El láser dispara solo. Yo solo me muevo y esquivo. Mira los círculos naranjas en el suelo: avisan antes del golpe." |
| 0:50 a 1:05 | Subida de nivel, tres cartas | Elegir una carta con la tecla 1, 2 o 3 | "Al subir de nivel elijo 1 de 3 mejoras. Tienen rareza: común, rara, épica o legendaria." |
| 1:05 a 1:25 | Minijefe 1 (oleada 5). Barra de jefe | Esquivar el aviso del jefe. Atajo si tarda: `bosshp` | "El primer jefe anuncia cada ataque en el suelo. Al vencerlo suelta una pieza de la nave." |
| 1:25 a 1:45 | Panel "Pieza recuperada: Batería nuclear (MMRTG)" | Dejar el panel abierto. La simulación está en pausa. Pulsar CONTINUAR al terminar | Leer el texto "En la realidad" del panel (sección 4, línea 1) |
| 1:45 a 2:00 | Bioma 2. Cambia el color del cielo y del suelo | Atajo: `time` 540. Jefe 2 aparece | "Cada pieza viene de un jefe y cada jefe vive en un bioma. Salto al segundo bioma." |
| 2:00 a 2:15 | Jefe 2. Pieza 2 | Atajo: `bosshp` 100 | "Antena de alta ganancia: su bono es más experiencia, porque vuelve el enlace de datos." |
| 2:15 a 2:35 | Bioma 3. Alerta "ALERTA DE CLIMA ESPACIAL" con una fecha real | Atajo: `time` 840. Esperar la alerta (unos 4 s) | Leer la alerta (sección 4, línea 2) |
| 2:35 a 2:50 | Jefe final. Pieza 4 | Atajo: `time` 1020 tras caer los anteriores. `bosshp` 200 | "El jefe final suelta el propulsor de retorno. Con él, la nave puede despegar." |
| 2:50 a 3:00 | Despegue e informe de misión | Dejar que corra la cinemática | "Misión cumplida. Gracias." (el pitch continúa en `docs/PITCH.md`) |

Nota: el despegue dura unos 5,5 s antes de que aparezca el informe (`game/src/client/Main.client.luau`).

Los atajos dependen del orden de jefes (`R.bossIdx`). `time` no salta jefes. Si usas `time` 540 con el jefe 1 vivo, el jefe 2 no aparece hasta que caiga el jefe 1. Ensaya el orden exacto (P-13).

## 4. Frases de apoyo

Las líneas salen de los textos del juego (`game/src/shared/Content.luau`, `game/src/shared/NasaData.luau`). No digas "según NASA".

1. Pieza 1 (MMRTG): "Un generador termoeléctrico de radioisótopos convierte en electricidad el calor de un material radiactivo. Funciona de día, de noche y con polvo. La referencia técnica es la ficha NTRS 20150005587."
2. Alerta de clima espacial: "Esta alerta se basa en un evento real registrado en la base de datos DONKI, copia del 14-11-2026. El efecto en el juego es de diseño."
3. Pieza 4 (propulsor): "El módulo de servicio de Orion usa propelentes que se encienden al mezclarse. Referencia: ficha NTRS 20240003648."

No cites cifras de la antena ni del generador de oxígeno. Su referencia NTRS está pendiente (P-06).

## 5. Atajos de depuración (solo Studio)

Se escriben en la barra de comandos con contexto de cliente `VERIFICAR EN STUDIO`.

```lua
local cmd = game.ReplicatedStorage.Remotes.Cmd
cmd:FireServer("debug", "time", 540)      -- bioma 2 y jefe 2 (si el jefe 1 ya cayó)
cmd:FireServer("debug", "bosshp", 100)    -- baja la vida del jefe vivo
cmd:FireServer("debug", "time", 840)      -- bioma 3 y jefe 3
cmd:FireServer("debug", "time", 1020)     -- jefe final
cmd:FireServer("debug", "hp", 100)        -- recupera vida
```

`invincible` sirve para los ensayos. En la demo ante el jurado, si lo activas, dilo si te lo preguntan. Es un modo de presentación.

## 6. Plan B

| Falla | Señal | Respuesta |
|---|---|---|
| Falla la red del lugar | Internet cae o la página no carga | El juego en Studio no usa los datos de NASA en vivo: la telemetría y las alertas salen de una copia local (`NasaData.luau`). Seguir con Studio. Decir: "El juego muestra la copia guardada del 14-11-2026" |
| Studio no abre el lugar | Error al abrir | Abrir el vídeo de respaldo. Una persona narra encima con el mismo guion |
| El juego arroja un error en la Salida durante la demo | Texto rojo | No lo menciones. Si el juego sigue, continúa. Si se congela, reiniciar con Stop y Play y saltar al minuto 1:45 con los atajos |
| Un atajo no hace nada | El jefe no aparece | Comprobar si hay un jefe vivo (los atajos de tiempo no saltan jefes). Usar `bosshp` primero |
| El audio no suena | Silencio | Continuar. El audio actual es provisional (P-12) |
| Se acaba el tiempo | El reloj marca 2:30 y el jefe final no ha caído | Saltar a la cinemática: `bosshp` 1 en el jefe final |

El vídeo de respaldo debe mostrar el bucle completo (menú, jefe, pieza, bioma 3, despegue e informe) en menos de 2 minutos. **Pendiente de grabar.**

## 7. Ensayos

Se registran aquí cada ensayo, con fecha y resultado. Objetivo: 3 seguidos sin fallos.

| Ensayo | Fecha | Duración real | Fallos | Resultado |
|---|---|---|---|---|
| 1 | `[PENDIENTE]` | | | |
| 2 | `[PENDIENTE]` | | | |
| 3 | `[PENDIENTE]` | | | |

## 8. Documentos relacionados

- Discurso: `docs/PITCH.md`
- Tráiler: `docs/TRAILER.md`
- Atajos: `docs/NOTAS.md`, sección 4
- Tiempos de la demo rápida: `docs/BALANCE_V0.md`, sección 2
