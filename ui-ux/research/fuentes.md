# Investigación de diseño · ORBITAL UI

**Fecha:** 14 de noviembre de 2026  
**Objetivo:** construir una fuente de diseño UI/UX con temática NASA para Outpost Run: color, tipografía, bordes, formas, texturas, efectos y componentes frontend; descargar los recursos y dejar una maqueta aplicable a la web.

> No se pudo usar un MCP de navegador (no había servidores MCP expuestos en la sesión), así que la investigación se hizo con peticiones HTTP directas a las fuentes y con la API de imágenes de NASA. Todo lo descargado quedó versionado en `ui-ux/assets/`.

---

## 1. Fuentes consultadas

| Fuente | Qué se tomó | URL |
|---|---|---|
| NASA Brand Center | Reglas de uso de insignia, logotipo, imágenes y aviso de no respaldo | <https://www.nasa.gov/nasa-brand-center/> |
| NASA Images & Media Usage | Las fotos se pueden usar con atribución; el emblema y el logotipo **no** son de dominio público | <https://www.nasa.gov/nasa-brand-center/images-and-media/> |
| NASA Graphics Standards Manual, NHB 1430.2 (1976) | Retícula, carteles, diagramas técnicos, rojo/azul, espíritu del programa gráfico federal | <https://www.nasa.gov/wp-content/uploads/2015/01/nasa_graphics_manual_nhb_1430-2_jan_1976.pdf> |
| NASA Insignia (Wikipedia) | Valores exactos: rojo `#FC3D21` (Pantone 185), azul `#0B3D91` (Pantone 286), worm `#E03C31` (Pantone 179) | <https://en.wikipedia.org/wiki/NASA_insignia> |
| NASA.gov (tema 2026) | Acento rojo de interfaz `#F64137`; el bundle declara Inter y DM Mono | <https://www.nasa.gov/> |
| USWDS · Typography | Public Sans como tipografía del sistema federal | <https://designsystem.digital.gov/components/typography/> |
| NASA Images API | Búsqueda y descarga de fotos con metadatos | <https://images-api.nasa.gov/> |
| Google Fonts | Descarga de las familias OFL en woff2 | <https://fonts.google.com/> |
| Lucide | Set de íconos SVG (ISC) | <https://lucide.dev/> |

El manual de 1976 se guardó completo en [`nasa-graphics-standards-manual-1976.pdf`](./nasa-graphics-standards-manual-1976.pdf) y hay un tablero de referencia en [`moodboard-nasa.webp`](./moodboard-nasa.webp).

---

## 2. Hallazgos y decisiones

### 2.1 Marca: inspiración, no imitación

La insignia “meatball”, el sello y el logotipo “worm” **no son de dominio público** y su uso está regulado por 14 CFR 1221. NASA tampoco permite insinuar que un producto está aprobado o patrocinado por la agencia.

**Decisión:** el kit no incluye ni reconstruye el emblema, el sello ni el worm. Se creó un wordmark original (`assets/svg/wordmark-outpost.svg`) y un parche de misión original (`patch-junior-astronaut.svg`). Los textos dicen “NASA Space Apps” solo como contexto factual del evento y el pie aclara que NASA y CSA no respaldan el proyecto.

### 2.2 Color: señal, confianza y telemetría

La paleta oficial del emblema da dos anclas muy potentes:

- **Rojo de señal `#FC3D21`** para acción, peligro y energía.
- **Azul institucional `#0B3D91`** para fondo, confianza y profundidad.
- El worm usó un rojo ligeramente más cálido, `#E03C31`, útil para superficies grandes.
- El sitio de NASA en 2026 usa `#F64137` como acento de interfaz.

**Decisión:** conservar esos dos colores como ejes y añadir una capa funcional: cian `#38BDF8` para datos, ámbar `#F5A524` para avisos, verde menta `#2DD4A7` para estados nominales, óxido `#C1440E` para Marte y oro `#D9A441` para el foil de los parches. Los neutros van del vacío `#04060C` al lunar `#B4C2D6`.

### 2.3 Tipografía: la voz de la agencia y la voz de la fiesta

- **Public Sans** es la tipografía base del sistema de diseño federal (USWDS) que usa NASA Science. Perfecta para interfaz y lectura.
- El bundle de NASA declara además **Inter** y **DM Mono** (HDS). Se incorporan para dar una segunda voz de UI y una mono de datos.
- **IBM Plex Mono** ya era la mono de telemetría del proyecto; se mantiene por coherencia.
- **Michroma** aporta el gesto ancho y geométrico del display aeroespacial sin copiar el worm.
- **Instrument Serif** da el contraste editorial del pitch (la frase humana entre tantos datos).
- **Chakra Petch** es la alternativa HUD/sci-fi para paneles y cifras.
- **Bungee** es la voz de “fiesta de cumpleaños”: póster, sticker, globo, parche.

**Decisión:** ocho familias con roles claros, todas OFL, descargadas en woff2 con subsets `latin` y `latin-ext` (cubren tildes y ñ). El runtime no llama a Google Fonts.

### 2.4 Forma: del manual de 1976 al HUD moderno

El manual de Danne & Blackburn trabaja con retícula estricta, líneas finas, diagramas y una economía gráfica muy reconocible. Los paneles modernos de control de misión añaden esquinas técnicas, tipografía mono y densidad de datos.

**Decisión:** el kit usa chaflanes de 8/14/22 px, corchetes HUD de 1 px, órbitas punteadas, parches circulares, stickers torcidos y una retícula de blueprint. Nada de “glassmorphism” genérico sin estructura: el vidrio siempre va acompañado de una línea y una etiqueta.

### 2.5 Celebración: que se note que es una fiesta

Una temática NASA no es solo azul oscuro y estrellas. Es cumpleaños: **parche bordado, sticker, foil metálico, confeti de estrellas, póster, cinta de misión, cuenta atrás**. Esos elementos se incorporan como assets y como tratamiento (foil, starburst, marquee, sticker). La regla: **un acento festivo por pantalla**, no todos a la vez.

### 2.6 Imágenes: reales, optimizadas y con crédito

Se descargaron ocho fotografías de la NASA Images API:

| Archivo | ID NASA | Uso |
|---|---|---|
| `earthrise-artemis.webp` | `art002e009280b` | Hero / horizonte |
| `carina-nebula.webp` | `carina_nebula` | Galería / celebración |
| `perseverance-selfie.webp` | `PIA24542` | Marte / rover |
| `artemis-ii-launch.webp` | `SLS_MAF_20260401_ArtemisIILaunch_05` | Lanzamiento / actualidad |
| `apollo-17-panorama.webp` | `jsc2004e52772` | Luna / archivo |
| `mission-control-2026.webp` | `jsc2026e020490` | Datos / control |
| `mars-vista.webp` | `PIA20332` | Marte / panorama |
| `hubble-deep-field.webp` | `PIA12110` | Universo / fondo |

Los originales JPEG y las versiones WebP conviven en `assets/img/`. `credits.json` guarda título, ID, centro, fecha, URL de origen y licencia. El script `scripts/download-assets.mjs` permite repetir la descarga.

---

## 3. Principios de diseño del kit

1. **Primero la misión, después el adorno.** Cada pantalla debe responder: ¿dónde estoy, qué recurso tengo, qué decisión sigue?
2. **Datos con voz propia.** Cifras siempre en mono y con unidad; nunca en el mismo tono que la prosa.
3. **Un rojo que significa algo.** El rojo no decora: señala acción, peligro o evento solar.
4. **Estructura visible.** Línea de 1 px, esquina, etiqueta y retícula: se debe sentir un artefacto, no una plantilla.
5. **Fiesta controlada.** Foil, sticker y estrellas en dosis pequeñas; en pantallas infantiles, sí, pero siempre legibles.
6. **Contraste y foco.** Todo interactivo tiene foco visible y target mínimo de 44 px.
7. **Movimiento opcional.** `prefers-reduced-motion` desactiva animaciones; el contenido nunca depende de ellas.

---

## 4. Traducción a tokens y clases

| Elemento de diseño | Token / clase |
|---|---|
| Rojo de acción | `--ux-red-500`, `.ux-btn--primary`, `.ux-badge--red` |
| Azul institucional | `--ux-blue-600`, `.ux-btn--secondary` |
| Datos | `--ux-cyan-400`, `.ux-data`, `.ux-readout` |
| Aviso solar | `--ux-amber-400`, `.ux-btn--hazard`, `.ux-alert--warning` |
| Éxito | `--ux-mint-400`, `.ux-alert--success` |
| Panel de cabina | `.ux-panel`, `.ux-panel--chamfer`, `.ux-hud` |
| Retícula técnica | `.ux-grid-bg`, `.ux-grid-bg--blueprint` |
| Estrellas | `.ux-starfield`, `.ux-starfield--deep` |
| Grano / scanlines | `.ux-noise`, `.ux-scanlines`, `.ux-crt` |
| Foil de parche | `.ux-foil`, `--ux-grad-foil` |
| Parche / sticker | `.ux-patch`, `.ux-sticker` |
| Cinta de misión | `.ux-marquee` |
| Medidores | `.ux-meter`, `.ux-meter--energy/air/shield` |

---

## 5. Licencias y límites

- **Código del kit:** MIT (`ui-ux/LICENSE`).
- **Tipografías:** SIL Open Font License 1.1 (Google Fonts).
- **Íconos:** Lucide, ISC.
- **Imágenes:** NASA Media Usage Guidelines; se acredita a NASA en la interfaz y en `credits.json`.
- **Emblema/sello/worm:** no se usan. No se debe usar el kit para sugerir aprobación de NASA.
- **Datos del juego:** los valores de la maqueta son de demostración, no mediciones en vivo.

## 6. Pendientes / siguientes pasos

- [ ] Revisar la maqueta en Safari/iOS y en un teléfono real.
- [ ] Añadir pruebas automáticas de contraste (WCAG AA) para las combinaciones de texto sobre panel.
- [ ] Decidir si la web del juego adopta los tokens 1:1 o mantiene `public/styles.css` y usa el kit solo para el pitch.
- [ ] Revisar con niños de 7–12 años si los stickers y el tono “fiesta” ayudan o distraen.
- [ ] Antes de una demo pública: confirmar que ninguna imagen muestra personas identificables en contexto promocional.
