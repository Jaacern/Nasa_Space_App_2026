"""Genera los rótulos del tráiler (PNG transparentes 1920x1080) con la estética del HUD del juego.
Uso: python -B make_titles.py <carpeta_salida>"""
import sys, pathlib
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = pathlib.Path(sys.argv[1]); OUT.mkdir(parents=True, exist_ok=True)
W, H = 1920, 1080
FONT = "C:/Windows/Fonts/bahnschrift.ttf"
CYAN, ORANGE, GOLD, WHITE, BG = (0, 210, 255), (255, 107, 53), (255, 200, 40), (248, 250, 252), (7, 11, 20)


def font(size, wght=700, wdth=100):
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_axes([wght, wdth])
    except Exception:
        pass
    return f


def spaced(draw, xy, text, f, fill, spacing=0, anchor="la", shadow=True):
    """Texto con interletrado y sombra suave."""
    x, y = xy
    widths = [draw.textlength(c, font=f) for c in text]
    total = sum(widths) + spacing * (len(text) - 1)
    if anchor[0] == "m":
        x -= total / 2
    elif anchor[0] == "r":
        x -= total
    if shadow:
        sh = Image.new("RGBA", (W, H), (0, 0, 0, 0)); sd = ImageDraw.Draw(sh)
        cx = x
        for c, w in zip(text, widths):
            sd.text((cx + 2, y + 3), c, font=f, fill=(0, 0, 0, 200), anchor="l" + anchor[1]); cx += w + spacing
        draw._image.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4)))
    cx = x
    for c, w in zip(text, widths):
        draw.text((cx, y), c, font=f, fill=fill, anchor="l" + anchor[1]); cx += w + spacing
    return total


def lower_third(name, kicker, line, y=860):
    """Rótulo inferior: etiqueta naranja + frase grande, barra cian a la izquierda."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    fk, fl = font(30, 600), font(58, 700)
    lw = d.textlength(line, font=fl) + 2 * len(line)
    panel = Image.new("RGBA", (W, H), (0, 0, 0, 0)); pd = ImageDraw.Draw(panel)
    pd.rounded_rectangle((96, y - 62, 96 + lw + 70, y + 52), 10, fill=(*BG, 175))
    im.alpha_composite(panel)
    d.rectangle((96, y - 62, 104, y + 52), fill=CYAN)
    spaced(d, (132, y - 34), kicker, fk, ORANGE, spacing=4, anchor="lm")
    spaced(d, (130, y + 14), line, fl, WHITE, spacing=2, anchor="lm")
    im.save(OUT / f"{name}.png")


def corner_tag(name, text, color, pos="tr"):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    f = font(24, 600)
    tw = d.textlength(text, font=f) + 3 * len(text)
    x1 = W - 48 if pos[1] == "r" else 48 + tw + 40
    x0 = x1 - tw - 40
    y0 = 40 if pos[0] == "t" else H - 40 - 44
    d.rounded_rectangle((x0, y0, x1, y0 + 44), 8, fill=(*BG, 160), outline=(*color, 230), width=2)
    spaced(d, (x0 + 20, y0 + 22), text, f, color, spacing=3, anchor="lm", shadow=False)
    im.save(OUT / f"{name}.png")


def title_card():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    vign = Image.new("RGBA", (W, H), (0, 0, 0, 0)); vd = ImageDraw.Draw(vign)
    vd.rectangle((0, 330, W, 760), fill=(*BG, 150))
    im.alpha_composite(vign.filter(ImageFilter.GaussianBlur(60)))
    spaced(d, (W / 2, 470), "ARES FORGE", font(170, 700, 100), WHITE, spacing=26, anchor="mm")
    d.rectangle((W / 2 - 110, 578, W / 2 + 110, 584), fill=ORANGE)
    spaced(d, (W / 2, 632), "SURVIVE MARS. RECOVER 4 REAL SPACECRAFT SYSTEMS. GO HOME.", font(40, 600), GOLD, spacing=3, anchor="mm")
    im.save(OUT / "title.png")


def end_card():
    im = Image.new("RGBA", (W, H), (*BG, 255)); d = ImageDraw.Draw(im)
    # retícula sutil de consola
    for x in range(0, W, 64):
        d.line((x, 0, x, H), fill=(19, 32, 74, 255))
    for y in range(0, H, 64):
        d.line((0, y, W, y), fill=(19, 32, 74, 255))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0)); gd = ImageDraw.Draw(glow)
    gd.ellipse((W / 2 - 700, 140, W / 2 + 700, 760), fill=(255, 107, 53, 60))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(120)))
    spaced(d, (W / 2, 330), "ARES FORGE", font(150, 700), WHITE, spacing=22, anchor="mm")
    d.rectangle((W / 2 - 100, 425, W / 2 + 100, 431), fill=ORANGE)
    spaced(d, (W / 2, 486), "A ROGUELITE THAT TEACHES REAL SPACE ENGINEERING", font(38, 600), GOLD, spacing=3, anchor="mm")
    spaced(d, (W / 2, 600), "TEAM CODE OR DIE  ·  CONCEPCIÓN, CHILE", font(44, 700), CYAN, spacing=4, anchor="mm")
    spaced(d, (W / 2, 660), "NASA SPACE APPS CHALLENGE 2026  ·  SPACE MISSION DESIGN GAME", font(32, 500), WHITE, spacing=3, anchor="mm")
    spaced(d, (W / 2, 760), "PLAY ON PC · MOBILE · GAMEPAD   |   BUILT IN ROBLOX + BLENDER", font(28, 500), (159, 176, 204), spacing=3, anchor="mm")
    small = font(22, 400)
    spaced(d, (W / 2, 950), "Uses public NASA data (CCMC DONKI, NTRS, InSight, Chandra). Not sponsored or endorsed by NASA.", small, (159, 176, 204), spacing=1, anchor="mm", shadow=False)
    spaced(d, (W / 2, 984), "Opening/closing shots and music generated with AI (Google Flow). All gameplay is real in-game capture.", small, (159, 176, 204), spacing=1, anchor="mm", shadow=False)
    im.save(OUT / "endcard.png")


def team_open():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    spaced(d, (96, 120), "TEAM CODE OR DIE", font(64, 700), WHITE, spacing=6, anchor="lm")
    d.rectangle((96, 162, 300, 167), fill=ORANGE)
    spaced(d, (96, 200), "CONCEPCIÓN, CHILE  ·  NASA SPACE APPS 2026", font(30, 600), CYAN, spacing=4, anchor="lm")
    im.save(OUT / "team.png")


team_open()
title_card()
end_card()
corner_tag("tag_ai", "AI-GENERATED · GOOGLE FLOW", GOLD, "br")
corner_tag("tag_game", "REAL GAMEPLAY", CYAN, "tr")
corner_tag("tag_phone", "REAL GAMEPLAY · iPHONE SIMULATOR", CYAN, "tr")
lower_third("lt_challenge", "CHALLENGE", "SPACE MISSION DESIGN GAME")
lower_third("lt_loop", "HOW IT PLAYS", "YOUR LASER FIRES ITSELF. YOU MOVE, DODGE, SURVIVE.")
lower_third("lt_facts", "LEARN BY PLAYING", "EVERY UPGRADE CARD SHOWS A REAL NASA FACT")
lower_third("lt_boss", "MISSION DESIGN", "4 BOSSES GUARD 4 REAL SPACECRAFT SYSTEMS")
lower_third("lt_parts", "NASA TECHNICAL REPORTS (NTRS)", "MMRTG · HIGH-GAIN ANTENNA · MOXIE · ORION ENGINE")
lower_third("lt_data", "NASA DONKI + INSIGHT + CHANDRA", "REAL SPACE EVENTS BECOME IN-GAME HAZARDS")
lower_third("lt_devices", "ANYWHERE", "PC · MOBILE · GAMEPAD  —  ENGLISH & SPANISH")
lower_third("lt_future", "THE FUTURE", "TRAIN THE NEXT EXPLORERS TO BRING CREWS HOME")
print("ok", sorted(p.name for p in OUT.glob("*.png")))
