--!strict
-- Arranque del servidor: mundo, remotos y una sesion por jugador.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Balance = require(ReplicatedStorage.Shared.Balance)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Session = require(script.Parent.Session)
local SaveService = require(script.Parent.SaveService)

WorldBuilder.build()

local oldRemotes = ReplicatedStorage:FindFirstChild("Remotes")
if oldRemotes then
	oldRemotes:Destroy()
end
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local sync = Instance.new("RemoteEvent")
sync.Name = "Sync"
sync.Parent = remotes
local cmd = Instance.new("RemoteEvent")
cmd.Name = "Cmd"
cmd.Parent = remotes
remotes.Parent = ReplicatedStorage

local sessions: { [Player]: any } = {}

local function setupCharacter(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	hum.UseJumpPower = true
	hum.JumpPower = Balance.Hero.JumpPower
	hum.BreakJointsOnDeath = false
	hum.WalkSpeed = Balance.Hero.WalkSpeed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	character:WaitForChild("HumanoidRootPart", 10)
	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end
	WorldBuilder.dress(character)
	local s = sessions[player]
	if s and s.R then
		hum.WalkSpeed = s.R.stats.speed
	end
end

local function onPlayer(player: Player)
	sessions[player] = Session.new(player, sync)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	local s = sessions[player]
	sessions[player] = nil
	if s then
		SaveService.save(player.UserId, s.account)
	end
end)

cmd.OnServerEvent:Connect(function(player, name, a, b, c)
	local s = sessions[player]
	if s then
		s:onCmd(name, a, b, c)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for _, s in sessions do
		s:update(dt)
	end
end)

game:BindToClose(function()
	for player, s in sessions do
		SaveService.save(player.UserId, s.account)
	end
end)
