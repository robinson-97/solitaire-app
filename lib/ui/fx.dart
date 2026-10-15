import 'dart:math';
import 'package:flutter/material.dart';

/// Each peg theme has its own hop trail and landing burst.
enum FxKind { none, dust, firefly, moon, ember, crystal, star, frost, puff, confetti, pixel, note, sprinkles, crumbs, heart }

Path _poly(Offset c, double r, int points, double inner, double rot) {
  final p = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = rot + i * pi / points - pi / 2;
    final rad = i.isEven ? r : r * inner;
    final o = c + Offset(cos(a), sin(a)) * rad;
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

/// One particle of the theme's kind. [r] is its radius, [alpha] 0..1.
void drawParticle(Canvas c, FxKind k, Offset o, double r, double alpha, Color color, double rot) {
  if (alpha <= 0 || r <= 0) return;
  final a = alpha.clamp(0.0, 1.0);
  switch (k) {
    case FxKind.none:
      return;
    case FxKind.dust:
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(rot);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 1.9, height: r * 1.0), Radius.circular(r * 0.4)),
        Paint()..color = const Color(0xFFB07A44).withValues(alpha: a),
      );
      c.restore();
    case FxKind.firefly:
      c.drawCircle(o, r * 2.6, Paint()..color = color.withValues(alpha: a * 0.35)..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
      c.drawCircle(o, r * 0.7, Paint()..color = const Color(0xFFF6FFC0).withValues(alpha: a));
    case FxKind.moon:
      c.drawPath(_poly(o, r * 1.5, 4, 0.22, rot * 0.3), Paint()..color = Colors.white.withValues(alpha: a));
      c.drawCircle(o, r * 1.8, Paint()..color = color.withValues(alpha: a * 0.25)..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
    case FxKind.ember:
      c.drawCircle(o, r * 2.2, Paint()..color = color.withValues(alpha: a * 0.4)..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
      c.drawCircle(o, r * 0.8, Paint()..color = const Color(0xFFFFD27A).withValues(alpha: a));
    case FxKind.crystal:
      c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - r * 1.5)
          ..lineTo(o.dx + r, o.dy)
          ..lineTo(o.dx, o.dy + r * 1.5)
          ..lineTo(o.dx - r, o.dy)
          ..close(),
        Paint()..color = Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: a),
      );
    case FxKind.star:
      c.drawCircle(o, r * 2.2, Paint()..color = color.withValues(alpha: a * 0.3)..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
      c.drawPath(_poly(o, r * 1.6, 5, 0.45, rot), Paint()..color = const Color(0xFFFFE27A).withValues(alpha: a));
    case FxKind.frost:
      final p = Paint()..color = const Color(0xFFDFF6FF).withValues(alpha: a)..strokeWidth = max(1.0, r * 0.28)..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final ang = rot + i * pi / 3;
        final d = Offset(cos(ang), sin(ang)) * r * 1.3;
        c.drawLine(o - d, o + d, p);
      }
    case FxKind.puff:
      c.drawCircle(o, r * 1.7, Paint()..color = color.withValues(alpha: a * 0.55)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8));
    case FxKind.confetti:
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(rot * 1.7);
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 0.9),
          Paint()..color = HSVColor.fromAHSV(a, (rot * 57) % 360, 0.65, 1).toColor());
      c.restore();
    case FxKind.pixel:
      const cols = [Color(0xFFFFD23A), Color(0xFFFF4F6D), Color(0xFF35F0FF)];
      final side = r * 1.5;
      c.drawRect(Rect.fromCenter(center: o, width: side, height: side), Paint()..color = cols[rot.floor().abs() % 3].withValues(alpha: a));
    case FxKind.note:
      final p = Paint()..color = color.withValues(alpha: a);
      c.drawOval(Rect.fromCenter(center: o, width: r * 1.5, height: r * 1.1), p);
      c.drawLine(o + Offset(r * 0.7, 0), o + Offset(r * 0.7, -r * 2.2), p..strokeWidth = max(1.0, r * 0.3));
      c.drawPath(Path()..moveTo(o.dx + r * 0.7, o.dy - r * 2.2)..quadraticBezierTo(o.dx + r * 1.9, o.dy - r * 1.6, o.dx + r * 1.2, o.dy - r * 0.9), p..style = PaintingStyle.stroke);
    case FxKind.sprinkles:
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(rot * 2.3);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 2.0, height: r * 0.55), Radius.circular(r * 0.3)),
        Paint()..color = HSVColor.fromAHSV(a, (rot * 83) % 360, 0.7, 1).toColor(),
      );
      c.restore();
    case FxKind.crumbs:
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(rot);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * 1.1), Radius.circular(r * 0.35)),
          Paint()..color = (rot.floor().isEven ? color : const Color(0xFF5E3A14)).withValues(alpha: a));
      c.restore();
    case FxKind.heart:
      final h = Path()
        ..moveTo(o.dx, o.dy + r * 1.1)
        ..cubicTo(o.dx - r * 2.0, o.dy - r * 0.2, o.dx - r * 0.9, o.dy - r * 1.5, o.dx, o.dy - r * 0.4)
        ..cubicTo(o.dx + r * 0.9, o.dy - r * 1.5, o.dx + r * 2.0, o.dy - r * 0.2, o.dx, o.dy + r * 1.1);
      c.drawPath(h, Paint()..color = const Color(0xFFFF5C8A).withValues(alpha: a));
  }
}

/// Burst + ripple at the landing spot. [v] runs 0..1; [px] is a peg diameter.
void paintLanding(Canvas c, FxKind k, Offset center, double px, double v, Color color, {required bool ripple}) {
  if (v <= 0 || v >= 1) return;
  if (ripple) {
    paintRipple(c, center, px, v, color);
  } else {
    _paintBurst(c, k, center, px, v, color);
  }
}

void paintRipple(Canvas c, Offset center, double px, double v, Color color) {
  for (var i = 0; i < 2; i++) {
    final t = (v - i * 0.15).clamp(0.0, 1.0);
    if (t <= 0) continue;
    final w = px * (0.8 + 1.6 * t);
    c.drawOval(
      Rect.fromCenter(center: center, width: w, height: w * 0.45),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4 * (1 - t) + 0.5..color = color.withValues(alpha: (1 - t) * 0.65),
    );
  }
}

void _paintBurst(Canvas c, FxKind k, Offset center, double px, double v, Color color) {
  if (k == FxKind.none) return;
  final rnd = Random(k.index * 31 + 5);
  final count = switch (k) { FxKind.star => 14, FxKind.ember => 14, FxKind.confetti => 18, FxKind.sprinkles => 16, FxKind.frost => 12, FxKind.note => 7, FxKind.heart => 8, _ => 11 };
  final up = center - Offset(0, px * 0.3);
  for (var i = 0; i < count; i++) {
    final ang = (i / count) * 2 * pi + rnd.nextDouble() * 0.6;
    final speed = px * (2.0 + rnd.nextDouble() * 1.6);
    final vy = px * (2.0 + rnd.nextDouble() * 1.8);
    var pos = Offset(cos(ang) * speed * v, -vy * v * (k == FxKind.puff ? 0.5 : 1) + px * 2.3 * v * v * (k == FxKind.firefly || k == FxKind.puff ? 0.1 : 1));
    if (k == FxKind.firefly) pos += Offset(sin(v * 9 + i) * px * 0.2, 0); // wandering
    final fade = (1 - v * v) * 1.3;
    drawParticle(c, k, up + pos, px * (0.13 + rnd.nextDouble() * 0.08) * (k == FxKind.puff ? 1.6 : 1), fade, color, v * 6 + i);
  }
  // ember: a little smoke rising afterwards; moon: a soft flash
  if (k == FxKind.ember && v > 0.25) {
    for (var i = 0; i < 3; i++) {
      final t = (v - 0.25 + i * 0.05) / 0.75;
      c.drawCircle(up + Offset((i - 1) * px * 0.18, -px * 1.4 * t), px * (0.18 + 0.2 * t),
          Paint()..color = const Color(0xFF8A8A92).withValues(alpha: 0.25 * (1 - t).clamp(0.0, 1.0))..maskFilter = MaskFilter.blur(BlurStyle.normal, px * 0.12));
    }
  }
  if (k == FxKind.moon || k == FxKind.crystal) {
    c.drawCircle(up, px * (0.5 + 0.9 * v), Paint()..color = color.withValues(alpha: 0.35 * (1 - v))..maskFilter = MaskFilter.blur(BlurStyle.normal, px * 0.3));
  }
}
