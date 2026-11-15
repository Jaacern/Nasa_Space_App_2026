# Brief de producción: ARES FORGE

Fecha: 14-11-2026. Equipo de 3 personas (diseño y arte, programación Roblox, arquitectura web). Sede: Concepción, Chile.
Evento: NASA International Space Apps Challenge 2026. Desafío: "Space Mission Design Game".

## Concepto

ARES FORGE es un roguelite de supervivencia 3D en tercera persona. Una nave cae en la superficie de Marte. El jugador sobrevive a oleadas de peligros, derrota a 4 jefes y recupera 4 piezas de la nave: batería nuclear (MMRTG), antena de alta ganancia, generador de oxígeno y propulsor de retorno. Con la cuarta pieza, la nave despega.
Cada pieza muestra un texto "En la realidad" con una explicación técnica breve. El clima espacial real aparece en la telemetría y en las alertas.

## Público

- Jugadores de roguelites de ritmo rápido, en PC y móvil (Q1).
- Jurado del concurso: evalúa game feel, innovación técnica, impacto educativo y presentación (Q20).

## Pilares

En orden de prioridad (prompt maestro, sección 5):

1. **Game feel.** Cada acción responde al instante.
2. **Legibilidad.** Los avisos de ataque se ven en el suelo antes de golpear.
3. **Builds con sinergias.** Cartas y objetos se combinan.
4. **Rendimiento estable.** Se mide, no se supone.
5. **Identidad propia.** Las referencias dan lectura, no contenido.

## Bucle de juego

1. El héroe se mueve; su láser dispara solo al enemigo más cercano.
2. Los enemigos mueren y sueltan muestras (XP).
3. Al subir de nivel, el jugador elige 1 de 3 cartas con rareza.
4. Los cofres entregan objetos con efecto medible.
5. Cada oleada dura 60 s. Los minijefes llegan en las oleadas 5, 10 y 15. El jefe final llega en la oleada 18.
6. Cada jefe suelta una pieza de la nave. La cuarta da la victoria.
7. El informe de misión da "datos científicos". Se gastan en mejoras permanentes entre partidas.

Parámetros: `game/src/shared/Balance.luau`. Tablas completas: `docs/BALANCE_V0.md`.

## Alcance de la jam

**Dentro:**

- 1 héroe, 2 habilidades activas y 1 pasiva.
- 4 arquetipos de enemigo, 3 élites (una por bioma), 3 minijefes y 1 jefe final.
- 3 biomas, 11 mejoras de nivel, 15 objetos, 8 mejoras permanentes.
- Tutorial guiado y arena de práctica.
- Modo "Demo rápida" para el pitch.
- Datos de clima espacial de NASA DONKI (copia local) y 4 fichas NTRS verificadas.
- Guardado con DataStore.

**Fuera:**

- Cooperativo (Q2).
- Llamadas en vivo a NASA.
- Desbloqueo de héroes y de objetos nuevos (decisión pendiente, P-08).
- Tablas de clasificación, cofres de pago y tienda.
- Subir assets a Roblox.

## Riesgos y mitigaciones

| Id | Riesgo | Probabilidad | Mitigación |
|---|---|---|---|
| R-01 | El rendimiento con 100 enemigos no llega a 60 FPS en PC o 30 FPS en móvil | Media | Simulación numérica en el servidor, pooling en el cliente, modo de efectos bajos. Medir (P-05) |
| R-02 | La demo falla en vivo | Media | Plan B en `docs/DEMO_GUION.md`. Tres ensayos seguidos (P-13) |
| R-03 | DataStore no guarda en el lugar publicado | Baja | Modo en memoria sin guardado. Verificar (P-03) |
| R-04 | Un dato NASA se presenta sin verificar | Baja | Solo se usan datos de `docs/NASA_APIS.md` y fichas NTRS verificadas. Antena y oxígeno sin cifras |
| R-05 | Falla la red durante el pitch | Media | El juego no necesita red. Los datos NASA son una copia local |
| R-06 | Las mallas de Blender no llegan a tiempo | Baja (mitigado) | Las 30 mallas de Blender ya están exportadas (`CATALOGO_BLENDER.md`) e integradas en cliente (`EditableMesh` `FixedSize = true`) con respaldo en `Templates` |
| R-07 | La demo rápida otorga la misma ciencia que la misión completa y rompe la meta-progresión | Media | Aceptable para el pitch. Si se publica, limitar la ciencia del modo demo (`Balance.Meta`) |
| R-08 | Una clave de NASA expuesta sigue activa | Alta hasta rotarla | Rotar y crear clave propia en el entorno del servidor (P-04) |
| R-09 | Cámara orbital poco legible en móvil | Media | Probar en móvil real (P-11). Ajustar FOV y distancia |
| R-10 | Audio provisional resta calidad percibida | Media | Cerrar P-12 antes del trailer |

## Definición de terminado por fase

Estado real al 14-11-2026. Criterios: prompt maestro, sección 11.

| Fase | Criterio de aceptación | Estado | Qué falta |
|---|---|---|---|
| F0 Pre-producción | Q1 a Q20 registradas; `[PENDIENTE]` con dueño y fecha | **Hecha** con este documento y `docs/DECISIONES.md` | Confirmar las fechas objetivo |
| F1 Prototipo | 100 enemigos de prueba sin bajar del objetivo de FPS | **Parcial (medido en Studio).** Héroe, enemigos, XP y nivel funcionan. Sondeo en `docs/perf/RENDIMIENTO.md` con 92→98 enemigos (15 FPS por capado en segundo plano, 547 MB) | Repetir medición en primer plano a 60 FPS y en móvil real (P-05, P-11) |
| F2 Ciclo de juego | Una partida completa sin errores en la Salida | **Hecha en modo demo** el 14-11-2026: 4 jefes, 4 piezas, despegue e informe (`MISIÓN CUMPLIDA`) y tutorial verificados. 15 objetos, cofres, victoria y derrota implementados | Repetir la misión completa de 18 min |
| F3 Arte híbrido | PASS de `roblox-export` y `qa-review` | **Avanzada.** 30/30 mallas de Blender exportadas (`PASS` en `CATALOGO_BLENDER.md`) e integradas en cliente con `EditableMesh` (`FixedSize = true`); interfaz y efectos hechos | Iluminación `Future` (P-01) |
| F4 Meta y guardado | Guardado verificado tras reiniciar la sesión de prueba | **Parcial.** Código escrito con reintentos | Verificar en lugar publicado (P-03). Desbloqueos de Q10 (P-08) |
| F5 Pulido | Lista de la sección 9 completa; balance con 5 partidas | **Parcial.** Game feel, tutorial y ajustes hechos | Música, audio propio (P-12). 5 partidas de balance. Medir móvil |
| F6 Presentación | La demo corre sin fallos en 3 ensayos seguidos | **No empezada** en ensayo. Guiones escritos: `docs/DEMO_GUION.md`, `docs/TRAILER.md`, `docs/PITCH.md` | Ensayos (P-13). Grabar tráiler |

## Documentos relacionados

- Decisiones y pendientes: `docs/DECISIONES.md`
- Números del juego: `docs/BALANCE_V0.md`
- Assets: `docs/ASSETS.md`
- Referencias: `docs/REFERENCIAS.md`
- Bitácora técnica: `docs/NOTAS.md`
- Demo, tráiler y pitch: `docs/DEMO_GUION.md`, `docs/TRAILER.md`, `docs/PITCH.md`
