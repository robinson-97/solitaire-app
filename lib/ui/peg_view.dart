import 'dart:math';
import 'package:flutter/material.dart';
import 'shaders.dart';
import 'styles.dart';

/// A peg drawn as a lit sphere, with per-theme character.
/// [glow] runs 0..1 in a loop and drives pulsing / shimmer.
class PegView extends StatelessWidget {
  const PegView({super.key, required this.theme, required this.glow, this.selected = false});
  final PegTheme theme;
  final double glow;
  final bool selected;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _PegPainter(theme, glow, selected),
        child: const SizedBox.expand(),
      );
}

Path _polygon(Offset c, double r, int n, double rot) {
  final p = Path();
  for (var i = 0; i < n; i++) {
    final a = rot + i * 2 * pi / n - pi / 2;
    final o = c + Offset(cos(a), sin(a)) * r;
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

void _text(Canvas canvas, String t, Offset center, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: size, color: color, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

class _PegPainter extends CustomPainter {
  _PegPainter(this.theme, this.glow, this.selected);
  final PegTheme theme;
  final double glow;
  final bool selected;

  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width / 2;
    final c = Offset(r, r);
    final pulse = 0.5 + 0.5 * sin(glow * 2 * pi);
    final cols = theme.colors;

    // ambient glow (theme) and selection lantern light
    final ga = theme.glowAlpha * (0.55 + 0.45 * pulse);
    if (ga > 0) {
      canvas.drawCircle(c, r * 1.45,
          Paint()..color = theme.glow.withValues(alpha: ga * 0.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7));
    }
    if (selected) {
      canvas.drawCircle(c, r * 1.5,
          Paint()..color = const Color(0xFFFFB347).withValues(alpha: 0.85)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6));
    }

    final rect = Rect.fromCircle(center: c, radius: r);
    final glassy = theme.kind == PegKind.glass || theme.kind == PegKind.frost;
    final spec = theme.mat;
    if (spec != null && Gfx.material != null) {
      final sh = Gfx.material!.fragmentShader()
        ..setFloat(0, s.width)
        ..setFloat(1, s.height)
        ..setFloat(2, glow * 20)
        ..setFloat(3, spec.mode);
      var i = 4;
      for (final col in [spec.c1, spec.c2, spec.c3]) {
        sh
          ..setFloat(i++, col.r)
          ..setFloat(i++, col.g)
          ..setFloat(i++, col.b);
      }
      canvas.drawRect(Offset.zero & s, Paint()..shader = sh);
    } else {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.45),
            radius: 1.0,
            colors: glassy ? [for (final k in cols) k.withValues(alpha: 0.92)] : cols,
            stops: const [0.0, 0.3, 0.75, 1.0],
          ).createShader(rect),
      );
    }

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    switch (theme.kind) {
      case PegKind.wood:
        // acorn cap with hatching
        final cap = Rect.fromLTWH(0, 0, s.width, r * 0.62);
        canvas.drawRect(cap, Paint()..color = const Color(0xFF5A3512).withValues(alpha: 0.9));
        final hatch = Paint()..color = const Color(0xFF2E1706)..strokeWidth = 1;
        for (var i = -2; i < 6; i++) {
          canvas.drawLine(Offset(i * r * 0.4, 0), Offset(i * r * 0.4 + r * 0.5, r * 0.62), hatch);
        }
        canvas.drawLine(Offset(0, r * 0.62), Offset(s.width, r * 0.62),
            Paint()..color = const Color(0xFF2E1706)..strokeWidth = 1.6);
      case PegKind.glass:
        // a tiny firefly glowing inside
        canvas.drawCircle(c + Offset(0, r * 0.1), r * (0.3 + 0.12 * pulse),
            Paint()..color = const Color(0xFFF6FFB0).withValues(alpha: 0.5 + 0.4 * pulse)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.25));
        canvas.drawCircle(c + Offset(0, r * 0.1), r * 0.1, Paint()..color = Colors.white);
      case PegKind.moon:
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = SweepGradient(
              transform: GradientRotation(glow * 2 * pi),
              colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.0)],
              stops: const [0.0, 0.18, 0.4],
            ).createShader(rect),
        );
      case PegKind.crystal:
        final facet = Paint()..color = Colors.white.withValues(alpha: 0.28)..strokeWidth = 1.1..style = PaintingStyle.stroke;
        final hex = Path();
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3 - pi / 2;
          final pt = c + Offset(cos(a), sin(a)) * r * 0.62;
          i == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
          canvas.drawLine(c, c + Offset(cos(a), sin(a)) * r, facet);
        }
        hex.close();
        canvas.drawPath(hex, facet);
        canvas.drawCircle(c, r * 0.3, Paint()..color = const Color(0xFFD9CCFF).withValues(alpha: 0.25 + 0.35 * pulse)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.2));
      case PegKind.star:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = i * pi / 5 - pi / 2;
          final rad = i.isEven ? r * 0.55 : r * 0.24;
          final pt = c + Offset(cos(a), sin(a)) * rad;
          i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
        }
        star.close();
        canvas.drawPath(star, Paint()..color = const Color(0xFF7A4A08).withValues(alpha: 0.35));
        canvas.drawPath(star, Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.55 + 0.4 * pulse)..style = PaintingStyle.stroke..strokeWidth = 1.4);
      case PegKind.frost:
        final fl = Paint()..color = Colors.white.withValues(alpha: 0.65)..strokeWidth = 1.3..strokeCap = StrokeCap.round;
        for (var i = 0; i < 3; i++) {
          final a = i * pi / 3;
          final d = Offset(cos(a), sin(a)) * r * 0.6;
          canvas.drawLine(c - d, c + d, fl);
          final tip = Offset(cos(a), sin(a));
          for (final sgn in [-1, 1]) {
            final base = c + tip * sgn.toDouble() * r * 0.36;
            final side = Offset(-tip.dy, tip.dx) * r * 0.13;
            canvas.drawLine(base, base + tip * sgn.toDouble() * r * 0.14 + side, fl);
            canvas.drawLine(base, base + tip * sgn.toDouble() * r * 0.14 - side, fl);
          }
        }
        canvas.drawCircle(c, r * 0.12, Paint()..color = Colors.white.withValues(alpha: 0.6 + 0.3 * pulse));
      case PegKind.mushroom:
        final cap = Path()..moveTo(0, 0)..lineTo(s.width, 0)..lineTo(s.width, r * 0.9);
        for (var i = 4; i >= 0; i--) {
          final x = s.width * i / 4;
          cap.quadraticBezierTo(x + s.width * 0.125, r * 1.15, x, r * 0.9);
        }
        cap.close();
        canvas.drawPath(cap, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEE5A4A), Color(0xFFA81F1F)]).createShader(Rect.fromLTWH(0, 0, s.width, r * 1.2)));
        final dot = Paint()..color = const Color(0xFFFFF3E0).withValues(alpha: 0.95);
        canvas.drawCircle(Offset(r * 0.55, r * 0.35), r * 0.17, dot);
        canvas.drawCircle(Offset(r * 1.1, r * 0.22), r * 0.14, dot);
        canvas.drawCircle(Offset(r * 1.5, r * 0.58), r * 0.15, dot);
        canvas.drawCircle(Offset(r * 0.95, r * 0.65), r * 0.1, dot);
      case PegKind.soccer:
        final dark = Paint()..color = const Color(0xFF1B1B1F);
        canvas.drawPath(_polygon(c, r * 0.36, 5, 0), dark);
        final seam = Paint()..color = const Color(0xFF55555C)..strokeWidth = 1.2..style = PaintingStyle.stroke;
        for (var i = 0; i < 5; i++) {
          final a = i * 2 * pi / 5 - pi / 2;
          final inner = c + Offset(cos(a), sin(a)) * r * 0.36;
          final outer = c + Offset(cos(a), sin(a)) * r * 0.74;
          canvas.drawLine(inner, outer, seam);
          canvas.drawPath(_polygon(c + Offset(cos(a), sin(a)) * r * 1.0, r * 0.3, 5, a + pi), dark);
        }
      case PegKind.basketball:
        final line = Paint()..color = const Color(0xFF3A1A08)..strokeWidth = 1.7..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, s.height), line);
        canvas.drawLine(Offset(0, c.dy), Offset(s.width, c.dy), line);
        canvas.drawCircle(c + Offset(-r * 1.35, 0), r * 0.98, line);
        canvas.drawCircle(c + Offset(r * 1.35, 0), r * 0.98, line);
      case PegKind.tennis:
        final seamT = Paint()..color = Colors.white.withValues(alpha: 0.92)..strokeWidth = 2.2..style = PaintingStyle.stroke;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-0.55);
        canvas.drawCircle(Offset(-r * 1.28, 0), r * 0.98, seamT);
        canvas.drawCircle(Offset(r * 1.28, 0), r * 0.98, seamT);
        canvas.restore();
      case PegKind.baseball:
        final red = Paint()..color = const Color(0xFFC0262B)..strokeWidth = 1.4..style = PaintingStyle.stroke;
        for (final sgn in [-1.0, 1.0]) {
          final cc = c + Offset(sgn * r * 1.5, 0);
          final rad = r * 1.12;
          canvas.drawCircle(cc, rad, red);
          for (var i = -5; i <= 5; i++) {
            final a = (sgn < 0 ? 0.0 : pi) + i * 0.13;
            final pt = cc + Offset(cos(a), sin(a)) * rad;
            final n = Offset(cos(a), sin(a)) * r * 0.09;
            canvas.drawLine(pt - n, pt + n + Offset(-sin(a), cos(a)) * r * 0.05, red);
          }
        }
      case PegKind.billiard:
        canvas.drawCircle(c + Offset(0, -r * 0.04), r * 0.5, Paint()..color = Colors.white.withValues(alpha: 0.95));
        _text(canvas, '8', c + Offset(0, -r * 0.03), r * 0.78, Colors.black);
      case PegKind.golf:
        final dim = Paint()..color = const Color(0xFF7A8794).withValues(alpha: 0.28);
        final lit = Paint()..color = Colors.white.withValues(alpha: 0.7);
        final step = r * 0.3;
        for (var row = -4; row <= 4; row++) {
          for (var col = -4; col <= 4; col++) {
            final o = c + Offset(col * step + (row.isOdd ? step / 2 : 0), row * step * 0.87);
            if ((o - c).distance > r * 0.95) continue;
            canvas.drawCircle(o + Offset(r * 0.02, r * 0.03), r * 0.09, dim);
            canvas.drawCircle(o - Offset(r * 0.03, r * 0.03), r * 0.05, lit);
          }
        }
      case PegKind.pixel:
        const art = ['..#..', '.###.', '#####', '.###.', '.#.#.'];
        final u = r * 0.26;
        final origin = c - Offset(u * 2.5, u * 2.5);
        for (var y = 0; y < art.length; y++) {
          for (var x = 0; x < art[y].length; x++) {
            if (art[y][x] != '#') continue;
            final rect = Rect.fromLTWH(origin.dx + x * u, origin.dy + y * u, u * 0.95, u * 0.95);
            canvas.drawRect(rect.shift(Offset(u * 0.12, u * 0.12)), Paint()..color = const Color(0xFF7A4D03).withValues(alpha: 0.55));
            canvas.drawRect(rect, Paint()..color = const Color(0xFFFFF6C8));
          }
        }
        canvas.drawCircle(c, r - 2, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFB07808).withValues(alpha: 0.7));
      case PegKind.disco:
        final n = 8;
        final t = r * 2 / n;
        for (var i = 0; i < n; i++) {
          for (var j = 0; j < n; j++) {
            final h = (i * 7 + j * 13) % 11;
            final tw = 0.5 + 0.5 * sin(glow * 2 * pi * 2 + h);
            final col = HSVColor.fromAHSV(1, (h * 33.0 + glow * 360) % 360, 0.5, 1).toColor();
            final rect = Rect.fromLTWH(i * t + 0.5, j * t + 0.5, t - 1, t - 1);
            canvas.drawRect(rect, Paint()..color = col.withValues(alpha: 0.12 + 0.4 * tw * tw));
          }
        }
        final gl = Paint()..color = Colors.black.withValues(alpha: 0.35)..strokeWidth = 0.8;
        for (var i = 1; i < n; i++) {
          canvas.drawLine(Offset(i * t, 0), Offset(i * t, s.height), gl);
          canvas.drawLine(Offset(0, i * t), Offset(s.width, i * t), gl);
        }
      case PegKind.vinyl:
        final groove = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = Colors.white.withValues(alpha: 0.13);
        for (var k = 0.42; k < 0.97; k += 0.09) {
          canvas.drawCircle(c, r * k, groove);
        }
        canvas.drawCircle(c, r * 0.32, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF8AD0), Color(0xFFD02A8A)]).createShader(rect));
        canvas.drawCircle(c, r * 0.06, Paint()..color = const Color(0xFF0A0A0C));
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = SweepGradient(
              transform: GradientRotation(glow * 2 * pi * 0.5),
              colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.0)],
              stops: const [0.0, 0.06, 0.13, 0.5, 0.56, 0.63],
            ).createShader(rect),
        );
      case PegKind.smiley:
        final ink = Paint()..color = const Color(0xFF3A2A06);
        canvas.drawOval(Rect.fromCenter(center: c + Offset(-r * 0.32, -r * 0.2), width: r * 0.2, height: r * 0.34), ink);
        canvas.drawOval(Rect.fromCenter(center: c + Offset(r * 0.32, -r * 0.2), width: r * 0.2, height: r * 0.34), ink);
        canvas.drawArc(Rect.fromCenter(center: c + Offset(0, r * 0.02), width: r * 1.1, height: r * 0.95), 0.25, pi - 0.5, false,
            Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.13..strokeCap = StrokeCap.round..color = const Color(0xFF3A2A06));
        canvas.drawCircle(c + Offset(-r * 0.55, r * 0.12), r * 0.12, Paint()..color = const Color(0xFFFF8A6A).withValues(alpha: 0.35));
        canvas.drawCircle(c + Offset(r * 0.55, r * 0.12), r * 0.12, Paint()..color = const Color(0xFFFF8A6A).withValues(alpha: 0.35));
      case PegKind.donut:
        canvas.drawCircle(c + Offset(0, -r * 0.05), r * 0.84,
            Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFC2DC), Color(0xFFFF7FB4), Color(0xFFD94A86)]).createShader(rect));
        final spr = Random(4);
        for (var i = 0; i < 12; i++) {
          final a = spr.nextDouble() * 2 * pi;
          final d = r * (0.42 + spr.nextDouble() * 0.36);
          canvas.save();
          canvas.translate(c.dx + cos(a) * d, c.dy + sin(a) * d - r * 0.05);
          canvas.rotate(spr.nextDouble() * pi);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 0.26, height: r * 0.08), Radius.circular(r * 0.04)),
              Paint()..color = HSVColor.fromAHSV(1, spr.nextDouble() * 360, 0.6, 1).toColor());
          canvas.restore();
        }
        canvas.drawCircle(c, r * 0.27, Paint()..shader = const RadialGradient(center: Alignment(0, 0.4), colors: [Color(0xFF3A2010), Color(0xFF140A04)]).createShader(Rect.fromCircle(center: c, radius: r * 0.27)));
        canvas.drawCircle(c, r * 0.27, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0xFFB02E6A));
      case PegKind.planet:
        final band = [const Color(0xFFD08A48), const Color(0xFFF6D6A0), const Color(0xFFB8682A)];
        for (var i = 0; i < 5; i++) {
          canvas.drawRect(Rect.fromLTWH(0, r * (0.2 + i * 0.38), s.width, r * 0.17),
              Paint()..color = band[i % 3].withValues(alpha: 0.38));
        }
      case PegKind.cookie:
        final chip = Paint()..color = const Color(0xFF3A200C);
        final rr = Random(9);
        for (var i = 0; i < 8; i++) {
          final a = rr.nextDouble() * 2 * pi;
          final d = r * (0.1 + rr.nextDouble() * 0.7);
          final o = c + Offset(cos(a) * d, sin(a) * d);
          canvas.drawOval(Rect.fromCenter(center: o, width: r * (0.2 + rr.nextDouble() * 0.12), height: r * 0.17), chip);
          canvas.drawCircle(o - Offset(r * 0.03, r * 0.03), r * 0.03, Paint()..color = Colors.white.withValues(alpha: 0.25));
        }
      case PegKind.aurora:
        const cols = [Color(0xFF6BFFB0), Color(0xFFFF7ADF), Color(0xFF6BD6FF)];
        for (var i = 0; i < 3; i++) {
          final pth = Path();
          for (var k = 0; k <= 12; k++) {
            final x = s.width * k / 12;
            final y = c.dy + (i - 1) * r * 0.45 + sin(k * 0.9 + glow * 2 * pi + i * 1.7) * r * 0.3;
            k == 0 ? pth.moveTo(x, y) : pth.lineTo(x, y);
          }
          canvas.drawPath(pth, Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.3..strokeCap = StrokeCap.round..color = cols[i].withValues(alpha: 0.55)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08));
        }
      case PegKind.galaxy:
        for (var arm = 0; arm < 2; arm++) {
          for (var j = 1; j < 26; j++) {
            final a = arm * pi + j * 0.27 + glow * 2 * pi;
            final d = r * (0.05 + j * 0.034);
            canvas.drawCircle(c + Offset(cos(a), sin(a)) * d, r * (0.045 + 0.02 * (j % 3)), Paint()..color = Color.lerp(const Color(0xFFFFF0C8), const Color(0xFFB59BFF), j / 26)!.withValues(alpha: 0.9));
          }
        }
        canvas.drawCircle(c, r * (0.2 + 0.04 * pulse), Paint()..color = const Color(0xFFFFF0C8).withValues(alpha: 0.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12));
      case PegKind.tide:
        for (var i = 0; i < 3; i++) {
          final pth = Path()..moveTo(0, s.height);
          for (var k = 0; k <= 16; k++) {
            final x = s.width * k / 16;
            pth.lineTo(x, c.dy + (i - 0.6) * r * 0.5 + sin(k * 0.8 + glow * 2 * pi * (i.isEven ? 1 : -1) + i) * r * 0.12);
          }
          pth..lineTo(s.width, s.height)..close();
          canvas.drawPath(pth, Paint()..color = Colors.white.withValues(alpha: 0.18));
        }
      case PegKind.clockwork:
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(glow * 2 * pi);
        final gear = Path();
        for (var i = 0; i < 20; i++) {
          final a = i * pi / 10;
          final rad = (i % 2 == 0) ? r * 0.72 : r * 0.56;
          final a2 = a + pi / 20;
          gear..lineTo(cos(a) * rad, sin(a) * rad)..lineTo(cos(a2) * rad, sin(a2) * rad);
        }
        gear.close();
        canvas.drawPath(gear, Paint()..color = const Color(0xFF5A3A12).withValues(alpha: 0.75));
        canvas.drawCircle(Offset.zero, r * 0.3, Paint()..color = const Color(0xFFE8B866));
        canvas.restore();
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-glow * 2 * pi * 3);
        canvas.drawLine(Offset.zero, Offset(0, -r * 0.5), Paint()..color = const Color(0xFF2A1604)..strokeWidth = 2..strokeCap = StrokeCap.round);
        canvas.restore();
        canvas.drawCircle(c, r * 0.07, Paint()..color = const Color(0xFF2A1604));
      case PegKind.storm:
        final cl = Paint()..color = const Color(0xFF2A2E44).withValues(alpha: 0.85);
        for (var i = 0; i < 3; i++) {
          final x = ((glow * 2 + i / 3) % 1.0) * s.width * 1.6 - s.width * 0.3;
          canvas.drawCircle(Offset(x, r * (0.5 + 0.5 * i * 0.6)), r * 0.45, cl);
          canvas.drawCircle(Offset(x + r * 0.35, r * (0.55 + 0.5 * i * 0.6)), r * 0.35, cl);
        }
        final fl = pow(max(0.0, sin(glow * 2 * pi * 3)), 14).toDouble();
        if (fl > 0.02) {
          canvas.drawPath(Path()..moveTo(c.dx + r * 0.1, c.dy - r * 0.7)..lineTo(c.dx - r * 0.2, c.dy - r * 0.05)..lineTo(c.dx + r * 0.1, c.dy - r * 0.05)..lineTo(c.dx - r * 0.15, c.dy + r * 0.7), Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round..color = const Color(0xFFFFF6B0).withValues(alpha: fl));
          canvas.drawCircle(c, r, Paint()..color = Colors.white.withValues(alpha: fl * 0.25));
        }
      case PegKind.plasma:
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3 + glow * 2 * pi * (i.isEven ? 1 : -1) * 0.5;
          final pth = Path()..moveTo(c.dx, c.dy);
          for (var k = 1; k <= 6; k++) {
            final d = r * k / 6;
            final w = sin(k * 2.1 + glow * 2 * pi * 4 + i) * 0.22;
            pth.lineTo(c.dx + cos(a + w) * d, c.dy + sin(a + w) * d);
          }
          canvas.drawPath(pth, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = (i.isEven ? const Color(0xFFFFB8FF) : const Color(0xFF9AF0FF)).withValues(alpha: 0.85));
        }
        canvas.drawCircle(c, r * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.55 + 0.3 * pulse)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1));
      case PegKind.koi:
        canvas.drawCircle(c, r * (0.45 + 0.35 * ((glow * 2) % 1.0)), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: 0.4 * (1 - (glow * 2) % 1.0)));
        for (var i = 0; i < 2; i++) {
          final a = glow * 2 * pi * (i == 0 ? 1 : -1) + i * pi;
          final rad = r * (i == 0 ? 0.5 : 0.28);
          final pos = c + Offset(cos(a), sin(a)) * rad;
          final dir = a + (i == 0 ? pi / 2 : -pi / 2);
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(dir);
          final body = i == 0 ? const Color(0xFFFF8A2E) : const Color(0xFFFFFFFF);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.55, height: r * 0.26), Paint()..color = body);
          canvas.drawPath(Path()..moveTo(-r * 0.22, 0)..lineTo(-r * 0.46, -r * 0.14 + sin(glow * 2 * pi * 12) * r * 0.05)..lineTo(-r * 0.46, r * 0.14 + sin(glow * 2 * pi * 12) * r * 0.05)..close(), Paint()..color = body.withValues(alpha: 0.85));
          canvas.drawCircle(Offset(r * 0.1, -r * 0.04), r * 0.04, Paint()..color = Colors.black87);
          canvas.restore();
        }
      case PegKind.lantern:
        canvas.drawCircle(c, r * (0.75 + 0.05 * pulse), Paint()..color = const Color(0xFFFFC46B).withValues(alpha: 0.3 + 0.25 * pulse)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.2));
        final rib = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFF5A0E08).withValues(alpha: 0.6);
        for (var i = -2; i <= 2; i++) {
          canvas.drawOval(Rect.fromCenter(center: c, width: r * 2 * (i.abs() / 2.4 + 0.1), height: s.height), rib);
        }
        canvas.drawRect(Rect.fromLTWH(c.dx - r * 0.45, 0, r * 0.9, r * 0.2), Paint()..color = const Color(0xFF2A1004));
        canvas.drawRect(Rect.fromLTWH(c.dx - r * 0.45, s.height - r * 0.2, r * 0.9, r * 0.2), Paint()..color = const Color(0xFF2A1004));
      case PegKind.radar:
        final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0xFF8AFFB0).withValues(alpha: 0.4);
        for (final k in [0.3, 0.6, 0.9]) {
          canvas.drawCircle(c, r * k, ring);
        }
        canvas.drawLine(Offset(0, c.dy), Offset(s.width, c.dy), ring);
        canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, s.height), ring);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = SweepGradient(
              transform: GradientRotation(glow * 2 * pi),
              colors: [const Color(0xFF8AFFB0).withValues(alpha: 0.0), const Color(0xFF8AFFB0).withValues(alpha: 0.65), const Color(0xFF8AFFB0).withValues(alpha: 0.0)],
              stops: const [0.0, 0.14, 0.15],
            ).createShader(rect),
        );
        final blip = (1 - ((glow - 0.3) % 1.0)) .clamp(0.0, 1.0);
        canvas.drawCircle(c + Offset(r * 0.4, -r * 0.3), r * 0.07, Paint()..color = Colors.white.withValues(alpha: blip));
      case PegKind.peppermint:
        const red = Color(0xFFE6304F);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = SweepGradient(
              transform: GradientRotation(glow * 2 * pi),
              colors: [for (var i = 0; i < 12; i++) ...(i.isEven ? [red, red] : [Colors.white, Colors.white])],
              stops: [for (var i = 0; i < 12; i++) ...[i / 12, (i + 1) / 12 - 0.0001]],
            ).createShader(rect),
        );
        canvas.drawCircle(c, r * 0.16, Paint()..color = Colors.white);
      case PegKind.material:
        break;
      case PegKind.ember:
        final facet = Paint()..color = const Color(0xFF3A0A02).withValues(alpha: 0.35)..strokeWidth = 1.2..style = PaintingStyle.stroke;
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3 + pi / 6;
          canvas.drawLine(c, c + Offset(cos(a), sin(a)) * r, facet);
        }
        canvas.drawCircle(c, r * 0.5, Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.25 + 0.3 * pulse)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3));
    }
    canvas.restore();

    if (theme.kind == PegKind.planet) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.38);
      final ringRect = Rect.fromCenter(center: Offset.zero, width: r * 2.7, height: r * 0.8);
      final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.2..color = const Color(0xFFEBD3A8).withValues(alpha: 0.9);
      canvas.drawArc(ringRect, 0.15, pi - 0.3, false, ring); // front half
      canvas.restore();
    }

    if (theme.kind != PegKind.material && Gfx.gloss != null) {
      for (final pass in [0.0, 1.0]) {
        final sh = Gfx.gloss!.fragmentShader()
          ..setFloat(0, s.width)
          ..setFloat(1, s.height)
          ..setFloat(2, pass)
          ..setFloat(3, theme.shine);
        canvas.drawRect(Offset.zero & s, Paint()..shader = sh..blendMode = pass == 0 ? BlendMode.multiply : BlendMode.plus);
      }
    }

    canvas.drawCircle(c, r - 0.5,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.black.withValues(alpha: 0.45));
    // specular highlight (fallback when shaders are unavailable)
    if (Gfx.gloss != null) return;
    final hl = Rect.fromLTWH(r * 0.42, r * 0.2, r * 0.7, r * 0.42);
    canvas.drawOval(
      hl,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.0)],
        ).createShader(hl),
    );
  }

  @override
  bool shouldRepaint(_PegPainter old) =>
      old.glow != glow || old.selected != selected || old.theme != theme;
}
