# Catálogo de Modelos Oficiales NASA 3D Resources (`science.nasa.gov/3d-resources`)

Integración unificada entre el pipeline **Blender 4.5 / Roblox Studio** (`roblox-blender/assets/export/`) y el motor **WebGL Three.js** (`public/assets/models/`) siguiendo el contrato de `roblox-export/SKILL.md` (`SM_<Nombre>_LOD0`, pivote centrado, escala en metros/studs).

| Asset Roblox (`roblox-blender/assets/export/`) | Asset WebGL (`public/assets/models/`) | Fuente Oficial NASA 3D Resources | Uso en Web 3D & Roblox Outpost Run | Estado |
|---|---|---|---|---|
| `SM_Rocket_Ares_LOD0.glb` | `ares_rocket.glb` | `Ares 1 (A)` (`95.8 KB`) | Cohete principal que despega desde la Tierra y recorre los portales planetarios | **PASS** |
| `SM_Rocket_SaturnV_LOD0.glb` | `saturn_v_rocket.glb` | `Saturn V` (`905.5 KB`) | Cohete pesado histórico en plataforma y transición orbital | **PASS** |
| `SM_LaunchPad_39B_LOD0.glb` | `mobile_launcher.glb` | `Mobile Launcher (assembled)` (`193.8 KB`) | Torre de lanzamiento en la superficie del Planeta Tierra (Diapositiva 1) | **PASS** |
| `SM_Station_ISS_LOD0.glb` | `iss_station.glb` | `International Space Station (ISS) (A)` (`38.8 KB`) | Estación en órbita baja terrestre (LEO RadLab `4.20 µGy/h`) | **PASS** |
| `SM_Asteroid_Bennu_LOD0.glb` | `asteroid_bennu.glb` | `1999 RQ36 asteroid (Bennu)` (`321.9 KB`) | Asteroide cercano a la Tierra (NeoWs / OSIRIS-REx) en el corredor interplanetario | **PASS** |
| `SM_Orbiter_LRO_LOD0.glb` | `lro_orbiter.glb` | `Lunar Reconnaissance Orbiter (A)` (`639.2 KB`) | Sonda orbital en la Luna (sensor real `CRaTER-D1D2`, `12.72 µGy/h`) | **PASS** |
| `SM_Lander_Lunar_LOD0.glb` | `apollo_lander.glb` | `Apollo Lunar Module` (`700.0 KB`) | Módulo de descenso en el Polo Sur Lunar (Cráter Shackleton) | **PASS** |
| `SM_Habitat_HDU_LOD0.glb` | `nasa_habitat_hdu.glb` | `Habitat Demonstration Unit` (`504.6 KB`) | Núcleo presurizado de la Base Lunar y Marciana en Outpost Run | **PASS** |
| `SM_Orbiter_MGS_LOD0.glb` | `mars_mgs_orbiter.glb` | `Mars Global Surveyor (mapping)` (`53.9 KB`) | Satélite del altímetro láser `MOLA` en órbita marciana (`463 m/px`) | **PASS** |
| `SM_Drone_Ingenuity_LOD0.glb` | `ingenuity_mars.glb` | `Ingenuity Mars Helicopter` (`1.97 MB`) | Helicóptero explorador sobre el Cráter Jezero junto al Outpost | **PASS** |

## Texturas Planetarias Equirectangulares Oficiales (`public/assets/textures/`)
* `earth_nasa.jpg` — Mapa global de la Tierra (`NASA Earth (A)`) con shader de atmósfera Rayleigh y capa de nubes dinámicas.
* `moon_nasa.jpg` — Mosaico global lunar (`NASA LRO Moon`).
* `mars_nasa.jpg` — Mapa global marciano (`NASA Viking/MGS Mars`) + tesela `Mars Trek WMTS MOLA`.
* `phobos_nasa.jpg` y `deimos_nasa.jpg` — Lunas de Marte (`Phobos` y `Deimos`).
* `starmap_hipparcos.jpg` — Mapa estelar científico `Hipparcos`.
