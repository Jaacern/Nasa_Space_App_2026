# Procesos de conexión: Blender y Roblox Studio

Cómo funcionan las dos conexiones, en qué orden arrancan, cómo usarlas y qué mirar cuando algo falle. La auditoría de seguridad está en [SEGURIDAD_MCP.md](SEGURIDAD_MCP.md).

## 1. Arquitectura

```
Claude Code
  ├─ stdio/MCP ─► tools/blender_mcp/server.py ─► TCP 127.0.0.1:9877 + token ─► Blender (bridge_addon.py) ─► bpy
  └─ stdio/MCP ─► cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat ─► StudioMCP.exe (firmado por Roblox) ─► Roblox Studio
```

- **Blender:** el servidor MCP es nuestro. Habla con un puente que corre dentro de Blender. Solo usa `localhost` y un token.
- **Roblox Studio:** el servidor MCP lo entrega Roblox dentro de Studio. Se activa con un interruptor en Studio.

## 2. Arranque

### 2.1 Blender (automático)

1. Claude Code carga el servidor `blender` de `.mcp.json`. La primera vez te pedirá aprobarlo.
2. `server.py` arranca un hilo de apertura automática. Si el puerto `9877` no responde, lanza:
   `blender.exe --python tools/blender_mcp/bridge_addon.py`. Blender abre con su ventana, como proceso independiente.
3. `bridge_addon.py` lee o crea el token en `%USERPROFILE%\.claude\blender_bridge\token.txt`, abre el puerto `9877` y registra un temporizador. Ese temporizador ejecuta los comandos en el hilo de Blender.
4. El servidor queda listo. Cada herramienta se conecta al puente, o abre Blender si hace falta.

Tiempo típico: unos 3 segundos hasta que el puente responde (registrado en `logs/blender_mcp_server.log`).

### 2.2 Roblox Studio (manual, una sola vez)

1. Abre Roblox Studio y tu place.
2. Ve a *Assistant → … → Manage MCP Servers* y activa **Enable Studio as MCP server**. Esta es la única acción de Studio que hay que hacer.
3. Claude Code carga `Roblox_Studio` de `.mcp.json`, que ejecuta `mcp.bat`. La primera vez te pedirá aprobarlo.
4. Verificación: el panel de *Manage MCP Servers* muestra un indicador verde y el número de clientes conectados.

**Importante:** `mcp.bat` solo existe después del paso 2. Antes de activarlo, el servidor `Roblox_Studio` aparecerá como fallido. Es lo esperado.

**Verificado el 14-11-2026:** `mcp.bat` existe y `list_roblox_studios` devuelve `Place1` (modo Edit).

**Nota:** las herramientas aparecen en Claude Code al reiniciar la sesión o recargar los servidores MCP, después de aprobarlos. Las pruebas de este documento se hicieron con los servidores directamente por stdio.

## 3. Uso diario

| Qué pedir | Herramienta | Nota |
|---|---|---|
| "Comprueba Blender" | `blender_ping` | Confirma la versión, el archivo abierto y la carpeta del proyecto |
| "Lista la escena" | `blender_scene_info` | Hasta 500 objetos |
| "Valida presupuestos de COL_Export" | `blender_budget_report` | Triángulos y materiales por malla |
| "Ejecuta tools/blender/x.py" | `blender_run_script` | Solo archivos `.py` dentro del proyecto |
| "Guarda una copia en assets/src" | `blender_save_blend` | No cambia el archivo abierto |
| "Exporta SM_Nombre" | `blender_export_fbx` | Escala aplicada, ejes -Z/Y, destino `assets/export` |
| "Abre Blender" | `blender_open` | Solo si lo cerraste |

**Flujo típico de un asset:** brief (`blender-director`) → script en `tools/blender/` → `blender_run_script` → `blender_budget_report` → `blender_export_fbx` → lista de `roblox-export` → importar el FBX en Studio y probarlo.

Para Roblox Studio, las herramientas oficiales incluyen `list_roblox_studios`, `search_game_tree`, `inspect_instance`, `execute_luau`, `start_stop_play`, `get_console_output` y `screen_capture`. Las de guardado y generación piden confirmación.

**Importar el FBX en Roblox:** `VERIFICAR EN STUDIO` el método exacto con la versión de Studio que tienes instalada. Hasta confirmarlo, se hace a mano desde Studio.

## 4. Registros

| Archivo | Qué guarda | Nunca guarda |
|---|---|---|
| `logs/blender_mcp_server.log` | Arranques, apertura automática, nombre de cada herramienta llamada y errores | Argumentos ni tokens |
| `logs/blender_bridge.log` | Comandos ejecutados, rechazos (motivo), exportaciones (rutas), errores con traza | Token ni contenido de scripts |
| `logs/selftest/resultado.json` | Resultado de la última ejecución de `selftest.py` | — |

## 5. Contexto que recibe Claude

- **Herramientas Blender (7):** `blender_ping`, `blender_scene_info`, `blender_budget_report`, `blender_run_script`, `blender_save_blend`, `blender_export_fbx`, `blender_open`.
- **Herramientas Roblox Studio (38 en la prueba del 14-11-2026):** la lista completa, con su propuesta de permiso, está en [SEGURIDAD_MCP.md](SEGURIDAD_MCP.md), sección 2b. La documentación oficial (`create.roblox.com/docs/studio/mcp`) describe 30. El servidor real expone 38.
- **Reglas del proyecto:** `PROMPT_MAESTRO_FABLE_5.2_v3.md`, `BLENDER_PIPELINE.md`, `docs/SEGURIDAD_MCP.md` y el skill `roblox-export`.
- **Límites conocidos:** salida de scripts de 20 000 caracteres. `script_search` de Roblox devuelve 10 resultados como máximo. `script_grep` devuelve 50 coincidencias como máximo.

## 6. Solución de problemas

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `no existe el token del puente` | Blender nunca se abrió en este equipo | Ejecuta `blender_open` |
| `tiempo agotado esperando a Blender` | Blender tardó en arrancar | Repite la herramienta; mira `logs/blender_mcp_server.log` |
| `no encuentro Blender en …` | Cambió la ruta de Blender | Corrige `blender_exe` en `tools/blender_mcp/config.json` |
| El puerto 9877 está ocupado | Hay otra instancia del puente abierta | Cierra esa ventana de Blender |
| `Roblox_Studio` no conecta | El interruptor está apagado o Studio está cerrado | Actívalo en Studio y reinicia Claude Code |
| No existe `%LOCALAPPDATA%\Roblox\mcp.bat` | El interruptor nunca se activó | Activa *Enable Studio as MCP server* |
| `comando no permitido` | Se pidió un comando que no está en la lista blanca | Es el comportamiento esperado. Ver la auditoría |

## 7. Mantenimiento

- **Re-probar el puente** tras cualquier cambio: `blender.exe -b --factory-startup -noaudio --python tools\blender_mcp\selftest.py`. Debe dar `15/15 OK`.
- **Actualizar Blender:** instala la nueva build oficial y vuelve a ejecutar `selftest.py`.
- **Actualizar el servidor MCP de Roblox:** lo gestiona Studio. Tras cada actualización, verifica la firma del archivo: `Get-AuthenticodeSignature` sobre `StudioMCP.exe` debe dar `Valid` y firmante *Roblox Corporation*.
