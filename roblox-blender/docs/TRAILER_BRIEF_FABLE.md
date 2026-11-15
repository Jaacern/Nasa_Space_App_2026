# Brief de producción: tráiler E3 (para Fable)

Estado: **preparado, no ejecutado.** Se produce cuando el juego esté completo. Guion base: [`TRAILER.md`](TRAILER.md) (55 s). Este brief lo amplía a un tráiler de 60 s con estilo de presentación E3.

## 1. Objetivo

- Video de 60 s (rango 55 a 65 s), 1920×1080, 30 FPS, para el pitch de 3 minutos.
- Estilo: tráiler de feria de videojuegos (E3): ritmo rápido, cortes secos, títulos grandes, tipografía con peso, cierre con logotipo del juego.
- Ilustrar los conceptos del juego: supervivencia en Marte, gravedad baja, ataque automático, hordas, mejoras, jefes y datos reales de la NASA como mecánica.
- Idioma: español en textos. Voz en off opcional.

## 2. Referencias de diseño (solo principios, sin material)

- *Megabonk* y *Risk of Rain 2*: partidas de ritmo rápido, siluetas claras, color saturado, objetos que se acumulan, teleporter y jefes.
- Prohibido copiar assets, música, logotipos o capturas de esos juegos.

## 3. Reglas legales (obligatorias)

- **Sin logotipo de NASA** (insignia, logotipo "worm" ni sello). Según la política de NASA, su uso requiere permiso explícito y no puede sugerir respaldo. Fuente: [NASA Brand Center](https://www.nasa.gov/nasa-brand-center/nasa-logo-use/).
- **Imágenes de NASA:** solo de fuentes oficiales (NASA Images API, NASA Science, Mars Trek, DONKI). Citar la fuente en pantalla y en créditos. No insinuar respaldo. Ver [Images and Media](https://www.nasa.gov/nasa-brand-center/images-and-media/).
- **Sin logotipo de Space Apps ni de CSA** sin permiso escrito. Revisar la licencia CSA antes de usar cualquiera de sus recursos.
- **Aviso visible** en el cierre: "No patrocinado por NASA ni CSA. Usa datos públicos de NASA." (ya definido en `CLAUDE.md`).
- **Imágenes generadas con IA** (Flow u otra herramienta): rotular como "ilustración generada". Nunca presentarlas como fotografía o dato real.
- **Música y SFX:** solo propios o con licencia verificada (`P-12` en `DECISIONES.md`).
- **Tipografías:** solo Google Fonts con licencia abierta o fuentes con licencia comercial confirmada.

## 4. Fuentes de material

| Fuente | Uso | Obligación |
|---|---|---|
| Captura de Studio (juego real) | Gameplay principal | Ninguna, es propio |
| Renders de Blender (28 mallas) | Planos de personajes y enemigos | Ninguna, es propio |
| NASA Images / Mars Trek / DONKI | Marte, Sol, mapas, datos | Crédito a NASA |
| Google Flow (opcional) | Planos de ambientación o transiciones | Rótulo "generado", presupuesto máximo 600 créditos, confirmar cada lote |
| Agent Reach (investigación) | Buscar materiales oficiales y verificar licencias | Registrar URL y fecha de cada asset |

Todo asset queda registrado en `docs/assets/` con URL, fecha, licencia y uso.

## 5. Guion

Usar el plano a plano de [`TRAILER.md`](TRAILER.md) como base. Ampliar a 60 s con:
- Un plano de título con fuerza (estilo E3) en los primeros 3 s.
- Un plano de jefe con nombre en pantalla.
- Cierre con logotipo propio del juego, fecha de lanzamiento de concurso y aviso legal.

## 6. Producción

1. **Storyboard:** Fable escribe planos y textos. DeepSeek puede redactar variantes de titulares (encargo acotado, verificado por Fable).
2. **Capturas:** Studio con el juego completo. Requiere el MCP `Roblox_Studio` operativo o capturas manuales.
3. **Composición:** skill `hyperframes` (HTML a video) para títulos, transiciones y créditos. Render final a MP4.
4. **Audio:** capa de música y SFX propios; voz en off si aplica.
5. **QA:** checklist de legalidad (sección 3), duración 55 a 65 s, sin texto cortado, legible en 1080p.

## 7. Puntos de control con el usuario

- Aprobar guion y lista de assets antes de generar nada.
- Aprobar cada lote de Flow antes de gastar créditos.
- Aprobar el corte final.

## 8. Pendientes que bloquean la producción

- Juego completo (`P-08`, fases F1 a F5).
- MCP de Roblox Studio conectado (hoy falla con timeout).
- Música propia (`P-12`).
- Confirmación de reglas y fecha del concurso (`P-14`).
- Cuenta de Google Flow con sesión iniciada en el Chrome del usuario (no la puedo iniciar yo).
