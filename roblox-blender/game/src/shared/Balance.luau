--!strict
-- Balance v0. Todos los valores de equilibrio del juego viven aqui.
-- Unidades: studs, segundos, puntos de vida. Cambiar aqui, no en los sistemas.

local Balance = {}

Balance.Debug = {
	Invincible = false, -- true: el heroe no recibe dano (solo pruebas)
	StartMinute = 0, -- minuto de mision en el que arranca la partida (solo pruebas)
	LogPerf = false,
}

Balance.Sim = {
	Step = 1 / 20, -- paso fijo de simulacion del servidor
	SnapshotEvery = 2, -- posiciones cada 2 pasos = 10 Hz
	MaxEnemies = 100,
	MaxGems = 160,
	ArenaRadius = 210,
	SpawnMinDist = 58,
	SpawnMaxDist = 74,
	MaxCmdsPerSecond = 20,
}

Balance.Modes = {
	full = { TimeScale = 1, XpMult = 1, Label = "Mision completa" },
	demo = { TimeScale = 5, XpMult = 3.2, Label = "Demo rapida" },
}

Balance.Hero = {
	MaxHp = 100,
	WalkSpeed = 16,
	Radius = 1.5,
	AttackInterval = 0.6,
	Damage = 12,
	Range = 48,
	ProjSpeed = 110,
	ProjRadius = 1.2,
	SpreadDeg = 9,
	CritChance = 0.05,
	CritMult = 2,
	PickupRadius = 9,
	JumpPower = 34,
	IFrames = 0.35, -- invulnerabilidad tras recibir un golpe
	RegenDelay = 6, -- pasiva "Soporte vital": espera sin dano
	RegenPerSec = 1,
}

-- Modos de fuego del arma principal (alternables en combate con [F] / [Y] o tocando la ranura).
Balance.WeaponModes = {
	{
		id = "laser",
		shotKind = "shot",
		dmgMult = 1.0,
		rateMult = 1.0,
		projCountBonus = 0,
		pierceBonus = 0,
		range = 48,
		speedMult = 1.0,
		critBonus = 0.08,
		splash = 0,
		knock = 0,
		spread = 0.14,
	},
	{
		id = "spread",
		shotKind = "spread",
		dmgMult = 0.68,
		rateMult = 0.92,
		projCountBonus = 2,
		pierceBonus = 0,
		range = 38,
		speedMult = 0.92,
		critBonus = 0,
		splash = 0,
		knock = 1.5,
		spread = 0.24,
	},
	{
		id = "mortar",
		shotKind = "mortar",
		dmgMult = 1.45,
		rateMult = 0.56,
		projCountBonus = 0,
		pierceBonus = 0,
		range = 44,
		speedMult = 0.52,
		critBonus = 0.05,
		splash = 10.5,
		knock = 10,
		spread = 0.20,
	},
}

Balance.Skills = {
	Dash = { Cooldown = 8, Distance = 24, Width = 5, Damage = 25, Invuln = 0.45, Duration = 0.18 },
	Pulse = { Cooldown = 20, Radius = 18, Damage = 45, Knockback = 18, Shield = 35, ShieldTime = 6 },
}

Balance.World = {
	ShipRadius = 8.4,
	ArenaSafeMargin = 3.0,
}

Balance.Zones = {
	{ id = "central", name = "Cráter del Módulo", bonus = "+1.5 vida/s en base segura", regen = 1.5 },
	{ id = "north", name = "Cresta Basáltica", bonus = "+15 % XP de muestras", xp = 0.15 },
	{ id = "east", name = "Falla Perseverance", bonus = "+20 % Datos científicos", science = 0.20 },
	{ id = "south", name = "Llanura Roja", bonus = "+10 % Velocidad de movimiento", speed = 0.10 },
	{ id = "west", name = "Cuenca Criogénica", bonus = "-15 % Espera de habilidades", cd = 0.15 },
}

Balance.Meteors = {
	UnlockLevel = 5,
	UnlockWave = 4,
	Interval = { 22, 15, 11 },
	Count = { 2, 3, 4 },
	Radius = 8.5,
	Delay = 1.65,
	Dmg = 24,
}

Balance.BlackHole = {
	FirstAt = 48,
	Interval = 85,
	Duration = 15,
}

-- Enemigos comunes. speed en studs/s; wind = aviso antes del ataque.
Balance.Enemies = {
	chaser = { hp = 12, speed = 17, dmg = 6, radius = 1.6, xp = 1, hitCd = 0.8 },
	tank = { hp = 80, speed = 8, dmg = 16, radius = 3.0, xp = 5, wind = 0.8, atkRange = 6, atkRadius = 8, atkCd = 2.5 },
	ranged = { hp = 24, speed = 10, dmg = 9, radius = 1.8, xp = 3, wind = 0.7, atkRange = 36, keepMin = 20, keepMax = 30, atkCd = 2.8, shotSpeed = 38, shotRadius = 1.3, shotLife = 2.2 },
	kamikaze = { hp = 10, speed = 22, dmg = 22, radius = 1.5, xp = 2, wind = 0.8, atkRange = 6, atkRadius = 9 },
	elite = { hp = 420, speed = 11, dmg = 20, radius = 4.0, xp = 25, atkCd = 3.2 },
}

Balance.Scaling = {
	HpPerMinute = 0.10,
	HpPerMinuteSq = 0.004,
	DmgPerMinute = 0.04,
	XpBase = 5,
	XpLinear = 4,
	XpQuad = 0.6,
}

Balance.Director = {
	RateBase = 1.1, -- enemigos por segundo al inicio
	RatePerMinute = 0.30,
	BossRateMult = 0.5, -- durante un jefe
	UnlockKamikaze = 90,
	UnlockRanged = 180,
	UnlockTank = 270,
	EliteInterval = 150,
	ChestInterval = 80,
	Weights = { chaser = 10, kamikaze = 3, ranged = 3, tank = 2 },
}

Balance.Run = {
	WaveLength = 60, -- cada oleada dura 60 s de mision
	TotalWaves = 18,
	MiniBossTimes = { 240, 540, 840 }, -- inicio de las oleadas 5, 10 y 15
	FinalBossTime = 1020, -- oleada 18
	BiomeTimes = { 0, 360, 720 },
	HazardInterval = { 0, 9, 7 }, -- por bioma; 0 = sin peligro ambiental
	HazardCount = { 0, 3, 5 },
	HazardRadius = 6,
	HazardDelay = 1.3,
	HazardDmg = 14,
}

-- Patrones: charge, slam, rocks, nova, summon. Avisos entre 1 y 2 s.
Balance.Bosses = {
	{ id = "boss1", hp = 900, speed = 12, dmg = 18, radius = 5, xp = 60, cycle = 3.2, patterns = { "charge", "summon" } },
	{ id = "boss2", hp = 2200, speed = 9, dmg = 22, radius = 6, xp = 90, cycle = 3.0, patterns = { "slam", "rocks" } },
	{ id = "boss3", hp = 4000, speed = 11, dmg = 24, radius = 5.5, xp = 120, cycle = 2.8, patterns = { "nova", "charge", "rocks" } },
	{ id = "final", hp = 8000, speed = 10, dmg = 28, radius = 7, xp = 0, cycle = 2.6, patterns = { "slam", "nova", "rocks", "summon", "charge" }, enrageAt = 0.35, enrageCycle = 1.9 },
}

Balance.Patterns = {
	charge = { delay = 1.0, length = 46, width = 7 },
	slam = { delay = 1.2, radius = 15 },
	rocks = { delay = 1.3, count = 5, radius = 6, spread = 14 },
	nova = { delay = 1.0, count = 14, speed = 30, radius = 1.4, life = 3 },
	summon = { count = 6 },
	elite = { "charge", "slam", "nova" }, -- patron de la elite por bioma
}

-- Mejoras de nivel (elige 1 de 3). per = efecto por nivel.
Balance.Upgrades = {
	damage = { max = 5, per = 0.20 },
	rate = { max = 5, per = 0.12 },
	multishot = { max = 2, per = 1 },
	pierce = { max = 3, per = 1 },
	armor = { max = 5, per = 20 },
	speed = { max = 4, per = 0.08 },
	magnet = { max = 4, per = 0.30 },
	drone = { max = 4, per = 1, dmg = 9, radius = 9, hitRadius = 3.2, angSpeed = 2.6, hitCd = 0.5 },
	cooldown = { max = 4, per = 0.10 },
	crit = { max = 5, per = 0.08 },
	aura = { max = 4, per = 5, radius = 10, interval = 0.5 },
	nova = { max = 5, baseDmg = 24, per = 11, radius = 14, radiusPer = 2.2, knock = 14, interval = 3.2, intervalPer = 0.25 },
	missiles = { max = 5, baseCount = 2, dmgMult = 0.82, per = 12, range = 48, speed = 70, splash = 5.2, interval = 2.0, intervalPer = 0.14 },
	arc = { max = 5, baseChains = 2, dmgMult = 0.78, per = 11, range = 42, jumpRange = 22, interval = 1.65, intervalPer = 0.12 },
}
-- Mejoras que suman unidades enteras: valen 1 nivel y se desbloquean a partir de nivel 2.
Balance.UpgradeCount = { multishot = true, pierce = true, drone = true }
Balance.UpgradeCountMinLevel = 2
-- Armas secundarias por rango: disponibles desde nivel 1 (+1 rango, +2 si carta epica/legendaria).
Balance.WeaponRanks = { nova = true, missiles = true, arc = true }
-- Rareza de carta: 1 comun, 2 rara, 3 epica, 4 legendaria. Mult = niveles que otorga.
-- Escala por nivel del jugador: evita cartas legendarias o epicas en los primeros niveles.
Balance.CardRarity = {
	Weights = { 82, 18, 0, 0 },
	Stages = {
		{ minLvl = 1, w = { 82, 18, 0, 0 } },
		{ minLvl = 4, w = { 62, 30, 8, 0 } },
		{ minLvl = 7, w = { 46, 34, 17, 3 } },
		{ minLvl = 11, w = { 32, 36, 24, 8 } },
		{ minLvl = 15, w = { 22, 34, 29, 15 } },
	},
	Mult = { 1, 1.5, 2, 3 },
	LuckShift = 5,
}

Balance.ChestTiers = {
	{ name = "Común", itemW = { 76, 22, 2 }, science = 8, heal = 10, extra = false },
	{ name = "Raro", itemW = { 20, 62, 18 }, science = 16, heal = 15, extra = false },
	{ name = "Épico", itemW = { 0, 35, 65 }, science = 28, heal = 22, extra = false },
	{ name = "Legendario", itemW = { 0, 10, 90 }, science = 45, heal = 35, extra = true },
}
Balance.ChestWaveWeights = {
	{ minWave = 1, w = { 75, 25, 0, 0 } },
	{ minWave = 4, w = { 42, 40, 16, 2 } },
	{ minWave = 8, w = { 20, 38, 30, 12 } },
	{ minWave = 12, w = { 10, 30, 38, 22 } },
}
Balance.UpgradeOrder = { "damage", "rate", "nova", "missiles", "arc", "multishot", "pierce", "armor", "speed", "magnet", "drone", "cooldown", "crit", "aura" }
Balance.LevelUpHeal = 30 -- opcion de reserva "Reparacion de campo"

-- Objetos de cofre. cat: off | def | util. rar: 1 comun, 2 raro, 3 epico.
Balance.Items = {
	lens = { cat = "off", rar = 1, per = 0.10 },
	cell = { cat = "off", rar = 1, per = 0.08 },
	spectro = { cat = "off", rar = 2, per = 0.10 },
	ion = { cat = "off", rar = 2, per = 0.25, pierce = 1 },
	plasma = { cat = "off", rar = 3, every = 5, radius = 8, frac = 0.6 },
	pica = { cat = "def", rar = 1, per = 15 },
	mli = { cat = "def", rar = 1, per = 0.06 },
	filter = { cat = "def", rar = 2, per = 0.5 },
	whipple = { cat = "def", rar = 2, per = 0.10 },
	shelter = { cat = "def", rar = 3, threshold = 0.25, invuln = 3, cd = 60 },
	boots = { cat = "util", rar = 1, per = 0.06 },
	arm = { cat = "util", rar = 1, per = 0.25 },
	solar = { cat = "util", rar = 2, per = 0.10 },
	antenna = { cat = "util", rar = 2, per = 0.08 },
	orbital = { cat = "util", rar = 3, per = 1 },
}
Balance.ItemOrder = { "lens", "cell", "spectro", "ion", "plasma", "pica", "mli", "filter", "whipple", "shelter", "boots", "arm", "solar", "antenna", "orbital" }
Balance.RarityWeights = { 60, 30, 10 }
Balance.Caps = { Armor = 0.6, Block = 0.5, CdMult = 0.4, Crit = 0.8 }

-- Meta-progresion: se compra con "datos cientificos" entre partidas.
Balance.Meta = {
	Order = { "dmg", "hp", "armor", "speed", "magnet", "xp", "luck", "revive" },
	armor = { max = 5, per = 0.03, cost = 40 },
	speed = { max = 5, per = 0.02, cost = 30 },
	luck = { max = 5, per = 1, cost = 50 },
	hp = { max = 5, per = 10, cost = 30 },
	dmg = { max = 5, per = 0.05, cost = 40 },
	xp = { max = 5, per = 0.05, cost = 40 },
	magnet = { max = 3, per = 0.10, cost = 30 },
	revive = { max = 1, per = 0.5, cost = 300 },
	SciencePerKill = 0.2,
	SciencePerMinute = 10,
	SciencePerPiece = 40,
	ScienceWin = 150,
}

-- Bonos al recuperar cada pieza de la nave (1 a 3; la 4 da la victoria).
Balance.Pieces = {
	{ regen = 1, cd = 0.10 },
	{ xp = 0.20 },
	{ heal = 40, maxHp = 15 },
	{},
}

-- Camara en tercera persona con giro libre.
Balance.Camera = { Distance = 27, MinDistance = 14, MaxDistance = 42, Pitch = 24, MinPitch = 6, MaxPitch = 72, Fov = 80, FocusHeight = 3.5, Sensitivity = 0.0036, ShakeMax = 0.35 }

-- Gravedad de Marte: 0,38 veces la terrestre (196,2 studs/s2 en Roblox).
Balance.World = { Gravity = 74.5 }

Balance.Juice = {
	HitstopKill = 0.04,
	HitstopBig = 0.06,
	FlashTime = 0.08,
	KickTime = 0.14, -- duracion del retroceso visual al golpear
	KickDist = 0.9, -- studs que retrocede el enemigo golpeado
	LevelUpPause = 0.15,
	PitchVar = 0.05,
	DamageNumberLife = 0.6,
}

-- Audio. Todo sale de catalogos con licencia de Roblox (APM, DistroKid, ProSoundEffects) o del cliente.
-- Los volumenes se igualaron midiendo PlaybackLoudness en Studio; ver docs/assets/AUDIO.md.
Balance.Audio = {
	Music = {
		calm = { id = "rbxassetid://140533822783920", vol = 0.10 }, -- "Space Ambient" (DistroKid)
		combat = { id = "rbxassetid://1837839878", vol = 0.20 }, -- "Terminal Velocity (Perc)" (APM)
		boss = { id = "rbxassetid://9042593925", vol = 0.28 }, -- "Final Outcome" (APM)
	},
	Sfx = {
		shoot = { id = "rbxasset://sounds/action_jump.mp3", vol = 0.09, pitch = 1.7 },
		hit = { id = "rbxassetid://9113485712", vol = 0.10, pitch = 1.25 },
		kill = { id = "rbxassetid://9118172604", vol = 0.12, pitch = 1.3 },
		boom = { id = "rbxassetid://9119378289", vol = 0.28, pitch = 1 },
		hurt = { id = "rbxasset://sounds/action_falling.ogg", vol = 0.4, pitch = 1.3 },
		gem = { id = "rbxassetid://9126073001", vol = 0.12, pitch = 1 },
		level = { id = "rbxassetid://9126071775", vol = 0.26, pitch = 0.9 },
		chest = { id = "rbxassetid://9126072453", vol = 0.24, pitch = 0.8 },
		buff = { id = "rbxassetid://9126076030", vol = 0.2, pitch = 0.85 },
		ui = { id = "rbxasset://sounds/volume_slider.ogg", vol = 0.25, pitch = 1 },
		skill = { id = "rbxassetid://9125442175", vol = 0.26, pitch = 1.3 },
		warn = { id = "rbxassetid://9117955911", vol = 0.22, pitch = 1 },
	},
}

-- Insignia de NASA en el menu. Su uso exige autorizacion escrita de NASA: ponlo en false si no la tienes.
Balance.Branding = { NasaInsignia = true }

Balance.Tutorial = { MoveDistance = 20, Dummies = 3, TelegraphDelay = 2 }

function Balance.xpNeeded(level: number): number
	local s = Balance.Scaling
	return math.floor(s.XpBase + s.XpLinear * level + s.XpQuad * level * level)
end

function Balance.hpMult(minutes: number): number
	local s = Balance.Scaling
	return 1 + s.HpPerMinute * minutes + s.HpPerMinuteSq * minutes * minutes
end

function Balance.dmgMult(minutes: number): number
	return 1 + Balance.Scaling.DmgPerMinute * minutes
end

return Balance
