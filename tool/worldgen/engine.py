"""A small offline 3D renderer (numpy) used to bake Hopstone's world artwork.

It ray-marches a height-field terrain with lighting, fog, sky, optional water
and glow, then post-processes (bloom, vignette, grain). Nothing here ships in
the app; only the finished images in assets/worlds/ do.
"""
import numpy as np
from PIL import Image, ImageFilter

rng = np.random.default_rng(1234)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def mix(a, b, t):
    return a + (b - a) * t


def norm(v):
    return v / np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-9)


# ---------------------------------------------------------------- noise ----
def value_noise_grid(n, cells, seed):
    """Tileless value noise on an n x n grid, with `cells` lattice cells."""
    r = np.random.default_rng(seed)
    lat = r.random((cells + 2, cells + 2)).astype(np.float32)
    xs = np.linspace(0, cells, n, endpoint=False, dtype=np.float32)
    ix = xs.astype(int)
    fx = xs - ix
    fx = fx * fx * (3 - 2 * fx)
    a = lat[np.ix_(ix, ix)]
    b = lat[np.ix_(ix, ix + 1)]
    c = lat[np.ix_(ix + 1, ix)]
    d = lat[np.ix_(ix + 1, ix + 1)]
    fxx = fx[None, :]
    fyy = fx[:, None]
    return (a * (1 - fxx) + b * fxx) * (1 - fyy) + (c * (1 - fxx) + d * fxx) * fyy


def fbm_grid(n, base_cells, octaves, seed, gain=0.5, lac=2.0):
    total = np.zeros((n, n), np.float32)
    amp = 1.0
    norm_sum = 0.0
    cells = base_cells
    for o in range(octaves):
        total += amp * value_noise_grid(n, int(cells), seed + o * 17)
        norm_sum += amp
        amp *= gain
        cells *= lac
    return total / norm_sum


def ridged(n, base_cells, octaves, seed):
    f = fbm_grid(n, base_cells, octaves, seed)
    return 1.0 - np.abs(f * 2 - 1)


# ----------------------------------------------------------- height field --
class Terrain:
    """Height field on a grid covering x in [-hx, hx], z in [z0, z1]."""

    def __init__(self, H, hx, z0, z1):
        self.H = H.astype(np.float32)
        self.n = H.shape[0]
        self.hx, self.z0, self.z1 = hx, z0, z1
        gy, gx = np.gradient(self.H)
        self.cx = (2 * hx) / self.n
        self.cz = (z1 - z0) / self.n
        self.gx = gx / self.cx
        self.gz = gy / self.cz

    def to_idx(self, x, z):
        u = (x + self.hx) / (2 * self.hx) * (self.n - 1)
        v = (z - self.z0) / (self.z1 - self.z0) * (self.n - 1)
        return u, v

    def sample(self, arr, x, z):
        u, v = self.to_idx(x, z)
        inside = (u >= 0) & (u < self.n - 1) & (v >= 0) & (v < self.n - 1)
        u = np.clip(u, 0, self.n - 1.001)
        v = np.clip(v, 0, self.n - 1.001)
        iu = u.astype(np.int32)
        iv = v.astype(np.int32)
        fu = u - iu
        fv = v - iv
        a = arr[iv, iu]
        b = arr[iv, iu + 1]
        c = arr[iv + 1, iu]
        d = arr[iv + 1, iu + 1]
        val = (a * (1 - fu) + b * fu) * (1 - fv) + (c * (1 - fu) + d * fu) * fv
        return val, inside

    def height(self, x, z):
        return self.sample(self.H, x, z)

    def normal(self, x, z):
        gx, _ = self.sample(self.gx, x, z)
        gz, _ = self.sample(self.gz, x, z)
        n = np.stack([-gx, np.ones_like(gx), -gz], -1)
        return norm(n)


# ------------------------------------------------------------------ camera --
def camera_rays(w, h, cam_pos, pitch, fov=1.0, yaw=0.0):
    xs = (np.arange(w, dtype=np.float32) + 0.5) / w * 2 - 1
    ys = 1 - (np.arange(h, dtype=np.float32) + 0.5) / h * 2
    X, Y = np.meshgrid(xs * (w / h), ys)
    f = 1.0 / np.tan(fov / 2)
    d = np.stack([X, Y, np.full_like(X, f)], -1)
    cp, sp = np.cos(pitch), np.sin(pitch)
    d = np.stack([d[..., 0], d[..., 1] * cp - d[..., 2] * sp, d[..., 1] * sp + d[..., 2] * cp], -1)
    cy, sy = np.cos(yaw), np.sin(yaw)
    d = np.stack([d[..., 0] * cy + d[..., 2] * sy, d[..., 1], -d[..., 0] * sy + d[..., 2] * cy], -1)
    d = norm(d)
    o = np.broadcast_to(np.array(cam_pos, np.float32), d.shape).copy()
    return o, d


def march(terrain, o, d, steps=140, tmax=380.0, water=None):
    """Returns (t, hit mask, water_hit mask). Relaxed ray-marching."""
    shape = d.shape[:2]
    t = np.full(shape, 0.5, np.float32)
    hit = np.zeros(shape, bool)
    alive = np.ones(shape, bool)
    for _ in range(steps):
        p = o + d * t[..., None]
        hgt, inside = terrain.height(p[..., 0], p[..., 2])
        dy = p[..., 1] - hgt
        newly = alive & inside & (dy < 0.05)
        hit |= newly
        alive &= ~newly
        alive &= (t < tmax)
        step = np.clip(0.55 * dy, 0.12, 6.0)
        t = np.where(alive, t + step, t)
        if not alive.any():
            break
    # refine hits with a few bisection steps
    lo = t - 4.0
    hi = t.copy()
    for _ in range(6):
        mid = 0.5 * (lo + hi)
        p = o + d * mid[..., None]
        hgt, _ = terrain.height(p[..., 0], p[..., 2])
        below = p[..., 1] < hgt
        hi = np.where(below & hit, mid, hi)
        lo = np.where(~below & hit, mid, lo)
    t = np.where(hit, 0.5 * (lo + hi), t)
    return t, hit


# --------------------------------------------------------------------- sky --
def sky(d, sun_dir, top, mid, hor, sun_col, sun_size=0.025, glow=0.5, clouds=None, seed=3):
    y = np.clip(d[..., 1], -0.2, 1.0)
    col = np.where(y[..., None] < 0.25, mix(hor, mid, (y / 0.25)[..., None].clip(0, 1)), mix(mid, top, ((y - 0.25) / 0.75)[..., None].clip(0, 1)))
    sd = np.clip((d * sun_dir).sum(-1), -1, 1)
    col = col + sun_col * (np.exp((sd - 1) * 40.0) * glow)[..., None]
    col = col + sun_col * (np.exp((sd - 1) * 400.0) * 0.8)[..., None]
    disc = smoothstep(1 - sun_size, 1 - sun_size * 0.7, sd)
    col = mix(col, sun_col * 1.4, disc[..., None])
    return col


def _hash(ix, iy, seed):
    n = np.sin(ix * 127.1 + iy * 311.7 + seed * 74.7) * 43758.5453
    return (n - np.floor(n)).astype(np.float32)


def noise2(x, y, seed=0):
    ix = np.floor(x)
    iy = np.floor(y)
    fx = (x - ix).astype(np.float32)
    fy = (y - iy).astype(np.float32)
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    a = _hash(ix, iy, seed)
    b = _hash(ix + 1, iy, seed)
    c = _hash(ix, iy + 1, seed)
    d = _hash(ix + 1, iy + 1, seed)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm2(x, y, octaves=6, seed=0, gain=0.5):
    tot = 0.0
    amp = 1.0
    ns = 0.0
    for o in range(octaves):
        tot = tot + amp * noise2(x, y, seed + o)
        ns += amp
        x = x * 2.03 + 17.1
        y = y * 2.03 + 3.7
        amp *= gain
    return tot / ns


def cloud_layer(d, seed, color=None, scale=3.0, coverage=0.55, soft=0.25, strength=0.85, stretch=1.0):
    """Clouds painted on a sky plane (no tiling seams)."""
    y = np.maximum(d[..., 1], 0.03)
    u = d[..., 0] / y * scale * 0.35
    v = d[..., 2] / y * scale * 0.35 * stretch
    val = fbm2(u, v, 6, seed)
    dens = smoothstep(coverage, coverage + soft, val) * smoothstep(0.03, 0.4, d[..., 1])
    return dens[..., None] * strength


# ---------------------------------------------------------------- post ------
def bloom(img, threshold=0.75, radius=18, strength=0.6):
    bright = np.clip(img - threshold, 0, None)
    b = Image.fromarray((np.clip(bright, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(radius))
    b = np.asarray(b).astype(np.float32) / 255
    return img + b * strength


def finish(img, out_w, out_h, vignette=0.35, grain=0.012, sat=1.08, contrast=1.05, seed=2, bloom_strength=0.5, bloom_threshold=0.78, bloom_radius=14):
    img = np.clip(img, 0, None)
    img = bloom(img, bloom_threshold, bloom_radius, bloom_strength)
    img = img / (1 + 0.15 * img)  # soft tone map
    gray = img.mean(-1, keepdims=True)
    img = gray + (img - gray) * sat
    img = np.clip((img - 0.5) * contrast + 0.5, 0, 1)
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    img = img * (1 - vignette * smoothstep(0.55, 1.35, r))[..., None]
    pil = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).resize((out_w, out_h), Image.LANCZOS)
    pil = pil.filter(ImageFilter.UnsharpMask(radius=1.6, percent=60, threshold=2))
    arr = np.asarray(pil).astype(np.float32) / 255
    g = np.random.default_rng(seed).normal(0, grain, arr.shape[:2])[..., None]
    arr = np.clip(arr + g, 0, 1)
    return Image.fromarray((arr * 255).astype(np.uint8))
