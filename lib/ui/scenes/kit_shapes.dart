import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit_core.dart';

// ---------------------------------------------------------------- paths

/// Smooth curve through [pts] (quadratic curves between midpoints, so there are
/// never any corners).
Path smoothPath(List<Offset> pts, {bool closed = false}) {
  final p = Path();
  if (pts.length < 2) return p;
  if (closed) {
    final n = pts.length;
    Offset mid(int a, int b) => Offset((pts[a % n].dx + pts[b % n].dx) / 2, (pts[a % n].dy + pts[b % n].dy) / 2);
    final m0 = mid(n - 1, 0);
    p.moveTo(m0.dx, m0.dy);
    for (var i = 0; i < n; i++) {
      final m = mid(i, i + 1);
      p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
    }
    p.close();
    return p;
  }
  p.moveTo(pts.first.dx, pts.first.dy);
  for (var i = 0; i < pts.length - 1; i++) {
    final m = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
    p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
  }
  p.lineTo(pts.last.dx, pts.last.dy);
  return p;
}

/// Soft organic blob (rounded, slightly irregular ellipse).
Path blobPath(Offset c, double rx, double ry, {int seed = 1, double wobble = 0.12, int lumps = 8}) {
  final r = rng(seed);
  final pts = <Offset>[
    for (var i = 0; i < lumps; i++)
      () {
        final a = tau * i / lumps;
        final k = 1 + (r.nextDouble() - 0.5) * 2 * wobble;
        return Offset(c.dx + math.cos(a) * rx * k, c.dy + math.sin(a) * ry * k);
      }(),
  ];
  return smoothPath(pts, closed: true);
}

// ---------------------------------------------------------------- terrain

/// A rolling / jagged horizon line you can fill, query ([yAt]) and decorate.
/// [y] and [amp] are fractions of the height.
class Ridge {
  Ridge(
    this.size, {
    required double y,
    required double amp,
    double freq = 2.0,
    int seed = 1,
    int octaves = 3,
    double sharp = 0,
    double tilt = 0,
    double x0 = -0.08,
    double x1 = 1.08,
    double step = 4,
    double Function(double n)? shaper,
  }) {
    final w = size.width, h = size.height;
    final pts = <Offset>[];
    final from = x0 * w, to = x1 * w;
    for (var x = from; x <= to + step; x += step) {
      var n = fbm(x / w * freq + 3.7, seed: seed, octaves: octaves);
      n = (n - 0.5) * 1.9 + 0.5; // widen the narrow noise range
      if (sharp > 0) n = n + (1 - (2 * n - 1).abs() - n) * sharp;
      if (shaper != null) n = shaper(n);
      pts.add(Offset(x, (y + tilt * (x / w - 0.5)) * h - (n - 0.5) * 2 * amp * h));
    }
    points = pts;
  }

  final Size size;
  late final List<Offset> points;

  double yAt(double x) {
    if (x <= points.first.dx) return points.first.dy;
    if (x >= points.last.dx) return points.last.dy;
    final step = points[1].dx - points[0].dx;
    final i = ((x - points.first.dx) / step).floor().clamp(0, points.length - 2);
    final t = (x - points[i].dx) / step;
    return points[i].dy + (points[i + 1].dy - points[i].dy) * t;
  }

  /// Highest point (smallest y).
  double get top => points.map((p) => p.dy).reduce(math.min);

  Path edge() => smoothPath(points);

  Path fill([double? bottom]) {
    final b = bottom ?? size.height * 1.05;
    final p = smoothPath(points);
    p
      ..lineTo(points.last.dx, b)
      ..lineTo(points.first.dx, b)
      ..close();
    return p;
  }
}

/// Fills a [Ridge] with a vertical gradient and a thin rim light on its crest.
void paintRidge(
  Canvas c,
  Ridge r, {
  required Color top,
  required Color bottom,
  double? bottomY,
  Color? rim,
  double rimWidth = 1.6,
  double rimAlpha = 0.55,
  Color? shadow, // darkens the underside of the hill for depth
}) {
  final b = bottomY ?? r.size.height * 1.05;
  final area = Rect.fromLTRB(0, r.top - 2, r.size.width, b);
  final path = r.fill(b);
  c.drawPath(path, verticalPaint(area, [top, bottom]));
  if (shadow != null) {
    c.save();
    c.clipPath(path);
    c.drawRect(area, verticalPaint(area, [shadow.withValues(alpha: 0), shadow]));
    c.restore();
  }
  if (rim != null) {
    c.drawPath(
      r.edge(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth
        ..strokeJoin = StrokeJoin.round
        ..color = rim.withValues(alpha: rimAlpha),
    );
  }
}

/// Light and shadow painted INSIDE a shape: gives flat vector art its volume.
/// [light] is the direction the light comes from, e.g. (-0.6, -0.8) = upper left.
void shadeInside(
  Canvas c,
  Path p, {
  Offset light = const Offset(-0.6, -0.8),
  Color lightColor = const Color(0xFFFFFFFF),
  double lightAlpha = 0.28,
  Color shadowColor = const Color(0xFF000020),
  double shadowAlpha = 0.28,
}) {
  final b = p.getBounds();
  if (b.isEmpty) return;
  final l = light / light.distance;
  final center = b.center;
  final ext = (b.width * l.dx).abs() / 2 + (b.height * l.dy).abs() / 2;
  c
    ..save()
    ..clipPath(p);
  c.drawRect(
    b.inflate(2),
    Paint()
      ..shader = ui.Gradient.linear(center + l * ext, center - l * ext, [
        lightColor.withValues(alpha: lightAlpha),
        lightColor.withValues(alpha: 0),
        shadowColor.withValues(alpha: 0),
        shadowColor.withValues(alpha: shadowAlpha),
      ], const [0.0, 0.42, 0.55, 1.0]),
  );
  c.restore();
}

/// Snow on the crest of a mountain [Ridge]: anything higher than [line] (a y
/// coordinate) is capped with a soft white drift.
void paintSnow(Canvas c, Ridge r, double line, {Color color = const Color(0xFFFFFFFF), Color shade = const Color(0xFFBFD4EE), int seed = 3}) {
  final pts = r.points;
  var i = 0;
  while (i < pts.length) {
    if (pts[i].dy < line) {
      var j = i;
      while (j + 1 < pts.length && pts[j + 1].dy < line) {
        j++;
      }
      if (j - i >= 2) {
        final top = pts.sublist(i, j + 1);
        final low = <Offset>[];
        for (var k = j; k >= i; k--) {
          final depth = (line - pts[k].dy) * (0.55 + 0.4 * vnoise(pts[k].dx * 0.05, seed));
          low.add(Offset(pts[k].dx, pts[k].dy + depth.clamp(1.0, 1e9)));
        }
        final path = smoothPath([...top, ...low], closed: true);
        final b = path.getBounds();
        c.drawPath(path, verticalPaint(b, [color, mix(color, shade, 0.7)]));
      }
      i = j + 1;
    } else {
      i++;
    }
  }
}

// ---------------------------------------------------------------- sky props

/// A flat-bottomed puffy cloud that can be drawn many times cheaply.
class CloudSprite {
  CloudSprite(this.width, {int seed = 1, this.top = const Color(0xFFFFFFFF), this.bottom = const Color(0xFFD6E4F5), double puff = 1.0}) {
    final r = rng(seed);
    final h = width * 0.34 * puff;
    height = h;
    final p = Path();
    final bumps = 4 + r.nextInt(3);
    for (var i = 0; i < bumps; i++) {
      final t = (i + 0.5) / bumps;
      final centerBias = 1 - (t - 0.5).abs() * 1.4;
      final rad = h * (0.34 + 0.34 * centerBias + r.nextDouble() * 0.12);
      final cx = -width / 2 + width * (0.12 + 0.76 * t);
      p.addOval(Rect.fromCircle(center: Offset(cx, -rad * 0.55 + h * 0.18), radius: rad));
    }
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-width * 0.5, -h * 0.18, width * 0.5, h * 0.34), Radius.circular(h * 0.26)));
    path = p;
    final b = p.getBounds();
    paint = Paint()..shader = ui.Gradient.linear(b.topCenter, b.bottomCenter, [top, mix(top, bottom, 0.35), bottom], const [0.0, 0.55, 1.0]);
  }

  final double width;
  final Color top, bottom;
  late final double height;
  late final Path path;
  late final Paint paint;

  /// Draws the cloud with its flat base centred on [at].
  void draw(Canvas c, Offset at, {double opacity = 1, double scale = 1}) {
    if (opacity <= 0) return;
    paint.color = Color.fromARGB((opacity * 255).round().clamp(0, 255), 255, 255, 255);
    c
      ..save()
      ..translate(at.dx, at.dy)
      ..scale(scale)
      ..drawPath(path, paint)
      ..restore();
  }
}

void paintMoon(Canvas c, Offset o, double r, {Color color = const Color(0xFFFFF6DC), Color shade = const Color(0xFFE3D2A8), bool craters = true, Color glowColor = const Color(0xFFBFD8FF)}) {
  glow(c, o, r * 3.4, glowColor, 0.5);
  glow(c, o, r * 1.9, glowColor, 0.45);
  final disc = Path()..addOval(Rect.fromCircle(center: o, radius: r));
  c.drawPath(disc, radialPaint(o + Offset(-r * 0.3, -r * 0.3), r * 1.5, [color, shade]));
  if (craters) {
    final rn = rng(5);
    c.save();
    c.clipPath(disc);
    for (var i = 0; i < 7; i++) {
      final a = rn.nextDouble() * tau, d = math.sqrt(rn.nextDouble()) * r * 0.78;
      final cr = r * (0.06 + rn.nextDouble() * 0.13);
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * d, cr, Paint()..color = shade.withValues(alpha: 0.55));
    }
    c.restore();
  }
  shadeInside(c, disc, light: const Offset(-0.7, -0.5), lightAlpha: 0.2, shadowColor: const Color(0xFF6A7090), shadowAlpha: 0.25);
}

void paintSun(Canvas c, Offset o, double r, {Color core = const Color(0xFFFFFBE0), Color edge = const Color(0xFFFFD27A), Color glowColor = const Color(0xFFFFC76B), double glowScale = 4.0}) {
  glow(c, o, r * glowScale, glowColor, 0.55, true);
  glow(c, o, r * glowScale * 0.5, glowColor, 0.6, true);
  c.drawCircle(o, r, radialPaint(o, r, [core, edge], const [0.55, 1.0]));
}

// ---------------------------------------------------------------- plants & rocks

/// Round-crowned tree: a tapered trunk and a lumpy canopy lit from the upper left.
void paintRoundTree(
  Canvas c,
  Offset base,
  double h, {
  Color leaf = const Color(0xFF2E8B57),
  Color light = const Color(0xFF8EDB5E),
  Color trunk = const Color(0xFF6B4A32),
  int seed = 1,
  double lean = 0,
  double crown = 1.0,
}) {
  final r = rng(seed);
  final tw = h * 0.075;
  final tp = Path()
    ..moveTo(base.dx - tw, base.dy)
    ..quadraticBezierTo(base.dx - tw * 0.5 + lean * 0.4, base.dy - h * 0.3, base.dx + lean * h * 0.1 - tw * 0.4, base.dy - h * 0.62)
    ..lineTo(base.dx + lean * h * 0.1 + tw * 0.4, base.dy - h * 0.62)
    ..quadraticBezierTo(base.dx + tw * 0.5 + lean * 0.4, base.dy - h * 0.3, base.dx + tw, base.dy)
    ..close();
  c.drawPath(tp, verticalPaint(tp.getBounds(), [lighten(trunk, 0.04), darken(trunk, 0.1)]));
  shadeInside(c, tp, light: const Offset(-1, -0.2), lightAlpha: 0.18, shadowAlpha: 0.3);

  final cc = Offset(base.dx + lean * h * 0.1, base.dy - h * 0.68);
  final cr = h * 0.34 * crown;
  final canopy = Path();
  final n = 6 + r.nextInt(3);
  for (var i = 0; i < n; i++) {
    final a = tau * i / n + r.nextDouble() * 0.5;
    final d = cr * (0.38 + r.nextDouble() * 0.22);
    canopy.addOval(Rect.fromCircle(center: cc + Offset(math.cos(a) * d, math.sin(a) * d * 0.8), radius: cr * (0.5 + r.nextDouble() * 0.2)));
  }
  canopy.addOval(Rect.fromCircle(center: cc, radius: cr * 0.7));
  final b = canopy.getBounds();
  c.drawPath(canopy, verticalPaint(b, [mix(leaf, light, 0.55), leaf, darken(leaf, 0.1)], const [0.0, 0.5, 1.0]));
  shadeInside(c, canopy, light: const Offset(-0.7, -0.8), lightColor: light, lightAlpha: 0.35, shadowColor: darken(leaf, 0.3), shadowAlpha: 0.4);
  // sunlit leaf clusters
  c.save();
  c.clipPath(canopy);
  for (var i = 0; i < 4; i++) {
    final a = -2.4 + r.nextDouble() * 1.4;
    final d = cr * (0.35 + r.nextDouble() * 0.5);
    c.drawCircle(cc + Offset(math.cos(a) * d, math.sin(a) * d), cr * (0.1 + r.nextDouble() * 0.12), Paint()..color = light.withValues(alpha: 0.35));
  }
  c.restore();
}

/// Layered fir tree with a lit left side, shaded right side and optional snow.
void paintPine(
  Canvas c,
  Offset base,
  double h, {
  Color dark = const Color(0xFF0E4B3A),
  Color light = const Color(0xFF2F9A6A),
  Color trunk = const Color(0xFF4B3426),
  int tiers = 4,
  double snow = 0,
  double width = 0.5,
}) {
  final tw = h * 0.035;
  c.drawRect(Rect.fromLTRB(base.dx - tw, base.dy - h * 0.18, base.dx + tw, base.dy), Paint()..color = trunk);
  for (var i = 0; i < tiers; i++) {
    final t = i / tiers;
    final top = base.dy - h + h * 0.8 * t * 0.78;
    final bot = base.dy - h * 0.14 - (tiers - 1 - i) * h * 0.205 * (4 / tiers);
    final wHalf = h * width * (0.34 + 0.66 * (t + 0.1)) * 0.5;
    final cx = base.dx;
    final tier = Path()
      ..moveTo(cx, top)
      ..quadraticBezierTo(cx - wHalf * 0.35, (top + bot) / 2, cx - wHalf, bot)
      ..quadraticBezierTo(cx, bot - h * 0.05, cx + wHalf, bot)
      ..quadraticBezierTo(cx + wHalf * 0.35, (top + bot) / 2, cx, top)
      ..close();
    c.drawPath(tier, verticalPaint(tier.getBounds(), [mix(dark, light, 0.5), dark]));
    // lit left half
    final lit = Path()
      ..moveTo(cx, top)
      ..quadraticBezierTo(cx - wHalf * 0.35, (top + bot) / 2, cx - wHalf, bot)
      ..quadraticBezierTo(cx - wHalf * 0.5, bot - h * 0.03, cx, bot - h * 0.04)
      ..close();
    c.drawPath(lit, Paint()..color = light.withValues(alpha: 0.5));
    if (snow > 0) {
      final cap = Path()
        ..moveTo(cx, top)
        ..quadraticBezierTo(cx - wHalf * 0.2, top + (bot - top) * 0.3, cx - wHalf * 0.55, top + (bot - top) * 0.58)
        ..quadraticBezierTo(cx - wHalf * 0.1, top + (bot - top) * 0.5, cx + wHalf * 0.05, top + (bot - top) * 0.62)
        ..quadraticBezierTo(cx + wHalf * 0.3, top + (bot - top) * 0.45, cx + wHalf * 0.5, top + (bot - top) * 0.55)
        ..quadraticBezierTo(cx + wHalf * 0.2, top + (bot - top) * 0.25, cx, top)
        ..close();
      c.drawPath(cap, Paint()..color = Colors.white.withValues(alpha: snow));
    }
  }
}

void paintBush(Canvas c, Offset base, double w, {Color dark = const Color(0xFF1F6B3A), Color light = const Color(0xFF7BCB55), int seed = 1}) {
  final r = rng(seed);
  final p = Path();
  final n = 4 + r.nextInt(2);
  for (var i = 0; i < n; i++) {
    final t = (i + 0.5) / n;
    final rad = w * (0.17 + 0.12 * (1 - (t - 0.5).abs() * 1.6) + r.nextDouble() * 0.04);
    p.addOval(Rect.fromCircle(center: Offset(base.dx - w / 2 + w * t, base.dy - rad * 0.7), radius: rad));
  }
  final b = p.getBounds();
  c.drawPath(p, verticalPaint(b, [mix(dark, light, 0.5), dark]));
  shadeInside(c, p, lightColor: light, lightAlpha: 0.35, shadowColor: darken(dark, 0.2), shadowAlpha: 0.35);
}

void paintRock(Canvas c, Offset base, double w, double h, {Color color = const Color(0xFF8A8F99), Color light = const Color(0xFFC6CBD3), int seed = 1}) {
  final r = rng(seed);
  final pts = <Offset>[
    Offset(base.dx - w / 2, base.dy),
    Offset(base.dx - w * 0.46, base.dy - h * (0.35 + r.nextDouble() * 0.2)),
    Offset(base.dx - w * 0.2, base.dy - h * (0.8 + r.nextDouble() * 0.2)),
    Offset(base.dx + w * 0.15, base.dy - h * (0.85 + r.nextDouble() * 0.15)),
    Offset(base.dx + w * 0.44, base.dy - h * (0.4 + r.nextDouble() * 0.2)),
    Offset(base.dx + w / 2, base.dy),
  ];
  final p = smoothPath(pts, closed: true);
  c.drawPath(p, verticalPaint(p.getBounds(), [light, color, darken(color, 0.12)], const [0.0, 0.5, 1.0]));
  shadeInside(c, p, lightAlpha: 0.2, shadowAlpha: 0.32);
}

/// A tuft of curved grass blades.
void paintGrassTuft(Canvas c, Offset base, double h, {Color dark = const Color(0xFF2B7A32), Color light = const Color(0xFF9BE05A), int blades = 7, int seed = 1, double sway = 0}) {
  final r = rng(seed);
  for (var i = 0; i < blades; i++) {
    final t = blades == 1 ? 0.5 : i / (blades - 1);
    final bh = h * (0.55 + 0.45 * math.sin(t * math.pi)) * (0.85 + r.nextDouble() * 0.3);
    final lean = (t - 0.5) * h * 0.9 + sway * bh;
    final w = h * 0.06;
    final x = base.dx + (t - 0.5) * h * 0.5;
    final p = Path()
      ..moveTo(x - w, base.dy)
      ..quadraticBezierTo(x - w * 0.4 + lean * 0.15, base.dy - bh * 0.6, x + lean, base.dy - bh)
      ..quadraticBezierTo(x + w * 0.4 + lean * 0.25, base.dy - bh * 0.55, x + w, base.dy)
      ..close();
    c.drawPath(p, linearPaint(Offset(x, base.dy), Offset(x + lean, base.dy - bh), [dark, light]));
  }
}

/// Flower with petals around a centre.
void paintFlower(Canvas c, Offset o, double r, {Color petal = const Color(0xFFFFE066), Color center = const Color(0xFFFF9F1C), int petals = 5, double rot = 0}) {
  for (var i = 0; i < petals; i++) {
    final a = rot + tau * i / petals;
    c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.62, r * 0.46, Paint()..color = petal);
  }
  c.drawCircle(o, r * 0.38, Paint()..color = center);
}

/// Hexagonal crystal spike with a bright facet.
void paintCrystal(Canvas c, Offset base, double w, double h, {Color color = const Color(0xFF9B6BFF), Color light = const Color(0xFFE2D0FF), double lean = 0}) {
  final tip = Offset(base.dx + lean * h, base.dy - h);
  final shoulder = h * 0.78;
  final body = Path()
    ..moveTo(base.dx - w / 2, base.dy)
    ..lineTo(base.dx - w * 0.5 + lean * shoulder * 0.9, base.dy - shoulder)
    ..lineTo(tip.dx, tip.dy)
    ..lineTo(base.dx + w * 0.5 + lean * shoulder * 0.9, base.dy - shoulder)
    ..lineTo(base.dx + w / 2, base.dy)
    ..close();
  c.drawPath(body, linearPaint(Offset(base.dx - w / 2, base.dy), Offset(base.dx + w / 2, tip.dy), [darken(color, 0.12), color, light], const [0.0, 0.5, 1.0]));
  final facet = Path()
    ..moveTo(base.dx - w * 0.05, base.dy)
    ..lineTo(base.dx - w * 0.04 + lean * shoulder * 0.9, base.dy - shoulder)
    ..lineTo(tip.dx, tip.dy)
    ..lineTo(base.dx + w * 0.5 + lean * shoulder * 0.9, base.dy - shoulder)
    ..lineTo(base.dx + w / 2, base.dy)
    ..close();
  c.drawPath(facet, Paint()..color = darken(color, 0.18).withValues(alpha: 0.5));
}
