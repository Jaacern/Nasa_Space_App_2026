# -*- coding: utf-8 -*-
"""Construye los 28 assets low-poly facetados de ARES FORGE en Blender.

Cada funcion build_<nombre>() devuelve una coleccion COL_<nombre> con las mallas
SM_<nombre>_<MAT_xxx>. Todas las medidas estan en STUDS (ares_lib.finish escala por 0,28).
Ejes en Blender: Z arriba, frente hacia -Y.
No usa rutas absolutas.
"""
import math
import random
import sys
from pathlib import Path

from mathutils import Vector

AQUI = Path(__file__).resolve().parent
if str(AQUI) not in sys.path:
    sys.path.insert(0, str(AQUI))

import ares_lib as L  # noqa: E402
from ares_lib import (  # noqa: E402
    Asset,
    CYA,
    GLD,
    GLS,
    GOLD,
    HD,
    HG,
    HW,
    ICE,
    MAG,
    MD,
    MR,
    MU,
    ORA,
    RED,
)


def _spikes(a: Asset, mat: str, dirs, base_r: float, tip_r: float, base_w: float, seg=4, center=(0, 0, 0)):
    cx, cy, cz = center
    for d in dirs:
        dv = Vector(d).normalized()
        p = (cx + dv.x * base_r, cy + dv.y * base_r, cz + dv.z * base_r)
        M = L.orient(p, dv)
        V, F = L.g_lathe([(0, 0), (base_w, 0), (0, tip_r - base_r)], seg=seg)
        a.put(mat, V, F, M=M)


# --------------------------------------------------------------------------- Enemigos comunes
def build_chaser():
    """Remolino de polvo: peonza de 4 anillos desalineados y ojo rojo al frente (-Y)."""
    a = Asset("chaser")
    rings = [
        (MD, 0.55, 0.72, 0.24, 0.28, (0.05, 0.0, 0.0), (4, -3, 0), 8),
        (MR, 1.40, 1.05, 0.30, 0.34, (-0.10, 0.08, 0.0), (-5, 4, 15), 9),
        (MD, 2.35, 1.38, 0.34, 0.36, (0.12, -0.06, 0.0), (4, 6, 30), 10),
        (MR, 3.35, 1.55, 0.32, 0.34, (-0.08, 0.10, 0.0), (-6, -4, 45), 10),
    ]
    for mat, z, R, w, hh, (ox, oy, oz), rot, seg in rings:
        a.ring(mat, R, w, hh, seg=seg, loc=(ox, oy, z + oz), rot=rot)
    # Nucleo interno oscuro y ojo rojo al frente (-Y)
    a.octa(MD, 0.65, 1.65, seg=6, loc=(0, 0, 2.0))
    a.ico(RED, 0.52, sub=1, loc=(0, -1.25, 2.35), scl=(1.0, 0.75, 1.0))
    a.cone(RED, 0.22, 0.6, seg=5, loc=(0, -1.4, 2.35), rot=(90, 0, 0))
    return a.finish(floor=True)


def build_tank():
    """Golem de regolito: cuerpo ancho encorvado, hombros, brazos, piernas, visor magenta y nucleo rojo."""
    a = Asset("tank")
    # Piernas cortas y gruesas
    for sx in (-1.15, 1.15):
        a.cyl(MR, 0.85, 1.8, seg=7, base=True, r2=0.72, loc=(sx, 0.1, 0.0))
        a.box(MR, (1.5, 1.9, 0.55), loc=(sx, -0.15, 0.28))
    # Torso ancho y joroba
    a.lathe(MR, [(0, 1.4), (1.9, 1.5), (2.45, 3.2), (2.2, 5.1), (1.3, 5.8), (0, 5.9)], seg=8)
    # Hombros rocosos grandes
    for sx in (-2.35, 2.35):
        a.ico(MR, 1.35, sub=1, jitter=0.14, seed=10 if sx < 0 else 20, loc=(sx, 0.0, 4.7), scl=(1.05, 1.0, 0.95))
        # Brazos gruesos + antebrazos
        a.cyl(MR, 0.78, 2.2, seg=6, r2=0.92, loc=(sx * 1.18, -0.25, 2.9), rot=(12, -8 * (1 if sx > 0 else -1), 0))
        a.box(MR, (1.45, 1.5, 1.3), loc=(sx * 1.22, -0.55, 1.45))
    # Cabeza hundida hacia delante (-Y)
    a.ico(MR, 1.15, sub=1, jitter=0.1, seed=7, loc=(0, -0.55, 5.85), scl=(1.1, 1.0, 0.85))
    # Visor magenta y placa roja en el pecho
    a.box(MAG, (1.55, 0.45, 0.42), loc=(0, -1.6, 5.75))
    a.box(RED, (1.9, 0.45, 1.7), loc=(0, -2.28, 3.45), rot=(6, 0, 0))
    return a.finish(floor=True)


def build_ranged():
    """Centinela ionico: cristal octaedrico magenta flotante (base a 1.5), anillo inclinado y canon rojo."""
    a = Asset("ranged")
    # Sombra/emisor inferior discreto a z=1.5 para anclar lectura flotante sin tocar suelo
    a.octa(MAG, 1.15, 2.25, seg=6, loc=(0, 0, 3.75))
    a.band(HD, 1.68, 0.24, 0.22, seg=12, loc=(0, 0, 3.75), rot=(24, 18, 0))
    # Aletas laterales del anillo
    for sx in (-1.7, 1.7):
        a.box(HD, (0.35, 0.7, 0.9), loc=(sx, 0, 3.75))
    # Canon-pua rojo apuntando al frente (-Y)
    a.cone(RED, 0.48, 1.65, seg=6, loc=(0, -0.75, 3.75), rot=(90, 0, 0))
    a.cyl(HD, 0.56, 0.65, seg=6, loc=(0, -0.75, 3.75), rot=(90, 0, 0))
    return a.finish(floor=True)


def build_kamikaze():
    """Meteoroide inestable: roca irregular con puas y nucleo naranja (centro a 2.0)."""
    a = Asset("kamikaze")
    c = (0.0, 0.0, 2.0)
    a.ico(MR, 1.25, sub=1, jitter=0.2, seed=42, loc=c)
    # Grietas / bandas emisivas naranjas
    a.ring(ORA, 1.22, 0.16, 0.16, seg=8, loc=c, rot=(25, 35, 0))
    a.ring(ORA, 1.18, 0.14, 0.14, seg=8, loc=c, rot=(-40, 20, 45))
    # Nucleo frontal naranja
    a.ico(ORA, 0.68, sub=1, loc=(0, -0.92, 2.0))
    # Puas rojas/naranjas alrededor
    dirs = [
        (0, -1, 0), (1, -0.6, 0.5), (-1, -0.6, 0.5),
        (0.7, 0.6, 0.8), (-0.7, 0.6, 0.8), (0, 0.8, -0.7), (0, -0.4, -0.9),
    ]
    _spikes(a, RED, dirs, 1.05, 1.95, 0.34, seg=4, center=c)
    return a.finish(floor=True)


# --------------------------------------------------------------------------- Elites
def build_elite1():
    """Tolvanera mayor: vortice de 5 niveles con anillo de escombros y corona magenta (alto 9, radio 3.5)."""
    a = Asset("elite1")
    levels = [
        (MD, 0.8, 1.1, 0.35, 0.42, (0.15, 0, 0), (5, -4, 0)),
        (MR, 2.2, 1.7, 0.42, 0.46, (-0.18, 0.15, 0), (-6, 5, 18)),
        (MD, 3.8, 2.35, 0.46, 0.48, (0.18, -0.14, 0), (4, 6, 36)),
        (MR, 5.5, 2.95, 0.48, 0.50, (-0.14, 0.16, 0), (-5, -4, 54)),
        (MD, 7.2, 3.35, 0.45, 0.48, (0.1, -0.08, 0), (3, 4, 72)),
    ]
    for mat, z, R, w, hh, off, rot in levels:
        a.ring(mat, R, w, hh, seg=10, loc=(off[0], off[1], z), rot=rot)
    # Nucleo central + ojo magenta
    a.octa(MD, 1.35, 3.8, seg=6, loc=(0, 0, 4.4))
    a.ico(MAG, 1.05, sub=1, loc=(0, -2.5, 5.2), scl=(1.1, 0.75, 1.0))
    # Corona superior magenta y escombros orbitando
    a.ring(MAG, 2.8, 0.26, 0.26, seg=12, loc=(0, 0, 8.65), rot=(6, 0, 0))
    for k in range(6):
        ang = math.radians(k * 60 + 15)
        r = 3.25
        a.ico(MR, 0.45, sub=0, jitter=0.18, seed=k + 3, loc=(math.cos(ang) * r, math.sin(ang) * r, 4.5 + (k % 2) * 1.4))
    return a.finish(floor=True)


def build_elite2():
    """Coloso de hielo: golem con placas de MAT_Ice y cuernos de cristal (alto 10, radio 4)."""
    a = Asset("elite2")
    for sx in (-1.55, 1.55):
        a.cyl(MR, 1.05, 2.5, seg=7, base=True, r2=0.9, loc=(sx, 0.15, 0.0))
        a.box(ICE, (1.85, 2.35, 0.75), loc=(sx, -0.2, 0.38))
    # Cuerpo masivo
    a.lathe(MR, [(0, 2.0), (2.5, 2.2), (3.2, 4.8), (2.9, 7.2), (1.7, 8.2), (0, 8.4)], seg=8)
    # Placas de hielo en pecho, hombros y espalda
    a.box(ICE, (2.8, 0.75, 2.6), loc=(0, -2.85, 5.2), rot=(8, 0, 0))
    for sx in (-3.2, 3.2):
        a.ico(ICE, 1.65, sub=1, jitter=0.12, seed=22 + int(sx), loc=(sx, 0, 6.8), scl=(1.1, 0.95, 1.15))
        a.cyl(MR, 0.98, 3.2, seg=6, r2=1.18, loc=(sx * 1.12, -0.35, 4.1), rot=(12, -10 * (1 if sx > 0 else -1), 0))
        a.box(ICE, (1.75, 1.85, 1.55), loc=(sx * 1.15, -0.7, 2.0))
    # Cabeza + cuernos de hielo + visor magenta
    a.ico(MR, 1.45, sub=1, jitter=0.08, seed=9, loc=(0, -0.7, 8.35), scl=(1.1, 1.0, 0.9))
    a.box(MAG, (2.0, 0.5, 0.52), loc=(0, -1.95, 8.2))
    for sx in (-1.0, 1.0):
        a.cone(ICE, 0.52, 2.2, seg=5, loc=(sx * 0.95, -0.5, 8.95), rot=(-18, sx * 22, 0))
    return a.finish(floor=True)


def build_elite3():
    """Heraldo solar: cristal grande con corona de puas naranja y doble anillo (alto 10, radio 3.5)."""
    a = Asset("elite3")
    a.octa(MAG, 2.05, 3.9, seg=6, loc=(0, 0, 5.7))
    a.band(HD, 3.05, 0.34, 0.30, seg=14, loc=(0, 0, 5.7), rot=(28, 22, 0))
    a.band(HD, 2.65, 0.28, 0.24, seg=14, loc=(0, 0, 5.7), rot=(-32, 18, 30))
    # Corona de puas naranjas alrededor del cristal y al frente
    dirs = [(math.cos(math.radians(k * 45)), math.sin(math.radians(k * 45)), 0.15) for k in range(8)]
    _spikes(a, ORA, dirs, 1.65, 3.45, 0.45, seg=4, center=(0, 0, 5.8))
    a.cone(ORA, 0.68, 2.4, seg=6, loc=(0, -1.2, 5.7), rot=(90, 0, 0))
    a.cone(ORA, 0.75, 2.1, seg=6, loc=(0, 0, 7.9))
    return a.finish(floor=True)


# --------------------------------------------------------------------------- Jefes
def build_boss1():
    """Tormenta de polvo global: vortice colosal, rocas orbitando y ojo rojo (alto 13, radio 5)."""
    a = Asset("boss1")
    lvls = [
        (MD, 1.0, 1.6, 0.5, 0.55, (0.2, 0), (5, -4, 0)),
        (MR, 3.0, 2.5, 0.55, 0.62, (-0.22, 0.15), (-5, 6, 15)),
        (MD, 5.2, 3.4, 0.6, 0.65, (0.22, -0.18), (4, 5, 30)),
        (MR, 7.6, 4.2, 0.62, 0.65, (-0.18, 0.2), (-6, -4, 45)),
        (MD, 10.0, 4.7, 0.58, 0.62, (0.14, -0.12), (4, 4, 60)),
    ]
    for mat, z, R, w, hh, off, rot in lvls:
        a.ring(mat, R, w, hh, seg=12, loc=(off[0], off[1], z), rot=rot)
    a.octa(MD, 1.9, 5.5, seg=8, loc=(0, 0, 6.6))
    # Ojo rojo colosal y corona magenta
    a.ico(RED, 1.55, sub=1, loc=(0, -3.55, 7.8), scl=(1.1, 0.7, 1.0))
    a.ring(MAG, 4.2, 0.35, 0.35, seg=14, loc=(0, 0, 12.45), rot=(8, 0, 0))
    # Rocas orbitando
    for k in range(8):
        ang = math.radians(k * 45)
        r = 4.65
        z = 4.2 + (k % 3) * 2.5
        a.ico(MR, 0.65, sub=1, jitter=0.22, seed=k + 50, loc=(math.cos(ang) * r, math.sin(ang) * r, z))
    return a.finish(floor=True)


def build_boss2():
    """Coloso de la lluvia de rocas: golem enorme con hombros-crater y punos (alto 14, radio 6)."""
    a = Asset("boss2")
    for sx in (-2.2, 2.2):
        a.cyl(MD, 1.45, 3.4, seg=8, base=True, r2=1.2, loc=(sx, 0.2, 0.0))
        a.box(MR, (2.6, 3.2, 1.0), loc=(sx, -0.35, 0.5))
    a.lathe(MR, [(0, 2.8), (3.6, 3.0), (4.6, 6.8), (4.1, 10.2), (2.4, 11.4), (0, 11.6)], seg=9)
    # Placas oxidadas + nucleo rojo
    a.box(MU, (4.2, 1.0, 3.4), loc=(0, -4.1, 7.3), rot=(8, 0, 0))
    a.ico(RED, 1.25, sub=1, loc=(0, -4.65, 7.3), scl=(1.2, 0.6, 1.1))
    # Hombros-crater
    for sx in (-4.4, 4.4):
        a.band(MU, 1.7, 0.65, 0.85, seg=8, loc=(sx, 0, 10.2), rot=(0, -18 * (1 if sx > 0 else -1), 0))
        a.ico(RED, 0.85, sub=1, loc=(sx, 0, 10.35))
        # Brazos + punos enormes
        a.cyl(MD, 1.35, 4.5, seg=7, r2=1.6, loc=(sx * 1.12, -0.45, 6.2), rot=(12, -12 * (1 if sx > 0 else -1), 0))
        a.ico(MR, 1.85, sub=1, jitter=0.16, seed=70 + int(sx), loc=(sx * 1.18, -1.0, 2.9))
    # Cabeza acorazada + visor rojo
    a.ico(MD, 1.95, sub=1, jitter=0.1, seed=13, loc=(0, -1.0, 12.1), scl=(1.15, 1.0, 0.9))
    a.box(RED, (2.8, 0.6, 0.7), loc=(0, -2.75, 12.0))
    return a.finish(floor=True)


def build_boss3():
    """Heraldo de la erupcion: cristal monumental con llamaradas y anillos (alto 14, radio 5.5)."""
    a = Asset("boss3")
    a.octa(MAG, 2.8, 5.4, seg=8, loc=(0, 0, 7.9))
    a.band(HD, 4.4, 0.45, 0.42, seg=16, loc=(0, 0, 7.9), rot=(26, 20, 0))
    a.band(HD, 3.85, 0.38, 0.34, seg=16, loc=(0, 0, 7.9), rot=(-30, -24, 25))
    a.ring(ORA, 5.1, 0.3, 0.3, seg=14, loc=(0, 0, 7.9), rot=(8, -14, 0))
    # Protuberancias de llamarada naranja y roja
    dirs = [(math.cos(math.radians(k * 36)), math.sin(math.radians(k * 36)), (k % 3 - 1) * 0.35) for k in range(10)]
    _spikes(a, ORA, dirs, 2.1, 4.9, 0.62, seg=5, center=(0, 0, 8.0))
    a.cone(RED, 1.05, 3.3, seg=6, loc=(0, -1.65, 7.9), rot=(90, 0, 0))
    a.cone(RED, 1.1, 3.0, seg=6, loc=(0, 0, 11.1))
    return a.finish(floor=True)


def build_final():
    """Coloso de la tormenta solar: titan humanoide de placas oscuras, sol naranja en el pecho y halo dorado (alto 20, radio 7)."""
    a = Asset("final")
    # Piernas blindadas
    for sx in (-2.3, 2.3):
        a.cyl(MD, 1.45, 5.2, seg=8, base=True, r2=1.25, loc=(sx, 0, 0.0))
        a.box(HD, (2.8, 3.6, 1.1), loc=(sx, -0.45, 0.55))
        a.cyl(HD, 1.65, 4.2, seg=8, base=True, r2=1.45, loc=(sx, 0, 4.8))
    # Pelvis y torso titanico
    a.box(MD, (6.2, 4.2, 2.4), loc=(0, 0, 9.4))
    a.lathe(HD, [(0, 9.8), (3.4, 10.2), (4.8, 13.8), (4.4, 16.4), (2.4, 17.2), (0, 17.3)], seg=8)
    # Nucleo-sol naranja en el pecho
    a.ico(ORA, 2.05, sub=1, loc=(0, -3.55, 13.6), scl=(1.0, 0.72, 1.0))
    a.ring(GLD, 2.45, 0.25, 0.25, seg=12, loc=(0, -3.75, 13.6), rot=(90, 0, 0))
    # Hombreras angulares
    for sx in (-5.2, 5.2):
        a.box(HD, (3.6, 4.2, 2.6), loc=(sx, 0, 15.6), rot=(0, -18 * (1 if sx > 0 else -1), 0))
        a.box(ORA, (1.6, 3.6, 0.6), loc=(sx, 0, 17.0), rot=(0, -18 * (1 if sx > 0 else -1), 0))
        # Brazos + antebrazos
        a.cyl(MD, 1.35, 5.0, seg=7, r2=1.15, loc=(sx * 1.08, -0.3, 12.2), rot=(8, -6 * (1 if sx > 0 else -1), 0))
        a.cyl(HD, 1.55, 4.6, seg=7, r2=1.4, loc=(sx * 1.14, -1.1, 7.6), rot=(22, 0, 0))
    # Cabeza con visera y halo dorado detras
    a.ico(HD, 1.75, sub=1, loc=(0, -0.5, 18.4), scl=(1.0, 1.0, 1.1))
    a.box(ORA, (2.2, 0.55, 0.65), loc=(0, -1.95, 18.4))
    a.ring(GLD, 3.8, 0.35, 0.35, seg=14, loc=(0, 1.35, 18.5), rot=(90, 0, 0))
    _spikes(a, GLD, [(math.cos(math.radians(a_deg)), 0, math.sin(math.radians(a_deg))) for a_deg in range(0, 181, 30)],
            3.8, 5.4, 0.42, seg=4, center=(0, 1.35, 18.5))
    return a.finish(floor=True)


# --------------------------------------------------------------------------- Recompensas y jugador
def build_gem():
    """Muestra dorada: octaedro facetado flotando (alto 1.2, centro a 1.2)."""
    a = Asset("gem")
    a.octa(GLD, 0.55, 0.62, seg=6, loc=(0, 0, 1.2))
    a.ring(GOLD, 0.72, 0.12, 0.10, seg=6, loc=(0, 0, 1.2), rot=(18, 0, 0))
    return a.finish(floor=True)


def build_chest():
    """Contenedor de carga: caja metalica oscura con tapa, refuerzos y cierres dorados (3.4 x 2.4 x 2.4)."""
    a = Asset("chest")
    a.box(HD, (3.4, 2.4, 1.75), loc=(0, 0, 0.875))
    a.box(HG, (3.6, 2.6, 0.58), loc=(0, 0, 2.02))
    # Esquinas / patas y cerradura frontal (-Y)
    for sx in (-1.55, 1.55):
        a.box(GLD, (0.28, 2.68, 2.36), loc=(sx, 0, 1.2))
    a.box(GLD, (0.75, 0.35, 0.85), loc=(0, -1.25, 1.5))
    return a.finish(floor=True)


def build_drone():
    """Dron helicoptero: cuerpo blanco, rotores coaxiales cian translucidos y patas (ancho 3, centro a 3.2)."""
    a = Asset("drone")
    a.ico(HW, 0.72, sub=1, loc=(0, 0, 3.2), scl=(1.1, 1.25, 0.65))
    a.box(HD, (0.5, 0.75, 0.35), loc=(0, -0.45, 3.0))
    # Mastil y rotores coaxiales
    a.cyl(HD, 0.12, 0.85, seg=6, loc=(0, 0, 3.68))
    a.cyl(GLS, 1.48, 0.10, seg=12, loc=(0, 0, 3.88))
    a.cyl(GLS, 1.15, 0.08, seg=12, loc=(0, 0, 4.08))
    # Patas
    for sx in (-0.65, 0.65):
        a.strut(HD, (sx * 0.6, 0, 2.95), (sx, 0, 2.45), 0.08, seg=4)
        a.box(HD, (0.14, 1.35, 0.12), loc=(sx, 0, 2.42))
    return a.finish(floor=True)


def build_shot():
    """Rayo cian alargado facetado de 3.2 de largo a lo largo de Y, centro a 2.6."""
    a = Asset("shot")
    a.lathe(CYA, [(0, -1.6), (0.30, -0.9), (0.34, 0.6), (0, 1.6)], seg=6, loc=(0, 0, 2.6), rot=(90, 0, 0))
    a.lathe(HW, [(0, -0.85), (0.18, 0.0), (0, 0.95)], seg=6, loc=(0, 0, 2.6), rot=(90, 0, 0))
    return a.finish(floor=True)


def build_eshot():
    """Esfera facetada magenta de 2.4 de diametro con anillo rojo, centro a 2.6."""
    a = Asset("eshot")
    a.ico(MAG, 1.15, sub=1, loc=(0, 0, 2.6))
    a.ring(RED, 1.22, 0.18, 0.16, seg=8, loc=(0, 0, 2.6), rot=(30, 20, 0))
    return a.finish(floor=True)


def build_Helmet():
    """Casco de astronauta: esfera blanca de 2.3 con visor MAT_Glass al frente (-Y) y aro de cuello. Centrado."""
    a = Asset("Helmet")
    a.ico(HW, 1.15, sub=1, loc=(0, 0, 0.05), scl=(1.0, 1.05, 1.0))
    # Visor frontal (-Y) sobresaliendo claramente delante de la calota blanca
    a.ico(GLS, 0.90, sub=1, loc=(0, -0.50, 0.08), scl=(1.06, 0.92, 0.76))
    # Aro de cuello y detalles laterales
    a.band(HD, 0.92, 0.22, 0.18, seg=12, loc=(0, 0, -0.95))
    for sx in (-1.08, 1.08):
        a.cyl(HD, 0.28, 0.25, seg=6, loc=(sx, 0.1, 0.0), rot=(0, 90, 0))
    return a.finish(center=True)


def build_Backpack():
    """Mochila de soporte vital blanca 1.7 x 0.9 x 2.0 con luz cian (+Y atras) y antena. Centrada."""
    a = Asset("Backpack")
    a.box(HW, (1.7, 0.88, 2.0), loc=(0, 0, 0))
    a.box(HD, (1.35, 0.25, 1.5), loc=(0, 0.40, -0.1))
    # Luz cian de telemetria en la cara trasera (+Y en Blender = +Z Roblox)
    a.box(CYA, (1.15, 0.16, 0.28), loc=(0, 0.50, 0.55))
    # Tanques inferiores y antena corta
    for sx in (-0.45, 0.45):
        a.cyl(HD, 0.28, 1.1, seg=8, loc=(sx, 0.15, -0.35))
    a.cyl(HD, 0.07, 0.85, seg=6, loc=(0.62, 0.2, 1.35))
    a.ico(CYA, 0.12, sub=0, loc=(0.62, 0.2, 1.80))
    return a.finish(center=True)


# --------------------------------------------------------------------------- Piezas de la nave (centradas)
def build_Piece1():
    """MMRTG: cilindro oscuro con 8 aletas radiales blancas y tapa caliente naranja. Largo 4.5 en X, diam 3.6."""
    a = Asset("Piece1")
    a.cyl(HD, 1.0, 4.2, seg=10, loc=(0, 0, 0), rot=(0, 90, 0))
    # 8 aletas radiales alrededor del eje X
    for k in range(8):
        ang = math.radians(k * 45)
        cy = math.cos(ang) * 1.35
        cz = math.sin(ang) * 1.35
        a.box(HW, (3.6, 0.9, 0.16), loc=(0, cy, cz), rot=(k * 45 + 90, 0, 0))
    # Tapa caliente naranja y brida trasera
    a.cyl(ORA, 0.72, 0.42, seg=10, loc=(2.18, 0, 0), rot=(0, 90, 0))
    a.cyl(HD, 1.12, 0.35, seg=10, loc=(-2.05, 0, 0), rot=(0, 90, 0))
    return a.finish(center=True)


def build_Piece2():
    """Antena de alta ganancia: plato parabolico blanco de 5 de diametro mirando a +Z, tripode y bocina cian."""
    a = Asset("Piece2")
    # Perfil parabolico de plato mirando hacia +Z (concavo arriba)
    prof = [
        (0.0, 0.0), (0.5, 0.05), (1.3, 0.24), (2.1, 0.62), (2.5, 1.0),
        (2.42, 1.06), (2.0, 0.70), (1.2, 0.34), (0.45, 0.16), (0.0, 0.14),
    ]
    a.lathe(HW, prof, seg=14, loc=(0, 0, -0.7))
    # Base inferior oscura
    a.cyl(HD, 0.85, 0.55, seg=8, loc=(0, 0, -0.95))
    # Tripode hasta subreflector en z=1.65
    for k in range(3):
        ang = math.radians(k * 120)
        a.strut(HD, (math.cos(ang) * 1.75, math.sin(ang) * 1.75, -0.15), (0, 0, 1.65), 0.10, seg=4)
    a.cyl(HD, 0.42, 0.35, seg=8, loc=(0, 0, 1.72))
    a.cone(CYA, 0.38, 0.65, seg=8, loc=(0, 0, 1.55), rot=(180, 0, 0))
    a.ico(CYA, 0.25, sub=1, loc=(0, 0, 2.02))
    return a.finish(center=True)


def build_Piece3():
    """Generador de oxigeno: caja dorada 3x3x3 con tuberias, rejilla superior y panel cian."""
    a = Asset("Piece3")
    a.box(GOLD, (2.8, 2.8, 2.7), loc=(0, 0, 0))
    # Tapa superior oscura con valvulas
    a.cyl(HD, 0.85, 0.55, seg=8, loc=(0, 0, 1.58))
    # Tuberias laterales
    for sy in (-0.85, 0.85):
        a.cyl(HD, 0.28, 3.1, seg=6, loc=(0, sy, 0.45), rot=(0, 90, 0))
    # Rejilla frontal (-Y) y lateral (-X / +X) + panel cian
    a.box(HD, (2.1, 0.25, 1.35), loc=(0, -1.42, 0.3))
    a.box(CYA, (2.2, 0.22, 0.48), loc=(0, -1.45, -0.78))
    a.box(CYA, (0.22, 2.0, 0.48), loc=(-1.45, 0, -0.78))
    return a.finish(center=True)


def build_Piece4():
    """Propulsor: campana de motor cohete con camara, tuberias y anillo naranja en la boca (alto 5, boca 4.4)."""
    a = Asset("Piece4")
    # Camara superior (z=0.5..2.5) y campana abriendose hacia abajo (z=-2.5..0.5)
    a.lathe(HD, [(0, 2.4), (1.3, 2.4), (1.4, 1.2), (0.85, 0.5), (1.75, -0.9), (2.2, -2.4), (1.95, -2.4), (1.55, -0.95), (0.65, 0.4), (0, 0.4)], seg=12)
    # Anillos de refuerzo grises y tuberias externas
    a.band(HG, 1.68, 0.16, 0.16, seg=12, loc=(0, 0, -0.8))
    a.band(HG, 2.05, 0.16, 0.16, seg=12, loc=(0, 0, -1.8))
    for k in range(4):
        ang = math.radians(k * 90 + 45)
        a.strut(HG, (math.cos(ang) * 1.15, math.sin(ang) * 1.15, 2.1), (math.cos(ang) * 1.45, math.sin(ang) * 1.45, 0.3), 0.14, seg=5)
    # Anillo naranja emisivo en la boca inferior
    a.ring(ORA, 1.85, 0.24, 0.18, seg=12, loc=(0, 0, -2.35))
    return a.finish(center=True)


# --------------------------------------------------------------------------- Nave
def build_Ship():
    """Modulo de aterrizaje: capsula blanca/gris ~22 de alto, 10 de diam, 3 patas, escotilla, dano, franja cian.
    Deja hueco en los puntos de montaje SHIP_MOUNTS para Piece1..4.
    """
    a = Asset("Ship")
    # Fuselaje principal: cono truncado elevado sobre z=5.2 para que Piece4 encaje en z=3.0
    prof_hull = [
        (0.0, 5.2),
        (3.8, 5.2),
        (5.2, 6.8),
        (5.2, 13.5),
        (4.1, 18.8),
        (2.4, 21.8),
        (0.0, 21.8),
    ]
    a.lathe(HW, prof_hull, seg=12)
    # Anillo inferior oscuro y faldon del motor
    a.band(HD, 4.2, 0.65, 0.75, seg=12, loc=(0, 0, 5.4))
    # Anillo estructural gris medio + franja cian de identificacion
    a.band(HG, 5.28, 0.22, 0.8, seg=12, loc=(0, 0, 9.5))
    a.ring(CYA, 5.36, 0.22, 0.32, seg=12, loc=(0, 0, 12.6))
    # Anillo superior de acoplamiento en z=21.8 para recibir Piece2 (antena en z=23.6)
    a.cyl(HD, 2.1, 1.4, seg=10, loc=(0, 0, 22.0))
    # Anclaje trasero (+Y Blender = +Z Roblox) en z=8.5 para Piece1 (y=6.6)
    a.box(HD, (2.2, 1.6, 1.8), loc=(0, 5.1, 8.5))
    # Anclaje costado (+X Blender = -X Roblox) en z=12.0 para Piece3 (x=6.3)
    a.box(HD, (1.4, 2.2, 2.2), loc=(4.8, 0, 12.0))

    # Escotilla de tripulacion al frente (-Y) + visor cian
    a.box(HG, (2.8, 0.85, 4.2), loc=(0, -5.0, 10.2), rot=(-4, 0, 0))
    a.box(HD, (2.1, 0.35, 3.4), loc=(0, -5.35, 10.2), rot=(-4, 0, 0))
    a.box(CYA, (1.3, 0.25, 0.55), loc=(0, -5.42, 11.1), rot=(-4, 0, 0))

    # Placas abolladas / dano de aterrizaje en un costado
    a.box(HG, (2.4, 0.45, 2.2), loc=(-4.8, -1.6, 14.5), rot=(8, -14, -22))
    a.box(HD, (1.8, 0.35, 1.6), loc=(-4.3, 2.4, 8.4), rot=(-12, 10, 32))

    # 3 patas de aterrizaje (120 grados, desplazadas 60 deg para no tapar el frente ni el anclaje trasero)
    for k in range(3):
        ang = math.radians(k * 120 + 60)
        ca, sa = math.cos(ang), math.sin(ang)
        p_hip = (ca * 4.9, sa * 4.9, 7.6)
        p_low = (ca * 4.2, sa * 4.2, 5.5)
        p_foot = (ca * 8.2, sa * 8.2, 0.55)
        a.strut(HD, p_hip, p_foot, 0.42, seg=6)
        a.strut(HG, p_low, (ca * 6.8, sa * 6.8, 2.4), 0.28, seg=5)
        a.cyl(HD, 1.45, 0.65, seg=8, base=True, r2=1.15, loc=(p_foot[0], p_foot[1], 0.0))
    return a.finish(floor=True)


# --------------------------------------------------------------------------- Entorno
def _rock(name: str, rx: float, ry: float, rz: float, seed: int):
    a = Asset(name)
    a.ico(MU, 1.0, sub=1, jitter=0.26, seed=seed, loc=(0, 0, rz * 0.42), scl=(rx * 0.5, ry * 0.5, rz * 0.52))
    a.ico(MR, 0.72, sub=1, jitter=0.22, seed=seed + 100, loc=(rx * 0.18, -ry * 0.1, rz * 0.30), scl=(rx * 0.42, ry * 0.42, rz * 0.42))
    return a.finish(floor=True)


def build_RockA():
    return _rock("RockA", 3.0, 2.6, 2.1, 101)


def build_RockB():
    return _rock("RockB", 5.0, 4.2, 3.2, 202)


def build_RockC():
    return _rock("RockC", 8.0, 6.5, 4.6, 303)


def _ridge(name: str, sx: float, sy: float, sz: float, seed: int):
    a = Asset(name)
    rnd = random.Random(seed)
    pts = []
    # Base amplia y cima irregular en meseta
    for ang_deg in range(0, 360, 45):
        ang = math.radians(ang_deg)
        r_var = rnd.uniform(0.85, 1.08)
        pts.append((math.cos(ang) * sx * 0.5 * r_var, math.sin(ang) * sy * 0.5 * r_var, 0.0))
        pts.append((math.cos(ang) * sx * 0.30 * r_var, math.sin(ang) * sy * 0.30 * r_var, sz * rnd.uniform(0.72, 1.0)))
    a.hull(MR, pts)
    # Segundo pico lateral para silueta de sierra
    pts2 = []
    ox = sx * 0.18
    for ang_deg in range(0, 360, 60):
        ang = math.radians(ang_deg)
        r_var = rnd.uniform(0.8, 1.05)
        pts2.append((ox + math.cos(ang) * sx * 0.32 * r_var, math.sin(ang) * sy * 0.36 * r_var, 0.0))
        pts2.append((ox + math.cos(ang) * sx * 0.16 * r_var, math.sin(ang) * sy * 0.18 * r_var, sz * rnd.uniform(0.82, 1.08)))
    a.hull(MU, pts2)
    return a.finish(floor=True)


def build_RidgeA():
    return _ridge("RidgeA", 70.0, 40.0, 45.0, 404)


def build_RidgeB():
    return _ridge("RidgeB", 50.0, 60.0, 30.0, 505)


BUILDERS = {
    "chaser": build_chaser,
    "tank": build_tank,
    "ranged": build_ranged,
    "kamikaze": build_kamikaze,
    "elite1": build_elite1,
    "elite2": build_elite2,
    "elite3": build_elite3,
    "boss1": build_boss1,
    "boss2": build_boss2,
    "boss3": build_boss3,
    "final": build_final,
    "gem": build_gem,
    "chest": build_chest,
    "drone": build_drone,
    "shot": build_shot,
    "eshot": build_eshot,
    "Helmet": build_Helmet,
    "Backpack": build_Backpack,
    "Piece1": build_Piece1,
    "Piece2": build_Piece2,
    "Piece3": build_Piece3,
    "Piece4": build_Piece4,
    "Ship": build_Ship,
    "RockA": build_RockA,
    "RockB": build_RockB,
    "RockC": build_RockC,
    "RidgeA": build_RidgeA,
    "RidgeB": build_RidgeB,
}


def build_all():
    """Construye todos los assets en la escena actual (idempotente) y los ordena en rejilla."""
    cols = {}
    for name, *_rest in L.ASSETS:
        cols[name] = BUILDERS[name]()
    L.colocar_en_rejilla()
    return cols


if __name__ == "__main__":
    cols = build_all()
    print(f"Construidos {len(cols)} assets.")
