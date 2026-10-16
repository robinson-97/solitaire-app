from kit import *
rng = np.random.default_rng(10)
N = 1024
W3 = World(N=N, hx=240, z0=2, z1=460)
X, Z = W3.XG, W3.ZG
sx, WATER_Y, dist = valley(W3, hill=16, far_amp=46, river_w=18, bank=3.0, amp=16, seed=21)
pink = mix(rgb(1.0, 0.62, 0.78), rgb(1.0, 0.88, 0.93), fbm2(X * 0.05, Z * 0.05, 4, 4)[..., None])
W3.ALB[:] = mix(pink, rgb(0.70, 0.95, 0.82), (smoothstep(0.55, 0.65, fbm2(X * 0.03, Z * 0.03, 4, 9)) * 0.9)[..., None])
W3.SIDE[:] = rgb(0.95, 0.55, 0.70)
W3.ALB[:] = mix(W3.ALB, rgb(1.0, 0.92, 0.80), (smoothstep(6, 2.5, dist) * 0.9)[..., None])
gum = [rgb(1.0, 0.35, 0.55), rgb(0.35, 0.80, 1.0), rgb(1.0, 0.85, 0.30), rgb(0.60, 0.95, 0.45), rgb(0.80, 0.50, 1.0), rgb(1.0, 0.60, 0.25)]
ok_ = lambda x, z: abs(x - sx(z)) > 14
for (x, z, r) in sorted(scatter(rng, 160, (-220, 220), (16, 420), ok=ok_, min_gap=1.0, radius_fn=lambda x, z: 4 + z / 40), key=lambda t: -t[1]):
    c = gum[rng.integers(0, 6)]
    W3.dome(x, z, r, r * rng.uniform(0.7, 1.1), 0.0, c, side=c * 0.82)
# lollipops and candy canes
for (x, z, r) in sorted(scatter(rng, 90, (-200, 200), (30, 300), ok=ok_, min_gap=1.0, radius_fn=lambda x, z: 2.6 + z / 80), key=lambda t: -t[1]):
    c1, c2 = gum[rng.integers(0, 6)], rgb(1, 1, 1)
    h = r * rng.uniform(3.0, 5.0)
    W3.cyl(x, z, r * 0.16, h, rgb(0.98, 0.95, 0.92), side=rgb(0.9, 0.85, 0.85))
    sl = W3.window(x, z, r * 1.3)
    if sl is None:
        continue
    b = W3.ground(x, z) + h
    d = np.hypot(W3.XG[sl] - x, W3.ZG[sl] - z)
    ang = np.arctan2(W3.ZG[sl] - z, W3.XG[sl] - x)
    sw = (0.5 + 0.5 * np.sin(ang * 3 + d * 1.4)) > 0.5
    colr = np.where(sw[..., None], c1[None, None, :], c2[None, None, :])
    top = b + np.sqrt(np.maximum(1 - (d / (r * 1.1)) ** 2, 0)) * r * 1.1
    mask = d < r * 1.1
    up = mask & (top > W3.H[sl])
    W3.H[sl] = np.where(up, top, W3.H[sl])
    W3.ALB[sl] = np.where(up[..., None], colr, W3.ALB[sl])
    W3.SIDE[sl] = np.where(up[..., None], colr * 0.85, W3.SIDE[sl])
for (x, z, r) in sorted(scatter(rng, 70, (-200, 200), (40, 320), ok=ok_, min_gap=1.0, radius_fn=lambda x, z: 2.0 + z / 140), key=lambda t: -t[1]):
    h = rng.uniform(9, 20)
    W3.cyl(x, z, 1.0, h, rgb(1.0, 0.25, 0.30), side=rgb(0.95, 0.9, 0.92))
    W3.cyl(x + 1.8, z, 1.0, 2.6, rgb(1.0, 0.25, 0.30), side=rgb(0.95, 0.9, 0.92), base=W3.ground(x, z) + h - 2)
T = W3.terrain(0.7)
sun_dir = (-0.35, 0.50, 0.80)
sun_col = rgb(1.0, 0.92, 0.85) * 1.45
skyf = with_clouds(sky_gradient((0.62, 0.55, 0.92), (0.95, 0.72, 0.92), (1.0, 0.90, 0.95), sun_dir, sun_col, 0.02, 0.5), seed=15, tint=(1.0, 0.85, 0.95), scale=0.9, coverage=0.45, soft=0.25, strength=0.9)
look = Look(sun_dir, sun_col, rgb(0.85, 0.72, 0.95), rgb(0.75, 0.50, 0.65), skyf, rgb(1.0, 0.82, 0.92), 0.0030)
sparkles = sparkle_cloud(rng, 260, (-60, 60), (4, 40), (20, 170), size=(0.15, 0.4), cols=((1, 1, 1), (1, 0.8, 0.95), (0.8, 0.95, 1)), alpha=(0.5, 1.0))
print(go(W3, look, (0, 48, -12), 0.36, 'w10.png', fov=1.2, water=dict(y=WATER_Y, shallow=rgb(1.0, 0.55, 0.70), deep=rgb(0.85, 0.18, 0.40), clarity=0.12, ripple=0.04, reflect=0.9, glitter=2.0), particles=sparkles + (4.0,), rays=dict(strength=0.15, threshold=0.85), finish_kw=dict(sat=1.1)))
