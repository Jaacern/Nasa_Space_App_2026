# Junior Astronaut Mission Trainer

NASA Space Apps 2026. Juego para niños de 7 a 12 años: gestionar una base lunar o marciana (energía, aire, blindaje) con clima espacial, radiación y ciencia reales de NASA y la CSA.

## Empezar

Requiere Node 22.9 o superior. No hay dependencias que instalar.

```bash
npm test            # 23 pruebas, sin red
npm run check       # contenido del juego, snapshots y relevancia de los datos
npm run api         # API local en http://127.0.0.1:8787 (abre / para ver el catálogo)
```

## Leer en este orden

1. [docs/JUEGO.md](docs/JUEGO.md): idea, mecánicas, reparto del equipo, calendario, lista para el jurado.
2. [docs/DATOS.md](docs/DATOS.md): cada recurso de la pestaña Resources, cómo consumirlo, límites y saneado.
3. [docs/IA.md](docs/IA.md): dónde se usa IA, prompts y revisión humana.

## Estructura

| Ruta | Contenido |
|---|---|
| `src/api/` | Catálogo de fuentes, saneado, contratos y adaptadores |
| `src/data/worldState.mjs` | Capa de datos del juego: calendario de eventos, perfil del sitio, datos curiosos |
| `server/api.mjs` | API local que sirve los datos ya saneados |
| `scripts/` | `ingest.mjs` (descarga snapshots) y `check.mjs` (comprobaciones) |
| `data/curated/` | Snapshots reales con fecha de copia: el juego funciona sin red |
| `content/` | Cartas, constantes de equilibrio y glosario (valores de juego, no datos NASA) |
| `public/` | Página de prueba que lee la API |
| `ui-ux/` | Kit de diseño ORBITAL UI: tokens, componentes, assets y demo en `/ui-ux/` |
| `test/` | Pruebas y respuestas reales guardadas |

## Pendiente (solo una persona puede hacerlo)

- [ ] **Clave NASA nueva.** La que se pegó en el chat está expuesta. Pide otra en <https://api.nasa.gov/>, ponla en `.env` (`cp .env.example .env`) y ejecuta `npm run check:live`. Solo la necesitan APOD e InSight.
- [ ] **Primer commit.** Nada está commiteado. Revisa que `git status` no muestre `.env`.
- [ ] **APOD:** la API devolvió `500` y una vez el logo de NASA como imagen. No hay snapshot; es decorativo, reintentar o descartar.
- [ ] **Pestaña Resources y reglas del evento:** no tengo acceso. Revisar si añadieron recursos y qué exigen sobre declarar el uso de IA.
- [ ] **Elegir sitio y capas en Mars Trek** explorando <https://trek.nasa.gov/mars/> (es una aplicación web que no pude leer).
- [ ] **Revisar los estudios OSDR elegidos** y los resúmenes infantiles (`reviewedByHuman`). Hoy hay 26 pendientes y el juego los oculta.
- [ ] **Confirmar con una fuente NASA** las afirmaciones físicas de `content/balance.json` (noche lunar, tormentas de polvo) antes de decirlas como hechos.
- [ ] **Probar el juego en un navegador real** (CORS y teselas se verificaron solo con Node) y con niños de 7 a 12 años.
- [ ] **Antes de la demo:** `npm run ingest`, `npm run check`, commit de `data/curated/`.

## Seguridad

No subas claves. `.env` está ignorado por Git y el servidor nunca devuelve la clave.

NASA y la CSA no patrocinan ni respaldan este proyecto.
