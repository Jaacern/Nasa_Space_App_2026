# Catálogo de assets 3D de ARES FORGE

Fecha: 14-11-2026. Generado automáticamente por `tools/blender/export_assets.py`.
Convención: 1 stud = 0,28 m. Ejes en Blender: +Z arriba, frente -Y. Ejes en Roblox: +Y arriba, frente -Z.
Materiales: sombreado plano facetado sin texturas; un objeto `SM_<nombre>_<MAT_xxx>` por material.

## 1. Inventario de los 28 assets

| Asset | Familia | Descripción | Tris | Presupuesto | Mats | Tamaño en studs (X×Y×Z) | Pivote | Estado |
|---|---|---|---|---|---|---|---|---|
| `chaser` | Enemigo | Remolino de polvo | 398 | ≤ 900 | 3/3 | 3.7×3.7×4.0 | suelo | PASS |
| `tank` | Enemigo | Golem de regolito | 480 | ≤ 900 | 3/3 | 7.5×6.8×5.0 | suelo | PASS |
| `ranged` | Enemigo | Centinela ionico | 168 | ≤ 900 | 3/3 | 3.7×4.5×4.2 | suelo (flota, base a 1,5) | PASS |
| `kamikaze` | Enemigo | Meteoroide inestable | 344 | ≤ 900 | 3/3 | 3.1×3.1×3.4 | suelo (flota, centro a 2) | PASS |
| `elite1` | Elite | Tolvanera mayor | 708 | ≤ 2500 | 3/3 | 7.6×8.9×7.3 | suelo | PASS |
| `elite2` | Elite | Coloso de hielo | 500 | ≤ 2500 | 3/3 | 10.2×10.9×6.6 | suelo | PASS |
| `elite3` | Elite | Heraldo solar | 324 | ≤ 2500 | 3/3 | 6.8×8.2×7.0 | suelo | PASS |
| `boss1` | Jefe | Tormenta de polvo global | 1328 | ≤ 4000 | 4/4 | 10.8×13.1×10.7 | suelo | PASS |
| `boss2` | Jefe | Coloso de la lluvia de rocas | 848 | ≤ 4000 | 4/4 | 14.5×14.0×9.9 | suelo | PASS |
| `boss3` | Jefe | Heraldo de la erupcion | 508 | ≤ 4000 | 4/4 | 10.5×11.6×10.4 | suelo | PASS |
| `final` | Jefe | Coloso de la tormenta solar | 824 | ≤ 4000 | 4/4 | 14.8×23.9×9.8 | suelo | PASS |
| `gem` | Recompensa | Muestra dorada | 60 | ≤ 500 | 2/3 | 1.7×1.2×1.4 | suelo (flota, centro a 1,2) | PASS |
| `chest` | Recompensa | Contenedor de carga | 60 | ≤ 500 | 3/3 | 3.6×2.4×2.8 | suelo | PASS |
| `drone` | Jugador | Dron helicoptero | 268 | ≤ 500 | 3/3 | 3.0×1.8×3.0 | suelo (flota, centro a 3,2) | PASS |
| `shot` | Jugador | Rayo cian | 36 | ≤ 500 | 2/3 | 0.7×0.6×3.2 | suelo (centro a 2,6) | PASS |
| `eshot` | Enemigo | Esfera de plasma enemiga | 144 | ≤ 500 | 2/3 | 2.6×2.3×2.4 | suelo (centro a 2,6) | PASS |
| `Helmet` | Jugador | Casco de astronauta | 304 | ≤ 500 | 3/3 | 2.4×2.3×2.5 | centro del casco | PASS |
| `Backpack` | Jugador | Mochila de soporte vital | 144 | ≤ 500 | 3/3 | 1.7×2.9×1.0 | centro de la mochila | PASS |
| `Piece1` | Pieza | MMRTG | 216 | ≤ 1200 | 3/3 | 4.6×2.9×2.9 | centro de la pieza | PASS |
| `Piece2` | Pieza | Antena de alta ganancia | 432 | ≤ 1200 | 3/3 | 5.0×3.5×4.9 | centro de la pieza | PASS |
| `Piece3` | Pieza | Generador de oxigeno | 128 | ≤ 1200 | 3/3 | 3.1×3.2×3.0 | centro de la pieza | PASS |
| `Piece4` | Pieza | Propulsor | 560 | ≤ 1200 | 3/3 | 4.4×4.9×4.4 | centro de la pieza | PASS |
| `Ship` | Nave | Modulo de aterrizaje | 760 | ≤ 5000 | 4/4 | 15.2×22.7×17.1 | suelo | PASS |
| `RockA` | Entorno | Roca marciana 3 | 160 | ≤ 300 | 2/3 | 3.1×2.2×2.6 | suelo | PASS |
| `RockB` | Entorno | Roca marciana 5 | 160 | ≤ 300 | 2/3 | 4.8×3.3×4.1 | suelo | PASS |
| `RockC` | Entorno | Roca marciana 8 | 160 | ≤ 300 | 2/3 | 8.4×4.4×7.5 | suelo | PASS |
| `RidgeA` | Entorno | Cresta/meseta del horizonte A | 48 | ≤ 400 | 2/3 | 68.2×46.5×37.6 | suelo | PASS |
| `RidgeB` | Entorno | Cresta/meseta del horizonte B | 48 | ≤ 400 | 2/3 | 52.3×32.2×58.0 | suelo | PASS |

## 2. Posiciones de montaje en la nave (`SHIP_MOUNTS`)

Coordenadas en studs, ejes de Roblox (`+Y` arriba, `-Z` frente), relativas al origen de `Ship` (`0, 0, 0` en el suelo).

| Pieza | Nombre | Posición Roblox (X, Y, Z) | Orientación / nota |
|---|---|---|---|
| `Piece1` | MMRTG | `(0.0, 8.5, 6.6)` | Trasera (`+Z`), eje largo a lo largo de X |
| `Piece2` | Antena de alta ganancia | `(0.0, 23.6, 0.0)` | Sobre la punta superior, plato mirando a `+Y` |
| `Piece3` | Generador de oxígeno | `(-6.3, 12.0, 0.0)` | Costado `-X` del fuselaje |
| `Piece4` | Propulsor de retorno | `(0.0, 3.0, 0.0)` | Bajo el fuselaje, boca hacia abajo (`-Y`) |

## 3. Archivos generados

- Módulos Luau (`EditableMesh`): `game/src/shared/Meshes/<nombre>.luau`
- FBX (flujo clásico): `assets/export/<nombre>.fbx`
- Vistas previas PNG (512×512): `docs/assets/previews/<nombre>.png`
- Archivo fuente Blender: `assets/blend/ares_assets.blend`

## 4. Cómo regenerar todo

Con Blender abierto y el puente activo, ejecuta el script `tools/blender/export_assets.py` (por ejemplo mediante `blender_run_script`), o en línea de comandos:

```bash
"<ruta-a-blender.exe>" -b --factory-startup -noaudio --python tools/blender/export_assets.py
```
