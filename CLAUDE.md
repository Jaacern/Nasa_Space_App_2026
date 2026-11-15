# CLAUDE.md — NASA Space Apps 2026

Repositorio unificado con **dos subproyectos independientes**:
1. **Raíz (`Outpost Run`)**: API local Node `>=22.9` sin dependencias, ingesta NASA/CSA, saneado y capa de datos (`src/`, `server/`, `scripts/`, `data/curated/`, `content/`, `public/`, `test/`). El bucle jugable (`src/sim/`, `src/ui/`) aún no está implementado.
2. **`roblox-blender/` (`ARES FORGE`)**: roguelite 3D en Roblox Studio (`Luau --!strict`) con `30` mallas low-poly generadas en Blender y puente MCP local propio.

> Este proyecto usa datos públicos de NASA y recursos de la CSA. NASA y CSA no patrocinan ni respaldan este producto.

## Continuar desde el último estado (traspaso)

- **Leer primero al retomar trabajo:** [`docs/HANDOFF-CLAUDE.md`](docs/HANDOFF-CLAUDE.md) (estado Git, resumen completo de auditoría, inventario verificado y cola de tareas `P0`–`P2`) y [`docs/CONTINUAR-EN-OTRO-EQUIPO.md`](docs/CONTINUAR-EN-OTRO-EQUIPO.md).
- **Rama actual:** `audit/actualizacion-completa` (lugar de Roblox guardado en la nube: «Núcleo de Ares», `placeId: 114817072312952`, versión `29`).

## Guardrails transversales

- **Secretos y rutas locales fuera de Git:** nunca commitear `.env`, claves de API ni rutas `C:\Users\...`. En `roblox-blender/.mcp.json` y `roblox-blender/tools/blender_mcp/config.json`, los marcadores `<RUTA_...>` deben conservarse en Git (si los rellenas en local, no los subas).
- **Integridad científica NASA/CSA:** usar snapshots en `data/curated/` (`mode: "snapshot"`); pasar toda respuesta externa por `src/api/sanitize.mjs`; nunca citar datos sin respaldo verificable (en `ARES FORGE`, las 4 piezas tienen ficha NTRS verificada; `P-06` cerrado el 14-11-2026).
- **Licencia:** la raíz aún no tiene `LICENSE` definido.

## Rutas de trabajo (cargar bajo demanda)

- **Si trabajas en `Outpost Run` (Node / API / Web / Datos):**
  - Verificación obligatoria tras editar: `npm test && npm run check` (en Windows PowerShell usar `;` en lugar de `&&`). Para sintaxis: `node --check`.
  - Arquitectura y diseño: [`docs/PLAN-JUEGO-Y-DATOS.md`](docs/PLAN-JUEGO-Y-DATOS.md)
  - Endpoints (`13` rutas GET) y saneado: [`docs/API-LOCAL.md`](docs/API-LOCAL.md)
  - Checklist de pendientes y contenido: [`docs/PENDIENTES-MANUALES.md`](docs/PENDIENTES-MANUALES.md)
  - Prompts y registro de IA: [`docs/ia/PROMPTS.md`](docs/ia/PROMPTS.md), [`docs/ia/REGISTRO.md`](docs/ia/REGISTRO.md)
- **Si trabajas en `ARES FORGE` (Roblox Studio / Blender / MCP):**
  - Para cargar los servidores MCP (`blender` y `Roblox_Studio`), inicia Claude Code dentro de [`roblox-blender/`](roblox-blender/CLAUDE.md).
  - Fuente de verdad Luau: `roblox-blender/game/src/` (controles `WASD / Flechas ↑ ↓ ← →`). En el lugar guardado en la nube («Núcleo de Ares», `placeId: 114817072312952`), sincroniza sin HTTP mediante `roblox-blender/tools/studio/push.py` + `tools/studio/studio_call.py` (o MCP `execute_luau`); en lugares locales sin nube sigue disponible `http://127.0.0.1:8765/sync_studio.lua` (mantén `roblox-blender/tools/sync/sync_studio.luau` y `roblox-blender/game/src/sync_studio.lua` idénticos).
  - Mallas 3D: regenerar `game/src/shared/Meshes/` (`30` mallas) desde `tools/blender/` en lugar de editar geometría a mano.
  - Verificación Python sin ensuciar `.pyc`: `python -B -m py_compile <archivo.py>`.
  - Decisiones y pendientes `P-01`–`P-17`: [`roblox-blender/docs/DECISIONES.md`](roblox-blender/docs/DECISIONES.md), [`roblox-blender/docs/NOTAS.md`](roblox-blender/docs/NOTAS.md), [`roblox-blender/BLENDER_PIPELINE.md`](roblox-blender/BLENDER_PIPELINE.md).
