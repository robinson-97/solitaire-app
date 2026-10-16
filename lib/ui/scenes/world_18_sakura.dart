import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Sakura Mountains: a serene dawn valley in flat, graphic 2D. A snowy Fuji-like
// peak in rose light, a mirror lake with a red torii, blossoming cherry trees,
// a pagoda on a wooded hill, drifting mist and a constant fall of petals.
// Light comes from the upper left everywhere (shade on the right).

const double _hy = 0.5; // horizon / lake line (fraction of height)

// palette
const _skyTop = Color(0xFFBFE3FF), _skyMid = Color(0xFFFFE5EE), _skyLow = Color(0xFFFFD2B8);
const _fuji = Color(0xFF9DB6E4), _fujiShade = Color(0xFF889FD6), _fujiRim = Color(0xFFC9C8EE);
const _snow = Color(0xFFFFFFFF), _snowRose = Color(0xFFFFD9E2), _snowShade = Color(0xFFD9E0F5);
const _range = Color(0xFF7FA3D6), _rangeShade = Color(0xFF6D90C6);
const _bloom = Color(0xFFFFB7D0), _bloomDeep = Color(0xFFFF8FB8), _bloomLight = Color(0xFFFFE3EC), _bloomUnder = Color(0xFFF07BA6);
const _red = Color(0xFFE8392E), _redRim = Color(0xFFFF7A62), _redShade = Color(0xFFBC2B2E);
const _wood = Color(0xFF4A2E2A), _woodRim = Color(0xFF6A403A), _woodShade = Color(0xFF35201F);
const _jade = Color(0xFF5FB89A), _jadeDark = Color(0xFF3F9E80), _jadeDeep = Color(0xFF2F8A70), _jadeLight = Color(0xFF9BDDB8);
const _lakeTop = Color(0xFFCDE8F8), _lakeMid = Color(0xFFA9D2EE), _lakeLow = Color(0xFF7FB5E0);
const _haze = Color(0xFFFFE5EE);

// --------------------------------------------------------------- tint (for reflections)

Color _id(Color c) => c;
Color Function(Color) _tint = _id;
Color _t(Color c) => _tint(c);
Paint _p(Color c) => Paint()..color = _t(c);

void _reflect(Canvas c, Size s, double wl, void Function() draw) {
  c
    ..save()
    ..clipRect(Rect.fromLTRB(-s.width, wl, s.width * 2, s.height * 1.3))
    ..translate(0, 2 * wl)
    ..scale(1, -1);
  _tint = (col) => mix(col, const Color(0xFFB4D9F1), 0.6);
  draw();
  _tint = _id;
  c.restore();
}

SceneSpec sakuraScene() => SceneSpec(
      focusY: -0.15,
      topShade: 0.08,
      bottomShade: 0.3,
      layers: [
        Layer.still(_sky),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.32),
        Layer.still(_fujiLayer, driftX: 0.004, driftCycles: 2),
        Layer.scroll(_mistHigh, scrollCycles: 2, bandTop: 0.4, bandBottom: 0.56),
        Layer.still(_hills, driftX: 0.008, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_lake, driftX: 0.008, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_shore, driftX: 0.014, driftCycles: 2, driftPhase: 0.15),
        Layer.scroll(_mistLow, scrollCycles: 1, scrollLeft: false, bandTop: 0.7, bandBottom: 0.9),
        Layer.still(_toriiLayer, driftX: 0.018, driftCycles: 2, driftPhase: 0.2),
        Layer.live(_water),
        Layer.still(_foreTree, driftX: 0.03, driftCycles: 2, driftPhase: 0.25, sway: 0.004, swayCycles: 5, pivot: const Alignment(0.8, 1)),
        Layer.still(_foreLeft, driftX: 0.034, driftCycles: 2, driftPhase: 0.28),
        Layer.live(_petals),
        Layer.live(_birds),
      ],
    );

// --------------------------------------------------------------- helpers

/// Cel-shaded fill: a thin lit rim on the left, flat body, flat shade on the right.
void _cel(Canvas c, Path p, Color rim, Color main, Color shade, double a, double b) {
  c.drawPath(p, _p(rim));
  c
    ..save()
    ..clipPath(p.shift(Offset(b, 0)))
    ..drawPath(p, _p(shade))
    ..save()
    ..clipPath(p.shift(Offset(-a, 0)))
    ..drawPath(p, _p(main))
    ..restore()
    ..restore();
}

/// Flat shape with a lighter lit edge at the upper left.
void _lit(Canvas c, Path p, Color main, Color light, double dx, double dy) {
  c.drawPath(p, _p(light));
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(dx, dy)), _p(main))
    ..restore();
}

Path _ribbon(List<Offset> pts, List<double> hw) {
  final l = <Offset>[], r = <Offset>[];
  for (var i = 0; i < pts.length; i++) {
    final a = pts[math.max(i - 1, 0)], b = pts[math.min(i + 1, pts.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    l.add(pts[i] - n * hw[i]);
    r.add(pts[i] + n * hw[i]);
  }
  return smoothPath([...l, ...r.reversed], closed: true);
}

void _trunk(Canvas c, List<Offset> pts, List<double> hw) {
  final p = _ribbon(pts, hw);
  _cel(c, p, _woodRim, _wood, _woodShade, hw.first * 0.5, hw.first * 0.38);
}

/// Cluster of blossom clumps. Each clump is a union of a few circles with a flat
/// darker underside and a flat lighter crown, sorted top to bottom.
void _canopy(Canvas c, Offset o, double rx, double ry, {int seed = 1, int n = 9, double puff = 0, bool dots = true}) {
  final rg = rng(seed);
  final base = puff > 0 ? puff : math.min(rx, ry) * 0.62;
  final clumps = <(Offset, double)>[];
  for (var i = 0; i < n; i++) {
    final a = tau * i / n + rg.nextDouble() * 0.7;
    final d = i == 0 ? 0.0 : 0.5 + 0.5 * rg.nextDouble();
    clumps.add((o + Offset(math.cos(a) * rx * d * 0.8, math.sin(a) * ry * d * 0.8), base * (0.8 + rg.nextDouble() * 0.5)));
  }
  clumps.sort((a, b) => a.$1.dy.compareTo(b.$1.dy));
  for (final (pos, r) in clumps) {
    final subs = <(Offset, double)>[];
    for (var j = 0; j < 4; j++) {
      final a = tau * j / 4 + rg.nextDouble();
      subs.add((pos + Offset(math.cos(a), math.sin(a) * 0.8) * r * 0.5, r * (0.5 + rg.nextDouble() * 0.2)));
    }
    subs.add((pos, r * 0.68));
    for (final (q, rr) in subs) {
      c.drawCircle(q, rr, _p(_bloomUnder));
    }
    for (final (q, rr) in subs) {
      c.drawCircle(q + Offset(-rr * 0.1, -rr * 0.16), rr * 0.9, _p(_bloom));
    }
    for (final (q, rr) in subs) {
      if (q.dy <= pos.dy + r * 0.1) c.drawCircle(q + Offset(-rr * 0.26, -rr * 0.38), rr * 0.5, _p(_bloomLight));
    }
  }
  if (dots) {
    for (var i = 0; i < n * 4; i++) {
      final (pos, r) = clumps[rg.nextInt(clumps.length)];
      final a = rg.nextDouble() * tau, d = 0.3 + rg.nextDouble() * 0.8;
      final q = pos + Offset(math.cos(a), math.sin(a)) * r * d;
      c.drawCircle(q, 1.3 + rg.nextDouble() * 1.3, _p(i % 3 == 0 ? _bloomDeep : _bloomLight));
    }
  }
}

void _sakuraTree(Canvas c, Offset base, double h, int seed, {double lean = 0}) {
  final top = Offset(base.dx + lean * h * 0.25, base.dy - h * 0.62);
  _trunk(c, [base, Offset(base.dx + lean * h * 0.05, base.dy - h * 0.25), top], [h * 0.05, h * 0.035, h * 0.022]);
  _canopy(c, top + Offset(0, -h * 0.12), h * 0.4, h * 0.3, seed: seed, n: 7, dots: false);
}

void _roof(Canvas c, double cx, double y, double rw, double rh, Color col, Color sh) {
  final p = Path()
    ..moveTo(cx - rw, y - rh * 0.25)
    ..quadraticBezierTo(cx - rw * 0.62, y + rh * 0.45, cx, y + rh * 0.45)
    ..quadraticBezierTo(cx + rw * 0.62, y + rh * 0.45, cx + rw, y - rh * 0.25)
    ..quadraticBezierTo(cx + rw * 0.5, y - rh * 0.05, cx + rw * 0.2, y - rh)
    ..lineTo(cx - rw * 0.2, y - rh)
    ..quadraticBezierTo(cx - rw * 0.5, y - rh * 0.05, cx - rw, y - rh * 0.25)
    ..close();
  c.drawPath(p, _p(col));
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(cx + rw * 0.12, y - rh * 1.2, cx + rw * 1.2, y + rh), _p(sh))
    ..restore();
}

void _pagoda(Canvas c, Offset base, double h) {
  const tiers = 5;
  final u = h / 4.1;
  final cx = base.dx;
  var y = base.dy;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - u * 1.2, y - u * 0.3, u * 2.4, u * 0.3), Radius.circular(u * 0.1)), _p(const Color(0xFFD8CCE0)));
  y -= u * 0.3;
  for (var i = 0; i < tiers; i++) {
    final sc = 1 - i * 0.14;
    final rw = u * 1.4 * sc, bw = rw * 1.05, bh = u * 0.62 * sc, rh = u * 0.5 * sc;
    final body = Rect.fromLTWH(cx - bw / 2, y - bh, bw, bh);
    c.drawRect(body, _p(const Color(0xFFFBEFEA)));
    c.drawRect(Rect.fromLTWH(cx + bw * 0.12, y - bh, bw * 0.38, bh), _p(const Color(0xFFE6D1D8)));
    c.drawRect(Rect.fromLTWH(cx - bw / 2, y - bh, bw * 0.1, bh), _p(_red));
    c.drawRect(Rect.fromLTWH(cx + bw / 2 - bw * 0.1, y - bh, bw * 0.1, bh), _p(_redShade));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y - bh * 0.5), width: bw * 0.2, height: bh * 0.5), Radius.circular(bw * 0.04)), _p(i.isOdd ? const Color(0xFFFFD98A) : const Color(0xFF8B6E8E)));
    y -= bh;
    _roof(c, cx, y + rh * 0.12, rw, rh, const Color(0xFF6F6BAA), const Color(0xFF5C5896));
    y -= rh * 0.55;
  }
  c.drawRect(Rect.fromLTWH(cx - u * 0.04, y - u * 0.9, u * 0.08, u * 0.9), _p(_wood));
  for (var i = 0; i < 3; i++) {
    c.drawCircle(Offset(cx, y - u * (0.25 + i * 0.22)), u * (0.16 - i * 0.03), _p(const Color(0xFFF0C27A)));
  }
}

/// A smooth wooded hill: returns sampled points of the crest.
List<Offset> _bump(Size s, double x0, double x1, double sx, double sy, double by, {double pw = 0.85}) {
  final pts = <Offset>[];
  for (var x = x0; x <= x1; x += 5) {
    final t = x < sx ? (sx - x) / (sx - x0) : (x - sx) / (x1 - sx);
    final f = math.pow(0.5 + 0.5 * math.cos(math.pi * t.clamp(0.0, 1.0)), pw).toDouble();
    pts.add(Offset(x, by - (by - sy) * f));
  }
  return pts;
}

double _yOf(List<Offset> pts, double x) {
  var best = pts.first;
  for (final p in pts) {
    if ((p.dx - x).abs() < (best.dx - x).abs()) best = p;
  }
  return best.dy;
}

Path _fillOf(List<Offset> pts, double bottom) => smoothPath(pts)
  ..lineTo(pts.last.dx, bottom)
  ..lineTo(pts.first.dx, bottom)
  ..close();

void _pills(Canvas c, Size s, int seed, double y0, double y1, int n, Color col, double a, double hMin, double hMax, double wMin, double wMax) {
  final r = rng(seed);
  final paint = Paint()..color = col.withValues(alpha: a);
  for (var i = 0; i < n; i++) {
    final wd = (wMin + r.nextDouble() * (wMax - wMin)) * s.width / 390;
    final hh = (hMin + r.nextDouble() * (hMax - hMin)) * s.width / 390;
    final x = (i + 0.2 + r.nextDouble() * 0.6) / n * s.width;
    final y = (y0 + r.nextDouble() * (y1 - y0)) * s.height;
    for (final dx in [-s.width, 0.0, s.width]) {
      final rc = Rect.fromCenter(center: Offset(x + dx, y), width: wd, height: hh);
      if (rc.right < -2 || rc.left > s.width + 2) continue;
      c.drawRRect(RRect.fromRectAndRadius(rc, Radius.circular(hh / 2)), paint);
    }
  }
}

// --------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_skyTop, _skyMid, _skyLow], const [0.0, 0.3, 0.52]);
  final w = s.width;
  final o = Offset(w * 0.17, s.height * 0.15);
  final r = w * 0.052;
  c.drawCircle(o, r * 5.2, Paint()..color = const Color(0xFFFFE0D2).withValues(alpha: 0.18));
  c.drawCircle(o, r * 3.5, Paint()..color = const Color(0xFFFFD0D8).withValues(alpha: 0.26));
  c.drawCircle(o, r * 2.2, Paint()..color = const Color(0xFFFFE6E4).withValues(alpha: 0.4));
  c.drawCircle(o, r, Paint()..color = const Color(0xFFFFF8EE));
}

void _cloudsBack(Canvas c, Size s) {
  final w = s.width, h = s.height;
  const shade = Color(0xFFF6D3E1);
  flatCloud(c, Offset(w * 0.3, h * 0.105), w * 0.42, color: const Color(0xFFFFFFFF), shade: shade, seed: 3, puff: 1.15);
  flatCloud(c, Offset(w * 0.78, h * 0.2), w * 0.3, color: const Color(0xFFFFF6F8), shade: shade, seed: 8, puff: 1.0);
  flatCloud(c, Offset(w * 0.55, h * 0.275), w * 0.36, color: const Color(0xFFFFFFFF), shade: const Color(0xFFFFD9DF), seed: 12, puff: 0.9);
  flatCloud(c, Offset(w * 0.07, h * 0.255), w * 0.22, color: const Color(0xFFFFF6F8), shade: shade, seed: 5, puff: 0.9);
}

// --------------------------------------------------------------- Fuji

void _fujiDraw(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final px = w * 0.42, py = h * 0.15, by = h * _hy + 6;
  final half = w * 0.68;
  final body = Path()
    ..moveTo(px - half, by)
    ..quadraticBezierTo(px - w * 0.4, by - h * 0.03, px - w * 0.05, py + h * 0.03)
    ..quadraticBezierTo(px, py - h * 0.014, px + w * 0.05, py + h * 0.03)
    ..quadraticBezierTo(px + w * 0.4, by - h * 0.03, px + half, by)
    ..close();
  _lit(c, body, _fuji, _fujiRim, w * 0.03, 0);
  // shade face on the right
  final shade = smoothPath([
    Offset(px + w * 0.004, py - h * 0.02),
    Offset(px + w * 0.012, py + h * 0.07),
    Offset(px + w * 0.05, py + h * 0.17),
    Offset(px + w * 0.11, py + h * 0.26),
    Offset(px + w * 0.19, by),
    Offset(px + half * 1.2, by + 20),
    Offset(px + half * 1.2, py - h * 0.1),
  ], closed: true);
  c
    ..save()
    ..clipPath(body)
    ..drawPath(shade, _p(_fujiShade));
  c.restore();
  // snow cap with soft drips
  final sy = py + h * 0.105;
  const drips = [0.0, 0.035, 0.005, 0.07, 0.01, 0.045, 0.0, 0.06, 0.015, 0.04, 0.0];
  final edge = <Offset>[];
  for (var i = 0; i < drips.length; i++) {
    final x = px - w * 0.25 + i * w * 0.05;
    edge.add(Offset(x, sy + drips[i] * h + (i.isEven ? -h * 0.004 : h * 0.006)));
  }
  final cap = smoothPath([Offset(px - w * 0.3, py - h * 0.1), ...edge, Offset(px + w * 0.3, py - h * 0.1)], closed: true);
  c
    ..save()
    ..clipPath(body)
    ..clipPath(cap)
    ..drawRect(Rect.fromLTRB(px - w * 0.4, py - h * 0.1, px + w * 0.4, sy + h * 0.2), _p(_snow))
    ..drawPath(
        smoothPath([Offset(px - w * 0.02, py - h * 0.02), Offset(px - w * 0.05, py + h * 0.05), Offset(px - w * 0.1, py + h * 0.12), Offset(px - w * 0.4, py + h * 0.2), Offset(px - w * 0.4, py - h * 0.1)], closed: true),
        _p(_snowRose))
    ..drawPath(shade, _p(_snowShade))
    ..restore();
  // base haze
  final hz = Rect.fromLTRB(0, by - h * 0.14, w, by);
  c.drawRect(hz, Paint()..shader = verticalPaint(hz, [_t(_haze).withValues(alpha: 0), _t(_haze).withValues(alpha: 0.85)]).shader);
}

void _rangeDraw(Canvas c, Size s) {
  final by = s.height * _hy + 6;
  final r1 = Ridge(s, y: 0.468, amp: 0.026, freq: 1.7, seed: 9, octaves: 2, sharp: 0.3);
  flatMountains(c, r1, _t(_range), _t(_rangeShade), bottomY: by);
}

void _fujiLayer(Canvas c, Size s) {
  _fujiDraw(c, s);
  _rangeDraw(c, s);
}

// --------------------------------------------------------------- mist

void _mistHigh(Canvas c, Size s) {
  _pills(c, s, 4, 0.435, 0.5, 6, const Color(0xFFFFF1F5), 0.55, 10, 18, 110, 250);
  _pills(c, s, 9, 0.45, 0.52, 5, const Color(0xFFFFFFFF), 0.4, 8, 14, 90, 200);
}

void _mistLow(Canvas c, Size s) {
  _pills(c, s, 14, 0.74, 0.9, 4, const Color(0xFFFFFFFF), 0.3, 7, 12, 140, 300);
}

// --------------------------------------------------------------- hills with pagoda

void _hillsDraw(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final by = h * _hy + 6;
  final r = rng(33);
  // left hill with pagoda
  final lh = _bump(s, -w * 0.12, w * 0.56, w * 0.13, h * 0.385, by, pw: 0.6);
  _lit(c, _fillOf(lh, by + 10), mix(_jade, _haze, 0.28), mix(_jadeLight, _haze, 0.35), 4, 5);
  for (var x = -w * 0.06; x < w * 0.5; x += 17 + r.nextDouble() * 14) {
    if ((x - w * 0.13).abs() < w * 0.07) continue;
    final y = _yOf(lh, x) + 3;
    if (r.nextDouble() < 0.4) {
      flatPine(c, Offset(x, y), h * 0.05, color: _t(mix(_jadeDark, _haze, 0.2)), shade: _t(mix(_jadeDeep, _haze, 0.2)));
    } else {
      _sakuraTree(c, Offset(x, y), h * (0.045 + r.nextDouble() * 0.02), r.nextInt(99), lean: r.nextDouble() - 0.5);
    }
  }
  _pagoda(c, Offset(w * 0.13, _yOf(lh, w * 0.13) + 2), h * 0.13);
  // right hill, rounder and darker
  final rh = _bump(s, w * 0.5, w * 1.14, w * 0.9, h * 0.43, by, pw: 0.8);
  _lit(c, _fillOf(rh, by + 10), mix(_jadeDark, _haze, 0.2), mix(_jade, _haze, 0.3), 4, 5);
  for (var x = w * 0.58; x < w * 1.1; x += 15 + r.nextDouble() * 12) {
    final y = _yOf(rh, x) + 3;
    if (r.nextDouble() < 0.35) {
      flatPine(c, Offset(x, y), h * 0.055, color: _t(mix(_jadeDeep, _haze, 0.1)), shade: _t(darken(_jadeDeep, 0.05)));
    } else {
      _sakuraTree(c, Offset(x, y), h * (0.05 + r.nextDouble() * 0.025), r.nextInt(99), lean: r.nextDouble() - 0.5);
    }
  }
}

void _hills(Canvas c, Size s) => _hillsDraw(c, s);

// --------------------------------------------------------------- lake

void _lake(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final hy = h * _hy;
  final rect = Rect.fromLTRB(-w * 0.2, hy, w * 1.2, h * 1.2);
  c.drawRect(rect, verticalPaint(rect, const [_lakeTop, _lakeMid, _lakeLow], const [0.0, 0.4, 1.0]));
  _reflect(c, s, hy, () {
    _fujiLayer(c, s);
    _hillsDraw(c, s);
  });
  // ripple cuts across the reflection
  final r = rng(5);
  for (var y = hy + 5; y < h * 1.05; y += 7 + (y - hy) * 0.012) {
    final f = ((y - hy) / (h - hy)).clamp(0.0, 1.0);
    final col = Color.lerp(_lakeTop, _lakeMid, (f * 2.2).clamp(0.0, 1.0))!;
    for (var i = 0; i < 5; i++) {
      final x = r.nextDouble() * w * 1.1 - w * 0.05;
      final wd = (18 + r.nextDouble() * 60) * (1 + f);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: wd, height: 2.4 + f * 1.4), const Radius.circular(2)), Paint()..color = col.withValues(alpha: 0.75));
    }
  }
  // sun path on the water
  for (var i = 0; i < 16; i++) {
    final y = hy + 14 + i * (h * 0.028) + i * i * 0.3;
    final wd = w * (0.22 - i * 0.008) * (0.7 + 0.3 * math.sin(i * 1.7));
    final cx = w * 0.17 + math.sin(i * 1.3) * 10;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y), width: wd, height: 3.4), const Radius.circular(2)), Paint()..color = const Color(0xFFFFF0E6).withValues(alpha: 0.78));
  }
}

// --------------------------------------------------------------- shore, torii, banks

void _isle(Canvas c, Size s, double x0, double x1, double sx, double sy, double wl, int seed, Color col, Color light) {
  final pts = _bump(s, x0, x1, sx, sy, wl, pw: 0.9);
  _lit(c, _fillOf(pts, wl + 4), col, light, 3, 4);
  final r = rng(seed);
  for (var x = x0 + 14; x < x1 - 10; x += 14 + r.nextDouble() * 12) {
    final y = _yOf(pts, x) + 2;
    if (r.nextDouble() < 0.35) {
      flatPine(c, Offset(x, y), s.height * 0.06, color: _t(_jadeDeep), shade: _t(darken(_jadeDeep, 0.05)));
    } else {
      _sakuraTree(c, Offset(x, y), s.height * (0.055 + r.nextDouble() * 0.03), r.nextInt(99), lean: r.nextDouble() - 0.5);
    }
  }
}

void _shore(Canvas c, Size s) {
  final w = s.width, h = s.height;
  void draw() {
    _isle(c, s, -w * 0.14, w * 0.4, w * 0.12, h * 0.545, h * 0.585, 3, _jadeDark, _jade);
    _isle(c, s, w * 0.66, w * 1.16, w * 0.92, h * 0.55, h * 0.6, 6, _jadeDark, _jade);
  }

  draw();
  _reflect(c, s, h * 0.585, () => _isle(c, s, -w * 0.14, w * 0.4, w * 0.12, h * 0.545, h * 0.585, 3, _jadeDark, _jade));
  _reflect(c, s, h * 0.6, () => _isle(c, s, w * 0.66, w * 1.16, w * 0.92, h * 0.55, h * 0.6, 6, _jadeDark, _jade));
  // restore waterline sparkle edge
  c.drawRect(Rect.fromLTWH(-w * 0.2, h * 0.585 - 1, w * 0.7, 2), Paint()..color = _lakeTop.withValues(alpha: 0.7));
}

void _toriiDraw(Canvas c, Offset base, double h) {
  final wd = h * 1.12;
  final pw = h * 0.085;
  final topY = base.dy - h;
  for (final side in [-1, 1]) {
    final cx = base.dx + side * wd / 2;
    final tx = cx - side * h * 0.018;
    final p = Path()
      ..moveTo(cx - pw * 0.58, base.dy)
      ..lineTo(tx - pw * 0.46, topY + h * 0.08)
      ..lineTo(tx + pw * 0.46, topY + h * 0.08)
      ..lineTo(cx + pw * 0.58, base.dy)
      ..close();
    _cel(c, p, _redRim, _red, _redShade, pw * 0.22, pw * 0.3);
    final foot = RRect.fromRectAndRadius(Rect.fromLTRB(cx - pw * 0.72, base.dy - h * 0.075, cx + pw * 0.72, base.dy + h * 0.005), Radius.circular(pw * 0.2));
    _cel(c, Path()..addRRect(foot), _woodRim, _wood, _woodShade, pw * 0.1, pw * 0.2);
  }
  // nuki (tie beam)
  final nukiY = topY + h * 0.3;
  final nuki = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - wd / 2 - pw * 1.0, nukiY, base.dx + wd / 2 + pw * 1.0, nukiY + h * 0.055), Radius.circular(h * 0.012)));
  _cel(c, nuki, _redRim, _red, _redShade, 2, h * 0.012);
  // plaque
  final plaque = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx, topY + h * 0.2), width: h * 0.075, height: h * 0.2), Radius.circular(h * 0.01)));
  _cel(c, plaque, _woodRim, _wood, _woodShade, 1.5, 2.5);
  // shimaki
  final shim = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - wd / 2 - pw * 1.35, topY + h * 0.1, base.dx + wd / 2 + pw * 1.35, topY + h * 0.155), Radius.circular(h * 0.01)));
  _cel(c, shim, _redRim, _red, _redShade, 2, h * 0.014);
  // kasagi (curved top beam)
  final half = wd / 2 + pw * 2.3;
  final cx = base.dx;
  final kas = Path()
    ..moveTo(cx - half, topY - h * 0.02)
    ..quadraticBezierTo(cx - half * 0.5, topY + h * 0.03, cx, topY + h * 0.028)
    ..quadraticBezierTo(cx + half * 0.5, topY + h * 0.03, cx + half, topY - h * 0.02)
    ..quadraticBezierTo(cx + half * 1.0, topY + h * 0.0, cx + half * 0.94, topY + h * 0.018)
    ..quadraticBezierTo(cx + half * 0.5, topY + h * 0.1, cx, topY + h * 0.1)
    ..quadraticBezierTo(cx - half * 0.5, topY + h * 0.1, cx - half * 0.94, topY + h * 0.018)
    ..quadraticBezierTo(cx - half * 1.0, topY + h * 0.0, cx - half, topY - h * 0.02)
    ..close();
  _cel(c, kas, _woodRim, _wood, _woodShade, 2.5, h * 0.05);
}

void _toriiLayer(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final base = Offset(w * 0.54, h * 0.925);
  final th = h * 0.185;
  // reflection first (lake colour tinted)
  _reflect(c, s, base.dy, () => _toriiDraw(c, base, th));
  // ripple lines at the feet
  for (final side in [-1, 1]) {
    final fx = base.dx + side * th * 0.56;
    for (var i = 0; i < 2; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(fx, base.dy + 2), width: th * (0.26 + i * 0.16), height: th * (0.05 + i * 0.03)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.7 - i * 0.25));
    }
  }
  _toriiDraw(c, base, th);
  // lily pads with a lotus blossom
  for (final (x, y, sz, fl) in [(0.66, 0.975, 0.07, true), (0.58, 0.96, 0.045, false), (0.75, 0.955, 0.05, false)]) {
    final o = Offset(w * x, h * y);
    final rw = w * sz, rh = rw * 0.34;
    final pad = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + rw * 0.9, o.dy - rh * 0.5)
      ..arcTo(Rect.fromCenter(center: o, width: rw * 2, height: rh * 2), -0.22, tau - 0.5, false)
      ..close();
    c.drawPath(pad, Paint()..color = _jade);
    c.drawPath(pad.shift(const Offset(2, 1.5)), Paint()..color = _jadeDeep.withValues(alpha: 0.0));
    c.drawOval(Rect.fromCenter(center: o + Offset(-rw * 0.2, -rh * 0.25), width: rw * 1.1, height: rh * 0.9), Paint()..color = _jadeLight.withValues(alpha: 0.55));
    if (fl) {
      for (final (dx, ang) in [(-0.2, -0.5), (0.2, 0.5), (0.0, 0.0)]) {
        c
          ..save()
          ..translate(o.dx + rw * dx, o.dy - rh * 0.3)
          ..rotate(ang);
        c.drawPath(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(-rw * 0.2, -rw * 0.22, 0, -rw * 0.46)
              ..quadraticBezierTo(rw * 0.2, -rw * 0.22, 0, 0),
            Paint()..color = dx == 0 ? _bloomLight : _bloom);
        c.restore();
      }
    }
  }
  // stepping stones leading to the gate
  const stones = [(0.24, 0.972, 0.1), (0.33, 0.962, 0.085), (0.41, 0.952, 0.07), (0.47, 0.944, 0.058)];
  for (final (x, y, sz) in stones) {
    final o = Offset(w * x, h * y);
    final wdt = w * sz, ht = wdt * 0.38;
    c.drawOval(Rect.fromCenter(center: o + Offset(0, ht * 0.35), width: wdt * 1.15, height: ht * 0.9), Paint()..color = const Color(0xFF8FB4D6).withValues(alpha: 0.7));
    c.drawOval(Rect.fromCenter(center: o, width: wdt, height: ht), Paint()..color = const Color(0xFF9C97BE));
    c.drawOval(Rect.fromCenter(center: o + Offset(-wdt * 0.04, -ht * 0.12), width: wdt * 0.84, height: ht * 0.62), Paint()..color = const Color(0xFFC4C0DE));
  }
}

// --------------------------------------------------------------- live water

void _water(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.0, 0.52, 0.5, 0.99), count: 22, seed: 6, color: const Color(0xFFFFFFFF), cycles: 8);
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.5, 0.8, 1.0, 0.99), count: 12, seed: 9, color: const Color(0xFFFFFFFF), cycles: 7);
  // ripple rings in open water
  const rings = [(0.3, 0.84, 0), (0.78, 0.9, 3), (0.62, 0.8, 5), (0.12, 0.8, 2)];
  for (final (x, y, ph) in rings) {
    for (var j = 0; j < 2; j++) {
      final t = k.saw(6, ph / 6 + j * 0.5);
      final r = (6 + t * 30) * w / 390;
      final a = (1 - t) * 0.7 * math.min(1.0, t * 6);
      c.drawOval(Rect.fromCenter(center: Offset(w * x, h * y), width: r * 2, height: r * 0.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: a));
    }
  }
  // petals floating on the lake
  final r = rng(21);
  final pp = Paint();
  for (var i = 0; i < 22; i++) {
    final x0 = r.nextDouble(), y = (0.56 + r.nextDouble() * 0.43) * h, ph = r.nextDouble();
    final sp = 1 + i % 2;
    final lap = k.saw(sp, ph);
    final px = (x0 + 0.25 * lap) % 1.0 * (w + 40) - 20;
    final sz = (2.2 + (y / h - 0.5) * 3 + r.nextDouble()) * w / 390;
    final bob = math.sin(tau * (k.u * (6 + i % 3) + ph)) * 1.2;
    final fade = math.min(1.0, math.min(lap, 1 - lap) * 8);
    c
      ..save()
      ..translate(px, y + bob)
      ..rotate(ph * 3 + math.sin(tau * (k.u * 3 + ph)) * 0.4);
    pp.color = (i % 3 == 0 ? _bloomDeep : _bloom).withValues(alpha: 0.95 * fade);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: sz * 2.2, height: sz * 1.0), pp);
    c.restore();
  }
}

// --------------------------------------------------------------- foreground

void _foreTree(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // right bank
  final bank = smoothPath([Offset(w * 0.6, h * 1.06), Offset(w * 0.74, h * 0.975), Offset(w * 0.88, h * 0.945), Offset(w * 1.15, h * 0.93)])
    ..lineTo(w * 1.15, h * 1.1)
    ..lineTo(w * 0.6, h * 1.1)
    ..close();
  _lit(c, bank, _jadeDark, _jadeLight, 0, 5);
  final gr = rng(41);
  for (var i = 0; i < 16; i++) {
    final x = w * (0.78 + gr.nextDouble() * 0.3);
    final y = h * (0.955 + gr.nextDouble() * 0.04);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 5, height: 2.8), Paint()..color = i % 3 == 0 ? _bloomDeep : (i % 3 == 1 ? _bloom : _bloomLight));
  }
  flatBush(c, Offset(w * 0.78, h * 0.975), w * 0.2, seed: 8, color: _jadeDeep, light: _jade);
  // trunk on the right bank
  _trunk(c, [Offset(w * 0.9, h * 1.06), Offset(w * 0.94, h * 0.86), Offset(w * 0.88, h * 0.62), Offset(w * 0.93, h * 0.42), Offset(w * 0.86, h * 0.27), Offset(w * 0.84, h * 0.2)],
      [w * 0.06, w * 0.04, w * 0.03, w * 0.026, w * 0.022, w * 0.018]);
  // roots
  _trunk(c, [Offset(w * 0.82, h * 1.03), Offset(w * 0.88, h * 0.96), Offset(w * 0.91, h * 0.9)], [w * 0.03, w * 0.025, w * 0.02]);
  // branches reaching left across the top
  _trunk(c, [Offset(w * 0.86, h * 0.26), Offset(w * 0.76, h * 0.2), Offset(w * 0.66, h * 0.15), Offset(w * 0.56, h * 0.11)], [w * 0.024, w * 0.018, w * 0.012, w * 0.007]);
  _trunk(c, [Offset(w * 0.9, h * 0.38), Offset(w * 1.0, h * 0.32), Offset(w * 1.08, h * 0.26)], [w * 0.02, w * 0.014, w * 0.01]);
  _trunk(c, [Offset(w * 0.85, h * 0.2), Offset(w * 0.8, h * 0.12), Offset(w * 0.82, h * 0.03)], [w * 0.015, w * 0.011, w * 0.008]);
  // crowns
  _canopy(c, Offset(w * 0.82, h * 0.105), w * 0.36, h * 0.1, seed: 4, n: 12, puff: w * 0.08);
  _canopy(c, Offset(w * 0.62, h * 0.075), w * 0.17, h * 0.065, seed: 11, n: 7, puff: w * 0.07);
  _canopy(c, Offset(w * 1.0, h * 0.27), w * 0.2, h * 0.08, seed: 21, n: 8, puff: w * 0.075);
  _canopy(c, Offset(w * 0.86, h * 0.205), w * 0.16, h * 0.05, seed: 31, n: 6, puff: w * 0.065);
  _canopy(c, Offset(w * 0.86, h * 0.5), w * 0.1, h * 0.045, seed: 17, n: 6, puff: w * 0.05, dots: false);
  // paper lanterns hanging from the branch
  for (final (lx, ly, ls) in [(0.7, 0.19, 1.0), (0.77, 0.235, 0.8)]) {
    final o = Offset(w * lx, h * ly);
    final r = w * 0.022 * ls;
    c.drawLine(Offset(o.dx, o.dy - h * 0.045 * ls - r), Offset(o.dx, o.dy - r), Paint()
      ..strokeWidth = 1.4
      ..color = _wood);
    final body = Path()..addOval(Rect.fromCenter(center: o, width: r * 2, height: r * 2.5));
    _cel(c, body, const Color(0xFFFFA48F), _red, _redShade, r * 0.3, r * 0.5);
    c.drawRect(Rect.fromCenter(center: o + Offset(0, -r * 1.2), width: r * 0.9, height: r * 0.3), Paint()..color = _wood);
    c.drawRect(Rect.fromCenter(center: o + Offset(0, r * 1.2), width: r * 0.9, height: r * 0.3), Paint()..color = _wood);
    c.drawCircle(o + Offset(0, r * 1.55), r * 0.14, Paint()..color = const Color(0xFFF0C27A));
  }
  // hanging blossom sprigs
  final r = rng(9);
  final twig = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6
    ..color = _wood;
  for (var i = 0; i < 9; i++) {
    final x = w * (0.55 + i * 0.05 + r.nextDouble() * 0.02);
    final y0 = h * (0.095 + 0.03 * math.sin(i * 1.3).abs());
    final len = h * (0.03 + r.nextDouble() * 0.05);
    c.drawPath(
        Path()
          ..moveTo(x, y0)
          ..quadraticBezierTo(x + 3, y0 + len * 0.5, x - 1, y0 + len),
        twig);
    for (var j = 0; j < 3; j++) {
      c.drawCircle(Offset(x + (j == 1 ? 2.5 : -0.5), y0 + len * (0.45 + j * 0.28)), 3.2 - j * 0.5, Paint()..color = j == 1 ? _bloomDeep : _bloom);
    }
  }
}

void _foreLeft(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // left bank
  final top = [Offset(-w * 0.15, h * 0.915), Offset(w * 0.03, h * 0.9), Offset(w * 0.14, h * 0.915), Offset(w * 0.22, h * 0.95), Offset(w * 0.3, h * 1.02)];
  final bank = smoothPath(top)
    ..lineTo(w * 0.3, h * 1.1)
    ..lineTo(-w * 0.15, h * 1.1)
    ..close();
  _lit(c, bank, _jadeDark, _jadeLight, 0, 5);
  c.drawPath(
      smoothPath([Offset(-w * 0.15, h * 0.97), Offset(w * 0.05, h * 0.955), Offset(w * 0.17, h * 0.99), Offset(w * 0.25, h * 1.1)])..lineTo(-w * 0.15, h * 1.1)..close(),
      Paint()..color = _jadeDeep);
  // grass tufts
  final r = rng(14);
  for (var i = 0; i < 14; i++) {
    final x = -w * 0.05 + r.nextDouble() * w * 0.27;
    final y = h * (0.905 + r.nextDouble() * 0.06) + (x > w * 0.1 ? (x - w * 0.1) * 0.5 : 0);
    final th = h * (0.012 + r.nextDouble() * 0.012);
    for (var k = -1; k <= 1; k++) {
      final bx = x + k * th * 0.5;
      c.drawPath(
          Path()
            ..moveTo(bx - 2, y)
            ..quadraticBezierTo(bx + k * 3, y - th * 0.6, bx + k * th * 0.6, y - th * (k == 0 ? 1.1 : 0.85))
            ..quadraticBezierTo(bx + k * 3 + 3, y - th * 0.5, bx + 2, y)
            ..close(),
          Paint()..color = k == 0 ? _jadeLight : _jade);
    }
  }
  // fallen petals
  for (var i = 0; i < 26; i++) {
    final x = -w * 0.04 + r.nextDouble() * w * 0.26;
    final y = h * (0.92 + r.nextDouble() * 0.075) + (x > w * 0.12 ? (x - w * 0.12) * 0.6 : 0);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 5, height: 2.8), Paint()..color = i % 3 == 0 ? _bloomDeep : (i % 3 == 1 ? _bloom : _bloomLight));
  }
  flatRock(c, Offset(w * 0.19, h * 0.945), w * 0.09, h * 0.026, seed: 3, color: const Color(0xFFB4B0D2), shade: const Color(0xFF938FBC));
  flatBush(c, Offset(w * 0.02, h * 0.905), w * 0.2, seed: 5, color: _jadeDeep, light: _jade);
  _lantern(c, Offset(w * 0.1, h * 0.91), h * 0.12);
}

void _lantern(Canvas c, Offset base, double sz) {
  const rim = Color(0xFFE2DFF2), main = Color(0xFFB9B5D8), shade = Color(0xFF9692BE);
  final cx = base.dx;
  Path rr(Rect r, double rad) => Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(rad)));
  _cel(c, rr(Rect.fromLTWH(cx - sz * 0.24, base.dy - sz * 0.09, sz * 0.48, sz * 0.09), sz * 0.02), rim, main, shade, 1.5, 2.5);
  _cel(c, rr(Rect.fromLTWH(cx - sz * 0.08, base.dy - sz * 0.42, sz * 0.16, sz * 0.34), sz * 0.015), rim, main, shade, 1, 2);
  _cel(c, rr(Rect.fromLTWH(cx - sz * 0.2, base.dy - sz * 0.5, sz * 0.4, sz * 0.09), sz * 0.02), rim, main, shade, 1.5, 2.5);
  final chamber = Rect.fromLTWH(cx - sz * 0.15, base.dy - sz * 0.74, sz * 0.3, sz * 0.24);
  // flat halo rings around the lit window
  c.drawCircle(chamber.center, sz * 0.36, Paint()..color = const Color(0xFFFFE6A8).withValues(alpha: 0.16));
  c.drawCircle(chamber.center, sz * 0.24, Paint()..color = const Color(0xFFFFE6A8).withValues(alpha: 0.24));
  _cel(c, rr(chamber, sz * 0.015), rim, main, shade, 1.5, 3);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - sz * 0.08, base.dy - sz * 0.69, sz * 0.15, sz * 0.15), Radius.circular(sz * 0.02)), Paint()..color = const Color(0xFFFFE9A8));
  _roof(c, cx, base.dy - sz * 0.72, sz * 0.34, sz * 0.2, const Color(0xFF7C78A8), const Color(0xFF625E8E));
  c.drawCircle(Offset(cx, base.dy - sz * 0.95), sz * 0.04, Paint()..color = const Color(0xFFF0C27A));
}

// --------------------------------------------------------------- live air

void _petals(Canvas c, Size s, Clock k) {
  const pinks = [_bloom, _bloomLight, _bloomDeep, _bloom];
  // far
  paintParticles(c, s, k, const ParticleSpec(count: 36, seed: 2, colors: pinks, minSize: 1.4, maxSize: 2.2, flow: Offset(-0.25, 1.0), cycles: 2, spread: 1, wander: 10, wanderCycles: 3, shape: ParticleShape.petal, opacity: 0.75, region: Rect.fromLTRB(0.0, 0.0, 1.0, 0.82)));
  // mid
  paintParticles(c, s, k, const ParticleSpec(count: 30, seed: 5, colors: pinks, minSize: 2.4, maxSize: 3.4, flow: Offset(-0.35, 1.0), cycles: 3, spread: 2, wander: 18, wanderCycles: 4, shape: ParticleShape.petal, opacity: 0.92, region: Rect.fromLTRB(0.0, 0.0, 1.0, 0.95)));
  // near, big
  paintParticles(c, s, k, const ParticleSpec(count: 14, seed: 8, colors: [_bloom, _bloomDeep], minSize: 5, maxSize: 7, flow: Offset(-0.45, 1.0), cycles: 3, spread: 2, wander: 26, wanderCycles: 3, shape: ParticleShape.petal, opacity: 0.95, region: Rect.fromLTRB(0.0, -0.05, 1.1, 1.0)));
}

void _birds(Canvas c, Size s, Clock k) {
  paintBirds(c, s, k, count: 4, seed: 3, y: 0.2, band: 0.07, color: const Color(0xFF6A6BA3), size: 6.5, cycles: 1);
}
