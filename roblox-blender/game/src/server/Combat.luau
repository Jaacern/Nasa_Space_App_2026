--!strict
-- Dano, ataque automatico, proyectiles del heroe, drones, aura y habilidades.
-- Todo se decide en el servidor; el cliente solo dibuja.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage.Shared.Balance)
local Loot = require(script.Parent.Loot)

local Combat = {}
type Run = any

local rng = Random.new()

function Combat.kill(R: Run, e: any)
	if e.dead then
		return
	end
	e.dead = true
	R.kills += 1
	R.anyDead = true
	if R.stats and (R.stats.scienceZoneMult or 1) > 1 then
		R.scienceBonus = (R.scienceBonus or 0) + Balance.Meta.SciencePerKill * ((R.stats.scienceZoneMult or 1) - 1)
	end
	table.insert(R.events, { "die", e.id })
	Loot.dropGem(R, e.x, e.z, e.xp)
	if e.elite then
		Loot.spawnChest(R, e.x, e.z, if (R.wave or 1) >= 6 then 3 else 2)
	end
	if e.boss then
		R.bossKilled = e
	end
end

function Combat.damageEnemy(R: Run, e: any, amount: number, crit: boolean)
	if e.dead then
		return
	end
	e.hp -= amount
	table.insert(R.events, { "hit", e.id, math.max(1, math.round(amount)), crit and 1 or 0 })
	if e.hp <= 0 then
		Combat.kill(R, e)
	end
end

function Combat.areaDamage(R: Run, x: number, z: number, radius: number, amount: number, knock: number?)
	for _, e in R.enemies do
		if not e.dead then
			local dx, dz = e.x - x, e.z - z
			local rr = radius + e.r
			local d2 = dx * dx + dz * dz
			if d2 <= rr * rr then
				if knock and not e.boss then
					local d = math.max(0.01, math.sqrt(d2))
					e.kx, e.kz = dx / d * knock * 6, dz / d * knock * 6
				end
				Combat.damageEnemy(R, e, amount, false)
			end
		end
	end
end

-- Devuelve true si el heroe recibio dano.
function Combat.damagePlayer(R: Run, dmg: number): boolean
	if R.invuln > 0 or Balance.Debug.Invincible then
		return false
	end
	local s = R.stats
	R.invuln = Balance.Hero.IFrames
	if s.block > 0 and rng:NextNumber() < s.block then
		table.insert(R.events, { "block" })
		return false
	end
	dmg *= (1 - s.armor)
	if R.shield > 0 then
		local absorbed = math.min(R.shield, dmg)
		R.shield -= absorbed
		dmg -= absorbed
		table.insert(R.events, { "shieldHit", math.ceil(R.shield), math.max(1, math.round(absorbed)) })
		if R.shield <= 0 then
			R.shield = 0
			R.shieldT = 0
			table.insert(R.events, { "shieldBreak" })
		end
	end
	if dmg <= 0 then
		return false
	end
	R.hp -= dmg
	R.lastHurt = R.real
	R.damageTaken += dmg
	if R.tutorial and R.hp < 1 then
		R.hp = 1
	end
	table.insert(R.events, { "hurt", math.max(1, math.round(dmg)) })
	local sh = Balance.Items.shelter
	if s.shelter and R.hp > 0 and R.hp < s.maxHp * sh.threshold and R.shelterCd <= 0 then
		R.invuln = sh.invuln
		R.shelterCd = sh.cd
		table.insert(R.events, { "alert", "REFUGIO DE TORMENTA ACTIVADO", "good" })
	end
	return true
end

local function nearestEnemy(R: Run, range: number): any
	local best, bestD = nil, range * range
	local px, pz = R.px, R.pz
	for _, e in R.enemies do
		if not e.dead then
			local dx, dz = e.x - px, e.z - pz
			local d2 = dx * dx + dz * dz - e.r * e.r
			if d2 < bestD then
				best, bestD = e, d2
			end
		end
	end
	return best
end

local function fire(R: Run, target: any)
	local H, s = Balance.Hero, R.stats
	local dx, dz = target.x - R.px, target.z - R.pz
	local d = math.max(0.01, math.sqrt(dx * dx + dz * dz))
	dx, dz = dx / d, dz / d
	local n = s.projCount
	for k = 1, n do
		local ang = math.rad((k - (n + 1) / 2) * H.SpreadDeg)
		local c, sn = math.cos(ang), math.sin(ang)
		local sx, sz = dx * c - dz * sn, dx * sn + dz * c
		R.nextShot += 1
		R.shotCount += 1
		local boom = s.plasma and (R.shotCount % Balance.Items.plasma.every == 0)
		table.insert(R.shots, {
			id = R.nextShot, x = R.px, z = R.pz, dx = sx, dz = sz, speed = s.projSpeed,
			left = H.Range, pierce = s.pierce, dmg = H.Damage * s.dmgMult, hit = {}, boom = boom,
		})
		table.insert(R.events, { "shot", R.nextShot, math.round(R.px * 10) / 10, math.round(R.pz * 10) / 10, math.round(sx * 1000) / 1000, math.round(sz * 1000) / 1000, s.projSpeed, H.Range, boom and 1 or 0 })
	end
end

local function stepShots(R: Run, dt: number)
	local shots = R.shots
	local projR = Balance.Hero.ProjRadius
	local s = R.stats
	for i = #shots, 1, -1 do
		local sh = shots[i]
		local dist = math.min(sh.speed * dt, sh.left)
		local cands = {}
		for _, e in R.enemies do
			if not e.dead and not sh.hit[e.id] then
				local rx, rz = e.x - sh.x, e.z - sh.z
				local t = rx * sh.dx + rz * sh.dz
				if t >= -e.r and t <= dist + e.r then
					local qx, qz = rx - sh.dx * t, rz - sh.dz * t
					local rr = e.r + projR
					if qx * qx + qz * qz <= rr * rr then
						table.insert(cands, { t = t, e = e })
					end
				end
			end
		end
		local ended = false
		if #cands > 0 then
			table.sort(cands, function(a, b)
				return a.t < b.t
			end)
			for _, c in cands do
				local e = c.e
				sh.hit[e.id] = true
				local crit = rng:NextNumber() < s.crit
				Combat.damageEnemy(R, e, sh.dmg * (crit and Balance.Hero.CritMult or 1), crit)
				if sh.boom then
					sh.boom = false
					local pl = Balance.Items.plasma
					table.insert(R.events, { "boom", math.round(e.x), math.round(e.z), pl.radius })
					Combat.areaDamage(R, e.x, e.z, pl.radius, sh.dmg * pl.frac)
				end
				if sh.pierce <= 0 then
					ended = true
					break
				end
				sh.pierce -= 1
			end
		end
		sh.x += sh.dx * dist
		sh.z += sh.dz * dist
		sh.left -= dist
		if ended then
			table.insert(R.events, { "shotEnd", sh.id })
		end
		if ended or sh.left <= 0 then
			shots[i] = shots[#shots]
			shots[#shots] = nil
		end
	end
end

function Combat.useSkill(R: Run, idx: number, dx: number, dz: number)
	if R.paused or R.cds[idx] > 0 or R.hp <= 0 then
		return
	end
	local s = R.stats
	if idx == 1 then
		local D = Balance.Skills.Dash
		local len = math.sqrt(dx * dx + dz * dz)
		if len < 0.1 then
			dx, dz, len = 0, -1, 1
		end
		dx, dz = dx / len, dz / len
		local px, pz = R.px, R.pz
		for _, e in R.enemies do
			if not e.dead then
				local rx, rz = e.x - px, e.z - pz
				local t = math.clamp(rx * dx + rz * dz, 0, D.Distance)
				local qx, qz = rx - dx * t, rz - dz * t
				local rr = e.r + D.Width / 2
				if qx * qx + qz * qz <= rr * rr then
					Combat.damageEnemy(R, e, D.Damage * s.dmgMult, false)
				end
			end
		end
		R.invuln = math.max(R.invuln, D.Invuln)
		R.cds[1] = D.Cooldown * s.cdMult
		R.cdMax[1] = R.cds[1]
		table.insert(R.events, { "skill", 1, dx, dz })
	elseif idx == 2 then
		local P = Balance.Skills.Pulse
		Combat.areaDamage(R, R.px, R.pz, P.Radius, P.Damage * s.dmgMult, P.Knockback)
		R.shield = P.Shield
		R.shieldMax = P.Shield
		R.shieldT = P.ShieldTime
		R.cds[2] = P.Cooldown * s.cdMult
		R.cdMax[2] = R.cds[2]
		table.insert(R.events, { "skill", 2, 0, 0 })
	else
		return
	end
	R.used[idx] = true
end

function Combat.update(R: Run, dt: number)
	local H, s = Balance.Hero, R.stats
	if R.invuln > 0 then
		R.invuln -= dt
	end
	if R.shelterCd > 0 then
		R.shelterCd -= dt
	end
	for i = 1, 2 do
		if R.cds[i] > 0 then
			R.cds[i] = math.max(0, R.cds[i] - dt)
		end
	end
	if R.shield > 0 then
		R.shieldT -= dt
		if R.shieldT <= 0 then
			R.shield = 0
			R.shieldT = 0
			table.insert(R.events, { "shieldBreak" })
		end
	end

	-- Pasiva "Soporte vital" + regeneracion de objetos.
	local regen = s.regen
	if R.real - R.lastHurt > H.RegenDelay then
		regen += H.RegenPerSec
	end
	if regen > 0 and R.hp > 0 then
		R.hp = math.min(s.maxHp, R.hp + regen * dt)
	end

	-- Ataque automatico.
	R.atkT -= dt
	if R.atkT <= 0 then
		local target = nearestEnemy(R, H.Range)
		if target then
			fire(R, target)
			R.atkT += s.atkInterval
			if R.atkT < 0 then
				R.atkT = 0
			end
		else
			R.atkT = 0
		end
	end
	stepShots(R, dt)

	-- Drones orbitales.
	if s.drones > 0 then
		local D = Balance.Upgrades.drone
		for i = 1, s.drones do
			local a = R.real * D.angSpeed + (i - 1) * math.pi * 2 / s.drones
			local x, z = R.px + math.cos(a) * D.radius, R.pz + math.sin(a) * D.radius
			for _, e in R.enemies do
				if not e.dead and (e.droneT or 0) <= R.real then
					local dx, dz = e.x - x, e.z - z
					local rr = D.hitRadius + e.r
					if dx * dx + dz * dz <= rr * rr then
						e.droneT = R.real + D.hitCd
						Combat.damageEnemy(R, e, D.dmg * s.dmgMult, false)
					end
				end
			end
		end
	end

	-- Campo electrostatico.
	if s.aura > 0 then
		R.auraT -= dt
		if R.auraT <= 0 then
			local A = Balance.Upgrades.aura
			R.auraT = A.interval
			Combat.areaDamage(R, R.px, R.pz, A.radius, s.aura * s.dmgMult)
		end
	end
end

return Combat
