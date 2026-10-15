import sys
import numpy as np
sys.path.insert(0, '/home/user/solitaire-app/tool/worldgen')
from engine import *

W, H = 540, 960
N = 1024
# dunes: ridged waves stretched along a wind direction + big mesas far away
x = np.linspace(-1, 1, N, dtype=np.float32)
X, Z = np.meshgrid(x, x)
wind = fbm_grid(N, 6, 4, 11)
dune = np.zeros((N, N), np.float32)
for k, (fr, amp, ph) in enumerate([(7, 1.0, 0.0), (15, 0.35, 1.3), (31, 0.12, 2.1)]):
    wv = (X * 0.6 + Z * 1.0) * fr + wind * 3.0 * (k + 1) + ph
    dune += amp * (1 - np.abs(np.sin(wv))) ** 1.6
dune = dune / 1.5
big = fbm_grid(N, 3, 5, 5)
heights = dune * 9 + big * 22
# distant mesas: plateaus with steep flanks
m = fbm_grid(N, 4, 4, 9)
mesa = smoothstep(0.58, 0.66, m) * smoothstep(0.35, 0.9, Z * 0.5 + 0.5)
heights = heights * (1 - mesa * 0.6) + mesa * 70
terrain = Terrain(heights, hx=260, z0=2, z1=520)

o, d = camera_rays(W, H, (0, 34, 0), pitch=-0.20, fov=1.15)
t, hit = march(terrain, o, d, steps=170, tmax=520)
p = o + d * t[..., None]
n = terrain.normal(p[..., 0], p[..., 2])
sun_dir = norm(np.array([-0.22, 0.20, 0.92], np.float32))
sun_col = np.array([1.0, 0.62, 0.30], np.float32)
top = np.array([0.20, 0.17, 0.42], np.float32)
mid = np.array([0.80, 0.38, 0.35], np.float32)
hor = np.array([1.0, 0.70, 0.40], np.float32)
col_sky = sky(d, sun_dir, top, mid, hor, sun_col, 0.03, 0.9)
cl = cloud_layer(d, 7, None, scale=1.6, coverage=0.50, soft=0.28, strength=0.55, stretch=2.5)
col_sky = col_sky + cl * np.array([1.0, 0.55, 0.45]) * (0.4 + 0.5 * np.clip((d * sun_dir).sum(-1), 0, 1))[..., None]

# sand shading: sun side vs shadow side, stylized colour ramp
ndl = np.clip((n * sun_dir).sum(-1), -1, 1)
light = smoothstep(-0.15, 0.6, ndl)
sand_lit = np.array([1.0, 0.72, 0.36], np.float32)
sand_mid = np.array([0.88, 0.48, 0.22], np.float32)
sand_shadow = np.array([0.38, 0.17, 0.26], np.float32)
col = np.where(light[..., None] > 0.5, mix(sand_mid, sand_lit, ((light - 0.5) * 2)[..., None]), mix(sand_shadow, sand_mid, (light * 2)[..., None]))
# rim glow on ridges
rim = np.clip(1 - n[..., 1], 0, 1) ** 2
col = col + np.array([1.0, 0.6, 0.3]) * (rim * light * 0.35)[..., None]
# mesa rock colour by height
hh = p[..., 1]
rock = mix(np.array([0.62, 0.28, 0.16], np.float32), np.array([0.85, 0.46, 0.24], np.float32), ((hh - 30) / 50).clip(0, 1)[..., None])
is_mesa = (hh > 28)[..., None]
col = np.where(is_mesa, rock * (0.35 + 0.8 * light[..., None]), col)
# fog toward the sun-lit horizon
dist = np.where(hit, t, 600.0)
fog = 1 - np.exp(-dist * 0.0042)
fogc = mix(hor * 0.95, mid, 0.25)
col = mix(col, fogc, fog[..., None])
img = np.where(hit[..., None], col, col_sky)
# god rays / dust: radial blur of the sun glow
img = img + sun_col * (np.clip((d * sun_dir).sum(-1), 0, 1) ** 24 * 0.25)[..., None]
out = finish(img, 1080, 1920, vignette=0.30, sat=1.10)
out.save('/tmp/claude-0/-home-user-solitaire-app/2159d7d9-0583-50a7-a346-78ef31ed353a/scratchpad/world_desert.png')
print('ok')
