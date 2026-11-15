# Cliente de Roblox Studio por línea de comandos

Sirve para que cualquier IA o persona maneje Studio sin tener cargadas las herramientas MCP.
Habla JSON-RPC por stdio con `%LOCALAPPDATA%\Roblox\mcp.bat`.

Requisitos: Studio abierto con el lugar y la opción *Enable Studio as MCP server* activa.

## Uso

```bash
python -B tools/studio/studio_call.py list_roblox_studios "{}"
```

```bash
python -B tools/studio/studio_call.py --schema execute_luau
```

- Forma general: `studio_call.py <herramienta> @args.json [<herramienta> @args.json ...]`.
- `STUDIO_TIMEOUT` (segundos) alarga la espera. `STUDIO_IMG=<nombre>` guarda la captura de `screen_capture`.
- `mk.py <archivo.luau> <Edit|Client|Server> <salida.json>` crea los argumentos de `execute_luau`. Lee el id de Studio de `STUDIO_ID`.
- En Windows añade `PYTHONIOENCODING=utf-8` si la salida trae acentos.

## Ciclo de prueba

1. Servir el código: `python -m http.server 8765 --bind 127.0.0.1 --directory game/src`.
2. Sincronizar: ejecutar en modo `Edit` el contenido de `tools/sync/sync_studio.luau`.
3. `start_stop_play` para entrar y salir de Play.
4. En modo `Client`: `game.ReplicatedStorage.Remotes.Cmd:FireServer("start", "demo")`.
5. `get_console_output` para leer errores. `save_place` para guardar (el lugar debe haberse guardado a mano una vez).

Las capturas pueden salir con el fondo 3D en blanco si Studio no tiene el foco. No las uses como única prueba.

## Lugar publicado en Roblox

En un lugar guardado en la nube, Studio bloquea las peticiones a `127.0.0.1`. Usa `push.py`, que mete el código dentro de la llamada:

```bash
STUDIO_ID=<id> python -B tools/studio/push.py push.json client/Hud.luau shared/Content.luau
```

```bash
python -B tools/studio/studio_call.py execute_luau @push.json
```
