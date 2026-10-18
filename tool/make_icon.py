#!/usr/bin/env python3
"""Turns store/logo-source.png into every Android launcher icon and the store icons.
   python3 tool/make_icon.py   (needs Pillow)"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = Image.open(os.path.join(root, 'store/logo-source.png')).convert('RGB')
S = 1024
full = src.resize((S, S), Image.LANCZOS)


def rounded(img, frac):
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=int(img.width * frac), fill=255)
    out = img.convert('RGBA')
    out.putalpha(m)
    return out


# adaptive icon layers (108dp, only the central 72dp is always visible):
# background = a heavily blurred copy of the logo, foreground = the sharp logo
# shrunk into the safe zone with softly faded edges so no seam shows.
bg = full.filter(ImageFilter.GaussianBlur(70)).resize((S, S))
shrink = 0.80
fg_size = int(S * shrink)
fg = full.resize((fg_size, fg_size), Image.LANCZOS).convert('RGBA')
feather = int(fg_size * 0.07)
mask = Image.new('L', (fg_size, fg_size), 0)
ImageDraw.Draw(mask).rectangle([feather, feather, fg_size - feather, fg_size - feather], fill=255)
mask = mask.filter(ImageFilter.GaussianBlur(feather / 2))
fg.putalpha(mask)
layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
layer.paste(fg, ((S - fg_size) // 2, (S - fg_size) // 2), fg)

res = os.path.join(root, 'android/app/src/main/res')
for name, legacy, adaptive in [('mdpi', 48, 108), ('hdpi', 72, 162), ('xhdpi', 96, 216), ('xxhdpi', 144, 324), ('xxxhdpi', 192, 432)]:
    d = os.path.join(res, f'mipmap-{name}')
    os.makedirs(d, exist_ok=True)
    rounded(full.resize((legacy, legacy), Image.LANCZOS), 0.22).save(os.path.join(d, 'ic_launcher.png'))
    bg.resize((adaptive, adaptive), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_background.png'))
    layer.resize((adaptive, adaptive), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'))
any_dir = os.path.join(res, 'mipmap-anydpi-v26')
os.makedirs(any_dir, exist_ok=True)
open(os.path.join(any_dir, 'ic_launcher.xml'), 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
full.resize((512, 512), Image.LANCZOS).save(os.path.join(root, 'store/icon-512.png'))
full.save(os.path.join(root, 'store/icon-1024.png'))
print('icons written')
