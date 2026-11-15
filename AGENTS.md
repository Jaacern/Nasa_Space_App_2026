# AGENTS.md — guía para cualquier asistente de IA

Este archivo sirve a cualquier modelo (Claude, GPT, Gemini, DeepSeek u otro). No depende de herramientas de un proveedor.

## Qué es

- **Foco:** `roblox-blender/` = **ARES FORGE**, roguelite 3D en Roblox (jugabilidad tipo Megabonk, estética Risk of Rain 2). Objetivo: ganar NASA Space Apps 2026. Pitch de 3 min con tráiler de 1 min.
- **Raíz:** `Outpost Run`, capa de datos NASA en Node. El «juego de cartas puro» está descartado.
- Idioma de trabajo y del juego: español.

## Leer primero (en este orden, solo lo necesario)

1. `CLAUDE.md` (reglas del repositorio; valen para cualquier IA).
2. `roblox-blender/docs/NOTAS.md` sección 9 (estado más reciente y cosas sin verificar).
3. `roblox-blender/docs/DECISIONES.md` (pendientes `P-01` a `P-17`).
4. `roblox-blender/docs/ASSETS.md` y `docs/assets/AUDIO.md`.
5. `roblox-blender/docs/TRAILER_BRIEF_FABLE.md` (tráiler; se produce al final).
6. `docs/HANDOFF-CLAUDE.md` (auditoría anterior e inventario).

## Reglas que no se rompen

- Nunca subir `.env`, claves ni rutas `C:\Users\...`. `roblox-blender/.mcp.json` y `tools/blender_mcp/config.json` llevan marcadores `<RUTA_...>` en Git.
- Datos NASA solo con fuente verificable (fichas NTRS en `game/src/shared/Content.luau`).
- Fuente de verdad del juego: `roblox-blender/game/src/` (Luau `--!strict`). Studio se sincroniza desde ahí, nunca al revés.
- Mallas: se generan con `tools/blender/` (no editar `Meshes/*.luau` a mano). Límite por archivo: 180 KB.
- Audio: solo catálogo con licencia de Roblox o sonidos integrados.
- Insignia NASA: controlada por `Balance.Branding.NasaInsignia`. Requiere permiso de NASA; el equipo declaró tenerlo.
- No publicar el lugar de Roblox sin que el equipo lo pida.

## Cómo trabajar

| Tarea | Comando o archivo |
|---|---|
| Regenerar mallas | `blender -b --factory-startup -noaudio --python tools/blender/export_assets.py` (dentro de `roblox-blender/`) |
| Manejar Studio sin MCP | `roblox-blender/tools/studio/README.md` |
| Pruebas de la raíz | `npm test` y `npm run check` |
| Comprobar Python | `python -B -m py_compile <archivo.py>` |

Reparto sugerido si hay varios modelos: el más capaz orquesta, diseña y revisa; uno más barato hace encargos acotados y verificables (textos, tablas, búsquedas).

## Siguiente trabajo (15-11-2026)

1. Una persona mira el menú en Studio (insignia girando, lunas) y escucha la mezcla de audio.
2. Guardar el lugar a mano una vez en Studio.
3. Pulido pendiente: animaciones de combate (retroceso, destello de golpe), fuentes de títulos, datos científicos en las cartas de mejora.
4. Pendientes `P-01` a `P-15` que dependen del equipo.
5. Tráiler, al final.
