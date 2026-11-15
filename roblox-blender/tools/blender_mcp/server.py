# -*- coding: utf-8 -*-
"""Servidor MCP (stdio) para Blender. Usa solo la biblioteca estandar de Python.

Herramientas: blender_ping, blender_scene_info, blender_budget_report,
blender_run_script, blender_save_blend, blender_export_fbx y blender_open.
Al arrancar abre Blender con el puente si todavia no esta abierto.
"""

import json
import os
import socket
import subprocess
import sys
import threading
import time
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[1]
CONFIG = json.loads((AQUI / "config.json").read_text(encoding="utf-8"))
HOST = "127.0.0.1"
PORT = int(CONFIG["port"])
TOKEN_FILE = Path(os.path.expandvars(CONFIG["token_file"]))
BLENDER = Path(CONFIG["blender_exe"])
PUENTE = AQUI / "bridge_addon.py"
LOG = RAIZ / "logs" / "blender_mcp_server.log"
TIEMPO_LLAMADA = 120
_bloqueo_abrir = threading.Lock()

HERRAMIENTAS = [
    {
        "name": "blender_ping",
        "description": "Comprueba que Blender y el puente responden. Devuelve version, archivo abierto y carpeta del proyecto.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "blender_scene_info",
        "description": "Lista los objetos de la escena: tipo, colecciones, posicion, escala y triangulos/materiales de las mallas (maximo 500 objetos).",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "blender_budget_report",
        "description": "Triangulos y materiales por malla de una coleccion (por defecto COL_Export). Sirve para validar presupuestos de roblox-export.",
        "inputSchema": {"type": "object", "properties": {"coleccion": {"type": "string"}}},
    },
    {
        "name": "blender_run_script",
        "description": "Ejecuta un archivo .py que ya esta dentro del proyecto (por ejemplo tools/blender/x.py). No acepta codigo como texto.",
        "inputSchema": {"type": "object", "properties": {"ruta": {"type": "string"}}, "required": ["ruta"]},
    },
    {
        "name": "blender_save_blend",
        "description": "Guarda una copia .blend dentro del proyecto. No cambia el archivo que esta abierto.",
        "inputSchema": {"type": "object", "properties": {"ruta": {"type": "string"}}, "required": ["ruta"]},
    },
    {
        "name": "blender_export_fbx",
        "description": "Exporta una coleccion a FBX con escala aplicada y ejes -Z/Y. Destino por defecto: assets/export.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "coleccion": {"type": "string"},
                "nombre": {"type": "string"},
                "carpeta": {"type": "string"},
            },
            "required": ["nombre"],
        },
    },
    {
        "name": "blender_open",
        "description": "Abre Blender con el puente si esta cerrado.",
        "inputSchema": {"type": "object", "properties": {}},
    },
]

CORRESPONDENCIA = {
    "blender_ping": "ping",
    "blender_scene_info": "scene_info",
    "blender_budget_report": "budget_report",
    "blender_run_script": "run_script",
    "blender_save_blend": "save_blend",
    "blender_export_fbx": "export_fbx",
}


def registrar(texto):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as fh:
        fh.write(time.strftime("%Y-%m-%d %H:%M:%S") + " " + texto + "\n")


def puerto_abierto(espera=0.5):
    try:
        with socket.create_connection((HOST, PORT), timeout=espera):
            return True
    except OSError:
        return False


def abrir_blender():
    """Abre Blender con el puente en modo ventana. Es idempotente: si ya esta abierto, no hace nada."""
    with _bloqueo_abrir:
        if puerto_abierto():
            return {"estado": "ya estaba abierto"}
        if not BLENDER.is_file():
            raise FileNotFoundError(f"no encuentro Blender en {BLENDER}")
        indicadores = getattr(subprocess, "DETACHED_PROCESS", 0) | getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
        subprocess.Popen(
            [str(BLENDER), "--python", str(PUENTE)],
            cwd=str(RAIZ),
            creationflags=indicadores,
            start_new_session=(os.name != "nt"),
            close_fds=True,
        )
        registrar("blender_lanzado")
        for _ in range(180):  # hasta unos 90 s
            if puerto_abierto(0.5):
                registrar("puente_listo")
                return {"estado": "abierto"}
            time.sleep(0.5)
        raise TimeoutError("Blender se abrio, pero el puente no respondio a tiempo")


def leer_token():
    if not TOKEN_FILE.is_file():
        raise FileNotFoundError("no existe el token del puente. Ejecuta blender_open para crearlo")
    return TOKEN_FILE.read_text(encoding="utf-8").strip()


def llamar_puente(comando, args=None):
    if not puerto_abierto():
        abrir_blender()
    peticion = {"token": leer_token(), "cmd": comando, "args": args or {}}
    with socket.create_connection((HOST, PORT), timeout=TIEMPO_LLAMADA) as s:
        s.sendall((json.dumps(peticion, ensure_ascii=False) + "\n").encode("utf-8"))
        datos = b""
        while not datos.endswith(b"\n"):
            trozo = s.recv(65536)
            if not trozo:
                break
            datos += trozo
    respuesta = json.loads(datos.decode("utf-8") or "{}")
    if not respuesta.get("ok"):
        raise RuntimeError(respuesta.get("error", "error desconocido"))
    return respuesta.get("result")


def ejecutar(nombre, args):
    if nombre == "blender_open":
        return abrir_blender()
    if nombre not in CORRESPONDENCIA:
        raise ValueError(f"herramienta desconocida: {nombre}")
    registrar(f"llamada {nombre}")
    return llamar_puente(CORRESPONDENCIA[nombre], args)


def enviar(obj):
    sys.stdout.buffer.write((json.dumps(obj, ensure_ascii=False) + "\n").encode("utf-8"))
    sys.stdout.buffer.flush()


def _apertura_automatica():
    try:
        registrar(f"apertura automatica: {abrir_blender()['estado']}")
    except Exception as exc:  # no debe tumbar el servidor
        registrar(f"apertura automatica fallida: {type(exc).__name__}: {exc}")


def main():
    threading.Thread(target=_apertura_automatica, daemon=True).start()
    for linea in sys.stdin.buffer:
        linea = linea.strip().lstrip(b"\xef\xbb\xbf")  # tolera un BOM UTF-8 al inicio de la entrada
        if not linea:
            continue
        try:
            msg = json.loads(linea.decode("utf-8"))
        except ValueError:
            enviar({"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "JSON invalido"}})
            continue
        metodo = msg.get("method")
        mid = msg.get("id")
        params = msg.get("params") or {}
        if mid is None:  # notificaciones (por ejemplo notifications/initialized): no se responden
            continue
        if metodo == "initialize":
            resultado = {
                "protocolVersion": params.get("protocolVersion", "2024-11-05"),
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "blender-puente", "version": "1.0.0"},
            }
        elif metodo == "tools/list":
            resultado = {"tools": HERRAMIENTAS}
        elif metodo == "tools/call":
            try:
                salida = ejecutar(params.get("name", ""), params.get("arguments") or {})
                texto = salida if isinstance(salida, str) else json.dumps(salida, ensure_ascii=False, indent=2)
                resultado = {"content": [{"type": "text", "text": texto}], "isError": False}
            except Exception as exc:
                registrar(f"error {params.get('name')}: {type(exc).__name__}: {exc}")
                resultado = {"content": [{"type": "text", "text": f"{type(exc).__name__}: {exc}"}], "isError": True}
        elif metodo == "ping":
            resultado = {}
        else:
            enviar({"jsonrpc": "2.0", "id": mid, "error": {"code": -32601, "message": f"metodo no soportado: {metodo}"}})
            continue
        enviar({"jsonrpc": "2.0", "id": mid, "result": resultado})


if __name__ == "__main__":
    main()
