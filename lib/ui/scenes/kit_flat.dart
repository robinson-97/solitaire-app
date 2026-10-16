import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit_core.dart';
import 'kit_shapes.dart';

// FLAT, graphic helpers: solid colours, two-tone cel shading, smooth rounded
// silhouettes. No gradients inside shapes (skies and depth fades may use them).
// This is the house style: crisp, clean, tight 2D.

/// Hill / horizon band in one flat colour, with an optional flat lighter strip
/// along the crest ([light], [band] px thick) for a clean cel-shaded rim.
void flatRidge(Canvas c, Ridge r, Color color, {Color? light, double band = 3, double? bottomY}) {
  final path = r.fill(bottomY);
  if (light == null) {
    c.drawPath(path, Paint()..color = color);
    return;
  }
  c.drawPath(path, Paint()..color = light);
  c
    ..save()
    ..clipPath(path)
    ..drawPath(path.shift(Offset(0, band)), Paint()..color = color)
    ..restore();
}

/// Soft rounded mountains: flat colour with a flat darker side on every slope
/// that faces away from the light (light from the left).
void flatMountains(Canvas c, Ridge r, Color color, Color shade, {double? bottomY, Color? snow, double snowLine = 0}) {
  final b = bottomY ?? r.size.height * 1.05;
  c.drawPath(r.fill(b), Paint()..color = color);
  final pts = r.points;
  // find peaks (local minima of y) and the next valley (local maximum)
  final peaks = <int>[];
  for (var i = 2; i < pts.length - 2; i += 1) {
    if (pts[i].dy < pts[i - 1].dy && pts[i].dy <= pts[i + 1].dy && pts[i].dy < pts[i - 2].dy && pts[i].dy <= pts[i + 2].dy) peaks.add(i);
  }
  final sp = Paint()..color = shade;
  for (final pk in peaks) {
    var v = pk;
    while (v + 1 < pts.length && pts[v + 1].dy >= pts[v].dy - 0.01) {
      v++;
    }
    if (v - pk < 3) continue;
    final slope = <Offset>[for (var i = pk; i <= v; i++) pts[i]];
    final x0 = pts[pk].dx;
    final poly = [...slope, Offset(pts[v].dx, b), Offset(x0 + (pts[v].dx - x0) * 0.12, b)];
    c.drawPath(smoothPath(poly, closed: true), sp);
  }
  if (snow != null && snowLine > 0) {
    for (final pk in peaks) {
      if (pts[pk].dy > snowLine) continue;
      var l = pk, rr = pk;
      while (l > 0 && pts[l - 1].dy < snowLine) {
        l--;
      }
      while (rr + 1 < pts.length && pts[rr + 1].dy < snowLine) {
        rr++;
      }
      if (rr - l < 3) continue;
      final cap = <Offset>[for (var i = l; i <= rr; i++) pts[i]];
      final hem = <Offset>[
        for (var i = rr; i >= l; i--) Offset(pts[i].dx, pts[i].dy + (snowLine - pts[i].dy) * 0.55 + 3 + (i % 3 == 0 ? 5 : 0)),
      ];
      c.drawPath(smoothPath([...cap, ...hem], closed: true), Paint()..color = snow);
    }
  }
}

/// Flat cloud: rounded white shape with a flat shadow strip underneath.
void flatCloud(Canvas c, Offset base, double w, {Color color = const Color(0xFFFFFFFF), Color shade = const Color(0xFFD3DDF2), int seed = 1, double puff = 1.0, double opacity = 1.0}) {
  final r = rng(seed);
  final h = w * 0.3 * puff;
  final p = Path();
  final n = 4 + r.nextInt(2);
  for (var i = 0; i < n; i++) {
    final t = (i + 0.5) / n;
    final k = 1 - (t - 0.5).abs() * 1.5;
    final rad = h * (0.38 + 0.5 * k) * (0.85 + r.nextDouble() * 0.3);
    p.addOval(Rect.fromCircle(center: Offset(base.dx - w / 2 + w * (0.14 + 0.72 * t), base.dy - rad * 0.65), radius: rad));
  }
  p.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - w * 0.5, base.dy - h * 0.34, base.dx + w * 0.5, base.dy), Radius.circular(h * 0.34)));
  final op = (opacity * 255).round().clamp(0, 255);
  c.drawPath(p, Paint()..color = shade.withAlpha(op));
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(0, -h * 0.16)), Paint()..color = color.withAlpha(op))
    ..restore();
}

/// A round tree: trunk + crown of overlapping circles, two flat greens.
void flatTree(
  Canvas c,
  Offset base,
  double h, {
  required Color crown,
  required Color light,
  Color trunk = const Color(0xFF7A5238),
  Color? trunkShade,
  int seed = 1,
  double lean = 0,
  double crownScale = 1.0,
}) {
  final r = rng(seed);
  final tw = h * 0.07;
  final cx = base.dx + lean * h * 0.12;
  final trunkPath = Path()
    ..moveTo(base.dx - tw * 1.4, base.dy)
    ..quadraticBezierTo(base.dx - tw * 0.6, base.dy - h * 0.3, cx - tw * 0.7, base.dy - h * 0.62)
    ..lineTo(cx + tw * 0.7, base.dy - h * 0.62)
    ..quadraticBezierTo(base.dx + tw * 0.6, base.dy - h * 0.3, base.dx + tw * 1.4, base.dy)
    ..close();
  c.drawPath(trunkPath, Paint()..color = trunk);
  c
    ..save()
    ..clipPath(trunkPath)
    ..drawRect(Rect.fromLTRB(base.dx + tw * 0.15, base.dy - h, base.dx + tw * 2, base.dy), Paint()..color = trunkShade ?? darken(trunk, 0.1))
    ..restore();

  final cc = Offset(cx, base.dy - h * 0.68);
  final cr = h * 0.3 * crownScale;
  final p = Path();
  final n = 4 + r.nextInt(2);
  for (var i = 0; i < n; i++) {
    final a = tau * i / n + r.nextDouble() * 0.5;
    p.addOval(Rect.fromCircle(center: cc + Offset(math.cos(a) * cr * 0.55, math.sin(a) * cr * 0.45), radius: cr * (0.55 + r.nextDouble() * 0.2)));
  }
  p.addOval(Rect.fromCircle(center: cc, radius: cr * 0.75));
  // light crescent: crown shape in the light colour, then the crown colour shifted over it
  c.drawPath(p, Paint()..color = light);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(cr * 0.18, cr * 0.22)), Paint()..color = crown)
    ..restore();
}

/// Smooth fir tree, three rounded tiers; the right half of each tier is the
/// flat shade colour.
void flatPine(Canvas c, Offset base, double h, {required Color color, required Color shade, Color trunk = const Color(0xFF5A3F30), int tiers = 3, double width = 0.5}) {
  final tw = h * 0.04;
  c.drawRect(Rect.fromLTRB(base.dx - tw, base.dy - h * 0.2, base.dx + tw, base.dy), Paint()..color = trunk);
  for (var i = 0; i < tiers; i++) {
    final t = i / tiers;
    final top = base.dy - h + h * 0.62 * t * 0.9;
    final bot = base.dy - h * 0.14 - (tiers - 1 - i) * h * 0.26;
    final half = h * width * (0.4 + 0.6 * (t + 0.15)) * 0.5;
    final cx = base.dx;
    final tier = Path()
      ..moveTo(cx, top)
      ..quadraticBezierTo(cx - half * 0.4, (top + bot) / 2, cx - half, bot - h * 0.01)
      ..quadraticBezierTo(cx - half * 0.98, bot + h * 0.02, cx - half * 0.7, bot + h * 0.02)
      ..lineTo(cx + half * 0.7, bot + h * 0.02)
      ..quadraticBezierTo(cx + half * 0.98, bot + h * 0.02, cx + half, bot - h * 0.01)
      ..quadraticBezierTo(cx + half * 0.4, (top + bot) / 2, cx, top)
      ..close();
    c.drawPath(tier, Paint()..color = color);
    c
      ..save()
      ..clipPath(tier)
      ..drawRect(Rect.fromLTRB(cx + half * 0.02, top, cx + half * 1.2, bot + h * 0.05), Paint()..color = shade)
      ..restore();
  }
}

/// Smooth rounded boulder, two flat tones.
void flatRock(Canvas c, Offset base, double w, double h, {required Color color, required Color shade, int seed = 1}) {
  final r = rng(seed);
  final pts = <Offset>[
    Offset(base.dx - w / 2, base.dy),
    Offset(base.dx - w * 0.47, base.dy - h * (0.4 + r.nextDouble() * 0.15)),
    Offset(base.dx - w * 0.2, base.dy - h * (0.9 + r.nextDouble() * 0.1)),
    Offset(base.dx + w * 0.18, base.dy - h * (0.9 + r.nextDouble() * 0.1)),
    Offset(base.dx + w * 0.46, base.dy - h * (0.4 + r.nextDouble() * 0.15)),
    Offset(base.dx + w / 2, base.dy),
  ];
  final p = smoothPath(pts, closed: true);
  c.drawPath(p, Paint()..color = color);
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(base.dx + w * 0.06, base.dy - h * 1.2, base.dx + w, base.dy + 2), Paint()..color = shade)
    ..restore();
}

/// Round bush: overlapping circles, two flat greens.
void flatBush(Canvas c, Offset base, double w, {required Color color, required Color light, int seed = 1}) {
  final r = rng(seed);
  final p = Path();
  final n = 3 + r.nextInt(2);
  for (var i = 0; i < n; i++) {
    final t = (i + 0.5) / n;
    final rad = w * (0.2 + 0.12 * (1 - (t - 0.5).abs() * 1.6) + r.nextDouble() * 0.04);
    p.addOval(Rect.fromCircle(center: Offset(base.dx - w / 2 + w * t, base.dy - rad * 0.7), radius: rad));
  }
  c.drawPath(p, Paint()..color = light);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(w * 0.03, w * 0.05)), Paint()..color = color)
    ..restore();
}

/// Flat sun / moon disc with two flat translucent halo rings.
void flatSun(Canvas c, Offset o, double r, {Color core = const Color(0xFFFFF3C4), Color halo = const Color(0xFFFFE08A)}) {
  c.drawCircle(o, r * 2.4, Paint()..color = halo.withValues(alpha: 0.16));
  c.drawCircle(o, r * 1.6, Paint()..color = halo.withValues(alpha: 0.26));
  c.drawCircle(o, r, Paint()..color = core);
}

/// Flat stream / river ribbon between two edge curves, drawn as one flat fill
/// with a lighter flat strip on one side.
void flatRibbon(Canvas c, List<Offset> centre, List<double> halfWidth, {required Color color, Color? light, Color? bank}) {
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i < centre.length; i++) {
    final a = centre[math.max(i - 1, 0)], b = centre[math.min(i + 1, centre.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    left.add(centre[i] - n * halfWidth[i]);
    right.add(centre[i] + n * halfWidth[i]);
  }
  final p = smoothPath([...left, ...right.reversed], closed: true);
  if (bank != null) c.drawPath(p.shift(const Offset(0, 3)), Paint()..color = bank);
  c.drawPath(p, Paint()..color = color);
  if (light != null) {
    c
      ..save()
      ..clipPath(p)
      ..drawPath(smoothPath([for (var i = 0; i < left.length; i++) Offset.lerp(left[i], right[i], 0.12)!]), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = light)
      ..restore();
  }
}
