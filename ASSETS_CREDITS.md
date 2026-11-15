# Créditos de assets · Outpost Run (NASA Space Apps Challenge 2026)

Todos los assets 3D y las texturas planetarias provienen de recursos oficiales de NASA,
que son de dominio público para usos no comerciales con atribución
(NASA Media Usage Guidelines: https://www.nasa.gov/nasa-brand-center/images-and-media/).
NASA no respalda este proyecto. No se usa el logotipo oficial de NASA (meatball/worm).

## Modelos 3D (`public/assets/models/`, formato glTF binario descomprimido)

Fuente: **NASA 3D Resources** — https://science.nasa.gov/3d-resources/ y
https://github.com/nasa/NASA-3D-Resources (dominio público, cortesía NASA).

| Archivo | Objeto real | Tris |
|---|---|---|
| saturn_v_rocket.glb | Cohete Saturn V | 34.814 |
| mobile_launcher.glb | Torre Mobile Launcher (Pad 39B) | 19.296 |
| ares_rocket.glb | Ares I Crew Launch Vehicle | 4.664 |
| space_shuttle.glb | Transbordador Espacial | 212.970 |
| canadarm_csa.glb | Canadarm (Agencia Espacial Canadiense/CSA) | 1.080 |
| iss_detailed.glb | Estación Espacial Internacional (detallada) | 174.440 |
| iss_station.glb | ISS (módulo simplificado) | 6.642 |
| hubble_telescope.glb | Telescopio Espacial Hubble | 7.672 |
| jwst_telescope.glb | Telescopio James Webb | 99.239 |
| asteroid_bennu.glb | Asteroide 101955 Bennu (OSIRIS-REx) | 18.240 |
| voyager_probe.glb | Sonda Voyager | 29.911 |
| apollo_lander.glb | Módulo Lunar Apollo | 97.588 |
| lro_orbiter.glb | Lunar Reconnaissance Orbiter | 76.349 |
| mars_mgs_orbiter.glb | Mars Global Surveyor (MOLA) | 19.314 |
| nasa_habitat_hdu.glb | Hábitat HDU (Habitat Demonstration Unit) | 2.264 |
| perseverance_rover.glb | Rover Mars 2020 Perseverance | 199.521 |
| ingenuity_mars.glb | Helicóptero Ingenuity | 9.124 |

Procesado local: descompresión Draco → glTF estándar, recálculo de bounding boxes,
UVs esféricos para Bennu y saneo de materiales (ver `roblox-blender/tools/blender_mcp/`).

## Texturas planetarias (`public/assets/textures/`)

Fuente: NASA Visible Earth / NASA Scientific Visualization Studio / USGS Astrogeology
(dominio público, cortesía NASA y NASA/JPL-Caltech).

| Archivo | Contenido |
|---|---|
| earth_nasa.jpg | Mapa equirectangular de la Tierra (Blue Marble) |
| moon_nasa.jpg | Mapa lunar (LRO/LOLA) |
| mars_nasa.jpg | Mapa de Marte (Viking/MGS) |
| phobos_nasa.jpg | Fobos (Mars Express/Viking) |
| deimos_nasa.jpg | Deimos — usada también como albedo de rocas y asteroides |
| starmap_hipparcos.jpg | Mapa estelar (catálogo Hipparcos, NASA SVS) |

El Sol, el campo estelar de puntos, la pluma del cohete y los halos de portal son
**shaders GLSL procedurales propios** (sin assets externos).

## Imágenes de portales

Cargadas en tiempo de ejecución desde **NASA Image and Video Library**
(images.nasa.gov, dominio público) a través del proxy local `/api/media-proxy`,
con la URL de origen registrada en `content/flow_video_plan.json`.

## Tipografías (`public/assets/fonts/`, .woff2 locales)

| Familia | Licencia | Rol |
|---|---|---|
| Public Sans | SIL OFL 1.1 (USWDS, usada por nasa.gov) | Texto base |
| IBM Plex Mono | SIL OFL 1.1 | Telemetría / datos |
| Instrument Serif | SIL OFL 1.1 | Acento editorial en titulares |
| Michroma | SIL OFL 1.1 | Nomenclatura display aeroespacial |

## Datos científicos

DONKI, RadLab/OSDR, Mars Trek, InSight, Mars Rover Photos, APOD (NASA) y recursos CSA,
vía las APIs listadas en `/api/catalog`; atribución visible en el panel de fuentes de la app.
