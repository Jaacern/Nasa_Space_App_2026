--!strict
-- Piloto automático y cámaras de captura. SOLO en Studio (pruebas, demo grabada y tráiler).
-- Se controla con atributos del jugador local (los pone una persona o una herramienta en Studio):
--   Autopilot (bool)   juega como una persona: esquiva, usa habilidades, elige cartas y continúa.
--   CineCam (string)   cámara de captura: "orbit" | "low" | "high" | "boss" | "ship" | "side" | "" (normal).
--   CineFov (number)   campo de visión para la cámara de captura (por defecto 55).
--   CleanCapture (bool) oculta la barra superior y el chat de Roblox.
--   HideHud (bool)     oculta la interfaz del juego (planos limpios).
--   HideInsignia (bool) oculta la insignia de NASA del menú (el tráiler no la usa).
-- En un servidor publicado no hace nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Balance)

local Autopilot = {}

type Deps = {
	hud: any,
	renderer: any,
	send: (...any) -> (),
	useSkill: (number) -> (),
	phase: () -> string,
}

local player = Players.LocalPlayer
local t = 0
local orbitDir = 1
local nextFlip = 14
local overlayT = 0
local cineT = 0
local lastSkill = { 0, 0 }

local function attr(name: string): any
	return player:GetAttribute(name)
end

local function rootPart(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoid(): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- Dirección de movimiento: círculo amplio alrededor del centro + repulsión de enemigos + atracción a cofres.
local function steer(deps: Deps, pos: Vector3): (Vector3, number, number)
	local R = Balance.Sim.ArenaRadius
	local flat = Vector3.new(pos.X, 0, pos.Z)
	local d = flat.Magnitude
	local radial = if d > 0.1 then flat / d else Vector3.new(1, 0, 0)
	local tangent = Vector3.new(-radial.Z, 0, radial.X) * orbitDir
	local target = math.clamp(R * 0.42, 40, 110)
	local move = tangent + radial * math.clamp((target - d) / 30, -1, 1) * 0.8
	local near, close = 0, 0
	for _, e in deps.renderer.enemyPositions() do
		local dx, dz = pos.X - e.x, pos.Z - e.z
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist < 26 and dist > 0.01 then
			local w = (26 - dist) / 26
			move += Vector3.new(dx / dist, 0, dz / dist) * w * w * 3.2
			near += 1
			if dist < 7 then
				close += 1
			end
		end
	end
	local chest = deps.renderer.nearestChest()
	if chest and near < 3 then
		local v = Vector3.new(chest.X - pos.X, 0, chest.Z - pos.Z)
		if v.Magnitude > 2 and v.Magnitude < 90 then
			move += v.Unit * 1.4
		end
	end
	if move.Magnitude < 0.05 then
		move = tangent
	end
	return move.Unit, near, close
end

local function visible(name: string): GuiObject?
	local pg = player:FindFirstChild("PlayerGui")
	local gui = pg and pg:FindFirstChild("AresHud")
	local f = gui and gui:FindFirstChild(name, true)
	if f and f:IsA("GuiObject") and f.Visible then
		return f
	end
	return nil
end

local function play(deps: Deps, dt: number)
	local ph = deps.phase()
	if ph ~= "run" and ph ~= "tutorial" then
		return
	end
	-- Paneles: cartas, pieza y briefing (con una pausa para que se lean en la grabación).
	if visible("LevelUp") or visible("Piece") or visible("Briefing") then
		overlayT += dt
		local wait = if visible("Piece") then 4.5 elseif visible("Briefing") then 2.5 else 1.6
		if overlayT > wait then
			overlayT = 0
			deps.hud.autoAdvance()
		end
		return
	end
	overlayT = 0
	local hum, hrp = humanoid(), rootPart()
	if not hum or not hrp then
		return
	end
	t += dt
	if t > nextFlip then
		orbitDir = -orbitDir
		nextFlip = t + math.random(10, 18)
	end
	local dir, near, close = steer(deps, hrp.Position)
	hum:Move(dir, false)
	-- Habilidades: impulso si algo está encima; pulso si hay grupo alrededor.
	if close >= 1 and t - lastSkill[1] > 2 then
		lastSkill[1] = t
		deps.useSkill(1)
	elseif near >= 6 and t - lastSkill[2] > 3 then
		lastSkill[2] = t
		deps.useSkill(2)
	end
end

-- Cámaras de captura (se aplican después de la cámara del juego).
local function cine(dt: number)
	local mode = attr("CineCam")
	if type(mode) ~= "string" or mode == "" then
		return
	end
	cineT += dt
	local cam = Workspace.CurrentCamera
	local hrp = rootPart()
	cam.FieldOfView = (attr("CineFov") :: number?) or 55
	local p = if hrp then hrp.Position else Vector3.new(0, 3, 34)
	if mode == "orbit" then
		local a = cineT * 0.22
		local eye = p + Vector3.new(math.sin(a) * 24, 8, math.cos(a) * 24)
		cam.CFrame = CFrame.lookAt(eye, p + Vector3.new(0, 2.5, 0))
	elseif mode == "low" then
		local a = cineT * 0.08
		local eye = p + Vector3.new(math.sin(a) * 11, 1.2, math.cos(a) * 11)
		cam.CFrame = CFrame.lookAt(eye, p + Vector3.new(0, 4.5, 0))
	elseif mode == "high" then
		local a = cineT * 0.05
		local eye = p + Vector3.new(math.sin(a) * 52, 62, math.cos(a) * 52)
		cam.CFrame = CFrame.lookAt(eye, p)
	elseif mode == "side" then
		local look = if hrp then hrp.CFrame.RightVector else Vector3.new(1, 0, 0)
		local eye = p + look * 18 + Vector3.new(0, 4, 0)
		cam.CFrame = CFrame.lookAt(eye, p + Vector3.new(0, 2.5, 0))
	elseif mode == "boss" then
		-- Encuadra al modelo más grande de la escena de combate (el jefe), con el héroe delante.
		local best: Model? = nil
		local bestSize = 0
		local folder = Workspace:FindFirstChild("ClientFx")
		for _, m in (if folder then folder:GetChildren() else {}) do
			if m:IsA("Model") then
				local ok, size = pcall(function()
					return (m :: Model):GetExtentsSize().Magnitude
				end)
				local piv = (m :: Model):GetPivot().Position
				if ok and size > bestSize and size < 200 and piv.Y > -3 then
					best, bestSize = m :: Model, size
				end
			end
		end
		if best then
			local bp = best:GetPivot().Position
			local away = (p - bp)
			away = if away.Magnitude > 0.1 then Vector3.new(away.X, 0, away.Z).Unit else Vector3.new(0, 0, 1)
			local eye = p + away * 14 + Vector3.new(0, 3, 0)
			cam.CFrame = CFrame.lookAt(eye, bp + Vector3.new(0, bestSize * 0.3, 0))
		end
	elseif mode == "ship" then
		local ship = Workspace:FindFirstChild("ShipVisual") or (Workspace:FindFirstChild("Arena") and (Workspace :: any).Arena:FindFirstChild("Ship"))
		local sp = if ship and ship:IsA("Model") then ship:GetPivot().Position else Vector3.zero
		local a = cineT * 0.12 + 0.6
		local eye = sp + Vector3.new(math.sin(a) * 40, 6, math.cos(a) * 40)
		cam.CFrame = CFrame.lookAt(eye, sp + Vector3.new(0, 5, 0))
	end
end

local cleanApplied: boolean? = nil
local function applyClean()
	local on = attr("CleanCapture") == true
	if on ~= cleanApplied then
		cleanApplied = on
		pcall(function()
			StarterGui:SetCore("TopbarEnabled", not on)
		end)
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not on)
		end)
	end
	-- Insignia de NASA fuera de cuadro en las tomas del tráiler (atributo HideInsignia).
	local ins = Workspace:FindFirstChild("InsigniaVisual")
	if ins then
		local m = if attr("HideInsignia") == true then 1 else 0
		for _, d in ins:GetDescendants() do
			if d:IsA("BasePart") and d.LocalTransparencyModifier ~= m then
				d.LocalTransparencyModifier = m
			end
		end
	end
	local pg = player:FindFirstChild("PlayerGui")
	local gui = pg and pg:FindFirstChild("AresHud")
	if gui and gui:IsA("ScreenGui") then
		local hide = attr("HideHud") == true
		if gui.Enabled == hide then
			gui.Enabled = not hide
		end
	end
end

function Autopilot.start(deps: Deps)
	if not RunService:IsStudio() then
		return
	end
	RunService:BindToRenderStep("AresCapture", Enum.RenderPriority.Camera.Value + 5, function(dt: number)
		applyClean()
		if attr("Autopilot") == true then
			play(deps, dt)
		end
		cine(dt)
	end)
end

return Autopilot
