# roblox-blender

Juego en Roblox Studio (**ARES FORGE**) con assets de Blender: roguelite de supervivencia 3D con temática NASA, para NASA Space Apps 2026.

Esta carpeta es independiente del prototipo Node de la raíz del repositorio. No usa ni modifica `src/`, `server/` ni `scripts/`.

> Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto.

## Contenido

| Ruta | Qué es |
|---|---|
| `game/` | Código Luau en `game/src/` (`server/`, `client/`, `shared/`, `shared/Meshes/` con las 28 mallas exportadas) y guía en `game/README.md` |
| `assets/` | Archivo fuente `assets/blend/ares_assets.blend` y los 28 `.fbx` en `assets/export/` |
| `tools/blender/` | Generación y exportación reproducible de los 28 assets (`ares_lib.py`, `build_assets.py`, `export_assets.py`) |
| `tools/sync/` | Sincronizador recursivo disco → Studio (`sync_studio.luau`, servido vía `game/src/sync_studio.lua`) |
| `tools/blender_mcp/` | Puente propio con Blender: servidor MCP, add-on, pruebas y configuración |
| `docs/` | Documentación técnica, diseño (`BRIEF_PRODUCCION.md`, `DECISIONES.md`, `BALANCE_V0.md`, `NOTAS.md`), guiones (`DEMO_GUION.md`, `TRAILER.md`, `PITCH.md`), rendimiento (`docs/perf/RENDIMIENTO.md`), catálogo 3D (`docs/assets/CATALOGO_BLENDER.md`, previews 512×512), audio (`docs/assets/AUDIO.md`) y catálogo NASA |
| `.claude/skills/` | 21 skills para assets 3D (de blender-skills, MIT) y la skill `roblox-export` |
| `.mcp.json` | Configuración de los servidores MCP de Blender y Roblox Studio |
| `PROMPT_MAESTRO_FABLE_5.2_v3.md` | Prompt maestro vigente. Las versiones v1 y v2 quedan como historial |
| `BLENDER_PIPELINE.md` | Estado y decisiones del pipeline Blender a Roblox |
| `SKILLS_PROYECTO_PARA_ANTIGRAVITY.md` | Las mismas skills del proyecto en un solo archivo, para otras herramientas |

## Arranque rápido en Studio

1. Levanta el servidor local desde `roblox-blender/`:
   ```bash
   python -m http.server 8765 --bind 127.0.0.1 --directory game/src
   ```
2. En Roblox Studio (modo **Edit**), ejecuta en la barra de comandos:
   ```lua
   local H = game:GetService("HttpService")
   return loadstring(H:GetAsync("http://127.0.0.1:8765/sync_studio.lua", true))()
   ```
   Ver detalles en `game/README.md` y `docs/NOTAS.md`.

## Antes de usarlo en tu equipo

- `.mcp.json` y `tools/blender_mcp/config.json` tienen marcadores `<RUTA_...>` (Python, Blender y carpeta del proyecto). Sustitúyelos por las rutas de tu equipo.
- La documentación usa `%USERPROFILE%`, `%LOCALAPPDATA%` y `<RUTA_DEL_PROYECTO>` como marcadores. El repositorio no contiene rutas personales.
- El servidor de Roblox Studio requiere activar *Enable Studio as MCP server* dentro de Studio.
- Las claves de NASA nunca van en esta carpeta. Ver `docs/NASA_APIS.md`.

## Prueba del puente de Blender

Sustituye `<ruta-a-blender.exe>` por la de tu instalación:

```bash
"<ruta-a-blender.exe>" -b --factory-startup -noaudio --python tools/blender_mcp/selftest.py
```

Debe terminar con `15/15 OK`.

## Licencias

- `.claude/skills/` (salvo `roblox-export`): MIT. Ver `.claude/skills/LICENSE-arjun988-blender-skills.txt`.
- Resto del contenido: sin licencia definida todavía. Decisión del equipo.
