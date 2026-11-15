--!strict
-- Copia local (snapshot) de datos publicos de NASA. El cliente nunca llama a NASA.
-- Contrato de datos: source, sourceUrl, retrievedAt, mode, attribution, dataKind.
-- Origen: data/curated/space_weather.json del repositorio del equipo (scripts/ingest.mjs).

local NasaData = {}

NasaData.SpaceWeather = {
	source = "NASA CCMC DONKI",
	sourceUrl = "https://ccmc.gsfc.nasa.gov/DONKI/",
	retrievedAt = "2026-11-14T14:40:15Z",
	mode = "snapshot",
	attribution = "Datos publicos de NASA CCMC DONKI. Informacion experimental de investigacion; la fuente oficial de pronosticos es NOAA SWPC.",
	dataKind = "space-weather-events",
	windowStart = "2026-10-15",
	windowEnd = "2026-11-14",
	counts = { CME = 88, FLR = 13, GST = 1, SEP = 0, IPS = 2 },
	-- Eventos reales usados como avisos dentro del juego. power es una heuristica de juego (0 a 1).
	events = {
		{ kind = "FLR", date = "05-11-2026", label = "Erupción solar clase M3.5", power = 0.9, link = "https://ccmc.gsfc.nasa.gov/DONKI/view/FLR/49391/-1" },
		{ kind = "FLR", date = "07-11-2026", label = "Erupción solar clase M1.9", power = 0.6, link = "https://ccmc.gsfc.nasa.gov/DONKI/view/FLR/49448/-1" },
		{ kind = "FLR", date = "11-11-2026", label = "Erupción solar clase M1.7", power = 0.55, link = "https://ccmc.gsfc.nasa.gov/DONKI/view/FLR/49504/-1" },
		{ kind = "FLR", date = "19-10-2026", label = "Erupción solar clase M1.6", power = 0.5, link = "https://ccmc.gsfc.nasa.gov/DONKI/view/FLR/49165/-1" },
		{ kind = "GST", date = "31-10-2026", label = "Tormenta geomagnética G2 (Kp 6)", power = 0.7, link = "https://ccmc.gsfc.nasa.gov/DONKI/view/GST/49348/-1" },
		{ kind = "CME", date = "17-10-2026", label = "Nube de plasma solar (CME) a 1048 km/s", power = 0.8, link = "https://ccmc.gsfc.nasa.gov/DONKI/view/CME/49150/-1" },
		{ kind = "IPS", date = "20-10-2026", label = "Llegada de un choque interplanetario", power = 0.4, link = "https://ccmc.gsfc.nasa.gov/DONKI/view/IPS/49181/-1" },
	},
}

-- Catalogo curado de observaciones reales de agujeros negros (NASA Chandra / NuSTAR / EHT).
NasaData.BlackHoleEvents = {
	{
		id = "sgra",
		title = "ANOMALÍA GRAVITACIONAL · SAGITTARIUS A*",
		sub = "EHT + NASA Chandra · Centro galáctico a ~26 000 años luz · ~4 millones de masas solares",
		fact = "Imagen EHT (mayo 2022) y rayos X de Chandra: gas caliente orbitando el horizonte de sucesos de Sgr A*.",
		tint = { 255, 165, 85 },
	},
	{
		id = "m87",
		title = "CHORRO RELATIVISTA · M87*",
		sub = "EHT + NASA Chandra · Galaxia M87 (~55 M años luz) · ~6 500 millones de masas solares",
		fact = "M87* expulsa un chorro de partículas a miles de años luz observado en rayos X por NASA Chandra.",
		tint = { 130, 210, 255 },
	},
	{
		id = "cygx1",
		title = "DISCO DE ACRECIÓN · CYGNUS X-1",
		sub = "NASA Chandra / NuSTAR · Binaria de rayos X · Lente gravitacional sobre el horizonte",
		fact = "Observatorios de rayos X de NASA miden el gas supercaliente que cae en espiral hacia el agujero negro.",
		tint = { 210, 145, 255 },
	},
}

NasaData.MeteorEvents = {
	{
		title = "LLUVIA DE METEOROS · DETECCIÓN SÍSMICA",
		sub = "NASA InSight (SEIS) + MRO HiRISE · Impactos en Elysium Planitia",
		fact = "El 05-09-2021 NASA InSight registró ondas sísmicas y acústicas de un meteoroide fragmentado en Marte.",
	},
	{
		title = "ENTRADA ATMOSFÉRICA · BÓLIDO ACTIVO",
		sub = "NASA JPL CNEOS · Monitoreo de bólidos y fragmentación atmosférica",
		fact = "CNEOS de NASA/JPL analiza bólidos e impactos para modelar cómo se fragmentan meteoroides al entrar.",
	},
}

-- Lineas para la telemetria del HUD. Solo hechos presentes en el snapshot.
function NasaData.tickerLines(): { string }
	local sw = NasaData.SpaceWeather
	local lines = {
		string.format("DONKI %s a %s: %d erupciones solares registradas", sw.windowStart, sw.windowEnd, sw.counts.FLR),
		string.format("DONKI: %d nubes de plasma (CME) en 30 días", sw.counts.CME),
		string.format("DONKI: %d tormenta geomagnética en 30 días", sw.counts.GST),
		"EHT + NASA Chandra: Sagittarius A* (~4 M masas solares, 26 000 años luz)",
		"NASA InSight / MRO: impactos sísmicos confirmados con cráteres en Marte",
	}
	for _, e in sw.events do
		table.insert(lines, string.format("%s: %s", e.date, e.label))
	end
	return lines
end

function NasaData.eventForAlert(index: number)
	local ev = NasaData.SpaceWeather.events
	return ev[((index - 1) % #ev) + 1]
end

function NasaData.blackHoleForEvent(index: number)
	local list = NasaData.BlackHoleEvents
	return list[((index - 1) % #list) + 1]
end

function NasaData.meteorForAlert(index: number)
	local list = NasaData.MeteorEvents
	return list[((index - 1) % #list) + 1]
end

return NasaData
