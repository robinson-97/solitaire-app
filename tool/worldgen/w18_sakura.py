from kit import *
rng = np.random.default_rng(18)
N = 1024
W3 = World(N=N, hx=320, z0=2, z1=640)
X, Z = W3.XG, W3.ZG
basin = smoothstep(180, 60, np.hypot(X * 0.7, (Z - 200) * 1.0))
land = fbm2(X * 0.012, Z * 0.012, 5, 3) * 20 + fbm2(X * 0.06, Z * 0.06, 3, 5) * 2.5
fuji_r = np.hypot(X + 40, (Z - 500) * 0.9)
fuji = np.clip(210 - fuji_r * 0.85, 0, None) * (0.94 + 0.12 * fbm2(X * 0.03, Z * 0.03, 4, 2))
ridge_far = ridged(N, 5, 5, 8) ** 1.4 * 80 * smoothstep(380, 600, Z)
W3.H[:] = land * (1 - basin * 0.92) + fuji + ridge_far - basin * 4 + 3
WATER_Y = 1.0
snow = smoothstep(120, 150, W3.H)
W3.ALB[:] = mix(mix(rgb(0.30, 0.48, 0.30), rgb(0.50, 0.65, 0.35), fbm2(X * 0.05, Z * 0.05, 4, 8)[..., None]), rgb(0.97, 0.98, 1.0), snow[..., None])
W3.SIDE[:] = mix(rgb(0.30, 0.34, 0.42), rgb(0.85, 0.9, 1.0), snow[..., None])
pink = [rgb(1.0, 0.68, 0.80), rgb(1.0, 0.80, 0.88), rgb(0.96, 0.55, 0.72), rgb(1.0, 0.90, 0.94)]
plant(W3, rng, 1100, pink, (-300, 300), (14, 380), ok=lambda x, z: W3.ground(x, z) > WATER_Y + 1.2 and W3.ground(x, z) < 60, rad=lambda x, z: 3.6 + z / 60, lift=0.6, min_gap=0.9, seed=60)
# temple island with roofs
tx, tz = 56.0, 150.0
b0 = W3.ground(tx, tz)
red = rgb(0.80, 0.16, 0.12)
roof = rgb(0.25, 0.28, 0.34)
W3.box(tx, tz, 22, 16, 9, rgb(0.94, 0.90, 0.82), side=rgb(0.8, 0.74, 0.66), base=b0 + 0.5)
W3.box(tx, tz, 30, 22, 3.2, roof, side=roof * 0.8, base=b0 + 9.5, roof=7)
W3.box(tx, tz, 14, 12, 8, rgb(0.94, 0.9, 0.82), side=rgb(0.8, 0.74, 0.66), base=b0 + 16)
W3.box(tx, tz, 22, 18, 3.0, roof, side=roof * 0.8, base=b0 + 24, roof=6)
T = W3.terrain(0.6)
sun_dir = (0.35, 0.28, 0.89)
sun_col = rgb(1.0, 0.80, 0.62) * 1.1
skyf = with_clouds(sky_gradient((0.42, 0.55, 0.88), (0.95, 0.72, 0.80), (1.0, 0.86, 0.70), sun_dir, sun_col, 0.016, 0.7), seed=29, tint=(1.0, 0.8, 0.82), strength=0.55, coverage=0.5)
look = Look(sun_dir, sun_col, rgb(0.70, 0.62, 0.82), rgb(0.50, 0.40, 0.40), skyf, rgb(0.98, 0.84, 0.84), 0.0036)
petals = sparkle_cloud(rng, 300, (-70, 70), (2, 40), (14, 170), size=(0.25, 0.55), cols=((1.0, 0.7, 0.82), (1.0, 0.85, 0.9)), alpha=(0.6, 1.0))
def torii(img, depth, cam):
    def draw(dr, proj):
        x0, z0 = -14.0, 105.0
        px_, py_, zz, f = proj([(x0, WATER_Y, z0)])
        s = 3.6 * f / zz[0]
        c = (205, 40, 30, 255)
        dk = (30, 30, 36, 255)
        for dx in (-2.4, 2.4):
            dr.rectangle([px_[0] + dx * s - s * 0.28, py_[0] - 5.2 * s, px_[0] + dx * s + s * 0.28, py_[0]], fill=c)
        dr.rectangle([px_[0] - 3.6 * s, py_[0] - 5.6 * s, px_[0] + 3.6 * s, py_[0] - 4.8 * s], fill=c)
        dr.polygon([(px_[0] - 4.3 * s, py_[0] - 5.2 * s), (px_[0] + 4.3 * s, py_[0] - 5.2 * s), (px_[0] + 3.7 * s, py_[0] - 6.3 * s), (px_[0] - 3.7 * s, py_[0] - 6.3 * s)], fill=dk)
        dr.rectangle([px_[0] - 3.3 * s, py_[0] - 4.1 * s, px_[0] + 3.3 * s, py_[0] - 3.7 * s], fill=c)
    return composite_rgba(img, sprite_layer(img, depth, cam, draw))
print(go(W3, look, (0, 52, -14), 0.28, 'w18.png', fov=1.2, water=dict(y=WATER_Y, shallow=rgb(0.8, 0.95, 0.95), deep=rgb(0.10, 0.30, 0.45), clarity=0.2, ripple=0.012, reflect=1.0, glitter=2.0),
         particles=petals + (3.0,), extra=torii, rays=dict(strength=0.2, threshold=0.8, color=(1.0, 0.85, 0.7)), finish_kw=dict(sat=1.12)))
