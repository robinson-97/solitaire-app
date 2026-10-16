import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Enchanted Forest, painted in a gentle storybook / gouache mood: an ancient
// camphor-like tree, golden light through big clouds, a clear stream, ferns,
// wildflowers; seeds and forest lights drift in the sunbeams.

const _sun = Offset(0.80, 0.17); // fractions of the screen
const _haze = Color(0xFFD7EBC9);

double _lerp(double a, double b, double t) => a + (b - a) * t;

SceneSpec forestScene() => SceneSpec(
      focusY: -0.1,
      topShade: 0.18,
      bottomShade: 0.32,
      layers: [
        Layer.still(_sky),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.4),
        Layer.still(_mountains, driftX: 0.005, driftCycles: 2),
        Layer.scroll(_cloudsFront, scrollCycles: 2, bandTop: 0.1, bandBottom: 0.5),
        Layer.still(_rays, rotate: 0.03, swayCycles: 3, pivot: const Alignment(0.6, -0.7)),
        Layer.still(_farWoods, driftX: 0.01, driftCycles: 2, sway: 0.004, swayCycles: 5),
        Layer.live(_farMist),
        Layer.still(_meadow, driftX: 0.016, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_hero, driftX: 0.022, driftCycles: 2, driftPhase: 0.15, sway: 0.003, swayCycles: 4, pivot: const Alignment(-0.2, 1)),
        Layer.still(_stream, driftX: 0.028, driftCycles: 2, driftPhase: 0.2),
        Layer.live(_glints),
        Layer.still(_ground, driftX: 0.034, driftCycles: 2, driftPhase: 0.25),
        Layer.still(_foreLeaves, driftX: 0.05, driftCycles: 2, driftPhase: 0.3, sway: 0.006, swayCycles: 6, pivot: const Alignment(0, 1)),
        Layer.live(_seeds),
        Layer.live(_spirits),
        Layer.live(_butterflies),
        Layer.live(_nearMist),
      ],
    );

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  const cols = [Color(0xFF3F8FB4), Color(0xFF7CC7C9), Color(0xFFC6E6C4), Color(0xFFF7EDBE), Color(0xFFFFF4D2)];
  const stops = [0.0, 0.2, 0.36, 0.48, 1.0];
  paintSkyWash(c, s, cols, stops: stops, seed: 4, strokes: 300, alpha: 0.2);
  final o = Offset(_sun.dx * s.width, _sun.dy * s.height);
  glow(c, o, s.width * 1.1, const Color(0xFFFFE9A8), 0.4);
  glow(c, o, s.width * 0.4, const Color(0xFFFFF6D4), 0.6);
  c.drawCircle(o, s.width * 0.07, radialPaint(o, s.width * 0.07, const [Color(0xFFFFFFF4), Color(0xFFFFF3C0)], const [0.5, 1.0]));
}

void _cloudsBack(Canvas c, Size s) {
  final r = rng(7);
  for (var i = 0; i < 3; i++) {
    final x = (i + 0.25 + r.nextDouble() * 0.5) * s.width / 3;
    paintCumulus(c, Offset(x, s.height * (0.15 + r.nextDouble() * 0.12)), s.width * (0.42 + r.nextDouble() * 0.2), seed: i + 17, lit: const Color(0xFFFFFCEF), mid: const Color(0xFFE6F0F0), shade: const Color(0xFF9FBAD8), opacity: 0.95);
  }
}

void _cloudsFront(Canvas c, Size s) {
  final r = rng(19);
  for (var i = 0; i < 2; i++) {
    final x = (i + 0.3 + r.nextDouble() * 0.4) * s.width / 2;
    paintCumulus(c, Offset(x, s.height * (0.36 + r.nextDouble() * 0.04)), s.width * (0.3 + r.nextDouble() * 0.12), seed: i + 31, lit: const Color(0xFFFFFFFA), mid: const Color(0xFFEDF3F0), shade: const Color(0xFFB0C6E0), opacity: 0.95, height: s.width * 0.12);
  }
}

void _mountains(Canvas c, Size s) {
  final h = s.height;
  final far = Ridge(s, y: 0.43, amp: 0.035, freq: 1.5, seed: 12, octaves: 3);
  paintRidge(c, far, top: const Color(0xFF9CC9BE), bottom: const Color(0xFFC6E2CC), rim: Colors.white, rimAlpha: 0.35);
  paintBrushwork(c, Rect.fromLTRB(0, far.top, s.width, 0.5 * h), clip: far.fill(), colors: const [Color(0xFFB7DCC9), Color(0xFF86B8AE)], strokes: 70, alpha: 0.18, thickness: 5, angle: 0.06);
  final mid = Ridge(s, y: 0.46, amp: 0.03, freq: 2.1, seed: 5, octaves: 3);
  paintRidge(c, mid, top: const Color(0xFF7DB79C), bottom: const Color(0xFFAFD7B4), rim: const Color(0xFFFFF3C4), rimAlpha: 0.45);
  paintBrushwork(c, Rect.fromLTRB(0, mid.top, s.width, 0.55 * h), clip: mid.fill(), colors: const [Color(0xFF9CCDA6), Color(0xFF6BA88E)], strokes: 80, alpha: 0.2, thickness: 5, angle: 0.04);
  paintMist(c, Rect.fromLTRB(0, 0.4 * h, s.width, 0.54 * h), _haze, 0.6);
}

void _rays(Canvas c, Size s) {
  final o = Offset(_sun.dx * s.width, _sun.dy * s.height);
  glow(c, o, s.width * 0.7, const Color(0xFFFFEFB0), 0.28, true);
  glow(c, o, s.width * 0.25, const Color(0xFFFFFFFF), 0.4, true);
  paintRays(c, o, length: s.height * 1.0, centerAngle: math.pi * 0.62, spread: 1.5, count: 8, opacity: 0.2, color: const Color(0xFFFFEFB8), seed: 3, minWidth: 0.07, maxWidth: 0.18);
  paintRays(c, o, length: s.height * 0.75, centerAngle: math.pi * 0.6, spread: 1.0, count: 4, opacity: 0.14, color: const Color(0xFFFFFFFF), seed: 8, minWidth: 0.03, maxWidth: 0.06);
}

// ---------------------------------------------------------------- woods

void _farWoods(Canvas c, Size s) {
  final h = s.height, w = s.width;
  final r = rng(21);
  final ridge = Ridge(s, y: 0.52, amp: 0.012, freq: 3, seed: 40);
  for (var row = 0; row < 3; row++) {
    final haze = 0.5 - row * 0.17;
    var x = -w * 0.05;
    while (x < w * 1.05) {
      final rad = w * (0.06 + r.nextDouble() * 0.05) * (1 + row * 0.25);
      final y = ridge.yAt(x) + h * (0.012 + row * 0.024) - rad * 0.55;
      paintFoliage(
        c,
        Offset(x, y),
        rad,
        dark: hazeTo(const Color(0xFF2A7A5C), _haze, haze),
        mid: hazeTo(const Color(0xFF4FA06A), _haze, haze),
        light: hazeTo(const Color(0xFFB4DE78), _haze, haze * 0.8),
        seed: r.nextInt(9999),
        density: 0.8,
      );
      x += rad * (1.0 + r.nextDouble() * 0.5);
    }
    // ground under each row
    final g = Ridge(s, y: 0.535 + row * 0.024, amp: 0.008, freq: 3, seed: 60 + row);
    paintRidge(c, g, top: hazeTo(const Color(0xFF4A9A62), _haze, haze * 0.8), bottom: hazeTo(const Color(0xFF3E8A58), _haze, haze * 0.8));
  }
}

void _farMist(Canvas c, Size s, Clock k) {
  for (var i = 0; i < 3; i++) {
    final w = s.width * (1.1 + i * 0.3);
    final x = -w * 0.6 + k.saw(1, i / 3) * (s.width + w * 1.2);
    softEllipse(c, Offset(x, s.height * (0.52 + i * 0.04)), w, s.height * 0.07, _haze, 0.5);
  }
}

void _meadow(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final ridge = Ridge(s, y: 0.62, amp: 0.02, freq: 1.7, seed: 77, tilt: 0.02);
  paintRidge(c, ridge, top: const Color(0xFF86C46A), bottom: const Color(0xFF3F8F4E), rim: const Color(0xFFF1FFB5), rimAlpha: 0.5);
  paintBrushwork(c, Rect.fromLTRB(0, ridge.top, w, h), clip: ridge.fill(), colors: const [Color(0xFFB9E37A), Color(0xFF5FB060), Color(0xFF2F8A4C)], strokes: 220, alpha: 0.22, thickness: 6, angle: -0.08, minLen: 20, maxLen: 70);
  paintGrassBlades(c, Rect.fromLTRB(0, ridge.top + 4, w, h * 0.74), count: 260, minH: 5, maxH: 15, lean: 0.25, seed: 5);
  paintWildflowers(c, Rect.fromLTRB(0, h * 0.64, w, h * 0.76), colors: const [Color(0xFFFFFFFF), Color(0xFFFFF0A0), Color(0xFFB9A6F0)], count: 46, size: 1.9, seed: 8);
}

// ---------------------------------------------------------------- the ancient tree

void _hero(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // trunk with roots, lit from the upper right
  final base = Offset(w * 0.33, h * 0.80);
  final trunk = Path()
    ..moveTo(base.dx - w * 0.2, base.dy + h * 0.03)
    ..cubicTo(base.dx - w * 0.1, base.dy - h * 0.02, base.dx - w * 0.09, base.dy - h * 0.1, base.dx - w * 0.1, base.dy - h * 0.2)
    ..cubicTo(base.dx - w * 0.09, base.dy - h * 0.34, base.dx - w * 0.08, base.dy - h * 0.42, base.dx - w * 0.06, base.dy - h * 0.55)
    ..lineTo(base.dx + w * 0.11, base.dy - h * 0.55)
    ..cubicTo(base.dx + w * 0.115, base.dy - h * 0.4, base.dx + w * 0.12, base.dy - h * 0.3, base.dx + w * 0.13, base.dy - h * 0.18)
    ..cubicTo(base.dx + w * 0.13, base.dy - h * 0.06, base.dx + w * 0.2, base.dy, base.dx + w * 0.28, base.dy + h * 0.03)
    ..close();
  c.drawPath(trunk, linearPaint(Offset(base.dx - w * 0.1, 0), Offset(base.dx + w * 0.14, 0), const [Color(0xFF3F2E27), Color(0xFF6A4A36), Color(0xFFB08458)], const [0.0, 0.6, 1.0]));
  paintBrushwork(c, trunk.getBounds(), clip: trunk, colors: const [Color(0xFF2E211D), Color(0xFF8A6244), Color(0xFF5A4030)], strokes: 150, alpha: 0.26, thickness: 4, angle: math.pi / 2, minLen: 30, maxLen: 120, angleJitter: 0.12);
  // moss on the trunk base and roots
  final moss = Path()
    ..moveTo(base.dx - w * 0.16, base.dy + h * 0.02)
    ..quadraticBezierTo(base.dx - w * 0.06, base.dy - h * 0.13, base.dx + w * 0.02, base.dy - h * 0.07)
    ..quadraticBezierTo(base.dx + w * 0.1, base.dy - h * 0.14, base.dx + w * 0.22, base.dy + h * 0.02)
    ..close();
  c.save();
  c.clipPath(trunk);
  c.drawPath(wobblePath(moss, amp: 2.5, seed: 4), verticalPaint(moss.getBounds(), const [Color(0xFF9BDB5C), Color(0xFF3F8F46)]));
  c.restore();
  // sunlit rim on the right of the trunk
  c.drawPath(
    Path()
      ..moveTo(base.dx + w * 0.11, base.dy - h * 0.55)
      ..cubicTo(base.dx + w * 0.115, base.dy - h * 0.4, base.dx + w * 0.12, base.dy - h * 0.3, base.dx + w * 0.13, base.dy - h * 0.18)
      ..cubicTo(base.dx + w * 0.13, base.dy - h * 0.06, base.dx + w * 0.2, base.dy, base.dx + w * 0.28, base.dy + h * 0.03),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFE3A0).withValues(alpha: 0.85),
  );

  // limbs reaching into the crown
  final limb = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF4A3528);
  for (final (dx, dy, wd) in [(-0.2, -0.2, 9.0), (0.22, -0.18, 8.0), (-0.02, -0.28, 10.0)]) {
    final top = Offset(base.dx + w * dx, h * (0.78 + dy) - h * 0.45);
    c.drawPath(
      Path()
        ..moveTo(base.dx + w * 0.02, base.dy - h * 0.5)
        ..quadraticBezierTo(base.dx + w * dx * 0.3, base.dy - h * 0.58, top.dx, top.dy),
      limb..strokeWidth = wd,
    );
  }
  // great crown: airy clumps with a few gaps showing sky
  final cr = Offset(w * 0.3, h * 0.22);
  final parts = <(Offset, double)>[
    (cr + Offset(w * 0.0, h * 0.0), w * 0.34),
    (cr + Offset(w * 0.33, -h * 0.01), w * 0.26),
    (cr + Offset(-w * 0.32, h * 0.015), w * 0.26),
    (cr + Offset(w * 0.08, -h * 0.095), w * 0.28),
    (cr + Offset(w * 0.22, h * 0.095), w * 0.22),
    (cr + Offset(-w * 0.2, h * 0.095), w * 0.21),
  ];
  var k = 0;
  for (final (o, rad) in parts) {
    paintFoliage(c, o, rad, dark: const Color(0xFF17513C), mid: const Color(0xFF3A8A56), light: const Color(0xFFB4E070), lightDir: const Offset(0.7, -0.7), seed: 100 + k++, density: 1.0);
  }
  // hanging moss/vines under the crown
  final r = rng(12);
  for (var i = 0; i < 9; i++) {
    final x = w * (0.05 + r.nextDouble() * 0.55);
    final len = h * (0.04 + r.nextDouble() * 0.08);
    final y0 = h * (0.27 + r.nextDouble() * 0.04);
    c.drawPath(
      Path()
        ..moveTo(x, y0)
        ..quadraticBezierTo(x + 4, y0 + len * 0.5, x - 2, y0 + len),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3F8F46),
    );
    for (var j = 1; j <= 3; j++) {
      c.drawOval(Rect.fromCenter(center: Offset(x + (j.isEven ? 3 : -3), y0 + len * j / 4), width: 6, height: 3), Paint()..color = const Color(0xFFA6D86A));
    }
  }
}

// ---------------------------------------------------------------- stream & ground

Path _streamPath(Size s) {
  final w = s.width, h = s.height;
  final center = <Offset>[Offset(w * 0.76, h * 0.612), Offset(w * 0.72, h * 0.64), Offset(w * 0.64, h * 0.71), Offset(w * 0.55, h * 0.79), Offset(w * 0.5, h * 0.88), Offset(w * 0.52, h * 1.06)];
  final half = <double>[w * 0.008, w * 0.03, w * 0.06, w * 0.09, w * 0.14, w * 0.2];
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i < center.length; i++) {
    final a = center[math.max(i - 1, 0)], b = center[math.min(i + 1, center.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    left.add(center[i] - n * half[i]);
    right.add(center[i] + n * half[i]);
  }
  return smoothPath([...left, ...right.reversed], closed: true);
}

void _stream(Canvas c, Size s) {
  final p = _streamPath(s);
  final b = p.getBounds();
  c.drawPath(p.shift(const Offset(0, 3)), Paint()..color = const Color(0xFF2B6A4A));
  c.drawPath(p, verticalPaint(b, const [Color(0xFFA6EFE0), Color(0xFF55C7C3), Color(0xFF2FA0B0)]));
  paintBrushwork(c, b, clip: p, colors: const [Color(0xFFD6FFF0), Color(0xFF2B93AA), Color(0xFF8EE6DD)], strokes: 90, alpha: 0.28, thickness: 4, angle: 0.9, minLen: 20, maxLen: 70, angleJitter: 0.35);
  shadeInside(c, p, light: const Offset(0.6, -0.9), lightColor: const Color(0xFFFFF3C4), lightAlpha: 0.25, shadowColor: const Color(0xFF14506A), shadowAlpha: 0.25);
  // grassy bank rims
  c.drawPath(p, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFFE8FFB5).withValues(alpha: 0.6));
}

void _glints(Canvas c, Size s, Clock k) {
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.3, 0.66, 0.78, 1.0), count: 30, seed: 6, color: const Color(0xFFFFFFFF), cycles: 8);
}

void _ground(Canvas c, Size s) {
  final w = s.width, h = s.height;
  for (final side in [-1, 1]) {
    final pts = <Offset>[];
    for (var i = 0; i <= 8; i++) {
      final t = i / 8;
      final x = side < 0 ? _lerp(-w * 0.1, w * 0.4, t) : _lerp(w * 1.1, w * 0.62, t);
      final y = h * (0.80 + 0.2 * t * t) - math.pow(1 - t, 1.5) * h * 0.08;
      pts.add(Offset(x, y));
    }
    final p = smoothPath(pts)
      ..lineTo(side < 0 ? w * 0.55 : w * 0.45, h * 1.1)
      ..lineTo(side < 0 ? -w * 0.1 : w * 1.1, h * 1.1)
      ..close();
    c.drawPath(p, verticalPaint(p.getBounds(), const [Color(0xFF7FCB62), Color(0xFF3A964E), Color(0xFF1E6040)]));
    paintBrushwork(c, p.getBounds(), clip: p, colors: const [Color(0xFFBDEB7E), Color(0xFF3F9A54), Color(0xFF1B5A3E)], strokes: 160, alpha: 0.24, thickness: 6, angle: -0.5 * side, minLen: 18, maxLen: 60);
    c.save();
    c.clipPath(p);
    paintGrassBlades(c, p.getBounds().intersect(Rect.fromLTRB(0, h * 0.82, w, h)), count: 240, minH: 8, maxH: 24, lean: 0.3 * side, seed: 20 + side);
    c.restore();
    c.drawPath(smoothPath(pts), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFF1FFB0).withValues(alpha: 0.7));
  }
  // flowers in the foreground meadow
  paintWildflowers(c, Rect.fromLTRB(0, h * 0.86, w * 0.4, h * 0.99), colors: const [Color(0xFFFFFFFF), Color(0xFFFFE066), Color(0xFFF4A9C4), Color(0xFFB9A6F0)], count: 26, size: 2.8, seed: 3);
  paintWildflowers(c, Rect.fromLTRB(w * 0.62, h * 0.86, w, h * 0.99), colors: const [Color(0xFFFFFFFF), Color(0xFFFFE066), Color(0xFFF4A9C4), Color(0xFFB9A6F0)], count: 26, size: 2.8, seed: 4);
  // mossy stones
  paintRock(c, Offset(w * 0.36, h * 0.945), w * 0.2, h * 0.045, seed: 12, color: const Color(0xFF7A8576), light: const Color(0xFFC7D2B0));
  paintRock(c, Offset(w * 0.66, h * 0.925), w * 0.15, h * 0.035, seed: 14, color: const Color(0xFF727D6C), light: const Color(0xFFBCC9A6));
  paintBush(c, Offset(w * 0.2, h * 0.9), w * 0.18, seed: 5, dark: const Color(0xFF1E6A40), light: const Color(0xFF8EDB60));
}

// ---------------------------------------------------------------- foreground

void _leaf(Canvas c, Offset base, double len, double angle, Color dark, Color light) {
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angle);
  final w = len * 0.28;
  final p = Path()
    ..moveTo(0, 0)
    ..cubicTo(-w * 1.3, -len * 0.25, -w * 1.1, -len * 0.75, 0, -len)
    ..cubicTo(w * 1.1, -len * 0.75, w * 1.3, -len * 0.25, 0, 0)
    ..close();
  c.drawPath(p, linearPaint(Offset(-w, 0), Offset(w, -len * 0.5), [dark, mix(dark, light, 0.55)]));
  // lit half + midrib
  c.drawPath(
    Path()
      ..moveTo(0, 0)
      ..cubicTo(w * 1.3, -len * 0.25, w * 1.1, -len * 0.75, 0, -len)
      ..quadraticBezierTo(w * 0.2, -len * 0.5, 0, 0)
      ..close(),
    Paint()..color = light.withValues(alpha: 0.45),
  );
  c.drawLine(
    Offset.zero,
    Offset(0, -len * 0.92),
    Paint()
      ..color = light.withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round,
  );
  c.restore();
}

void _foreLeaves(Canvas c, Size s) {
  final w = s.width, h = s.height;
  const dark = Color(0xFF0F4A34), light = Color(0xFF9EDB62);
  for (final side in [-1, 1]) {
    final bx = side < 0 ? w * 0.0 : w * 1.0;
    for (var i = 0; i < 6; i++) {
      final a = (side < 0 ? 0.25 : -0.25) + side * (i - 2.5) * 0.28 + (side < 0 ? 0.15 : -0.15);
      _leaf(c, Offset(bx + side * w * 0.02, h * 1.03), h * (0.2 + (i % 3) * 0.04), a, darken(dark, 0.02 * i), light);
    }
  }
}

// ---------------------------------------------------------------- live

void _seeds(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 38, seed: 3, colors: [Color(0xFFFFFFFF), Color(0xFFFFF3C2)], minSize: 0.9, maxSize: 2.0, flow: Offset(0.1, -0.22), cycles: 2, spread: 2, wander: 14, twinkle: 0.4, shape: ParticleShape.dot, region: Rect.fromLTRB(0.0, 0.2, 1.0, 0.98), opacity: 0.85));
}

void _spirits(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 20, seed: 8, colors: [Color(0xFFFFF0A0), Color(0xFFC4FF9A)], minSize: 1.8, maxSize: 3.4, flow: Offset(0.02, -0.05), cycles: 1, spread: 1, wander: 26, twinkle: 0.7, twinkleCycles: 8, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.4, 1.0, 0.98), haloScale: 4.4));
}

void _butterflies(Canvas c, Size s, Clock k) {
  for (var i = 0; i < 3; i++) {
    final ph = i / 3.0;
    final t = k.saw(1, ph);
    final x = s.width * (0.15 + 0.7 * t) + math.sin(tau * (k.u * 5 + ph)) * 26;
    final y = s.height * (0.72 - 0.1 * i) + math.cos(tau * (k.u * 7 + ph * 2)) * 18;
    final flap = 0.45 + 0.55 * math.sin(tau * (k.u * 60 + i)).abs();
    final col = i == 1 ? const Color(0xFFFFD36B) : const Color(0xFFFFFFFF);
    for (final sd in [-1, 1]) {
      c
        ..save()
        ..translate(x, y)
        ..scale(sd * flap, 1);
      c.drawOval(Rect.fromLTWH(0, -5, 7, 6), Paint()..color = col.withValues(alpha: 0.95));
      c.drawOval(Rect.fromLTWH(0, 0, 5, 5), Paint()..color = col.withValues(alpha: 0.8));
      c.restore();
    }
  }
}

void _nearMist(Canvas c, Size s, Clock k) {
  for (var i = 0; i < 2; i++) {
    final w = s.width * 1.5;
    final x = -w * 0.6 + k.saw(1, i / 2 + 0.2) * (s.width + w * 1.2);
    softEllipse(c, Offset(x, s.height * (0.8 + i * 0.1)), w, s.height * 0.09, const Color(0xFFEFFFF4), 0.28);
  }
}
