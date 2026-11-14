# NASA Space Apps 2026: juego de outpost con datos reales

Prototipo educativo para niños de 7 a 12 años: gestionar una base lunar o marciana con clima espacial, radiación y estudios reales de NASA.

## Empezar (5 minutos)

Requiere Node 22.9 o superior. No hay dependencias que instalar.

```bash
npm test               # 15 pruebas sin red
npm run validate       # revisa cartas, balance y procedencia de los datos
npm run demo           # muestra un escenario real jugable en consola
npm run api            # API local en http://127.0.0.1:8787  (abre / para ver los endpoints)
```

Para traer datos nuevos o comprobar las fuentes en vivo (necesita tu clave en `.env`):

```bash
cp .env.example .env   # y pega tu NASA_API_KEY nueva
npm run check:apis     # prueba las 6 fuentes en vivo
npm run ingest         # regenera data/curated/
```

## Leer en este orden

1. [Plan del juego y de los datos](docs/PLAN-JUEGO-Y-DATOS.md): idea, mecánicas, uso de los datos, IA, calendario.
2. [API local y saneado](docs/API-LOCAL.md): cómo pedir datos desde el juego, endpoints y seguridad.
3. [Pendientes manuales](docs/PENDIENTES-MANUALES.md): lo que solo una persona puede hacer.
4. [Prompts de IA](docs/ia/PROMPTS.md): resúmenes infantiles, narración y revisiones.
5. [Investigación de fuentes](docs/investigacion-recursos-nasa-csa.md): qué ofrece cada recurso NASA y CSA, con límites.

## Estructura

| Ruta | Contenido |
|---|---|
| `server/api.mjs` | API local que sirve datos ya saneados |
| `src/api/` | Saneado, contratos y adaptadores por fuente |
| `src/data/worldState.mjs` | Capa de datos para el juego (calendario de eventos, perfil del sitio) |
| `scripts/ingest.mjs` | Descarga y guarda snapshots en `data/curated/` |
| `scripts/check-apis.mjs` | Prueba de las fuentes en vivo |
| `data/curated/` | Snapshots JSON con fecha de copia |
| `content/` | Cartas, constantes de equilibrio y glosario (valores de juego) |
| `public/` | Página de arranque de prueba |
| `test/` | Pruebas y ejemplos de respuestas (incluida una "hostil") |

## Estado actual

- Datos reales descargados y probados: DONKI, RadLab, OSDR, Mars Trek, InSight.
- Pendiente: el bucle del juego y la interfaz. Los datos y la API ya están listos para empezar.
- Pendiente con clave NASA propia: `asteroids.json` y `apod.json` (la `DEMO_KEY` se agotó en las pruebas).

## Seguridad

No subas claves. `.env` está ignorado por Git y el servidor nunca devuelve la clave.

NASA y CSA no patrocinan ni respaldan este proyecto.
