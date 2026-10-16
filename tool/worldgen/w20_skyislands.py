from kit import *
rng = np.random.default_rng(20)
N = 1024
W3 = World(N=N, hx=300, z0=2, z1=560)
X, Z = W3.XG, W3.ZG
cloud = fbm2(X * 0.015, Z * 0.015, 6, 3)
W3.H[:] = cloud * 14 - 6
W3.ALB[:] = mix(rgb(0.98, 0.90, 0.95), rgb(1.0, 1.0, 1.0), fbm2(X * 0.04, Z * 0.04, 4, 5)[..., None])
W3.SIDE[:] = rgb(0.85, 0.80, 0.92)
rock = rgb(0.58, 0.46, 0.46)
grass = [rgb(0.30, 0.74, 0.30), rgb(0.42, 0.82, 0.32)]
isl = [(0, 200, 44, 56), (-120, 150, 28, 40), (110, 260, 36, 50), (-70, 330, 30, 46), (170, 140, 20, 32), (20, 430, 40, 60), (-190, 260, 24, 36)]
for (x, z, r, h) in isl:
    b = W3.ground(x, z)
    # tapered rock plateau
    sl = W3.window(x, z, r * 1.2)
    d = np.hypot(W3.XG[sl] - x, W3.ZG[sl] - z)
    nz = noise2(W3.XG[sl] * 0.2, W3.ZG[sl] * 0.2, 3)
    top = b + h * (1 - 0.22 * (d / r) ** 2) * (0.92 + 0.14 * nz)
    mask = d < r * (0.92 + 0.14 * nz)
    up = mask & (top > W3.H[sl])
    W3.H[sl] = np.where(up, top, W3.H[sl])
    W3.ALB[sl] = np.where(up[..., None], grass[0], W3.ALB[sl])
    W3.SIDE[sl] = np.where(up[..., None], rock, W3.SIDE[sl])
    top_h = b + h * 0.9
    for _ in range(int(r / 3)):
        a = rng.uniform(0, 6.28)
        dd = rng.uniform(0, r * 0.7)
        W3.dome(x + np.cos(a) * dd, z + np.sin(a) * dd, rng.uniform(2.2, 4.4), rng.uniform(2.5, 5.0), 0.8, rgb(0.14, 0.52, 0.20), side=rgb(0.08, 0.34, 0.14), base=top_h - 3)
    # ancient stones
    for _ in range(3):
        a = rng.uniform(0, 6.28)
        dd = rng.uniform(0, r * 0.5)
        W3.cyl(x + np.cos(a) * dd, z + np.sin(a) * dd, 1.2, rng.uniform(5, 9), rgb(0.82, 0.80, 0.74), side=rgb(0.6, 0.58, 0.55), base=top_h - 2)
T = W3.terrain(0.5)
sun_dir = (-0.65, 0.35, 0.67)
sun_col = rgb(1.0, 0.86, 0.62) * 1.3
skyf = with_clouds(sky_gradient((0.18, 0.40, 0.88), (0.50, 0.72, 0.98), (1.0, 0.88, 0.75), sun_dir, sun_col, 0.018, 0.7), seed=37, scale=1.2, coverage=0.5, soft=0.25, strength=0.8, tint=(1.0, 0.92, 0.92))
look = Look(sun_dir, sun_col, rgb(0.58, 0.72, 0.98), rgb(0.80, 0.70, 0.78), skyf, rgb(0.96, 0.86, 0.90), 0.0042)
def falls(img, depth, cam):
    def draw(dr, proj):
        for (x, z, r, h) in isl[:4]:
            px_, py_, zz, f = proj([(x + r * 0.55, h * 0.8 + W3.ground(x, z), z - r * 0.2)])
            L = 30 * f / zz[0]
            for k in range(3):
                dr.line([px_[0] + k * L * 0.05, py_[0], px_[0] + k * L * 0.05 + L * 0.06, py_[0] + L], fill=(230, 250, 255, 190), width=max(2, int(L * 0.07)))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
sp = sparkle_cloud(rng, 220, (-70, 70), (4, 70), (14, 260), size=(0.15, 0.4), cols=((1, 1, 1), (1, 0.9, 0.8)), alpha=(0.4, 0.9))
print(go(W3, look, (0, 62, -16), 0.12, 'w20.png', fov=1.2, particles=sp + (3.5,), extra=falls, rays=dict(strength=0.2, threshold=0.8, color=(1.0, 0.88, 0.7)), finish_kw=dict(sat=1.1)))
