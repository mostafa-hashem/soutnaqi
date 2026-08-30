"""Render SoutNaqi launcher/splash marks from the in-app logo geometry."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "brand"
BLUE = (37, 99, 235, 255)
WHITE = (255, 255, 255, 255)
SIZE = 1024


def wave_points(size: int, pad_ratio: float = 0.22) -> list[tuple[float, float]]:
    left = size * pad_ratio
    right = size * (1 - pad_ratio)
    mid_y = size * 0.5
    amplitude = size * 0.16
    steps = 96
    points: list[tuple[float, float]] = []
    for i in range(steps + 1):
        t = i / steps
        x = left + (right - left) * t
        y = mid_y - math.sin(t * 2 * math.pi) * amplitude
        points.append((x, y))
    return points


def draw_wave(draw: ImageDraw.ImageDraw, size: int, pad_ratio: float = 0.22) -> None:
    width = max(8, int(size * 0.08))
    draw.line(wave_points(size, pad_ratio), fill=WHITE, width=width, joint="curve")
    # Round caps: PIL line caps are limited; stamp circles at ends.
    pts = wave_points(size, pad_ratio)
    r = width / 2
    for x, y in (pts[0], pts[-1]):
        draw.ellipse((x - r, y - r, x + r, y + r), fill=WHITE)


def rounded_rect_mask(size: int, radius: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def export_full_icon(path: Path) -> None:
    scale = 4
    src = SIZE * scale
    img = Image.new("RGBA", (src, src), BLUE)
    draw = ImageDraw.Draw(img)
    draw_wave(draw, src)
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    img.save(path)


def export_foreground(path: Path) -> None:
    scale = 4
    src = SIZE * scale
    img = Image.new("RGBA", (src, src), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_wave(draw, src, pad_ratio=0.28)
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    img.save(path)


def export_splash_mark(path: Path) -> None:
    scale = 4
    src = SIZE * scale
    img = Image.new("RGBA", (src, src), BLUE)
    draw = ImageDraw.Draw(img)
    draw_wave(draw, src)
    radius = src * 0.22
    mask = rounded_rect_mask(src, radius)
    rounded = Image.new("RGBA", (src, src), (0, 0, 0, 0))
    rounded.paste(img, (0, 0), mask)
    rounded = rounded.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    rounded.save(path)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    export_full_icon(OUT / "app-icon.png")
    export_foreground(OUT / "app-icon-foreground.png")
    export_splash_mark(OUT / "splash-mark.png")
    print(f"Wrote icons in {OUT}")


if __name__ == "__main__":
    main()
