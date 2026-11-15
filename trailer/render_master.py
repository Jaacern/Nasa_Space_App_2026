"""Máster final del tráiler de ARES FORGE: 29,9 s, 60 fps, 1080p y 4K, con rótulos animados y diseño sonoro.
Uso (desde trailer/): python -B render_master.py
Requiere: raw/ (gameplay a 60 fps), ai/flow_crash_60.mp4 y ai/flow_liftoff_60.mp4 (interpolados con minterpolate),
ai/music_mars_trailer_cue.wav y gfx/ (make_titles.py). La versión de 30 fps anterior es render_trailer.py."""
import subprocess, pathlib, shutil

ROOT = pathlib.Path(__file__).resolve().parent
RAW, AI, GFX, SEG = ROOT / "raw", ROOT / "ai", ROOT / "gfx", ROOT / "build60"
SEG.mkdir(exist_ok=True)
DESK = pathlib.Path.home() / "OneDrive" / "Escritorio"
FPS = 60
GRADE_GAME = "eq=contrast=1.06:saturation=1.08,vignette=PI/5"
SCALE = "scale=1920:1080:flags=lanczos,unsharp=5:5:0.45"
LT = ("lt_challenge", "lt_loop", "lt_facts", "lt_boss", "lt_parts", "lt_data", "lt_devices", "lt_future", "team")

SHOTS = [
    ("ai/flow_crash_60.mp4", 0.0, 5.5, [("team", 0.15, 5.35), ("lt_challenge", 2.0, 5.35), ("tag_ai", 0.0, 5.5)], 1.00, ""),
    ("raw/runB_cine.mp4", 39.5, 3.0, [("title", 0.0, 2.95), ("tag_game", 0.0, 3.0)], 1.06, GRADE_GAME),
    ("raw/runA_hud.mp4", 29.0, 2.5, [("lt_loop", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.03, GRADE_GAME),
    ("raw/runA_hud.mp4", 38.9, 2.5, [("lt_facts", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.10, GRADE_GAME),
    ("raw/runB_cine.mp4", 26.0, 2.5, [("lt_boss", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.05, GRADE_GAME),
    ("raw/runA_hud.mp4", 61.0, 2.5, [("lt_parts", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.08, GRADE_GAME),
    ("raw/runA_hud.mp4", 107.0, 2.5, [("lt_data", 0.05, 2.45), ("tag_game", 0.0, 2.5)], 1.04, GRADE_GAME),
    ("PHONE", 0.0, 2.0, [("lt_devices", 0.05, 1.95), ("tag_phone", 0.0, 2.0)], 1.00, ""),
    ("ai/flow_liftoff_60.mp4", 0.2, 2.5, [("lt_future", 0.05, 2.45), ("tag_ai", 0.0, 2.5)], 1.04, ""),
    ("ENDCARD", 0.0, 4.4, [], 1.04, ""),
]
TOTAL = sum(s[2] for s in SHOTS)  # 29,9 s


def run(args):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args])
    if r.returncode:
        raise SystemExit("ffmpeg falló: " + " ".join(map(str, args))[:500])


def zoom(dur, z):
    if z <= 1.0:
        return ""
    n = int(dur * FPS)
    return (f",scale=3840:2160:flags=lanczos,zoompan=z='1+({z}-1)*on/{n}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'"
            f":d=1:s=1920x1080:fps={FPS}")


def overlay_chain(gfx, first):
    chain, last = [], "base"
    for k, (name, t0, t1) in enumerate(gfx):
        idx, fo = first + k, max(t0, t1 - 0.2)
        if name == "title":
            # Golpe de título: entra grande (x1.18) y se asienta con curva de frenado en 0,4 s.
            chain.append(f"[{idx}:v]format=rgba,scale=w='trunc(1920*(1+0.18*pow(max(0\\,1-t/0.4)\\,2))/2)*2':h=-2:eval=frame,"
                         f"fade=t=in:st={t0}:d=0.12:alpha=1,fade=t=out:st={fo}:d=0.2:alpha=1[g{k}]")
            chain.append(f"[{last}][g{k}]overlay=x='(W-w)/2':y='(H-h)/2':eval=frame:enable='between(t,{t0},{t1})'[o{k}]")
        else:
            chain.append(f"[{idx}:v]format=rgba,fade=t=in:st={t0}:d=0.22:alpha=1,fade=t=out:st={fo}:d=0.2:alpha=1[g{k}]")
            # Rótulos: deslizamiento corto desde la izquierda con frenado.
            x = f"'-70*pow(max(0\\,1-(t-{t0})/0.3)\\,2)'" if name in LT else "0"
            chain.append(f"[{last}][g{k}]overlay=x={x}:y=0:eval=frame:enable='between(t,{t0},{t1})'[o{k}]")
        last = f"o{k}"
    return chain, last


for i, (src, ss, dur, gfx, z, grade) in enumerate(SHOTS):
    out = SEG / f"seg{i:02d}.mp4"
    inputs, pre = [], []
    if src == "PHONE":
        inputs += ["-ss", "18", "-t", str(dur), "-i", str(RAW / "runB_cine.mp4"),
                   "-ss", "29.5", "-t", str(dur), "-i", str(RAW / "runM_phone.mp4")]
        pre.append(f"[0:v]{SCALE},boxblur=20:2,eq=brightness=-0.18:saturation=0.8,fps={FPS}[bg]")
        pre.append(f"[1:v]colorkey=0xBABDC8:0.06:0.02,scale=1380:-2:flags=lanczos,unsharp=5:5:0.6,fps={FPS}[ph]")
        pre.append("[bg][ph]overlay=(W-w)/2:92[base]")
        first = 2
    elif src == "ENDCARD":
        inputs += ["-loop", "1", "-framerate", str(FPS), "-t", str(dur), "-i", str(GFX / "endcard.png")]
        pre.append(f"[0:v]format=rgb24{zoom(dur, z)},fade=t=in:st=0:d=0.25[base]")
        first = 1
    else:
        inputs += ["-ss", str(ss), "-t", str(dur), "-i", str(ROOT / src)]
        g = ("," + grade) if grade else ""
        pre.append(f"[0:v]{SCALE},fps={FPS}{g}{zoom(dur, z)}[base]")
        first = 1
    for name, _, _ in gfx:
        inputs += ["-loop", "1", "-framerate", str(FPS), "-t", str(dur), "-i", str(GFX / f"{name}.png")]
    chain, last = overlay_chain(gfx, first)
    if i == 1:
        chain.append(f"[{last}]fade=t=in:st=0:d=0.18:color=white[fl]")
        last = "fl"
    run([*inputs, "-filter_complex", ";".join(pre + chain), "-map", f"[{last}]", "-t", str(dur), "-r", str(FPS),
         "-c:v", "libx264", "-preset", "slow", "-crf", "11", "-pix_fmt", "yuv420p", "-an", str(out)])
    print("ok", out.name, flush=True)

(SEG / "list.txt").write_text("".join(f"file 'seg{i:02d}.mp4'\n" for i in range(len(SHOTS))), encoding="utf-8")
run(["-f", "concat", "-safe", "0", "-i", str(SEG / "list.txt"), "-c", "copy", str(SEG / "video.mp4")])

# Música (golpe en 0:05.5, remate en la tarjeta final) + diseño sonoro propio sintetizado.
music = AI / "music_mars_trailer_cue.wav"
run(["-ss", "97.8", "-t", "25.8", "-i", str(music), "-ss", "169.8", "-t", "4.4", "-i", str(music),
     "-filter_complex", "[0:a]afade=t=in:st=0:d=0.3[a];[1:a]afade=t=out:st=3.0:d=1.4[b];[a][b]acrossfade=d=0.3:c1=tri:c2=tri[m]",
     "-map", "[m]", "-ar", "48000", "-ac", "2", str(SEG / "music.wav")])
boom = "aevalsrc='0.95*sin(2*PI*(38+70*exp(-t*9))*t)*exp(-t*2.6)|0.95*sin(2*PI*(38+70*exp(-t*9))*t)*exp(-t*2.6)':s=48000:d=2.6"
run(["-f", "lavfi", "-i", "anoisesrc=d=1.3:c=pink:a=0.6:r=48000",
     "-f", "lavfi", "-i", boom, "-f", "lavfi", "-i", boom,
     "-filter_complex",
     "[0:a]highpass=f=400,lowpass=f=9000,volume='pow(t/1.3\\,3)':eval=frame,aformat=channel_layouts=stereo,adelay=4200|4200[r];"
     "[1:a]adelay=5500|5500,volume=0.9[b1];[2:a]adelay=25500|25500,volume=0.8[b2];"
     f"[r][b1][b2]amix=inputs=3:normalize=0,atrim=0:{TOTAL}[s]",
     "-map", "[s]", "-ar", "48000", str(SEG / "sfx.wav")])
run(["-i", str(SEG / "music.wav"), "-i", str(SEG / "sfx.wav"), "-filter_complex",
     f"[1:a]volume=0.55[s];[0:a][s]amix=inputs=2:normalize=0,atrim=0:{TOTAL},loudnorm=I=-14:TP=-1.0:LRA=9[x]",
     "-map", "[x]", "-ar", "48000", "-c:a", "pcm_s16le", str(SEG / "mix.wav")])

meta = [
    "-metadata", "title=ARES FORGE — Team Code or die — NASA Space Apps Challenge 2026",
    "-metadata", "artist=Team Code or die (Concepción, Chile)",
    "-metadata", "comment=Real gameplay captured in Roblox Studio. AI disclosure: opening and closing shots generated with "
                 "Google Flow (Omni 1.2 Flash) and music generated with Google Flow Music; AI shots are marked on screen. "
                 "Uses public NASA data. Not sponsored or endorsed by NASA.",
]
hd = ROOT / "ARES_FORGE_Trailer_1080p60.mp4"
run(["-i", str(SEG / "video.mp4"), "-i", str(SEG / "mix.wav"), "-map", "0:v", "-map", "1:a", "-c:v", "copy",
     "-c:a", "aac", "-b:a", "320k", "-t", str(TOTAL), "-movflags", "+faststart", *meta, str(hd)])
# 4K: reescalado lanczos + nitidez suave. YouTube asigna más bitrate a los envíos 4K (mejor imagen también en 1080p).
uhd = ROOT / "ARES_FORGE_Trailer_4K60.mp4"
run(["-i", str(hd), "-vf", "scale=3840:2160:flags=lanczos,unsharp=7:7:0.35", "-c:v", "libx264", "-preset", "slow",
     "-crf", "15", "-profile:v", "high", "-level", "5.2", "-pix_fmt", "yuv420p", "-c:a", "copy",
     "-movflags", "+faststart", *meta, str(uhd)])
for f in (hd, uhd):
    shutil.copy2(f, DESK / f.name)
print("FINAL", hd.name, uhd.name)
