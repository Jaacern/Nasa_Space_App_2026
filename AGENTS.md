# AGENTS.md — guía para cualquier asistente de IA

Este archivo sirve a cualquier modelo (Claude, GPT, Gemini, DeepSeek u otro). No depende de herramientas de un proveedor.

## Qué es

- **Foco:** `roblox-blender/` = **ARES FORGE**, roguelite 3D en Roblox (jugabilidad tipo Megabonk, estética Risk of Rain 2). Objetivo: ganar NASA Space Apps 2026. Pitch de 3 min con tráiler de 1 min.
- **Raíz:** `Outpost Run`, capa de datos NASA en Node. El «juego de cartas puro» está descartado.
- Idioma de trabajo y del juego: español.

## Leer primero (en este orden, solo lo necesario)

0. Si estás en un equipo nuevo: `docs/CONTINUAR-EN-OTRO-EQUIPO.md`.

1. `CLAUDE.md` (reglas del repositorio; valen para cualquier IA).
2. `roblox-blender/docs/NOTAS.md` secciones 9 y 10 (estado más reciente y cosas sin verificar).
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

1. Una persona escucha la mezcla de audio (`P-12`) y prueba manualmente en dispositivos reales (PC/web, móvil vertical/horizontal y mando/consola) la calidad adaptativa, los controles adaptados (`kb`, `gamepad`, `touch`), el nuevo escudo con CD 20 s, las 5 zonas, los meteoros y los eventos de agujero negro (`0` errores en consola y `0` fallos `TextFits` en las 8 pantallas en Studio `Play`).
2. El lugar está en Roblox como «Núcleo de Ares» (`placeId: 114817072312952`, guardado en versión `20`); guardar con `save_place` tras cada avance. No publicar sin pedirlo.
3. Pulido pendiente de código: ninguno inmediato tras la tanda de perfiles, checkpoints, zonas, meteoros/agujeros negros, escudo 20 s y pulido UI/colisiones (`Balance`, `NasaData`, `Content`, `Visuals`, `WorldBuilder`, `SaveService`, `Loot`, `Combat`, `Enemies`, `Main.server`, `Session`, `Ui`, `Fx`, `Scenery`, `Renderer`, `Main.client`, `Hud` sincronizados y guardados). Lista: audio por una persona (`P-12`), revisión manual de iluminación (`P-01`), pruebas `F5` (`0/5`) y tráiler al final.
4. Pendientes `P-01` a `P-15` que dependen del equipo (`roblox-blender/docs/DECISIONES.md`).
5. Tráiler, al final (`roblox-blender/docs/TRAILER_BRIEF_FABLE.md`).

## Agente DeepSeek (opcional, con tope de gasto)

- Conectado como MCP `deepseek-agente` (ámbito usuario). Herramientas: `deepseek_perfiles`, `deepseek_encargar`, `deepseek_estado`, `deepseek_reanudar`.
- Flujo: `deepseek_encargar` → `deepseek_estado` hasta `terminado` → revisar los archivos que informa. Nunca aplicar a ciegas.
- Topes por perfil entre 0,05 y 0,30 USD. El límite que fijó el usuario es 0,80 USD por encargo.
- Gasto mensual: el saldo puede estar en estado crítico; revisar `deepseek_perfiles` antes de encargar algo grande.
- Solo para encargos acotados y verificables (un bloque de código, una tabla, una búsqueda). El juego se verifica siempre en Studio.
