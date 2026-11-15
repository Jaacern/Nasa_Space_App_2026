--!strict
-- Sistema de diseño "Dark Telemetry": consola de control de misión.
-- Reglas: texto base >= 18 px (>= 14 px con la escala mínima 0,8), botones >= 44 px,
-- contraste >= 4,5:1 sobre el panel, transiciones de 150 a 250 ms, sin emojis como iconos.

local TweenService = game:GetService("TweenService")

local Ui = {}

Ui.Theme = {
	bg = Color3.fromHex("#070B14"),
	panel = Color3.fromHex("#0B132B"),
	panelHi = Color3.fromHex("#13204A"),
	line = Color3.fromHex("#1F3A6B"),
	cyan = Color3.fromHex("#00B4D8"),
	cyanHi = Color3.fromHex("#00D2FF"),
	orange = Color3.fromHex("#FF6B35"),
	gold = Color3.fromHex("#FFC828"),
	red = Color3.fromHex("#FF2D55"),
	green = Color3.fromHex("#50E696"),
	violet = Color3.fromHex("#B48CFF"),
	text = Color3.fromHex("#F8FAFC"),
	dim = Color3.fromHex("#9FB0CC"),
}
Ui.Theme.rarity = { Ui.Theme.dim, Ui.Theme.cyanHi, Ui.Theme.violet, Ui.Theme.gold }

-- Tipografías incluidas en Roblox, con jerarquía aeroespacial y trazos marcados (verificadas en Studio).
local MICHROMA = "rbxasset://fonts/families/Michroma.json"
local SARPANCH = "rbxasset://fonts/families/Sarpanch.json"
local JURA = "rbxasset://fonts/families/Jura.json"
local BUILDER = "rbxasset://fonts/families/BuilderSans.json"
local MONO = "rbxasset://fonts/families/RobotoMono.json"
Ui.Fonts = {
	title = Font.new(MICHROMA),
	display = Font.new(SARPANCH, Enum.FontWeight.Bold),
	hero = Font.new(SARPANCH, Enum.FontWeight.ExtraBold),
	bold = Font.new(BUILDER, Enum.FontWeight.Bold),
	semi = Font.new(JURA, Enum.FontWeight.SemiBold),
	body = Font.new(JURA, Enum.FontWeight.Medium),
	mono = Font.new(MONO, Enum.FontWeight.Medium),
	monoBold = Font.new(MONO, Enum.FontWeight.Bold),
	impact = Font.new("rbxasset://fonts/families/Bangers.json"), -- rotulos de momento fuerte
}

-- Escala de capas.
Ui.Z = { hud = 2, hudTop = 4, vignette = 8, overlay = 10, panel = 11, content = 12, top = 13 }

local FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Ui.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		for k, v in props do
			(inst :: any)[k] = v
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	return inst
end

function Ui.corner(radius: number): UICorner
	return Ui.new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

function Ui.stroke(color: Color3, thickness: number?, transparency: number?): UIStroke
	return Ui.new("UIStroke", { Color = color, Thickness = thickness or 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function Ui.label(text: string, size: number, props: { [string]: any }?): TextLabel
	local l = Ui.new("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size, FontFace = Ui.Fonts.body, TextColor3 = Ui.Theme.text,
		TextStrokeColor3 = Color3.fromRGB(4, 8, 18), TextStrokeTransparency = 0.62,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, size + 8),
	})
	if props then
		for k, v in props do
			(l :: any)[k] = v
		end
	end
	return l
end

-- Esquinas de encuadre, como en una consola de telemetría.
local function brackets(parent: Instance, color: Color3, z: number)
	local L, T = 14, 2
	local specs = {
		{ Vector2.new(0, 0), UDim2.fromOffset(0, 0) },
		{ Vector2.new(1, 0), UDim2.new(1, 0, 0, 0) },
		{ Vector2.new(0, 1), UDim2.new(0, 0, 1, 0) },
		{ Vector2.new(1, 1), UDim2.new(1, 0, 1, 0) },
	}
	for _, s in specs do
		for k = 1, 2 do
			local f = Instance.new("Frame")
			f.AnchorPoint = s[1] :: Vector2
			f.Position = s[2] :: UDim2
			f.Size = if k == 1 then UDim2.fromOffset(L, T) else UDim2.fromOffset(T, L)
			f.BackgroundColor3 = color
			f.BorderSizePixel = 0
			f.ZIndex = z
			f.Parent = parent
		end
	end
end

-- Panel base. tag = etiqueta técnica opcional en la cabecera; TagColor en props tiñe acento y cabecera.
function Ui.panel(props: { [string]: any }?, tag: string?): Frame
	local tagColor: Color3? = if props and props.TagColor then props.TagColor :: Color3 else nil
	local accent = tagColor or Ui.Theme.cyanHi
	local f = Ui.new("Frame", { BackgroundColor3 = Ui.Theme.panel, BackgroundTransparency = 0.05, BorderSizePixel = 0 })
	Ui.corner(4).Parent = f
	Ui.stroke(tagColor or Ui.Theme.cyan, 1.4, 0.35).Parent = f
	if props then
		for k, v in props do
			if k ~= "TagColor" then
				(f :: any)[k] = v
			end
		end
	end
	brackets(f, accent, f.ZIndex + 1)
	if tag then
		local bar = Ui.new("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(4, 16), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = f.ZIndex + 1 })
		bar.Parent = f
		Ui.label(tag, 17, { FontFace = Ui.Fonts.display, TextColor3 = accent, TextStrokeColor3 = Color3.fromRGB(3, 6, 14), TextStrokeTransparency = 0.38, Position = UDim2.fromOffset(22, 6), Size = UDim2.new(1, -34, 0, 24), ZIndex = f.ZIndex + 1, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd }).Parent = f
	end
	return f
end

-- Botón >= 44 px. kind: "primary" | "ghost" | "danger" | "gold" | "violet" | "green".
function Ui.button(text: string, onClick: () -> (), props: { [string]: any }?, kind: string?): TextButton
	local T = Ui.Theme
	local k = kind or "primary"
	local base = if k == "primary" then T.cyanHi
		elseif k == "danger" then T.orange
		elseif k == "gold" then T.gold
		elseif k == "violet" then T.violet
		elseif k == "green" then T.green
		else T.panelHi
	local hover = if k == "ghost" then T.line else base:Lerp(Color3.new(1, 1, 1), 0.25)
	local b = Ui.new("TextButton", {
		Text = text, TextSize = 20, FontFace = Ui.Fonts.bold, TextColor3 = if k == "ghost" then T.text else T.bg, AutoButtonColor = false,
		BackgroundColor3 = base, BorderSizePixel = 0, Size = UDim2.fromOffset(300, 54), TextWrapped = true,
	})
	Ui.corner(6).Parent = b
	if k == "ghost" then
		Ui.stroke(T.cyan, 1.2, 0.25).Parent = b
	else
		Ui.stroke(Color3.new(1, 1, 1), 1, 0.72).Parent = b
	end
	if props then
		for key, v in props do
			(b :: any)[key] = v
		end
	end
	b:SetAttribute("Base", base)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, FAST, { BackgroundColor3 = hover }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, FAST, { BackgroundColor3 = b:GetAttribute("Base") }):Play()
	end)
	b.SelectionGained:Connect(function()
		TweenService:Create(b, FAST, { BackgroundColor3 = hover }):Play()
	end)
	b.SelectionLost:Connect(function()
		TweenService:Create(b, FAST, { BackgroundColor3 = b:GetAttribute("Base") }):Play()
	end)
	b.Activated:Connect(onClick)
	return b
end

function Ui.setButtonColor(b: TextButton, color: Color3)
	b:SetAttribute("Base", color)
	b.BackgroundColor3 = color
end

-- Barra de progreso. Devuelve (fondo, relleno).
function Ui.bar(parent: Instance, pos: UDim2, size: UDim2, color: Color3, z: number?): (Frame, Frame)
	local back = Ui.new("Frame", { Position = pos, Size = size, BackgroundColor3 = Ui.Theme.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = z or 1 })
	Ui.corner(2).Parent = back
	Ui.stroke(Ui.Theme.line, 1, 0).Parent = back
	local fill = Ui.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = (z or 1) + 1 })
	Ui.corner(2).Parent = fill
	fill.Parent = back
	back.Parent = parent
	return back, fill
end

function Ui.list(padding: number, horizontal: boolean?, align: Enum.HorizontalAlignment?, valign: Enum.VerticalAlignment?): UIListLayout
	return Ui.new("UIListLayout", {
		Padding = UDim.new(0, padding), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Center,
		VerticalAlignment = valign or Enum.VerticalAlignment.Center,
	})
end

function Ui.pad(px: number, top: number?): UIPadding
	return Ui.new("UIPadding", { PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px), PaddingTop = UDim.new(0, top or px), PaddingBottom = UDim.new(0, px) })
end

-- Aparición breve (180 ms): el panel crece de 0,94 a 1.
function Ui.pop(frame: GuiObject, instant: boolean?)
	local s = frame:FindFirstChild("Pop") :: UIScale?
	if not s then
		local created = Instance.new("UIScale")
		created.Name = "Pop"
		created.Parent = frame
		s = created
	end
	local scale = s :: UIScale
	local target = (frame:GetAttribute("Fit") :: number?) or 1
	if instant then
		scale.Scale = target
		return
	end
	scale.Scale = 0.94 * target
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
end

function Ui.tween(inst: Instance, time: number, goal: { [string]: any })
	TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function vpPart(wm: WorldModel, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, trans: number?): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = trans or 0
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Parent = wm
	return p
end

local spinWidgets: { { rig: Model, base: CFrame, speed: number, angle: number, vp: ViewportFrame } } = {}

-- Icono 3D interactivo para habilidades y equipo (ViewportFrame con WorldModel; sin assets externos).
function Ui.skillIcon3D(kind: string, px: number, accent: Color3?, spinSpeed: number?): ViewportFrame
	local T = Ui.Theme
	local glow = accent or T.cyanHi
	local vp = Ui.new("ViewportFrame", {
		Size = UDim2.fromOffset(px, px),
		BackgroundColor3 = Color3.fromHex("#091428"),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(165, 195, 235),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1.2, -0.9),
	}) :: ViewportFrame
	Ui.corner(6).Parent = vp
	Ui.stroke(glow, 1.2, 0.35).Parent = vp

	local wm = Instance.new("WorldModel")
	wm.Parent = vp
	local rig = Instance.new("Model")
	local pivot = Instance.new("Part")
	pivot.Size = Vector3.new(0.2, 0.2, 0.2)
	pivot.Transparency = 1
	pivot.Anchored = true
	pivot.CanCollide = false
	pivot.CFrame = CFrame.identity
	pivot.Parent = rig
	rig.PrimaryPart = pivot
	rig.Parent = wm

	local steel = Color3.fromRGB(150, 174, 210)
	local dark = Color3.fromRGB(48, 60, 88)
	local baseRot = CFrame.Angles(math.rad(14), math.rad(28), math.rad(-10))

	if kind == "laser" then
		vpPart(wm, Enum.PartType.Block, Vector3.new(0.95, 0.72, 2.2), CFrame.new(0, 0, 0.25), dark, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Cylinder, Vector3.new(1.8, 0.42, 0.42), CFrame.new(0, 0.14, -0.75) * CFrame.Angles(0, math.rad(90), 0), steel, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Block, Vector3.new(1.2, 0.28, 0.8), CFrame.new(0, 0.12, -0.15), glow, Enum.Material.Neon).Parent = rig
		vpPart(wm, Enum.PartType.Ball, Vector3.new(0.68, 0.68, 0.68), CFrame.new(0, 0.14, -1.55), glow, Enum.Material.Neon).Parent = rig
		vpPart(wm, Enum.PartType.Block, Vector3.new(0.32, 0.95, 0.8), CFrame.new(0, -0.45, 0.55) * CFrame.Angles(math.rad(18), 0, 0), dark, Enum.Material.Metal).Parent = rig
	elseif kind == "spread" then
		vpPart(wm, Enum.PartType.Block, Vector3.new(1.65, 0.65, 1.5), CFrame.new(0, 0, 0.35), dark, Enum.Material.Metal).Parent = rig
		for _, a in { -22, 0, 22 } do
			local cf = CFrame.new(math.sin(math.rad(a)) * 0.55, 0.12, -0.72) * CFrame.Angles(0, math.rad(90 + a), 0)
			vpPart(wm, Enum.PartType.Cylinder, Vector3.new(1.3, 0.28, 0.28), cf, steel, Enum.Material.Metal).Parent = rig
			vpPart(wm, Enum.PartType.Ball, Vector3.new(0.44, 0.44, 0.44), CFrame.new(math.sin(math.rad(a)) * 0.92, 0.12, -1.32), glow, Enum.Material.Neon).Parent = rig
		end
	elseif kind == "mortar" then
		vpPart(wm, Enum.PartType.Cylinder, Vector3.new(1.3, 1.35, 1.35), CFrame.new(0, 0.05, 0.25) * CFrame.Angles(0, math.rad(90), 0), dark, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Cylinder, Vector3.new(1.65, 0.95, 0.95), CFrame.new(0, 0.28, -0.65) * CFrame.Angles(0, math.rad(90), 0), steel, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Ball, Vector3.new(0.92, 0.92, 0.92), CFrame.new(0, 0.32, -1.38), glow, Enum.Material.Neon).Parent = rig
		vpPart(wm, Enum.PartType.Block, Vector3.new(1.85, 0.28, 0.7), CFrame.new(0, -0.58, 0.15), dark, Enum.Material.Metal).Parent = rig
	elseif kind == "dash" then
		vpPart(wm, Enum.PartType.Cylinder, Vector3.new(1.7, 0.72, 0.72), CFrame.new(-0.55, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), steel, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Cylinder, Vector3.new(1.7, 0.72, 0.72), CFrame.new(0.55, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), steel, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Block, Vector3.new(1.5, 0.6, 0.9), CFrame.new(0, 0.1, 0.05), dark, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Ball, Vector3.new(0.85, 0.85, 0.85), CFrame.new(-0.55, -0.95, 0), glow, Enum.Material.Neon).Parent = rig
		vpPart(wm, Enum.PartType.Ball, Vector3.new(0.85, 0.85, 0.85), CFrame.new(0.55, -0.95, 0), glow, Enum.Material.Neon).Parent = rig
		vpPart(wm, Enum.PartType.Block, Vector3.new(0.45, 1.1, 0.45), CFrame.new(0, -1.15, 0), Color3.fromRGB(255, 220, 120), Enum.Material.Neon).Parent = rig
	elseif kind == "shield" then
		vpPart(wm, Enum.PartType.Ball, Vector3.new(1.85, 1.85, 1.85), CFrame.identity, glow, Enum.Material.ForceField, 0.18).Parent = rig
		vpPart(wm, Enum.PartType.Ball, Vector3.new(1.05, 1.05, 1.05), CFrame.identity, glow, Enum.Material.Neon, 0.35).Parent = rig
		vpPart(wm, Enum.PartType.Cylinder, Vector3.new(0.24, 2.35, 2.35), CFrame.Angles(math.rad(68), math.rad(20), 0), Color3.fromRGB(160, 245, 255), Enum.Material.Neon, 0.2).Parent = rig
		vpPart(wm, Enum.PartType.Cylinder, Vector3.new(0.22, 2.25, 2.25), CFrame.Angles(math.rad(-58), math.rad(-25), 0), steel, Enum.Material.Metal).Parent = rig
	else -- cofre / módulo de suministros
		vpPart(wm, Enum.PartType.Block, Vector3.new(1.8, 1.25, 1.35), CFrame.new(0, -0.1, 0), dark, Enum.Material.Metal).Parent = rig
		vpPart(wm, Enum.PartType.Block, Vector3.new(1.9, 0.3, 1.42), CFrame.new(0, 0.38, 0), glow, Enum.Material.Neon).Parent = rig
		vpPart(wm, Enum.PartType.Block, Vector3.new(0.42, 0.55, 1.48), CFrame.new(0, 0.15, 0), steel, Enum.Material.Metal).Parent = rig
	end

	rig:PivotTo(baseRot)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 38
	cam.CFrame = CFrame.lookAt(Vector3.new(2.7, 2.0, 3.1), Vector3.zero)
	cam.Parent = vp
	vp.CurrentCamera = cam

	table.insert(spinWidgets, { rig = rig, base = baseRot, speed = spinSpeed or 0.9, angle = 0, vp = vp })
	return vp
end

-- Icono geométrico nítido para botones de navegación (Pausa, Menú, Guardar, Audio, Ayuda, Perfiles).
function Ui.navGlyph(kind: string, px: number, color: Color3?): Frame
	local c = color or Ui.Theme.text
	local box = Ui.new("Frame", { Size = UDim2.fromOffset(px, px), BackgroundTransparency = 1 })
	local function bar(x: number, y: number, w: number, h: number, rot: number?, rad: number?)
		local f = Ui.new("Frame", {
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(w, h),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rot or 0,
			BackgroundColor3 = c,
			BorderSizePixel = 0,
		})
		if rad and rad > 0 then
			Ui.corner(rad).Parent = f
		end
		f.Parent = box
	end
	if kind == "pause" then
		bar(0.34, 0.5, 0.22, 0.72, 0, 2)
		bar(0.66, 0.5, 0.22, 0.72, 0, 2)
	elseif kind == "play" then
		local t = Ui.label("▶", math.max(12, math.round(px * 0.85)), { FontFace = Ui.Fonts.bold, TextColor3 = c, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), TextStrokeTransparency = 1 })
		t.Parent = box
	elseif kind == "menu" then
		bar(0.5, 0.24, 0.76, 0.14, 0, 2)
		bar(0.5, 0.50, 0.76, 0.14, 0, 2)
		bar(0.5, 0.76, 0.76, 0.14, 0, 2)
	elseif kind == "save" then
		bar(0.5, 0.5, 0.76, 0.76, 0, 2)
		local inner = Ui.new("Frame", { Position = UDim2.fromScale(0.5, 0.28), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(0.46, 0.24), BackgroundColor3 = Ui.Theme.bg, BorderSizePixel = 0 })
		inner.Parent = box
	elseif kind == "audio" then
		bar(0.28, 0.5, 0.22, 0.36, 0, 1)
		bar(0.48, 0.5, 0.22, 0.62, 0, 1)
		bar(0.76, 0.38, 0.14, 0.26, 25, 2)
		bar(0.76, 0.62, 0.14, 0.26, -25, 2)
	elseif kind == "profiles" then
		bar(0.5, 0.32, 0.34, 0.34, 0, 12)
		bar(0.5, 0.74, 0.68, 0.28, 0, 6)
	elseif kind == "cursor" then
		bar(0.5, 0.5, 0.76, 0.14, 0, 2)
		bar(0.5, 0.5, 0.14, 0.76, 0, 2)
		bar(0.5, 0.5, 0.34, 0.34, 0, 10)
	else -- help / info
		bar(0.5, 0.24, 0.18, 0.18, 0, 8)
		bar(0.5, 0.60, 0.18, 0.44, 0, 2)
	end
	return box
end

function Ui.tickIcons(dt: number)
	for i = #spinWidgets, 1, -1 do
		local w = spinWidgets[i]
		if not w.vp.Parent then
			table.remove(spinWidgets, i)
		elseif w.vp.Visible then
			w.angle += dt * w.speed
			w.rig:PivotTo(CFrame.Angles(0, w.angle, 0) * w.base)
		end
	end
end

function Ui.time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

function Ui.num(v: number): string
	if math.abs(v - math.round(v)) < 0.05 then
		return tostring(math.round(v))
	end
	return string.format("%.1f", v)
end

return Ui
