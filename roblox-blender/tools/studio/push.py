"""Empuja archivos de game/src a Studio SIN HTTP (para lugares publicados, donde 127.0.0.1 no esta permitido).
Uso: python -B tools/studio/push.py <salida.json> <ruta relativa a game/src> [...]
Ejemplo: STUDIO_ID=<id> python -B tools/studio/push.py push.json client/Hud.luau shared/Content.luau
Luego: python -B tools/studio/studio_call.py execute_luau @push.json
Misma regla que sync_studio.luau: shared/ -> ReplicatedStorage.Shared, server/ -> ServerScriptService.Server,
client/ -> StarterPlayer.StarterPlayerScripts.Client; .server.luau = Script, .client.luau = LocalScript."""
import json, os, pathlib, sys

SRC = pathlib.Path(__file__).resolve().parents[2] / "game" / "src"
ROOTS = {
    "shared": 'game:GetService("ReplicatedStorage"):FindFirstChild("Shared")',
    "server": 'game:GetService("ServerScriptService"):FindFirstChild("Server")',
    "client": 'game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Client")',
}

def quote(text):
    n = 1
    while "]" + "=" * n + "]" in text:
        n += 1
    return "[" + "=" * n + "[\n" + text + "]" + "=" * n + "]"

out = ["local changed = {}",
       "local function put(root, path, class, src)",
       "  local inst = root",
       "  for i, name in path do",
       "    local child = inst:FindFirstChild(name)",
       "    if not child then child = Instance.new(if i == #path then class else 'Folder') child.Name = name child.Parent = inst end",
       "    inst = child",
       "  end",
       "  if inst.Source ~= src then inst.Source = src table.insert(changed, inst:GetFullName()) end",
       "end"]
for rel in sys.argv[2:]:
    parts = pathlib.PurePosixPath(rel.replace("\\", "/")).parts
    base = parts[-1].removesuffix(".luau")
    cls = "ModuleScript"
    if base.endswith(".server"):
        cls, base = "Script", base[:-7]
    elif base.endswith(".client"):
        cls, base = "LocalScript", base[:-7]
    path = ", ".join('"%s"' % p for p in (*parts[1:-1], base))
    src = (SRC / rel).read_text(encoding="utf-8")
    out.append("put(%s, {%s}, %r, %s)" % (ROOTS[parts[0]], path, cls, quote(src)))
out.append('return #changed .. " cambios: " .. table.concat(changed, ", ")')
json.dump({"code": "\n".join(out), "datamodel_type": "Edit", "studio_id": os.environ["STUDIO_ID"]},
          open(sys.argv[1], "w", encoding="utf-8"))
