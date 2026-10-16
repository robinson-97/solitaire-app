from kit import *
rng = np.random.default_rng(15)
N = 1024
W3 = World(N=N, hx=200, z0=2, z1=420)
X, Z = W3.XG, W3.ZG
basin = smoothstep(120, 30, np.hypot(X * 0.9, (Z - 150) * 1.0))
W3.H[:] = fbm2(X * 0.02, Z * 0.02, 5, 3) * 20 * (1 - basin * 0.9) + smoothstep(210, 380, Z) * 55 * fbm2(X * 0.02, Z * 0.02, 4, 5) + fbm2(X * 0.1, Z * 0.1, 3, 7) * 1.5 - basin * 3
WATER_Y = 0.6
W3.ALB[:] = mix(rgb(0.10, 0.06, 0.18), rgb(0.22, 0.14, 0.32), fbm2(X * 0.05, Z * 0.05, 4, 4)[..., None])
W3.SIDE[:] = rgb(0.08, 0.06, 0.14)
cols = [rgb(0.62, 0.25, 1.0), rgb(0.35, 0.45, 1.0), rgb(0.80, 0.35, 1.0), rgb(0.30, 0.80, 1.0)]
for (x, z, r) in sorted(scatter(rng, 160, (-170, 170), (16, 330), ok=lambda x, z: W3.ground(x, z) > WATER_Y + 0.6, radius_fn=lambda x, z: 2.6 + z / 60, min_gap=0.7), key=lambda t: -t[1]):
    c = cols[rng.integers(0, 4)]
    for j in range(rng.integers(2, 6)):
        a = rng.uniform(0, 6.28)
        d = rng.uniform(0, r * 1.1)
        W3.cone(x + np.cos(a) * d, z + np.sin(a) * d, r * rng.uniform(0.35, 0.6), r * rng.uniform(2.5, 5.5), c * 0.8, side=c * 0.7, emi=c * 0.85)
T = W3.terrain(0.5)
sun_dir = (0.1, 0.9, 0.3)
sun_col = rgb(0.5, 0.4, 0.9) * 0.45
def skyf(d):
    y = np.clip(d[..., 1], -0.2, 1)
    return mix(rgb(0.10, 0.06, 0.24), rgb(0.01, 0.01, 0.06), smoothstep(0.0, 0.8, y)[..., None]) + rgb(0.30, 0.15, 0.55) * (np.exp(-np.abs(y) * 5) * 0.5)[..., None]
look = Look(sun_dir, sun_col, rgb(0.30, 0.20, 0.55), rgb(0.18, 0.10, 0.32), skyf, rgb(0.20, 0.10, 0.40), 0.0040)
sparks = sparkle_cloud(rng, 420, (-80, 80), (2, 60), (14, 240), size=(0.12, 0.4), cols=((0.8, 0.5, 1.0), (0.5, 0.8, 1.0), (1, 0.8, 1)), alpha=(0.5, 1.0))
def stalactites(img, depth, cam):
    def draw(dr, proj):
        Wd, Hd = cam[3] * 2, cam[4] * 2
        for _ in range(26):
            x = rng.uniform(0, Wd)
            w = rng.uniform(40, 120)
            h = rng.uniform(120, 420)
            dr.polygon([(x - w, -10), (x + w, -10), (x + w * 0.2, h * 0.75), (x, h), (x - w * 0.2, h * 0.7)], fill=(10, 6, 24, 240))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 40, -12), 0.24, 'w15.png', fov=1.2, water=dict(y=WATER_Y, shallow=rgb(0.5, 0.3, 0.9), deep=rgb(0.02, 0.01, 0.12), clarity=0.2, ripple=0.02, reflect=1.0, glitter=0.5),
         particles=sparks + (4.5,), extra=stalactites, finish_kw=dict(sat=1.2, vignette=0.4)))
