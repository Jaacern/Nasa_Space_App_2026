# Tráiler de ARES FORGE (demo oficial de 30 s)

**Entregable vigente (v4, 15-11-2026 noche):** `ARES_FORGE_Trailer_4K60.mp4` (YouTube) y `ARES_FORGE_Trailer_1080p60.mp4`, 29,9 s a 60 fps (`1794` cuadros). Montaje en Remotion: copia en [`remotion/Trailer.tsx`](remotion/Trailer.tsx) (se renderiza desde `video-core/src/ares/` del repositorio DEEPSEEK editor, composición `AresTrailer`, medios en `public/ares/`). Acabado (`loudnorm` 2 pasadas lineal −14,05 LUFS / −1,60 dBTP, 4K, metadatos, copia al Escritorio): `python -B finish_remotion.py <render>`. Cómo subir y entregar: [`SUBIR_Y_ENTREGAR.md`](SUBIR_Y_ENTREGAR.md).

Qué cambió en la v4:
- **Encuadre intacto de HUD (`safe`)**: escala `1.0` sin recorte ni sacudidas en los 9 planos con UI del juego (`loop`, `cards`, `boss`, `m1..m4`, `parts`, `data`).
- **Inicios limpios y velocidad controlada**: `title.mp4` entra directo en la órbita limpia (`trimBefore={62}`) con scrim radial detrás del título; `cards.mp4` inicia en las cartas (`trimBefore={28}`, `playbackRate=0.54`) para no volver al combate; `phone.mp4` entra en combate limpio (`trimBefore={24}`) en marco horizontal `1736×864` sin recortar el HUD táctil ni chocar con la nota a mano.
- **Rótulos y transiciones equilibradas**: paneles ortogonales a 60 fps reales con respaldo oscuro, etiqueta mono completa sin truncar, `TopScrim` en etiquetas superiores, `HudPanel` inferior en el despegue para despejar el cohete, micro-barridos luminosos (`Streak`) y destellos calibrados sobre los golpes medidos de `mix.wav`, más 2 líneas legales de mayor legibilidad en la tarjeta final.

Versión v3 guardada como `*_v3.mp4` y v2 (ffmpeg, `render_master.py`) como `*_v2.mp4` en esta carpeta.

Versión anterior (reemplazada por la de 60 fps): `ARES_FORGE_trailer_30s_1080p.mp4`, de `render_trailer.py`.
Especificación medida el 15-11-2026: 30,000 s (900 cuadros), 1920×1080, 30 fps, H.264 High, AAC 48 kHz estéreo, −13,1 LUFS integrado, pico −1,0 dBTP, sin cuadros negros.

## Reglas que cumple (Project Submission Guide 2026, leída el 15-11-2026)

- Video de **30 s o menos** (si se excede, el proyecto no es elegible para juicio global).
- Todo en inglés. Abre con el equipo (0:00), el desafío (0:02), título y lema (0:05), cómo funciona con datos NASA (0:10–0:20) y visión de futuro (0:20–0:30).
- Contenido generado con IA marcado con rótulo visible `AI-GENERATED · GOOGLE FLOW`. La música IA se declara en la tarjeta final y en los metadatos del MP4 (`comment`).
- Sin logotipos ni insignia de NASA: la insignia del menú se oculta en las tomas (`HideInsignia`). Aviso de no patrocinio en la tarjeta final.
- Sin personas menores ni rostros reales.

## Plano a plano

| Tiempo | Toma | Origen | Rótulo |
|---|---|---|---|
| 0:00–0:05.5 | Aterrizaje forzoso | IA (Google Flow, Omni 1.2 Flash) | TEAM CODE OR DIE · CHALLENGE: SPACE MISSION DESIGN GAME |
| 0:05.5–0:08.5 | Órbita a la nave | Juego (cámara `orbit`) | ARES FORGE (entra con el golpe musical) |
| 0:08.5–0:11 | Combate | Juego | HOW IT PLAYS |
| 0:11–0:13.5 | Cartas con REAL FACT | Juego | EVERY UPGRADE CARD SHOWS A REAL NASA FACT |
| 0:13.5–0:16 | Coloso (jefe) | Juego (cámara `boss`) | 4 BOSSES GUARD 4 REAL SPACECRAFT SYSTEMS |
| 0:16–0:18.5 | Panel MMRTG | Juego | NTRS: MMRTG · HIGH-GAIN ANTENNA · MOXIE · ORION ENGINE |
| 0:18.5–0:21 | Evento bólido (CNEOS) | Juego | NASA DONKI + INSIGHT + CHANDRA |
| 0:21–0:23 | Juego en iPhone XR | Studio Device Simulator | PC · MOBILE · GAMEPAD — ENGLISH & SPANISH |
| 0:23–0:25.5 | Despegue | IA (Google Flow, cuadro inicial = captura del juego) | THE FUTURE |
| 0:25.5–0:30 | Tarjeta final | Gráfica propia | Equipo, desafío, aviso NASA, declaración IA |

## Cómo se rehace

1. Grabar en Studio (pantalla completa, paneles cerrados) con los atributos de `game/src/client/Autopilot.luau`: `Autopilot`, `CineCam`, `CleanCapture`, `HideHud`, `HideInsignia`. Captura con `ffmpeg -f gdigrab` de la región del visor (1536×864) a `raw/`.
2. Medios IA en `ai/` (Flow: 2 clips × 24 créditos = 48; Flow Music: 1 pista de 3:01, se usan 97,8–123,6 s y 169,8–174,3 s).
3. `python -B make_titles.py gfx` y `python -B render_trailer.py`.

## Créditos usados

- Google Flow (video): 48 de 700 autorizados. Flow Music: 1 generación.
