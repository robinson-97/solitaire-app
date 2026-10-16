from kit import *
rng = np.random.default_rng(16)
N = 1024
W3 = World(N=N, hx=240, z0=2, z1=480)
X, Z = W3.XG, W3.ZG
sx, WATER_Y, dist = valley(W3, hill=18, far_amp=50, river_w=18, bank=3.0, amp=14, seed=41, ph=2.0)
hill = np.exp(-(((X - 20) / 70.0) ** 2 + ((Z - 230) / 60.0) ** 2)) * 34
W3.H[:] = W3.H + hill
W3.ALB[:] = mix(rgb(0.20, 0.62, 0.18), rgb(0.48, 0.80, 0.26), fbm2(X * 0.05, Z * 0.05, 4, 6)[..., None])
W3.SIDE[:] = rgb(0.50, 0.46, 0.40)
stone = rgb(0.86, 0.84, 0.80)
sd = rgb(0.62, 0.60, 0.58)
roof = rgb(0.18, 0.38, 0.85)
cx, cz = 20.0, 230.0
b0 = W3.ground(cx, cz)
W3.box(cx, cz, 34, 30, 36, stone, side=sd, base=b0)
W3.box(cx, cz, 18, 18, 52, stone, side=sd, base=b0)
for (dx, dz) in [(-22, -20), (22, -20), (-22, 20), (22, 20)]:
    W3.cyl(cx + dx, cz + dz, 5.2, 42, stone, side=sd, base=b0)
    W3.cone(cx + dx, cz + dz, 7.4, 16, roof, side=roof * 0.7, base=b0 + 42)
W3.cone(cx, cz, 13, 22, roof, side=roof * 0.7, base=b0 + 52)
W3.box(cx, cz - 22, 62, 5, 20, stone, side=sd, base=b0)
W3.box(cx, cz + 22, 62, 5, 20, stone, side=sd, base=b0)
W3.box(cx - 31, cz, 5, 44, 20, stone, side=sd, base=b0)
W3.box(cx + 31, cz, 5, 44, 20, stone, side=sd, base=b0)
# bridge across the river
bz = 90.0
bxr = sx(bz)
W3.box(bxr, bz, 46, 7, 5.5, stone, side=sd, base=WATER_Y + 1.0)
# small village houses
for _ in range(9):
    x, z = rng.uniform(-120, 120), rng.uniform(60, 190)
    if abs(x - sx(z)) < 14:
        continue
    b = W3.ground(x, z)
    W3.box(x, z, 9, 8, 6, rgb(0.95, 0.90, 0.80), side=rgb(0.8, 0.74, 0.66), base=b, roof=5)
pal = [rgb(0.16, 0.56, 0.18), rgb(0.26, 0.66, 0.20), rgb(0.12, 0.46, 0.20)]
plant(W3, rng, 700, pal, (-230, 230), (12, 460), ok=lambda x, z: abs(x - sx(z)) > 14 and not (abs(x - cx) < 52 and abs(z - cz) < 48), rad=lambda x, z: 3.2 + z / 70, min_gap=1.0, seed=50)
T = W3.terrain(0.6)
sun_dir = (0.40, 0.50, 0.77)
sun_col = rgb(1.0, 0.92, 0.75) * 1.5
skyf = with_clouds(sky_gradient((0.20, 0.45, 0.92), (0.55, 0.76, 0.98), (0.90, 0.95, 1.0), sun_dir, sun_col, 0.018, 0.5), seed=33, scale=1.0, coverage=0.5, soft=0.22, strength=0.85)
look = Look(sun_dir, sun_col, rgb(0.50, 0.68, 0.92), rgb(0.32, 0.45, 0.25), skyf, rgb(0.80, 0.90, 1.0), 0.0030)
def flags(img, depth, cam):
    def draw(dr, proj):
        for (dx, dz, top) in [(-22, -20, 58), (22, -20, 58), (-22, 20, 58), (22, 20, 58), (0, 0, 74)]:
            px_, py_, z_, f = proj([(cx + dx, b0 + top, cz + dz)])
            L = 6 * f / z_[0]
            dr.line([px_[0], py_[0], px_[0], py_[0] - L * 2.2], fill=(240, 240, 240, 255), width=max(1, int(L * 0.12)))
            dr.polygon([(px_[0], py_[0] - L * 2.2), (px_[0] + L * 1.6, py_[0] - L * 1.8), (px_[0], py_[0] - L * 1.3)], fill=(235, 50, 60, 255))
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 56, -14), 0.36, 'w16.png', fov=1.18, water=dict(y=WATER_Y, shallow=rgb(0.55, 0.9, 0.9), deep=rgb(0.08, 0.35, 0.55), clarity=0.2, ripple=0.04, reflect=1.0), extra=flags, finish_kw=dict(sat=1.12)))
