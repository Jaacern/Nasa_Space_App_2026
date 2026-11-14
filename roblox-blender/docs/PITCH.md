# Pitch de 3 minutos

Fecha: 14-11-2026. Estado: borrador. Sin ensayar.
Desafío: "Space Mission Design Game". `[PENDIENTE]` confirmar el texto oficial del desafío y ajustar el discurso a sus criterios.
Equipo: 3 personas, sede Concepción, Chile.
Ritmo de lectura: unas 130 palabras por minuto. El texto tiene unas 400 palabras.

## 1. Estructura

| Tramo | Tiempo | Contenido |
|---|---|---|
| Gancho | 0:00 a 0:25 | Una imagen y una pregunta |
| Demo | 0:25 a 2:00 | El juego en vivo (`docs/DEMO_GUION.md`) |
| Rigor científico | 2:00 a 2:40 | Qué es real y qué es de diseño |
| Cierre | 2:40 a 3:00 | Resumen y llamada a probar |

La demo ocupa el tramo central. El guion de la demo de 3 minutos tiene más detalle que el que cabe aquí. En el pitch se muestra solo un recorte de 1:35 (menú, subida de nivel, jefe, pieza y alerta de clima espacial).

## 2. Texto

### Gancho (0:00 a 0:25)

> Imaginen que su nave cae en Marte. Les quedan 18 minutos de supervivencia y cuatro piezas que recuperar para volver a casa.
>
> Somos un equipo de tres personas de Concepción, Chile. Hicimos ARES FORGE: un juego de supervivencia en tercera persona, hecho en Roblox, donde cada pieza que recuperas es un sistema real de una nave espacial.

### Demo (0:25 a 2:00)

Habla una persona mientras otra juega. Frases cortas, una por acción. Guía: `docs/DEMO_GUION.md`, sección 3.

> Esta es la demo rápida. El láser dispara solo. Yo me muevo y esquivo.
>
> Los círculos naranjas avisan antes de cada golpe. Siempre hay una señal.
>
> Al subir de nivel elijo una de tres mejoras. Cada carta tiene rareza.
>
> Este jefe suelta la primera pieza: una batería nuclear, un generador que convierte el calor de un material radiactivo en electricidad. Aquí el juego explica cómo funciona de verdad.
>
> Cambiamos de bioma. Ahora hay una alerta de clima espacial. Esa alerta se basa en un evento solar real, con su fecha.

### Rigor científico (2:00 a 2:40)

> Queremos que el juego enseñe sin mentir. Por eso separamos tres cosas.
>
> Primero, lo que es dato: el clima espacial viene de la base de datos pública DONKI, una copia guardada el 14 de noviembre de 2026. Las alertas muestran eventos reales con su fecha.
>
> Segundo, lo que es referencia: la batería nuclear y el propulsor de retorno tienen una ficha del servidor de informes técnicos de NASA, verificada por el equipo. Las piezas que aún no tienen ficha verificada no llevan cifras.
>
> Tercero, lo que es diseño: el daño, la velocidad y las recompensas son del juego. Lo decimos en pantalla.
>
> El juego no necesita internet para mostrar estos datos. Funciona con la copia local, y dice claramente que es una copia.

### Cierre (2:40 a 3:00)

> ARES FORGE combina lo que más nos gusta: un juego rápido y un contenido técnico que se puede verificar. Cuatro jefes, cuatro piezas, tres biomas y un despegue.
>
> Los invitamos a probarlo. Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto.
>
> Gracias.

## 3. Cómo responde al desafío

`[PENDIENTE]` Confirmar el enunciado oficial. Esta es la lectura del equipo, que se debe contrastar:

- **Diseño de misión.** El jugador recorre una misión con fases: oleadas numeradas, minijefes, jefe final y despegue.
- **Sistemas de nave.** Cada jefe entrega un sistema (energía, comunicaciones, oxígeno y propulsión) con su explicación.
- **Entorno real.** El clima espacial de DONKI entra en la telemetría y en las alertas.
- **Juego.** Es un juego completo y jugable, con progresión entre partidas.

## 4. Reglas de lenguaje

- No digas "según NASA". Di "datos públicos de NASA" o "fuente: DONKI, 14-11-2026".
- No digas "aprobado por NASA", "oficial" ni "con la colaboración de NASA".
- No afirmes cifras de la antena ni del generador de oxígeno (P-06).
- No afirmes rendimiento medido (60 FPS, 100 enemigos) hasta tener la medición (P-05).
- No uses el logotipo ni la insignia de NASA.
- Si preguntan por algo no verificado, di: "Está pendiente de verificar".

## 5. Preguntas probables y respuestas

| Pregunta | Respuesta |
|---|---|
| ¿Los datos de clima espacial son en vivo? | No. Son una copia local del 14-11-2026 con la etiqueta "snapshot". La llamada en vivo exige un proxy del equipo y está pendiente |
| ¿Qué es real y qué es inventado? | Real: los eventos de DONKI y las dos fichas NTRS. Diseño: el daño, la dificultad y los nombres de los enemigos |
| ¿Se copia de otro juego? | Tomamos mecánicas de género (oleadas, cartas de mejora, jefes). No copiamos nombres, arte ni sonidos. Las referencias están en `docs/REFERENCIAS.md` |
| ¿Funciona en móvil? | Está diseñado para PC y móvil. La prueba en móvil real está pendiente |
| ¿Cómo hicieron los modelos? | Con scripts de Blender y un puente propio auditado. En esta versión el arte es provisional |
| ¿Se guarda el progreso? | Sí, con DataStore de Roblox. La verificación en el lugar publicado está pendiente |

## 6. Ensayos

| Ensayo | Fecha | Duración | Observaciones |
|---|---|---|---|
| 1 | `[PENDIENTE]` | | |
| 2 | `[PENDIENTE]` | | |
| 3 | `[PENDIENTE]` | | |
