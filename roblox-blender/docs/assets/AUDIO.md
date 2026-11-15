# Audio de ARES FORGE

Fecha: 14-11-2026.
Configuración fuente: tabla `Balance.Audio` en `game/src/shared/Balance.luau`.
Reproductor en cliente: `game/src/client/Fx.luau` (`Fx.init`, `Fx.play`, `Fx.setMusic`, `Fx.update`).

## 1. Música (`Balance.Audio.Music`)

Actualizado el 15-11-2026. Cada entrada es `{ id, vol }`. `Fx.setMusic` reproduce **una sola pista a la vez** y hace fundido entre ellas. Todo pasa por el grupo `AresMusic`.

| Clave | Id | `vol` | Uso |
|---|---|---|---|
| `calm` | `rbxassetid://140533822783920` | 0,10 | Menú, despegue y resumen |
| `combat` | `rbxassetid://1837839878` | 0,20 | Combate y tutorial |
| `boss` | `rbxassetid://9042593925` | 0,28 | Minijefes y jefe final |

## 2. Efectos (`Balance.Audio.Sfx`)

Todos pasan por el grupo `AresSfx`, que lleva un `EqualizerSoundEffect` (`HighGain -7`, `MidGain -1.5`, `LowGain 1`) para quitar agudos agresivos.

| Clave | Id | Uso |
|---|---|---|
| `shoot` | `rbxasset://sounds/action_jump.mp3` (vol 0,09, pitch 1,7) | Disparo |
| `hit` | `rbxassetid://9113485712` | Impacto |
| `kill` | `rbxassetid://9118172604` | Enemigo derrotado |
| `boom` | `rbxassetid://9119378289` | Explosión |
| `hurt` | integrado de Roblox | Daño recibido |
| `gem` | `rbxassetid://9126073001` | Muestra de XP |
| `level` | `rbxassetid://9126071775` | Subida de nivel |
| `chest` | `rbxassetid://9126072453` | Cofre |
| `buff` | `rbxassetid://9126076030` | Mejora elegida (nuevo) |
| `ui` | integrado de Roblox | Interfaz |
| `skill` | `rbxassetid://9125442175` | Impulso RCS y Pulso |
| `warn` | `rbxassetid://9117955911` | Alertas |

Los valores exactos de `vol` y `pitch` mandan en `Balance.luau`.

### Origen y criterio

- Solo se usan catálogos con licencia dentro de Roblox (cuentas oficiales de música y efectos del Creator Store) o sonidos integrados `rbxasset://`. No se usan audios subidos por terceros sin licencia.
- La música **no** viene de Google Flow: Flow no estaba conectado y no genera música para juegos.
- El volumen se ajustó midiendo `PlaybackLoudness` en Studio. Es una medida, no una escucha.
- Probado el 15-11-2026: todos los sonidos cargan (`IsLoaded`) y la consola no da `Failed to load sound`.
- **Pendiente humano:** una persona del equipo debe escuchar la mezcla completa y confirmar el estilo. La IA no puede oír.

## 3. Cómo sustituir por audio definitivo

1. Sube las pistas y efectos propios (o licenciados) al grupo/cuenta del proyecto en Roblox Creator Hub y obtén cada `rbxassetid://<ID>`.
2. Edita `Balance.Audio` en `game/src/shared/Balance.luau` rellenando `Music.calm`, `Music.combat`, `Music.boss` y reemplazando los `id` de `Balance.Audio.Sfx`, ajustando `vol` y `pitch` si hace falta.
3. Resincroniza `game/src/` hacia Studio (`sync_studio.lua`) y comprueba en la Salida que no haya errores de permisos de audio (`Failed to load sound`).
