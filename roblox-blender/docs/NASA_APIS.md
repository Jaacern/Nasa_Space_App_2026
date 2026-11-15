# Catálogo de APIs y recursos oficiales de NASA

Verificado el 14-11-2026. Alcance: las APIs que usa la raíz de este repositorio (`Outpost Run`) y los recursos oficiales de NASA que puede usar `ARES FORGE` (mega prompt v3, sección 13.5).

## 1. Cómo se verificó

- **Raíz del repositorio (`Outpost Run`):** código Node en la carpeta superior del mismo repo (`Jaacern/Nasa_Space_App_2026`), sin archivo `LICENSE` definido todavía en la raíz.
- **Llamadas de solo lectura** (GET y HEAD) con `DEMO_KEY` o sin clave, desde PowerShell, con User-Agent genérico. No se usó ninguna clave del equipo ni de ninguna persona.
- **Documentación oficial** leída por búsqueda y lectura de páginas. Cuando una página no se pudo leer completa, se indica.

Estados: **Verificado** = respondió con datos en esta comprobación. **Doc** = confirmado solo por documentación oficial. **No verificado** = ni la documentación ni la prueba lo confirman.

## 2. APIs de api.nasa.gov (requieren clave)

| API | Endpoint | Estado | Notas |
|---|---|---|---|
| APOD | `https://api.nasa.gov/planetary/apod?api_key=` | **Error HTTP 500** con DEMO_KEY (hoy). El repo registró el mismo error | Usar solo si el campo `copyright` es nulo. Sin verificar con clave propia |
| NeoWs (feed) | `https://api.nasa.gov/neo/rest/v1/feed?start_date=&end_date=&api_key=` | **Verificado** con DEMO_KEY: HTTP 200, 10 objetos | Cabeceras `X-RateLimit-Limit: 10`, `Remaining: 8`. El código del repo no lo implementa (ver §5) |
| DONKI en api.nasa.gov | `https://api.nasa.gov/DONKI/…` | No probado hoy | El repo indica que la API se migró. No usar en código nuevo |
| InSight (clima de Marte) | `https://api.nasa.gov/insight_weather/?api_key=&feedtype=json&ver=1.0` | No probado hoy. Según el snapshot del repo, último sol con datos 2020-10-25 | Solo contexto histórico, marcado como archivo congelado |
| Mars Rover Photos | `https://api.nasa.gov/mars-photos/api/v1/…` | **No concluyente**: sin clave devolvió HTTP 403. El repo afirma 404 "No such app" | No usar hasta confirmarlo con clave propia |

**Claves.** Se obtienen en api.nasa.gov. Según la página oficial de autenticación (`https://api.nasa.gov/assets/html/authentication.html`, localizada por búsqueda), una clave registrada tiene 1.000 solicitudes por hora en todas las APIs de api.nasa.gov, y puede pedirse un límite mayor. **DEMO_KEY**: documentación de terceros indica 30 solicitudes por hora y 50 al día por IP; nuestra cabecera mostró límite 10. Usar DEMO_KEY solo para pruebas manuales pequeñas.

## 3. APIs oficiales fuera de api.nasa.gov (sin clave)

| API | Endpoint | Estado | Uso propuesto en el juego |
|---|---|---|---|
| DONKI (CCMC) | `https://ccmc.gsfc.nasa.gov/DONKI-API/get/{CME\|FLR\|GST\|SEP\|IPS}?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD` | **Verificado**: CME del 2026-11-01 devolvió JSON. La migración de CCMC indica efecto desde el 30-09-2026, con las mismas entradas y salidas. Los endpoints antiguos seguían activos hasta esa fecha | Eventos solares reales: oleadas con aviso previo |
| Mars raw images (Perseverance y Curiosity) | `https://mars.nasa.gov/rss/api/?feed=raw_images&feedtype=json&order=sol+desc&category=msl&num=1&page=0` | **Verificado**: JSON con `images[].image_files.medium` | Fondos de la fase en Marte, con crédito |
| Images API | `https://images-api.nasa.gov/search?q=&media_type=image&page_size=`; `/asset/{nasa_id}`; `/metadata/{nasa_id}` | **Verificado**: búsqueda "Perseverance Mars" con 1.274 resultados; asset y metadata HTTP 200. Captions y album: **no verificados** (el PDF de la documentación no se pudo leer) | Galería y codex con crédito |
| EONET v3 | `https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=&days=&category=&bbox=` | **Verificado** (cuerpo JSON). El Content-Type declara `application/rss+xml`, que no coincide. Cabecera `X-RateLimit-Limit: 60` | Opcional: peligro de mapa según eventos activos |
| EPIC | `https://epic.gsfc.nasa.gov/api/natural` (también `/date/YYYY-MM-DD`, `/available`, `/enhanced`). Imagen: `https://epic.gsfc.nasa.gov/archive/natural/YYYY/MM/DD/png/epic_1b_YYYYMMDDHHMMSS.png` | **Verificado**: último registro 2026-11-12 | Fondo de inicio: la Tierra real |
| POWER (Temporal daily point) | `https://power.larc.nasa.gov/api/temporal/daily/point?parameters=T2M&community=RE&longitude=&latitude=&start=YYYYMMDD&end=YYYYMMDD&format=JSON` | **Verificado**: JSON (GeoJSON) | Codex: clima de referencia de la Tierra |
| Exoplanet Archive (TAP) | `https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=…&format=json` (tabla `pscomppars`) | **Verificado**. La API antigua `nstedAPI` ya no sirve para varias tablas; la documentación indica usar TAP | Codex de exoplanetas y "destinos" |
| JPL SBDB | `https://ssd-api.jpl.nasa.gov/sbdb.api?sstr=…&phys-par=1` (o `des=`, `spk=`) | **Verificado**: versión 1.3 (433 Eros) | Ficha de asteroide: diámetro y órbita |
| JPL CAD (aproximaciones) | `https://ssd-api.jpl.nasa.gov/cad.api?dist-max=0.05&date-min=now&date-max=%2B60` | **Verificado**: versión 1.5, 34 aproximaciones en la prueba | Amenaza de "lluvia de rocas" con fechas reales. Sustituto sin clave de NeoWs |
| JPL Horizons | `https://ssd.jpl.nasa.gov/api/horizons.api?format=json&COMMAND=…&MAKE_EPHEM=…&OBJ_DATA=…` | Respondió HTTP 200, pero nuestra prueba usó `OBJ_DATA='NO'` y `MAKE_EPHEM='NO'` y no dio datos. **No verificado** | Efemérides, opcional |
| NTRS (citas) | `https://ntrs.nasa.gov/api/citations/{id}` (id de 11 dígitos, p. ej. `20150005587`) | **Verificado** JSON; cabecera `X-RateLimit-Limit: 500`. La página `ntrs.nasa.gov/api/` devolvió 404. La búsqueda **no verificada** | Citas técnicas del codex |
| OSDR Biological Data API v2 | `https://visualization.osdr.nasa.gov/biodata/api/v2/datasets/?format=json`; `/dataset/OSD-n/files/`; `/query/metadata/?…&format=json.records` | **Verificado** (lista de datasets, ~60 KB) | Fichas de estudio con procedencia |
| OSDR Search | `https://osdr.nasa.gov/osdr/data/search?term=…&size=` | **Verificado**: 122 resultados para "bone density". Incluye fuentes externas (GEO, PRIDE): filtrar accesiones `OSD-` | Descubrimiento de estudios |
| RadLab | `https://visualization.osdr.nasa.gov/radlab/api/?…&format=json` (**siempre** con rango de tiempo) | **Verificado** con ventana de la ISS (`columns`, `index`, `data`). Sin rango, el repo registra 504 | Dosis de referencia por sitio |
| GIBS (WMTS) | `https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/1.0.0/WMTSCapabilities.xml` | **Verificado** con HEAD (200). El contenido no se descargó | Fondos satelitales, opcional |
| CMR (Earthdata) | `https://cmr.earthdata.nasa.gov/search/collections.json?keyword=` | **Verificado** | No necesario en el MVP |
| Mars Trek (WMTS) | `https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/WMTSCapabilities.xml` | Snapshot del repo (`mars_layers.json`). No probado hoy | Mapa de selección de sitio |
| NASA Technology Transfer API | `https://technology.nasa.gov/api/` | Devuelve una página HTML de la API. Formato JSON **no verificado** | No usar sin verificar |

## 4. Medios y modelos 3D

- **Imágenes y medios** ([pautas oficiales de NASA](https://www.nasa.gov/nasa-brand-center/images-and-media)): el contenido de NASA generalmente no tiene copyright en EE. UU.; el uso educativo e informativo está permitido y se debe reconocer a NASA como fuente. El logotipo, la insignia y los identificadores no son de dominio público. Las imágenes de terceros requieren permiso del titular. No se puede sugerir respaldo de NASA. Para aplicaciones de IA, la guía dice que no se puede atribuir la información directamente a NASA; sí se puede indicar que la herramienta contiene material de NASA.
- **Modelos 3D** ([NASA 3D Resources](https://nasa3d.arc.nasa.gov/)): el sitio los describe como de uso libre. Los metadatos del repositorio [nasa/NASA-3D-Resources](https://github.com/nasa/NASA-3D-Resources) indican NASA Open Source Agreement 1.3, y algunos registros de data.nasa.gov no indican licencia. **Conclusión:** verificar la licencia de cada modelo antes de usarlo. Por defecto, usar assets propios de Blender.
- **APOD:** si el campo `copyright` no es nulo, no usar la imagen.
- **CSA** (recursos del repo): uso educativo no comercial citando a la CSA y sin sugerir respaldo. No usar su logotipo.

## 5. Raíz del repositorio `Jaacern/Nasa_Space_App_2026` (`Outpost Run`)

**Lo que aporta:**
- Patrón sólido: servidor local `127.0.0.1:8787`, respuestas saneadas con contrato de esquema, snapshots en `data/curated/`. Si una fuente falla, no sobrescribe el snapshot anterior.
- Fuentes que usa: DONKI (ruta CCMC nueva), RadLab, OSDR (búsqueda y v2), Mars Trek (WMTS), fotos de rovers (`mars.nasa.gov`), InSight (archivo), APOD (`HTTP 500` en la última ingesta; snapshot provisional `reusable: false`), CSA (enlaces).
- Último `manifest.json`: DONKI 104 eventos; RadLab 4 sitios; OSDR 26 estudios; Mars Trek 1 capa; rover 6 fotos; InSight 7 soles (congelado); APOD error; CSA 64 enlaces.

**Estado tras auditoría del 14-11-2026:**
1. Se actualizaron `README.md`, `docs/API-LOCAL.md`, `docs/PENDIENTES-MANUALES.md`, `docs/PLAN-JUEGO-Y-DATOS.md`, `content/cards.json` y `scripts/ingest.mjs` para eliminar referencias obsoletas (`demo`, `validate`, `check:apis`, `ingest:donki`, `/api/asteroids`, `getAsteroids`, `ASTEROIDS_SCHEMA`).
2. Nuestra prueba de `api.nasa.gov/mars-photos` sin clave devolvió `403`, mientras el código raíz registra `404 "No such app"` y resuelve fotos directamente desde `mars.nasa.gov` sin clave.
3. Dos documentos del repo (`docs/investigacion-recursos-nasa-csa.md` y `docs/PENDIENTES-MANUALES.md`) mencionan una clave NASA expuesta en chat. **Pendiente rotarla (P-04)** y no pegarla en chats ni repositorios.
4. Sigue sin archivo `LICENSE` en la raíz del repositorio (decisión pendiente del equipo).

Búsqueda de patrones de claves en el código del repo: sin coincidencias. `.env.example` no tiene valor.

## 6. Límites de uso

| Fuente | Límite conocido |
|---|---|
| api.nasa.gov, clave registrada | 1.000 solicitudes por hora (documentación oficial) |
| api.nasa.gov, DEMO_KEY | Terceros: 30 por hora y 50 al día por IP. Observado: límite 10. Inestable |
| EONET | Cabecera 60; ventana no documentada |
| NTRS | Cabecera 500; ventana no documentada |
| RadLab | Requiere rango temporal; sin rango, 504 |
| POWER | Documentado HTTP 429 al exceder; sin cifras publicadas |
| JPL SBDB y CAD | No documentado |
| DONKI, EPIC, Images, OSDR, Exoplanet TAP | No documentado: tratar como limitado y usar caché |

## 7. Roblox: puntos a verificar

- Los servidores de Roblox no alcanzan `127.0.0.1` de nuestro equipo. El servidor local sirve para desarrollo. La versión publicada usa snapshots dentro del place o un proxy público.
- `HttpService` se usa en el servidor. El ejemplo oficial de `RequestAsync` recuerda activar las solicitudes HTTP en la configuración de la experiencia.
- **Límites de tasa, tamaño de respuesta y dominios permitidos: no verificados.** La página de `HttpService` se leyó truncada. Verificar antes de diseñar.
- La clave de NASA nunca debe estar en LocalScripts ni en el cliente.

## 8. Cómo volver a verificar

```bash
curl -s "https://ccmc.gsfc.nasa.gov/DONKI-API/get/CME?startDate=2026-11-01&endDate=2026-11-02" | head -c 300
curl -s "https://images-api.nasa.gov/search?q=Perseverance%20Mars&media_type=image&page_size=1" | head -c 300
curl -s "https://eonet.gsfc.nasa.gov/api/v3/events?limit=2&status=open" | head -c 300
curl -s "https://ssd-api.jpl.nasa.gov/cad.api?dist-max=0.05&date-min=now&date-max=%2B60" | head -c 300
```

## 9. Fuentes oficiales

- [NASA Open APIs (portal)](https://api.nasa.gov/)
- [Autenticación y límites de api.nasa.gov](https://api.nasa.gov/assets/html/authentication.html)
- [Aviso de migración de DONKI (CCMC)](https://ccmc.gsfc.nasa.gov/news/major-updates/)
- [Exoplanet Archive: interfaces de programa](https://exoplanetarchive.ipac.caltech.edu/docs/program_interfaces.html)
- [JPL SBDB API](https://ssd-api.jpl.nasa.gov/doc/sbdb.html)
- [NASA POWER: APIs](https://power.larc.nasa.gov/docs/services/api/)
- [EONET v3](https://eonet.gsfc.nasa.gov/docs/v3)
- [EPIC API](https://epic.gsfc.nasa.gov/about/api)
- [OSDR Biological Data API](https://visualization.osdr.nasa.gov/biodata/api)
- [RadLab Data API](https://visualization.osdr.nasa.gov/radlab/gui/data-api/)
- [NASA Images and Media Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media)
- [NASA 3D Resources](https://nasa3d.arc.nasa.gov/)
- [Repositorio de documentación de APIs de NASA](https://github.com/nasa/api-docs)
