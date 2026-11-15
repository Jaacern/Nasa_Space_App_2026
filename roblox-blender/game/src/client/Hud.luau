--!strict
-- Interfaz completa: HUD de misión, menú, hangar, ajustes, créditos, cartas de nivel, pieza, pausa y resumen.
-- Estilo: consola de control de misión (ver Ui.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Balance)
local Content = require(ReplicatedStorage.Shared.Content)
local NasaData = require(ReplicatedStorage.Shared.NasaData)
local Ui = require(script.Parent.Ui)
local Fx = require(script.Parent.Fx)

local Hud = {}

local T, F, Z = Ui.Theme, Ui.Fonts, Ui.Z
local new, label, panel, button = Ui.new, Ui.label, Ui.panel, Ui.button
local CENTER = Enum.TextXAlignment.Center
local RIGHT = Enum.TextXAlignment.Right
local TOP = Enum.TextYAlignment.Top

local BIOME_COLORS = { T.orange, T.cyanHi, T.gold }
local META_COLORS: { [string]: Color3 } = {
	dmg = T.orange,
	hp = T.green,
	armor = T.green,
	revive = T.green,
	speed = T.cyanHi,
	magnet = T.cyanHi,
	xp = T.violet,
	luck = T.violet,
}

Hud.settings = { fov = Balance.Camera.Fov, sens = 1, lowFx = false }

local send: (...any) -> () = function() end
local useSkill: (number) -> () = function() end
local onSettings: () -> () = function() end
local gui: ScreenGui
local uiScale: UIScale
local r: { [string]: any } = {}
local phase = "menu"
local meta: any = nil
local lastMode = "full"
local alertT, toastT, vignette, hintT = 0, 0, 0, 0
local tickerT, tickerI = 0, 0
local tickerLines = NasaData.tickerLines()
local choiceOpen = false
local bossName = ""
local overlays: { Frame } = {}
local fitPanels: { { p: GuiObject, w: number, h: number } } = {}
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function click(fn: () -> ()): () -> ()
	return function()
		Fx.play("ui")
		fn()
	end
end

local function overlay(name: string, dim: number?): Frame
	local f = new("Frame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BackgroundTransparency = dim or 0.3, BorderSizePixel = 0, Visible = false, ZIndex = Z.overlay })
	f.Parent = gui
	table.insert(overlays, f)
	return f
end

local function centerPanel(parent: Instance, w: number, h: number, tag: string?, tagColor: Color3?): Frame
	local p = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(w, h), ZIndex = Z.panel, BackgroundTransparency = 0.04, TagColor = tagColor }, tag)
	p.Name = "Panel"
	p.Parent = parent
	table.insert(fitPanels, { p = p, w = w, h = h })
	return p
end

local function show(f: Frame, on: boolean)
	if on and not f.Visible then
		local p = f:FindFirstChild("Panel")
		if p then
			Ui.pop(p :: GuiObject)
		end
	end
	f.Visible = on
end

-- ---------------------------------------------------------------- HUD de misión
local function buildHud()
	local h = new("Frame", { Name = "Hud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	h.Parent = gui
	r.hud = h

	local _, xpFill = Ui.bar(h, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 10), T.cyanHi, Z.hud)
	r.xpFill = xpFill
	local lvlChip = panel({ Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(136, 36), ZIndex = Z.hud, TagColor = T.gold })
	lvlChip.Parent = h
	r.lvl = label("NIVEL 1", 24, { FontFace = F.impact, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.hudTop })
	r.lvl.Parent = lvlChip

	local suit = panel({ Position = UDim2.fromOffset(16, 62), Size = UDim2.fromOffset(340, 100), ZIndex = Z.hud }, "ESTADO DEL TRAJE")
	suit.Parent = h
	local hpBack, hpFill = Ui.bar(suit, UDim2.fromOffset(12, 36), UDim2.fromOffset(316, 26), T.green, Z.hud)
	r.hpFill = hpFill
	r.shieldFill = new("Frame", { Size = UDim2.fromScale(0, 0.28), BackgroundColor3 = T.cyanHi, BorderSizePixel = 0, ZIndex = Z.hudTop })
	r.shieldFill.Parent = hpBack
	r.hpText = label("100 / 100", 18, { FontFace = F.monoBold, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, ZIndex = Z.hudTop + 1, TextStrokeTransparency = 0.35 })
	r.hpText.Parent = hpBack
	r.kills = label("BAJAS 0", 18, { FontFace = F.mono, Position = UDim2.fromOffset(12, 68), Size = UDim2.fromOffset(150, 24), TextColor3 = T.text, ZIndex = Z.hudTop })
	r.kills.Parent = suit
	label("SOPORTE VITAL", 18, { FontFace = F.mono, Position = UDim2.fromOffset(164, 68), Size = UDim2.fromOffset(164, 24), TextXAlignment = RIGHT, TextColor3 = T.green, ZIndex = Z.hudTop }).Parent = suit

	r.wave = label("OLEADA 01/18", 34, { Name = "Wave", FontFace = F.impact, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(420, 40), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeTransparency = 0.15, ZIndex = Z.hud })
	r.wave.Parent = h
	r.timer = label("T+ 00:00", 22, { Name = "Timer", FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54), Size = UDim2.fromOffset(240, 26), TextXAlignment = CENTER, TextColor3 = T.cyanHi, TextStrokeTransparency = 0.3, ZIndex = Z.hud })
	r.timer.Parent = h
	r.biome = label("ETAPA 1 · " .. Content.Biomes[1].name, 18, { Name = "Biome", FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 82), Size = UDim2.fromOffset(480, 24), TextXAlignment = CENTER, TextColor3 = BIOME_COLORS[1], TextStrokeTransparency = 0.25, ZIndex = Z.hud })
	r.biome.Parent = h

	local bossWrap = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.new(0.42, 0, 0, 52), BackgroundTransparency = 1, Visible = false })
	bossWrap.Parent = h
	r.bossWrap = bossWrap
	r.bossName = label("", 20, { FontFace = F.bold, TextColor3 = T.orange, TextXAlignment = CENTER, Size = UDim2.new(1, 0, 0, 24), TextStrokeTransparency = 0.3, ZIndex = Z.hud })
	r.bossName.Parent = bossWrap
	local _, bossFill = Ui.bar(bossWrap, UDim2.fromOffset(0, 28), UDim2.new(1, 0, 0, 16), T.red, Z.hud)
	r.bossFill = bossFill

	-- Piezas de la nave
	local ship = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 18), Size = UDim2.fromOffset(368, 92), ZIndex = Z.hud }, "NAVE · PIEZAS RECUPERADAS")
	ship.Parent = h
	r.pieces = {}
	for i = 1, 4 do
		local cell = new("TextLabel", {
			Position = UDim2.fromOffset(12 + (i - 1) * 87, 38), Size = UDim2.fromOffset(82, 42), BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
			Text = Content.Pieces[i].short, TextSize = 18, FontFace = F.monoBold, TextColor3 = T.dim, BorderSizePixel = 0, ZIndex = Z.hudTop,
		})
		Ui.corner(2).Parent = cell
		Ui.stroke(T.line, 1, 0).Parent = cell
		cell.Parent = ship
		r.pieces[i] = cell
	end
	r.pauseBtn = button("II", click(function()
		send("pause")
	end), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 118), Size = UDim2.fromOffset(52, 46), ZIndex = Z.hudTop, FontFace = F.monoBold }, "ghost")
	r.pauseBtn.Parent = h
	r.exitBtn = button("SALIR", click(function()
		send("menu")
	end), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 118), Size = UDim2.fromOffset(130, 46), ZIndex = Z.hudTop, Visible = false }, "danger")
	r.exitBtn.Parent = h

	-- Habilidades
	r.skills = {}
	for i = 1, 2 do
		local sk = Content.Skills[i]
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24 - (2 - i) * 112, 1, -(touch and 160 or 28)), Size = UDim2.fromOffset(100, 100),
			BackgroundColor3 = T.panel, BackgroundTransparency = 0.1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = Z.hud,
		})
		Ui.corner(50).Parent = b
		local stroke = Ui.stroke(T.cyanHi, 2.5, 0)
		stroke.Parent = b
		label(sk.short, 20, { FontFace = F.bold, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 26), TextColor3 = T.cyanHi, ZIndex = Z.hudTop }).Parent = b
		label(if touch then "" else "[" .. sk.key .. "]", 18, { FontFace = F.mono, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 22), TextColor3 = T.dim, ZIndex = Z.hudTop }).Parent = b
		local cdOverlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false, ZIndex = Z.hudTop + 1 })
		Ui.corner(50).Parent = cdOverlay
		cdOverlay.Parent = b
		local cdText = label("", 28, { FontFace = F.monoBold, TextXAlignment = CENTER, Size = UDim2.fromScale(1, 1), ZIndex = Z.hudTop + 2 })
		cdText.Parent = cdOverlay
		b.Activated:Connect(function()
			useSkill(i)
		end)
		b.Parent = h
		r.skills[i] = { button = b, overlay = cdOverlay, text = cdText, stroke = stroke, ready = true }
	end

	-- Telemetría (datos NASA)
	local ticker = panel({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -(touch and 180 or 20)), Size = UDim2.fromOffset(470, 66), ZIndex = Z.hud }, "TELEMETRÍA · NASA DONKI · COPIA LOCAL")
	ticker.Parent = h
	r.ticker = label("", 18, { FontFace = F.mono, Position = UDim2.fromOffset(12, 34), Size = UDim2.fromOffset(446, 24), ZIndex = Z.hudTop, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	r.ticker.Parent = ticker

	r.alert = label("", 44, { FontFace = F.impact, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.24), Size = UDim2.new(0.9, 0, 0, 52), TextXAlignment = CENTER, TextColor3 = T.orange, TextStrokeTransparency = 0.25, TextTransparency = 1, ZIndex = Z.hudTop })
	r.alert.Parent = h
	r.alertSub = label("", 20, { FontFace = F.semi, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.24, 44), Size = UDim2.new(0.9, 0, 0, 28), TextXAlignment = CENTER, TextStrokeTransparency = 0.25, TextTransparency = 1, ZIndex = Z.hudTop })
	r.alertSub.Parent = h

	local tut = panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(640, 96), Visible = false, ZIndex = Z.hud }, "TUTORIAL 1/8")
	tut.Parent = h
	r.tut = tut
	r.tutText = label("", 20, { FontFace = F.semi, Position = UDim2.fromOffset(14, 34), Size = UDim2.fromOffset(612, 54), ZIndex = Z.hudTop, TextYAlignment = TOP })
	r.tutText.Parent = tut

	r.hint = label(Content.Controls, 18, { FontFace = F.mono, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.new(0.5, 0, 0, 48), TextXAlignment = CENTER, TextColor3 = T.text, TextStrokeTransparency = 0.3, Visible = false, ZIndex = Z.hud })
	r.hint.Parent = h

	r.arrow = label("▲", 40, { FontFace = F.bold, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(48, 48), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeTransparency = 0.2, Visible = false, ZIndex = Z.hud })
	r.arrow.Parent = h

	local toast = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 176), Size = UDim2.fromOffset(380, 168), Visible = false, ZIndex = Z.hud }, "OBJETO RECUPERADO")
	toast.Parent = h
	r.toast = toast
	r.toastRar = label("", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 32), Size = UDim2.fromOffset(350, 22), ZIndex = Z.hudTop })
	r.toastRar.Parent = toast
	r.toastName = label("", 22, { FontFace = F.bold, Position = UDim2.fromOffset(14, 54), Size = UDim2.fromOffset(350, 26), ZIndex = Z.hudTop })
	r.toastName.Parent = toast
	r.toastDesc = label("", 18, { FontFace = F.semi, Position = UDim2.fromOffset(14, 80), Size = UDim2.fromOffset(350, 24), TextColor3 = T.gold, ZIndex = Z.hudTop })
	r.toastDesc.Parent = toast
	r.toastFact = label("", 18, { Position = UDim2.fromOffset(14, 104), Size = UDim2.fromOffset(350, 58), TextColor3 = T.dim, TextYAlignment = TOP, TextScaled = true, ZIndex = Z.hudTop })
	new("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 18 }).Parent = r.toastFact
	r.toastFact.Parent = toast

	r.vignette = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.red, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = Z.vignette, Active = false })
	r.vignette.Parent = gui
end

-- ---------------------------------------------------------------- Menú principal
local function stepper(parent: Instance, y: number, title: string, get: () -> string, dec: () -> (), inc: () -> ())
	label(title, 20, { FontFace = F.semi, Position = UDim2.fromOffset(24, y), Size = UDim2.fromOffset(320, 46), ZIndex = Z.content }).Parent = parent
	local value = label(get(), 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(422, y), Size = UDim2.fromOffset(118, 46), TextXAlignment = CENTER, TextColor3 = T.cyanHi, ZIndex = Z.content })
	value.Parent = parent
	button("−", click(function()
		dec()
		value.Text = get()
		onSettings()
	end), { Position = UDim2.fromOffset(362, y), Size = UDim2.fromOffset(52, 46), ZIndex = Z.content }, "ghost").Parent = parent
	button("+", click(function()
		inc()
		value.Text = get()
		onSettings()
	end), { Position = UDim2.fromOffset(548, y), Size = UDim2.fromOffset(52, 46), ZIndex = Z.content }, "ghost").Parent = parent
end

local function virtualSize(): Vector2
	local cam = Workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	return vp / uiScale.Scale
end

-- Menú principal. compact = pantallas bajas (móvil): botones en dos columnas.
local function buildMainMenu(compact: boolean)
	local old = r.menu
	local wasVisible = old ~= nil and old.Visible
	if old then
		local idx = table.find(overlays, old)
		if idx then
			table.remove(overlays, idx)
		end
		old:Destroy()
	end
	local m = new("Frame", { Name = "Menu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = wasVisible, ZIndex = Z.overlay })
	m.Parent = gui
	table.insert(overlays, m)
	r.menu = m
	r.menuCompact = compact
	-- Columna izquierda con degradado: deja ver la nave a la derecha.
	local shade = new("Frame", { Size = UDim2.new(0, 820, 1, 0), BackgroundColor3 = T.bg, BorderSizePixel = 0, ZIndex = Z.overlay })
	new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.6, 0.25), NumberSequenceKeypoint.new(1, 1) }) }).Parent = shade
	shade.Parent = m

	local X = 48
	local y: number
	if compact then
		label(Content.Title, 44, { FontFace = F.title, Position = UDim2.fromOffset(X - 3, 12), Size = UDim2.fromOffset(340, 48), TextStrokeTransparency = 0.25, ZIndex = Z.content }).Parent = m
		label(Content.Subtitle, 24, { FontFace = F.impact, Position = UDim2.fromOffset(X + 350, 20), Size = UDim2.fromOffset(360, 32), TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = m
		new("Frame", { Position = UDim2.fromOffset(X, 62), Size = UDim2.fromOffset(120, 4), BackgroundColor3 = T.orange, BorderSizePixel = 0, ZIndex = Z.content }).Parent = m
		label("ETAPA 1 · LLANURA DE REGOLITO · MARTE", 16, { FontFace = F.monoBold, Position = UDim2.fromOffset(X, 70), Size = UDim2.fromOffset(700, 22), TextColor3 = T.orange, ZIndex = Z.content, TextWrapped = false }).Parent = m
		y = 100
	else
		label("MISIÓN DE SUPERFICIE · EXPEDIENTE AF-2026", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(X, 28), Size = UDim2.fromOffset(580, 24), TextColor3 = T.cyanHi, ZIndex = Z.content }).Parent = m
		label(Content.Title, 68, { FontFace = F.title, Position = UDim2.fromOffset(X - 4, 52), Size = UDim2.fromOffset(640, 82), TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = m
		new("Frame", { Position = UDim2.fromOffset(X, 138), Size = UDim2.fromOffset(140, 4), BackgroundColor3 = T.orange, BorderSizePixel = 0, ZIndex = Z.content }).Parent = m
		label(Content.Subtitle, 32, { FontFace = F.impact, Position = UDim2.fromOffset(X, 146), Size = UDim2.fromOffset(620, 38), TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = m
		label("ETAPA 1 · LLANURA DE REGOLITO · MARTE", 16, { FontFace = F.monoBold, Position = UDim2.fromOffset(X, 186), Size = UDim2.fromOffset(620, 22), TextColor3 = T.orange, ZIndex = Z.content, TextWrapped = false }).Parent = m
		label(Content.Tagline, 18, { FontFace = F.semi, Position = UDim2.fromOffset(X, 208), Size = UDim2.fromOffset(620, 24), TextColor3 = T.text, ZIndex = Z.content }).Parent = m
		y = 240
	end

	local n = 0
	local bw, bh, gap = if compact then 340 else 440, if compact then 48 else 52, if compact then 6 else 7
	local function mb(text: string, fn: () -> (), kind: string?, sub: string?, accent: Color3?): TextButton
		local col, row = 0, n
		if compact then
			col, row = n % 2, n // 2
		end
		local bx, by = X + col * (bw + 10), y + row * (bh + gap)
		local b = button(text, click(fn), { Position = UDim2.fromOffset(bx, by), Size = UDim2.fromOffset(bw, bh), ZIndex = Z.content, TextXAlignment = Enum.TextXAlignment.Left }, kind)
		local ac = accent or (if kind == "primary" or kind == "gold" then T.gold else T.cyanHi)
		-- El texto va en una etiqueta propia: un UIPadding desplazaría también al número y al labio.
		b.Text = ""
		label(text, 19, {
			FontFace = F.bold,
			Position = UDim2.fromOffset(58, 0),
			Size = UDim2.new(1, if sub and not compact then -195 else -76, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if kind == "ghost" then T.text else T.bg,
			TextWrapped = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = Z.content + 1,
		}).Parent = b
		-- Forma humana: esquinas redondeadas, chip numérico 01..06, acento y labio inferior.
		local corner = b:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0, 10)
		end
		local stroke = b:FindFirstChildOfClass("UIStroke")
		if stroke and kind == "ghost" then
			stroke.Color = ac
			stroke.Transparency = 0.25
			stroke.Thickness = 1.4
		end
		local chip = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(40, bh - 16), BackgroundColor3 = T.bg, BackgroundTransparency = if kind == "ghost" then 0.2 else 0.35, BorderSizePixel = 0, ZIndex = Z.content + 1 })
		new("UICorner", { CornerRadius = UDim.new(0, 7) }).Parent = chip
		if kind == "ghost" then
			Ui.stroke(ac, 1, 0.45).Parent = chip
		end
		label(string.format("%02d", n + 1), 16, { FontFace = F.monoBold, TextXAlignment = CENTER, Size = UDim2.fromScale(1, 1), TextColor3 = ac, ZIndex = Z.content + 2 }).Parent = chip
		chip.Parent = b
		if kind == "primary" or kind == "gold" then
			local lip = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = if kind == "gold" then Color3.fromHex("#B07F0E") else Color3.fromHex("#0086A6"), BorderSizePixel = 0, ZIndex = Z.content })
			new("UICorner", { CornerRadius = UDim.new(0, 10) }).Parent = lip
			lip.Parent = b
		else
			local lip = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = ac, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = Z.content })
			new("UICorner", { CornerRadius = UDim.new(0, 10) }).Parent = lip
			lip.Parent = b
		end
		b.Parent = m
		if sub and not compact then
			-- el subtítulo vive dentro del botón, a la derecha y acotado para no chocar con el título
			local subLbl = label(sub, 14, { FontFace = F.monoBold, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(124, 20), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = if kind == "primary" or kind == "gold" then T.bg else ac, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
			new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = subLbl
			subLbl.Parent = b
		end
		n += 1
		return b
	end
	mb("INICIAR MISIÓN", function()
		lastMode = "full"
		send("start", "full")
	end, "primary", "18 oleadas · 17 min", T.gold)
	mb("DEMO RÁPIDA", function()
		lastMode = "demo"
		send("start", "demo")
	end, "ghost", "4 min · comprimida", T.orange)
	mb("TUTORIAL Y PRÁCTICA", function()
		send("tutorial")
	end, "gold", "7 pasos guiados", T.cyanHi)
	mb("HANGAR · MEJORAS", function()
		show(r.shop, true)
	end, "ghost", "8 mejoras", T.violet)
	mb("AJUSTES Y CONTROLES", function()
		show(r.settings, true)
	end, "ghost", "WASD · Flechas", T.green)
	mb("CRÉDITOS Y FUENTES", function()
		show(r.credits, true)
	end, "ghost", "NASA · NTRS", T.cyanHi)

	local rows = if compact then 3 else 6
	local iy = y + rows * (bh + gap) + 6
	local info = panel({ Position = UDim2.fromOffset(X, iy), Size = UDim2.fromOffset(if compact then 690 else 580, 84), ZIndex = Z.panel, TagColor = T.gold }, "REGISTRO DEL PILOTO")
	info.Parent = m
	r.menuInfo = label("", 18, { FontFace = F.mono, Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -28, 0, 48), TextYAlignment = TOP, TextColor3 = T.text, ZIndex = Z.content, TextScaled = true })
	new("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 18 }).Parent = r.menuInfo
	r.menuInfo.Parent = info
	label("Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto.", 18, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -8), Size = UDim2.fromOffset(780, 24), TextColor3 = T.dim, ZIndex = Z.content, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Right }).Parent = m
end

local function buildMenu()
	-- Hangar
	local s = overlay("Shop")
	r.shop = s
	local sp = centerPanel(s, 790, 704, "HANGAR · MEJORAS PERMANENTES", T.violet)
	label("HANGAR DE MEJORAS", 30, { FontFace = F.impact, Position = UDim2.fromOffset(24, 34), Size = UDim2.fromOffset(320, 34), TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = sp
	r.shopScience = label("", 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(348, 38), Size = UDim2.fromOffset(418, 28), TextXAlignment = RIGHT, TextColor3 = T.cyanHi, ZIndex = Z.content })
	r.shopScience.Parent = sp
	r.shopRows = {}
	for i, id in Balance.Meta.Order do
		local txt = (Content.Meta :: any)[id]
		local col = META_COLORS[id] or T.cyanHi
		local row = new("Frame", { Position = UDim2.fromOffset(24, 74 + (i - 1) * 66), Size = UDim2.new(1, -48, 0, 60), BackgroundColor3 = T.bg, BackgroundTransparency = 0.28, BorderSizePixel = 0, ZIndex = Z.panel })
		Ui.corner(4).Parent = row
		Ui.stroke(col, 1, 0.72).Parent = row
		new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = Z.content }).Parent = row
		row.Parent = sp
		label(txt.name, 20, { FontFace = F.bold, Position = UDim2.fromOffset(16, 5), Size = UDim2.fromOffset(436, 26), TextColor3 = col, ZIndex = Z.content }).Parent = row
		label(txt.desc, 18, { Position = UDim2.fromOffset(16, 31), Size = UDim2.fromOffset(436, 24), TextColor3 = T.dim, ZIndex = Z.content, TextWrapped = false }).Parent = row
		local lvl = label("0/5", 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(460, 7), Size = UDim2.fromOffset(70, 46), TextXAlignment = CENTER, TextColor3 = col, ZIndex = Z.content })
		lvl.Parent = row
		local b = button("", click(function()
			send("buy", id)
		end), { Position = UDim2.fromOffset(540, 7), Size = UDim2.fromOffset(188, 46), ZIndex = Z.content, TextSize = 18 }, "gold")
		b.Parent = row
		r.shopRows[id] = { lvl = lvl, btn = b }
	end
	button("VOLVER", click(function()
		show(r.shop, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(240, 50), ZIndex = Z.content }).Parent = sp

	-- Ajustes y Controles
	local st = overlay("Settings")
	r.settings = st
	local stp = centerPanel(st, 640, 468, "AJUSTES Y CONTROLES", T.green)
	label("AJUSTES DEL TRAJE", 28, { FontFace = F.impact, Position = UDim2.fromOffset(24, 34), Size = UDim2.fromOffset(420, 32), TextColor3 = T.green, TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = stp
	local S = Hud.settings
	stepper(stp, 74, "CAMPO DE VISIÓN", function()
		return tostring(S.fov) .. "°"
	end, function()
		S.fov = math.max(60, S.fov - 5)
	end, function()
		S.fov = math.min(100, S.fov + 5)
	end)
	stepper(stp, 126, "SENSIBILIDAD DE CÁMARA", function()
		return string.format("%.1f", S.sens)
	end, function()
		S.sens = math.max(0.4, S.sens - 0.2)
	end, function()
		S.sens = math.min(2.6, S.sens + 0.2)
	end)
	stepper(stp, 178, "EFECTOS VISUALES", function()
		return if S.lowFx then "BAJOS" else "ALTOS"
	end, function()
		S.lowFx = true
	end, function()
		S.lowFx = false
	end)
	local ctrlBox = new("Frame", { Position = UDim2.fromOffset(24, 236), Size = UDim2.new(1, -48, 0, 150), BackgroundColor3 = T.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = Z.panel })
	Ui.corner(4).Parent = ctrlBox
	Ui.stroke(T.green, 1, 0.55).Parent = ctrlBox
	ctrlBox.Parent = stp
	label("CONTROLES DE MANDO", 16, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 22), TextColor3 = T.green, ZIndex = Z.content }).Parent = ctrlBox
	local ctrlLines = {
		{ k = "WASD / FLECHAS ↑↓←→", d = "Moverse en 8 direcciones", c = T.cyanHi },
		{ k = "RATÓN / ARRASTRAR", d = "Girar cámara  ·  RUEDA : Zoom", c = T.gold },
		{ k = "ESPACIO", d = "Saltar  ·  Q : Impulso RCS  ·  E : Pulso", c = T.green },
		{ k = "1 · 2 · 3", d = "Elegir carta de mejora  ·  P : Pausa", c = T.orange },
	}
	for idx, cl in ctrlLines do
		local ly = 34 + (idx - 1) * 27
		label(cl.k, 16, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, ly), Size = UDim2.fromOffset(218, 24), TextColor3 = cl.c, ZIndex = Z.content, TextWrapped = false }).Parent = ctrlBox
		label(cl.d, 16, { FontFace = F.semi, Position = UDim2.fromOffset(238, ly), Size = UDim2.new(1, -252, 0, 24), TextColor3 = T.text, ZIndex = Z.content, TextWrapped = false }).Parent = ctrlBox
	end
	button("VOLVER", click(function()
		show(r.settings, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(240, 50), ZIndex = Z.content }).Parent = stp

	-- Créditos
	local c = overlay("Credits")
	r.credits = c
	local cp = centerPanel(c, 800, 620, "CRÉDITOS Y FUENTES", T.cyanHi)
	label("ARCHIVO DE FUENTES Y CRÉDITOS", 28, { FontFace = F.impact, Position = UDim2.fromOffset(24, 34), Size = UDim2.new(1, -48, 0, 32), TextColor3 = T.cyanHi, TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = cp
	label(table.concat(Content.Credits, "\n"), 18, { Position = UDim2.fromOffset(24, 72), Size = UDim2.new(1, -48, 1, -150), TextYAlignment = TOP, TextColor3 = T.text, LineHeight = 1.12, ZIndex = Z.content }).Parent = cp
	button("VOLVER", click(function()
		show(r.credits, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(240, 50), ZIndex = Z.content }).Parent = cp
end

-- ---------------------------------------------------------------- Cartas, pieza, pausa, resumen
local function buildOverlays()
	local lv = overlay("LevelUp", 0.35)
	r.level = lv
	r.levelTag = label("SUBIDA DE NIVEL", 18, { FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.new(0.9, 0, 0, 24), TextXAlignment = CENTER, TextColor3 = T.cyanHi, ZIndex = Z.content })
	r.levelTag.Parent = lv
	r.levelTitle = label("", 46, { FontFace = F.impact, TextColor3 = T.gold, TextStrokeTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.1, 26), Size = UDim2.new(0.9, 0, 0, 52), TextXAlignment = CENTER, ZIndex = Z.content })
	r.levelTitle.Parent = lv
	local row = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(960, 340), BackgroundTransparency = 1, ZIndex = Z.panel })
	Ui.list(22, true).Parent = row
	row.Parent = lv
	table.insert(fitPanels, { p = row, w = 980, h = 560 })
	r.cards = {}
	for i = 1, 3 do
		local card = new("TextButton", { Size = UDim2.fromOffset(304, 340), BackgroundColor3 = T.panel, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, ZIndex = Z.panel })
		Ui.corner(4).Parent = card
		local stroke = Ui.stroke(T.cyanHi, 2, 0.15)
		stroke.Parent = card
		local band = new("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T.cyanHi, BorderSizePixel = 0, ZIndex = Z.content })
		band.Parent = card
		local rar = label("", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(200, 24), ZIndex = Z.content })
		rar.Parent = card
		label(if touch then "" else "[" .. i .. "]", 18, { FontFace = F.mono, Position = UDim2.fromOffset(226, 18), Size = UDim2.fromOffset(60, 24), TextXAlignment = RIGHT, TextColor3 = T.dim, ZIndex = Z.content }).Parent = card
		local name = label("", 28, { FontFace = F.impact, Position = UDim2.fromOffset(18, 52), Size = UDim2.fromOffset(268, 66), TextStrokeTransparency = 0.25, ZIndex = Z.content, TextYAlignment = TOP })
		name.Parent = card
		local desc = label("", 20, { Position = UDim2.fromOffset(18, 120), Size = UDim2.fromOffset(268, 52), ZIndex = Z.content, TextYAlignment = TOP })
		desc.Parent = card
		local factBox = new("Frame", { Position = UDim2.fromOffset(14, 178), Size = UDim2.fromOffset(276, 86), BackgroundColor3 = T.bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = Z.content })
		Ui.corner(4).Parent = factBox
		Ui.stroke(T.cyanHi, 1, 0.65).Parent = factBox
		factBox.Parent = card
		label("DATO REAL", 13, { FontFace = F.monoBold, Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(260, 16), TextColor3 = T.cyanHi, ZIndex = Z.content + 1 }).Parent = factBox
		local fact = label("", 17, { Position = UDim2.fromOffset(8, 21), Size = UDim2.fromOffset(260, 61), TextColor3 = T.text, TextTransparency = 0.12, ZIndex = Z.content + 1, TextYAlignment = TOP, TextScaled = true })
		new("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 13 }).Parent = fact
		fact.Parent = factBox
		local lvlText = label("", 18, { FontFace = F.mono, Position = UDim2.fromOffset(18, 270), Size = UDim2.fromOffset(268, 24), TextColor3 = T.dim, ZIndex = Z.content })
		lvlText.Parent = card
		local _, lvlFill = Ui.bar(card, UDim2.fromOffset(18, 300), UDim2.fromOffset(268, 10), T.cyanHi, Z.content)
		card.MouseEnter:Connect(function()
			Ui.tween(card, 0.15, { BackgroundColor3 = T.panelHi })
		end)
		card.MouseLeave:Connect(function()
			Ui.tween(card, 0.15, { BackgroundColor3 = T.panel })
		end)
		card.Activated:Connect(function()
			Hud.pick(i)
		end)
		card.Parent = row
		r.cards[i] = { card = card, name = name, desc = desc, fact = fact, lvl = lvlText, fill = lvlFill, rar = rar, band = band, stroke = stroke }
	end

	local pc = overlay("Piece")
	r.piece = pc
	local pp = centerPanel(pc, 760, 500, "PIEZA RECUPERADA", T.gold)
	r.pieceHead = label("", 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(24, 38), Size = UDim2.new(1, -48, 0, 26), TextColor3 = T.gold, ZIndex = Z.content })
	r.pieceHead.Parent = pp
	r.pieceName = label("", 36, { FontFace = F.impact, Position = UDim2.fromOffset(24, 66), Size = UDim2.new(1, -48, 0, 46), TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.content, TextScaled = true })
	new("UITextSizeConstraint", { MinTextSize = 22, MaxTextSize = 36 }).Parent = r.pieceName
	r.pieceName.Parent = pp
	r.pieceBonus = label("", 20, { FontFace = F.bold, Position = UDim2.fromOffset(24, 118), Size = UDim2.new(1, -48, 0, 48), TextColor3 = T.gold, ZIndex = Z.content, TextYAlignment = TOP })
	r.pieceBonus.Parent = pp
	label("EN LA REALIDAD", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(24, 170), Size = UDim2.new(1, -48, 0, 22), TextColor3 = T.dim, ZIndex = Z.content }).Parent = pp
	r.pieceReal = label("", 20, { Position = UDim2.fromOffset(24, 194), Size = UDim2.new(1, -48, 0, 110), ZIndex = Z.content, TextYAlignment = TOP })
	r.pieceReal.Parent = pp
	r.pieceRef = label("", 18, { FontFace = F.mono, Position = UDim2.fromOffset(24, 310), Size = UDim2.new(1, -48, 0, 96), TextColor3 = T.cyanHi, ZIndex = Z.content, TextYAlignment = TOP })
	r.pieceRef.Parent = pp
	button("CONTINUAR", click(function()
		show(r.piece, false)
		send("continue")
		if choiceOpen then
			show(r.level, true)
		end
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(280, 54), ZIndex = Z.content }).Parent = pp

	local pa = overlay("Pause")
	r.pause = pa
	local pap = centerPanel(pa, 440, 300, "MISIÓN EN PAUSA", T.orange)
	label("PAUSA", 50, { FontFace = F.impact, TextColor3 = T.orange, TextStrokeTransparency = 0.2, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 56), ZIndex = Z.content }).Parent = pap
	button("CONTINUAR", click(function()
		send("pause")
	end), { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), ZIndex = Z.content }).Parent = pap
	button("ABANDONAR MISIÓN", click(function()
		show(r.pause, false)
		send("menu")
	end), { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 180), ZIndex = Z.content }, "danger").Parent = pap

	local su = overlay("Summary", 0.2)
	r.summary = su
	local sp = centerPanel(su, 760, 640, "INFORME DE MISIÓN", T.cyanHi)
	r.sumTitle = label("", 54, { FontFace = F.impact, TextStrokeTransparency = 0.2, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 58), ZIndex = Z.content })
	r.sumTitle.Parent = sp
	r.sumSub = label("", 20, { TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 28), TextColor3 = T.dim, ZIndex = Z.content })
	r.sumSub.Parent = sp
	r.sumKeys = label("TIEMPO DE MISIÓN\nOLEADA ALCANZADA\nNIVEL\nBAJAS\nCOFRES ABIERTOS\nPIEZAS RECUPERADAS\nDATOS CIENTÍFICOS", 20, { FontFace = F.mono, Position = UDim2.fromOffset(60, 134), Size = UDim2.fromOffset(340, 196), TextYAlignment = TOP, TextColor3 = T.dim, ZIndex = Z.content, LineHeight = 1.15 })
	r.sumKeys.Parent = sp
	r.sumVals = label("", 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(400, 134), Size = UDim2.fromOffset(300, 196), TextYAlignment = TOP, TextXAlignment = RIGHT, ZIndex = Z.content, LineHeight = 1.15 })
	r.sumVals.Parent = sp
	label("EQUIPO Y MEJORAS", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(60, 338), Size = UDim2.new(1, -120, 0, 22), TextColor3 = T.dim, ZIndex = Z.content }).Parent = sp
	r.sumItems = label("", 18, { Position = UDim2.fromOffset(60, 362), Size = UDim2.new(1, -120, 0, 180), TextYAlignment = TOP, ZIndex = Z.content, TextScaled = true })
	new("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 18 }).Parent = r.sumItems
	r.sumItems.Parent = sp
	button("REINTENTAR", click(function()
		send("start", lastMode)
	end), { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 60, 1, -18), Size = UDim2.fromOffset(310, 54), ZIndex = Z.content }).Parent = sp
	button("MENÚ", click(function()
		send("menu")
	end), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -60, 1, -18), Size = UDim2.fromOffset(310, 54), ZIndex = Z.content }, "ghost").Parent = sp
end

local refreshMeta: () -> ()

function Hud.init(sendFn: (...any) -> (), skillFn: (number) -> (), settingsFn: () -> ())
	send = sendFn
	useSkill = skillFn
	onSettings = settingsFn
	gui = new("ScreenGui", { Name = "AresHud", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5 })
	uiScale = new("UIScale", {})
	uiScale.Parent = gui
	local function rescale()
		local cam = Workspace.CurrentCamera
		local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		uiScale.Scale = math.clamp(math.min(vp.Y / 720, vp.X / 1180), 0.8, 1.8)
	end
	rescale()
	buildHud()
	buildMainMenu(virtualSize().Y < 640)
	buildMenu()
	buildOverlays()
	-- Ajusta los paneles grandes y el menú a pantallas bajas.
	local function refit()
		rescale()
		local v = virtualSize()
		for _, e in fitPanels do
			local s = math.min(1, (v.Y - 16) / e.h, (v.X - 16) / e.w)
			e.p:SetAttribute("Fit", s)
			Ui.pop(e.p, true)
		end
		local compact = v.Y < 640
		if compact ~= r.menuCompact then
			buildMainMenu(compact)
			refreshMeta()
		end
	end
	refit()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

refreshMeta = function()
	if not meta then
		return
	end
	local best = meta.best
	local info = string.format("DATOS CIENTÍFICOS %d · MISIONES %d · VICTORIAS %d\nMEJOR MARCA %s · NIVEL %d · %d BAJAS", meta.science, meta.runs, meta.wins, Ui.time(best.time), best.level, best.kills)
	if not meta.loaded then
		info = "Cargando progreso..."
	elseif meta.offline then
		info ..= "\nSIN GUARDADO: el progreso de esta sesión no se conserva."
	end
	r.menuInfo.Text = info
	r.shopScience.Text = string.format("DATOS CIENTÍFICOS DISPONIBLES: %d", meta.science)
	for _, id in Balance.Meta.Order do
		local def = (Balance.Meta :: any)[id]
		local lvl = meta.unlocks[id] or 0
		local row = r.shopRows[id]
		row.lvl.Text = string.format("%d/%d", lvl, def.max)
		if lvl >= def.max then
			row.btn.Text = "MÁXIMO"
			Ui.setButtonColor(row.btn, T.line)
			row.btn.TextColor3 = T.dim
		else
			local cost = def.cost * (lvl + 1)
			row.btn.Text = string.format("MEJORAR · %d", cost)
			local can = meta.science >= cost
			Ui.setButtonColor(row.btn, if can then T.gold else T.line)
			row.btn.TextColor3 = if can then T.bg else T.dim
		end
	end
end

function Hud.setPhase(newPhase: string, newMeta: any, extra: any)
	local keepShop = newPhase == "menu" and phase == "menu" and r.shop.Visible
	phase = newPhase
	meta = newMeta
	refreshMeta()
	local inRun = phase == "run" or phase == "tutorial"
	r.hud.Visible = inRun
	show(r.menu, phase == "menu")
	r.shop.Visible = keepShop
	r.credits.Visible = false
	r.settings.Visible = false
	r.level.Visible = false
	r.piece.Visible = false
	r.pause.Visible = false
	show(r.summary, phase == "victory" or phase == "defeat")
	choiceOpen = false
	if inRun then
		r.tut.Visible = phase == "tutorial"
		r.exitBtn.Visible = phase == "tutorial"
		r.pauseBtn.Visible = phase == "run"
		r.bossWrap.Visible = false
		r.toast.Visible = false
		r.biome.Text = if phase == "tutorial" then "ARENA DE PRÁCTICA" else ("ETAPA 1 · " .. Content.Biomes[1].name)
		r.biome.TextColor3 = if phase == "tutorial" then T.cyanHi else BIOME_COLORS[1]
		r.wave.Text = if phase == "tutorial" then "PRÁCTICA" else "OLEADA 01/" .. Balance.Run.TotalWaves
		for i = 1, 4 do
			r.pieces[i].BackgroundColor3 = T.bg
			r.pieces[i].TextColor3 = T.dim
		end
		if extra and extra.mode then
			lastMode = extra.mode
		end
		r.hint.Visible = not touch
		hintT = 14
	elseif r.summary.Visible and extra then
		local win = extra.win == true
		r.sumTitle.Text = if win then "MISIÓN CUMPLIDA" else "MISIÓN FALLIDA"
		r.sumTitle.TextColor3 = if win then T.gold else T.orange
		r.sumSub.Text = if win then "La nave despega. Vuelves a casa." else "La nave sigue esperando sus piezas. Inténtalo otra vez."
		local pieces = 0
		for i = 1, 4 do
			if extra.pieces[i] then
				pieces += 1
			end
		end
		local wave = math.min(Balance.Run.TotalWaves, extra.time // Balance.Run.WaveLength + 1)
		r.sumVals.Text = string.format("%s\n%d/%d\n%d\n%d\n%d\n%d/4\n+%d", Ui.time(extra.time), wave, Balance.Run.TotalWaves, extra.level, extra.kills, extra.chests, pieces, extra.science)
		local parts = {}
		for _, id in Balance.ItemOrder do
			local n = extra.items[id]
			if n then
				table.insert(parts, string.format("%s ×%d", (Content.Items :: any)[id].name, n))
			end
		end
		for _, id in Balance.UpgradeOrder do
			local n = extra.upgrades[id]
			if n then
				table.insert(parts, string.format("%s nv %s", (Content.Upgrades :: any)[id].name, Ui.num(n)))
			end
		end
		r.sumItems.Text = if #parts > 0 then table.concat(parts, "  ·  ") else "Nada todavía."
	end
end

function Hud.setHud(h: { number })
	local hpFrac = math.clamp(h[1] / h[2], 0, 1)
	r.hpFill.Size = UDim2.fromScale(hpFrac, 1)
	r.hpFill.BackgroundColor3 = if hpFrac > 0.5 then T.green elseif hpFrac > 0.25 then T.gold else T.red
	r.hpText.Text = string.format("%d / %d", math.max(0, h[1]), h[2])
	r.shieldFill.Size = UDim2.fromScale(math.clamp(h[3] / h[2], 0, 1), 0.28)
	r.xpFill.Size = UDim2.fromScale(math.clamp(h[4] / h[5], 0, 1), 1)
	r.lvl.Text = "NIVEL " .. h[6]
	r.kills.Text = "BAJAS " .. h[7]
	r.timer.Text = "T+ " .. Ui.time(h[8])
	for i = 1, 2 do
		local cd = h[7 + i * 2]
		local sk = r.skills[i]
		local ready = cd <= 0
		sk.overlay.Visible = not ready
		sk.text.Text = if ready then "" else tostring(math.ceil(cd))
		if ready ~= sk.ready then
			sk.ready = ready
			sk.stroke.Color = if ready then T.cyanHi else T.line
			if ready then
				Ui.pop(sk.button)
			end
		end
	end
	if h[13] >= 0 and not (r.level.Visible or r.piece.Visible) then
		r.bossWrap.Visible = true
		r.bossFill.Size = UDim2.fromScale(h[13], 1)
		r.bossName.Text = bossName
	else
		r.bossWrap.Visible = false
	end
end

function Hud.wave(n: number, total: number)
	r.wave.Text = string.format("OLEADA %02d/%d", n, total)
	Ui.pop(r.wave)
	if n > 1 then
		Hud.alert(string.format("OLEADA %d", n), "info")
	end
end

function Hud.levelUp(level: number, ids: { string }, levels: { number }, rars: { number })
	choiceOpen = true
	r.levelTitle.Text = string.format("NIVEL %d · ELIGE UNA MEJORA", level)
	for i = 1, 3 do
		local c = r.cards[i]
		local id = ids[i]
		c.card.Visible = id ~= nil
		if id then
			local txt = (Content.Upgrades :: any)[id]
			local def = (Balance.Upgrades :: any)[id]
			local rar = rars[i] or 1
			local color = T.rarity[rar]
			c.rar.Text = Content.CardRarities[rar]
			c.rar.TextColor3 = color
			c.band.BackgroundColor3 = color
			c.stroke.Color = color
			c.fill.BackgroundColor3 = color
			c.name.Text = txt.name
			c.name.TextColor3 = color
			c.fact.Text = txt.fact or ""
			if def then
				local mult = if Balance.UpgradeCount[id] then 1 else Balance.CardRarity.Mult[rar]
				local after = math.min(def.max, levels[i] + mult)
				c.desc.Text = if txt.fmt then string.format(txt.fmt, math.round(def.per * (after - levels[i]) * txt.scale)) else txt.desc
				c.lvl.Text = string.format("NIVEL %s → %s / %d", Ui.num(levels[i]), Ui.num(after), def.max)
				c.fill.Size = UDim2.fromScale(after / def.max, 1)
			else
				c.desc.Text = txt.desc
				c.lvl.Text = "USO INMEDIATO"
				c.fill.Size = UDim2.fromScale(0, 1)
			end
		end
	end
	task.delay(Balance.Juice.LevelUpPause, function()
		if choiceOpen and not r.piece.Visible then
			show(r.level, true)
			Fx.play("level")
		end
	end)
end

function Hud.pick(i: number)
	if choiceOpen and r.level.Visible and r.cards[i].card.Visible then
		choiceOpen = false
		r.level.Visible = false
		Fx.play("ui")
		send("choose", i)
	end
end

function Hud.piece(idx: number)
	local p = Content.Pieces[idx]
	r.pieces[idx].BackgroundColor3 = T.gold
	r.pieces[idx].TextColor3 = T.bg
	r.pieceHead.Text = string.format("PIEZA %d DE 4", idx)
	r.pieceName.Text = string.upper(p.name)
	r.pieceBonus.Text = "EN EL JUEGO: " .. p.bonus
	r.pieceReal.Text = p.real
	r.pieceRef.Text = if p.ntrs ~= "" then string.format("FUENTE · NASA Technical Reports Server (NTRS) %s\n%s", p.ntrs, p.ref) else p.ref
	r.level.Visible = false -- las cartas pendientes vuelven al pulsar CONTINUAR
	show(r.piece, true)
	Fx.play("level", 0.8)
end

function Hud.item(id: string, count: number)
	local txt = (Content.Items :: any)[id]
	local def = (Balance.Items :: any)[id]
	if not txt or not def then
		return
	end
	r.toastRar.Text = string.format("%s · %s", Content.Rarities[def.rar], (Content.Categories :: any)[def.cat])
	r.toastRar.TextColor3 = if def.rar == 3 then T.gold elseif def.rar == 2 then T.cyanHi else T.dim
	r.toastName.Text = if count > 1 then string.format("%s ×%d", txt.name, count) else txt.name
	r.toastDesc.Text = txt.desc
	r.toastFact.Text = txt.fact
	if not r.toast.Visible then
		Ui.pop(r.toast)
	end
	r.toast.Visible = true
	toastT = 6
end

function Hud.alert(text: string, kind: string?, sub: string?)
	r.alert.Text = text
	r.alert.TextColor3 = if kind == "good" then T.green elseif kind == "info" then T.text else T.orange
	r.alertSub.Text = sub or ""
	alertT = if kind == "info" then 1.8 else 3.2
	if kind == "warn" or kind == nil then
		Fx.play("warn", 0.8)
	end
end

function Hud.biome(i: number)
	local b = Content.Biomes[i]
	local col = BIOME_COLORS[i] or T.cyanHi
	r.biome.Text = string.format("ETAPA %d · %s", i, b.name)
	r.biome.TextColor3 = col
	Hud.alert(string.format("ETAPA %d · %s", i, b.name), "good", b.desc)
end

function Hud.boss(idx: number)
	local id = Balance.Bosses[idx].id
	bossName = (Content.Enemies :: any)[id]
	Hud.alert("ALERTA: " .. bossName, "warn", if idx == 4 then "Derrótalo para recuperar el propulsor." else "Derrótalo para recuperar una pieza de la nave.")
end

function Hud.tutorial(step: number)
	local n = #Content.Tutorial
	step = math.min(step, n)
	local tag = r.tut:FindFirstChildWhichIsA("TextLabel")
	if tag then
		tag.Text = string.format("TUTORIAL %d/%d", step, n)
	end
	r.tutText.Text = Content.Tutorial[step]
	Ui.pop(r.tut)
	Fx.play("ui", 1.4)
end

function Hud.paused(on: boolean)
	show(r.pause, on)
end

-- Estimulos visuales: destello y rotulo grande al subir de nivel, y aviso al activar una mejora.
local TweenService = game:GetService("TweenService")
local stim: any = nil

local function stimuli(): any
	if stim then
		return stim
	end
	local gui = r.hud.Parent :: Instance
	local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.cyanHi, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = Z.hudTop, Active = false })
	flash.Parent = gui
	local big = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(900, 120), BackgroundTransparency = 1, Font = Enum.Font.Bangers, TextSize = 96, TextColor3 = T.gold, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.2, TextTransparency = 1, Text = "", ZIndex = Z.hudTop })
	big.Parent = gui
	local buff = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 178), Size = UDim2.fromOffset(460, 62), BackgroundColor3 = T.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0, Visible = false, ZIndex = Z.hud })
	new("UICorner", { CornerRadius = UDim.new(0, 8) }).Parent = buff
	new("UIStroke", { Thickness = 2, Color = T.cyanHi }).Parent = buff
	new("Frame", { Size = UDim2.new(0, 6, 1, 0), BackgroundColor3 = T.cyanHi, BorderSizePixel = 0, ZIndex = Z.hudTop }).Parent = buff
	local tag = label("MEJORA ACTIVA", 16, { FontFace = F.monoBold, Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -30, 0, 20), TextColor3 = T.cyanHi, ZIndex = Z.hudTop })
	tag.Parent = buff
	local name = label("", 24, { FontFace = F.bold, Position = UDim2.fromOffset(20, 26), Size = UDim2.new(1, -30, 0, 30), ZIndex = Z.hudTop, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	name.Parent = buff
	buff.Parent = gui
	stim = { flash = flash, big = big, buff = buff, buffName = name }
	return stim
end

function Hud.levelFlash(level: number)
	local s = stimuli()
	s.flash.BackgroundTransparency = 0.72
	TweenService:Create(s.flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	s.big.Text = string.format("¡NIVEL %d!", level)
	s.big.TextTransparency = 0
	s.big.TextStrokeTransparency = 0.2
	s.big.TextSize = 40
	s.big.Rotation = -6
	TweenService:Create(s.big, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextSize = 104, Rotation = 0 }):Play()
	task.delay(0.75, function()
		TweenService:Create(s.big, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

local buffToken = 0
function Hud.buff(id: string, level: number)
	local txt = (Content.Upgrades :: any)[id]
	if not txt then
		return
	end
	local s = stimuli()
	local def = (Balance.Upgrades :: any)[id]
	s.buffName.Text = if def then string.format("%s  ·  NIVEL %s/%d", txt.name, Ui.num(level), def.max) else txt.name
	s.buff.Visible = true
	Ui.pop(s.buff)
	buffToken += 1
	local token = buffToken
	task.delay(2.4, function()
		if token == buffToken then
			s.buff.Visible = false
		end
	end)
end

function Hud.hurt()
	vignette = 1
end

-- true si hay un panel abierto y el ratón debe quedar libre.
function Hud.wantsCursor(): boolean
	if phase ~= "run" and phase ~= "tutorial" then
		return true
	end
	for _, f in overlays do
		if f.Visible then
			return true
		end
	end
	return false
end

function Hud.update(dt: number, chestPos: Vector3?)
	-- Las etiquetas centrales se solapan con el titulo de las cartas y de la tarjeta de pieza.
	local covered = r.level.Visible or r.piece.Visible
	if r.wave.Visible == covered then
		r.wave.Visible = not covered
		r.timer.Visible = not covered
		r.biome.Visible = not covered
	end
	if alertT > 0 then
		alertT -= dt
		local a = math.clamp(alertT / 0.5, 0, 1)
		r.alert.TextTransparency = 1 - a
		r.alert.TextStrokeTransparency = 1 - a * 0.75
		r.alertSub.TextTransparency = 1 - a
		r.alertSub.TextStrokeTransparency = 1 - a * 0.75
	end
	if toastT > 0 then
		toastT -= dt
		if toastT <= 0 then
			r.toast.Visible = false
		end
	end
	if hintT > 0 then
		hintT -= dt
		if hintT <= 0 then
			r.hint.Visible = false
		end
	end
	if vignette > 0 then
		vignette = math.max(0, vignette - dt * 3)
		r.vignette.BackgroundTransparency = 1 - vignette * 0.3
	end
	tickerT -= dt
	if tickerT <= 0 then
		tickerT = 6
		tickerI = tickerI % #tickerLines + 1
		r.ticker.Text = tickerLines[tickerI]
	end
	-- Flecha al cofre más cercano cuando queda fuera de pantalla.
	local cam = Workspace.CurrentCamera
	if chestPos and cam and r.hud.Visible then
		local sp, onScreen = cam:WorldToViewportPoint(chestPos)
		local vp = cam.ViewportSize
		if onScreen and sp.X > 40 and sp.X < vp.X - 40 and sp.Y > 40 and sp.Y < vp.Y - 40 then
			r.arrow.Visible = false
		else
			local cx, cy = vp.X / 2, vp.Y / 2
			local dx, dy = sp.X - cx, sp.Y - cy
			if sp.Z < 0 then
				dx, dy = -dx, -dy
			end
			local len = math.max(1, math.sqrt(dx * dx + dy * dy))
			local rad = math.min(cx, cy) * 0.7
			local s = uiScale.Scale
			r.arrow.Position = UDim2.fromOffset((cx + dx / len * rad) / s, (cy + dy / len * rad) / s)
			r.arrow.Rotation = math.deg(math.atan2(dx, -dy))
			r.arrow.Visible = true
		end
	else
		r.arrow.Visible = false
	end
end

return Hud
