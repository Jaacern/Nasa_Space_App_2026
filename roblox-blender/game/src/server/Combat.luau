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

function Combat.areaDamage(R: Run, x: number, z: number, radius: number, amount: number, knock: number?, skipId: number?)
	for _, e in R.enemies do
		if not e.dead and e.id ~= skipId then
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

local function weaponModeOf(R: Run): any
	local modes = Balance.WeaponModes
	local idx = R.weaponMode or 1
	return modes[idx] or modes[1]
end

local function spawnShot(R: Run, px: number, pz: number, dx: number, dz: number, speed: number, range: number, pierce: number, dmg: number, boom: boolean, kind: string, critChance: number?, splash: number?, knock: number?, detonateOnEnd: boolean?, waveKind: number?)
	R.nextShot += 1
	local sx = math.round(dx * 1000) / 1000
	local sz = math.round(dz * 1000) / 1000
	table.insert(R.shots, {
		id = R.nextShot, x = px, z = pz, dx = dx, dz = dz, speed = speed,
		left = range, pierce = pierce, dmg = dmg, hit = {}, boom = boom,
		kind = kind, crit = critChance, splash = splash or 0, knock = knock or 0,
		detonateOnEnd = detonateOnEnd == true, waveKind = waveKind or 1,
	})
	table.insert(R.events, { "shot", R.nextShot, math.round(px * 10) / 10, math.round(pz * 10) / 10, sx, sz, speed, range, boom and 1 or 0, kind })
end

local function fire(R: Run, target: any)
	local H, s = Balance.Hero, R.stats
	local mode = weaponModeOf(R)
	local dx, dz = target.x - R.px, target.z - R.pz
	local d = math.max(0.01, math.sqrt(dx * dx + dz * dz))
	dx, dz = dx / d, dz / d
	local n = math.max(1, s.projCount + (mode.projCountBonus or 0))
	local stepAng = mode.spread or math.rad(H.SpreadDeg)
	local speed = s.projSpeed * (mode.speedMult or 1)
	local shotKind = mode.shotKind or "shot"
	local range = if shotKind == "mortar" then math.min(mode.range, math.max(10, d)) else (mode.range or H.Range)
	local splash = mode.splash or 0
	local knock = mode.knock or 0
	local pierce = if splash > 0 then 0 else (s.pierce + (mode.pierceBonus or 0))
	local dmg = H.Damage * s.dmgMult * (mode.dmgMult or 1)
	local crit = math.min(Balance.Caps.Crit, s.crit + (mode.critBonus or 0))
	local detEnd = splash > 0
	for k = 1, n do
		local ang = (k - (n + 1) / 2) * stepAng
		local c, sn = math.cos(ang), math.sin(ang)
		local sx, sz = dx * c - dz * sn, dx * sn + dz * c
		R.shotCount += 1
		local boom = s.plasma and (R.shotCount % Balance.Items.plasma.every == 0)
		spawnShot(R, R.px, R.pz, sx, sz, speed, range, pierce, dmg, boom, shotKind, crit, splash, knock, detEnd, 1)
	end
end

local function triggerSplash(R: Run, x: number, z: number, sh: any, skipId: number?)
	local splash = sh.splash or 0
	if splash <= 0 then
		return
	end
	Combat.areaDamage(R, x, z, splash, sh.dmg * (if skipId then 0.85 else 1), sh.knock, skipId)
	table.insert(R.events, { "boom", math.round(x), math.round(z), splash })
	table.insert(R.events, { "waveRing", math.round(x * 10) / 10, math.round(z * 10) / 10, splash, sh.waveKind or 1 })
end

local function stepShots(R: Run, dt: number)
	local shots = R.shots
	local projR = Balance.Hero.ProjRadius
	local s = R.stats
	for i = #shots, 1, -1 do
		local sh = shots[i]
		local dist = math.min(sh.speed * dt, sh.left)
		local cands = {}
		local hitRadius = projR + (if sh.kind == "mortar" then 0.8 else 0)
		for _, e in R.enemies do
			if not e.dead and not sh.hit[e.id] then
				local rx, rz = e.x - sh.x, e.z - sh.z
				local t = rx * sh.dx + rz * sh.dz
				if t >= -e.r and t <= dist + e.r then
					local qx, qz = rx - sh.dx * t, rz - sh.dz * t
					local rr = e.r + hitRadius
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
				local crit = rng:NextNumber() < (sh.crit or s.crit)
				Combat.damageEnemy(R, e, sh.dmg * (crit and Balance.Hero.CritMult or 1), crit)
				if sh.splash and sh.splash > 0 then
					triggerSplash(R, e.x, e.z, sh, e.id)
				end
				if sh.boom then
					sh.boom = false
					local pl = Balance.Items.plasma
					table.insert(R.events, { "boom", math.round(e.x), math.round(e.z), pl.radius })
					Combat.areaDamage(R, e.x, e.z, pl.radius, sh.dmg * pl.frac, nil, e.id)
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
		if not ended and sh.left <= 0 and sh.detonateOnEnd and sh.splash and sh.splash > 0 then
			triggerSplash(R, sh.x, sh.z, sh, nil)
		end
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
		table.insert(R.events, { "waveRing", math.round(R.px * 10) / 10, math.round(R.pz * 10) / 10, P.Radius, 3 })
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

	-- Ataque principal automatico (Láser / Abanico / Mortero).
	local mode = weaponModeOf(R)
	R.atkT -= dt
	if R.atkT <= 0 then
		local target = nearestEnemy(R, mode.range or H.Range)
		if target then
			fire(R, target)
			R.atkT += s.atkInterval / (mode.rateMult or 1)
			if R.atkT < 0 then
				R.atkT = 0
			end
		else
			R.atkT = 0
		end
	end

	-- Armas automaticas de area y multiples objetivos.
	if (s.novaLvl or 0) > 0 then
		R.novaT -= dt
		if R.novaT <= 0 then
			local N = Balance.Upgrades.nova
			local radius = N.radius + N.radiusPer * (s.novaLvl - 1)
			if nearestEnemy(R, radius + 3) then
				R.novaT = math.max(1.2, N.interval - N.intervalPer * (s.novaLvl - 1)) * math.max(0.75, s.cdMult)
				local dmg = (N.baseDmg + N.per * (s.novaLvl - 1)) * s.dmgMult
				Combat.areaDamage(R, R.px, R.pz, radius, dmg, N.knock)
				table.insert(R.events, { "waveRing", math.round(R.px * 10) / 10, math.round(R.pz * 10) / 10, radius, 2 })
			else
				R.novaT = 0.25
			end
		end
	end

	if (s.missilesLvl or 0) > 0 then
		R.missileT -= dt
		if R.missileT <= 0 then
			local M = Balance.Upgrades.missiles
			local cands = {}
			local maxR2 = M.range * M.range
			for _, e in R.enemies do
				if not e.dead then
					local dx, dz = e.x - R.px, e.z - R.pz
					local d2 = dx * dx + dz * dz
					if d2 <= maxR2 then
						table.insert(cands, { d2 = d2, e = e })
					end
				end
			end
			if #cands > 0 then
				table.sort(cands, function(a, b)
					return a.d2 < b.d2
				end)
				R.missileT = math.max(0.65, M.interval - M.intervalPer * (s.missilesLvl - 1))
				local count = M.baseCount + (s.missilesLvl - 1)
				local dmg = (H.Damage * M.dmgMult + M.per * (s.missilesLvl - 1)) * s.dmgMult
				for i = 1, count do
					local tgt = cands[((i - 1) % #cands) + 1].e
					local dx, dz = tgt.x - R.px, tgt.z - R.pz
					local d = math.max(0.01, math.sqrt(dx * dx + dz * dz))
					dx, dz = dx / d, dz / d
					local fan = if i > #cands then ((i - #cands) % 2 * 2 - 1) * 0.14 else 0
					local c, sn = math.cos(fan), math.sin(fan)
					spawnShot(R, R.px, R.pz, dx * c - dz * sn, dx * sn + dz * c, M.speed, math.min(M.range, d + 5), 0, dmg, false, "missile", s.crit, M.splash, 3, true, 4)
				end
			else
				R.missileT = 0.25
			end
		end
	end

	if (s.arcLvl or 0) > 0 then
		R.arcT -= dt
		if R.arcT <= 0 then
			local AR = Balance.Upgrades.arc
			local cur = nearestEnemy(R, AR.range)
			if cur then
				R.arcT = math.max(0.55, AR.interval - AR.intervalPer * (s.arcLvl - 1))
				local chains = AR.baseChains + (s.arcLvl - 1)
				local dmg = (H.Damage * AR.dmgMult + AR.per * (s.arcLvl - 1)) * s.dmgMult
				local visited: { [number]: boolean } = {}
				local pts: { number } = { math.round(R.px * 10) / 10, math.round(R.pz * 10) / 10 }
				local prevX, prevZ = cur.x, cur.z
				local jump2 = AR.jumpRange * AR.jumpRange
				for hop = 1, chains do
					if not cur then
						break
					end
					visited[cur.id] = true
					table.insert(pts, math.round(cur.x * 10) / 10)
					table.insert(pts, math.round(cur.z * 10) / 10)
					prevX, prevZ = cur.x, cur.z
					local crit = rng:NextNumber() < s.crit
					Combat.damageEnemy(R, cur, dmg * (0.88 ^ (hop - 1)) * (if crit then H.CritMult else 1), crit)
					local nxt: any = nil
					local bestD2 = jump2
					for _, e in R.enemies do
						if not e.dead and not visited[e.id] then
							local dx, dz = e.x - prevX, e.z - prevZ
							local d2 = dx * dx + dz * dz
							if d2 <= bestD2 then
								nxt, bestD2 = e, d2
							end
						end
					end
					cur = nxt
				end
				if #pts >= 4 then
					table.insert(R.events, { "arc", pts })
				end
			else
				R.arcT = 0.25
			end
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
			local hadTarget = nearestEnemy(R, A.radius + 2) ~= nil
			Combat.areaDamage(R, R.px, R.pz, A.radius, s.aura * s.dmgMult)
			if hadTarget then
				table.insert(R.events, { "waveRing", math.round(R.px * 10) / 10, math.round(R.pz * 10) / 10, A.radius, 3 })
			end
		end
	end
end

return Combat
