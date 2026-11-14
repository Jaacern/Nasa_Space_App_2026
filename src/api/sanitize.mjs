/**
 * Utilidades de saneamiento para TODO lo que viene de fuera (APIs de NASA).
 * Principio: el resto del proyecto nunca ve la respuesta cruda; solo objetos que pasaron por aquí.
 * Módulo ESM sin dependencias.
 */

const SECRET_PARAM = /([?&;]|^)(api_key|apikey|key|token|access_token)=[^&\s"']*/gi;

/** Oculta claves en cualquier texto (URLs, mensajes de error). Incluye el valor real de NASA_API_KEY. */
export function redact(text) {
  let s = String(text ?? "").replace(SECRET_PARAM, "$1$2=***");
  const secret = globalThis.process?.env?.NASA_API_KEY;
  if (secret && secret.length >= 8) s = s.split(secret).join("***");
  return s;
}

/** Texto plano: sin etiquetas HTML, sin caracteres de control, espacios colapsados, longitud limitada. */
export function cleanText(value, max = 300) {
  if (value == null) return "";
  let s = String(value)
    .replace(/<[^>]*>/g, " ")
    .replace(/[\u0000-\u001F\u007F-\u009F]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  s = redact(s);
  return s.length > max ? s.slice(0, max - 1).trimEnd() + "…" : s;
}

/** Número válido o null. Rechaza (null) valores fuera de rango en lugar de recortarlos. */
export function num(value, { min = -Infinity, max = Infinity, digits } = {}) {
  if (value == null || value === "" || typeof value === "boolean") return null;
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n) || n < min || n > max) return null;
  return digits == null ? n : Number(n.toFixed(digits));
}

/** Fecha YYYY-MM-DD real o null. */
export function isoDate(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const d = new Date(value + "T00:00:00Z");
  return Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== value ? null : value;
}

/** Marca de tiempo ISO simple (acepta "2026-11-01T00:00Z" o con segundos) o null. */
export function isoTime(value) {
  if (typeof value !== "string") return null;
  return /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?(\.\d+)?Z?$/.test(value) ? value : null;
}

const DEFAULT_HOSTS = [/(^|\.)nasa\.gov$/i];

/**
 * URL segura: https, host permitido, sin parámetros secretos. http se convierte a https.
 * Devuelve null si no pasa.
 */
export function safeUrl(value, hosts = DEFAULT_HOSTS) {
  try {
    const u = new URL(String(value));
    if (!["http:", "https:"].includes(u.protocol)) return null;
    if (!hosts.some((re) => re.test(u.hostname))) return null;
    u.protocol = "https:";
    for (const k of [...u.searchParams.keys()]) {
      if (/^(api_key|apikey|key|token|access_token)$/i.test(k)) u.searchParams.delete(k);
    }
    // Algunas URLs (p. ej. JPL) llevan parámetros dentro del fragmento "#/?a=1&api_key=...".
    const secret = "(?:api_key|apikey|key|token|access_token)";
    u.hash = u.hash
      .replace(new RegExp(`\\?${secret}=[^&]*&?`, "gi"), "?")
      .replace(new RegExp(`&${secret}=[^&]*`, "gi"), "")
      .replace(/[?&]$/, "");
    return u.toString();
  } catch {
    return null;
  }
}

/**
 * Validador de contrato mínimo. Esquemas:
 *   "string" | "number" | "boolean" | "string?" | "number?" (admite null)
 *   ["array", esquemaDeItem]
 *   { campo: esquema }  (objeto; campos extra permitidos, pero campos requeridos deben existir)
 * Devuelve la lista de problemas ([] = válido).
 */
export function validate(value, schema, path = "$") {
  const problems = [];
  if (typeof schema === "string") {
    const nullable = schema.endsWith("?");
    const type = nullable ? schema.slice(0, -1) : schema;
    if (value == null) {
      if (!nullable) problems.push(`${path}: falta (se esperaba ${type})`);
    } else if (typeof value !== type || (type === "number" && !Number.isFinite(value))) {
      problems.push(`${path}: tipo inválido (se esperaba ${type})`);
    }
    return problems;
  }
  if (Array.isArray(schema)) {
    if (!Array.isArray(value)) return [`${path}: se esperaba un arreglo`];
    value.forEach((v, i) => problems.push(...validate(v, schema[1], `${path}[${i}]`)));
    return problems;
  }
  if (value == null || typeof value !== "object") return [`${path}: se esperaba un objeto`];
  for (const [k, s] of Object.entries(schema)) problems.push(...validate(value[k], s, `${path}.${k}`));
  return problems;
}

/** Lanza si el objeto no cumple el contrato. Evita servir datos mal formados. */
export function assertValid(value, schema, label) {
  const problems = validate(value, schema);
  if (problems.length) throw new Error(`${label}: contrato roto -> ${problems.slice(0, 5).join("; ")}`);
  return value;
}

/** Revisa que un objeto serializado no contenga claves ni parámetros secretos. */
export function findSecretLeaks(obj) {
  const text = JSON.stringify(obj);
  const leaks = [];
  if (/(api_key|apikey|access_token)=(?!\*\*\*)[^&"\s]+/i.test(text)) leaks.push("parámetro de clave en el JSON");
  const secret = globalThis.process?.env?.NASA_API_KEY;
  if (secret && secret.length >= 8 && text.includes(secret)) leaks.push("valor de NASA_API_KEY en el JSON");
  if (/DEMO_KEY/.test(text)) leaks.push("DEMO_KEY en el JSON");
  return leaks;
}
