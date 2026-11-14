# Prompts para IA

Plantillas para usar con cualquier modelo. Regla general: **la IA redacta, una persona decide**. Nada generado se muestra a niños sin revisión.

## Reglas comunes (pégalas al inicio de cada prompt)

```text
Eres editor de ciencia para niños de 7 a 12 años.
- Usa solo la información que te doy. No añadas cifras, fechas ni nombres que no estén en el texto.
- Si el texto no basta para afirmar algo, di que no lo sabes.
- Lenguaje sencillo, frases cortas, sin jerga. Si usas un término técnico, explícalo en la misma frase.
- Si el estudio es en ratones, ratas, plantas o células, dilo claramente.
  Nunca digas que le pasa igual a los astronautas.
- Responde únicamente con JSON válido que cumpla el esquema.
```

## 1. Resumen infantil de un estudio OSDR

Entrada: un objeto de `data/curated/osdr_facts.json` (`title`, `organism`, `mission`, `summaryOriginal`, `evidenceNote`).

```text
[Reglas comunes]

Tarea: escribe un resumen para niños del estudio siguiente.

Estudio:
{{pega aquí el objeto JSON del estudio}}

Devuelve este JSON:
{
  "accession": "OSD-xxx",
  "es": "máximo 2 frases, máximo 35 palabras",
  "en": "max 2 sentences, max 35 words",
  "subject": "con qué o con quién se hizo (por ejemplo: ratones)",
  "askMeLater": "una pregunta de curiosidad para el niño, máximo 12 palabras",
  "unknowns": ["lo que el texto no permite afirmar"]
}
```

Controles automáticos recomendados antes de la revisión humana:

- No aparece ningún número que no esté en el texto original.
- `subject` coincide con `organism` o `material`.
- Longitud dentro del límite.
- Sin las palabras "los astronautas sufren" salvo que el estudio sea en humanos.

Después de revisar, copia `es` y `en` a `kidSummary` y pon `reviewedByHuman: true`.

## 2. Frases de narración del control de misión

Se generan **antes** de jugar y se eligen con la semilla. No hay IA en ejecución.

```text
[Reglas comunes]

Tarea: escribe 5 variantes de aviso del control de misión para este tipo de evento.
Tono: calmado, amable, sin dramatizar. Máximo 20 palabras cada una.

Tipo de evento: {{CME | FLR | SEP | GST}}
Qué significa (no cambies esto): {{descripción corta del evento}}
Aviso disponible: {{sí, con N soles de anticipación | no}}

Devuelve:
{
  "eventType": "...",
  "lines": [{ "es": "...", "en": "..." }]
}
```

## 3. Revisor de procedencia (QA)

```text
Eres revisor de calidad. Te doy el texto de una pantalla del juego y la lista de fuentes
permitidas (archivos de data/curated/ con su campo meta).

Para cada cifra o afirmación del texto indica:
- "fuente": el archivo y campo del que sale, o "simulado" si es un valor de juego, o "SIN FUENTE".
- "riesgo": si podría confundirse con un dato real.

Marca como problema cualquier cifra "SIN FUENTE" y cualquier valor simulado que no esté
etiquetado como simulado. Responde con una tabla.
```

## 4. Revisor de equilibrio de cartas

```text
Te doy una lista de cartas con: beneficio, costo inmediato y costo diferido.
Busca:
1. Cartas sin costo real.
2. Cartas estrictamente mejores que otra.
3. Combinaciones de dos cartas que anulen todos los costos.
4. Costos tan altos que nadie elegiría la carta.
Propón un ajuste por cada problema y explica qué hecho real del programa espacial
ilustra la carta.
```

## Registro

Anota en `docs/ia/REGISTRO.md` qué modelo se usó, qué prompt y quién revisó cada texto. Es útil para el jurado y para corregir errores.
