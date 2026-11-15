"""Convierte el astronauta riggeado (.fbx + texturas PBR 4K) en un .glb listo para la web.

Uso (Blender en modo headless, desde la raíz del proyecto):
  ./blender-5.3.0-linux-x64/blender -b --python scripts/convert_astronaut.py

- Reconstruye los dos materiales (bake_1, bake_2) con Principled BSDF y sus mapas PBR.
- Reduce las texturas de 4096 a 1024 px (carga rápida en GitHub Pages).
- Conserva la armadura, el skinning y el clip de animación (renombrado a "idle").
"""
import os
import tempfile
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "ASSETS 3D", "3D Models", "astronaut-rigged-and-animated")
FBX = os.path.join(SRC, "source", "astronaught_3_1.fbx")
TEXTURES = os.path.join(SRC, "textures")
OUT = os.path.join(ROOT, "public", "assets", "models", "astronaut_guide.glb")
TEX_SIZE = 1024
TMP = tempfile.mkdtemp(prefix="astronaut_tex_")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=FBX)


def load_texture(name, color):
    path = os.path.join(TEXTURES, name)
    if not os.path.exists(path):
        return None
    img = bpy.data.images.load(path)
    img.scale(TEX_SIZE, TEX_SIZE)
    # Se guarda la copia reducida y se enlaza a ella: así el exportador no relee el PNG 4K original.
    small = os.path.join(TMP, name.replace("_4k", "_1k"))
    img.filepath_raw = small
    img.file_format = "PNG"
    img.save()
    img.reload()
    img.colorspace_settings.name = "sRGB" if color else "Non-Color"
    return img


def rebuild_material(mat, prefix):
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    def tex_node(suffix, color):
        img = load_texture(f"{prefix}_{suffix}_4k.png", color)
        if not img:
            return None
        node = nt.nodes.new("ShaderNodeTexImage")
        node.image = img
        return node

    diffuse = tex_node("diffuse", True)
    if diffuse:
        nt.links.new(diffuse.outputs["Color"], bsdf.inputs["Base Color"])
    rough = tex_node("rough", False)
    if rough:
        nt.links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])
    metal = tex_node("metal", False)
    if metal:
        nt.links.new(metal.outputs["Color"], bsdf.inputs["Metallic"])
    else:
        bsdf.inputs["Metallic"].default_value = 0.0
    normal = tex_node("normal", False)
    if normal:
        nmap = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(normal.outputs["Color"], nmap.inputs["Color"])
        nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])


for mat in bpy.data.materials:
    if mat.name.startswith("bake_1"):
        rebuild_material(mat, "bake_1")
    elif mat.name.startswith("bake_2"):
        rebuild_material(mat, "bake_2")

# Las imágenes originales del FBX apuntan a rutas inexistentes (E:/...): fuera.
for img in list(bpy.data.images):
    if img.users == 0:
        bpy.data.images.remove(img)

for action in bpy.data.actions:
    action.name = "idle"

bpy.ops.export_scene.gltf(
    filepath=OUT,
    export_format="GLB",
    export_image_format="JPEG",
    export_image_quality=88,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_skins=True,
    export_yup=True,
    export_apply=False,
)
print("GLB exportado:", OUT, os.path.getsize(OUT), "bytes")
