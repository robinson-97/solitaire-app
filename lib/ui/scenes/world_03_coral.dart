import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Coral Ocean in flat, graphic 2D: turquoise water with a bright rolling
// surface, slanted light shafts, a hazy canyon with a stone arch, layered coral
// reefs in pink / orange / purple / electric blue, a rippled sand floor and
// swaying kelp. Three schools of fish swim across, bubbles rise in clusters.
// Light comes from the upper left: shade crescents sit on the right/bottom.

// palette
const _w0 = Color(0xFF8FF6EA), _w1 = Color(0xFF4FD6D6), _w2 = Color(0xFF19B6C9), _w3 = Color(0xFF1189B5), _w4 = Color(0xFF0A5F8F);
const _pink = Color(0xFFFF6FA8), _pinkD = Color(0xFFE04F92), _pinkL = Color(0xFFFF9CC4);
const _orange = Color(0xFFFF9B4A), _orangeD = Color(0xFFE57A36), _orangeL = Color(0xFFFFC07E);
const _purple = Color(0xFFA86BFF), _purpleD = Color(0xFF824FE0), _purpleL = Color(0xFFC79CFF);
const _blue = Color(0xFF3DA0FF), _blueD = Color(0xFF2A7FE0), _blueL = Color(0xFF7CC4FF);
const _sand = Color(0xFFF2E2B0), _sandL = Color(0xFFFFF3CC), _sandD = Color(0xFFD9C48F), _sandDD = Color(0xFFC2AC78);
const _kelp = Color(0xFF2FAF6A), _kelpD = Color(0xFF1F8F59), _kelpL = Color(0xFF63D68C);

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Flat cel shading: [color] shape with a hard [shade] crescent on the right/bottom edge.
void _cel(Canvas c, Path p, Color color, Color shade, double dx, double dy) {
  c.drawPath(p, Paint()..color = shade);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(-dx, -dy)), Paint()..color = color)
    ..restore();
}

SceneSpec coralScene() => SceneSpec(
      focusY: 0.35,
      topShade: 0.06,
      bottomShade: 0.28,
      layers: [
        Layer.still(_water),
        Layer.still(_canyon, driftX: 0.004, driftCycles: 2),
        Layer.still(_rays, rotate: 0.03, swayCycles: 3, pivot: const Alignment(0.0, -1.1)),
        Layer.still(_farReef, driftX: 0.008, driftCycles: 2, driftPhase: 0.1),
        Layer.live(_fishFar),
        Layer.still(_midReef, driftX: 0.013, driftCycles: 2, driftPhase: 0.2),
        Layer.still(_grass, driftX: 0.017, driftCycles: 2, driftPhase: 0.3, sway: 0.012, swayCycles: 6),
        Layer.live(_fishMid),
        Layer.still(_floor, driftX: 0.022, driftCycles: 2, driftPhase: 0.4),
        Layer.live(_caustics),
        Layer.live(_fishNear),
        Layer.live(_kelpLive),
        Layer.live(_surface),
        Layer.live(_jellies),
        Layer.live(_drift),
      ],
    );

// ---------------------------------------------------------------- water

void _water(Canvas c, Size s) {
  fillSky(c, s, const [_w0, _w1, _w2, _w3, _w4], const [0.0, 0.1, 0.34, 0.66, 1.0]);
}

// ---------------------------------------------------------------- canyon

Path _wallPath(Size s, bool left, double reach, double top) {
  final w = s.width, h = s.height;
  // points as (inward distance from the screen edge in w, y in h)
  final pts = <List<double>>[
    [-0.2, 1.1],
    [-0.2, top],
    [0.05 * reach, top - 0.025],
    [0.14 * reach, top + 0.05],
    [0.2 * reach, top + 0.18],
    [0.23 * reach, top + 0.34],
    [0.25 * reach, top + 0.5],
    [0.3 * reach, top + 0.66],
    [0.4 * reach, 1.1],
  ];
  return smoothPath([
    for (final p in pts) Offset(left ? p[0] * w : w - p[0] * w, p[1] * h),
  ], closed: true);
}

void _strata(Canvas c, Size s, Path clip, Color col, int seed, double y0, double y1) {
  final r = rng(seed);
  c
    ..save()
    ..clipPath(clip);
  final p = Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 5 * s.width / 390;
  for (var i = 0; i < 5; i++) {
    final y = s.height * _lerp(y0, y1, (i + r.nextDouble() * 0.5) / 5);
    final pts = <Offset>[
      for (var k = 0; k <= 6; k++) Offset(s.width * (-0.1 + k * 0.2), y + math.sin(k * 1.3 + i * 2.1) * 7),
    ];
    c.drawPath(smoothPath(pts), p);
  }
  c.restore();
}

void _canyon(Canvas c, Size s) {
  final w = s.width, h = s.height;
  const back = Color(0xFF4DC3DA), archC = Color(0xFF3DB2D2), archS = Color(0xFF319EC8);
  // pale distance
  c.drawRect(Rect.fromLTRB(-w * 0.1, h * 0.4, w * 1.1, h * 1.1), Paint()..color = back);
  // a wide natural arch
  final open = RRect.fromRectAndCorners(Rect.fromLTRB(w * 0.3, h * 0.44, w * 0.72, h * 0.9), topLeft: Radius.circular(w * 0.21), topRight: Radius.circular(w * 0.21));
  final arch = Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(RRect.fromRectAndCorners(Rect.fromLTRB(w * 0.1, h * 0.3, w * 0.92, h * 0.9), topLeft: Radius.circular(w * 0.41), topRight: Radius.circular(w * 0.41)))
    ..addRRect(open);
  _cel(c, arch, archC, archS, 8, 8);
  c.drawRRect(open, Paint()..color = const Color(0xFF6FD6E4));
  // canyon walls: far plane, then near plane
  for (final left in [true, false]) {
    final far = _wallPath(s, left, 0.95, left ? 0.17 : 0.11);
    _cel(c, far, const Color(0xFF38B0D2), const Color(0xFF2FA0C8), 9, 0);
    _strata(c, s, far, const Color(0xFF30A0C8), left ? 3 : 4, 0.2, 0.8);
  }
  for (final left in [true, false]) {
    final near = _wallPath(s, left, 0.7, left ? 0.27 : 0.21);
    _cel(c, near, const Color(0xFF2B97C4), const Color(0xFF2388B8), 10, 0);
    _strata(c, s, near, const Color(0xFF2490BE), left ? 8 : 9, 0.3, 0.85);
  }
}

// ---------------------------------------------------------------- light shafts

void _rays(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(14);
  final slant = w * 0.34;
  var x = -w * 0.25;
  var i = 0;
  while (x < w * 1.25) {
    final tw = w * (0.05 + r.nextDouble() * 0.07);
    final bw = tw * (2.2 + r.nextDouble() * 0.8);
    final p = Path()
      ..moveTo(x, -h * 0.05)
      ..lineTo(x + tw, -h * 0.05)
      ..lineTo(x + slant + bw, h * 0.92)
      ..lineTo(x + slant, h * 0.92)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFE8FFF8).withValues(alpha: i.isEven ? 0.15 : 0.09));
    x += w * (0.14 + r.nextDouble() * 0.1);
    i++;
  }
}

// ---------------------------------------------------------------- coral shapes

class _Seg {
  _Seg(this.path, this.width);
  final Path path;
  final double width;
}

void _branch(List<_Seg> out, math.Random r, Offset p, double ang, double len, double wd, int depth) {
  final bend = (r.nextDouble() - 0.5) * 0.5;
  final end = p + Offset(math.sin(ang + bend), -math.cos(ang + bend)) * len;
  final mid = p + Offset(math.sin(ang), -math.cos(ang)) * len * 0.55;
  out.add(_Seg(Path()
    ..moveTo(p.dx, p.dy)
    ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy), wd));
  if (depth <= 0) return;
  final n = depth == 1 ? 2 : 2 + r.nextInt(2);
  for (var i = 0; i < n; i++) {
    final t = n == 1 ? 0.0 : (i / (n - 1) - 0.5) * 2;
    _branch(out, r, Offset.lerp(p, end, i == 0 ? 0.6 : 1.0)!, ang + bend + t * 0.62 + (r.nextDouble() - 0.5) * 0.2, len * (0.7 + r.nextDouble() * 0.12), wd * 0.72, depth - 1);
  }
}

/// Branching staghorn coral: smooth round tubes, lit tube drawn over a shade tube.
void _staghorn(Canvas c, Offset base, double h, Color color, Color shade, Color light, int seed, {int depth = 3}) {
  final r = rng(seed);
  final segs = <_Seg>[];
  final wd = h * 0.13;
  final n = 2 + r.nextInt(2);
  for (var i = 0; i < n; i++) {
    final t = n == 1 ? 0.0 : (i / (n - 1) - 0.5) * 2;
    _branch(segs, r, base + Offset(t * h * 0.08, 0), t * 0.5 + (r.nextDouble() - 0.5) * 0.2, h * 0.32, wd, depth);
  }
  final sp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final sg in segs) {
    c.drawPath(sg.path, sp
      ..color = shade
      ..strokeWidth = sg.width);
  }
  for (final sg in segs) {
    c.drawPath(sg.path.shift(Offset(-sg.width * 0.16, 0)), sp
      ..color = color
      ..strokeWidth = sg.width * 0.62);
  }
  // little bright tips
  for (final sg in segs) {
    if (sg.width < wd * 0.4) {
      final m = sg.path.computeMetrics().first;
      final t = m.getTangentForOffset(m.length)!;
      c.drawCircle(t.position + Offset(-sg.width * 0.16, 0), sg.width * 0.3, Paint()..color = light);
    }
  }
}

/// Dome (brain) coral with winding ridges.
void _brain(Canvas c, Offset base, double w, double h, Color color, Color shade, Color ridge, int seed) {
  final foot = RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - w * 0.36, base.dy - h * 0.25, base.dx + w * 0.36, base.dy + h * 0.1), Radius.circular(h * 0.18));
  c.drawRRect(foot, Paint()..color = shade);
  final dome = Path()
    ..moveTo(base.dx - w / 2, base.dy)
    ..arcTo(Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h * 2), math.pi, math.pi, false)
    ..close();
  _cel(c, dome, color, shade, w * 0.1, h * 0.1);
  final r = rng(seed);
  c
    ..save()
    ..clipPath(dome);
  final lp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(1.6, w * 0.022)
    ..color = ridge;
  for (var i = 1; i <= 5; i++) {
    final rad = i / 5.4;
    final pts = <Offset>[];
    const steps = 14;
    for (var k = 0; k <= steps; k++) {
      final a = math.pi + math.pi * k / steps;
      final wob = 1 + 0.07 * math.sin(k * 2.4 + i * 1.7 + r.nextDouble());
      pts.add(Offset(base.dx + math.cos(a) * w * 0.5 * rad * wob, base.dy + math.sin(a) * h * rad * wob));
    }
    c.drawPath(smoothPath(pts), lp);
  }
  c.restore();
}

/// Fan coral with scalloped rim and ribs.
void _fan(Canvas c, Offset base, double w, double h, Color color, Color shade, Color rib, {double tilt = 0}) {
  final stem = Path()
    ..moveTo(base.dx - w * 0.04, base.dy)
    ..lineTo(base.dx + w * 0.04, base.dy)
    ..lineTo(base.dx + w * 0.03 + tilt * 6, base.dy - h * 0.28)
    ..lineTo(base.dx - w * 0.03 + tilt * 6, base.dy - h * 0.28)
    ..close();
  c.drawPath(stem, Paint()..color = shade);
  final cx = base.dx + tilt * 6, cy = base.dy - h * 0.2;
  const n = 11;
  final pts = <Offset>[Offset(cx, cy)];
  for (var i = 0; i <= n; i++) {
    final a = -math.pi / 2 - 1.15 + 2.3 * i / n + tilt * 0.2;
    final rad = (i.isEven ? 1.0 : 0.88) * (1 - 0.18 * (i / n - 0.5).abs() * 2);
    pts.add(Offset(cx + math.cos(a) * w * 0.5 * rad, cy + math.sin(a) * h * 0.8 * rad));
  }
  final fan = smoothPath(pts, closed: true);
  _cel(c, fan, color, shade, w * 0.06, h * 0.05);
  c
    ..save()
    ..clipPath(fan);
  final rp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(1.4, w * 0.018)
    ..color = rib;
  for (var i = 1; i < n; i += 1) {
    final a = -math.pi / 2 - 1.15 + 2.3 * i / n + tilt * 0.2;
    c.drawLine(Offset(cx, cy), Offset(cx + math.cos(a) * w * 0.46, cy + math.sin(a) * h * 0.74), rp);
  }
  c.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.55, height: h * 0.9), -math.pi / 2 - 1.15, 2.3, false, rp);
  c.restore();
}

/// Cluster of tube sponges with dark openings.
void _tubes(Canvas c, Offset base, double w, double h, Color color, Color shade, Color inner, int seed) {
  final r = rng(seed);
  final n = 3 + r.nextInt(2);
  final order = List<int>.generate(n, (i) => i)..sort((a, b) => (a - (n - 1) / 2).abs().compareTo((b - (n - 1) / 2).abs()) * -1);
  final tw = w / n * 1.15;
  for (final i in order) {
    final x = base.dx - w / 2 + w * (i + 0.5) / n;
    final th = h * (0.55 + 0.45 * (1 - (i - (n - 1) / 2).abs() / n * 1.2) * (0.8 + r.nextDouble() * 0.3));
    final top = base.dy - th;
    final body = Path()
      ..moveTo(x - tw / 2, base.dy + 2)
      ..lineTo(x - tw * 0.44, top)
      ..lineTo(x + tw * 0.44, top)
      ..lineTo(x + tw / 2, base.dy + 2)
      ..close();
    final tube = Path()
      ..addPath(body, Offset.zero)
      ..addOval(Rect.fromCenter(center: Offset(x, top), width: tw * 0.88, height: tw * 0.34));
    _cel(c, tube, color, shade, tw * 0.2, 0);
    c.drawOval(Rect.fromCenter(center: Offset(x, top), width: tw * 0.66, height: tw * 0.22), Paint()..color = inner);
  }
}

/// Knobbly bubble coral: overlapping circles with lit dots.
void _knobs(Canvas c, Offset base, double w, Color color, Color shade, Color light, int seed) {
  final r = rng(seed);
  final p = Path();
  final n = 5 + r.nextInt(3);
  final centres = <Offset>[];
  for (var i = 0; i < n; i++) {
    final t = (i + 0.5) / n;
    final rad = w * (0.15 + 0.1 * (1 - (t - 0.5).abs() * 1.6) + r.nextDouble() * 0.04);
    final o = Offset(base.dx - w / 2 + w * t, base.dy - rad * (0.8 + r.nextDouble() * 0.5));
    centres.add(o);
    p.addOval(Rect.fromCircle(center: o, radius: rad));
  }
  _cel(c, p, color, shade, w * 0.04, w * 0.05);
  for (final o in centres) {
    c.drawCircle(o + Offset(-w * 0.02, -w * 0.03), w * 0.035, Paint()..color = light);
  }
}

void _blade(Canvas c, Offset base, double h, double wd, Color color, Color light, {double lean = 0}) {
  final pts = <Offset>[];
  const n = 7;
  final l = <Offset>[], rr = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final x = base.dx + math.sin(t * 2.4 + lean) * wd * 1.6 * t + lean * h * 0.15 * t * t;
    final y = base.dy - h * t;
    final hw = wd * 0.5 * math.sqrt(1 - math.pow(t, 2.4)) * (t < 0.1 ? 0.6 + 4 * t : 1.0);
    l.add(Offset(x - hw, y));
    rr.add(Offset(x + hw, y));
  }
  pts
    ..addAll(l)
    ..addAll(rr.reversed);
  final path = smoothPath(pts, closed: true);
  _cel(c, path, light, color, wd * 0.22, 0);
}

// ---------------------------------------------------------------- reefs

void _farReef(Canvas c, Size s) {
  final w = s.width, h = s.height, k = w / 390;
  // soft violet-blue rock plane at the back
  const rock = Color(0xFF4E8FD2), rockL = Color(0xFF63A2DC);
  final ridge = Ridge(s, y: 0.79, amp: 0.02, freq: 2.2, seed: 61, octaves: 2);
  flatRidge(c, ridge, rock, light: rockL, band: 3);
  // far corals: hazy blue-purple
  const fc = [Color(0xFF7F8EEA), Color(0xFF6E9AEA), Color(0xFF8B86E6)];
  const fs = [Color(0xFF6A78D6), Color(0xFF5B85D6), Color(0xFF7770D2)];
  final r = rng(33);
  void far(double x, double y, int kind) {
    final i = kind % 3;
    final base = Offset(x * w, y * h);
    switch (kind) {
      case 0:
        _staghorn(c, base, 80 * k, fc[i], fs[i], lighten(fc[i], 0.1), 100 + (x * 100).round(), depth: 2);
      case 1:
        _brain(c, base, 56 * k, 34 * k, fc[i], fs[i], lighten(fc[i], 0.06), 5);
      case 2:
        _fan(c, base, 62 * k, 70 * k, fc[i], fs[i], lighten(fc[i], 0.1));
      default:
        _tubes(c, base, 44 * k, 44 * k, fc[i], fs[i], darken(fs[i], 0.1), 9);
    }
  }

  for (final x in [-0.02, 0.1, 0.2, 0.33, 0.52, 0.66, 0.78, 0.9, 1.02]) {
    far(x, ridge.yAt(x * w) / h + 0.012, r.nextInt(4));
  }
  // corals clinging to the canyon walls near the top
  for (final p in const [
    [0.05, 0.31, 0],
    [0.12, 0.42, 2],
    [0.94, 0.27, 3],
    [0.88, 0.38, 0],
  ]) {
    final base = Offset(p[0] * w, p[1] * h);
    final i = p[2].toInt() % 3;
    final col = hazeTo(fc[i], const Color(0xFF3A9FC8), 0.35), sh = hazeTo(fs[i], const Color(0xFF3A9FC8), 0.35);
    if (p[2] == 0) {
      _staghorn(c, base, 46 * k, col, sh, lighten(col, 0.1), 40 + (p[0] * 10).round(), depth: 2);
    } else if (p[2] == 2) {
      _fan(c, base, 36 * k, 40 * k, col, sh, lighten(col, 0.1));
    } else {
      _tubes(c, base, 28 * k, 28 * k, col, sh, darken(sh, 0.12), 3);
    }
  }
}

void _midReef(Canvas c, Size s) {
  final w = s.width, h = s.height, k = w / 390;
  // reef rock bed
  final bed = Ridge(s, y: 0.855, amp: 0.012, freq: 2.0, seed: 17, octaves: 2);
  flatRidge(c, bed, const Color(0xFF3B6FC0), light: const Color(0xFF4F86D3), band: 4);

  // left cluster
  _fan(c, Offset(w * 0.07, h * 0.88), 110 * k, 130 * k, _orange, _orangeD, _orangeL, tilt: 0.3);
  _staghorn(c, Offset(w * 0.17, h * 0.88), 170 * k, _pink, _pinkD, _pinkL, 11);
  _brain(c, Offset(w * 0.3, h * 0.905), 96 * k, 60 * k, _purple, _purpleD, _purpleL, 2);
  _tubes(c, Offset(w * 0.4, h * 0.915), 56 * k, 78 * k, _blue, _blueD, const Color(0xFF1B4FA8), 4);
  _knobs(c, Offset(w * 0.1, h * 0.915), 70 * k, _orange, _orangeD, _orangeL, 6);

  // right cluster
  _staghorn(c, Offset(w * 0.86, h * 0.88), 190 * k, _orange, _orangeD, _orangeL, 23);
  _tubes(c, Offset(w * 0.69, h * 0.915), 62 * k, 92 * k, _purple, _purpleD, const Color(0xFF4F2BA8), 8);
  _brain(c, Offset(w * 0.77, h * 0.915), 92 * k, 58 * k, _pink, _pinkD, _pinkL, 5);
  _fan(c, Offset(w * 0.985, h * 0.88), 120 * k, 150 * k, _blue, _blueD, _blueL, tilt: -0.3);
  _knobs(c, Offset(w * 0.93, h * 0.92), 66 * k, _pink, _pinkD, _pinkL, 12);

  // small ones in the middle
  _knobs(c, Offset(w * 0.52, h * 0.925), 54 * k, _blue, _blueD, _blueL, 9);
  _staghorn(c, Offset(w * 0.6, h * 0.925), 70 * k, _purple, _purpleD, _purpleL, 31, depth: 2);
}

void _grass(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(52);
  for (var i = 0; i < 16; i++) {
    final x = (0.04 + (i % 2 == 0 ? r.nextDouble() * 0.34 : 0.62 + r.nextDouble() * 0.34)) * w;
    _blade(c, Offset(x, h * (0.915 + r.nextDouble() * 0.02)), h * (0.07 + r.nextDouble() * 0.09), 11 * w / 390, _kelpD, _kelp, lean: (r.nextDouble() - 0.5) * 1.2);
  }
}

// ---------------------------------------------------------------- sand floor

void _floor(Canvas c, Size s) {
  final w = s.width, h = s.height, k = w / 390;
  final back = Ridge(s, y: 0.915, amp: 0.012, freq: 1.8, seed: 71, octaves: 2);
  flatRidge(c, back, const Color(0xFFDCCFA0), light: const Color(0xFFE8DDB2), band: 3);
  final front = Ridge(s, y: 0.945, amp: 0.012, freq: 1.5, seed: 72, octaves: 2, tilt: 0.02);
  flatRidge(c, front, _sand, light: _sandL, band: 4);
  // ripples
  final rp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3 * k
    ..color = _sandD;
  final r = rng(91);
  for (var row = 0; row < 3; row++) {
    var x = -w * 0.05 + r.nextDouble() * 40;
    while (x < w * 1.05) {
      final len = (50 + r.nextDouble() * 70) * k;
      final y = h * (0.965 + row * 0.014) + (r.nextDouble() - 0.5) * 4;
      c.drawPath(smoothPath([Offset(x, y), Offset(x + len * 0.3, y - 3 * k), Offset(x + len * 0.65, y + 3 * k), Offset(x + len, y)]), rp);
      x += len + (30 + r.nextDouble() * 60) * k;
    }
  }
  // starfish
  void star(Offset o, double rad, Color col, Color dot, double rot) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = rad * 0.5
      ..color = col;
    for (var i = 0; i < 5; i++) {
      final a = rot + tau * i / 5;
      c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * rad * 0.7, p);
    }
    c.drawCircle(o, rad * 0.4, Paint()..color = col);
    for (var i = 0; i < 5; i++) {
      final a = rot + tau * i / 5;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * rad * 0.55, rad * 0.07, Paint()..color = dot);
    }
  }

  star(Offset(w * 0.27, h * 0.965), 15 * k, _pink, _pinkL, 0.4);
  star(Offset(w * 0.73, h * 0.975), 12 * k, _orange, _orangeL, 1.0);
  // shells and pebbles
  void shell(Offset o, double rad) {
    final p = Path()
      ..moveTo(o.dx - rad, o.dy)
      ..arcTo(Rect.fromCenter(center: o, width: rad * 2, height: rad * 2.2), math.pi, math.pi, false)
      ..close();
    c.drawPath(p, Paint()..color = _pinkL);
    c
      ..save()
      ..clipPath(p);
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rad * 0.12
      ..color = _pink;
    for (var i = -2; i <= 2; i++) {
      c.drawLine(o, o + Offset(i * rad * 0.42, -rad * 1.1), lp);
    }
    c.restore();
  }

  shell(Offset(w * 0.5, h * 0.972), 10 * k);
  shell(Offset(w * 0.12, h * 0.985), 8 * k);
  final pr = rng(77);
  for (var i = 0; i < 9; i++) {
    final x = pr.nextDouble() * w, y = h * (0.955 + pr.nextDouble() * 0.04);
    final rad = (2.5 + pr.nextDouble() * 3.5) * k;
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: rad * 2.2, height: rad * 1.4), Paint()..color = _sandDD);
    c.drawOval(Rect.fromCenter(center: Offset(x - rad * 0.2, y - rad * 0.2), width: rad * 1.5, height: rad * 0.9), Paint()..color = _sandD);
  }
  // sea grass tufts in front
  final gr = rng(63);
  for (var i = 0; i < 6; i++) {
    final x = (i < 3 ? 0.18 + gr.nextDouble() * 0.2 : 0.6 + gr.nextDouble() * 0.22) * w;
    for (var b = 0; b < 3; b++) {
      _blade(c, Offset(x + b * 7 * k, h * 0.965), h * (0.03 + gr.nextDouble() * 0.03), 8 * k, _kelpD, _kelp, lean: (b - 1) * 0.5);
    }
  }
}

// ---------------------------------------------------------------- live: surface

void _surface(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, sc = w / 390;
  void band(double y, double amp, double crests, int cycles, double phase, Color col, double a) {
    final p = Path()..moveTo(-4, -4);
    p.lineTo(w + 4, -4);
    const steps = 44;
    final shift = k.saw(cycles) * tau;
    for (var i = steps; i >= 0; i--) {
      final x = -4 + (w + 8) * i / steps;
      final u = x / w * crests * tau + phase + shift;
      p.lineTo(x, y * h + amp * sc * (math.sin(u) * 0.7 + math.sin(u * 2 + 1.1) * 0.3));
    }
    p.close();
    c.drawPath(p, Paint()..color = col.withValues(alpha: a));
  }

  band(0.052, 5, 3, 2, 0.5, const Color(0xFFBFFBF1), 0.5);
  band(0.04, 4, 4, 3, 1.7, const Color(0xFFE9FFFA), 0.95);
  band(0.022, 3, 5, 4, 3.0, const Color(0xFFFFFFFF), 0.75);
}

// ---------------------------------------------------------------- live: fish

final Path _fishBody = Path()
  ..moveTo(0.5, 0)
  ..cubicTo(0.3, -0.27, -0.2, -0.24, -0.38, -0.05)
  ..lineTo(-0.38, 0.05)
  ..cubicTo(-0.2, 0.24, 0.3, 0.27, 0.5, 0)
  ..close();
final Path _fishBelly = Path()
  ..moveTo(0.48, 0.03)
  ..cubicTo(0.3, 0.27, -0.2, 0.24, -0.38, 0.05)
  ..quadraticBezierTo(-0.1, 0.1, 0.48, 0.03)
  ..close();
final Path _fishTail = Path()
  ..moveTo(0.02, -0.04)
  ..quadraticBezierTo(-0.1, -0.07, -0.27, -0.25)
  ..quadraticBezierTo(-0.21, 0, -0.27, 0.25)
  ..quadraticBezierTo(-0.1, 0.07, 0.02, 0.04)
  ..close();
final Path _fishFin = Path()
  ..moveTo(0.18, -0.2)
  ..quadraticBezierTo(0.0, -0.4, -0.22, -0.3)
  ..quadraticBezierTo(-0.1, -0.2, -0.2, -0.14)
  ..close();

final Paint _fp = Paint();

void _fish(Canvas c, Offset o, double len, int dir, double wag, Color body, Color belly, Color fin) {
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..scale(len * dir, len);
  _fp.color = fin;
  c.drawPath(_fishFin, _fp);
  c
    ..save()
    ..translate(-0.37, 0)
    ..rotate(wag);
  c.drawPath(_fishTail, _fp);
  c.restore();
  _fp.color = body;
  c.drawPath(_fishBody, _fp);
  _fp.color = belly;
  c.drawPath(_fishBelly, _fp);
  _fp.color = const Color(0xFF0B3A63);
  c.drawCircle(const Offset(0.31, -0.06), 0.034, _fp);
  c.restore();
}

void _school(Canvas c, Size s, Clock k, {required int seed, required int n, required double y, required double len, required int cycles, required double phase, required bool right, required Color body, required Color belly, required Color fin, double spread = 1.0, double bob = 5}) {
  final w = s.width, sc = w / 390;
  final r = rng(seed);
  final margin = 130 * sc * spread;
  final t = k.saw(cycles, phase);
  final cx = right ? -margin + t * (w + 2 * margin) : w + margin - t * (w + 2 * margin);
  for (var i = 0; i < n; i++) {
    final ox = (r.nextDouble() - 0.5) * 100 * sc * spread;
    final oy = (r.nextDouble() - 0.5) * 46 * sc * spread;
    final ph = r.nextDouble();
    final l = len * sc * (0.85 + r.nextDouble() * 0.3);
    final yy = y * s.height + oy + k.sine(4 + i % 3, ph) * bob * sc;
    final wag = k.sine(70 + (i % 4) * 3, ph) * 0.38;
    _fish(c, Offset(cx + ox, yy), l, right ? 1 : -1, wag, body, belly, fin);
  }
}

void _fishFar(Canvas c, Size s, Clock k) {
  _school(c, s, k, seed: 3, n: 9, y: 0.26, len: 15, cycles: 1, phase: 0.55, right: false, body: const Color(0xFF6FA6F2), belly: const Color(0xFF9CC6FA), fin: const Color(0xFF5588DA), bob: 3);
}

void _fishMid(Canvas c, Size s, Clock k) {
  _school(c, s, k, seed: 8, n: 7, y: 0.14, len: 24, cycles: 2, phase: 0.1, right: true, body: _orange, belly: _orangeL, fin: _orangeD);
}

void _fishNear(Canvas c, Size s, Clock k) {
  _school(c, s, k, seed: 12, n: 5, y: 0.79, len: 34, cycles: 2, phase: 0.62, right: false, body: const Color(0xFFFFDD55), belly: const Color(0xFFFFF0A0), fin: _orange, spread: 1.1, bob: 7);
  _school(c, s, k, seed: 21, n: 6, y: 0.66, len: 17, cycles: 3, phase: 0.2, right: true, body: _purple, belly: _purpleL, fin: _purpleD, bob: 4);
}

// ---------------------------------------------------------------- live: light + kelp + bubbles

void _caustics(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, sc = w / 390;
  final r = rng(5);
  final p = Paint();
  for (var i = 0; i < 16; i++) {
    final x = r.nextDouble() * w, y = h * (0.935 + r.nextDouble() * 0.055);
    final ph = r.nextDouble();
    final a = 0.12 + 0.3 * k.pulse(6 + i % 4, ph);
    final dx = k.sine(3, ph) * 8 * sc;
    final ww = (30 + r.nextDouble() * 40) * sc;
    p.color = const Color(0xFFFFFBE0).withValues(alpha: a);
    c.drawOval(Rect.fromCenter(center: Offset(x + dx, y), width: ww, height: ww * 0.2), p);
    c.drawOval(Rect.fromCenter(center: Offset(x + dx + ww * 0.6, y + 4 * sc), width: ww * 0.4, height: ww * 0.1), p);
  }
}

void _kelpLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, sc = w / 390;
  final r = rng(44);
  const n = 5;
  for (var side = 0; side < 2; side++) {
    for (var i = 0; i < n; i++) {
      final bx = side == 0 ? (-0.03 + i * 0.036 + r.nextDouble() * 0.01) * w : w * (1.03 - i * 0.036 - r.nextDouble() * 0.01);
      final bh = h * (0.12 + r.nextDouble() * 0.14) * (1 - i * 0.06);
      final ph = r.nextDouble();
      final wd = (18 + r.nextDouble() * 8) * sc;
      final cyc = 5 + (i % 3);
      final base = Offset(bx, h * 1.02);
      final left = <Offset>[], right = <Offset>[];
      const seg = 9;
      for (var j = 0; j <= seg; j++) {
        final t = j / seg;
        final x = bx + (side == 0 ? 1 : -1) * t * t * 24 * sc + math.sin(tau * (k.u * cyc + ph) - t * 2.6) * 16 * sc * t;
        final y = base.dy - bh * t;
        final hw = wd * 0.5 * math.sqrt(1 - math.pow(t, 2.2) * 0.85) * (t < 0.08 ? 0.5 + 6 * t : 1);
        left.add(Offset(x - hw, y));
        right.add(Offset(x + hw, y));
      }
      final path = smoothPath([...left, ...right.reversed], closed: true);
      final dark = i.isEven ? _kelpD : mix(_kelpD, const Color(0xFF176F66), 0.5);
      c.drawPath(path, Paint()..color = dark);
      // flat lit strip along the left half
      final strip = smoothPath([for (var j = 0; j <= seg; j++) Offset.lerp(left[j], right[j], 0.0)!, for (var j = seg; j >= 0; j--) Offset.lerp(left[j], right[j], 0.45)!], closed: true);
      c.drawPath(strip, Paint()..color = i.isEven ? _kelp : _kelpL);
    }
  }
}

void _drift(Canvas c, Size s, Clock k) {
  const white = Color(0xFFEFFFFF);
  paintParticles(c, s, k, const ParticleSpec(count: 7, seed: 1, colors: [white], minSize: 2, maxSize: 5.5, flow: Offset(0, -1), cycles: 2, spread: 2, wander: 7, shape: ParticleShape.bubble, region: Rect.fromLTRB(0.1, 0.05, 0.24, 0.93), fade: 0.1, opacity: 0.9));
  paintParticles(c, s, k, const ParticleSpec(count: 6, seed: 2, colors: [white], minSize: 1.8, maxSize: 5, flow: Offset(0, -1), cycles: 3, spread: 1, wander: 7, shape: ParticleShape.bubble, region: Rect.fromLTRB(0.72, 0.05, 0.86, 0.93), fade: 0.1, opacity: 0.9));
  paintParticles(c, s, k, const ParticleSpec(count: 5, seed: 3, colors: [white], minSize: 1.5, maxSize: 4, flow: Offset(0, -1), cycles: 2, spread: 1, wander: 6, shape: ParticleShape.bubble, region: Rect.fromLTRB(0.44, 0.05, 0.56, 0.93), fade: 0.1, opacity: 0.8));
  paintParticles(c, s, k, const ParticleSpec(count: 34, seed: 4, colors: [Color(0xFFE8FFF8)], minSize: 0.9, maxSize: 2.0, flow: Offset(0.08, -0.12), cycles: 1, spread: 2, wander: 9, wanderCycles: 3, shape: ParticleShape.dot, twinkle: 0.5, opacity: 0.55, fade: 0.08));
}

void _jellies(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, sc = w / 390;
  void jelly(double fx, double fy, double r, int cyc, double ph, Color body, Color shade) {
    final pulse = k.sine(cyc, ph);
    final o = Offset(fx * w + k.sine(2, ph) * 10 * sc, fy * h + k.sine(cyc, ph + 0.25) * 8 * sc);
    final rw = r * sc * (1 + pulse * 0.05), rh = r * sc * 0.8 * (1 - pulse * 0.06);
    final tp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2 * sc
      ..color = body.withValues(alpha: 0.7);
    for (var i = 0; i < 5; i++) {
      final x = o.dx + (i - 2) * rw * 0.36;
      final len = rw * (1.5 + (i % 2) * 0.5);
      final pts = <Offset>[
        for (var j = 0; j <= 4; j++) Offset(x + math.sin(tau * (k.u * 6 + i * 0.2) - j * 1.1) * rw * 0.12 * j, o.dy + rh * 0.2 + len * j / 4),
      ];
      c.drawPath(smoothPath(pts), tp);
    }
    final dome = Path()
      ..moveTo(o.dx - rw, o.dy + rh * 0.25)
      ..arcTo(Rect.fromCenter(center: Offset(o.dx, o.dy + rh * 0.25), width: rw * 2, height: rh * 2), math.pi, math.pi, false)
      ..quadraticBezierTo(o.dx + rw * 0.5, o.dy + rh * 0.5, o.dx, o.dy + rh * 0.32)
      ..quadraticBezierTo(o.dx - rw * 0.5, o.dy + rh * 0.5, o.dx - rw, o.dy + rh * 0.25)
      ..close();
    _cel(c, dome, body.withValues(alpha: 0.9), shade.withValues(alpha: 0.9), rw * 0.14, rh * 0.12);
  }

  jelly(0.8, 0.2, 20, 4, 0.0, _pinkL, _pink);
  jelly(0.62, 0.115, 12, 5, 0.4, _purpleL, _purple);
}
