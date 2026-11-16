"""Acabado del tráiler v3 (montaje en Remotion: video-core/src/ares/Trailer.tsx).
Toma el render de Remotion (1080p60, audio PCM), normaliza el audio a -14 LUFS / -1 dBTP,
genera el máster 1080p60 y el 4K60 para YouTube, y los copia al Escritorio.
Uso (desde trailer/): python -B finish_remotion.py <ruta al render de Remotion>"""
import subprocess, pathlib, shutil, sys

ROOT = pathlib.Path(__file__).resolve().parent
DESK = pathlib.Path.home() / "OneDrive" / "Escritorio"
SRC = pathlib.Path(sys.argv[1])
TOTAL = "29.9"


def run(args):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args])
    if r.returncode:
        raise SystemExit("ffmpeg falló: " + " ".join(map(str, args))[:400])


meta = [
    "-metadata", "title=ARES FORGE — Team Code or die — NASA Space Apps Challenge 2026",
    "-metadata", "artist=Team Code or die (Concepción, Chile)",
    "-metadata", "comment=Real gameplay captured in Roblox Studio. AI disclosure: opening and closing shots generated with "
                 "Google Flow (Omni 1.2 Flash), marked on screen; music generated with Google Flow Music. "
                 "Uses public NASA data. Not sponsored or endorsed by NASA.",
]
hd = ROOT / "ARES_FORGE_Trailer_1080p60.mp4"
uhd = ROOT / "ARES_FORGE_Trailer_4K60.mp4"
# Conserva la versión anterior (ffmpeg, v2) con otro nombre en trailer/.
for f in (hd, uhd):
    if f.exists():
        f.replace(f.with_name(f.stem + "_v2.mp4"))
aud = "loudnorm=I=-14:TP=-1.0:LRA=9,aresample=48000"
run(["-i", str(SRC), "-map", "0:v", "-map", "0:a", "-c:v", "copy", "-af", aud, "-c:a", "aac", "-b:a", "320k",
     "-t", TOTAL, "-movflags", "+faststart", *meta, str(hd)])
run(["-i", str(hd), "-vf", "scale=3840:2160:flags=lanczos,unsharp=7:7:0.35", "-c:v", "libx264", "-preset", "slow",
     "-crf", "15", "-profile:v", "high", "-level", "5.2", "-pix_fmt", "yuv420p", "-c:a", "copy",
     "-movflags", "+faststart", *meta, str(uhd)])
for f in (hd, uhd):
    shutil.copy2(f, DESK / f.name)
print("FINAL", hd.name, uhd.name)
