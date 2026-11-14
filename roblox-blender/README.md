# roblox-blender

Juego en Roblox Studio con assets de Blender: roguelite de supervivencia 3D con temática NASA, para NASA Space Apps 2026.

Esta carpeta es independiente del prototipo Node de la raíz del repositorio. No usa ni modifica `src/`, `server/` ni `scripts/`.

## Contenido

| Ruta | Qué es |
|---|---|
| `PROMPT_MAESTRO_FABLE_5.2_v3.md` | Prompt maestro vigente. Las versiones v1 y v2 quedan como historial |
| `BLENDER_PIPELINE.md` | Estado y decisiones del pipeline Blender a Roblox |
| `docs/NASA_APIS.md` | Catálogo de APIs y recursos oficiales de NASA, con estado verificado |
| `docs/SEGURIDAD_MCP.md` | Auditoría de las conexiones MCP con Blender y Roblox Studio |
| `docs/PROCESOS_MCP.md` | Cómo arrancan las conexiones y cómo resolver problemas |
| `tools/blender_mcp/` | Puente propio con Blender: servidor MCP, add-on, pruebas y configuración |
| `.claude/skills/` | 21 skills para assets 3D (de blender-skills, MIT) y la skill `roblox-export` |
| `.mcp.json` | Configuración de los servidores MCP de Blender y Roblox Studio |
| `SKILLS_PROYECTO_PARA_ANTIGRAVITY.md` | Las mismas skills del proyecto en un solo archivo, para otras herramientas |

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