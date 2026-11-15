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

local ES_UPPER: { [string]: string } = {
	["á"] = "Á", ["é"] = "É", ["í"] = "Í", ["ó"] = "Ó", ["ú"] = "Ú", ["ü"] = "Ü", ["ñ"] = "Ñ",
}
local function upperEs(s: string): string
	local mapped = s:gsub("[%z\1-\127\194-\244][\128-\191]*", function(ch)
		return ES_UPPER[ch] or ch
	end)
	return string.upper(mapped)
end

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

Hud.settings = { fov = Balance.Camera.Fov, sens = 1, qualityMode = "auto", effectiveQuality = "high", lowFx = false, muted = false }

local send: (...any) -> () = function() end
local useSkill: (number) -> () = function() end
local onSettings: () -> () = function() end
local gui: ScreenGui
local uiScale: UIScale
local r: { [string]: any } = {}
local phase = "menu"
local meta: any = nil
local lastMode = "full"
local returnTarget = "menu"
local briefingReturn = "none"
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

local ZONE_COLORS: { Color3 } = { T.cyanHi, T.orange, T.gold, T.red, Color3.fromRGB(110, 230, 255) }

local function click(fn: () -> ()): () -> ()
	return function()
		Fx.play("ui")
		fn()
	end
end

local function overlay(name: string, dim: number?): Frame
	local f = new("Frame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BackgroundTransparency = dim or 0.14, BorderSizePixel = 0, Visible = false, ZIndex = Z.overlay })
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
	elseif r.briefing and r.briefing.Visible and r.briefDeployBtn then
		GuiService.SelectedObject = r.briefDeployBtn
	elseif r.piece and r.piece.Visible and r.pieceContinueBtn then
		GuiService.SelectedObject = r.pieceContinueBtn
	elseif r.pause and r.pause.Visible and r.pauseContinueBtn then
		GuiService.SelectedObject = r.pauseContinueBtn
	elseif r.summary and r.summary.Visible and r.sumRetryBtn then
		GuiService.SelectedObject = r.sumRetryBtn
	elseif r.profiles and r.profiles.Visible and r.profilesBackBtn then
		GuiService.SelectedObject = r.profilesBackBtn
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

local function syncMenuSurface()
	if not r.menu then
		return
	end
	local subOpen = (r.shop and r.shop.Visible)
		or (r.settings and r.settings.Visible)
		or (r.credits and r.credits.Visible)
		or (r.profiles and r.profiles.Visible)
	local showCols = (phase == "menu") and not subOpen
	r.menu.Visible = (phase == "menu")
	if r.menuCol then
		r.menuCol.Visible = showCols
	end
	if r.menuShade then
		r.menuShade.Visible = showCols
	end
end

local function show(f: Frame, on: boolean)
	if on then
		-- Cierra submenús hermanos para evitar que ningún menú choque o se superponga.
		for _, sub in { r.shop, r.settings, r.credits, r.profiles } do
			if sub and sub ~= f then
				sub.Visible = false
			end
		end
		if (f == r.shop or f == r.settings or f == r.credits or f == r.profiles) and phase == "menu" then
			returnTarget = "menu"
		end
		if not f.Visible then
			local p = f:FindFirstChild("Panel")
			if p then
				Ui.pop(p :: GuiObject)
			end
		end
	end
	f.Visible = on
	syncMenuSurface()
	updateFocus()
end

-- ---------------------------------------------------------------- HUD de misión
local function buildHud()
	local h = new("Frame", { Name = "Hud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	h.Parent = gui
	r.hud = h

	local _, xpFill = Ui.bar(h, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 10), T.cyanHi, Z.hud)
	r.xpFill = xpFill
	local lvlChip = panel({ Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(146, 38), ZIndex = Z.hud, TagColor = T.gold })
	lvlChip.Parent = h
	r.lvlChip = lvlChip
	r.lvlScale = new("UIScale", { Scale = 1 })
	r.lvlScale.Parent = lvlChip
	r.lvl = label("NIVEL 1", 24, { FontFace = F.display, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.hudTop })
	r.lvl.Parent = lvlChip

	local suit = panel({ Position = UDim2.fromOffset(16, 62), Size = UDim2.fromOffset(346, 126), ZIndex = Z.hud }, "TRAJE · ENERGÍA Y ESCUDO")
	suit.Parent = h
	r.suitPanel = suit
	r.suitScale = new("UIScale", { Scale = 1 })
	r.suitScale.Parent = suit
	local hpBack, hpFill = Ui.bar(suit, UDim2.fromOffset(12, 34), UDim2.fromOffset(322, 24), T.green, Z.hud)
	r.hpFill = hpFill
	r.hpText = label("SALUD 100 / 100", 16, { FontFace = F.monoBold, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, ZIndex = Z.hudTop + 1, TextStrokeTransparency = 0.25 })
	r.hpText.Parent = hpBack

	local shBack, shFill = Ui.bar(suit, UDim2.fromOffset(12, 64), UDim2.fromOffset(322, 22), T.cyanHi, Z.hud)
	shFill.Size = UDim2.fromScale(0, 1)
	local shStroke = shBack:FindFirstChildOfClass("UIStroke")
	if shStroke then
		shStroke.Color = T.cyan
	end
	r.shieldFill = shFill
	r.shieldText = label("ESCUDO LISTO [E]", 14, { FontFace = F.monoBold, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextColor3 = T.cyanHi, ZIndex = Z.hudTop + 1, TextStrokeTransparency = 0.25 })
	r.shieldText.Parent = shBack

	r.kills = label("BAJAS 0", 16, { FontFace = F.monoBold, Position = UDim2.fromOffset(12, 94), Size = UDim2.fromOffset(156, 24), TextColor3 = T.text, ZIndex = Z.hudTop })
	r.kills.Parent = suit
	r.shieldBadge = label("PULSO CD 20s", 15, { FontFace = F.monoBold, Position = UDim2.fromOffset(168, 94), Size = UDim2.fromOffset(166, 24), TextXAlignment = RIGHT, TextColor3 = T.cyanHi, ZIndex = Z.hudTop })
	r.shieldBadge.Parent = suit

	r.wave = label("OLEADA 01/18", 34, { Name = "Wave", FontFace = F.hero, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(420, 40), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.12, TextWrapped = false, TextScaled = true, ZIndex = Z.hud })
	new("UITextSizeConstraint", { MinTextSize = 20, MaxTextSize = 34 }).Parent = r.wave
	r.wave.Parent = h
	r.timer = label("T+ 00:00", 22, { Name = "Timer", FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54), Size = UDim2.fromOffset(240, 26), TextXAlignment = CENTER, TextColor3 = T.cyanHi, TextStrokeTransparency = 0.22, ZIndex = Z.hud })
	r.timer.Parent = h
	r.biome = label("ETAPA 1 · " .. Content.Biomes[1].name, 18, { Name = "Biome", FontFace = F.display, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 82), Size = UDim2.fromOffset(480, 24), TextXAlignment = CENTER, TextColor3 = BIOME_COLORS[1], TextStrokeTransparency = 0.18, TextWrapped = false, TextScaled = true, ZIndex = Z.hud })
	new("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 18 }).Parent = r.biome
	r.biome.Parent = h
	r.zoneBadge = label("ZONA: CRÁTER DEL MÓDULO", 15, { Name = "ZoneBadge", FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 108), Size = UDim2.fromOffset(480, 22), TextXAlignment = CENTER, TextColor3 = ZONE_COLORS[1], TextStrokeTransparency = 0.15, TextWrapped = false, TextScaled = true, ZIndex = Z.hud })
	new("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 15 }).Parent = r.zoneBadge
	r.zoneBadge.Parent = h

	local bossWrap = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 134), Size = UDim2.new(0.38, 0, 0, 52), BackgroundTransparency = 1, Visible = false })
	bossWrap.Parent = h
	r.bossWrap = bossWrap
	r.bossName = label("", 20, { FontFace = F.hero, TextColor3 = T.orange, TextXAlignment = CENTER, Size = UDim2.new(1, 0, 0, 24), TextStrokeTransparency = 0.2, ZIndex = Z.hud })
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
			Position = UDim2.fromOffset(12 + (i - 1) * 87, 38), Size = UDim2.fromOffset(82, 42), BackgroundColor3 = T.bg, BackgroundTransparency = 0.15,
			Text = Content.Pieces[i].short, TextSize = 18, FontFace = F.monoBold, TextColor3 = T.dim, BorderSizePixel = 0, ZIndex = Z.hudTop,
		})
		Ui.corner(2).Parent = cell
		Ui.stroke(T.line, 1, 0).Parent = cell
		cell.Parent = ship
		r.pieces[i] = cell
	end

	r.pauseBtn = button("   PAUSA", click(function()
		send("pause")
	end), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 118), Size = UDim2.fromOffset(118, 44), ZIndex = Z.hudTop, FontFace = F.display, TextSize = 16 }, "ghost")
	r.pauseBtn.Parent = h
	local pGlyph = Ui.navGlyph("pause", 16, T.cyanHi)
	pGlyph.Position = UDim2.fromOffset(12, 14)
	pGlyph.ZIndex = Z.hudTop + 1
	pGlyph.Parent = r.pauseBtn

	r.hudMenuBtn = button("   MENÚ", click(function()
		send("menu", "direct")
	end), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -142, 0, 118), Size = UDim2.fromOffset(114, 44), ZIndex = Z.hudTop, FontFace = F.display, TextSize = 16 }, "ghost")
	r.hudMenuBtn.Parent = h
	local mGlyph = Ui.navGlyph("menu", 16, T.orange)
	mGlyph.Position = UDim2.fromOffset(12, 14)
	mGlyph.ZIndex = Z.hudTop + 1
	mGlyph.Parent = r.hudMenuBtn

	r.exitBtn = button("SALIR", click(function()
		send("menu")
	end), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 118), Size = UDim2.fromOffset(130, 44), ZIndex = Z.hudTop, Visible = false }, "danger")
	r.exitBtn.Parent = h

	-- Ranura visual de Auto-Láser + 2 habilidades activas con vista 3D integrada
	local autoCard = new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -264, 1, -(touch and 160 or 28)),
		Size = UDim2.fromOffset(92, 112),
		BackgroundColor3 = T.panel,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = Z.hud,
	})
	Ui.corner(10).Parent = autoCard
	Ui.stroke(T.gold, 1.8, 0.15).Parent = autoCard
	local autoVp = Ui.skillIcon3D("laser", 62, T.gold, 0.7)
	autoVp.AnchorPoint = Vector2.new(0.5, 0)
	autoVp.Position = UDim2.new(0.5, 0, 0, 8)
	autoVp.ZIndex = Z.hudTop
	autoVp.Parent = autoCard
	label("LÁSER", 14, { FontFace = F.display, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 0, 18), TextColor3 = T.gold, TextWrapped = false, ZIndex = Z.hudTop }).Parent = autoCard
	label("AUTO", 13, { FontFace = F.monoBold, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 89), Size = UDim2.new(1, 0, 0, 18), TextColor3 = T.dim, TextWrapped = false, ZIndex = Z.hudTop }).Parent = autoCard
	autoCard.Parent = h
	r.autoSlot = autoCard

	r.skills = {}
	local skillKinds3D = { "dash", "shield" }
	for i = 1, 2 do
		local sk = Content.Skills[i]
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24 - (2 - i) * 116, 1, -(touch and 160 or 28)), Size = UDim2.fromOffset(106, 112),
			BackgroundColor3 = T.panel, BackgroundTransparency = 0.05, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = Z.hud,
		})
		Ui.corner(12).Parent = b
		local stroke = Ui.stroke(T.cyanHi, 2.2, 0)
		stroke.Parent = b
		local vp = Ui.skillIcon3D(skillKinds3D[i], 64, T.cyanHi, if i == 1 then 1.0 else -0.85)
		vp.AnchorPoint = Vector2.new(0.5, 0)
		vp.Position = UDim2.new(0.5, 0, 0, 8)
		vp.ZIndex = Z.hudTop
		vp.Parent = b
		label(sk.short, 15, { FontFace = F.display, TextXAlignment = CENTER, Position = UDim2.fromOffset(2, 73), Size = UDim2.new(1, -4, 0, 18), TextColor3 = T.cyanHi, TextWrapped = false, ZIndex = Z.hudTop }).Parent = b
		local keyLbl = label(if touch then "TOCAR" elseif inputMode == "gamepad" then (if i == 1 then "[X/L1]" else "[B/R1]") else "[" .. sk.key .. "]", 14, { FontFace = F.monoBold, TextXAlignment = CENTER, Position = UDim2.fromOffset(4, 90), Size = UDim2.new(1, -8, 0, 18), TextColor3 = T.text, TextWrapped = false, TextScaled = true, ZIndex = Z.hudTop })
		new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = keyLbl
		keyLbl.Parent = b
		local cdOverlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BackgroundTransparency = 0.14, BorderSizePixel = 0, Visible = false, ZIndex = Z.hudTop + 2 })
		Ui.corner(12).Parent = cdOverlay
		cdOverlay.Parent = b
		local cdText = label("", 32, { FontFace = F.monoBold, TextXAlignment = CENTER, TextColor3 = T.text, Size = UDim2.fromScale(1, 1), ZIndex = Z.hudTop + 3 })
		cdText.Parent = cdOverlay
		b.Activated:Connect(function()
			useSkill(i)
		end)
		b.Parent = h
		r.skills[i] = { button = b, overlay = cdOverlay, text = cdText, stroke = stroke, keyLabel = keyLbl, ready = true }
	end

	-- Telemetría (datos NASA)
	local ticker = panel({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -(touch and 180 or 20)), Size = UDim2.fromOffset(470, 68), ZIndex = Z.hud }, "TELEMETRÍA · NASA ARCHIVO VERIFICADO")
	ticker.Parent = h
	r.tickerPanel = ticker
	r.tickerScale = new("UIScale", { Scale = 1 })
	r.tickerScale.Parent = ticker
	r.ticker = label("", 17, { FontFace = F.mono, Position = UDim2.fromOffset(12, 34), Size = UDim2.fromOffset(446, 26), ZIndex = Z.hudTop, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	r.ticker.Parent = ticker

	r.alert = label("", 44, { FontFace = F.hero, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.24), Size = UDim2.new(0.9, 0, 0, 52), TextXAlignment = CENTER, TextColor3 = T.orange, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.18, TextTransparency = 1, ZIndex = Z.hudTop })
	r.alert.Parent = h
	r.alertSub = label("", 20, { FontFace = F.semi, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.24, 48), Size = UDim2.new(0.9, 0, 0, 30), TextXAlignment = CENTER, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.18, TextTransparency = 1, ZIndex = Z.hudTop })
	r.alertSub.Parent = h

	local tut = panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(640, 98), Visible = false, ZIndex = Z.hud }, "TUTORIAL 1/8")
	tut.Parent = h
	r.tut = tut
	r.tutText = label("", 20, { FontFace = F.semi, Position = UDim2.fromOffset(14, 34), Size = UDim2.fromOffset(612, 56), ZIndex = Z.hudTop, TextYAlignment = TOP, TextScaled = true })
	new("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 20 }).Parent = r.tutText
	r.tutText.Parent = tut

	r.hint = label(Content.Controls, 17, { FontFace = F.mono, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(0.46, 0, 0, 48), TextXAlignment = CENTER, TextColor3 = T.text, TextStrokeTransparency = 0.22, TextWrapped = true, TextScaled = true, Visible = false, ZIndex = Z.hud })
	new("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 17 }).Parent = r.hint
	r.hint.Parent = h

	r.arrow = label("▲", 42, { FontFace = F.bold, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(50, 50), TextXAlignment = CENTER, TextColor3 = T.gold, TextStrokeTransparency = 0.12, Visible = false, ZIndex = Z.hud })
	r.arrow.Parent = h

	local toast = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 176), Size = UDim2.fromOffset(386, 174), Visible = false, ZIndex = Z.hud }, "MÓDULO RECUPERADO")
	toast.Parent = h
	r.toast = toast
	r.toastRar = label("", 17, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 34), Size = UDim2.fromOffset(358, 22), ZIndex = Z.hudTop })
	r.toastRar.Parent = toast
	r.toastName = label("", 22, { FontFace = F.display, Position = UDim2.fromOffset(14, 56), Size = UDim2.fromOffset(358, 26), ZIndex = Z.hudTop })
	r.toastName.Parent = toast
	r.toastDesc = label("", 18, { FontFace = F.semi, Position = UDim2.fromOffset(14, 84), Size = UDim2.fromOffset(358, 24), TextColor3 = T.gold, ZIndex = Z.hudTop })
	r.toastDesc.Parent = toast
	r.toastFact = label("", 17, { Position = UDim2.fromOffset(14, 110), Size = UDim2.fromOffset(358, 56), TextColor3 = T.text, TextYAlignment = TOP, TextScaled = true, ZIndex = Z.hudTop })
	new("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 17 }).Parent = r.toastFact
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
	local shade = new("Frame", { Size = UDim2.new(0.37, 0, 1, 0), BackgroundColor3 = T.bg, BackgroundTransparency = 0.16, BorderSizePixel = 0, ZIndex = Z.overlay })
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.68, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}).Parent = shade
	shade.Parent = m
	r.menuShade = shade

	local col = new("Frame", {
		Name = "MenuColumn",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 28, 0.5, 16),
		Size = UDim2.fromOffset(376, 536),
		BackgroundTransparency = 1,
		ZIndex = Z.panel,
	})
	col:SetAttribute("BaseH", 536)
	col.Parent = m
	local colScale = new("UIScale", { Name = "Pop", Scale = 1 })
	colScale.Parent = col
	r.menuCol = col
	r.menuColScale = colScale

	-- 1. Cabecera de marca (limpia, debajo de la barra superior de Roblox).
	local dot = new("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = T.orange, BorderSizePixel = 0, ZIndex = Z.content })
	Ui.corner(4).Parent = dot
	dot.Parent = col
	local kicker = label("CRÁTER JEZERO · SOL 01", 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(362, 18), TextColor3 = T.orange, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = kicker
	kicker.Parent = col

	local titleLbl = label(Content.Title, 42, { FontFace = F.title, Position = UDim2.fromOffset(-2, 18), Size = UDim2.fromOffset(376, 46), TextColor3 = T.text, TextStrokeTransparency = 0.25, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 24, MaxTextSize = 42 }).Parent = titleLbl
	titleLbl.Parent = col

	new("Frame", { Position = UDim2.fromOffset(0, 74), Size = UDim2.fromOffset(38, 3), BackgroundColor3 = T.gold, BorderSizePixel = 0, ZIndex = Z.content }).Parent = col
	label("SUPERVIVENCIA EN MARTE", 16, { FontFace = F.display, Position = UDim2.fromOffset(48, 64), Size = UDim2.fromOffset(328, 22), TextColor3 = T.gold, TextStrokeTransparency = 0.3, TextWrapped = false, ZIndex = Z.content }).Parent = col
	local hook = label("Recupera las 4 piezas de tu módulo y despega.", 15, { FontFace = F.semi, Position = UDim2.fromOffset(0, 85), Size = UDim2.fromOffset(376, 24), TextColor3 = Color3.fromHex("#E8F0FC"), TextStrokeTransparency = 0.35, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 15 }).Parent = hook
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

	-- Selector rápido de perfil (3 ranuras independientes de guardado).
	local profBar = new("Frame", {
		Name = "ProfileBar",
		Position = UDim2.fromOffset(0, 112),
		Size = UDim2.fromOffset(376, 36),
		BackgroundColor3 = T.panel,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = Z.panel,
	})
	Ui.corner(8).Parent = profBar
	Ui.stroke(T.cyan, 1.2, 0.35).Parent = profBar
	profBar.Parent = col

	local profIcon = Ui.navGlyph("profiles", 18, T.cyanHi)
	profIcon.Position = UDim2.fromOffset(10, 9)
	profIcon.ZIndex = Z.content + 1
	profIcon.Parent = profBar

	r.menuProfileLabel = label("PERFIL 1 · PILOTO 1", 14, { FontFace = F.display, Position = UDim2.fromOffset(34, 0), Size = UDim2.fromOffset(214, 36), TextColor3 = T.text, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = r.menuProfileLabel
	r.menuProfileLabel.Parent = profBar

	local profBtn = button("PERFILES (3)", click(function()
		show(r.profiles, true)
	end), { Position = UDim2.fromOffset(252, 4), Size = UDim2.fromOffset(118, 28), TextSize = 13, FontFace = F.monoBold, ZIndex = Z.content + 2 }, "ghost")
	profBtn.Parent = profBar

	-- Bloque de acciones deslizante (permite mostrar CONTINUAR CHECKPOINT sin solapamientos).
	local actionHost = new("Frame", {
		Name = "MenuActions",
		Position = UDim2.fromOffset(0, 156),
		Size = UDim2.fromOffset(376, 380),
		BackgroundTransparency = 1,
		ZIndex = Z.panel,
	})
	actionHost.Parent = col
	r.menuActions = actionHost

	local resumeBtn = new("TextButton", {
		Name = "BtnResume",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(376, 52),
		BackgroundColor3 = T.green,
		BackgroundTransparency = 0.04,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = Z.content,
	})
	Ui.corner(8).Parent = resumeBtn
	local resStroke = Ui.stroke(Color3.fromHex("#A8FFD0"), 1.4, 0.2)
	resStroke.Parent = resumeBtn
	r.menuResumeTitle = label("REANUDAR CHECKPOINT", 18, { FontFace = F.display, Position = UDim2.fromOffset(16, 5), Size = UDim2.fromOffset(300, 22), TextColor3 = T.bg, TextStrokeTransparency = 1, TextWrapped = false, ZIndex = Z.content + 1 })
	r.menuResumeTitle.Parent = resumeBtn
	r.menuResumeSub = label("Oleada 1/18 · Nivel 1", 13, { FontFace = F.monoBold, Position = UDim2.fromOffset(16, 27), Size = UDim2.fromOffset(300, 18), TextColor3 = Color3.fromHex("#092218"), TextStrokeTransparency = 1, TextWrapped = false, ZIndex = Z.content + 1 })
	r.menuResumeSub.Parent = resumeBtn
	local resGlyph = Ui.navGlyph("play", 20, T.bg)
	resGlyph.AnchorPoint = Vector2.new(1, 0.5)
	resGlyph.Position = UDim2.new(1, -16, 0.5, 0)
	resGlyph.ZIndex = Z.content + 1
	resGlyph.Parent = resumeBtn
	bindHover(resumeBtn, T.green, 0.04, Color3.fromHex("#70F5B0"), 0, resStroke, 0.2, 0.05)
	resumeBtn.Activated:Connect(click(function()
		send("resume")
	end))
	resumeBtn.Parent = actionHost
	r.menuResumeBtn = resumeBtn

	local stack = new("Frame", {
		Name = "ActionStack",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(376, 380),
		BackgroundTransparency = 1,
		ZIndex = Z.panel,
	})
	stack.Parent = actionHost
	r.menuStack = stack

	-- 2. Acciones de juego: boton principal prominente + fila de modos rapidos.
	local heroBg = Color3.fromHex("#FF6B35")
	local heroHover = Color3.fromHex("#FF8552")
	local hero = new("TextButton", {
		Name = "BtnPlay",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(376, 62),
		BackgroundColor3 = heroBg,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = Z.content,
	})
	Ui.corner(8).Parent = hero
	local heroStroke = Ui.stroke(Color3.fromHex("#FFB899"), 1.2, 0.45)
	heroStroke.Parent = hero
	local heroLip = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Color3.fromHex("#B84318"), BorderSizePixel = 0, ZIndex = Z.content })
	heroLip.Parent = hero
	label("INICIAR MISIÓN", 22, { FontFace = F.hero, Position = UDim2.fromOffset(18, 7), Size = UDim2.fromOffset(292, 26), TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.55, TextWrapped = false, ZIndex = Z.content + 1 }).Parent = hero
	local heroSub = label("Nueva partida · 18 oleadas en 3 etapas", 14, { FontFace = F.semi, Position = UDim2.fromOffset(18, 33), Size = UDim2.fromOffset(292, 22), TextColor3 = Color3.fromHex("#FFE4D6"), TextStrokeTransparency = 1, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
	new("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 14 }).Parent = heroSub
	heroSub.Parent = hero
	local playPill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = T.bg, BackgroundTransparency = 0.65, BorderSizePixel = 0, ZIndex = Z.content + 1 })
	Ui.corner(8).Parent = playPill
	label("▶", 18, { FontFace = F.monoBold, Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, TextColor3 = Color3.new(1, 1, 1), ZIndex = Z.content + 2 }).Parent = playPill
	playPill.Parent = hero
	bindHover(hero, heroBg, 0, heroHover, 0, heroStroke, 0.45, 0.15)
	hero.Activated:Connect(click(function()
		lastMode = "full"
		send("start", "full")
	end))
	hero.Parent = stack
	r.menuBtnPlay = hero

	local function darkCard(name: string, x: number, py: number, w: number, h: number, titleTxt: string, subTxt: string?, accent: Color3, fn: () -> ()): TextButton
		local b = new("TextButton", {
			Name = name,
			Position = UDim2.fromOffset(x, py),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = T.panel,
			BackgroundTransparency = 0.06,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = Z.content,
		})
		Ui.corner(8).Parent = b
		local st = Ui.stroke(accent, 1.2, 0.32)
		st.Parent = b
		local bar = new("Frame", { Position = UDim2.fromOffset(4, 10), Size = UDim2.new(0, 3, 1, -20), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = Z.content + 1 })
		Ui.corner(2).Parent = bar
		bar.Parent = b
		local titleW = if titleTxt == "HANGAR DEL TRAJE" then 212 else (w - 22)
		local tLbl = label(titleTxt, if subTxt then 16 else 15, { FontFace = F.display, Position = UDim2.fromOffset(14, 7), Size = UDim2.fromOffset(titleW, 20), TextColor3 = T.text, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
		new("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 16 }).Parent = tLbl
		tLbl.Parent = b
		if subTxt then
			local sLbl = label(subTxt, 14, { FontFace = F.body, Position = UDim2.fromOffset(14, 28), Size = UDim2.fromOffset(titleW, 18), TextColor3 = accent, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
			new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = sLbl
			sLbl.Parent = b
		end
		bindHover(b, T.panel, 0.06, T.panelHi, 0.02, st, 0.32, 0.05)
		b.Activated:Connect(click(fn))
		b.Parent = stack
		return b
	end

	darkCard("BtnDemo", 0, 72, 182, 52, "DEMO RÁPIDA", "Partida de 4 min", T.cyanHi, function()
		lastMode = "demo"
		send("start", "demo")
	end)
	darkCard("BtnTutorial", 194, 72, 182, 52, "TUTORIAL", "Práctica guiada", T.gold, function()
		send("tutorial")
	end)

	-- 3. Progresion y utilidades.
	new("Frame", { Position = UDim2.fromOffset(0, 133), Size = UDim2.fromOffset(376, 1), BackgroundColor3 = T.line, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = Z.content }).Parent = stack

	local hangar = darkCard("BtnHangar", 0, 142, 376, 50, "HANGAR DEL TRAJE", "Mejoras permanentes", T.violet, function()
		show(r.shop, true)
	end)
	local sciPill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(122, 28), BackgroundColor3 = T.bg, BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = Z.content + 1 })
	Ui.corner(6).Parent = sciPill
	Ui.stroke(T.gold, 1, 0.25).Parent = sciPill
	sciPill.Parent = hangar
	r.menuScience = label("0 CIENCIA", 14, { FontFace = F.monoBold, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), TextXAlignment = CENTER, TextColor3 = T.gold, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 2 })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = r.menuScience
	r.menuScience.Parent = sciPill

	local function utilBtn(name: string, x: number, txt: string, fn: () -> ())
		local b = new("TextButton", {
			Name = name,
			Position = UDim2.fromOffset(x, 200),
			Size = UDim2.fromOffset(182, 42),
			BackgroundColor3 = T.panel,
			BackgroundTransparency = 0.08,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = Z.content,
		})
		Ui.corner(8).Parent = b
		local st = Ui.stroke(T.line, 1.1, 0.2)
		st.Parent = b
		local l = label(txt, 14, { FontFace = F.display, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), TextXAlignment = CENTER, TextColor3 = T.text, TextWrapped = false, TextScaled = true, ZIndex = Z.content + 1 })
		new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = l
		l.Parent = b
		bindHover(b, T.panel, 0.08, T.panelHi, 0.02, st, 0.2, 0.1, T.line, T.cyanHi)
		b.Activated:Connect(click(fn))
		b.Parent = stack
	end
	utilBtn("BtnSettings", 0, "AJUSTES Y MANDOS", function()
		returnTarget = "menu"
		show(r.settings, true)
	end)
	utilBtn("BtnCredits", 194, "CRÉDITOS Y FUENTES", function()
		show(r.credits, true)
	end)

	-- 4. Hoja de servicio compacta en 3 columnas limpias.
	local sheet = new("Frame", {
		Name = "ServiceSheet",
		Position = UDim2.fromOffset(0, 252),
		Size = UDim2.fromOffset(376, 86),
		BackgroundColor3 = T.panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = Z.panel,
	})
	Ui.corner(8).Parent = sheet
	Ui.stroke(T.line, 1.1, 0.28).Parent = sheet
	sheet.Parent = stack

	label("HOJA DE SERVICIO", 13, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(152, 18), TextColor3 = T.dim, TextWrapped = false, ZIndex = Z.content }).Parent = sheet
	r.menuStatus = label("GUARDADO ACTIVO", 13, { FontFace = F.monoBold, Position = UDim2.fromOffset(170, 6), Size = UDim2.fromOffset(192, 18), TextXAlignment = RIGHT, TextColor3 = T.green, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 13 }).Parent = r.menuStatus
	r.menuStatus.Parent = sheet

	new("Frame", { Position = UDim2.fromOffset(12, 27), Size = UDim2.fromOffset(352, 1), BackgroundColor3 = T.line, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = Z.content }).Parent = sheet
	new("Frame", { Position = UDim2.fromOffset(125, 34), Size = UDim2.fromOffset(1, 40), BackgroundColor3 = T.line, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = Z.content }).Parent = sheet
	new("Frame", { Position = UDim2.fromOffset(251, 34), Size = UDim2.fromOffset(1, 40), BackgroundColor3 = T.line, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = Z.content }).Parent = sheet

	local function statCol(x: number, hdr: string, colr: Color3, font: Font): TextLabel
		label(hdr, 12, { FontFace = F.monoBold, Position = UDim2.fromOffset(x, 32), Size = UDim2.fromOffset(112, 16), TextXAlignment = CENTER, TextColor3 = T.dim, TextWrapped = false, ZIndex = Z.content }).Parent = sheet
		local val = label("—", 16, { FontFace = font, Position = UDim2.fromOffset(x, 49), Size = UDim2.fromOffset(112, 24), TextXAlignment = CENTER, TextColor3 = colr, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
		new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 16 }).Parent = val
		val.Parent = sheet
		return val
	end
	r.statRuns = statCol(8, "MISIONES (VICT.)", T.text, F.monoBold)
	r.statTime = statCol(132, "MEJOR TIEMPO", T.cyanHi, F.monoBold)
	r.statBest = statCol(256, "NIVEL / BAJAS", T.gold, F.monoBold)

	-- 5. Nota legal discreta al pie de la columna.
	label("Este proyecto usa datos públicos de NASA. NASA no patrocina ni respalda este producto.", 13, {
		Position = UDim2.fromOffset(0, 346),
		Size = UDim2.fromOffset(376, 36),
		TextColor3 = T.dim,
		TextTransparency = 0,
		TextStrokeTransparency = 0.45,
		TextYAlignment = TOP,
		ZIndex = Z.content,
	}).Parent = stack
end

local function buildMenu()
	-- Hangar
	local s = overlay("Shop", 0.12)
	r.shop = s
	local sp = centerPanel(s, 790, 704, "HANGAR · MEJORAS PERMANENTES", T.violet)
	label("HANGAR DE MEJORAS", 30, { FontFace = F.hero, Position = UDim2.fromOffset(24, 34), Size = UDim2.fromOffset(340, 34), TextColor3 = T.gold, TextStrokeTransparency = 0.15, ZIndex = Z.content }).Parent = sp
	r.shopScience = label("", 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(358, 38), Size = UDim2.fromOffset(408, 28), TextXAlignment = RIGHT, TextColor3 = T.cyanHi, ZIndex = Z.content })
	r.shopScience.Parent = sp
	r.shopRows = {}
	for i, id in Balance.Meta.Order do
		local txt = (Content.Meta :: any)[id]
		local col = META_COLORS[id] or T.cyanHi
		local row = new("Frame", { Position = UDim2.fromOffset(24, 74 + (i - 1) * 66), Size = UDim2.new(1, -48, 0, 60), BackgroundColor3 = T.bg, BackgroundTransparency = 0.14, BorderSizePixel = 0, ZIndex = Z.panel })
		Ui.corner(4).Parent = row
		Ui.stroke(col, 1.2, 0.55).Parent = row
		new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = Z.content }).Parent = row
		row.Parent = sp
		label(txt.name, 20, { FontFace = F.display, Position = UDim2.fromOffset(16, 5), Size = UDim2.fromOffset(436, 26), TextColor3 = col, ZIndex = Z.content }).Parent = row
		label(txt.desc, 17, { Position = UDim2.fromOffset(16, 31), Size = UDim2.fromOffset(436, 24), TextColor3 = T.text, ZIndex = Z.content, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd }).Parent = row
		local lvl = label("0/5", 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(460, 7), Size = UDim2.fromOffset(70, 46), TextXAlignment = CENTER, TextColor3 = col, ZIndex = Z.content })
		lvl.Parent = row
		local b = button("", click(function()
			send("buy", id)
		end), { Position = UDim2.fromOffset(540, 7), Size = UDim2.fromOffset(188, 46), ZIndex = Z.content, TextSize = 18 }, "gold")
		b.Parent = row
		r.shopRows[id] = { lvl = lvl, btn = b }
	end
	local shopBack = button("VOLVER AL MENÚ", click(function()
		show(r.shop, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(260, 50), ZIndex = Z.content })
	shopBack.Parent = sp
	r.shopBackBtn = shopBack

	-- Perfiles (3 ranuras independientes con Checkpoint)
	local pf = overlay("Profiles", 0.12)
	r.profiles = pf
	local pfp = centerPanel(pf, 780, 540, "PERFILES DE GUARDADO · 3 RANURAS", T.cyanHi)
	label("ELIGE TU PERFIL DE PILOTO", 28, { FontFace = F.hero, Position = UDim2.fromOffset(24, 34), Size = UDim2.fromOffset(460, 34), TextColor3 = T.cyanHi, TextStrokeTransparency = 0.15, ZIndex = Z.content }).Parent = pfp
	label("Cada perfil conserva ciencia, mejoras y checkpoint propio.", 16, { FontFace = F.semi, Position = UDim2.fromOffset(24, 68), Size = UDim2.new(1, -48, 0, 22), TextColor3 = T.dim, ZIndex = Z.content }).Parent = pfp
	r.profileCards = {}
	for slot = 1, 3 do
		local py = 100 + (slot - 1) * 118
		local card = new("Frame", { Position = UDim2.fromOffset(24, py), Size = UDim2.new(1, -48, 0, 106), BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = Z.panel })
		Ui.corner(6).Parent = card
		local st = Ui.stroke(T.line, 1.5, 0.2)
		st.Parent = card
		card.Parent = pfp
		local bar = new("Frame", { Size = UDim2.new(0, 5, 1, 0), BackgroundColor3 = T.cyanHi, BorderSizePixel = 0, ZIndex = Z.content })
		bar.Parent = card
		local title = label("PERFIL " .. slot, 20, { FontFace = F.display, Position = UDim2.fromOffset(16, 8), Size = UDim2.fromOffset(390, 26), TextColor3 = T.text, ZIndex = Z.content })
		title.Parent = card
		local stats = label("", 16, { FontFace = F.mono, Position = UDim2.fromOffset(16, 36), Size = UDim2.fromOffset(430, 24), TextColor3 = T.gold, ZIndex = Z.content })
		stats.Parent = card
		local cp = label("", 16, { FontFace = F.semi, Position = UDim2.fromOffset(16, 66), Size = UDim2.fromOffset(430, 26), TextColor3 = T.green, ZIndex = Z.content })
		cp.Parent = card
		local useBtn = button("USAR PERFIL", click(function()
			send("selectProfile", slot)
			show(r.profiles, false)
		end), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -138, 0.5, 0), Size = UDim2.fromOffset(156, 46), TextSize = 16, ZIndex = Z.content }, "primary")
		useBtn.Parent = card
		local rstBtn = button("BORRAR", click(function()
			send("resetProfile", slot)
		end), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(110, 46), TextSize = 16, ZIndex = Z.content }, "danger")
		rstBtn.Parent = card
		r.profileCards[slot] = { card = card, stroke = st, bar = bar, title = title, stats = stats, cp = cp, useBtn = useBtn, rstBtn = rstBtn }
	end
	local profBack = button("VOLVER AL MENÚ", click(function()
		show(r.profiles, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(260, 50), ZIndex = Z.content }, "ghost")
	profBack.Parent = pfp
	r.profilesBackBtn = profBack

	-- Ajustes y Controles
	local st = overlay("Settings", 0.12)
	r.settings = st
	local stp = centerPanel(st, 680, 558, "AJUSTES Y CONTROLES", T.green)
	label("AJUSTES DEL TRAJE", 28, { FontFace = F.hero, Position = UDim2.fromOffset(24, 34), Size = UDim2.fromOffset(440, 32), TextColor3 = T.green, TextStrokeTransparency = 0.15, ZIndex = Z.content }).Parent = stp
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
	r.audioValue = stepper(stp, 230, "AUDIO GENERAL", function()
		return if S.muted then "SILENCIO" else "ACTIVADO"
	end, function()
		S.muted = not S.muted
	end, function()
		S.muted = not S.muted
	end)
	local ctrlBox = new("Frame", { Position = UDim2.fromOffset(24, 286), Size = UDim2.new(1, -48, 0, 184), BackgroundColor3 = T.bg, BackgroundTransparency = 0.14, BorderSizePixel = 0, ZIndex = Z.panel })
	Ui.corner(4).Parent = ctrlBox
	Ui.stroke(T.green, 1.2, 0.45).Parent = ctrlBox
	ctrlBox.Parent = stp
	label("CONTROLES POR PLATAFORMA", 15, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(290, 22), TextColor3 = T.green, TextWrapped = false, ZIndex = Z.content }).Parent = ctrlBox
	r.platformBadge = label("", 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(310, 8), Size = UDim2.new(1, -324, 0, 22), TextXAlignment = RIGHT, TextColor3 = T.cyanHi, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 14 }).Parent = r.platformBadge
	r.platformBadge.Parent = ctrlBox
	new("Frame", { Position = UDim2.fromOffset(14, 33), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = T.line, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = Z.content }).Parent = ctrlBox
	local ctrlLines = {
		{ k = "PC / WEB", d = "WASD o Flechas ↑↓←→ mover · Ratón cámara · Rueda zoom · Espacio saltar · Q/E habs · 1-3 cartas · P pausa", c = T.cyanHi },
		{ k = "CONSOLA / MANDO", d = "Stick Izq mover · Stick Der cámara · A saltar · X/L1 y B/R1 habs · ◀▲▶ elegir carta · Start pausa", c = T.gold },
		{ k = "MÓVIL / TÁCTIL", d = "Joystick izq mover · Arrastrar derecha cámara · Pellizcar zoom · Botones saltar, RCS, Pulso y tocar cartas", c = T.green },
	}
	for idx, cl in ctrlLines do
		local ly = 38 + (idx - 1) * 47
		local kl = label(cl.k, 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, ly), Size = UDim2.fromOffset(150, 44), TextColor3 = cl.c, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
		new("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 14 }).Parent = kl
		kl.Parent = ctrlBox
		local dl = label(cl.d, 15, { FontFace = F.semi, Position = UDim2.fromOffset(170, ly), Size = UDim2.new(1, -184, 0, 44), TextColor3 = T.text, TextScaled = true, ZIndex = Z.content })
		new("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 15 }).Parent = dl
		dl.Parent = ctrlBox
	end
	local stBack = button("VOLVER", click(function()
		show(r.settings, false)
		if (phase == "run" or phase == "tutorial") and returnTarget == "pause" then
			show(r.pause, true)
		end
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(260, 50), ZIndex = Z.content })
	stBack.Parent = stp
	r.settingsBackBtn = stBack

	-- Créditos
	local c = overlay("Credits", 0.12)
	r.credits = c
	local cp = centerPanel(c, 800, 620, "CRÉDITOS Y FUENTES", T.cyanHi)
	label("ARCHIVO DE FUENTES Y CRÉDITOS", 28, { FontFace = F.hero, Position = UDim2.fromOffset(24, 34), Size = UDim2.new(1, -48, 0, 32), TextColor3 = T.cyanHi, TextStrokeTransparency = 0.15, ZIndex = Z.content }).Parent = cp
	label(table.concat(Content.Credits, "\n"), 18, { Position = UDim2.fromOffset(24, 72), Size = UDim2.new(1, -48, 1, -150), TextYAlignment = TOP, TextColor3 = T.text, LineHeight = 1.15, ZIndex = Z.content }).Parent = cp
	local crBack = button("VOLVER AL MENÚ", click(function()
		show(r.credits, false)
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(260, 50), ZIndex = Z.content })
	crBack.Parent = cp
	r.creditsBackBtn = crBack
end

-- ---------------------------------------------------------------- Cartas, Briefing, Pieza, Pausa, Resumen
local function buildOverlays()
	local lv = overlay("LevelUp", 0.24)
	r.level = lv
	r.levelTag = label("SUBIDA DE NIVEL", 18, { FontFace = F.monoBold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.new(0.9, 0, 0, 24), TextXAlignment = CENTER, TextColor3 = T.cyanHi, ZIndex = Z.content })
	r.levelTag.Parent = lv
	r.levelTitle = label("", 46, { FontFace = F.hero, TextColor3 = T.gold, TextStrokeTransparency = 0.15, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.1, 26), Size = UDim2.new(0.92, 0, 0, 52), TextXAlignment = CENTER, TextWrapped = false, TextScaled = true, ZIndex = Z.content })
	new("UITextSizeConstraint", { MinTextSize = 22, MaxTextSize = 46 }).Parent = r.levelTitle
	r.levelTitle.Parent = lv
	local row = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(960, 340), BackgroundTransparency = 1, ZIndex = Z.panel })
	Ui.list(22, true).Parent = row
	row.Parent = lv
	r.levelRow = row
	r.cards = {}
	for i = 1, 3 do
		local card = new("TextButton", { Size = UDim2.fromOffset(304, 340), BackgroundColor3 = T.panel, BackgroundTransparency = 0.04, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, ZIndex = Z.panel })
		Ui.corner(4).Parent = card
		local stroke = Ui.stroke(T.cyanHi, 2, 0.1)
		stroke.Parent = card
		local band = new("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T.cyanHi, BorderSizePixel = 0, ZIndex = Z.content })
		band.Parent = card
		local rar = label("", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(180, 24), ZIndex = Z.content })
		rar.Parent = card
		local keyLbl = label(if touch then "TOCAR" elseif inputMode == "gamepad" then (if i == 1 then "[◀]" elseif i == 2 then "[▲]" else "[▶]") else "[" .. i .. "]", 17, { FontFace = F.monoBold, Position = UDim2.fromOffset(204, 18), Size = UDim2.fromOffset(82, 24), TextXAlignment = RIGHT, TextColor3 = T.dim, TextWrapped = false, ZIndex = Z.content })
		keyLbl.Parent = card
		local name = label("", 26, { FontFace = F.display, Position = UDim2.fromOffset(18, 48), Size = UDim2.fromOffset(268, 66), TextStrokeTransparency = 0.2, ZIndex = Z.content, TextYAlignment = TOP })
		name.Parent = card
		local desc = label("", 19, { FontFace = F.semi, Position = UDim2.fromOffset(18, 118), Size = UDim2.fromOffset(268, 54), TextColor3 = T.text, ZIndex = Z.content, TextYAlignment = TOP })
		desc.Parent = card
		local factBox = new("Frame", { Position = UDim2.fromOffset(14, 178), Size = UDim2.fromOffset(276, 88), BackgroundColor3 = T.bg, BackgroundTransparency = 0.14, BorderSizePixel = 0, ZIndex = Z.content })
		Ui.corner(4).Parent = factBox
		Ui.stroke(T.cyanHi, 1.2, 0.45).Parent = factBox
		factBox.Parent = card
		label("DATO REAL", 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(260, 18), TextColor3 = T.cyanHi, ZIndex = Z.content + 1 }).Parent = factBox
		local fact = label("", 16, { FontFace = F.body, Position = UDim2.fromOffset(8, 22), Size = UDim2.fromOffset(260, 62), TextColor3 = T.text, TextTransparency = 0, ZIndex = Z.content + 1, TextYAlignment = TOP, TextScaled = true })
		new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 13 }).Parent = fact
		fact.Parent = factBox
		local lvlText = label("", 18, { FontFace = F.monoBold, Position = UDim2.fromOffset(18, 272), Size = UDim2.fromOffset(268, 24), TextColor3 = T.gold, ZIndex = Z.content })
		lvlText.Parent = card
		local _, lvlFill = Ui.bar(card, UDim2.fromOffset(18, 302), UDim2.fromOffset(268, 10), T.cyanHi, Z.content)
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

	-- Informe tÃ¡ctico al iniciar partida o desde Pausa (armamento 3D + zonas + eventos)
	local br = overlay("Briefing", 0.12)
	r.briefing = br
	local bp = centerPanel(br, 860, 560, "INFORME DE DESPLIEGUE · CRÁTER JEZERO", T.cyanHi)
	label("SISTEMAS DE COMBATE Y SUPERFICIE", 28, { FontFace = F.hero, Position = UDim2.fromOffset(24, 34), Size = UDim2.new(1, -48, 0, 34), TextColor3 = T.gold, TextStrokeTransparency = 0.15, ZIndex = Z.content }).Parent = bp
	local skEntries = {
		{ kind = "laser", title = Content.AutoWeapon.name, tag = Content.AutoWeapon.tag, desc = Content.AutoWeapon.desc, col = T.gold },
		{ kind = "dash", title = Content.Skills[1].name, tag = "[Q / X] · CD " .. Balance.Skills.Dash.Cooldown .. "s", desc = Content.Skills[1].desc, col = T.cyanHi },
		{ kind = "shield", title = Content.Skills[2].name, tag = "[E / B] · CD " .. Balance.Skills.Pulse.Cooldown .. "s", desc = Content.Skills[2].desc, col = T.cyanHi },
	}
	for idx, entry in skEntries do
		local cx = 24 + (idx - 1) * 276
		local box = new("Frame", { Position = UDim2.fromOffset(cx, 76), Size = UDim2.fromOffset(262, 260), BackgroundColor3 = T.bg, BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = Z.panel })
		Ui.corner(6).Parent = box
		Ui.stroke(entry.col, 1.4, 0.25).Parent = box
		box.Parent = bp
		local vp = Ui.skillIcon3D(entry.kind, 84, entry.col, if idx == 2 then 0.9 else -0.8)
		vp.AnchorPoint = Vector2.new(0.5, 0)
		vp.Position = UDim2.new(0.5, 0, 0, 12)
		vp.ZIndex = Z.content + 1
		vp.Parent = box
		label(entry.title, 19, { FontFace = F.display, Position = UDim2.fromOffset(12, 102), Size = UDim2.fromOffset(238, 24), TextXAlignment = CENTER, TextColor3 = entry.col, ZIndex = Z.content + 1 }).Parent = box
		label(entry.tag, 14, { FontFace = F.monoBold, Position = UDim2.fromOffset(12, 128), Size = UDim2.fromOffset(238, 20), TextXAlignment = CENTER, TextColor3 = T.gold, ZIndex = Z.content + 1 }).Parent = box
		local dl = label(entry.desc, 15, { FontFace = F.body, Position = UDim2.fromOffset(12, 154), Size = UDim2.fromOffset(238, 96), TextColor3 = T.text, TextYAlignment = TOP, TextScaled = true, ZIndex = Z.content + 1 })
		new("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 15 }).Parent = dl
		dl.Parent = box
	end
	local envBox = new("Frame", { Position = UDim2.fromOffset(24, 348), Size = UDim2.new(1, -48, 0, 134), BackgroundColor3 = T.bg, BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = Z.panel })
	Ui.corner(6).Parent = envBox
	Ui.stroke(T.orange, 1.2, 0.35).Parent = envBox
	envBox.Parent = bp
	label("ZONAS DE MARTE, COFRES Y ANOMALÍAS", 15, { FontFace = F.monoBold, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 20), TextColor3 = T.orange, ZIndex = Z.content + 1 }).Parent = envBox
	local envTxt = label(table.concat(Content.Briefing, "\n"), 15, { FontFace = F.semi, Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 0, 96), TextColor3 = T.text, TextYAlignment = TOP, TextScaled = true, LineHeight = 1.15, ZIndex = Z.content + 1 })
	new("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 15 }).Parent = envTxt
	envTxt.Parent = envBox
	local deployBtn = button("DESPLEGAR AHORA [ESPACIO]", click(function()
		Hud.closeBriefing()
	end), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(360, 50), ZIndex = Z.content }, "primary")
	deployBtn.Parent = bp
	r.briefDeployBtn = deployBtn

	local pc = overlay("Piece", 0.14)
	r.piece = pc
	local pp = centerPanel(pc, 760, 500, "PIEZA RECUPERADA", T.gold)
	r.pieceHead = label("", 20, { FontFace = F.monoBold, Position = UDim2.fromOffset(24, 38), Size = UDim2.new(1, -48, 0, 26), TextColor3 = T.gold, ZIndex = Z.content })
	r.pieceHead.Parent = pp
	r.pieceName = label("", 36, { FontFace = F.hero, Position = UDim2.fromOffset(24, 66), Size = UDim2.new(1, -48, 0, 46), TextColor3 = T.gold, TextStrokeTransparency = 0.2, ZIndex = Z.content, TextScaled = true })
	new("UITextSizeConstraint", { MinTextSize = 22, MaxTextSize = 36 }).Parent = r.pieceName
	r.pieceName.Parent = pp
	r.pieceBonus = label("", 20, { FontFace = F.display, Position = UDim2.fromOffset(24, 118), Size = UDim2.new(1, -48, 0, 48), TextColor3 = T.gold, ZIndex = Z.content, TextYAlignment = TOP })
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

	-- Menú de Pausa estilo videojuego con iconos y checkpoint
	local pa = overlay("Pause", 0.14)
	r.pause = pa
	local pap = centerPanel(pa, 480, 548, "MISIÓN EN PAUSA", T.orange)
	label("PAUSA", 44, { FontFace = F.hero, TextColor3 = T.orange, TextStrokeTransparency = 0.15, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 48), ZIndex = Z.content }).Parent = pap
	r.pauseSaveNote = label("", 15, { FontFace = F.monoBold, TextColor3 = T.green, TextXAlignment = CENTER, Position = UDim2.fromOffset(20, 82), Size = UDim2.new(1, -40, 0, 22), ZIndex = Z.content })
	r.pauseSaveNote.Parent = pap

	local function pauseItem(y: number, labelTxt: string, glyphKind: string, kind: string, fn: () -> ()): TextButton
		local b = button("    " .. labelTxt, fn, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.fromOffset(370, 50), TextSize = 18, FontFace = F.display, ZIndex = Z.content }, kind)
		local gCol = if kind == "ghost" then T.cyanHi elseif kind == "danger" then T.bg else T.bg
		local g = Ui.navGlyph(glyphKind, 20, gCol)
		g.Position = UDim2.fromOffset(18, 15)
		g.ZIndex = Z.content + 1
		g.Parent = b
		b.Parent = pap
		return b
	end

	local paCont = pauseItem(112, "CONTINUAR MISIÓN", "play", "primary", function()
		send("pause")
	end)
	r.pauseContinueBtn = paCont
	pauseItem(170, "GUARDAR CHECKPOINT", "save", "green", function()
		send("saveCheckpoint")
		r.pauseSaveNote.Text = "SOLICITANDO CHECKPOINT..."
	end)
	pauseItem(228, "HABILIDADES Y ZONAS", "help", "gold", function()
		briefingReturn = "pause"
		if r.briefDeployBtn then
			r.briefDeployBtn.Text = "VOLVER A PAUSA"
		end
		show(r.pause, false)
		show(r.briefing, true)
	end)
	pauseItem(286, "AJUSTES Y CONTROLES", "profiles", "ghost", function()
		returnTarget = "pause"
		show(r.pause, false)
		show(r.settings, true)
	end)
	r.pauseAudioBtn = pauseItem(344, "SONIDO: ACTIVADO", "audio", "ghost", function()
		Hud.settings.muted = not Hud.settings.muted
		onSettings()
		r.pauseAudioBtn.Text = if Hud.settings.muted then "    SONIDO: SILENCIO" else "    SONIDO: ACTIVADO"
		if r.audioValue then
			r.audioValue.Text = if Hud.settings.muted then "SILENCIO" else "ACTIVADO"
		end
	end)
	pauseItem(402, "REINICIAR MISIÓN", "play", "ghost", function()
		show(r.pause, false)
		send("restart")
	end)
	pauseItem(460, "VOLVER AL MENÚ", "menu", "danger", function()
		show(r.pause, false)
		send("menu", "direct")
	end)

	local su = overlay("Summary", 0.14)
	r.summary = su
	local sp = centerPanel(su, 760, 640, "INFORME DE MISIÓN", T.cyanHi)
	r.sumTitle = label("", 54, { FontFace = F.hero, TextStrokeTransparency = 0.2, TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 58), ZIndex = Z.content })
	r.sumTitle.Parent = sp
	r.sumSub = label("", 20, { TextXAlignment = CENTER, Position = UDim2.fromOffset(0, 92), Size = UDim2.new(1, 0, 0, 28), TextColor3 = T.text, ZIndex = Z.content })
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

function Hud.isBriefingOpen(): boolean
	return r.briefing ~= nil and r.briefing.Visible == true
end

function Hud.closeBriefing()
	if not r.briefing or not r.briefing.Visible then
		return
	end
	show(r.briefing, false)
	if briefingReturn == "pause" then
		briefingReturn = "none"
		show(r.pause, true)
	else
		briefingReturn = "none"
		send("briefOk")
	end
end

function Hud.back(): boolean
	if r.briefing and r.briefing.Visible then
		Hud.closeBriefing()
		return true
	end
	if r.settings and r.settings.Visible then
		show(r.settings, false)
		if (phase == "run" or phase == "tutorial") and returnTarget == "pause" then
			show(r.pause, true)
		end
		return true
	end
	if r.profiles and r.profiles.Visible then
		show(r.profiles, false)
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
		local baseMenuH = if r.menuResumeBtn and r.menuResumeBtn.Visible then 598 else 536
		if r.menuCol and r.menuColScale then
			r.menuCol.Size = UDim2.fromOffset(376, baseMenuH)
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
				local availH = math.max(200, (v.Y - topSafe) * 0.58)
				r.menuColScale.Scale = math.clamp(math.min(1, availH / baseMenuH, availW / 376), 0.48, 1)
				r.menuCol.AnchorPoint = Vector2.new(0.5, 1)
				r.menuCol.Position = UDim2.new(0.5, 0, 1, -18)
			else
				if r.menuShade then
					r.menuShade.Size = UDim2.new(0.37, 0, 1, 0)
					r.menuShade.Position = UDim2.fromOffset(0, 0)
					local grad = r.menuShade:FindFirstChildOfClass("UIGradient")
					if grad then
						grad.Rotation = 0
					end
				end
				local availH = math.max(160, v.Y - topSafe - 18)
				local availW = math.max(220, v.X * 0.35)
				r.menuColScale.Scale = math.clamp(math.min(1, availH / baseMenuH, availW / 376), 0.48, 1)
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
			r.suitPanel.Position = UDim2.fromOffset(16, topSafe + math.ceil(44 * cornerScale))
			r.shipPanel.Position = UDim2.new(1, -16, 0, topSafe)

			local rightNextY = topSafe + math.ceil(98 * cornerScale)
			r.pauseBtn.Position = UDim2.new(1, -16, 0, rightNextY)
			if r.hudMenuBtn then
				r.hudMenuBtn.Position = UDim2.new(1, -142, 0, rightNextY)
			end
			r.exitBtn.Position = UDim2.new(1, -16, 0, rightNextY)
			r.toast:SetAttribute("Fit", cornerScale)
			Ui.pop(r.toast, true)
			r.toast.Position = UDim2.new(1, -16, 0, rightNextY + 54)

			local narrow = v.X < 1080
			local centerY = if narrow then (topSafe + math.max(146, math.ceil(174 * cornerScale))) else math.max(14, topSafe - 4)
			local corridor = if narrow then (v.X - 32) else math.max(290, math.floor(v.X - 56 - 346 * cornerScale - 368 * cornerScale))
			local waveW = math.min(420, corridor)
			local biomeW = math.min(460, corridor)
			r.wave.Position = UDim2.new(0.5, 0, 0, centerY)
			r.wave.Size = UDim2.fromOffset(waveW, 40)
			r.timer.Position = UDim2.new(0.5, 0, 0, centerY + 40)
			r.biome.Position = UDim2.new(0.5, 0, 0, centerY + 68)
			r.biome.Size = UDim2.fromOffset(biomeW, 24)
			if r.zoneBadge then
				r.zoneBadge.Position = UDim2.new(0.5, 0, 0, centerY + 94)
				r.zoneBadge.Size = UDim2.fromOffset(biomeW, 22)
			end
			r.bossWrap.Position = UDim2.new(0.5, 0, 0, centerY + 120)
			r.bossWrap.Size = UDim2.fromOffset(math.min(460, corridor), 52)

			local tw = if narrow then math.max(260, math.floor(v.X - 32)) else math.clamp(math.floor(v.X * 0.39), 320, 470)
			r.tickerPanel.Size = UDim2.fromOffset(tw, 68)
			r.ticker.Size = UDim2.fromOffset(tw - 24, 26)
			if inputMode == "touch" then
				r.tickerPanel.AnchorPoint = Vector2.new(0, 0)
				local tickerY = if narrow then (centerY + 126) else (topSafe + math.ceil(176 * cornerScale))
				r.tickerPanel.Position = UDim2.fromOffset(16, tickerY)
			else
				r.tickerPanel.AnchorPoint = Vector2.new(0, 1)
				r.tickerPanel.Position = UDim2.new(0, 16, 1, -20)
			end

			local skillFit = if inputMode == "touch" then math.clamp(0.72 / uiScale.Scale, 0.85, 1.15) else cornerScale
			local skillGap = math.ceil(116 * skillFit)
			local skillRightPad = if inputMode == "touch" then (if narrow then 134 else 156) else 24
			local skillBottomPad = if inputMode == "touch" then 34 else 28
			for i = 1, 2 do
				local btn = r.skills[i].button
				btn:SetAttribute("Fit", skillFit)
				Ui.pop(btn, true)
				btn.Position = UDim2.new(1, -skillRightPad - (2 - i) * skillGap, 1, -skillBottomPad)
			end
			if r.autoSlot then
				r.autoSlot:SetAttribute("Fit", skillFit)
				Ui.pop(r.autoSlot, true)
				r.autoSlot.Position = UDim2.new(1, -skillRightPad - 2 * skillGap, 1, -skillBottomPad)
			end

			local tutW = math.min(640, v.X - 32)
			r.tut.Size = UDim2.fromOffset(tutW, 98)
			r.tutText.Size = UDim2.fromOffset(tutW - 28, 56)
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
	if r.menuProfileLabel then
		r.menuProfileLabel.Text = string.format("PERFIL %d · %s", meta.activeSlot or 1, string.upper(meta.profileName or "PILOTO"))
	end
	local hadResume = r.menuResumeBtn and r.menuResumeBtn.Visible == true
	local hasCp = meta.loaded and meta.hasCheckpoint == true and meta.checkpoint ~= nil
	if r.menuResumeBtn and r.menuStack then
		r.menuResumeBtn.Visible = hasCp
		if hasCp and meta.checkpoint then
			r.menuResumeSub.Text = string.format("Oleada %d/%d · Nivel %d · %s", meta.checkpoint.wave or 1, Balance.Run.TotalWaves, meta.checkpoint.lvl or 1, Ui.time(meta.checkpoint.time or 0))
			r.menuStack.Position = UDim2.fromOffset(0, 62)
		else
			r.menuStack.Position = UDim2.fromOffset(0, 0)
		end
		if hasCp ~= hadResume then
			refitFn()
		end
	end

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

	if r.profileCards and meta.profiles then
		local active = meta.activeSlot or 1
		for slot = 1, 3 do
			local card = r.profileCards[slot]
			local p = meta.profiles[slot]
			if card and p then
				local isAct = slot == active
				card.stroke.Color = if isAct then T.cyanHi else T.line
				card.bar.BackgroundColor3 = if isAct then T.cyanHi else T.dim
				card.title.Text = string.format("%s %s", string.upper(p.name or ("Piloto " .. slot)), if isAct then "· ACTIVO" else "")
				card.title.TextColor3 = if isAct then T.cyanHi else T.text
				local pb = p.best or { level = 0, time = 0 }
				card.stats.Text = string.format("%d Ciencia · %d Misiones (%d Vict.) · Mejor Nvl %d (%s)", p.science or 0, p.runs or 0, p.wins or 0, pb.level or 0, Ui.time(pb.time or 0))
				if p.checkpoint then
					card.cp.Text = string.format("CHECKPOINT: Oleada %d/%d · Nivel %d · %s", p.checkpoint.wave or 1, Balance.Run.TotalWaves, p.checkpoint.lvl or 1, Ui.time(p.checkpoint.time or 0))
					card.cp.TextColor3 = T.green
				else
					card.cp.Text = "Sin checkpoint guardado"
					card.cp.TextColor3 = T.dim
				end
				card.useBtn.Text = if isAct then "EN USO" else "USAR PERFIL"
				Ui.setButtonColor(card.useBtn, if isAct then T.line else T.cyanHi)
				card.useBtn.TextColor3 = if isAct then T.dim else T.bg
			end
		end
	end
end

function Hud.setPhase(newPhase: string, newMeta: any, extra: any)
	local keepShop = newPhase == "menu" and phase == "menu" and r.shop.Visible
	local keepProfiles = newPhase == "menu" and phase == "menu" and r.profiles and r.profiles.Visible
	phase = newPhase
	meta = newMeta
	refreshMeta()
	local inRun = phase == "run" or phase == "tutorial"
	r.hud.Visible = inRun
	r.shop.Visible = keepShop
	if r.profiles then
		r.profiles.Visible = keepProfiles
	end
	r.credits.Visible = false
	r.settings.Visible = false
	r.level.Visible = false
	r.piece.Visible = false
	r.pause.Visible = false
	if r.briefing then
		r.briefing.Visible = false
	end
	show(r.menu, phase == "menu")
	show(r.summary, phase == "victory" or phase == "defeat")
	choiceOpen = false
	if inRun then
		r.tut.Visible = phase == "tutorial"
		r.exitBtn.Visible = phase == "tutorial"
		r.pauseBtn.Visible = phase == "run"
		if r.hudMenuBtn then
			r.hudMenuBtn.Visible = phase == "run"
		end
		r.bossWrap.Visible = false
		r.toast.Visible = false
		r.biome.Text = if phase == "tutorial" then "ARENA DE PRÁCTICA" else ("ETAPA 1 · " .. Content.Biomes[1].name)
		r.biome.TextColor3 = if phase == "tutorial" then T.cyanHi else BIOME_COLORS[1]
		if r.zoneBadge then
			local z1 = (Balance.Zones :: any)[1]
			r.zoneBadge.Text = if z1 then string.format("ZONA: %s · %s", upperEs(z1.name), z1.bonus or "") else "ZONA: CRÁTER DEL MÓDULO"
			r.zoneBadge.TextColor3 = ZONE_COLORS[1]
		end
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
	local hpFrac = math.clamp(h[1] / math.max(1, h[2]), 0, 1)
	r.hpFill.Size = UDim2.fromScale(hpFrac, 1)
	r.hpFill.BackgroundColor3 = if hpFrac > 0.5 then T.green elseif hpFrac > 0.25 then T.gold else T.red
	r.hpText.Text = string.format("SALUD %d / %d", math.max(0, h[1]), h[2])

	local sCur = math.max(0, h[3] or 0)
	local sMax = math.max(1, h[21] or Balance.Skills.Pulse.Shield)
	local sTime = math.max(0, h[22] or 0)
	local sCd = math.max(0, h[11] or 0)
	r.shieldFill.Size = UDim2.fromScale(math.clamp(sCur / sMax, 0, 1), 1)
	if r.shieldText then
		if sCur > 0 then
			r.shieldText.Text = if sTime > 0 then string.format("ESCUDO %d / %d · %.1fs", math.ceil(sCur), sMax, sTime) else string.format("ESCUDO %d / %d", math.ceil(sCur), sMax)
			r.shieldText.TextColor3 = T.text
			if r.shieldBadge then
				r.shieldBadge.Text = "ESCUDO ACTIVO"
				r.shieldBadge.TextColor3 = T.cyanHi
			end
		elseif sCd > 0 then
			r.shieldText.Text = string.format("RECARGANDO ESCUDO · %ds", math.ceil(sCd))
			r.shieldText.TextColor3 = T.dim
			if r.shieldBadge then
				r.shieldBadge.Text = string.format("CD ESCUDO %ds", math.ceil(sCd))
				r.shieldBadge.TextColor3 = T.dim
			end
		else
			r.shieldText.Text = string.format("ESCUDO LISTO (+%d) [E]", Balance.Skills.Pulse.Shield)
			r.shieldText.TextColor3 = T.cyanHi
			if r.shieldBadge then
				r.shieldBadge.Text = "PULSO LISTO (20s CD)"
				r.shieldBadge.TextColor3 = T.gold
			end
		end
	end

	r.xpFill.Size = UDim2.fromScale(math.clamp(h[4] / math.max(1, h[5]), 0, 1), 1)
	r.lvl.Text = "NIVEL " .. h[6]
	r.kills.Text = "BAJAS " .. h[7]
	r.timer.Text = "T+ " .. Ui.time(h[8])
	for i = 1, 2 do
		local cd = h[7 + i * 2]
		local sk = r.skills[i]
		local ready = cd <= 0
		sk.overlay.Visible = not ready
		sk.text.Text = if ready then "" else tostring(math.ceil(cd))
		if i == 2 and sCur > 0 then
			sk.stroke.Color = T.gold
		elseif ready ~= sk.ready then
			sk.ready = ready
			sk.stroke.Color = if ready then T.cyanHi else T.line
			if ready then
				Ui.pop(sk.button)
			end
		elseif ready and i == 2 then
			sk.stroke.Color = T.cyanHi
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
	r.pieceName.Text = upperEs(p.name)
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

function Hud.zone(zIdx: number)
	if not r.zoneBadge then
		return
	end
	local z = (Balance.Zones :: any)[zIdx]
	local col = ZONE_COLORS[zIdx] or T.cyanHi
	if z then
		r.zoneBadge.Text = string.format("ZONA: %s · %s", upperEs(z.name), z.bonus or "")
		r.zoneBadge.TextColor3 = col
		Ui.pop(r.zoneBadge)
	end
end

function Hud.blackHole(bhIdx: number, _duration: number)
	local bh = NasaData.blackHoleForEvent(bhIdx)
	if bh then
		Hud.alert(bh.title, "warn", bh.sub)
	end
end

function Hud.briefing(on: boolean)
	if not r.briefing then
		return
	end
	if on then
		briefingReturn = "run"
		if r.briefDeployBtn then
			r.briefDeployBtn.Text = "DESPLEGAR AHORA [ESPACIO]"
		end
	else
		briefingReturn = "none"
	end
	show(r.briefing, on)
end

function Hud.toastMsg(title: string, body: string, rarIdx: number?)
	if r.pauseSaveNote and title:find("CHECKPOINT") then
		r.pauseSaveNote.Text = body ~= "" and ("✓ " .. body) or "✓ CHECKPOINT GUARDADO"
	end
	local col = if rarIdx then (T.rarity[rarIdx] or T.gold) else T.green
	r.toastRar.Text = "TELEMETRÍA"
	r.toastRar.TextColor3 = col
	r.toastName.Text = title
	r.toastDesc.Text = body
	r.toastFact.Text = ""
	if not r.toast.Visible then
		Ui.pop(r.toast)
	end
	r.toast.Visible = true
	toastT = 4.5
end

function Hud.paused(on: boolean)
	if r.pauseAudioBtn then
		r.pauseAudioBtn.Text = if Hud.settings.muted then "    SONIDO: SILENCIO" else "    SONIDO: ACTIVADO"
	end
	if r.audioValue then
		r.audioValue.Text = if Hud.settings.muted then "SILENCIO" else "ACTIVADO"
	end
	if on and r.pauseSaveNote then
		r.pauseSaveNote.Text = ""
	end
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

function Hud.update(dt: number, chestPos: Vector3?, chestTier: number?)
	-- Las etiquetas centrales se solapan con el titulo de las cartas, briefing y de la tarjeta de pieza.
	local covered = r.level.Visible or r.piece.Visible or (r.briefing and r.briefing.Visible) or r.pause.Visible
	if r.wave.Visible == covered then
		r.wave.Visible = not covered
		r.timer.Visible = not covered
		r.biome.Visible = not covered
		if r.zoneBadge then
			r.zoneBadge.Visible = not covered
		end
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
	-- Flecha al cofre más cercano (con color de rareza) cuando queda fuera de pantalla.
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
			r.arrow.TextColor3 = T.rarity[chestTier or 4] or T.gold
			r.arrow.Position = UDim2.fromOffset((cx + dx / len * rad) / s, (cy + dy / len * rad) / s)
			r.arrow.Rotation = math.deg(math.atan2(dx, -dy))
			r.arrow.Visible = true
		end
	else
		r.arrow.Visible = false
	end
end

return Hud
