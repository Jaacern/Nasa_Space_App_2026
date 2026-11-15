--!strict
-- Textos del juego (español). Los números viven en Balance.

local Content = {}

Content.Title = "ARES FORGE"
Content.Subtitle = "SUPERVIVENCIA EN SUPERFICIE"
Content.Tagline = "Tu nave cayó. Recupera sus 4 piezas y vuelve a casa."

-- fmt recibe el valor de la carta (per × rareza × scale). Sin fmt = texto fijo.
-- fact: dato real breve que se muestra en la carta; fuentes en docs/NASA_APIS.md (seccion Datos de cartas).
Content.Upgrades = {
	damage = { name = "Láser de mayor potencia", fmt = "+%d %% de daño del láser.", scale = 100, fact = "SuperCam, en Perseverance, identifica la composición de la roca a más de 7 metros de distancia." },
	rate = { name = "Disparo más rápido", fmt = "+%d %% de cadencia de disparo.", scale = 100, fact = "ChemCam, en Curiosity, analiza con un láser la composición química de rocas y suelo." },
	multishot = { name = "Haz dividido", desc = "+1 proyectil por disparo.", fact = "Marte tiene dos lunas pequeñas: Fobos y Deimos." },
	pierce = { name = "Haz perforante", desc = "El láser atraviesa +1 enemigo.", fact = "El radar RIMFAX de Perseverance sondea el suelo bajo el rover para ver su geología." },
	armor = { name = "Traje reforzado", fmt = "+%d de vida máxima.", scale = 1, fact = "El instrumento RAD de Curiosity mide la radiación de alta energía en la superficie de Marte." },
	speed = { name = "Servos de movilidad", fmt = "+%d %% de velocidad.", scale = 100, fact = "Perseverance avanza despacio: su velocidad máxima ronda los 152 metros por hora." },
	magnet = { name = "Imán de muestras", fmt = "+%d %% de radio de recogida.", scale = 100, fact = "Perseverance guarda los núcleos de roca que perfora en tubos de muestra." },
	drone = { name = "Dron orbital", desc = "+1 dron que gira a tu alrededor y golpea.", fact = "El 19 de abril de 2021, Ingenuity hizo el primer vuelo propulsado y controlado en Marte." },
	cooldown = { name = "Recarga eficiente", fmt = "-%d %% de espera de habilidades.", scale = 100, fact = "El generador MMRTG convierte en electricidad el calor de la desintegración del plutonio." },
	crit = { name = "Puntería de precisión", fmt = "+%d %% de golpe crítico.", scale = 100, fact = "SuperCam puede analizar zonas de roca tan pequeñas como la punta de un lápiz." },
	aura = { name = "Campo electrostático", fmt = "+%d de daño por pulso a los enemigos cercanos.", scale = 1, fact = "El láser de ChemCam vaporiza la superficie de la roca y crea un plasma que el instrumento analiza." },
	heal = { name = "Reparación de campo", desc = "Recupera 30 de vida.", fact = "MOXIE probó cómo producir oxígeno a partir de la atmósfera de Marte." },
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
	{ name = "Impulso RCS", short = "RCS", key = "Q", desc = "CD 8 s · Esquiva direccional invulnerable que atraviesa y daña enemigos cercanos." },
	{ name = "Pulso de escudo", short = "ESCUDO", key = "E", desc = "CD 20 s · Onda expansiva que empuja enemigos y activa +35 de escudo visible por 6 s." },
}

Content.AutoWeapon = {
	name = "Láser Táctico Automático",
	short = "LÁSER",
	key = "AUTO",
	desc = "Disparo continuo al enemigo más cercano. Mejora su daño, cadencia, perforación y haz dividido.",
}

Content.ChestTiers = { "COFRE COMÚN", "COFRE RARO", "COFRE ÉPICO", "COFRE LEGENDARIO" }

Content.Briefing = {
	title = "INFORME TÁCTICO DE TRAJE Y ZONAS",
	sub = "Revisa tus sistemas antes de entrar en combate (la simulación espera tu confirmación):",
	sections = {
		{ title = "LÁSER AUTOMÁTICO (PASIVA)", color = "cyan", text = "Apunta y dispara solo al hostil más cercano. Recoge cristales dorados para subir de nivel y escalar cartas hasta Legendaria en niveles altos." },
		{ title = "IMPULSO RCS (ACTIVA · Q / X / BOTÓN RCS)", color = "gold", text = "CD 8 s · Propulsión instantánea con 0.45 s de invulnerabilidad. Úsalo para salir de zonas naranja de meteoros o rodear jefes." },
		{ title = "PULSO DE ESCUDO (ACTIVA · E / B / BOTÓN ESCUDO)", color = "cyan", text = "CD 20 s · Detona un pulso protector de radio 18: empujón + daño en área y +35 de escudo visible en la barra cian por 6 s." },
		{ title = "ZONAS DEL CRÁTER Y EVENTOS CÓSMICOS", color = "orange", text = "Explora las 5 zonas del mapa (Centro seguro, Norte +XP, Este +Ciencia, Sur +Velocidad, Oeste -CD). Evita lluvias de meteoros (niv. 5+) y contempla anomalías de agujero negro." },
	},
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
	"Muévete con WASD, las flechas o el joystick. Gira la cámara con el ratón o arrastrando la pantalla.",
	"Tu láser dispara solo. Aléjate de los remolinos mientras dispara y destruye 3.",
	"Recoge las muestras doradas hasta subir de nivel.",
	"Zona naranja = peligro. Sal antes de que se llene.",
	"Pulsa Q (o el botón RCS) para esquivar.",
	"Pulsa E (o el botón PULSO) para empujar y ganar escudo.",
	"Abre el cofre: sigue la flecha dorada.",
	"Práctica libre. Pulsa SALIR cuando quieras.",
}

Content.Controls = "WASD / Flechas mover · Ratón girar cámara · Espacio saltar · Q impulso · E pulso · P pausa · 1-2-3 elegir carta"
Content.ControlsGamepad = "STICK IZQ : Mover · STICK DER : Cámara · A : Saltar · X/L1 : Impulso · B/R1 : Pulso · ◀/▲/▶ : Carta · START : Pausa"
Content.ControlsTouch = "JOYSTICK IZQ : Moverse · ARRASTRAR DER : Girar cámara · PELLIZCAR : Zoom · BOTONES : Salto, Impulso y Pulso"

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
	"Tipografías: Michroma, Sarpanch, Jura, Builder Sans, Bangers y Roboto Mono (incluidas en Roblox).",
	"Eventos astrofísicos: NASA Chandra / NuSTAR / Event Horizon Telescope (Sgr A*, M87*, Cygnus X-1) y NASA InSight / JPL CNEOS.",
	"",
	"El juego no usa el logotipo de NASA ni assets de otros juegos.",
}

return Content
