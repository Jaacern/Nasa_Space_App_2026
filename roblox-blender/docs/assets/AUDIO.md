# Audio de ARES FORGE

Fecha: 14-11-2026.
Configuración fuente: tabla `Balance.Audio` en `game/src/shared/Balance.luau`.
Reproductor en cliente: `game/src/client/Fx.luau` (`Fx.init`, `Fx.play`, `Fx.setMusic`, `Fx.update`).

## 1. Música por capas (`Balance.Audio.Music`)

`Fx.luau` soporta 3 capas musicales simultáneas en bucle alojadas en `SoundService` (`Music_calm`, `Music_combat`, `Music_boss`). Cuando una entrada es `""`, `Fx.init` la omite y esa capa queda en silencio sin provocar errores.

| Clave | Estado actual | Objetivo cuando esté activa | Mezcla en `Fx.setMusic(level)` |
|---|---|---|---|
| `calm` | `""` (en silencio) | Menú, cinemática de despegue y resumen | Volumen objetivo `0,4` en los tres modos (`calm`, `combat`, `boss`) |
| `combat` | `""` (en silencio) | Combate general y tutorial | Volumen objetivo `0,4` en `combat` y `boss`; `0` en `calm` |
| `boss` | `""` (en silencio) | Enfrentamiento contra minijefes y jefe final | Volumen objetivo `0,4` en `boss`; `0` en `calm` y `combat` |

La transición de volumen de cada capa se interpola en `Fx.update(dt)` con paso `math.min(1, dt * 1.5)` hasta su volumen objetivo (`0` o `0,4`).

## 2. Efectos de sonido (`Balance.Audio.Sfx`)

Actualmente los 11 efectos usan sonidos integrados de Roblox (`rbxasset://sounds/...`) como reemplazo provisional funcional:

| Clave | Asset actual (provisional) | `vol` | `pitch` | Uso principal |
|---|---|---|---|---|
| `shoot` | `rbxasset://sounds/action_jump.mp3` | 0,12 | 2,2 | Disparo del héroe |
| `hit` | `rbxasset://sounds/action_jump_land.mp3` | 0,25 | 1,6 | Impacto sobre enemigo |
| `kill` | `rbxasset://sounds/impact_water.mp3` | 0,20 | 1,8 | Enemigo derrotado |
| `boom` | `rbxasset://sounds/impact_explosion_03.mp3` | 0,50 | 1,0 | Explosión / área |
| `hurt` | `rbxasset://sounds/action_falling.ogg` | 0,50 | 1,4 | Daño recibido por el héroe |
| `gem` | `rbxasset://sounds/volume_slider.ogg` | 0,35 | 1,5 | Recogida de muestra de XP |
| `level` | `rbxasset://sounds/action_get_up.mp3` | 0,60 | 1,5 | Subida de nivel y recuperación de pieza (0,8× pitch) |
| `chest` | `rbxasset://sounds/action_get_up.mp3` | 0,60 | 1,1 | Apertura de cofre |
| `ui` | `rbxasset://sounds/volume_slider.ogg` | 0,40 | 1,0 | Pulsación de interfaz y avance de tutorial (1,4× pitch) |
| `skill` | `rbxasset://sounds/action_jump.mp3` | 0,50 | 0,8 | Activación de Impulso RCS o Pulso |
| `warn` | `rbxasset://sounds/volume_slider.ogg` | 0,50 | 0,6 | Alertas de jefe y clima espacial (0,8× pitch) |

Comportamiento de `Fx.play(name, pitchMul)`:
- Límite de disparo repetido: intervalo mínimo de `0,045 s` por clave (`lastPlay[name]`).
- Variación aleatoria de tono: `±5 %` (`Balance.Juice.PitchVar = 0.05`).

## 3. Cómo sustituir por audio definitivo

1. Sube las pistas y efectos propios (o licenciados) al grupo/cuenta del proyecto en Roblox Creator Hub y obtén cada `rbxassetid://<ID>`.
2. Edita `Balance.Audio` en `game/src/shared/Balance.luau` rellenando `Music.calm`, `Music.combat`, `Music.boss` y reemplazando los `id` de `Balance.Audio.Sfx`, ajustando `vol` y `pitch` si hace falta.
3. Resincroniza `game/src/` hacia Studio (`sync_studio.lua`) y comprueba en la Salida que no haya errores de permisos de audio (`Failed to load sound`).
