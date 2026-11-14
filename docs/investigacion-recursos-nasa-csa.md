# Investigación de recursos NASA y CSA

**Fecha de verificación:** 14 de noviembre de 2026  
**Objetivo:** determinar qué aporta cada recurso, cómo integrarlo en un prototipo y qué límites técnicos o de uso deben respetarse.

## Conclusión ejecutiva

Los recursos son complementarios, pero no representan el mismo tipo de evidencia:

- **DONKI** aporta eventos recientes de clima espacial. Conviene usarlo como señal dinámica de peligro, no como pronóstico operativo.
- **RadLab** aporta mediciones dosimétricas históricas y reales. Sirve para construir referencias y comparaciones, pero no describe por sí solo la radiación actual de una misión.
- **OSDR** aporta estudios, metadatos y archivos científicos sobre biología y salud espacial. Es la fuente adecuada para justificar efectos y contramedidas, no para calcular directamente un riesgo clínico individual.
- **Mars Trek** aporta cartografía, imágenes, elevación y capas científicas reales de Marte. Su integración es geoespacial mediante WMTS, no una API JSON convencional.
- **CSA** aporta materiales educativos sobre STEM y producción de alimentos. Son contenido pedagógico, no datos dinámicos ni APIs.
- **NASA Open APIs** sigue siendo útil para APOD y otros servicios del portal. Para DONKI, el código nuevo debe usar la dirección oficial de CCMC introducida en septiembre de 2026.

Para un MVP de análisis de una misión recomiendo comenzar con **DONKI + RadLab + OSDR**. Mars Trek debe entrar cuando el prototipo necesite selección o visualización de emplazamientos. El contenido CSA encaja como una capa educativa o de diseño de sistemas alimentarios.

## Comparación rápida

| Recurso | Tipo | Acceso verificado | Salida | Actualización | Mejor uso | Dificultad |
|---|---|---|---|---|---|---|
| NASA Open APIs | Catálogo de APIs | Clave API | Principalmente JSON | Depende del servicio | APOD, fotos, objetos y servicios generales | Baja |
| DONKI | Eventos de clima espacial | API oficial de CCMC sin clave | JSON | Regular y reciente | Alertas de contexto y mecánicas de riesgo | Baja-media |
| OSDR Search | Buscador federado | Sin clave observada | JSON estilo Elasticsearch | Según publicación de estudios | Descubrimiento por palabras clave | Media |
| OSDR Biological Data API v2 | Metadatos y datos científicos | Sin clave observada | JSON, CSV, TSV, archivos | Según publicación de estudios | Evidencia, metadatos, archivos procesados | Media-alta |
| RadLab | Dosimetría espacial | Sin clave observada | CSV, TSV, JSON, HTML | Colecciones históricas por instrumento | Dosis, flujo y comparación de instrumentos | Media |
| Mars Trek | GIS planetario | Sin clave observada | WMTS, teselas, metadatos y descargas | Por publicación de capas | Mapa, terreno, emplazamientos | Alta |
| CSA STEM | Contenido educativo | Web pública | HTML y recursos enlazados | Editorial | Experiencias educativas | Baja |
| CSA Food Production | Kit educativo | Web pública | HTML, actividades, videos e infografías | Editorial | Nutrición y agricultura espacial | Baja |

"Sin clave observada" significa que las solicitudes de prueba funcionaron sin autenticación. No equivale a una garantía contractual de acceso ilimitado.

## Hallazgos por recurso

### 1. NASA Open APIs

El [portal oficial de NASA Open APIs](https://api.nasa.gov/) centraliza el registro de claves y APIs como APOD, fotos de rovers y DONKI. Los límites se aplican de forma conjunta a las solicitudes de `api.nasa.gov` asociadas a una clave; cuando se exceden, el portal puede bloquearla temporalmente. Fuentes secundarias indican 1.000 solicitudes por hora para una clave registrada y 30 por hora, con 50 al día, para `DEMO_KEY`. En una prueba del 14 de noviembre de 2026, `DEMO_KEY` devolvió una cabecera de límite de 10 y luego una respuesta `429`, así que esas cifras no son estables. La aplicación debe observar las cabeceras de límite, tolerar `429` y usar una clave propia.

**Corrección de verificación:** en la primera pasada, las comprobaciones de cabeceras con Python y `curl` no se ejecutaron realmente (el módulo `requests` no estaba instalado y la salida del shell no se capturaba). El contenido de las APIs sí se verificó con lecturas web. Las cabeceras CORS se comprobaron después con `fetch` de Node: DONKI no envía `Access-Control-Allow-Origin`, el buscador OSDR solo lo permite para `osdr.nasa.gov`, y las teselas de Mars Trek y `api.nasa.gov` usan `*`. RadLab devolvió `504` en consultas sin rango de fechas.

Recomendaciones:

- Guardar la clave en una variable de entorno del servidor, por ejemplo `NASA_API_KEY`.
- No incluirla en JavaScript entregado al navegador, Git, capturas ni documentación.
- Aplicar caché, reintentos con espera exponencial y un límite interno por usuario.
- Usar `DEMO_KEY` únicamente para pruebas manuales pequeñas.

**Incidente de credencial:** se incluyó una clave en el mensaje original. El informe no la reproduce. Debe considerarse expuesta, sustituirse por una nueva y dejar de usarse en el proyecto.

### 2. DONKI

NASA/CCMC migró DONKI el **30 de septiembre de 2026**. El [aviso oficial de migración](https://ccmc.gsfc.nasa.gov/news/major-updates/) pide actualizar las integraciones al prefijo:

```text
https://ccmc.gsfc.nasa.gov/DONKI-API/get/
```

Las rutas y formatos posteriores a `/get/` se conservaron. Una solicitud real a la ruta nueva devolvió eventos CME en JSON:

```http
GET https://ccmc.gsfc.nasa.gov/DONKI-API/get/CME?startDate=2026-11-01&endDate=2026-11-02
```

La API cubre, entre otros, CME, erupciones solares, tormentas geomagnéticas, partículas energéticas solares, choques interplanetarios y notificaciones. Las respuestas contienen identificadores, horas, instrumentos, relaciones con otros eventos y, cuando existe, análisis o simulaciones asociadas. La [referencia oficial de DONKI](https://ccmc.gsfc.nasa.gov/DONKI/api/) debe ser la fuente para parámetros y esquemas.

El antiguo acceso `https://api.nasa.gov/DONKI/...` todavía respondió en algunas pruebas, pero no debe ser la base de una integración nueva después del aviso de migración.

Riesgos y controles:

- Algunos campos son `null` y las listas relacionadas pueden estar vacías.
- Un evento puede recibir análisis o revisiones posteriores. Conviene conservar `activityID`, `submissionTime` y `versionId`.
- Una fecha sin resultados devuelve `[]`; esto no es un error.
- Las notificaciones indican que DONKI contiene información experimental. NOAA Space Weather Prediction Center es la fuente oficial estadounidense de pronósticos de clima espacial. No se debe usar DONKI como único sistema para decisiones de seguridad humana o de hardware.

### 3. OSDR Search

La ruta proporcionada funciona como buscador:

```http
GET https://osdr.nasa.gov/osdr/data/search?term=bone%20density
```

La respuesta tiene una estructura similar a Elasticsearch: tiempo de consulta, total de resultados, puntuación, documento fuente y fragmentos resaltados. En las pruebas se encontraron estudios pertinentes sobre pérdida ósea, respuesta inmune y fisiología espacial.

Limitaciones importantes:

- Es un índice amplio. Puede devolver fuentes externas como NIH GEO o EBI PRIDE, además de accesiones NASA `OSD-*`.
- Una coincidencia textual no demuestra que un estudio sea espacial, humano ni clínicamente aplicable.
- El esquema es cómodo para búsqueda, pero menos estable y explícito que la API biológica v2.

Uso recomendado: descubrimiento y búsqueda libre. Después, la aplicación debe resolver la accesión elegida en OSDR v2 y mostrar organismo, tipo de estudio, misión, controles, tamaño de muestra, licencia y archivos disponibles.

### 4. OSDR Biological Data API v2

La [documentación oficial de OSDR Biological Data API](https://visualization.osdr.nasa.gov/biodata/api) define dos interfaces:

1. **REST jerárquica**, para recorrer datasets, ensayos, muestras, metadatos y archivos.
2. **Query**, para seleccionar y filtrar campos de metadatos o columnas de datos.

Formatos disponibles:

- REST: JSON por defecto.
- Query: CSV por defecto; también TSV y variantes JSON.
- Datos no tabulares: descarga del archivo original con salida `raw`.
- Salida HTML o `browser` para inspección interactiva.

Solicitudes verificadas:

```http
GET https://visualization.osdr.nasa.gov/biodata/api/v2/datasets/?format=json

GET https://visualization.osdr.nasa.gov/biodata/api/v2/query/metadata/?id.accession=OSD-471&study.factor%20value.spaceflight&format=json.records

GET https://visualization.osdr.nasa.gov/biodata/api/v2/dataset/OSD-471/files/
```

La segunda consulta devolvió muestras de vuelo y control del estudio OSD-471. La tercera devolvió enlaces directos a archivos procesados, enviados por investigadores y metadatos ISA.

Recomendaciones:

- Para fichas de evidencia, usar `format=json.records`.
- Descargar archivos grandes en un proceso de ingestión, no desde cada navegador.
- Mantener la accesión, DOI, licencia y URL original junto a cada conclusión.
- No presentar resultados de ratones, plantas o cultivos celulares como efectos cuantificados en astronautas.
- La ausencia de un límite publicado no implica acceso ilimitado. Cachear metadatos y evitar consultas comodín amplias.

### 5. RadLab

La [documentación de la Data API de RadLab](https://visualization.osdr.nasa.gov/radlab/gui/data-api/) especifica solicitudes GET a:

```text
https://visualization.osdr.nasa.gov/radlab/api/
```

Admite dos sintaxis que no se pueden mezclar:

- Pares clave-valor para filtros sencillos.
- Una expresión booleana con `AND`, `OR`, comparaciones y paréntesis.

Campos útiles:

| Campo | Unidad o tipo |
|---|---|
| `timestamp` | ISO 8601 o Unix |
| `absorbed_dose_rate` | μGy/h |
| `dose_equivalent_rate` | μSv/h |
| `flux` | cm⁻² sr⁻¹ s⁻¹ |
| `latitude`, `longitude` | grados |
| `altitude` | km |
| `instrument_id` | identificador único y sensible a mayúsculas |
| `spacecraft`, `module`, `trajectory` | texto categórico |

Ejemplo verificado:

```http
GET https://visualization.osdr.nasa.gov/radlab/api/?spacecraft=ISS&instrument=DosTel&timestamp%3E=2022-04-01T23%3A00&timestamp%3C2022-04-02T01%3A05&absorbed_dose_rate%3E2&flux&latitude&longitude&altitude&format=json
```

La salida JSON usa una forma tabular con `columns`, `index` y `data`. No devuelve necesariamente una lista de objetos. La cadencia varía: la colección general puede alcanzar aproximadamente un minuto, algunos instrumentos entregan cinco minutos y ciertos conjuntos preliminares contienen promedios diarios.

Riesgos y controles:

- Siempre restringir el intervalo temporal. Una consulta amplia puede producir demasiadas filas.
- No sumar μGy y μSv ni tratarlos como unidades equivalentes.
- Comparar instrumentos sólo después de revisar ubicación, calibración, cadencia y cobertura.
- RadLab contiene observaciones históricas. Para un “riesgo actual”, DONKI y un modelo explícito deben permanecer separados de esta referencia dosimétrica.

### 6. Mars Trek

[Mars Trek](https://trek.nasa.gov/mars/) es primero un portal GIS interactivo. La [documentación técnica de Mars Trek](https://trek.nasa.gov/tiles/apidoc/trekAPI.html?body=mars) expone capas mediante el estándar OGC WMTS. Las teselas se solicitan con estilo, matriz, nivel, fila y columna obtenidos de `GetCapabilities`; el archivo puede ser PNG o JPEG según la capa.

También existen rutas de catálogo y metadatos, por ejemplo la ficha del [DEM de Columbia Hills](https://trek.nasa.gov/mars/TrekWS/rest/cat/metadata/fgdc/html?label=CLH_DEM_Mosaic_HiRISE_CTX_HRSC_GCS_MARS_07-10-2018).

Consideraciones de integración:

- Usar una librería con WMTS, como OpenLayers, Cesium o un cliente GIS compatible.
- Leer `GetCapabilities` en vez de codificar estilos y niveles manualmente.
- Respetar la extensión de cobertura; una tesela ausente puede indicar que no hay datos en esa zona.
- Mars Trek usa sistemas de referencia planetarios, incluido el CRS marciano mostrado como EPSG:104905 en el enlace compartido. No debe suponerse Web Mercator terrestre.
- Cada capa tiene procedencia, resolución y finalidad propias. Algunos DEM se describen como productos preliminares o para planificación y discusión.
- La documentación visible de versiones es antigua aunque el portal esté accesible. Conviene aislar el cliente WMTS para poder cambiar endpoints o capas sin afectar el resto de la aplicación.

### 7. Recursos CSA para STEM

La página [Space resources for STEM and youth organizations](https://www.asc-csa.gc.ca/eng/youth-educators/resources-stem-and-youth-organizations.asp) reúne herramientas gratuitas y bilingües: presentaciones, kits, actividades, juegos, materiales imprimibles y recursos de divulgación.

No ofrece una API ni un esquema de datos. Su mejor uso en un producto es:

- enlazar actividades seleccionadas;
- crear una vista para educadores con edad, duración y objetivo;
- citar la página original;
- evitar copiar masivamente textos o archivos.

### 8. CSA: producción de alimentos en la Luna

El [kit de producción de alimentos](https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/) organiza lecturas, actividades para grados 6 a 9, infografías y videos sobre nutrición, seguridad alimentaria, agricultura y reciclaje de agua.

Puede aportar restricciones y preguntas de diseño a una simulación: nutrición de la tripulación, agua, residuos, volumen, seguridad y producción local. Sin embargo, el kit no ofrece valores numéricos normalizados para ejecutar un modelo. Los números de una simulación deben proceder de una fuente científica identificada o declararse como supuestos.

## Estrategia recomendada de integración

### Producto propuesto

Un **laboratorio de decisiones para hábitats y misiones** puede conectar las fuentes sin mezclarlas indebidamente:

1. **Situación espacial:** DONKI muestra eventos recientes y relaciones entre ellos.
2. **Referencia de exposición:** RadLab muestra distribuciones históricas por instrumento, lugar y periodo.
3. **Efectos biológicos:** OSDR presenta estudios relevantes con organismo, misión, ensayo, controles y enlaces a datos.
4. **Emplazamiento marciano:** Mars Trek muestra terreno, elevación, geología y posibles regiones de interés.
5. **Sistema alimentario:** CSA aporta actividades y preguntas para explorar nutrición, producción y sostenibilidad.

### Arquitectura mínima

```text
Navegador
   │
   ▼
Backend del proyecto
   ├── adaptador DONKI ── caché corta
   ├── adaptador RadLab ─ caché por consulta normalizada
   ├── índice OSDR ────── caché larga / ingestión programada
   └── configuración y procedencia

Mapa web ──────────────── WMTS de Mars Trek
Contenido educativo ───── enlaces y metadatos curados de CSA
```

Reglas de implementación:

- El backend normaliza fechas, valores nulos y errores, pero conserva la respuesta original para auditoría.
- Cada tarjeta o gráfico muestra fuente, URL, hora de consulta, unidad y si el valor es observado, derivado o simulado.
- Los esquemas se validan antes de guardar o mostrar datos.
- Los datos OSDR y RadLab se cachean; no se vuelven a descargar en cada visita.
- Las capas WMTS se cargan directamente sólo si CORS, rendimiento y términos lo permiten. De lo contrario, se usa un proxy de teselas con caché responsable.
- La aplicación nunca convierte automáticamente un evento DONKI en una dosis para astronautas. Esa conversión requiere un modelo de transporte y blindaje documentado.

## Prioridad para un MVP

### Fase 1

- Adaptador de DONKI para CME, SEP, GST y notificaciones.
- Consulta RadLab limitada a un instrumento y periodo de ejemplo.
- Buscador OSDR y ficha de estudio basada en accesiones `OSD-*`.
- Etiquetas visibles: **dato observado**, **inferencia** y **escenario simulado**.

### Fase 2

- Mapa Mars Trek con una sola capa base y un DEM de una región seleccionada.
- Comparación de emplazamientos con criterios claramente definidos.
- Módulo educativo CSA con enlaces bilingües y actividades curadas.

### Fase 3

- Modelos cuantitativos de blindaje, salud o alimentos, sólo después de documentar ecuaciones, supuestos, incertidumbre y fuentes científicas.

## Riesgos legales, de marca y de interpretación

- Las [pautas de imágenes y medios de NASA](https://www.nasa.gov/nasa-brand-center/images-and-media) permiten en general usos informativos y educativos con reconocimiento de la fuente, pero el logotipo, los identificadores, las personas identificables y el contenido de terceros tienen reglas adicionales.
- El producto no debe insinuar que NASA o CSA lo revisó, patrocinó o aprobó.
- Debe conservarse el aviso de no endoso proporcionado por la organización del reto.
- Las fuentes no gubernamentales enlazadas desde una página NASA mantienen sus propios términos.
- La [guía de uso del logotipo de CSA](https://www.asc-csa.gc.ca/eng/about/use-logo-csa.asp) está orientada a colaboradores y prohíbe usos que parezcan patrocinio o promoción. No se debe usar el logotipo para decorar el prototipo sin autorización aplicable.
- En CSA, revisar la licencia de cada imagen, video, PDF o actividad. “Gratuito” no significa necesariamente libre de derechos para redistribución o modificación.
- Las visualizaciones deben incluir incertidumbre y límites de aplicabilidad, especialmente al pasar de animales o células a salud humana.

Texto corto recomendado para el pie del prototipo:

> Este proyecto utiliza datos y recursos públicos de NASA y CSA. NASA y CSA no patrocinan ni respaldan este producto. Los resultados derivados y simulados son responsabilidad del equipo. Consulte cada fuente para conocer sus condiciones de uso.

## Próximos pasos concretos

1. Reemplazar la clave NASA publicada y guardarla sólo como secreto de servidor.
2. Elegir una historia de usuario principal: radiación, salud, emplazamiento marciano o producción de alimentos.
3. Implementar primero adaptadores pequeños para DONKI, RadLab y OSDR, con respuestas de ejemplo guardadas para desarrollo.
4. Definir un esquema interno común con `source`, `retrievedAt`, `observedAt`, `units`, `provenanceUrl`, `license`, `dataKind` y `uncertainty`.
5. Elegir una única capa Mars Trek antes de construir un mapa multicapa.
6. Revisar la licencia específica de cada recurso CSA que se quiera reproducir, en lugar de enlazar.
7. Añadir atribución y aviso de no endoso desde la primera versión de la interfaz.

## Fuentes principales

- [NASA Open APIs](https://api.nasa.gov/)
- [DONKI API Reference](https://ccmc.gsfc.nasa.gov/DONKI/api/)
- [Aviso de migración CCMC de septiembre de 2026](https://ccmc.gsfc.nasa.gov/news/major-updates/)
- [NASA OSDR](https://osdr.nasa.gov/bio/repo/)
- [OSDR Biological Data API](https://visualization.osdr.nasa.gov/biodata/api)
- [RadLab Data API](https://visualization.osdr.nasa.gov/radlab/gui/data-api/)
- [RadLab Data Overview](https://visualization.osdr.nasa.gov/radlab/gui/data-overview/)
- [Mars Trek](https://trek.nasa.gov/mars/)
- [Mars Trek API/WMTS](https://trek.nasa.gov/tiles/apidoc/trekAPI.html?body=mars)
- [CSA: recursos STEM](https://www.asc-csa.gc.ca/eng/youth-educators/resources-stem-and-youth-organizations.asp)
- [CSA: producción de alimentos en la Luna](https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/)
- [NASA Images and Media Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media)
- [CSA logo usage guidelines](https://www.asc-csa.gc.ca/eng/about/use-logo-csa.asp)

Content was rephrased for compliance with licensing restrictions.
