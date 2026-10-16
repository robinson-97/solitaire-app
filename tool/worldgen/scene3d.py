"""Scene builder + renderer on top of engine.py: stamped objects, material maps,
sun shadows, water with planar reflection, sprites, particles, god rays."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from engine import *


def _box1(a, r, axis):
    r = int(max(r, 1))
    pad = [(0, 0)] * a.ndim
    pad[axis] = (r + 1, r)
    ap = np.pad(a, pad, mode='edge')
    c = np.cumsum(ap, axis=axis, dtype=np.float64)
    n = a.shape[axis]
    hi = np.take(c, np.arange(2 * r + 1, 2 * r + 1 + n), axis=axis)
    lo = np.take(c, np.arange(0, n), axis=axis)
    return ((hi - lo) / (2 * r + 1)).astype(np.float32)


def blur(a, r):
    """Approximate gaussian blur (3 box passes) for float arrays of any depth."""
    if r <= 0:
        return a
    rb = max(int(round(r * 0.9)), 1)
    out = a.astype(np.float32)
    for _ in range(3):
        out = _box1(out, rb, 0)
        out = _box1(out, rb, 1)
    return out


class World:
    def __init__(self, N=1024, hx=200.0, z0=2.0, z1=460.0):
        self.N, self.hx, self.z0, self.z1 = N, hx, z0, z1
        xs = np.linspace(-hx, hx, N, dtype=np.float32)
        zs = np.linspace(z0, z1, N, dtype=np.float32)
        self.XG, self.ZG = np.meshgrid(xs, zs)
        self.H = np.zeros((N, N), np.float32)
        self.ALB = np.zeros((N, N, 3), np.float32) + 0.5
        self.SIDE = np.zeros((N, N, 3), np.float32) + 0.4
        self.EMI = np.zeros((N, N, 3), np.float32)
        self.BAND = np.zeros((N, N), np.float32)  # >0 where emissive windows are banded by height
        self.cx = 2 * hx / N
        self.cz = (z1 - z0) / N

    # -------- coordinates
    def idx(self, x, z):
        return int((x + self.hx) / (2 * self.hx) * (self.N - 1)), int((z - self.z0) / (self.z1 - self.z0) * (self.N - 1))

    def window(self, x, z, r):
        ix, iz = self.idx(x, z)
        rx = int(r / self.cx) + 2
        rz = int(r / self.cz) + 2
        x0, x1 = max(ix - rx, 0), min(ix + rx + 1, self.N)
        z0, z1 = max(iz - rz, 0), min(iz + rz + 1, self.N)
        if x1 <= x0 or z1 <= z0:
            return None
        return slice(z0, z1), slice(x0, x1)

    def ground(self, x, z):
        ix, iz = self.idx(x, z)
        ix = min(max(ix, 0), self.N - 1)
        iz = min(max(iz, 0), self.N - 1)
        return float(self.H[iz, ix])

    # -------- stamps
    def _apply(self, sl, top, mask, col, side=None, emi=None):
        cur = self.H[sl]
        up = mask & (top > cur)
        self.H[sl] = np.where(up, top, cur)
        self.ALB[sl] = np.where(up[..., None], col(up) if callable(col) else col, self.ALB[sl])
        if side is not None:
            self.SIDE[sl] = np.where(up[..., None], side(up) if callable(side) else side, self.SIDE[sl])
        if emi is not None:
            self.EMI[sl] = np.where(up[..., None], emi(up) if callable(emi) else emi, self.EMI[sl])

    def cone(self, x, z, r, h, col, side=None, tiers=0.0, base=None, emi=None):
        sl = self.window(x, z, r)
        if sl is None:
            return
        b = self.ground(x, z) if base is None else base
        d = np.hypot(self.XG[sl] - x, self.ZG[sl] - z)
        prof = h * (1 - d / r)
        if tiers:
            prof = prof + h * 0.05 * np.sin(prof / h * tiers * 6.283)
        mask = d < r
        self._apply(sl, b + np.maximum(prof, 0), mask, col, side, emi)

    def dome(self, x, z, r, h, lift, col, side=None, squash=1.0, base=None, emi=None):
        sl = self.window(x, z, r)
        if sl is None:
            return
        b = self.ground(x, z) if base is None else base
        d = np.hypot(self.XG[sl] - x, self.ZG[sl] - z)
        prof = lift + h * np.sqrt(np.maximum(1 - (d / r) ** 2, 0)) * squash
        mask = d < r
        self._apply(sl, b + prof, mask, col, side, emi)

    def box(self, x, z, w, dpt, h, col, side=None, rot=0.0, base=None, emi=None, roof=None):
        r = np.hypot(w, dpt)
        sl = self.window(x, z, r)
        if sl is None:
            return
        b = self.ground(x, z) if base is None else base
        c, s = np.cos(rot), np.sin(rot)
        dx = self.XG[sl] - x
        dz = self.ZG[sl] - z
        u = dx * c + dz * s
        v = -dx * s + dz * c
        mask = (np.abs(u) < w / 2) & (np.abs(v) < dpt / 2)
        top = b + h
        if roof is not None:  # gabled roof along u
            top = b + h + roof * (1 - np.abs(v) / (dpt / 2))
        self._apply(sl, top, mask, col, side, emi)

    def cyl(self, x, z, r, h, col, side=None, base=None, emi=None, taper=0.0):
        sl = self.window(x, z, r)
        if sl is None:
            return
        b = self.ground(x, z) if base is None else base
        d = np.hypot(self.XG[sl] - x, self.ZG[sl] - z)
        mask = d < r
        top = b + h - taper * (d / r) * h
        self._apply(sl, top, mask, col, side, emi)

    def blob(self, x, z, r, h, col, side=None, noise=0.25, seed=0, base=None, emi=None):
        sl = self.window(x, z, r)
        if sl is None:
            return
        b = self.ground(x, z) if base is None else base
        d = np.hypot(self.XG[sl] - x, self.ZG[sl] - z)
        n = noise2(self.XG[sl] * 0.6 + seed, self.ZG[sl] * 0.6, seed) - 0.5
        prof = h * np.sqrt(np.maximum(1 - (d / r) ** 2, 0)) * (1 + n * noise * 2)
        self._apply(sl, b + np.maximum(prof, 0), d < r, col, side, emi)

    # -------- finish
    def terrain(self, smooth=0.6):
        H = blur(self.H, smooth) if smooth else self.H
        t = Terrain(H, self.hx, self.z0, self.z1)
        self.T = t
        # cheap ambient occlusion: how far the surface sits below its neighbourhood
        self.AO = np.clip(0.62 + (self.H - blur(self.H, 6)) * 0.35, 0.25, 1.0).astype(np.float32)
        return t


def _sample_nearest(arr, T, x, z):
    """Bilinear lookup of a (N,N) or (N,N,C) map at world (x, z)."""
    u, v = T.to_idx(x, z)
    u = np.clip(u, 0, T.n - 1.001)
    v = np.clip(v, 0, T.n - 1.001)
    iu = u.astype(np.int32)
    iv = v.astype(np.int32)
    fu = (u - iu)
    fv = (v - iv)
    if arr.ndim == 3:
        fu = fu[..., None]
        fv = fv[..., None]
    a = arr[iv, iu]
    b = arr[iv, iu + 1]
    c = arr[iv + 1, iu]
    d = arr[iv + 1, iu + 1]
    return (a * (1 - fu) + b * fu) * (1 - fv) + (c * (1 - fu) + d * fu) * fv


class Look:
    def __init__(self, sun_dir, sun_col, amb_sky, amb_ground, sky_fn, fog_col, fog_density, fog_height=0.0, exposure=1.0):
        self.sun_dir = norm(np.array(sun_dir, np.float32))
        self.sun_col = np.array(sun_col, np.float32)
        self.amb_sky = np.array(amb_sky, np.float32)
        self.amb_ground = np.array(amb_ground, np.float32)
        self.sky_fn = sky_fn
        self.fog_col = np.array(fog_col, np.float32)
        self.fog_density = fog_density
        self.exposure = exposure


def slope_pre(n):
    return smoothstep(0.80, 0.45, n[..., 1])


def shade_hits(world, look, p, n, t, d, shadows=True, spec=0.0, wetness=None):
    T = world.T
    alb_top = _sample_nearest(world.ALB, T, p[..., 0], p[..., 2])
    alb_side = _sample_nearest(world.SIDE, T, p[..., 0], p[..., 2])
    emi = _sample_nearest(world.EMI, T, p[..., 0], p[..., 2])
    band = _sample_nearest(world.BAND, T, p[..., 0], p[..., 2])
    if band.max() > 0:
        win = smoothstep(0.30, 0.55, np.sin(p[..., 1] * 1.9) * np.sin(p[..., 0] * 2.3 + p[..., 2] * 2.3)) 
        emi = emi * (1 - band[..., None]) + emi * (win * band)[..., None] * (1 - slope_pre(n))[..., None] + emi * 0.0
    ao = _sample_nearest(world.AO, T, p[..., 0], p[..., 2])
    slope = smoothstep(0.80, 0.45, n[..., 1])[..., None]
    alb = mix(alb_top, alb_side, slope)
    ndl = (n * look.sun_dir).sum(-1)
    diff = smoothstep(-0.1, 0.9, ndl)
    shadow = np.ones_like(diff)
    if shadows:
        for k in range(1, 22):
            q = p + look.sun_dir * (k * 1.4) + np.array([0, 0.6, 0], np.float32)
            hq, ins = T.height(q[..., 0], q[..., 2])
            blocked = (hq > q[..., 1]) & ins
            shadow = np.where(blocked, shadow * 0.0 + np.minimum(shadow, 0.18 + 0.02 * k), shadow)
    amb = mix(look.amb_ground, look.amb_sky, (n[..., 1] * 0.5 + 0.5)[..., None])
    sun = look.sun_col * (diff * shadow)[..., None]
    col = alb * (sun + amb * ao[..., None]) + emi
    if spec:
        h = norm(look.sun_dir - d)
        sp = np.clip((n * h).sum(-1), 0, 1) ** 60 * shadow
        col = col + look.sun_col * (sp * spec)[..., None]
    # rim light on edges facing away from the sun
    rim = np.clip(1 - np.abs((n * -d).sum(-1)), 0, 1) ** 3 * 0.18
    col = col + look.amb_sky * rim[..., None]
    return col


def apply_fog(col, t, p, d, look, hit):
    dist = np.where(hit, t, 700.0)
    f = 1 - np.exp(-dist * look.fog_density)
    sd = np.clip((d * look.sun_dir).sum(-1), 0, 1)
    fog_col = look.fog_col + look.sun_col * (sd ** 6 * 0.25)[..., None]
    return mix(col, fog_col, f[..., None])


def render(world, look, cam_pos, pitch, W, H, fov=1.1, yaw=0.0, steps=150, tmax=480, water=None, spec=0.0, shadows=True):
    """water = dict(y=level, shallow=rgb, deep=rgb, clarity=float, ripple=float)"""
    T = world.T
    o, d = camera_rays(W, H, cam_pos, pitch, fov, yaw)
    sky_col = look.sky_fn(d)
    t, hit = march(T, o, d, steps=steps, tmax=tmax)
    p = o + d * t[..., None]
    n = T.normal(p[..., 0], p[..., 2])
    col = shade_hits(world, look, p, n, t, d, shadows=shadows, spec=spec)
    depth = np.where(hit, t, 1e4).astype(np.float32)
    img = np.where(hit[..., None], apply_fog(col, t, p, d, look, hit), sky_col)
    if water is not None:
        wy = water['y']
        with np.errstate(divide='ignore', invalid='ignore'):
            tw = (wy - o[..., 1]) / d[..., 1]
        wmask = (d[..., 1] < 0) & (tw > 0) & (tw < np.where(hit, t, 1e9))
        if wmask.any():
            pw = o + d * np.where(wmask, tw, 0)[..., None]
            # ripples distort the normal
            rp = water.get('ripple', 0.04)
            nx = (noise2(pw[..., 0] * 0.35, pw[..., 2] * 0.35, 3) - 0.5) * rp
            nz = (noise2(pw[..., 0] * 0.35 + 9, pw[..., 2] * 0.35, 4) - 0.5) * rp
            nw = norm(np.stack([nx, np.ones_like(nx), nz], -1))
            rd = d - 2 * (d * nw).sum(-1, keepdims=True) * nw
            rd[..., 1] = np.abs(rd[..., 1])
            # reflected scene (second march on the water pixels only)
            idx = np.where(wmask)
            ro = pw[idx]
            rdir = norm(rd[idx])
            sky_r = look.sky_fn(rdir[None, ...])[0]
            tr, hr = march(T, ro[None, ...] + np.array([0, 0.05, 0], np.float32), rdir[None, ...], steps=90, tmax=380)
            pr = ro[None, ...] + rdir[None, ...] * tr[..., None]
            nr = T.normal(pr[..., 0], pr[..., 2])
            cr = shade_hits(world, look, pr, nr, tr, rdir[None, ...], shadows=False)
            cr = apply_fog(cr, tr, pr, rdir[None, ...], look, hr)
            refl = np.where(hr[..., None], cr, sky_r[None, ...])[0]
            # what is below the water
            hb, _ = T.height(pw[..., 0], pw[..., 2])
            depth_w = np.clip(wy - hb, 0, 60)
            below_alb = _sample_nearest(world.ALB, T, pw[..., 0], pw[..., 2])
            absorb = np.exp(-depth_w[..., None] * water.get('clarity', 0.18))
            under = mix(water['deep'], below_alb * water['shallow'], absorb)
            fres = (0.04 + 0.96 * (1 - np.clip(-(d * nw).sum(-1), 0, 1)) ** 4)[..., None] * water.get('reflect', 1.0)
            wcol = mix(under, np.zeros_like(under), 0)
            wcol[idx] = mix(under[idx], refl, fres[idx])
            # sun glitter
            sdir = look.sun_dir
            sp = np.clip((norm(sdir - d) * nw).sum(-1), 0, 1) ** 220
            wcol = wcol + look.sun_col * (sp * water.get('glitter', 2.0))[..., None]
            wcol = apply_fog(wcol, np.where(wmask, tw, 0), pw, d, look, wmask)
            img = np.where(wmask[..., None], wcol, img)
            depth = np.where(wmask, tw, depth).astype(np.float32)
    return img, depth, o, d


# ----------------------------------------------------------- 2D extras ----
def project(cam_pos, pitch, yaw, W, H, fov, pts):
    """world points (M,3) -> pixel x, y and depth along the view axis."""
    cp, sp = np.cos(pitch), np.sin(pitch)
    cy, sy = np.cos(yaw), np.sin(yaw)
    v = pts - np.array(cam_pos, np.float32)
    # inverse of yaw then pitch
    x = v[:, 0] * cy - v[:, 2] * sy
    z = v[:, 0] * sy + v[:, 2] * cy
    y = v[:, 1]
    y2 = y * cp + z * sp
    z2 = -y * sp + z * cp
    f = 1.0 / np.tan(fov / 2)
    with np.errstate(divide='ignore', invalid='ignore'):
        sx = x / z2 * f / (W / H)
        sy_ = y2 / z2 * f
    px = (sx + 1) / 2 * W
    py = (1 - sy_) / 2 * H
    return px, py, z2


def add_particles(img, depth, cam, pts, sizes, colors, glow=3.0, alphas=None, seed=0):
    """Glowing dots at 3D points with depth test. cam = (pos, pitch, yaw, W, H, fov)."""
    pos, pitch, yaw, W, H, fov = cam
    px, py, z = project(pos, pitch, yaw, W, H, fov, pts)
    layer = np.zeros((H, W, 3), np.float32)
    f = 1.0 / np.tan(fov / 2)
    for i in range(len(pts)):
        if z[i] <= 0.5 or not (0 <= px[i] < W and 0 <= py[i] < H):
            continue
        ix, iy = int(px[i]), int(py[i])
        if depth[iy, ix] < z[i] * 1.0:
            continue
        r = max(1.0, sizes[i] * f / z[i] * H * 0.5)
        rr = int(r * glow) + 2
        y0, y1, x0, x1 = max(iy - rr, 0), min(iy + rr + 1, H), max(ix - rr, 0), min(ix + rr + 1, W)
        yy, xx = np.mgrid[y0:y1, x0:x1]
        dd = np.hypot(xx - px[i], yy - py[i]) / r
        a = 1.0 if alphas is None else alphas[i]
        g = (np.exp(-dd * dd * 0.6) * 0.9 + np.exp(-dd * 0.9) * 0.18) * a
        layer[y0:y1, x0:x1] += g[..., None] * np.array(colors[i], np.float32)
    return img + layer


def god_rays(img, sun_px, strength=0.35, decay=0.96, samples=40, threshold=0.7, color=None):
    H, W = img.shape[:2]
    bright = np.clip(img - threshold, 0, None)
    small = Image.fromarray((np.clip(bright, 0, 1) * 255).astype(np.uint8)).resize((W // 2, H // 2), Image.BILINEAR)
    b = np.asarray(small).astype(np.float32) / 255
    h2, w2 = b.shape[:2]
    yy, xx = np.mgrid[0:h2, 0:w2].astype(np.float32)
    sx, sy = sun_px[0] / 2, sun_px[1] / 2
    acc = np.zeros_like(b)
    wgt = 1.0
    for k in range(samples):
        f = k / samples
        px = np.clip((xx + (sx - xx) * f * 0.9).astype(np.int32), 0, w2 - 1)
        py = np.clip((yy + (sy - yy) * f * 0.9).astype(np.int32), 0, h2 - 1)
        acc += b[py, px] * wgt
        wgt *= decay
    acc = acc / samples * 2.2
    big = np.asarray(Image.fromarray((np.clip(acc, 0, 1) * 255).astype(np.uint8)).resize((W, H), Image.BILINEAR)).astype(np.float32) / 255
    tint = np.ones(3, np.float32) if color is None else np.array(color, np.float32)
    return img + big * strength * tint


def sprite_layer(img, depth, cam, draw_fn, scale_world=1.0):
    """draw_fn(ImageDraw, project) draws RGBA shapes; occluded by terrain via depth."""
    pos, pitch, yaw, W, H, fov = cam
    ss = 2
    layer = Image.new('RGBA', (W * ss, H * ss), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)

    def proj(pts):
        pts = np.atleast_2d(np.array(pts, np.float32))
        px, py, z = project(pos, pitch, yaw, W, H, fov, pts)
        return px * ss, py * ss, z, (1.0 / np.tan(fov / 2)) * H * 0.5 * ss

    draw_fn(dr, proj)
    layer = layer.resize((W, H), Image.LANCZOS)
    arr = np.asarray(layer).astype(np.float32) / 255
    return arr


def composite_rgba(img, rgba, mask=None):
    a = rgba[..., 3:4]
    if mask is not None:
        a = a * mask[..., None]
    return img * (1 - a) + rgba[..., :3] * a


def save(img, name, W=1080, H=1920, **kw):
    out = finish(img, W, H, **kw)
    path = '/tmp/claude-0/-home-user-solitaire-app/2159d7d9-0583-50a7-a346-78ef31ed353a/scratchpad/' + name
    out.save(path)
    return path
