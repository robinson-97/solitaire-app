#!/usr/bin/env python3
"""Sanity checks on rendered scene frames (see scene_shots_test.dart).

  python3 tool/shots/check_scenes.py DIR forest desert ...
Needs frames rendered with --dart-define=US=0,0.125,0.375,0.625,0.875,0.99999
  * gaps:  any transparent pixel means a layer shows its edge when it drifts
  * loop:  frame u=0 and u=0.99999 must look (almost) the same
"""
import sys
import numpy as np
from PIL import Image

d = sys.argv[1]
ids = sys.argv[2:]
for i in ids:
    bad = []
    for u in ['0', '0.125', '0.375', '0.625', '0.875', '0.99999']:
        try:
            im = Image.open(f'{d}/{i}_u{u}.png').convert('RGBA')
        except FileNotFoundError:
            bad.append(f'missing u{u}')
            continue
        lo = int((np.asarray(im)[:, :, 3] < 250).sum())
        if lo:
            bad.append(f'u{u}: {lo} transparent px')
    try:
        a = np.asarray(Image.open(f'{d}/{i}_u0.png').convert('RGB')).astype(int)
        b = np.asarray(Image.open(f'{d}/{i}_u0.99999.png').convert('RGB')).astype(int)
        diff = np.abs(a - b).max(axis=2)
        mean = float(diff.mean())
        mx = int(diff.max())
        loop = f'loop diff mean {mean:.3f} max {mx}'
        if mean > 0.6:
            bad.append(loop)
    except FileNotFoundError:
        loop = 'loop n/a'
    print(f'{i}: {"OK" if not bad else "; ".join(bad)}  ({loop})')
