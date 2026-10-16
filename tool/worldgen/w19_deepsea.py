from kit import *
rng = np.random.default_rng(19)
N = 1024
W3 = World(N=N, hx=200, z0=2, z1=420)
X, Z = W3.XG, W3.ZG
W3.H[:] = fbm2(X * 0.02, Z * 0.02, 5, 3) * 10 + smoothstep(240, 400, Z) * 50 * fbm2(X * 0.02, Z * 0.02, 4, 4) + smoothstep(100, 190, np.abs(X)) * 40 * fbm2(X * 0.03, Z * 0.03, 3, 6)
W3.ALB[:] = mix(rgb(0.04, 0.08, 0.14), rgb(0.08, 0.14, 0.22), fbm2(X * 0.05, Z * 0.05, 4, 4)[..., None])
W3.SIDE[:] = rgb(0.03, 0.05, 0.10)
glows = [rgb(0.1, 0.9, 1.0), rgb(1.0, 0.25, 0.75), rgb(0.35, 0.45, 1.0), rgb(0.2, 1.0, 0.6)]
for (x, z, r) in sorted(scatter(rng, 260, (-170, 170), (14, 320), radius_fn=lambda x, z: 1.8 + z / 70, min_gap=0.7), key=lambda t: -t[1]):
    c = glows[rng.integers(0, 4)]
    k = rng.integers(0, 3)
    if k == 0:
        for j in range(rng.integers(3, 7)):
            a = rng.uniform(0, 6.28)
            W3.cone(x + np.cos(a) * r * 0.5, z + np.sin(a) * r * 0.5, r * 0.4, r * rng.uniform(2.0, 4.2), c * 0.6, side=c * 0.5, emi=c * 1.1)
    elif k == 1:
        W3.dome(x, z, r * 1.1, r * 0.9, 0.0, c * 0.6, side=c * 0.5, emi=c * 0.9)
    else:
        W3.cyl(x, z, r * 0.4, r * rng.uniform(1.8, 3.4), c * 0.6, side=c * 0.5, emi=c * 1.2, taper=0.15)
T = W3.terrain(0.6)
sun_dir = (0.1, 0.9, 0.2)
sun_col = rgb(0.3, 0.6, 1.0) * 0.55
def skyf(d):
    y = np.clip(d[..., 1], -0.3, 1)
    return mix(rgb(0.01, 0.06, 0.20), rgb(0.01, 0.02, 0.08), smoothstep(-0.1, 0.8, y)[..., None]) + rgb(0.02, 0.2, 0.4) * (np.exp(-np.abs(y) * 6) * 0.8)[..., None]
look = Look(sun_dir, sun_col, rgb(0.05, 0.16, 0.35), rgb(0.03, 0.08, 0.18), skyf, rgb(0.01, 0.08, 0.20), 0.0105)
plank = sparkle_cloud(rng, 520, (-70, 70), (2, 70), (14, 200), size=(0.08, 0.3), cols=((0.4, 0.9, 1.0), (0.9, 0.5, 1.0), (0.5, 1.0, 0.8)), alpha=(0.4, 1.0))
def jellies(img, depth, cam):
    def draw(dr, proj):
        for _ in range(14):
            x, y, z = rng.uniform(-70, 70), rng.uniform(16, 60), rng.uniform(40, 190)
            px_, py_, zz, f = proj([(x, y, z)])
            R = rng.uniform(5, 11) * f / zz[0]
            c = [(90, 230, 255), (255, 110, 220), (130, 140, 255)][rng.integers(0, 3)]
            for t in range(4):
                tt = 1 - t * 0.2
                a = int(70 + t * 32)
                dr.pieslice([px_[0] - R * tt, py_[0] - R * tt * 0.9, px_[0] + R * tt, py_[0] + R * tt * 0.9], 180, 360, fill=c + (a,))
            for k in range(7):
                ox = px_[0] + (k - 3) * R * 0.28
                pts = [(ox + np.sin(j * 0.9 + k) * R * 0.1, py_[0] + j * R * 0.22) for j in range(12)]
                dr.line(pts, fill=c + (150,), width=max(1, int(R * 0.05)))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 34, -10), 0.20, 'w19.png', fov=1.2, particles=plank + (3.5,), extra=jellies, rays=dict(strength=0.35, threshold=0.7, color=(0.4, 0.7, 1.0)), finish_kw=dict(sat=1.2, vignette=0.4)))
