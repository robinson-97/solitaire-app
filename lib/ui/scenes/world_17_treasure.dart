import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Treasure Cavern in flat, graphic 2D: a vast brown chamber with a ceiling
// opening that pours golden light shafts, giant gold columns, amber veins that
// pulse slowly, a copper stream and heaps of coins and gems. Light comes from
// the upper right (the opening), so every shade side is on the left.

// palette
const _c0 = Color(0xFF120A06), _c1 = Color(0xFF1A0F0A), _c2 = Color(0xFF2A170D), _c3 = Color(0xFF3A2214), _c4 = Color(0xFF55321A), _c5 = Color(0xFF6B3E1C);
const _gold = Color(0xFFFFD36B), _goldMid = Color(0xFFC98A1E), _goldDeep = Color(0xFF7A4A12), _goldShade = Color(0xFF4E2E0E);
const _amber = Color(0xFFFFB02E), _copper = Color(0xFFD9783A), _glow = Color(0xFFFFC24A), _shaft = Color(0xFFFFE29A);
const _ruby = Color(0xFFFF4A5E), _emerald = Color(0xFF3CE08A), _sapphire = Color(0xFF4C8CFF);

// parallax drifts (fractions of the width) shared by a layer and its live overlay
const _dFar = 0.006, _dCol = 0.013, _dCeil = 0.010, _dFloor = 0.02, _dHeap = 0.032;
const _pCol = 0.1, _pCeil = 0.05, _pFloor = 0.2, _pHeap = 0.3;

SceneSpec treasureScene() => SceneSpec(
      focusY: 0.3,
      topShade: 0.12,
      bottomShade: 0.2,
      layers: [
        Layer.still(_wall),
        Layer.live(_veinPulse),
        Layer.scroll(_fogBack, scrollCycles: 1, bandTop: 0.45, bandBottom: 0.8),
        Layer.still(_far, driftX: _dFar, driftCycles: 2),
        Layer.still(_columns, driftX: _dCol, driftCycles: 2, driftPhase: _pCol),
        Layer.still(_ceiling, driftX: _dCeil, driftCycles: 2, driftPhase: _pCeil, sway: 0.003, swayCycles: 4, pivot: Alignment.topCenter),
        Layer.still(_shafts, driftX: _dCeil, driftCycles: 2, driftPhase: _pCeil, sway: 0.003, swayCycles: 4, pivot: Alignment.topCenter),
        Layer.still(_floor, driftX: _dFloor, driftCycles: 2, driftPhase: _pFloor),
        Layer.live(_streamGlints),
        Layer.scroll(_fogFront, scrollCycles: 2, bandTop: 0.78, bandBottom: 1.0),
        Layer.still(_heaps, driftX: _dHeap, driftCycles: 2, driftPhase: _pHeap),
        Layer.live(_fireAndGlitter),
        Layer.live(_dust),
      ],
    );

double _dx(Size s, Clock k, double d, double ph) => d * s.width * k.sine(2, ph);

// ---------------------------------------------------------------- shape helpers

Path _spike(Offset base, double w, double h, {bool down = false, double lean = 0}) {
  final d = down ? 1.0 : -1.0;
  final tx = base.dx + lean * w;
  return smoothPath([
    Offset(base.dx - w / 2, base.dy - d * h * 0.06),
    Offset(base.dx - w * 0.4 + lean * w * 0.3, base.dy + d * h * 0.35),
    Offset(tx - w * 0.1, base.dy + d * h * 0.8),
    Offset(tx, base.dy + d * h),
    Offset(tx + w * 0.1, base.dy + d * h * 0.8),
    Offset(base.dx + w * 0.4 + lean * w * 0.3, base.dy + d * h * 0.35),
    Offset(base.dx + w / 2, base.dy - d * h * 0.06),
  ], closed: true);
}

/// Two-tone cel shading with hard edges: shade on the left, a thin lit strip on
/// the right (light from the upper right).
void _cel(Canvas c, Path p, Color body, Color shade, Color? light, {double shadeFrac = 0.42, double band = 3}) {
  final b = p.getBounds();
  c.drawPath(p, Paint()..color = light ?? body);
  c.save();
  c.clipPath(p);
  c.drawPath(p.shift(Offset(-band, 0)), Paint()..color = body);
  final outside = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(b.inflate(40))
    ..addPath(p.shift(Offset(b.width * shadeFrac, b.width * 0.03)), Offset.zero);
  c.clipPath(outside);
  c.drawRect(b.inflate(2), Paint()..color = shade);
  c.restore();
}

/// Hourglass column from the ceiling to the floor.
Path _column(Size s, double cx, double hwTop, double hwMid, double hwBot, double yTop, double yBot, double yMid, {int seed = 1}) {
  final r = rng(seed);
  final left = <Offset>[], right = <Offset>[];
  const n = 9;
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final y = yTop + (yBot - yTop) * t;
    final m = yMid.clamp(0.2, 0.8);
    double hw;
    if (t < m) {
      final q = t / m;
      hw = hwTop + (hwMid - hwTop) * math.sin(q * math.pi / 2);
    } else {
      final q = (t - m) / (1 - m);
      hw = hwMid + (hwBot - hwMid) * (1 - math.cos(q * math.pi / 2));
    }
    final wob = 1 + (r.nextDouble() - 0.5) * 0.12 + (i.isOdd ? 0.04 : -0.02);
    left.add(Offset(cx - hw * wob, y));
    right.add(Offset(cx + hw * (2 - wob), y));
  }
  return smoothPath([...left, ...right.reversed], closed: true);
}

void _crystal(Canvas c, Offset base, double w, double h, Color body, Color shade, Color light, {double lean = 0}) {
  final tip = Offset(base.dx + lean * w, base.dy - h);
  final p = smoothPath([
    Offset(base.dx - w / 2, base.dy),
    Offset(base.dx - w * 0.52 + lean * w * 0.3, base.dy - h * 0.68),
    tip + Offset(-w * 0.02, h * 0.02),
    tip + Offset(w * 0.02, h * 0.02),
    Offset(base.dx + w * 0.52 + lean * w * 0.3, base.dy - h * 0.68),
    Offset(base.dx + w / 2, base.dy),
  ], closed: true);
  _cel(c, p, body, shade, light, shadeFrac: 0.38, band: math.max(1.5, w * 0.16));
}

void _gem(Canvas c, Offset o, double r, Color col, {double rot = 0}) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(rot);
  final dark = darken(col, 0.16);
  final lite = lighten(col, 0.22);
  final top = Path()
    ..moveTo(-r, -r * 0.2)
    ..lineTo(-r * 0.55, -r * 0.8)
    ..lineTo(r * 0.55, -r * 0.8)
    ..lineTo(r, -r * 0.2)
    ..close();
  final bot = Path()
    ..moveTo(-r, -r * 0.2)
    ..lineTo(r, -r * 0.2)
    ..lineTo(0, r)
    ..close();
  c.drawPath(bot, Paint()..color = dark);
  c.drawPath(top, Paint()..color = col);
  c.drawPath(Path()..moveTo(r * 0.1, -r * 0.8)..lineTo(r * 0.55, -r * 0.8)..lineTo(r, -r * 0.2)..lineTo(r * 0.3, -r * 0.2)..close(), Paint()..color = lite);
  c.drawPath(Path()..moveTo(r * 0.3, -r * 0.2)..lineTo(r, -r * 0.2)..lineTo(0, r)..close(), Paint()..color = col);
  c.restore();
}

void _coin(Canvas c, Offset o, double r, int tone, double tilt) {
  const faces = [_gold, Color(0xFFFFC24A), Color(0xFFEBA52E), Color(0xFFC98A1E)];
  const rims = [Color(0xFFC98A1E), Color(0xFFB87818), Color(0xFF9A6216), Color(0xFF7A4A12)];
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(tilt);
  final ry = r * 0.55;
  c.drawOval(Rect.fromCenter(center: Offset(0, r * 0.22), width: r * 2, height: ry * 2), Paint()..color = rims[tone % 4]);
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: ry * 2), Paint()..color = faces[tone % 4]);
  c.drawOval(Rect.fromCenter(center: Offset(r * 0.1, 0), width: r * 1.1, height: ry * 1.1), Paint()..color = faces[(tone + 1) % 4].withValues(alpha: 0.55));
  c.restore();
}

void _star(Canvas c, Offset o, double r, Color col, double a) {
  if (a <= 0.03) return;
  final rr = r * a;
  final p = Path()
    ..moveTo(o.dx, o.dy - rr)
    ..quadraticBezierTo(o.dx + rr * 0.1, o.dy - rr * 0.1, o.dx + rr, o.dy)
    ..quadraticBezierTo(o.dx + rr * 0.1, o.dy + rr * 0.1, o.dx, o.dy + rr)
    ..quadraticBezierTo(o.dx - rr * 0.1, o.dy + rr * 0.1, o.dx - rr, o.dy)
    ..quadraticBezierTo(o.dx - rr * 0.1, o.dy - rr * 0.1, o.dx, o.dy - rr)
    ..close();
  c.drawPath(p, Paint()..color = col);
}

// ---------------------------------------------------------------- back wall + veins

List<Path>? _veinCache;
Size? _veinSize;

List<Path> _veins(Size s) {
  if (_veinCache != null && _veinSize == s) return _veinCache!;
  final r = rng(91);
  final out = <Path>[];
  final starts = [
    const Offset(0.26, 0.10), const Offset(0.42, 0.06), const Offset(0.78, 0.17), const Offset(0.24, 0.40), const Offset(0.70, 0.46), const Offset(0.5, 0.3),
  ];
  for (var v = 0; v < starts.length; v++) {
    var x = starts[v].dx * s.width, y = starts[v].dy * s.height;
    final pts = <Offset>[Offset(x, y)];
    var dir = (r.nextDouble() - 0.5) * 1.2 + (v.isEven ? 0.4 : -0.4);
    for (var i = 0; i < 11; i++) {
      dir += (r.nextDouble() - 0.5) * 1.6;
      dir *= 0.8;
      x += math.sin(dir) * s.width * 0.035;
      y += math.cos(dir).abs() * s.height * 0.02 + s.height * 0.006;
      pts.add(Offset(x, y));
    }
    out.add(smoothPath(pts));
    final sg = v.isEven ? 1.0 : -1.0;
    final b = pts[4];
    out.add(smoothPath([b, b + Offset(s.width * 0.025 * sg, s.height * 0.012), b + Offset(s.width * 0.05 * sg, s.height * 0.016), b + Offset(s.width * 0.07 * sg, s.height * 0.03), b + Offset(s.width * 0.075 * sg, s.height * 0.05)]));
  }
  _veinCache = out;
  _veinSize = s;
  return out;
}

void _wall(Canvas c, Size s) {
  final w = s.width, h = s.height;
  fillSky(c, s, const [_c0, _c2, _c4, Color(0xFF7A4A22), _c4, _c2], const [0.0, 0.22, 0.46, 0.6, 0.78, 1.0]);
  // distant lit chamber: flat concentric halo rings
  final o = Offset(w * 0.36, h * 0.52);
  for (var i = 4; i >= 0; i--) {
    c.drawOval(Rect.fromCenter(center: o, width: w * (0.34 + i * 0.2), height: h * (0.12 + i * 0.07)), Paint()..color = _glow.withValues(alpha: 0.05 + (4 - i) * 0.018));
  }
  // veins: dark wall cracks filled with amber
  for (final p in _veins(s)) {
    c.drawPath(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6 * w / 390
      ..color = _c1.withValues(alpha: 0.5));
    c.drawPath(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 * w / 390
      ..color = const Color(0xFFC9801E));
  }
}

void _veinPulse(Canvas c, Size s, Clock k) {
  final vs = _veins(s);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.8 * s.width / 390;
  for (var i = 0; i < vs.length; i++) {
    final a = math.pow(k.pulse(3 + (i ~/ 2) % 3, i * 0.137), 2).toDouble();
    p.color = _amber.withValues(alpha: 0.2 + 0.7 * a);
    c.drawPath(vs[i], p);
  }
}

// ---------------------------------------------------------------- fog

void _fogBack(Canvas c, Size s) {
  final w = s.width, h = s.height;
  softEllipse(c, Offset(w * 0.25, h * 0.62), w * 0.7, h * 0.07, const Color(0xFFE0A050), 0.28);
  softEllipse(c, Offset(w * 0.78, h * 0.55), w * 0.6, h * 0.06, const Color(0xFFE0A050), 0.22);
}

void _fogFront(Canvas c, Size s) {
  final w = s.width, h = s.height;
  softEllipse(c, Offset(w * 0.3, h * 0.9), w * 0.8, h * 0.07, const Color(0xFFD08A40), 0.22);
  softEllipse(c, Offset(w * 0.85, h * 0.86), w * 0.5, h * 0.05, const Color(0xFFD08A40), 0.18);
}

// ---------------------------------------------------------------- far chamber

void _far(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // far ceiling stalactites (hazy)
  final r = rng(5);
  final ceilFar = Ridge(s, y: 0.1, amp: 0.02, freq: 2.2, seed: 3);
  final cp = smoothPath(ceilFar.points)
    ..lineTo(ceilFar.points.last.dx, -20)
    ..lineTo(ceilFar.points.first.dx, -20)
    ..close();
  c.drawPath(cp, Paint()..color = _c2);
  for (var x = -0.02 * w; x < w * 1.04; x += w * (0.07 + r.nextDouble() * 0.06)) {
    final len = h * (0.03 + r.nextDouble() * 0.07);
    c.drawPath(_spike(Offset(x, ceilFar.yAt(x) - 6), w * (0.05 + r.nextDouble() * 0.04), len + 6, down: true, lean: (r.nextDouble() - 0.5) * 0.2), Paint()..color = _c2);
  }
  // far arches / pillars in haze
  final pillar = hazeTo(_c4, _glow, 0.18);
  for (final px in [0.30, 0.48, 0.66]) {
    final pth = _column(s, w * px, w * 0.035, w * 0.015, w * 0.045, h * 0.10, h * 0.64, 0.55, seed: (px * 100).round());
    _cel(c, pth, pillar, hazeTo(_c3, _glow, 0.12), hazeTo(_goldMid, _c4, 0.55), shadeFrac: 0.5, band: 2);
  }
  // far floor + stalagmites
  final far = Ridge(s, y: 0.64, amp: 0.018, freq: 2.0, seed: 9);
  for (var x = 0.0; x < w; x += w * (0.06 + r.nextDouble() * 0.07)) {
    c.drawPath(_spike(Offset(x, far.yAt(x) + 6), w * (0.05 + r.nextDouble() * 0.05), h * (0.03 + r.nextDouble() * 0.05) + 6, lean: (r.nextDouble() - 0.5) * 0.2), Paint()..color = hazeTo(_c4, _glow, 0.14));
  }
  flatRidge(c, far, hazeTo(_c4, _glow, 0.14), light: hazeTo(_goldMid, _c4, 0.5), band: 3);
  final far2 = Ridge(s, y: 0.7, amp: 0.016, freq: 2.6, seed: 14, tilt: -0.02);
  flatRidge(c, far2, _c3, light: hazeTo(_c5, _goldMid, 0.4), band: 3);
}

// ---------------------------------------------------------------- hero columns + torches

void _columns(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // right column (further, slimmer)
  final rc = _column(s, w * 0.92, w * 0.11, w * 0.065, w * 0.12, -h * 0.05, h * 0.9, 0.42, seed: 4);
  _cel(c, rc, const Color(0xFFBC7C22), const Color(0xFF6E4012), const Color(0xFFF0BC48), shadeFrac: 0.5, band: 5);
  // left hero column
  final lc = _column(s, w * 0.05, w * 0.15, w * 0.1, w * 0.17, -h * 0.05, h * 0.92, 0.38, seed: 8);
  _cel(c, lc, const Color(0xFFD9962A), _goldDeep, _gold, shadeFrac: 0.45, band: 5);
  // flowstone ridges on columns (flat rounded bands)
  final r = rng(12);
  for (var i = 0; i < 7; i++) {
    final y = h * (0.12 + i * 0.1 + r.nextDouble() * 0.03);
    final x = w * 0.07 + (r.nextDouble() - 0.4) * w * 0.07;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: w * (0.07 + r.nextDouble() * 0.05), height: 5), const Radius.circular(3)), Paint()..color = _goldDeep.withValues(alpha: 0.7));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + w * 0.02, y - 4), width: w * 0.04, height: 2.5), const Radius.circular(2)), Paint()..color = _gold.withValues(alpha: 0.8));
  }
  for (var i = 0; i < 5; i++) {
    final y = h * (0.15 + i * 0.12 + r.nextDouble() * 0.03);
    final x = w * 0.95 + (r.nextDouble() - 0.5) * w * 0.05;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: w * 0.06, height: 4.5), const Radius.circular(3)), Paint()..color = const Color(0xFF5E3610).withValues(alpha: 0.7));
  }
  // amber veins glowing in the columns
  for (final seg in [
    [Offset(w * 0.04, h * 0.16), Offset(w * 0.09, h * 0.24), Offset(w * 0.06, h * 0.33), Offset(w * 0.11, h * 0.42)],
    [Offset(w * 0.9, h * 0.18), Offset(w * 0.94, h * 0.27), Offset(w * 0.9, h * 0.36)],
  ]) {
    c.drawPath(smoothPath(seg), Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2
      ..color = _amber);
    c.drawPath(smoothPath(seg), Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = _shaft);
  }
  // torch brackets
  for (final t in _torches(s)) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: t + Offset(0, 16), width: 5, height: 26), const Radius.circular(2.5)), Paint()..color = _goldShade);
    final bowl = Path()
      ..moveTo(t.dx - 10, t.dy - 2)
      ..quadraticBezierTo(t.dx - 8, t.dy + 10, t.dx, t.dy + 10)
      ..quadraticBezierTo(t.dx + 8, t.dy + 10, t.dx + 10, t.dy - 2)
      ..close();
    c.drawPath(bowl, Paint()..color = _c1);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: t + Offset(0, -2), width: 22, height: 4.5), const Radius.circular(2)), Paint()..color = _goldDeep);
  }
  // crystal clusters at the column bases
  _crystalCluster(c, Offset(w * 0.2, h * 0.805), w, seed: 1, scale: 1.0);
  _crystalCluster(c, Offset(w * 0.8, h * 0.805), w, seed: 2, scale: 0.8);
  // gem pockets in the wall
  _gem(c, Offset(w * 0.05, h * 0.52), 6, _sapphire, rot: -0.3);
  _gem(c, Offset(w * 0.1, h * 0.56), 4.5, _sapphire, rot: 0.2);
  _gem(c, Offset(w * 0.955, h * 0.5), 5.5, _ruby, rot: 0.3);
  _gem(c, Offset(w * 0.915, h * 0.455), 4, _emerald, rot: -0.2);
}

List<Offset> _torches(Size s) => [Offset(s.width * 0.205, s.height * 0.285), Offset(s.width * 0.775, s.height * 0.31)];

void _crystalCluster(Canvas c, Offset base, double w, {int seed = 1, double scale = 1}) {
  final r = rng(seed * 11);
  final k = w / 390 * scale;
  const bodies = [Color(0xFFFFB02E), Color(0xFFFFC24A), Color(0xFFE8962A)];
  for (var i = 0; i < 5; i++) {
    final dx = (i - 2) * 11 * k + (r.nextDouble() - 0.5) * 5 * k;
    final hh = (28 - (i - 2).abs() * 7 + r.nextDouble() * 8) * k;
    _crystal(c, base + Offset(dx, 0), (11 + r.nextDouble() * 3) * k, hh, bodies[i % 3], _goldMid, const Color(0xFFFFF0B8), lean: (i - 2) * 0.12);
  }
}

// ---------------------------------------------------------------- ceiling

void _ceiling(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(33);
  // back row of stalactites (lighter, further)
  final back = Ridge(s, y: 0.075, amp: 0.02, freq: 2.8, seed: 21, x0: -0.15, x1: 1.15);
  final bp = smoothPath(back.points)
    ..lineTo(back.points.last.dx, -30)
    ..lineTo(back.points.first.dx, -30)
    ..close();
  c.drawPath(bp, Paint()..color = _c3);
  for (var x = -0.1 * w; x < w * 1.1; x += w * (0.05 + r.nextDouble() * 0.05)) {
    final len = h * (0.04 + r.nextDouble() * 0.09);
    _cel(c, _spike(Offset(x, back.yAt(x) - 8), w * (0.05 + r.nextDouble() * 0.04), len + 8, down: true, lean: (r.nextDouble() - 0.5) * 0.25), _c4, _c3, _goldDeep, shadeFrac: 0.5, band: 2);
  }
  // the opening in the roof (light comes in here)
  final oc = Offset(w * 0.7, h * 0.0);
  c.drawOval(Rect.fromCenter(center: oc + Offset(0, h * 0.012), width: w * 0.4, height: h * 0.1), Paint()..color = _goldDeep);
  c.drawOval(Rect.fromCenter(center: oc, width: w * 0.35, height: h * 0.085), Paint()..color = _gold);
  c.drawOval(Rect.fromCenter(center: oc + Offset(w * 0.02, -h * 0.01), width: w * 0.3, height: h * 0.07), Paint()..color = const Color(0xFFFFF4CC));
  // front row: darker, bigger stalactites; every third one is gold
  final front = Ridge(s, y: 0.045, amp: 0.022, freq: 3.4, seed: 5, x0: -0.15, x1: 1.15);
  final fp = smoothPath(front.points)
    ..lineTo(front.points.last.dx, -30)
    ..lineTo(front.points.first.dx, -30)
    ..close();
  c.save();
  // keep the opening free
  final hole = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTWH(-w, -100, w * 3, h))
    ..addOval(Rect.fromCenter(center: oc, width: w * 0.3, height: h * 0.07));
  c.clipPath(hole);
  c.drawPath(fp, Paint()..color = _c1);
  c.restore();
  var i = 0;
  for (var x = -0.1 * w; x < w * 1.1; x += w * (0.06 + r.nextDouble() * 0.06)) {
    i++;
    if ((x - oc.dx).abs() < w * 0.15) continue;
    final len = h * (0.03 + r.nextDouble() * 0.1) * (i % 4 == 0 ? 1.5 : 1);
    final bw = w * (0.05 + r.nextDouble() * 0.05);
    final sp = _spike(Offset(x, front.yAt(x) - 8), bw, len + 8, down: true, lean: (r.nextDouble() - 0.5) * 0.2);
    if (i % 3 == 0) {
      _cel(c, sp, _goldMid, _goldDeep, _gold, shadeFrac: 0.5, band: 2.5);
    } else {
      _cel(c, sp, _c2, _c0, _c5, shadeFrac: 0.5, band: 2);
    }
  }
  // lip of the opening: lit rim
  c.drawArc(Rect.fromCenter(center: oc, width: w * 0.36, height: h * 0.082), 0.15, math.pi - 0.3, false, Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.5
    ..color = _gold);
}

// ---------------------------------------------------------------- light shafts

void _shafts(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final top = h * 0.04, bot = h * 0.83;
  final slant = -w * 0.34;
  // soft haze around the opening
  final oc = Offset(w * 0.7, 0);
  c.drawOval(Rect.fromCenter(center: oc, width: w * 0.32, height: h * 0.075), Paint()..color = const Color(0xFFFFE9A8));
  c.drawOval(Rect.fromCenter(center: oc + Offset(w * 0.02, -h * 0.004), width: w * 0.2, height: h * 0.048), Paint()..color = const Color(0xFFFFF6D6));
  const defs = [
    [0.60, 0.70, 0.22, 0.14, 0.15],
    [0.66, 0.84, 0.30, 0.18, 0.11],
    [0.74, 0.80, 0.52, 0.12, 0.1],
    [0.54, 0.60, 0.10, 0.06, 0.1],
  ];
  for (final d in defs) {
    final p = Path()
      ..moveTo(w * d[0], top)
      ..lineTo(w * d[1], top)
      ..lineTo(w * d[1] + slant * (0.85 + d[2]) + w * d[3] * 0.5, bot)
      ..lineTo(w * d[0] + slant * (0.85 + d[2]) - w * d[3] * 0.5, bot)
      ..close();
    c.drawPath(p, Paint()..color = _glow.withValues(alpha: d[4] * 1.15));
  }
  // lit pool where the shafts land
  c.drawOval(Rect.fromCenter(center: Offset(w * 0.34, h * 0.835), width: w * 0.55, height: h * 0.04), Paint()..color = _shaft.withValues(alpha: 0.13));
  c.drawOval(Rect.fromCenter(center: Offset(w * 0.36, h * 0.835), width: w * 0.32, height: h * 0.022), Paint()..color = _shaft.withValues(alpha: 0.15));
}

// ---------------------------------------------------------------- floor + stream

List<Offset> _streamC(Size s) {
  final w = s.width, h = s.height;
  return [Offset(-w * 0.15, h * 0.842), Offset(w * 0.15, h * 0.83), Offset(w * 0.4, h * 0.845), Offset(w * 0.65, h * 0.835), Offset(w * 0.9, h * 0.815), Offset(w * 1.2, h * 0.822)];
}

List<double> _streamW(Size s) => [for (final v in [0.03, 0.03, 0.033, 0.03, 0.026, 0.026]) s.height * v];

void _floor(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(61);
  final f1 = Ridge(s, y: 0.745, amp: 0.012, freq: 2.2, seed: 6, tilt: 0.02);
  flatRidge(c, f1, _c3, light: _c5, band: 3);
  for (var x = w * 0.05; x < w * 1.1; x += w * (0.09 + r.nextDouble() * 0.09)) {
    _cel(c, _spike(Offset(x, f1.yAt(x) + 4), w * 0.06, h * (0.03 + r.nextDouble() * 0.04), lean: (r.nextDouble() - 0.5) * 0.2), _c4, _c3, _goldMid, shadeFrac: 0.5, band: 2);
  }
  final f2 = Ridge(s, y: 0.79, amp: 0.012, freq: 1.8, seed: 17, tilt: -0.015);
  flatRidge(c, f2, _c2, light: hazeTo(_c5, _goldDeep, 0.4), band: 3);
  // the stream: copper water with flat reflected gold
  final cl = _streamC(s), hw = _streamW(s);
  flatRibbon(c, cl, hw, color: const Color(0xFF8A4A1E), bank: _goldDeep);
  final ribbon = _ribbonPath(cl, hw);
  c.save();
  c.clipPath(ribbon);
  c.drawRect(Rect.fromLTRB(0, h * 0.84, w * 1.2, h * 0.9), Paint()..color = const Color(0xFF6F3A18));
  // reflected light shafts (flat parallelograms)
  for (final d in [[0.18, 0.1], [0.4, 0.06], [0.5, 0.04]]) {
    final p = Path()
      ..moveTo(w * d[0], h * 0.79)
      ..lineTo(w * (d[0] + d[1]), h * 0.79)
      ..lineTo(w * (d[0] + d[1] * 1.3 - 0.05), h * 0.9)
      ..lineTo(w * (d[0] - 0.05 - d[1] * 0.3), h * 0.9)
      ..close();
    c.drawPath(p, Paint()..color = _gold.withValues(alpha: 0.4));
  }
  final rr = rng(70);
  for (var i = 0; i < 28; i++) {
    final x = rr.nextDouble() * w * 1.1;
    final y = h * (0.815 + rr.nextDouble() * 0.05);
    final len = w * (0.04 + rr.nextDouble() * 0.09);
    final col = i % 3 == 0 ? _gold : (i % 3 == 1 ? _copper : _amber);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: len, height: 2.6 + rr.nextDouble() * 2), const Radius.circular(3)), Paint()..color = col.withValues(alpha: 0.8));
  }
  c.restore();
  // stones in the water
  for (final q in [[0.58, 0.855], [0.72, 0.83], [0.3, 0.852]]) {
    c.drawOval(Rect.fromCenter(center: Offset(w * q[0], h * q[1]), width: w * 0.07, height: h * 0.012), Paint()..color = _c2);
    c.drawOval(Rect.fromCenter(center: Offset(w * q[0] + 2, h * q[1] - 2), width: w * 0.055, height: h * 0.008), Paint()..color = _c4);
  }
  // near bank of the stream
  final nb = Ridge(s, y: 0.9, amp: 0.012, freq: 1.6, seed: 23, tilt: 0.01);
  flatRidge(c, nb, _c1, light: _c4, band: 3);
}

Path _ribbonPath(List<Offset> centre, List<double> halfWidth) {
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i < centre.length; i++) {
    final a = centre[math.max(i - 1, 0)], b = centre[math.min(i + 1, centre.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    left.add(centre[i] - n * halfWidth[i]);
    right.add(centre[i] + n * halfWidth[i]);
  }
  return smoothPath([...left, ...right.reversed], closed: true);
}

Offset _along(List<Offset> pts, double t) {
  final f = t * (pts.length - 1);
  final i = f.floor().clamp(0, pts.length - 2);
  return Offset.lerp(pts[i], pts[i + 1], f - i)!;
}

double _lerpW(List<double> w, double t) {
  final f = t * (w.length - 1);
  final i = f.floor().clamp(0, w.length - 2);
  return w[i] + (w[i + 1] - w[i]) * (f - i);
}

void _streamGlints(Canvas c, Size s, Clock k) {
  c.save();
  c.translate(_dx(s, k, _dFloor, _pFloor), 0);
  final cl = _streamC(s), hw = _streamW(s);
  final r = rng(81);
  final p = Paint();
  for (var i = 0; i < 22; i++) {
    final t = 0.1 + r.nextDouble() * 0.85;
    final pos = _along(cl, t);
    final off = (r.nextDouble() - 0.5) * _lerpW(hw, t) * 1.5;
    final ph = r.nextDouble();
    final a = math.pow(k.pulse(8 + i % 5, ph), 3).toDouble();
    if (a < 0.05) continue;
    final wdt = (7 + r.nextDouble() * 18) * (0.5 + t);
    final dx = k.sine(3 + i % 3, ph) * 4;
    p.color = (i % 2 == 0 ? _shaft : const Color(0xFFFFF4CC)).withValues(alpha: 0.9 * a);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos + Offset(off + dx, 0), width: wdt, height: 1.8 + t * 1.6), const Radius.circular(1.5)), p);
  }
  c.restore();
}

// ---------------------------------------------------------------- coin heaps

double _heapTop(Size s, double x, double cx, double sw, double peak) {
  final u = (x - cx) / sw;
  return s.height * 1.03 - peak * math.exp(-math.pow(u.abs(), 2.3)) - math.sin(x * 0.09) * 1.5;
}

void _heap(Canvas c, Size s, double cx, double sw, double peak, int seed, double coinR, {void Function()? mid, double midY = 0}) {
  final h = s.height;
  final pts = <Offset>[];
  for (var x = cx - sw * 2.4; x <= cx + sw * 2.4; x += 8) {
    pts.add(Offset(x, _heapTop(s, x, cx, sw, peak)));
  }
  final body = smoothPath(pts)
    ..lineTo(pts.last.dx, h * 1.1)
    ..lineTo(pts.first.dx, h * 1.1)
    ..close();
  c.drawPath(body, Paint()..color = _goldDeep);
  final r = rng(seed);
  final coins = <(Offset, int, double, double)>[];
  for (var i = 0; i < 420; i++) {
    final x = cx + (r.nextDouble() - 0.5) * sw * 4.8;
    final top = _heapTop(s, x, cx, sw, peak);
    final y = top + 2 + r.nextDouble() * (h * 1.04 - top);
    if (y > h * 1.02) continue;
    final depth = (y - top) / (h * 1.04 - top + 1);
    coins.add((Offset(x, y), math.min(3, r.nextInt(3) + (depth * 2.2).floor()), (r.nextDouble() - 0.5) * 0.9, coinR * (0.8 + r.nextDouble() * 0.5)));
  }
  coins.sort((a, b) => a.$1.dy.compareTo(b.$1.dy));
  c.save();
  c.clipPath(body);
  var midDone = mid == null;
  for (final q in coins) {
    if (!midDone && q.$1.dy > midY) {
      midDone = true;
      c.restore();
      mid!();
      c.save();
      c.clipPath(body);
    }
    _coin(c, q.$1, q.$4, q.$2, q.$3);
  }
  c.restore();
  for (var i = 0; i < 16; i++) {
    final x = cx + (r.nextDouble() - 0.5) * sw * 3.0;
    _coin(c, Offset(x, _heapTop(s, x, cx, sw, peak) + 1), coinR * (0.9 + r.nextDouble() * 0.4), r.nextInt(2), (r.nextDouble() - 0.5) * 1.1);
  }
  final g = rng(seed + 5);
  const cols = [_ruby, _emerald, _sapphire, _ruby, _emerald];
  for (var i = 0; i < 8; i++) {
    final x = cx + (g.nextDouble() - 0.5) * sw * 2.8;
    final top = _heapTop(s, x, cx, sw, peak);
    _gem(c, Offset(x, top + 6 + g.nextDouble() * 30), 5 + g.nextDouble() * 3.5, cols[i % 5], rot: (g.nextDouble() - 0.5) * 0.8);
  }
}

void _chest(Canvas c, Offset b, double k) {
  final bw = 44 * k, bh = 22 * k;
  final body = RRect.fromRectAndRadius(Rect.fromLTWH(b.dx - bw / 2, b.dy - bh, bw, bh), Radius.circular(3 * k));
  c.drawRRect(body, Paint()..color = const Color(0xFF8A4A22));
  c.save();
  c.clipRRect(body);
  c.drawRect(Rect.fromLTWH(b.dx - bw / 2, b.dy - bh, bw * 0.4, bh), Paint()..color = const Color(0xFF5E3014));
  c.restore();
  final lid = Path()
    ..moveTo(b.dx - bw / 2 - 1 * k, b.dy - bh)
    ..quadraticBezierTo(b.dx - bw / 2, b.dy - bh - 20 * k, b.dx, b.dy - bh - 20 * k)
    ..quadraticBezierTo(b.dx + bw / 2, b.dy - bh - 20 * k, b.dx + bw / 2 + 1 * k, b.dy - bh)
    ..close();
  c.drawPath(lid, Paint()..color = const Color(0xFFA9602B));
  c.save();
  c.clipPath(lid);
  c.drawRect(Rect.fromLTWH(b.dx - bw / 2 - 2, b.dy - bh - 22 * k, bw * 0.42, 24 * k), Paint()..color = const Color(0xFF7A4020));
  c.restore();
  for (final dx in [-0.3, 0.3]) {
    c.drawRect(Rect.fromLTWH(b.dx + bw * dx - 2.5 * k, b.dy - bh - 18 * k, 5 * k, bh + 18 * k), Paint()..color = _goldMid);
    c.drawRect(Rect.fromLTWH(b.dx + bw * dx + 0.5 * k, b.dy - bh - 18 * k, 2 * k, bh + 18 * k), Paint()..color = _gold);
  }
  c.drawRect(Rect.fromLTWH(b.dx - bw / 2, b.dy - bh - 2 * k, bw, 4 * k), Paint()..color = _goldMid);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(b.dx, b.dy - bh), width: 8 * k, height: 9 * k), Radius.circular(2 * k)), Paint()..color = _gold);
  c.drawCircle(Offset(b.dx, b.dy - bh), 1.4 * k, Paint()..color = _goldShade);
}

void _heaps(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _crystalCluster(c, Offset(w * 0.52, h * 0.955), w, seed: 5, scale: 1.5);
  _crystalCluster(c, Offset(w * 0.64, h * 0.975), w, seed: 6, scale: 1.1);
  _heap(c, s, w * 0.2, w * 0.3, h * 0.19, 3, 9.5 * w / 390);
  final chestBase = Offset(w * 0.8, _heapTop(s, w * 0.8, w * 0.86, w * 0.3, h * 0.12) + 14);
  _heap(c, s, w * 0.86, w * 0.3, h * 0.12, 9, 8.5 * w / 390, mid: () => _chest(c, chestBase, w / 390 * 1.2), midY: chestBase.dy - 3);
  // the bottom-edge rock to anchor the frame
  final front = Ridge(s, y: 1.0, amp: 0.012, freq: 3.0, seed: 52, x0: -0.15, x1: 1.15);
  flatRidge(c, front, _c0, light: _c2, band: 2);
}

// ---------------------------------------------------------------- live: fire + glitter

void _flame(Canvas c, Offset o, Clock k, int seed) {
  final f1 = k.sine(31 + seed, seed * 0.3), f2 = k.sine(47 + seed, seed * 0.7), f3 = k.sine(19, seed * 0.5);
  final hgt = 22 + f1 * 2.5 + f3 * 1.5;
  final lean = f2 * 2.2;
  // flat halo rings
  final breathe = 1 + 0.04 * k.sine(6, seed * 0.2);
  c.drawCircle(o + const Offset(0, -10), 64 * breathe, Paint()..color = _glow.withValues(alpha: 0.06));
  c.drawCircle(o + const Offset(0, -10), 42 * breathe, Paint()..color = _glow.withValues(alpha: 0.1));
  c.drawCircle(o + const Offset(0, -10), 26 * breathe, Paint()..color = _glow.withValues(alpha: 0.16));
  Path drop(double w, double hh, double lean) => Path()
    ..moveTo(o.dx - w, o.dy)
    ..cubicTo(o.dx - w * 1.1, o.dy - hh * 0.4, o.dx - w * 0.2 + lean * 0.3, o.dy - hh * 0.7, o.dx + lean, o.dy - hh)
    ..cubicTo(o.dx + w * 0.2 + lean * 0.3, o.dy - hh * 0.7, o.dx + w * 1.1, o.dy - hh * 0.4, o.dx + w, o.dy)
    ..quadraticBezierTo(o.dx, o.dy + w * 0.5, o.dx - w, o.dy)
    ..close();
  c.drawPath(drop(8.5, hgt, lean), Paint()..color = const Color(0xFFFF8A2A));
  c.drawPath(drop(5.6, hgt * 0.72, lean * 0.7), Paint()..color = _glow);
  c.drawPath(drop(2.9, hgt * 0.42, lean * 0.4), Paint()..color = const Color(0xFFFFF3C4));
  // rising embers
  final p = Paint();
  for (var i = 0; i < 3; i++) {
    final t = k.saw(6 + i, i * 0.31 + seed * 0.17);
    p.color = _glow.withValues(alpha: (1 - t) * 0.9);
    c.drawCircle(o + Offset(math.sin(t * 6 + i + seed) * 5 + lean, -hgt * 0.6 - t * 34), 1.4 * (1 - t * 0.5), p);
  }
}

void _glitter(Canvas c, Offset o, double r, Clock k, int i, Color col) {
  final a = math.pow(k.pulse(11 + i % 6, (i * 0.6180339) % 1.0), 4).toDouble();
  _star(c, o, r, col, a);
}

void _fireAndGlitter(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  // torches ride with the column layer
  c.save();
  c.translate(_dx(s, k, _dCol, _pCol), 0);
  final ts = _torches(s);
  for (var i = 0; i < ts.length; i++) {
    _flame(c, ts[i] + Offset(0, -1), k, i);
  }
  final cr = rng(3);
  for (var i = 0; i < 9; i++) {
    final o = Offset(w * (i < 5 ? 0.02 + cr.nextDouble() * 0.2 : 0.8 + cr.nextDouble() * 0.19), h * (0.1 + cr.nextDouble() * 0.7));
    _glitter(c, o, (4.5 + cr.nextDouble() * 3) * k0, k, i, _shaft);
  }
  // crystal clusters
  for (var i = 0; i < 4; i++) {
    final base = i < 2 ? Offset(w * 0.2, h * 0.805) : Offset(w * 0.8, h * 0.805);
    _glitter(c, base + Offset((i % 2 - 0.5) * 20 * k0, -22 * k0), 5.5 * k0, k, 20 + i, Colors.white);
  }
  c.restore();
  // back-wall gold veins glitter (static layer)
  final vr = rng(15);
  for (var i = 0; i < 6; i++) {
    final o = Offset(w * (0.1 + vr.nextDouble() * 0.8), h * (0.1 + vr.nextDouble() * 0.45));
    _glitter(c, o, (3.5 + vr.nextDouble() * 2) * k0, k, 30 + i, _gold);
  }
  // heaps
  c.save();
  c.translate(_dx(s, k, _dHeap, _pHeap), 0);
  final hr = rng(26);
  for (var i = 0; i < 18; i++) {
    final left = i < 11;
    final cx = left ? w * 0.2 : w * 0.86;
    final sw = left ? w * 0.3 : w * 0.3;
    final peak = left ? h * 0.19 : h * 0.12;
    final x = cx + (hr.nextDouble() - 0.5) * sw * 2.6;
    final y = _heapTop(s, x, cx, sw, peak) + 4 + hr.nextDouble() * 22;
    _glitter(c, Offset(x, y), (4 + hr.nextDouble() * 4) * k0, k, 40 + i, i % 3 == 0 ? Colors.white : _shaft);
  }
  c.restore();
}

// ---------------------------------------------------------------- dust in the light

void _dust(Canvas c, Size s, Clock k) {
  paintParticles(
    c,
    s,
    k,
    const ParticleSpec(
      count: 46,
      seed: 12,
      colors: [_shaft, Color(0xFFFFF4CC), _glow],
      minSize: 0.9,
      maxSize: 2.2,
      flow: Offset(-0.03, -0.12),
      cycles: 2,
      spread: 3,
      wander: 9,
      twinkle: 0.6,
      shape: ParticleShape.dot,
      region: Rect.fromLTRB(0.1, 0.06, 0.88, 0.86),
      fade: 0.2,
      opacity: 0.85,
    ),
  );
}
