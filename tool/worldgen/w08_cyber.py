from kit import *
rng = np.random.default_rng(8)
N = 1024
W3 = World(N=N, hx=240, z0=2, z1=520)
X, Z = W3.XG, W3.ZG
W3.H[:] = 0
W3.ALB[:] = rgb(0.02, 0.02, 0.05)
W3.SIDE[:] = rgb(0.04, 0.05, 0.10)
neon = [rgb(1.0, 0.15, 0.65), rgb(0.1, 0.9, 1.0), rgb(0.55, 0.25, 1.0), rgb(1.0, 0.45, 0.15)]
BAYZ = 70.0
for gz in np.arange(BAYZ + 10, 500, 26):
    for gx in np.arange(-230, 230, 26):
        if abs(gx) < 6 and gz < 300:
            continue
        centre = np.exp(-((gx / 160) ** 2 + ((gz - 300) / 150) ** 2))
        h = rng.uniform(14, 60) * (0.5 + centre * 2.2) * (1 + gz / 700)
        w, dd = rng.uniform(12, 20), rng.uniform(12, 20)
        c = neon[rng.integers(0, 4)]
        tall = h > 70
        W3.box(gx + rng.uniform(-3, 3), gz + rng.uniform(-3, 3), w, dd, h, rgb(0.10, 0.10, 0.24), side=rgb(0.10, 0.12, 0.30), base=0.0)
        sl = W3.window(gx, gz, 22)
        if sl is None:
            continue
        m = (np.abs(W3.XG[sl] - gx) < w / 2 + 2) & (np.abs(W3.ZG[sl] - gz) < dd / 2 + 2) & (W3.H[sl] > h * 0.5)
        W3.EMI[sl] = np.where(m[..., None], c[None, None, :] * 1.8 * (0.55 + 0.9 * noise2(W3.XG[sl] * 1.7, W3.ZG[sl] * 1.7, int(gx))[..., None]), W3.EMI[sl])
        W3.BAND[sl] = np.where(m, 1.0, W3.BAND[sl])
        if rng.random() < 0.5:  # glowing rooftop beacon
            W3.cyl(gx, gz, 1.2, h + rng.uniform(6, 22), c * 0.5, side=c, base=0.0, emi=c * 2.5)
# elevated walkway
for gz in (150, 230, 330):
    W3.box(0, gz, 480, 5, 22, rgb(0.08, 0.09, 0.20), side=rgb(0.1, 0.1, 0.3), base=0.0, emi=rgb(0.2, 0.9, 1.0) * 0.4)
# bay in front: flatten land to a shoreline
W3.H[Z < BAYZ] = -3.0
W3.EMI[Z < BAYZ] = 0
T = W3.terrain(0.5)
sun_dir = (-0.2, 0.2, 0.96)
sun_col = rgb(0.9, 0.3, 0.8) * 0.5
def skyf(d):
    y = np.clip(d[..., 1], -0.1, 1)
    c = mix(rgb(1.0, 0.25, 0.65), rgb(0.35, 0.10, 0.60), smoothstep(0.0, 0.3, y)[..., None])
    c = mix(c, rgb(0.05, 0.03, 0.22), smoothstep(0.25, 0.8, y)[..., None])
    return c + rgb(1.0, 0.4, 0.9) * (np.exp(-np.abs(y) * 14) * 0.5)[..., None]
look = Look(sun_dir, sun_col, rgb(0.55, 0.30, 0.80), rgb(0.20, 0.12, 0.38), skyf, rgb(0.65, 0.22, 0.72), 0.0036)
def vehicles(img, depth, cam):
    def draw(dr, proj):
        for _ in range(18):
            x, y, z = rng.uniform(-150, 150), rng.uniform(60, 130), rng.uniform(120, 360)
            px, py, zz, f = proj([(x, y, z)])
            L = 1.6 * f / zz[0]
            c = [(255, 80, 190), (90, 230, 255), (255, 170, 60)][rng.integers(0, 3)]
            dr.line([px[0] - L * 6, py[0], px[0], py[0]], fill=c + (110,), width=max(1, int(L * 0.5)))
            dr.ellipse([px[0] - L, py[0] - L * 0.5, px[0] + L, py[0] + L * 0.5], fill=c + (255,))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 34, -10), 0.07, 'w08.png', fov=1.15, water=dict(y=0.0, shallow=rgb(0.1, 0.1, 0.25), deep=rgb(0.02, 0.02, 0.10), clarity=0.3, ripple=0.045, reflect=1.0, glitter=0.6), extra=vehicles, finish_kw=dict(sat=1.2, vignette=0.35, bloom_strength=1.0, bloom_threshold=0.55, bloom_radius=18)))
