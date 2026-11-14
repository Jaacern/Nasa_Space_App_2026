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

-- Lineas para la telemetria del HUD. Solo hechos presentes en el snapshot.
function NasaData.tickerLines(): { string }
	local sw = NasaData.SpaceWeather
	local lines = {
		string.format("DONKI %s a %s: %d erupciones solares registradas", sw.windowStart, sw.windowEnd, sw.counts.FLR),
		string.format("DONKI: %d nubes de plasma (CME) en 30 días", sw.counts.CME),
		string.format("DONKI: %d tormenta geomagnética en 30 días", sw.counts.GST),
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

return NasaData
