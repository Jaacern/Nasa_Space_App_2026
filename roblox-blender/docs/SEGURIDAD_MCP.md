# Auditoría de seguridad: MCP para Blender y Roblox Studio

Fecha: 14-11-2026 · Equipo: PC de Windows 11 · Proyecto: `<RUTA_DEL_PROYECTO>`
Última actualización: 14-11-2026, después de que se activó el interruptor de Studio.

## 1. Resumen

| Conexión | Qué es | Estado |
|---|---|---|
| **Blender** | Puente propio en `tools/blender_mcp/`, sin paquetes de terceros | Instalado y probado: 15/15 pruebas y protocolo MCP correcto. Se abre automáticamente. |
| **Roblox Studio** | Servidor MCP integrado y oficial de Roblox (`StudioMCP.exe`), firma válida | **Activo.** La conexión se probó en solo lectura: `Place1` (modo Edit) responde. |
| **Permisos de herramientas** | Reglas de Claude Code en `.claude/settings.json` | **Aplicados el 14-11-2026** con autorización explícita del usuario: 28 permitidas, 15 con confirmación y 2 bloqueadas (sección 6a). |

**Hallazgo principal:** el servidor oficial de Roblox expone **38 herramientas**. La documentación oficial que consultamos describe 30. Entre las 8 adicionales hay una de alto riesgo: `open_cloud_invoke`, que hace peticiones autenticadas a Roblox Open Cloud. La propuesta de permisos ya la incluye.

## 2. Componentes y verificación

| Componente | Origen | Versión / huella | Cómo se verificó |
|---|---|---|---|
| Blender | download.blender.org (oficial) | 4.5.16 LTS, build 2026-11-10 | Descargado del índice oficial; `blender --version` |
| Puente Blender (`bridge_addon.py`) | Código propio de este proyecto | 1.0.0 | Revisión de código y `selftest.py` (15/15) |
| Servidor MCP Blender (`server.py`) | Código propio de este proyecto | 1.0.0 | Solo biblioteca estándar; protocolo probado por stdio |
| Servidor MCP Roblox (`StudioMCP.exe`) | Roblox Corporation | SHA256 `1969330180467609FDB5F5E16BE1AA40EA9E659776A0CBB588AB9AD90F9D8870`, 9 990 608 bytes | Firma Authenticode **Valid**; firmante *Roblox Corporation*; emisor *DigiCert Trusted G4 Code Signing* |
| Lanzador `mcp.bat` (Roblox) | Creado por Studio al activar el interruptor | SHA256 `054D13804305D5FD95045C1169011D6E6ECC0A2C3E68E24DAE89882EA7278A42`, 341 bytes | Leído completo: solo llama a `StudioMCP.exe`, con ruta fija o con la clave de registro `ContentFolder` |
| Python para el servidor | uv (`cpython-3.12.14`) | 3.12.14 | Instalado con uv; sin paquetes adicionales |
| Skills de Blender | `arjun988/blender-skills` (licencia MIT) | 21 de 94 instalados | Búsqueda de patrones de red, ejecución y borrado en los SKILL.md: sin hallazgos |

### 2b. Inventario de herramientas de Roblox Studio (38)

Dato de la prueba del 14-11-2026 (`tools/list`). Las marcas de anotación son las que declara el propio servidor.

| Herramienta | Solo lectura | Destructiva | Abierta al exterior | Propuesta |
|---|---|---|---|---|
| `upload_image` | no | no | sí | ask |
| `open_cloud_invoke` | no | **sí** | **sí** | **deny** |
| `search_game_tree` | sí | no | no | allow |
| `script_search` | sí | no | no | allow |
| `save_place` | no | no | sí | ask |
| `skill` | sí | no | no | allow |
| `subagent` | no | no | no | allow |
| `multi_edit` | no | **sí** | no | allow |
| `execute_luau` | no | **sí** | **sí** | allow |
| `submit_feedback` | no | no | sí | deny |
| `get_console_output` | sí | no | no | allow |
| `user_mouse_input` | no | no | no | allow |
| `auto_setup_avatar` | no | no | no | ask |
| `store_image` | no | no | no | ask |
| `character_navigation` | no | no | no | allow |
| `http_get` | sí | no | sí | allow |
| `list_roblox_studios` | sí | no | no | allow |
| `script_read` | sí | no | no | allow |
| `screen_capture` | sí | no | no | allow |
| `get_studio_state` | sí | no | no | allow |
| `user_keyboard_input` | no | no | no | allow |
| `generate_scene` | no | no | no | ask |
| `script_grep` | sí | no | no | allow |
| `wait_job_finished` | sí | no | no | allow |
| `generate_procedural_model` | no | no | sí | ask |
| `generate_animation` | no | no | no | ask |
| `segment_mesh` | no | **sí** | **sí** | ask |
| `list_skills` | sí | no | no | allow |
| `start_stop_play` | no | no | no | allow |
| `create_skill` | no | no | no | ask |
| `generate_avatar` | no | no | sí | ask |
| `generate_mesh` | no | no | sí | ask |
| `generate_material` | no | no | sí | ask |
| `inspect_instance` | sí | no | no | allow |
| `generate_texture` | no | **sí** | **sí** | ask |
| `search_asset` | sí | no | sí | allow |
| `edit_skill` | no | **sí** | no | ask |
| `insert_asset` | no | no | sí | ask |

## 3. Lo que se descartó y por qué

- **`mcp-for-blender` (PyPI) y su add-on `addon.py` (repo `ahujasid/blender-mcp`).** Hallazgos de la revisión:
  - El add-on descarga y reemplaza su propio código desde GitHub (`ADDON_UPDATE_URL`, `requests.get`).
  - Incluye una capa "premium" con un backend en Supabase para licencias (`PREMIUM_API_URL_DEFAULT`).
  - Integra proveedores externos (Sketchfab, Poly Haven, Poly Pizza, Meshy, Tripo, Hyper3D/fal.ai, Hunyuan3D/Tencent y World Labs) que envían datos a terceros cuando se activan.
  - Tiene un socket sin autenticación y `exec()` de código arbitrario.
  - El servidor tiene telemetría activada por defecto.
- **Intento de instalación automática del add-on** (`uvx … install-addon`): el clasificador de seguridad lo denegó. No se repitió.
- **Repo oficial `Roblox/studio-rust-mcp-server`:** archivado en abril de 2026. Roblox recomienda el MCP integrado de Studio. No se usa.
- **Plugins de terceros para Roblox** (por ejemplo `boshyxd/robloxstudio-mcp`): no se usan.

## 4. Controles del puente de Blender

1. Escucha solo en `127.0.0.1`, puerto `9877`. No es accesible desde la red.
2. En Windows usa `SO_EXCLUSIVEADDRUSE`, así otro proceso no puede tomar el puerto.
3. Token aleatorio de 256 bits en `%USERPROFILE%\.claude\blender_bridge\token.txt`, creado con `O_EXCL`. Su ACL está restringida a tu usuario (`icacls`: solo `<USUARIO_WINDOWS>` con lectura y escritura). El token nunca se escribe en el log ni en el repositorio.
4. La comparación del token es en tiempo constante (`hmac.compare_digest`).
5. Lista blanca de 6 comandos (`ping`, `scene_info`, `budget_report`, `run_script`, `save_blend`, `export_fbx`). Cualquier otro se rechaza y queda registrado.
6. No hay ejecución de texto libre. `run_script` solo acepta archivos `.py` dentro del proyecto.
7. Todas las rutas se resuelven y deben quedar dentro de la carpeta del proyecto.
8. Extensiones permitidas: `.py` para scripts, `.blend` para guardados y `.fbx` para exportaciones.
9. Límites: 1 MB por petición, 20 s de espera para leer y 180 s para ejecutar. La salida de un script se corta a 20 000 caracteres.
10. Registro en `logs/blender_bridge.log` y `logs/blender_mcp_server.log`. Nunca se registra el token ni el contenido de los scripts.
11. El puente no hace llamadas a Internet. Ningún dato sale de la máquina por esta vía.

## 5. Pruebas realizadas

**Blender**
- **Sintaxis:** los tres archivos Python se analizaron con `ast` sin ejecutarlos. Resultado: OK.
- **`selftest.py` dentro de Blender 4.5.16 en modo `-b`:** **15/15 OK**. Incluye ping, scene_info, budget_report, exportación FBX (`SM_Prueba_Cubo.fbx`), run_script, cinco barreras de seguridad, token válido, token incorrecto, comando no permitido, registro de rechazos y verificación de que el token no aparece en el log. Resultado en `logs/selftest/resultado.json`.
- **Protocolo MCP por stdio:** `initialize`, `tools/list` y `tools/call` (`blender_ping` y `blender_scene_info`) respondieron bien, también sin BOM.
- **Apertura automática:** el servidor lanzó Blender como proceso separado. El puente estuvo listo en unos 3 segundos (`logs/blender_mcp_server.log`).

**Roblox Studio (14-11-2026, solo lectura)**
- `initialize`: correcto. El servidor se declara como `RobloxStudio` 1.0.0.
- `tools/list`: 38 herramientas (sección 2b).
- `tools/call list_roblox_studios`: devolvió `Place1` (modo Edit, `persistedToCloud: false`), sin error.
- **Avisos del registro del proxy:** `401 no_auth_header` y `No proxy found`, además de un `Connection reset` puntual. El proxy rechazó conexiones sin cabecera de autenticación, que es el comportamiento esperado. Las reconexiones posteriores funcionaron. Vigilar si aparecen de forma repetida.
- Firma de `StudioMCP.exe`: Authenticode **Valid**.

## 6. Decisiones pendientes

**a) Reglas de permisos (`.claude/settings.json`): aplicadas el 14-11-2026.**
El clasificador de seguridad denegó la escritura dos veces. Con la instrucción explícita del usuario, se creó el archivo con esta configuración. Sin ella, Claude Code pide aprobación para cada herramienta MCP. Configuración aplicada, con las 38 herramientas:

```json
{
  "permissions": {
    "allow": [
      "mcp__blender__blender_ping",
      "mcp__blender__blender_scene_info",
      "mcp__blender__blender_budget_report",
      "mcp__blender__blender_run_script",
      "mcp__blender__blender_save_blend",
      "mcp__blender__blender_export_fbx",
      "mcp__blender__blender_open",
      "mcp__Roblox_Studio__list_roblox_studios",
      "mcp__Roblox_Studio__get_studio_state",
      "mcp__Roblox_Studio__search_game_tree",
      "mcp__Roblox_Studio__inspect_instance",
      "mcp__Roblox_Studio__script_read",
      "mcp__Roblox_Studio__script_search",
      "mcp__Roblox_Studio__script_grep",
      "mcp__Roblox_Studio__execute_luau",
      "mcp__Roblox_Studio__multi_edit",
      "mcp__Roblox_Studio__start_stop_play",
      "mcp__Roblox_Studio__get_console_output",
      "mcp__Roblox_Studio__screen_capture",
      "mcp__Roblox_Studio__character_navigation",
      "mcp__Roblox_Studio__user_keyboard_input",
      "mcp__Roblox_Studio__user_mouse_input",
      "mcp__Roblox_Studio__wait_job_finished",
      "mcp__Roblox_Studio__search_asset",
      "mcp__Roblox_Studio__http_get",
      "mcp__Roblox_Studio__skill",
      "mcp__Roblox_Studio__list_skills",
      "mcp__Roblox_Studio__subagent"
    ],
    "ask": [
      "mcp__Roblox_Studio__save_place",
      "mcp__Roblox_Studio__insert_asset",
      "mcp__Roblox_Studio__upload_image",
      "mcp__Roblox_Studio__store_image",
      "mcp__Roblox_Studio__auto_setup_avatar",
      "mcp__Roblox_Studio__generate_scene",
      "mcp__Roblox_Studio__generate_procedural_model",
      "mcp__Roblox_Studio__generate_animation",
      "mcp__Roblox_Studio__generate_avatar",
      "mcp__Roblox_Studio__generate_mesh",
      "mcp__Roblox_Studio__generate_material",
      "mcp__Roblox_Studio__generate_texture",
      "mcp__Roblox_Studio__segment_mesh",
      "mcp__Roblox_Studio__create_skill",
      "mcp__Roblox_Studio__edit_skill"
    ],
    "deny": [
      "mcp__Roblox_Studio__open_cloud_invoke",
      "mcp__Roblox_Studio__submit_feedback"
    ]
  }
}
```

**Razón de la propuesta:**
- Deja automáticas la lectura, la edición de scripts y la prueba en Studio.
- Pide confirmación para lo que cuesta dinero, sube datos, guarda la place, crea skills o modifica assets.
- Bloquea `open_cloud_invoke`, que hace peticiones autenticadas a Open Cloud con los permisos del asistente, y bloquea el envío de comentarios a Roblox.
- Si el equipo necesita Open Cloud más adelante, cambia esa entrada a `ask` con una justificación concreta.

**b) Activar el servidor MCP de Roblox Studio:** hecho el 14-11-2026. Si lo desactivas, `mcp.bat` deja de existir y el servidor falla.

## 7. Riesgos residuales

- **Procesos del mismo usuario.** La ACL del token protege frente a otros usuarios, no frente a otros programas que corran con tu sesión. Cualquiera de ellos podría leer el token.
- **`run_script` ejecuta código del proyecto.** Revisa los scripts antes de ejecutarlos. Los de `logs/selftest/` son solo de prueba.
- **`execute_luau` de Roblox** puede modificar la place abierta sin restricciones. Además, su anotación indica que puede salir al exterior, así que conviene revisar qué servicios usa el código antes de ejecutarlo. Mitigación: guardar copias de la place con frecuencia.
- **Herramientas destructivas permitidas:** `multi_edit` y `execute_luau` (en la propuesta, automáticas por necesidad). `segment_mesh`, `generate_texture` y `edit_skill` piden confirmación.
- **`open_cloud_invoke`:** bloqueada en la propuesta. Si no se aplica la propuesta, Claude Code la pediría como cualquier otra herramienta.
- **`create_skill` y `edit_skill`:** pueden dejar instrucciones persistentes para el asistente. Piden confirmación en la propuesta.
- **`subagent` de Roblox:** ejecuta tareas de varios pasos sin un paso de aprobación, según la documentación oficial. Se deja automática por tu decisión de maximizar la velocidad. Puedes pasarla a `ask` en cualquier momento.
- **`save_place`:** la place actual no está guardada en la nube (`persistedToCloud: false`), así que guardar escribe en un archivo local. Pide confirmación en la propuesta. Haz copia antes de cambios grandes.
- **Blender queda abierto** al terminar la sesión, por diseño. Para cerrarlo, cierra su ventana.

## 8. Cómo desactivar o revocar

- **Blender:** elimina la entrada `blender` de `.mcp.json` y cierra Blender. Para cambiar el token, borra `%USERPROFILE%\.claude\blender_bridge\token.txt`; se regenera al abrir Blender.
- **Roblox Studio:** desactiva *Enable Studio as MCP server* en Studio. Así `mcp.bat` deja de funcionar. Para quitar la conexión del proyecto, elimina la entrada `Roblox_Studio` de `.mcp.json`.

## 9. Historial

- **14-11-2026, primera parte:** creación del puente de Blender y sus pruebas. ACL del token. Configuración de `.mcp.json` con dos servidores.
- **14-11-2026, segunda parte:** el usuario activó el interruptor de Studio. Se auditó `mcp.bat` y se probó la conexión en solo lectura. Se corrigió el inventario de 30 a 38 herramientas, con la propuesta de permisos actualizada. Los permisos siguen sin aplicar.
- **14-11-2026, tercera parte:** el usuario autorizó aplicar los permisos de la sección 6a. El clasificador de seguridad denegó otra vez la escritura de `.claude/settings.json`. Con una nueva instrucción explícita del usuario, se creó el archivo con el bloque de la sección 6a. El archivo no está en el repositorio del equipo.
