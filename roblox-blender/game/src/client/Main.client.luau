--!strict
-- Cliente: entrada, cámara en tercera persona, interfaz y efectos.
-- Nunca decide daño: solo dibuja lo que manda el servidor.

local ContextActionService = game:GetService("ContextActionService")
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
local Ui = require(script.Parent.Ui)

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

local function detectHardwareTier(): string
	local ok, lvl = pcall(function()
		return (UserSettings() :: any):GetService("UserGameSettings").SavedQualityLevel
	end)
	if ok and lvl then
		if lvl == Enum.SavedQualitySetting.QualityLevel1
			or lvl == Enum.SavedQualitySetting.QualityLevel2
			or lvl == Enum.SavedQualitySetting.QualityLevel3
		then
			return "low"
		elseif lvl == Enum.SavedQualitySetting.QualityLevel4
			or lvl == Enum.SavedQualitySetting.QualityLevel5
			or lvl == Enum.SavedQualitySetting.QualityLevel6
		then
			return "med"
		end
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "med"
	end
	return "high"
end

local hwTier = detectHardwareTier()
Hud.settings.effectiveQuality = hwTier
local fpsEma, lowFpsT, highFpsT = 60, 0, 0

local function applySettings()
	local S = Hud.settings
	Fx.setMuted(S.muted == true)
	local tier = if S.qualityMode == "auto" then S.effectiveQuality else S.qualityMode
	Hud.setEffectiveQuality(tier)
	Fx.setQuality(tier)
	Renderer.setQuality(tier)
	local bloom = Lighting:FindFirstChild("Bloom")
	if bloom and bloom:IsA("BloomEffect") then
		bloom.Enabled = (tier ~= "low")
		bloom.Intensity = if tier == "high" then 0.55 else 0.32
	end
	pcall(function()
		Lighting.GlobalShadows = (tier ~= "low")
	end)
end

-- Equilibrio gráfico automático con histéresis para adaptarse a la carga real del dispositivo.
local function updateAdaptiveQuality(dt: number)
	if Hud.settings.qualityMode ~= "auto" or not inRun() or Hud.wantsCursor() then
		lowFpsT = 0
		highFpsT = 0
		return
	end
	local instFps = math.clamp(1 / math.max(dt, 0.001), 10, 120)
	fpsEma = fpsEma * 0.93 + instFps * 0.07
	local cur = Hud.settings.effectiveQuality
	if fpsEma < 42 then
		lowFpsT += dt
		highFpsT = 0
		if lowFpsT >= 2.5 then
			lowFpsT = 0
			if cur == "high" then
				Hud.settings.effectiveQuality = "med"
				applySettings()
			elseif cur == "med" then
				Hud.settings.effectiveQuality = "low"
				applySettings()
			end
		end
	elseif fpsEma > 57 then
		highFpsT += dt
		lowFpsT = 0
		if highFpsT >= 7.0 then
			highFpsT = 0
			if cur == "low" then
				Hud.settings.effectiveQuality = "med"
				applySettings()
			elseif cur == "med" and hwTier == "high" then
				Hud.settings.effectiveQuality = "high"
				applySettings()
			end
		end
	else
		lowFpsT = math.max(0, lowFpsT - dt * 0.5)
		highFpsT = math.max(0, highFpsT - dt * 0.5)
	end
end

-- ------------------------------------------------------------ Biomas (solo visual)
local BIOMES = {
	{ ground = Color3.fromRGB(150, 85, 55), atm = Color3.fromRGB(222, 170, 120), decay = Color3.fromRGB(168, 104, 62), tint = Color3.fromRGB(255, 240, 228), amb = Color3.fromRGB(128, 102, 92), outAmb = Color3.fromRGB(145, 118, 105), clock = 15.2, density = 0.36, bright = 2.5 },
	{ ground = Color3.fromRGB(84, 96, 122), atm = Color3.fromRGB(132, 152, 198), decay = Color3.fromRGB(48, 60, 102), tint = Color3.fromRGB(224, 236, 255), amb = Color3.fromRGB(115, 128, 158), outAmb = Color3.fromRGB(132, 145, 178), clock = 17.6, density = 0.38, bright = 2.0 },
	{ ground = Color3.fromRGB(102, 54, 46), atm = Color3.fromRGB(255, 158, 92), decay = Color3.fromRGB(190, 68, 36), tint = Color3.fromRGB(255, 228, 208), amb = Color3.fromRGB(136, 96, 84), outAmb = Color3.fromRGB(158, 112, 96), clock = 13.0, density = 0.42, bright = 3.1 },
}

local function applyBiome(i: number, instant: boolean?)
	local b = BIOMES[i] or BIOMES[1]
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
	TweenService:Create(Lighting, info, { ClockTime = b.clock, Brightness = b.bright, Ambient = b.amb, OutdoorAmbient = b.outAmb }):Play()
end

-- ------------------------------------------------------------ Eventos del servidor
local function onPhase(newPhase: string, meta: any, extra: any)
	local old = phase
	phase = newPhase
	dash = nil
	Renderer.clearAll()
	Scenery.clearBlackHole()
	Scenery.setMenu(newPhase == "menu")
	if newPhase == "run" or newPhase == "tutorial" or newPhase == "menu" then
		Scenery.clearGear()
	end
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
		Renderer.chest(ev[2], ev[3], ev[4], ev[5])
	end,
	chestGot = function(ev)
		Renderer.chestGot(ev[2], ev[3])
	end,
	meteorBoom = function(ev)
		Renderer.meteorBoom(ev[2], ev[3], ev[4])
	end,
	zone = function(ev)
		Hud.zone(ev[2])
	end,
	blackhole = function(ev)
		Scenery.triggerBlackHole(ev[2], ev[3])
		Hud.blackHole(ev[2], ev[3])
	end,
	briefing = function(ev)
		Hud.briefing(ev[2] == 1)
	end,
	toastMsg = function(ev)
		Hud.toastMsg(ev[2], ev[3], ev[4])
	end,
	shieldHit = function()
		Renderer.shieldHit()
		Fx.play("block")
	end,
	shieldBreak = function()
		Renderer.shieldBreak()
		Fx.play("hurt")
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
		Hud.levelFlash(ev[2])
		local hrp = rootPart()
		if hrp then
			Fx.celebrate(hrp.Position, true)
		end
		Hud.levelUp(ev[2], ev[3], ev[4], ev[5])
	end,
	chosen = function(ev)
		Hud.buff(ev[2], ev[3])
		Scenery.gear(ev[2], ev[3])
		Fx.play("buff")
		local hrp = rootPart()
		if hrp then
			Fx.celebrate(hrp.Position)
		end
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
applySettings()
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

-- ------------------------------------------------------------ Entrada multiplataforma
local function modeFromInputType(t: Enum.UserInputType): string?
	if t == Enum.UserInputType.Touch then
		return "touch"
	elseif t == Enum.UserInputType.Gamepad1
		or t == Enum.UserInputType.Gamepad2
		or t == Enum.UserInputType.Gamepad3
		or t == Enum.UserInputType.Gamepad4
		or t == Enum.UserInputType.Gamepad5
		or t == Enum.UserInputType.Gamepad6
		or t == Enum.UserInputType.Gamepad7
		or t == Enum.UserInputType.Gamepad8
	then
		return "gamepad"
	elseif t == Enum.UserInputType.Keyboard
		or t == Enum.UserInputType.MouseButton1
		or t == Enum.UserInputType.MouseButton2
		or t == Enum.UserInputType.MouseMovement
		or t == Enum.UserInputType.MouseWheel
	then
		return "kb"
	end
	return nil
end

local initInputMode = modeFromInputType(UserInputService:GetLastInputType())
if initInputMode then
	Hud.setInputMode(initInputMode)
end
UserInputService.LastInputTypeChanged:Connect(function(t)
	local m = modeFromInputType(t)
	if m then
		Hud.setInputMode(m)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	local k = input.KeyCode
	if Hud.isBriefingOpen() and (k == Enum.KeyCode.Space or k == Enum.KeyCode.Return or k == Enum.KeyCode.ButtonA) and not UserInputService:GetFocusedTextBox() then
		Hud.closeBriefing()
		return
	end
	if k == Enum.KeyCode.ButtonB and not UserInputService:GetFocusedTextBox() and Hud.wantsCursor() then
		if Hud.back() then
			return
		end
	end
	if processed then
		return
	end
	if k == Enum.KeyCode.Q or k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.ButtonX or k == Enum.KeyCode.ButtonL1 then
		useSkill(1)
	elseif k == Enum.KeyCode.E or k == Enum.KeyCode.ButtonB or k == Enum.KeyCode.ButtonR1 then
		useSkill(2)
	elseif k == Enum.KeyCode.One or k == Enum.KeyCode.KeypadOne or k == Enum.KeyCode.DPadLeft then
		Hud.pick(1)
	elseif k == Enum.KeyCode.Two or k == Enum.KeyCode.KeypadTwo or k == Enum.KeyCode.DPadUp then
		Hud.pick(2)
	elseif k == Enum.KeyCode.Three or k == Enum.KeyCode.KeypadThree or k == Enum.KeyCode.DPadRight then
		Hud.pick(3)
	elseif k == Enum.KeyCode.ButtonR3 then
		if inRun() and not Hud.wantsCursor() then
			if dist > (CAM.Distance + CAM.MaxDistance) * 0.5 then
				dist = CAM.MinDistance
			elseif dist < (CAM.MinDistance + CAM.Distance) * 0.5 then
				dist = CAM.Distance
			else
				dist = CAM.MaxDistance
			end
		end
	elseif k == Enum.KeyCode.P or k == Enum.KeyCode.ButtonStart then
		if phase == "run" and not Hud.wantsCursor() then
			send("pause")
		elseif Hud.wantsCursor() then
			Hud.back()
		end
	end
end)

-- Intercepta las flechas para mover al héroe en lugar de girar la cámara clásica de Roblox.
ContextActionService:BindActionAtPriority("AresArrowKeys", function()
	if inRun() and not Hud.wantsCursor() and not UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)

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

-- Táctil: evita que el joystick virtual inferior izquierdo gire la cámara, y soporta pellizco para zoom.
local joystickTouches: { [InputObject]: boolean } = {}
UserInputService.TouchStarted:Connect(function(touchInput, processed)
	if processed then
		joystickTouches[touchInput] = true
		return
	end
	local cam = Workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local p = touchInput.Position
	if p.X < vp.X * 0.38 and p.Y > vp.Y * 0.52 then
		joystickTouches[touchInput] = true
	end
end)
UserInputService.TouchEnded:Connect(function(touchInput)
	joystickTouches[touchInput] = nil
end)
UserInputService.TouchMoved:Connect(function(touchInput, processed)
	if not processed and not joystickTouches[touchInput] and inRun() and not Hud.wantsCursor() then
		rotate(touchInput.Delta.X * 1.6, touchInput.Delta.Y * 1.6)
	end
end)
UserInputService.TouchPinch:Connect(function(_touches, _scale, velocity, _state, processed)
	if not processed and inRun() and not Hud.wantsCursor() then
		dist = math.clamp(dist - velocity * 0.08, CAM.MinDistance, CAM.MaxDistance)
	end
end)

-- ------------------------------------------------------------ Bucle de dibujo
local camera = Workspace.CurrentCamera :: Camera
local camFocus = Vector3.new(0, CAM.FocusHeight, 34)
local minRad = (Balance.World and Balance.World.ShipRadius or 8.4) + 0.4
local limit = Balance.Sim.ArenaRadius - 3.5
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
local wasArrowMoving = false

RunService:BindToRenderStep("AresMain", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	local hrp = rootPart()

	-- Impulso RCS: el cliente mueve su personaje; el servidor ya validó el uso y el daño.
	if dash and hrp then
		local D = Balance.Skills.Dash
		local step = math.min(dash.left, D.Distance / D.Duration * dt)
		local target = hrp.Position + dash.dir * step
		local flatLen = math.sqrt(target.X * target.X + target.Z * target.Z)
		local blocked = flatLen > limit or flatLen < minRad
		if not blocked then
			hrp.CFrame = hrp.CFrame + dash.dir * step
			hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
		end
		dash.left -= step
		if dash.left <= 0 or blocked then
			dash = nil
		end
	end

	-- Mantiene al jugador dentro del cráter jugable y fuera del collider de la nave.
	if hrp and inRun() then
		local p = hrp.Position
		local flat = math.sqrt(p.X * p.X + p.Z * p.Z)
		if flat > limit or flat < minRad then
			local nx = if flat > 0.01 then p.X / flat else 0
			local nz = if flat > 0.01 then p.Z / flat else 1
			local rad = if flat > limit then limit else minRad
			local rot = hrp.CFrame - hrp.CFrame.Position
			hrp.CFrame = CFrame.new(nx * rad, math.clamp(p.Y, 1.5, 40), nz * rad) * rot
			hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(0, hrp.AssemblyLinearVelocity.Y), 0)
		end
	end

	updateAdaptiveQuality(dt)
	Fx.update(dt)
	Fx.kickUpdate(dt)
	Scenery.update(dt)
	Renderer.update(dt)
	Ui.tickIcons(dt)
	local nc, ncTier = Renderer.nearestChest()
	Hud.update(dt, if inRun() then nc else nil, if inRun() then ncTier else nil)

	local locked = inRun() and not Hud.wantsCursor() and Hud.getInputMode() == "kb" and UserInputService.MouseEnabled
	UserInputService.MouseBehavior = if locked then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not locked

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = Hud.settings.fov

	if phase == "menu" then
		if wasArrowMoving then
			player:Move(Vector3.zero, true)
			wasArrowMoving = false
		end
		-- Órbita lenta alrededor de la nave; nave y logo NASA quedan despejados a la derecha del menú.
		menuYaw += dt * 0.06
		local ship = Scenery.shipPosition()
		local eye = ship + Vector3.new(math.sin(menuYaw) * 60, 17, math.cos(menuYaw) * 60)
		local cf = CFrame.lookAt(eye, ship + Vector3.new(0, 11, 0))
		camera.CFrame = cf * CFrame.new(-14, 0, 0)
		return
	end
	if phase == "victory" then
		if wasArrowMoving then
			player:Move(Vector3.zero, true)
			wasArrowMoving = false
		end
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

	if hrp and inRun() and not Hud.wantsCursor() and not UserInputService:GetFocusedTextBox() then
		local arrowUp = UserInputService:IsKeyDown(Enum.KeyCode.Up)
		local arrowDown = UserInputService:IsKeyDown(Enum.KeyCode.Down)
		local arrowLeft = UserInputService:IsKeyDown(Enum.KeyCode.Left)
		local arrowRight = UserInputService:IsKeyDown(Enum.KeyCode.Right)
		local arrowActive = arrowUp or arrowDown or arrowLeft or arrowRight
		if arrowActive or wasArrowMoving then
			local kx = (if UserInputService:IsKeyDown(Enum.KeyCode.D) or arrowRight then 1 else 0)
				- (if UserInputService:IsKeyDown(Enum.KeyCode.A) or arrowLeft then 1 else 0)
			local kz = (if UserInputService:IsKeyDown(Enum.KeyCode.S) or arrowDown then 1 else 0)
				- (if UserInputService:IsKeyDown(Enum.KeyCode.W) or arrowUp then 1 else 0)
			player:Move(Vector3.new(kx, 0, kz), true)
			wasArrowMoving = arrowActive
		end
	elseif wasArrowMoving then
		player:Move(Vector3.zero, true)
		wasArrowMoving = false
	end
end)
