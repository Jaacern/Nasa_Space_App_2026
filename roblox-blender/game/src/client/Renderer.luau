--!strict
-- Dibuja lo que el servidor simula: enemigos, proyectiles, avisos, muestras, cofres, drones.
-- Usa pooling: los modelos se reciclan en vez de crearse y destruirse.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Balance)
local Visuals = require(ReplicatedStorage.Shared.Visuals)
local Fx = require(script.Parent.Fx)
local MeshFactory = require(script.Parent.MeshFactory)
local Scenery = require(script.Parent.Scenery)

local Renderer = {}

local MESH_ORDER = {
	"chaser", "tank", "ranged", "kamikaze", "elite1", "elite2", "elite3", "boss1", "boss2", "boss3", "final",
	"gem", "chest", "shot", "eshot", "drone",
	"Ship", "Piece1", "Piece2", "Piece3", "Piece4", "RockA", "RockB", "RockC", "RidgeA", "RidgeB", "Helmet", "Backpack", "Rover", "Insignia",
}

local C = Visuals.Colors
local FAR = CFrame.new(0, -600, 0)
local INTERP = Balance.Sim.Step * Balance.Sim.SnapshotEvery
local WHITE = Color3.new(1, 1, 1)

local folder: Folder
local templates: Instance
local pools: { [string]: { Model } } = {}
local meshTemplates: { [string]: Model } = {}
local partCache: { [Model]: { parts: { BasePart }, colors: { Color3 } } } = {}

local enemies: { [number]: any } = {}
local shots: { [number]: any } = {}
local eshots: { [number]: any } = {}
local teles: { [number]: any } = {}
local gems: { [number]: any } = {}
local chests: { [number]: any } = {}
local drones: { Model } = {}
local waveRings: { any } = {}
local arcBeams: { any } = {}
local circlePool: { Part } = {}
local linePool: { Part } = {}
local wavePool: { Part } = {}
local beamPool: { Part } = {}
local meteorPool: { Model } = {}
local auraRing: Part
local shieldBubble: Part
local shieldRing: Part
local shieldFlashT = 0
local heroRadius = 6.8
local hud: { number }? = nil
local simT = 0
local playerPos = Vector3.zero
local lastGemSound = 0
local qualityTier = "high"
local oddFrame = false

local CHEST_COLORS: { Color3 } = {
	Color3.fromRGB(215, 228, 245), -- 1: Comun
	Color3.fromRGB(0, 215, 255),   -- 2: Raro
	Color3.fromRGB(205, 95, 255),  -- 3: Epico
	Color3.fromRGB(255, 200, 40),  -- 4: Legendario
}

local NON_ENEMY_KINDS: { [string]: boolean } = {
	gem = true, chest = true, shot = true, spread = true, mortar = true, missile = true, eshot = true, drone = true,
}

local WAVE_COLORS: { Color3 } = {
	Color3.fromRGB(255, 115, 45),  -- 1: Mortero
	Color3.fromRGB(255, 195, 55),  -- 2: Onda Sismica 360
	C.cyan,                        -- 3: Pulso / Campo electrostatico
	Color3.fromRGB(210, 120, 255), -- 4: Micromisiles
}

local function outlineColorFor(kind: string): Color3
	if kind == "boss1" or kind == "boss2" or kind == "boss3" or kind == "final" then
		return Color3.fromRGB(255, 65, 95)
	elseif kind == "elite1" or kind == "elite2" or kind == "elite3" then
		return Color3.fromRGB(255, 205, 55)
	elseif kind == "ranged" or kind == "kamikaze" then
		return Color3.fromRGB(255, 115, 60)
	end
	return Color3.fromRGB(255, 165, 110)
end

local function brightenEnemyModel(kind: string, m: Model)
	if NON_ENEMY_KINDS[kind] then
		return
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d ~= m.PrimaryPart and d.Material ~= Enum.Material.Neon then
			local h, s, v = d.Color:ToHSV()
			if v < 0.42 then
				d.Color = Color3.fromHSV(h, math.max(0.16, s * 0.88), math.clamp(v * 1.7 + 0.16, 0.34, 0.72))
			end
		end
	end
	if (string.sub(kind, 1, 5) == "elite" or string.sub(kind, 1, 4) == "boss" or kind == "final") and not m:FindFirstChild("EnemyRim") then
		local hl = Instance.new("Highlight")
		hl.Name = "EnemyRim"
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.FillTransparency = 0.94
		hl.FillColor = outlineColorFor(kind)
		hl.OutlineColor = outlineColorFor(kind)
		hl.OutlineTransparency = 0.48
		hl.Adornee = m
		hl.Parent = m
	end
end

local function take(kind: string): Model
	local pool = pools[kind]
	if pool and #pool > 0 then
		return table.remove(pool) :: Model
	end
	-- malla propia si existe; si no, plantilla basica del servidor
	local t = meshTemplates[kind] or templates:FindFirstChild(kind) or templates:FindFirstChild("chaser")
	local m = (t :: Model):Clone()
	brightenEnemyModel(kind, m)
	local parts, colors = {}, {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d ~= m.PrimaryPart then
			table.insert(parts, d)
			table.insert(colors, d.Color)
		end
	end
	partCache[m] = { parts = parts, colors = colors }
	m.Parent = folder
	return m
end

local function give(kind: string, m: Model)
	-- si ya hay malla para este kind y el modelo es una plantilla basica, se descarta en vez de reciclarlo
	if meshTemplates[kind] and not m:GetAttribute("Mesh") then
		partCache[m] = nil
		m:Destroy()
		return
	end
	(m.PrimaryPart :: Part).CFrame = FAR
	local pool = pools[kind]
	if not pool then
		pool = {}
		pools[kind] = pool
	end
	table.insert(pool, m)
end

local function flat(shape: Enum.PartType, color: Color3, transparency: number): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Shape = shape
	p.Color = color
	p.Transparency = transparency
	p.CFrame = FAR
	p.Parent = folder
	return p
end

local UPR = CFrame.Angles(0, 0, math.rad(90))

-- Destello de boca: una esfera de luz que dura un instante en el origen del disparo.
local MUZZLE_TIME = 0.06
local MUZZLE_COLOR = Color3.fromRGB(150, 240, 255)
local muzzle: Part? = nil
local muzzleT = 0
local function setCircle(p: Part, x: number, z: number, r: number, y: number)
	p.Size = Vector3.new(0.12, math.max(0.1, r * 2), math.max(0.1, r * 2))
	p.CFrame = CFrame.new(x, y, z) * UPR
end

function Renderer.init()
	folder = Instance.new("Folder")
	folder.Name = "ClientFx"
	folder.Parent = Workspace
	templates = ReplicatedStorage:WaitForChild("Templates")
	Fx.init(folder)
	auraRing = flat(Enum.PartType.Cylinder, C.cyan, 0.84)
	shieldBubble = flat(Enum.PartType.Ball, C.cyan, 0.66)
	shieldBubble.Material = Enum.Material.ForceField
	shieldBubble.Size = Vector3.new(7, 7, 7)
	shieldRing = flat(Enum.PartType.Cylinder, C.cyan, 0.22)
	shieldRing.Size = Vector3.new(0.28, 7.8, 7.8)
	-- Mallas generadas desde los modulos de Shared.Meshes (enemigos primero). Sin bloquear.
	task.spawn(MeshFactory.buildAll, MESH_ORDER, function(name: string, model: Model)
		meshTemplates[name] = model
		-- vacia el pool de ese kind: los modelos basicos antiguos ya no deben reciclarse
		local pool = pools[name]
		if pool then
			for _, old in pool do
				partCache[old] = nil
				old:Destroy()
			end
			table.clear(pool)
		end
		Scenery.onMesh(name, model)
	end)
end

function Renderer.folder(): Folder
	return folder
end

function Renderer.clearAll()
	for id, e in enemies do
		give(e.kind, e.m)
		enemies[id] = nil
	end
	for id, s in shots do
		give(s.kind or "shot", s.m)
		shots[id] = nil
	end
	for id, s in eshots do
		give("eshot", s.m)
		eshots[id] = nil
	end
	for id, _ in teles do
		Renderer.teleEnd(id)
	end
	for i = #waveRings, 1, -1 do
		local w = waveRings[i]
		w.p.CFrame = FAR
		table.insert(wavePool, w.p)
		waveRings[i] = nil
	end
	for i = #arcBeams, 1, -1 do
		local b = arcBeams[i]
		b.p.CFrame = FAR
		table.insert(beamPool, b.p)
		arcBeams[i] = nil
	end
	for id, g in gems do
		give("gem", g.m)
		gems[id] = nil
	end
	for id, c in chests do
		if c.beam then
			c.beam:Destroy()
		end
		if c.ring then
			c.ring:Destroy()
		end
		give("chest", c.m)
		chests[id] = nil
	end
	for _, d in drones do
		give("drone", d)
	end
	table.clear(drones)
	auraRing.CFrame = FAR
	shieldBubble.CFrame = FAR
	shieldRing.CFrame = FAR
	shieldFlashT = 0
	hud = nil
end

function Renderer.spawn(id: number, kind: string, x: number, z: number)
	local m = take(kind)
	local e = { m = m, root = m.PrimaryPart, kind = kind, x = x, z = z, x0 = x, z0 = z, x1 = x, z1 = z, a = 1, flash = 0, rise = 0, dx = 0, dz = 0, kick = 0 }
	enemies[id] = e
	e.root.CFrame = CFrame.new(x, -6, z)
end

function Renderer.snapshot(pos: { number })
	for i = 1, #pos, 3 do
		local e = enemies[pos[i]]
		if e then
			e.x0, e.z0 = e.x, e.z
			e.x1, e.z1 = pos[i + 1], pos[i + 2]
			e.a = 0
		end
	end
end

local function restoreColors(m: Model)
	local c = partCache[m]
	if c then
		for i, p in c.parts do
			p.Color = c.colors[i]
		end
	end
end

function Renderer.hit(id: number, dmg: number, crit: boolean)
	local e = enemies[id]
	if not e then
		return
	end
	if e.flash <= 0 then
		local c = partCache[e.m]
		if c then
			for _, p in c.parts do
				p.Color = WHITE
			end
		end
	end
	e.flash = Balance.Juice.FlashTime
	e.kick = if crit then 1.6 else 1 -- retroceso visual del golpe
	local pos = Vector3.new(e.x, 5, e.z)
	if crit then
		Fx.number(pos, tostring(dmg) .. "!", C.gold, true)
		Fx.hitstop(Balance.Juice.HitstopKill)
	else
		Fx.number(pos, tostring(dmg), C.white)
	end
	Fx.play("hit")
end

function Renderer.die(id: number)
	local e = enemies[id]
	if not e then
		return
	end
	enemies[id] = nil
	restoreColors(e.m)
	local big = e.kind ~= "chaser" and e.kind ~= "kamikaze" and e.kind ~= "ranged" and e.kind ~= "tank"
	Fx.burst("die", Vector3.new(e.x, 2.5, e.z), if big then 60 else 10)
	if big then
		Fx.hitstop(Balance.Juice.HitstopBig)
		Fx.shake(0.3)
		Fx.play("boom")
	else
		Fx.play("kill")
	end
	give(e.kind, e.m)
end

function Renderer.shot(id: number, x: number, z: number, dx: number, dz: number, speed: number, range: number, boom: boolean, kind: string?)
	local k = kind or "shot"
	local m = take(k)
	shots[id] = { m = m, kind = k, x = x, z = z, dx = dx, dz = dz, speed = speed, left = range }
	if k ~= "missile" then
		local mz = muzzle
		if not mz then
			mz = flat(Enum.PartType.Ball, MUZZLE_COLOR, 0.2)
			muzzle = mz
		end
		mz.Color = if k == "mortar" then WAVE_COLORS[1] elseif k == "spread" then WAVE_COLORS[2] else MUZZLE_COLOR
		mz.CFrame = CFrame.new(x + dx * 2, playerPos.Y + 0.3, z + dz * 2)
		muzzleT = MUZZLE_TIME
		Fx.kickBack(if boom or k == "mortar" then 0.22 elseif k == "spread" then 0.13 else 0.1)
		if boom then
			Fx.shake(0.12)
		end
		Fx.play("shoot", if k == "mortar" then 0.56 elseif k == "spread" then 1.18 elseif boom then 0.6 else 1)
	else
		Fx.play("shoot", 1.38)
	end
end

function Renderer.shotEnd(id: number)
	local s = shots[id]
	if s then
		shots[id] = nil
		if s.kind == "spread" then
			Fx.burst("gold", Vector3.new(s.x, 2.6, s.z), 5)
		elseif s.kind ~= "mortar" and s.kind ~= "missile" then
			Fx.burst("cyan", Vector3.new(s.x, 2.6, s.z), 5)
		end
		give(s.kind or "shot", s.m)
	end
end

function Renderer.waveRing(x: number, z: number, radius: number, kind: number?)
	local p = table.remove(wavePool) or flat(Enum.PartType.Cylinder, C.cyan, 0.2)
	local k = kind or 1
	p.Color = WAVE_COLORS[k] or C.cyan
	p.Transparency = if k == 3 then 0.42 else 0.16
	setCircle(p, x, z, math.max(1.5, radius * 0.22), 0.24)
	table.insert(waveRings, { p = p, x = x, z = z, r = radius, t = 0, dur = if k == 3 then 0.32 else 0.42 })
	if k == 2 then
		Fx.burst("gold", Vector3.new(x, 1.5, z), 22)
		Fx.play("boom", 1.15)
		Fx.shake(0.16)
	end
end

function Renderer.arc(pts: { number })
	local segCount = 0
	for i = 1, #pts - 3, 2 do
		local x1, z1, x2, z2 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
		local mx, mz = (x1 + x2) * 0.5, (z1 + z2) * 0.5
		local dx, dz = x2 - x1, z2 - z1
		local len = math.max(0.1, math.sqrt(dx * dx + dz * dz))
		local nx, nz = -dz / len, dx / len
		local jit = (if (i // 2) % 2 == 0 then 1 else -1) * math.min(1.6, len * 0.14)
		local jx, jz = mx + nx * jit, mz + nz * jit
		local hops = { { x1, z1, jx, jz }, { jx, jz, x2, z2 } }
		for _, h in hops do
			local ax, az, bx, bz = h[1], h[2], h[3], h[4]
			local hdx, hdz = bx - ax, bz - az
			local hlen = math.max(0.2, math.sqrt(hdx * hdx + hdz * hdz))
			local p = table.remove(beamPool) or flat(Enum.PartType.Block, Color3.fromRGB(140, 240, 255), 0.08)
			p.Color = Color3.fromRGB(140, 240, 255)
			p.Transparency = 0.06
			p.Size = Vector3.new(0.32, 0.32, hlen)
			p.CFrame = CFrame.lookAt(Vector3.new((ax + bx) * 0.5, 2.7, (az + bz) * 0.5), Vector3.new(bx, 2.7, bz))
			table.insert(arcBeams, { p = p, t = 0, dur = 0.18 })
			segCount += 1
		end
		Fx.burst("cyan", Vector3.new(x2, 2.6, z2), 7)
	end
	if segCount > 0 then
		Fx.play("hit", 1.45)
	end
end

function Renderer.eshot(id: number, x: number, z: number, vx: number, vz: number, life: number)
	eshots[id] = { m = take("eshot"), x = x, z = z, vx = vx, vz = vz, life = life }
end

function Renderer.eshotEnd(id: number)
	local s = eshots[id]
	if s then
		eshots[id] = nil
		give("eshot", s.m)
	end
end

local function takeMeteor(): Model
	local cached = table.remove(meteorPool)
	if cached then
		return cached
	end
	local m = Instance.new("Model")
	m.Name = "MeteorVisual"
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(4.2, 4.2, 4.2)
	core.Color = Color3.fromRGB(255, 115, 35)
	core.Material = Enum.Material.Neon
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.CastShadow = false
	core.Parent = m
	local rock = Instance.new("Part")
	rock.Size = Vector3.new(3.6, 3.2, 3.6)
	rock.Color = Color3.fromRGB(108, 74, 70)
	rock.Material = Enum.Material.Slate
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanQuery = false
	rock.CanTouch = false
	rock.CFrame = CFrame.new(0, 0.2, 0) * CFrame.Angles(0.5, 0.9, 0.3)
	rock.Parent = m
	local trail = Instance.new("Part")
	trail.Shape = Enum.PartType.Cylinder
	trail.Size = Vector3.new(12, 2.2, 2.2)
	trail.Color = Color3.fromRGB(255, 195, 75)
	trail.Material = Enum.Material.Neon
	trail.Transparency = 0.35
	trail.Anchored = true
	trail.CanCollide = false
	trail.CanQuery = false
	trail.CanTouch = false
	trail.CFrame = CFrame.new(0, 5.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	trail.Parent = m
	m.PrimaryPart = core
	m.Parent = folder
	return m
end

function Renderer.tele(id: number, shape: string, a: number, b: number, c: number, d: number, e: number?, f: number?, g: number?)
	if shape == "c" or shape == "m" then
		local col = if shape == "m" then Color3.fromRGB(255, 45, 30) else Color3.fromRGB(255, 55, 45)
		local base = table.remove(circlePool) or flat(Enum.PartType.Cylinder, col, 0.78)
		local fill = table.remove(circlePool) or flat(Enum.PartType.Cylinder, col, 0.42)
		base.Color, fill.Color = col, col
		base.Transparency, fill.Transparency = 0.7, 0.5
		setCircle(base, a, b, c, 0.14)
		setCircle(fill, a, b, 0.1, 0.22)
		local rock: Model? = nil
		if shape == "m" then
			local rm = takeMeteor()
			rm:PivotTo(CFrame.new(a, 98, b))
			rock = rm
		end
		teles[id] = { shape = shape, base = base, fill = fill, rock = rock, x = a, z = b, r = c, t = 0, dur = d, real = true }
	else
		local x, z, x2, z2, w, dur, real = a, b, c, d, e :: number, f :: number, g == 1
		local len = math.max(0.5, math.sqrt((x2 - x) ^ 2 + (z2 - z) ^ 2))
		local cf = CFrame.lookAt(Vector3.new((x + x2) / 2, 0.14, (z + z2) / 2), Vector3.new(x2, 0.14, z2))
		local base = table.remove(linePool) or flat(Enum.PartType.Block, C.orange, 0.8)
		base.Color = if real then Color3.fromRGB(255, 55, 45) else C.magenta
		base.Transparency = if real then 0.7 else 0.55
		base.Size = Vector3.new(w, 0.12, len)
		base.CFrame = cf
		local fill: Part? = nil
		if real then
			fill = table.remove(linePool) or flat(Enum.PartType.Block, C.orange, 0.45)
			local fp = fill :: Part
			fp.Color = Color3.fromRGB(255, 55, 45)
			fp.Transparency = 0.45
			fp.Size = Vector3.new(0.1, 0.14, len)
			fp.CFrame = cf + Vector3.new(0, 0.05, 0)
		end
		teles[id] = { shape = "l", base = base, fill = fill, w = w, len = len, cf = cf, t = 0, dur = dur, real = real, x = (x + x2) / 2, z = (z + z2) / 2 }
	end
	Fx.play("warn")
end

function Renderer.teleEnd(id: number)
	local t = teles[id]
	if not t then
		return
	end
	teles[id] = nil
	t.base.CFrame = FAR
	local pool = if t.shape == "c" or t.shape == "m" then circlePool else linePool
	table.insert(pool, t.base)
	if t.fill then
		t.fill.CFrame = FAR
		table.insert(pool, t.fill)
	end
	if t.rock then
		t.rock:PivotTo(FAR)
		table.insert(meteorPool, t.rock)
	end
end

function Renderer.boom(x: number, z: number, r: number)
	Fx.burst("boom", Vector3.new(x, 2, z), math.clamp(math.floor(r * 3), 12, 50))
	Fx.play("boom")
	local d = (Vector3.new(x, 0, z) - Vector3.new(playerPos.X, 0, playerPos.Z)).Magnitude
	if d < 40 then
		Fx.shake(0.25)
	end
end

function Renderer.meteorBoom(x: number, z: number, r: number)
	Fx.burst("boom", Vector3.new(x, 1.5, z), math.clamp(math.floor(r * 4), 24, 65))
	Fx.burst("gold", Vector3.new(x, 2.2, z), 22)
	Fx.play("boom", 0.85)
	local d = (Vector3.new(x, 0, z) - Vector3.new(playerPos.X, 0, playerPos.Z)).Magnitude
	if d < 75 then
		Fx.shake(if d < r * 2 then 0.36 else 0.18)
	end
end

function Renderer.shieldHit()
	shieldFlashT = 0.18
	Fx.burst("cyan", playerPos + Vector3.new(0, 0.5, 0), 18)
end

function Renderer.shieldBreak()
	shieldFlashT = 0.25
	Fx.burst("cyan", playerPos, 42)
	Fx.shake(0.22)
end

function Renderer.gem(id: number, x: number, z: number)
	local m = take("gem")
	;(m.PrimaryPart :: Part).CFrame = CFrame.new(x, 0, z)
	gems[id] = { m = m, x = x, z = z, fly = -1 }
end

function Renderer.gemGot(id: number)
	local g = gems[id]
	if g then
		g.fly = 0
	end
end

function Renderer.chest(id: number, x: number, z: number, tier: number?)
	local tr = math.clamp(tier or 1, 1, 4)
	local col = CHEST_COLORS[tr] or CHEST_COLORS[1]
	local m = take("chest")
	;(m.PrimaryPart :: Part).CFrame = CFrame.new(x, 0, z)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
			d.Color = col
		end
	end
	local beam = flat(Enum.PartType.Cylinder, col, if tr >= 3 then 0.42 else 0.58)
	beam.Size = Vector3.new(12 + tr * 5, 0.45 + tr * 0.14, 0.45 + tr * 0.14)
	beam.CFrame = CFrame.new(x, (12 + tr * 5) * 0.5 + 0.5, z) * UPR
	local ring = flat(Enum.PartType.Cylinder, col, 0.45)
	setCircle(ring, x, z, 2.4 + tr * 0.45, 0.16)
	chests[id] = { m = m, x = x, z = z, tier = tr, beam = beam, ring = ring }
end

function Renderer.chestGot(id: number, tier: number?)
	local c = chests[id]
	if c then
		chests[id] = nil
		local tr = tier or c.tier or 1
		if tr >= 3 then
			Fx.burst("gold", Vector3.new(c.x, 3, c.z), 48)
			Fx.burst("cyan", Vector3.new(c.x, 4, c.z), 28)
		else
			Fx.burst("gold", Vector3.new(c.x, 3, c.z), 36)
		end
		Fx.play("chest")
		if c.beam then
			c.beam:Destroy()
		end
		if c.ring then
			c.ring:Destroy()
		end
		give("chest", c.m)
	end
end

function Renderer.nearestChest(): (Vector3?, number?)
	local best: Vector3? = nil
	local bestTier: number? = nil
	local bestD = math.huge
	for _, c in chests do
		local d = (c.x - playerPos.X) ^ 2 + (c.z - playerPos.Z) ^ 2
		if d < bestD then
			bestD = d
			best = Vector3.new(c.x, 2, c.z)
			bestTier = c.tier or 1
		end
	end
	return best, bestTier
end

function Renderer.enemyCount(): number
	local n = 0
	for _ in enemies do
		n += 1
	end
	return n
end

function Renderer.setHud(h: { number })
	hud = h
	simT = h[16]
end

function Renderer.skillFx(idx: number)
	if idx == 2 then
		Fx.burst("cyan", playerPos, 60)
		Fx.shake(0.2)
	end
	Fx.play("skill", if idx == 1 then 1.3 else 1)
end

function Renderer.setQuality(tier: string)
	if tier ~= "high" and tier ~= "med" and tier ~= "low" then
		tier = "high"
	end
	qualityTier = tier
end

-- Campo electrostatico: el anillo solo se muestra si hay un enemigo dentro de su alcance.
local function auraNearby(px: number, pz: number): boolean
	local R = Balance.Upgrades.aura.radius + 4
	for _, e in enemies do
		local dx, dz = e.x - px, e.z - pz
		if dx * dx + dz * dz <= R * R then
			return true
		end
	end
	return false
end

function Renderer.update(dt: number)
	oddFrame = not oddFrame
	local paused = hud ~= nil and hud[18] == 1
	local sdt = if paused then 0 else dt
	local farDistSq = if qualityTier == "low" then 4900 elseif qualityTier == "med" then 10000 else math.huge
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp then
		playerPos = hrp.Position
	end
	local px, pz = playerPos.X, playerPos.Z
	if muzzleT > 0 and muzzle then
		muzzleT -= dt
		if muzzleT <= 0 then
			muzzle.CFrame = FAR
		else
			local k = muzzleT / MUZZLE_TIME
			local d = 1 + 1.8 * (1 - k)
			muzzle.Size = Vector3.new(d, d, d)
			muzzle.Transparency = 0.2 + 0.75 * (1 - k)
		end
	end
	local feet = playerPos.Y - (if hrp and hum then hrp.Size.Y * 0.5 + hum.HipHeight else 2.9)
	if char and hrp then
		local torso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
		local scaleRef = if torso then math.clamp(torso.Size.Y / 1.65, 0.35, 1.6) else 1
		heroRadius = math.clamp(7.0 * scaleRef, 4.2, 10.5)
	end

	-- Los avisos y el heroe no se congelan con el hitstop; los enemigos si.
	local frozen = Fx.frozen()
	if not frozen then
		for _, e in enemies do
			local moved = false
			if e.a < 1 then
				e.a = math.min(1, e.a + dt / INTERP)
				local nx, nz = e.x0 + (e.x1 - e.x0) * e.a, e.z0 + (e.z1 - e.z0) * e.a
				local mx, mz = nx - e.x, nz - e.z
				e.x, e.z = nx, nz
				if mx * mx + mz * mz <= 0.0004 then
					mx, mz = px - nx, pz - nz
				end
				local len = math.sqrt(mx * mx + mz * mz)
				if len > 0.01 then
					-- giro suavizado hacia la dirección de avance
					local k = math.min(1, dt * 10)
					e.dx += (mx / len - e.dx) * k
					e.dz += (mz / len - e.dz) * k
				end
				moved = true
			end
			if e.rise < 1 then
				e.rise = math.min(1, e.rise + dt / 0.4)
				moved = true
			end
			local kick = e.kick
			if kick > 0 then
				kick = math.max(0, kick - dt / Balance.Juice.KickTime)
				e.kick = kick
				moved = true
			end
			if moved then
				local skipFar = oddFrame and e.flash <= 0 and kick <= 0 and ((e.x - px) * (e.x - px) + (e.z - pz) * (e.z - pz) > farDistSq)
				if not skipFar then
					local y = -6 * (1 - e.rise) * (1 - e.rise)
					local pos = Vector3.new(e.x, y, e.z)
					if e.dx * e.dx + e.dz * e.dz > 0.0001 then
						-- el golpe empuja al enemigo hacia atras y lo inclina un instante
						local back = kick * Balance.Juice.KickDist
						pos -= Vector3.new(e.dx, 0, e.dz) * back
						e.root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(e.dx, 0, e.dz)) * CFrame.Angles(kick * 0.26, 0, 0)
					else
						e.root.CFrame = CFrame.new(pos)
					end
				end
			end
			if e.flash > 0 then
				e.flash -= dt
				if e.flash <= 0 then
					restoreColors(e.m)
				end
			end
		end
	end

	for id, s in shots do
		local step = s.speed * sdt
		s.x += s.dx * step
		s.z += s.dz * step
		s.left -= step
		if s.left <= 0 then
			shots[id] = nil
			give(s.kind or "shot", s.m)
		else
			s.m.PrimaryPart.CFrame = CFrame.lookAt(Vector3.new(s.x, 0, s.z), Vector3.new(s.x + s.dx, 0, s.z + s.dz))
		end
	end
	for i = #waveRings, 1, -1 do
		local w = waveRings[i]
		w.t += dt
		local k = math.clamp(w.t / w.dur, 0, 1)
		if k >= 1 then
			w.p.CFrame = FAR
			table.insert(wavePool, w.p)
			waveRings[i] = waveRings[#waveRings]
			waveRings[#waveRings] = nil
		else
			setCircle(w.p, w.x, w.z, math.max(1.2, w.r * (0.2 + 0.85 * k)), 0.24)
			w.p.Transparency = 0.18 + 0.82 * (k * k)
		end
	end
	for i = #arcBeams, 1, -1 do
		local b = arcBeams[i]
		b.t += dt
		local k = math.clamp(b.t / b.dur, 0, 1)
		if k >= 1 then
			b.p.CFrame = FAR
			table.insert(beamPool, b.p)
			arcBeams[i] = arcBeams[#arcBeams]
			arcBeams[#arcBeams] = nil
		else
			b.p.Transparency = 0.06 + 0.94 * k
		end
	end
	for id, s in eshots do
		s.x += s.vx * sdt
		s.z += s.vz * sdt
		s.life -= sdt
		if s.life <= 0 then
			eshots[id] = nil
			give("eshot", s.m)
		else
			s.m.PrimaryPart.CFrame = CFrame.new(s.x, 0, s.z)
		end
	end

	for id, t in teles do
		t.t += sdt
		local k = math.clamp(t.t / t.dur, 0, 1)
		if t.shape == "c" or t.shape == "m" then
			setCircle(t.fill, t.x, t.z, t.r * k, 0.22)
			if t.rock then
				local y = 98 * (1 - k * k)
				t.rock:PivotTo(CFrame.new(t.x, y, t.z) * CFrame.Angles(t.t * 4.5, t.t * 3.1, 0))
			end
		elseif t.fill then
			t.fill.Size = Vector3.new(math.max(0.1, t.w * k), 0.14, t.len)
		end
		if t.t >= t.dur then
			if t.real then
				Fx.burst("boom", Vector3.new(t.x, 1.5, t.z), if t.shape == "m" then 26 else 14)
				Fx.play("boom", if t.shape == "m" then 0.85 else 1.3)
			end
			Renderer.teleEnd(id)
		end
	end

	local now = os.clock()
	for id, g in gems do
		if g.fly >= 0 then
			g.fly += dt / 0.16
			if g.fly >= 1 then
				gems[id] = nil
				give("gem", g.m)
				if now - lastGemSound > 0.05 then
					lastGemSound = now
					Fx.play("gem")
				end
			else
				local x, z = g.x + (px - g.x) * g.fly, g.z + (pz - g.z) * g.fly
				g.m.PrimaryPart.CFrame = CFrame.new(x, g.fly * 2, z)
			end
		end
	end

	if shieldFlashT > 0 then
		shieldFlashT = math.max(0, shieldFlashT - dt)
	end

	local h = hud
	if h then
		simT += dt
		local want = h[14]
		while #drones < want do
			table.insert(drones, take("drone"))
		end
		while #drones > want do
			give("drone", table.remove(drones) :: Model)
		end
		local D = Balance.Upgrades.drone
		for i, m in drones do
			local a = simT * D.angSpeed + (i - 1) * math.pi * 2 / want
			;(m.PrimaryPart :: Part).CFrame = CFrame.new(px + math.cos(a) * D.radius, feet + 1.2, pz + math.sin(a) * D.radius) * CFrame.Angles(0, -a, 0)
		end
		if h[15] == 1 and auraNearby(px, pz) then
			setCircle(auraRing, px, pz, Balance.Upgrades.aura.radius, feet + 0.15)
		else
			auraRing.CFrame = FAR
		end
		local hasActiveShield = h[3] > 0
		if hasActiveShield or h[17] == 1 then
			local d = heroRadius
			shieldBubble.Size = Vector3.new(d, d, d)
			shieldBubble.CFrame = CFrame.new(playerPos)
			if shieldFlashT > 0 then
				shieldBubble.Color = WHITE
				shieldBubble.Transparency = 0.45
			elseif hasActiveShield then
				shieldBubble.Color = C.cyan
				shieldBubble.Transparency = 0.78 + math.sin(simT * 6) * 0.03
			else
				shieldBubble.Color = C.cyan
				shieldBubble.Transparency = 0.8
			end
			shieldRing.Size = Vector3.new(0.24, d * 1.12, d * 1.12)
			shieldRing.Color = if shieldFlashT > 0 then WHITE else C.cyan
			shieldRing.Transparency = if hasActiveShield then 0.45 else 0.7
			shieldRing.CFrame = CFrame.new(playerPos) * CFrame.Angles(0.32, simT * 2.2, math.rad(90) + 0.18)
		else
			shieldBubble.CFrame = FAR
			shieldRing.CFrame = FAR
		end
	end
end

return Renderer
