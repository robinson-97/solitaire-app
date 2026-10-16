from kit import *
rng = np.random.default_rng(3)
N = 1024
W3 = World(N=N, hx=200, z0=2, z1=420)
X, Z = W3.XG, W3.ZG
canyon = smoothstep(240, 400, Z) * 60 * (0.6 + fbm2(X * 0.02, Z * 0.02, 4, 4))
walls = smoothstep(90, 190, np.abs(X)) * 40 * (0.5 + fbm2(X * 0.03, Z * 0.03, 3, 5))
W3.H[:] = fbm2(X * 0.02, Z * 0.02, 5, 3) * 6 + fbm2(X * 0.1, Z * 0.1, 3, 7) * 1.2 + canyon + walls
sand = rgb(0.78, 0.68, 0.50)
W3.ALB[:] = mix(sand, rgb(0.75, 0.70, 0.60), fbm2(X * 0.06, Z * 0.06, 3, 8)[..., None])
W3.SIDE[:] = rgb(0.45, 0.40, 0.42)
cols = [rgb(1.0, 0.35, 0.55), rgb(1.0, 0.55, 0.20), rgb(0.70, 0.30, 0.90), rgb(0.20, 0.55, 1.0), rgb(1.0, 0.85, 0.25), rgb(0.95, 0.30, 0.35)]
for (x, z, r) in scatter(rng, 900, (-180, 180), (14, 330), min_gap=0.7, radius_fn=lambda x, z: 1.6 + z / 70):
    c = cols[rng.integers(0, len(cols))]
    k = rng.integers(0, 4)
    if k == 0:
        W3.dome(x, z, r * 1.2, r * 0.9, 0.0, c, side=c * 0.6, squash=1.0)
    elif k == 1:
        for j in range(rng.integers(3, 7)):
            a = rng.uniform(0, 6.28)
            W3.cone(x + np.cos(a) * r * 0.5, z + np.sin(a) * r * 0.5, r * 0.7, r * rng.uniform(1.6, 2.8), c, side=c * 0.8)
    elif k == 2:
        W3.cyl(x, z, r * 0.55, r * rng.uniform(1.6, 3.0), c, side=c * 0.85, taper=0.1)
    else:
        W3.blob(x, z, r * 1.3, r * 1.0, c, side=c * 0.6, noise=0.5, seed=int(x * 7 + z))
for (x, z, r) in scatter(rng, 260, (-180, 180), (14, 320), min_gap=0.5, radius_fn=lambda x, z: 0.6):
    W3.cone(x, z, 0.9, rng.uniform(5, 13), rgb(0.15, 0.75, 0.40), side=rgb(0.10, 0.5, 0.3))
T = W3.terrain(0.6)
sun_dir = (0.15, 0.92, 0.35)
sun_col = rgb(0.80, 1.0, 1.0) * 1.0
def skyf(d):
    y = np.clip(d[..., 1], -0.3, 1.0)
    deep = rgb(0.02, 0.28, 0.45)
    shallow = rgb(0.25, 0.85, 0.92)
    top = rgb(0.75, 1.0, 1.0)
    c = mix(deep, shallow, smoothstep(-0.1, 0.55, y)[..., None])
    c = mix(c, top, smoothstep(0.55, 1.0, y)[..., None])
    return c
look = Look(sun_dir, sun_col, rgb(0.55, 0.95, 1.0), rgb(0.35, 0.65, 0.65), skyf, rgb(0.03, 0.40, 0.56), 0.0085)
bubbles = sparkle_cloud(rng, 300, (-50, 50), (2, 50), (14, 150), size=(0.1, 0.35), cols=((0.8, 1, 1),), alpha=(0.4, 0.9))
def fish(img, depth, cam):
    def draw(dr, proj):
        for _ in range(70):
            x, y, z = rng.uniform(-60, 60), rng.uniform(6, 30), rng.uniform(25, 130)
            px, py, zz, f = proj([(x, y, z)])
            L = 1.6 * f / zz[0]
            c = [(255, 170, 40), (255, 90, 120), (80, 200, 255), (255, 235, 90)][rng.integers(0, 4)]
            dr.ellipse([px[0] - L, py[0] - L * 0.45, px[0] + L, py[0] + L * 0.45], fill=c + (230,))
            dr.polygon([(px[0] - L * 0.9, py[0]), (px[0] - L * 1.7, py[0] - L * 0.55), (px[0] - L * 1.7, py[0] + L * 0.55)], fill=c + (220,))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 30, -10), 0.22, 'w03.png', fov=1.2, particles=bubbles + (3.0,), rays=dict(strength=0.55, threshold=0.6, color=(0.7, 1.0, 1.0), samples=48), extra=fish, finish_kw=dict(sat=1.15)))
