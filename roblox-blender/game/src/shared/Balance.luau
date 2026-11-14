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

Balance.Skills = {
	Dash = { Cooldown = 8, Distance = 24, Width = 5, Damage = 25, Invuln = 0.45, Duration = 0.18 },
	Pulse = { Cooldown = 12, Radius = 18, Damage = 40, Knockback = 16, Shield = 25, ShieldTime = 4 },
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
}
-- Mejoras que suman unidades enteras: siempre valen 1 nivel y salen como carta epica.
Balance.UpgradeCount = { multishot = true, pierce = true, drone = true }
-- Rareza de carta: 1 comun, 2 rara, 3 epica, 4 legendaria. Mult = niveles que otorga.
Balance.CardRarity = { Weights = { 60, 27, 10, 3 }, Mult = { 1, 1.5, 2, 3 }, LuckShift = 5 }
Balance.UpgradeOrder = { "damage", "rate", "multishot", "pierce", "armor", "speed", "magnet", "drone", "cooldown", "crit", "aura" }
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
	LevelUpPause = 0.15,
	PitchVar = 0.05,
	DamageNumberLife = 0.6,
}

-- Audio. Los Id vacios quedan en silencio; ver docs/assets/AUDIO.md.
Balance.Audio = {
	Music = { calm = "", combat = "", boss = "" },
	Sfx = {
		shoot = { id = "rbxasset://sounds/action_jump.mp3", vol = 0.12, pitch = 2.2 },
		hit = { id = "rbxasset://sounds/action_jump_land.mp3", vol = 0.25, pitch = 1.6 },
		kill = { id = "rbxasset://sounds/impact_water.mp3", vol = 0.2, pitch = 1.8 },
		boom = { id = "rbxasset://sounds/impact_explosion_03.mp3", vol = 0.5, pitch = 1 },
		hurt = { id = "rbxasset://sounds/action_falling.ogg", vol = 0.5, pitch = 1.4 },
		gem = { id = "rbxasset://sounds/volume_slider.ogg", vol = 0.35, pitch = 1.5 },
		level = { id = "rbxasset://sounds/action_get_up.mp3", vol = 0.6, pitch = 1.5 },
		chest = { id = "rbxasset://sounds/action_get_up.mp3", vol = 0.6, pitch = 1.1 },
		ui = { id = "rbxasset://sounds/volume_slider.ogg", vol = 0.4, pitch = 1 },
		skill = { id = "rbxasset://sounds/action_jump.mp3", vol = 0.5, pitch = 0.8 },
		warn = { id = "rbxasset://sounds/volume_slider.ogg", vol = 0.5, pitch = 0.6 },
	},
}

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
