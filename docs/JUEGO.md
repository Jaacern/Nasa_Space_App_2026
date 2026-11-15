# Juego: Junior Astronaut Mission Trainer

Diseño y plan de trabajo. Los datos y la API están en [DATOS.md](DATOS.md); el uso de IA, en [IA.md](IA.md).

## 1. Idea

**Outpost Run**: una partida es una misión de 30 soles (días marcianos o lunares). Cada sol eliges una mejora para tu base, y el clima espacial **real** de una fecha histórica sube la presión. Al terminar ves qué midió NASA en ese sitio y un hallazgo científico real relacionado con lo que viviste.

| Pide el desafío | Cómo lo cubre |
|---|---|
| Niños de 7 a 12 años | Partidas de 5 a 10 minutos, 3 recursos, texto corto, sin cuenta ni descarga |
| Ninguna decisión es gratis | Cada carta tiene beneficio, costo inmediato y costo diferido (`npm run check` lo exige) |
| Datos reales de NASA | Eventos DONKI, dosis RadLab, estudios OSDR, fotos y mapa de Marte |
| Consecuencias visibles | Tu blindaje se enfrenta a una tormenta real con fecha |
| Rejugabilidad | 4 escenarios históricos, semilla por partida, mazo aleatorio |
| Trazabilidad | Pantalla "De dónde vienen los datos" y atribución en cada dato |

### Qué se toma de *Risk of Rain 2* y *Megabonk*

Solo ideas de diseño. Arte, nombres, música y código son propios.

| Idea | En el juego |
|---|---|
| Reloj de dificultad que sube con el tiempo | La amenaza sigue la línea de tiempo real de eventos solares del escenario |
| Objetos que se apilan | Módulos apilables (paneles, blindaje, invernadero) cuyos costos también se acumulan |
| Evento de carga bajo presión | "Refugio de tormenta": preparar el blindaje antes de que llegue la partícula |
| Partidas cortas y repetibles | Si fallas, un informe con el dato real y reintento inmediato |
| Niveles de dificultad | Calma, Activo y Tormenta, derivados de los datos |

## 2. Mecánicas

### Recursos (solo tres)

| Recurso | Sube con | Baja con |
|---|---|---|
| **Energía** | Paneles solares | Todo lo demás; el polvo marciano |
| **Aire** | Reciclador de agua, invernadero | Tripulación, fugas |
| **Blindaje** | Muro de regolito | Mantenimiento: cuesta energía |

La **dosis de la tripulación** es la consecuencia, no un cuarto recurso: sube cuando una tormenta golpea con poco blindaje. La comida se modela como una carta (invernadero).

Cartas, constantes de equilibrio y glosario: [`content/cards.json`](../content/cards.json), [`content/balance.json`](../content/balance.json), [`content/glossary.json`](../content/glossary.json). **Todos esos números son valores de juego**, no datos NASA. Márquenlos así en la interfaz.

### De datos a eventos

| Evento DONKI | En la realidad (resumen) | Mecánica |
|---|---|---|
| Erupción solar (FLR) | Sus rayos X llegan en unos 8 minutos | Apagón de radio breve, casi sin aviso |
| Nube de plasma (CME) | Tarda horas o días en llegar | **Aviso**: `warningSols` da tiempo para reforzar |
| Protones (SEP) | Partículas rápidas que dañan | Peligro directo: usar el Refugio |
| Tormenta geomagnética (GST) | Afecta a la Tierra | Se corta el contacto con el control de misión |
| Choque interplanetario (IPS) | Llega la perturbación | Marca el golpe de un CME |

El sitio importa: un CME solo pega si DONKI lo marca para ese destino (`hitsSite`). Un casi-golpe también enseña.

### De datos a la base

- **Dosis base** = `baselinePerSolAtIss` × `siteProfile().doseMultiplierVsIss`: la radiación de fondo de la Luna o Marte sale de las mediciones reales de RadLab.
- **Retraso de radio:** Luna ~1,3 s; Marte de ~3 a ~22 minutos. "Preguntar al control de misión" responde tarde en Marte: quien no prepara el blindaje antes del aviso se queda sin ayuda a tiempo.
- **Clima de Marte:** temperatura, presión y viento de InSight (archivo de 2020) como condiciones del sitio.
- **Fotos reales** de Perseverance y Curiosity en la pantalla del sitio.

### Ciclo de una partida

1. Elegir sitio (Luna o Marte) y escenario.
2. Cada sol: ver el pronóstico, elegir 1 de 3 cartas y repartir la energía.
3. Si hay evento: reaccionar con el Refugio y ver la dosis resultante.
4. Final: **informe de misión** con la fecha real, el evento más fuerte, lo que midió NASA y un estudio OSDR.

### Para 7 a 12 años

Glosario en pantalla (*dosis*, *sol*, *CME*, *blindaje*); fallar no castiga; se puede pausar; texto corto e íconos claros; dos niveles de lectura (simple y con datos extra); sin cuenta.

## 3. Trabajo del equipo

La base técnica ya está: datos, API, saneado, pruebas. Falta el juego.

| Rol | Responsabilidad | Carpeta |
|---|---|---|
| Datos y procedencia | Pipeline, créditos, pantalla "De dónde vienen los datos" | `scripts/`, `src/api/`, `src/data/` |
| Sistemas de juego | Recursos, cartas, eventos, equilibrio | `src/sim/` (nueva), `content/` |
| Interfaz | Pantallas, móvil, glosario, accesibilidad | `src/ui/` (nueva), `public/` |
| Contenido | Textos infantiles, cartas, informe final; revisión de resúmenes de IA | `content/` |
| Coordinación | Tablero, pruebas con niños, video y pitch | |

Contratos entre roles: la API de [DATOS.md](DATOS.md), el formato de evento normalizado y `content/cards.json`. Cada quien edita solo su carpeta.

| Horas desde el inicio | Entregable |
|---|---|
| 0 a 4 | Acordar nombre, sitio principal y reglas; todos ejecutan `npm test` y `npm run api` |
| 4 a 14 | Bucle jugable: 30 soles, 3 recursos, 6 cartas, 1 escenario en Marte |
| 14 a 24 | Eventos reales conectados, informe final con dato OSDR, atribución en pantalla |
| 24 a 36 | Luna, tres escenarios, glosario, prueba con al menos un niño |
| 36 a 44 | Equilibrio, accesibilidad, móvil, mapa de Marte si hay tiempo |
| 44 a 48 | Última ingesta, congelar datos, video y pitch |

## 4. Lista para el jurado

- [ ] Funciona en el navegador sin cuenta ni descarga; una partida dura menos de 10 minutos.
- [ ] Ninguna decisión es gratuita.
- [ ] El jugador ve cómo su blindaje enfrentó una tormenta **real** con fecha.
- [ ] Pantalla "De dónde vienen los datos": fuentes, fecha de cada copia, "no es en vivo" y aviso de que NASA y la CSA no respaldan el proyecto.
- [ ] Lo simulado está marcado como simulado; los estudios OSDR indican el organismo.
- [ ] Una página corta explica qué dato se usó y por qué (la tabla de [DATOS.md](DATOS.md) sirve de base).

## 5. Riesgos

| Riesgo | Mitigación |
|---|---|
| Se cae la red en la demo | `data/curated/` dentro del repositorio |
| Un modelo inventa un dato | Revisión humana; `pickFact` oculta lo no revisado |
| Se confunde simulación con realidad | Etiquetas "dato real", "calculado", "simulado" en cada cifra |
| Demasiados sistemas para un niño | Máximo tres recursos |
| Un escenario resulta injusto | Probar cada uno con semilla fija y ajustar el costo del Refugio |
| Se copia demasiado de los juegos de referencia | Solo mecánicas generales; todo lo demás, propio |
| Una fuente cambia o desaparece | `manifest.json` avisa y se conserva el snapshot (ya pasó con Mars Rover Photos) |
