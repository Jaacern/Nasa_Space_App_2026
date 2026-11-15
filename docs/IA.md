# Uso de IA en el proyecto

La IA está permitida por el desafío. Regla del equipo: **la IA redacta y revisa, una persona decide**. Nada generado se muestra a niños sin revisión, y el juego funciona sin ninguna IA en ejecución.

## Dónde se usa

**A. Contenido educativo (antes de jugar).** El campo `kidSummary` de cada estudio de `data/curated/osdr_facts.json` empieza vacío (`reviewedByHuman: false`).
1. Un modelo redacta el resumen con el prompt 1.
2. Controles automáticos: longitud, ningún número que no esté en el texto original, mención del organismo.
3. Una persona lo revisa y pone `reviewedByHuman: true`. Solo entonces `pickFact` lo muestra.

**B. Desarrollo del proyecto.** Cada agente o persona tiene su carpeta y un contrato.

| Agente | Responsable de | No debe tocar |
|---|---|---|
| Datos | `scripts/`, `src/api/`, `src/data/`, `data/` | La lógica del juego |
| Sistemas | `src/sim/` y el equilibrio | Los JSON de `data/` |
| Contenido | `content/` y los textos | El código de simulación |
| Interfaz | `src/ui/`, `public/` | Las constantes de equilibrio |
| Calidad | `test/`, `npm run check` | Código de producción |

Flujo: el coordinador asigna cada tarea con el contrato, las carpetas permitidas y un criterio verificable (`npm test` y `npm run check` en verde); el agente trabaja en su rama con cambios pequeños; una persona aprueba antes de mezclar.

**C. En ejecución (opcional).** Narración del control de misión con **frases generadas de antemano** y elegidas con la semilla: funciona sin red y sin riesgo con menores. No se recomienda un modelo conversando en vivo con niños en el prototipo.

## Prompts

Reglas comunes, para pegar al inicio de cada prompt:

```text
Eres editor de ciencia para niños de 7 a 12 años.
- Usa solo la información que te doy. No añadas cifras, fechas ni nombres que no estén en el texto.
- Si el texto no basta para afirmar algo, di que no lo sabes.
- Lenguaje sencillo, frases cortas. Si usas un término técnico, explícalo en la misma frase.
- Si el estudio es en ratones, ratas, plantas o células, dilo claramente. Nunca digas que le pasa igual a los astronautas.
- Responde únicamente con JSON válido que cumpla el esquema.
```

**1. Resumen infantil de un estudio OSDR** (entrada: un objeto de `osdr_facts.json` con `title`, `organism`, `mission`, `summaryOriginal`, `evidenceNote`):

```text
[Reglas comunes]
Estudio: {{objeto JSON del estudio}}
Devuelve: {
  "accession": "OSD-xxx",
  "es": "máximo 2 frases, 35 palabras",
  "en": "max 2 sentences, 35 words",
  "subject": "con qué o con quién se hizo (por ejemplo: ratones)",
  "askMeLater": "pregunta de curiosidad, máximo 12 palabras",
  "unknowns": ["lo que el texto no permite afirmar"]
}
```
Después de revisar, copia `es` y `en` a `kidSummary` y marca `reviewedByHuman: true`.

**2. Frases del control de misión** (se generan antes de jugar):

```text
[Reglas comunes]
Escribe 5 variantes de aviso del control de misión. Tono calmado, sin dramatizar, máximo 20 palabras cada una.
Tipo de evento: {{CME | FLR | SEP | GST}}. Qué significa (no lo cambies): {{descripción corta}}.
Aviso disponible: {{sí, con N soles | no}}.
Devuelve: { "eventType": "...", "lines": [{ "es": "...", "en": "..." }] }
```

**3. Revisor de procedencia:**

```text
Te doy el texto de una pantalla del juego y la lista de fuentes permitidas (archivos de data/curated/ con su meta).
Para cada cifra o afirmación indica: "fuente" (archivo y campo, "simulado" si es un valor de juego, o "SIN FUENTE") y "riesgo" de confundirse con un dato real.
Marca como problema toda cifra SIN FUENTE y todo valor simulado que no esté etiquetado. Responde con una tabla.
```

**4. Revisor de equilibrio de cartas:**

```text
Te doy cartas con beneficio, costo inmediato y costo diferido. Busca: cartas sin costo real; cartas estrictamente mejores que otra;
combinaciones que anulen todos los costos; costos tan altos que nadie elegiría la carta. Propón un ajuste por problema y qué hecho real del
programa espacial ilustra la carta.
```

## Registro

Anota en `docs/IA-REGISTRO.md` (créalo al usarlo) qué modelo se usó, con qué prompt y quién revisó cada texto. Sirve al jurado y para corregir errores. Si el evento exige declarar el uso de IA, de ahí sale la declaración.
