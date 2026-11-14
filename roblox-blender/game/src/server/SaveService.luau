--!strict
-- Meta-progresion en DataStore. Toda llamada va en pcall con reintentos y espera creciente.
-- Si la carga falla, la sesion sigue en memoria y NO se guarda (para no pisar datos reales).

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local SaveService = {}

local STORE_NAME = "AresForgeMeta_v1"
local VERSION = 1

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

function SaveService.default(): Meta
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

local store: DataStore? = nil
local storeTried = false

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

local function reconcile(data: any): Meta
	local d = SaveService.default()
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
		d.wins = data.wins
	end
	if type(data.runs) == "number" then
		d.runs = data.runs
	end
	if type(data.pieces) == "table" then
		for i = 1, 4 do
			d.pieces[i] = data.pieces[i] == true
		end
	end
	d.tutorialDone = data.tutorialDone == true
	return d
end

-- Bloquea hasta terminar. Devuelve datos y si quedaron en modo sin conexion.
function SaveService.load(userId: number): Meta
	local s = getStore()
	if s then
		local wait = 1
		for i = 1, attempts() do
			local ok, res = pcall(function()
				return s:GetAsync("u_" .. userId)
			end)
			if ok then
				return reconcile(res)
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
	return d
end

function SaveService.save(userId: number, meta: Meta): boolean
	if meta.offline then
		return false
	end
	local s = getStore()
	if not s then
		return false
	end
	local copy = reconcile(meta)
	local wait = 1
	for i = 1, attempts() do
		local ok, res = pcall(function()
			s:SetAsync("u_" .. userId, copy)
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

return SaveService
