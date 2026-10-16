from kit import *
rng = np.random.default_rng(17)
N = 1024
W3 = World(N=N, hx=200, z0=2, z1=420)
X, Z = W3.XG, W3.ZG
basin = smoothstep(110, 25, np.hypot(X * 0.9, (Z - 140)))
W3.H[:] = fbm2(X * 0.02, Z * 0.02, 5, 3) * 18 * (1 - basin * 0.9) + smoothstep(200, 380, Z) * 50 * fbm2(X * 0.02, Z * 0.02, 4, 5) + fbm2(X * 0.1, Z * 0.1, 3, 7) * 1.4 - basin * 3
WATER_Y = 0.5
W3.ALB[:] = mix(rgb(0.30, 0.18, 0.08), rgb(0.50, 0.30, 0.12), fbm2(X * 0.05, Z * 0.05, 4, 4)[..., None])
W3.SIDE[:] = rgb(0.22, 0.12, 0.06)
gold = rgb(1.0, 0.72, 0.18)
for (x, z, r) in sorted(scatter(rng, 110, (-170, 170), (16, 320), ok=lambda x, z: W3.ground(x, z) > WATER_Y + 0.5, radius_fn=lambda x, z: 3.0 + z / 55, min_gap=0.7), key=lambda t: -t[1]):
    k = rng.integers(0, 3)
    if k == 0:
        W3.blob(x, z, r * 1.3, r * 0.95, gold, side=gold * 0.7, noise=0.55, seed=int(x * 3 + z), emi=gold * 0.35)
    else:
        c = [rgb(1.0, 0.62, 0.15), rgb(1.0, 0.82, 0.30)][k - 1]
        for j in range(rng.integers(2, 5)):
            a = rng.uniform(0, 6.28)
            d = rng.uniform(0, r)
            W3.cone(x + np.cos(a) * d, z + np.sin(a) * d, r * 0.5, r * rng.uniform(2.2, 4.5), c, side=c * 0.75, emi=c * 0.55)
for _ in range(40):
    x, z = rng.uniform(-150, 150), rng.uniform(20, 200)
    if W3.ground(x, z) > WATER_Y + 0.5:
        W3.blob(x, z, rng.uniform(1.5, 3.5), rng.uniform(1.0, 2.5), rgb(1.0, 0.8, 0.25), side=rgb(0.8, 0.55, 0.15), seed=int(z), emi=rgb(0.5, 0.35, 0.08))
T = W3.terrain(0.5)
sun_dir = (0.15, 0.95, 0.25)
sun_col = rgb(1.0, 0.82, 0.45) * 1.3
def skyf(d):
    y = np.clip(d[..., 1], -0.2, 1)
    return mix(rgb(0.30, 0.16, 0.06), rgb(0.04, 0.02, 0.02), smoothstep(0.0, 0.8, y)[..., None]) + rgb(0.8, 0.45, 0.12) * (np.exp(-np.abs(y) * 5) * 0.45)[..., None]
look = Look(sun_dir, sun_col, rgb(0.55, 0.36, 0.16), rgb(0.30, 0.18, 0.08), skyf, rgb(0.35, 0.20, 0.08), 0.0042)
dust = sparkle_cloud(rng, 420, (-80, 80), (2, 60), (14, 240), size=(0.12, 0.4), cols=((1.0, 0.85, 0.4), (1.0, 0.7, 0.25)), alpha=(0.5, 1.0))
def stalactites(img, depth, cam):
    def draw(dr, proj):
        Wd = cam[3] * 2
        for _ in range(26):
            x = rng.uniform(0, Wd)
            w = rng.uniform(40, 120)
            h = rng.uniform(120, 400)
            dr.polygon([(x - w, -10), (x + w, -10), (x + w * 0.2, h * 0.75), (x, h), (x - w * 0.2, h * 0.7)], fill=(22, 12, 6, 240))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 40, -12), 0.24, 'w17.png', fov=1.2, water=dict(y=WATER_Y, shallow=rgb(1.0, 0.7, 0.3), deep=rgb(0.15, 0.06, 0.02), clarity=0.2, ripple=0.02, reflect=1.0, glitter=1.2),
         particles=dust + (4.5,), extra=stalactites, rays=dict(strength=0.5, threshold=0.65, color=(1.0, 0.8, 0.4), samples=56), finish_kw=dict(sat=1.2, vignette=0.4)))
