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

-- Oculta (solo en el cliente) las piezas visibles de la nave del servidor; la colision se conserva.
local function hideHull()
	local ship = serverShip()
	if not ship or hullHidden then
		return
	end
	hullHidden = true
	for _, d in ship:GetChildren() do
		if d:IsA("BasePart") then
			d.Transparency = 1
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

local function attachMesh(char: Model, name: string, to: BasePart, offset: CFrame)
	local old = char:FindFirstChild("Suit" .. name)
	if old then
		old:Destroy()
	end
	local m = meshes[name]:Clone()
	m.Name = "Suit" .. name
	local root = m.PrimaryPart :: Part
	root.Anchored = false
	root.Massless = true
	m:PivotTo(to.CFrame * offset)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = root
	w.Parent = root
	m.Parent = char
end

local dressing: { [Model]: boolean } = {}
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
			attachMesh(char, "Helmet", head, CFrame.new(0, 0.1, 0))
			attachMesh(char, "Backpack", torso, CFrame.new(0, 0.1, 0.9))
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
	elseif name == "Helmet" or name == "Backpack" then
		redress()
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
		scheduleDecor()
		redress()
	end)
end

return Scenery
