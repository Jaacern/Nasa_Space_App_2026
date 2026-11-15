--!strict
-- Textos del juego (español). Los números viven en Balance.

local Content = {}

Content.Title = "ARES FORGE"
Content.Subtitle = "SUPERVIVENCIA EN SUPERFICIE"
Content.Tagline = "Tu nave cayó. Recupera sus 4 piezas y vuelve a casa."

-- fmt recibe el valor de la carta (per × rareza × scale). Sin fmt = texto fijo.
-- fact: dato real breve que se muestra en la carta; fuentes en docs/NASA_APIS.md (seccion Datos de cartas).
Content.Upgrades = {
	damage = { name = "Láser de mayor potencia", fmt = "+%d %% de daño del láser.", scale = 100, fact = "El láser de SuperCam, en Perseverance, vaporiza roca a distancia para leer su composición." },
	rate = { name = "Disparo más rápido", fmt = "+%d %% de cadencia de disparo.", scale = 100, fact = "ChemCam, en Curiosity, dispara ráfagas de pulsos láser sobre cada punto de roca que analiza." },
	multishot = { name = "Haz dividido", desc = "+1 proyectil por disparo.", fact = "Marte tiene dos lunas pequeñas: Fobos y Deimos." },
	pierce = { name = "Haz perforante", desc = "El láser atraviesa +1 enemigo.", fact = "El radar RIMFAX de Perseverance estudia las capas de roca que hay bajo el suelo." },
	armor = { name = "Traje reforzado", fmt = "+%d de vida máxima.", scale = 1, fact = "Marte no tiene campo magnético global. El instrumento RAD de Curiosity mide la radiación en superficie." },
	speed = { name = "Servos de movilidad", fmt = "+%d %% de velocidad.", scale = 100, fact = "Perseverance avanza despacio: su velocidad máxima ronda los 152 metros por hora." },
	magnet = { name = "Imán de muestras", fmt = "+%d %% de radio de recogida.", scale = 100, fact = "Perseverance guarda núcleos de roca en tubos sellados para traerlos algún día a la Tierra." },
	drone = { name = "Dron orbital", desc = "+1 dron que gira a tu alrededor y golpea.", fact = "El helicóptero Ingenuity logró en 2021 el primer vuelo con motor en otro planeta." },
	cooldown = { name = "Recarga eficiente", fmt = "-%d %% de espera de habilidades.", scale = 100, fact = "El generador MMRTG convierte en electricidad el calor del plutonio-238." },
	crit = { name = "Puntería de precisión", fmt = "+%d %% de golpe crítico.", scale = 100, fact = "Perseverance aterrizó comparando fotos del suelo con mapas a bordo para elegir un punto seguro." },
	aura = { name = "Campo electrostático", fmt = "+%d de daño por pulso a los enemigos cercanos.", scale = 1, fact = "El polvo marciano se carga de electricidad estática y se adhiere a los equipos." },
	heal = { name = "Reparación de campo", desc = "Recupera 30 de vida.", fact = "El experimento MOXIE produjo oxígeno a partir del dióxido de carbono del aire marciano." },
}
Content.CardRarities = { "COMÚN", "RARA", "ÉPICA", "LEGENDARIA" }

Content.Categories = { off = "OFENSIVA", def = "DEFENSA", util = "UTILIDAD" }
Content.Rarities = { "COMÚN", "RARO", "ÉPICO" }

-- fact: frase educativa general, sin cifras que no estén verificadas.
Content.Items = {
	lens = { name = "Lente de láser", desc = "+10 % de daño.", fact = "Los rovers usan láseres para vaporizar roca y leer su composición por la luz que emite." },
	cell = { name = "Celda de combustible", desc = "+8 % de cadencia.", fact = "Una celda de combustible produce electricidad combinando hidrógeno y oxígeno." },
	spectro = { name = "Espectrómetro", desc = "+10 % de golpe crítico.", fact = "Un espectrómetro separa la luz para identificar de qué está hecho un material." },
	ion = { name = "Microimpulsor iónico", desc = "Proyectiles +25 % más rápidos y +1 perforación.", fact = "Un motor iónico empuja muy poco, pero durante muchísimo tiempo y con poco combustible." },
	plasma = { name = "Núcleo de plasma", desc = "Cada 5.º disparo explota en área.", fact = "El plasma es gas tan caliente que sus átomos pierden electrones. El Sol está hecho de plasma." },
	pica = { name = "Placa de escudo térmico", desc = "+15 de vida máxima.", fact = "Un escudo ablativo se quema poco a poco y así se lleva el calor de la reentrada." },
	mli = { name = "Manta térmica multicapa", desc = "-6 % de daño recibido.", fact = "Las mantas doradas de las naves son capas finas que frenan el calor y el frío." },
	filter = { name = "Filtro de CO2", desc = "+0,5 de vida por segundo.", fact = "En una nave hay que retirar el CO2 del aire que respira la tripulación." },
	whipple = { name = "Escudo Whipple", desc = "10 % de bloquear un golpe.", fact = "Un escudo Whipple usa una capa fina separada del casco para romper micrometeoritos." },
	shelter = { name = "Refugio de tormenta", desc = "Bajo 25 % de vida: 3 s de invulnerabilidad (cada 60 s).", fact = "Durante una tormenta solar la tripulación se refugia en la zona más blindada de la nave." },
	boots = { name = "Botas de tracción", desc = "+6 % de velocidad.", fact = "El polvo de regolito es fino y abrasivo: caminar sobre él exige buena tracción." },
	arm = { name = "Brazo robótico", desc = "+25 % de radio de recogida.", fact = "Los brazos robóticos recogen muestras y mueven instrumentos sin que nadie salga de la nave." },
	solar = { name = "Panel solar", desc = "+10 % de experiencia.", fact = "Lejos del Sol llega menos luz: los paneles solares rinden menos en Marte que en la Tierra." },
	antenna = { name = "Antena de alta ganancia", desc = "-8 % de espera de habilidades.", fact = "Una antena parabólica concentra la señal en un haz estrecho para llegar muy lejos." },
	orbital = { name = "Mapa orbital", desc = "Cada cofre entrega +1 objeto.", fact = "Los orbitadores fotografían la superficie para planificar rutas seguras." },
}

Content.Enemies = {
	chaser = "Remolino de polvo",
	tank = "Gólem de regolito",
	ranged = "Centinela iónico",
	kamikaze = "Meteoroide inestable",
	elite1 = "Tolvanera mayor",
	elite2 = "Coloso de hielo",
	elite3 = "Heraldo solar",
	boss1 = "TORMENTA DE POLVO GLOBAL",
	boss2 = "COLOSO DE LA LLUVIA DE ROCAS",
	boss3 = "HERALDO DE LA ERUPCIÓN",
	final = "COLOSO DE LA TORMENTA SOLAR",
}

Content.Biomes = {
	{ name = "LLANURA DE REGOLITO", desc = "Polvo fino y remolinos." },
	{ name = "CAMPO DE CRÁTERES", desc = "Sombras heladas y lluvia de rocas." },
	{ name = "FRENTE DE TORMENTA SOLAR", desc = "Radiación y erupciones." },
}

-- Piezas de la nave. ntrs = identificador verificado en ntrs.nasa.gov o cadena vacía.
Content.Pieces = {
	{
		name = "Batería nuclear (MMRTG)",
		short = "MMRTG",
		bonus = "+1 de vida por segundo y -10 % de espera de habilidades.",
		real = "Un generador termoeléctrico de radioisótopos convierte en electricidad el calor de un material radiactivo. Funciona de día, de noche y con polvo.",
		ntrs = "20150005587",
		ref = "The F1 Multi-Mission Radioisotope Thermoelectric Generator (MMRTG): a Power Subsystem Enabler for the Mars Science Laboratory (MSL) Mission",
	},
	{
		name = "Antena de alta ganancia",
		short = "ANTENA",
		bonus = "+20 % de experiencia: vuelve el enlace de datos.",
		real = "Una antena de alta ganancia concentra la señal de radio en un haz estrecho y se orienta hacia la Tierra para comunicarse a enormes distancias.",
		ntrs = "20040084278",
		ref = "High Gain Antenna Gimbal for the 2003-2004 Mars Exploration Rover Program",
	},
	{
		name = "Generador de oxígeno",
		short = "OXÍGENO",
		bonus = "Recupera 40 de vida y +15 de vida máxima.",
		real = "En Marte el aire es casi todo CO2. Un generador de oxígeno separa el oxígeno de ese CO2 para respirar o para usarlo como propelente.",
		ntrs = "20205007222",
		ref = "MOXIE (Mars Oxygen ISRU Experiment), M. Hecht y J. Mellstrom",
	},
	{
		name = "Propulsor de retorno",
		short = "MOTOR",
		bonus = "Pieza final: la nave puede despegar.",
		real = "El motor principal vence la gravedad del planeta y pone la nave en ruta de regreso. El módulo de servicio de Orion usa propelentes que se encienden al mezclarse.",
		ntrs = "20240003648",
		ref = "Artemis I Orion ESM Propulsion System Engine Performance",
	},
}

Content.Skills = {
	{ name = "Impulso RCS", short = "RCS", key = "Q", desc = "Esquiva rápida que daña lo que cruza." },
	{ name = "Pulso de escudo", short = "PULSO", key = "E", desc = "Empuja y daña alrededor. Da escudo." },
}

Content.Meta = {
	dmg = { name = "Óptica calibrada", desc = "+5 % de daño por nivel." },
	hp = { name = "Traje reforzado", desc = "+10 de vida máxima por nivel." },
	armor = { name = "Blindaje del traje", desc = "-3 % de daño recibido por nivel." },
	speed = { name = "Servos del traje", desc = "+2 % de velocidad por nivel." },
	magnet = { name = "Colector ampliado", desc = "+10 % de radio de recogida por nivel." },
	xp = { name = "Análisis de muestras", desc = "+5 % de experiencia por nivel." },
	luck = { name = "Telemetría predictiva", desc = "Más cartas raras, épicas y legendarias." },
	revive = { name = "Protocolo de emergencia", desc = "Una vez por misión: revives con 50 % de vida." },
}

Content.Tutorial = {
	"Muévete con WASD o con el joystick. Gira la cámara con el ratón o arrastrando la pantalla.",
	"Tu láser dispara solo. Aléjate de los remolinos mientras dispara y destruye 3.",
	"Recoge las muestras doradas hasta subir de nivel.",
	"Zona naranja = peligro. Sal antes de que se llene.",
	"Pulsa Q (o el botón RCS) para esquivar.",
	"Pulsa E (o el botón PULSO) para empujar y ganar escudo.",
	"Abre el cofre: sigue la flecha dorada.",
	"Práctica libre. Pulsa SALIR cuando quieras.",
}

Content.Controls = "WASD mover · Ratón girar cámara · Espacio saltar · Q impulso · E pulso · P pausa · 1-2-3 elegir carta"

Content.Credits = {
	"ARES FORGE. Proyecto del equipo para NASA International Space Apps Challenge 2026.",
	"",
	"Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto.",
	"",
	"DATOS",
	"Clima espacial: NASA CCMC DONKI (copia local, modo snapshot). Información experimental de investigación; la fuente oficial de pronósticos es NOAA SWPC.",
	"Referencias técnicas: NASA Technical Reports Server (ntrs.nasa.gov), fichas 20150005587, 20040084278, 20205007222 y 20240003648.",
	"Rover Perseverance: modelado propio con medidas del modelo 3D oficial de NASA/JPL-Caltech.",
	"",
	"HERRAMIENTAS",
	"Roblox Studio (Luau) y Blender 4.5 LTS. Flujo de assets con skills de arjun988/blender-skills (licencia MIT).",
	"Tipografías: Michroma, Titillium Web y Roboto Mono (incluidas en Roblox).",
	"",
	"El juego no usa el logotipo de NASA ni assets de otros juegos.",
}

return Content
