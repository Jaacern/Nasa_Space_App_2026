# -*- coding: utf-8 -*-
"""Exporta los 28 assets de ARES FORGE desde Blender:
  - game/src/shared/Meshes/<nombre>.luau  (contrato EditableMesh en studs/ejes Roblox)
  - assets/export/<nombre>.fbx            (FBX con escala aplicada y ejes -Z/Y)
  - docs/assets/previews/<nombre>.png     (renders 512x512 en vista 3/4)
  - assets/blend/ares_assets.blend        (copia del archivo fuente)
  - docs/assets/CATALOGO_BLENDER.md       (tabla de inventario y presupuestos)

No usa rutas absolutas fijas: calcula RAIZ desde __file__.
"""
import importlib
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[1]
if str(AQUI) not in sys.path:
    sys.path.insert(0, str(AQUI))

import ares_lib as L  # noqa: E402
import build_assets  # noqa: E402

importlib.reload(L)
importlib.reload(build_assets)


def _ensure_preview_rig():
    scene = bpy.context.scene
    # Motor de render compatible con Blender 4.5
    engines = {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items}
    if "BLENDER_EEVEE_NEXT" in engines:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
        if hasattr(scene, "eevee"):
            scene.eevee.taa_render_samples = 16
    elif "BLENDER_EEVEE" in engines:
        scene.render.engine = "BLENDER_EEVEE"
    else:
        scene.render.engine = "BLENDER_WORKBENCH"

    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"

    # Mundo oscuro espacial con luz ambiente suave para leer caras en sombra
    world = bpy.data.worlds.get("ARES_World") or bpy.data.worlds.new("ARES_World")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg is not None:
        bg.inputs["Color"].default_value = (0.015, 0.022, 0.040, 1.0)
        bg.inputs["Strength"].default_value = 1.0
    scene.world = world

    # Camara dedicada
    cam_ob = bpy.data.objects.get("ARES_PreviewCam")
    if cam_ob is None:
        cam_data = bpy.data.cameras.new("ARES_PreviewCam")
        cam_ob = bpy.data.objects.new("ARES_PreviewCam", cam_data)
        scene.collection.objects.link(cam_ob)
    cam_ob.data.lens = 38.0
    cam_ob.data.clip_start = 0.05
    cam_ob.data.clip_end = 500.0
    scene.camera = cam_ob

    # Luces clave y relleno
    def _sun(name, rot_deg, energy, color=(1.0, 1.0, 1.0)):
        ob = bpy.data.objects.get(name)
        if ob is None:
            ld = bpy.data.lights.new(name, type="SUN")
            ob = bpy.data.objects.new(name, ld)
            scene.collection.objects.link(ob)
        ob.data.energy = energy
        ob.data.color = color
        ob.rotation_euler = tuple(math.radians(a) for a in rot_deg)
        return ob

    key = _sun("ARES_KeySun", (52, 12, -38), 3.4, (1.0, 0.96, 0.92))
    fill = _sun("ARES_FillSun", (65, -20, 145), 1.4, (0.65, 0.80, 1.0))
    return cam_ob, key, fill


def _remove_preview_rig(cam_ob, key, fill):
    for ob in (cam_ob, key, fill):
        if ob is not None and ob.name in bpy.data.objects:
            data = ob.data
            bpy.data.objects.remove(ob, do_unlink=True)
            if data is not None and data.users == 0:
                if isinstance(data, bpy.types.Camera):
                    bpy.data.cameras.remove(data)
                elif isinstance(data, bpy.types.Light):
                    bpy.data.lights.remove(data)


def _world_bbox_meters(col):
    pts = []
    for ob in col.all_objects:
        if ob.type == "MESH":
            M = ob.matrix_world
            for corner in ob.bound_box:
                pts.append(M @ Vector(corner))
    if not pts:
        return Vector((0, 0, 0)), 1.0
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (mn + mx) * 0.5
    radius = max((mx - mn).length * 0.5, 0.15)
    return center, radius


def _export_fbx(col, ruta_fbx: Path):
    ruta_fbx.parent.mkdir(parents=True, exist_ok=True)
    objs = [ob for ob in col.all_objects if ob.type in {"MESH", "ARMATURE", "EMPTY"}]
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.select_set(True)
    if objs:
        bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=str(ruta_fbx),
        use_selection=True,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        object_types={"MESH", "ARMATURE", "EMPTY"},
        path_mode="COPY",
        embed_textures=False,
        use_mesh_modifiers=True,
    )


def _render_preview(col, cam_ob, ruta_png: Path):
    ruta_png.parent.mkdir(parents=True, exist_ok=True)
    center, rad = _world_bbox_meters(col)
    # Vista 3/4 mirando al frente (-Y) y ligeramente desde el lado izquierdo (-X) y arriba (+Z)
    view_dir = Vector((-0.95, -1.25, 0.62)).normalized()
    fov_half = math.atan(18.0 / cam_ob.data.lens)  # sensor ~36mm -> mitad 18mm
    dist = (rad / math.sin(fov_half)) * 1.15
    cam_ob.location = center + view_dir * dist
    direction = (center - cam_ob.location).normalized()
    cam_ob.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.filepath = str(ruta_png)
    bpy.ops.render.render(write_still=True)


def _write_catalog(rows):
    ruta = RAIZ / "docs" / "assets" / "CATALOGO_BLENDER.md"
    ruta.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Catálogo de assets 3D de ARES FORGE",
        "",
        "Fecha: 14-11-2026. Generado automáticamente por `tools/blender/export_assets.py`.",
        "Convención: 1 stud = 0,28 m. Ejes en Blender: +Z arriba, frente -Y. Ejes en Roblox: +Y arriba, frente -Z.",
        "Materiales: sombreado plano facetado sin texturas; un objeto `SM_<nombre>_<MAT_xxx>` por material.",
        "",
        "## 1. Inventario de los 28 assets",
        "",
        "| Asset | Familia | Descripción | Tris | Presupuesto | Mats | Tamaño en studs (X×Y×Z) | Pivote | Estado |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        lines.append(
            f"| `{r['name']}` | {r['family']} | {r['desc']} | {r['tris']} | ≤ {r['max_tris']} | "
            f"{r['mats']}/{r['max_mats']} | {r['size']} | {r['pivot']} | {r['status']} |"
        )
    lines += [
        "",
        "## 2. Posiciones de montaje en la nave (`SHIP_MOUNTS`)",
        "",
        "Coordenadas en studs, ejes de Roblox (`+Y` arriba, `-Z` frente), relativas al origen de `Ship` (`0, 0, 0` en el suelo).",
        "",
        "| Pieza | Nombre | Posición Roblox (X, Y, Z) | Orientación / nota |",
        "|---|---|---|---|",
        f"| `Piece1` | MMRTG | `{L.SHIP_MOUNTS['Piece1']}` | Trasera (`+Z`), eje largo a lo largo de X |",
        f"| `Piece2` | Antena de alta ganancia | `{L.SHIP_MOUNTS['Piece2']}` | Sobre la punta superior, plato mirando a `+Y` |",
        f"| `Piece3` | Generador de oxígeno | `{L.SHIP_MOUNTS['Piece3']}` | Costado `-X` del fuselaje |",
        f"| `Piece4` | Propulsor de retorno | `{L.SHIP_MOUNTS['Piece4']}` | Bajo el fuselaje, boca hacia abajo (`-Y`) |",
        "",
        "## 3. Archivos generados",
        "",
        "- Módulos Luau (`EditableMesh`): `game/src/shared/Meshes/<nombre>.luau`",
        "- FBX (flujo clásico): `assets/export/<nombre>.fbx`",
        "- Vistas previas PNG (512×512): `docs/assets/previews/<nombre>.png`",
        "- Archivo fuente Blender: `assets/blend/ares_assets.blend`",
        "",
        "## 4. Cómo regenerar todo",
        "",
        "Con Blender abierto y el puente activo, ejecuta el script `tools/blender/export_assets.py` (por ejemplo mediante `blender_run_script`), o en línea de comandos:",
        "",
        "```bash",
        '"<ruta-a-blender.exe>" -b --factory-startup -noaudio --python tools/blender/export_assets.py',
        "```",
        "",
    ]
    ruta.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def _purge_stray_scene_objects():
    """Elimina objetos sueltos fuera de las colecciones de assets (p.ej. Cube/Camera/Light iniciales)."""
    valid_cols = {"COL_" + info[0] for info in L.ASSETS}
    for ob in list(bpy.data.objects):
        in_asset_col = any(c.name in valid_cols for c in ob.users_collection)
        if not in_asset_col and not ob.name.startswith("ARES_"):
            data = ob.data
            bpy.data.objects.remove(ob, do_unlink=True)
            if data is not None and data.users == 0:
                if isinstance(data, bpy.types.Mesh):
                    bpy.data.meshes.remove(data)
                elif isinstance(data, bpy.types.Camera):
                    bpy.data.cameras.remove(data)
                elif isinstance(data, bpy.types.Light):
                    bpy.data.lights.remove(data)


def export_all():
    cols = build_assets.build_all()
    _purge_stray_scene_objects()
    cam_ob, key, fill = _ensure_preview_rig()

    asset_cols = [bpy.data.collections.get("COL_" + info[0]) for info in L.ASSETS]
    for c in asset_cols:
        if c is not None:
            c.hide_render = True

    rows = []
    errors = []
    for name, family, desc, max_tris, max_mats, pivot in L.ASSETS:
        col = cols[name]
        with L.en_origen(name):
            partes = L.recoger_partes(col)
            ruta_luau = RAIZ / "game" / "src" / "shared" / "Meshes" / f"{name}.luau"
            tris, nbytes = L.escribir_luau(name, partes, ruta_luau)
            mnx, mxx, mny, mxy, mnz, mxz = L.bbox_studs(partes)
            size_str = f"{mxx - mnx:.1f}×{mxy - mny:.1f}×{mxz - mnz:.1f}"

            ruta_fbx = RAIZ / "assets" / "export" / f"{name}.fbx"
            _export_fbx(col, ruta_fbx)

            col.hide_render = False
            ruta_png = RAIZ / "docs" / "assets" / "previews" / f"{name}.png"
            _render_preview(col, cam_ob, ruta_png)
            col.hide_render = True

        nmats = len(partes)
        ok = (tris <= max_tris) and (nmats <= max_mats) and (nbytes < 180000)
        status = "PASS" if ok else "FAIL"
        if not ok:
            errors.append(f"{name}: tris={tris}/{max_tris}, mats={nmats}/{max_mats}, bytes={nbytes}")
        rows.append({
            "name": name,
            "family": family,
            "desc": desc,
            "tris": tris,
            "max_tris": max_tris,
            "mats": nmats,
            "max_mats": max_mats,
            "size": size_str,
            "pivot": pivot,
            "status": status,
        })
        print(f"[{status}] {name:10s} tris={tris:4d}/{max_tris:<4d} mats={nmats}/{max_mats} bytes={nbytes:6d} size={size_str}")

    for c in asset_cols:
        if c is not None:
            c.hide_render = False

    _remove_preview_rig(cam_ob, key, fill)
    L.colocar_en_rejilla()

    blend_path = RAIZ / "assets" / "blend" / "ares_assets.blend"
    blend_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), copy=True)

    _write_catalog(rows)
    if errors:
        raise RuntimeError("Validacion fallida: " + "; ".join(errors))
    print(f"Exportacion completa: {len(rows)} assets OK -> {blend_path.name}")
    return rows


if __name__ == "__main__":
    export_all()
