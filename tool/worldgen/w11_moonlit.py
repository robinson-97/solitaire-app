from kit import *
rng = np.random.default_rng(11)
N = 1024
W3 = World(N=N, hx=300, z0=2, z1=620)
X, Z = W3.XG, W3.ZG
basin = smoothstep(150, 40, np.hypot(X * 0.8, (Z - 190) * 1.1))
hills = fbm2(X * 0.012, Z * 0.012, 5, 3) * 26 + fbm2(X * 0.06, Z * 0.06, 3, 5) * 3
far = ridged(N, 5, 5, 9) ** 1.5 * 150 * smoothstep(300, 560, Z)
W3.H[:] = hills * (1 - basin * 0.95) + far + 2.0 - basin * 4
WATER_Y = 1.6
W3.ALB[:] = mix(rgb(0.10, 0.22, 0.22), rgb(0.20, 0.38, 0.34), fbm2(X * 0.05, Z * 0.05, 4, 3)[..., None])
W3.SIDE[:] = rgb(0.10, 0.12, 0.16)
W3.ALB[:] = mix(W3.ALB, rgb(0.85, 0.9, 1.0), (smoothstep(0.5, 0.0, 1 - far / 150.0) * 0.0)[..., None])
pal = [rgb(0.08, 0.30, 0.28), rgb(0.10, 0.36, 0.33), rgb(0.06, 0.26, 0.30)]
lm, pts = plant(W3, rng, 1700, pal, (-290, 290), (10, 520), ok=lambda x, z: W3.H[min(max(W3.idx(x, z)[1], 0), N - 1), min(max(W3.idx(x, z)[0], 0), N - 1)] > WATER_Y + 0.8,
                rad=lambda x, z: 2.2 + z / 90, shape='cone', tall=(1.0, 1.5), side=0.7, min_gap=0.8, bump=False, tiers=6)
W3.ALB[:] = np.where(lm[..., None], mix(W3.ALB, rgb(0.55, 0.75, 0.9), (smoothstep(0.45, 0.75, fbm2(X * 0.3, Z * 0.3, 3, 4)) * 0.18)[..., None]), W3.ALB)
T = W3.terrain(0.6)
moon_dir = norm(np.array([-0.20, 0.42, 0.88], np.float32))
sun_col = rgb(0.45, 0.58, 1.0) * 1.5
def skyf(d):
    y = np.clip(d[..., 1], -0.2, 1)
    c = mix(rgb(0.07, 0.13, 0.32), rgb(0.02, 0.03, 0.12), smoothstep(0.0, 0.7, y)[..., None])
    c = c + rgb(0.10, 0.22, 0.40) * (np.exp(-y * 6) * 0.9)[..., None]
    md = np.clip((d * moon_dir).sum(-1), -1, 1)
    c = c + rgb(0.7, 0.8, 1.0) * (np.exp((md - 1) * 30) * 0.7)[..., None]
    c = mix(c, rgb(1.0, 0.98, 0.9) * 1.6, smoothstep(0.9935, 0.9945, md)[..., None])
    rs = np.random.default_rng(1)
    return c + (stars_layer(d))[..., None] * rgb(0.9, 0.95, 1.0)
def stars_layer(d):
    h = d.shape[0]
    g = noise2(d[..., 0] * 220, d[..., 1] * 220, 3)
    return (g > 0.985).astype(np.float32) * np.clip(d[..., 1] * 3, 0, 1) * 0.8
look = Look(moon_dir, sun_col, rgb(0.30, 0.42, 0.75), rgb(0.12, 0.18, 0.26), skyf, rgb(0.14, 0.24, 0.46), 0.0034)
ff = sparkle_cloud(rng, 360, (-80, 80), (2, 40), (16, 220), size=(0.15, 0.45), cols=((0.5, 0.9, 1.0), (0.7, 1.0, 0.9)), alpha=(0.5, 1.0))
print(go(W3, look, (0, 80, -20), 0.46, 'w11.png', fov=1.2, water=dict(y=WATER_Y, shallow=rgb(0.2, 0.4, 0.5), deep=rgb(0.01, 0.05, 0.12), clarity=0.3, ripple=0.012, reflect=1.0, glitter=3.0),
         particles=ff + (4.0,), rays=dict(strength=0.2, threshold=0.8, color=(0.7, 0.85, 1.0)), finish_kw=dict(sat=1.1, vignette=0.4)))
