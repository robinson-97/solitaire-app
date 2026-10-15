import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Twilight forest: indigo-to-green sky, moon, pine silhouettes, fireflies.
class TwilightBackground extends StatefulWidget {
  const TwilightBackground({super.key, required this.child});
  final Widget child;

  @override
  State<TwilightBackground> createState() => _TwilightBackgroundState();
}

class _TwilightBackgroundState extends State<TwilightBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return Stack(children: [
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _ForestPainter(still ? 0 : _c.value),
          ),
        ),
      ),
      widget.child,
    ]);
  }
}

class _ForestPainter extends CustomPainter {
  _ForestPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1646), Color(0xFF1E3A5F), Color(0xFF0F3B2E)],
        ).createShader(rect),
    );
    // moon
    final moon = Offset(s.width * 0.84, s.height * 0.2);
    canvas.drawCircle(moon, 46,
        Paint()..color = const Color(0x33FFF3C4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
    canvas.drawCircle(moon, 22, Paint()..color = const Color(0xFFFFF3C4));
    // pines
    final pine = Paint()..color = const Color(0xFF07160F);
    final rnd = Random(4);
    for (var i = 0; i < 12; i++) {
      final x = i * s.width / 11;
      final h = 90 + rnd.nextDouble() * 90;
      final w = h * 0.45;
      final base = s.height;
      final path = Path();
      for (var k = 0; k < 3; k++) {
        final top = base - h + k * h * 0.28;
        final bw = w * (0.45 + k * 0.28);
        path
          ..moveTo(x, top)
          ..lineTo(x + bw, top + h * 0.4)
          ..lineTo(x - bw, top + h * 0.4)
          ..close();
      }
      canvas.drawPath(path, pine);
    }
    // fireflies
    final fr = Random(11);
    for (var i = 0; i < 16; i++) {
      final bx = fr.nextDouble() * s.width;
      final by = s.height * (0.35 + fr.nextDouble() * 0.6);
      final ph = fr.nextDouble() * 2 * pi;
      final x = bx + sin(t * 2 * pi * 2 + ph) * 18;
      final y = by + cos(t * 2 * pi * 3 + ph) * 12;
      final glow = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 * pi * 6 + ph));
      canvas.drawCircle(
          Offset(x, y),
          7,
          Paint()
            ..color = lantern.withValues(alpha: 0.25 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset(x, y), 1.8,
          Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: glow));
    }
  }

  @override
  bool shouldRepaint(_ForestPainter old) => old.t != t;
}
