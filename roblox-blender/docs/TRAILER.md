# Guion del tráiler (55 segundos)

Fecha: 14-11-2026. Estado: guion escrito. No hay material grabado.
Duración objetivo: 55 s (rango permitido: 45 a 60 s). Formato: 1920×1080, 30 FPS.
Todas las tomas se graban en Studio con el juego real. No se usan imágenes de otros juegos. No se usa el logotipo de NASA.

## 1. Plano a plano

| Plano | Tiempo | Qué se ve | Cámara | Audio | Texto en pantalla |
|---|---|---|---|---|---|
| 1 | 0:00 a 0:05 | Negro. Un destello cian. Aparece la nave estrellada en la arena de Marte, con polvo | Órbita lenta alrededor de la nave (la del menú) | Silencio, luego un tono grave | "Tu nave cayó." |
| 2 | 0:05 a 0:09 | El héroe en traje de astronauta camina por el regolito. Salto alto por la gravedad baja | Tercera persona, cámara detrás | Pasos y viento | "Gravedad de Marte: 0,38 g" |
| 3 | 0:09 a 0:15 | Primeras oleadas: remolinos de polvo rodean al héroe. El láser dispara solo. Números de daño | Tercera persona, cerrada | Entra el pulso rítmico de la música (capa de combate) | "El láser dispara solo. Tú te mueves." |
| 4 | 0:15 a 0:20 | Círculo naranja en el suelo. El héroe usa el Impulso RCS y lo esquiva | Tercera persona, plano corto. Cámara lenta breve | Sonido de aviso y de impulso | "Cada ataque avisa." |
| 5 | 0:20 a 0:26 | Subida de nivel: aparecen las 3 cartas con rareza. Se elige una épica | Plano de interfaz, a pantalla completa | Sonido de nivel | "Elige 1 de 3." |
| 6 | 0:26 a 0:33 | Horda grande de 80 a 100 enemigos. El Pulso de escudo y los drones orbitales limpian a la vez | Cámara más alta y abierta | Música a máxima intensidad | "Más de 100 enemigos a la vez" `[PENDIENTE: verificar con la medición P-05]` |
| 7 | 0:33 a 0:39 | Aparece el jefe: barra de vida, el nombre "TORMENTA DE POLVO GLOBAL". Línea naranja de carga | Plano bajo, el jefe ocupa el cuadro | Capa de jefe en la música | "4 jefes" |
| 8 | 0:39 a 0:44 | Panel "Pieza recuperada: Batería nuclear (MMRTG)" y la pieza que encaja en la nave | Interfaz y plano de la nave | Sonido de pieza (provisional) | "Cada jefe suelta una pieza real de una nave." |
| 9 | 0:44 a 0:48 | Bioma 3 con la alerta "ALERTA DE CLIMA ESPACIAL" y la fecha de un evento real | Plano de interfaz sobre el cielo naranja | Sirena suave | "Clima espacial real. Datos públicos de NASA." |
| 10 | 0:48 a 0:53 | La nave despega entre polvo y luz | Plano fijo con paneo hacia arriba | Subida de música, luego silencio | "Vuelve a casa." |
| 11 | 0:53 a 0:55 | Tarjeta final sobre fondo oscuro | Fija | Silencio | Ver sección 2 |

## 2. Tarjeta final

Texto, en este orden:

```
ARES FORGE
Supervivencia en superficie
NASA International Space Apps Challenge 2026
Este proyecto usa datos públicos de NASA.
NASA no patrocina ni respalda este producto.
```

Fuente del título: Michroma. Fuente del resto: Titillium Web. Fondo `#070B14`. Acento `#00D2FF`. No pongas el logotipo ni la insignia de NASA.

## 3. Reglas del tráiler

- Solo se usa material grabado del juego, sin retoques que no existan en el juego.
- Los textos no dicen "según NASA". El plano 9 dice "Datos públicos de NASA".
- No muestres rostros de astronautas reales.
- No pongas cifras de la antena ni del generador de oxígeno.
- El texto "Más de 100 enemigos a la vez" se queda fuera si la medición P-05 no lo confirma. Alternativa: "Hordas de cientos de peligros" no es verificable; usa "Hordas cada vez más grandes".

## 4. Lista de tomas por grabar

| Toma | Cómo se consigue | Atajo de `docs/NOTAS.md` |
|---|---|---|
| Plano 1 | Menú, sin tocar nada | Ninguno |
| Planos 2 a 4 | Demo rápida, primeros 40 s | Ninguno |
| Plano 5 | Subir de nivel | `xp` |
| Plano 6 | Minuto 12 de misión | `time` 720 |
| Plano 7 | Primer jefe | `time` 240 |
| Plano 8 | Vencer al jefe 1 | `bosshp` |
| Plano 9 | Bioma 3 | `time` 720 y esperar la alerta |
| Plano 10 | Final de la demo | `time` 1020, `bosshp` |

## 5. Pendientes

- Música definitiva y sonidos propios (P-12). El tráiler no se publica con el audio provisional.
- Mallas de Blender para héroe y jefes (P-09). El arte actual es provisional.
- Revisar el tráiler contra la lista de reglas de contenido NASA (prompt maestro, sección 13.5).
