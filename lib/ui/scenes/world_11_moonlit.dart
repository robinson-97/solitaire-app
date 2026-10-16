import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Moonlit Forest in flat, graphic 2D: a huge moon over a still lake, layered
// navy pines framing both sides, a glittering moon path on the water, drifting
// silver cloud wisps and mist, tiny cyan forest lights. Light comes from the
// moon: rim light on the moon-facing (right) side of the trees.

const _moonPos = Offset(0.62, 0.165);
const _horizon = 0.6; // lake horizon (fraction of height)

// palette
const _sky0 = Color(0xFF050B24), _sky1 = Color(0xFF0B1E4A), _sky2 = Color(0xFF1D3F7A), _sky3 = Color(0xFF3A6BAA);
const _moonCore = Color(0xFFFFF6DC), _moonShade = Color(0xFFF1E5C2), _crater = Color(0xFFE6D9B2), _halo = Color(0xFFBFD8FF);
const _silver = Color(0xFFD6E6FF);
const _mtFar = Color(0xFF30599A), _mtFarShade = Color(0xFF284D88), _mtNear = Color(0xFF234A7F), _mtNearShade = Color(0xFF1C3F70);
const _pineDeep = Color(0xFF0A1A33), _pineMid = Color(0xFF0D2244), _pineFar = Color(0xFF16335F), _pineRim = Color(0xFF4F86C0);
const _land = Color(0xFF081630), _landRim = Color(0xFF2A5A94);
const _fly = Color(0xFF8FE8FF);
const _warm = Color(0xFFFFC66B);

double _lerp(double a, double b, double t) => a + (b - a) * t;

SceneSpec moonlitScene() => SceneSpec(
      focusY: -0.35,
      topShade: 0.1,
      bottomShade: 0.22,
      layers: [
        Layer.still(_sky),
        Layer.live(_stars),
        Layer.still(_moon),
        Layer.scroll(_wisps, scrollCycles: 1, bandTop: 0.04, bandBottom: 0.3),
        Layer.scroll(_duskClouds, scrollCycles: 2, scrollLeft: false, bandTop: 0.3, bandBottom: 0.46),
        Layer.still(_mountains, driftX: 0.004, driftCycles: 2),
        Layer.scroll(_mountainMist, scrollCycles: 1, scrollLeft: false, bandTop: 0.4, bandBottom: 0.62),
        Layer.still(_lake),
        Layer.live(_lakeLive),
        Layer.scroll(_waterMist, scrollCycles: 2, bandTop: 0.58, bandBottom: 0.74),
        Layer.still(_midShore, driftX: 0.012, driftCycles: 2, driftPhase: 0.1, sway: 0.003, swayCycles: 5),
        Layer.still(_bigPines, driftX: 0.024, driftCycles: 2, driftPhase: 0.2, sway: 0.004, swayCycles: 4),
        Layer.live(_fireflies),
        Layer.still(_bank, driftX: 0.032, driftCycles: 2, driftPhase: 0.3, sway: 0.005, swayCycles: 6),
      ],
    );

// ---------------------------------------------------------------- pines

Path _tier(double cx, double ty, double by, double hw, double d) {
  final hgt = by - ty;
  final p = Path()
    ..moveTo(cx, ty)
    ..cubicTo(cx - hw * 0.1, ty + hgt * 0.38, cx - hw * 0.75, by - hgt * 0.3, cx - hw, by - d);
  const n = 3;
  for (var j = 0; j < n; j++) {
    final x1 = cx - hw + 2 * hw * (j + 1) / n;
    final x0 = cx - hw + 2 * hw * j / n;
    p.quadraticBezierTo((x0 + x1) / 2, by + d * 2.2, x1, j == n - 1 ? by - d : by - d * 0.2);
  }
  p.cubicTo(cx + hw * 0.75, by - hgt * 0.3, cx + hw * 0.1, ty + hgt * 0.38, cx, ty);
  p.close();
  return p;
}

/// Smooth layered pine. Flat colour with a flat lighter rim on the moon side (right).
void _pine(Canvas c, Offset base, double h, double w, Color col, Color? rim, {int tiers = 4, Color? trunk}) {
  final tw = math.max(2.0, w * 0.05);
  c.drawRect(Rect.fromLTRB(base.dx - tw, base.dy - h * 0.16, base.dx + tw, base.dy + 2), Paint()..color = trunk ?? col);
  final top = base.dy - h;
  final usable = h * 0.9;
  final tierH = usable / tiers * 1.55;
  final rw = (w * 0.012).clamp(1.4, 3.6);
  for (var i = 0; i < tiers; i++) {
    final f = tiers == 1 ? 1.0 : i / (tiers - 1);
    final ty = top + (usable - tierH) * f;
    final hw = w / 2 * (0.3 + 0.7 * math.pow(f, 0.85));
    final path = _tier(base.dx, ty, ty + tierH, hw, tierH * 0.07);
    if (rim == null) {
      c.drawPath(path, Paint()..color = col);
    } else {
      c.drawPath(path, Paint()..color = rim);
      c
        ..save()
        ..clipPath(path)
        ..drawPath(path.shift(Offset(-rw, rw * 0.7)), Paint()..color = col)
        ..restore();
    }
  }
}

void _treeRow(Canvas c, Size s, double y, double x0, double x1, double hMin, double hMax, Color col, Color? rim, int seed, {double gap = 0.55, int tiers = 3}) {
  final r = rng(seed);
  var x = x0;
  while (x < x1) {
    final th = _lerp(hMin, hMax, r.nextDouble());
    _pine(c, Offset(x, y), th, th * (0.42 + r.nextDouble() * 0.12), col, rim, tiers: tiers + (th > (hMin + hMax) / 2 ? 1 : 0));
    x += th * (gap * 0.5 + r.nextDouble() * gap * 0.4);
  }
}

// ---------------------------------------------------------------- sky & moon

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_sky0, _sky1, _sky2, _sky3], const [0.0, 0.3, 0.5, 0.64]);
}

void _stars(Canvas c, Size s, Clock k) {
  paintStars(c, s, k, count: 78, seed: 5, region: const Rect.fromLTRB(0, 0, 1, 0.46), color: const Color(0xFFDDE9FF), minR: 0.5, maxR: 1.5, twinkleCycles: 12, sparkleShare: 0.07);
  // shooting star, three times per loop
  final idx = (k.u * 3).floor() % 3;
  final t = k.saw(3);
  const dur = 0.09;
  if (t < dur) {
    const starts = [Offset(0.08, 0.05), Offset(0.7, 0.025), Offset(0.04, 0.27)];
    const dirs = [Offset(0.3, 0.14), Offset(0.26, 0.15), Offset(0.28, 0.1)];
    final p = t / dur;
    final fade = math.sin(p * math.pi);
    final a = Offset(starts[idx].dx * s.width, starts[idx].dy * s.height);
    final d = Offset(dirs[idx].dx * s.width, dirs[idx].dy * s.height);
    final head = a + d * p;
    for (var i = 0; i < 6; i++) {
      final f0 = i / 6, f1 = (i + 1) / 6;
      c.drawLine(
        head - d * 0.22 * f0,
        head - d * 0.22 * f1,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0 * (1 - f0 * 0.6)
          ..color = const Color(0xFFEAF3FF).withValues(alpha: 0.9 * fade * (1 - f0)),
      );
    }
  }
}

void _moon(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final o = Offset(_moonPos.dx * w, _moonPos.dy * h);
  final r = w * 0.2;
  c.drawCircle(o, r * 2.7, Paint()..color = _halo.withValues(alpha: 0.06));
  c.drawCircle(o, r * 2.0, Paint()..color = _halo.withValues(alpha: 0.09));
  c.drawCircle(o, r * 1.5, Paint()..color = _halo.withValues(alpha: 0.15));
  c.drawCircle(o, r * 1.2, Paint()..color = _halo.withValues(alpha: 0.24));
  // disc: flat shade, lit crescent from the upper right
  c.drawCircle(o, r, Paint()..color = _moonShade);
  final disc = Path()..addOval(Rect.fromCircle(center: o, radius: r));
  c
    ..save()
    ..clipPath(disc)
    ..drawCircle(o + Offset(r * 0.06, -r * 0.06), r * 0.96, Paint()..color = _moonCore);
  const craters = [(-0.38, -0.3, 0.2), (0.18, -0.52, 0.12), (0.44, 0.0, 0.17), (-0.12, 0.2, 0.26), (-0.55, 0.28, 0.1), (0.2, 0.55, 0.14), (0.6, -0.32, 0.08), (-0.1, -0.62, 0.07)];
  for (final (dx, dy, cr) in craters) {
    final co = o + Offset(dx * r, dy * r);
    c.drawCircle(co, cr * r, Paint()..color = _crater);
    c.drawCircle(co + Offset(cr * r * 0.18, -cr * r * 0.18), cr * r * 0.8, Paint()..color = _moonShade);
  }
  c.restore();
}

void _wisp(Canvas c, double cx, double y, double wd, double thick, Color col, double a) {
  final p = Path()
    ..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - wd / 2, y - thick * 0.5, cx + wd / 2, y + thick * 0.5), Radius.circular(thick * 0.5)))
    ..addOval(Rect.fromCenter(center: Offset(cx - wd * 0.12, y - thick * 0.55), width: wd * 0.34, height: thick * 1.5))
    ..addOval(Rect.fromCenter(center: Offset(cx + wd * 0.16, y - thick * 0.4), width: wd * 0.24, height: thick * 1.2));
  c.drawPath(p, Paint()..color = col.withValues(alpha: a));
}

void _wisps(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _wisp(c, w * 0.30, h * 0.105, w * 0.5, 15, _silver, 0.5);
  _wisp(c, w * 0.78, h * 0.175, w * 0.62, 18, _silver, 0.42);
  _wisp(c, w * 0.52, h * 0.245, w * 0.46, 13, const Color(0xFFA9C6F2), 0.42);
  _wisp(c, w * 0.12, h * 0.19, w * 0.28, 10, _silver, 0.3);
}

void _puffCloud(Canvas c, Offset base, double wd, double hgt, Color col, Color shade, int seed) {
  final r = rng(seed);
  final p = Path();
  final n = 5;
  for (var i = 0; i < n; i++) {
    final t = (i + 0.5) / n;
    final k = 1 - (t - 0.5).abs() * 1.7;
    final rad = hgt * (0.35 + 0.55 * k) * (0.9 + r.nextDouble() * 0.2);
    p.addOval(Rect.fromCircle(center: Offset(base.dx - wd / 2 + wd * (0.12 + 0.76 * t), base.dy - rad * 0.8), radius: rad));
  }
  p.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - wd * 0.42, base.dy - hgt * 0.5, base.dx + wd * 0.42, base.dy), Radius.circular(hgt * 0.25)));
  c.drawPath(p, Paint()..color = shade);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(0, -hgt * 0.14)), Paint()..color = col)
    ..restore();
}

void _duskClouds(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _puffCloud(c, Offset(w * 0.3, h * 0.395), w * 0.44, h * 0.04, const Color(0xFF3D68AA), const Color(0xFF30599A), 3);
  _puffCloud(c, Offset(w * 0.82, h * 0.35), w * 0.34, h * 0.03, const Color(0xFF3A64A5), const Color(0xFF2E5696), 8);
}

// ---------------------------------------------------------------- mountains

void _mountains(Canvas c, Size s) {
  final far = Ridge(s, y: 0.47, amp: 0.07, freq: 1.7, seed: 12, octaves: 2, sharp: 0.45);
  flatRidge(c, far, _mtFarShade, light: _mtFar, band: 4, bottomY: s.height);
  final near = Ridge(s, y: 0.525, amp: 0.04, freq: 2.2, seed: 6, octaves: 2, sharp: 0.3);
  flatRidge(c, near, _mtNearShade, light: _mtNear, band: 4, bottomY: s.height);
}

void _mountainMist(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(4);
  for (var i = 0; i < 5; i++) {
    softEllipse(c, Offset(w * (i + 0.5) / 5, h * (0.5 + r.nextDouble() * 0.06)), w * 0.6, h * 0.05, const Color(0xFF8DB4EA), 0.2);
  }
}

// ---------------------------------------------------------------- lake

void _farShore(Canvas c, Size s, Color col, Color? rim, {bool cabin = false}) {
  final y0 = _horizon * s.height;
  _treeRow(c, s, y0 + 2, -s.width * 0.05, s.width * 1.08, s.height * 0.045, s.height * 0.085, col, rim, 31, gap: 0.62);
  c.drawRect(Rect.fromLTRB(-10, y0 - 3, s.width + 10, y0 + 3), Paint()..color = col);
  if (cabin) {
    // tiny cabin with a warm window among the far trees
    final cx = s.width * 0.83, cy = y0 + 1;
    final body = Path()
      ..moveTo(cx - 9, cy)
      ..lineTo(cx - 9, cy - 8)
      ..lineTo(cx, cy - 15)
      ..lineTo(cx + 9, cy - 8)
      ..lineTo(cx + 9, cy)
      ..close();
    c.drawPath(body, Paint()..color = _pineDeep);
    c.drawRect(Rect.fromLTWH(cx - 2.2, cy - 8, 4.4, 4.4), Paint()..color = _warm);
    c.drawRect(Rect.fromLTWH(cx + 4.5, cy - 17, 2.6, 5), Paint()..color = _pineDeep);
  }
}

void _lake(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final y0 = _horizon * h;
  _farShore(c, s, _pineFar, const Color(0xFF3A6AA6), cabin: true);
  // lake bands with soft wavy flat edges
  const cols = [Color(0xFF2C6AA6), Color(0xFF225F9B), Color(0xFF1B5089), Color(0xFF143F74), Color(0xFF0E2F5F), Color(0xFF0B2552)];
  const edges = [0.0, 0.05, 0.12, 0.21, 0.32, 0.46];
  for (var b = 0; b < cols.length; b++) {
    final yy = y0 + edges[b] * h;
    final pts = <Offset>[
      for (var i = 0; i <= 14; i++) Offset(-w * 0.05 + w * 1.1 * i / 14, yy + (b == 0 ? 0 : math.sin(i * 1.7 + b * 2.0) * 2.4)),
    ];
    final p = smoothPath(pts)
      ..lineTo(w * 1.05, h * 1.05)
      ..lineTo(-w * 0.05, h * 1.05)
      ..close();
    c.drawPath(p, Paint()..color = cols[b]);
  }
  // mirrored far shore
  c
    ..save()
    ..clipRect(Rect.fromLTRB(0, y0, w, h))
    ..translate(0, y0)
    ..scale(1, -0.9)
    ..translate(0, -y0);
  _farShore(c, s, const Color(0xFF173F72).withValues(alpha: 0.7), null);
  c.restore();
  // moon path: pale flat column + broken bright strips
  final mx = _moonPos.dx * w;
  final col = Path()
    ..moveTo(mx - w * 0.05, y0)
    ..lineTo(mx + w * 0.05, y0)
    ..quadraticBezierTo(mx + w * 0.12, y0 + h * 0.2, mx + w * 0.2, h * 1.05)
    ..lineTo(mx - w * 0.2, h * 1.05)
    ..quadraticBezierTo(mx - w * 0.12, y0 + h * 0.2, mx - w * 0.05, y0)
    ..close();
  c.drawPath(col, Paint()..color = _halo.withValues(alpha: 0.1));
  final r = rng(17);
  for (var i = 0; i < 30; i++) {
    final t = i / 30;
    final yy = y0 + h * (0.012 + t * 0.34);
    final wd = w * (0.04 + 0.15 * t) * (0.55 + r.nextDouble() * 0.6);
    final xx = mx + (r.nextDouble() - 0.5) * w * (0.02 + 0.05 * t);
    final hh = 2.2 + t * 3.6;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(xx, yy), width: wd, height: hh), Radius.circular(hh / 2)), Paint()..color = const Color(0xFFE8F4FF).withValues(alpha: 0.35 + 0.4 * (1 - t * 0.6) * r.nextDouble()));
  }
}

void _lakeLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final y0 = _horizon * h;
  final k0 = w / 390;
  final mx = _moonPos.dx * w;
  final r = rng(23);
  final paint = Paint();
  // glints sliding through the reflection
  for (var i = 0; i < 34; i++) {
    final t = math.pow(r.nextDouble(), 0.8).toDouble();
    final yy = y0 + h * (0.02 + t * 0.36);
    final spread = w * (0.03 + 0.14 * t);
    final x = mx + (r.nextDouble() - 0.5) * 2 * spread + k.sine(3 + i % 3, r.nextDouble()) * 5 * k0;
    final wd = (7 + r.nextDouble() * 20 * (0.4 + t)) * k0;
    final ph = r.nextDouble();
    final a = math.pow(k.pulse(8 + i % 5, ph), 2.2).toDouble();
    if (a < 0.04) continue;
    paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.85 * a);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, yy), width: wd, height: (1.6 + t * 1.4) * k0), const Radius.circular(2)), paint);
  }
  // water streaks creeping across the lake (periodic)
  for (var i = 0; i < 16; i++) {
    final t = r.nextDouble();
    final yy = y0 + h * (0.04 + t * 0.34);
    final wd = (20 + r.nextDouble() * 50) * k0 * (0.5 + t);
    final dir = i.isEven ? 1 : -1;
    final x = ((r.nextDouble() + dir * k.saw(2 + i % 2) ) % 1.0 + 1.0) % 1.0 * (w + wd * 2) - wd;
    final edge = math.min(1.0, math.min(x + wd, w - x + wd) / (wd * 1.5)).clamp(0.0, 1.0);
    paint.color = const Color(0xFF5B9AD4).withValues(alpha: 0.38 * edge);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, yy), width: wd, height: 2.2 * k0), const Radius.circular(2)), paint);
  }
  // slow ripple rings
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3 * k0;
  for (var i = 0; i < 8; i++) {
    final t = r.nextDouble();
    final cx = w * (0.08 + r.nextDouble() * 0.84);
    final cy = y0 + h * (0.06 + t * 0.3);
    final q = k.saw(6, i / 8);
    final rx = (6 + q * 44) * k0 * (0.5 + t * 1.1);
    ring.color = const Color(0xFFB8D8FA).withValues(alpha: 0.5 * (1 - q) * math.min(1.0, q * 6));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: rx * 0.45), ring);
  }
  _boat(c, s, k);
}

void _boat(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final bob = k.sine(5) * 1.4;
  final tilt = k.sine(5, 0.25) * 0.012;
  final o = Offset(w * 0.47, h * 0.85 + bob);
  final bw = w * 0.17;
  // warm lantern reflection on the water
  final fl = 0.75 + 0.25 * k.pulse(23);
  for (var i = 0; i < 4; i++) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(o.dx - bw * 0.36 + k.sine(4, i * 0.2) * 2, o.dy + 12 + i * 7), width: 14 - i * 2.4, height: 2.6), const Radius.circular(2)),
      Paint()..color = _warm.withValues(alpha: 0.5 * fl * (1 - i * 0.2)),
    );
  }
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(tilt);
  final hull = Path()
    ..moveTo(-bw / 2, -5)
    ..quadraticBezierTo(-bw * 0.4, 7, -bw * 0.18, 8)
    ..lineTo(bw * 0.2, 8)
    ..quadraticBezierTo(bw * 0.42, 7, bw / 2, -6)
    ..quadraticBezierTo(0, -2, -bw / 2, -5)
    ..close();
  c.drawPath(hull, Paint()..color = _pineDeep);
  c
    ..save()
    ..clipPath(hull)
    ..drawRect(Rect.fromLTRB(-bw, -7, bw, -3.6), Paint()..color = _pineRim)
    ..drawPath(hull.shift(const Offset(0, 1.6)), Paint()..color = _pineDeep)
    ..restore();
  // lantern on a little pole at the bow
  c.drawRect(Rect.fromLTRB(-bw * 0.36 - 0.8, -22, -bw * 0.36 + 0.8, -5), Paint()..color = _pineDeep);
  final lo = Offset(-bw * 0.36, -23);
  c.drawCircle(lo, 11, Paint()..color = _warm.withValues(alpha: 0.14 * fl));
  c.drawCircle(lo, 7, Paint()..color = _warm.withValues(alpha: 0.24 * fl));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lo, width: 5.4, height: 7), const Radius.circular(2.4)), Paint()..color = _warm);
  c.restore();
}

void _waterMist(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(9);
  for (var i = 0; i < 4; i++) {
    softEllipse(c, Offset(w * (i + 0.2 + r.nextDouble() * 0.6) / 4, h * (0.625 + r.nextDouble() * 0.09)), w * (0.6 + r.nextDouble() * 0.3), h * 0.045, const Color(0xFF9CC2F0), 0.3);
  }
}

// ---------------------------------------------------------------- shore trees

void _midShore(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final y = h * 0.665;
  for (final mirror in [false, true]) {
    c.save();
    if (mirror) {
      c
        ..clipRect(Rect.fromLTRB(-w * 0.2, y, w * 1.2, h))
        ..translate(0, y)
        ..scale(1, -0.55)
        ..translate(0, -y);
    }
    final col = mirror ? const Color(0xFF0B2A57).withValues(alpha: 0.8) : _pineMid;
    final rim = mirror ? null : const Color(0xFF3F74B0);
    _treeRow(c, s, y, -w * 0.12, w * 0.3, h * 0.12, h * 0.2, col, rim, 51, gap: 0.62);
    _treeRow(c, s, y - 1, w * 0.74, w * 1.12, h * 0.1, h * 0.19, col, rim, 57, gap: 0.62);
    // low shore mounds
    for (final (x0, x1) in [(-w * 0.15, w * 0.34), (w * 0.7, w * 1.15)]) {
      final mound = Path()
        ..moveTo(x0, y + h * 0.03)
        ..quadraticBezierTo(x0 + (x1 - x0) * 0.1, y - h * 0.004, x0 + (x1 - x0) * 0.5, y - 1)
        ..quadraticBezierTo(x0 + (x1 - x0) * 0.9, y - h * 0.004, x1, y + h * 0.03)
        ..close();
      c.drawPath(mound, Paint()..color = col);
    }
    c.restore();
  }
}

void _bigPines(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // back pines (lighter navy), then the big framing ones
  _pine(c, Offset(w * 0.2, h * 0.84), h * 0.5, w * 0.24, _pineMid, const Color(0xFF3A6AA6), tiers: 7, trunk: _pineMid);
  _pine(c, Offset(w * 0.83, h * 0.83), h * 0.46, w * 0.22, _pineMid, const Color(0xFF3A6AA6), tiers: 7, trunk: _pineMid);
  _pine(c, Offset(w * 0.07, h * 0.95), h * 1.0, w * 0.5, _pineDeep, _pineRim, tiers: 10);
  _pine(c, Offset(w * 0.97, h * 0.95), h * 0.86, w * 0.44, _pineDeep, _pineRim, tiers: 9);
  _pine(c, Offset(w * 0.9, h * 0.82), h * 0.3, w * 0.17, _pineDeep, _pineRim, tiers: 5);
}

void _bank(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final pts = <Offset>[
    Offset(-w * 0.1, h * 0.9),
    Offset(w * 0.1, h * 0.915),
    Offset(w * 0.3, h * 0.955),
    Offset(w * 0.5, h * 0.975),
    Offset(w * 0.72, h * 0.95),
    Offset(w * 0.92, h * 0.91),
    Offset(w * 1.1, h * 0.9),
  ];
  final land = smoothPath(pts)
    ..lineTo(w * 1.1, h * 1.1)
    ..lineTo(-w * 0.1, h * 1.1)
    ..close();
  c.drawPath(land, Paint()..color = _landRim);
  c
    ..save()
    ..clipPath(land)
    ..drawPath(land.shift(const Offset(0, 3)), Paint()..color = _land)
    ..restore();
  final r = rng(33);
  // reeds and cattails, in believable clusters
  void reed(double x, double y, double len, double lean, Color col) {
    final p = Path()
      ..moveTo(x - 1.6, y)
      ..quadraticBezierTo(x + lean * 0.4 - 1, y - len * 0.55, x + lean, y - len)
      ..quadraticBezierTo(x + lean * 0.4 + 1.4, y - len * 0.55, x + 1.6, y)
      ..close();
    c.drawPath(p, Paint()..color = col);
  }

  for (final cx in [w * 0.1, w * 0.32, w * 0.7, w * 0.9]) {
    final n = 9;
    for (var i = 0; i < n; i++) {
      final x = cx + (r.nextDouble() - 0.5) * w * 0.14;
      final y = h * 0.965 + (r.nextDouble() - 0.5) * h * 0.02 + (x - w * 0.5).abs() * 0.0;
      final len = h * (0.035 + r.nextDouble() * 0.05);
      final lean = (r.nextDouble() - 0.5) * 14;
      reed(x, y + 6, len, lean, i % 3 == 0 ? const Color(0xFF0B2347) : _land);
      if (i % 4 == 1) {
        final tip = Offset(x + lean, y + 6 - len);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: tip + const Offset(0, 5), width: 4.4, height: 14), const Radius.circular(2.2)), Paint()..color = const Color(0xFF14284A));
      }
    }
  }
  // rocks
  flatRock(c, Offset(w * 0.46, h * 0.99), w * 0.2, h * 0.035, color: const Color(0xFF12305A), shade: const Color(0xFF0A2040), seed: 12);
  flatRock(c, Offset(w * 0.2, h * 0.975), w * 0.12, h * 0.025, color: const Color(0xFF12305A), shade: const Color(0xFF0A2040), seed: 14);
  // moon-flowers: tiny flat pale blossoms with translucent rings
  final fr = rng(61);
  for (var i = 0; i < 14; i++) {
    final x = (i.isEven ? 0.0 : 0.62) * w + fr.nextDouble() * w * 0.38;
    final y = h * (0.965 + fr.nextDouble() * 0.03);
    c.drawCircle(Offset(x, y), 5.2, Paint()..color = _halo.withValues(alpha: 0.16));
    c.drawCircle(Offset(x, y), 2.2, Paint()..color = const Color(0xFFD7EAFF));
  }
}

// ---------------------------------------------------------------- live lights

void _fireflies(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 30, seed: 41, colors: [_fly, Color(0xFFA6F5E6)], minSize: 2.2, maxSize: 3.4, flow: Offset(0.03, -0.05), cycles: 1, spread: 1, wander: 24, wanderCycles: 3, twinkle: 0.75, twinkleCycles: 9, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.46, 1.0, 0.92), haloScale: 3.0));
  paintParticles(c, s, k, const ParticleSpec(count: 12, seed: 77, colors: [_fly], minSize: 3.0, maxSize: 4.2, flow: Offset(-0.02, -0.04), cycles: 1, spread: 1, wander: 30, wanderCycles: 2, twinkle: 0.8, twinkleCycles: 7, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.62, 1.0, 0.98), haloScale: 3.4));
}
