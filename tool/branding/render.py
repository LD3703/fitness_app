"""Vykreslí ikony, úvodní obrazovku a grafiku do obchodů z loga GymBar.

Logo (varianta 1 – „stupňovaná činka“) je popsané v souřadnicích 0–100,
stejně jako assets/branding/logo.svg. Hotové obrázky jsou v repozitáři,
takže skript stačí spustit jen při změně loga:

    python tool/branding/render.py

Potřebuje Python 3 a Pillow (pip install pillow). Písmo Archivo je pod
licencí OFL (assets/fonts/OFL.txt).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "branding"
STORE = ROOT / "docs" / "store" / "graphics"
WEB = ROOT / "docs" / "web"
FONTS = Path(__file__).resolve().parent

TEAL = (0x2E, 0x7D, 0x6B, 255)
AMBER = (0xFF, 0xC8, 0x57, 255)
WHITE = (255, 255, 255, 255)
INK = (0x13, 0x20, 0x1D, 255)
MUTED_ON_INK = (0xB8, 0xC4, 0xC0, 255)

# Činka: osa a kotouče rostoucí zleva doprava, poslední (nejtěžší) žlutý.
BAR = (12, 50, 88, 5)  # x1, y, x2, tloušťka (kulaté konce)
PLATES = [  # x, y, šířka, výška, barva
    (20, 41, 8, 18, WHITE),
    (31, 35, 8, 30, WHITE),
    (61, 29, 8, 42, WHITE),
    (72, 23, 8, 54, AMBER),
]
PLATE_RADIUS = 3
ICON_RADIUS = 22

SS = 4  # převzorkování kvůli hladkým hranám


def _glyph(draw, unit, ox, oy, mono=None):
    """Nakreslí činku; 1 jednotka loga = [unit] px, levý horní roh v (ox, oy)."""
    x1, y, x2, w = BAR
    color = mono or WHITE
    r = w / 2 * unit
    draw.rounded_rectangle(
        [ox + (x1 - w / 2) * unit, oy + (y - w / 2) * unit,
         ox + (x2 + w / 2) * unit, oy + (y + w / 2) * unit],
        radius=r, fill=color)
    for x, py, pw, ph, c in PLATES:
        draw.rounded_rectangle(
            [ox + x * unit, oy + py * unit,
             ox + (x + pw) * unit, oy + (py + ph) * unit],
            radius=PLATE_RADIUS * unit, fill=mono or c)


def _canvas(w, h, bg=(0, 0, 0, 0)):
    img = Image.new("RGBA", (w * SS, h * SS), bg)
    return img, ImageDraw.Draw(img)


def _finish(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def icon(size, rounded):
    """Celá ikona: teal pozadí + činka. [rounded] = průhledné rohy."""
    img, d = _canvas(size, size)
    unit = size * SS / 100
    if rounded:
        d.rounded_rectangle([0, 0, size * SS - 1, size * SS - 1],
                            radius=ICON_RADIUS * unit, fill=TEAL)
    else:
        d.rectangle([0, 0, size * SS, size * SS], fill=TEAL)
    _glyph(d, unit, 0, 0)
    return _finish(img, size, size)


def glyph_only(size, visible=72 / 108, mono=None):
    """Jen činka na průhledném pozadí.

    [visible] = jakou část plátna zabírá „ikona“ 0–100. U adaptivní ikony
    Androidu je vidět prostředních 72 z 108 dp, takže činka sedí stejně
    velká jako na celé ikoně a vejde se i do kulaté masky.
    """
    img, d = _canvas(size, size)
    unit = size * SS * visible / 100
    off = (size * SS - 100 * unit) / 2
    _glyph(d, unit, off, off, mono)
    return _finish(img, size, size)


def feature_graphic():
    """Grafika pro Google Play (1024 × 500): ikona, název a slogan."""
    w, h = 1024, 500
    img, d = _canvas(w, h, INK)
    s = SS
    icon_px = 220
    ix, iy = 112, (h - icon_px) // 2
    unit = icon_px * s / 100
    d.rounded_rectangle([ix * s, iy * s, (ix + icon_px) * s, (iy + icon_px) * s],
                        radius=ICON_RADIUS * unit, fill=TEAL)
    _glyph(d, unit, ix * s, iy * s)

    bold = ImageFont.truetype(str(FONTS / "archivo-latin-800-normal.woff"), 132 * s)
    semi = ImageFont.truetype(str(FONTS / "archivo-latin-600-normal.woff"), 40 * s)
    tx = (ix + icon_px + 56) * s
    gym_w = d.textlength("Gym", font=bold)
    # Název a slogan jako jeden blok svisle vycentrovaný vedle ikony.
    asc, desc = bold.getmetrics()
    semi_asc, semi_desc = semi.getmetrics()
    gap = 10 * s
    block = asc + desc + gap + semi_asc + semi_desc
    title_top = (h * s - block) / 2
    d.text((tx, title_top), "Gym", font=bold, fill=WHITE)
    d.text((tx + gym_w, title_top), "Bar", font=bold, fill=AMBER)
    d.text((tx + 6 * s, title_top + asc + desc + gap), "Raise the bar",
           font=semi, fill=MUTED_ON_INK)
    return _finish(img, w, h)


def og_image():
    """Náhled odkazu (Open Graph, 1200 × 630) – WhatsApp, Messenger, Facebook."""
    w, h = 1200, 630
    img = Image.new("RGB", (w, h), INK[:3])
    fg = feature_graphic().convert("RGB").resize((w, round(500 * w / 1024)),
                                                  Image.LANCZOS)
    img.paste(fg, (0, (h - fg.height) // 2))
    return img


SVG = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <title>GymBar</title>
  <rect width="100" height="100" rx="{ICON_RADIUS}" fill="#2E7D6B"/>
  <line x1="{BAR[0]}" y1="{BAR[1]}" x2="{BAR[2]}" y2="{BAR[1]}" stroke="#FFFFFF" stroke-width="{BAR[3]}" stroke-linecap="round"/>
""" + "".join(
    f'  <rect x="{x}" y="{y}" width="{pw}" height="{ph}" rx="{PLATE_RADIUS}" '
    f'fill="{"#FFC857" if c == AMBER else "#FFFFFF"}"/>\n'
    for x, y, pw, ph, c in PLATES) + "</svg>\n"


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    STORE.mkdir(parents=True, exist_ok=True)

    (OUT / "logo.svg").write_text(SVG, encoding="utf-8")
    (WEB / "favicon.svg").write_text(SVG, encoding="utf-8")

    # iOS: bez průhlednosti a bez zaoblení (zaoblí systém).
    icon(1024, rounded=False).convert("RGB").save(OUT / "icon_ios.png")
    # Android do 7.1 (bez adaptivních ikon) a web.
    icon(1024, rounded=True).save(OUT / "icon_android.png")
    glyph_only(1024).save(OUT / "adaptive_foreground.png")
    glyph_only(1024, mono=WHITE).save(OUT / "adaptive_monochrome.png")
    # Úvodní obrazovka: Android 12+ (1152, ikona v kruhu 768) a starší / iOS.
    glyph_only(1152).save(OUT / "splash_android12.png")
    glyph_only(768, visible=1.0).save(OUT / "splash.png")

    # Obchody: ikona 512 pro Google Play (rohy zaoblí Play sám).
    icon(512, rounded=False).save(STORE / "play_icon_512.png")
    feature_graphic().convert("RGB").save(STORE / "play_feature_graphic.png")
    og_image().save(WEB / "og-image.png")

    # Web: ikona pro záložky a plochu iPhonu.
    icon(180, rounded=False).convert("RGB").save(WEB / "apple-touch-icon.png")
    icon(192, rounded=True).save(WEB / "icon-192.png")
    print("Hotovo:", OUT, STORE, WEB)


if __name__ == "__main__":
    main()
