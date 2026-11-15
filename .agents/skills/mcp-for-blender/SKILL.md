---
name: mcp-for-blender
description: >-
  Use this skill when the user wants to create, edit, texture, rig, animate, or export 3D models and scenes in Blender using MCP for Blender (ahujasid/mcp-for-blender), including generating 3D assets (.glb/.gltf) for the NASA Space Apps 2026 Three.js/R3F landing page (portfolio-itom template) or outpost game.
---

# MCP for Blender (`ahujasid/mcp-for-blender`)

Skill centralizada en el proyecto `Nasa_Space_App_2026` a partir del repositorio oficial [`ahujasid/mcp-for-blender`](../../mcp/mcp-for-blender/README.md). Conecta Blender con el agente mediante el Model Context Protocol (socket local en `localhost:9876`).

## Herramientas MCP Principales

1. **`get_scene_info` / `get_object_info`**: Inspecciona los objetos actuales, escala del mundo y `world_bounding_box` antes de modificar la escena.
2. **`look(mode="camera" | "angles", shading="rendered" | "material" | "solid")`**: Captura vistas de cámara o ángulos ortogonales para verificar proporciones, materiales e iluminación.
3. **`execute_blender_code`**: Ejecuta scripts de Python (`bpy`) directamente dentro de Blender para modelado procedural, modificadores, nodos de materiales y exportación `.glb` / `.gltf`.
4. **`search_assets` / `import_asset`**: Busca e importa HDRIs, materiales PBR y modelos 3D desde **Poly Haven** (CC0), **Sketchfab** o **Poly Pizza**.
5. **`generate_3d`**: Genera objetos 3D ("hero props") individuales a partir de texto o imagen.

## Guías Oficiales de Flujo de Trabajo (Progressive Disclosure)

Lee estas guías de referencia según la tarea específica en Blender:

- **[Diseño de Escenas (scene.md)](./references/scene.md)**: Blockout a escala real, composición de cámara, regla de tercios, contacto con el suelo (`min_z`) e iluminación con HDRI + luces clave.
- **[API de Python en Blender (bpy.md)](./references/bpy.md)**: Patrones seguros de `bpy` compatibles con Blender 4.x y 5.0+, operaciones sin depender de `bpy.ops` y manejo de contextos.
- **[Materiales y Texturas PBR (materials.md)](./references/materials.md)**: Principled BSDF, valores físicos reales de `Metallic` y `Roughness`, proyección UV y texturas de Poly Haven.
- **[Diseño de Niveles (level-design.md)](./references/level-design.md)**: Construcción modular de entornos y exportación limpia a motores web (Three.js / R3F) o Godot.
- **[Animación (animation.md)](./references/animation.md)**: Keyframes, curvas F-Curve, ciclos de animación y exportación en `.glb`.
- **[Rigging (rigging.md)](./references/rigging.md)**: Armatures, pesos y restricciones para vehículos, rovers o personajes.
- **[Retopología (retopology.md)](./references/retopology.md)**: Optimización de mallas (`Decimate`, `Remesh`) para mantener 60 FPS en WebGL (`portfolio-itom`).

## Uso en `Nasa_Space_App_2026` (Landing Page `portfolio-itom` + Outpost Run)

1. **Reemplazo del Avión de Papel (`Paper Airplane`) de `portfolio-itom`:**
   - Modela o importa un cohete ligero / cápsula Orion (`< 15k triángulos`), orienta su eje frontal y expórtalo con `bpy.ops.export_scene.gltf(filepath="public/assets/models/orion_rocket.glb", export_format="GLB")`.
2. **Módulos del Outpost Lunar y Marciano:**
   - Genera los 3 módulos apilables del juego ([content/cards.json](../../../content/cards.json)): **Paneles Solares**, **Muro de Regolito Sinterizado** e **Invernadero Hidropónico**.
3. **Relieve Real desde NASA Mars/Moon Trek WMTS:**
   - Usa las teselas de [data/curated/mars_layers.json](../../../data/curated/mars_layers.json) como mapa de desplazamiento (`Displacement` node) sobre un plano subdividido en Blender para hornear terrenos 3D reales del Cráter Jezero o Shackleton.

## Activación Rápida del Servidor, Addon y Repositorio Oficial `blender/blender`

- **Repositorio oficial `blender/blender` (Scripts Python y Documentación `bpy`)**:
  - Raíz clonada: [`.agents/mcp/blender/`](../../mcp/blender/README.md)
  - Ejemplos oficiales de `bpy`, `bmesh`, `mathutils` y `gpu`: [`.agents/mcp/blender/doc/python_api/examples/`](../../mcp/blender/doc/python_api/examples/)
  - Documentación RST de la API Python: [`.agents/mcp/blender/doc/python_api/rst/`](../../mcp/blender/doc/python_api/rst/)
  - Plantillas oficiales de Python (`templates_py`): [`.agents/mcp/blender/scripts/templates_py/`](../../mcp/blender/scripts/templates_py/)
  - Exportador oficial glTF 2.0 / `.glb` (para Three.js / `portfolio-itom`): [`.agents/mcp/blender/scripts/addons_core/io_scene_gltf2/`](../../mcp/blender/scripts/addons_core/io_scene_gltf2/)
- **Código fuente local de `mcp-for-blender`:** [`.agents/mcp/mcp-for-blender/`](../../mcp/mcp-for-blender/)
- **Addon de Blender:** [`.agents/mcp/mcp-for-blender/addon.py`](../../mcp/mcp-for-blender/addon.py) (en Blender: *Edit → Preferences → Add-ons → Install from Disk* o mediante `uvx mcp-for-blender install-addon`).
- En la vista 3D de Blender presiona `N` → pestaña **MCP for Blender** → **Start MCP Server** (puerto `9876`).
