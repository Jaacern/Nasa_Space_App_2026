# Lo que requiere trabajo manual

Todo lo que se podía automatizar ya está automatizado y probado. Esto es lo que **solo una persona puede hacer**, por qué, y cómo.

Estado del 14 de noviembre de 2026. Marca cada casilla cuando se haga.

## Qué ya NO necesita trabajo manual

Probado hoy con `npm run check:apis` (6 de 6 fuentes respondieron y pasaron el saneado):

| Fuente | Acceso | Estado |
|---|---|---|
| DONKI (clima espacial) | Sin clave | Automático, en vivo y en snapshot |
| RadLab (radiación) | Sin clave | Automático (siempre con rango de fechas) |
| OSDR (estudios) | Sin clave | Automático |
| Mars Trek (capas WMTS) | Sin clave | Automático |
| NeoWs (asteroides) | Clave NASA | Automático con clave |
| InSight (clima de Marte) | Clave NASA | Automático con clave; ya hay snapshot |

## 1. Imprescindible antes de programar

- [ ] **Crear una clave NASA nueva.** La que se pegó en el chat está expuesta.
  - Cómo: pide una en <https://api.nasa.gov/>, cópiala a `.env` (`cp .env.example .env`) como `NASA_API_KEY=...`.
  - Por qué es manual: la clave es personal y no debe pasar por ningún chat.
  - Después ejecuta: `npm run check:apis` y `npm run ingest -- --only=neo,insight,apod`.
  - Motivo concreto: hoy la prueba con `DEMO_KEY` se agotó (HTTP 429) y por eso `asteroids.json` y `apod.json` no se regeneraron. `mars_weather.json` sí existe, creado a partir de una respuesta real guardada del mismo día.
- [ ] **Decidir el nombre del juego y la tecnología del frontend.** Recomendación: HTML + JavaScript con módulos ES, sin compilador, porque la capa de datos ya es ES modules.
- [ ] **Hacer el primer commit y subir el repositorio.** Nada está commiteado todavía. Revisa antes que `git status` no muestre `.env`.

## 2. Verificaciones que no pude hacer yo

- [ ] **Revisar la pestaña Resources del desafío.** El enunciado dice que pueden añadirse recursos antes del hackatón. No tengo acceso a esa página.
- [ ] **Leer las reglas del evento sobre uso de IA y atribución.** No las verifiqué. Si exigen declarar el uso de IA, usen el registro `docs/ia/REGISTRO.md` (se describe en `docs/ia/PROMPTS.md`).
- [ ] **Leer "Notices and copyright" de la CSA.** La página enlazada desde `https://www.asc-csa.gc.ca/eng/about/` no pude abrirla. Hasta que alguien la lea, solo se enlaza a la CSA, no se copian textos ni imágenes.
- [ ] **Probar en un navegador real.** Verifiqué CORS leyendo cabeceras con Node, no desde una página web. Cuando exista la primera pantalla, abrir la consola del navegador y comprobar que `/api/...` y las teselas de Mars Trek cargan.
- [ ] **Verificar las afirmaciones físicas de `content/balance.json`.** Ejemplo: el ciclo largo de noche lunar y la frecuencia de tormentas de polvo en Marte son valores de juego. Antes de decirlos en pantalla como hechos, confírmenlos con una fuente de NASA.

## 3. Decisiones de contenido

- [ ] **Elegir a mano los estudios OSDR que se usarán** (2 o 3 por tema). El buscador devuelve coincidencias de texto: por ejemplo, para "radiación" salió OSD-72 (microbiota de ratón), que encaja flojo.
- [ ] **Revisar los resúmenes infantiles.** La IA los redacta con `docs/ia/PROMPTS.md`, pero una persona debe leerlos y poner `reviewedByHuman: true`. Hoy hay 26 estudios pendientes y el juego los oculta.
- [ ] **Elegir el sitio marciano y las capas.** Mars Trek es una aplicación web interactiva que no pude leer. Explórenla en <https://trek.nasa.gov/mars/>, elijan una región y anoten la capa y las coordenadas. Después se añade la capa a `scripts/ingest.mjs` (lista `MARS_LAYERS`).
- [ ] **Escribir y revisar los textos del juego** (cartas, glosario, informe final). `content/glossary.json` es un borrador.

## 4. Antes de la demo

- [ ] **Última ingesta y commit de `data/curated/`.** Así el juego funciona aunque falle la red del evento: `npm run ingest`, luego `npm run validate`, luego commit.
- [ ] **Probar con niños de 7 a 12 años** (aunque sea uno o dos). Es la única forma de saber si el texto y las reglas se entienden.
- [ ] **Escribir la página "De dónde vienen los datos"** con las fuentes, las fechas de cada copia y el aviso de que NASA y la CSA no respaldan el proyecto. `attributionLines()` ya genera las líneas.
- [ ] **Grabar el video y preparar el pitch.**

## Orden sugerido

1. Clave nueva y primer commit (15 minutos).
2. Una persona abre la pestaña Resources y las reglas de IA (15 minutos).
3. Alguien explora Mars Trek y propone el sitio (30 minutos).
4. Mientras tanto, el resto empieza el bucle de juego con `npm run api` y los datos actuales.
