#!/usr/bin/env python3
"""Frames the raw device captures into Play Store screenshots and draws the feature graphic.

Needs `pillow` built with libraqm (Bangla shaping). Run from the repo root:

    python3 tool/store/make_store_graphics.py

Input:  playstore/graphics/screenshots/raw/*.png   (1080x2340 Samsung captures)
Output: playstore/graphics/screenshots/phone_bn/   8 x 1080x1920, Bangla captions
        playstore/graphics/screenshots/phone_en/   8 x 1080x1920, English captions
        playstore/graphics/feature_graphic_1024x500.png

Look: flat warm paper background, left-aligned caption in the app's deep green, the
screenshot itself (no fake phone bezel) with soft rounded corners and a quiet shadow,
running off the bottom edge. Edit CAPTIONS / colours below and re-run.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets/fonts"
GRAPHICS = ROOT / "playstore/graphics"
RAW = GRAPHICS / "screenshots/raw"

# Raw capture geometry: status bar above y=100, gesture nav bar from y=2196.
RAW_TOP, RAW_BOTTOM = 100, 2196
# The save sheet is a modal over a dimmed editor; start at the sheet's own top edge
# so its rounded corners line up with ours instead of showing the grey scrim.
RAW_TOP_OVERRIDE = {"11_save_sheet": 100}

# The sample letter in the signature captures was signed twice on the device (black
# scribble plus a blue zigzag). Those captures get the scribble painted out and a clean
# pen signature drawn in its place, in raw-pixel coordinates: (erase box, centre).
SIGNATURE_FONT = "/System/Library/Fonts/Supplemental/SnellRoundhand.ttc"  # macOS, index 1 = Bold
SIGNATURE_TEXT = "Arif Hossain"
SIGNATURE_INK = (28, 46, 120)
SIGNATURE_FIX = {
    "12_viewer": ((560, 1315, 930, 1770), (742, 1545)),
    "09_sign_place": ((571, 1363, 913, 1795), (742, 1579)),  # inside the green selection box
}

W, H = 1080, 1920
PAPER = (245, 241, 232)       # warm off-white, like a sheet of paper
INK = (15, 74, 58)            # deep green for headlines (close to AppTheme.seed)
MUTED = (91, 101, 95)         # grey-green for sublines
EDGE = (205, 200, 188)        # 2 px hairline around the screenshot
SHADOW = (20, 50, 40)

MARGIN = 84
HEADLINE_Y = 150
SHOT_WIDTH = 912
SHOT_TOP = 470
CORNER = 40

# (raw file, output stem, bn headline, bn subline, en headline, en subline)
CAPTIONS = [
    ("01_home", "01_home",
     "স্ক্যান করুন, সই দিন, PDF বানান", "সবকিছু ফোনেই, ইন্টারনেট লাগে না",
     "Scan, sign, save as PDF", "All on your phone, no internet needed"),
    ("06_page_editor", "02_page_editor",
     "ঝকঝকে পাতা, এক ট্যাপে", "অটো কালার, সাদা-কালো, হোয়াইটবোর্ড ফিল্টার",
     "Clean pages in one tap", "Auto colour, black & white and whiteboard filters"),
    ("09_sign_place", "03_sign_place",
     "একবার সই আঁকুন", "যেকোনো পাতায় টেনে বসান, সিলও দিন",
     "Draw your signature once", "Drag it onto any page, add stamps too"),
    ("14_ocr_result", "04_ocr_result",
     "বাংলা ও ইংরেজি লেখা পড়ে নেয়", "অফলাইনে OCR, তারপর কপি বা শেয়ার করুন",
     "Reads Bangla and English", "Offline OCR, then copy or share the text"),
    ("11_save_sheet", "05_save_sheet",
     "PDF বা JPEG, আপনার মতো করে", "সার্চযোগ্য PDF, পাসওয়ার্ড দিয়ে সুরক্ষা",
     "PDF or JPEG, your way", "Searchable PDF, password protection"),
    ("02_library", "06_library",
     "সব ডকুমেন্ট এক জায়গায়", "ফোল্ডার, প্রিয়, লেখা দিয়ে খোঁজা",
     "All your documents in one place", "Folders, favourites, search by text"),
    ("04_idcard", "07_idcard",
     "NID ও পাসপোর্ট স্ক্যান", "দুই দিক এক A4 পাতায়, আসল মাপে",
     "NID and passport mode", "Both sides on one A4, at real size"),
    ("12_viewer", "08_viewer",
     "শেয়ার করুন এক ট্যাপে", "WhatsApp, Gmail বা Downloads-এ রাখুন",
     "Share in one tap", "WhatsApp, Gmail or save to Downloads"),
]


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"HindSiliguri-{weight}.ttf"), size)


def fit_font(draw, text, weight, size, max_width):
    """Shrinks the size until the text fits on one line."""
    while size > 24:
        f = font(weight, size)
        if draw.textlength(text, font=f) <= max_width:
            return f
        size -= 2
    return font(weight, size)


def rounded_mask(size, radius, bottom=True):
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    if not bottom:  # square off the bottom corners (the shot runs off the canvas)
        d.rectangle((0, size[1] - radius, size[0] - 1, size[1] - 1), fill=255)
    return mask


def draw_signature(im: Image.Image, erase: tuple, centre: tuple) -> None:
    """Whites out `erase` and draws a tilted script-font signature centred on `centre`."""
    ImageDraw.Draw(im).rectangle(erase, fill=(255, 255, 255))
    size = 2 * 60  # render at 2x, rotate, then downsample for smooth strokes
    f = ImageFont.truetype(SIGNATURE_FONT, size, index=1)
    tmp = ImageDraw.Draw(Image.new("L", (1, 1)))
    box = tmp.textbbox((0, 0), SIGNATURE_TEXT, font=f)
    pad = 60
    layer = Image.new("RGBA", (box[2] - box[0] + 2 * pad, box[3] - box[1] + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((pad - box[0], pad - box[1]), SIGNATURE_TEXT, font=f, fill=SIGNATURE_INK + (255,))
    layer = layer.rotate(7, resample=Image.BICUBIC, expand=True)
    layer = layer.resize((layer.width // 2, layer.height // 2), Image.LANCZOS)
    rgba = im.convert("RGBA")
    rgba.alpha_composite(layer, (centre[0] - layer.width // 2, centre[1] - layer.height // 2))
    im.paste(rgba.convert("RGB"))


def crop_raw(name: str) -> Image.Image:
    im = Image.open(RAW / f"{name}.png").convert("RGB")
    if name in SIGNATURE_FIX:
        draw_signature(im, *SIGNATURE_FIX[name])
    im = im.crop((0, RAW_TOP_OVERRIDE.get(name, RAW_TOP), im.width, RAW_BOTTOM))
    if name in RAW_TOP_OVERRIDE:
        # The sheet's corner radius is larger than ours, so paint the scrim that would
        # peek through at the corners in the sheet's own background colour.
        px = im.load()
        sheet_bg = px[im.width // 2, 2]
        for y in range(0, 130):
            for x in list(range(0, 140)) + list(range(im.width - 140, im.width)):
                if sum(px[x, y]) < sum(sheet_bg) - 30:  # scrim or its anti-aliased edge
                    px[x, y] = sheet_bg
    return im


def place_shot(canvas: Image.Image, shot: Image.Image, x: int, y: int, width: int, radius: int):
    """Draws a screenshot with rounded corners, hairline edge and soft shadow."""
    scale = width / shot.width
    shot = shot.resize((width, round(shot.height * scale)), Image.LANCZOS)
    size = shot.size
    mask = rounded_mask(size, radius)

    # Shadow: blurred rounded rectangle, offset down.
    pad = 60
    sh = Image.new("RGBA", (size[0] + pad * 2, size[1] + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad, pad + size[0], pad + size[1]), radius=radius, fill=SHADOW + (70,))
    sh = sh.filter(ImageFilter.GaussianBlur(26))
    canvas.alpha_composite(sh, (x - pad, y - pad + 16))

    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    layer.paste(shot, (0, 0))
    layer.putalpha(mask)
    canvas.alpha_composite(layer, (x, y))

    edge = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, outline=EDGE + (255,), width=2)
    canvas.alpha_composite(edge, (x, y))


def frame(raw_name: str, headline: str, subline: str) -> Image.Image:
    canvas = Image.new("RGBA", (W, H), PAPER + (255,))
    d = ImageDraw.Draw(canvas)
    max_w = W - 2 * MARGIN

    hf = fit_font(d, headline, "SemiBold", 78, max_w)
    d.text((MARGIN, HEADLINE_Y), headline, font=hf, fill=INK)
    hb = d.textbbox((MARGIN, HEADLINE_Y), headline, font=hf)

    sf = fit_font(d, subline, "Regular", 42, max_w)
    d.text((MARGIN, hb[3] + 26), subline, font=sf, fill=MUTED)

    x = (W - SHOT_WIDTH) // 2
    place_shot(canvas, crop_raw(raw_name), x, SHOT_TOP, SHOT_WIDTH, CORNER)
    return canvas.convert("RGB")


def feature_graphic() -> Image.Image:
    FW, FH = 1024, 500
    canvas = Image.new("RGBA", (FW, FH), PAPER + (255,))
    d = ImageDraw.Draw(canvas)

    icon = Image.open(GRAPHICS / "app_icon_512.png").convert("RGB").resize((150, 150), Image.LANCZOS)
    icon_layer = Image.new("RGBA", icon.size, (0, 0, 0, 0))
    icon_layer.paste(icon, (0, 0))
    icon_layer.putalpha(rounded_mask(icon.size, 34))
    canvas.alpha_composite(icon_layer, (72, 64))

    d.text((72, 236), "বাংলা স্ক্যানার", font=font("Bold", 76), fill=INK)
    d.text((72, 340), "Bangla Scanner", font=font("Medium", 38), fill=MUTED)
    d.text((72, 404), "স্ক্যান · সই · PDF · বাংলা OCR · অফলাইন", font=font("Regular", 30), fill=INK)

    place_shot(canvas, crop_raw("01_home"), 640, 48, 384, 28)
    return canvas.convert("RGB")


def main():
    for lang, hi, si in (("bn", 2, 3), ("en", 4, 5)):
        out = GRAPHICS / "screenshots" / f"phone_{lang}"
        out.mkdir(parents=True, exist_ok=True)
        for row in CAPTIONS:
            img = frame(row[0], row[hi], row[si])
            path = out / f"{row[1]}.png"
            img.save(path, optimize=True)
            print("wrote", path.relative_to(ROOT))
    fg = GRAPHICS / "feature_graphic_1024x500.png"
    feature_graphic().save(fg, optimize=True)
    print("wrote", fg.relative_to(ROOT))


if __name__ == "__main__":
    main()
