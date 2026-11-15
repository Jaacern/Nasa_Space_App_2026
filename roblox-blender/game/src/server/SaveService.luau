--!strict
-- Meta-progresion y checkpoints en DataStore con 3 perfiles por jugador.
-- Toda llamada va en pcall con reintentos. En Studio sin DataStore conserva cache en memoria.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local SaveService = {}

local STORE_NAME = "AresForgeMeta_v1"
local VERSION = 2
SaveService.MAX_PROFILES = 3

export type Meta = {
	v: number,
	science: number,
	unlocks: { [string]: number },
	best: { time: number, level: number, kills: number },
	wins: number,
	runs: number,
	pieces: { boolean },
	tutorialDone: boolean,
	offline: boolean?,
}

export type Checkpoint = {
	modeName: string,
	t: number,
	real: number,
	wave: number,
	biome: number,
	lvl: number,
	xp: number,
	hp: number,
	shield: number,
	shieldT: number,
	shieldMax: number,
	kills: number,
	chestsOpened: number,
	zone: number,
	nextElite: number,
	chestT: number,
	bossIdx: number,
	upgrades: { [string]: number },
	items: { [string]: number },
	pieces: { boolean },
	scienceBonus: number,
	px: number,
	pz: number,
	weaponMode: number?,
	savedAt: number,
}

export type Profile = {
	name: string,
	meta: Meta,
	checkpoint: Checkpoint?,
}

export type Account = {
	v: number,
	activeSlot: number,
	profiles: { Profile },
	offline: boolean?,
}

function SaveService.defaultMeta(): Meta
	return {
		v = VERSION,
		science = 0,
		unlocks = { hp = 0, dmg = 0, xp = 0, magnet = 0, revive = 0, armor = 0, speed = 0, luck = 0 },
		best = { time = 0, level = 0, kills = 0 },
		wins = 0,
		runs = 0,
		pieces = { false, false, false, false },
		tutorialDone = false,
	}
end

function SaveService.defaultProfile(slot: number): Profile
	return {
		name = "PILOTO " .. tostring(slot),
		meta = SaveService.defaultMeta(),
		checkpoint = nil,
	}
end

function SaveService.default(): Account
	return {
		v = VERSION,
		activeSlot = 1,
		profiles = {
			SaveService.defaultProfile(1),
			SaveService.defaultProfile(2),
			SaveService.defaultProfile(3),
		},
	}
end

local store: DataStore? = nil
local storeTried = false
local memoryFallback: { [number]: Account } = {}

local function getStore(): DataStore?
	if not storeTried then
		storeTried = true
		local ok, res = pcall(function()
			return DataStoreService:GetDataStore(STORE_NAME)
		end)
		if ok then
			store = res
		else
			warn("[SaveService] DataStore no disponible: " .. tostring(res))
		end
	end
	return store
end

local function attempts(): number
	return if RunService:IsStudio() then 1 else 4
end

local function reconcileMeta(data: any): Meta
	local d = SaveService.defaultMeta()
	if type(data) ~= "table" then
		return d
	end
	if type(data.science) == "number" then
		d.science = math.max(0, math.floor(data.science))
	end
	if type(data.unlocks) == "table" then
		for k in d.unlocks do
			if type(data.unlocks[k]) == "number" then
				d.unlocks[k] = math.max(0, math.floor(data.unlocks[k]))
			end
		end
	end
	if type(data.best) == "table" then
		for k in d.best do
			if type(data.best[k]) == "number" then
				(d.best :: any)[k] = data.best[k]
			end
		end
	end
	if type(data.wins) == "number" then
		d.wins = math.max(0, math.floor(data.wins))
	end
	if type(data.runs) == "number" then
		d.runs = math.max(0, math.floor(data.runs))
	end
	if type(data.pieces) == "table" then
		for i = 1, 4 do
			d.pieces[i] = data.pieces[i] == true
		end
	end
	d.tutorialDone = data.tutorialDone == true
	return d
end

local function reconcileCheckpoint(raw: any): Checkpoint?
	if type(raw) ~= "table" then
		return nil
	end
	if type(raw.lvl) ~= "number" or type(raw.t) ~= "number" or type(raw.hp) ~= "number" then
		return nil
	end
	local upgrades: { [string]: number } = {}
	if type(raw.upgrades) == "table" then
		for k, v in raw.upgrades do
			if type(k) == "string" and type(v) == "number" and v > 0 then
				upgrades[k] = v
			end
		end
	end
	local items: { [string]: number } = {}
	if type(raw.items) == "table" then
		for k, v in raw.items do
			if type(k) == "string" and type(v) == "number" and v > 0 then
				items[k] = math.floor(v)
			end
		end
	end
	local pieces = { false, false, false, false }
	if type(raw.pieces) == "table" then
		for i = 1, 4 do
			pieces[i] = raw.pieces[i] == true
		end
	end
	return {
		modeName = if raw.modeName == "demo" then "demo" else "full",
		t = math.max(0, raw.t),
		real = if type(raw.real) == "number" then math.max(0, raw.real) else math.max(0, raw.t),
		wave = if type(raw.wave) == "number" then math.max(1, math.floor(raw.wave)) else 1,
		biome = if type(raw.biome) == "number" then math.clamp(math.floor(raw.biome), 1, 3) else 1,
		lvl = math.max(1, math.floor(raw.lvl)),
		xp = if type(raw.xp) == "number" then math.max(0, raw.xp) else 0,
		hp = math.max(1, raw.hp),
		shield = if type(raw.shield) == "number" then math.max(0, raw.shield) else 0,
		shieldT = if type(raw.shieldT) == "number" then math.max(0, raw.shieldT) else 0,
		shieldMax = if type(raw.shieldMax) == "number" then math.max(1, raw.shieldMax) else 35,
		kills = if type(raw.kills) == "number" then math.max(0, math.floor(raw.kills)) else 0,
		chestsOpened = if type(raw.chestsOpened) == "number" then math.max(0, math.floor(raw.chestsOpened)) else 0,
		zone = if type(raw.zone) == "number" then math.clamp(math.floor(raw.zone), 1, 5) else 1,
		nextElite = if type(raw.nextElite) == "number" then raw.nextElite else 150,
		chestT = if type(raw.chestT) == "number" then raw.chestT else 40,
		bossIdx = if type(raw.bossIdx) == "number" then math.clamp(math.floor(raw.bossIdx), 1, 5) else 1,
		upgrades = upgrades,
		items = items,
		pieces = pieces,
		scienceBonus = if type(raw.scienceBonus) == "number" then math.max(0, math.floor(raw.scienceBonus)) else 0,
		px = if type(raw.px) == "number" then raw.px else 0,
		pz = if type(raw.pz) == "number" then raw.pz else 34,
		weaponMode = if type(raw.weaponMode) == "number" then math.clamp(math.floor(raw.weaponMode), 1, 3) else 1,
		savedAt = if type(raw.savedAt) == "number" then raw.savedAt else os.time(),
	}
end

local function reconcile(data: any): Account
	local acc = SaveService.default()
	if type(data) ~= "table" then
		return acc
	end
	-- Migracion automatica sin perdida desde v1 (perfil unico) hacia Perfil 1.
	if type(data.profiles) ~= "table" then
		acc.profiles[1].meta = reconcileMeta(data)
		return acc
	end
	if type(data.activeSlot) == "number" then
		acc.activeSlot = math.clamp(math.floor(data.activeSlot), 1, SaveService.MAX_PROFILES)
	end
	for i = 1, SaveService.MAX_PROFILES do
		local rawP = data.profiles[i] or data.profiles[tostring(i)]
		if type(rawP) == "table" then
			local p = SaveService.defaultProfile(i)
			if type(rawP.name) == "string" and #rawP.name > 0 then
				p.name = rawP.name:sub(1, 18)
			end
			p.meta = reconcileMeta(rawP.meta)
			p.checkpoint = reconcileCheckpoint(rawP.checkpoint)
			acc.profiles[i] = p
		end
	end
	return acc
end

function SaveService.activeProfile(acc: Account): Profile
	local idx = math.clamp(math.floor(acc.activeSlot or 1), 1, SaveService.MAX_PROFILES)
	return acc.profiles[idx]
end

function SaveService.load(userId: number): Account
	if memoryFallback[userId] then
		return reconcile(memoryFallback[userId])
	end
	local s = getStore()
	if s then
		local wait = 1
		for i = 1, attempts() do
			local ok, res = pcall(function()
				return s:GetAsync("u_" .. userId)
			end)
			if ok then
				local acc = reconcile(res)
				memoryFallback[userId] = acc
				return acc
			end
			warn(string.format("[SaveService] Carga fallida (%d): %s", i, tostring(res)))
			if i < attempts() then
				task.wait(wait)
				wait *= 2
			end
		end
	end
	local d = SaveService.default()
	d.offline = true
	memoryFallback[userId] = d
	return d
end

function SaveService.save(userId: number, acc: Account): boolean
	local copy = reconcile(acc)
	copy.offline = acc.offline
	memoryFallback[userId] = copy
	if acc.offline then
		return false
	end
	local s = getStore()
	if not s then
		return false
	end
	local payload = {
		v = VERSION,
		activeSlot = copy.activeSlot,
		profiles = copy.profiles,
	}
	local wait = 1
	for i = 1, attempts() do
		local ok, res = pcall(function()
			s:SetAsync("u_" .. userId, payload)
		end)
		if ok then
			return true
		end
		warn(string.format("[SaveService] Guardado fallido (%d): %s", i, tostring(res)))
		if i < attempts() then
			task.wait(wait)
			wait *= 2
		end
	end
	return false
end

-- Libera la cache en memoria al salir el jugador.
function SaveService.release(userId: number)
	memoryFallback[userId] = nil
end

return SaveService
