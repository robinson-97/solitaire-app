from kit import *
rng = np.random.default_rng(4)
W, H = WPX, HPX
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
u = (xx / W - 0.5) * (W / H) * 2
v = (0.5 - yy / H) * 2
img = np.zeros((H, W, 3), np.float32) + rgb(0.015, 0.01, 0.06)
# domain-warped nebula
q = np.stack([u * 1.6, v * 1.6], -1)
w1 = fbm2(q[..., 0] + 3, q[..., 1], 6, 4)
w2 = fbm2(q[..., 0] + 4 * w1, q[..., 1] + 2 * w1, 6, 8)
w3 = fbm2(q[..., 0] + 3 * w2 + 9, q[..., 1] - 3 * w2, 6, 12)
img += rgb(0.95, 0.20, 0.60) * (np.clip(w2 - 0.25, 0, 1) ** 2.0 * 1.8)[..., None]
img += rgb(0.30, 0.35, 1.0) * (np.clip(w3 - 0.30, 0, 1) ** 2.0 * 1.7)[..., None]
img += rgb(0.10, 0.85, 0.80) * (np.clip(w1 - 0.45, 0, 1) ** 2.0 * 1.4)[..., None]
lane = smoothstep(0.50, 0.66, fbm2(q[..., 0] * 1.3 + 11, q[..., 1] * 1.3, 5, 21))
img *= (1 - lane * 0.55)[..., None]
# spiral galaxy
gx, gy = u - 0.15, (v - 0.42) * 2.1
rot = -0.6
rx = gx * np.cos(rot) - gy * np.sin(rot)
ry = gx * np.sin(rot) + gy * np.cos(rot)
r = np.hypot(rx, ry) + 1e-4
th = np.arctan2(ry, rx)
arms = 0.5 + 0.5 * np.cos(2 * (th - 3.2 * np.log(r * 3 + 0.3)))
dens = np.exp(-r * 1.9) * (0.25 + 0.95 * arms ** 2.2)
dust_n = fbm2(rx * 9, ry * 9, 4, 33)
glxy = rgb(0.75, 0.80, 1.0) * dens[..., None] * (0.7 + 0.8 * dust_n[..., None])
glxy += rgb(1.0, 0.82, 0.55) * np.exp(-r * 7.0)[..., None] * 1.6
img += glxy * 1.6
# planets
def planet(cx, cy, rad, base, band, light=(-0.6, 0.5), ring=None, seed=1):
    global img
    px, py = (u - cx) / rad, (v - cy) / rad
    rr = np.hypot(px, py)
    inside = rr < 1
    z = np.sqrt(np.clip(1 - rr * rr, 0, 1))
    nrm = np.stack([px, py, z], -1)
    L = np.array([light[0], light[1], 0.7], np.float32)
    L /= np.linalg.norm(L)
    dif = np.clip((nrm * L).sum(-1), 0, 1)
    bands = 0.5 + 0.5 * np.sin(py * 9 + fbm2(px * 3, py * 6, 4, seed) * 5)
    col = mix(rgb(*base), rgb(*band), bands[..., None])
    col = col * (0.12 + 1.15 * dif[..., None] ** 0.9)
    rim = np.clip(1 - z, 0, 1) ** 2.5
    col = col + rgb(0.5, 0.65, 1.0) * rim[..., None] * (0.25 + dif[..., None]) * 0.9
    a = smoothstep(1.0, 0.985, rr)
    img = np.where(inside[..., None], mix(img, col, a[..., None]), img)
    img += rgb(0.4, 0.5, 1.0) * (np.exp(-np.clip(rr - 1, 0, 9) * 9) * (rr > 1) * 0.35)[..., None]
    if ring:
        tilt = ring
        rx2, ry2 = px, py / 0.28
        rg = np.hypot(rx2, ry2)
        rm = smoothstep(1.35, 1.4, rg) * smoothstep(2.3, 2.2, rg) * (0.55 + 0.45 * np.sin(rg * 40))
        front = (py > 0) | ~inside
        img = np.where(((rm > 0) & front)[..., None], mix(img, rgb(0.95, 0.85, 0.65) * 0.9, (rm * 0.8)[..., None]), img)
planet(-0.42, -0.62, 0.34, (0.85, 0.45, 0.25), (1.0, 0.78, 0.5), ring=1.0, seed=3)
planet(0.52, -0.22, 0.14, (0.25, 0.45, 0.85), (0.55, 0.85, 1.0), seed=6)
planet(-0.5, 0.18, 0.09, (0.8, 0.3, 0.6), (1.0, 0.6, 0.85), seed=9)
# stars
for _ in range(900):
    sx, sy = rng.uniform(0, W), rng.uniform(0, H)
    b = rng.random() ** 3
    ix, iy = int(sx), int(sy)
    img[iy, ix] += (0.5 + 1.5 * b)
    if b > 0.6:
        rr = 8
        y0, y1, x0, x1 = max(iy - rr, 0), min(iy + rr, H), max(ix - rr, 0), min(ix + rr, W)
        gy2, gx2 = np.mgrid[y0:y1, x0:x1]
        d2 = np.hypot(gx2 - sx, gy2 - sy)
        img[y0:y1, x0:x1] += (np.exp(-d2 * 0.6) * b * 1.2)[..., None] * rgb(0.8, 0.9, 1.0)
print(save(img, 'w04.png', vignette=0.35, sat=1.15, contrast=1.08))
