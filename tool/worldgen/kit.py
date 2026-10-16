import sys
sys.path.insert(0, '/home/user/solitaire-app/tool/worldgen')
from scene3d import *

OUT = '/tmp/claude-0/-home-user-solitaire-app/2159d7d9-0583-50a7-a346-78ef31ed353a/scratchpad/'
WPX, HPX = 720, 1280


def rgb(*c):
    return np.array(c, np.float32)


def scatter(rng, n, xr, zr, ok=None, min_gap=0.0, radius_fn=None, tries=20):
    pts = []
    for _ in range(n * tries):
        if len(pts) >= n:
            break
        x = rng.uniform(*xr)
        z = rng.uniform(*zr)
        if ok is not None and not ok(x, z):
            continue
        r = radius_fn(x, z) if radius_fn else 1.0
        if min_gap and any(np.hypot(x - px, z - pz) < (r + pr) * min_gap for px, pz, pr in pts):
            continue
        pts.append((x, z, r))
    return pts


def sky_gradient(top, mid, hor, sun_dir=None, sun_col=None, sun_size=0.02, glow=0.5):
    top, mid, hor = rgb(*top), rgb(*mid), rgb(*hor)
    if sun_dir is None:
        return lambda d: sky(d, norm(np.array([0, 1, 0], np.float32)), top, mid, hor, rgb(0, 0, 0), 0.0001, 0.0)
    sd = norm(np.array(sun_dir, np.float32))
    sc = rgb(*sun_col)
    return lambda d: sky(d, sd, top, mid, hor, sc, sun_size, glow)


def with_clouds(fn, seed=5, tint=(1, 1, 1), scale=1.4, coverage=0.55, soft=0.3, strength=0.4, stretch=1.0):
    t = rgb(*tint)
    return lambda d: fn(d) + cloud_layer(d, seed, None, scale=scale, coverage=coverage, soft=soft, strength=strength, stretch=stretch) * t


def go(world, look, cam_pos, pitch, name, fov=1.15, yaw=0.0, water=None, particles=None, rays=None, steps=170, tmax=470,
       W=WPX, H=HPX, spec=0.0, shadows=True, post=None, finish_kw=None, extra=None):
    img, depth, o, d = render(world, look, cam_pos, pitch, W, H, fov=fov, yaw=yaw, steps=steps, tmax=tmax, water=water, spec=spec, shadows=shadows)
    cam = (cam_pos, pitch, yaw, W, H, fov)
    if extra is not None:
        img = extra(img, depth, cam)
    if particles:
        pts, sz, cols, al, glow = particles
        img = add_particles(img, depth, cam, np.array(pts, np.float32), sz, cols, glow=glow, alphas=al)
    if rays:
        sd = look.sun_dir
        sx, sy, sz_ = project(cam_pos, pitch, yaw, W, H, fov, (np.array(cam_pos, np.float32) + sd * 100)[None, :])
        img = god_rays(img, (float(sx[0]), float(sy[0])), **rays)
    if post is not None:
        img = post(img)
    kw = dict(vignette=0.30, sat=1.10)
    if finish_kw:
        kw.update(finish_kw)
    return save(img, name, **kw)


def sparkle_cloud(rng, n, xr, yr, zr, size=(0.2, 0.5), cols=((1, 0.9, 0.6),), alpha=(0.5, 1.0)):
    pts, sz, cc, al = [], [], [], []
    for _ in range(n):
        pts.append((rng.uniform(*xr), rng.uniform(*yr), rng.uniform(*zr)))
        sz.append(rng.uniform(*size))
        cc.append(cols[rng.integers(0, len(cols))])
        al.append(rng.uniform(*alpha))
    return pts, sz, cc, al


def valley(W3, hill=14.0, far_amp=38.0, river_w=20.0, bank=3.2, hill_f=0.012, amp=14.0, ph=0.6, seed=7, far_start=220, far_end=430):
    """Rolling hills with a winding river. Returns (stream_x(z), water_y, dist)."""
    X, Z = W3.XG, W3.ZG

    def sx(z):
        return amp * np.sin(z * 0.021 + ph) + amp * 0.45 * np.sin(z * 0.057) + amp * 0.7

    dist = np.abs(X - sx(Z))
    hills = fbm2(X * hill_f, Z * hill_f, 5, seed) * hill + fbm2(X * 0.05, Z * 0.05, 3, seed + 2) * 2.0
    far = smoothstep(far_start, far_end, Z) * far_amp * (0.5 + fbm2(X * 0.01, Z * 0.01, 4, 3))
    val = np.exp(-(dist / river_w) ** 2)
    H0 = hills * (1 - 0.75 * val) + far - val * 3.0 - smoothstep(7.0, 2.0, dist) * bank
    W3.H[:] = H0
    wy = float(np.percentile(H0[(dist < 3) & (Z > 8) & (Z < 200)], 60)) + 0.2
    return sx, wy, dist


def plant(W3, rng, n, palette, xr, zr, ok=None, rad=lambda x, z: 4 + z / 80, shape='dome', tall=(0.8, 1.3), lift=0.55,
          side=0.55, min_gap=0.9, bump=True, tiers=5, seed=40):
    X, Z = W3.XG, W3.ZG
    Hb = W3.H.copy()
    pts = scatter(rng, n, xr, zr, ok=ok, min_gap=min_gap, radius_fn=rad)
    for (x, z, r) in sorted(pts, key=lambda t: -t[1]):
        c = palette[rng.integers(0, len(palette))]
        h = r * rng.uniform(*tall)
        if shape == 'dome':
            W3.dome(x, z, r, h, lift=r * lift, col=c, side=c * side)
        else:
            W3.cone(x, z, r, r * rng.uniform(*tall) * 3.4, c, side=c * side, tiers=tiers)
    lm = W3.H > Hb + 0.5
    if bump:
        W3.H[:] = W3.H + lm * ((noise2(X * 1.6, Z * 1.6, seed) - 0.5) * 1.5 + (noise2(X * 0.5, Z * 0.5, seed + 1) - 0.5) * 1.2)
    var = 0.72 + 0.55 * noise2(X * 2.4, Z * 2.4, seed + 2)
    W3.ALB[:] = np.where(lm[..., None], W3.ALB * var[..., None], W3.ALB)
    return lm, pts
