---
name: roblox-export
description: Contract for exporting Blender 4.5 assets into Roblox Studio (scale in studs, FBX settings, SM_/COL_/MAT_ naming, per-tier triangle budgets, collision fidelity, SurfaceAppearance maps, in-Studio validation). Use before exporting any asset that goes into the Roblox game. Extends export-pipeline and asset-optimization.
license: MIT
metadata:
  domain: blender
  role: specialist
  project: juego-roblox-survivor
  version: "1.0.0"
  triggers: roblox, roblox studio, export roblox, MeshPart, SurfaceAppearance, studs, collision fidelity
  related-skills: export-pipeline, asset-optimization, lod-pipeline, collision-proxy, texture-workflow, qa-review
---

# Roblox Export

Contrato de exportación entre Blender 4.5 y Roblox Studio. Todo lo que no esté confirmado en Studio lleva la marca `VERIFICAR EN STUDIO`. No lo des por válido hasta probarlo.

## 1. Escala y orientación
- Trabaja en Blender en metros (1 unidad = 1 m) y aplica la escala (`Ctrl+A` → Scale) antes de exportar.
- Roblox mide en studs. Referencia orientativa: 1 stud ≈ 0.28 m. `VERIFICAR EN STUDIO`: importa un cubo de referencia y comprueba su tamaño antes de producir en serie.
- Pivote: en la base (contacto con el suelo) para personajes, enemigos y props. En el centro para pickups y proyectiles.
- Ejes según `export-pipeline`: forward `-Z`, up `Y`.

## 2. Formato
- Formato por defecto: **FBX**, con los ajustes de `export-pipeline` (Apply Scalings = FBX All, Apply Unit ON, Path Mode = Copy).
- GLB/glTF: `VERIFICAR EN STUDIO` si el importador de tu versión lo acepta. Si no, FBX.
- Un asset, un archivo. Fuente `.blend` en `assets/src/`; exportaciones en `assets/export/`.

## 3. Nombres (obligatorio)
| Elemento | Patrón | Ejemplo |
|---|---|---|
| Colección de exportación | `COL_Export` | `COL_Export` |
| Malla visible | `SM_<Nombre>_LOD0` | `SM_Enemigo_Perseguidor_LOD0` |
| Malla reducida | `SM_<Nombre>_LOD1` | `SM_Enemigo_Perseguidor_LOD1` |
| Colisión | `COL_<Nombre>` | `COL_Enemigo_Perseguidor` |
| Material | `MAT_<Nombre>` | `MAT_Enemigo_Rojo` |
| Textura | `T_<Nombre>_BC` / `_N` / `_MR` | `T_Heroe_BC` |

## 4. Presupuestos (orientativos; `VERIFICAR EN STUDIO` contra límites y rendimiento reales)
| Tier | Uso típico | Triángulos LOD0 | Triángulos LOD1 | Textura |
|---|---|---|---|---|
| Héroe jugador | 1 por personaje | ≤ 5 000 | ≤ 2 500 | 1024 |
| Enemigo común | Decenas en pantalla | ≤ 1 200 | ≤ 400 | Atlas 512 o 1024 |
| Élite / jefe | 1 a 3 | ≤ 8 000 | ≤ 3 000 | 1024 |
| Prop de escenario | Muchas copias | ≤ 500 | — | Atlas 1024 |
| Pieza de nave | 4 piezas del dossier | < 5 000 | ≤ 2 000 | 1024 |

Reglas: máximo 3 materiales por modelo. Un atlas por tier cuando sea posible, para reducir draw calls.

## 5. Colisión
- Malla `COL_<Nombre>` separada: caja o convexa, sin materiales, con transformaciones aplicadas y oculta en el render.
- En Studio, usa `CollisionFidelity` `Box` o `Hull` para enemigos, proyectiles y props dinámicos. Evita mallas de colisión precisas en objetos que se mueven. `VERIFICAR EN STUDIO` (nombres exactos de la propiedad en tu versión).

## 6. Materiales y texturas
- Un `SurfaceAppearance` por material, con `ColorMap` (BC), `NormalMap` (N), `MetalnessMap` y `RoughnessMap` (MR, empaquetado o por separado). `VERIFICAR EN STUDIO` cómo se asigna el canal empaquetado.
- Emisivos (luces de enemigos, ojos, núcleos): no van en `SurfaceAppearance`. Usa color en el modelo más efectos de Studio (`PointLight`, `ParticleEmitter`, material `Neon`). `VERIFICAR EN STUDIO`.
- Texturas de potencia de 2 y 1024 px como máximo, salvo jefes o pieza de nave hero.

## 7. LOD y rendimiento en Roblox
- En este flujo, Roblox no genera LOD automático: crea `LOD0` y `LOD1` como mallas separadas y cambia entre ellas por distancia en Luau.
- `VERIFICAR EN STUDIO`: la propiedad `RenderFidelity` de `MeshPart` y su efecto sobre el nivel de detalle.
- Para hordas usa modelos de bajo coste y pooling. Nunca clones un modelo pesado por enemigo.

## 8. Validación en Studio (checklist por asset)
1. Escala: el héroe mide lo previsto frente a un avatar de referencia (`VERIFICAR EN STUDIO`).
2. Pivote: ni flota ni se hunde en el suelo.
3. Normales y sombras correctas con iluminación Future.
4. Colisión: el jugador no se engancha ni atraviesa el objeto.
5. Estadísticas: número de partes y draw calls anotados en `docs/perf/`.
6. Salida (Output): sin advertencias ni errores al cargar.
7. Prueba en PC y en un móvil de referencia.

## 9. Entregable por asset
Archivo `docs/assets/<Nombre>.md` con:
- Archivo exportado y fecha.
- Escala y pivote.
- Triángulos por LOD y materiales.
- Colisión usada.
- Resultado de validación (PASS o FAIL, con evidencia).

## 10. Prohibido
- Exportar con escala sin aplicar, o con modificadores activos sin documentar.
- Nombres sin prefijo o fuera de la convención.
- Afirmar que algo funciona en Roblox sin haberlo probado en Studio.
- Usar assets de terceros sin licencia verificada.
