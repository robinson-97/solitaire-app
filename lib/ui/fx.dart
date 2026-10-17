import 'dart:math';
import 'package:flutter/material.dart';

/// Each peg theme has its own hop trail and landing effect. Everything is
/// drawn with smooth vector shapes and soft glows, no hard pixels.
enum FxKind {
  none,
  dust,
  firefly,
  moon,
  ember,
  crystal,
  star,
  frost,
  puff,
  confetti,
  pixel,
  note,
  sprinkles,
  crumbs,
  heart,
  spore,
  splash,
  shock,
  gear,
  sweep,
  glint,
  flame,
  disco,
  orbit,
  swirl,
  bounce,
  leaf,
  chalk,
  curtain,
  tendril,
  ripple,
  lantern,
}

/// Soft round glow (radial gradient, no blur filter needed).
void _glow(Canvas c, Offset o, double r, Color color, double a) {
  if (a <= 0 || r <= 0) return;
  c.drawCircle(
    o,
    r,
    Paint()..shader = RadialGradient(colors: [color.withValues(alpha: a.clamp(0.0, 1.0)), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)),
  );
}

/// A bright dot with a soft halo.
void _orb(Canvas c, Offset o, double r, Color color, double a, {Color core = Colors.white}) {
  _glow(c, o, r * 2.8, color, a * 0.55);
  c.drawCircle(o, r, Paint()..color = Color.lerp(color, core, 0.75)!.withValues(alpha: a.clamp(0.0, 1.0)));
}

/// Thin four-pointed sparkle.
void _sparkle(Canvas c, Offset o, double r, Color color, double a, {double rot = 0}) {
  if (a <= 0 || r <= 0) return;
  final p = Path();
  for (var i = 0; i < 8; i++) {
    final ang = rot + i * pi / 4;
    final rad = i.isEven ? r : r * 0.16;
    final q = o + Offset(cos(ang), sin(ang)) * rad;
    i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
  }
  p.close();
  _glow(c, o, r * 1.3, color, a * 0.5);
  c.drawPath(p, Paint()..color = Color.lerp(color, Colors.white, 0.8)!.withValues(alpha: a.clamp(0.0, 1.0)));
}

void _groundRing(Canvas c, Offset center, double rx, Color color, double a, {double width = 2.4, double squash = 0.45}) {
  if (a <= 0 || rx <= 0) return;
  c.drawOval(
    Rect.fromCenter(center: center, width: rx * 2, height: rx * 2 * squash),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color.withValues(alpha: a.clamp(0.0, 1.0)),
  );
}

Path _teardrop(Offset o, double w, double h) => Path()
  ..moveTo(o.dx, o.dy - h)
  ..cubicTo(o.dx + w * 0.2, o.dy - h * 0.4, o.dx + w, o.dy - h * 0.1, o.dx + w * 0.5, o.dy + h * 0.5)
  ..quadraticBezierTo(o.dx, o.dy + h * 0.9, o.dx - w * 0.5, o.dy + h * 0.5)
  ..cubicTo(o.dx - w, o.dy - h * 0.1, o.dx - w * 0.2, o.dy - h * 0.4, o.dx, o.dy - h)
  ..close();

Path _heart(Offset o, double r) => Path()
  ..moveTo(o.dx, o.dy + r * 1.1)
  ..cubicTo(o.dx - r * 2.0, o.dy - r * 0.2, o.dx - r * 0.9, o.dy - r * 1.5, o.dx, o.dy - r * 0.4)
  ..cubicTo(o.dx + r * 0.9, o.dy - r * 1.5, o.dx + r * 2.0, o.dy - r * 0.2, o.dx, o.dy + r * 1.1);

Path _leaf(Offset o, double len, double wid, double rot) {
  final dx = cos(rot), dy = sin(rot);
  final tip = o + Offset(dx, dy) * len;
  final tail = o - Offset(dx, dy) * len;
  final n = Offset(-dy, dx) * wid;
  return Path()
    ..moveTo(tail.dx, tail.dy)
    ..quadraticBezierTo(o.dx + n.dx, o.dy + n.dy, tip.dx, tip.dy)
    ..quadraticBezierTo(o.dx - n.dx, o.dy - n.dy, tail.dx, tail.dy)
    ..close();
}

Path _gear(Offset o, double r, int teeth, double rot) {
  final p = Path();
  final n = teeth * 4;
  for (var i = 0; i < n; i++) {
    final a = rot + i * 2 * pi / n;
    final rad = (i % 4 < 2) ? r : r * 0.78;
    final q = o + Offset(cos(a), sin(a)) * rad;
    i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
  }
  return p..close();
}

/// One particle for the hop trail (small, soft). [r] is its radius, [alpha] 0..1.
void drawParticle(Canvas c, FxKind k, Offset o, double r, double alpha, Color color, double rot) {
  if (alpha <= 0 || r <= 0) return;
  final a = alpha.clamp(0.0, 1.0);
  switch (k) {
    case FxKind.none:
      return;
    case FxKind.dust:
    case FxKind.crumbs:
    case FxKind.chalk:
      _glow(c, o, r * 2.0, k == FxKind.dust ? const Color(0xFFB07A44) : color, a * 0.6);
    case FxKind.moon:
    case FxKind.glint:
    case FxKind.star:
      _sparkle(c, o, r * 1.7, k == FxKind.star ? const Color(0xFFFFE27A) : color, a, rot: rot * 0.3);
    case FxKind.crystal:
      c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - r * 1.5)
          ..lineTo(o.dx + r * 0.8, o.dy)
          ..lineTo(o.dx, o.dy + r * 1.5)
          ..lineTo(o.dx - r * 0.8, o.dy)
          ..close(),
        Paint()..color = Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: a),
      );
    case FxKind.frost:
      final p = Paint()
        ..color = const Color(0xFFDFF6FF).withValues(alpha: a)
        ..strokeWidth = max(1.0, r * 0.28)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final ang = rot + i * pi / 3;
        final d = Offset(cos(ang), sin(ang)) * r * 1.3;
        c.drawLine(o - d, o + d, p);
      }
    case FxKind.confetti:
    case FxKind.sprinkles:
      c.drawOval(Rect.fromCenter(center: o, width: r * 1.8 * (0.35 + 0.65 * cos(rot).abs()), height: r * 0.9), Paint()..color = HSVColor.fromAHSV(a, (rot * 57) % 360, 0.65, 1).toColor());
    case FxKind.pixel:
      _orb(c, o, r * 0.8, const Color(0xFFFFD23A), a);
    case FxKind.note:
      final p = Paint()..color = color.withValues(alpha: a);
      c.drawOval(Rect.fromCenter(center: o, width: r * 1.5, height: r * 1.1), p);
      c.drawLine(o + Offset(r * 0.7, 0), o + Offset(r * 0.7, -r * 2.2), p..strokeWidth = max(1.0, r * 0.3));
      c.drawPath(Path()..moveTo(o.dx + r * 0.7, o.dy - r * 2.2)..quadraticBezierTo(o.dx + r * 1.9, o.dy - r * 1.6, o.dx + r * 1.2, o.dy - r * 0.9), p..style = PaintingStyle.stroke);
    case FxKind.heart:
      c.drawPath(_heart(o, r), Paint()..color = const Color(0xFFFF5C8A).withValues(alpha: a));
    case FxKind.leaf:
      c.drawPath(_leaf(o, r * 1.4, r * 0.6, rot), Paint()..color = color.withValues(alpha: a));
    case FxKind.gear:
      c.drawPath(_gear(o, r * 1.2, 6, rot), Paint()..color = color.withValues(alpha: a * 0.9));
    case FxKind.flame:
      c.drawPath(_teardrop(o, r * 0.9, r * 1.5), Paint()..color = Color.lerp(color, const Color(0xFFFFE08A), 0.4)!.withValues(alpha: a));
    case FxKind.firefly:
    case FxKind.ember:
    case FxKind.spore:
    case FxKind.lantern:
    case FxKind.splash:
    case FxKind.puff:
    case FxKind.bounce:
    case FxKind.shock:
    case FxKind.sweep:
    case FxKind.disco:
    case FxKind.orbit:
    case FxKind.swirl:
    case FxKind.curtain:
    case FxKind.tendril:
    case FxKind.ripple:
      _orb(c, o, r * 0.75, color, a);
  }
}

/// Landing effect. [v] runs 0..1; [px] is a peg diameter; [center] the hole.
void paintLanding(Canvas c, FxKind k, Offset center, double px, double v, Color color, {required bool ripple}) {
  if (v <= 0 || v >= 1) return;
  if (ripple) {
    paintRipple(c, center, px, v, color);
    return;
  }
  if (k == FxKind.none) {
    paintRipple(c, center, px, v, color);
    return;
  }
  _burst(c, k, center, px, v, color);
}

void paintRipple(Canvas c, Offset center, double px, double v, Color color) {
  for (var i = 0; i < 2; i++) {
    final t = (v - i * 0.15).clamp(0.0, 1.0);
    if (t <= 0) continue;
    _groundRing(c, center, px * (0.4 + 0.8 * t), color, (1 - t) * 0.65, width: 2.4 * (1 - t) + 0.5);
  }
}

double _eo(double v) => Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));

void _burst(Canvas c, FxKind k, Offset center, double px, double v, Color color) {
  final rnd = Random(k.index * 31 + 5);
  final up = center - Offset(0, px * 0.32);
  final e = _eo(v);
  final f = (1 - v).clamp(0.0, 1.0);
  double rr() => rnd.nextDouble();
  switch (k) {
    case FxKind.none:
      return;

    case FxKind.dust:
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * 2 * pi + rr() * 0.5;
        final d = px * (0.3 + 0.9 * e) * (0.7 + rr() * 0.5);
        _glow(c, center + Offset(cos(a) * d, sin(a) * d * 0.42 - px * 0.1 * e), px * (0.2 + 0.28 * e), const Color(0xFFB48A5A), 0.5 * f);
      }

    case FxKind.firefly:
      for (var i = 0; i < 8; i++) {
        final sp = 0.5 + rr() * 0.8;
        final o = up + Offset(sin(v * 6 + i * 1.7) * px * 0.35 + (i - 4) * px * 0.12, -px * (0.2 + 1.5 * v * sp));
        final tw = 0.6 + 0.4 * sin(v * 18 + i * 2.1);
        _orb(c, o, px * (0.05 + 0.04 * rr()), color, f * tw, core: const Color(0xFFF6FFC0));
      }
      _glow(c, up, px * (0.6 + 0.8 * e), color, 0.22 * f);

    case FxKind.moon:
      _glow(c, up, px * (0.5 + 1.3 * e), color, 0.35 * f);
      _groundRing(c, center, px * (0.4 + 1.1 * e), Colors.white, 0.6 * f, width: 1.8);
      for (var i = 0; i < 6; i++) {
        final a = rr() * 2 * pi;
        final d = px * (0.35 + 0.6 * rr());
        final o = up + Offset(cos(a) * d, sin(a) * d * 0.7 - px * 0.6 * e);
        final pop = sin(pi * ((v * 1.3 - i * 0.07).clamp(0.0, 1.0)));
        _sparkle(c, o, px * 0.2 * pop, color, pop, rot: v);
      }

    case FxKind.ember:
      for (var i = 0; i < 14; i++) {
        final ang = -pi / 2 + (rr() - 0.5) * 1.9;
        final sp = px * (1.6 + rr() * 1.6);
        final p0 = up + Offset(cos(ang) * sp * v, sin(ang) * sp * v + px * 2.8 * v * v);
        final dir = Offset(cos(ang) * sp, sin(ang) * sp + px * 5.6 * v);
        final tail = p0 - dir / dir.distance * px * 0.22 * f;
        c.drawLine(tail, p0, Paint()..color = const Color(0xFFFFB03A).withValues(alpha: f * 0.8)..strokeWidth = px * 0.06..strokeCap = StrokeCap.round);
        _orb(c, p0, px * 0.05, const Color(0xFFFF6A1A), f, core: const Color(0xFFFFE9A8));
      }
      if (v > 0.2) {
        for (var i = 0; i < 3; i++) {
          final t = ((v - 0.2 + i * 0.05) / 0.8).clamp(0.0, 1.0);
          _glow(c, up + Offset((i - 1) * px * 0.18, -px * 1.5 * t), px * (0.25 + 0.3 * t), const Color(0xFF8A8A92), 0.28 * (1 - t));
        }
      }

    case FxKind.crystal:
      _groundRing(c, center, px * (0.3 + 1.4 * _eo(v * 1.4)), Colors.white, 0.8 * (1 - v * 1.4).clamp(0.0, 1.0), width: 2.2);
      _glow(c, up, px * (0.5 + 0.9 * e), color, 0.4 * f);
      for (var i = 0; i < 9; i++) {
        final a = i / 9 * 2 * pi + rr() * 0.3;
        final d = px * (0.5 + 1.0 * e) * (0.7 + rr() * 0.5);
        final o = up + Offset(cos(a) * d, sin(a) * d * 0.55 - px * 0.3 * e);
        final len = px * 0.22 * (1 - v * 0.4), w = px * 0.07;
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(a + pi / 2);
        c.drawPath(
          Path()..moveTo(0, -len)..lineTo(w, 0)..lineTo(0, len * 0.6)..lineTo(-w, 0)..close(),
          Paint()..color = Color.lerp(color, Colors.white, 0.55)!.withValues(alpha: f),
        );
        c.restore();
      }

    case FxKind.star:
      final pop = sin(pi * (v * 1.6).clamp(0.0, 1.0));
      _sparkle(c, up - Offset(0, px * 0.3 * e), px * 0.9 * pop, const Color(0xFFFFE27A), pop, rot: v * 1.5);
      for (var i = 0; i < 7; i++) {
        final a = -pi / 2 + (i - 3) * 0.5 + (rr() - 0.5) * 0.2;
        final sp = px * (1.2 + rr() * 1.1);
        final o = up + Offset(cos(a) * sp * e, sin(a) * sp * e + px * 1.2 * v * v);
        _sparkle(c, o, px * (0.12 + 0.08 * rr()) * (1 - v * 0.5), const Color(0xFFFFE27A), f, rot: v * 4 + i);
      }

    case FxKind.frost:
      final hex = Path();
      final hr = px * (0.35 + 1.0 * e);
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3 + pi / 6;
        final q = center + Offset(cos(a) * hr, sin(a) * hr * 0.45);
        i == 0 ? hex.moveTo(q.dx, q.dy) : hex.lineTo(q.dx, q.dy);
      }
      hex.close();
      c.drawPath(hex, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round..color = const Color(0xFFDFF6FF).withValues(alpha: 0.85 * f));
      c.drawPath(hex, Paint()..color = const Color(0xFFBFE9FF).withValues(alpha: 0.18 * f));
      for (var i = 0; i < 8; i++) {
        final o = up + Offset((rr() - 0.5) * px * 1.6, -px * 0.4 + px * 1.1 * v * (0.6 + rr() * 0.6) - px * 0.8 * (1 - v));
        drawParticle(c, FxKind.frost, o, px * 0.1, f, color, v * 3 + i);
      }

    case FxKind.puff:
      for (var i = 0; i < 5; i++) {
        final a = pi + i / 4 * pi + (rr() - 0.5) * 0.3;
        final d = px * (0.25 + 0.8 * e);
        for (var j = 0; j < 3; j++) {
          final o = center + Offset(cos(a) * d * (1 + j * 0.15), -px * (0.1 + 0.5 * e) * (0.4 + j * 0.3) + sin(a) * d * 0.2);
          _glow(c, o, px * (0.2 + 0.2 * e + j * 0.05), Color.lerp(color, Colors.white, 0.35)!, 0.5 * f);
        }
      }

    case FxKind.confetti:
      for (var i = 0; i < 18; i++) {
        final ang = -pi / 2 + (rr() - 0.5) * 2.2;
        final sp = px * (1.4 + rr() * 1.8);
        final o = up + Offset(cos(ang) * sp * v, sin(ang) * sp * v + px * 2.6 * v * v);
        drawParticle(c, FxKind.confetti, o, px * (0.12 + rr() * 0.06), f * 1.3, color, v * 9 + i * 1.7);
      }

    case FxKind.pixel:
      for (var i = 0; i < 5; i++) {
        final a = -pi / 2 + (i - 2) * 0.45;
        final sp = px * (1.5 + rr() * 0.7);
        final o = up + Offset(cos(a) * sp * v, sin(a) * sp * v + px * 2.4 * v * v);
        final wid = px * 0.17 * (0.25 + 0.75 * cos(v * 14 + i).abs());
        c.drawOval(Rect.fromCenter(center: o, width: wid * 2, height: px * 0.34), Paint()..color = const Color(0xFFFFC21A).withValues(alpha: f));
        c.drawOval(Rect.fromCenter(center: o, width: wid * 1.2, height: px * 0.22), Paint()..color = const Color(0xFFFFE680).withValues(alpha: f));
      }
      _sparkle(c, up, px * 0.7 * sin(pi * (v * 1.8).clamp(0.0, 1.0)), const Color(0xFFFFD23A), 1);

    case FxKind.note:
      for (var i = 0; i < 6; i++) {
        final delay = i * 0.07;
        final t = ((v - delay) / (1 - delay)).clamp(0.0, 1.0);
        final o = up + Offset(sin(t * 5 + i * 1.3) * px * 0.4 + (i - 2.5) * px * 0.22, -px * 1.7 * _eo(t));
        drawParticle(c, FxKind.note, o, px * 0.11 * sin(pi * min(t * 1.2, 1.0)).clamp(0.1, 1.0), (1 - t) * 1.2, color, 0);
      }

    case FxKind.sprinkles:
      for (var i = 0; i < 20; i++) {
        final ang = -pi / 2 + (rr() - 0.5) * 2.4;
        final sp = px * (1.3 + rr() * 1.5);
        final o = up + Offset(cos(ang) * sp * v, sin(ang) * sp * v + px * 2.6 * v * v);
        final vel = Offset(cos(ang) * sp, sin(ang) * sp + px * 5.2 * v);
        final dir = vel / vel.distance;
        c.drawLine(o - dir * px * 0.1, o + dir * px * 0.1, Paint()..color = HSVColor.fromAHSV(f.clamp(0.0, 1.0), (i * 47.0) % 360, 0.65, 1).toColor()..strokeWidth = px * 0.07..strokeCap = StrokeCap.round);
      }

    case FxKind.crumbs:
      for (var i = 0; i < 9; i++) {
        final ang = -pi / 2 + (rr() - 0.5) * 2.0;
        final sp = px * (1.0 + rr() * 1.2);
        var y = sin(ang) * sp * v + px * 2.8 * v * v;
        final gnd = px * 0.32;
        if (y > gnd) y = gnd - (y - gnd) * 0.35; // lands and hops once
        final o = up + Offset(cos(ang) * sp * v, y);
        final r = px * (0.06 + rr() * 0.05);
        c.drawCircle(o, r, Paint()..color = (i.isEven ? const Color(0xFF8A5A2B) : const Color(0xFF4E2F12)).withValues(alpha: f.clamp(0.0, 1.0)));
        c.drawCircle(o - Offset(r * 0.25, r * 0.25), r * 0.45, Paint()..color = const Color(0xFFD9A066).withValues(alpha: f * 0.7));
      }

    case FxKind.heart:
      for (var i = 0; i < 6; i++) {
        final delay = i * 0.08;
        final t = ((v - delay) / (1 - delay)).clamp(0.0, 1.0);
        final o = up + Offset(sin(t * 4 + i * 2) * px * 0.35 + (i - 2.5) * px * 0.17, -px * 1.8 * _eo(t));
        drawParticle(c, FxKind.heart, o, px * 0.12 * sin(pi * min(t * 1.1, 1.0)), (1 - t) * 1.3, color, 0);
      }

    case FxKind.spore:
      _glow(c, center, px * (0.4 + 0.9 * e), color, 0.25 * f);
      for (var i = 0; i < 14; i++) {
        final a = rr() * 2 * pi;
        final d = px * (0.2 + 0.8 * rr()) * (0.4 + 0.6 * e);
        final o = up + Offset(cos(a) * d, sin(a) * d * 0.5 - px * (0.2 + 1.0 * v) * (0.5 + rr() * 0.7));
        _orb(c, o, px * (0.03 + 0.03 * rr()), color, f * (0.6 + 0.4 * sin(v * 12 + i)), core: const Color(0xFFFFF4C8));
      }

    case FxKind.splash:
      _groundRing(c, center, px * (0.3 + 1.0 * e), Colors.white, 0.7 * f, width: 2);
      _groundRing(c, center, px * (0.2 + 0.7 * _eo(v * 1.2)), color, 0.6 * f, width: 1.6);
      final col = Color.lerp(color, const Color(0xFF7ADCFF), 0.4)!;
      c.drawPath(_teardrop(up - Offset(0, px * 0.5 * e), px * 0.1 * (1 - v), px * 0.5 * sin(pi * min(v * 1.6, 1.0))), Paint()..color = col.withValues(alpha: 0.5 * f));
      for (var i = 0; i < 10; i++) {
        final a = -pi / 2 + (i - 4.5) * 0.3 + (rr() - 0.5) * 0.15;
        final sp = px * (1.2 + rr() * 0.9);
        final o = up + Offset(cos(a) * sp * v, sin(a) * sp * v + px * 2.6 * v * v);
        final r = px * (0.04 + 0.04 * rr());
        c.drawCircle(o, r, Paint()..color = col.withValues(alpha: f));
        c.drawCircle(o - Offset(r * 0.3, r * 0.3), r * 0.35, Paint()..color = Colors.white.withValues(alpha: f * 0.9));
      }

    case FxKind.shock:
      final flick = (v * 14).floor();
      final r2 = Random(flick * 17 + 3);
      _glow(c, up, px * (0.6 + 0.8 * e), color, 0.45 * f);
      for (var i = 0; i < 5; i++) {
        final a = i / 5 * 2 * pi + r2.nextDouble() * 0.6;
        final len = px * (0.8 + r2.nextDouble() * 0.9) * (0.4 + 0.6 * _eo(v * 2.5));
        final bolt = Path()..moveTo(up.dx, up.dy);
        var cur = up;
        for (var s = 1; s <= 5; s++) {
          final t = s / 5;
          final base = up + Offset(cos(a), sin(a) * 0.75) * len * t;
          cur = base + Offset((r2.nextDouble() - 0.5) * px * 0.25, (r2.nextDouble() - 0.5) * px * 0.25) * (s == 5 ? 0 : 1);
          bolt.lineTo(cur.dx, cur.dy);
        }
        c.drawPath(bolt, Paint()..style = PaintingStyle.stroke..strokeWidth = px * 0.1..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round..color = color.withValues(alpha: 0.5 * f));
        c.drawPath(bolt, Paint()..style = PaintingStyle.stroke..strokeWidth = px * 0.03..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: f));
      }

    case FxKind.gear:
      _groundRing(c, center, px * (0.3 + 1.1 * e), color, 0.5 * f, width: 2);
      for (var i = 0; i < 4; i++) {
        final a = -pi / 2 + (i - 1.5) * 0.7;
        final sp = px * (1.1 + rr() * 0.6);
        final o = up + Offset(cos(a) * sp * e, sin(a) * sp * e + px * 1.6 * v * v);
        final r = px * (0.13 + 0.07 * rr()) * (1 - v * 0.4);
        final g = _gear(o, r, 7, v * (i.isEven ? 7 : -7));
        c.drawPath(g, Paint()..color = Color.lerp(color, const Color(0xFFFFE7B0), 0.3)!.withValues(alpha: f));
        c.drawCircle(o, r * 0.35, Paint()..color = const Color(0xFF2A2018).withValues(alpha: f));
      }

    case FxKind.sweep:
      for (var i = 0; i < 3; i++) {
        final t = (v * 1.2 - i * 0.18).clamp(0.0, 1.0);
        _groundRing(c, center, px * (0.2 + 1.5 * _eo(t)), color, (1 - t) * 0.8, width: 2);
      }
      final ang = v * 2 * pi * 1.2;
      final rad = px * 1.1;
      final wedge = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCenter(center: center, width: rad * 2, height: rad * 2 * 0.45), ang - 0.7, 0.7, false)
        ..close();
      c.drawPath(wedge, Paint()..color = color.withValues(alpha: 0.35 * f));
      for (var i = 0; i < 3; i++) {
        final a = rr() * 2 * pi;
        _orb(c, center + Offset(cos(a) * rad * 0.7, sin(a) * rad * 0.7 * 0.45), px * 0.05, color, f * (0.5 + 0.5 * sin(v * 10 + i)));
      }

    case FxKind.glint:
      _glow(c, up, px * (0.5 + 0.8 * e), color, 0.3 * f);
      for (var i = 0; i < 6; i++) {
        final a = rr() * 2 * pi;
        final d = px * (0.35 + 0.7 * rr());
        final o = up + Offset(cos(a) * d, sin(a) * d * 0.7 - px * 0.2);
        final t = ((v * 1.4 - i * 0.09)).clamp(0.0, 1.0);
        final s = sin(pi * t);
        _sparkle(c, o, px * (0.16 + 0.14 * rr()) * s, color, s, rot: t * 1.2);
      }

    case FxKind.flame:
      _glow(c, center, px * (0.5 + 0.8 * e), const Color(0xFFFF7A1A), 0.35 * f);
      for (var i = 0; i < 5; i++) {
        final x = (i - 2) * px * 0.2;
        final life = ((v * 1.3 - i * 0.05)).clamp(0.0, 1.0);
        final h = px * (0.5 + 0.5 * (1 - (i - 2).abs() / 3)) * sin(pi * life);
        final w = px * 0.17 * (1 - life * 0.4);
        final o = up + Offset(x + sin(v * 14 + i * 2) * px * 0.04, -h * 0.5);
        c.drawPath(_teardrop(o, w, h * 0.9), Paint()..color = const Color(0xFFFF5A12).withValues(alpha: 0.85 * f.clamp(0.0, 1.0)));
        c.drawPath(_teardrop(o + Offset(0, h * 0.12), w * 0.55, h * 0.55), Paint()..color = const Color(0xFFFFD36A).withValues(alpha: f));
      }

    case FxKind.disco:
      final rot = v * 3.0;
      for (var i = 0; i < 10; i++) {
        final a = rot + i / 10 * 2 * pi;
        final len = px * (0.7 + 1.2 * e);
        final hue = (i * 36.0 + v * 200) % 360;
        final col = HSVColor.fromAHSV(1, hue, 0.55, 1).toColor();
        final p = Path()
          ..moveTo(up.dx, up.dy)
          ..lineTo(up.dx + cos(a - 0.07) * len, up.dy + sin(a - 0.07) * len * 0.8)
          ..lineTo(up.dx + cos(a + 0.07) * len, up.dy + sin(a + 0.07) * len * 0.8)
          ..close();
        c.drawPath(p, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.7 * f), col.withValues(alpha: 0)], radius: 1.0).createShader(Rect.fromCircle(center: up, radius: len)));
      }
      for (var i = 0; i < 6; i++) {
        final a = rr() * 2 * pi;
        final d = px * (0.4 + 0.7 * rr()) * e;
        _sparkle(c, up + Offset(cos(a) * d, sin(a) * d * 0.7), px * 0.13, HSVColor.fromAHSV(1, (i * 60.0 + v * 300) % 360, 0.4, 1).toColor(), f * (0.5 + 0.5 * sin(v * 20 + i)), rot: v * 3);

      }

    case FxKind.orbit:
      for (var i = 0; i < 2; i++) {
        final t = (v * 1.15 - i * 0.14).clamp(0.0, 1.0);
        final rx = px * (0.4 + 1.2 * _eo(t));
        c.save();
        c.translate(up.dx, up.dy);
        c.rotate(-0.35 + i * 0.5);
        final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: rx * 0.8);
        c.drawOval(rect, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = color.withValues(alpha: 0.7 * (1 - t)));
        final a = v * 2 * pi * (2 + i) + i;
        final dot = Offset(cos(a) * rx, sin(a) * rx * 0.4);
        _orb(c, dot, px * 0.06, color, 1 - t);
        c.restore();
      }

    case FxKind.swirl:
      for (var i = 0; i < 18; i++) {
        final arm = i % 3;
        final t = (i ~/ 3) / 6;
        final a = arm * 2 * pi / 3 + t * 3.2 + v * 4;
        final d = px * (0.15 + 1.1 * t) * (0.3 + 0.7 * e);
        final o = up + Offset(cos(a) * d, sin(a) * d * 0.55 - px * 0.5 * e * t);
        _orb(c, o, px * 0.045 * (1 - t * 0.4), arm == 0 ? color : (arm == 1 ? Colors.white : Color.lerp(color, Colors.white, 0.5)!), f * (1 - t * 0.3));
      }
      _glow(c, up, px * (0.4 + 0.5 * e), color, 0.3 * f);

    case FxKind.bounce:
      _groundRing(c, center, px * (0.35 + 1.0 * e), color, 0.75 * f, width: 3 * f + 0.6);
      for (var i = 0; i < 8; i++) {
        final a = pi + i / 7 * pi;
        final r0 = px * (0.45 + 0.5 * e), r1 = px * (0.62 + 0.8 * e);
        c.drawLine(center + Offset(cos(a) * r0, sin(a) * r0 * 0.9 - px * 0.1), center + Offset(cos(a) * r1, sin(a) * r1 * 0.9 - px * 0.1),
            Paint()..color = Colors.white.withValues(alpha: 0.85 * f)..strokeWidth = px * 0.05..strokeCap = StrokeCap.round);
      }

    case FxKind.leaf:
      for (var i = 0; i < 7; i++) {
        final delay = i * 0.04;
        final t = ((v - delay) / (1 - delay)).clamp(0.0, 1.0);
        final start = (i - 3) * px * 0.18;
        final o = up + Offset(start + sin(t * 6 + i) * px * 0.35 + (i - 3) * px * 0.15 * t, -px * 0.7 * sin(pi * min(t * 1.2, 1.0)) + px * 0.9 * t * t);
        final col = Color.lerp(color, const Color(0xFFB6E07A), (i % 3) / 3)!;
        c.drawPath(_leaf(o, px * 0.12, px * 0.055, t * 7 + i), Paint()..color = col.withValues(alpha: (1 - t * t)));
      }

    case FxKind.chalk:
      for (var i = 0; i < 3; i++) {
        final t = (v * 1.3 - i * 0.1).clamp(0.0, 1.0);
        _groundRing(c, center, px * (0.3 + 1.3 * _eo(t)), Colors.white, 0.6 * (1 - t), width: 1.6);
      }
      for (var i = 0; i < 6; i++) {
        final a = pi + i / 5 * pi;
        final d = px * (0.3 + 0.7 * e);
        _glow(c, center + Offset(cos(a) * d, sin(a) * d * 0.4 - px * (0.1 + 0.4 * e)), px * (0.2 + 0.2 * e), color, 0.5 * f);
      }

    case FxKind.curtain:
      for (var i = 0; i < 7; i++) {
        final x = (i - 3) * px * 0.2 + sin(v * 5 + i) * px * 0.06;
        final h = px * (0.8 + 0.7 * rr()) * _eo(v * 1.6) * (1 - v * 0.2);
        final col = Color.lerp(color, i.isEven ? const Color(0xFF8AFFC8) : const Color(0xFFB08AFF), 0.55)!;
        final rect = Rect.fromLTWH(up.dx + x - px * 0.06, up.dy - h, px * 0.12, h + px * 0.2);
        c.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(px * 0.06)),
          Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [col.withValues(alpha: 0.8 * f), col.withValues(alpha: 0)]).createShader(rect),
        );
      }
      _glow(c, center, px * (0.5 + 0.7 * e), color, 0.3 * f);

    case FxKind.tendril:
      _glow(c, up, px * (0.5 + 0.6 * e), color, 0.4 * f);
      final r2 = Random((v * 10).floor() * 13 + 1);
      for (var i = 0; i < 6; i++) {
        final a = i / 6 * 2 * pi + r2.nextDouble() * 0.4;
        final len = px * (0.7 + r2.nextDouble() * 0.6) * (0.3 + 0.7 * _eo(v * 2));
        final end = up + Offset(cos(a), sin(a) * 0.75) * len;
        final ctrl = up + Offset(cos(a + 0.8), sin(a + 0.8) * 0.75) * len * 0.6;
        final p = Path()..moveTo(up.dx, up.dy)..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
        c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = px * 0.09..strokeCap = StrokeCap.round..color = color.withValues(alpha: 0.4 * f));
        c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = px * 0.03..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: 0.9 * f));
      }

    case FxKind.ripple:
      for (var i = 0; i < 3; i++) {
        final t = (v * 1.25 - i * 0.16).clamp(0.0, 1.0);
        _groundRing(c, center, px * (0.25 + 1.3 * _eo(t)), color, 0.8 * (1 - t), width: 2.2 * (1 - t) + 0.6);
      }
      for (var i = 0; i < 3; i++) {
        final a = i * 2.1 + 0.5;
        final d = px * (0.4 + 0.5 * e);
        final o = center + Offset(cos(a + v * 1.5) * d, sin(a + v * 1.5) * d * 0.42 - px * 0.05);
        c.drawPath(_leaf(o, px * 0.1, px * 0.05, a + v * 3), Paint()..color = (i == 1 ? const Color(0xFFFF9A4A) : const Color(0xFFFFF4E8)).withValues(alpha: f));
      }

    case FxKind.lantern:
      for (var i = 0; i < 3; i++) {
        final delay = i * 0.1;
        final t = ((v - delay) / (1 - delay)).clamp(0.0, 1.0);
        final o = up + Offset((i - 1) * px * 0.35 + sin(t * 4 + i * 2) * px * 0.1, -px * (0.2 + 1.6 * _eo(t)));
        final a = sin(pi * min(t * 1.3, 1.0)) * (1 - t * 0.3);
        _glow(c, o, px * 0.38, const Color(0xFFFF9A3A), a * 0.5);
        final body = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: px * 0.16, height: px * 0.21), Radius.circular(px * 0.06));
        c.drawRRect(body, Paint()..color = const Color(0xFFFFC46A).withValues(alpha: a.clamp(0.0, 1.0)));
        c.drawRRect(body.deflate(px * 0.025), Paint()..color = const Color(0xFFFFF0C0).withValues(alpha: a.clamp(0.0, 1.0)));
      }
  }
}
