--!strict
-- Modelos hechos con piezas (arte provisional intercambiable por mallas de Blender).
-- Cada plantilla es un Model con PrimaryPart "Root" anclado y el resto soldado.
-- Codigo de color: jugador cian, enemigos rojo/magenta, recompensas dorado, peligro naranja.

local Visuals = {}

local C = {
	cyan = Color3.fromRGB(0, 210, 255),
	cyanDark = Color3.fromRGB(0, 180, 216),
	red = Color3.fromRGB(255, 45, 85),
	magenta = Color3.fromRGB(255, 0, 170),
	dark = Color3.fromRGB(38, 22, 34),
	rock = Color3.fromRGB(70, 52, 58),
	gold = Color3.fromRGB(255, 200, 40),
	orange = Color3.fromRGB(255, 107, 53),
	white = Color3.fromRGB(235, 240, 245),
	hull = Color3.fromRGB(200, 205, 215),
	hullDark = Color3.fromRGB(60, 66, 80),
	panel = Color3.fromRGB(11, 19, 43),
}
Visuals.Colors = C

local function base(p: Part)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
end

local function newModel(name: string): (Model, Part)
	local m = Instance.new("Model")
	m.Name = name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	base(root)
	root.Parent = m
	m.PrimaryPart = root
	return m, root
end

local function add(m: Model, root: Part, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, transparency: number?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Transparency = transparency or 0
	base(p)
	p.CFrame = root.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
	p.Parent = m
	return p
end

local NEON = Enum.Material.Neon
local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local UP = CFrame.Angles(0, 0, math.rad(90)) -- cilindro con eje vertical

local function chaser(name: string, s: number): Model
	local m, r = newModel(name)
	add(m, r, Vector3.new(1.2, 2.6, 2.6) * s, CFrame.new(0, 0.9 * s, 0) * UP, C.dark, Enum.Material.Sand, CYL)
	add(m, r, Vector3.new(1.0, 3.4, 3.4) * s, CFrame.new(0, 2.0 * s, 0) * UP, C.rock, Enum.Material.Sand, CYL)
	add(m, r, Vector3.new(0.8, 4.2, 4.2) * s, CFrame.new(0, 2.9 * s, 0) * UP, C.dark, Enum.Material.Sand, CYL)
	add(m, r, Vector3.new(1.3, 1.3, 1.3) * s, CFrame.new(0, 2.0 * s, -1.5 * s), C.red, NEON, BALL)
	return m
end

local function tank(name: string, s: number): Model
	local m, r = newModel(name)
	add(m, r, Vector3.new(5, 4.4, 4.4) * s, CFrame.new(0, 2.6 * s, 0), C.rock, Enum.Material.Slate)
	add(m, r, Vector3.new(2.6, 2.2, 2.6) * s, CFrame.new(0, 5.6 * s, -0.3 * s), C.dark, Enum.Material.Slate)
	add(m, r, Vector3.new(1.8, 3.6, 1.8) * s, CFrame.new(-3.3 * s, 2.6 * s, 0), C.dark, Enum.Material.Slate)
	add(m, r, Vector3.new(1.8, 3.6, 1.8) * s, CFrame.new(3.3 * s, 2.6 * s, 0), C.dark, Enum.Material.Slate)
	add(m, r, Vector3.new(1.8, 0.5, 0.4) * s, CFrame.new(0, 5.8 * s, -1.6 * s), C.magenta, NEON)
	add(m, r, Vector3.new(2.2, 2.2, 0.4) * s, CFrame.new(0, 2.8 * s, -2.25 * s), C.red, NEON)
	return m
end

local function ranged(name: string, s: number): Model
	local m, r = newModel(name)
	add(m, r, Vector3.new(2.2, 2.2, 2.2) * s, CFrame.new(0, 3.2 * s, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), C.magenta, NEON)
	add(m, r, Vector3.new(0.3, 4.6, 4.6) * s, CFrame.new(0, 3.2 * s, 0) * UP, C.dark, Enum.Material.Metal, CYL)
	add(m, r, Vector3.new(0.5, 0.5, 2.4) * s, CFrame.new(0, 3.2 * s, -2.0 * s), C.red, NEON)
	add(m, r, Vector3.new(0.4, 1.6, 1.6) * s, CFrame.new(0, 0.3 * s, 0) * UP, C.dark, Enum.Material.Metal, CYL, 0.3)
	return m
end

local function kamikaze(name: string, s: number): Model
	local m, r = newModel(name)
	add(m, r, Vector3.new(2.6, 2.6, 2.6) * s, CFrame.new(0, 2.0 * s, 0), C.rock, Enum.Material.Basalt, BALL)
	add(m, r, Vector3.new(1.5, 1.5, 1.5) * s, CFrame.new(0, 2.0 * s, -0.9 * s), C.orange, NEON, BALL)
	add(m, r, Vector3.new(0.5, 3.6, 0.5) * s, CFrame.new(0, 2.0 * s, 0) * CFrame.Angles(0, 0, math.rad(45)), C.red, NEON)
	add(m, r, Vector3.new(0.5, 3.6, 0.5) * s, CFrame.new(0, 2.0 * s, 0) * CFrame.Angles(0, 0, math.rad(-45)), C.red, NEON)
	return m
end

local function crown(m: Model, s: number, y: number, color: Color3)
	local r = m.PrimaryPart :: Part
	add(m, r, Vector3.new(0.4, 6 * s, 6 * s), CFrame.new(0, y, 0) * UP, color, NEON, CYL, 0.35)
end

local function boss(name: string, kind: string, s: number): Model
	local m: Model
	if kind == "chaser" then
		m = chaser(name, s)
	elseif kind == "tank" then
		m = tank(name, s)
	elseif kind == "ranged" then
		m = ranged(name, s)
	else
		m = tank(name, s)
		local r = m.PrimaryPart :: Part
		add(m, r, Vector3.new(4, 4, 4) * s, CFrame.new(0, 8.6 * s, 0), C.orange, NEON, BALL)
		add(m, r, Vector3.new(0.5, 9, 9) * s, CFrame.new(0, 8.6 * s, 0) * UP, C.gold, NEON, CYL, 0.4)
	end
	crown(m, s, 0.3, C.magenta)
	return m
end

local function gem(): Model
	local m, r = newModel("gem")
	add(m, r, Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, 1.2, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), C.gold, NEON)
	return m
end

local function chest(): Model
	local m, r = newModel("chest")
	add(m, r, Vector3.new(3.4, 2.2, 2.4), CFrame.new(0, 1.2, 0), C.hullDark, Enum.Material.Metal)
	add(m, r, Vector3.new(3.6, 0.5, 2.6), CFrame.new(0, 2.3, 0), C.gold, NEON)
	add(m, r, Vector3.new(0.6, 0.9, 0.3), CFrame.new(0, 1.3, -1.25), C.gold, NEON)
	add(m, r, Vector3.new(60, 1.2, 1.2), CFrame.new(0, 32, 0) * UP, C.gold, NEON, CYL, 0.6)
	return m
end

local function shot(name: string, color: Color3, size: Vector3, shape: Enum.PartType?): Model
	local m, r = newModel(name)
	add(m, r, size, CFrame.new(0, 2.6, 0), color, NEON, shape)
	return m
end

local function drone(): Model
	local m, r = newModel("drone")
	add(m, r, Vector3.new(1.2, 0.6, 1.2), CFrame.new(0, 3.2, 0), C.white, Enum.Material.Metal)
	add(m, r, Vector3.new(0.15, 3.0, 3.0), CFrame.new(0, 3.7, 0) * UP, C.cyan, NEON, CYL, 0.5)
	add(m, r, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 2.8, 0), C.cyan, NEON, BALL)
	return m
end

-- Piezas de la nave. Se ven en la nave (ranuras) y como recompensa.
local function piece(i: number): Model
	local m, r = newModel("Piece" .. i)
	if i == 1 then -- MMRTG: cilindro con aletas
		add(m, r, Vector3.new(4.5, 2, 2), CFrame.new(0, 0, 0), C.hullDark, Enum.Material.Metal, CYL)
		for k = 0, 3 do
			add(m, r, Vector3.new(4, 0.2, 3.6), CFrame.Angles(math.rad(45 * k), 0, 0), C.white, Enum.Material.Metal)
		end
		add(m, r, Vector3.new(0.5, 1.4, 1.4), CFrame.new(2.4, 0, 0), C.orange, NEON, CYL)
	elseif i == 2 then -- Antena de alta ganancia
		add(m, r, Vector3.new(0.5, 5, 5), CFrame.new(0, 0, 0) * UP, C.white, Enum.Material.Metal, CYL)
		add(m, r, Vector3.new(0.3, 3.6, 3.6), CFrame.new(0, 0.3, 0) * UP, C.hull, Enum.Material.Metal, CYL)
		add(m, r, Vector3.new(0.3, 2.4, 0.3), CFrame.new(0, 1.4, 0), C.hullDark, Enum.Material.Metal)
		add(m, r, Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 2.7, 0), C.cyan, NEON, BALL)
	elseif i == 3 then -- Generador de oxigeno
		add(m, r, Vector3.new(3, 3, 3), CFrame.new(0, 0, 0), C.gold, Enum.Material.Foil)
		add(m, r, Vector3.new(0.8, 0.8, 3.3), CFrame.new(0, 0.6, 0), C.hullDark, Enum.Material.Metal)
		add(m, r, Vector3.new(1.6, 1, 1), CFrame.new(0, 1.9, 0) * UP, C.hull, Enum.Material.Metal, CYL)
		add(m, r, Vector3.new(2.2, 0.4, 0.2), CFrame.new(0, -0.6, -1.55), C.cyan, NEON)
	else -- Propulsor
		add(m, r, Vector3.new(2, 2.6, 2.6), CFrame.new(0, 1, 0) * UP, C.hullDark, Enum.Material.Metal, CYL)
		add(m, r, Vector3.new(1.4, 3.6, 3.6), CFrame.new(0, -0.6, 0) * UP, C.hull, Enum.Material.Metal, CYL)
		add(m, r, Vector3.new(0.8, 4.4, 4.4), CFrame.new(0, -1.6, 0) * UP, C.hullDark, Enum.Material.Metal, CYL)
		add(m, r, Vector3.new(0.3, 3.4, 3.4), CFrame.new(0, -2.0, 0) * UP, C.orange, NEON, CYL)
	end
	return m
end

-- Nave estrellada: piezas ancladas con colision. Las ranuras Piece1..4 empiezan ocultas en el cliente.
function Visuals.makeShip(): Model
	local ship = Instance.new("Model")
	ship.Name = "Ship"
	local function solid(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		if shape then
			p.Shape = shape
		end
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = ship
		return p
	end
	local tilt = CFrame.new(0, 12.5, 0) * CFrame.Angles(0, math.rad(25), math.rad(8))
	local body = solid(Vector3.new(16, 10, 10), tilt * UP, C.hull, Enum.Material.Metal, CYL)
	body.Name = "Body"
	ship.PrimaryPart = body
	solid(Vector3.new(5, 8, 8), tilt * CFrame.new(0, 10, 0) * UP, C.white, Enum.Material.Metal, CYL)
	solid(Vector3.new(3, 5, 5), tilt * CFrame.new(0, 13.5, 0) * UP, C.hullDark, Enum.Material.Metal, CYL)
	solid(Vector3.new(1, 10.4, 10.4), tilt * CFrame.new(0, 3, 0) * UP, C.cyanDark, NEON, CYL)
	for k = 0, 2 do
		local a = math.rad(120 * k)
		solid(Vector3.new(1, 12, 1.2), tilt * CFrame.Angles(0, a, 0) * CFrame.new(5.6, -6, 0) * CFrame.Angles(0, 0, math.rad(-25)), C.hullDark, Enum.Material.Metal)
	end
	local slots = {
		tilt * CFrame.new(6.2, -2, 0),
		tilt * CFrame.new(0, 17.5, 0),
		tilt * CFrame.new(-6.4, 1, 0),
		tilt * CFrame.new(0, -9.5, 0),
	}
	for i = 1, 4 do
		local pm = piece(i)
		for _, d in pm:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d:SetAttribute("BaseT", d.Transparency)
			elseif d:IsA("WeldConstraint") then
				d:Destroy()
			end
		end
		pm:PivotTo(slots[i])
		pm.Parent = ship
	end
	return ship
end

function Visuals.buildTemplates(folder: Instance)
	local list: { Model } = {
		chaser("chaser", 1),
		tank("tank", 1),
		ranged("ranged", 1),
		kamikaze("kamikaze", 1),
		boss("elite1", "chaser", 2.2),
		boss("elite2", "tank", 1.5),
		boss("elite3", "ranged", 2.0),
		boss("boss1", "chaser", 3.2),
		boss("boss2", "tank", 2.2),
		boss("boss3", "ranged", 3.0),
		boss("final", "final", 2.6),
		gem(),
		chest(),
		shot("shot", C.cyan, Vector3.new(0.5, 0.5, 3.2)),
		shot("eshot", C.magenta, Vector3.new(2.4, 2.4, 2.4), BALL),
		drone(),
		piece(1),
		piece(2),
		piece(3),
		piece(4),
	}
	for _, m in list do
		m.Parent = folder
	end
end

return Visuals
