from kit import *
rng = np.random.default_rng(2)
N = 1024
W3 = World(N=N, hx=260, z0=2, z1=520)
X, Z = W3.XG, W3.ZG
xn, zn = X / 260, Z / 520
wind = fbm2(X * 0.012, Z * 0.012, 4, 11)
dune = np.zeros((N, N), np.float32)
for k, (fr, amp, ph) in enumerate([(7, 1.0, 0.0), (15, 0.35, 1.3), (31, 0.12, 2.1)]):
    wv = (xn * 0.6 + zn * 1.0) * fr + wind * 3.0 * (k + 1) + ph
    dune += amp * (1 - np.abs(np.sin(wv))) ** 1.6
heights = dune / 1.5 * 9 + fbm2(X * 0.01, Z * 0.01, 5, 5) * 22
m = fbm2(X * 0.008, Z * 0.008, 4, 9)
mesa = smoothstep(0.56, 0.62, m) * smoothstep(120, 330, Z)
heights = heights * (1 - mesa * 0.6) + mesa * (60 + fbm2(X * 0.1, Z * 0.1, 3, 4) * 16)
W3.H[:] = heights
n1 = fbm2(X * 0.05, Z * 0.05, 4, 8)
W3.ALB[:] = mix(rgb(0.95, 0.66, 0.32), rgb(1.0, 0.78, 0.42), n1[..., None])
W3.SIDE[:] = rgb(0.62, 0.30, 0.16)
# sandstone arch-like rock stacks
for _ in range(34):
    x, z = rng.uniform(-200, 200), rng.uniform(60, 330)
    r = rng.uniform(5, 12)
    W3.cyl(x, z, r, rng.uniform(18, 40), rgb(0.80, 0.46, 0.24), side=rgb(0.58, 0.28, 0.16), taper=0.15)
    W3.cyl(x + r * 0.7, z + 2, r * 0.6, rng.uniform(10, 26), rgb(0.84, 0.50, 0.26), side=rgb(0.6, 0.3, 0.18), taper=0.2)
T = W3.terrain(0.7)
sun_dir = (-0.30, 0.17, 0.94)
sun_col = rgb(1.0, 0.62, 0.30) * 1.5
skyf = with_clouds(sky_gradient((0.20, 0.17, 0.44), (0.82, 0.38, 0.36), (1.0, 0.72, 0.40), sun_dir, sun_col, 0.016, 0.9),
                   seed=7, tint=(1.0, 0.55, 0.45), scale=1.6, coverage=0.5, strength=0.5, stretch=2.5)
look = Look(sun_dir, sun_col, rgb(0.55, 0.38, 0.45), rgb(0.55, 0.30, 0.18), skyf, rgb(1.0, 0.70, 0.42), 0.0040)
dust = sparkle_cloud(rng, 220, (-60, 60), (2, 22), (20, 150), size=(0.15, 0.4), cols=((1.0, 0.8, 0.5),), alpha=(0.3, 0.7))
print(go(W3, look, (0, 30, -10), 0.14, 'w02.png', fov=1.2, particles=dust + (3.0,), rays=dict(strength=0.30, threshold=0.75, color=(1.0, 0.7, 0.4)), finish_kw=dict(sat=1.12)))
