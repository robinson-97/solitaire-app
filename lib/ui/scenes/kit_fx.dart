import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit_core.dart';

// ---------------------------------------------------------------- stars & sparkles

/// Four-pointed twinkle with a soft halo.
void sparkle(Canvas c, Offset o, double r, Color color, [double a = 1.0]) {
  if (a <= 0) return;
  glow(c, o, r * 2.2, color, 0.35 * a);
  final p = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx + r * 0.12, o.dy - r * 0.12, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx + r * 0.12, o.dy + r * 0.12, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx - r * 0.12, o.dy + r * 0.12, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx - r * 0.12, o.dy - r * 0.12, o.dx, o.dy - r)
    ..close();
  c.drawPath(p, Paint()..color = color.withValues(alpha: a.clamp(0.0, 1.0)));
}

/// A field of twinkling stars inside [region] (fractions of the screen).
void paintStars(
  Canvas c,
  Size s,
  Clock k, {
  int count = 90,
  int seed = 7,
  Rect region = const Rect.fromLTRB(0, 0, 1, 0.6),
  Color color = const Color(0xFFFFFFFF),
  double minR = 0.5,
  double maxR = 1.6,
  int twinkleCycles = 12,
  double sparkleShare = 0.08,
}) {
  final r = rng(seed);
  final k0 = s.width / 390;
  final paint = Paint();
  for (var i = 0; i < count; i++) {
    final x = (region.left + r.nextDouble() * region.width) * s.width;
    final y = (region.top + r.nextDouble() * region.height) * s.height;
    final size = (minR + math.pow(r.nextDouble(), 2.2) * (maxR - minR)) * k0;
    final phase = r.nextDouble();
    final cyc = twinkleCycles + (i % 5);
    final tw = 0.35 + 0.65 * k.pulse(cyc, phase);
    if (r.nextDouble() < sparkleShare) {
      sparkle(c, Offset(x, y), size * 3.4, color, tw);
    } else {
      paint.color = color.withValues(alpha: 0.9 * tw);
      c.drawCircle(Offset(x, y), size, paint);
    }
  }
}

// ---------------------------------------------------------------- particles

enum ParticleShape { dot, glow, snow, petal, leaf, bubble, spark, ember, confetti }

/// Description of a drifting swarm. All motion is deterministic and loops
/// seamlessly: every particle completes a whole number of laps per loop.
class ParticleSpec {
  const ParticleSpec({
    required this.count,
    this.seed = 1,
    this.colors = const [Color(0xFFFFFFFF)],
    this.minSize = 1.0,
    this.maxSize = 3.0,
    this.flow = Offset.zero,
    this.cycles = 3,
    this.spread = 2,
    this.wander = 0.0,
    this.wanderCycles = 3,
    this.twinkle = 0.0,
    this.twinkleCycles = 14,
    this.shape = ParticleShape.glow,
    this.region = const Rect.fromLTRB(0, 0, 1, 1),
    this.fade = 0.14,
    this.opacity = 1.0,
    this.haloScale = 3.2,
    this.spin = 0.0,
  });

  final int count;
  final int seed;
  final List<Color> colors;

  /// Radius in logical pixels on a 390 px wide screen (scales with the screen).
  final double minSize, maxSize;

  /// Distance travelled per lap as a fraction of the screen, e.g. (0, -1) rises
  /// from bottom to top. (0, 0) = hovering in place.
  final Offset flow;

  /// Laps per loop for the slowest particle; the others do up to [spread] more.
  final int cycles, spread;

  /// Lissajous wobble in px (fireflies, jellyfish, dust) with [wanderCycles].
  final double wander;
  final int wanderCycles;
  final double twinkle;
  final int twinkleCycles;
  final ParticleShape shape;
  final Rect region;

  /// Fraction of a lap spent fading in / out at the ends of the flow.
  final double fade;
  final double opacity;
  final double haloScale;

  /// Rotation speed of petals / leaves / confetti in turns per lap.
  final double spin;
}

final Paint _pp = Paint();

void paintParticles(Canvas c, Size s, Clock k, ParticleSpec sp) {
  final r = rng(sp.seed);
  final k0 = s.width / 390;
  final rw = sp.region.width * s.width, rh = sp.region.height * s.height;
  final left = sp.region.left * s.width, top = sp.region.top * s.height;
  for (var i = 0; i < sp.count; i++) {
    final x0 = r.nextDouble(), y0 = r.nextDouble();
    final size = (sp.minSize + r.nextDouble() * (sp.maxSize - sp.minSize)) * k0;
    final color = sp.colors[r.nextInt(sp.colors.length)];
    final phase = r.nextDouble();
    final cyc = sp.cycles + (sp.spread > 0 ? i % (sp.spread + 1) : 0);
    final lap = k.saw(cyc, phase);
    var px = x0 + sp.flow.dx * lap;
    var py = y0 + sp.flow.dy * lap;
    px -= px.floorToDouble();
    py -= py.floorToDouble();
    var x = left + px * rw, y = top + py * rh;
    final wi = 2 + (i % 3);
    if (sp.wander > 0) {
      x += math.sin(tau * (k.u * (sp.wanderCycles + wi) + phase * 3)) * sp.wander * k0;
      y += math.cos(tau * (k.u * (sp.wanderCycles + wi + 1) + phase * 5)) * sp.wander * 0.7 * k0;
    }
    // fade at both ends of the travelled line
    var life = 1.0;
    if (sp.flow != Offset.zero && sp.fade > 0) {
      final pos = sp.flow.dy.abs() >= sp.flow.dx.abs() ? (sp.flow.dy > 0 ? py : 1 - py) : (sp.flow.dx > 0 ? px : 1 - px);
      life = (math.min(pos, 1 - pos) / sp.fade).clamp(0.0, 1.0);
    }
    var a = sp.opacity * life;
    if (sp.twinkle > 0) a *= 1 - sp.twinkle + sp.twinkle * k.pulse(sp.twinkleCycles + i % 4, phase * 2);
    if (a <= 0.01) continue;
    final o = Offset(x, y);
    switch (sp.shape) {
      case ParticleShape.dot:
        _pp.color = color.withValues(alpha: a);
        c.drawCircle(o, size, _pp);
      case ParticleShape.snow:
        _pp.color = color.withValues(alpha: a * 0.9);
        c.drawCircle(o, size, _pp);
      case ParticleShape.glow:
        glow(c, o, size * sp.haloScale, color, 0.55 * a, true);
        _pp.color = Colors.white.withValues(alpha: a * 0.95);
        c.drawCircle(o, size * 0.55, _pp);
      case ParticleShape.ember:
        final shrink = 0.4 + 0.6 * life;
        glow(c, o, size * sp.haloScale * shrink, color, 0.7 * a, true);
        _pp.color = mix(color, Colors.white, 0.6).withValues(alpha: a);
        c.drawCircle(o, size * 0.5 * shrink, _pp);
      case ParticleShape.spark:
        sparkle(c, o, size * 2.4, color, a);
      case ParticleShape.bubble:
        _pp
          ..color = color.withValues(alpha: 0.12 * a)
          ..style = PaintingStyle.fill;
        c.drawCircle(o, size, _pp);
        _pp
          ..color = color.withValues(alpha: 0.7 * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, size * 0.12);
        c.drawCircle(o, size, _pp);
        _pp
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: 0.8 * a);
        c.drawCircle(o + Offset(-size * 0.35, -size * 0.35), size * 0.2, _pp);
      case ParticleShape.petal:
      case ParticleShape.leaf:
      case ParticleShape.confetti:
        final ang = tau * (phase + lap * (sp.spin == 0 ? 1 : sp.spin)) + i;
        c
          ..save()
          ..translate(x, y)
          ..rotate(ang);
        final flip = 0.35 + 0.65 * math.cos(tau * (k.u * (cyc + 2) + phase * 4)).abs(); // tumbling
        _pp.color = color.withValues(alpha: a);
        if (sp.shape == ParticleShape.confetti) {
          c.drawRect(Rect.fromCenter(center: Offset.zero, width: size * 2, height: size * 1.1 * flip), _pp);
        } else if (sp.shape == ParticleShape.petal) {
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: size * 2.2, height: size * 1.3 * flip), _pp);
        } else {
          final lp = Path()
            ..moveTo(-size * 1.3, 0)
            ..quadraticBezierTo(0, -size * 1.1 * flip, size * 1.3, 0)
            ..quadraticBezierTo(0, size * 1.1 * flip, -size * 1.3, 0)
            ..close();
          c.drawPath(lp, _pp);
        }
        c.restore();
    }
  }
}

// ---------------------------------------------------------------- light

/// Soft slanted shafts of light fanning out from [origin]. Static: put it in a
/// still layer (optionally with a little rotate/sway around the origin).
void paintRays(
  Canvas c,
  Offset origin, {
  required double length,
  double centerAngle = math.pi / 2, // radians, pointing down
  double spread = 0.9,
  int count = 7,
  Color color = const Color(0xFFFFE9A8),
  double opacity = 0.22,
  int seed = 4,
  double minWidth = 0.05,
  double maxWidth = 0.14,
}) {
  final r = rng(seed);
  for (var i = 0; i < count; i++) {
    final t = count == 1 ? 0.5 : i / (count - 1);
    final a = centerAngle - spread / 2 + spread * t + (r.nextDouble() - 0.5) * 0.08;
    final wdt = minWidth + r.nextDouble() * (maxWidth - minWidth);
    final len = length * (0.6 + r.nextDouble() * 0.4);
    final p1 = origin + Offset(math.cos(a - wdt / 2), math.sin(a - wdt / 2)) * len;
    final p2 = origin + Offset(math.cos(a + wdt / 2), math.sin(a + wdt / 2)) * len;
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    final mid = origin + Offset(math.cos(a), math.sin(a)) * len;
    final o = opacity * (0.55 + r.nextDouble() * 0.6);
    c.drawPath(path, Paint()..shader = ui.Gradient.linear(origin, mid, [color.withValues(alpha: o), color.withValues(alpha: o * 0.45), color.withValues(alpha: 0)], const [0.0, 0.5, 1.0]));
  }
}

/// A horizontal band of soft mist / haze (static).
void paintMist(Canvas c, Rect band, Color color, [double opacity = 0.5]) {
  c.drawRect(
    band,
    Paint()
      ..shader = ui.Gradient.linear(band.topCenter, band.bottomCenter, [
        color.withValues(alpha: 0),
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0),
      ], const [0.0, 0.5, 1.0]),
  );
}

/// Soft elliptical puff of colour (mist, steam, light haze), cheap to draw.
void softEllipse(Canvas c, Offset center, double w, double h, Color color, [double opacity = 1.0]) {
  if (opacity <= 0) return;
  c
    ..save()
    ..translate(center.dx, center.dy)
    ..scale(1, h / w);
  glow(c, Offset.zero, w / 2, color, opacity);
  c.restore();
}

// ---------------------------------------------------------------- water & life

/// Animated wave surface; the crests travel [dir] and join up after one loop.
void paintWave(
  Canvas c,
  Size s,
  Clock k, {
  required double y, // fraction of height
  double amp = 0.012, // fraction of height
  double crests = 3, // wave lengths across the width
  int cycles = 3, // wave lengths travelled per loop
  double phase = 0,
  int dir = 1,
  required List<Color> colors, // top -> bottom fill
  double? bottom,
  Color? crest,
}) {
  final path = Path();
  final y0 = y * s.height, a = amp * s.height;
  final bot = (bottom ?? 1.05) * s.height;
  path.moveTo(-4, bot);
  const steps = 48;
  final shift = dir * k.saw(cycles) * tau;
  for (var i = 0; i <= steps; i++) {
    final x = -4 + (s.width + 8) * i / steps;
    final u = (x / s.width) * crests * tau + phase + shift;
    final yy = y0 + a * (math.sin(u) * 0.7 + math.sin(u * 2.1 + 1.3 + shift * 0.0) * 0.3);
    path.lineTo(x, yy);
  }
  path.lineTo(s.width + 4, bot);
  path.close();
  c.drawPath(path, verticalPaint(Rect.fromLTRB(0, y0 - a, s.width, bot), colors));
  if (crest != null) {
    final line = Path();
    for (var i = 0; i <= steps; i++) {
      final x = -4 + (s.width + 8) * i / steps;
      final u = (x / s.width) * crests * tau + phase + shift;
      final yy = y0 + a * (math.sin(u) * 0.7 + math.sin(u * 2.1 + 1.3) * 0.3);
      i == 0 ? line.moveTo(x, yy) : line.lineTo(x, yy);
    }
    c.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = crest,
    );
  }
}

/// Little glints sliding across a patch of water or ice.
void paintShimmer(Canvas c, Size s, Clock k, {required Rect region, int count = 28, int seed = 11, Color color = const Color(0xFFFFFFFF), int cycles = 10}) {
  final r = rng(seed);
  final k0 = s.width / 390;
  for (var i = 0; i < count; i++) {
    final x = region.left + r.nextDouble() * region.width;
    final y = region.top + r.nextDouble() * region.height;
    final w = (6 + r.nextDouble() * 22) * k0;
    final ph = r.nextDouble();
    final a = math.pow(k.pulse(cycles + i % 4, ph), 3).toDouble();
    if (a < 0.03) continue;
    final dx = k.sine(cycles ~/ 2 + 1, ph) * 4 * k0;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset((x * s.width) + dx, y * s.height), width: w, height: 1.6 * k0), const Radius.circular(1)),
      Paint()..color = color.withValues(alpha: 0.7 * a),
    );
  }
}

/// Simple bird silhouette; [flap] is -1..1 (wings down..up).
void paintBird(Canvas c, Offset o, double size, double flap, Color color) {
  final up = -size * (0.15 + 0.55 * (flap * 0.5 + 0.5));
  final p = Path()
    ..moveTo(o.dx - size, o.dy + up * 0.2)
    ..quadraticBezierTo(o.dx - size * 0.45, o.dy + up, o.dx, o.dy)
    ..quadraticBezierTo(o.dx + size * 0.45, o.dy + up, o.dx + size, o.dy + up * 0.2)
    ..quadraticBezierTo(o.dx + size * 0.45, o.dy + up * 0.45 + size * 0.1, o.dx, o.dy + size * 0.12)
    ..quadraticBezierTo(o.dx - size * 0.45, o.dy + up * 0.45 + size * 0.1, o.dx - size, o.dy + up * 0.2)
    ..close();
  c.drawPath(p, Paint()..color = color);
}

/// Birds gliding across the sky on a loop (wraps around the screen).
void paintBirds(Canvas c, Size s, Clock k, {int count = 4, int seed = 5, double y = 0.2, double band = 0.12, Color color = const Color(0xFF2B3A55), double size = 7, int cycles = 1, int dir = 1}) {
  final r = rng(seed);
  final k0 = s.width / 390;
  for (var i = 0; i < count; i++) {
    final yy = (y + r.nextDouble() * band) * s.height;
    final ph = r.nextDouble();
    final t = k.saw(cycles + (i % 2), ph);
    final x = dir > 0 ? -40 + t * (s.width + 80) : s.width + 40 - t * (s.width + 80);
    final bob = math.sin(tau * (k.u * (6 + i) + ph)) * 5 * k0;
    paintBird(c, Offset(x, yy + bob), size * k0 * (0.7 + r.nextDouble() * 0.6), k.sine(30 + i * 3, ph), color);
  }
}
