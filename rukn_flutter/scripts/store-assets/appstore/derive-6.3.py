"""Derive the iPhone 6.1"/6.3" set (1206x2622, required by App Store Connect) from the 6.9" set.

1320x2868 and 1206x2622 differ in aspect by under 0.1%, so a downscale plus a 1 px centre crop
is enough. usage (repo root): python3 rukn_flutter/scripts/store-assets/appstore/derive-6.3.py
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[4] / "store-assets" / "appstore"
W, H = 1206, 2622
for src_dir in sorted(ROOT.glob("*/iphone-6.9in-1320x2868")):
    out_dir = src_dir.parent / f"iphone-6.3in-{W}x{H}"
    out_dir.mkdir(exist_ok=True)
    for src in sorted(src_dir.glob("*.jpg")):
        im = Image.open(src).convert("RGB")
        sw = round(im.width * H / im.height)          # 1207
        im = im.resize((sw, H), Image.LANCZOS)
        left = (sw - W) // 2
        im = im.crop((left, 0, left + W, H))
        im.save(out_dir / src.name, "JPEG", quality=94, optimize=True)
        print(out_dir.relative_to(ROOT) / src.name, im.size)
