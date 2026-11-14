# -*- coding: utf-8 -*-
"""Pruebas del puente dentro de Blender en modo -b (sin ventana).

Ejecutar desde la carpeta del proyecto:
    blender.exe -b --factory-startup --python tools/blender_mcp/selftest.py

Escribe logs/selftest/resultado.json. Solo crea archivos dentro de logs/selftest.
"""

import json
import os
import runpy
import socket
import threading
import time
from pathlib import Path

os.environ["BLENDER_BRIDGE_TEST"] = "1"
RAIZ = Path(__file__).resolve().parents[2]
SALIDA = RAIZ / "logs" / "selftest"
SALIDA.mkdir(parents=True, exist_ok=True)
B = runpy.run_path(str(RAIZ / "tools" / "blender_mcp" / "bridge_addon.py"), run_name="puente_prueba")
resultados = []


def comprobar(nombre, ok, detalle=""):
    resultados.append({"prueba": nombre, "ok": bool(ok), "detalle": str(detalle)[:400]})


def esperar_error(nombre, tipo, fn):
    try:
        fn()
        comprobar(nombre, False, "no lanzo excepcion")
    except tipo as exc:
        comprobar(nombre, True, f"{type(exc).__name__}: {exc}")
    except Exception as exc:
        comprobar(nombre, False, f"excepcion inesperada {type(exc).__name__}: {exc}")


C = B["COMMANDS"]

# 1. Comandos directos
r = C["ping"]({})
comprobar("ping directo", "blender" in r, r.get("blender"))
r = C["scene_info"]({})
comprobar("scene_info devuelve objetos", r["total"] >= 1, f"total={r['total']}")
r = C["budget_report"]({"coleccion": "Collection"})
comprobar("budget_report lee la coleccion", "mallas" in r, f"mallas={len(r['mallas'])}")

# 2. Exportacion FBX dentro del proyecto
r = C["export_fbx"]({"coleccion": "Collection", "nombre": "SM_Prueba_Cubo", "carpeta": "logs/selftest"})
fbx = RAIZ / r["archivo"]
comprobar("export_fbx crea el archivo", fbx.is_file() and fbx.stat().st_size > 0, f"{r['archivo']} ({fbx.stat().st_size if fbx.exists() else 0} bytes)")

# 3. Script dentro del proyecto
script = SALIDA / "script_prueba.py"
script.write_text("print('hola desde el proyecto')\n", encoding="utf-8")
r = C["run_script"]({"ruta": "logs/selftest/script_prueba.py"})
comprobar("run_script ejecuta un .py del proyecto", "hola desde el proyecto" in r["salida"], r["salida"].strip())

# 4. Barreras de seguridad (deben fallar)
esperar_error("bloquea run_script fuera del proyecto", PermissionError,
              lambda: C["run_script"]({"ruta": "..\\..\\..\\Windows\\win.ini"}))
esperar_error("bloquea run_script con extension distinta de .py", ValueError,
              lambda: C["run_script"]({"ruta": "tools/blender_mcp/config.json"}))
esperar_error("bloquea save_blend fuera del proyecto", PermissionError,
              lambda: C["save_blend"]({"ruta": "..\\..\\..\\Users\\Public\\x.blend"}))
esperar_error("bloquea export con nombre peligroso", ValueError,
              lambda: C["export_fbx"]({"coleccion": "Collection", "nombre": "..\\..\\x"}))
esperar_error("bloquea coleccion inexistente", ValueError,
              lambda: C["budget_report"]({"coleccion": "NO_EXISTE"}))

# 5. Puente por socket: token, comandos no listados y peticion valida (con bombeo manual del hilo principal)
B["iniciar"](con_temporizador=False)


def cliente(peticion, out):
    with socket.create_connection(("127.0.0.1", B["PORT"]), timeout=30) as s:
        s.sendall((json.dumps(peticion) + "\n").encode("utf-8"))
        datos = b""
        while not datos.endswith(b"\n"):
            trozo = s.recv(65536)
            if not trozo:
                break
            datos += trozo
    out.append(json.loads(datos.decode("utf-8")))


def llamada(peticion):
    out = []
    hilo = threading.Thread(target=cliente, args=(peticion, out), daemon=True)
    hilo.start()
    inicio = time.time()
    while hilo.is_alive() and time.time() - inicio < 30:
        B["_bombear"]()
        time.sleep(0.02)
    hilo.join(1)
    return out[0] if out else {"ok": False, "error": "sin respuesta"}


r = llamada({"token": B["TOKEN"], "cmd": "ping", "args": {}})
comprobar("socket acepta token valido", r.get("ok") is True, r.get("result", r.get("error")))
r = llamada({"token": "token_falso", "cmd": "ping", "args": {}})
comprobar("socket rechaza token incorrecto", r.get("ok") is False and "token" in r.get("error", ""), r.get("error"))
r = llamada({"token": B["TOKEN"], "cmd": "exec_arbitrario", "args": {"codigo": "print(1)"}})
comprobar("socket rechaza comandos no listados", r.get("ok") is False and "no permitido" in r.get("error", ""), r.get("error"))

# 6. Registro de auditoria: debe existir, contener los rechazos y NO contener el token
log_txt = (RAIZ / "logs" / "blender_bridge.log").read_text(encoding="utf-8")
comprobar("el log registra rechazos", "rechazado" in log_txt)
comprobar("el log NO contiene el token", B["TOKEN"] not in log_txt)

ok_total = sum(1 for x in resultados if x["ok"])
resumen = {"total": len(resultados), "ok": ok_total, "fallos": len(resultados) - ok_total, "pruebas": resultados}
(SALIDA / "resultado.json").write_text(json.dumps(resumen, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"SELFTEST: {ok_total}/{len(resultados)} OK")
for x in resultados:
    print(("  OK   " if x["ok"] else "  FALLO ") + x["prueba"] + " -> " + x["detalle"][:160])
