# Subir el tráiler y entregar el proyecto (Space Apps 2026)

Cierre: **domingo 15-11-2026, 23:59 hora local del evento.** Sin envío antes de esa hora, el proyecto no se juzga.

Equipo **Code or die** (Concepción, Chile): Gonzalo Maldonado, Javier Cerna y Cristóbal Palma.

## Archivos (en el Escritorio)

| Archivo | Para qué |
|---|---|
| `ARES_FORGE_Trailer_4K60.mp4` | **El que se sube a YouTube.** 3840×2160, 60 fps. YouTube da más bitrate a los envíos 4K |
| `ARES_FORGE_Trailer_1080p60.mp4` | Respaldo (Drive, proyector) |

Ambos duran 29,9 s (la regla es "30 segundos o menos"). Montaje v4 en Remotion: `video-core/src/ares/Trailer.tsx` (repositorio DEEPSEEK editor); acabado en 2 pasadas con `trailer/finish_remotion.py`.

> **Ojo con la marca de IA.** La guía de envío pide marca visible en imágenes y videos hechos con IA. Por decisión del equipo, las dos tomas de Google Flow (caída inicial y despegue final) ya no llevan rótulo en pantalla; la IA se declara en la tarjeta final, en la descripción de YouTube y en los metadatos del archivo. Si se quiere eliminar el riesgo, se puede volver a poner una marca pequeña en esas dos tomas (cambio de una línea en `Trailer.tsx`).

## 1. Subir a YouTube

1. Abre https://studio.youtube.com y revisa (foto de perfil, arriba a la derecha) que estás en la cuenta correcta.
2. **Crear → Subir videos** → `ARES_FORGE_Trailer_4K60.mp4`.
3. **Título:** `ARES FORGE | 30-second demo | Team Code or die | NASA Space Apps 2026`
4. **Descripción** (copiar tal cual):

```
ARES FORGE is a Mars survival roguelite we built for the NASA Space Apps Challenge 2026 (challenge: Space Mission Design Game).

Your ship crashes in Jezero Crater. To get home you fight through waves of enemies, beat four bosses and recover four parts of your ship. Each part is real spacecraft hardware: an MMRTG nuclear battery, a high-gain antenna, the MOXIE oxygen generator and an Orion engine, and each one is based on a NASA Technical Reports Server document.

Every upgrade card you pick shows a short, real fact about Mars missions, and space-weather and astrophysics events (NASA CCMC DONKI, InSight, Chandra) turn up as hazards during a run. The idea is that you pick up the science while you're busy playing.

It runs on PC, mobile, tablet and gamepad, in several languages, and we're getting it ready for Roblox.

Team Code or die, from Concepción, Chile: Gonzalo Maldonado, Javier Cerna and Cristóbal Palma.

We made the game in Roblox Studio and Blender, and every gameplay shot in this video was recorded in the game. The opening crash and the closing liftoff were generated with Google Flow from one of our own screenshots, and the music was made with Google Flow Music.

This project uses public NASA data. NASA does not sponsor or endorse it.
```

5. **Público:** "No, no es contenido creado para niños".
6. **Contenido alterado o sintético:** marcar **Sí** (hay tomas generadas con IA que parecen reales). Es la opción honesta y no afecta la visibilidad.
7. **Visibilidad: No listado** → **Guardar**.
8. Espera el procesado HD/4K (unos minutos; el enlace funciona antes en menor calidad).
9. **Prueba el enlace en una ventana de incógnito.** Debe reproducirse sin iniciar sesión.

## 2. Entregar en spaceappschallenge.org

1. Inicia sesión → foto de perfil → **My Team** → pestaña **Project** → **Edit** (activa el **Lock**).
2. **Link to Project Demo:** el enlace de YouTube.
3. **Link to Final Project:** `https://github.com/Jaacern/Nasa_Space_App_2026` (público).
4. **Descripción del proyecto** (si la piden; copiar y ajustar):

```
We wanted to make a game where learning about space missions happens on the way, not in a quiz at the end. ARES FORGE drops you on Mars after a crash. You survive waves, level up, and every upgrade card carries a real fact from NASA missions. Four bosses each guard one part of your ship (MMRTG, high-gain antenna, MOXIE, Orion engine), and each part comes with a short explanation taken from a NASA Technical Reports Server document. Real space-weather and astrophysics events from NASA CCMC DONKI, InSight and Chandra show up in the run as hazards.

It's built in Roblox Studio with low-poly models we made in Blender, and it plays on PC, phones, tablets and gamepads in several languages.

Team Code or die (Concepción, Chile): Gonzalo Maldonado, Javier Cerna and Cristóbal Palma.
```

5. **Use of Super Intelligence (SI):** Google Flow (dos tomas del tráiler y la música), asistentes de IA usados en el código, la documentación y las traducciones del juego.
6. **NASA Data:** CCMC DONKI (clima espacial), NTRS (fichas 20150005587, 20040084278, 20205007222, 20240003648), science.nasa.gov (datos de las cartas), InSight y Chandra (eventos).
7. **Save Progress** → marca **Terms and Conditions** y **Confirm All Work is Original** → **Submit for Judging**. Debe aparecer un banner de confirmación.

## 3. Revisión final

- [ ] El video dura 0:29–0:30 en YouTube.
- [ ] El enlace abre en incógnito.
- [ ] No aparece el logotipo de NASA en ningún plano.
- [ ] Los tres integrantes están confirmados en el mismo evento local.
- [ ] Banner de confirmación visto tras **Submit for Judging**.

## Limpieza opcional

En el canal "Bronzalito Gonzalo" quedó un borrador privado sin publicar de un primer intento de subida. Para borrarlo: YouTube Studio de ese canal → Contenido → ⋮ del video → Borrar definitivamente.
