#!/usr/bin/env python3
"""Draws the Hopstone app icon and writes every Android launcher size.
   python3 tool/make_icon.py   (needs Pillow + numpy)"""
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # work size; everything is designed on a 1024 grid then scaled x2
K = S / 1024


def px(v):
    return v * K


def radial(size, center, radius, stops):
    """Float RGBA image with a radial gradient. stops: [(t, (r,g,b,a)), ...]"""
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    d = np.sqrt((xx - center[0]) ** 2 + (yy - center[1]) ** 2) / radius
    out = np.zeros((size, size, 4), np.float32)
    ts = [t for t, _ in stops]
    for ch in range(4):
        out[..., ch] = np.interp(d, ts, [c[ch] for _, c in stops])
    return out


def to_img(a):
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


def glow(layer_fn, blur):
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    layer_fn(ImageDraw.Draw(img))
    return img.filter(ImageFilter.GaussianBlur(blur * K))


def background():
    base = radial(S, (px(512), px(470)), px(760), [(0, (46, 62, 150, 255)), (0.55, (20, 26, 78, 255)), (1, (6, 8, 28, 255))])
    # soft magenta glow bottom right, cyan top left
    base2 = to_img(base)
    mg = radial(S, (px(900), px(960)), px(560), [(0, (255, 61, 180, 90)), (1, (255, 61, 180, 0))])
    cy = radial(S, (px(120), px(80)), px(520), [(0, (53, 240, 255, 70)), (1, (53, 240, 255, 0))])
    base2 = Image.alpha_composite(base2, to_img(mg))
    base2 = Image.alpha_composite(base2, to_img(cy))
    return base2


def sphere(cx, cy, r, light, mid, dark):
    """Glossy lit sphere, lit from the upper left, like the pegs in the game."""
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    nx = (xx - cx) / r
    ny = (yy - cy) / r
    d2 = nx ** 2 + ny ** 2
    inside = d2 <= 1
    nz = np.sqrt(np.clip(1 - d2, 0, 1))
    # light direction
    L = np.array([-0.5, -0.65, 0.58]); L = L / np.linalg.norm(L)
    diff = np.clip(nx * L[0] + ny * L[1] + nz * L[2], 0, 1)
    t = np.clip(1 - diff, 0, 1)
    col = np.zeros((S, S, 3), np.float32)
    for ch in range(3):
        col[..., ch] = np.where(t < 0.5, light[ch] + (mid[ch] - light[ch]) * (t / 0.5), mid[ch] + (dark[ch] - mid[ch]) * ((t - 0.5) / 0.5))
    # rim darkening + specular
    rim = np.clip(1 - nz, 0, 1) ** 2.2
    col *= (1 - 0.35 * rim)[..., None]
    hx, hy = nx + 0.38, ny + 0.45
    spec = np.exp(-(hx ** 2 + hy ** 2) / 0.018)
    spec2 = np.exp(-((nx - 0.45) ** 2 + (ny - 0.5) ** 2) / 0.05) * 0.25
    col += (spec * 255 * 0.95 + spec2 * 255)[..., None] * np.array([1.0, 0.97, 0.9])
    # soft bounce light at the bottom
    bounce = np.exp(-((nx + 0.1) ** 2 + (ny - 0.85) ** 2) / 0.12) * 0.25
    col += (bounce * 255)[..., None] * np.array([0.3, 0.8, 1.0])
    alpha = np.clip((1 - np.sqrt(d2)) * r / 1.6, 0, 1) * 255
    img = np.dstack([col, alpha])
    img[~inside] = 0
    return to_img(img)


def hole(cx, cy, r, rim=None):
    layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - r * 1.22, cy - r * 1.22, cx + r * 1.22, cy + r * 1.22], fill=(14, 20, 62, 255))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(3, 5, 20, 255))
    inner = radial(S, (cx, cy - r * 0.25), r * 1.1, [(0, (22, 30, 96, 255)), (1, (2, 3, 14, 255))])
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).ellipse([cx - r * 0.93, cy - r * 0.93, cx + r * 0.93, cy + r * 0.93], fill=255)
    layer.paste(to_img(inner), (0, 0), mask)
    if rim:
        g = glow(lambda dd: dd.ellipse([cx - r * 1.1, cy - r * 1.1, cx + r * 1.1, cy + r * 1.1], outline=rim + (255,), width=int(px(14))), 16)
        layer = Image.alpha_composite(layer, g)
        ImageDraw.Draw(layer).ellipse([cx - r * 1.1, cy - r * 1.1, cx + r * 1.1, cy + r * 1.1], outline=rim + (255,), width=int(px(7)))
    return layer


def foreground():
    f = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    hy = px(740)
    lx, mx, rx = px(284), px(512), px(740)
    hr = px(74)
    f = Image.alpha_composite(f, hole(lx, hy, hr))
    f = Image.alpha_composite(f, hole(mx, hy, hr))
    f = Image.alpha_composite(f, hole(rx, hy, hr, rim=(53, 240, 255)))
    # the peg that gets jumped: small, cool, sitting in its hole
    f = Image.alpha_composite(f, sphere(mx, hy - px(6), px(54), (205, 228, 255), (110, 150, 235), (40, 60, 150)))
    # hop arc from the left hole, over the middle peg, to the glowing target
    pts = []
    for i in range(0, 121):
        t = i / 120
        pts.append((lx + (rx - lx) * t, hy - px(40) - 4 * px(450) * t * (1 - t)))
    def arc(dd, w, col):
        dd.line(pts, fill=col, width=int(px(w)), joint='curve')
    f = Image.alpha_composite(f, glow(lambda dd: arc(dd, 30, (53, 240, 255, 255)), 22))
    layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    arc(ImageDraw.Draw(layer), 14, (170, 248, 255, 255))
    f = Image.alpha_composite(f, layer)
    # hero peg at the top of the hop
    pcx, pcy, pr = px(512), px(395), px(170)
    halo = radial(S, (pcx, pcy), pr * 2.2, [(0, (255, 190, 90, 130)), (0.5, (255, 140, 60, 45)), (1, (255, 140, 60, 0))])
    f = Image.alpha_composite(f, to_img(halo))
    f = Image.alpha_composite(f, sphere(pcx, pcy, pr, (255, 238, 180), (236, 154, 58), (118, 54, 14)))
    return f


def fit(img, size):
    return img.resize((size, size), Image.LANCZOS)


def rounded(img, radius_frac):
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=int(img.width * radius_frac), fill=255)
    out = img.copy()
    out.putalpha(m)
    return out


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    bg, fg = background(), foreground()
    full = Image.alpha_composite(bg, fg)
    res = os.path.join(root, 'android/app/src/main/res')
    os.makedirs(os.path.join(root, 'store'), exist_ok=True)
    fit(full, 512).save(os.path.join(root, 'store/icon-512.png'))
    fit(full, 1024).save(os.path.join(root, 'store/icon-1024.png'))
    # legacy launcher icons (rounded square)
    for name, px_size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        d = os.path.join(res, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        rounded(fit(full, px_size), 0.22).save(os.path.join(d, 'ic_launcher.png'))
        # adaptive layers are 108dp; content stays inside the central 66%
        a = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}[name]
        fit(bg, a).convert('RGB').save(os.path.join(d, 'ic_launcher_background.png'))
        # the art is drawn on a 1024 grid filling ~70%; shrink slightly into the safe area
        canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        scaled = fg.resize((int(S * 0.72), int(S * 0.72)), Image.LANCZOS)
        canvas.paste(scaled, ((S - scaled.width) // 2, (S - scaled.height) // 2 - int(S * 0.01)), scaled)
        fit(canvas, a).save(os.path.join(d, 'ic_launcher_foreground.png'))
    any_dir = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(any_dir, exist_ok=True)
    open(os.path.join(any_dir, 'ic_launcher.xml'), 'w').write(
        '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
    print('icons written')


if __name__ == '__main__':
    main()
