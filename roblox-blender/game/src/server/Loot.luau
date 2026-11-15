--!strict
-- Estadisticas del heroe, experiencia, muestras (gemas), cofres y mejoras.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage.Shared.Balance)

local Loot = {}
type Run = any

local rng = Random.new()

function Loot.computeZone(x: number, z: number): number
	if x * x + z * z <= 34 * 34 then
		return 1
	end
	if math.abs(z) >= math.abs(x) then
		return if z <= 0 then 2 else 4
	end
	return if x >= 0 then 3 else 5
end

function Loot.recompute(R: Run)
	local H, U, I, M, PC, Caps = Balance.Hero, Balance.Upgrades, Balance.Items, Balance.Meta, Balance.Pieces, Balance.Caps
	local up, it, mu, pc = R.upgrades, R.items, R.meta.unlocks, R.pieces
	local zDef = (Balance.Zones :: any)[R.zone or 1] or {}
	local function ul(id: string): number
		return up[id] or 0
	end
	local function il(id: string): number
		return it[id] or 0
	end
	local function ml(id: string): number
		return mu[id] or 0
	end
	local s = R.stats
	s.maxHp = H.MaxHp + U.armor.per * ul("armor") + I.pica.per * il("pica") + M.hp.per * ml("hp") + (pc[3] and PC[3].maxHp or 0)
	s.dmgMult = (1 + U.damage.per * ul("damage")) * (1 + I.lens.per * il("lens")) * (1 + M.dmg.per * ml("dmg"))
	s.atkInterval = H.AttackInterval / ((1 + U.rate.per * ul("rate")) * (1 + I.cell.per * il("cell")))
	s.projCount = 1 + math.floor(U.multishot.per * ul("multishot"))
	s.pierce = math.floor(U.pierce.per * ul("pierce")) + I.ion.pierce * il("ion")
	s.projSpeed = H.ProjSpeed * (1 + I.ion.per * il("ion"))
	s.speed = H.WalkSpeed * (1 + U.speed.per * ul("speed") + I.boots.per * il("boots") + M.speed.per * ml("speed") + (zDef.speed or 0))
	s.pickup = H.PickupRadius * (1 + U.magnet.per * ul("magnet") + I.arm.per * il("arm") + M.magnet.per * ml("magnet"))
	s.cdMult = math.max(Caps.CdMult, 1 - U.cooldown.per * ul("cooldown") - I.antenna.per * il("antenna") - (pc[1] and PC[1].cd or 0) - (zDef.cd or 0))
	s.crit = math.min(Caps.Crit, H.CritChance + U.crit.per * ul("crit") + I.spectro.per * il("spectro"))
	s.armor = math.min(Caps.Armor, I.mli.per * il("mli") + M.armor.per * ml("armor"))
	s.block = math.min(Caps.Block, I.whipple.per * il("whipple"))
	s.regen = I.filter.per * il("filter") + (pc[1] and PC[1].regen or 0) + (zDef.regen or 0)
	s.xpMult = R.mode.XpMult * (1 + I.solar.per * il("solar") + M.xp.per * ml("xp") + (pc[2] and PC[2].xp or 0) + (zDef.xp or 0))
	s.scienceZoneMult = 1 + (zDef.science or 0)
	s.drones = math.floor(ul("drone"))
	s.aura = U.aura.per * ul("aura")
	s.novaLvl = math.floor(ul("nova"))
	s.missilesLvl = math.floor(ul("missiles"))
	s.arcLvl = math.floor(ul("arc"))
	s.plasma = il("plasma") > 0
	s.shelter = il("shelter") > 0
	s.chestItems = 1 + I.orbital.per * il("orbital")
	if R.hp > s.maxHp then
		R.hp = s.maxHp
	end
	R.statsDirty = true
end

function Loot.addXp(R: Run, amount: number)
	R.xp += amount * R.stats.xpMult
	local need = Balance.levelNeed(R.lvl, R.mode.LevelCost)
	while R.xp >= need do
		R.xp -= need
		R.lvl += 1
		R.pendingLevels += 1
		need = Balance.levelNeed(R.lvl, R.mode.LevelCost)
	end
end

function Loot.dropGem(R: Run, x: number, z: number, val: number)
	if val <= 0 then
		return
	end
	local gems = R.gems
	if #gems >= Balance.Sim.MaxGems then
		gems[#gems].val += val
		return
	end
	R.nextGem += 1
	table.insert(gems, { id = R.nextGem, x = x, z = z, val = val })
	table.insert(R.events, { "gem", R.nextGem, math.round(x * 10) / 10, math.round(z * 10) / 10 })
end

local function rollChestTier(wave: number): number
	local w = Balance.ChestWaveWeights[1].w
	for _, stage in Balance.ChestWaveWeights do
		if wave >= stage.minWave then
			w = stage.w
		end
	end
	local total = w[1] + w[2] + w[3] + w[4]
	local roll = rng:NextNumber(0, total)
	for i = 1, 4 do
		roll -= w[i]
		if roll <= 0 then
			return i
		end
	end
	return 1
end

function Loot.spawnChest(R: Run, x: number, z: number, forcedTier: number?)
	local minR = 22
	local maxR = Balance.Sim.ArenaRadius - 14
	local len = math.sqrt(x * x + z * z)
	if len < minR then
		if len < 0.01 then
			x, z, len = minR, 0, minR
		else
			x, z = x / len * minR, z / len * minR
		end
	elseif len > maxR then
		x, z = x / len * maxR, z / len * maxR
	end
	local tier = forcedTier or rollChestTier(R.wave or 1)
	R.nextChest += 1
	table.insert(R.chests, { id = R.nextChest, x = x, z = z, tier = tier })
	table.insert(R.events, { "chest", R.nextChest, math.round(x), math.round(z), tier })
end

local function rollItem(R: Run, tier: number?): string
	local tDef = Balance.ChestTiers[tier or 1] or Balance.ChestTiers[1]
	local w = tDef.itemW
	for _ = 1, 8 do
		local roll = rng:NextNumber(0, w[1] + w[2] + w[3])
		local rar = if roll < w[1] then 1 elseif roll < w[1] + w[2] then 2 else 3
		local pool = {}
		for _, id in Balance.ItemOrder do
			local def = Balance.Items[id]
			-- los epicos no se acumulan
			if def.rar == rar and not (rar == 3 and (R.items[id] or 0) > 0) then
				table.insert(pool, id)
			end
		end
		if #pool > 0 then
			return pool[rng:NextInteger(1, #pool)]
		end
	end
	return "lens"
end

function Loot.giveItem(R: Run, id: string)
	R.items[id] = (R.items[id] or 0) + 1
	local before = R.stats.maxHp
	Loot.recompute(R)
	if R.stats.maxHp > before then
		R.hp = math.min(R.stats.maxHp, R.hp + (R.stats.maxHp - before))
	end
	table.insert(R.events, { "item", id, R.items[id] })
end

local function baseWeightsForLevel(lvl: number): { number }
	local stages = Balance.CardRarity.Stages
	local w = stages[1].w
	for _, st in stages do
		if lvl >= st.minLvl then
			w = st.w
		end
	end
	return w
end

local function rollRarity(R: Run): number
	local CR = Balance.CardRarity
	local base = baseWeightsForLevel(R.lvl)
	local luck = (R.meta.unlocks.luck or 0) * Balance.Meta.luck.per * CR.LuckShift
	-- La suerte solo impulsa rarezas ya desbloqueadas para el nivel actual.
	local w1 = base[1]
	local w2 = if base[2] > 0 then (base[2] + luck * 0.5) else 0
	local w3 = if base[3] > 0 then (base[3] + luck * 0.3) else 0
	local w4 = if base[4] > 0 then (base[4] + luck * 0.2) else 0
	if w2 + w3 + w4 > 0 then
		w1 = math.max(10, w1 - luck)
	end
	local roll = rng:NextNumber(0, w1 + w2 + w3 + w4)
	local weights = { w1, w2, w3, w4 }
	for i = 1, 4 do
		roll -= weights[i]
		if roll <= 0 then
			return i
		end
	end
	return 1
end

-- Devuelve hasta 3 cartas { id, rar }. Las cartas de unidades enteras arrancan en nivel 2.
local FIRST_CHOICE_VARIETY = { "nova", "missiles", "arc", "multishot" }

function Loot.makeOptions(R: Run): { any }
	local minSpec = Balance.UpgradeCountMinLevel or 2
	local pool = {}
	for _, id in Balance.UpgradeOrder do
		if (R.upgrades[id] or 0) < Balance.Upgrades[id].max then
			if not Balance.UpgradeCount[id] or R.lvl >= minSpec then
				table.insert(pool, id)
			end
		end
	end
	local out = {}
	for _ = 1, 3 do
		if #pool == 0 then
			break
		end
		local id = table.remove(pool, rng:NextInteger(1, #pool)) :: string
		local rar = if Balance.UpgradeCount[id] then (if R.lvl >= 4 then 3 else 2) else rollRarity(R)
		table.insert(out, { id = id, rar = rar })
	end
	if R.lvl <= 3 and #out == 3 then
		local hasVariety = false
		for _, opt in out do
			if table.find(FIRST_CHOICE_VARIETY, opt.id) or opt.id == "aura" then
				hasVariety = true
				break
			end
		end
		if not hasVariety then
			local avail = {}
			for _, id in FIRST_CHOICE_VARIETY do
				if (R.upgrades[id] or 0) < Balance.Upgrades[id].max and (not Balance.UpgradeCount[id] or R.lvl >= minSpec) then
					table.insert(avail, id)
				end
			end
			if #avail > 0 then
				local pick = avail[rng:NextInteger(1, #avail)]
				local rar = if Balance.UpgradeCount[pick] then 2 else rollRarity(R)
				out[3] = { id = pick, rar = rar }
			end
		end
	end
	if #out < 3 then
		table.insert(out, { id = "heal", rar = 1 })
	end
	return out
end

function Loot.applyChoice(R: Run, opt: any)
	local id: string = opt.id
	if id == "heal" then
		R.hp = math.min(R.stats.maxHp, R.hp + Balance.LevelUpHeal)
		return
	end
	local mult = if Balance.UpgradeCount[id]
		then 1
		elseif Balance.WeaponRanks and Balance.WeaponRanks[id] then (if opt.rar >= 3 then 2 else 1)
		else Balance.CardRarity.Mult[opt.rar]
	R.upgrades[id] = math.min(Balance.Upgrades[id].max, (R.upgrades[id] or 0) + mult)
	local before = R.stats.maxHp
	Loot.recompute(R)
	if R.stats.maxHp > before then
		R.hp = math.min(R.stats.maxHp, R.hp + (R.stats.maxHp - before))
	end
end

function Loot.openChoice(R: Run)
	local options = Loot.makeOptions(R)
	local ids, levels, rars = {}, {}, {}
	for i, opt in options do
		ids[i] = opt.id
		levels[i] = R.upgrades[opt.id] or 0
		rars[i] = opt.rar
	end
	R.choice = options
	R.paused = true
	R.pauseKind = "level"
	table.insert(R.events, { "levelup", R.lvl - R.pendingLevels + 1, ids, levels, rars })
end

function Loot.update(R: Run, dt: number)
	local px, pz = R.px, R.pz
	local pr2 = R.stats.pickup * R.stats.pickup
	local gems = R.gems
	for i = #gems, 1, -1 do
		local g = gems[i]
		local dx, dz = g.x - px, g.z - pz
		if dx * dx + dz * dz <= pr2 then
			Loot.addXp(R, g.val)
			table.insert(R.events, { "gemGot", g.id })
			gems[i] = gems[#gems]
			gems[#gems] = nil
		end
	end

	local chests = R.chests
	for i = #chests, 1, -1 do
		local c = chests[i]
		local dx, dz = c.x - px, c.z - pz
		if dx * dx + dz * dz <= 30 then
			local tier = c.tier or 1
			local tDef = Balance.ChestTiers[tier] or Balance.ChestTiers[1]
			table.insert(R.events, { "chestGot", c.id, tier })
			table.remove(chests, i)
			R.chestsOpened += 1
			R.hp = math.min(R.stats.maxHp, R.hp + tDef.heal)
			R.scienceBonus = (R.scienceBonus or 0) + tDef.science
			local rolls = R.stats.chestItems + (if tDef.extra then 1 else 0)
			for _ = 1, rolls do
				Loot.giveItem(R, rollItem(R, tier))
			end
		end
	end

	if not R.tutorial then
		R.chestT -= dt
		if R.chestT <= 0 then
			R.chestT = Balance.Director.ChestInterval
			local a = rng:NextNumber(0, math.pi * 2)
			local d = rng:NextNumber(34, 52)
			local x, z = px + math.cos(a) * d, pz + math.sin(a) * d
			Loot.spawnChest(R, x, z)
		end
	end

	if R.pendingLevels > 0 and not R.paused then
		Loot.openChoice(R)
	end
end

return Loot
