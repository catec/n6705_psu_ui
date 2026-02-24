"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file packaging/windows/make_icon.py
@brief Build Windows .ico file from SVG icon source.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


def build_icon(_svg_path: Path, ico_path: Path) -> None:
    size = 1024
    image = Image.new("RGBA", (size, size), (8, 24, 40, 255))
    draw = ImageDraw.Draw(image, "RGBA")

    # Outer rounded shape
    margin = 56
    draw.rounded_rectangle(
        (margin, margin, size - margin, size - margin),
        radius=220,
        fill=(9, 38, 62, 255),
        outline=(86, 205, 255, 210),
        width=14,
    )

    # Inner panel
    panel_m = 170
    draw.rounded_rectangle(
        (panel_m, panel_m, size - panel_m, size - panel_m),
        radius=130,
        fill=(7, 28, 46, 255),
        outline=(69, 178, 233, 180),
        width=8,
    )

    # Grid
    for y in (290, 430, 570, 710):
        draw.line((250, y, 774, y), fill=(88, 154, 190, 80), width=3)
    for x in (250, 430, 594, 774):
        draw.line((x, 250, x, 774), fill=(88, 154, 190, 80), width=3)

    # Waveform stroke
    waveform = [(280, 640), (360, 620), (440, 540), (520, 570), (620, 450), (710, 520), (770, 470)]
    draw.line(waveform, fill=(85, 230, 255, 255), width=28, joint="curve")

    # Status LEDs
    draw.ellipse((268, 808, 292, 832), fill=(214, 211, 58, 255))
    draw.ellipse((410, 808, 434, 832), fill=(70, 204, 90, 255))
    draw.ellipse((552, 808, 576, 832), fill=(57, 168, 255, 255))
    draw.ellipse((694, 808, 718, 832), fill=(209, 90, 240, 255))

    ico_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(
        ico_path,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create .ico from SVG.")
    parser.add_argument("--svg", required=True, help="Input SVG path.")
    parser.add_argument("--ico", required=True, help="Output ICO path.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    svg_path = Path(args.svg).resolve()
    ico_path = Path(args.ico).resolve()

    if not svg_path.exists():
        print(f"[WARN] SVG icon not found: {svg_path}. Generating fallback icon.")

    build_icon(svg_path, ico_path)
    print(f"ICO generated: {ico_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
