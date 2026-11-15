# Pipeline Blender ↔ Roblox

Estado al 14-11-2026. Documento de decisiones y de operación.

## 1. Estado

| Elemento | Estado | Detalle |
|---|---|---|
| Blender | Instalado y abierto automáticamente | 4.5.16 LTS en `C:\Users\black\AppData\Local\Programs\Blender Foundation\Blender 4.5` |
| Puente MCP con Blender | **Instalado y probado** | `tools/blender_mcp/`. 15/15 pruebas. Protocolo MCP correcto. Ver [docs/SEGURIDAD_MCP.md](docs/SEGURIDAD_MCP.md) |
| MCP de Roblox Studio | **Configurado; falta activarlo en Studio** | Servidor oficial de Roblox, firma válida. Ver [docs/PROCESOS_MCP.md](docs/PROCESOS_MCP.md) |
| Skills | 21 instalados + `references/` | Copiados de `arjun988/blender-skills` (MIT) a `.claude/skills/` |
| Skill de Roblox | Creado | `.claude/skills/roblox-export/`. El repositorio no trae uno para Roblox |
| Permisos de herramientas | **Aplicados** (14-11-2026) | Reglas en `.claude/settings.json`. Detalle en `docs/SEGURIDAD_MCP.md`, sección 6a |

## 2. Decisión sobre la conexión a Blender

Se eligió la **opción A del análisis anterior**: un puente propio, mínimo y auditable.

- El add-on oficial de terceros (`ahujasid/blender-mcp`) no se usa: se actualiza solo desde GitHub, tiene una capa de licencias en Supabase, integra proveedores externos y expone `exec()` sin autenticación.
- El puente propio usa solo la biblioteca estándar de Python. Escucha en `127.0.0.1`, exige un token de 256 bits, acepta 6 comandos fijos y solo ejecuta archivos `.py` del proyecto.

## 3. Flujo de trabajo con skills

```
blender-director
  → hard-surface | character-artist | creature-artist | prop-artist | environment-artist
  → uv-workflow / texture-workflow / materials / lookdev
  → lod-pipeline → collision-proxy → asset-optimization
  → export-pipeline → roblox-export → qa-review
```

Con el puente, cada paso se ejecuta con `blender_run_script` (scripts en `tools/blender/`) o con las herramientas `blender_budget_report` y `blender_export_fbx`.

## 4. Optimización aplicada

- **Menos contexto por sesión:** 21 skills de 94. Los de horror, anime, vehículos, Unity, Unreal y Godot no hacen falta para este juego.
- **Sin generadores ni APIs externas:** ninguna clave configurada y ninguna casilla activada.
- **Telemetría desactivada** en el servidor MCP de Blender (ningún servidor de telemetría; solo registros locales).
- **Configuración del proyecto:** `.mcp.json` solo se carga en esta carpeta.
- **Trabajo por lotes:** validar, exportar y generar LOD en una sola ejecución `-b`, no pieza por pieza.

## 5. Pendiente

1. **Activar** *Enable Studio as MCP server* en Roblox Studio y aprobar los servidores en Claude Code.
2. **Revisar** las reglas de permisos aplicadas (`docs/SEGURIDAD_MCP.md`, sección 6a) y reiniciar Claude Code para cargarlas.
3. **Validar** `roblox-export` en Studio: escala, colisión y materiales. Cada punto marcado `VERIFICAR EN STUDIO` debe probarse.
4. **Confirmar** si el concurso pide algún formato de entrega para los assets.
