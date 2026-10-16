from kit import *
rng = np.random.default_rng(9)
N = 1024
W3 = World(N=N, hx=240, z0=2, z1=460)
X, Z = W3.XG, W3.ZG
rolling = fbm2(X * 0.010, Z * 0.010, 5, 5) * 22 + fbm2(X * 0.05, Z * 0.05, 3, 6) * 1.5
far = smoothstep(230, 440, Z) * 40 * fbm2(X * 0.008, Z * 0.008, 4, 3)
W3.H[:] = rolling + far
grass = mix(rgb(0.22, 0.58, 0.16), rgb(0.45, 0.76, 0.22), fbm2(X * 0.04, Z * 0.04, 4, 8)[..., None])
W3.ALB[:] = grass
W3.SIDE[:] = rgb(0.36, 0.28, 0.16)
# wheat fields with mowed stripes
fieldm = smoothstep(0.52, 0.58, fbm2(X * 0.014 + 5, Z * 0.014, 4, 12))
stripe = 0.85 + 0.15 * np.sin(Z * 0.9 + X * 0.2)
W3.ALB[:] = mix(W3.ALB, rgb(0.92, 0.72, 0.22) * stripe[..., None], fieldm[..., None] * 0.95)
# winding dirt path
px = 18 * np.sin(Z * 0.03) + 6
pm = smoothstep(4.2, 2.2, np.abs(X - px)) * smoothstep(0, 20, Z)
W3.ALB[:] = mix(W3.ALB, rgb(0.70, 0.52, 0.30), pm[..., None])
# wildflowers
fl = noise2(X * 1.1, Z * 1.1, 17)
for (thr, c) in [(0.94, (1.0, 0.95, 0.4)), (0.965, (1.0, 0.5, 0.7)), (0.985, (0.9, 0.9, 1.0))]:
    m = (fl > thr) & (fieldm < 0.3)
    W3.ALB[m] = np.array(c)
# barn, silo, windmill
bx, bz = -48.0, 150.0
b0 = W3.ground(bx, bz)
W3.box(bx, bz, 26, 18, 12, rgb(0.74, 0.12, 0.10), side=rgb(0.62, 0.10, 0.08), base=b0, roof=9)
W3.cyl(bx + 20, bz + 4, 4.5, 24, rgb(0.85, 0.86, 0.88), side=rgb(0.7, 0.72, 0.76), base=b0)
W3.cone(bx + 20, bz + 4, 5.5, 8, rgb(0.55, 0.12, 0.10), side=rgb(0.5, 0.1, 0.1), base=b0 + 24)
mx, mz = 46.0, 210.0
m0 = W3.ground(mx, mz)
W3.cyl(mx, mz, 6, 34, rgb(0.92, 0.88, 0.80), side=rgb(0.80, 0.74, 0.64), base=m0, taper=0.18)
W3.cone(mx, mz, 7.5, 9, rgb(0.55, 0.22, 0.16), side=rgb(0.5, 0.2, 0.15), base=m0 + 30)
# fences along the path
for z in np.arange(10, 280, 3.2):
    for off in (-6.5, 6.5):
        x = 18 * np.sin(z * 0.03) + 6 + off
        W3.cyl(x, z, 0.35, 2.0, rgb(0.62, 0.42, 0.22), side=rgb(0.5, 0.34, 0.18))
# trees
plant(W3, rng, 160, [rgb(0.16, 0.55, 0.14), rgb(0.26, 0.66, 0.16), rgb(0.12, 0.45, 0.14)], (-220, 220), (20, 400),
      ok=lambda x, z: abs(x - (18 * np.sin(z * 0.03) + 6)) > 12 and not (abs(x - bx) < 30 and abs(z - bz) < 22) and not (abs(x - mx) < 14 and abs(z - mz) < 14),
      rad=lambda x, z: 3 + z / 70, min_gap=1.2)
T = W3.terrain(0.7)
sun_dir = (0.40, 0.55, 0.73)
sun_col = rgb(1.0, 0.94, 0.78) * 1.5
skyf = with_clouds(sky_gradient((0.20, 0.50, 0.92), (0.50, 0.76, 0.98), (0.86, 0.94, 1.0), sun_dir, sun_col, 0.018, 0.5), seed=3, scale=1.0, coverage=0.50, soft=0.22, strength=0.9)
look = Look(sun_dir, sun_col, rgb(0.50, 0.68, 0.92), rgb(0.30, 0.42, 0.22), skyf, rgb(0.78, 0.90, 1.0), 0.0030)
def blades(img, depth, cam):
    def draw(dr, proj):
        px_, py_, z_, f = proj([(mx, m0 + 31, mz - 8)])
        L = 22 * f / z_[0]
        for k in range(4):
            a = 0.5 + k * np.pi / 2
            ex, ey = px_[0] + np.cos(a) * L, py_[0] + np.sin(a) * L
            dr.line([px_[0], py_[0], ex, ey], fill=(250, 245, 235, 255), width=max(2, int(L * 0.09)))
            dr.polygon([(px_[0] + np.cos(a) * L * 0.2, py_[0] + np.sin(a) * L * 0.2), (ex, ey), (px_[0] + np.cos(a + 0.3) * L * 0.45, py_[0] + np.sin(a + 0.3) * L * 0.45)], fill=(255, 250, 240, 235))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 44, -14), 0.30, 'w09.png', fov=1.2, extra=blades, rays=dict(strength=0.12, threshold=0.85), finish_kw=dict(sat=1.12)))
