# -*- coding: utf-8 -*-
"""Puente local Blender <-> Claude Code. Auditable y sin dependencias externas.

Se ejecuta DENTRO de Blender, normalmente desde el servidor MCP:
    blender.exe --python tools/blender_mcp/bridge_addon.py

Garantias de seguridad:
  * Escucha solo en 127.0.0.1 (no accesible desde la red).
  * En Windows usa SO_EXCLUSIVEADDRUSE para que otro proceso no pueda robar el puerto.
  * Cada peticion debe llevar el token de TOKEN_FILE (comparacion en tiempo constante).
  * Solo acepta los comandos de COMMANDS. No ejecuta texto libre: solo archivos .py del proyecto.
  * Lectura y escritura: solo dentro de PROJECT_ROOT.
  * Cada comando queda registrado en logs/blender_bridge.log (sin token ni contenido de scripts).
"""

import contextlib
import hmac
import io
import json
import os
import queue
import runpy
import secrets
import socket
import threading
import time
import traceback
from pathlib import Path

import bpy  # solo existe dentro de Blender

AQUI = Path(__file__).resolve().parent
PROJECT_ROOT = AQUI.parents[1]
CONFIG = json.loads((AQUI / "config.json").read_text(encoding="utf-8"))
HOST = "127.0.0.1"
PORT = int(CONFIG["port"])
TOKEN_FILE = Path(os.path.expandvars(CONFIG["token_file"]))
LOG_FILE = PROJECT_ROOT / "logs" / "blender_bridge.log"
MAX_PETICION = 1_000_000
MAX_SALIDA = 20_000

_bloqueo_log = threading.Lock()
_cola = queue.Queue()


def registrar(evento, **datos):
    """Escribe una linea JSON en el log del proyecto. Nunca registra el token."""
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    linea = {"hora": time.strftime("%Y-%m-%d %H:%M:%S"), "evento": evento, **datos}
    with _bloqueo_log, LOG_FILE.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(linea, ensure_ascii=False) + "\n")


def cargar_o_crear_token():
    """Token aleatorio de 256 bits. Se crea solo si no existe (O_EXCL) y solo lo lee el usuario actual."""
    TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
    if TOKEN_FILE.exists():
        return TOKEN_FILE.read_text(encoding="utf-8").strip()
    token = secrets.token_urlsafe(32)
    fd = os.open(str(TOKEN_FILE), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(token)
    registrar("token_creado", archivo=str(TOKEN_FILE))  # solo la ruta, nunca el valor
    return token


TOKEN = cargar_o_crear_token()


def ruta_del_proyecto(ruta, extensiones=None):
    """Resuelve una ruta y exige que quede dentro de PROJECT_ROOT."""
    if not isinstance(ruta, str) or not ruta.strip():
        raise ValueError("ruta vacia")
    p = Path(ruta)
    p = (p if p.is_absolute() else PROJECT_ROOT / p).resolve()
    raiz = PROJECT_ROOT.resolve()
    if p != raiz and raiz not in p.parents:
        raise PermissionError(f"ruta fuera del proyecto: {p}")
    if extensiones and p.suffix.lower() not in extensiones:
        raise ValueError(f"extension no permitida '{p.suffix}' (permitidas: {', '.join(extensiones)})")
    return p


def relativa(p):
    return str(p.resolve().relative_to(PROJECT_ROOT.resolve()))


# ----------------------------------------------------------------- comandos
# Todos se ejecutan en el hilo principal de Blender.

def cmd_ping(_args):
    return {
        "blender": bpy.app.version_string,
        "archivo": bpy.data.filepath or "(sin guardar)",
        "escena": bpy.context.scene.name,
        "proyecto": str(PROJECT_ROOT),
    }


def _triangulos(malla):
    # Triangulos de la malla base (sin modificadores). Un poligono de n vertices = n-2 triangulos.
    return sum(max(len(p.vertices) - 2, 0) for p in malla.polygons)


def cmd_scene_info(_args):
    objetos = []
    for ob in list(bpy.data.objects)[:500]:
        info = {
            "nombre": ob.name,
            "tipo": ob.type,
            "colecciones": [c.name for c in ob.users_collection],
            "posicion": [round(v, 4) for v in ob.location],
            "escala": [round(v, 4) for v in ob.scale],
        }
        if ob.type == "MESH":
            info["triangulos"] = _triangulos(ob.data)
            info["materiales"] = len(ob.data.materials)
        objetos.append(info)
    return {"total": len(bpy.data.objects), "objetos": objetos}


def cmd_budget_report(args):
    nombre = args.get("coleccion", "COL_Export")
    col = bpy.data.collections.get(nombre)
    if col is None:
        raise ValueError(f"no existe la coleccion '{nombre}'")
    mallas = [
        {"nombre": ob.name, "triangulos": _triangulos(ob.data), "materiales": len(ob.data.materials)}
        for ob in col.all_objects if ob.type == "MESH"
    ]
    return {"coleccion": nombre, "mallas": mallas}


def cmd_run_script(args):
    ruta = ruta_del_proyecto(args.get("ruta", ""), extensiones=(".py",))
    if not ruta.is_file():
        raise FileNotFoundError(relativa(ruta))
    salida = io.StringIO()
    with contextlib.redirect_stdout(salida):
        runpy.run_path(str(ruta), run_name="__main__")
    registrar("run_script", archivo=relativa(ruta))
    return {"archivo": relativa(ruta), "salida": salida.getvalue()[-MAX_SALIDA:]}


def cmd_save_blend(args):
    ruta = ruta_del_proyecto(args.get("ruta", ""), extensiones=(".blend",))
    ruta.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(ruta), copy=True)  # copia: no cambia el archivo abierto
    registrar("save_blend", archivo=relativa(ruta))
    return {"archivo": relativa(ruta)}


def cmd_export_fbx(args):
    nombre = str(args.get("nombre", ""))
    if not nombre or not all(ch.isalnum() or ch == "_" for ch in nombre):
        raise ValueError("'nombre' solo admite letras, numeros y guion bajo")
    coleccion = args.get("coleccion", "COL_Export")
    col = bpy.data.collections.get(coleccion)
    if col is None:
        raise ValueError(f"no existe la coleccion '{coleccion}'")
    carpeta = ruta_del_proyecto(args.get("carpeta", "assets/export"))
    carpeta.mkdir(parents=True, exist_ok=True)
    destino = carpeta / f"{nombre}.fbx"
    objetos = [ob for ob in col.all_objects if ob.type in {"MESH", "ARMATURE", "EMPTY"}]
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objetos:
        ob.select_set(True)
    if objetos:
        bpy.context.view_layer.objects.active = objetos[0]
    # Ajustes de roblox-export: escala aplicada, ejes -Z/Y, sin texturas incrustadas.
    bpy.ops.export_scene.fbx(
        filepath=str(destino),
        use_selection=True,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        object_types={"MESH", "ARMATURE", "EMPTY"},
        path_mode="COPY",
        embed_textures=False,
        use_mesh_modifiers=True,
    )
    registrar("export_fbx", archivo=relativa(destino), objetos=len(objetos))
    return {"archivo": relativa(destino), "objetos": len(objetos)}


COMMANDS = {
    "ping": cmd_ping,
    "scene_info": cmd_scene_info,
    "budget_report": cmd_budget_report,
    "run_script": cmd_run_script,
    "save_blend": cmd_save_blend,
    "export_fbx": cmd_export_fbx,
}


# ------------------------------------------------------------------ servidor

def _crear_servidor():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    if hasattr(socket, "SO_EXCLUSIVEADDRUSE"):
        # En Windows, SO_REUSEADDR permitiria que otro proceso tomara el puerto. Esta opcion lo impide.
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
    srv.bind((HOST, PORT))  # solo loopback
    srv.listen(8)
    return srv


def _responder(conn, respuesta):
    conn.sendall((json.dumps(respuesta, ensure_ascii=False) + "\n").encode("utf-8"))


def _atender(conn):
    with conn:
        conn.settimeout(20)
        datos = b""
        try:
            while b"\n" not in datos:
                trozo = conn.recv(65536)
                if not trozo:
                    return
                datos += trozo
                if len(datos) > MAX_PETICION:
                    registrar("rechazado", motivo="tamano")
                    _responder(conn, {"ok": False, "error": "peticion demasiado grande"})
                    return
            peticion = json.loads(datos.split(b"\n", 1)[0].decode("utf-8"))
        except (OSError, ValueError):
            registrar("rechazado", motivo="formato")
            _responder(conn, {"ok": False, "error": "peticion invalida"})
            return
        if not isinstance(peticion, dict):
            registrar("rechazado", motivo="formato")
            _responder(conn, {"ok": False, "error": "peticion invalida"})
            return
        token_recibido = str(peticion.get("token", "")).encode("utf-8")
        if not hmac.compare_digest(token_recibido, TOKEN.encode("utf-8")):
            registrar("rechazado", motivo="token")
            _responder(conn, {"ok": False, "error": "token invalido"})
            return
        comando = peticion.get("cmd")
        if comando not in COMMANDS:
            registrar("rechazado", motivo="comando", comando=str(comando)[:40])
            _responder(conn, {"ok": False, "error": f"comando no permitido: {comando}"})
            return
        hecho = threading.Event()
        caja = {}
        _cola.put((comando, peticion.get("args") or {}, caja, hecho))
        if not hecho.wait(timeout=180):
            _responder(conn, {"ok": False, "error": "tiempo agotado esperando a Blender"})
            return
        _responder(conn, caja.get("resp", {"ok": False, "error": "sin respuesta"}))


def _bucle_aceptar(srv):
    while True:
        conn, _ = srv.accept()
        threading.Thread(target=_atender, args=(conn,), daemon=True).start()


def _bombear():
    """Corre en el hilo principal de Blender (bpy.app.timers) y ejecuta los comandos en cola."""
    while True:
        try:
            comando, args, caja, hecho = _cola.get_nowait()
        except queue.Empty:
            break
        try:
            caja["resp"] = {"ok": True, "result": COMMANDS[comando](args)}
        except Exception as exc:  # el error vuelve al cliente; no se oculta
            caja["resp"] = {"ok": False, "error": f"{type(exc).__name__}: {exc}"}
            registrar("error", comando=comando, detalle=f"{type(exc).__name__}: {exc}",
                      traza=traceback.format_exc()[-1500:])
        finally:
            hecho.set()
    return 0.1


def iniciar(con_temporizador=True):
    srv = _crear_servidor()
    threading.Thread(target=_bucle_aceptar, args=(srv,), daemon=True).start()
    if con_temporizador:
        bpy.app.timers.register(_bombear, first_interval=0.1, persistent=True)
    registrar("puente_iniciado", host=HOST, puerto=PORT, proyecto=str(PROJECT_ROOT))


if os.environ.get("BLENDER_BRIDGE_TEST") != "1":
    iniciar()
