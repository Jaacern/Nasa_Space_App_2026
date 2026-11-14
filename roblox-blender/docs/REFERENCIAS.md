# Referencias de diseño

Fecha: 14-11-2026.
Regla (prompt maestro, secciones 4 y 14): se toman principios de diseño y de lectura visual. No se copian modelos, texturas, sonidos, textos, nombres ni arte de otros juegos.

## 1. Referencias y qué aporta cada una

| Referencia | Qué aporta a ARES FORGE |
|---|---|
| Final Swarm (Roblox, Evolution Studio Games) | Mecánicas de género en Roblox: tercera persona, oleadas numeradas y mejoras en árbol |
| Megabonk | Ritmo rápido, hordas y progresión por nivel en 3D |
| Risk of Rain 2 | Lectura de objetos y estilo 3D legible con siluetas claras |

## 2. Final Swarm

La ficha del juego en Roblox dice "Inspired by Megabonk & Archero". Es el juego de Roblox más cercano a nuestro género y plataforma.

### Qué se toma

| Mecánica de Final Swarm | Cómo se usa en ARES FORGE | Dónde está |
|---|---|---|
| Tercera persona | Cámara orbital libre (ratón, arrastre táctil o stick derecho) | `game/src/client/Main.client.luau` |
| Oleadas numeradas, con oleadas de jefe | 18 oleadas de 60 s. Jefes en las oleadas 5, 10, 15 y 18 | `Balance.Run` |
| Cartas de mejora 1 de 3 con rareza (común, rara, épica, legendaria) | Mismo esquema, con pesos 60, 27, 10 y 3 | `Balance.CardRarity` |
| Mejoras permanentes tipo árbol: daño, vida, defensa, velocidad, recogida y suerte | 8 mejoras permanentes: `dmg`, `hp`, `armor`, `speed`, `magnet`, `xp`, `luck`, `revive` | `Balance.Meta` |
| Consejo de "kitear" en círculos | Mensaje para el tutorial o la pantalla de carga | `[PENDIENTE]`: aún no está en `Content.Tutorial` |
| Ajuste de FOV | Ajustes: 60 a 100 | `game/src/client/Hud.luau` |
| Modo de efectos bajos | Ajustes: efectos ALTOS o BAJOS | `game/src/client/Hud.luau`, `Fx.setLow` |

### Qué no se toma, y por qué

| Elemento | Motivo |
|---|---|
| Llaves o cofres de pago | El juego no tiene tienda ni pagos. El cofre se gana jugando |
| Tablas de clasificación | Una sesión independiente por jugador (Q2). Fuera del alcance de la jam |
| Nombres de armas y de objetos | Regla de no copiar. Todos los nombres son propios y tienen base técnica (por ejemplo "Escudo Whipple") |
| Arte, sonido y textos | Regla de no copiar |

### Aviso sobre las cifras

Los datos de las guías son de fans y aproximados. No se usaron como cifras del juego. Todos los números de ARES FORGE salen de `game/src/shared/Balance.luau` y se ajustan con pruebas propias (`docs/BALANCE_V0.md`, sección 14).

## 3. Megabonk

Se toma el principio: partidas cortas, hordas que crecen con el tiempo y subidas de nivel frecuentes. No se toman nombres, personajes ni arte.
Efecto en el diseño: el director de oleadas aumenta la tasa de aparición con el tiempo (`Balance.Director`) y la XP escala con el nivel (`Balance.xpNeeded`).

## 4. Risk of Rain 2

Se toma el principio de lectura: objetos que se acumulan y cambian la forma de jugar, siluetas claras, color saturado y jefes anunciados.
Efecto en el diseño:

- 15 objetos con efecto medible y una descripción corta (`Balance.Items`, `Content.Items`).
- Un código de color por función: jugador cian, enemigos rojo o magenta, recompensas doradas, peligro naranja (`game/src/shared/Visuals.luau`).
- Cada ataque de jefe se anuncia en el suelo con 1 a 2 s de aviso.

## 5. Qué hace distinto a ARES FORGE

- Tema y contenido educativo: cada jefe entrega una pieza real de una nave espacial y un texto "En la realidad".
- Datos reales: clima espacial de NASA DONKI en la telemetría y en las alertas (copia local fechada).
- Gravedad de Marte (0,38 g) en el salto.
- Pipeline Blender a Roblox con un puente propio y auditado (`docs/SEGURIDAD_MCP.md`, `docs/PROCESOS_MCP.md`).

## 6. Fuentes consultadas

Todas se consultaron el 14-11-2026.

1. Final Swarm, ficha en Roblox: https://www.roblox.com/games/99521272836282/Final-Swarm
2. Wiki de Final Swarm: https://final-swarm.wiki/
3. Sitio de Final Swarm: https://finalswarm.xyz/
4. Guía para principiantes de Final Swarm: https://roonby.com/2026/07/19/final-swarm-beginners-guide-best-upgrades-movement-tips-and-skill-tree-progression/

Las fuentes 2, 3 y 4 son de fans o de terceros. Su información es aproximada.
