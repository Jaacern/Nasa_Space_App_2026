--!strict
-- Escenario del cliente: nave (con piezas fantasma/recuperadas), decorado y traje del astronauta.
-- Dos modos para la nave: heredado (Arena.Ship del servidor) y con mallas (ShipVisual). Cada elemento
-- degrada por separado: si falta una malla se usa el modelo basico del servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Fx = require(script.Parent.Fx)

local Scenery = {}

local GHOST_T = 0.85
local LIFT = 260
local SHIP_FOCUS = Vector3.new(0, 12, 0)

local meshes: { [string]: Model } = {}
local ready = false
local templates: Instance? = nil
local shipVisual: Model? = nil
local pieceVisuals: { [number]: Model } = {}
local pieceSlots: { [number]: CFrame } = {}
local recovered: { [number]: boolean } = {}
local decorFolder: Folder? = nil
local decorToken = 0
local hullHidden = false
local hullSrc: Model? = nil
local lifted: { { m: Model, start: CFrame } }? = nil
local liftTween: Tween? = nil
local liftValue: NumberValue? = nil
local sizeCache: { [string]: Vector3 } = {}

-- Montaje de las piezas en la nave (studs, ejes Roblox, relativas al origen de Ship).
local MOUNTS: { [number]: CFrame } = {
	[1] = CFrame.new(0, 8.5, 6.6),
	[2] = CFrame.new(0, 23.6, 0),
	[3] = CFrame.new(-6.3, 12.0, 0),
	[4] = CFrame.new(0, 3.0, 0),
}

local function toMaterial(name: any): Enum.Material
	local ok, mat = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and mat then
		return mat
	end
	return Enum.Material.SmoothPlastic
end

local function serverShip(): Model?
	local arena = Workspace:FindFirstChild("Arena")
	return arena and arena:FindFirstChild("Ship") :: Model?
end

local function serverPiece(i: number): Model?
	local ship = serverShip()
	return ship and ship:FindFirstChild("Piece" .. i) :: Model?
end

-- ------------------------------------------------------------ Modo heredado (modelo del servidor)
local function legacyReset(i: number)
	local pm = serverPiece(i)
	if pm then
		for _, d in pm:GetDescendants() do
			if d:IsA("BasePart") then
				d.Transparency = if d.Name == "Root" then 1 else 0.88
				d.Material = if d.Name == "Root" then d.Material else Enum.Material.ForceField
				d.CanCollide = false
			end
		end
	end
end

local function legacyShow(i: number)
	local pm = serverPiece(i)
	if not pm then
		return
	end
	local tpl = if templates then templates:FindFirstChild("Piece" .. i) else nil
	local mats: { [string]: Enum.Material } = {}
	if tpl then
		for idx, d in tpl:GetChildren() do
			if d:IsA("BasePart") then
				mats[tostring(idx)] = d.Material
			end
		end
	end
	for idx, d in pm:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			d.Material = mats[tostring(idx)] or Enum.Material.Metal
			d.Transparency = (d:GetAttribute("BaseT") :: number?) or 0
		end
	end
end

local function hideLegacyPiece(i: number)
	local pm = serverPiece(i)
	if pm then
		for _, d in pm:GetDescendants() do
			if d:IsA("BasePart") then
				d.Transparency = 1
				d.CanCollide = false
			end
		end
	end
end

-- ------------------------------------------------------------ Modo con mallas
local function applyMeshPiece(i: number)
	local v = pieceVisuals[i]
	if not v then
		return
	end
	local rec = recovered[i] == true
	for _, d in v:GetDescendants() do
		if d:IsA("MeshPart") then
			if rec then
				d.Transparency = (d:GetAttribute("BaseT") :: number?) or 0
				d.Material = toMaterial(d:GetAttribute("BaseM"))
			else
				d.Transparency = GHOST_T
				d.Material = Enum.Material.ForceField
			end
		end
	end
end

-- Oculta (solo en el cliente) las piezas visibles de la nave del servidor; solo ShipCollider mantiene colision.
local function hideHull()
	local ship = serverShip()
	if not ship or hullHidden then
		return
	end
	hullHidden = true
	for _, d in ship:GetChildren() do
		if d:IsA("BasePart") then
			d.Transparency = 1
			if d.Name ~= "ShipCollider" then
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
	end
end

local function ensureVisual(): Model
	local sv = shipVisual
	if sv and sv.Parent then
		return sv
	end
	local m = Instance.new("Model")
	m.Name = "ShipVisual"
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.one
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.identity
	root.Parent = m
	m.PrimaryPart = root
	m.Parent = Workspace
	shipVisual = m
	return m
end

local function refreshShip()
	if not ready then
		return
	end
	local anyMesh = meshes.Ship ~= nil
	for i = 1, 4 do
		anyMesh = anyMesh or meshes["Piece" .. i] ~= nil
	end
	if not anyMesh then
		return
	end
	local sv = ensureVisual()
	if meshes.Ship then
		hideHull()
		local old = sv:FindFirstChild("Hull")
		if not old or hullSrc ~= meshes.Ship then
			if old then
				old:Destroy()
			end
			hullSrc = meshes.Ship
			local hull = meshes.Ship:Clone()
			hull.Name = "Hull"
			hull:PivotTo(CFrame.identity)
			hull.Parent = sv
		end
	end
	for i = 1, 4 do
		local src = meshes["Piece" .. i]
		if src and not pieceVisuals[i] then
			-- posicion de montaje: catalogo o ranura del servidor (se guarda la primera vez)
			if not pieceSlots[i] then
				local pm = serverPiece(i)
				pieceSlots[i] = MOUNTS[i] or (if pm then pm:GetPivot() else CFrame.new(0, 12, 0))
			end
			local c = src:Clone()
			c.Name = "Piece" .. i
			c:PivotTo(pieceSlots[i])
			c.Parent = sv
			pieceVisuals[i] = c
			hideLegacyPiece(i)
			applyMeshPiece(i)
		end
	end
end

-- ------------------------------------------------------------ API de la nave
function Scenery.resetShip()
	if lifted then
		-- si se reinicia a mitad de despegue, vuelve todo a su sitio
		for _, e in lifted do
			e.m:PivotTo(e.start)
		end
		lifted = nil
		if liftTween then
			liftTween:Cancel()
		end
	end
	table.clear(recovered)
	for i = 1, 4 do
		if pieceVisuals[i] then
			applyMeshPiece(i)
		else
			legacyReset(i)
		end
	end
end

function Scenery.showPiece(i: number)
	recovered[i] = true
	local pos: Vector3
	if pieceVisuals[i] then
		applyMeshPiece(i)
		pos = pieceVisuals[i]:GetPivot().Position
	else
		legacyShow(i)
		local pm = serverPiece(i)
		pos = if pm then pm:GetPivot().Position else SHIP_FOCUS
	end
	Fx.burst("gold", pos, 40)
end

function Scenery.shipPosition(): Vector3
	return SHIP_FOCUS
end

function Scenery.shipPivot(): Vector3
	local sv = shipVisual
	if sv and sv.Parent and meshes.Ship then
		return sv:GetPivot().Position + SHIP_FOCUS
	end
	local ship = serverShip()
	return if ship then ship:GetPivot().Position else SHIP_FOCUS
end

-- Despegue de la victoria: solo visual, en el cliente. Sube 260 studs en 5 s y vuelve a su sitio.
function Scenery.liftoff()
	if lifted then
		return
	end
	local movers: { { m: Model, start: CFrame } } = {}
	local sv = shipVisual
	if sv and sv.Parent then
		table.insert(movers, { m = sv, start = sv:GetPivot() })
	end
	local ship = serverShip()
	if ship then
		if not meshes.Ship then
			table.insert(movers, { m = ship, start = ship:GetPivot() })
		else
			-- con malla de nave: solo se mueven las piezas que siguen en modo heredado
			for i = 1, 4 do
				local pm = serverPiece(i)
				if pm and not pieceVisuals[i] then
					table.insert(movers, { m = pm, start = pm:GetPivot() })
				end
			end
		end
	end
	if #movers == 0 then
		return
	end
	lifted = movers
	local v = liftValue
	if not v then
		v = Instance.new("NumberValue")
		liftValue = v
		v.Changed:Connect(function(y)
			local l = lifted
			if not l then
				return
			end
			for _, e in l do
				e.m:PivotTo(e.start + Vector3.new(0, y, 0))
			end
			Fx.burst("boom", movers[1].start.Position + Vector3.new(0, y - 10, 0), 6)
		end)
	end
	v.Value = 0
	local tw = TweenService:Create(v, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = LIFT })
	liftTween = tw
	tw.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed then
			return
		end
		task.delay(1.5, function()
			if lifted == movers then
				for _, e in movers do
					e.m:PivotTo(e.start)
				end
				lifted = nil
			end
		end)
	end)
	tw:Play()
end

-- ------------------------------------------------------------ Decorado
local function extents(name: string): Vector3
	local s = sizeCache[name]
	if not s then
		s = meshes[name]:GetExtentsSize()
		sizeCache[name] = s
	end
	return s
end

local function sortedByPos(list: { BasePart }): { BasePart }
	table.sort(list, function(a, b)
		local pa, pb = a.Position, b.Position
		if math.abs(pa.X - pb.X) > 1e-3 then
			return pa.X < pb.X
		end
		return pa.Z < pb.Z
	end)
	return list
end

local function runDecor()
	decorToken += 1
	local token = decorToken
	local arena = Workspace:FindFirstChild("Arena")
	local decor = arena and arena:FindFirstChild("Decor")
	if not decor then
		return
	end
	local rockVars, ridgeVars = {}, {}
	for _, n in { "RockA", "RockB", "RockC" } do
		if meshes[n] then
			table.insert(rockVars, n)
		end
	end
	for _, n in { "RidgeA", "RidgeB" } do
		if meshes[n] then
			table.insert(ridgeVars, n)
		end
	end
	if #rockVars == 0 and #ridgeVars == 0 then
		return
	end
	if decorFolder then
		decorFolder:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "ClientDecor"
	folder.Parent = Workspace
	decorFolder = folder

	local rocks: { BasePart }, ridges: { BasePart } = {}, {}
	for _, d in decor:GetChildren() do
		if d:IsA("BasePart") then
			if d.Name == "Rock" and #rockVars > 0 then
				table.insert(rocks, d)
			elseif d.Name == "Ridge" and #ridgeVars > 0 then
				table.insert(ridges, d)
			end
		end
	end
	sortedByPos(rocks)
	sortedByPos(ridges)

	local n = 0
	local function place(orig: BasePart, name: string, scale: number, baseY: number)
		local c = meshes[name]:Clone()
		local _, yaw = orig.CFrame:ToOrientation()
		c.Parent = folder
		c:ScaleTo(math.max(0.05, scale))
		c:PivotTo(CFrame.new(orig.Position.X, baseY, orig.Position.Z) * CFrame.Angles(0, yaw, 0))
		n += 1
		if n % 4 == 0 then
			task.wait()
		end
	end
	for i, r in rocks do
		if token ~= decorToken then
			return
		end
		local name = rockVars[(i - 1) % #rockVars + 1]
		local e = extents(name)
		place(r, name, r.Size.X / math.max(0.1, math.max(e.X, e.Z)), 0)
		r.Transparency = 1
	end
	for i, r in ridges do
		if token ~= decorToken then
			return
		end
		local name = ridgeVars[(i - 1) % #ridgeVars + 1]
		local e = extents(name)
		local k = (r.Size.X / math.max(0.1, e.X) + r.Size.Y / math.max(0.1, e.Y)) / 2
		-- la pieza original queda invisible pero presente (la camara hace raycast contra ella)
		place(r, name, k, r.Position.Y - r.Size.Y / 2)
		r.Transparency = 1
	end
end

local decorPending = false
local function scheduleDecor()
	if decorPending then
		return
	end
	decorPending = true
	task.delay(0.6, function()
		decorPending = false
		if ready then
			runDecor()
		end
	end)
end

-- ------------------------------------------------------------ Astronauta
local function hasRing(char: Model): boolean
	for _, d in char:GetChildren() do
		if d:IsA("Part") and d.Name == "Suit" and d.Shape == Enum.PartType.Cylinder then
			return true
		end
	end
	return false
end

local function attachMesh(char: Model, name: string, to: BasePart, offset: CFrame, scale: number)
	local old = char:FindFirstChild("Suit" .. name)
	if old then
		old:Destroy()
	end
	local m = meshes[name]:Clone()
	m.Name = "Suit" .. name
	local root = m.PrimaryPart :: Part
	root.Anchored = false
	root.Massless = true
	m:ScaleTo(scale)
	m:PivotTo(to.CFrame * offset)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = root
	w.Parent = root
	m.Parent = char
end

local function charScales(char: Model): (number, number)
	local head = char:FindFirstChild("Head") :: BasePart?
	local torso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
	local torsoScale = if torso then math.clamp(torso.Size.Y / 1.65, 0.32, 1.6) else 1
	local headScale = if head then math.clamp(math.max(head.Size.Y, head.Size.Z) / 1.18, 0.32, 1.6) else torsoScale
	return torsoScale, headScale
end

local dressing: { [Model]: boolean } = {}
local applyGear: () -> () -- se define mas abajo, en Equipo visible
local function dress(char: Model)
	if not (meshes.Helmet and meshes.Backpack) or dressing[char] then
		return
	end
	dressing[char] = true
	task.spawn(function()
		local head = char:WaitForChild("Head", 10) :: BasePart?
		local t0 = os.clock()
		local torso: BasePart? = nil
		while os.clock() - t0 < 8 do
			torso = (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
			if torso and hasRing(char) then
				break
			end
			task.wait(0.2)
		end
		if head and torso and char.Parent and meshes.Helmet and meshes.Backpack then
			for _, d in char:GetChildren() do
				-- oculta mochila, luz y visor del servidor; el anillo de los pies (cilindro) se queda
				if d:IsA("Part") and d.Name == "Suit" and d.Shape ~= Enum.PartType.Cylinder then
					d.Transparency = 1
				end
			end
			local torsoScale, headScale = charScales(char)
			local backZ = torso.Size.Z * 0.52 + 0.38 * torsoScale
			attachMesh(char, "Helmet", head, CFrame.new(0, 0.08 * headScale, 0), headScale)
			attachMesh(char, "Backpack", torso, CFrame.new(0, 0.08 * torsoScale, backZ), torsoScale)
			applyGear()
		end
		dressing[char] = nil
	end)
end

local function redress()
	local char = Players.LocalPlayer.Character
	if char then
		dress(char)
	end
end

-- ------------------------------------------------------------ Rover (hito del paisaje)
-- Rover Perseverance como hito visual. Va justo fuera del borde jugable (ArenaRadius = 210)
-- porque es solo decorado y no tiene colision en la simulacion.
local ROVER_POS = Vector3.new(150, 0, 172)
local ROVER_YAW = math.rad(215)
local ROVER_SCALE = 1.6
local roverVisual: Model? = nil

local function refreshRover()
	if roverVisual then
		roverVisual:Destroy()
		roverVisual = nil
	end
	local src = meshes.Rover
	if not src then
		return
	end
	local m = src:Clone()
	m.Name = "RoverVisual"
	m.Parent = Workspace
	m:ScaleTo(ROVER_SCALE)
	m:PivotTo(CFrame.new(ROVER_POS) * CFrame.Angles(0, ROVER_YAW, 0))
	roverVisual = m
end

-- ------------------------------------------------------------ Lunas (fondo)
-- Fobos y Deimos, las dos lunas de Marte, como rocas facetadas lejanas. Fobos se ve mayor que Deimos.
local moons: Folder? = nil

local function refreshMoons()
	if moons or not meshes.RockB or not meshes.RockC then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Moons"
	folder.Parent = Workspace
	moons = folder
	local function moon(src: Model, name: string, size: number, pos: Vector3, rot: CFrame)
		local m = src:Clone()
		m.Name = name
		m.Parent = folder
		local e = m:GetExtentsSize()
		m:ScaleTo(size / math.max(0.1, math.max(e.X, e.Y, e.Z)))
		m:PivotTo(CFrame.new(pos) * rot)
	end
	moon(meshes.RockB, "Fobos", 46, Vector3.new(-520, 560, -760), CFrame.Angles(0.5, 0.8, 0.2))
	moon(meshes.RockC, "Deimos", 22, Vector3.new(560, 640, -820), CFrame.Angles(1.1, 0.3, 0.7))
end

-- ------------------------------------------------------------ Insignia del menu
local BalanceS = require(ReplicatedStorage.Shared.Balance)
local menuOn = true
local insignia: Model? = nil
local insigniaYaw = 0
local INSIGNIA_HEIGHT = 29
local INSIGNIA_SPIN = 0.3 -- rad/s: giro lento y continuo

local function refreshInsignia()
	if insignia then
		insignia:Destroy()
		insignia = nil
	end
	if not (ready and menuOn and meshes.Insignia and (BalanceS :: any).Branding.NasaInsignia) then
		return
	end
	local m = meshes.Insignia:Clone()
	m.Name = "InsigniaVisual"
	m.Parent = Workspace
	m:ScaleTo(1.5)
	insignia = m
end

function Scenery.setMenu(on: boolean)
	if menuOn ~= on then
		menuOn = on
		refreshInsignia()
	end
end

-- ------------------------------------------------------------ Zonas del cráter + Evento Agujero Negro (NASA)
local zoneFolder: Folder? = nil

local function buildZones()
	if zoneFolder then
		zoneFolder:Destroy()
		zoneFolder = nil
	end
	local arena = Workspace:FindFirstChild("Arena")
	if not arena then
		return
	end
	local zf = Instance.new("Folder")
	zf.Name = "ArenaZones"
	zf.Parent = arena
	zoneFolder = zf

	-- Anillo central de Zona 1 (Crater del Modulo, R = 34)
	local zoneR = (BalanceS :: any).World and (BalanceS :: any).World.Zone1Radius or 34
	local maxR = (BalanceS :: any).Sim.ArenaRadius - 6
	local segs = 28
	for i = 1, segs do
		local a = (i - 0.5) / segs * math.pi * 2
		local arc = (2 * math.pi * zoneR) / segs * 0.65
		local p = Instance.new("Part")
		p.Name = "Zone1Ring"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(0, 210, 255)
		p.Transparency = 0.55
		p.Size = Vector3.new(arc, 0.14, 0.42)
		p.CFrame = CFrame.new(math.cos(a) * zoneR, 0.08, math.sin(a) * zoneR) * CFrame.Angles(0, -a + math.pi * 0.5, 0)
		p.Parent = zf
	end

	-- Fronteras diagonales |x| == |z| entre las 4 zonas exteriores
	local zColors = {
		Color3.fromRGB(255, 130, 60),
		Color3.fromRGB(255, 200, 40),
		Color3.fromRGB(255, 75, 70),
		Color3.fromRGB(90, 225, 255),
	}
	for i = 1, 4 do
		local ang = math.rad(45 + (i - 1) * 90)
		local len = maxR - zoneR
		local midR = (zoneR + maxR) * 0.5
		-- Frontera discontinua (marcas de topografía), menos invasiva que una línea continua.
		local _ = midR
		local dash, gap = 3.2, 3.6
		local n = math.floor(len / (dash + gap))
		for k = 0, n - 1 do
			local rr = zoneR + 2 + k * (dash + gap) + dash * 0.5
			local strip = Instance.new("Part")
			strip.Name = "ZoneLine" .. i
			strip.Anchored = true
			strip.CanCollide = false
			strip.CanQuery = false
			strip.CanTouch = false
			strip.CastShadow = false
			strip.Material = Enum.Material.Neon
			strip.Color = Color3.fromRGB(255, 196, 150)
			strip.Transparency = 0.6
			strip.Size = Vector3.new(0.38, 0.1, dash)
			strip.CFrame = CFrame.new(math.cos(ang) * rr, 0.07, math.sin(ang) * rr) * CFrame.Angles(0, -ang + math.pi * 0.5, 0)
			strip.Parent = zf
		end

		-- Baliza de sector en la bisectriz (0, 90, 180, 270 deg)
		local bAng = math.rad((i - 1) * 90 - 90)
		local bx, bz = math.cos(bAng) * (maxR - 10), math.sin(bAng) * (maxR - 10)
		local beacon = Instance.new("Part")
		beacon.Name = "ZoneBeacon" .. i
		beacon.Shape = Enum.PartType.Cylinder
		beacon.Anchored = true
		beacon.CanCollide = false
		beacon.CanQuery = false
		beacon.CanTouch = false
		beacon.CastShadow = false
		beacon.Material = Enum.Material.Neon
		beacon.Color = zColors[i]
		beacon.Transparency = 0.55
		beacon.Size = Vector3.new(18, 0.85, 0.85)
		beacon.CFrame = CFrame.new(bx, 9, bz) * CFrame.Angles(0, 0, math.rad(90))
		beacon.Parent = zf
	end
end

local NasaDataS = require(ReplicatedStorage.Shared.NasaData)
local bhModel: Model? = nil
local bhCore: Part? = nil
local bhInner: Part? = nil
local bhOuter: Part? = nil
local bhJetN: Part? = nil
local bhJetS: Part? = nil
local bhLeft = 0
local bhDur = 15
local bhPhase = 0
local bhTilt = CFrame.Angles(math.rad(22), math.rad(-18), math.rad(14))
local BH_POS = Vector3.new(-220, 185, -450)

function Scenery.clearBlackHole()
	bhLeft = 0
	if bhModel then
		bhModel:Destroy()
		bhModel = nil
	end
	bhCore, bhInner, bhOuter, bhJetN, bhJetS = nil, nil, nil, nil, nil
end

function Scenery.triggerBlackHole(bhIdx: number, duration: number)
	Scenery.clearBlackHole()
	local def = NasaDataS.blackHoleForEvent(bhIdx)
	local tint = if def and def.tint then def.tint else nil
	local diskCol = if tint then Color3.fromRGB(tint[1], tint[2], tint[3]) else Color3.fromRGB(255, 160, 60)
	local jetCol = if tint
		then Color3.fromRGB(math.min(255, math.floor(tint[1] * 0.65 + 90)), math.min(255, math.floor(tint[2] * 0.65 + 100)), 255)
		else Color3.fromRGB(165, 110, 255)
	bhDur = math.max(4, duration or 15)
	bhLeft = bhDur
	bhPhase = 0

	local m = Instance.new("Model")
	m.Name = "BlackHoleEvent"
	local core = Instance.new("Part")
	core.Name = "EventHorizon"
	core.Shape = Enum.PartType.Ball
	core.Material = Enum.Material.SmoothPlastic
	core.Color = Color3.new(0, 0, 0)
	core.Reflectance = 0
	core.CastShadow = false
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.Size = Vector3.new(78, 78, 78)
	core.CFrame = CFrame.new(BH_POS)
	core.Parent = m

	local inner = Instance.new("Part")
	inner.Name = "AccretionInner"
	inner.Shape = Enum.PartType.Cylinder
	inner.Material = Enum.Material.Neon
	inner.Color = diskCol
	inner.Transparency = 0.2
	inner.CastShadow = false
	inner.Anchored = true
	inner.CanCollide = false
	inner.CanQuery = false
	inner.CanTouch = false
	inner.Size = Vector3.new(2.5, 165, 165)
	inner.Parent = m

	local outer = Instance.new("Part")
	outer.Name = "AccretionOuter"
	outer.Shape = Enum.PartType.Cylinder
	outer.Material = Enum.Material.Neon
	outer.Color = jetCol
	outer.Transparency = 0.5
	outer.CastShadow = false
	outer.Anchored = true
	outer.CanCollide = false
	outer.CanQuery = false
	outer.CanTouch = false
	outer.Size = Vector3.new(1.6, 235, 235)
	outer.Parent = m

	local function jet(name: string): Part
		local j = Instance.new("Part")
		j.Name = name
		j.Shape = Enum.PartType.Cylinder
		j.Material = Enum.Material.Neon
		j.Color = jetCol
		j.Transparency = 0.45
		j.CastShadow = false
		j.Anchored = true
		j.CanCollide = false
		j.CanQuery = false
		j.CanTouch = false
		j.Size = Vector3.new(190, 12, 12)
		j.Parent = m
		return j
	end

	bhCore = core
	bhInner = inner
	bhOuter = outer
	bhJetN = jet("JetN")
	bhJetS = jet("JetS")
	m.PrimaryPart = core
	m.Parent = Workspace
	bhModel = m
end

function Scenery.update(dt: number)
	local m = insignia
	if m then
		insigniaYaw += dt * INSIGNIA_SPIN
		m:PivotTo(CFrame.new(Scenery.shipPosition() + Vector3.new(0, INSIGNIA_HEIGHT, 0)) * CFrame.Angles(0, insigniaYaw, 0))
	end
	if bhLeft > 0 and bhModel and bhCore and bhInner and bhOuter and bhJetN and bhJetS then
		bhLeft -= dt
		if bhLeft <= 0 then
			Scenery.clearBlackHole()
			return
		end
		bhPhase += dt
		local elapsed = bhDur - bhLeft
		local s = math.min(1, elapsed / 1.4, bhLeft / 1.6)
		local origin = CFrame.new(BH_POS) * bhTilt
		bhCore.Size = Vector3.new(78, 78, 78) * s
		bhCore.CFrame = origin
		bhInner.Size = Vector3.new(2.4, 165 * s, 165 * s)
		bhInner.CFrame = origin * CFrame.Angles(0, bhPhase * 1.6, math.rad(90))
		bhOuter.Size = Vector3.new(1.5, 235 * s, 235 * s)
		bhOuter.CFrame = origin * CFrame.Angles(0, -bhPhase * 0.9, math.rad(90) + 0.08)
		local jetOffset = 95 * s
		bhJetN.Size = Vector3.new(180 * s, 12 * s, 12 * s)
		bhJetN.CFrame = origin * CFrame.new(0, jetOffset, 0) * CFrame.Angles(0, bhPhase * 2.2, math.rad(90))
		bhJetS.Size = Vector3.new(180 * s, 12 * s, 12 * s)
		bhJetS.CFrame = origin * CFrame.new(0, -jetOffset, 0) * CFrame.Angles(0, -bhPhase * 2.2, math.rad(90))
	end
end

-- ------------------------------------------------------------ Equipo visible
-- Cada mejora elegida deja una pieza visible en el traje: el jugador ve como crece su equipo.
local gearState: { [string]: number } = {}
local G_CYAN = Color3.fromRGB(0, 210, 255)
local G_GOLD = Color3.fromRGB(212, 160, 40)
local G_ORANGE = Color3.fromRGB(255, 107, 53)
local G_MAGENTA = Color3.fromRGB(255, 0, 170)
local G_RED = Color3.fromRGB(255, 45, 85)
local G_DARK = Color3.fromRGB(60, 66, 80)
local NEON, METAL = Enum.Material.Neon, Enum.Material.Metal

local function gearPart(char: Model, tag: string, to: BasePart, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?, transparency: number?)
	local p = Instance.new("Part")
	p.Name = "Gear_" .. tag
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = material
	p.Transparency = transparency or 0
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
	p.Parent = char
end

local function bodyPart(char: Model, ...: string): BasePart?
	for _, n in { ... } do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return nil
end

local function scaledOffset(s: number, cf: CFrame): CFrame
	local rot = cf - cf.Position
	return CFrame.new(cf.Position * s) * rot
end

local function buildGear(char: Model, id: string, lvl: number)
	for _, d in char:GetChildren() do
		if d.Name == "Gear_" .. id then
			d:Destroy()
		end
	end
	local torso = bodyPart(char, "UpperTorso", "Torso")
	local arm = bodyPart(char, "RightLowerArm", "Right Arm") or torso
	local head = bodyPart(char, "Head")
	if not torso or not arm then
		return
	end
	local s, headS = charScales(char)
	local armS = math.clamp(arm.Size.Y / 1.05, 0.32, 1.6)
	local n = math.clamp(math.ceil(lvl), 1, 4)
	local ring = CFrame.Angles(0, 0, math.pi / 2)
	local function gp(to: BasePart, sc: number, size: Vector3, off: CFrame, color: Color3, mat: Enum.Material, shape: Enum.PartType?, trans: number?)
		gearPart(char, id, to, size * sc, scaledOffset(sc, off), color, mat, shape, trans)
	end
	if id == "blaster" then
		-- arma base: siempre visible en el antebrazo derecho
		gp(arm, armS, Vector3.new(0.5, 0.5, 1.5), CFrame.new(0, -0.5, -0.55), G_DARK, METAL)
		gp(arm, armS, Vector3.new(0.26, 0.26, 0.5), CFrame.new(0, -0.5, -1.5), G_CYAN, NEON)
	elseif id == "damage" then
		for i = 1, n do
			gp(arm, armS, Vector3.new(0.66, 0.66, 0.12), CFrame.new(0, -0.5, -0.15 - 0.3 * i), G_ORANGE, NEON)
		end
	elseif id == "rate" then
		gp(arm, armS, Vector3.new(0.28, 0.28, 1.1 + 0.15 * n), CFrame.new(0, -0.95, -0.6), G_DARK, METAL)
		gp(arm, armS, Vector3.new(0.16, 0.16, 0.3), CFrame.new(0, -0.95, -1.3 - 0.08 * n), G_GOLD, NEON)
	elseif id == "multishot" then
		for i = 1, n do
			local side = if i % 2 == 1 then 1 else -1
			gp(arm, armS, Vector3.new(0.18, 0.18, 1.3), CFrame.new(side * (0.36 + 0.1 * ((i - 1) // 2)), -0.5, -0.75), G_CYAN, NEON)
		end
	elseif id == "pierce" then
		gp(arm, armS, Vector3.new(0.1, 0.1, 1.0 + 0.35 * n), CFrame.new(0, -0.5, -2.1 - 0.17 * n), G_CYAN, NEON)
	elseif id == "armor" then
		for _, sx in { -1, 1 } do
			gp(torso, s, Vector3.new(0.95, 0.28 + 0.08 * n, 1.1), CFrame.new(sx * 1.3, 0.8, 0), G_GOLD, METAL)
		end
	elseif id == "speed" then
		for _, legName in { { "LeftLowerLeg", "Left Leg" }, { "RightLowerLeg", "Right Leg" } } do
			local leg = bodyPart(char, legName[1], legName[2])
			if leg then
				local legS = math.clamp(leg.Size.Y / 1.15, 0.32, 1.6)
				gp(leg, legS, Vector3.new(0.3 + 0.05 * n, 0.5 + 0.1 * n, 0.3 + 0.05 * n), CFrame.new(0, -0.1, 0.5), G_ORANGE, NEON)
			end
		end
	elseif id == "magnet" then
		local d = 3 + 0.5 * n
		gp(torso, s, Vector3.new(0.1, d, d), CFrame.new(0, -0.9, 0) * ring, G_CYAN, NEON, Enum.PartType.Cylinder, 0.6)
	elseif id == "cooldown" then
		for _, sx in { -1, 1 } do
			gp(torso, s, Vector3.new(0.12, 0.9 + 0.2 * n, 0.5), CFrame.new(sx * 0.6, 1.0, 1.35), G_CYAN, NEON)
		end
	elseif id == "crit" and head then
		gp(head, headS, Vector3.new(0.3, 0.3, 0.45 + 0.08 * n), CFrame.new(0.6, 0.25, -0.6), G_RED, NEON)
	elseif id == "aura" then
		local d = 5 + 0.8 * n
		gp(torso, s, Vector3.new(0.12, d, d), CFrame.new(0, -2.6, 0) * ring, G_MAGENTA, NEON, Enum.PartType.Cylinder, 0.55)
	elseif id == "nova" then
		gp(torso, s, Vector3.new(0.22, 2.7 + 0.25 * n, 2.7 + 0.25 * n), CFrame.new(0, -0.45, 0) * ring, G_ORANGE, NEON, Enum.PartType.Cylinder, 0.25)
	elseif id == "missiles" then
		for _, sx in { -1, 1 } do
			gp(torso, s, Vector3.new(0.55, 0.65, 1.05), CFrame.new(sx * 1.38, 1.35, 0.15), G_DARK, METAL)
			gp(torso, s, Vector3.new(0.32, 0.32, 0.45), CFrame.new(sx * 1.38, 1.5, -0.42), G_MAGENTA, NEON)
		end
	elseif id == "arc" then
		for _, sx in { -1, 1 } do
			gp(torso, s, Vector3.new(0.24, 1.15 + 0.12 * n, 0.24), CFrame.new(sx * 0.88, 1.35, 0.92), G_CYAN, NEON)
		end
	end
end

applyGear = function()
	local char = Players.LocalPlayer.Character
	if not char then
		return
	end
	buildGear(char, "blaster", 1)
	for id, lvl in gearState do
		buildGear(char, id, lvl)
	end
end

function Scenery.gear(id: string, lvl: number)
	gearState[id] = lvl
	local char = Players.LocalPlayer.Character
	if char then
		buildGear(char, "blaster", 1)
		buildGear(char, id, lvl)
	end
end

function Scenery.clearGear()
	gearState = {}
	local char = Players.LocalPlayer.Character
	if char then
		for _, d in char:GetChildren() do
			if d.Name:sub(1, 5) == "Gear_" then
				d:Destroy()
			end
		end
		buildGear(char, "blaster", 1)
	end
end

-- ------------------------------------------------------------ Entrada
-- Lo llama el Renderer cuando una malla queda lista.
function Scenery.onMesh(name: string, model: Model)
	meshes[name] = model
	sizeCache[name] = nil
	if not ready then
		return
	end
	if name == "Ship" or name:match("^Piece%d$") then
		-- si cambia una malla de pieza ya montada, se rehace
		local i = tonumber(name:match("^Piece(%d)$"))
		if i and pieceVisuals[i] then
			pieceVisuals[i]:Destroy()
			pieceVisuals[i] = nil
		end
		refreshShip()
	elseif name:match("^Rock") or name:match("^Ridge") then
		scheduleDecor()
		refreshMoons()
	elseif name == "Helmet" or name == "Backpack" then
		redress()
	elseif name == "Rover" then
		refreshRover()
	elseif name == "Insignia" then
		refreshInsignia()
	end
end

function Scenery.init()
	templates = ReplicatedStorage:WaitForChild("Templates")
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(dress)
	task.spawn(function()
		local arena = Workspace:WaitForChild("Arena", 30)
		if arena then
			arena:WaitForChild("Ship", 30)
			arena:WaitForChild("Decor", 30)
		end
		ready = true
		Scenery.resetShip()
		refreshShip()
		Scenery.resetShip()
		buildZones()
		scheduleDecor()
		redress()
		refreshRover()
		refreshInsignia()
		refreshMoons()
		applyGear()
	end)
end

return Scenery
