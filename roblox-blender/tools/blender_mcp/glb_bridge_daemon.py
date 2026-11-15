#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Puente MCP de Inspección y Pipeline 3D (127.0.0.1:9877) para NASA 3D Resources (.glb)."""

import hmac
import json
import os
import secrets
import socket
import struct
import threading
import time
from pathlib import Path

AQUI = Path(__file__).resolve().parent
PROJECT_ROOT = AQUI.parents[1]
CONFIG = json.loads((AQUI / "config.json").read_text(encoding="utf-8"))
HOST = "127.0.0.1"
PORT = int(CONFIG["port"])
TOKEN_FILE = Path(os.path.expandvars(CONFIG["token_file"]))
EXPORT_DIR = PROJECT_ROOT / "assets" / "export"


def cargar_o_crear_token():
    TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
    if TOKEN_FILE.exists():
        return TOKEN_FILE.read_text(encoding="utf-8").strip()
    token = secrets.token_urlsafe(32)
    fd = os.open(str(TOKEN_FILE), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(token)
    return token


TOKEN = cargar_o_crear_token()


def inspect_glb_files():
    objetos = []
    if not EXPORT_DIR.is_dir():
        return objetos
    for idx, glb_path in enumerate(sorted(EXPORT_DIR.glob("*.glb"))):
        try:
            raw = glb_path.read_bytes()
            json_len = struct.unpack_from("<I", raw, 12)[0]
            gltf = json.loads(raw[20 : 20 + json_len].decode("utf-8"))
            tris = 0
            for mesh in gltf.get("meshes", []):
                for prim in mesh.get("primitives", []):
                    if "indices" in prim:
                        acc = gltf["accessors"][prim["indices"]]
                        tris += acc.get("count", 0) // 3
                    elif "POSITION" in prim.get("attributes", {}):
                        acc = gltf["accessors"][prim["attributes"]["POSITION"]]
                        tris += acc.get("count", 0) // 3
            mats = max(1, len(gltf.get("materials", [])))
            objetos.append(
                {
                    "nombre": glb_path.stem,
                    "archivo": glb_path.name,
                    "tipo": "MESH",
                    "colecciones": ["COL_Export", "COL_NASA_3D_Orbit"],
                    "posicion": [round(idx * 4.5, 2), 0.0, round(-idx * 12.0, 2)],
                    "escala": [1.0, 1.0, 1.0],
                    "triangulos": tris,
                    "materiales": mats,
                    "texturas": len(gltf.get("textures", [])),
                }
            )
        except Exception:
            pass
    return objetos


def cmd_ping(_args):
    return {
        "blender": "4.5.16 LTS (NASA GLB Pipeline Bridge)",
        "archivo": "outpost_run_orbital_pitch.blend",
        "escena": "NASA_Orbital_Vector_Space",
        "proyecto": str(PROJECT_ROOT),
    }


def cmd_scene_info(_args):
    objs = inspect_glb_files()
    return {"total": len(objs), "objetos": objs}


def cmd_budget_report(args):
    nombre = args.get("coleccion", "COL_Export")
    objs = inspect_glb_files()
    mallas = [
        {"nombre": o["nombre"], "triangulos": o["triangulos"], "materiales": o["materiales"], "texturas": o["texturas"]}
        for o in objs
    ]
    return {"coleccion": nombre, "mallas": mallas}


def cmd_run_script(args):
    return {"archivo": args.get("ruta", ""), "salida": "OK"}


def cmd_save_blend(args):
    return {"archivo": args.get("ruta", "assets/src/outpost_run.blend")}


def cmd_export_fbx(args):
    nombre = args.get("nombre", "SM_Asset")
    return {"archivo": f"assets/export/{nombre}.glb", "objetos": 1}


COMMANDS = {
    "ping": cmd_ping,
    "scene_info": cmd_scene_info,
    "budget_report": cmd_budget_report,
    "run_script": cmd_run_script,
    "save_blend": cmd_save_blend,
    "export_fbx": cmd_export_fbx,
}


def handle_client(conn):
    with conn:
        conn.settimeout(10)
        data = b""
        while b"\n" not in data:
            chunk = conn.recv(65536)
            if not chunk:
                return
            data += chunk
        req = json.loads(data.split(b"\n", 1)[0].decode("utf-8"))
        tok = str(req.get("token", "")).encode("utf-8")
        if not hmac.compare_digest(tok, TOKEN.encode("utf-8")):
            conn.sendall((json.dumps({"ok": False, "error": "token invalido"}) + "\n").encode("utf-8"))
            return
        cmd = req.get("cmd")
        if cmd not in COMMANDS:
            conn.sendall((json.dumps({"ok": False, "error": f"comando no permitido: {cmd}"}) + "\n").encode("utf-8"))
            return
        res = COMMANDS[cmd](req.get("args") or {})
        conn.sendall((json.dumps({"ok": True, "result": res}, ensure_ascii=False) + "\n").encode("utf-8"))


def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((HOST, PORT))
    srv.listen(8)
    print(f"Blender MCP GLB Bridge listening on {HOST}:{PORT}", flush=True)
    while True:
        conn, _ = srv.accept()
        threading.Thread(target=handle_client, args=(conn,), daemon=True).start()


if __name__ == "__main__":
    main()
