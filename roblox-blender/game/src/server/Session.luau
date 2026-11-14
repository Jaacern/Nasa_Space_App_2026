--!strict
-- Una sesion por jugador: fases (menu, mision, tutorial, resumen), bucle de simulacion y comandos del cliente.
-- Cada jugador tiene su propia simulacion; el cliente solo recibe lo suyo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Balance = require(ReplicatedStorage.Shared.Balance)
local Loot = require(script.Parent.Loot)
local Combat = require(script.Parent.Combat)
local Enemies = require(script.Parent.Enemies)
local SaveService = require(script.Parent.SaveService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Session = {}
Session.__index = Session
type Run = any

local function r1(v: number): number
	return math.round(v * 10) / 10
end

function Session.new(player: Player, sync: RemoteEvent)
	local self = setmetatable({}, Session)
	self.player = player
	self.sync = sync
	self.meta = SaveService.default()
	self.metaLoaded = false
	self.phase = "menu"
	self.R = nil :: Run?
	self.acc = 0
	self.cmdCount = 0
	self.cmdWindow = os.clock()
	task.spawn(function()
		self.meta = SaveService.load(player.UserId)
		self.metaLoaded = true
		self:sendPhase()
	end)
	return self
end

function Session:metaPayload()
	local m = self.meta
	return {
		science = m.science, unlocks = m.unlocks, best = m.best, wins = m.wins, runs = m.runs,
		pieces = m.pieces, tutorialDone = m.tutorialDone, offline = m.offline == true, loaded = self.metaLoaded,
	}
end

function Session:sendPhase(extra: any?)
	self.sync:FireClient(self.player, nil, { { "phase", self.phase, self:metaPayload(), extra } })
end

function Session:humanoid(): Humanoid?
	local char = self.player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Session:save()
	local meta = self.meta
	local userId = self.player.UserId
	task.spawn(function()
		SaveService.save(userId, meta)
	end)
end

function Session:startRun(modeName: string, tutorial: boolean)
	local D = Balance.Director
	local R: Run = {
		mode = Balance.Modes[modeName], modeName = modeName,
		tutorial = if tutorial then { step = 1, init = false, moved = 0, timer = 0, spawnT = 0 } else nil,
		directorOn = not tutorial,
		t = Balance.Debug.StartMinute * 60, real = 0, stepCount = 0, paused = false, pauseKind = nil,
		stats = {}, statsDirty = true, upgrades = {}, items = {}, pieces = { false, false, false, false }, meta = self.meta,
		hp = 0, shield = 0, shieldT = 0, invuln = 1.5, lastHurt = -99, shelterCd = 0, reviveUsed = false, damageTaken = 0,
		lvl = 1, xp = 0, kills = 0, pendingLevels = 0, choice = nil, chestsOpened = 0,
		enemies = {}, nextId = 0, anyDead = false, teles = {}, nextTele = 0,
		shots = {}, nextShot = 0, shotCount = 0, eshots = {}, gems = {}, nextGem = 0, chests = {}, nextChest = 0,
		events = {}, cds = { 0, 0 }, cdMax = { 1, 1 }, used = { false, false }, atkT = 0.5, auraT = 0,
		spawnAcc = 0, nextElite = D.EliteInterval, chestT = D.ChestInterval * 0.5, hazT = 0, hazN = 0,
		wave = 0, bossIdx = 1, boss = nil, bossKilled = nil, biome = 1, px = 0, pz = 0, won = false,
	}
	Loot.recompute(R)
	R.hp = R.stats.maxHp
	local char = self.player.Character
	if char then
		char:PivotTo(CFrame.new(WorldBuilder.SpawnPosition))
	end
	self.R = R
	self.acc = 0
	self.lastMode = modeName
	self.phase = if tutorial then "tutorial" else "run"
	self:sendPhase({ mode = modeName })
	if tutorial then
		table.insert(R.events, { "tut", 1 })
	end
end

function Session:flush(R: Run, withSnapshot: boolean)
	local snap = nil
	if withSnapshot then
		local pos = table.create(#R.enemies * 3)
		for _, e in R.enemies do
			if not e.dead then
				table.insert(pos, e.id)
				table.insert(pos, r1(e.x))
				table.insert(pos, r1(e.z))
			end
		end
		local s = R.stats
		local boss = R.boss
		snap = {
			pos = pos,
			hud = {
				math.ceil(R.hp), s.maxHp, math.floor(R.shield), math.floor(R.xp), Balance.xpNeeded(R.lvl), R.lvl, R.kills,
				math.floor(R.t), r1(R.cds[1]), r1(R.cdMax[1]), r1(R.cds[2]), r1(R.cdMax[2]),
				if boss then math.max(0, boss.hp / boss.hpMax) else -1, s.drones, if s.aura > 0 then 1 else 0, r1(R.real),
				if R.invuln > 0.5 then 1 else 0, if R.paused then 1 else 0, s.pickup, R.wave,
			},
		}
	end
	if snap or #R.events > 0 then
		self.sync:FireClient(self.player, snap, R.events)
		R.events = {}
	end
end

function Session:finish(win: boolean)
	local R = self.R
	if not R then
		return
	end
	local M = Balance.Meta
	local meta = self.meta
	local pieces = 0
	for i = 1, 4 do
		if R.pieces[i] then
			pieces += 1
			meta.pieces[i] = true
		end
	end
	local science = math.floor(R.kills * M.SciencePerKill + R.t / 60 * M.SciencePerMinute + pieces * M.SciencePerPiece + (if win then M.ScienceWin else 0))
	meta.science += science
	meta.runs += 1
	if win then
		meta.wins += 1
	end
	meta.best.time = math.max(meta.best.time, math.floor(R.t))
	meta.best.level = math.max(meta.best.level, R.lvl)
	meta.best.kills = math.max(meta.best.kills, R.kills)
	local summary = {
		win = win, time = math.floor(R.t), level = R.lvl, kills = R.kills, items = R.items, upgrades = R.upgrades,
		pieces = R.pieces, science = science, mode = R.modeName, chests = R.chestsOpened,
	}
	Enemies.clear(R)
	self:flush(R, false)
	self.R = nil
	self.phase = if win then "victory" else "defeat"
	self:sendPhase(summary)
	self:save()
end

function Session:endTutorial()
	local R = self.R
	if R then
		Enemies.clear(R)
		self:flush(R, false)
	end
	self.R = nil
	self.phase = "menu"
	self:sendPhase()
end

function Session:onBossKilled(R: Run)
	local e = R.bossKilled
	R.bossKilled = nil
	R.boss = nil
	local idx: number = e.bossIdx
	R.pieces[idx] = true
	R.bossIdx = idx + 1
	Loot.recompute(R)
	local bonus = Balance.Pieces[idx] :: any
	R.hp = math.min(R.stats.maxHp, R.hp + (bonus.heal or 0) + (bonus.maxHp or 0))
	if idx < 4 then
		Loot.spawnChest(R, e.x, e.z)
	else
		Enemies.clear(R)
		R.won = true
	end
	table.insert(R.events, { "piece", idx })
	R.paused = true
	R.pauseKind = "piece"
end

function Session:onDeath(R: Run)
	local rv = Balance.Meta.revive
	if (R.meta.unlocks.revive or 0) > 0 and not R.reviveUsed then
		R.reviveUsed = true
		R.hp = R.stats.maxHp * rv.per
		R.invuln = 2.5
		local P = Balance.Skills.Pulse
		Combat.areaDamage(R, R.px, R.pz, P.Radius, P.Damage * 2, P.Knockback)
		table.insert(R.events, { "skill", 2, 0, 0 })
		table.insert(R.events, { "alert", "PROTOCOLO DE EMERGENCIA: SISTEMAS RESTAURADOS", "good" })
		return
	end
	self:finish(false)
end

function Session:updateTutorial(R: Run, dt: number)
	local T = R.tutorial
	local TB = Balance.Tutorial
	local function advance()
		T.step += 1
		T.init = false
		table.insert(R.events, { "tut", T.step })
	end
	local step = T.step
	if step == 1 then
		if T.lx then
			T.moved += math.sqrt((R.px - T.lx) ^ 2 + (R.pz - T.lz) ^ 2)
		end
		T.lx, T.lz = R.px, R.pz
		if T.moved >= TB.MoveDistance then
			advance()
		end
	elseif step == 2 then
		if not T.init then
			T.init = true
			T.k0 = R.kills
			for i = 1, TB.Dummies do
				local a = i / TB.Dummies * math.pi * 2
				local e = Enemies.spawn(R, "chaser", R.px + math.cos(a) * 26, R.pz + math.sin(a) * 26)
				e.speed = 6
			end
		end
		if R.kills - T.k0 >= TB.Dummies then
			advance()
		end
	elseif step == 3 then
		if R.lvl >= 2 and R.pendingLevels == 0 and not R.paused then
			advance()
		elseif #R.gems == 0 and R.lvl < 2 then
			for i = 1, 6 do
				local a = i / 6 * math.pi * 2
				Loot.dropGem(R, R.px + math.cos(a) * 14, R.pz + math.sin(a) * 14, 2)
			end
		end
	elseif step == 4 then
		if not T.init then
			T.init = true
			T.timer = TB.TelegraphDelay + 0.6
			Enemies.addTele(R, { shape = "c", x = R.px, z = R.pz, r = 9, t = TB.TelegraphDelay, dmg = 10 })
		end
		T.timer -= dt
		if T.timer <= 0 then
			advance()
		end
	elseif step == 5 or step == 6 then
		local idx = step - 4
		if not T.init then
			T.init = true
			R.used[idx] = false
			R.cds[idx] = 0
		end
		if R.used[idx] then
			advance()
		end
	elseif step == 7 then
		if not T.init then
			T.init = true
			T.c0 = R.chestsOpened
			Loot.spawnChest(R, R.px + 30, R.pz)
		end
		if R.chestsOpened > T.c0 then
			advance()
			if not self.meta.tutorialDone then
				self.meta.tutorialDone = true
				self:save()
			end
		end
	else
		T.spawnT -= dt
		if T.spawnT <= 0 then
			T.spawnT = 1.5
			if #R.enemies < 14 then
				local a = math.random() * math.pi * 2
				Enemies.spawn(R, if math.random() < 0.7 then "chaser" else "tank", R.px + math.cos(a) * 50, R.pz + math.sin(a) * 50)
			end
		end
	end
end

function Session:step(dt: number)
	local R = self.R
	if not R then
		return
	end
	local char = self.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	R.px, R.pz = hrp.Position.X, hrp.Position.Z
	R.stepCount += 1
	if not R.paused then
		R.real += dt
		if R.directorOn then
			R.t += dt * R.mode.TimeScale
		end
		Combat.update(R, dt)
		Enemies.update(R, dt)
		Loot.update(R, dt)
		if R.tutorial then
			self:updateTutorial(R, dt)
		end
		if R.hp <= 0 then
			self:onDeath(R)
		end
	end
	if self.R ~= R then
		return
	end
	if R.bossKilled and not R.paused then
		self:onBossKilled(R)
	end
	if R.statsDirty then
		R.statsDirty = false
		local hum = self:humanoid()
		if hum then
			hum.WalkSpeed = R.stats.speed
		end
	end
	self:flush(R, R.stepCount % Balance.Sim.SnapshotEvery == 0)
end

function Session:update(dt: number)
	if not self.R then
		return
	end
	local step = Balance.Sim.Step
	self.acc += math.min(dt, 0.25)
	while self.acc >= step do
		self.acc -= step
		self:step(step)
	end
end

function Session:onCmd(name: any, a: any, b: any, c: any)
	local now = os.clock()
	if now - self.cmdWindow >= 1 then
		self.cmdWindow = now
		self.cmdCount = 0
	end
	self.cmdCount += 1
	if self.cmdCount > Balance.Sim.MaxCmdsPerSecond or type(name) ~= "string" then
		return
	end
	local R = self.R
	if name == "ready" then
		self:sendPhase()
	elseif name == "start" then
		if not R and self.metaLoaded then
			self:startRun(if a == "demo" then "demo" else "full", false)
		end
	elseif name == "tutorial" then
		if not R and self.metaLoaded then
			self:startRun("full", true)
		end
	elseif name == "skill" then
		if R and (a == 1 or a == 2) and type(b) == "number" and type(c) == "number" and b == b and c == c then
			Combat.useSkill(R, a, math.clamp(b, -1, 1), math.clamp(c, -1, 1))
		end
	elseif name == "choose" then
		if R and R.choice and type(a) == "number" then
			local opt = R.choice[a]
			if opt then
				local id = opt.id
				R.choice = nil
				R.pendingLevels = math.max(0, R.pendingLevels - 1)
				Loot.applyChoice(R, opt)
				R.paused = false
				R.pauseKind = nil
				table.insert(R.events, { "chosen", id, R.upgrades[id] or 0 })
			end
		end
	elseif name == "continue" then
		if R and R.pauseKind == "piece" then
			R.paused = false
			R.pauseKind = nil
			if R.won then
				self:finish(true)
			end
		end
	elseif name == "pause" then
		if R then
			if not R.paused then
				R.paused = true
				R.pauseKind = "user"
				table.insert(R.events, { "paused", 1 })
			elseif R.pauseKind == "user" then
				R.paused = false
				R.pauseKind = nil
				table.insert(R.events, { "paused", 0 })
			end
		end
	elseif name == "menu" then
		if R then
			if R.tutorial then
				self:endTutorial()
			else
				self:finish(false)
			end
		else
			self.phase = "menu"
			self:sendPhase()
		end
	elseif name == "debug" then
		-- Solo en Studio: atajos para ensayar la demo y probar jefes.
		if RunService:IsStudio() then
			if a == "invincible" then
				Balance.Debug.Invincible = b == true
			elseif a == "time" and R and type(b) == "number" then
				R.t = b
			elseif a == "xp" and R and type(b) == "number" then
				Loot.addXp(R, b)
			elseif a == "item" and R and type(b) == "string" and (Balance.Items :: any)[b] then
				Loot.giveItem(R, b)
			elseif a == "bosshp" and R and R.boss and type(b) == "number" then
				R.boss.hp = math.min(R.boss.hp, b)
			elseif a == "hp" and R and type(b) == "number" then
				R.hp = b
			elseif a == "science" and not R and type(b) == "number" then
				self.meta.science += b
				self:sendPhase()
			end
		end
	elseif name == "buy" then
		if not R and self.metaLoaded and type(a) == "string" then
			local def = (Balance.Meta :: any)[a]
			local lvl = self.meta.unlocks[a]
			if type(def) == "table" and def.max and lvl and lvl < def.max then
				local cost = def.cost * (lvl + 1)
				if self.meta.science >= cost then
					self.meta.science -= cost
					self.meta.unlocks[a] = lvl + 1
					self:save()
					self:sendPhase()
				end
			end
		end
	end
end

return Session
