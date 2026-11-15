# NASA Space Apps 2026: Outpost Run + ARES FORGE

Repositorio del equipo con dos módulos complementarios bajo un mismo techo:

1. **Raíz (`Outpost Run`)**: capa de datos, ingesta, saneado, servidor local (`127.0.0.1:8787`) y contenidos del prototipo educativo (7 a 12 años) basado en datos reales de NASA y recursos de la CSA. Falta implementar el bucle de juego (`src/sim/`) y la interfaz web (`src/ui/`).
2. **[`roblox-blender/`](roblox-blender/README.md) (`ARES FORGE`)**: juego roguelite de supervivencia 3D jugable en Roblox Studio (Luau `--!strict`), con 28 mallas exportadas desde Blender y puente MCP local propio.

> Este proyecto usa datos públicos de NASA y recursos educativos de la CSA. NASA y CSA no patrocinan ni respaldan este producto.

## Empezar con la capa Node (Outpost Run)

Requiere Node `22.9` o superior. No hay dependencias externas que instalar.

```bash
npm test               # 23 pruebas sin red
npm run check          # valida cartas, balance, glosario, catálogo y snapshots
npm run api            # API local en http://127.0.0.1:8787 (abre / para ver endpoints)
```

Para actualizar snapshots o comprobar las fuentes en vivo (configura `.env` si usarás `APOD` o `InSight`):

```bash
cp .env.example .env   # y pega tu NASA_API_KEY nueva
npm run check:live     # valida snapshots y prueba las fuentes en vivo
npm run ingest         # regenera data/curated/ y manifest.json
```

Para arrancar el juego de Roblox (**ARES FORGE**), sigue [`roblox-blender/README.md`](roblox-blender/README.md) y [`roblox-blender/game/README.md`](roblox-blender/game/README.md).

## Leer en este orden

1. [Plan del juego y de los datos](docs/PLAN-JUEGO-Y-DATOS.md): idea, mecánicas, uso de datos, IA y cronograma.
2. [API local y saneado](docs/API-LOCAL.md): endpoints reales, modo `live=1` vs `snapshot` y seguridad.
3. [Pendientes manuales](docs/PENDIENTES-MANUALES.md): checklist consolidado de pendientes de `Outpost Run` y `ARES FORGE`.
4. [Prompts de IA](docs/ia/PROMPTS.md) y [Registro de IA](docs/ia/REGISTRO.md): resúmenes infantiles, QA y trazabilidad.
5. [Investigación de fuentes](docs/investigacion-recursos-nasa-csa.md): alcance, CORS y términos de NASA y CSA.

## Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `server/api.mjs` | API local (`127.0.0.1:8787`) que sirve datos ya saneados y estáticos |
| `src/api/` | Catálogo de 8 fuentes, saneado, contratos y adaptadores por fuente |
| `src/data/worldState.mjs` | Capa de datos para el juego (calendario de eventos, perfil del sitio, atribución) |
| `scripts/ingest.mjs` | Descarga y guarda los snapshots en `data/curated/` |
| `scripts/check.mjs` | Comprueba contenido, snapshots (`npm run check`) y fuentes en vivo (`--live`) |
| `data/curated/` | Snapshots JSON fechados y `manifest.json` de la última ingesta |
| `content/` | Cartas (`cards.json`), constantes de equilibrio (`balance.json`) y glosario (`glossary.json`) |
| `public/` | Página mínima de prueba de conectividad con la API |
| `test/` | 23 pruebas unitarias e integración con fixtures locales |
| `roblox-blender/` | Subproyecto `ARES FORGE` en Roblox Studio + Blender + puente MCP |

## Estado actual (auditado el 14-11-2026)

- **Fuentes ingesta OK (`data/curated/manifest.json`):** DONKI (`104` eventos + `4` escenarios), RadLab (`4` sitios), OSDR (`26` estudios), Mars Trek (`1` capa WMTS), Rover Photos (`6` fotos vía `mars.nasa.gov`), InSight (`7` sols, archivo congelado de 2020) y CSA (`64` enlaces educativos).
- **APOD:** la última ingesta devolvió `HTTP 500` sin clave válida; `data/curated/apod.json` queda en estado provisional (`reusable: false`) hasta ejecutar `npm run ingest -- --only=apod` con `NASA_API_KEY`.
- **OSDR:** `26` estudios pendientes de resumen infantil con `reviewedByHuman: true` (el juego los oculta mientras no se revisen).
- **Pendiente principal (`Outpost Run`):** implementar el bucle jugable (`src/sim/`) y la interfaz web (`src/ui/`) en reemplazo del stub `public/index.html`.
- **Pendiente principal (`ARES FORGE`):** ver P-01 a P-15 en [`roblox-blender/docs/DECISIONES.md`](roblox-blender/docs/DECISIONES.md) y el resumen en [`docs/PENDIENTES-MANUALES.md`](docs/PENDIENTES-MANUALES.md).

## Seguridad y licencias

- No subas claves ni rutas personales. `.env` está ignorado por Git y el servidor nunca devuelve `NASA_API_KEY`.
- Licencia general pendiente de definir por el equipo (`.claude/skills/` dentro de `roblox-blender/` usa licencia MIT).

NASA y CSA no patrocinan ni respaldan este proyecto.
