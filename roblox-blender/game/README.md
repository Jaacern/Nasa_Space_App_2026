# ARES FORGE (Juego en Roblox Studio)

Roguelite de supervivencia 3D con temática NASA para NASA Space Apps 2026. Sobrevive en la superficie marciana, recupera las 4 piezas de tu módulo de aterrizaje y despega de vuelta a casa.

> Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto.

## 1. Arquitectura de `game/src/`

La carpeta `game/src/` es la fuente de verdad del código Luau (`--!strict`):

| Carpeta | Destino en Roblox Studio | Rol |
|---|---|---|
| `game/src/shared/` | `ReplicatedStorage/Shared` | Equilibrio (`Balance.luau`), textos y fichas (`Content.luau`), copia local DONKI (`NasaData.luau`), plantillas de respaldo (`Visuals.luau`) |
| `game/src/shared/Meshes/` | `ReplicatedStorage/Shared/Meshes` | 30 módulos de geometría low-poly exportados desde Blender (`Ship`, `Helmet`, `Backpack`, `Piece1..4`, `Rover`, `Insignia`, enemigos, jefes, props) |
| `game/src/server/` | `ServerScriptService/Server` | Simulación autoritativa: `Session.luau`, `Combat.luau`, `Enemies.luau`, `Loot.luau`, `SaveService.luau`, `WorldBuilder.luau`, `Main.server.luau` |
| `game/src/client/` | `StarterPlayer/StarterPlayerScripts/Client` | Cámara orbital, pooling (`Renderer.luau`), mallas (`MeshFactory.luau`), nave/entorno (`Scenery.luau`), UI (`Hud.luau`, `Ui.luau`), FX/audio (`Fx.luau`), `Main.client.luau` |

### Generación de mallas (`MeshFactory.luau`)
- `MeshFactory` construye los 30 modelos en el cliente usando `AssetService:CreateEditableMesh()`, los convierte a inmutables mediante `AssetService:CreateEditableMeshAsync(..., { FixedSize = true })` (destruyendo inmediatamente el `EditableMesh` temporal para no agotar el presupuesto de memoria) y genera cada `MeshPart` con `CreateMeshPartAsync`.
- Si una malla aún no está lista o falla, `Renderer.luau` usa automáticamente las plantillas de respaldo en `ReplicatedStorage/Templates`.

## 2. Sincronización hacia Roblox Studio

### Vía A — Lugar en la nube «Núcleo de Ares» (`placeId: 114817072312952`, recomendada)
En lugares ya guardados en la nube de Roblox, `HttpService` bloquea `127.0.0.1`. Con Studio abierto y *Enable Studio as MCP server* activo, genera el paquete y ejecútalo vía stdio MCP:
```bash
STUDIO_ID=<id> python -B tools/studio/push.py push.json client/Hud.luau shared/Content.luau
python -B tools/studio/studio_call.py execute_luau @push.json
```
También puedes sincronizar con herramientas MCP (`execute_luau`) y guardar en la nube con `save_place` (sin publicar). Ver [`../tools/studio/README.md`](../tools/studio/README.md).

### Vía B — Lugar local sin nube (HTTP `127.0.0.1:8765`)
1. Desde la raíz del subproyecto (`roblox-blender/`), arranca el servidor HTTP solo en `127.0.0.1`:
   ```bash
   python -m http.server 8765 --bind 127.0.0.1 --directory game/src
   ```
2. Abre el lugar en **Roblox Studio** en modo **Edit** (con `HttpService` permitido hacia `127.0.0.1`) y ejecuta en la barra de comandos (o mediante `execute_luau` en modo `Edit`):
   ```lua
   local H = game:GetService("HttpService")
   return loadstring(H:GetAsync("http://127.0.0.1:8765/sync_studio.lua", true))()
   ```
   `sync_studio.lua` (copia sincronizada de `tools/sync/sync_studio.luau`) recorre recursivamente `shared`, `server` y `client` —incluida `shared/Meshes/`— y crea, actualiza o elimina scripts según corresponda.

## 3. Controles

- **Movimiento**: `W A S D` o Flechas (`↑ ↓ ← →`) / joystick izquierdo / joystick táctil
- **Cámara orbital**: ratón y rueda (zoom) / arrastre táctil / stick derecho
- **Salto**: `Espacio` (gravedad marciana `74,5 studs/s²`)
- **Habilidades**: `Q` o `Shift izq.` (Impulso RCS) · `E` (Pulso)
- **Cartas de subida de nivel**: clic o teclas `1`, `2`, `3`
- **Pausa**: `P`

## 4. Comandos de depuración (solo en Studio)

El servidor solo acepta `debug` cuando `RunService:IsStudio()` es verdadero (`game/src/server/Session.luau`). En la barra de comandos del **Cliente** durante `Play`:

```lua
local Cmd = game.ReplicatedStorage.Remotes.Cmd
Cmd:FireServer("debug", "invincible", true) -- invulnerabilidad
Cmd:FireServer("debug", "time", 700)        -- fija el reloj de misión (s)
Cmd:FireServer("debug", "xp", 50)           -- suma experiencia
Cmd:FireServer("debug", "item", "plasma")   -- entrega objeto de Balance.Items
Cmd:FireServer("debug", "bosshp", 1)        -- reduce vida del jefe activo
Cmd:FireServer("debug", "hp", 100)          -- fija vida del héroe
Cmd:FireServer("debug", "science", 500)     -- suma ciencia (solo en Menú)
```

## 5. Documentación relacionada

- Catálogo 3D de Blender: [docs/assets/CATALOGO_BLENDER.md](../docs/assets/CATALOGO_BLENDER.md)
- Contrato e integración de audio: [docs/assets/AUDIO.md](../docs/assets/AUDIO.md)
- Inventario completo de assets: [docs/ASSETS.md](../docs/ASSETS.md)
- Medición de rendimiento en Studio: [docs/perf/RENDIMIENTO.md](../docs/perf/RENDIMIENTO.md)
- Bitácora técnica y checklist: [docs/NOTAS.md](../docs/NOTAS.md)
- Decisiones y pendientes: [docs/DECISIONES.md](../docs/DECISIONES.md)
