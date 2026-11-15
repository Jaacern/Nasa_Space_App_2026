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
local circlePool: { Part } = {}
local linePool: { Part } = {}
local auraRing: Part
local shieldBubble: Part
local hud: { number }? = nil
local simT = 0
local playerPos = Vector3.zero
local lastGemSound = 0

local function take(kind: string): Model
	local pool = pools[kind]
	if pool and #pool > 0 then
		return table.remove(pool) :: Model
	end
	-- malla propia si existe; si no, plantilla basica del servidor
	local t = meshTemplates[kind] or templates:FindFirstChild(kind) or templates:FindFirstChild("chaser")
	local m = (t :: Model):Clone()
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
	auraRing = flat(Enum.PartType.Cylinder, C.cyan, 0.86)
	shieldBubble = flat(Enum.PartType.Ball, C.cyan, 0.7)
	shieldBubble.Material = Enum.Material.ForceField
	shieldBubble.Size = Vector3.new(9, 9, 9)
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
		give("shot", s.m)
		shots[id] = nil
	end
	for id, s in eshots do
		give("eshot", s.m)
		eshots[id] = nil
	end
	for id, t in teles do
		Renderer.teleEnd(id)
	end
	for id, g in gems do
		give("gem", g.m)
		gems[id] = nil
	end
	for id, c in chests do
		give("chest", c.m)
		chests[id] = nil
	end
	for _, d in drones do
		give("drone", d)
	end
	table.clear(drones)
	auraRing.CFrame = FAR
	shieldBubble.CFrame = FAR
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

function Renderer.shot(id: number, x: number, z: number, dx: number, dz: number, speed: number, range: number, boom: boolean)
	local m = take("shot")
	shots[id] = { m = m, x = x, z = z, dx = dx, dz = dz, speed = speed, left = range }
	Fx.play("shoot", if boom then 0.6 else 1)
end

function Renderer.shotEnd(id: number)
	local s = shots[id]
	if s then
		shots[id] = nil
		Fx.burst("cyan", Vector3.new(s.x, 2.6, s.z), 5)
		give("shot", s.m)
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

function Renderer.tele(id: number, shape: string, a: number, b: number, c: number, d: number, e: number?, f: number?, g: number?)
	if shape == "c" then
		local base = table.remove(circlePool) or flat(Enum.PartType.Cylinder, C.orange, 0.8)
		local fill = table.remove(circlePool) or flat(Enum.PartType.Cylinder, C.orange, 0.45)
		base.Transparency, fill.Transparency = 0.8, 0.45
		setCircle(base, a, b, c, 0.12)
		setCircle(fill, a, b, 0.1, 0.2)
		teles[id] = { shape = "c", base = base, fill = fill, x = a, z = b, r = c, t = 0, dur = d, real = true }
	else
		local x, z, x2, z2, w, dur, real = a, b, c, d, e :: number, f :: number, g == 1
		local len = math.max(0.5, math.sqrt((x2 - x) ^ 2 + (z2 - z) ^ 2))
		local cf = CFrame.lookAt(Vector3.new((x + x2) / 2, 0.14, (z + z2) / 2), Vector3.new(x2, 0.14, z2))
		local base = table.remove(linePool) or flat(Enum.PartType.Block, C.orange, 0.8)
		base.Color = if real then C.orange else C.magenta
		base.Transparency = if real then 0.8 else 0.55
		base.Size = Vector3.new(w, 0.12, len)
		base.CFrame = cf
		local fill: Part? = nil
		if real then
			fill = table.remove(linePool) or flat(Enum.PartType.Block, C.orange, 0.45)
			local fp = fill :: Part
			fp.Color = C.orange
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
	local pool = if t.shape == "c" then circlePool else linePool
	table.insert(pool, t.base)
	if t.fill then
		t.fill.CFrame = FAR
		table.insert(pool, t.fill)
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

function Renderer.chest(id: number, x: number, z: number)
	local m = take("chest")
	;(m.PrimaryPart :: Part).CFrame = CFrame.new(x, 0, z)
	chests[id] = { m = m, x = x, z = z }
end

function Renderer.chestGot(id: number)
	local c = chests[id]
	if c then
		chests[id] = nil
		Fx.burst("gold", Vector3.new(c.x, 3, c.z), 40)
		Fx.play("chest")
		give("chest", c.m)
	end
end

function Renderer.nearestChest(): Vector3?
	local best: Vector3? = nil
	local bestD = math.huge
	for _, c in chests do
		local d = (c.x - playerPos.X) ^ 2 + (c.z - playerPos.Z) ^ 2
		if d < bestD then
			bestD = d
			best = Vector3.new(c.x, 2, c.z)
		end
	end
	return best
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

function Renderer.update(dt: number)
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		playerPos = hrp.Position
	end
	local px, pz = playerPos.X, playerPos.Z
	local feet = playerPos.Y - 2.9

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
			if e.flash > 0 then
				e.flash -= dt
				if e.flash <= 0 then
					restoreColors(e.m)
				end
			end
		end
	end

	for id, s in shots do
		local step = s.speed * dt
		s.x += s.dx * step
		s.z += s.dz * step
		s.left -= step
		if s.left <= 0 then
			shots[id] = nil
			give("shot", s.m)
		else
			s.m.PrimaryPart.CFrame = CFrame.lookAt(Vector3.new(s.x, 0, s.z), Vector3.new(s.x + s.dx, 0, s.z + s.dz))
		end
	end
	for id, s in eshots do
		s.x += s.vx * dt
		s.z += s.vz * dt
		s.life -= dt
		if s.life <= 0 then
			eshots[id] = nil
			give("eshot", s.m)
		else
			s.m.PrimaryPart.CFrame = CFrame.new(s.x, 0, s.z)
		end
	end

	for id, t in teles do
		t.t += dt
		local k = math.clamp(t.t / t.dur, 0, 1)
		if t.shape == "c" then
			setCircle(t.fill, t.x, t.z, t.r * k, 0.2)
		elseif t.fill then
			t.fill.Size = Vector3.new(math.max(0.1, t.w * k), 0.14, t.len)
		end
		if t.t >= t.dur then
			if t.real then
				Fx.burst("boom", Vector3.new(t.x, 1.5, t.z), 14)
				Fx.play("boom", 1.3)
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
			;(m.PrimaryPart :: Part).CFrame = CFrame.new(px + math.cos(a) * D.radius, feet, pz + math.sin(a) * D.radius) * CFrame.Angles(0, -a, 0)
		end
		if h[15] == 1 then
			setCircle(auraRing, px, pz, Balance.Upgrades.aura.radius, feet + 0.15)
		else
			auraRing.CFrame = FAR
		end
		if h[3] > 0 or h[17] == 1 then
			shieldBubble.CFrame = CFrame.new(playerPos)
		else
			shieldBubble.CFrame = FAR
		end
	end
end

return Renderer
