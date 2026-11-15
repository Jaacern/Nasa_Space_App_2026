# Continuar en otro equipo (por ejemplo, el notebook)

Fecha: 15-11-2026. Estado al cerrar: commit `406d32e` y siguientes en la rama `audit/actualizacion-completa`.

## Dónde está cada cosa

| Qué | Dónde vive | Cómo llega al otro equipo |
|---|---|---|
| Código, mallas, documentación | GitHub `Jaacern/Nasa_Space_App_2026`, rama `audit/actualizacion-completa` | `git clone` y `git checkout` |
| Lugar de Roblox | Nube de Roblox: «Núcleo de Ares», placeId `114817072312952` | Abrir Studio con la **misma cuenta de Roblox** |
| Permisos de la experiencia (mallas, API) | En la experiencia, en la nube | Ya activos; no hay que repetirlos |
| Rutas locales de MCP, `.env`, ajustes de Claude | Solo en el equipo original | Se rehacen en el equipo nuevo (ver paso 4) |
| Modelo NASA original `25042_Perseverance.glb` (11 MB) | Solo en el equipo original | Opcional. Enlace y huella en `roblox-blender/docs/assets/NASA_ROVER.md` |
| Memoria y skills de Claude | Carpeta `.claude` del usuario original | No viajan. `AGENTS.md` las sustituye |

## Pasos

1. Instalar: Git, Roblox Studio, Python 3.11 o superior. Blender 4.5 solo si se van a regenerar mallas. Node 22.9 o superior solo para la raíz `Outpost Run`.
2. Clonar y cambiar de rama:

```bash
git clone https://github.com/Jaacern/Nasa_Space_App_2026.git
```

```bash
git checkout audit/actualizacion-completa
```

3. Abrir Roblox Studio con la misma cuenta. En **Archivo > Abrir desde Roblox** elegir «Núcleo de Ares». El lugar ya trae el código de la última sesión.
4. Solo si se va a usar una IA con Studio:
   - En Studio, activar *Enable Studio as MCP server* (ajustes del Asistente).
   - Seguir `roblox-blender/tools/studio/README.md`. No hace falta configurar nada más para ese cliente.
   - Para el MCP de Blender, rellenar en local los marcadores `<RUTA_...>` de `roblox-blender/.mcp.json` y `roblox-blender/tools/blender_mcp/config.json`, y después ejecutar `git update-index --skip-worktree` sobre ambos para no subirlos.
5. Pulsar Play en Studio. Debe verse el menú con la insignia girando sobre la nave y la consola sin errores.

## Regla de oro entre dos equipos

- El código manda en `roblox-blender/game/src/`. Studio es una copia.
- Antes de trabajar: `git pull`. Si otra persona o equipo cambió código, empujarlo a Studio con `tools/studio/push.py`.
- Al terminar: empujar a Studio, guardar el lugar (Ctrl+S o `save_place`), `git commit` y `git push`.
- No editar scripts directamente en Studio: el siguiente empuje los pisa.
- Guardar no es publicar. Los jugadores solo ven cambios si alguien publica.

## Si se continúa con una IA

Darle este mensaje para empezar:

> Lee `AGENTS.md` y `roblox-blender/docs/NOTAS.md` sección 9. Luego sigue con la lista «Siguiente trabajo» de `AGENTS.md`. Responde en español.

## Comprobación rápida de que todo llegó bien

- `git log --oneline -1` muestra el último commit de la rama.
- En Studio, `ReplicatedStorage.Shared.Meshes` tiene 30 módulos (incluye `Rover` e `Insignia`).
- En Play, la consola no muestra `EditableMesh is not accessible`. Si aparece, revisar Configuración del juego > Seguridad.
