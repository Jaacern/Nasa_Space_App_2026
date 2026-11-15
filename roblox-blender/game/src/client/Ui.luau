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

-- Tipografías incluidas en Roblox, elegidas por su aire aeroespacial y técnico.
local TITILLIUM = "rbxasset://fonts/families/TitilliumWeb.json"
local MONO = "rbxasset://fonts/families/RobotoMono.json"
Ui.Fonts = {
	title = Font.new("rbxasset://fonts/families/Michroma.json"),
	bold = Font.new(TITILLIUM, Enum.FontWeight.Bold),
	semi = Font.new(TITILLIUM, Enum.FontWeight.SemiBold),
	body = Font.new(TITILLIUM, Enum.FontWeight.Regular),
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
	local f = Ui.new("Frame", { BackgroundColor3 = Ui.Theme.panel, BackgroundTransparency = 0.12, BorderSizePixel = 0 })
	Ui.corner(4).Parent = f
	Ui.stroke(tagColor or Ui.Theme.cyan, 1.2, 0.5).Parent = f
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
		Ui.label(tag, 18, { FontFace = Ui.Fonts.monoBold, TextColor3 = accent, TextStrokeTransparency = 0.55, Position = UDim2.fromOffset(22, 6), Size = UDim2.new(1, -34, 0, 24), ZIndex = f.ZIndex + 1, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd }).Parent = f
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
