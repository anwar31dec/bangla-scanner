#!/usr/bin/env python3
"""Generates every launcher icon (Android prod + dev flavor, iOS) from one drawing.

Needs `pillow` (pip, built with libraqm for Bangla shaping) and `rsvg-convert`
(brew install librsvg). Run from the repo root:

    python3 tool/icon/generate_icons.py

The artwork is a scanned page carrying the app name "বাংলা স্ক্যানার" on two lines inside
viewfinder brackets, on the app's seed green (AppTheme.seed). The name is rendered with
Pillow (HarfBuzz shaping through libraqm) and embedded in the SVG as a PNG, because
rsvg-convert cannot shape Bangla text. Edit the constants / `artwork()` and re-run.
"""
import base64
import io
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/HindSiliguri-Bold.ttf"
ANDROID_RES = ROOT / "android/app/src/{flavor}/res"
IOS_ICONSET = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

GREEN = "#006A4E"  # AppTheme.seed
GREEN_LIGHT = "#0A8A67"
GREEN_DARK = "#004D39"
RED = "#F42A41"
PAPER = "#FFFFFF"
FOLD = "#CFE5DD"
DEV_RED = "#D32F2F"

NAME_LINES = (("বাংলা", 176, 372), ("স্ক্যানার", 150, 528))  # text, font size, centre y
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
TEXT_SCALE = 2  # the name is rasterised at 2048 px and downsampled by the renderer


def name_image(color):
    """The two-line app name as a base64 PNG (transparent background) on a 1024 canvas."""
    k = TEXT_SCALE
    img = Image.new("RGBA", (1024 * k, 1024 * k), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for text, size, cy in NAME_LINES:
        font = ImageFont.truetype(str(FONT), size * k)
        draw.text((512 * k, cy * k), text, font=font, fill=color, anchor="mm")
    buf = io.BytesIO()
    img.save(buf, "PNG", optimize=True)
    data = base64.b64encode(buf.getvalue()).decode("ascii")
    return f'<image x="0" y="0" width="1024" height="1024" href="data:image/png;base64,{data}"/>'


def brackets(color, width=34):
    """Four viewfinder corners of a 620 square centred on the 1024 canvas."""
    a, b, arm, r = 202, 822, 96, 44
    d = (
        f"M{a} {a + arm + r}V{a + r}Q{a} {a} {a + r} {a}H{a + arm + r}"
        f"M{b - arm - r} {a}H{b - r}Q{b} {a} {b} {a + r}V{a + arm + r}"
        f"M{b} {b - arm - r}V{b - r}Q{b} {b} {b - r} {b}H{b - arm - r}"
        f"M{a + arm + r} {b}H{a + r}Q{a} {b} {a} {b - r}V{b - arm - r}"
    )
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round"/>'


# Page outline: 380x470 with a folded top-right corner.
PX0, PY0, PX1, PY1, PR, PFOLD = 252, 268, 772, 756, 34, 84
PAGE = (
    f"M{PX0 + PR} {PY0}H{PX1 - PFOLD}L{PX1} {PY0 + PFOLD}V{PY1 - PR}"
    f"Q{PX1} {PY1} {PX1 - PR} {PY1}H{PX0 + PR}Q{PX0} {PY1} {PX0} {PY1 - PR}"
    f"V{PY0 + PR}Q{PX0} {PY0} {PX0 + PR} {PY0}Z"
)
FOLD_PATH = (
    f"M{PX1 - PFOLD} {PY0}L{PX1} {PY0 + PFOLD}H{PX1 - PFOLD + 26}"
    f"Q{PX1 - PFOLD} {PY0 + PFOLD} {PX1 - PFOLD} {PY0 + PFOLD - 26}Z"
)
SCAN_Y, SCAN_X0, SCAN_X1, SCAN_W = 690, 202, 822, 26


def artwork():
    """Full-colour foreground (no background), drawn on a 1024 canvas."""
    return f"""
  <defs>
    <linearGradient id="beam" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{RED}" stop-opacity="0"/>
      <stop offset="1" stop-color="{RED}" stop-opacity="0.26"/>
    </linearGradient>
    <clipPath id="page"><path d="{PAGE}"/></clipPath>
  </defs>
  {brackets(PAPER)}
  <path d="{PAGE}" fill="#00271C" opacity="0.22" transform="translate(0 14)"/>
  <path d="{PAGE}" fill="{PAPER}"/>
  <path d="{FOLD_PATH}" fill="{FOLD}"/>
  <rect x="{PX0}" y="{SCAN_Y - 112}" width="{PX1 - PX0}" height="112" fill="url(#beam)" clip-path="url(#page)"/>
  {name_image(GREEN)}
  <path d="M{SCAN_X0} {SCAN_Y}H{SCAN_X1}" stroke="{RED}" stroke-width="{SCAN_W}" stroke-linecap="round"/>
"""


def monochrome():
    """Single-colour silhouette for Android 13+ themed icons (only alpha matters)."""
    gap = SCAN_W + 30
    return f"""
  <defs>
    <mask id="cut">
      <rect width="1024" height="1024" fill="#fff"/>
      {name_image("#000")}
      <path d="M{SCAN_X0} {SCAN_Y}H{SCAN_X1}" stroke="#000" stroke-width="{gap}" stroke-linecap="round"/>
    </mask>
  </defs>
  {brackets("#000")}
  <path d="{PAGE}" fill="#000" mask="url(#cut)"/>
  <path d="M{SCAN_X0} {SCAN_Y}H{SCAN_X1}" stroke="#000" stroke-width="{SCAN_W}" stroke-linecap="round"/>
"""


def background(shape=""):
    """Green gradient fill; `shape` is an optional clip (rounded square for legacy icons)."""
    grad = f"""
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{GREEN_LIGHT}"/>
      <stop offset="0.55" stop-color="{GREEN}"/>
      <stop offset="1" stop-color="{GREEN_DARK}"/>
    </linearGradient>
  </defs>"""
    return grad + (shape or '<rect width="1024" height="1024" fill="url(#bg)"/>')


def dev_band(y, text_y, font_size):
    """Red "DEV" band along the bottom so testers can tell the dev build from prod."""
    return f"""
  <rect x="0" y="{y}" width="1024" height="{1024 - y}" fill="{DEV_RED}"/>
  <text x="512" y="{text_y + font_size * 0.36}" text-anchor="middle" font-family="Helvetica Neue, Helvetica, Arial, sans-serif"
        font-weight="bold" font-size="{font_size}" letter-spacing="{font_size * 0.06:.0f}" fill="#fff">DEV</text>
"""


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{body}</svg>'


def scaled(body, scale):
    """Shrinks `body` around the canvas centre."""
    t = 512 * (1 - scale)
    return f'<g transform="translate({t:.2f} {t:.2f}) scale({scale})">{body}</g>'


def full_icon():
    """Square, full-bleed icon (iOS; the OS applies its own mask)."""
    return svg(background() + scaled(artwork(), 1.06))


def legacy_icon(dev=False):
    """Pre-Android 8 icon: rounded square with a little transparent margin."""
    clip = '<clipPath id="tile"><rect x="52" y="52" width="920" height="920" rx="200"/></clipPath>'
    band = dev_band(760, 866, 150) if dev else ""
    inner = background() + scaled(artwork(), 0.96) + band
    return svg(f'<defs>{clip}</defs><g clip-path="url(#tile)">{inner}</g>')


ADAPTIVE_SCALE = 0.69  # keeps the brackets inside the 66/108 safe zone


def adaptive_foreground(dev=False):
    """Adaptive foreground body; the launcher mask shows roughly the middle 72/108."""
    band = dev_band(664, 742, 108) if dev else ""
    return scaled(artwork(), ADAPTIVE_SCALE) + band


def render(svg_text, size, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg_text)
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), f.name, "-o", str(out)], check=True)
    Path(f.name).unlink()


def write_android():
    for flavor, dev in (("main", False), ("dev", True)):
        res = Path(str(ANDROID_RES).format(flavor=flavor))
        for density, k in DENSITIES.items():
            mip = res / f"mipmap-{density}"
            render(legacy_icon(dev), round(48 * k), mip / "ic_launcher.png")
            render(svg(adaptive_foreground(dev)), round(108 * k), mip / "ic_launcher_foreground.png")
            if not dev:
                render(svg(background()), round(108 * k), mip / "ic_launcher_background.png")
                render(svg(scaled(monochrome(), ADAPTIVE_SCALE)), round(108 * k), mip / "ic_launcher_monochrome.png")
    adaptive = Path(str(ANDROID_RES).format(flavor="main")) / "mipmap-anydpi-v26/ic_launcher.xml"
    adaptive.parent.mkdir(parents=True, exist_ok=True)
    adaptive.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        "</adaptive-icon>\n"
    )


def write_ios():
    contents = json.loads((IOS_ICONSET / "Contents.json").read_text())
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        pixels = round(points * int(image["scale"].rstrip("x")))
        out = IOS_ICONSET / image["filename"]
        render(full_icon(), pixels, out)
        Image.open(out).convert("RGB").save(out)  # App Store rejects icons with an alpha channel


def write_preview(out_dir):
    """Loose previews for eyeballing a change; not referenced by the app."""
    out_dir = Path(out_dir)
    render(full_icon(), 1024, out_dir / "full.png")
    render(legacy_icon(), 512, out_dir / "legacy.png")
    render(legacy_icon(dev=True), 512, out_dir / "legacy_dev.png")
    render(legacy_icon(), 48, out_dir / "legacy_48.png")
    render(svg(background() + adaptive_foreground()), 512, out_dir / "adaptive.png")
    render(svg(background() + adaptive_foreground(dev=True)), 512, out_dir / "adaptive_dev.png")
    tint = '<rect width="1024" height="1024" fill="#D7E8DF"/>'
    render(svg(tint + scaled(monochrome(), ADAPTIVE_SCALE)), 512, out_dir / "mono.png")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--preview":
        write_preview(sys.argv[2])
    else:
        write_android()
        write_ios()
        (ROOT / "tool/icon/icon.svg").write_text(full_icon())
        print("Launcher icons written.")
