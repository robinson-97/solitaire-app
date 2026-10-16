from kit import *
rng = np.random.default_rng(6)
N = 1024
W3 = World(N=N, hx=300, z0=2, z1=560)
X, Z = W3.XG, W3.ZG
cz = 300.0
r = np.hypot(X, (Z - cz) * 0.9)
rough = fbm2(X * 0.04, Z * 0.04, 5, 3)
cone = np.clip(150 - r * 0.78, 0, None) * (0.85 + 0.3 * rough)
crater = np.clip((26 - r) / 26, 0, 1)
cone = cone - crater * 46
base = fbm2(X * 0.02, Z * 0.02, 5, 8) * 16 + fbm2(X * 0.1, Z * 0.1, 3, 4) * 3
far = smoothstep(380, 560, Z) * 60 * fbm2(X * 0.01, Z * 0.01, 4, 9)
H0 = base + cone + far
W3.H[:] = H0
rock = mix(rgb(0.10, 0.08, 0.09), rgb(0.24, 0.17, 0.15), fbm2(X * 0.08, Z * 0.08, 4, 5)[..., None])
W3.ALB[:] = rock
W3.SIDE[:] = rgb(0.08, 0.06, 0.07)
# lava rivers running down the front of the cone
LAVA = np.zeros((N, N), np.float32)
for k in range(7):
    th = (k - 3) * 0.28 + rng.uniform(-0.1, 0.1)
    for rr in np.linspace(14, 230, 600):
        wig = 0.12 * np.sin(rr * 0.07 + k * 2.1)
        x = rr * np.sin(th + wig)
        z = cz - rr * np.cos(th + wig) / 0.9
        ix, iz = W3.idx(x, z)
        w = max(2.2 - rr / 160, 0.8)
        sl = W3.window(x, z, w + 1)
        if sl is None:
            continue
        d = np.hypot(W3.XG[sl] - x, W3.ZG[sl] - z)
        LAVA[sl] = np.maximum(LAVA[sl], smoothstep(w + 0.8, w * 0.4, d))
W3.H -= LAVA * 1.8
W3.EMI[:] = rgb(1.0, 0.42, 0.06)[None, None, :] * (LAVA[..., None] ** 1.2) * 2.2
W3.ALB[:] = mix(W3.ALB, rgb(1.0, 0.5, 0.1), (LAVA * 0.9)[..., None])
cr = (np.hypot(X, Z - cz) < 24)
W3.EMI[cr] = rgb(1.0, 0.45, 0.08) * 2.4 * (0.7 + 0.5 * fbm2(X * 0.3, Z * 0.3, 3, 2)[cr][..., None])
T = W3.terrain(0.7)
sun_dir = (0.2, 0.25, 0.95)
sun_col = rgb(1.0, 0.45, 0.22) * 0.9
skyf = with_clouds(sky_gradient((0.12, 0.04, 0.07), (0.50, 0.12, 0.08), (1.0, 0.45, 0.14), sun_dir, sun_col, 0.012, 0.5),
                   seed=14, tint=(0.35, 0.16, 0.12), scale=1.1, coverage=0.40, soft=0.35, strength=0.95, stretch=1.5)
look = Look(sun_dir, sun_col, rgb(0.35, 0.14, 0.10), rgb(0.40, 0.12, 0.04), skyf, rgb(0.55, 0.16, 0.06), 0.0045)
embers = sparkle_cloud(rng, 520, (-110, 110), (2, 95), (25, 330), size=(0.18, 0.5), cols=((1.0, 0.55, 0.15), (1.0, 0.75, 0.3)), alpha=(0.5, 1.0))
print(go(W3, look, (0, 34, -12), 0.04, 'w06.png', fov=1.2, particles=embers + (3.5,), rays=dict(strength=0.30, threshold=0.7, color=(1.0, 0.45, 0.2)), finish_kw=dict(sat=1.12, vignette=0.38)))
