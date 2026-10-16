from kit import *
rng = np.random.default_rng(12)
N = 1024
W3 = World(N=N, hx=220, z0=2, z1=460)
X, Z = W3.XG, W3.ZG
sx, WATER_Y, dist = valley(W3, hill=22, far_amp=52, river_w=24, bank=3.6, amp=20, seed=31, ph=1.4)
leaf = mix(rgb(0.55, 0.25, 0.08), rgb(0.85, 0.52, 0.16), fbm2(X * 0.07, Z * 0.07, 4, 4)[..., None])
W3.ALB[:] = mix(leaf, rgb(0.62, 0.40, 0.12), (smoothstep(5.5, 2.5, dist) * 0.6)[..., None])
W3.SIDE[:] = rgb(0.30, 0.18, 0.10)
pal = [rgb(0.90, 0.25, 0.08), rgb(1.0, 0.55, 0.10), rgb(0.95, 0.75, 0.15), rgb(0.70, 0.18, 0.10), rgb(0.85, 0.40, 0.08)]
plant(W3, rng, 2600, pal, (-210, 210), (10, 440), ok=lambda x, z: abs(x - sx(z)) > 16, rad=lambda x, z: 3.4 + z / 60, lift=0.5, side=0.55, min_gap=0.85, seed=44)
T = W3.terrain(0.7)
sun_dir = (-0.50, 0.28, 0.82)
sun_col = rgb(1.0, 0.68, 0.30) * 1.6
skyf = with_clouds(sky_gradient((0.30, 0.45, 0.78), (0.88, 0.66, 0.52), (1.0, 0.78, 0.45), sun_dir, sun_col, 0.016, 0.6), seed=19, tint=(1.0, 0.7, 0.5), strength=0.45)
look = Look(sun_dir, sun_col, rgb(0.60, 0.48, 0.55), rgb(0.40, 0.22, 0.10), skyf, rgb(1.0, 0.78, 0.55), 0.0045)
leaves = sparkle_cloud(rng, 240, (-60, 60), (2, 36), (16, 160), size=(0.3, 0.7), cols=((1.0, 0.5, 0.1), (0.9, 0.2, 0.08), (1.0, 0.75, 0.2)), alpha=(0.6, 1.0))
print(go(W3, look, (0, 50, -12), 0.46, 'w12.png', fov=1.18, water=dict(y=WATER_Y, shallow=rgb(1.0, 0.75, 0.5), deep=rgb(0.15, 0.20, 0.25), clarity=0.18, ripple=0.04, reflect=1.0, glitter=2.5), particles=leaves + (2.6,), rays=dict(strength=0.28, threshold=0.78, color=(1.0, 0.7, 0.35)), finish_kw=dict(sat=1.15)))
