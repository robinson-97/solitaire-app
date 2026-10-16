import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit_core.dart';
import 'kit_shapes.dart';

// Hand-painted (gouache / storybook) helpers. Everything here is meant for
// STILL layers: it draws hundreds of small brush marks once and is cached.

/// Colour of a vertical gradient at [t] (0 top .. 1 bottom).
Color gradientAt(List<Color> colors, double t, [List<double>? stops]) {
  final st = stops ?? [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];
  if (t <= st.first) return colors.first;
  for (var i = 0; i < colors.length - 1; i++) {
    if (t <= st[i + 1]) return Color.lerp(colors[i], colors[i + 1], (t - st[i]) / (st[i + 1] - st[i]))!;
  }
  return colors.last;
}

/// Many soft translucent brush strokes: gives flat gradients a hand-painted
/// texture. Strokes follow [angle] (radians, 0 = horizontal) and pick random
/// colours from [colors]. Draw it over a base fill, inside [clip] if given.
void paintBrushwork(
  Canvas c,
  Rect area, {
  Path? clip,
  required List<Color> colors,
  int strokes = 200,
  double minLen = 24,
  double maxLen = 90,
  double thickness = 7,
  double alpha = 0.14,
  double angle = 0,
  double angleJitter = 0.18,
  double curve = 0.25,
  int seed = 1,
}) {
  final r = rng(seed);
  c.save();
  if (clip != null) c.clipPath(clip);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < strokes; i++) {
    final cx = area.left + r.nextDouble() * area.width;
    final cy = area.top + r.nextDouble() * area.height;
    final len = minLen + r.nextDouble() * (maxLen - minLen);
    final a = angle + (r.nextDouble() - 0.5) * 2 * angleJitter;
    final dx = math.cos(a) * len / 2, dy = math.sin(a) * len / 2;
    final bend = (r.nextDouble() - 0.5) * len * curve;
    final path = Path()
      ..moveTo(cx - dx, cy - dy)
      ..quadraticBezierTo(cx - dy * 0 + (-math.sin(a)) * bend, cy + math.cos(a) * bend, cx + dx, cy + dy);
    p
      ..strokeWidth = thickness * (0.5 + r.nextDouble())
      ..color = colors[r.nextInt(colors.length)].withValues(alpha: alpha * (0.5 + r.nextDouble() * 0.8));
    c.drawPath(path, p);
  }
  c.restore();
}

/// Sky gradient with horizontal brush texture (the base of every painted sky).
void paintSkyWash(Canvas c, Size s, List<Color> colors, {List<double>? stops, int seed = 2, int strokes = 260, double alpha = 0.16}) {
  fillSky(c, s, colors, stops);
  final r = rng(seed);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < strokes; i++) {
    final y = r.nextDouble();
    final base = gradientAt(colors, y, stops);
    final lighter = r.nextBool();
    final col = lighter ? lighten(base, 0.05 + r.nextDouble() * 0.07) : darken(base, 0.03 + r.nextDouble() * 0.05);
    final len = s.width * (0.18 + r.nextDouble() * 0.5);
    final x = (r.nextDouble() * 1.3 - 0.15) * s.width;
    final yy = y * s.height;
    final path = Path()
      ..moveTo(x, yy)
      ..quadraticBezierTo(x + len / 2, yy + (r.nextDouble() - 0.5) * 12, x + len, yy + (r.nextDouble() - 0.5) * 6);
    p
      ..strokeWidth = 10 + r.nextDouble() * 26
      ..color = col.withValues(alpha: alpha * (0.4 + r.nextDouble() * 0.8));
    c.drawPath(path, p);
  }
}

/// Fine paper / film grain over the whole frame (cheap: two point batches).
void paintGrain(Canvas c, Size s, {int seed = 5, double amount = 1.0}) {
  final r = rng(seed);
  final n = (s.width * s.height / 70).round();
  final dark = Float32List(n * 2), light = Float32List(n * 2);
  for (var i = 0; i < n; i++) {
    dark[i * 2] = r.nextDouble() * s.width;
    dark[i * 2 + 1] = r.nextDouble() * s.height;
    light[i * 2] = r.nextDouble() * s.width;
    light[i * 2 + 1] = r.nextDouble() * s.height;
  }
  c.drawRawPoints(
    ui.PointMode.points,
    dark,
    Paint()
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1B1030).withValues(alpha: 0.05 * amount),
  );
  c.drawRawPoints(
    ui.PointMode.points,
    light,
    Paint()
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFF6E0).withValues(alpha: 0.06 * amount),
  );
}

/// Slightly irregular, hand-drawn version of [p] (organic outlines).
Path wobblePath(Path p, {double amp = 1.6, double step = 9, int seed = 1}) {
  final out = Path();
  for (final m in p.computeMetrics()) {
    final pts = <Offset>[];
    for (var d = 0.0; d < m.length; d += step) {
      final t = m.getTangentForOffset(d)!;
      final n = Offset(-t.vector.dy, t.vector.dx);
      final k = (vnoise(d * 0.045 + seed * 3.1, seed) - 0.5) * 2 * amp;
      pts.add(t.position + n * k);
    }
    if (pts.length > 2) out.addPath(smoothPath(pts, closed: m.isClosed), Offset.zero);
  }
  return out;
}

/// Soft cast shadow of a shape (static layers only: uses a blur).
void softShadow(Canvas c, Path p, {Offset offset = const Offset(6, 8), double blur = 8, Color color = const Color(0xFF1B1030), double opacity = 0.25}) {
  c.drawPath(
    p.shift(offset),
    Paint()
      ..color = color.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
  );
}

// ---------------------------------------------------------------- clouds

/// Big billowy cumulus: overlapping puffs, each lit from [light] with a warm
/// top, a cool lilac belly and a thin bright rim, like a painted Ghibli sky.
/// [width] is the total width; the flat-ish base sits at [base].
void paintCumulus(
  Canvas c,
  Offset base,
  double width, {
  double height = 0,
  Color lit = const Color(0xFFFFFDF5),
  Color mid = const Color(0xFFEAF0FA),
  Color shade = const Color(0xFFAEB9E3),
  Offset light = const Offset(-0.55, -0.8),
  int seed = 1,
  double opacity = 1.0,
}) {
  final r = rng(seed);
  final h = height > 0 ? height : width * 0.42;
  final puffs = <(Offset, double)>[];
  // base row
  final nb = 4 + (width / 90).round().clamp(0, 5);
  for (var i = 0; i < nb; i++) {
    final t = (i + 0.5) / nb;
    final env = 0.55 + 0.45 * math.sin(t * math.pi);
    final rad = h * (0.22 + 0.2 * env) * (0.85 + r.nextDouble() * 0.3);
    puffs.add((Offset((t - 0.5) * width * 0.9, -rad * 0.62), rad));
  }
  // middle row
  final nm = 2 + (width / 130).round().clamp(0, 4);
  for (var i = 0; i < nm; i++) {
    final t = (i + 0.6 + r.nextDouble() * 0.4) / (nm + 0.5);
    final env = math.sin(t * math.pi);
    final rad = h * (0.26 + 0.22 * env) * (0.85 + r.nextDouble() * 0.3);
    puffs.add((Offset((t - 0.5) * width * 0.7, -h * (0.4 + 0.25 * env) - rad * 0.2), rad));
  }
  // crown
  final nc = 1 + r.nextInt(2);
  for (var i = 0; i < nc; i++) {
    final rad = h * (0.26 + r.nextDouble() * 0.12);
    puffs.add((Offset((r.nextDouble() - 0.5) * width * 0.35, -h * (0.78 + r.nextDouble() * 0.15)), rad));
  }
  puffs.sort((a, b) => a.$1.dy.compareTo(b.$1.dy)); // high puffs first (behind)
  final l = light / light.distance;
  final op = (opacity * 255).round().clamp(0, 255);
  final lightAngle = math.atan2(l.dy, l.dx);
  c.save();
  c.translate(base.dx, base.dy);
  for (final (o, rad) in puffs) {
    final focus = o + l * rad * 0.5;
    c.drawCircle(
      o,
      rad * 1.03,
      Paint()
        ..shader = ui.Gradient.radial(
          focus,
          rad * 1.55,
          [lit.withAlpha(op), mid.withAlpha(op), shade.withAlpha(op), shade.withAlpha(0)],
          const [0.0, 0.5, 0.88, 1.0],
        ),
    );
    // thin bright rim on the sunny side
    c.drawArc(
      Rect.fromCircle(center: o, radius: rad * 0.93),
      lightAngle - 1.0,
      2.0,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, rad * 0.05)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.55 * opacity),
    );
  }
  // flat cool belly so the cloud sits heavy
  final belly = Rect.fromCenter(center: Offset(0, -h * 0.03), width: width * 0.92, height: h * 0.3);
  c.drawOval(
    belly,
    Paint()..shader = ui.Gradient.linear(belly.topCenter, belly.bottomCenter, [shade.withAlpha(0), shade.withAlpha((op * 0.6).round())]),
  );
  c.restore();
}

// ---------------------------------------------------------------- plants

/// A painted tree crown / bush: a dark mass built from leaf CLUMPS, each with
/// many small leaf dabs in three tones lit from [lightDir], plus loose leaves
/// breaking the outline. [radius] is the crown radius.
void paintFoliage(
  Canvas c,
  Offset center,
  double radius, {
  Color dark = const Color(0xFF1E5A3A),
  Color mid = const Color(0xFF3F8F4A),
  Color light = const Color(0xFF9BD25A),
  Color? sparkle,
  Offset lightDir = const Offset(-0.6, -0.8),
  int seed = 1,
  double density = 1.0,
  double squash = 0.88,
  int clusters = 0,
}) {
  final r = rng(seed);
  final l = lightDir / lightDir.distance;
  final nCl = clusters > 0 ? clusters : (6 + (radius / 14).round().clamp(0, 8));
  // cluster layout: a ring of clumps around a core
  final cl = <(Offset, double)>[];
  for (var i = 0; i < nCl; i++) {
    final a = tau * i / nCl + r.nextDouble() * 0.7;
    final d = radius * (0.2 + r.nextDouble() * 0.5);
    final rc = radius * (0.28 + r.nextDouble() * 0.16);
    cl.add((center + Offset(math.cos(a) * d, math.sin(a) * d * squash), rc));
  }
  cl.add((center + Offset(0, -radius * 0.05), radius * 0.5));
  final mass = Path();
  for (final (o, rc) in cl) {
    mass.addOval(Rect.fromCenter(center: o, width: rc * 2.1, height: rc * 1.85 * squash));
  }
  final b = mass.getBounds();
  c.drawPath(mass, verticalPaint(b, [mix(dark, mid, 0.45), dark, darken(dark, 0.07)], const [0.0, 0.5, 1.0]));

  final leaf = Paint();
  c.save();
  c.clipPath(mass);
  // clumps back to front (lower ones last so their lit tops overlap)
  cl.sort((a, b) => a.$1.dy.compareTo(b.$1.dy));
  for (final (o, rc) in cl) {
    final facing = ((o - center).dx * l.dx + (o - center).dy * l.dy) / math.max(radius, 1);
    final lit = (0.5 + 0.55 * facing).clamp(0.0, 1.0);
    // clump body: darker underside, lighter top
    final body = Rect.fromCenter(center: o, width: rc * 1.9, height: rc * 1.6 * squash);
    c.drawOval(body, Paint()..shader = ui.Gradient.linear(body.topCenter, body.bottomCenter, [mix(dark, mid, 0.4 + 0.5 * lit), mix(dark, mid, 0.1 + 0.3 * lit)]));
    final n = (rc * rc / 60 * density).round().clamp(12, 220);
    for (var i = 0; i < n; i++) {
      final ang = r.nextDouble() * tau;
      final rr = math.sqrt(r.nextDouble());
      final p = Offset(math.cos(ang) * rr * rc * 0.95, math.sin(ang) * rr * rc * 0.82 * squash);
      final up = (-p.dy / (rc * 0.8)).clamp(-1.0, 1.0); // 1 at the top of the clump
      final side = (p.dx * l.dx + p.dy * l.dy) / (rc * 0.9);
      final tone = (0.35 + 0.35 * up + 0.3 * side + (lit - 0.5) * 0.5 + (r.nextDouble() - 0.5) * 0.35).clamp(0.0, 1.0);
      final col = tone < 0.5 ? Color.lerp(dark, mid, tone * 2)! : Color.lerp(mid, light, (tone - 0.5) * 2)!;
      final w = radius * (0.028 + r.nextDouble() * 0.03);
      c
        ..save()
        ..translate(o.dx + p.dx, o.dy + p.dy)
        ..rotate(-1.1 + r.nextDouble() * 2.2);
      leaf.color = col.withValues(alpha: 0.88);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 2.4, height: w * 1.15), leaf);
      c.restore();
    }
    // bright specks on the lit crown of the clump
    if (sparkle != null) {
      for (var i = 0; i < (rc * 0.18 * density).round(); i++) {
        final ang = lightDirAngle(l) + (r.nextDouble() - 0.5) * 1.6;
        final p = Offset(math.cos(ang), math.sin(ang)) * rc * (0.45 + r.nextDouble() * 0.4);
        leaf.color = sparkle.withValues(alpha: 0.8);
        c.drawCircle(o + p, radius * 0.012 + r.nextDouble() * 1.2, leaf);
      }
    }
  }
  c.restore();

  // loose leaves breaking the outline
  final outline = Paint();
  for (var i = 0; i < (radius * 0.7 * density).round(); i++) {
    final ang = r.nextDouble() * tau;
    final rr = radius * (0.9 + r.nextDouble() * 0.2);
    final o = center + Offset(math.cos(ang) * rr, math.sin(ang) * rr * squash);
    final facing = (math.cos(ang) * l.dx + math.sin(ang) * l.dy) * 0.5 + 0.5;
    final col = Color.lerp(mix(dark, mid, 0.3), light, facing * facing * r.nextDouble())!;
    final w = radius * (0.03 + r.nextDouble() * 0.03);
    c
      ..save()
      ..translate(o.dx, o.dy)
      ..rotate(ang + math.pi / 2 + (r.nextDouble() - 0.5));
    outline.color = col.withValues(alpha: 0.95);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 2.4, height: w * 1.15), outline);
    c.restore();
  }
}

double lightDirAngle(Offset l) => math.atan2(l.dy, l.dx);

/// A patch of grass blades (static).
void paintGrassBlades(
  Canvas c,
  Rect area, {
  Color dark = const Color(0xFF2F7A3A),
  Color light = const Color(0xFFB4E060),
  int count = 300,
  double minH = 6,
  double maxH = 20,
  double lean = 0.0,
  double alpha = 0.92,
  int seed = 1,
}) {
  final r = rng(seed);
  final p = Paint();
  for (var i = 0; i < count; i++) {
    final x = area.left + r.nextDouble() * area.width;
    final y = area.top + r.nextDouble() * area.height;
    final h = minH + r.nextDouble() * (maxH - minH);
    final bend = (lean + (r.nextDouble() - 0.5) * 0.6) * h;
    final w = 0.9 + r.nextDouble() * 1.4;
    final path = Path()
      ..moveTo(x - w, y)
      ..quadraticBezierTo(x - w * 0.3 + bend * 0.3, y - h * 0.6, x + bend, y - h)
      ..quadraticBezierTo(x + w * 0.4 + bend * 0.3, y - h * 0.55, x + w, y)
      ..close();
    p.color = Color.lerp(dark, light, math.pow(r.nextDouble(), 0.8).toDouble())!.withValues(alpha: alpha);
    c.drawPath(path, p);
  }
}

/// A cluster of soft wildflower dots.
void paintWildflowers(Canvas c, Rect area, {required List<Color> colors, int count = 40, double size = 2.6, int seed = 1}) {
  final r = rng(seed);
  for (var i = 0; i < count; i++) {
    final x = area.left + r.nextDouble() * area.width;
    final y = area.top + r.nextDouble() * area.height;
    final col = colors[r.nextInt(colors.length)];
    final sz = size * (0.7 + r.nextDouble() * 0.8);
    c.drawCircle(Offset(x, y), sz, Paint()..color = col);
    c.drawCircle(Offset(x - sz * 0.25, y - sz * 0.25), sz * 0.45, Paint()..color = Colors.white.withValues(alpha: 0.55));
  }
}
