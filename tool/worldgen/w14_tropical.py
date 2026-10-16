from kit import *
rng = np.random.default_rng(14)
N = 1024
W3 = World(N=N, hx=300, z0=2, z1=560)
X, Z = W3.XG, W3.ZG
isl = np.zeros((N, N), np.float32)
for (cx, cz, r, h) in [(0, 150, 95, 12), (-170, 280, 55, 8), (160, 330, 70, 10), (30, 460, 45, 6), (-120, 90, 22, 4)]:
    d = np.hypot(X - cx, (Z - cz) * 1.0)
    isl = np.maximum(isl, np.clip(1 - d / r, 0, 1) ** 0.7 * h)
W3.H[:] = -9 + isl * 1.6 + fbm2(X * 0.05, Z * 0.05, 4, 6) * 2 * (isl > 0.5) + fbm2(X * 0.02, Z * 0.02, 4, 8) * 3
sand = rgb(0.98, 0.90, 0.70)
grass = rgb(0.18, 0.62, 0.20)
land = smoothstep(-1.0, 1.8, W3.H)
inner = smoothstep(2.0, 6.0, W3.H)
W3.ALB[:] = mix(sand, mix(grass, rgb(0.30, 0.74, 0.22), fbm2(X * 0.06, Z * 0.06, 3, 9)[..., None]), inner[..., None])
W3.SIDE[:] = rgb(0.50, 0.42, 0.32)
# palms
for (x, z, r) in sorted(scatter(rng, 90, (-150, 150), (50, 400), ok=lambda x, z: 2.5 < W3.ground(x, z) < 16, radius_fn=lambda x, z: 2.0 + z / 90, min_gap=1.6), key=lambda t: -t[1]):
    h = r * rng.uniform(3.2, 4.4)
    b = W3.ground(x, z)
    W3.cyl(x, z, r * 0.18, h, rgb(0.52, 0.36, 0.20), side=rgb(0.42, 0.30, 0.18))
    sl = W3.window(x, z, r * 1.5)
    if sl is None:
        continue
    d = np.hypot(W3.XG[sl] - x, W3.ZG[sl] - z)
    ang = np.arctan2(W3.ZG[sl] - z, W3.XG[sl] - x)
    star = d < r * 1.7 * (0.30 + 0.70 * np.abs(np.cos(ang * 3.0)) ** 2)
    top = b + h + 1.0 - (d / (r * 1.5)) * 1.8
    up = star & (top > W3.H[sl])
    W3.H[sl] = np.where(up, top, W3.H[sl])
    W3.ALB[sl] = np.where(up[..., None], rgb(0.14, 0.60, 0.18), W3.ALB[sl])
    W3.SIDE[sl] = np.where(up[..., None], rgb(0.08, 0.40, 0.14), W3.SIDE[sl])
for (x, z, r) in scatter(rng, 90, (-150, 150), (50, 400), ok=lambda x, z: 1.6 < W3.ground(x, z) < 5, radius_fn=lambda x, z: 1.5, min_gap=0.8):
    W3.blob(x, z, rng.uniform(1.2, 2.5), rng.uniform(0.8, 1.8), rgb(0.55, 0.55, 0.52), side=rgb(0.4, 0.4, 0.4), seed=int(x))
T = W3.terrain(0.6)
sun_dir = (-0.30, 0.78, 0.55)
sun_col = rgb(1.0, 0.95, 0.80) * 1.6
skyf = with_clouds(sky_gradient((0.12, 0.45, 0.92), (0.42, 0.74, 0.98), (0.80, 0.94, 1.0), sun_dir, sun_col, 0.018, 0.5), seed=27, scale=1.0, coverage=0.5, soft=0.22, strength=0.9)
look = Look(sun_dir, sun_col, rgb(0.50, 0.72, 0.95), rgb(0.55, 0.70, 0.55), skyf, rgb(0.70, 0.92, 1.0), 0.0020)
print(go(W3, look, (0, 62, -18), 0.40, 'w14.png', fov=1.2, water=dict(y=0.0, shallow=rgb(0.75, 1.0, 0.95), deep=rgb(0.0, 0.32, 0.60), clarity=0.30, ripple=0.03, reflect=0.9, glitter=3.0), rays=dict(strength=0.10, threshold=0.85), finish_kw=dict(sat=1.2)))
