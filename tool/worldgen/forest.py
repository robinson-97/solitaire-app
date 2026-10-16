import sys
sys.path.insert(0, '/home/user/solitaire-app/tool/worldgen')
from scene3d import *

rngp = np.random.default_rng(42)
W3 = World(N=1024, hx=190, z0=2, z1=440)
X, Z = W3.XG, W3.ZG

# --- ground: rolling forest floor with a winding stream
stream_x = 14 * np.sin(Z * 0.021 + 0.6) + 6 * np.sin(Z * 0.057) + 10
dist = np.abs(X - stream_x)
hills = fbm2(X * 0.012, Z * 0.012, 5, 7) * 14 + fbm2(X * 0.05, Z * 0.05, 3, 9) * 2.0
far = smoothstep(220, 430, Z) * 38 * (0.5 + fbm2(X * 0.01, Z * 0.01, 4, 3))
valley = np.exp(-(dist / 20.0) ** 2)
H0 = hills * (1 - 0.75 * valley) + far - valley * 3.0
bank = smoothstep(7.0, 2.0, dist)
H0 = H0 - bank * 3.2
W3.H[:] = H0
WATER_Y = float(np.percentile(H0[(dist < 3) & (Z > 8) & (Z < 200)], 60)) + 0.2

# --- albedo: moss, grass, flowers, mud near the water
n1 = fbm2(X * 0.09, Z * 0.09, 4, 5)
moss = mix(np.array([0.10, 0.38, 0.14]), np.array([0.34, 0.62, 0.18]), n1[..., None])
dirt = np.array([0.30, 0.22, 0.13])
W3.ALB[:] = mix(moss, dirt, (smoothstep(5.5, 2.5, dist) * 0.8)[..., None])
W3.SIDE[:] = np.array([0.28, 0.20, 0.14])
fl = noise2(X * 1.3, Z * 1.3, 11)
for (thr, c) in [(0.935, (1.0, 0.95, 0.55)), (0.965, (1.0, 0.65, 0.85)), (0.985, (0.7, 0.8, 1.0))]:
    m = (fl > thr) & (dist > 6)
    W3.ALB[m] = np.array(c)

# --- waterfall cliff at the far end of the stream
cz = 330.0
cxs = 14 * np.sin(cz * 0.021 + 0.6) + 6 * np.sin(cz * 0.057) + 10
W3.box(cxs, cz, 70, 26, 34, np.array([0.30, 0.34, 0.26]), side=np.array([0.36, 0.38, 0.32]), base=-2.0)
fall = (np.abs(X - cxs) < 5.0) & (Z > cz - 14) & (Z < cz - 11)
W3.SIDE[fall] = np.array([0.95, 0.98, 1.0])
W3.EMI[fall] = np.array([0.18, 0.22, 0.26])
W3.ALB[(np.abs(X - cxs) < 5.5) & (Z > cz - 13) & (Z < cz - 6) & (W3.H > 30)] = np.array([0.9, 0.95, 1.0])

# --- trees
Hbefore_trees = W3.H.copy()
leaf_top = [np.array(c) for c in [(0.22, 0.66, 0.20), (0.35, 0.74, 0.22), (0.15, 0.55, 0.22), (0.50, 0.78, 0.25)]]
leaf_side = [np.array(c) * 0.55 for c in [(0.22, 0.66, 0.20), (0.35, 0.74, 0.22), (0.15, 0.55, 0.22), (0.50, 0.78, 0.25)]]
trees = []
for _ in range(2600):
    z = rngp.uniform(12, 430)
    x = rngp.uniform(-170, 170)
    sx = 14 * np.sin(z * 0.021 + 0.6) + 6 * np.sin(z * 0.057) + 10
    if abs(x - sx) < 15 and z < 340:
        continue
    if all(np.hypot(x - tx, z - tz) > (tr + 4) * 0.8 for tx, tz, tr in trees):
        trees.append((x, z, rngp.uniform(3.2, 6.5) * (1 + z / 420)))
for (x, z, r) in sorted(trees, key=lambda t: -t[1]):
    k = rngp.integers(0, 4)
    h = r * rngp.uniform(0.8, 1.3)
    W3.dome(x, z, r, h, lift=r * 0.55, col=leaf_top[k], side=leaf_side[k], squash=1.0)
# big framing trees in front
for (x, z, r) in [(-58, 26, 10), (64, 30, 11), (-96, 60, 13), (104, 70, 13)]:
    W3.dome(x, z, r, r * 1.1, lift=r * 0.6, col=leaf_top[2], side=leaf_side[2])
leafmask = W3.H > Hbefore_trees + 0.5
bump = (noise2(X * 1.6, Z * 1.6, 21) - 0.5) * 1.5 + (noise2(X * 0.5, Z * 0.5, 22) - 0.5) * 1.2
W3.H[:] = W3.H + leafmask * bump
var = 0.72 + 0.55 * noise2(X * 2.4, Z * 2.4, 23)
W3.ALB[:] = np.where(leafmask[..., None], W3.ALB * var[..., None], W3.ALB)
W3.SIDE[:] = np.where(leafmask[..., None], W3.SIDE * (0.8 + 0.4 * noise2(X * 2.0, Z * 2.0, 24))[..., None], W3.SIDE)
# mossy boulders around the stream
for _ in range(60):
    z = rngp.uniform(10, 300)
    sx = 14 * np.sin(z * 0.021 + 0.6) + 6 * np.sin(z * 0.057) + 10
    x = sx + rngp.choice([-1, 1]) * rngp.uniform(3.5, 9)
    W3.blob(x, z, rngp.uniform(1.2, 3.2), rngp.uniform(0.8, 2.2), np.array([0.46, 0.5, 0.46]), side=np.array([0.32, 0.36, 0.32]), seed=int(z))

T = W3.terrain(0.7)

# --- sky and light
sun_dir = norm(np.array([-0.62, 0.30, 0.74], np.float32))
sun_col = np.array([1.0, 0.80, 0.50], np.float32) * 1.25


def sky_fn(d):
    return sky(d, sun_dir, np.array([0.28, 0.58, 0.85]), np.array([0.62, 0.84, 0.88]), np.array([1.0, 0.92, 0.66]), sun_col, 0.018, 0.55) + \
        cloud_layer(d, 5, None, scale=1.4, coverage=0.55, soft=0.3, strength=0.35)[..., :] * np.array([1.0, 0.95, 0.85])


look = Look(sun_dir, sun_col, amb_sky=np.array([0.38, 0.55, 0.62]), amb_ground=np.array([0.20, 0.28, 0.14]),
            sky_fn=sky_fn, fog_col=np.array([0.62, 0.82, 0.78]), fog_density=0.0052)

Wpx, Hpx = 720, 1280
cam_pos = (0, 52, -12)
pitch, fov = 0.52, 1.15
img, depth, o, d = render(W3, look, cam_pos, pitch, Wpx, Hpx, fov=fov, steps=170, tmax=470,
                          water=dict(y=WATER_Y, shallow=np.array([0.5, 0.95, 0.85]), deep=np.array([0.04, 0.34, 0.38]), clarity=0.25, ripple=0.06, reflect=1.0, glitter=2.5))

# magical particles: fireflies and drifting pollen
cam = (cam_pos, pitch, 0.0, Wpx, Hpx, fov)
pts, sz, cols, al = [], [], [], []
for _ in range(260):
    z = rngp.uniform(18, 150)
    x = rngp.uniform(-60, 60)
    y = rngp.uniform(8, 40)
    pts.append((x, y, z))
    sz.append(rngp.uniform(0.18, 0.5))
    cols.append((1.0, 0.85, 0.4) if rngp.random() < 0.7 else (0.7, 1.0, 0.7))
    al.append(rngp.uniform(0.5, 1.0))
img = add_particles(img, depth, cam, np.array(pts, np.float32), sz, cols, glow=4.0, alphas=al)
sx, sy, sz_ = project(cam_pos, pitch, 0.0, Wpx, Hpx, fov, (np.array(cam_pos, np.float32) + sun_dir * 100)[None, :])
img = god_rays(img, (float(sx[0]), float(sy[0])), strength=0.22, threshold=0.8, color=(1.0, 0.85, 0.55))
print(save(img, 'world_forest.png', vignette=0.32, sat=1.12))
