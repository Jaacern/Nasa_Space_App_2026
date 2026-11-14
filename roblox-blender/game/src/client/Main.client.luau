--!strict
-- Cliente: entrada, cámara en tercera persona, interfaz y efectos.
-- Nunca decide daño: solo dibuja lo que manda el servidor.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Balance)
local Fx = require(script.Parent.Fx)
local Renderer = require(script.Parent.Renderer)
local Scenery = require(script.Parent.Scenery)
local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local sync = remotes:WaitForChild("Sync") :: RemoteEvent
local cmd = remotes:WaitForChild("Cmd") :: RemoteEvent

local CAM = Balance.Camera
local phase = "menu"
local dash: { dir: Vector3, left: number }? = nil
local cinematicStart = 0

-- Estado de la cámara orbital.
local yaw, pitch, dist = 0, math.rad(CAM.Pitch), CAM.Distance
local stick = Vector2.zero
local menuYaw = 0.6

local function send(...: any)
	cmd:FireServer(...)
end

local function rootPart(): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inRun(): boolean
	return phase == "run" or phase == "tutorial"
end

local function useSkill(idx: number)
	if not inRun() then
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = rootPart()
	if not hum or not hrp then
		return
	end
	local dir = hum.MoveDirection
	if dir.Magnitude < 0.1 then
		dir = hrp.CFrame.LookVector
	end
	send("skill", idx, dir.X, dir.Z)
end

local function applySettings()
	local S = Hud.settings
	Fx.setLow(S.lowFx)
	local bloom = Lighting:FindFirstChild("Bloom")
	if bloom and bloom:IsA("BloomEffect") then
		bloom.Enabled = not S.lowFx
	end
end

-- ------------------------------------------------------------ Biomas (solo visual)
local BIOMES = {
	{ ground = Color3.fromRGB(150, 85, 55), atm = Color3.fromRGB(214, 150, 110), decay = Color3.fromRGB(150, 80, 50), tint = Color3.fromRGB(255, 240, 228), clock = 15.2, density = 0.36, bright = 2.4 },
	{ ground = Color3.fromRGB(74, 84, 108), atm = Color3.fromRGB(120, 140, 185), decay = Color3.fromRGB(40, 50, 90), tint = Color3.fromRGB(215, 228, 255), clock = 18.4, density = 0.42, bright = 1.6 },
	{ ground = Color3.fromRGB(88, 44, 38), atm = Color3.fromRGB(255, 150, 80), decay = Color3.fromRGB(190, 60, 30), tint = Color3.fromRGB(255, 222, 200), clock = 12.5, density = 0.46, bright = 3.2 },
}

local function applyBiome(i: number, instant: boolean?)
	local b = BIOMES[i]
	local info = TweenInfo.new(if instant then 0 else 3, Enum.EasingStyle.Sine)
	local arena = Workspace:FindFirstChild("Arena")
	local ground = arena and arena:FindFirstChild("Ground")
	if ground then
		TweenService:Create(ground, info, { Color = b.ground }):Play()
	end
	local atm = Lighting:FindFirstChild("Atmosphere")
	if atm then
		TweenService:Create(atm, info, { Color = b.atm, Decay = b.decay, Density = b.density }):Play()
	end
	local cc = Lighting:FindFirstChild("ColorCorrection")
	if cc then
		TweenService:Create(cc, info, { TintColor = b.tint }):Play()
	end
	TweenService:Create(Lighting, info, { ClockTime = b.clock, Brightness = b.bright }):Play()
end

-- ------------------------------------------------------------ Eventos del servidor
local function onPhase(newPhase: string, meta: any, extra: any)
	local old = phase
	phase = newPhase
	Renderer.clearAll()
	if newPhase == "run" or newPhase == "tutorial" then
		Scenery.resetShip()
		applyBiome(1, old == "menu")
		Fx.setMusic("combat")
		yaw, pitch, dist = 0, math.rad(CAM.Pitch), CAM.Distance
		Hud.setPhase(newPhase, meta, extra)
	elseif newPhase == "victory" then
		cinematicStart = os.clock()
		Scenery.liftoff()
		Fx.setMusic("calm")
		Hud.setPhase("cinematic", meta, nil)
		-- el informe aparece cuando termina el despegue
		task.delay(5.5, function()
			if phase == "victory" then
				Hud.setPhase("victory", meta, extra)
			end
		end)
	else
		Fx.setMusic("calm")
		if newPhase == "menu" then
			applyBiome(1, true)
		end
		Hud.setPhase(newPhase, meta, extra)
	end
end

local handlers: { [string]: (ev: { any }) -> () } = {
	phase = function(ev)
		onPhase(ev[2], ev[3], ev[4])
	end,
	spawn = function(ev)
		Renderer.spawn(ev[2], ev[3], ev[4], ev[5])
	end,
	die = function(ev)
		Renderer.die(ev[2])
	end,
	hit = function(ev)
		Renderer.hit(ev[2], ev[3], ev[4] == 1)
	end,
	shot = function(ev)
		Renderer.shot(ev[2], ev[3], ev[4], ev[5], ev[6], ev[7], ev[8], ev[9] == 1)
	end,
	shotEnd = function(ev)
		Renderer.shotEnd(ev[2])
	end,
	eshot = function(ev)
		Renderer.eshot(ev[2], ev[3], ev[4], ev[5], ev[6], ev[7])
	end,
	eshotEnd = function(ev)
		Renderer.eshotEnd(ev[2])
	end,
	tele = function(ev)
		Renderer.tele(ev[2], ev[3], ev[4], ev[5], ev[6], ev[7], ev[8], ev[9], ev[10])
	end,
	teleEnd = function(ev)
		Renderer.teleEnd(ev[2])
	end,
	boom = function(ev)
		Renderer.boom(ev[2], ev[3], ev[4])
	end,
	gem = function(ev)
		Renderer.gem(ev[2], ev[3], ev[4])
	end,
	gemGot = function(ev)
		Renderer.gemGot(ev[2])
	end,
	chest = function(ev)
		Renderer.chest(ev[2], ev[3], ev[4])
	end,
	chestGot = function(ev)
		Renderer.chestGot(ev[2])
	end,
	item = function(ev)
		Hud.item(ev[2], ev[3])
	end,
	hurt = function(ev)
		Hud.hurt()
		Fx.shake(0.3)
		Fx.play("hurt")
		local hrp = rootPart()
		if hrp then
			Fx.number(hrp.Position + Vector3.new(0, 3, 0), "-" .. ev[2], Color3.fromRGB(255, 45, 85), true)
		end
	end,
	block = function()
		local hrp = rootPart()
		if hrp then
			Fx.number(hrp.Position + Vector3.new(0, 3, 0), "BLOQUEADO", Color3.fromRGB(0, 210, 255))
		end
	end,
	levelup = function(ev)
		Hud.levelUp(ev[2], ev[3], ev[4], ev[5])
	end,
	piece = function(ev)
		Scenery.showPiece(ev[2])
		Hud.piece(ev[2])
	end,
	alert = function(ev)
		Hud.alert(ev[2], ev[3])
	end,
	nasa = function(ev)
		Hud.alert("ALERTA DE CLIMA ESPACIAL", "warn", string.format("Evento real del %s: %s (NASA DONKI)", ev[3], ev[2]))
	end,
	wave = function(ev)
		Hud.wave(ev[2], ev[3])
	end,
	biome = function(ev)
		applyBiome(ev[2])
		Hud.biome(ev[2])
	end,
	boss = function(ev)
		Hud.boss(ev[2])
		Fx.setMusic("boss")
	end,
	skill = function(ev)
		Renderer.skillFx(ev[2])
		if ev[2] == 1 then
			dash = { dir = Vector3.new(ev[3], 0, ev[4]), left = Balance.Skills.Dash.Distance }
		end
	end,
	tut = function(ev)
		Hud.tutorial(ev[2])
	end,
	paused = function(ev)
		Hud.paused(ev[2] == 1)
	end,
}

-- ------------------------------------------------------------ Arranque
Renderer.init()
Scenery.init()
Hud.init(send, useSkill, applySettings)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

sync.OnClientEvent:Connect(function(snap: any, events: any)
	if snap then
		Renderer.snapshot(snap.pos)
		Renderer.setHud(snap.hud)
		Hud.setHud(snap.hud)
	end
	if events then
		for _, ev in events do
			local h = handlers[ev[1]]
			if h then
				h(ev)
			end
		end
	end
end)
send("ready")

-- ------------------------------------------------------------ Entrada
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local k = input.KeyCode
	if k == Enum.KeyCode.Q or k == Enum.KeyCode.ButtonX or k == Enum.KeyCode.LeftShift then
		useSkill(1)
	elseif k == Enum.KeyCode.E or k == Enum.KeyCode.ButtonB then
		useSkill(2)
	elseif k == Enum.KeyCode.One or k == Enum.KeyCode.KeypadOne then
		Hud.pick(1)
	elseif k == Enum.KeyCode.Two or k == Enum.KeyCode.KeypadTwo then
		Hud.pick(2)
	elseif k == Enum.KeyCode.Three or k == Enum.KeyCode.KeypadThree then
		Hud.pick(3)
	elseif k == Enum.KeyCode.P or k == Enum.KeyCode.ButtonStart then
		if phase == "run" then
			send("pause")
		end
	end
end)

local function rotate(dx: number, dy: number)
	local s = CAM.Sensitivity * Hud.settings.sens
	yaw -= dx * s
	pitch = math.clamp(pitch + dy * s, math.rad(CAM.MinPitch), math.rad(CAM.MaxPitch))
end

UserInputService.InputChanged:Connect(function(input, processed)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseMovement then
		if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			rotate(input.Delta.X, input.Delta.Y)
		end
	elseif t == Enum.UserInputType.MouseWheel then
		if inRun() and not processed then
			dist = math.clamp(dist - input.Position.Z * 3, CAM.MinDistance, CAM.MaxDistance)
		end
	elseif t == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2 then
		stick = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

-- Táctil: arrastrar fuera del joystick y de los botones gira la cámara.
UserInputService.TouchMoved:Connect(function(touchInput, processed)
	if not processed and inRun() and not Hud.wantsCursor() then
		rotate(touchInput.Delta.X * 1.6, touchInput.Delta.Y * 1.6)
	end
end)

-- ------------------------------------------------------------ Bucle de dibujo
local camera = Workspace.CurrentCamera :: Camera
local camFocus = Vector3.new(0, CAM.FocusHeight, 34)
local limit = Balance.Sim.ArenaRadius - 3
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

RunService:BindToRenderStep("AresMain", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	local hrp = rootPart()

	-- Impulso RCS: el cliente mueve su personaje; el servidor ya validó el uso y el daño.
	if dash and hrp then
		local D = Balance.Skills.Dash
		local step = math.min(dash.left, D.Distance / D.Duration * dt)
		local target = hrp.Position + dash.dir * step
		local flatLen = math.sqrt(target.X * target.X + target.Z * target.Z)
		local blocked = flatLen > limit or flatLen < 13
		if not blocked then
			hrp.CFrame = hrp.CFrame + dash.dir * step
			hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
		end
		dash.left -= step
		if dash.left <= 0 or blocked then
			dash = nil
		end
	end

	Fx.update(dt)
	Renderer.update(dt)
	Hud.update(dt, if inRun() then Renderer.nearestChest() else nil)

	local locked = inRun() and not Hud.wantsCursor() and UserInputService.MouseEnabled
	UserInputService.MouseBehavior = if locked then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not locked

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = Hud.settings.fov

	if phase == "menu" then
		-- Órbita lenta alrededor de la nave; la nave queda a la derecha del menú.
		menuYaw += dt * 0.06
		local ship = Scenery.shipPosition()
		local eye = ship + Vector3.new(math.sin(menuYaw) * 58, 16, math.cos(menuYaw) * 58)
		local cf = CFrame.lookAt(eye, ship + Vector3.new(0, 4, 0))
		camera.CFrame = cf * CFrame.new(-17, 0, 0)
		return
	end
	if phase == "victory" then
		local ship = Scenery.shipPivot()
		local eye = Vector3.new(70, 18, 70)
		camera.CFrame = CFrame.lookAt(eye, ship)
		return
	end

	if hrp then
		if stick.Magnitude > 0.15 then
			rotate(stick.X * 900 * dt, -stick.Y * 500 * dt)
		end
		local want = hrp.Position + Vector3.new(0, CAM.FocusHeight, 0)
		camFocus = camFocus:Lerp(want, math.min(1, dt * 14))
		local cp = math.cos(pitch)
		local offset = Vector3.new(math.sin(yaw) * cp, math.sin(pitch), math.cos(yaw) * cp)
		local d = dist
		local arena = Workspace:FindFirstChild("Arena")
		if arena then
			rayParams.FilterDescendantsInstances = { arena }
			local hit = Workspace:Raycast(camFocus, offset * dist, rayParams)
			if hit then
				d = math.max(4, hit.Distance - 1)
			end
		end
		camera.CFrame = CFrame.lookAt(camFocus + offset * d, camFocus) * CFrame.new(Fx.shakeOffset())
	end
end)
