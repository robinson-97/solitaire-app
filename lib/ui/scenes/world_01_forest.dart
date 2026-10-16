import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit.dart';

// Enchanted Forest: golden light falls through ancient trees onto a mossy
// stream with a little waterfall; fireflies and pollen drift in the sunbeams.

const _sun = Offset(0.64, 0.30); // fractions of the screen
const _haze = Color(0xFFBFE6C9);

SceneSpec forestScene() => SceneSpec(
      focusY: -0.15,
      layers: [
        Layer.still(_sky),
        Layer.still(_hills, driftX: 0.006, driftCycles: 2),
        Layer.still(_rays, rotate: 0.035, swayCycles: 3, pivot: Alignment(0.28, -0.4)),
        Layer.still(_farTrees, driftX: 0.01, driftCycles: 2, sway: 0.004, swayCycles: 5),
        Layer.live(_farMist),
        Layer.still(_midTrees, driftX: 0.016, driftCycles: 2, driftPhase: 0.1, sway: 0.006, swayCycles: 4, swayPhase: 0.3),
        Layer.still(_cliff, driftX: 0.02, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_waterfall),
        Layer.still(_stream, driftX: 0.024, driftCycles: 2, driftPhase: 0.2),
        Layer.live(_shimmer),
        Layer.still(_banks, driftX: 0.03, driftCycles: 2, driftPhase: 0.25),
        Layer.live(_pollen),
        Layer.still(_giants, driftX: 0.04, driftCycles: 2, driftPhase: 0.3, sway: 0.003, swayCycles: 6),
        Layer.live(_fireflies),
        Layer.live(_nearMist),
      ],
    );

// ---------------------------------------------------------------- sky & far

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [Color(0xFF1B6C8C), Color(0xFF3FA3A8), Color(0xFF9CDBB8), Color(0xFFFFE9A6), Color(0xFFFFF1C4)], const [0.0, 0.22, 0.38, 0.5, 1.0]);
  final o = Offset(_sun.dx * s.width, _sun.dy * s.height);
  glow(c, o, s.width * 1.5, const Color(0xFFFFD27A), 0.5);
  glow(c, o, s.width * 0.8, const Color(0xFFFFE9A6), 0.7);
  c.drawCircle(o, s.width * 0.085, radialPaint(o, s.width * 0.085, const [Color(0xFFFFFFF0), Color(0xFFFFF0B8)], const [0.6, 1.0]));
  // wispy morning clouds
  final r = rng(3);
  for (var i = 0; i < 5; i++) {
    final cs = CloudSprite(s.width * (0.35 + r.nextDouble() * 0.25), seed: i + 2, top: const Color(0xFFFFF7DC), bottom: const Color(0xFFBFE6D2), puff: 0.7);
    cs.draw(c, Offset(s.width * (r.nextDouble() * 1.1), s.height * (0.06 + r.nextDouble() * 0.2)), opacity: 0.5);
  }
}

void _hills(Canvas c, Size s) {
  final h = s.height;
  final far = Ridge(s, y: 0.40, amp: 0.035, freq: 1.6, seed: 11, octaves: 3);
  paintRidge(c, far, top: const Color(0xFF8FCDB2), bottom: const Color(0xFFB5E2C0), rim: Colors.white, rimAlpha: 0.35);
  final mid = Ridge(s, y: 0.43, amp: 0.03, freq: 2.2, seed: 5, octaves: 3);
  paintRidge(c, mid, top: const Color(0xFF6DB79C), bottom: const Color(0xFF9ED6B3), rim: const Color(0xFFFFF1C0), rimAlpha: 0.4);
  paintMist(c, Rect.fromLTRB(0, 0.38 * h, s.width, 0.5 * h), _haze, 0.55);
}

void _rays(Canvas c, Size s) {
  final o = Offset(_sun.dx * s.width, _sun.dy * s.height);
  paintRays(c, o, length: s.height * 0.95, centerAngle: math.pi * 0.52, spread: 1.7, count: 9, opacity: 0.22, color: const Color(0xFFFFEBB0), seed: 9, minWidth: 0.06, maxWidth: 0.16);
  paintRays(c, o, length: s.height * 0.7, centerAngle: math.pi * 0.5, spread: 1.2, count: 5, opacity: 0.16, color: const Color(0xFFFFFFFF), seed: 4, minWidth: 0.03, maxWidth: 0.07);
}

// ---------------------------------------------------------------- trees

void _treeRow(
  Canvas c,
  Size s, {
  required double baseY,
  required double minH,
  required double maxH,
  required int seed,
  required Color leaf,
  required Color light,
  required Color ground,
  double hazeAmt = 0,
  double gap = 0.55,
  double pineShare = 0.35,
  Color trunk = const Color(0xFF5A4332),
}) {
  final r = rng(seed);
  final hz = _haze;
  final ridge = Ridge(s, y: baseY + 0.004, amp: 0.012, freq: 3, seed: seed + 50);
  var x = -s.width * 0.08;
  while (x < s.width * 1.08) {
    final h = (minH + r.nextDouble() * (maxH - minH)) * s.height;
    final base = Offset(x, ridge.yAt(x) + 2);
    if (r.nextDouble() < pineShare) {
      paintPine(c, base, h * 1.05, dark: hazeTo(darken(leaf, 0.05), hz, hazeAmt), light: hazeTo(light, hz, hazeAmt), trunk: hazeTo(trunk, hz, hazeAmt), tiers: 4, width: 0.46);
    } else {
      paintRoundTree(c, base, h, leaf: hazeTo(leaf, hz, hazeAmt), light: hazeTo(light, hz, hazeAmt), trunk: hazeTo(trunk, hz, hazeAmt), seed: r.nextInt(999), lean: (r.nextDouble() - 0.5) * 0.3);
    }
    x += h * gap * (0.7 + r.nextDouble() * 0.6);
  }
  paintRidge(c, ridge, top: hazeTo(ground, hz, hazeAmt * 0.8), bottom: hazeTo(darken(ground, 0.06), hz, hazeAmt * 0.8));
}

void _farTrees(Canvas c, Size s) {
  _treeRow(c, s, baseY: 0.49, minH: 0.08, maxH: 0.14, seed: 21, leaf: const Color(0xFF2F8C6A), light: const Color(0xFF8ED8A6), ground: const Color(0xFF4FA583), hazeAmt: 0.55, pineShare: 0.5);
  _treeRow(c, s, baseY: 0.53, minH: 0.10, maxH: 0.17, seed: 22, leaf: const Color(0xFF237D58), light: const Color(0xFF86D494), ground: const Color(0xFF3E9A72), hazeAmt: 0.38, pineShare: 0.4);
}

void _midTrees(Canvas c, Size s) {
  _treeRow(c, s, baseY: 0.58, minH: 0.14, maxH: 0.22, seed: 31, leaf: const Color(0xFF1B7A4C), light: const Color(0xFF86D95A), ground: const Color(0xFF2E8F5B), hazeAmt: 0.2, gap: 0.6);
  _treeRow(c, s, baseY: 0.63, minH: 0.17, maxH: 0.27, seed: 32, leaf: const Color(0xFF16683F), light: const Color(0xFF7FD25A), ground: const Color(0xFF247C4A), hazeAmt: 0.08, gap: 0.65, pineShare: 0.2);
}

// ---------------------------------------------------------------- waterfall & stream

const _fallTop = Offset(0.60, 0.545);
const _poolC = Offset(0.60, 0.665);

void _cliff(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // mossy rock face behind the fall
  final rock = Path()
    ..moveTo(w * 0.36, h * 0.69)
    ..quadraticBezierTo(w * 0.34, h * 0.56, w * 0.44, h * 0.535)
    ..quadraticBezierTo(w * 0.55, h * 0.50, w * 0.68, h * 0.53)
    ..quadraticBezierTo(w * 0.84, h * 0.55, w * 0.86, h * 0.69)
    ..close();
  c.drawPath(rock, verticalPaint(rock.getBounds(), const [Color(0xFF8C8F88), Color(0xFF5E6358), Color(0xFF3F4A3E)], const [0.0, 0.5, 1.0]));
  shadeInside(c, rock, light: const Offset(0.8, -0.8), lightColor: const Color(0xFFFFE9B0), lightAlpha: 0.3, shadowAlpha: 0.35);
  // moss cap
  final moss = Path()
    ..moveTo(w * 0.36, h * 0.575)
    ..quadraticBezierTo(w * 0.40, h * 0.525, w * 0.5, h * 0.52)
    ..quadraticBezierTo(w * 0.6, h * 0.50, w * 0.7, h * 0.52)
    ..quadraticBezierTo(w * 0.83, h * 0.535, w * 0.855, h * 0.6)
    ..quadraticBezierTo(w * 0.75, h * 0.56, w * 0.64, h * 0.575)
    ..quadraticBezierTo(w * 0.5, h * 0.59, w * 0.36, h * 0.575)
    ..close();
  c.drawPath(moss, verticalPaint(moss.getBounds(), const [Color(0xFF8BD65A), Color(0xFF2F9455)]));
  // rim light on the moss
  c.drawPath(
    Path()
      ..moveTo(w * 0.42, h * 0.53)
      ..quadraticBezierTo(w * 0.58, h * 0.495, w * 0.7, h * 0.52)
      ..quadraticBezierTo(w * 0.8, h * 0.53, w * 0.845, h * 0.585),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFFFF3C2).withValues(alpha: 0.6),
  );
  // smooth boulders at the foot
  paintRock(c, Offset(w * 0.42, h * 0.695), w * 0.16, h * 0.04, seed: 3, color: const Color(0xFF7C8279), light: const Color(0xFFB9C0AF));
  paintRock(c, Offset(w * 0.79, h * 0.70), w * 0.2, h * 0.05, seed: 8, color: const Color(0xFF727866), light: const Color(0xFFB2BCA3));
  // pool
  final pool = Rect.fromCenter(center: Offset(_poolC.dx * w, _poolC.dy * h + 4), width: w * 0.34, height: h * 0.05);
  c.drawOval(pool, verticalPaint(pool, const [Color(0xFF7FE6E0), Color(0xFF1AA6B0)]));
  c.drawOval(pool.deflate(2), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = Colors.white.withValues(alpha: 0.4));
}

void _waterfall(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final topY = _fallTop.dy * h, botY = (_poolC.dy - 0.004) * h;
  final cx = _fallTop.dx * w;
  final half = w * 0.05;
  // translucent body
  final body = Path()
    ..moveTo(cx - half, topY)
    ..quadraticBezierTo(cx - half * 1.1, (topY + botY) / 2, cx - half * 1.25, botY)
    ..lineTo(cx + half * 1.25, botY)
    ..quadraticBezierTo(cx + half * 1.1, (topY + botY) / 2, cx + half, topY)
    ..close();
  c.drawPath(body, verticalPaint(body.getBounds(), const [Color(0xFFF2FFFF), Color(0xFFB6F0F2), Color(0xFF7FDCE4)]));
  // flowing streaks
  c.save();
  c.clipPath(body);
  final r = rng(17);
  for (var i = 0; i < 9; i++) {
    final x = cx - half * 1.05 + r.nextDouble() * half * 2.1;
    final ph = r.nextDouble();
    final len = (botY - topY) * (0.22 + r.nextDouble() * 0.2);
    final y = topY - len + k.saw(6 + i % 3, ph) * (botY - topY + len * 2);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 1.6 + r.nextDouble() * 2.2, len), const Radius.circular(2)),
      linearPaint(Offset(x, y), Offset(x, y + len), [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)]),
    );
  }
  c.restore();
  // lip highlight + foam & spray at the bottom
  final foamY = botY;
  for (var i = 0; i < 7; i++) {
    final ph = i / 7;
    final pulse = k.pulse(8, ph);
    glow(c, Offset(cx + (i - 3) * half * 0.42, foamY + 2), half * (0.7 + 0.5 * pulse), Colors.white, 0.55);
  }
  for (var i = 0; i < 10; i++) {
    final t = k.saw(5, i / 10);
    final a = (1 - t) * 0.8;
    final ang = -math.pi / 2 + (i - 4.5) * 0.28;
    final d = t * h * 0.03;
    c.drawCircle(Offset(cx + math.cos(ang) * d * 1.4, foamY - math.sin(-ang) * d - 2), 1.0 + (1 - t) * 1.6, Paint()..color = Colors.white.withValues(alpha: a));
  }
  glow(c, Offset(cx, foamY - 6), w * 0.17, const Color(0xFFE6FFFF), 0.28 + 0.1 * k.pulse(4));
}

Path _streamPath(Size s) {
  final w = s.width, h = s.height;
  final center = <Offset>[
    Offset(w * 0.60, h * 0.672),
    Offset(w * 0.56, h * 0.705),
    Offset(w * 0.42, h * 0.76),
    Offset(w * 0.40, h * 0.83),
    Offset(w * 0.50, h * 0.9),
    Offset(w * 0.52, h * 1.05),
  ];
  final half = <double>[w * 0.07, w * 0.08, w * 0.1, w * 0.13, w * 0.2, w * 0.3];
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i < center.length; i++) {
    final a = center[math.max(i - 1, 0)], b = center[math.min(i + 1, center.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    left.add(center[i] - n * half[i]);
    right.add(center[i] + n * half[i]);
  }
  final pts = [...left, ...right.reversed];
  return smoothPath(pts, closed: true);
}

void _stream(Canvas c, Size s) {
  final p = _streamPath(s);
  final b = p.getBounds();
  // muddy bank rim
  c.drawPath(p.shift(const Offset(0, 3)), Paint()..color = const Color(0xFF184A38));
  c.drawPath(p, verticalPaint(b, const [Color(0xFF8CEBE4), Color(0xFF2DB9BE), Color(0xFF1B8FA6)], const [0.0, 0.5, 1.0]));
  shadeInside(c, p, light: const Offset(0.6, -0.9), lightColor: const Color(0xFFFFF3C4), lightAlpha: 0.22, shadowColor: const Color(0xFF06355A), shadowAlpha: 0.3);
  // sun reflection down the middle
  final refl = Path()
    ..moveTo(s.width * 0.56, s.height * 0.70)
    ..quadraticBezierTo(s.width * 0.44, s.height * 0.76, s.width * 0.45, s.height * 0.83)
    ..quadraticBezierTo(s.width * 0.5, s.height * 0.9, s.width * 0.56, s.height * 1.02)
    ..lineTo(s.width * 0.6, s.height * 1.02)
    ..quadraticBezierTo(s.width * 0.55, s.height * 0.9, s.width * 0.5, s.height * 0.83)
    ..quadraticBezierTo(s.width * 0.5, s.height * 0.77, s.width * 0.6, s.height * 0.705)
    ..close();
  c.save();
  c.clipPath(p);
  c.drawPath(refl, linearPaint(Offset(0, s.height * 0.7), Offset(0, s.height), [const Color(0xFFFFF6C8).withValues(alpha: 0.5), const Color(0xFFFFF6C8).withValues(alpha: 0.12)]));
  c.restore();
}

void _shimmer(Canvas c, Size s, Clock k) {
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.28, 0.7, 0.72, 1.0), count: 34, seed: 4, color: const Color(0xFFFFFFFF), cycles: 9);
}

// ---------------------------------------------------------------- banks & giants

void _banks(Canvas c, Size s) {
  final w = s.width, h = s.height;
  for (final side in [-1, 1]) {
    final pts = <Offset>[];
    final x0 = side < 0 ? -w * 0.1 : w * 1.1;
    for (var i = 0; i <= 8; i++) {
      final t = i / 8;
      final x = side < 0 ? ui.lerpDouble(x0, w * 0.37, t)! : ui.lerpDouble(x0, w * 0.64, t)!;
      final lift = math.pow(1 - t, 1.6) * h * 0.1;
      final y = h * (0.80 + 0.19 * t * t) - lift;
      pts.add(Offset(x, y));
    }
    final p = smoothPath(pts)
      ..lineTo(side < 0 ? w * 0.52 : w * 0.48, h * 1.1)
      ..lineTo(x0, h * 1.1)
      ..close();
    c.drawPath(p, verticalPaint(p.getBounds(), const [Color(0xFF63C44E), Color(0xFF2B8A3E), Color(0xFF14522E)], const [0.0, 0.45, 1.0]));
    shadeInside(c, p, lightColor: const Color(0xFFFFF0A8), lightAlpha: 0.22, shadowColor: const Color(0xFF0A3320), shadowAlpha: 0.3);
    c.drawPath(smoothPath(pts), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE8FF9E).withValues(alpha: 0.7));
  }
  final r = rng(41);
  // grass, flowers and stones along both banks
  for (var i = 0; i < 26; i++) {
    final side = i.isEven ? -1 : 1;
    final x = side < 0 ? r.nextDouble() * w * 0.42 : w * 0.58 + r.nextDouble() * w * 0.42;
    final y = h * (0.88 + r.nextDouble() * 0.11);
    paintGrassTuft(c, Offset(x, y), h * (0.025 + r.nextDouble() * 0.03), blades: 6, seed: i, dark: const Color(0xFF1E6B35), light: const Color(0xFFB4F06A));
  }
  const petals = [Color(0xFFFFE066), Color(0xFFFF8FB8), Color(0xFFFFFFFF), Color(0xFFA8D0FF)];
  for (var i = 0; i < 22; i++) {
    final side = i.isEven ? -1 : 1;
    final x = side < 0 ? r.nextDouble() * w * 0.4 : w * 0.6 + r.nextDouble() * w * 0.4;
    final y = h * (0.85 + r.nextDouble() * 0.13);
    final fr = 2.2 + r.nextDouble() * 2.2;
    c.drawLine(Offset(x, y), Offset(x, y + fr * 2.4), Paint()
      ..color = const Color(0xFF1F6B35)
      ..strokeWidth = 1.1);
    paintFlower(c, Offset(x, y), fr, petal: petals[i % 4], rot: r.nextDouble());
  }
  paintRock(c, Offset(w * 0.36, h * 0.955), w * 0.2, h * 0.055, seed: 12, color: const Color(0xFF747C6E), light: const Color(0xFFC2CCB0));
  paintRock(c, Offset(w * 0.66, h * 0.93), w * 0.16, h * 0.04, seed: 14, color: const Color(0xFF6E7668), light: const Color(0xFFB9C4A8));
  paintBush(c, Offset(w * 0.27, h * 0.9), w * 0.2, seed: 5, dark: const Color(0xFF1B6A3B), light: const Color(0xFF7ED35C));
  paintBush(c, Offset(w * 0.76, h * 0.9), w * 0.22, seed: 6, dark: const Color(0xFF1B6A3B), light: const Color(0xFF7ED35C));
  // mushrooms
  for (final m in const [Offset(0.18, 0.93), Offset(0.22, 0.945), Offset(0.84, 0.925)]) {
    final o = Offset(m.dx * w, m.dy * h);
    final sc = m.dx == 0.22 ? 0.7 : 1.0;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, 4 * sc), width: 5 * sc, height: 9 * sc), const Radius.circular(2)), Paint()..color = const Color(0xFFF5E8D0));
    final cap = Path()
      ..moveTo(o.dx - 11 * sc, o.dy)
      ..quadraticBezierTo(o.dx, o.dy - 17 * sc, o.dx + 11 * sc, o.dy)
      ..quadraticBezierTo(o.dx, o.dy + 3 * sc, o.dx - 11 * sc, o.dy)
      ..close();
    c.drawPath(cap, verticalPaint(cap.getBounds(), const [Color(0xFFFF6A5C), Color(0xFFC62E3A)]));
    for (final d in const [Offset(-4, -4), Offset(3, -6), Offset(5, -2)]) {
      c.drawCircle(o + d * sc, 1.5 * sc, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
    glow(c, o + Offset(0, -4 * sc), 18 * sc, const Color(0xFFFF9C8A), 0.25);
  }
}

void _giant(Canvas c, Size s, int side) {
  final w = s.width, h = s.height;
  final dir = side.toDouble(); // -1 left, 1 right
  final edge = side < 0 ? 0.0 : w; // screen edge the tree grows from
  double ex(double d) => edge - dir * d; // x at distance d from the edge, towards the middle
  // inner silhouette: slim at the top, flaring into roots at the bottom
  double inner(double t) => w * (0.07 + 0.012 * math.sin(t * 5 + side) + 0.09 * math.pow(t, 6));
  final pts = [for (var i = 0; i <= 12; i++) Offset(ex(inner(i / 12)), h * (-0.03 + 1.06 * i / 12))];
  final trunk = smoothPath(pts)
    ..lineTo(ex(-w * 0.05), h * 1.03)
    ..lineTo(ex(-w * 0.05), -h * 0.03)
    ..close();
  c.drawPath(trunk, linearPaint(Offset(ex(w * 0.17), 0), Offset(ex(-w * 0.02), 0), const [Color(0xFF7A5638), Color(0xFF4E3623), Color(0xFF2E2019)], const [0.0, 0.45, 1.0]));
  // bark furrows following the trunk
  final r = rng(60 + side);
  for (var i = 0; i < 12; i++) {
    final t0 = 0.04 + r.nextDouble() * 0.78;
    final off = w * (0.012 + r.nextDouble() * 0.05);
    final y0 = h * t0;
    final x0 = ex(inner(t0) - off);
    final furrow = Path()
      ..moveTo(x0, y0)
      ..quadraticBezierTo(x0 - dir * 4, y0 + h * 0.07, x0 + dir * 2, y0 + h * (0.14 + r.nextDouble() * 0.1));
    c.drawPath(furrow, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1B120E).withValues(alpha: 0.4));
  }
  // moss clinging to the sunny edge
  for (var i = 0; i < 7; i++) {
    final t = 0.16 + i * 0.12 + r.nextDouble() * 0.05;
    final mp = blobPath(Offset(ex(inner(t) - w * 0.012), h * t), w * 0.02, h * (0.018 + r.nextDouble() * 0.02), seed: i + 90 + side);
    c.drawPath(mp, verticalPaint(mp.getBounds(), const [Color(0xFF9BE05A), Color(0xFF2F8F45)]));
  }
  // sunlit rim
  final rim = smoothPath(pts);
  c.drawPath(rim, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
    ..color = const Color(0xFFFFD98A).withValues(alpha: 0.28));
  c.drawPath(rim, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..color = const Color(0xFFFFDE96).withValues(alpha: 0.9));
  // mossy mound where the trunk meets the bank
  final mound = smoothPath([
    Offset(ex(w * 0.02), h * 0.9),
    Offset(ex(w * 0.12), h * 0.925),
    Offset(ex(w * 0.2), h * 0.96),
    Offset(ex(w * 0.18), h * 1.03),
    Offset(ex(w * 0.02), h * 1.03),
  ], closed: true);
  c.drawPath(mound, verticalPaint(mound.getBounds(), const [Color(0xFF8BD65A), Color(0xFF2B8A3E), Color(0xFF14522E)]));
  c.drawPath(smoothPath([Offset(ex(w * 0.04), h * 0.9), Offset(ex(w * 0.12), h * 0.925), Offset(ex(w * 0.2), h * 0.96)]), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..color = const Color(0xFFE8FF9E).withValues(alpha: 0.7));

  // canopy in the top corner: scalloped, layered, with sunlit leaf clusters
  final cr = rng(80 + side);
  final canopy = Path();
  for (var i = 0; i < 10; i++) {
    final px = edge - dir * w * (0.0 + i * 0.07) + (cr.nextDouble() - 0.5) * w * 0.05;
    final py = h * (0.02 + (i % 3) * 0.032 + cr.nextDouble() * 0.03);
    canopy.addOval(Rect.fromCircle(center: Offset(px, py), radius: w * (0.1 + cr.nextDouble() * 0.06)));
  }
  canopy.addRect(Rect.fromLTRB(math.min(edge - dir * w * 0.8, edge + dir * w * 0.2), -h * 0.06, math.max(edge - dir * w * 0.8, edge + dir * w * 0.2), h * 0.02));
  c.drawPath(canopy, verticalPaint(canopy.getBounds(), const [Color(0xFF0A3626), Color(0xFF126B41), Color(0xFF0D4F34)], const [0.0, 0.62, 1.0]));
  shadeInside(c, canopy, light: Offset(-dir * 0.5, 0.9), lightColor: const Color(0xFFD8FF7A), lightAlpha: 0.45, shadowColor: const Color(0xFF031C14), shadowAlpha: 0.4);
  c.save();
  c.clipPath(canopy);
  for (var i = 0; i < 46; i++) {
    final px = edge - dir * w * (cr.nextDouble() * 0.62);
    final py = h * (0.006 + math.pow(cr.nextDouble(), 0.8) * 0.13);
    final lw = w * (0.018 + cr.nextDouble() * 0.022);
    c
      ..save()
      ..translate(px, py)
      ..rotate(-0.9 + cr.nextDouble() * 1.8);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: lw * 2, height: lw), Paint()..color = const Color(0xFFB8F36A).withValues(alpha: 0.12 + cr.nextDouble() * 0.28));
    c.restore();
  }
  c.restore();
  // hanging vines
  for (var i = 0; i < 6; i++) {
    final x = edge - dir * w * (0.1 + i * 0.075 + cr.nextDouble() * 0.04);
    final len = h * (0.08 + cr.nextDouble() * 0.16);
    final v = Path()
      ..moveTo(x, h * 0.07)
      ..quadraticBezierTo(x + dir * 8, h * 0.07 + len * 0.5, x - dir * 3, h * 0.07 + len);
    c.drawPath(v, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1E7A3E));
    for (var j = 1; j <= 4; j++) {
      c.drawOval(Rect.fromCenter(center: Offset(x + dir * (j.isEven ? 4 : -3), h * 0.07 + len * j / 5), width: 7, height: 3.6), Paint()..color = const Color(0xFF86DA5C));
    }
  }
}

void _giants(Canvas c, Size s) {
  _giant(c, s, -1);
  _giant(c, s, 1);
}

// ---------------------------------------------------------------- live effects

void _farMist(Canvas c, Size s, Clock k) {
  for (var i = 0; i < 3; i++) {
    final w = s.width * (1.1 + i * 0.3);
    final x = -w * 0.6 + k.saw(1, i / 3) * (s.width + w * 1.2);
    softEllipse(c, Offset(x, s.height * (0.47 + i * 0.05)), w, s.height * 0.07, _haze, 0.55);
  }
}

void _nearMist(Canvas c, Size s, Clock k) {
  for (var i = 0; i < 2; i++) {
    final w = s.width * 1.5;
    final x = -w * 0.6 + k.saw(1, i / 2 + 0.2) * (s.width + w * 1.2);
    softEllipse(c, Offset(x, s.height * (0.80 + i * 0.1)), w, s.height * 0.09, const Color(0xFFE7FFF1), 0.3);
  }
}

void _pollen(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 46, seed: 3, colors: [Color(0xFFFFF3C2), Color(0xFFFFFFFF)], minSize: 0.8, maxSize: 1.8, flow: Offset(0.04, -0.2), cycles: 2, spread: 2, wander: 10, twinkle: 0.5, shape: ParticleShape.dot, region: Rect.fromLTRB(0.05, 0.25, 0.95, 0.95), opacity: 0.8));
}

void _fireflies(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 30, seed: 8, colors: [Color(0xFFFFEE88), Color(0xFFBFFF8F)], minSize: 1.6, maxSize: 3.0, flow: Offset(0.02, -0.06), cycles: 1, spread: 1, wander: 24, twinkle: 0.7, twinkleCycles: 10, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.35, 1.0, 0.98), haloScale: 4.2));
}
