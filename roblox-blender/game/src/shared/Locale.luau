--!strict
-- Idioma de la interfaz (inglés por defecto, español opcional).
-- El código del juego escribe sus textos en español. Esta capa los traduce en vivo:
-- vigila cada TextLabel/TextButton de la interfaz y, si el idioma es inglés, cambia el texto
-- por su traducción (LocaleEN.luau). El original se guarda en el atributo "LocSrc".
-- Si falta una traducción, se deja el texto original (nunca rompe la interfaz).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Data = require(script.Parent.LocaleEN)

local Locale = {}

Locale.lang = "en"
Locale.changed = Instance.new("BindableEvent")

-- Mayúsculas con acentos (string.upper no cambia los caracteres UTF-8 acentuados).
local ACCENTS = { ["á"] = "Á", ["é"] = "É", ["í"] = "Í", ["ó"] = "Ó", ["ú"] = "Ú", ["ñ"] = "Ñ", ["ü"] = "Ü" }
local function upper(s: string): string
	local out = string.upper(s)
	for lo, up in ACCENTS do
		out = string.gsub(out, lo, up)
	end
	return out
end
Locale.upper = upper

local EN: { [string]: string } = {}
for k, v in Data.EN do
	EN[k] = v
end
-- Variantes en mayúsculas (el HUD muestra nombres de zonas y piezas en mayúsculas).
for k, v in Data.EN do
	local uk = upper(k)
	if EN[uk] == nil then
		EN[uk] = upper(v)
	end
end

-- Formatos -> patrones Lua anclados.
type Fmt = { pat: string, en: string, kinds: { string } }
local FORMATS: { Fmt } = {}
local function compile(es: string, en: string)
	local kinds = {}
	local pat = ""
	local i = 1
	while i <= #es do
		local c = string.sub(es, i, i)
		if c == "%" then
			local spec = string.match(es, "^%%[%d%.]*[dsf%%]", i)
			if spec == "%%" then
				pat ..= "%%"
				i += 2
			elseif spec then
				local k = string.sub(spec, -1)
				table.insert(kinds, k)
				pat ..= if k == "s" then "(.-)" elseif k == "d" then "(%-?%d+)" else "(%-?[%d%.]+)"
				i += #spec
			else
				pat ..= "%%"
				i += 1
			end
		elseif string.find(c, "[%^%$%(%)%.%[%]%*%+%-%?]") then
			pat ..= "%" .. c
			i += 1
		else
			pat ..= c
			i += 1
		end
	end
	-- En inglés todos los argumentos llegan como texto: cada especificador pasa a %s.
	local enFmt = string.gsub(en, "%%[%d%.]*[df]", "%%s")
	table.insert(FORMATS, { pat = "^" .. pat .. "$", en = enFmt, kinds = kinds })
end
-- Mayúsculas sin tocar los especificadores (%d, %s...).
local function upperFmt(s: string): string
	return (string.gsub(upper(s), "%%([%d%.]*)([DSF])", function(w, k)
		return "%" .. w .. string.lower(k)
	end))
end
for _, f in Data.FORMATS do
	compile(f[1], f[2])
	if upperFmt(f[1]) ~= f[1] then
		compile(upperFmt(f[1]), upperFmt(f[2]))
	end
end

local translate: (string, number?) -> string

local function viaFormats(s: string, depth: number): string?
	for _, f in FORMATS do
		local caps = { string.match(s, f.pat) }
		if #caps > 0 and caps[1] ~= nil then
			for j, cap in caps do
				if f.kinds[j] == "s" then
					caps[j] = translate(cap, depth + 1)
				end
			end
			local ok, out = pcall(string.format, f.en, table.unpack(caps))
			if ok then
				return out
			end
		end
	end
	return nil
end

-- Traduce un texto fuente (español) al idioma activo.
translate = function(s: string, depth: number?): string
	local d = depth or 0
	if Locale.lang == "es" or s == "" or d > 3 then
		return s
	end
	local hit = EN[s]
	if hit then
		return hit
	end
	-- Conserva los espacios de los bordes (algunos botones los usan como sangría).
	local lead, core, trail = string.match(s, "^(%s*)(.-)(%s*)$")
	if core and core ~= s and core ~= "" then
		local t = translate(core, d + 1)
		if t ~= core then
			return lead .. t .. trail
		end
		return s
	end
	-- Texto enriquecido: traduce los trozos entre etiquetas.
	if string.find(s, "<", 1, true) then
		local changed = false
		local out = string.gsub(s, ">([^<]+)<", function(seg)
			local t = translate(seg, d + 1)
			if t ~= seg then
				changed = true
			end
			return ">" .. t .. "<"
		end)
		if changed then
			return out
		end
	end
	-- Varias líneas: traduce línea a línea.
	if string.find(s, "\n", 1, true) then
		local lines = string.split(s, "\n")
		local changed = false
		for i, l in lines do
			local t = translate(l, d + 1)
			if t ~= l then
				changed = true
				lines[i] = t
			end
		end
		if changed then
			return table.concat(lines, "\n")
		end
		return s
	end
	return viaFormats(s, d) or s
end
Locale.t = function(s: string): string
	return translate(s)
end

function Locale.f(fmt: string, ...: any): string
	return translate(string.format(fmt, ...))
end

-- ------------------------------------------------------------ Traducción en vivo de la interfaz
local tracked: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local writing: { [Instance]: boolean } = {}

local function apply(obj: TextLabel | TextButton)
	if writing[obj] then
		return
	end
	local current = obj.Text
	local src = obj:GetAttribute("LocSrc")
	local shown = obj:GetAttribute("LocShown")
	-- Si el juego escribió un texto nuevo (no el que pusimos nosotros), ese es el nuevo original.
	if shown == nil or current ~= shown then
		src = current
		obj:SetAttribute("LocSrc", src)
	end
	local out = translate(src :: string)
	obj:SetAttribute("LocShown", out)
	if out ~= current then
		writing[obj] = true
		obj.Text = out
		writing[obj] = nil
	end
end

local function track(obj: Instance)
	if tracked[obj] then
		return
	end
	if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj:GetAttribute("LocSkip") ~= true then
		tracked[obj] = true
		apply(obj)
		obj:GetPropertyChangedSignal("Text"):Connect(function()
			apply(obj :: any)
		end)
	end
end

-- Traduce en vivo todo lo que haya (y lo que se cree) bajo root.
function Locale.attach(root: Instance)
	for _, d in root:GetDescendants() do
		track(d)
	end
	root.DescendantAdded:Connect(track)
end

-- Cambia el idioma y retraduce todo lo vigilado.
function Locale.set(lang: string)
	if lang ~= "en" and lang ~= "es" then
		return
	end
	Locale.lang = lang
	if RunService:IsClient() then
		local lp = Players.LocalPlayer
		if lp then
			lp:SetAttribute("Lang", lang)
		end
	end
	for obj in tracked do
		if obj.Parent then
			local src = obj:GetAttribute("LocSrc")
			if type(src) == "string" then
				local out = translate(src)
				obj:SetAttribute("LocShown", out)
				writing[obj] = true
				;(obj :: any).Text = out
				writing[obj] = nil
			end
		end
	end
	Locale.changed:Fire(lang)
end

-- Para pruebas: textos de una lista que quedan sin traducir.
function Locale.missing(list: { string }): { string }
	local out = {}
	for _, s in list do
		if translate(s) == s and string.find(s, "%a%a") then
			table.insert(out, s)
		end
	end
	return out
end

return Locale
