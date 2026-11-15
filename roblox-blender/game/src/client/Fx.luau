--!strict
-- Jugo: sonidos con variacion de tono, temblor de camara, hitstop, numeros de dano y chispas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Balance)
local Visuals = require(ReplicatedStorage.Shared.Visuals)

local Fx = {}

local rng = Random.new()
local sounds: { [string]: Sound } = {}
local lastPlay: { [string]: number } = {}
local music: { [string]: Sound } = {}
local musicTarget: { [string]: number } = { calm = 0, combat = 0, boss = 0 }
local musicVol: { [string]: number } = {}
local emitters: { [string]: { att: Attachment, em: ParticleEmitter } } = {}
local sfxGroup: SoundGroup? = nil
local musicGroup: SoundGroup? = nil
local muted = false
local shake = 0
local low = false
local qualityTier = "high"
local hitstopT = 0

type Num = { part: Part, label: TextLabel, t: number, life: number, vy: number }
local numPool: { Num } = {}
local numActive: { Num } = {}

local function makeEmitter(anchor: Part, name: string, color: Color3, size: number, speed: number, life: number)
	local att = Instance.new("Attachment")
	att.Name = name
	att.Parent = anchor
	local em = Instance.new("ParticleEmitter")
	em.Enabled = false
	em.Color = ColorSequence.new(color)
	em.LightEmission = 1
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	em.Speed = NumberRange.new(speed * 0.6, speed)
	em.Lifetime = NumberRange.new(life * 0.6, life)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Drag = 4
	em.Rate = 0
	em.Parent = att
	emitters[name] = { att = att, em = em }
end

function Fx.init(folder: Instance)
	-- Grupo de efectos con ecualizador: recorta agudos para que nada suene agresivo.
	local sg = Instance.new("SoundGroup")
	sg.Name = "AresSfx"
	sg.Volume = if muted then 0 else 1
	sg.Parent = SoundService
	sfxGroup = sg
	local eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain = -7
	eq.MidGain = -1.5
	eq.LowGain = 1
	eq.Parent = sg
	local mg = Instance.new("SoundGroup")
	mg.Name = "AresMusic"
	mg.Volume = if muted then 0 else 1
	mg.Parent = SoundService
	musicGroup = mg
	for name, def in Balance.Audio.Sfx :: { [string]: any } do
		local s = Instance.new("Sound")
		s.Name = "Sfx_" .. name
		s.SoundId = def.id
		s.Volume = def.vol
		s.SoundGroup = sg
		s.Parent = SoundService
		sounds[name] = s
	end
	for name, def in Balance.Audio.Music :: { [string]: any } do
		if def.id ~= "" then
			local s = Instance.new("Sound")
			s.Name = "Music_" .. name
			s.SoundId = def.id
			s.Looped = true
			s.Volume = 0
			s.SoundGroup = mg
			s.Parent = SoundService
			s:Play()
			music[name] = s
			musicVol[name] = def.vol
		end
	end

	local anchor = Instance.new("Part")
	anchor.Name = "FxAnchor"
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(0, 0, 0)
	anchor.Parent = folder
	local C = Visuals.Colors
	makeEmitter(anchor, "die", C.red, 1.4, 26, 0.4)
	makeEmitter(anchor, "gold", C.gold, 0.9, 16, 0.35)
	makeEmitter(anchor, "boom", C.orange, 3.2, 40, 0.5)
	makeEmitter(anchor, "cyan", C.cyan, 0.8, 18, 0.25)

	for _ = 1, 36 do
		local p = Instance.new("Part")
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.CFrame = CFrame.new(0, -500, 0)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(140, 44)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Enabled = false
		bb.Parent = p
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.Font = Enum.Font.Bangers
		l.TextSize = 26
		l.TextStrokeTransparency = 0.15
		l.TextStrokeColor3 = Color3.new(0, 0, 0)
		l.Parent = bb
		p.Parent = folder
		table.insert(numPool, { part = p, label = l, t = 0, life = 1, vy = 6 })
	end
end

function Fx.play(name: string, pitchMul: number?)
	local s = sounds[name]
	if not s then
		return
	end
	local now = os.clock()
	if now - (lastPlay[name] or 0) < 0.045 then
		return
	end
	lastPlay[name] = now
	local def = (Balance.Audio.Sfx :: any)[name]
	local v = Balance.Juice.PitchVar
	s.PlaybackSpeed = def.pitch * (pitchMul or 1) * (1 + rng:NextNumber(-v, v))
	SoundService:PlayLocalSound(s)
end

function Fx.setLow(on: boolean)
	low = on
	qualityTier = if on then "low" else "high"
end

function Fx.setMuted(on: boolean)
	muted = on
	if sfxGroup then
		sfxGroup.Volume = if on then 0 else 1
	end
	if musicGroup then
		musicGroup.Volume = if on then 0 else 1
	end
end

function Fx.isMuted(): boolean
	return muted
end

-- Ajusta densidad de partículas, sacudida y rótulos flotantes según las especificaciones del dispositivo.
function Fx.setQuality(tier: string)
	if tier ~= "high" and tier ~= "med" and tier ~= "low" then
		tier = "high"
	end
	qualityTier = tier
	low = (tier == "low")
end

function Fx.getQuality(): string
	return qualityTier
end

function Fx.burst(name: string, pos: Vector3, count: number)
	local e = emitters[name]
	if e then
		if qualityTier == "low" then
			count = math.max(3, math.round(count * 0.35))
		elseif qualityTier == "med" then
			count = math.max(4, math.round(count * 0.65))
		end
		e.att.WorldPosition = pos
		e.em:Emit(count)
	end
end

function Fx.shake(amount: number)
	local mul = if qualityTier == "low" then 0.55 elseif qualityTier == "med" then 0.85 else 1
	shake = math.min(Balance.Camera.ShakeMax, math.max(shake, amount * mul))
end

-- Retroceso del heroe al disparar: empuje breve hacia atras de la camara que vuelve solo.
local kick = 0

function Fx.kickBack(amount: number)
	kick = math.min(0.35, math.max(kick, amount))
end

function Fx.kickUpdate(dt: number)
	if kick > 0 then
		kick = math.max(0, kick - dt * 3)
	end
end

function Fx.shakeOffset(): Vector3
	local back = kick * 1.2
	if shake <= 0.001 then
		return Vector3.new(0, 0, back)
	end
	return Vector3.new(rng:NextNumber(-shake, shake), rng:NextNumber(-shake, shake), back)
end

function Fx.hitstop(t: number)
	hitstopT = math.max(hitstopT, t)
end

function Fx.frozen(): boolean
	return hitstopT > 0
end

function Fx.number(pos: Vector3, text: string, color: Color3, big: boolean?)
	if qualityTier == "low" and not big and #numActive >= 8 then
		return
	end
	local n = table.remove(numPool)
	if not n then
		n = table.remove(numActive, 1) :: Num
	end
	n.t = 0
	n.life = Balance.Juice.DamageNumberLife * (if big then 1.4 else 1)
	n.vy = if big then 9 else 6
	n.part.CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)))
	n.label.Text = text
	n.label.TextColor3 = color
	n.label.TextSize = if big then 38 else 26
	n.label.TextTransparency = 0;
	(n.label.Parent :: BillboardGui).Enabled = true
	table.insert(numActive, n)
end

-- Celebracion visual en una posicion: chispas doradas y cian.
function Fx.celebrate(pos: Vector3, strong: boolean?)
	Fx.burst("gold", pos + Vector3.new(0, 2, 0), if strong then 46 else 22)
	Fx.burst("cyan", pos + Vector3.new(0, 3, 0), if strong then 30 else 14)
end

-- intensidad: "calm" | "combat" | "boss"
function Fx.setMusic(level: string)
	for name in musicTarget do
		-- una sola pista a la vez, con fundido: son piezas distintas y no se mezclan
		musicTarget[name] = if name == level then (musicVol[name] or 0.2) else 0
	end
end

function Fx.update(dt: number)
	if hitstopT > 0 then
		hitstopT -= dt
	end
	if shake > 0 then
		shake = math.max(0, shake - dt * 1.6)
	end
	for i = #numActive, 1, -1 do
		local n = numActive[i]
		n.t += dt
		if n.t >= n.life then
			(n.label.Parent :: BillboardGui).Enabled = false
			table.remove(numActive, i)
			table.insert(numPool, n)
		else
			n.part.CFrame += Vector3.new(0, n.vy * dt, 0)
			n.label.TextTransparency = math.max(0, n.t / n.life * 2 - 1)
			-- entrada con rebote: nace inclinado y se asienta
			n.label.Rotation = (1 - math.min(1, n.t / 0.12)) * -12
		end
	end
	for name, s in music do
		s.Volume += (musicTarget[name] - s.Volume) * math.min(1, dt * 1.5)
	end
end

return Fx
