# Rover Perseverance: procedencia y adaptación

Fecha: 14-11-2026.

## Fuente oficial

- Modelo: *Mars Perseverance Rover, 3D Model* (id 25042). Crédito: NASA/JPL-Caltech.
- Página: <https://science.nasa.gov/resource/mars-perseverance-rover-3d-model/>
- Archivo: `assets/src/nasa/25042_Perseverance.glb` (11 687 880 bytes).
- SHA256: `484f00aa5d3739b127b6d413e77149a2d74ae87b76ae57463c4b91965ffb4990`.
- Original: 199 307 triángulos, 65 mallas, 48 materiales.
- Uso: la página no publica una licencia propia. Aplica la guía general de NASA: contenido usable con crédito y sin sugerir respaldo. El logotipo de NASA no se usa. Ver <https://www.nasa.gov/nasa-brand-center/images-and-media/>.

## Adaptación al juego

- La malla original no entra al juego. Una reducción automática a 470 triángulos se probó y se descartó: la silueta dejaba de reconocerse.
- `build_Rover()` en `tools/blender/build_assets.py` modela el rover con primitivas facetadas, igual que los otros 28 assets. Las posiciones y tamaños de cuerpo, ruedas, balancines, mástil, brazo, RTG y antenas se midieron del GLB (1 stud = 0,28 m).
- Resultado: 800 triángulos (presupuesto 900), 4 materiales de la paleta, 9,6 × 8,0 × 14,4 studs, pivote en el suelo.
- En el juego: `Scenery.luau` lo coloca como hito visual en `(150, 0, 172)`, fuera del radio jugable (210), con escala 1,6.

## Pendiente

- Carga en Studio verificada el 15-11-2026 (9 partes, caja de 15,3 × 13,5 × 23,1 studs con escala 1,6). Falta medir el coste de rendimiento y ver el modelo de cerca en partida.
- Decidir si el GLB de 11 MB se versiona en Git o se deja solo la referencia.
