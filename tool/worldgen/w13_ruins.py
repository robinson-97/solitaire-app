from kit import *
rng = np.random.default_rng(13)
N = 1024
W3 = World(N=N, hx=240, z0=2, z1=480)
X, Z = W3.XG, W3.ZG
W3.H[:] = fbm2(X * 0.014, Z * 0.014, 5, 3) * 14 + smoothstep(260, 470, Z) * 60 * fbm2(X * 0.01, Z * 0.01, 4, 6) + fbm2(X * 0.1, Z * 0.1, 3, 2) * 1.2
terr = rgb(0.55, 0.60, 0.36)
W3.ALB[:] = mix(terr, rgb(0.72, 0.68, 0.52), fbm2(X * 0.05, Z * 0.05, 4, 7)[..., None])
W3.SIDE[:] = rgb(0.52, 0.50, 0.44)
stone = rgb(0.78, 0.74, 0.62)
dark = rgb(0.46, 0.46, 0.40)
# central plaza with pillars in rows
for row, zrow in enumerate(np.arange(60, 330, 30)):
    for xcol in np.arange(-110, 111, 28):
        if rng.random() < 0.18:
            continue
        h = rng.uniform(16, 36) * (0.5 if rng.random() < 0.25 else 1.0)
        r = rng.uniform(1.8, 2.6)
        x = xcol + rng.uniform(-2, 2)
        W3.cyl(x, zrow, r, h, stone, side=dark, taper=0.0)
        W3.cyl(x, zrow, r * 1.35, 3.0, stone * 0.92, side=dark)
        if rng.random() < 0.5:
            W3.box(x, zrow, r * 3.0, r * 3.0, 3.5, stone, side=dark, base=W3.ground(x, zrow) + h)
# broken walls and steps
for _ in range(34):
    x, z = rng.uniform(-170, 170), rng.uniform(40, 360)
    W3.box(x, z, rng.uniform(10, 26), rng.uniform(3, 6), rng.uniform(5, 18), stone * 0.95, side=dark, rot=rng.uniform(0, 3.14))
for k in range(9):
    W3.box(0, 250 + k * 5, 90, 5.2, 3 + k * 3.2, stone, side=dark, base=0)
W3.box(0, 300, 120, 60, 40, stone, side=dark, base=0)
for (x, z, r) in scatter(rng, 400, (-230, 230), (20, 440), radius_fn=lambda x, z: 2.0 + z / 120, min_gap=0.9):
    W3.dome(x, z, r, r * 0.9, r * 0.2, rgb(0.15, 0.50, 0.16), side=rgb(0.08, 0.30, 0.10))
# moss on stone
mm = (W3.H > 4) & (fbm2(X * 0.5, Z * 0.5, 4, 8) > 0.58)
W3.ALB[:] = np.where(mm[..., None], mix(W3.ALB, rgb(0.20, 0.52, 0.18), 0.7), W3.ALB)
T = W3.terrain(0.5)
sun_dir = (-0.45, 0.45, 0.77)
sun_col = rgb(1.0, 0.85, 0.55) * 1.7
skyf = with_clouds(sky_gradient((0.42, 0.62, 0.86), (0.80, 0.86, 0.90), (1.0, 0.92, 0.72), sun_dir, sun_col, 0.016, 0.6), seed=23, strength=0.4)
look = Look(sun_dir, sun_col, rgb(0.52, 0.64, 0.78), rgb(0.38, 0.38, 0.28), skyf, rgb(0.88, 0.86, 0.74), 0.0046)
dust = sparkle_cloud(rng, 300, (-70, 70), (3, 40), (20, 200), size=(0.15, 0.4), cols=((1.0, 0.95, 0.7),), alpha=(0.3, 0.8))
print(go(W3, look, (0, 64, -14), 0.50, 'w13.png', fov=1.2, particles=dust + (3.5,), rays=dict(strength=0.55, threshold=0.7, color=(1.0, 0.9, 0.6), samples=56), finish_kw=dict(sat=1.1)))
