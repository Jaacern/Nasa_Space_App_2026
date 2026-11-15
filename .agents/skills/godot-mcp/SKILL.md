---
name: godot-mcp
description: >-
  Use this skill when the user wants to create, inspect, run, or debug Godot Engine scenes, nodes, scripts, or 3D MeshLibraries using Godot MCP (Coding-Solo/godot-mcp), or integrate the Junior Astronaut Mission Trainer (Outpost Run) mechanics with Godot.
---

# Godot MCP (`Coding-Solo/godot-mcp`)

Skill centralizada en el proyecto `Nasa_Space_App_2026` a partir del repositorio oficial [`Coding-Solo/godot-mcp`](../../mcp/godot-mcp/README.md). Permite controlar el editor de Godot, crear escenas 2D/3D, agregar nodos, cargar texturas, exportar `MeshLibrary` y capturar la salida de depuración.

## Herramientas MCP Disponibles

### Gestión de Proyecto y Ejecución
- **`get_godot_version`**: Obtiene la versión instalada de Godot Engine.
- **`list_projects`**: Busca proyectos de Godot (`project.godot`) dentro de un directorio.
- **`get_project_info`**: Analiza la estructura de carpetas, escenas y recursos del proyecto.
- **`launch_editor`**: Abre el editor visual de Godot para el proyecto indicado.
- **`run_project` / `stop_project`**: Ejecuta el proyecto en modo depuración y lo detiene programáticamente.
- **`get_debug_output`**: Captura los logs de consola y errores de GDScript en tiempo real.

### Creación y Manipulación de Escenas (`godot_operations.gd`)
- **`create_scene`**: Crea una escena nueva (`.tscn`) especificando el tipo de nodo raíz (`Node3D`, `Node2D`, `Control`, etc.).
- **`add_node`**: Inserta nodos hijos en una escena existente con propiedades personalizadas.
- **`load_sprite`**: Carga texturas o imágenes de la NASA en nodos `Sprite2D` / `Sprite3D`.
- **`export_mesh_library`**: Convierte escenas 3D (por ejemplo, módulos del Outpost exportados desde Blender) en un recurso `MeshLibrary` para `GridMap`.
- **`save_scene`**: Guarda escenas o crea variantes heredadas.
- **`get_uid` / `update_project_uids`**: Gestiona referencias `uid://` en Godot 4.4+.

## Referencias Locales

- **[Documentación completa de Godot MCP (README.md)](./references/README.md)**
- **[Script de operaciones GDScript (godot_operations.gd)](./references/godot_operations.gd)**
- **[Servidor fuente TypeScript (.agents/mcp/godot-mcp/src/index.ts)](../../mcp/godot-mcp/src/index.ts)**

## Integración con `Nasa_Space_App_2026` (Outpost Run)

1. **Consumo de Datos NASA Saneados:**
   - Godot puede leer directamente los JSON estáticos de [`data/curated/`](../../../data/curated/) (`space_weather_scenarios.json`, `radiation.json`, `osdr_facts.json`, `mars_weather.json`, `rover_photos.json`) o conectarse por HTTP a la API local (`http://127.0.0.1:8787/api/...` levantada con `npm run api`).
2. **Pipeline Blender → Godot / Web 3D:**
   - Los módulos del Outpost (**Paneles Solares**, **Muro de Regolito**, **Invernadero**) modelados con `mcp-for-blender` se exportan en `.glb` y se convierten en `MeshLibrary` con `export_mesh_library` para construir la base lunar o marciana en un `GridMap`.
