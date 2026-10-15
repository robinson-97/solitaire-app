import 'dart:math';
import 'package:flutter/material.dart';
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
    final glassy = theme.kind == PegKind.glass;
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
      case PegKind.ember:
        final facet = Paint()..color = const Color(0xFF3A0A02).withValues(alpha: 0.35)..strokeWidth = 1.2..style = PaintingStyle.stroke;
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3 + pi / 6;
          canvas.drawLine(c, c + Offset(cos(a), sin(a)) * r, facet);
        }
        canvas.drawCircle(c, r * 0.5, Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.25 + 0.3 * pulse)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3));
    }
    canvas.restore();

    canvas.drawCircle(c, r - 0.5,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.black.withValues(alpha: 0.45));
    // specular highlight
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
