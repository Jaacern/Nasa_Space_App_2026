# Continuar en otro equipo o como colaborador

Fecha: 15-11-2026. Estado base: rama `audit/actualizacion-completa` (tras `5388d5c` + actualización de UI/flechas/docs en progreso).

## Dónde está cada cosa

| Qué | Dónde vive | Cómo llega al equipo colaborador |
|---|---|---|
| Código Luau, 30 mallas, datos NASA, docs | GitHub `Jaacern/Nasa_Space_App_2026`, rama `audit/actualizacion-completa` | `git clone` y `git checkout audit/actualizacion-completa` |
| Avances del pitch web 3D (`public/`, `ui-ux/`) | GitHub `Jaacern/Nasa_Space_App_2026`, rama `main` | `git checkout main` (trabajo paralelo de `@jaacern`; no forzar ni sobrescribir) |
| Lugar de Roblox | Nube de Roblox: «Núcleo de Ares», placeId `114817072312952` (versión `29`) | Abrir Studio con cuenta autorizada en Team Create |
| Permisos de la experiencia (mallas, API) | En la experiencia, en la nube | Ya activos; no hay que repetirlos |
| Rutas locales de MCP, `.env`, ajustes de IA | Solo en el equipo original | Se rehacen en el equipo nuevo (ver paso 4) |
| Modelo NASA original `25042_Perseverance.glb` (11 MB) | Solo en el equipo original | Opcional. Enlace y huella en `roblox-blender/docs/assets/NASA_ROVER.md` |
| Memoria y skills locales | Carpeta `.claude` del usuario original | No viajan. `AGENTS.md` y `CLAUDE.md` las sustituyen |

## Pasos

1. Instalar: Git, Roblox Studio, Python 3.11 o superior. Blender 4.5 solo si se van a regenerar mallas. Node 22.9 o superior solo para la raíz `Outpost Run`.
2. Clonar y cambiar de rama:

```bash
git clone https://github.com/Jaacern/Nasa_Space_App_2026.git
```

```bash
git checkout audit/actualizacion-completa
```

3. Abrir Roblox Studio con cuenta con acceso a la experiencia. En **Archivo > Abrir desde Roblox** elegir «Núcleo de Ares» (`placeId: 114817072312952`). El lugar en la nube ya trae la versión `29` (menú «Forma humana», tipografía `Bangers`/`Michroma`, paleta por sección y movimiento con `WASD / Flechas ↑ ↓ ← →`).
4. Solo si se va a usar una IA o terminal CLI con Studio para editar UI/código desde `roblox-blender/game/src/`:
   - En Studio, activar *Enable Studio as MCP server* (ajustes del Asistente).
   - Seguir `roblox-blender/tools/studio/README.md` (`tools/studio/push.py` + `tools/studio/studio_call.py` para empujar cambios al lugar en nube sin HTTP local).
   - Para el MCP de Blender, rellenar en local los marcadores `<RUTA_...>` de `roblox-blender/.mcp.json` y `roblox-blender/tools/blender_mcp/config.json`, y después ejecutar `git update-index --skip-worktree` sobre ambos para no subirlos.
5. Pulsar Play en Studio. Debe verse el menú «Forma humana» con colores por sección, la insignia girando sobre la nave y la consola sin errores.

## Regla de oro entre colaboradores y equipos

- El código e interfaz Luau mandan en `roblox-blender/game/src/` (por ejemplo `client/Hud.luau` y `client/Ui.luau` para menús y HUD). Studio es una copia.
- Antes de trabajar: `git pull origin audit/actualizacion-completa`. Si alguien del equipo cambió Luau en Git, empujarlo a Studio con `tools/studio/push.py` + `studio_call.py execute_luau` (o herramientas MCP).
- Al terminar: empujar a Studio, probar en Play, guardar el lugar (Ctrl+S o `save_place`), `git commit` y `git push origin audit/actualizacion-completa`.
- No editar scripts directamente en Studio sin pasarlos luego a `roblox-blender/game/src/`: el siguiente empuje los pisa.
- Guardar no es publicar. Los jugadores solo ven cambios si alguien publica el lugar cuando el equipo lo pida.

## Si se continúa con una IA

Darle este mensaje para empezar:

> Lee `AGENTS.md` y `roblox-blender/docs/NOTAS.md` secciones 9 y 10. Luego sigue con la lista «Siguiente trabajo» de `AGENTS.md`. Responde en español.

## Comprobación rápida de que todo llegó bien

- `git log --oneline -1` muestra el último commit de la rama.
- En Studio, `ReplicatedStorage.Shared.Meshes` tiene 30 módulos (incluye `Rover` e `Insignia`).
- En Play, la consola no muestra `EditableMesh is not accessible`. Si aparece, revisar Configuración del juego > Seguridad.
