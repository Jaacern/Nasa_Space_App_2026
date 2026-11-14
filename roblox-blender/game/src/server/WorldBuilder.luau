--!strict
-- Construye la arena, la iluminacion base, la nave y las plantillas al iniciar el servidor.
-- Asi el lugar se reconstruye entero desde el codigo del repositorio.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Balance)
local Visuals = require(ReplicatedStorage.Shared.Visuals)

local WorldBuilder = {}

WorldBuilder.SpawnPosition = Vector3.new(0, 4, 34)

local function fx<T>(className: string, name: string, parent: Instance): T
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return (inst :: any) :: T
end

function WorldBuilder.build()
	for _, name in { "Baseplate", "Arena", "SpawnLocation" } do
		local old = Workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local oldT = ReplicatedStorage:FindFirstChild("Templates")
	if oldT then
		oldT:Destroy()
	end

	Workspace.Gravity = Balance.World.Gravity
	local R = Balance.Sim.ArenaRadius
	local arena = Instance.new("Folder")
	arena.Name = "Arena"

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Shape = Enum.PartType.Cylinder
	ground.Size = Vector3.new(8, (R + 60) * 2, (R + 60) * 2)
	ground.CFrame = CFrame.new(0, -4, 0) * CFrame.Angles(0, 0, math.rad(90))
	ground.Anchored = true
	ground.Material = Enum.Material.Sand
	ground.Color = Color3.fromRGB(150, 85, 55)
	ground.Parent = arena

	local rng = Random.new(2026)
	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = arena
	local segs = 48
	local segLen = 2 * math.pi * (R + 2) / segs + 2
	for i = 1, segs do
		local a = i / segs * math.pi * 2
		local w = Instance.new("Part")
		w.Anchored = true
		w.Transparency = 1
		w.CanQuery = false
		w.Size = Vector3.new(segLen, 60, 4)
		w.CFrame = CFrame.new(math.cos(a) * (R + 2), 26, math.sin(a) * (R + 2)) * CFrame.Angles(0, -a + math.pi / 2, 0)
		w.Parent = walls
	end

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = arena
	-- Crateres planos (no bloquean a nadie).
	for _ = 1, 46 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(28, R - 10)
		local size = rng:NextNumber(8, 26)
		local c = Instance.new("Part")
		c.Name = "Crater"
		c.Shape = Enum.PartType.Cylinder
		c.Anchored = true
		c.CanCollide = false
		c.CanQuery = false
		c.CanTouch = false
		c.CastShadow = false
		c.Material = Enum.Material.Slate
		c.Color = Color3.fromRGB(95, 55, 40)
		c.Transparency = 0.25
		c.Size = Vector3.new(0.2, size, size)
		c.CFrame = CFrame.new(math.cos(a) * d, 0.06, math.sin(a) * d) * CFrame.Angles(0, 0, math.rad(90))
		c.Parent = decor
	end
	-- Rocas bajas decorativas.
	for _ = 1, 70 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(24, R - 6)
		local s = rng:NextNumber(1.2, 3.4)
		local rock = Instance.new("Part")
		rock.Name = "Rock"
		rock.Anchored = true
		rock.CanCollide = false
		rock.CanQuery = false
		rock.CanTouch = false
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(110, 66, 48)
		rock.Size = Vector3.new(s * 1.4, s * 0.7, s)
		rock.CFrame = CFrame.new(math.cos(a) * d, s * 0.2, math.sin(a) * d) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3))
		rock.Parent = decor
	end
	-- Sierra exterior para dar horizonte.
	for i = 1, 26 do
		local a = i / 26 * math.pi * 2 + rng:NextNumber(-0.05, 0.05)
		local d = R + rng:NextNumber(22, 44)
		local h = rng:NextNumber(30, 80)
		local m = Instance.new("Part")
		m.Name = "Ridge"
		m.Anchored = true
		m.Material = Enum.Material.Slate
		m.Color = Color3.fromRGB(96, 56, 44)
		m.Size = Vector3.new(rng:NextNumber(50, 80), h, rng:NextNumber(30, 50))
		m.CFrame = CFrame.new(math.cos(a) * d, h / 2 - 8, math.sin(a) * d) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), -a, rng:NextNumber(-0.2, 0.2))
		m.Parent = decor
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(WorldBuilder.SpawnPosition.X, 0.5, WorldBuilder.SpawnPosition.Z)
	spawn.Parent = arena

	local ship = Visuals.makeShip()
	ship.Parent = arena
	arena.Parent = Workspace

	local templates = Instance.new("Folder")
	templates.Name = "Templates"
	Visuals.buildTemplates(templates)
	templates.Parent = ReplicatedStorage

	-- Iluminacion base (bioma 1). El cliente la cambia al pasar de bioma.
	Lighting.ClockTime = 15.2
	Lighting.GeographicLatitude = 20
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(70, 50, 45)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 90, 80)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 100000

	local atm: Atmosphere = fx("Atmosphere", "Atmosphere", Lighting)
	atm.Density = 0.36
	atm.Offset = 0.2
	atm.Color = Color3.fromRGB(214, 150, 110)
	atm.Decay = Color3.fromRGB(150, 80, 50)
	atm.Glare = 0.2
	atm.Haze = 1.6

	local bloom: BloomEffect = fx("BloomEffect", "Bloom", Lighting)
	bloom.Intensity = 0.55
	bloom.Size = 28
	bloom.Threshold = 1.1

	local cc: ColorCorrectionEffect = fx("ColorCorrectionEffect", "ColorCorrection", Lighting)
	cc.Contrast = 0.12
	cc.Saturation = 0.1
	cc.TintColor = Color3.fromRGB(255, 240, 228)

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky.StarCount = 3000
		sky.CelestialBodiesShown = true
	end
end

-- Traje de astronauta provisional sobre el avatar: mochila, visor y anillo cian.
function WorldBuilder.dress(character: Model)
	local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	local head = character:FindFirstChild("Head") :: BasePart?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not torso or not head or not root then
		return
	end
	local C = Visuals.Colors
	local function attach(to: BasePart, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?, transparency: number?)
		local p = Instance.new("Part")
		p.Name = "Suit"
		p.Size = size
		p.Color = color
		p.Material = material
		if shape then
			p.Shape = shape
		end
		p.Transparency = transparency or 0
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = to.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = to
		w.Part1 = p
		w.Parent = p
		p.Parent = character
	end
	attach(torso, Vector3.new(1.7, 2.0, 0.9), CFrame.new(0, 0.1, 0.9), C.white, Enum.Material.SmoothPlastic)
	attach(torso, Vector3.new(1.2, 0.3, 0.2), CFrame.new(0, 0.7, 1.4), C.cyan, Enum.Material.Neon)
	attach(head, Vector3.new(2.1, 2.1, 2.1), CFrame.new(0, 0.1, 0), C.white, Enum.Material.Glass, Enum.PartType.Ball, 0.55)
	attach(root, Vector3.new(0.15, 4.4, 4.4), CFrame.new(0, -2.9, 0) * CFrame.Angles(0, 0, math.rad(90)), C.cyan, Enum.Material.Neon, Enum.PartType.Cylinder, 0.45)
end

return WorldBuilder
