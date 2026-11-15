--!strict
-- Director de oleadas, IA por lotes (10 Hz), avisos de ataque (telegraphs), jefes y proyectiles enemigos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage.Shared.Balance)
local NasaData = require(ReplicatedStorage.Shared.NasaData)
local Combat = require(script.Parent.Combat)

local Enemies = {}
type Run = any

local rng = Random.new()
local function r1(v: number): number
	return math.round(v * 10) / 10
end

local function clampArena(x: number, z: number, margin: number): (number, number)
	local lim = Balance.Sim.ArenaRadius - margin
	local len = math.sqrt(x * x + z * z)
	if len > lim then
		return x / len * lim, z / len * lim
	end
	return x, z
end

local function ringPoint(R: Run): (number, number)
	local S = Balance.Sim
	local lim = S.ArenaRadius - 6
	for _ = 1, 8 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(S.SpawnMinDist, S.SpawnMaxDist)
		local x, z = R.px + math.cos(a) * d, R.pz + math.sin(a) * d
		if x * x + z * z <= lim * lim then
			return x, z
		end
	end
	-- cerca del borde: aparece hacia el centro de la arena
	local len = math.max(1, math.sqrt(R.px * R.px + R.pz * R.pz))
	return R.px - R.px / len * S.SpawnMinDist, R.pz - R.pz / len * S.SpawnMinDist
end

function Enemies.spawn(R: Run, ai: string, x: number, z: number): any
	local def = Balance.Enemies[ai]
	local minutes = R.t / 60
	R.nextId += 1
	local hp = def.hp * Balance.hpMult(minutes)
	local e = {
		id = R.nextId, kind = ai, ai = ai, def = def, x = x, z = z, hp = hp, hpMax = hp,
		r = def.radius, speed = def.speed, dmg = def.dmg * Balance.dmgMult(minutes), xp = def.xp,
		cd = rng:NextNumber(0.2, 1.2), state = "move", wind = 0, vx = 0, vz = 0, kx = 0, kz = 0,
		side = if rng:NextNumber() < 0.5 then 1 else -1, contact = (ai == "chaser"),
		dead = false, elite = false, boss = false,
	}
	table.insert(R.enemies, e)
	table.insert(R.events, { "spawn", e.id, e.kind, r1(x), r1(z) })
	return e
end

local function spawnElite(R: Run)
	local x, z = ringPoint(R)
	local e = Enemies.spawn(R, "elite", x, z)
	e.kind = "elite" .. R.biome
	e.elite = true
	e.contact = true
	e.patterns = { Balance.Patterns.elite[R.biome] }
	e.patIdx = 0
	e.cycle = Balance.Enemies.elite.atkCd
	e.cd = 2
	R.events[#R.events][3] = e.kind
	table.insert(R.events, { "alert", "ENEMIGO DE ÉLITE DETECTADO", "warn" })
end

function Enemies.spawnBoss(R: Run, idx: number)
	local def = Balance.Bosses[idx]
	local x, z = ringPoint(R)
	R.nextId += 1
	local e = {
		id = R.nextId, kind = def.id, ai = "boss", def = def, x = x, z = z, hp = def.hp, hpMax = def.hp,
		r = def.radius, speed = def.speed, dmg = def.dmg, xp = def.xp,
		cd = 2.5, state = "move", wind = 0, vx = 0, vz = 0, kx = 0, kz = 0, side = 1, contact = true,
		dead = false, elite = false, boss = true, bossIdx = idx, patterns = def.patterns, patIdx = 0, cycle = def.cycle,
	}
	table.insert(R.enemies, e)
	R.boss = e
	table.insert(R.events, { "spawn", e.id, e.kind, r1(x), r1(z) })
	table.insert(R.events, { "boss", idx })
end

local function addTele(R: Run, t: any)
	R.nextTele += 1
	t.id = R.nextTele
	table.insert(R.teles, t)
	if t.shape == "c" or t.shape == "m" then
		table.insert(R.events, { "tele", t.id, t.shape, r1(t.x), r1(t.z), t.r, t.t })
	else
		table.insert(R.events, { "tele", t.id, "l", r1(t.x), r1(t.z), r1(t.x2), r1(t.z2), t.w, t.t, t.dmg > 0 and 1 or 0 })
	end
end

local function doPattern(R: Run, e: any, pat: string, nx: number, nz: number)
	local P = Balance.Patterns
	if pat == "charge" then
		local c = P.charge
		local x2, z2 = clampArena(e.x + nx * c.length, e.z + nz * c.length, 4)
		addTele(R, { shape = "l", x = e.x, z = e.z, x2 = x2, z2 = z2, w = c.width + e.r, t = c.delay, dmg = e.dmg, owner = e, act = "moveTo" })
		e.state, e.wind = "wind", c.delay
	elseif pat == "slam" then
		local c = P.slam
		addTele(R, { shape = "c", x = R.px, z = R.pz, r = c.radius, t = c.delay, dmg = e.dmg, owner = e, act = "moveTo", x2 = R.px, z2 = R.pz })
		e.state, e.wind = "wind", c.delay
	elseif pat == "rocks" then
		local c = P.rocks
		for i = 1, c.count do
			local ox, oz = 0, 0
			if i > 1 then
				local a = rng:NextNumber(0, math.pi * 2)
				local d = rng:NextNumber(4, c.spread)
				ox, oz = math.cos(a) * d, math.sin(a) * d
			end
			addTele(R, { shape = "c", x = R.px + ox, z = R.pz + oz, r = c.radius, t = c.delay + (i - 1) * 0.12, dmg = e.dmg * 0.8, owner = e })
		end
	elseif pat == "nova" then
		local c = P.nova
		addTele(R, { shape = "c", x = e.x, z = e.z, r = e.r + 4, t = c.delay, dmg = e.dmg, owner = e, act = "nova" })
		e.state, e.wind = "wind", c.delay
	elseif pat == "summon" then
		for i = 1, P.summon.count do
			if #R.enemies < Balance.Sim.MaxEnemies then
				local a = i / P.summon.count * math.pi * 2
				local x, z = clampArena(e.x + math.cos(a) * (e.r + 5), e.z + math.sin(a) * (e.r + 5), 4)
				Enemies.spawn(R, "chaser", x, z)
			end
		end
	end
end

local function decide(R: Run, e: any, d: number, nx: number, nz: number)
	local ai, def = e.ai, e.def
	if ai == "chaser" then
		e.vx, e.vz = nx * e.speed, nz * e.speed
	elseif ai == "tank" then
		if d < def.atkRange + e.r and e.cd <= 0 then
			addTele(R, { shape = "c", x = e.x, z = e.z, r = def.atkRadius, t = def.wind, dmg = e.dmg, owner = e })
			e.state, e.wind, e.cd = "wind", def.wind, def.atkCd
		else
			e.vx, e.vz = nx * e.speed, nz * e.speed
		end
	elseif ai == "ranged" then
		if d < def.atkRange and e.cd <= 0 then
			local len = def.atkRange + 6
			addTele(R, { shape = "l", x = e.x, z = e.z, x2 = e.x + nx * len, z2 = e.z + nz * len, w = 1.6, t = def.wind, dmg = 0, owner = e, act = "shoot", dx = nx, dz = nz })
			e.state, e.wind, e.cd = "wind", def.wind, def.atkCd
		elseif d > def.keepMax then
			e.vx, e.vz = nx * e.speed, nz * e.speed
		elseif d < def.keepMin then
			e.vx, e.vz = -nx * e.speed, -nz * e.speed
		else
			e.vx, e.vz = -nz * e.speed * 0.5 * e.side, nx * e.speed * 0.5 * e.side
		end
	elseif ai == "kamikaze" then
		if d < def.atkRange then
			addTele(R, { shape = "c", x = e.x, z = e.z, r = def.atkRadius, t = def.wind, dmg = e.dmg, owner = e, act = "explode" })
			e.state, e.wind = "wind", def.wind + 0.2
		else
			e.vx, e.vz = nx * e.speed, nz * e.speed
		end
	else -- elite y boss
		if e.cd <= 0 then
			e.patIdx = e.patIdx % #e.patterns + 1
			local cycle = e.cycle
			if e.boss and e.def.enrageAt and e.hp < e.hpMax * e.def.enrageAt then
				cycle = e.def.enrageCycle
				if not e.enraged then
					e.enraged = true
					table.insert(R.events, { "alert", "EL COLOSO ENTRA EN FURIA", "warn" })
				end
			end
			e.cd = cycle
			e.vx, e.vz = 0, 0
			doPattern(R, e, e.patterns[e.patIdx], nx, nz)
		elseif d > e.r + 1 then
			e.vx, e.vz = nx * e.speed, nz * e.speed
		else
			e.vx, e.vz = 0, 0
		end
	end
end

local function resolveTeles(R: Run, dt: number)
	local teles = R.teles
	local hr = Balance.Hero.Radius * 0.5
	for i = #teles, 1, -1 do
		local t = teles[i]
		local owner = t.owner
		if owner and owner.dead then
			table.insert(R.events, { "teleEnd", t.id })
			table.remove(teles, i)
			continue
		end
		t.t -= dt
		if t.t > 0 then
			continue
		end
		table.remove(teles, i)
		if t.dmg > 0 then
			local inside = false
			if t.shape == "c" or t.shape == "m" then
				local dx, dz = R.px - t.x, R.pz - t.z
				inside = dx * dx + dz * dz <= (t.r + hr) * (t.r + hr)
			else
				local lx, lz = t.x2 - t.x, t.z2 - t.z
				local len = math.max(0.01, math.sqrt(lx * lx + lz * lz))
				lx, lz = lx / len, lz / len
				local rx, rz = R.px - t.x, R.pz - t.z
				local along = math.clamp(rx * lx + rz * lz, 0, len)
				local qx, qz = rx - lx * along, rz - lz * along
				local w = t.w / 2 + hr
				inside = qx * qx + qz * qz <= w * w
			end
			if inside then
				Combat.damagePlayer(R, t.dmg)
			end
		end
		if t.shape == "m" then
			table.insert(R.events, { "meteorBoom", math.round(t.x), math.round(t.z), t.r })
		end
		if owner then
			if t.act == "shoot" then
				local def = owner.def
				R.nextShot += 1
				table.insert(R.eshots, { id = R.nextShot, x = owner.x, z = owner.z, vx = t.dx * def.shotSpeed, vz = t.dz * def.shotSpeed, r = def.shotRadius, dmg = owner.dmg, life = def.shotLife })
				table.insert(R.events, { "eshot", R.nextShot, r1(owner.x), r1(owner.z), r1(t.dx * def.shotSpeed), r1(t.dz * def.shotSpeed), def.shotLife })
			elseif t.act == "explode" then
				table.insert(R.events, { "boom", math.round(t.x), math.round(t.z), t.r })
				Combat.kill(R, owner)
			elseif t.act == "moveTo" then
				owner.x, owner.z = t.x2, t.z2
				owner.tp = true
			elseif t.act == "nova" then
				local c = Balance.Patterns.nova
				for k = 1, c.count do
					local a = k / c.count * math.pi * 2 + owner.patIdx
					local vx, vz = math.cos(a) * c.speed, math.sin(a) * c.speed
					R.nextShot += 1
					table.insert(R.eshots, { id = R.nextShot, x = owner.x, z = owner.z, vx = vx, vz = vz, r = c.radius, dmg = owner.dmg * 0.7, life = c.life })
					table.insert(R.events, { "eshot", R.nextShot, r1(owner.x), r1(owner.z), r1(vx), r1(vz), c.life })
				end
			end
		end
	end
end

local function stepEShots(R: Run, dt: number)
	local list = R.eshots
	local hr = Balance.Hero.Radius
	for i = #list, 1, -1 do
		local s = list[i]
		s.x += s.vx * dt
		s.z += s.vz * dt
		s.life -= dt
		local dx, dz = s.x - R.px, s.z - R.pz
		local rr = s.r + hr
		local hit = dx * dx + dz * dz <= rr * rr
		if hit then
			Combat.damagePlayer(R, s.dmg)
			table.insert(R.events, { "eshotEnd", s.id })
		end
		if hit or s.life <= 0 then
			list[i] = list[#list]
			list[#list] = nil
		end
	end
end

local function separate(R: Run)
	local list = R.enemies
	local n = #list
	for i = 1, n - 1 do
		local a = list[i]
		if a.dead then
			continue
		end
		for j = i + 1, n do
			local b = list[j]
			if b.dead then
				continue
			end
			local dx, dz = b.x - a.x, b.z - a.z
			local rr = (a.r + b.r) * 0.9
			local d2 = dx * dx + dz * dz
			if d2 < rr * rr and d2 > 0.0001 then
				local d = math.sqrt(d2)
				local push = (rr - d) * 0.5
				local ux, uz = dx / d, dz / d
				if a.boss or a.state == "wind" then
					b.x += ux * push * 2
					b.z += uz * push * 2
				elseif b.boss or b.state == "wind" then
					a.x -= ux * push * 2
					a.z -= uz * push * 2
				else
					a.x -= ux * push
					a.z -= uz * push
					b.x += ux * push
					b.z += uz * push
				end
			end
		end
	end
end

local function pickKind(R: Run): string
	local D = Balance.Director
	local w = D.Weights
	local pool = { { "chaser", w.chaser } }
	if R.t >= D.UnlockKamikaze then
		table.insert(pool, { "kamikaze", w.kamikaze })
	end
	if R.t >= D.UnlockRanged then
		table.insert(pool, { "ranged", w.ranged })
	end
	if R.t >= D.UnlockTank then
		table.insert(pool, { "tank", w.tank })
	end
	local total = 0
	for _, p in pool do
		total += p[2] :: number
	end
	local roll = rng:NextNumber(0, total)
	for _, p in pool do
		roll -= p[2] :: number
		if roll <= 0 then
			return p[1] :: string
		end
	end
	return "chaser"
end

local function director(R: Run, dt: number)
	local D, Run = Balance.Director, Balance.Run
	local rate = (D.RateBase + D.RatePerMinute * R.t / 60) * (R.boss and D.BossRateMult or 1)
	R.spawnAcc += rate * dt
	while R.spawnAcc >= 1 do
		R.spawnAcc -= 1
		if #R.enemies < Balance.Sim.MaxEnemies then
			local x, z = ringPoint(R)
			Enemies.spawn(R, pickKind(R), x, z)
		end
	end

	if not R.boss then
		if R.t >= R.nextElite and R.bossIdx <= 4 then
			R.nextElite += D.EliteInterval
			spawnElite(R)
		end
		local due = if R.bossIdx <= 3 then Run.MiniBossTimes[R.bossIdx] elseif R.bossIdx == 4 then Run.FinalBossTime else nil
		if due and R.t >= due then
			Enemies.spawnBoss(R, R.bossIdx)
		end
	end

	local wave = math.min(Run.TotalWaves, math.floor(R.t / Run.WaveLength) + 1)
	if wave ~= R.wave then
		R.wave = wave
		table.insert(R.events, { "wave", wave, Run.TotalWaves })
	end

	local biome = 1
	for i, t0 in Run.BiomeTimes do
		if R.t >= t0 then
			biome = i
		end
	end
	if biome ~= R.biome then
		R.biome = biome
		R.hazT = 4
		table.insert(R.events, { "biome", biome })
	end

	local interval = Run.HazardInterval[R.biome]
	if interval > 0 then
		R.hazT -= dt
		if R.hazT <= 0 then
			R.hazT = interval
			R.hazN += 1
			local dmg = Run.HazardDmg * Balance.dmgMult(R.t / 60)
			for i = 1, Run.HazardCount[R.biome] do
				local ox, oz = 0, 0
				if i > 1 then
					local a = rng:NextNumber(0, math.pi * 2)
					local d = rng:NextNumber(5, 20)
					ox, oz = math.cos(a) * d, math.sin(a) * d
				end
				addTele(R, { shape = "c", x = R.px + ox, z = R.pz + oz, r = Run.HazardRadius, t = Run.HazardDelay + (i - 1) * 0.15, dmg = dmg })
			end
			if R.biome == 3 and R.hazN % 3 == 1 then
				local ev = NasaData.eventForAlert(math.ceil(R.hazN / 3))
				table.insert(R.events, { "nasa", ev.label, ev.date })
			end
		end
	end

	-- Caida esporadica de meteoros en niveles/oleadas avanzados (NASA InSight / CNEOS).
	local M = Balance.Meteors
	if R.lvl >= M.UnlockLevel or R.wave >= M.UnlockWave then
		R.meteorT -= dt
		if R.meteorT <= 0 then
			local mInterval = M.Interval[R.biome] or 18
			R.meteorT = mInterval
			R.meteorN += 1
			local count = M.Count[R.biome] or 2
			local dmg = M.Dmg * Balance.dmgMult(R.t / 60)
			for i = 1, count do
				local ox, oz = 0, 0
				if i == 1 then
					local a = rng:NextNumber(0, math.pi * 2)
					local d = rng:NextNumber(2, 10)
					ox, oz = math.cos(a) * d, math.sin(a) * d
				else
					local a = rng:NextNumber(0, math.pi * 2)
					local d = rng:NextNumber(12, 34)
					ox, oz = math.cos(a) * d, math.sin(a) * d
				end
				local mx, mz = clampArena(R.px + ox, R.pz + oz, 10)
				if mx * mx + mz * mz < 16 * 16 then
					mx, mz = clampArena(mx + 22, mz + 12, 10)
				end
				addTele(R, { shape = "m", x = mx, z = mz, r = M.Radius, t = M.Delay + (i - 1) * 0.28, dmg = dmg })
			end
			local mf = NasaData.meteorForAlert(R.meteorN)
			table.insert(R.events, { "nasa", mf.title, mf.sub })
		end
	end
end

function Enemies.update(R: Run, dt: number)
	if R.directorOn then
		director(R, dt)
	end

	local px, pz = R.px, R.pz
	local step = R.stepCount
	local heroR = Balance.Hero.Radius
	local lim = Balance.Sim.ArenaRadius - 2
	for _, e in R.enemies do
		if e.dead then
			continue
		end
		local dx, dz = px - e.x, pz - e.z
		local d = math.max(0.001, math.sqrt(dx * dx + dz * dz))
		local nx, nz = dx / d, dz / d
		if e.cd > 0 then
			e.cd -= dt
		end
		if e.state == "wind" then
			e.wind -= dt
			e.vx, e.vz = 0, 0
			if e.wind <= 0 then
				e.state = "move"
			end
		elseif (e.id + step) % 2 == 0 then
			decide(R, e, d, nx, nz)
		end
		e.x += (e.vx + e.kx) * dt
		e.z += (e.vz + e.kz) * dt
		if e.kx ~= 0 or e.kz ~= 0 then
			local k = math.max(0, 1 - 6 * dt)
			e.kx *= k
			e.kz *= k
			if math.abs(e.kx) + math.abs(e.kz) < 0.2 then
				e.kx, e.kz = 0, 0
			end
		end
		if e.x * e.x + e.z * e.z > lim * lim then
			e.x, e.z = clampArena(e.x, e.z, 2)
		end
		if e.contact and e.state ~= "wind" and d < e.r + heroR + 0.5 and (e.hitT or 0) <= R.real then
			e.hitT = R.real + Balance.Enemies.chaser.hitCd
			Combat.damagePlayer(R, e.dmg)
		end
	end

	if step % 2 == 0 then
		separate(R)
	end
	resolveTeles(R, dt)
	stepEShots(R, dt)

	if R.anyDead then
		R.anyDead = false
		local list = R.enemies
		for i = #list, 1, -1 do
			if list[i].dead then
				list[i] = list[#list]
				list[#list] = nil
			end
		end
	end
end

Enemies.addTele = addTele

function Enemies.clear(R: Run)
	for _, e in R.enemies do
		if not e.dead then
			e.dead = true
			table.insert(R.events, { "die", e.id })
		end
	end
	table.clear(R.enemies)
	for _, t in R.teles do
		table.insert(R.events, { "teleEnd", t.id })
	end
	table.clear(R.teles)
	for _, s in R.eshots do
		table.insert(R.events, { "eshotEnd", s.id })
	end
	table.clear(R.eshots)
end

return Enemies
