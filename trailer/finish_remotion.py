"""Acabado del tráiler v3 (montaje en Remotion: video-core/src/ares/Trailer.tsx).
Toma el render de Remotion (1080p60, audio PCM), normaliza el audio a -14 LUFS / -1 dBTP,
genera el máster 1080p60 y el 4K60 para YouTube, y los copia al Escritorio.
Uso (desde trailer/): python -B finish_remotion.py <ruta al render de Remotion>"""
import json, pathlib, re, shutil, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent
DESK = pathlib.Path.home() / "OneDrive" / "Escritorio"
SRC = pathlib.Path(sys.argv[1])
TOTAL = "29.9"


def run(args, capture=False):
    r = subprocess.run(
        ["ffmpeg", "-hide_banner", *([] if capture else ["-loglevel", "error"]), "-y", *args],
        text=True, capture_output=capture,
    )
    if r.returncode:
        raise SystemExit("ffmpeg falló: " + " ".join(map(str, args))[:400])
    return r


meta = [
    "-metadata", "title=ARES FORGE — Team Code or die — NASA Space Apps Challenge 2026",
    "-metadata", "artist=Team Code or die (Concepción, Chile)",
    "-metadata", "comment=Real gameplay captured in Roblox Studio. AI disclosure: opening and closing shots generated with "
                 "Google Flow (Omni 1.2 Flash), and music generated with Google Flow Music (declared on end card and metadata). "
                 "Uses public NASA data. Not sponsored or endorsed by NASA.",
]
hd = ROOT / "ARES_FORGE_Trailer_1080p60.mp4"
uhd = ROOT / "ARES_FORGE_Trailer_4K60.mp4"
# Conserva copias previas sin pisar la v2 de ffmpeg.
for f in (hd, uhd):
    if f.exists():
        v3 = f.with_name(f.stem + "_v3.mp4")
        if not v3.exists():
            f.replace(v3)
        else:
            f.unlink()

# Loudnorm en 2 pasadas (linear=true): mantiene LRA sin comprimir y garantiza TP <= -1.0 dBTP.
target = "I=-14:TP=-1.5:LRA=11"
p1 = run(["-i", str(SRC), "-t", TOTAL, "-af", f"loudnorm={target}:print_format=json", "-f", "null", "-"], capture=True)
m = json.loads(re.search(r"\{[\s\S]*\}", p1.stderr).group(0))
aud = (
    f"loudnorm={target}:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
    f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:"
    f"offset={m['target_offset']}:linear=true,aresample=48000"
)
run(["-i", str(SRC), "-map", "0:v", "-map", "0:a", "-c:v", "copy", "-af", aud, "-c:a", "aac", "-b:a", "320k",
     "-t", TOTAL, "-movflags", "+faststart", *meta, str(hd)])
run(["-i", str(hd), "-vf", "scale=3840:2160:flags=lanczos,unsharp=7:7:0.35", "-c:v", "libx264", "-preset", "slow",
     "-crf", "15", "-profile:v", "high", "-level", "5.2", "-pix_fmt", "yuv420p", "-c:a", "copy",
     "-movflags", "+faststart", *meta, str(uhd)])
for f in (hd, uhd):
    shutil.copy2(f, DESK / f.name)
p2 = run(["-i", str(hd), "-af", "loudnorm=print_format=json", "-f", "null", "-"], capture=True)
fm = json.loads(re.search(r"\{[\s\S]*\}", p2.stderr).group(0))
print(f"FINAL {hd.name} {uhd.name} | audio: {fm['input_i']} LUFS / {fm['input_tp']} dBTP / LRA {fm['input_lra']}")
