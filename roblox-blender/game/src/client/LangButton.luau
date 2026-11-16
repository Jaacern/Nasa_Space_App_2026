--!strict
-- Botón de idioma en el menú principal: recorre los idiomas instalados (Locale.list()). Activa la traducción en vivo de Locale.
-- Visible solo mientras el menú principal está abierto.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Locale = require(ReplicatedStorage.Shared.Locale)
local Ui = require(script.Parent.Ui)

local LangButton = {}

function LangButton.start()
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	Locale.attach(pg)
	Locale.attach(Workspace)

	local T = Ui.Theme
	local gui = Ui.new("ScreenGui", { Name = "AresLang", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 8 })
	local scale = Ui.new("UIScale", {})
	scale.Parent = gui
	local btn: TextButton
	btn = Ui.button("ENGLISH", function()
		local list = Locale.list()
		local idx = 1
		for i, l in list do
			if l.code == Locale.lang then
				idx = i
			end
		end
		Locale.set(list[idx % #list + 1].code)
	end, { AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(230, 44), TextSize = 17, FontFace = Ui.Fonts.monoBold, ZIndex = 5 }, "ghost")
	btn.Name = "Lang"
	btn.Parent = gui
	-- El propio botón no se traduce: muestra el idioma activo; cada toque pasa al siguiente.
	btn:SetAttribute("LocSkip", true)
	local function label()
		btn.Text = "◀ " .. Locale.name() .. " ▶"
		btn:SetAttribute("LocSrc", btn.Text)
		btn:SetAttribute("LocShown", btn.Text)
	end
	Locale.changed.Event:Connect(label)
	label()
	gui.Parent = pg

	RunService.RenderStepped:Connect(function()
		local hud = pg:FindFirstChild("AresHud")
		local menu = hud and hud:FindFirstChild("Menu")
		local on = menu ~= nil and menu:IsA("GuiObject") and menu.Visible and (hud :: ScreenGui).Enabled
		if btn.Visible ~= on then
			btn.Visible = on
		end
		if on then
			local cam = Workspace.CurrentCamera
			local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
			local s = math.clamp(math.min(vp.Y / 720, vp.X / 1200), 0.6, 1.6)
			scale.Scale = s
			btn.Position = UDim2.new(1, -16 / s, 0, (GuiService:GetGuiInset().Y + 12) / s)
		end
	end)
end

return LangButton
