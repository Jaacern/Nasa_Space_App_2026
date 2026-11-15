"""Cliente minimo JSON-RPC por stdio para el MCP integrado de Roblox Studio.
Uso: python studio_call.py <tool|--list> [json_args | @archivo.json]"""
import json, os, subprocess, sys, threading, queue
bat = os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")
p = subprocess.Popen(["cmd.exe", "/c", bat], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, cwd=os.path.dirname(bat))
q = queue.Queue()
def rd():
    for line in p.stdout:
        line = line.strip()
        if line:
            try: q.put(json.loads(line.decode("utf-8", "replace")))
            except Exception: pass
threading.Thread(target=rd, daemon=True).start()
def send(o): p.stdin.write((json.dumps(o) + "\n").encode()); p.stdin.flush()
def wait(i, t):
    while True:
        m = q.get(timeout=t)
        if m.get("id") == i: return m
send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"0"}}})
wait(1, 20)
send({"jsonrpc":"2.0","method":"notifications/initialized"})
def call(i, tool, args, t):
    send({"jsonrpc":"2.0","id":i,"method":"tools/call","params":{"name":tool,"arguments":args}})
    r = wait(i, t)
    res = r.get("result") or r
    out = [c["text"] for c in (res.get("content", []) if isinstance(res, dict) else []) if c.get("type") == "text"]
    import base64
    for n, c in enumerate(res.get("content", []) if isinstance(res, dict) else []):
        if c.get("type") == "image":
            f = os.environ.get("STUDIO_IMG", "cap") + ("_%d" % n if n else "") + ".png"
            open(f, "wb").write(base64.b64decode(c["data"])); out.append("IMG " + os.path.abspath(f) + " " + c.get("mimeType", ""))
    print("=== %s ===" % tool); print(chr(10).join(out) if out else json.dumps(r)[:3000])
T = float(os.environ.get("STUDIO_TIMEOUT", "90"))
if sys.argv[1] == "--schema":
    send({"jsonrpc":"2.0","id":2,"method":"tools/list"}); r = wait(2, 20)
    for t in r["result"]["tools"]:
        if t["name"] in sys.argv[2:]: print(t["name"], json.dumps(t.get("inputSchema"))[:900]); print("  ", t.get("description","")[:500])
else:
    # argumentos: pares tool json|@archivo ; siempre abre con list_roblox_studios para enlazar la sesion
    import time
    for k in range(20):  # Studio tarda unos segundos en enlazarse con un proceso nuevo
        send({"jsonrpc":"2.0","id":100+k,"method":"tools/call","params":{"name":"list_roblox_studios","arguments":{}}})
        r = wait(100+k, 30)
        txt = "".join(c.get("text","") for c in r.get("result",{}).get("content",[]))
        if '"id"' in txt: break
        time.sleep(1.5)
    else:
        print("SIN_STUDIO"); p.kill(); sys.exit(2)
    pares = sys.argv[1:]
    for n in range(0, len(pares), 2):
        a = pares[n+1] if n+1 < len(pares) else "{}"
        args = json.load(open(a[1:], encoding="utf-8")) if a.startswith("@") else json.loads(a)
        call(20+n, pares[n], args, T)
p.kill()
