# -*- coding: utf-8 -*-
"""ARES FORGE - biblioteca de ayudas para modelar assets low-poly facetados en Blender.

Convenciones:
  * Se modela en STUDS (1 stud = 0,28 m). Al crear la malla en Blender todo se escala por S (=0,28).
  * Ejes Blender: Z arriba, el "frente" del asset mira a -Y.
  * Cada asset es una coleccion COL_<nombre> con UNA malla por material: SM_<nombre>_<MAT_xxx>.
  * Mallas trianguladas, sombreado plano, normales recalculadas hacia fuera.
No usa rutas absolutas: la raiz del proyecto se calcula a partir de __file__.
"""
import contextlib
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[1]          # tools/blender/ -> tools/ -> RAIZ
if str(AQUI) not in sys.path:
    sys.path.insert(0, str(AQUI))

S = 0.28  # metros por stud

# ----------------------------------------------------------------------------- paleta
# nombre: (rgb 0-255, material Roblox, emisivo, alpha de transparencia 0-1)
PALETA = {
    "MAT_RockDark":    ((38, 22, 34),    "Slate",         False, 0.0),
    "MAT_Rock":        ((70, 52, 58),    "Slate",         False, 0.0),
    "MAT_RockRust":    ((110, 66, 48),   "Slate",         False, 0.0),
    "MAT_Ice":         ((150, 190, 225), "Glass",         False, 0.0),
    "MAT_GlowRed":     ((255, 45, 85),   "Neon",          True,  0.0),
    "MAT_GlowMagenta": ((255, 0, 170),   "Neon",          True,  0.0),
    "MAT_GlowOrange":  ((255, 107, 53),  "Neon",          True,  0.0),
    "MAT_GlowCyan":    ((0, 210, 255),   "Neon",          True,  0.0),
    "MAT_GlowGold":    ((255, 200, 40),  "Neon",          True,  0.0),
    "MAT_Gold":        ((212, 160, 40),  "Foil",          False, 0.0),
    "MAT_HullWhite":   ((235, 240, 245), "SmoothPlastic", False, 0.0),
    "MAT_HullGrey":    ((200, 205, 215), "Metal",         False, 0.0),
    "MAT_HullDark":    ((60, 66, 80),    "Metal",         False, 0.0),
    "MAT_Glass":       ((140, 200, 230), "Glass",         False, 0.5),
    # Colores oficiales de la insignia NASA (azul #0B3D91, rojo #FC3D21)
    "MAT_NasaBlue":    ((11, 61, 145),   "SmoothPlastic", False, 0.0),
    "MAT_NasaRed":     ((252, 61, 33),   "SmoothPlastic", False, 0.0),
}
ORDEN_MAT = list(PALETA.keys())

# alias cortos para los scripts de construccion
MD, MR, MU, ICE = "MAT_RockDark", "MAT_Rock", "MAT_RockRust", "MAT_Ice"
RED, MAG, ORA, CYA, GLD = "MAT_GlowRed", "MAT_GlowMagenta", "MAT_GlowOrange", "MAT_GlowCyan", "MAT_GlowGold"
GOLD, HW, HG, HD, GLS = "MAT_Gold", "MAT_HullWhite", "MAT_HullGrey", "MAT_HullDark", "MAT_Glass"

# nombre, familia, descripcion, presupuesto tris, max materiales, pivote
ASSETS = [
    ("chaser",   "Enemigo",  "Remolino de polvo",            900, 3, "suelo"),
    ("tank",     "Enemigo",  "Golem de regolito",            900, 3, "suelo"),
    ("ranged",   "Enemigo",  "Centinela ionico",             900, 3, "suelo (flota, base a 1,5)"),
    ("kamikaze", "Enemigo",  "Meteoroide inestable",         900, 3, "suelo (flota, centro a 2)"),
    ("elite1",   "Elite",    "Tolvanera mayor",             2500, 3, "suelo"),
    ("elite2",   "Elite",    "Coloso de hielo",             2500, 3, "suelo"),
    ("elite3",   "Elite",    "Heraldo solar",               2500, 3, "suelo"),
    ("boss1",    "Jefe",     "Tormenta de polvo global",    4000, 4, "suelo"),
    ("boss2",    "Jefe",     "Coloso de la lluvia de rocas", 4000, 4, "suelo"),
    ("boss3",    "Jefe",     "Heraldo de la erupcion",      4000, 4, "suelo"),
    ("final",    "Jefe",     "Coloso de la tormenta solar", 4000, 4, "suelo"),
    ("gem",      "Recompensa", "Muestra dorada",             500, 3, "suelo (flota, centro a 1,2)"),
    ("chest",    "Recompensa", "Contenedor de carga",        500, 3, "suelo"),
    ("drone",    "Jugador",  "Dron helicoptero",             500, 3, "suelo (flota, centro a 3,2)"),
    ("shot",     "Jugador",  "Rayo cian",                    500, 3, "suelo (centro a 2,6)"),
    ("eshot",    "Enemigo",  "Esfera de plasma enemiga",     500, 3, "suelo (centro a 2,6)"),
    ("Helmet",   "Jugador",  "Casco de astronauta",          500, 3, "centro del casco"),
    ("Backpack", "Jugador",  "Mochila de soporte vital",     500, 3, "centro de la mochila"),
    ("Piece1",   "Pieza",    "MMRTG",                       1200, 3, "centro de la pieza"),
    ("Piece2",   "Pieza",    "Antena de alta ganancia",     1200, 3, "centro de la pieza"),
    ("Piece3",   "Pieza",    "Generador de oxigeno",        1200, 3, "centro de la pieza"),
    ("Piece4",   "Pieza",    "Propulsor",                   1200, 3, "centro de la pieza"),
    ("Ship",     "Nave",     "Modulo de aterrizaje",        5000, 4, "suelo"),
    ("RockA",    "Entorno",  "Roca marciana 3",              300, 3, "suelo"),
    ("RockB",    "Entorno",  "Roca marciana 5",              300, 3, "suelo"),
    ("RockC",    "Entorno",  "Roca marciana 8",              300, 3, "suelo"),
    ("RidgeA",   "Entorno",  "Cresta/meseta del horizonte A", 400, 3, "suelo"),
    ("RidgeB",   "Entorno",  "Cresta/meseta del horizonte B", 400, 3, "suelo"),
    ("Rover",    "Entorno",  "Rover Perseverance (medidas NASA/JPL-Caltech)", 900, 4, "suelo"),
    ("Insignia", "Marca",    "Insignia NASA (menu principal)", 9000, 3, "centro"),
]
ASSET_INFO = {a[0]: a for a in ASSETS}

# Posiciones (studs, ejes Roblox, relativas al origen de la nave) donde se montan las 4 piezas.
SHIP_MOUNTS = {
    "Piece1": (0.0, 8.5, 6.6),    # MMRTG: trasera (+Z Roblox), eje largo a lo largo de X
    "Piece2": (0.0, 23.6, 0.0),   # antena: sobre la punta, plato mirando a +Y(Roblox arriba)
    "Piece3": (-6.3, 12.0, 0.0),  # generador O2: costado -X Roblox
    "Piece4": (0.0, 3.0, 0.0),    # propulsor: bajo el fuselaje, boca hacia abajo
}


# ----------------------------------------------------------------------------- materiales
def _lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def crear_materiales():
    """Crea/actualiza los materiales de la paleta (idempotente)."""
    for nombre, (rgb, _rm, emis, alpha) in PALETA.items():
        mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
        lin = (_lin(rgb[0]), _lin(rgb[1]), _lin(rgb[2]))
        mat.use_nodes = True
        mat.diffuse_color = (*lin, 1.0)
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf is not None:
            bsdf.inputs["Base Color"].default_value = (*lin, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.85
            bsdf.inputs["Alpha"].default_value = 1.0 - alpha
            if emis:
                bsdf.inputs["Emission Color"].default_value = (*lin, 1.0)
                bsdf.inputs["Emission Strength"].default_value = 3.0
            else:
                bsdf.inputs["Emission Strength"].default_value = 0.0
    return {n: bpy.data.materials[n] for n in PALETA}


# ----------------------------------------------------------------------------- matrices
def xf(loc=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1)):
    T = Matrix.Translation(Vector(loc))
    R = Euler([math.radians(a) for a in rot], "XYZ").to_matrix().to_4x4()
    Sm = Matrix.Diagonal(Vector((scl[0], scl[1], scl[2], 1.0)))
    return T @ R @ Sm


def orient(pos, direccion, roll=0.0, scl=(1, 1, 1)):
    """Matriz con el eje Z local apuntando a `direccion`, colocada en `pos`."""
    d = Vector(direccion).normalized()
    q = Vector((0, 0, 1)).rotation_difference(d)
    M = Matrix.Translation(Vector(pos)) @ q.to_matrix().to_4x4() @ Matrix.Rotation(math.radians(roll), 4, "Z")
    return M @ Matrix.Diagonal(Vector((scl[0], scl[1], scl[2], 1.0)))


# ----------------------------------------------------------------------------- generadores de geometria (V, F)
def g_lathe(prof, seg=8, closed=False, phase=0.0):
    """Solido de revolucion alrededor de Z. prof = [(r, z), ...]. r=0 -> un unico vertice (apice)."""
    V, F, rings = [], [], []
    for r, z in prof:
        if abs(r) < 1e-6:
            rings.append(("p", len(V)))
            V.append((0.0, 0.0, z))
        else:
            idx = []
            for k in range(seg):
                ang = 2 * math.pi * (k + phase) / seg
                idx.append(len(V))
                V.append((r * math.cos(ang), r * math.sin(ang), z))
            rings.append(("r", idx))
    n = len(prof)
    pares = range(n) if closed else range(n - 1)
    for i in pares:
        A, B = rings[i], rings[(i + 1) % n]
        if A[0] == "p" and B[0] == "p":
            continue
        for k in range(seg):
            k2 = (k + 1) % seg
            if A[0] == "p":
                F.append((A[1], B[1][k2], B[1][k]))
            elif B[0] == "p":
                F.append((A[1][k], A[1][k2], B[1]))
            else:
                F.append((A[1][k], A[1][k2], B[1][k2], B[1][k]))
    if not closed:
        if rings[0][0] == "r":
            F.append(tuple(reversed(rings[0][1])))
        if rings[-1][0] == "r":
            F.append(tuple(rings[-1][1]))
    return V, F


def g_box(size):
    x, y, z = size[0] / 2, size[1] / 2, size[2] / 2
    V = [(-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z), (-x, -y, z), (x, -y, z), (x, y, z), (-x, y, z)]
    F = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return V, F


_PHI = (1 + 5 ** 0.5) / 2


def g_ico(sub=1, jitter=0.0, seed=0):
    rnd = random.Random(seed)
    P = _PHI
    v = [(-1, P, 0), (1, P, 0), (-1, -P, 0), (1, -P, 0), (0, -1, P), (0, 1, P),
         (0, -1, -P), (0, 1, -P), (P, 0, -1), (P, 0, 1), (-P, 0, -1), (-P, 0, 1)]
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2),
         (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5),
         (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    V = [Vector(p).normalized() for p in v]
    for _ in range(sub):
        cache, nf = {}, []

        def mid(i, j):
            key = (min(i, j), max(i, j))
            if key not in cache:
                V.append(((V[i] + V[j]) / 2).normalized())
                cache[key] = len(V) - 1
            return cache[key]
        for a, b, c in f:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        f = nf
    if jitter:
        V = [p * (1 + rnd.uniform(-jitter, jitter)) for p in V]
    return [tuple(p) for p in V], f


def g_hull(pts):
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
    bm.verts.ensure_lookup_table()
    usados = [v for v in bm.verts if v.link_faces]
    idx = {v.index: i for i, v in enumerate(usados)}
    V = [tuple(v.co) for v in usados]
    F = [tuple(idx[v.index] for v in f.verts) for f in bm.faces]
    bm.free()
    return V, F


# ----------------------------------------------------------------------------- Asset
class Asset:
    def __init__(self, name):
        self.name = name
        self.geo = {}          # material -> ([V], [F])
        self.base = Matrix.Identity(4)

    @contextlib.contextmanager
    def local(self, loc=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1)):
        viejo = self.base
        self.base = viejo @ xf(loc, rot, scl)
        try:
            yield
        finally:
            self.base = viejo

    def put(self, mat, V, F, loc=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1), M=None):
        assert mat in PALETA, mat
        T = self.base @ (M if M is not None else xf(loc, rot, scl))
        lst = self.geo.setdefault(mat, ([], []))
        b = len(lst[0])
        lst[0].extend(tuple(T @ Vector(v)) for v in V)
        lst[1].extend(tuple(b + i for i in f) for f in F)

    # ---- primitivas
    def lathe(self, mat, prof, seg=8, closed=False, phase=0.0, **kw):
        V, F = g_lathe(prof, seg, closed, phase)
        self.put(mat, V, F, **kw)

    def box(self, mat, size, **kw):
        V, F = g_box(size)
        self.put(mat, V, F, **kw)

    def cyl(self, mat, r, h, seg=8, base=False, r2=None, **kw):
        z0 = 0 if base else -h / 2
        self.lathe(mat, [(0, z0), (r, z0), (r if r2 is None else r2, z0 + h), (0, z0 + h)], seg=seg, **kw)

    def cone(self, mat, r, h, seg=6, r2=0.0, **kw):
        prof = [(0, 0), (r, 0), (r2, h)] + ([(0, h)] if r2 > 0 else [])
        self.lathe(mat, prof, seg=seg, **kw)

    def ico(self, mat, r, sub=1, jitter=0.0, seed=0, scl=(1, 1, 1), **kw):
        V, F = g_ico(sub, jitter, seed)
        V = [(p[0] * r, p[1] * r, p[2] * r) for p in V]
        self.put(mat, V, F, scl=scl, **kw)

    def ring(self, mat, R, w, hh, seg=10, **kw):
        """Anillo facetado de seccion en rombo (R radio medio, w semianchura radial, hh semialtura)."""
        self.lathe(mat, [(R - w, 0), (R, -hh), (R + w, 0), (R, hh)], seg=seg, closed=True, **kw)

    def band(self, mat, R, w, hh, seg=12, **kw):
        """Anillo de seccion trapezoidal (mas 'duro' que el rombo)."""
        self.lathe(mat, [(R - w, -hh), (R + w * 0.6, -hh), (R + w, hh * 0.6), (R - w, hh)],
                   seg=seg, closed=True, **kw)

    def octa(self, mat, r, h, seg=4, **kw):
        self.lathe(mat, [(0, -h), (r, 0), (0, h)], seg=seg, **kw)

    def hull(self, mat, pts, **kw):
        V, F = g_hull(pts)
        self.put(mat, V, F, **kw)

    def strut(self, mat, p1, p2, r, seg=4, **kw):
        a, b = Vector(p1), Vector(p2)
        d = b - a
        L = d.length
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        M = Matrix.Translation((a + b) / 2) @ q.to_matrix().to_4x4()
        V, F = g_lathe([(0, -L / 2), (r, -L / 2), (r, L / 2), (0, L / 2)], seg)
        self.put(mat, V, F, M=M)

    # ---- estadisticas previas
    def tris(self):
        return sum(len(f) - 2 for _, (_, Fs) in self.geo.items() for f in Fs)

    def finish(self, center=False, floor=False):
        """Crea la coleccion COL_<name> y una malla por material. Devuelve la coleccion."""
        mats = crear_materiales()
        todos = [Vector(v) for (Vs, _) in self.geo.values() for v in Vs]
        off = Vector((0, 0, 0))
        if center and todos:
            mn = Vector((min(v.x for v in todos), min(v.y for v in todos), min(v.z for v in todos)))
            mx = Vector((max(v.x for v in todos), max(v.y for v in todos), max(v.z for v in todos)))
            off = -(mn + mx) / 2
        borrar_coleccion("COL_" + self.name)
        col = bpy.data.collections.new("COL_" + self.name)
        bpy.context.scene.collection.children.link(col)
        for mat in sorted(self.geo, key=ORDEN_MAT.index):
            Vs, Fs = self.geo[mat]
            bm = bmesh.new()
            bv = []
            for v in Vs:
                p = Vector(v) + off
                if floor and p.z < 0:
                    p.z = 0.0
                bv.append(bm.verts.new(p * S))
            vistos = set()
            for f in Fs:
                if len(set(f)) < 3:
                    continue
                key = tuple(sorted(f))
                if key in vistos:
                    continue
                vistos.add(key)
                try:
                    bm.faces.new([bv[i] for i in f])
                except ValueError:
                    pass
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
            bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="BEAUTY", ngon_method="BEAUTY")
            nombre = "SM_%s_%s" % (self.name, mat)
            me = bpy.data.meshes.new(nombre)
            bm.to_mesh(me)
            bm.free()
            for p in me.polygons:
                p.use_smooth = False
            me.materials.append(mats[mat])
            ob = bpy.data.objects.new(nombre, me)
            col.objects.link(ob)
        return col


def borrar_coleccion(nombre):
    col = bpy.data.collections.get(nombre)
    if col is not None:
        for ob in list(col.all_objects):
            me = ob.data
            bpy.data.objects.remove(ob, do_unlink=True)
            if me is not None and me.users == 0:
                bpy.data.meshes.remove(me)
        bpy.data.collections.remove(col)
    base = nombre[4:]
    for me in list(bpy.data.meshes):
        if me.name.startswith("SM_%s_MAT_" % base) and me.users == 0:
            bpy.data.meshes.remove(me)


# ----------------------------------------------------------------------------- disposicion y origen
def colocar_en_rejilla():
    """Separa las colecciones en una rejilla (solo para ver el .blend). Export/preview las devuelven al origen."""
    for i, info in enumerate(ASSETS):
        col = bpy.data.collections.get("COL_" + info[0])
        if col is None:
            continue
        pos = ((i % 7) * 26.0, -(i // 7) * 26.0, 0.0)
        for ob in col.all_objects:
            ob.location = pos


@contextlib.contextmanager
def en_origen(nombre_col):
    col = bpy.data.collections["COL_" + nombre_col]
    guardado = {}
    for ob in col.all_objects:
        guardado[ob] = ob.location.copy()
        ob.location = (0, 0, 0)
    bpy.context.view_layer.update()
    try:
        yield col
    finally:
        for ob, loc in guardado.items():
            ob.location = loc
        bpy.context.view_layer.update()


# ----------------------------------------------------------------------------- extraccion para Roblox
def _fmt(x):
    s = ("%.2f" % x).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def recoger_partes(col):
    """Devuelve la lista de partes [{mat, material, color, alpha, v, f}] en studs y ejes Roblox.
    Debe llamarse con el asset en el origen (en_origen)."""
    partes = []
    objs = [o for o in col.all_objects if o.type == "MESH"]
    objs.sort(key=lambda o: ORDEN_MAT.index(o.data.materials[0].name))
    for ob in objs:
        matname = ob.data.materials[0].name
        rgb, rmat, _e, alpha = PALETA[matname]
        M = ob.matrix_world
        me = ob.data
        remap, V, F, vistos = {}, [], [], set()
        idx_local = []
        for v in me.vertices:
            w = M @ v.co
            p = (round(-w.x / S, 2) + 0.0, round(w.z / S, 2) + 0.0, round(w.y / S, 2) + 0.0)
            if p not in remap:
                remap[p] = len(V) + 1
                V.append(p)
            idx_local.append(remap[p])
        for poly in me.polygons:
            tri = tuple(idx_local[i] for i in poly.vertices)
            if len(set(tri)) < 3:
                continue
            key = tuple(sorted(tri))
            if key in vistos:
                continue
            vistos.add(key)
            F.append(tri)
        if F:
            partes.append({"mat": matname, "material": rmat, "color": rgb, "alpha": alpha, "v": V, "f": F})
    return partes


def escribir_luau(nombre, partes, ruta):
    tris = sum(len(p["f"]) for p in partes)
    L = ["-- Generado por tools/blender/export_assets.py. No editar a mano.",
         "return {", '\tname = "%s",' % nombre, "\ttris = %d," % tris, "\tparts = {"]
    for p in partes:
        v = ", ".join(_fmt(c) for vert in p["v"] for c in vert)
        f = ", ".join(str(i) for tri in p["f"] for i in tri)
        L.append("\t\t{ material = \"%s\", color = { %d, %d, %d }, alpha = %s, v = { %s }, f = { %s } },"
                 % (p["material"], p["color"][0], p["color"][1], p["color"][2], _fmt(p["alpha"]) if p["alpha"] else "0", v, f))
    L += ["\t},", "}", ""]
    texto = "\n".join(L)
    Path(ruta).parent.mkdir(parents=True, exist_ok=True)
    Path(ruta).write_text(texto, encoding="utf-8", newline="\n")
    return tris, len(texto)


def bbox_studs(partes):
    xs = [v[0] for p in partes for v in p["v"]]
    ys = [v[1] for p in partes for v in p["v"]]
    zs = [v[2] for p in partes for v in p["v"]]
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))
