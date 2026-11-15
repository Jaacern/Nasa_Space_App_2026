# Guion de la partida de pitch (demo de 2 minutos)

Fecha: 15-11-2026. Sustituye al guion de 3 minutos del 14-11-2026.
Estado: tiempos medidos con un bot en Studio (3 partidas completas). **Sin ensayar con una persona.**

## 1. Idea central

El botón **DEMO RÁPIDA** del menú lanza una partida completa pensada para el pitch. No hacen falta atajos de depuración.

| Ajuste (`Balance.Modes.demo`) | Valor | Para qué |
|---|---|---|
| `TimeScale` | 12 | Las 18 oleadas pasan en 85 s |
| `XpMult` | 2,6 | Una carta de mejora cada 6 a 8 s |
| `BossHp` | 0,22 | Cada jefe cae en 7 a 10 s |
| `EnemyHp` / `EnemyDmg` | 0,45 / 0,25 | Mucha acción y poco riesgo |
| `SpawnMult` | 1,5 | Hay enemigos desde el primer segundo |
| `FreeRevive` | sí | Si la vida llega a 0, el «Protocolo de emergencia» te levanta una vez |
| `Briefing` / `Checkpoints` | no | Entra directo al combate y no escribe en el guardado |

Medición del 15-11-2026 con un bot que camina en círculo y **no esquiva**: victoria a los 95 s de juego, 105 s de reloj, nivel 15, 420 bajas y 98 golpes recibidos sin morir. Con `TimeScale = 10` las tres partidas de prueba dieron 111, 115 y 111 s.

El reloj del juego se detiene mientras eliges carta o lees una pieza. Con una persona leyendo, calcula entre 2:00 y 2:15 de reloj.

## 2. Preparación (10 minutos antes)

- [ ] Studio abierto con el lugar «Núcleo de Ares» y la Salida sin errores.
- [ ] Una partida de calentamiento completa en Demo rápida, y volver al menú.
- [ ] Ventana a 1920×1080, sonido encendido, notificaciones apagadas.
- [ ] Vídeo de respaldo abierto en otra ventana (plan B).
- [ ] Quién habla, quién juega y quién vigila el reloj.

## 3. La partida, paso a paso

Tiempos de juego (los que marca el bot). Una persona habla y otra juega.

| Juego | Qué pasa en pantalla | Qué hace quien juega | Qué decir |
|---|---|---|---|
| Antes | Menú con la nave y la órbita de cámara | Nada, 5 s. Luego DEMO RÁPIDA | "Esto es ARES FORGE. Tu nave cayó en Marte. Recupera sus 4 piezas y vuelve a casa." |
| 0:00 a 0:20 | Remolinos de polvo, muestras doradas | Caminar en círculo alrededor de la nave. Recoger muestras | "El láser dispara solo. Yo me muevo y recojo muestras." |
| ~0:13 | Primera carta de mejora | Leer el «Dato real» y pulsar 1, 2 o 3 | "Cada mejora trae un dato real de una misión a Marte." |
| 0:20 | **Jefe 1**: Tormenta de polvo global | Esquivar la carga con Q. Usar el escudo con E | "Los círculos naranjas avisan antes de cada golpe." |
| ~0:28 | **Pieza 1**: Batería nuclear (MMRTG) | Dejar el panel 3 s. CONTINUAR | Frase 1 de la sección 4 |
| 0:30 | Etapa 2: Campo de cráteres. Cambia el cielo | Pulsar F: pasar a Abanico | "Cada etapa cambia el terreno. Con F cambio el modo del arma." |
| 0:45 | **Jefe 2**: Coloso de la lluvia de rocas | Salir de los círculos | "Cada jefe guarda un sistema de la nave." |
| ~0:48 | Anomalía en el horizonte (agujero negro) | Girar la cámara hacia el horizonte un segundo | "En el cielo aparecen objetos reales observados por Chandra." |
| ~0:52 | **Pieza 2**: Antena de alta ganancia | CONTINUAR | "La antena devuelve el enlace de datos: más experiencia." |
| 1:00 | Etapa 3: Frente de tormenta solar. Alerta de clima espacial | Seguir en movimiento | Frase 2 de la sección 4 |
| 1:10 | **Jefe 3**: Heraldo de la erupción | Pulsar F: Mortero para los grupos | "El mortero limpia grupos enteros." |
| ~1:19 | **Pieza 3**: Generador de oxígeno | CONTINUAR | "Oxígeno a partir del CO2 de Marte." |
| 1:25 | **Jefe final**: Coloso de la tormenta solar | Q para esquivar, E para el escudo | "Último sistema: el propulsor de retorno." |
| ~1:35 | **Pieza 4** y despegue (5,5 s) | CONTINUAR y soltar el teclado | Frase 3 de la sección 4 |
| Final | Informe de misión | Nada | "Misión cumplida. Gracias." |

Consejos para quien juega:

- Elige cartas con las teclas 1, 2 y 3. No uses el ratón.
- Si salen varias cartas seguidas (pasa al caer un jefe), elige siempre la 1.
- No te quedes quieto: el bot sobrevive caminando en círculo a unos 40 studs de la nave.
- Si la vida baja de 30, usa E y aléjate. El Protocolo de emergencia te cubre una vez.

## 4. Frases de apoyo

Salen de los textos del juego (`game/src/shared/Content.luau`, `game/src/shared/NasaData.luau`). No digas "según NASA".

1. Pieza 1: "Un generador termoeléctrico de radioisótopos convierte en electricidad el calor de un material radiactivo. Funciona de día, de noche y con polvo. Referencia: ficha NTRS 20150005587."
2. Alerta de clima espacial: "Esta alerta sale de un evento real de la base DONKI, copia del 14-11-2026. El efecto en el juego es de diseño."
3. Pieza 4: "El módulo de servicio de Orion usa propelentes que se encienden al mezclarse. Referencia: ficha NTRS 20240003648."

Las cuatro piezas tienen ficha NTRS verificada (`20150005587`, `20040084278`, `20205007222`, `20240003648`). No des cifras de la antena ni del generador de oxígeno que no estén en el panel.

## 5. Atajos de depuración (solo ensayos en Studio)

La partida de pitch no los necesita. Sirven para repetir un tramo:

```lua
local cmd = game.ReplicatedStorage.Remotes.Cmd
cmd:FireServer("debug", "time", 540)      -- salta a la oleada 10 (jefe 2 si el 1 ya cayó)
cmd:FireServer("debug", "bosshp", 50)     -- baja la vida del jefe vivo
cmd:FireServer("debug", "hp", 100)        -- recupera vida
cmd:FireServer("debug", "invincible", true)
```

Si usas `invincible` ante el jurado, dilo si te lo preguntan.

## 6. Plan B

| Falla | Respuesta |
|---|---|
| Studio no abre o se cuelga | Vídeo de respaldo. Una persona narra encima con este guion |
| Texto rojo en la Salida | No lo menciones. Si el juego sigue, continúa |
| Mueres dos veces | REINTENTAR en el informe. Di: "La demo también se puede perder" y sigue |
| Se acaba el tiempo | Pausa con P y pasa al cierre del pitch |
| No hay sonido | Continúa |

## 7. Ensayos

Objetivo: 3 seguidos sin fallos (P-13).

| Ensayo | Fecha | Quién | Duración de reloj | Fallos |
|---|---|---|---|---|
| Bot ×10 (3 partidas) | 15-11-2026 | Bot en Studio | 122 a 124 s | Ninguno. Consola limpia |
| Bot ×12 | 15-11-2026 | Bot en Studio | 105 s | Ninguno. Consola limpia |
| 1 | `[PENDIENTE]` | | | |
| 2 | `[PENDIENTE]` | | | |
| 3 | `[PENDIENTE]` | | | |

## 8. Documentos relacionados

- Discurso: `docs/PITCH.md`
- Tráiler: `docs/TRAILER.md`
- Valores de la demo: `game/src/shared/Balance.luau` (`Balance.Modes.demo`) y `docs/BALANCE_V0.md`
