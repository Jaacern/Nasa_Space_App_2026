# Plan: juego de outpost con datos reales de NASA

Guía para el equipo. Cubre qué datos hay ya listos, cómo consumirlos, cómo se convierten en mecánicas de juego (con la inspiración de *Risk of Rain 2* y *Megabonk*), cómo usar IA para organizar el trabajo y qué entregar al jurado.

> Estado verificado el 14 de noviembre de 2026: `npm run ingest` descarga y normaliza DONKI, RadLab, OSDR y Mars Trek. `npm run demo` imprime un escenario real jugable. Los archivos ya están en `data/curated/`.

---

## 1. Idea en una frase

**Outpost Run**: una partida es una misión de 30 soles (días marcianos o lunares). Cada sol eliges una mejora para tu base, y el clima espacial **real** de una fecha histórica real sube la presión. Al terminar ves qué midió NASA en esa época y qué hallazgo científico real se relaciona con lo que viviste.

### Por qué encaja con el desafío

| Pide el desafío | Cómo lo cubre |
|---|---|
| Niños de 7 a 12 años | Partidas de 5 a 10 minutos, 3 recursos, texto corto, sin cuenta ni descarga |
| Decisiones sin opción "gratis" | Cada carta tiene beneficio, costo inmediato y costo diferido |
| Datos reales de NASA | Eventos DONKI reales, dosis RadLab reales, estudios OSDR reales, mapa Mars Trek |
| Consecuencias visibles | La carta de blindaje que elegiste se compara con la tormenta real de esa partida |
| Rejugabilidad | Escenarios históricos distintos, semilla por partida, mazo de cartas aleatorio |
| Trazabilidad | Pantalla "De dónde vienen los datos" y atribución en cada dato |

### Qué tomamos de los juegos de referencia

Se toman **ideas de diseño**, no arte, nombres, música ni código.

| Idea | En *Risk of Rain 2* / *Megabonk* (como referencia general) | En nuestro juego |
|---|---|---|
| Reloj de dificultad | La amenaza sube con el tiempo de la partida | La amenaza sube con la línea de tiempo real de eventos solares del escenario |
| Objetos que se acumulan | Mejoras que se apilan y crean combinaciones | Módulos que se apilan (paneles, blindaje, invernadero) con costos que también se acumulan |
| Evento de carga bajo presión | Aguantar mientras se carga un objetivo | "Refugio de tormenta": tiempo limitado para cargar el blindaje antes de que llegue la partícula |
| Partidas cortas y repetibles | Se pierde, se aprende, se reintenta | Si fallas, recibes un "informe de misión" con el dato real y un botón de reintento inmediato |
| Escalado por niveles | Niveles de dificultad | Escenarios Calma, Activo y Tormenta (los ids internos del dato usan `drizzle`, `rainstorm`, `monsoon`; en la interfaz usen nombres propios) |

---

## 2. Datos ya listos

Todo vive en `data/curated/`. El juego **solo lee estos archivos**.

| Archivo | Qué contiene | Fuente | Uso en el juego |
|---|---|---|---|
| `space_weather.json` | Eventos de los últimos 30 días: CME, erupciones, tormentas geomagnéticas, protones, choques | DONKI | Modo "semana real reciente" |
| `space_weather_scenarios.json` | 4 ventanas rejugables: semana reciente tranquila, sep. 2017, may. 2024, oct. 2024 | DONKI | Escenarios con dificultad |
| `radiation.json` | Dosis absorbida (μGy/h) por sitio: ISS, órbita lunar (LRO), Orion en Artemis I, órbita de Marte (Liulin-MO) | RadLab | Línea base de radiación del sitio |
| `osdr_facts.json` | Estudios reales por tema: hueso, músculo, inmunidad, radiación, plantas, sueño | OSDR | Datos curiosos al final y en eventos |
| `mars_layers.json` | Plantilla de teselas WMTS y metadatos de la capa MOLA de Marte | Mars Trek | Selector de sitio en el mapa |
| `apod.json` | Imagen astronómica del día (opcional) | NASA APOD | Pantalla de inicio |
| `manifest.json` | Estado de cada fuente en la última ingesta | Pipeline | Diagnóstico |

Cada archivo incluye `meta.retrievedAt` y `meta.mode: "snapshot"`. **No se debe presentar como "en vivo"**; el desafío pide ser honestos con esto.

### Lo que ya medimos (para no inventar números)

Valores de `radiation.json`, dosis absorbida mediana por sitio:

| Sitio | Mediana de medias (μGy/h) | Veces la ISS | Ventana |
|---|---:|---:|---|
| ISS, instrumento Lidal | 4,2 | 1,0 | 1-3 ene. 2023 |
| Órbita lunar, LRO CRaTER | 12,7 | 3,0 | 5-7 ene. 2019 |
| Orion, Artemis I | 17,2 | 4,1 | 20 nov. 2022 |
| Órbita de Marte, Liulin-MO | 15,2 | 3,6 | 1-3 jun. 2018 |

Lectura correcta: en el espacio profundo la dosis medida es varias veces la de la ISS. **No** es una comparación perfecta: cambian instrumento, año y fase del ciclo solar. Esos avisos viajan dentro del JSON (`caveats`) y deben mostrarse en la pantalla de créditos.

### Límites reales que descubrimos

| Hallazgo | Consecuencia |
|---|---|
| DONKI no envía cabecera CORS | El navegador no puede llamarlo directamente. Por eso usamos snapshots |
| El buscador OSDR solo permite CORS desde `osdr.nasa.gov` | Igual: snapshot |
| Las teselas de Mars Trek y `api.nasa.gov` sí permiten CORS (`*`) | El mapa puede cargarse directo desde el navegador |
| RadLab devuelve 504 sin ventana temporal | Siempre consultar con rango de fechas corto |
| RadLab no trae superficie lunar ni marciana, solo órbita o vuelo | Decirlo en pantalla: "medido en órbita" |
| `DEMO_KEY` mostró límite de 10 y APOD respondió 429 | Pedir clave propia; no depender de APOD |
| DONKI marca sus datos como experimentales | Mostrar aviso y usar `threat` solo como valor de juego |
| OSDR son mayormente ratones, ratas y plantas | `evidenceNote` obliga a no presentarlo como efecto exacto en astronautas |

---

## 3. Cómo traer y consumir los datos

### 3.1 Requisitos

- Node 22.9 o superior (ya instalado en esta máquina: 22.22).
- No hay dependencias que instalar.

### 3.2 Actualizar datos

```bash
npm run ingest                      # todo, últimos 30 días de DONKI
npm run ingest:donki                # solo DONKI y escenarios
node scripts/ingest.mjs --end=2026-11-01   # fijar fecha para que todo el equipo tenga lo mismo
node scripts/ingest.mjs --only=radlab,osdr
```

Si una fuente falla, **no se pisa el archivo anterior**: el juego sigue con el último snapshot bueno y `manifest.json` registra el error.

> Recomendación: ejecuten la ingesta por última vez justo antes de la demo y **suban `data/curated/` a Git**. Así el juego funciona aunque la red del evento falle.

Clave opcional para APOD:

```bash
cp .env.example .env     # pegar la clave nueva en NASA_API_KEY
```

La clave que se compartió en el chat debe considerarse expuesta; generen una nueva.

### 3.3 Probar sin abrir el juego

```bash
npm run demo                                  # escenario gannon-2024-05 en Marte
node scripts/demo.mjs oct-2024-x9 moon        # otro escenario y sitio
```

### 3.4 Usarlo desde el juego (navegador)

Sirvan la carpeta raíz con cualquier servidor estático, por ejemplo `python3 -m http.server 8080`, y carguen la capa de datos:

```js
import {
  browserReader, loadWorldState, getScenario, scheduleEvents,
  siteProfile, commDelaySec, pickFact, makeRng, attributionLines,
} from "./src/data/worldState.mjs";

const state = await loadWorldState(browserReader("./data/curated/"));

const run = {
  seed: 20260001,
  site: "mars",                       // "moon" | "mars"
  scenarioId: "gannon-2024-05",       // o "live"
};
const rng = makeRng(run.seed);                       // misma semilla = misma partida
const scenario = getScenario(state, run.scenarioId);
const schedule = scheduleEvents(scenario, run.site, { sols: 30, minThreat: 0.3 });
const profile = siteProfile(state, run.site);

// En cada sol del bucle de juego:
const today = schedule.filter((e) => e.sol === currentSol);
const delaySeconds = commDelaySec(run.site, currentSol);   // retraso de radio, un sentido
```

### 3.5 Referencia de la API de `src/data/worldState.mjs`

| Función | Para qué |
|---|---|
| `loadWorldState(read)` | Carga todos los JSON |
| `getScenario(state, id)` | `"live"` o un escenario archivado |
| `scheduleEvents(scenario, site, {sols, minThreat})` | Reparte eventos reales en sols. Añade `sol`, `hitsSite`, `arrivalSol`, `warningSols` |
| `siteProfile(state, site)` | Dosis base, múltiplo respecto a la ISS, retraso de radio y avisos |
| `commDelaySec(site, sol)` | Retraso de comunicación de un sentido |
| `pickFact(state, tema, rng)` | Estudio OSDR real; solo devuelve texto infantil si fue revisado por una persona |
| `makeRng(seed)` | Aleatorio con semilla para repetir partidas |
| `attributionLines(state)` | Créditos listos para la interfaz |

### 3.6 Mapa de Marte

`mars_layers.json` ya trae `tileUrlTemplate`. Usen OpenLayers o Leaflet con soporte de CRS personalizado. Puntos a cuidar:

- El CRS es `EPSG:104905` (Marte), no Web Mercator.
- El nivel 0 tiene 2 columnas y 1 fila.
- Si falta una tesela, es que no hay datos.
- Para el prototipo basta una imagen fija de la región más una capa de ejemplo; un mapa interactivo completo puede quedar para después.

### 3.7 Diccionario del evento normalizado

```json
{
  "id": "2024-05-10T...-FLR-001",
  "type": "FLR | CME | GST | SEP | IPS",
  "time": "2024-05-10T06:54Z",
  "threat": 0.85,
  "gameEffect": "warning | radio-blackout | comms | radiation",
  "label": { "es": "...", "en": "..." },
  "detail": { },
  "arrivals": { "earth": "ISO|null", "mars": "ISO|null" },
  "link": "https://ccmc.gsfc.nasa.gov/DONKI/view/..."
}
```

`threat` va de 0 a 1 y es **una heurística del equipo**, no una escala oficial. La regla está en `scripts/ingest.mjs` (funciones `flareThreat`, `normCME`, `normGST`).

---

## 4. De datos a mecánicas

### 4.1 Qué hace cada tipo de evento (todas son decisiones de juego basadas en cómo funciona cada fenómeno)

| Evento DONKI | Lo que pasa en la realidad (resumen) | Mecánica |
|---|---|---|
| Erupción solar (FLR) | Los rayos X llegan en unos 8 minutos | Apagón de radio breve, casi sin aviso |
| Nube de plasma (CME) | Tarda horas o días en llegar | **Aviso**: `warningSols` da tiempo para reforzar el blindaje |
| Protones (SEP) | Partículas rápidas que dañan | Peligro directo para la tripulación: hay que usar el Refugio |
| Tormenta geomagnética (GST) | Afecta a la Tierra | Interrupción de comunicaciones con el control de misión |
| Choque interplanetario (IPS) | Llegada de la perturbación | Marca el momento del golpe de un CME |

Regla pedagógica: **el sitio importa**. Un CME solo pega si DONKI lo marca para ese destino (`hitsSite`). Un "casi golpe" también enseña algo.

### 4.2 Recursos (solo tres, como recomienda el desafío)

| Recurso | Qué representa | Sube con | Baja con |
|---|---|---|---|
| **Energía** | Paneles, baterías | Paneles, reactor pequeño | Todo lo demás, y el polvo marciano |
| **Aire** | Oxígeno y agua reciclada | Reciclador, invernadero | Tripulación, fugas |
| **Blindaje** | Grosor de protección | Muro de regolito, agua | Hay que reforzarlo; cuesta energía y tiempo de construcción |

Una medida de consecuencia, no un cuarto recurso: **Dosis de la tripulación** (sube cuando una tormenta golpea con poco blindaje). La comida se modela como un tipo de carta (invernadero), no como otro medidor.

### 4.3 Cartas de mejora (valores iniciales, ajustables tras probar)

Los números son **valores de juego**, no datos NASA. Marquen en la interfaz cuáles son reales y cuáles simulados.

| Carta | Beneficio | Costo inmediato | Costo diferido |
|---|---|---|---|
| Panel solar extra | + Energía | Pasa tiempo construyéndolo | En Marte, el polvo lo degrada cada pocos soles |
| Muro de regolito | + Blindaje | − Energía de excavación | Hay que mantenerlo; no sirve contra todo |
| Invernadero | + Aire, + comida | − Energía constante | Si falla la energía, se pierde la cosecha |
| Reciclador de agua | + Aire estable | − Energía | Piezas que se desgastan |
| Antena potente | Contacto con la Tierra más rápido | − Energía | No cambia la velocidad de la luz: el retraso sigue |
| Refugio de tormenta | Reduce mucho la dosis durante un evento | − Espacio y energía | Solo ayuda si lo preparas antes |

Regla de diseño: **ninguna carta es siempre buena**. Para revisarlo, cada carta debe tener beneficio, costo inmediato y costo diferido.

### 4.4 Retraso de comunicación como mecánica

- Luna: unos 1,3 segundos. Casi inmediato.
- Marte: de unos 3 a unos 22 minutos en un sentido, según la distancia entre planetas (cálculo en `commDelaySec`).
- Jugable: el botón "Preguntar al control de misión" devuelve el consejo **tarde** en Marte. Quien no prepara el blindaje antes del aviso se queda sin ayuda a tiempo.

### 4.5 Ciclo de una partida

1. Elegir sitio (Luna o Marte) y escenario (Calma, Activo, Tormenta, o semana reciente).
2. Cada sol: ver el pronóstico del día, elegir 1 de 3 cartas y repartir la energía.
3. Si hay evento: reaccionar con el Refugio y ver la dosis resultante.
4. Cada pocos soles aparece una mejora mayor o un evento de la base.
5. Final: **informe de misión** con la fecha real, el evento más fuerte, lo que midió NASA en ese sitio y un estudio real de OSDR.

### 4.6 Diseño para 7 a 12 años

- Glosario en pantalla para *dosis*, *sol*, *CME*, *blindaje*.
- Fallar no castiga: se muestra qué decisión fue clave y cómo reintentar.
- Sin tiempo real estresante: se puede pausar.
- Texto corto, íconos claros, sin cuenta.
- Modo dos niveles: simple para 7 a 9 y datos extra para 10 a 12 y familias.

---

## 5. Orquestación con IA

La IA se usa en tres capas, y **el juego funciona sin ninguna de ellas en ejecución**.

### Capa A. Contenido educativo en tiempo de construcción

El campo `kidSummary` de cada estudio de `osdr_facts.json` empieza vacío (`reviewedByHuman: false`).

1. Un modelo de IA redacta un resumen para niños a partir del título y la descripción original, siguiendo `docs/ia/PROMPTS.md`.
2. Un script o una segunda pasada comprueba reglas: longitud, sin números nuevos, mención del organismo.
3. **Una persona del equipo revisa** y marca `reviewedByHuman: true`.
4. El juego solo muestra el texto si fue revisado (`pickFact` ya lo exige).

Así evitamos que un modelo invente ciencia delante de niños.

### Capa B. Agentes para desarrollar el proyecto

Cada agente tiene su carpeta y un contrato. Así no se pisan.

| Agente | Responsable de | Entrega | No debe tocar |
|---|---|---|---|
| **Datos** | `scripts/`, `data/`, `src/data/` | Snapshots válidos, `manifest.json` sin errores | La lógica del juego |
| **Sistemas** | Simulación y balance (`src/sim/`) | Reglas de cartas, recursos y eventos, con pruebas de equilibrio | Los JSON de datos |
| **Contenido** | `content/` y textos | Cartas, glosario, resúmenes infantiles | El código de simulación |
| **Interfaz** | `src/ui/` | Pantallas, accesibilidad, móvil | Constantes de balance |
| **QA y procedencia** | `docs/` y pruebas | Lista de cada número mostrado con su fuente | Código de producción |

Contratos entre ellos: la API de `worldState.mjs`, el formato del evento normalizado (sección 3.7) y un archivo `content/cards.json` con beneficio, costo inmediato y costo diferido.

Flujo sugerido:

1. Una persona actúa de coordinadora y mantiene un tablero de tareas.
2. Cada tarea se asigna con el contrato, los archivos permitidos y un criterio de aceptación verificable.
3. El agente trabaja en su rama y abre cambios pequeños.
4. El agente de QA revisa que ningún número en pantalla carezca de fuente, y que no haya carta "gratis".
5. Una persona humana aprueba antes de mezclar.

### Capa C. Dentro del juego (opcional)

- **Recomendado para el desafío:** narración con plantillas y variantes generadas de antemano, elegidas con la semilla. Funciona sin red y sin riesgos con menores.
- **No recomendado para el prototipo:** un modelo conversando en vivo con niños. Si lo quieren después, debe ir detrás de un servidor propio, con filtro de contenido y con una versión sin IA como respaldo.

---

## 6. Reparto y calendario

Se asume un equipo de 4 o 5 personas. Ajusten los nombres.

| Rol | Responsabilidad principal |
|---|---|
| Datos y procedencia | Pipeline, atribución, página "De dónde vienen los datos" |
| Sistemas de juego | Recursos, cartas, eventos, balance |
| Interfaz | Pantallas, móvil, glosario, accesibilidad |
| Contenido y narrativa | Textos infantiles, cartas, informe final, revisión de resúmenes IA |
| Coordinación y demo | Tablero, video, pitch, pruebas con niños |

Calendario en horas desde el inicio del hackatón (ajustar según las horas reales):

| Tramo | Entregable |
|---|---|
| 0 a 4 h | Acordar la historia de usuario, nombre y reglas básicas. Todos ejecutan `npm run demo` |
| 4 a 14 h | Bucle jugable mínimo: 30 sols, 3 recursos, 6 cartas, 1 escenario en Marte |
| 14 a 24 h | Eventos reales conectados, informe final con dato OSDR, atribución en pantalla |
| 24 a 36 h | Segundo sitio (Luna), tres escenarios, glosario, prueba con al menos un niño del entorno |
| 36 a 44 h | Balance, accesibilidad, móvil, mapa de Marte si hay tiempo |
| 44 a 48 h | Congelar datos con una última ingesta, video corto, pitch |

---

## 7. Lista para el jurado

- [ ] Funciona en el navegador sin cuenta ni descarga.
- [ ] Una partida completa en menos de 10 minutos.
- [ ] Ninguna decisión es gratuita.
- [ ] Un jugador puede ver cómo su blindaje enfrentó una tormenta **real** con fecha.
- [ ] Pantalla "De dónde vienen los datos" con DONKI, RadLab, OSDR y Mars Trek, la fecha de la copia y la aclaración "no es en vivo".
- [ ] Aviso de que NASA y CSA no respaldan el proyecto.
- [ ] Lo simulado está marcado como simulado.
- [ ] Estudios OSDR con el organismo (ratones, plantas) y sin afirmar que es un efecto exacto en astronautas.
- [ ] Una página corta que explica qué dato se usó y por qué.

Sobre la CSA: usen el kit de producción de alimentos como inspiración de la carta "Invernadero" y enlácenlo en los créditos. No copien textos ni imágenes sin revisar su licencia.

---

## 8. Riesgos y qué hacer

| Riesgo | Mitigación |
|---|---|
| Se cae la red en la demo | Datos en `data/curated/` dentro del repositorio |
| Un modelo inventa un dato | Revisión humana obligatoria; `pickFact` oculta lo no revisado |
| Se confunde simulación con realidad | Etiquetas "dato real", "calculado", "simulado" en cada cifra |
| Demasiados sistemas para un niño | Máximo tres recursos; el resto se resume en el informe final |
| El escenario "Tormenta" es injusto | Probar cada escenario con la semilla de pruebas y ajustar el costo del Refugio |
| Se copia demasiado de los juegos de referencia | Solo mecánicas generales; arte, nombres y sonidos propios |
| Una fuente cambia su formato | `manifest.json` avisa del error y se conserva el snapshot anterior |

---

## 9. Próximos pasos inmediatos

1. Cada integrante ejecuta `npm run demo` y lee `data/curated/manifest.json`.
2. Decidir nombre del juego y sitio principal (se recomienda Marte para aprovechar el retraso de comunicación; la Luna sirve como tutorial).
3. Crear `content/cards.json` con las seis cartas de la sección 4.3.
4. Implementar el bucle mínimo de 30 sols usando `scheduleEvents`.
5. Pedir un resumen infantil por estudio con `docs/ia/PROMPTS.md` y revisar cada uno.
6. Crear una clave NASA nueva y retirar la que se compartió en el chat.
