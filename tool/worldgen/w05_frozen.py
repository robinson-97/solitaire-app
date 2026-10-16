from kit import *
rng = np.random.default_rng(5)
N = 1024
W3 = World(N=N, hx=300, z0=2, z1=620)
X, Z = W3.XG, W3.ZG
ridge = ridged(N, 5, 6, 12)
far = smoothstep(120, 560, Z)
mount = (ridge ** 1.4) * 150 * far + fbm2(X * 0.01, Z * 0.01, 4, 3) * 18
lake_mask = smoothstep(40, 10, np.abs(X - 10) + (Z - 70) * 0.35) * smoothstep(200, 120, Z)
H0 = mount * (1 - lake_mask * 0.95) + fbm2(X * 0.05, Z * 0.05, 3, 6) * 2
W3.H[:] = H0
LAKE_Y = 1.0
snow = rgb(0.93, 0.97, 1.0)
rock = rgb(0.35, 0.40, 0.52)
slope_h = H0
W3.ALB[:] = mix(snow, rgb(0.80, 0.90, 1.0), fbm2(X * 0.03, Z * 0.03, 3, 2)[..., None])
W3.SIDE[:] = rock
# frosted pines
for (x, z, r) in scatter(rng, 380, (-260, 260), (20, 300), ok=lambda x, z: not (abs(x - 10) + (z - 70) * 0.35 < 46 and z < 200), min_gap=0.9, radius_fn=lambda x, z: 3 + z / 90):
    W3.cone(x, z, r, r * 3.6, rgb(0.86, 0.95, 1.0), side=rgb(0.16, 0.34, 0.32), tiers=5)
T = W3.terrain(0.7)
sun_dir = (0.75, 0.30, 0.59)
sun_col = rgb(1.0, 0.90, 0.72) * 1.2
skyf = with_clouds(sky_gradient((0.30, 0.52, 0.86), (0.62, 0.80, 0.95), (0.92, 0.96, 1.0), sun_dir, sun_col, 0.02, 0.7),
                   seed=9, tint=(0.95, 0.98, 1.0), strength=0.35)
look = Look(sun_dir, sun_col, rgb(0.50, 0.66, 0.88), rgb(0.62, 0.72, 0.92), skyf, rgb(0.78, 0.88, 0.98), 0.0030)
snowfall = sparkle_cloud(rng, 360, (-70, 70), (1, 60), (12, 160), size=(0.08, 0.2), cols=((1, 1, 1),), alpha=(0.5, 0.9))
print(go(W3, look, (0, 40, -14), 0.10, 'w05.png', fov=1.15, water=dict(y=LAKE_Y, shallow=rgb(0.7, 0.9, 1.0), deep=rgb(0.10, 0.36, 0.52), clarity=0.12, ripple=0.01, reflect=1.0, glitter=1.5),
         particles=snowfall + (3.0,), rays=dict(strength=0.20, threshold=0.8, color=(1, 0.95, 0.85)), finish_kw=dict(sat=1.08)))
