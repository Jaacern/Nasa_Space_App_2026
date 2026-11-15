"""Empaqueta un .luau como argumentos JSON de execute_luau.
Uso: python -B mk.py <archivo.luau> <Edit|Client|Server> <salida.json>
El id de Studio se lee de la variable de entorno STUDIO_ID (obtenlo con list_roblox_studios)."""
import json, os, pathlib, sys
json.dump({"code": pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), "datamodel_type": sys.argv[2], "studio_id": os.environ["STUDIO_ID"]}, open(sys.argv[3], "w", encoding="utf-8"))
