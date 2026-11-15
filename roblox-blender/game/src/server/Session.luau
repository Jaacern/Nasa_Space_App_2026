--!strict
-- Una sesion por jugador: fases (menu, mision, tutorial, resumen), bucle de simulacion y comandos del cliente.
-- Cada jugador tiene su propia simulacion; el cliente solo recibe lo suyo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Balance = require(ReplicatedStorage.Shared.Balance)
local NasaData = require(ReplicatedStorage.Shared.NasaData)
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

local function clampPosXZ(x: number, z: number): (number, number, boolean)
	local W = Balance.World or { ShipRadius = 8.4, ArenaSafeMargin = 3.0 }
	local minR = W.ShipRadius or 8.4
	local maxR = Balance.Sim.ArenaRadius - (W.ArenaSafeMargin or 3.0)
	local len = math.sqrt(x * x + z * z)
	if len < 0.001 then
		return 0, minR + 2, true
	end
	if len < minR then
		return x / len * minR, z / len * minR, true
	elseif len > maxR then
		return x / len * maxR, z / len * maxR, true
	end
	return x, z, false
end

function Session.new(player: Player, sync: RemoteEvent)
	local self = setmetatable({}, Session)
	self.player = player
	self.sync = sync
	self.account = SaveService.default()
	self.meta = SaveService.activeProfile(self.account).meta
	self.metaLoaded = false
	self.phase = "menu"
	self.R = nil :: Run?
	self.acc = 0
	self.cmdCount = 0
	self.cmdWindow = os.clock()
	task.spawn(function()
		self.account = SaveService.load(player.UserId)
		self.meta = SaveService.activeProfile(self.account).meta
		self.metaLoaded = true
		self:sendPhase()
	end)
	return self
end

function Session:metaPayload()
	local acc = self.account
	local active = SaveService.activeProfile(acc)
	local m = active.meta
	local profiles = {}
	for i = 1, SaveService.MAX_PROFILES do
		local p = acc.profiles[i]
		local cp = p.checkpoint
		table.insert(profiles, {
			slot = i,
			name = p.name,
			science = p.meta.science,
			runs = p.meta.runs,
			wins = p.meta.wins,
			best = p.meta.best,
			checkpoint = if cp then { wave = cp.wave, lvl = cp.lvl, time = math.floor(cp.t), mode = cp.modeName } else nil,
		})
	end
	local acp = active.checkpoint
	return {
		activeSlot = acc.activeSlot,
		profileName = active.name,
		hasCheckpoint = acp ~= nil,
		checkpoint = if acp then { wave = acp.wave, lvl = acp.lvl, time = math.floor(acp.t), mode = acp.modeName } else nil,
		profiles = profiles,
		science = m.science, unlocks = m.unlocks, best = m.best, wins = m.wins, runs = m.runs,
		pieces = m.pieces, tutorialDone = m.tutorialDone, offline = acc.offline == true, loaded = self.metaLoaded,
	}
end

function Session:sendPhase(extra: any?)
	self.sync:FireClient(self.player, nil, { { "phase", self.phase, self:metaPayload(), extra } })
end

function Session:humanoid(): Humanoid?
	local char = self.player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Session:syncMovement(canMove: boolean)
	local hum = self:humanoid()
	if hum then
		if canMove and self.R then
			hum.WalkSpeed = self.R.stats.speed
			hum.JumpPower = Balance.Hero.JumpPower
		else
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end
	end
	if not canMove then
		local char = self.player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(0, hrp.AssemblyLinearVelocity.Y), 0)
		end
	end
end

function Session:save()
	-- Coalescido: una sola escritura en curso; si llegan mas, repite una vez (min 7 s entre escrituras).
	if self.closed then
		return
	end
	if self.saving then
		self.saveDirty = true
		return
	end
	self.saving = true
	task.spawn(function()
		repeat
			local gap = 7 - (os.clock() - (self.lastSaveAt or -math.huge))
			if gap > 0 then
				task.wait(gap)
			end
			self.saveDirty = false
			self.lastSaveAt = os.clock()
			SaveService.save(self.player.UserId, self.account)
		until not self.saveDirty or self.closed
		self.saving = false
	end)
end

function Session:saveCheckpoint(silent: boolean?)
	local R = self.R
	if not R or R.tutorial then
		return
	end
	-- La demo dura 2 minutos y cambia de oleada cada 6 s: no guarda (evita saturar el DataStore).
	if R.mode.Checkpoints == false then
		if not silent then
			table.insert(R.events, { "toastMsg", "CHECKPOINT NO DISPONIBLE", "La demo rápida no guarda la partida." })
		end
		return
	end
	local upCopy: { [string]: number } = {}
	for k, v in R.upgrades do
		upCopy[k] = v
	end
	local itCopy: { [string]: number } = {}
	for k, v in R.items do
		itCopy[k] = v
	end
	local pcCopy = { R.pieces[1] == true, R.pieces[2] == true, R.pieces[3] == true, R.pieces[4] == true }
	local cp = {
		modeName = R.modeName,
		t = R.t,
		real = R.real,
		wave = math.max(1, R.wave),
		biome = math.max(1, R.biome),
		lvl = R.lvl,
		xp = R.xp,
		hp = math.max(1, math.floor(R.hp)),
		shield = R.shield,
		shieldT = R.shieldT,
		shieldMax = R.shieldMax or Balance.Skills.Pulse.Shield,
		kills = R.kills,
		chestsOpened = R.chestsOpened,
		zone = R.zone or 1,
		nextElite = R.nextElite,
		chestT = R.chestT,
		bossIdx = R.bossIdx,
		upgrades = upCopy,
		items = itCopy,
		pieces = pcCopy,
		scienceBonus = R.scienceBonus or 0,
		px = R.px,
		pz = R.pz,
		weaponMode = R.weaponMode or 1,
		savedAt = os.time(),
	}
	local active = SaveService.activeProfile(self.account)
	active.checkpoint = cp
	self:save()
	if not silent then
		table.insert(R.events, { "toastMsg", "CHECKPOINT GUARDADO", string.format("%s · Oleada %d · Nvl %d", active.name, cp.wave, cp.lvl) })
	end
end

function Session:startRun(modeName: string, tutorial: boolean, cp: any?)
	local D = Balance.Director
	local useMode = if cp then cp.modeName else modeName
	local startT = if cp then cp.t else Balance.Debug.StartMinute * 60
	local brief = not tutorial and cp == nil and Balance.Modes[useMode].Briefing ~= false
	local R: Run = {
		mode = Balance.Modes[useMode], modeName = useMode,
		tutorial = if tutorial then { step = 1, init = false, moved = 0, timer = 0, spawnT = 0 } else nil,
		directorOn = not tutorial,
		t = startT, real = if cp then cp.real else 0, stepCount = 0,
		paused = brief, pauseKind = if brief then "briefing" else nil,
		stats = {}, statsDirty = true,
		upgrades = if cp then table.clone(cp.upgrades) else {}, items = if cp then table.clone(cp.items) else {},
		pieces = if cp then table.clone(cp.pieces) else { false, false, false, false }, meta = self.meta,
		hp = 0, shield = if cp then cp.shield else 0, shieldT = if cp then cp.shieldT else 0,
		shieldMax = if cp then (cp.shieldMax or Balance.Skills.Pulse.Shield) else Balance.Skills.Pulse.Shield,
		invuln = 1.5, lastHurt = -99, shelterCd = 0, reviveUsed = false, damageTaken = 0,
		lvl = if cp then cp.lvl else 1, xp = if cp then cp.xp else 0, kills = if cp then cp.kills else 0,
		pendingLevels = 0, choice = nil, chestsOpened = if cp then cp.chestsOpened else 0,
		enemies = {}, nextId = 0, anyDead = false, teles = {}, nextTele = 0,
		shots = {}, nextShot = 0, shotCount = 0, eshots = {}, gems = {}, nextGem = 0, chests = {}, nextChest = 0,
		events = {}, cds = { 0, 0 }, cdMax = { 1, 1 }, used = { false, false },
		atkT = 0.5, auraT = 0, novaT = 1.0, missileT = 0.8, arcT = 0.6,
		weaponMode = if cp and cp.weaponMode then cp.weaponMode else 1,
		spawnAcc = 0, nextElite = if cp then cp.nextElite else (startT + D.EliteInterval),
		chestT = if cp then cp.chestT else D.ChestInterval * 0.5, hazT = 0, hazN = 0,
		meteorT = 12, meteorN = 0, bhT = Balance.BlackHole.FirstAt, bhIdx = 0,
		wave = if cp then cp.wave else 0, waveSaved = if cp then cp.wave else 1,
		bossIdx = if cp then cp.bossIdx else 1, boss = nil, bossKilled = nil,
		biome = if cp then cp.biome else 1, zone = if cp then cp.zone else 1,
		scienceBonus = if cp then (cp.scienceBonus or 0) else 0,
		px = 0, pz = 0, won = false,
	}
	Loot.recompute(R)
	R.hp = if cp then math.clamp(cp.hp, 1, R.stats.maxHp) else R.stats.maxHp
	local sx, sz = WorldBuilder.SpawnPosition.X, WorldBuilder.SpawnPosition.Z
	if cp then
		sx, sz = clampPosXZ(cp.px, cp.pz)
	end
	R.px, R.pz = sx, sz
	local char = self.player.Character
	if char then
		char:PivotTo(CFrame.new(sx, 4, sz))
	end
	self.R = R
	self.acc = 0
	self.lastMode = useMode
	self.phase = if tutorial then "tutorial" else "run"
	self:sendPhase({ mode = useMode })
	if tutorial then
		table.insert(R.events, { "tut", 1 })
	elseif cp then
		table.insert(R.events, { "wave", R.wave, Balance.Run.TotalWaves })
		table.insert(R.events, { "biome", R.biome })
		table.insert(R.events, { "zone", R.zone })
		table.insert(R.events, { "weaponMode", R.weaponMode or 1 })
		for id, lv in R.upgrades do
			table.insert(R.events, { "chosen", id, lv })
		end
		table.insert(R.events, { "toastMsg", "CHECKPOINT CARGADO", string.format("Retomando Oleada %d · Nvl %d", R.wave, R.lvl) })
	elseif brief then
		table.insert(R.events, { "briefing", 1 })
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
				math.ceil(R.hp), s.maxHp, math.floor(R.shield), math.floor(R.xp), Balance.levelNeed(R.lvl, R.mode.LevelCost), R.lvl, R.kills,
				math.floor(R.t), r1(R.cds[1]), r1(R.cdMax[1]), r1(R.cds[2]), r1(R.cdMax[2]),
				if boss then math.max(0, boss.hp / boss.hpMax) else -1, s.drones, if s.aura > 0 then 1 else 0, r1(R.real),
				if R.invuln > 0.5 then 1 else 0, if R.paused then 1 else 0, s.pickup, R.wave,
				math.ceil(R.shieldMax or Balance.Skills.Pulse.Shield), r1(math.max(0, R.shieldT)), R.zone or 1, R.weaponMode or 1,
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
	local science = math.floor(R.kills * M.SciencePerKill + R.t / 60 / R.mode.TimeScale * M.SciencePerMinute + pieces * M.SciencePerPiece + (if win then M.ScienceWin else 0) + (R.scienceBonus or 0))
	meta.science += science
	meta.runs += 1
	if win then
		meta.wins += 1
		if R.mode.Checkpoints ~= false then
			SaveService.activeProfile(self.account).checkpoint = nil
		end
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
	self:syncMovement(false)
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
	self:syncMovement(false)
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
		Loot.spawnChest(R, e.x, e.z, if idx >= 2 then 4 else 3)
		self:saveCheckpoint(true)
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
	if ((R.meta.unlocks.revive or 0) > 0 or R.mode.FreeRevive == true) and not R.reviveUsed then
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
	local cx, cz, moved = clampPosXZ(hrp.Position.X, hrp.Position.Z)
	if moved or hrp.Position.Y < 0.4 then
		local ny = math.max(hrp.Position.Y, 3.2)
		hrp.CFrame = CFrame.new(cx, ny, cz) * hrp.CFrame.Rotation
	end
	R.px, R.pz = cx, cz
	local newZone = Loot.computeZone(cx, cz)
	if newZone ~= R.zone then
		R.zone = newZone
		Loot.recompute(R)
		table.insert(R.events, { "zone", newZone })
	end
	R.stepCount += 1
	if not R.paused then
		R.real += dt
		if R.directorOn then
			R.t += dt * R.mode.TimeScale
			R.bhT -= dt
			if R.bhT <= 0 then
				R.bhT = Balance.BlackHole.Interval
				R.bhIdx += 1
				-- El cliente rotula el evento con NasaData.blackHoleForEvent (no es clima espacial DONKI).
				table.insert(R.events, { "blackhole", R.bhIdx, Balance.BlackHole.Duration })
			end
		end
		Combat.update(R, dt)
		Enemies.update(R, dt)
		Loot.update(R, dt)
		if not R.tutorial and R.wave > (R.waveSaved or 1) and R.pendingLevels == 0 and not R.choice then
			R.waveSaved = R.wave
			self:saveCheckpoint(true)
		end
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
	if R.statsDirty or R.paused ~= R.lastPaused then
		R.statsDirty = false
		R.lastPaused = R.paused
		self:syncMovement(not R.paused)
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
	elseif name == "resume" then
		if not R and self.metaLoaded then
			local cp = SaveService.activeProfile(self.account).checkpoint
			if cp then
				self:startRun(cp.modeName, false, cp)
			end
		end
	elseif name == "briefOk" then
		if R and R.pauseKind == "briefing" then
			R.paused = false
			R.pauseKind = nil
			table.insert(R.events, { "briefing", 0 })
		end
	elseif name == "saveCheckpoint" then
		if R and not R.tutorial then
			self:saveCheckpoint(false)
		end
	elseif name == "restart" then
		if R then
			local mode = if R.tutorial then "full" else R.modeName
			local tut = R.tutorial ~= nil
			Enemies.clear(R)
			self:flush(R, false)
			self.R = nil
			self:startRun(mode, tut)
		end
	elseif name == "selectProfile" then
		if not R and self.metaLoaded and type(a) == "number" then
			local slot = math.clamp(math.floor(a), 1, SaveService.MAX_PROFILES)
			self.account.activeSlot = slot
			self.meta = SaveService.activeProfile(self.account).meta
			self:save()
			self:sendPhase()
		end
	elseif name == "resetProfile" then
		if not R and self.metaLoaded and type(a) == "number" then
			local slot = math.clamp(math.floor(a), 1, SaveService.MAX_PROFILES)
			self.account.profiles[slot] = SaveService.defaultProfile(slot)
			self.meta = SaveService.activeProfile(self.account).meta
			self:save()
			self:sendPhase()
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
	elseif name == "weaponMode" then
		if R then
			local maxM = #Balance.WeaponModes
			local nextMode = if type(a) == "number" and a >= 1 and a <= maxM then math.floor(a) else (((R.weaponMode or 1) % maxM) + 1)
			R.weaponMode = nextMode
			table.insert(R.events, { "weaponMode", nextMode })
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
			elseif a == "direct" then
				if R.won then
					self:finish(true)
					return
				end
				if R.hp > 0 and R.pauseKind ~= "briefing" and R.pendingLevels == 0 and not R.choice and (R.wave > 1 or R.lvl > 1 or R.kills > 0) then
					self:saveCheckpoint(true)
				end
				Enemies.clear(R)
				self:flush(R, false)
				self.R = nil
				self.phase = "menu"
				self:syncMovement(false)
				self:sendPhase()
			else
				self:finish(R.won == true)
			end
		else
			self.phase = "menu"
			self:syncMovement(false)
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
