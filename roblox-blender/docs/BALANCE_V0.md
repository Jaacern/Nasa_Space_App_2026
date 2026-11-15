# Balance v0

Fecha: 14-11-2026.
Fuente única de los números: `game/src/shared/Balance.luau`. Si este documento y el código difieren, manda el código.
Unidades: studs, segundos y puntos de vida. Las cifras marcadas "derivado" se calculan aquí a partir de los valores del archivo; no están en el archivo.

## 1. Simulación

| Parámetro | Valor | Clave |
|---|---|---|
| Paso fijo del servidor | 1/20 s (20 pasos/s) | `Sim.Step` |
| Instantánea al cliente | cada 2 pasos = 10 Hz | `Sim.SnapshotEvery` |
| Enemigos máximos | 100 | `Sim.MaxEnemies` |
| Muestras (gemas) máximas | 160. Al llenarse, la última suma valor | `Sim.MaxGems` |
| Radio de la arena | 210 | `Sim.ArenaRadius` |
| Distancia de aparición | 58 a 74 del héroe | `Sim.SpawnMinDist`, `SpawnMaxDist` |
| Comandos del cliente por segundo | 20 | `Sim.MaxCmdsPerSecond` |

## 2. Modos

| Modo | Escala de tiempo | Multiplicador de XP | Etiqueta | Duración real (derivado) |
|---|---|---|---|---|
| `full` | ×1 | ×1 | Misión completa | 18 min (1080 s). Jefe final a los 17 min |
| `demo` | ×12 | ×2,6 | Demo rápida | ~2 min de juego (victoria en 95 s medidos con bot el 15-11-2026). Jefe final a los 85 s |

Línea de tiempo de la demo en reloj real (derivado: segundo de misión ÷ 10):

| Evento | Misión (s) | Demo (s) |
|---|---|---|
| Kamikaze aparece | 90 | 18 |
| Centinela iónico (a distancia) aparece | 180 | 36 |
| Minijefe 1 (oleada 5) | 240 | 48 |
| Gólem (tanque) aparece | 270 | 54 |
| Bioma 2 | 360 | 72 |
| Minijefe 2 (oleada 10) | 540 | 108 |
| Bioma 3 | 720 | 144 |
| Minijefe 3 (oleada 15) | 840 | 168 |
| Jefe final (oleada 18) | 1020 | 204 |

Un jefe aparece solo si no hay otro vivo. El director retrasa el siguiente hasta que cae el anterior.

## 3. Héroe

| Parámetro | Valor | Clave |
|---|---|---|
| Vida máxima | 100 | `Hero.MaxHp` |
| Velocidad | 16 studs/s | `Hero.WalkSpeed` |
| Radio | 1,5 | `Hero.Radius` |
| Intervalo de ataque | 0,6 s | `Hero.AttackInterval` |
| Daño por proyectil | 12 | `Hero.Damage` |
| Alcance | 48 | `Hero.Range` |
| Velocidad del proyectil | 110 | `Hero.ProjSpeed` |
| Radio del proyectil | 1,2 | `Hero.ProjRadius` |
| Apertura entre proyectiles | 9° | `Hero.SpreadDeg` |
| Probabilidad de crítico | 5 % | `Hero.CritChance` |
| Multiplicador de crítico | ×2 | `Hero.CritMult` |
| Radio de recogida | 9 | `Hero.PickupRadius` |
| Potencia de salto | 34 | `Hero.JumpPower` |
| Invulnerabilidad tras golpe | 0,35 s | `Hero.IFrames` |
| Pasiva "Soporte vital": espera sin daño | 6 s | `Hero.RegenDelay` |
| Pasiva "Soporte vital": regeneración | 1 vida/s | `Hero.RegenPerSec` |
| Gravedad (Marte, 0,38 g) | 74,5 studs/s² | `World.Gravity` |

Daño por segundo base (derivado): 12 ÷ 0,6 = 20 por segundo con un proyectil. El héroe ataca al enemigo más cercano dentro del alcance.

## 4. Habilidades

| Habilidad | Tecla | Espera | Efecto | Clave |
|---|---|---|---|---|
| Impulso RCS | Q | 8 s | Avanza 24 studs en 0,18 s. Daña 25 (× multiplicador de daño) en un ancho de 5. Invulnerable 0,45 s | `Skills.Dash` |
| Pulso de escudo | E | 12 s | Radio 18. Daña 40 (× multiplicador de daño) y empuja 16. Da 25 de escudo durante 4 s | `Skills.Pulse` |

El tope de reducción de espera es 0,4 del valor base (ver sección 11, `Caps.CdMult`). Esto es, el multiplicador de espera nunca baja de 0,4.

## 5. Enemigos comunes

`wind` es el aviso antes del ataque, en segundos. Todos los valores de vida y daño se multiplican por el escalado de la sección 6.

| Arquetipo (nombre en juego) | Vida | Velocidad | Daño | Radio | XP | Otros |
|---|---|---|---|---|---|---|
| `chaser` (Remolino de polvo) | 12 | 17 | 6 | 1,6 | 1 | Daño por contacto cada 0,8 s |
| `tank` (Gólem de regolito) | 80 | 8 | 16 | 3,0 | 5 | Aviso 0,8 s. Alcance 6. Radio del golpe 8. Espera 2,5 s |
| `ranged` (Centinela iónico) | 24 | 10 | 9 | 1,8 | 3 | Aviso 0,7 s. Alcance 36. Mantiene 20 a 30 de distancia. Espera 2,8 s. Disparo: velocidad 38, radio 1,3, vida 2,2 s |
| `kamikaze` (Meteoroide inestable) | 10 | 22 | 22 | 1,5 | 2 | Aviso 0,8 s. Alcance 6. Radio de explosión 9 |
| `elite` (una por bioma) | 420 | 11 | 20 | 4,0 | 25 | Espera entre patrones 3,2 s. Daño por contacto. Suelta un cofre |

Élites por bioma (`Content.Enemies`): bioma 1 Tolvanera mayor, bioma 2 Coloso de hielo, bioma 3 Heraldo solar. Patrón de la élite por bioma (`Patterns.elite`): `charge`, `slam`, `nova`.

## 6. Escalado por tiempo

Fórmulas (`Balance.hpMult` y `Balance.dmgMult`, con `m` = minutos de misión):

- Multiplicador de vida = 1 + 0,10·m + 0,004·m².
- Multiplicador de daño = 1 + 0,04·m.

Valores derivados:

| Minuto de misión | Vida ×  | Daño × | Vida de Remolino (12) | Vida de Gólem (80) |
|---|---|---|---|---|
| 0 | 1,000 | 1,00 | 12,0 | 80 |
| 3 | 1,336 | 1,12 | 16,0 | 106,9 |
| 6 | 1,744 | 1,24 | 20,9 | 139,5 |
| 10 | 2,400 | 1,40 | 28,8 | 192,0 |
| 14 | 3,184 | 1,56 | 38,2 | 254,7 |
| 17 | 3,856 | 1,68 | 46,3 | 308,5 |

Los jefes no usan este escalado: tienen vida fija (sección 8). Los daños de los jefes tampoco se escalan.

Experiencia necesaria para subir (`Balance.xpNeeded`): `floor(5 + 4·nivel + 0,6·nivel²)`.

| Nivel actual | XP para el siguiente |
|---|---|
| 1 | 9 |
| 2 | 15 |
| 3 | 22 |
| 4 | 30 |
| 5 | 40 |
| 10 | 105 |
| 15 | 200 |
| 20 | 325 |

La XP recibida se multiplica por el modo (×1 o ×2,6) y por los bonos de objetos, meta y pieza 2.

## 7. Director de oleadas

| Parámetro | Valor | Clave |
|---|---|---|
| Aparición inicial | 1,1 enemigos/s | `Director.RateBase` |
| Aumento por minuto | +0,30 enemigos/s | `Director.RatePerMinute` |
| Multiplicador durante un jefe | ×0,5 | `Director.BossRateMult` |
| Kamikaze desbloqueado | 90 s | `Director.UnlockKamikaze` |
| A distancia desbloqueado | 180 s | `Director.UnlockRanged` |
| Tanque desbloqueado | 270 s | `Director.UnlockTank` |
| Élite cada | 150 s (solo sin jefe vivo) | `Director.EliteInterval` |
| Cofre cada | 80 s de reloj real, no de misión (el primero a los 40 s). En la demo rápida no se acelera | `Director.ChestInterval` |
| Pesos de aparición | chaser 10, kamikaze 3, ranged 3, tank 2 | `Director.Weights` |

Tasa de aparición (derivado): minuto 0, 1,1/s. Minuto 6, 2,9/s. Minuto 12, 4,7/s. Minuto 17, 6,2/s. El tope de 100 enemigos limita la cifra real.

Oleadas (`Run`): `WaveLength` 60 s, `TotalWaves` 18. Número de oleada = `floor(t / 60) + 1`, con tope 18.

Biomas (`Run.BiomeTimes`: 0, 360, 720 s):

| Bioma | Nombre (`Content.Biomes`) | Peligro ambiental | Zonas por pulso | Intervalo |
|---|---|---|---|---|
| 1 | Llanura de regolito | Ninguno | 0 | 0 |
| 2 | Campo de cráteres | Lluvia de rocas | 3 | 9 s |
| 3 | Frente de tormenta solar | Erupciones | 5 | 7 s |

Peligro ambiental común (`Run`): radio 6, aviso 1,3 s, daño 14 (× multiplicador de daño). En el bioma 3, cada tercer pulso muestra una alerta con un evento real de DONKI (`NasaData.eventForAlert`).

## 8. Jefes

Orden de aparición: `boss1` (oleada 5), `boss2` (10), `boss3` (15), `final` (18). `cycle` es el tiempo entre patrones.

| Id | Nombre (`Content.Enemies`) | Vida | Velocidad | Daño | Radio | XP | Ciclo | Patrones |
|---|---|---|---|---|---|---|---|---|
| `boss1` | Tormenta de polvo global | 900 | 12 | 18 | 5 | 60 | 3,2 s | charge, summon |
| `boss2` | Coloso de la lluvia de rocas | 2200 | 9 | 22 | 6 | 90 | 3,0 s | slam, rocks |
| `boss3` | Heraldo de la erupción | 4000 | 11 | 24 | 5,5 | 120 | 2,8 s | nova, charge, rocks |
| `final` | Coloso de la tormenta solar | 8000 | 10 | 28 | 7 | 0 | 2,6 s | slam, nova, rocks, summon, charge |

El jefe final entra en furia al bajar de 35 % de vida (`enrageAt` 0,35): su ciclo pasa a 1,9 s (`enrageCycle`).

### Patrones (`Balance.Patterns`)

| Patrón | Aviso | Parámetros |
|---|---|---|
| `charge` | 1,0 s | Línea de 46 de largo y 7 de ancho (más el radio del enemigo) |
| `slam` | 1,2 s | Círculo de radio 15 sobre la posición del héroe |
| `rocks` | 1,3 s | 5 círculos de radio 6, dispersos hasta 14, con 0,12 s entre cada uno. Daño ×0,8 |
| `nova` | 1,0 s | 14 proyectiles, velocidad 30, radio 1,4, vida 3 s. Daño ×0,7 |
| `summon` | Sin aviso | Invoca 6 remolinos de polvo (respeta el tope de 100) |

### Bonos por pieza de la nave (`Balance.Pieces`)

| Pieza | Jefe | Bono |
|---|---|---|
| 1. Batería nuclear (MMRTG) | `boss1` | +1 vida/s y −10 % de espera de habilidades |
| 2. Antena de alta ganancia | `boss2` | +20 % de XP |
| 3. Generador de oxígeno | `boss3` | Cura 40 y +15 de vida máxima |
| 4. Propulsor de retorno | `final` | Victoria y despegue |

## 9. Mejoras de nivel (cartas)

Al subir de nivel salen 3 cartas distintas (1 de 3). Si el conjunto agota las mejoras, aparece "Reparación de campo" (cura 30, `LevelUpHeal`).
`max` es el máximo de niveles. `per` es el efecto por nivel. El nivel que da una carta depende de su rareza (sección 9.1).

| Id | Nombre | Máx. | Efecto por nivel | Datos extra |
|---|---|---|---|---|
| `damage` | Láser de mayor potencia | 5 | +20 % de daño | |
| `rate` | Disparo más rápido | 5 | +12 % de cadencia | |
| `multishot` | Haz dividido | 2 | +1 proyectil | Siempre épica |
| `pierce` | Haz perforante | 3 | +1 perforación | Siempre épica |
| `armor` | Traje reforzado | 5 | +20 de vida máxima | |
| `speed` | Servos de movilidad | 4 | +8 % de velocidad | |
| `magnet` | Imán de muestras | 4 | +30 % de radio de recogida | |
| `drone` | Dron orbital | 4 | +1 dron | Siempre épica. Daño 9, órbita 9, radio de golpe 3,2, velocidad angular 2,6, espera 0,5 s |
| `cooldown` | Recarga eficiente | 4 | −10 % de espera de habilidades | |
| `crit` | Puntería de precisión | 5 | +8 % de crítico | |
| `aura` | Campo electrostático | 4 | +5 de daño por pulso | Radio 10, intervalo 0,5 s |

### 9.1 Rareza de carta

| Rareza | 1 Común | 2 Rara | 3 Épica | 4 Legendaria |
|---|---|---|---|---|
| Peso base | 60 | 27 | 10 | 3 |
| Niveles que otorga | ×1 | ×1,5 | ×2 | ×3 |

Las mejoras "de unidades enteras" (`multishot`, `pierce`, `drone`) valen siempre 1 nivel y salen como carta épica (`UpgradeCount`).

Ejemplo (derivado): "Láser de mayor potencia" da +20 % (común), +30 % (rara), +40 % (épica) o +60 % (legendaria). El nivel total no pasa del máximo.

Suerte: cada nivel de la mejora permanente `luck` desplaza 5 puntos de peso (`LuckShift` 5 × `per` 1). El peso común baja ese valor (mínimo 10). La rara sube 0,5 de ese valor, la épica 0,3 y la legendaria 0,2. Los pesos se normalizan al sortear.

## 10. Objetos de cofre

Un cofre entrega 1 objeto (más 1 por cada "Mapa orbital"). Rareza del objeto: común 60, raro 30, épico 10 (`RarityWeights`). Los épicos no se repiten. Los cofres aparecen por el director, por las élites y tras los jefes 1 a 3.

| Id | Nombre | Cat. | Rar. | Efecto (por unidad) |
|---|---|---|---|---|
| `lens` | Lente de láser | Ofensiva | Común | +10 % de daño |
| `cell` | Celda de combustible | Ofensiva | Común | +8 % de cadencia |
| `spectro` | Espectrómetro | Ofensiva | Raro | +10 % de crítico |
| `ion` | Microimpulsor iónico | Ofensiva | Raro | +25 % de velocidad de proyectil y +1 perforación |
| `plasma` | Núcleo de plasma | Ofensiva | Épico | Cada 5.º disparo explota: radio 8, 60 % del daño |
| `pica` | Placa de escudo térmico | Defensa | Común | +15 de vida máxima |
| `mli` | Manta térmica multicapa | Defensa | Común | −6 % de daño recibido |
| `filter` | Filtro de CO2 | Defensa | Raro | +0,5 de vida/s |
| `whipple` | Escudo Whipple | Defensa | Raro | 10 % de bloquear un golpe |
| `shelter` | Refugio de tormenta | Defensa | Épico | Bajo 25 % de vida: 3 s de invulnerabilidad, cada 60 s |
| `boots` | Botas de tracción | Utilidad | Común | +6 % de velocidad |
| `arm` | Brazo robótico | Utilidad | Común | +25 % de radio de recogida |
| `solar` | Panel solar | Utilidad | Raro | +10 % de XP |
| `antenna` | Antena de alta ganancia | Utilidad | Raro | −8 % de espera de habilidades |
| `orbital` | Mapa orbital | Utilidad | Épico | +1 objeto por cofre |

Topes (`Balance.Caps`): reducción de daño 0,6, bloqueo 0,5, multiplicador de espera mínimo 0,4, crítico 0,8.

## 11. Fórmulas de estadísticas (`Loot.recompute`)

- Vida máxima = 100 + 20·`armor` + 15·`pica` + 10·`hp` meta + 15 (pieza 3).
- Multiplicador de daño = (1 + 0,20·`damage`) · (1 + 0,10·`lens`) · (1 + 0,05·`dmg` meta).
- Intervalo de ataque = 0,6 ÷ ((1 + 0,12·`rate`) · (1 + 0,08·`cell`)).
- Velocidad = 16 · (1 + 0,08·`speed` + 0,06·`boots` + 0,02·`speed` meta).
- Radio de recogida = 9 · (1 + 0,30·`magnet` + 0,25·`arm` + 0,10·`magnet` meta).
- Multiplicador de espera = máx(0,4; 1 − 0,10·`cooldown` − 0,08·`antenna` − 0,10 de pieza 1).
- Crítico = mín(0,8; 0,05 + 0,08·`crit` + 0,10·`spectro`).
- Reducción de daño = mín(0,6; 0,06·`mli` + 0,03·`armor` meta).

## 12. Meta-progresión

Se compra con "datos científicos" entre partidas. El costo de cada nivel es `costo × (nivel nuevo)`; por ejemplo, `armor` cuesta 40, 80, 120, 160 y 200.

| Id | Nombre | Máx. | Efecto por nivel | Costo base | Costo total (derivado) |
|---|---|---|---|---|---|
| `dmg` | Óptica calibrada | 5 | +5 % de daño | 40 | 600 |
| `hp` | Traje reforzado | 5 | +10 de vida máxima | 30 | 450 |
| `armor` | Blindaje del traje | 5 | −3 % de daño recibido | 40 | 600 |
| `speed` | Servos del traje | 5 | +2 % de velocidad | 30 | 450 |
| `magnet` | Colector ampliado | 3 | +10 % de radio de recogida | 30 | 180 |
| `xp` | Análisis de muestras | 5 | +5 % de XP | 40 | 600 |
| `luck` | Telemetría predictiva | 5 | Más cartas raras, épicas y legendarias | 50 | 750 |
| `revive` | Protocolo de emergencia | 1 | Una vez por misión: revive con 50 % de vida y lanza un pulso doble | 300 | 300 |

Costo total para comprar todo (derivado): 3930.

Ganancia de ciencia al terminar (`Meta`):

- 0,2 por baja (`SciencePerKill`).
- 10 por minuto de misión (`SciencePerMinute`).
- 40 por pieza recuperada (`SciencePerPiece`).
- 150 por victoria (`ScienceWin`).

Estimación (no medida): una victoria con unas 800 bajas da unos 180 + 160 + 160 + 150 = 650. Se necesitarían unas 6 victorias para comprarlo todo.

## 13. Cámara, juice y tutorial

| Grupo | Valores | Clave |
|---|---|---|
| Cámara | Distancia 27 (14 a 42). Inclinación 24° (6° a 72°). FOV 80. Altura de foco 3,5. Sensibilidad 0,0036. Sacudida máxima 0,35 | `Camera` |
| Ajustes del jugador | FOV 60 a 100 en pasos de 5. Sensibilidad 0,4 a 2,6 en pasos de 0,2. Efectos ALTOS o BAJOS | `game/src/client/Hud.luau` |
| Juice | Hitstop 0,04 s (baja) y 0,06 s (grande). Destello 0,08 s. Pausa al subir de nivel 0,15 s. Variación de tono ±5 %. Vida del número de daño 0,6 s | `Juice` |
| Tutorial | Moverse 20 studs. 3 muñecos. Aviso de peligro 2 s | `Tutorial` |

## 14. Qué probar y cómo ajustar

Todas las pruebas usan Studio. Los atajos de depuración están en `docs/NOTAS.md`.
Regla: cambia un solo valor por prueba, en `Balance.luau`, y vuelve a sincronizar.

| Qué probar | Cómo | Señal de problema | Qué ajustar |
|---|---|---|---|
| Ritmo de subida de nivel | Demo rápida. Anotar el nivel en cada jefe | Menos de nivel 6 al minijefe 1, o más de nivel 15 al final | `Modes.demo.XpMult`, `Scaling.XpBase`, `XpLinear`, `XpQuad` |
| Duración del minijefe 1 | `debug xp` para subir cartas; medir hasta que cae | Más de 60 s sin mejoras | `Bosses[1].hp` |
| Dificultad de jefes | Partida completa sin atajos | El jefe final mata antes del segundo 1080 | `Bosses[n].hp`, `dmg`, `cycle` |
| Densidad de enemigos | Ver el contador de enemigos en el minuto 12 | Más de 100 sostenido, o menos de 40 | `Director.RateBase`, `RatePerMinute`, `Weights` |
| Legibilidad de avisos | Pedir a otra persona que juegue sin explicación | Recibe daño sin ver el aviso | `Patterns.*.delay`, `Run.HazardDelay` |
| Peligro del bioma 2 y 3 | Atajo `time` a 360 y a 720 | Muertes inmediatas o ninguna amenaza | `Run.HazardCount`, `HazardInterval`, `HazardDmg` |
| Mejoras dominantes | Repetir 5 partidas; anotar qué cartas se eligen | Una carta aparece en todas las victorias | `Upgrades.*.per`, `max` |
| Objetos fuertes | Atajo `item` con cada id | Un objeto resuelve toda la partida | `Items.*.per`, `Caps` |
| Economía meta | Terminar 3 partidas y comprar | Todo comprado en menos de 4 partidas | `Meta.*.cost`, `SciencePer*` |
| Salto y gravedad | Saltar durante el combate | El salto evita todos los avisos | `Hero.JumpPower`, `World.Gravity` |
| Cámara | Jugar 5 min en PC y móvil | Mareo, o el héroe tapado | `Camera.Distance`, `Pitch`, `Fov` |
| Rendimiento | Atajo `time` a 900 y mirar FPS | Menos de 60 FPS (PC) o 30 FPS (móvil) | `Sim.MaxEnemies`, efectos bajos, `Sim.SnapshotEvery` |

Los umbrales de la columna "Señal de problema" son propuestas de esta documentación. No salen del código. Se validan en las partidas de prueba.

Criterio del prompt maestro (F5): balance con 5 partidas de prueba. Estado: 0 de 5 `[PENDIENTE]`.
