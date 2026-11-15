--!strict
-- Interfaz completa: HUD de misión, menú, hangar, ajustes, créditos, cartas de nivel, pieza, pausa y resumen.
-- Estilo: consola de control de misión (ver Ui.luau).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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

Hud.settings = { fov = Balance.Camera.Fov, sens = 1, qualityMode = "auto", effectiveQuality = "high", lowFx = false }

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
local inputMode = if GuiService:IsTenFootInterface()
	then "gamepad"
	elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	then "touch"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
	then "gamepad"
	else "kb"
local touch = (inputMode == "touch")
local refitFn: () -> () = function() end
local qualityLabelFn: () -> string = function()
	return "AUTO"
end

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

local function updateFocus()
	if not gui or inputMode ~= "gamepad" then
		GuiService.SelectedObject = nil
		return
	end
	if r.level and r.level.Visible and r.cards and r.cards[1] then
		GuiService.SelectedObject = r.cards[1].card
	elseif r.piece and r.piece.Visible and r.pieceContinueBtn then
		GuiService.SelectedObject = r.pieceContinueBtn
	elseif r.pause and r.pause.Visible and r.pauseContinueBtn then
		GuiService.SelectedObject = r.pauseContinueBtn
	elseif r.summary and r.summary.Visible and r.sumRetryBtn then
		GuiService.SelectedObject = r.sumRetryBtn
	elseif r.shop and r.shop.Visible and r.shopBackBtn then
		GuiService.SelectedObject = r.shopBackBtn
	elseif r.settings and r.settings.Visible and r.settingsBackBtn then
		GuiService.SelectedObject = r.settingsBackBtn
	elseif r.credits and r.credits.Visible and r.creditsBackBtn then
		GuiService.SelectedObject = r.creditsBackBtn
	elseif r.menu and r.menu.Visible and r.menuBtnPlay then
		GuiService.SelectedObject = r.menuBtnPlay
	else
		GuiService.SelectedObject = nil
	end
end

local function show(f: Frame, on: boolean)
	if on and not f.Visible then
		local p = f:FindFirstChild("Panel")
		if p then
			Ui.pop(p :: GuiObject)
		end
	end
	f.Visible = on
	updateFocus()
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
	r.lvlChip = lvlChip
	r.lvlScale = new("UIScale", { Scale = 1 })
	r.lvlScale.Parent = lvlChip
	r.lvl = label("NIVEL 1", 24, { FontFace = F.impact, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.hudTop })
	r.lvl.Parent = lvlChip

	local suit = panel({ Position = UDim2.fromOffset(16, 62), Size = UDim2.fromOffset(340, 100), ZIndex = Z.hud }, "ESTADO DEL TRAJE")
	suit.Parent = h
	r.suitPanel = suit
	r.suitScale = new("UIScale", { Scale = 1 })
	r.suitScale.Parent = suit
	local hpBack, hpFill = Ui.bar(suit, UDim2.fromOffset(12, 36), UDim2.fromOffset(316, 26), T.green, Z.hud)
	r.hpFill = hpFill
	r.shieldFill = new("Frame", { Size = UDim2.fromScale(0, 0.28), BackgroundColor3 = T.cyanHi, BorderSizePixel = 0, ZIndex = Z.hudTop })
	r.shieldFill.Parent = hpBack
	r.hpText = label("100 / 100", 18, { FontFace = F.monoBold, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, ZIndex = Z.hudTop + 1, TextStrokeTransparency = 0.35 })
	r.hpText.Parent = hpBack
	r.kills = label("BAJAS 0", 18, { FontFace = F.mono, Position = UDim2.fromOffset(12, 68), Size = UDim2.fromOffset(150, 24), TextColor3 = T.text, ZIndex = Z.hudTop })
	r.kills.Parent = suit
	label("SOPORTE VITAL", 18, { FontFace = F.mono, Position = UDim2.fromOffset(164, 68), Size = UDim2.fromOffset(164, 24), TextXAlignment = RIGHT, TextColor3 = T.green, ZIndex = Z.hudTop }).Parent = suit

	r.wave = label("OLEADA 01/18", 34, { Name = "Wave", FontFace = F.impact, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(420, 40), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeTransparency = 0.15, TextWrapped = false, TextScaled = true, ZIndex = Z.hud })
	new("UITextSizeConstraint", { MinTextSize = 20, MaxTextSize = 34 }).Parent = r.wave
	r.wave.Parent = h
	r.timer = label("T+ 00:00", 22, { Name = "Timer", FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54), Size = UDim2.fromOffset(240, 26), TextXAlignment = CENTER, TextColor3 = T.cyanHi, TextStrokeTransparency = 0.3, ZIndex = Z.hud })
	r.timer.Parent = h
	r.biome = label("ETAPA 1 · " .. Content.Biomes[1].name, 18, { Name = "Biome", FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 82), Size = UDim2.fromOffset(480, 24), TextXAlignment = CENTER, TextColor3 = BIOME_COLORS[1], TextStrokeTransparency = 0.25, TextWrapped = false, TextScaled = true, ZIndex = Z.hud })
	new("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 18 }).Parent = r.biome
	r.biome.Parent = h

	local bossWrap = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.new(0.38, 0, 0, 52), BackgroundTransparency = 1, Visible = false })
	bossWrap.Parent = h
	r.bossWrap = bossWrap
	r.bossName = label("", 20, { FontFace = F.bold, TextColor3 = T.orange, TextXAlignment = CENTER, Size = UDim2.new(1, 0, 0, 24), TextStrokeTransparency = 0.3, ZIndex = Z.hud })
	r.bossName.Parent = bossWrap
	local _, bossFill = Ui.bar(bossWrap, UDim2.fromOffset(0, 28), UDim2.new(1, 0, 0, 16), T.red, Z.hud)
	r.bossFill = bossFill

	-- Piezas de la nave
	local ship = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 18), Size = UDim2.fromOffset(368, 92), ZIndex = Z.hud }, "NAVE · PIEZAS RECUPERADAS")
	ship.Parent = h
	r.shipPanel = ship
	r.shipScale = new("UIScale", { Scale = 1 })
	r.shipScale.Parent = ship
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
		local keyLbl = label(if touch then "TOCAR" elseif inputMode == "gamepad" then (if i == 1 then "[X/L1]" else "[B/R1]") else "[" .. sk.key .. "]", 17, { FontFace = F.mono, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, -8, 0, 22), TextColor3 = T.dim, TextWrapped = false, TextScaled = true, ZIndex = Z.hudTop })
		keyLbl.Position = UDim2.fromOffset(4, 52)
		new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 17 }).Parent = keyLbl
		keyLbl.Parent = b
		local cdOverlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false, ZIndex = Z.hudTop + 1 })
		Ui.corner(50).Parent = cdOverlay
		cdOverlay.Parent = b
		local cdText = label("", 28, { FontFace = F.monoBold, TextXAlignment = CENTER, Size = UDim2.fromScale(1, 1), ZIndex = Z.hudTop + 2 })
		cdText.Parent = cdOverlay
		b.Activated:Connect(function()
			useSkill(i)
		end)
		b.Parent = h
		r.skills[i] = { button = b, overlay = cdOverlay, text = cdText, stroke = stroke, keyLabel = keyLbl, ready = true }
	end

	-- Telemetría (datos NASA)
	local ticker = panel({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -(touch and 180 or 20)), Size = UDim2.fromOffset(470, 66), ZIndex = Z.hud }, "TELEMETRÍA · NASA DONKI · COPIA LOCAL")
	ticker.Parent = h
	r.tickerPanel = ticker
	r.tickerScale = new("UIScale", { Scale = 1 })
	r.tickerScale.Parent = ticker
	r.ticker = label("", 18, { FontFace = F.mono, Position = UDim2.fromOffset(12, 34), Size = UDim2.fromOffset(446, 24), ZIndex = Z.hudTop, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	r.ticker.Parent = ticker

	r.alert = label("", 44, { FontFace = F.impact, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.24), Size = UDim2.new(0.9, 0, 0, 52), TextXAlignment = CENTER, TextColor3 = T.orange, TextStrokeTransparency = 0.25, TextTransparency = 1, ZIndex = Z.hudTop })
	r.alert.Parent = h
	r.alertSub = label("", 20, { FontFace = F.semi, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.24, 44), Size = UDim2.new(0.9, 0, 0, 28), TextXAlignment = CENTER, TextStrokeTransparency = 0.25, TextTransparency = 1, ZIndex = Z.hudTop })
	r.alertSub.Parent = h

	local tut = panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(640, 96), Visible = false, ZIndex = Z.hud }, "TUTORIAL 1/8")
	tut.Parent = h
	r.tut = tut
	r.tutText = label("", 20, { FontFace = F.semi, Position = UDim2.fromOffset(14, 34), Size = UDim2.fromOffset(612, 54), ZIndex = Z.hudTop, TextYAlignment = TOP, TextScaled = true })
	new("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 20 }).Parent = r.tutText
	r.tutText.Parent = tut

	r.hint = label(Content.Controls, 17, { FontFace = F.mono, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(0.46, 0, 0, 48), TextXAlignment = CENTER, TextColor3 = T.text, TextStrokeTransparency = 0.3, TextWrapped = true, TextScaled = true, Visible = false, ZIndex = Z.hud })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 17 }).Parent = r.hint
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
local function stepper(parent: Instance, y: number, title: string, get: () -> string, dec: () -> (), inc: () -> ()): TextLabel
	label(title, 20, { FontFace = F.semi, Position = UDim2.fromOffset(24, y), Size = UDim2.fromOffset(310, 46), ZIndex = Z.content, TextWrapped = false, TextScaled = true }).Parent = parent
	local value = label(get(), 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(406, y), Size = UDim2.fromOffset(172, 46), TextXAlignment = CENTER, TextColor3 = T.cyanHi, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 18 }).Parent = value
	value.Parent = parent
	button("−", click(function()
		dec()
		value.Text = get()
		onSettings()
	end), { Position = UDim2.fromOffset(348, y), Size = UDim2.fromOffset(50, 46), ZIndex = Z.content }, "ghost").Parent = parent
	button("+", click(function()
		inc()
		value.Text = get()
		onSettings()
	end), { Position = UDim2.fromOffset(586, y), Size = UDim2.fromOffset(50, 46), ZIndex = Z.content }, "ghost").Parent = parent
	return value
end

local function virtualSize(): Vector2
	local cam = Workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	return vp / uiScale.Scale
end

-- Menú principal en columna izquierda: deja despejado el mundo 3D, la nave y el logo de NASA.
local HOVER_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function buildMainMenu()
	local m = new("Frame", { Name = "Menu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = Z.overlay })
	m.Parent = gui
	table.insert(overlays, m)
	r.menu = m

	-- Sombra lateral suave solo sobre el tercio izquierdo (el resto de la escena queda intacto).
	local shade = new("Frame", { Size = UDim2.new(0.36, 0, 1, 0), BackgroundColor3 = T.bg, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = Z.overlay })
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.65, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}).Parent = shade
	shade.Parent = m
	r.menuShade = shade

	local col = new("Frame", {
		Name = "MenuColumn",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 28, 0.5, 16),
		Size = UDim2.fromOffset(368, 504),
		BackgroundTransparency = 1,
		ZIndex = Z.panel,
	})
	col.Parent = m
	local colScale = new("UIScale", { Name = "Pop", Scale = 1 })
	colScale.Parent = col
	r.menuCol = col
	r.menuColScale = colScale

	-- 1. Cabecera de marca (limpia, debajo de la barra superior de Roblox).
	local dot = new("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = T.orange, BorderSizePixel = 0, ZIndex = Z.content })
	Ui.corner(4).Parent = dot
	dot.Parent = col
	local kicker = label("CRÁTER JEZERO · SOL 01", 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(354, 18), TextColor3 = T.orange, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 14 }).Parent = kicker
	kicker.Parent = col

	local titleLbl = label(Content.Title, 42, { FontFace = F.title, Position = UDim2.fromOffset(-2, 18), Size = UDim2.fromOffset(370, 46), TextColor3 = T.text, TextStrokeTransparency = 0.35, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 24, MaxTextSize = 42 }).Parent = titleLbl
	titleLbl.Parent = col

	new("Frame", { Position = UDim2.fromOffset(0, 74), Size = UDim2.fromOffset(36, 3), BackgroundColor3 = T.gold, BorderSizePixel = 0, ZIndex = Z.content }).Parent = col
	label("SUPERVIVENCIA EN MARTE", 15, { FontFace = F.bold, Position = UDim2.fromOffset(46, 65), Size = UDim2.fromOffset(322, 20), TextColor3 = T.gold, TextStrokeTransparency = 0.4, TextWrapped = false, ZIndex = Z.content }).Parent = col
	local hook = label("Recupera las 4 piezas de tu módulo y despega.", 15, { FontFace = F.semi, Position = UDim2.fromOffset(0, 86), Size = UDim2.fromOffset(368, 22), TextColor3 = Color3.fromHex("#DCE6F5"), TextStrokeTransparency = 0.45, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 15 }).Parent = hook
	hook.Parent = col

	local function bindHover(btn: TextButton, baseBg: Color3, baseT: number, hoverBg: Color3, hoverT: number, stroke: UIStroke, sBase: number, sHover: number, sBaseCol: Color3?, sHoverCol: Color3?)
		local function over()
			TweenService:Create(btn, HOVER_TWEEN, { BackgroundColor3 = hoverBg, BackgroundTransparency = hoverT }):Play()
			TweenService:Create(stroke, HOVER_TWEEN, { Transparency = sHover, Color = sHoverCol or stroke.Color }):Play()
		end
		local function out()
			TweenService:Create(btn, HOVER_TWEEN, { BackgroundColor3 = baseBg, BackgroundTransparency = baseT }):Play()
			TweenService:Create(stroke, HOVER_TWEEN, { Transparency = sBase, Color = sBaseCol or stroke.Color }):Play()
		end
		btn.MouseEnter:Connect(over)
		btn.SelectionGained:Connect(over)
		btn.MouseLeave:Connect(out)
		btn.SelectionLost:Connect(out)
	end

	-- 2. Acciones de juego: boton principal prominente + fila de modos rapidos.
	local heroBg = Color3.fromHex("#FF6B35")
	local heroHover = Color3.fromHex("#FF8552")
	local hero = new("TextButton", {
		Name = "BtnPlay",
		Position = UDim2.fromOffset(0, 114),
		Size = UDim2.fromOffset(368, 62),
		BackgroundColor3 = heroBg,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = Z.content,
	})
	Ui.corner(8).Parent = hero
	local heroStroke = Ui.stroke(Color3.fromHex("#FFB899"), 1.2, 0.55)
	heroStroke.Parent = hero
	local heroLip = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Color3.fromHex("#B84318"), BorderSizePixel = 0, ZIndex = Z.content })
	heroLip.Parent = hero
	label("INICIAR MISIÓN", 22, { FontFace = F.bold, Position = UDim2.fromOffset(18, 7), Size = UDim2.fromOffset(286, 26), TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.65, TextWrapped = false, ZIndex = Z.content + 1 }).Parent = hero
	local heroSub = label("Partida completa · 18 oleadas en 3 etapas", 14, { FontFace = F.semi, Position = UDim2.fromOffset(18, 33), Size = UDim2.fromOffset(286, 20), TextColor3 = Color3.fromHex("#FFE4D6"), TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = heroSub
	heroSub.Parent = hero
	local playPill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = T.bg, BackgroundTransparency = 0.65, BorderSizePixel = 0, ZIndex = Z.content + 1 })
	Ui.corner(8).Parent = playPill
	label(">", 22, { FontFace = F.monoBold, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextColor3 = Color3.new(1, 1, 1), ZIndex = Z.content + 2 }).Parent = playPill
	playPill.Parent = hero
	bindHover(hero, heroBg, 0, heroHover, 0, heroStroke, 0.55, 0.2)
	hero.Activated:Connect(click(function()
		lastMode = "full"
		send("start", "full")
	end))
	hero.Parent = col
	r.menuBtnPlay = hero

	local function darkCard(name: string, x: number, py: number, w: number, h: number, titleTxt: string, subTxt: string?, accent: Color3, fn: () -> ()): TextButton
		local b = new("TextButton", {
			Name = name,
			Position = UDim2.fromOffset(x, py),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = T.panel,
			BackgroundTransparency = 0.12,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = Z.content,
		})
		Ui.corner(8).Parent = b
		local st = Ui.stroke(accent, 1.2, 0.4)
		st.Parent = b
		local bar = new("Frame", { Position = UDim2.fromOffset(4, 10), Size = UDim2.new(0, 3, 1, -20), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = Z.content + 1 })
		Ui.corner(2).Parent = bar
		bar.Parent = b
		local titleW = if titleTxt == "HANGAR DEL TRAJE" then 212 else (w - 22)
		local tLbl = label(titleTxt, if subTxt then 16 else 15, { FontFace = F.bold, Position = UDim2.fromOffset(14, 7), Size = UDim2.fromOffset(titleW, 20), TextColor3 = T.text, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
		new("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 17 }).Parent = tLbl
		tLbl.Parent = b
		if subTxt then
			local sLbl = label(subTxt, 13, { FontFace = F.body, Position = UDim2.fromOffset(14, 28), Size = UDim2.fromOffset(titleW, 18), TextColor3 = accent, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
			new("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 13 }).Parent = sLbl
			sLbl.Parent = b
		end
		bindHover(b, T.panel, 0.12, T.panelHi, 0.04, st, 0.4, 0.08)
		b.Activated:Connect(click(fn))
		b.Parent = col
		return b
	end

	darkCard("BtnDemo", 0, 186, 178, 52, "DEMO RÁPIDA", "Partida de 4 min", T.cyanHi, function()
		lastMode = "demo"
		send("start", "demo")
	end)
	darkCard("BtnTutorial", 190, 186, 178, 52, "TUTORIAL", "Práctica guiada", T.gold, function()
		send("tutorial")
	end)

	-- 3. Progresion y utilidades.
	new("Frame", { Position = UDim2.fromOffset(0, 248), Size = UDim2.fromOffset(368, 1), BackgroundColor3 = T.line, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = Z.content }).Parent = col

	local hangar = darkCard("BtnHangar", 0, 258, 368, 50, "HANGAR DEL TRAJE", "Mejoras permanentes", T.violet, function()
		show(r.shop, true)
	end)
	local sciPill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(116, 26), BackgroundColor3 = T.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = Z.content + 1 })
	Ui.corner(6).Parent = sciPill
	Ui.stroke(T.gold, 1, 0.3).Parent = sciPill
	sciPill.Parent = hangar
	r.menuScience = label("0 CIENCIA", 13, { FontFace = F.monoBold, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), TextXAlignment = CENTER, TextColor3 = T.gold, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 2 })
	new("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 13 }).Parent = r.menuScience
	r.menuScience.Parent = sciPill

	local function utilBtn(name: string, x: number, txt: string, fn: () -> ())
		local b = new("TextButton", {
			Name = name,
			Position = UDim2.fromOffset(x, 316),
			Size = UDim2.fromOffset(178, 40),
			BackgroundColor3 = T.panel,
			BackgroundTransparency = 0.18,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = Z.content,
		})
		Ui.corner(8).Parent = b
		local st = Ui.stroke(T.line, 1, 0.25)
		st.Parent = b
		local l = label(txt, 14, { FontFace = F.semi, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), TextXAlignment = CENTER, TextColor3 = T.text, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
		new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = l
		l.Parent = b
		bindHover(b, T.panel, 0.18, T.panelHi, 0.04, st, 0.25, 0.15, T.line, T.cyanHi)
		b.Activated:Connect(click(fn))
		b.Parent = col
	end
	utilBtn("BtnSettings", 0, "AJUSTES Y MANDOS", function()
		show(r.settings, true)
	end)
	utilBtn("BtnCredits", 190, "CRÉDITOS Y FUENTES", function()
		show(r.credits, true)
	end)

	-- 4. Hoja de servicio compacta en 3 columnas limpias (sin cajones ruidosos).
	local sheet = new("Frame", {
		Name = "ServiceSheet",
		Position = UDim2.fromOffset(0, 368),
		Size = UDim2.fromOffset(368, 84),
		BackgroundColor3 = T.panel,
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		ZIndex = Z.panel,
	})
	Ui.corner(8).Parent = sheet
	Ui.stroke(T.line, 1, 0.35).Parent = sheet
	sheet.Parent = col

	label("HOJA DE SERVICIO", 12, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(152, 18), TextColor3 = T.dim, TextWrapped = false, ZIndex = Z.content }).Parent = sheet
	r.menuStatus = label("GUARDADO ACTIVO", 12, { FontFace = F.monoBold, Position = UDim2.fromOffset(168, 6), Size = UDim2.fromOffset(186, 18), TextXAlignment = RIGHT, TextColor3 = T.green, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 12 }).Parent = r.menuStatus
	r.menuStatus.Parent = sheet

	new("Frame", { Position = UDim2.fromOffset(12, 27), Size = UDim2.fromOffset(344, 1), BackgroundColor3 = T.line, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = Z.content }).Parent = sheet
	new("Frame", { Position = UDim2.fromOffset(123, 34), Size = UDim2.fromOffset(1, 38), BackgroundColor3 = T.line, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = Z.content }).Parent = sheet
	new("Frame", { Position = UDim2.fromOffset(245, 34), Size = UDim2.fromOffset(1, 38), BackgroundColor3 = T.line, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = Z.content }).Parent = sheet

	local function statCol(x: number, hdr: string, colr: Color3, font: Font): TextLabel
		label(hdr, 11, { FontFace = F.monoBold, Position = UDim2.fromOffset(x, 32), Size = UDim2.fromOffset(110, 16), TextXAlignment = CENTER, TextColor3 = T.dim, TextWrapped = false, ZIndex = Z.content }).Parent = sheet
		local val = label("—", 16, { FontFace = font, Position = UDim2.fromOffset(x, 49), Size = UDim2.fromOffset(110, 24), TextXAlignment = CENTER, TextColor3 = colr, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
		new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 16 }).Parent = val
		val.Parent = sheet
		return val
	end
	r.statRuns = statCol(8, "MISIONES (VICT.)", T.text, F.monoBold)
	r.statTime = statCol(129, "MEJOR TIEMPO", T.cyanHi, F.monoBold)
	r.statBest = statCol(250, "NIVEL / BAJAS", T.gold, F.monoBold)

	-- 5. Nota legal discreta al pie de la columna.
	label("Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto.", 13, {
		Position = UDim2.fromOffset(0, 462),
		Size = UDim2.fromOffset(368, 38),
		TextColor3 = T.dim,
		TextTransparency = 0.05,
		TextStrokeTransparency = 0.65,
		TextYAlignment = TOP,
		ZIndex = Z.content,
	}).Parent = col
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
	local shopBack = button("VOLVER", click(function()
		show(r.shop, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(240, 50), ZIndex = Z.content })
	shopBack.Parent = sp
	r.shopBackBtn = shopBack

	-- Ajustes y Controles
	local st = overlay("Settings")
	r.settings = st
	local stp = centerPanel(st, 660, 504, "AJUSTES Y CONTROLES", T.green)
	label("AJUSTES DEL TRAJE", 28, { FontFace = F.impact, Position = UDim2.fromOffset(24, 34), Size = UDim2.fromOffset(420, 32), TextColor3 = T.green, TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = stp
	local S = Hud.settings
	local QUALITY_CYCLE = { "auto", "high", "med", "low" }
	local function tierEs(t: string): string
		if t == "low" then
			return "BAJA"
		elseif t == "med" then
			return "MEDIA"
		end
		return "ALTA"
	end
	local function qualityLabel(): string
		if S.qualityMode == "auto" then
			return "AUTO (" .. tierEs(S.effectiveQuality) .. ")"
		end
		return tierEs(S.qualityMode)
	end
	qualityLabelFn = qualityLabel
	local function stepQuality(delta: number)
		local cur = table.find(QUALITY_CYCLE, S.qualityMode) or 1
		local nextIdx = ((cur - 1 + delta) % #QUALITY_CYCLE) + 1
		S.qualityMode = QUALITY_CYCLE[nextIdx]
		if S.qualityMode ~= "auto" then
			S.effectiveQuality = S.qualityMode
			S.lowFx = (S.qualityMode == "low")
		end
	end
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
	r.qualityValue = stepper(stp, 178, "CALIDAD GRÁFICA", qualityLabel, function()
		stepQuality(-1)
	end, function()
		stepQuality(1)
	end)
	local ctrlBox = new("Frame", { Position = UDim2.fromOffset(24, 236), Size = UDim2.new(1, -48, 0, 178), BackgroundColor3 = T.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = Z.panel })
	Ui.corner(4).Parent = ctrlBox
	Ui.stroke(T.green, 1, 0.55).Parent = ctrlBox
	ctrlBox.Parent = stp
	label("CONTROLES POR PLATAFORMA", 15, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(290, 22), TextColor3 = T.green, TextWrapped = false, ZIndex = Z.content }).Parent = ctrlBox
	r.platformBadge = label("", 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(310, 8), Size = UDim2.new(1, -324, 0, 22), TextXAlignment = RIGHT, TextColor3 = T.cyanHi, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 14 }).Parent = r.platformBadge
	r.platformBadge.Parent = ctrlBox
	new("Frame", { Position = UDim2.fromOffset(14, 33), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = T.line, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = Z.content }).Parent = ctrlBox
	local ctrlLines = {
		{ k = "PC / WEB", d = "WASD o Flechas ↑↓←→ mover · Ratón cámara · Rueda zoom · Espacio saltar · Q/E habs · 1-3 cartas · P pausa", c = T.cyanHi },
		{ k = "CONSOLA / MANDO", d = "Stick Izq mover · Stick Der cámara · A saltar · X/L1 e B/R1 habs · ◀▲▶ elegir carta · Start pausa", c = T.gold },
		{ k = "MÓVIL / TÁCTIL", d = "Joystick izq mover · Arrastrar derecha cámara · Pellizcar zoom · Botones saltar, RCS, Pulso y tocar cartas", c = T.green },
	}
	for idx, cl in ctrlLines do
		local ly = 40 + (idx - 1) * 44
		local kl = label(cl.k, 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, ly), Size = UDim2.fromOffset(146, 38), TextColor3 = cl.c, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
		new("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 14 }).Parent = kl
		kl.Parent = ctrlBox
		local dl = label(cl.d, 15, { FontFace = F.semi, Position = UDim2.fromOffset(166, ly), Size = UDim2.new(1, -180, 0, 38), TextColor3 = T.text, TextScaled = true, ZIndex = Z.content })
		new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 15 }).Parent = dl
		dl.Parent = ctrlBox
	end
	local stBack = button("VOLVER", click(function()
		show(r.settings, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(240, 50), ZIndex = Z.content })
	stBack.Parent = stp
	r.settingsBackBtn = stBack

	-- Créditos
	local c = overlay("Credits")
	r.credits = c
	local cp = centerPanel(c, 800, 620, "CRÉDITOS Y FUENTES", T.cyanHi)
	label("ARCHIVO DE FUENTES Y CRÉDITOS", 28, { FontFace = F.impact, Position = UDim2.fromOffset(24, 34), Size = UDim2.new(1, -48, 0, 32), TextColor3 = T.cyanHi, TextStrokeTransparency = 0.2, ZIndex = Z.content }).Parent = cp
	label(table.concat(Content.Credits, "\n"), 18, { Position = UDim2.fromOffset(24, 72), Size = UDim2.new(1, -48, 1, -150), TextYAlignment = TOP, TextColor3 = T.text, LineHeight = 1.12, ZIndex = Z.content }).Parent = cp
	local crBack = button("VOLVER", click(function()
		show(r.credits, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(240, 50), ZIndex = Z.content })
	crBack.Parent = cp
	r.creditsBackBtn = crBack
end

-- ---------------------------------------------------------------- Cartas, pieza, pausa, resumen
local function buildOverlays()
	local lv = overlay("LevelUp", 0.35)
	r.level = lv
	r.levelTag = label("SUBIDA DE NIVEL", 18, { FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.new(0.9, 0, 0, 24), TextXAlignment = CENTER, TextColor3 = T.cyanHi, ZIndex = Z.content })
	r.levelTag.Parent = lv
	r.levelTitle = label("", 46, { FontFace = F.impact, TextColor3 = T.gold, TextStrokeTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.1, 26), Size = UDim2.new(0.92, 0, 0, 52), TextXAlignment = CENTER, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 22, MaxTextSize = 46 }).Parent = r.levelTitle
	r.levelTitle.Parent = lv
	local row = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(960, 340), BackgroundTransparency = 1, ZIndex = Z.panel })
	Ui.list(22, true).Parent = row
	row.Parent = lv
	r.levelRow = row
	r.cards = {}
	for i = 1, 3 do
		local card = new("TextButton", { Size = UDim2.fromOffset(304, 340), BackgroundColor3 = T.panel, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, ZIndex = Z.panel })
		Ui.corner(4).Parent = card
		local stroke = Ui.stroke(T.cyanHi, 2, 0.15)
		stroke.Parent = card
		local band = new("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T.cyanHi, BorderSizePixel = 0, ZIndex = Z.content })
		band.Parent = card
		local rar = label("", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(180, 24), ZIndex = Z.content })
		rar.Parent = card
		local keyLbl = label(if touch then "TOCAR" elseif inputMode == "gamepad" then (if i == 1 then "[◀]" elseif i == 2 then "[▲]" else "[▶]") else "[" .. i .. "]", 17, { FontFace = F.monoBold, Position = UDim2.fromOffset(204, 18), Size = UDim2.fromOffset(82, 24), TextXAlignment = RIGHT, TextColor3 = T.dim, TextWrapped = false, ZIndex = Z.content })
		keyLbl.Parent = card
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
		local function cardOver()
			Ui.tween(card, 0.15, { BackgroundColor3 = T.panelHi })
		end
		local function cardOut()
			Ui.tween(card, 0.15, { BackgroundColor3 = T.panel })
		end
		card.MouseEnter:Connect(cardOver)
		card.SelectionGained:Connect(cardOver)
		card.MouseLeave:Connect(cardOut)
		card.SelectionLost:Connect(cardOut)
		card.Activated:Connect(function()
			Hud.pick(i)
		end)
		card.Parent = row
		r.cards[i] = { card = card, name = name, desc = desc, fact = fact, lvl = lvlText, fill = lvlFill, rar = rar, band = band, stroke = stroke, keyLabel = keyLbl }
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
	local pcCont = button("CONTINUAR", click(function()
		show(r.piece, false)
		send("continue")
		if choiceOpen then
			show(r.level, true)
		end
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(280, 54), ZIndex = Z.content })
	pcCont.Parent = pp
	r.pieceContinueBtn = pcCont

	local pa = overlay("Pause")
	r.pause = pa
	local pap = centerPanel(pa, 440, 300, "MISIÓN EN PAUSA", T.orange)
	label("PAUSA", 50, { FontFace = F.impact, TextColor3 = T.orange, TextStrokeTransparency = 0.2, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 56), ZIndex = Z.content }).Parent = pap
	local paCont = button("CONTINUAR", click(function()
		send("pause")
	end), { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), ZIndex = Z.content })
	paCont.Parent = pap
	r.pauseContinueBtn = paCont
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
	local sumRetry = button("REINTENTAR", click(function()
		send("start", lastMode)
	end), { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 60, 1, -18), Size = UDim2.fromOffset(310, 54), ZIndex = Z.content })
	sumRetry.Parent = sp
	r.sumRetryBtn = sumRetry
	button("MENÚ", click(function()
		send("menu")
	end), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -60, 1, -18), Size = UDim2.fromOffset(310, 54), ZIndex = Z.content }, "ghost").Parent = sp
end

local refreshMeta: () -> ()

local function applyInputLabels()
	touch = (inputMode == "touch")
	if not gui then
		return
	end
	if r.skills then
		for i = 1, 2 do
			local sk = Content.Skills[i]
			local kl = r.skills[i] and r.skills[i].keyLabel
			if kl then
				kl.Text = if inputMode == "touch"
					then "TOCAR"
					elseif inputMode == "gamepad" then (if i == 1 then "[X/L1]" else "[B/R1]")
					else "[" .. sk.key .. "]"
			end
		end
	end
	if r.cards then
		for i = 1, 3 do
			local kl = r.cards[i] and r.cards[i].keyLabel
			if kl then
				kl.Text = if inputMode == "touch"
					then "TOCAR"
					elseif inputMode == "gamepad" then (if i == 1 then "[◀]" elseif i == 2 then "[▲]" else "[▶]")
					else "[" .. i .. "]"
			end
		end
	end
	if r.hint then
		r.hint.Text = if inputMode == "gamepad"
			then Content.ControlsGamepad
			elseif inputMode == "touch" then Content.ControlsTouch
			else Content.Controls
	end
	if r.platformBadge then
		r.platformBadge.Text = if inputMode == "gamepad"
			then "MODO ACTIVO: MANDO / CONSOLA"
			elseif inputMode == "touch" then "MODO ACTIVO: MÓVIL / TÁCTIL"
			else "MODO ACTIVO: PC / WEB"
	end
	updateFocus()
	refitFn()
end

function Hud.setInputMode(mode: string)
	if mode ~= "kb" and mode ~= "gamepad" and mode ~= "touch" then
		return
	end
	if inputMode == mode then
		return
	end
	inputMode = mode
	applyInputLabels()
end

function Hud.getInputMode(): string
	return inputMode
end

function Hud.setEffectiveQuality(tier: string)
	if tier ~= "high" and tier ~= "med" and tier ~= "low" then
		return
	end
	Hud.settings.effectiveQuality = tier
	Hud.settings.lowFx = (tier == "low")
	if r.qualityValue then
		r.qualityValue.Text = qualityLabelFn()
	end
end

function Hud.back(): boolean
	if r.settings and r.settings.Visible then
		show(r.settings, false)
		return true
	end
	if r.credits and r.credits.Visible then
		show(r.credits, false)
		return true
	end
	if r.shop and r.shop.Visible then
		show(r.shop, false)
		return true
	end
	if r.pause and r.pause.Visible then
		send("pause")
		return true
	end
	return false
end

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
		uiScale.Scale = math.clamp(math.min(vp.Y / 720, vp.X / 1200), 0.48, 1.8)
	end
	rescale()
	buildHud()
	buildMainMenu()
	buildMenu()
	buildOverlays()

	-- Maquetación adaptable para PC, Web, Consola/TV y Móvil (horizontal y vertical).
	local function refit()
		rescale()
		local v = virtualSize()
		local topInset = GuiService:GetGuiInset()
		local topSafe = math.ceil(math.max(60, topInset.Y + 6) / uiScale.Scale)
		local safeH = math.max(200, v.Y - topSafe - 16)
		local safeW = math.max(260, v.X - 24)
		for _, e in fitPanels do
			local s = math.min(1, safeH / e.h, safeW / e.w)
			e.p:SetAttribute("Fit", s)
			e.p.Position = UDim2.new(0.5, 0, 0, topSafe + safeH * 0.5)
			Ui.pop(e.p, true)
		end
		if r.levelTag and r.levelTitle and r.levelRow then
			r.levelTag.Position = UDim2.new(0.5, 0, 0, topSafe + 8)
			r.levelTitle.Position = UDim2.new(0.5, 0, 0, topSafe + 34)
			local cardsTop = topSafe + 94
			local cardsH = math.max(160, v.Y - cardsTop - 18)
			local cardScale = math.min(1, cardsH / 348, (v.X - 28) / 960)
			r.levelRow:SetAttribute("Fit", cardScale)
			r.levelRow.Position = UDim2.new(0.5, 0, 0, cardsTop + cardsH * 0.5)
			Ui.pop(r.levelRow, true)
		end

		local portrait = v.X < v.Y
		if r.menuCol and r.menuColScale then
			if portrait then
				if r.menuShade then
					r.menuShade.Size = UDim2.new(1, 0, 0.58, 0)
					r.menuShade.Position = UDim2.new(0, 0, 0.42, 0)
					local grad = r.menuShade:FindFirstChildOfClass("UIGradient")
					if grad then
						grad.Rotation = -90
					end
				end
				local availW = math.max(240, v.X - 32)
				local availH = math.max(200, (v.Y - topSafe) * 0.56)
				r.menuColScale.Scale = math.clamp(math.min(1, availH / 504, availW / 368), 0.5, 1)
				r.menuCol.AnchorPoint = Vector2.new(0.5, 1)
				r.menuCol.Position = UDim2.new(0.5, 0, 1, -18)
			else
				if r.menuShade then
					r.menuShade.Size = UDim2.new(0.36, 0, 1, 0)
					r.menuShade.Position = UDim2.fromOffset(0, 0)
					local grad = r.menuShade:FindFirstChildOfClass("UIGradient")
					if grad then
						grad.Rotation = 0
					end
				end
				local availH = math.max(160, v.Y - topSafe - 18)
				local availW = math.max(220, v.X * 0.35)
				r.menuColScale.Scale = math.clamp(math.min(1, availH / 504, availW / 368), 0.5, 1)
				r.menuCol.AnchorPoint = Vector2.new(0, 0.5)
				r.menuCol.Position = UDim2.new(0, 28, 0, topSafe + availH * 0.5)
			end
		end

		if r.hud then
			local cornerScale = math.clamp((v.X - 40) / 1080, 0.68, 1)
			r.lvlScale.Scale = cornerScale
			r.suitScale.Scale = cornerScale
			r.shipScale.Scale = cornerScale
			r.tickerScale.Scale = cornerScale

			r.lvlChip.Position = UDim2.fromOffset(16, topSafe)
			r.suitPanel.Position = UDim2.fromOffset(16, topSafe + math.ceil(42 * cornerScale))
			r.shipPanel.Position = UDim2.new(1, -16, 0, topSafe)

			local rightNextY = topSafe + math.ceil(98 * cornerScale)
			r.pauseBtn.Position = UDim2.new(1, -16, 0, rightNextY)
			r.exitBtn.Position = UDim2.new(1, -16, 0, rightNextY)
			r.toast:SetAttribute("Fit", cornerScale)
			Ui.pop(r.toast, true)
			r.toast.Position = UDim2.new(1, -16, 0, rightNextY + 54)

			local narrow = v.X < 1080
			local centerY = if narrow then (topSafe + math.max(122, math.ceil(154 * cornerScale))) else math.max(14, topSafe - 4)
			local corridor = if narrow then (v.X - 32) else math.max(300, math.floor(v.X - 56 - 340 * cornerScale - 368 * cornerScale))
			local waveW = math.min(420, corridor)
			local biomeW = math.min(460, corridor)
			r.wave.Position = UDim2.new(0.5, 0, 0, centerY)
			r.wave.Size = UDim2.fromOffset(waveW, 40)
			r.timer.Position = UDim2.new(0.5, 0, 0, centerY + 40)
			r.biome.Position = UDim2.new(0.5, 0, 0, centerY + 68)
			r.biome.Size = UDim2.fromOffset(biomeW, 24)
			r.bossWrap.Position = UDim2.new(0.5, 0, 0, centerY + 96)
			r.bossWrap.Size = UDim2.fromOffset(math.min(460, corridor), 52)

			local tw = if narrow then math.max(260, math.floor(v.X - 32)) else math.clamp(math.floor(v.X * 0.39), 320, 470)
			r.tickerPanel.Size = UDim2.fromOffset(tw, 66)
			r.ticker.Size = UDim2.fromOffset(tw - 24, 24)
			if inputMode == "touch" then
				r.tickerPanel.AnchorPoint = Vector2.new(0, 0)
				local tickerY = if narrow then (centerY + 104) else (topSafe + math.ceil(150 * cornerScale))
				r.tickerPanel.Position = UDim2.fromOffset(16, tickerY)
			else
				r.tickerPanel.AnchorPoint = Vector2.new(0, 1)
				r.tickerPanel.Position = UDim2.new(0, 16, 1, -20)
			end

			local skillFit = if inputMode == "touch" then math.clamp(0.72 / uiScale.Scale, 0.85, 1.15) else cornerScale
			local skillGap = math.ceil(110 * skillFit)
			local skillRightPad = if inputMode == "touch" then (if narrow then 134 else 156) else 24
			local skillBottomPad = if inputMode == "touch" then 34 else 28
			for i = 1, 2 do
				local btn = r.skills[i].button
				btn:SetAttribute("Fit", skillFit)
				Ui.pop(btn, true)
				btn.Position = UDim2.new(1, -skillRightPad - (2 - i) * skillGap, 1, -skillBottomPad)
			end

			local tutW = math.min(640, v.X - 32)
			r.tut.Size = UDim2.fromOffset(tutW, 96)
			r.tutText.Size = UDim2.fromOffset(tutW - 28, 54)
			r.tut.Position = UDim2.new(0.5, 0, 1, if inputMode == "touch" then -196 elseif v.X < 1080 then -154 else -146)

			if v.X < 1080 then
				r.hint.Size = UDim2.fromOffset(math.min(540, v.X - 40), 46)
				r.hint.Position = UDim2.new(0.5, 0, 1, if inputMode == "touch" then -144 else -96)
			else
				r.hint.Size = UDim2.fromOffset(math.min(660, v.X - 64), 42)
				r.hint.Position = UDim2.new(0.5, 0, 1, if inputMode == "touch" then -20 else -94)
			end
		end
	end
	refitFn = refit
	applyInputLabels()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Hud.refit()
	refitFn()
end

refreshMeta = function()
	if not meta then
		return
	end
	local best = meta.best
	if not meta.loaded then
		r.menuScience.Text = "... CIENCIA"
		r.menuStatus.Text = "CARGANDO..."
		r.menuStatus.TextColor3 = T.dim
		r.statRuns.Text = "—"
		r.statTime.Text = "—"
		r.statBest.Text = "—"
	else
		r.menuScience.Text = string.format("%d CIENCIA", meta.science)
		if meta.offline then
			r.menuStatus.Text = "MODO LOCAL"
			r.menuStatus.TextColor3 = T.orange
		else
			r.menuStatus.Text = "GUARDADO ACTIVO"
			r.menuStatus.TextColor3 = T.green
		end
		r.statRuns.Text = string.format("%d (%d)", meta.runs, meta.wins)
		r.statTime.Text = Ui.time(best.time)
		r.statBest.Text = string.format("Nv.%d · %d", best.level, best.kills)
	end
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
		r.hint.Visible = true
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
	updateFocus()
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
		updateFocus()
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
