"""Monta el tráiler de ARES FORGE (30,0 s, 1920x1080, 30 fps) con ffmpeg.
Uso: python -B render_trailer.py   (desde la carpeta trailer/)
Entradas: raw/ (capturas reales del juego), ai/ (tomas y música de Google Flow), gfx/ (rótulos de make_titles.py)."""
import subprocess, pathlib

ROOT = pathlib.Path(__file__).resolve().parent
RAW, AI, GFX, SEG = ROOT / "raw", ROOT / "ai", ROOT / "gfx", ROOT / "build"
SEG.mkdir(exist_ok=True)
FPS = 30
GRADE_GAME = "eq=contrast=1.06:saturation=1.08,vignette=PI/5"
SCALE = "scale=1920:1080:flags=lanczos,unsharp=5:5:0.45"

# (fuente, inicio en la fuente, duración, rótulos [(png, t_in, t_out)], zoom final, grade)
SHOTS = [
    ("ai/flow_crash_1080p.mp4", 0.0, 5.5, [("team", 0.15, 5.3), ("lt_challenge", 2.0, 5.3), ("tag_ai", 0.0, 5.5)], 1.00, ""),
    ("raw/runB_cine.mp4", 39.5, 3.0, [("title", 0.0, 2.9), ("tag_game", 0.0, 3.0)], 1.06, GRADE_GAME),
    ("raw/runA_hud.mp4", 29.0, 2.5, [("lt_loop", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.03, GRADE_GAME),
    ("raw/runA_hud.mp4", 38.9, 2.5, [("lt_facts", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.10, GRADE_GAME),
    ("raw/runB_cine.mp4", 26.0, 2.5, [("lt_boss", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.05, GRADE_GAME),
    ("raw/runA_hud.mp4", 61.0, 2.5, [("lt_parts", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.08, GRADE_GAME),
    ("raw/runA_hud.mp4", 107.0, 2.5, [("lt_data", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.04, GRADE_GAME),
    ("PHONE", 0.0, 2.0, [("lt_devices", 0.05, 1.95), ("tag_phone", 0.0, 2.0)], 1.00, ""),
    ("ai/flow_liftoff_1080p.mp4", 2.8, 2.5, [("lt_future", 0.05, 2.45), ("tag_ai", 0.0, 2.5)], 1.04, ""),
    ("ENDCARD", 0.0, 4.5, [], 1.04, ""),
]


def run(args):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args])
    if r.returncode:
        raise SystemExit("ffmpeg falló: " + " ".join(map(str, args))[:400])


def zoom(dur, z):
    """Empuje lento de cámara (de 1.0 a z) sin temblor: escala grande y recorte centrado."""
    if z <= 1.0:
        return ""
    n = int(dur * FPS)
    return (f",scale=3840:2160:flags=lanczos,zoompan=z='1+({z}-1)*on/{n}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'"
            f":d=1:s=1920x1080:fps={FPS}")


def overlays(base_label, gfx, dur, first_input):
    """Encadena los PNG con aparición y salida de 0,2 s."""
    chain, last = [], base_label
    for k, (name, t0, t1) in enumerate(gfx):
        idx = first_input + k
        fo = max(t0, t1 - 0.2)
        chain.append(f"[{idx}:v]format=rgba,fade=t=in:st={t0}:d=0.2:alpha=1,fade=t=out:st={fo}:d=0.2:alpha=1[g{k}]")
        chain.append(f"[{last}][g{k}]overlay=0:0:enable='between(t,{t0},{t1})'[o{k}]")
        last = f"o{k}"
    return chain, last


for i, (src, ss, dur, gfx, z, grade) in enumerate(SHOTS):
    out = SEG / f"seg{i:02d}.mp4"
    inputs, pre = [], []
    if src == "PHONE":
        # Fondo: horda desenfocada; encima, el teléfono del simulador ampliado.
        inputs += ["-ss", "18", "-t", str(dur), "-i", str(RAW / "runB_cine.mp4"),
                   "-ss", "29.5", "-t", str(dur), "-i", str(RAW / "runM_phone.mp4")]
        pre.append(f"[0:v]{SCALE},boxblur=20:2,eq=brightness=-0.18:saturation=0.8,fps={FPS}[bg]")
        pre.append(f"[1:v]colorkey=0xBABDC8:0.06:0.02,scale=1380:-2:flags=lanczos,unsharp=5:5:0.6,fps={FPS}[ph]")  # quita el fondo gris del simulador
        pre.append("[bg][ph]overlay=(W-w)/2:92[base]")
        first = 2
    elif src == "ENDCARD":
        inputs += ["-loop", "1", "-t", str(dur), "-i", str(GFX / "endcard.png")]
        pre.append(f"[0:v]format=rgb24,fps={FPS}{zoom(dur, z)},fade=t=in:st=0:d=0.25[base]")
        first = 1
    else:
        inputs += ["-ss", str(ss), "-t", str(dur), "-i", str(ROOT / src)]
        g = ("," + grade) if grade else ""
        pre.append(f"[0:v]{SCALE},fps={FPS}{g}{zoom(dur, z)}[base]")
        first = 1
    for name, _, _ in gfx:
        inputs += ["-loop", "1", "-t", str(dur), "-i", str(GFX / f"{name}.png")]
    chain, last = overlays("base", gfx, dur, first)
    # Destello blanco breve al entrar el título (golpe musical en 0:05.5).
    if i == 1:
        chain.append(f"[{last}]fade=t=in:st=0:d=0.18:color=white[fl]")
        last = "fl"
    fc = ";".join(pre + chain)
    run([*inputs, "-filter_complex", fc, "-map", f"[{last}]", "-t", str(dur), "-r", str(FPS),
         "-c:v", "libx264", "-preset", "slow", "-crf", "14", "-pix_fmt", "yuv420p", "-an", str(out)])
    print("ok", out.name)

# Unión de planos (cortes secos).
lst = SEG / "list.txt"
lst.write_text("".join(f"file 'seg{i:02d}.mp4'\n" for i in range(len(SHOTS))), encoding="utf-8")
run(["-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(SEG / "video.mp4")])

# Música: tramo principal (97,8 s -> golpe en 0:05.5) + remate final (169,8 s) con fundido.
music = AI / "music_mars_trailer_cue.wav"
run(["-ss", "97.8", "-t", "25.8", "-i", str(music), "-ss", "169.8", "-t", "4.5", "-i", str(music),
     "-filter_complex",
     "[0:a]afade=t=in:st=0:d=0.3[a];[1:a]afade=t=out:st=3.2:d=1.3[b];[a][b]acrossfade=d=0.3:c1=tri:c2=tri,"
     "atrim=0:30,loudnorm=I=-14:TP=-1.0:LRA=9[m]",
     "-map", "[m]", "-ar", "48000", "-c:a", "pcm_s16le", str(SEG / "music.wav")])

meta = [
    "-metadata", "title=ARES FORGE — Team Code or die — NASA Space Apps Challenge 2026",
    "-metadata", "artist=Team Code or die (Concepción, Chile)",
    "-metadata", "comment=Real gameplay captured in Roblox Studio. AI disclosure: opening and closing shots generated with "
                 "Google Flow (Omni 1.2 Flash) and music generated with Google Flow Music; both are marked on screen. "
                 "Uses public NASA data. Not sponsored or endorsed by NASA.",
]
final = ROOT / "ARES_FORGE_trailer_30s_1080p.mp4"
run(["-i", str(SEG / "video.mp4"), "-i", str(SEG / "music.wav"), "-map", "0:v", "-map", "1:a",
     "-c:v", "copy", "-c:a", "aac", "-b:a", "320k", "-t", "30", "-movflags", "+faststart", *meta, str(final)])
print("FINAL", final)
