from kit import *
rng = np.random.default_rng(7)
N = 1024
W3 = World(N=N, hx=220, z0=2, z1=480)
X, Z = W3.XG, W3.ZG
river_x = 24 * np.sin(Z * 0.02) - 40
dist = np.abs(X - river_x)
hills = fbm2(X * 0.012, Z * 0.012, 5, 7) * 20 + fbm2(X * 0.06, Z * 0.06, 3, 9) * 2
far = smoothstep(260, 470, Z) * 50 * fbm2(X * 0.01, Z * 0.01, 4, 3)
valley = np.exp(-(dist / 22.0) ** 2)
H0 = hills * (1 - 0.7 * valley) + far - smoothstep(8, 2, dist) * 3.5
W3.H[:] = H0
WATER_Y = float(np.percentile(H0[(dist < 3) & (Z > 8) & (Z < 200)], 60)) + 0.2
n1 = fbm2(X * 0.08, Z * 0.08, 4, 5)
W3.ALB[:] = mix(rgb(0.06, 0.30, 0.12), rgb(0.20, 0.50, 0.16), n1[..., None])
W3.SIDE[:] = rgb(0.22, 0.18, 0.12)
# stepped temple
tx, tz = 40.0, 190.0
stone = rgb(0.52, 0.55, 0.45)
side = rgb(0.34, 0.37, 0.30)
base = W3.ground(tx, tz)
for k, (w, h) in enumerate([(78, 9), (64, 9), (50, 9), (36, 9), (22, 9)]):
    W3.box(tx, tz, w, w, h * (k + 1), stone * (1 - 0.04 * k), side=side, base=base)
W3.box(tx, tz, 12, 12, 62, stone * 1.05, side=side, base=base)
W3.box(tx, tz - 38, 14, 36, 10, stone * 0.95, side=side, base=base)   # stairs ramp
leafs = [rgb(0.10, 0.50, 0.16), rgb(0.18, 0.62, 0.22), rgb(0.07, 0.38, 0.18), rgb(0.30, 0.68, 0.18)]
Hb = W3.H.copy()
for (x, z, r) in scatter(rng, 3200, (-200, 200), (10, 460), ok=lambda x, z: not (abs(x - (24 * np.sin(z * 0.02) - 40)) < 14) and not (abs(x - tx) < 52 and abs(z - tz) < 52), min_gap=0.8, radius_fn=lambda x, z: 4 + z / 55):
    k = rng.integers(0, 4)
    W3.dome(x, z, r, r * rng.uniform(0.9, 1.5), lift=r * 0.9, col=leafs[k], side=leafs[k] * 0.5)
lm = W3.H > Hb + 0.5
W3.H[:] = W3.H + lm * ((noise2(X * 1.5, Z * 1.5, 31) - 0.5) * 1.6 + (noise2(X * 0.5, Z * 0.5, 32) - 0.5) * 1.5)
W3.ALB[:] = np.where(lm[..., None], W3.ALB * (0.7 + 0.6 * noise2(X * 2.2, Z * 2.2, 33))[..., None], W3.ALB)
# vines of moss on the temple
mt = (np.abs(X - tx) < 44) & (np.abs(Z - tz) < 44) & (W3.H > base + 2)
W3.ALB[:] = np.where(mt[..., None], mix(W3.ALB, rgb(0.20, 0.45, 0.18), (smoothstep(0.55, 0.75, fbm2(X * 0.4, Z * 0.4, 4, 3)) * 0.8)[..., None]), W3.ALB)
T = W3.terrain(0.7)
sun_dir = (-0.30, 0.55, 0.78)
sun_col = rgb(1.0, 0.88, 0.58) * 1.5
skyf = with_clouds(sky_gradient((0.24, 0.55, 0.78), (0.58, 0.82, 0.78), (0.95, 0.95, 0.72), sun_dir, sun_col, 0.016, 0.5), seed=11, strength=0.25)
look = Look(sun_dir, sun_col, rgb(0.35, 0.58, 0.55), rgb(0.12, 0.30, 0.15), skyf, rgb(0.52, 0.80, 0.66), 0.0058)
motes = sparkle_cloud(rng, 280, (-60, 60), (8, 46), (20, 160), size=(0.15, 0.4), cols=((1.0, 0.92, 0.55), (0.8, 1.0, 0.7)), alpha=(0.4, 1.0))
print(go(W3, look, (0, 56, -12), 0.50, 'w07.png', fov=1.15, water=dict(y=WATER_Y, shallow=rgb(0.4, 0.9, 0.8), deep=rgb(0.03, 0.30, 0.32), clarity=0.25, ripple=0.05, reflect=1.0), particles=motes + (4.0,), rays=dict(strength=0.30, threshold=0.78, color=(1.0, 0.9, 0.6))))
