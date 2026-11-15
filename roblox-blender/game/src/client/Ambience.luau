--!strict
-- Capa visual de ambiente (solo cliente, solo decoración; no afecta al juego):
--   * cráteres con borde levantado, fondo en sombra y eyecta clara (antes eran discos planos);
--   * manchas de regolito y guijarros que rompen el suelo liso y siguen el color de cada bioma;
--   * polvo en suspensión y velos de arena que deriva con el viento alrededor de la cámara;
--   * nubes altas de polvo, profundidad de campo suave y sombras más nítidas.
-- La cantidad de detalle baja con la calidad gráfica ("low" | "med" | "high").

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Ambience = {}

local quality = "high"
local folder: Folder? = nil
local patches: { { p: BasePart, k: number } } = {}
local dustAnchor: Part? = nil
local motes: ParticleEmitter? = nil
local veils: ParticleEmitter? = nil
local dof: DepthOfFieldEffect? = nil
local clouds: Clouds? = nil
local tintT = 0

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

-- Borde de cráter: anillo de bloques bajos e inclinados + fondo oscuro + halo de eyecta.
local function dressCrater(c: BasePart, rng: Random, parent: Instance)
	local d = math.max(c.Size.Y, c.Size.Z)
	local r = d * 0.5
	local center = Vector3.new(c.Position.X, 0, c.Position.Z)
	-- El disco original pasa a ser el fondo en sombra.
	c.Transparency = 0.2
	c.Color = Color3.fromRGB(104, 58, 40)
	c.Material = Enum.Material.Slate
	-- Halo de eyecta, más claro y fino.
	local ej = part({
		Name = "Ejecta", Shape = Enum.PartType.Cylinder, Material = Enum.Material.Sand,
		Color = Color3.fromRGB(196, 128, 86), Transparency = 0.45,
		Size = Vector3.new(0.12, d * 1.55, d * 1.55),
		CFrame = CFrame.new(center + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	ej.Parent = parent
	table.insert(patches, { p = ej, k = 0.16 })
	-- Bloques del borde.
	local n = math.clamp(math.floor(d * 0.9), 10, 22)
	if quality == "low" then
		n = math.floor(n * 0.5)
	end
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local h = rng:NextNumber(0.7, 1.4) * math.clamp(d / 14, 0.7, 1.8)
		local w = (2 * math.pi * r / n) * rng:NextNumber(1.05, 1.35)
		local rim = part({
			Name = "Rim", Material = Enum.Material.Sand,
			Color = Color3.fromRGB(176, 104, 66):Lerp(Color3.fromRGB(150, 86, 56), rng:NextNumber()),
			Size = Vector3.new(w, h, rng:NextNumber(1.2, 2.2) * math.clamp(d / 16, 0.7, 1.5)),
			CastShadow = d > 16 and quality == "high",
		})
		rim.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * r, h * 0.3, math.sin(a) * r))
			* CFrame.Angles(0, -a + math.pi * 0.5, 0)
			* CFrame.Angles(math.rad(rng:NextNumber(14, 26)), 0, 0)
		rim.Parent = parent
		table.insert(patches, { p = rim, k = 0.06 })
	end
end

local function buildDecor()
	if folder then
		folder:Destroy()
	end
	table.clear(patches)
	local arena = Workspace:FindFirstChild("Arena")
	local decor = arena and arena:FindFirstChild("Decor")
	if not arena or not decor then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "Ambience"
	folder = f
	local rng = Random.new(2027)
	for _, c in decor:GetChildren() do
		if c:IsA("BasePart") and c.Name == "Crater" then
			dressCrater(c, rng, f)
		end
	end
	-- Manchas de regolito (más claras y más oscuras) y guijarros.
	local R = 200
	local npatch = if quality == "low" then 24 elseif quality == "med" then 44 else 64
	for _ = 1, npatch do
		local a, dist = rng:NextNumber(0, math.pi * 2), rng:NextNumber(20, R)
		local s = rng:NextNumber(14, 46)
		local k = if rng:NextNumber() < 0.5 then rng:NextNumber(0.07, 0.14) else -rng:NextNumber(0.06, 0.12)
		local p = part({
			Name = "Patch", Shape = Enum.PartType.Cylinder, Material = Enum.Material.Sand,
			Transparency = rng:NextNumber(0.45, 0.65),
			Size = Vector3.new(0.1, s, s * rng:NextNumber(0.5, 1)),
			CFrame = CFrame.new(math.cos(a) * dist, 0.02 + rng:NextNumber(0, 0.02), math.sin(a) * dist)
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0) * CFrame.Angles(0, 0, math.rad(90)),
		})
		p.Parent = f
		table.insert(patches, { p = p, k = k })
	end
	local npeb = if quality == "low" then 80 elseif quality == "med" then 160 else 260
	for _ = 1, npeb do
		local a, dist = rng:NextNumber(0, math.pi * 2), rng:NextNumber(16, R)
		local s = rng:NextNumber(0.25, 0.8)
		local p = part({
			Name = "Pebble", Material = Enum.Material.Slate,
			Size = Vector3.new(s * rng:NextNumber(1, 1.8), s * 0.6, s),
			CFrame = CFrame.new(math.cos(a) * dist, s * 0.15, math.sin(a) * dist)
				* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4)),
		})
		p.Parent = f
		table.insert(patches, { p = p, k = -0.22 })
	end
	f.Parent = arena
end

-- El detalle del suelo sigue el color del suelo de cada bioma.
local function retint()
	local arena = Workspace:FindFirstChild("Arena")
	local ground = arena and arena:FindFirstChild("Ground")
	if not ground or not ground:IsA("BasePart") then
		return
	end
	local g = ground.Color
	for _, e in patches do
		if e.p.Name ~= "Rim" then
			e.p.Color = if e.k >= 0 then g:Lerp(Color3.new(1, 0.92, 0.82), e.k) else g:Lerp(Color3.new(0, 0, 0), -e.k)
		else
			e.p.Color = g:Lerp(Color3.new(1, 0.9, 0.8), e.k + 0.04)
		end
	end
end

local function buildAir()
	if dustAnchor then
		dustAnchor:Destroy()
	end
	local a = part({ Name = "AmbientDust", Transparency = 1, Size = Vector3.new(110, 26, 110) })
	-- Motas finas suspendidas.
	local m = Instance.new("ParticleEmitter")
	m.Name = "Motes"
	m.Shape = Enum.ParticleEmitterShape.Box
	m.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	m.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	m.Color = ColorSequence.new(Color3.fromRGB(255, 214, 170), Color3.fromRGB(230, 160, 110))
	m.LightEmission = 0.15
	m.LightInfluence = 0.6
	m.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0.14), NumberSequenceKeypoint.new(1, 0.04) })
	m.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.45), NumberSequenceKeypoint.new(0.8, 0.5), NumberSequenceKeypoint.new(1, 1) })
	m.Lifetime = NumberRange.new(5, 9)
	m.Speed = NumberRange.new(0.4, 1.4)
	m.SpreadAngle = Vector2.new(180, 180)
	m.Acceleration = Vector3.new(1.6, 0.1, 0.6)
	m.RotSpeed = NumberRange.new(-30, 30)
	m.Parent = a
	-- Velos de polvo a ras de suelo, grandes y muy tenues, arrastrados por el viento.
	local v = Instance.new("ParticleEmitter")
	v.Name = "Veils"
	v.Shape = Enum.ParticleEmitterShape.Box
	v.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	v.Texture = "rbxasset://textures/particles/smoke_main.dds"
	v.Color = ColorSequence.new(Color3.fromRGB(228, 160, 112))
	v.LightEmission = 0
	v.LightInfluence = 1
	v.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 14) })
	v.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.86), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 1) })
	v.Lifetime = NumberRange.new(7, 11)
	v.Speed = NumberRange.new(3, 6)
	v.EmissionDirection = Enum.NormalId.Right
	v.SpreadAngle = Vector2.new(12, 4)
	v.Acceleration = Vector3.new(0.8, 0.15, 0.3)
	v.RotSpeed = NumberRange.new(-8, 8)
	v.Rotation = NumberRange.new(0, 360)
	v.Parent = a
	a.Parent = Workspace
	dustAnchor, motes, veils = a, m, v
end

local function applyQuality()
	if motes then
		motes.Rate = if quality == "low" then 6 elseif quality == "med" then 14 else 26
	end
	if veils then
		veils.Rate = if quality == "low" then 0 elseif quality == "med" then 0.6 else 1.2
		veils.Enabled = quality ~= "low"
	end
	if dof then
		dof.Enabled = quality == "high"
	end
	if clouds then
		clouds.Enabled = quality ~= "low"
	end
	pcall(function()
		Lighting.ShadowSoftness = if quality == "high" then 0.12 else 0.3
	end)
end

function Ambience.setQuality(tier: string)
	if tier ~= quality then
		quality = tier
		buildDecor()
		retint()
	end
	applyQuality()
end

function Ambience.init()
	-- Profundidad de campo suave: el horizonte se ablanda y el combate queda nítido.
	local old = Lighting:FindFirstChild("AmbienceDOF")
	if old then
		old:Destroy()
	end
	local d = Instance.new("DepthOfFieldEffect")
	d.Name = "AmbienceDOF"
	d.FarIntensity = 0.14
	d.NearIntensity = 0
	d.FocusDistance = 70
	d.InFocusRadius = 70
	d.Parent = Lighting
	dof = d
	-- Nubes altas de polvo (tenues, cálidas).
	local terrain = Workspace.Terrain
	local c = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	c.Cover = 0.38
	c.Density = 0.22
	c.Color = Color3.fromRGB(255, 214, 178)
	c.Parent = terrain
	clouds = c
	-- Sol más pequeño: desde Marte se ve a unos 2/3 de su tamaño en la Tierra.
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky.SunAngularSize = 14
	end
	task.spawn(function()
		local arena = Workspace:WaitForChild("Arena", 20)
		if arena then
			arena:WaitForChild("Decor", 20)
			buildDecor()
			retint()
		end
	end)
	buildAir()
	applyQuality()
end

function Ambience.update(dt: number)
	local cam = Workspace.CurrentCamera
	if dustAnchor and cam then
		local p = cam.CFrame.Position + cam.CFrame.LookVector * 28
		dustAnchor.CFrame = CFrame.new(p.X, 10, p.Z)
	end
	tintT -= dt
	if tintT <= 0 then
		tintT = 0.25
		retint()
	end
end

return Ambience
