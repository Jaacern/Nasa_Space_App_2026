--!strict
-- Convierte los módulos de datos de malla (exportados desde Blender a Shared/Meshes) en modelos
-- con MeshPart generados en el cliente mediante EditableMesh. No hace falta subir assets a Roblox.
-- Contrato del módulo: { name, tris, parts = { { material, color = {r,g,b}, alpha, v = {x,y,z,...}, f = {a,b,c,...} } } }
-- Vértices en studs, ejes de Roblox (Y arriba, frente -Z), origen del asset en (0,0,0).

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshFactory = {}

local shared = ReplicatedStorage:WaitForChild("Shared")
local cache: { [string]: Model } = {}

local function meshFolder(): Instance?
	return shared:FindFirstChild("Meshes")
end

function MeshFactory.names(): { string }
	local out = {}
	local folder = meshFolder()
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("ModuleScript") then
				table.insert(out, m.Name)
			end
		end
	end
	return out
end

local function buildPart(model: Model, root: Part, part: any, index: number)
	local v: { number }, f: { number } = part.v, part.f
	local nv = #v // 3
	if nv < 3 or #f < 3 then
		return
	end
	-- Centra la geometría en su caja para que el MeshPart coincida con lo que se ve (culling correcto).
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	for i = 1, #v, 3 do
		local x, y, z = v[i], v[i + 1], v[i + 2]
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		minY, maxY = math.min(minY, y), math.max(maxY, y)
		minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
	end
	local cx, cy, cz = (minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2

	local em = AssetService:CreateEditableMesh()
	local ids = table.create(nv)
	local pos = table.create(nv)
	for i = 1, nv do
		local p = Vector3.new(v[i * 3 - 2] - cx, v[i * 3 - 1] - cy, v[i * 3] - cz)
		pos[i] = p
		ids[i] = em:AddVertex(p)
	end
	for i = 1, #f, 3 do
		local a, b, c = f[i], f[i + 1], f[i + 2]
		if ids[a] and ids[b] and ids[c] and a ~= b and b ~= c and a ~= c then
			local face = em:AddTriangle(ids[a], ids[b], ids[c])
			-- Normal plana por cara: aspecto facetado low-poly.
			local n = (pos[b] - pos[a]):Cross(pos[c] - pos[a])
			if n.Magnitude > 1e-7 then
				local nid = em:AddNormal(n.Unit)
				em:SetFaceNormals(face, { nid, nid, nid })
			end
		end
	end

	-- Convertir a FixedSize y destruir el EditableMesh dinámico para no agotar el presupuesto de memoria.
	local okFixed, emFixed = pcall(function()
		return AssetService:CreateEditableMeshAsync(Content.fromObject(em), { FixedSize = true })
	end)
	em:Destroy()
	if not okFixed or not emFixed then
		error("CreateEditableMeshAsync fallo: " .. tostring(emFixed))
	end

	local mp = AssetService:CreateMeshPartAsync(Content.fromObject(emFixed), { CollisionFidelity = Enum.CollisionFidelity.Box })
	mp.Name = "Mesh" .. index
	local ok = pcall(function()
		mp.Material = (Enum.Material :: any)[part.material]
	end)
	if not ok then
		mp.Material = Enum.Material.SmoothPlastic
	end
	local col = part.color
	mp.Color = Color3.fromRGB(col[1], col[2], col[3])
	mp.Transparency = part.alpha or 0
	mp.CanCollide = false
	mp.CanQuery = false
	mp.CanTouch = false
	mp.Massless = true
	mp.CastShadow = (part.alpha or 0) < 0.3 and part.material ~= "Neon"
	mp.CFrame = root.CFrame * CFrame.new(cx, cy, cz)
	mp:SetAttribute("BaseT", mp.Transparency)
	mp:SetAttribute("BaseM", part.material)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = mp
	w.Parent = mp
	mp.Parent = model
end

-- Devuelve un Model (Root anclado + MeshParts soldados) o nil si no existe o falla.
function MeshFactory.build(name: string): Model?
	if cache[name] then
		return cache[name]
	end
	local folder = meshFolder()
	local mod = folder and folder:FindFirstChild(name)
	if not mod or not mod:IsA("ModuleScript") then
		return nil
	end
	local ok, data = pcall(require, mod)
	if not ok or type(data) ~= "table" or type(data.parts) ~= "table" then
		warn("[MeshFactory] Módulo de malla inválido: " .. name)
		return nil
	end
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root
	for i, part in data.parts do
		local okPart, err = pcall(buildPart, model, root, part, i)
		if not okPart then
			warn(string.format("[MeshFactory] %s parte %d: %s", name, i, tostring(err)))
		end
	end
	if #model:GetChildren() <= 1 then
		model:Destroy()
		return nil
	end
	model:SetAttribute("Mesh", true)
	cache[name] = model
	return model
end

-- Construye todas las mallas disponibles sin bloquear: avisa de cada una al terminar.
function MeshFactory.buildAll(order: { string }, onReady: (name: string, model: Model) -> ())
	local done: { [string]: boolean } = {}
	local function one(name: string)
		if done[name] then
			return
		end
		done[name] = true
		local m = MeshFactory.build(name)
		if m then
			onReady(name, m)
		end
		task.wait()
	end
	for _, name in order do
		one(name)
	end
	for _, name in MeshFactory.names() do
		one(name)
	end
end

return MeshFactory
