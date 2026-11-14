-- Sincroniza game/src (disco) -> Roblox Studio. Se ejecuta en modo Edit con execute_luau.
-- Requiere el servidor local: python -m http.server 8765 --bind 127.0.0.1 --directory game/src
-- shared/ -> ReplicatedStorage.Shared | server/ -> ServerScriptService.Server | client/ -> StarterPlayer.StarterPlayerScripts.Client
-- X.luau = ModuleScript, X.server.luau = Script, X.client.luau = LocalScript. Las subcarpetas se convierten en Folder (recursivo).

local HttpService = game:GetService("HttpService")
local BASE = "http://127.0.0.1:8765/"

local targets = {
	{ dir = "shared", parent = game:GetService("ReplicatedStorage"), name = "Shared" },
	{ dir = "server", parent = game:GetService("ServerScriptService"), name = "Server" },
	{ dir = "client", parent = game:GetService("StarterPlayer").StarterPlayerScripts, name = "Client" },
}

local report = {}

local function syncDir(urlPath: string, folder: Instance, label: string)
	local listing = HttpService:GetAsync(BASE .. urlPath, true)
	local seen = {}
	for href in listing:gmatch('href="([^"]+)"') do
		if href:sub(-1) == "/" then
			-- subcarpeta
			local sub = href:sub(1, -2)
			if sub ~= ".." and sub ~= "." and not sub:find("/") then
				local subFolder = folder:FindFirstChild(sub)
				if subFolder and not subFolder:IsA("Folder") then
					subFolder:Destroy()
					subFolder = nil
				end
				if not subFolder then
					subFolder = Instance.new("Folder")
					subFolder.Name = sub
					subFolder.Parent = folder
				end
				seen[sub] = true
				syncDir(urlPath .. href, subFolder, label .. "." .. sub)
			end
		elseif href:match("%.luau$") then
			local source = HttpService:GetAsync(BASE .. urlPath .. href, true)
			local base = href:gsub("%.luau$", "")
			local className = "ModuleScript"
			if base:match("%.server$") then
				className = "Script"
				base = base:gsub("%.server$", "")
			elseif base:match("%.client$") then
				className = "LocalScript"
				base = base:gsub("%.client$", "")
			end
			seen[base] = true
			local inst = folder:FindFirstChild(base)
			if inst and inst.ClassName ~= className then
				inst:Destroy()
				inst = nil
			end
			if not inst then
				inst = Instance.new(className)
				inst.Name = base
				inst.Parent = folder
			end
			if inst.Source ~= source then
				inst.Source = source
				table.insert(report, label .. "." .. base .. " (" .. #source .. " B)")
			end
			task.wait() -- cede entre archivos (las mallas pesan hasta ~180 KB)
		end
	end
	for _, child in folder:GetChildren() do
		-- Solo borra scripts que ya no existen en disco; las carpetas no se tocan.
		if child:IsA("LuaSourceContainer") and not seen[child.Name] then
			table.insert(report, "ELIMINADO " .. label .. "." .. child.Name)
			child:Destroy()
		end
	end
end

for _, t in targets do
	local folder = t.parent:FindFirstChild(t.name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = t.name
		folder.Parent = t.parent
	end
	syncDir(t.dir .. "/", folder, t.name)
end
return #report .. " cambios: " .. table.concat(report, ", ")
