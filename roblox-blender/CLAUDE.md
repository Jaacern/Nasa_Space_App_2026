# CLAUDE.md — Subproyecto `ARES FORGE` (`roblox-blender/`)

Reglas locales al abrir Claude Code dentro de `roblox-blender/` (ver también [`../CLAUDE.md`](../CLAUDE.md) y [`../docs/HANDOFF-CLAUDE.md`](../docs/HANDOFF-CLAUDE.md)).

## Entorno MCP y seguridad

- **Rutas y permisos locales:** `.mcp.json` y `tools/blender_mcp/config.json` conservan marcadores `<RUTA_...>` en el repo. Sustitúyelos solo localmente sin commitearlos (`.claude/settings.json` tampoco está versionado; aplicar manualmente según [`docs/SEGURIDAD_MCP.md`](docs/SEGURIDAD_MCP.md) sección 6a).
- **Puente Blender:** usar `tools/blender_mcp/selftest.py` (`15/15 OK` en Blender `-b --factory-startup -noaudio`).

## Reglas de desarrollo Luau y assets

- **Fuente de verdad:** `game/src/` (`--!strict`). Todo cambio de código debe sincronizarse a Studio (`python -m http.server 8765 --bind 127.0.0.1 --directory game/src` + `sync_studio.lua` en Studio modo Edit). Si editas `tools/sync/sync_studio.luau`, replica el cambio exacto en `game/src/sync_studio.lua`.
- **Mallas 3D:** los `28` modelos viven en `game/src/shared/Meshes/` y se construyen en cliente con `EditableMesh` (`FixedSize = true`) en `game/src/client/MeshFactory.luau`. No editar las tablas de vértices a mano; regenerar desde `tools/blender/`.
- **Verificación Python:** usar `python -B -m py_compile` para no generar carpetas `__pycache__/`.

## Punteros clave

- Estado de decisiones y pendientes (`P-01`–`P-17`): [`docs/DECISIONES.md`](docs/DECISIONES.md)
- Bitácora técnica, atajos `debug` y checklist Studio: [`docs/NOTAS.md`](docs/NOTAS.md), [`game/README.md`](game/README.md)
- Balance (`0/5` pruebas F5), demo, tráiler, rendimiento: [`docs/BALANCE_V0.md`](docs/BALANCE_V0.md), [`docs/DEMO_GUION.md`](docs/DEMO_GUION.md), [`docs/TRAILER.md`](docs/TRAILER.md), [`docs/perf/RENDIMIENTO.md`](docs/perf/RENDIMIENTO.md)
- Reglas de datos NASA/NTRS: [`docs/NASA_APIS.md`](docs/NASA_APIS.md)
