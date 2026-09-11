#!/usr/bin/env python3
"""
Icon set. Raster work (alpha flattening, the adaptive-icon trio, the launcher
legibility check) is Pillow's job, not the browser's.

Writes the Play listing icon plus the in-binary assets, so the AAB and the store
page always carry the same mark — docs/PUBLISHING.md §1.3.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
MARK_SRC = Path("/root/rukn-site/public/logo-sq.png")
DARK = (7, 53, 43)

# The mark fills this share of the icon. 0.78 keeps the hexagon readable when a
# launcher shrinks it to 48 px; smaller and the inner "M" turns to mush.
MARK_SHARE = 0.78
# Android crops an adaptive foreground to the inner circle, so keep it smaller.
ADAPTIVE_SHARE = 0.62


def _mark() -> Image.Image:
    """The brand mark, cropped to its ink so scaling is predictable."""
    im = Image.open(MARK_SRC).convert("RGBA")
    return im.crop(im.getbbox())


def _place(mark: Image.Image, size: int, share: float, background) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), background)
    w = int(size * share)
    h = round(mark.height * w / mark.width)
    canvas.alpha_composite(mark.resize((w, h), Image.LANCZOS), ((size - w) // 2, (size - h) // 2))
    return canvas


def play_icon(size: int) -> Image.Image:
    """Full-bleed store icon. RGB — Play rejects an icon with an alpha channel."""
    return _place(_mark(), size, MARK_SHARE, (*DARK, 255)).convert("RGB")


def adaptive_foreground(size: int = 1024) -> Image.Image:
    return _place(_mark(), size, ADAPTIVE_SHARE, (0, 0, 0, 0))


def adaptive_background(size: int = 1024) -> Image.Image:
    return Image.new("RGBA", (size, size), (*DARK, 255))


def adaptive_monochrome(size: int = 1024) -> Image.Image:
    """Themed-icon layer: a white silhouette on transparent."""
    fg = adaptive_foreground(size)
    white = Image.new("RGBA", fg.size, (255, 255, 255, 0))
    white.putalpha(fg.getchannel("A"))
    return white


def legibility_strip(icon: Image.Image, path: Path) -> None:
    """Contact sheet at launcher sizes, so the check is a look, not a guess."""
    sizes = [48, 72, 96, 128, 192]
    pad, gap = 24, 20
    w = pad * 2 + sum(sizes) + gap * (len(sizes) - 1)
    sheet = Image.new("RGB", (w, max(sizes) + pad * 2), (245, 245, 245))
    x = pad
    for s in sizes:
        sheet.paste(icon.resize((s, s), Image.LANCZOS), (x, pad + (max(sizes) - s) // 2))
        x += s + gap
    sheet.save(path)


def main(out_dir: str) -> None:
    out = Path(out_dir)
    (out / "icon").mkdir(parents=True, exist_ok=True)

    icon512 = play_icon(512)
    icon1024 = play_icon(1024)
    icon512.save(out / "icon" / "app-icon-512.png", "PNG", optimize=True)
    icon1024.save(out / "icon" / "app-icon-1024.png", "PNG", optimize=True)
    legibility_strip(icon512, out / "icon" / "app-icon-launcher-sizes.png")

    images = REPO / "assets" / "images"
    icon1024.save(images / "icon.png", "PNG", optimize=True)
    icon1024.save(images / "splash-icon.png", "PNG", optimize=True)
    play_icon(256).save(images / "favicon.png", "PNG", optimize=True)
    adaptive_foreground().save(images / "android-icon-foreground.png", "PNG", optimize=True)
    adaptive_background().save(images / "android-icon-background.png", "PNG", optimize=True)
    adaptive_monochrome().save(images / "android-icon-monochrome.png", "PNG", optimize=True)

    print(f"  icon/app-icon-512.png            512x512 RGB  {(out / 'icon' / 'app-icon-512.png').stat().st_size // 1024} KB")
    print(f"  icon/app-icon-1024.png           1024x1024 RGB")
    print(f"  icon/app-icon-launcher-sizes.png legibility contact sheet")
    print(f"  assets/images/*.png              in-binary icon set refreshed")


if __name__ == "__main__":
    main(sys.argv[1])
