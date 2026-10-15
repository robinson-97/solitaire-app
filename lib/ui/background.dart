import 'dart:math';
import 'package:flutter/material.dart';
import '../game/worlds.dart';
import 'theme.dart';

/// Animated world scenery. Everything is drawn with smooth curves and soft
/// glows; motion loops seamlessly and stops when "reduce motion" is on.
class SceneBackground extends StatefulWidget {
  const SceneBackground({super.key, required this.scene, this.child = const SizedBox.shrink()});
  final WorldScene scene;
  final Widget child;

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(painter: _ScenePainter(widget.scene, _c.value)),
            ),
          ),
        ),
        widget.child,
      ]);
}

// ---------------------------------------------------------------- helpers

Path _smooth(List<Offset> pts, {bool closeBottom = false, double bottom = 0}) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 0; i < pts.length - 1; i++) {
    final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
    p.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
  }
  p.lineTo(pts.last.dx, pts.last.dy);
  if (closeBottom) {
    p
      ..lineTo(pts.last.dx, bottom)
      ..lineTo(pts.first.dx, bottom)
      ..close();
  }
  return p;
}

List<Offset> _ridge(Size s, double baseY, double amp, int seed, {int steps = 14, double phase = 0}) {
  final r = Random(seed);
  final a = r.nextDouble() * 6, b = r.nextDouble() * 6, c = r.nextDouble() * 6;
  return [
    for (var i = 0; i <= steps; i++)
      Offset(
        s.width * i / steps,
        baseY + amp * (sin(i * 0.55 + a + phase) * 0.55 + sin(i * 1.3 + b) * 0.3 + sin(i * 2.1 + c) * 0.15),
      ),
  ];
}

void _glow(Canvas c, Offset o, double r, Color color) {
  c.drawCircle(
    o,
    r,
    Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: o, radius: r)),
  );
}

void _sky(Canvas c, Size s, List<Color> colors, [List<double>? stops]) {
  final rect = Offset.zero & s;
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors, stops: stops)
          .createShader(rect),
  );
}

void _stars(Canvas c, Size s, double t, int n, double maxY, int seed) {
  final r = Random(seed);
  for (var i = 0; i < n; i++) {
    final x = r.nextDouble() * s.width;
    final y = r.nextDouble() * s.height * maxY;
    final size = 0.6 + r.nextDouble() * 1.3;
    final tw = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 2 * pi * (2 + i % 4) + i));
    c.drawCircle(Offset(x, y), size, Paint()..color = Colors.white.withValues(alpha: 0.75 * tw));
  }
}

void _mist(Canvas c, Size s, double t, double y, double h, Color color, double speed, double offset) {
  final w = s.width * 1.6;
  for (var k = 0; k < 2; k++) {
    final x = ((t * speed + offset + k * 0.5) % 1.0) * (s.width + w) - w;
    final rect = Rect.fromLTWH(x, y, w, h);
    c.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(rect),
    );
  }
}

void _pine(Canvas c, Offset base, double h, double sway, Paint paint) {
  final w = h * 0.30;
  for (var k = 0; k < 4; k++) {
    final top = base.dy - h + k * h * 0.2;
    final bot = top + h * 0.34;
    final half = w * (0.5 + k * 0.2);
    final tipX = base.dx + sway * (1 - k * 0.2);
    final path = Path()
      ..moveTo(tipX, top)
      ..quadraticBezierTo(base.dx + half * 0.15, (top + bot) / 2, base.dx + half, bot)
      ..quadraticBezierTo(base.dx, bot + h * 0.05, base.dx - half, bot)
      ..quadraticBezierTo(base.dx - half * 0.15, (top + bot) / 2, tipX, top)
      ..close();
    c.drawPath(path, paint);
  }
  c.drawRect(Rect.fromLTWH(base.dx - h * 0.02, base.dy - h * 0.1, h * 0.04, h * 0.12), paint);
}

// ---------------------------------------------------------------- scenes

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene, this.t);
  final WorldScene scene;
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    if (s.isEmpty) return;
    switch (scene) {
      case WorldScene.forest:
        _forest(canvas, s);
      case WorldScene.cavern:
        _cavern(canvas, s);
      case WorldScene.peak:
        _peak(canvas, s);
    }
  }

  // --- Glimmerwood
  void _forest(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF0B0A2E), Color(0xFF1C2A63), Color(0xFF1F5A6E), Color(0xFF123F3A)], const [0, 0.45, 0.78, 1]);
    _stars(c, s, t, 46, 0.45, 5);
    final moon = Offset(s.width * 0.78, s.height * 0.14);
    _glow(c, moon, 120, const Color(0x44FFF1C0));
    _glow(c, moon, 56, const Color(0x66FFF6D8));
    c.drawCircle(moon, 24, Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.3), colors: [Color(0xFFFFFBEA), Color(0xFFF3DFA2)]).createShader(Rect.fromCircle(center: moon, radius: 24)));

    final layers = [
      (0.62, 0.05, 0xFF16405A, 0.55, 13, 80.0),
      (0.72, 0.06, 0xFF0F3140, 0.75, 21, 105.0),
      (0.84, 0.05, 0xFF071A1C, 1.0, 34, 135.0),
    ];
    for (var i = 0; i < layers.length; i++) {
      final (y, amp, col, a, seed, treeH) = layers[i];
      final ridge = _ridge(s, s.height * y, s.height * amp, seed);
      final color = Color(col);
      c.drawPath(_smooth(ridge, closeBottom: true, bottom: s.height), Paint()..color = color);
      final pine = Paint()..color = color;
      final rnd = Random(seed + 7);
      final count = 9 + i * 2;
      for (var k = 0; k < count; k++) {
        final x = (k + rnd.nextDouble() * 0.7) * s.width / (count - 1);
        final ry = _ridgeY(ridge, x);
        final h = treeH * (0.6 + rnd.nextDouble() * 0.6);
        final sway = sin(t * 2 * pi * 3 + k * 1.7 + i) * h * 0.012;
        _pine(c, Offset(x, ry + 4), h, sway, pine);
      }
      if (i < 2) _mist(c, s, t, s.height * (y - 0.03), s.height * 0.12, Color(0x33A5C7D9), 1.0, i * 0.37);
    }
    // fireflies
    final r = Random(11);
    for (var i = 0; i < 26; i++) {
      final bx = r.nextDouble() * s.width;
      final by = s.height * (0.35 + r.nextDouble() * 0.6);
      final ph = r.nextDouble() * 2 * pi;
      final x = bx + sin(t * 2 * pi * 2 + ph) * 22 + sin(t * 2 * pi * 5 + ph) * 6;
      final y = by + cos(t * 2 * pi * 3 + ph) * 16;
      final glow = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 2 * pi * 6 + ph * 2));
      _glow(c, Offset(x, y), 11, lantern.withValues(alpha: 0.45 * glow));
      c.drawCircle(Offset(x, y), 1.6, Paint()..color = const Color(0xFFFFF0B8).withValues(alpha: glow));
    }
  }

  double _ridgeY(List<Offset> pts, double x) {
    for (var i = 0; i < pts.length - 1; i++) {
      if (x <= pts[i + 1].dx) {
        final f = (x - pts[i].dx) / (pts[i + 1].dx - pts[i].dx);
        return pts[i].dy + (pts[i + 1].dy - pts[i].dy) * f;
      }
    }
    return pts.last.dy;
  }

  // --- Crystal Cavern
  void _cavern(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF07031A), Color(0xFF190B3F), Color(0xFF0E3550), Color(0xFF07202B)], const [0, 0.4, 0.8, 1]);
    // soft light shafts
    for (var i = 0; i < 3; i++) {
      final x = s.width * (0.2 + i * 0.3) + sin(t * 2 * pi + i) * 18;
      final path = Path()
        ..moveTo(x - 14, 0)
        ..lineTo(x + 14, 0)
        ..lineTo(x + 90, s.height * 0.8)
        ..lineTo(x - 60, s.height * 0.8)
        ..close();
      final a = 0.05 + 0.03 * sin(t * 2 * pi * 2 + i * 2);
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(150, 220, 255, a * 2), const Color(0x00000000)])
              .createShader(Rect.fromLTWH(x - 60, 0, 150, s.height * 0.8)),
      );
    }
    // stalactites (two depths)
    for (var layer = 0; layer < 2; layer++) {
      final r = Random(40 + layer);
      final paint = Paint()..color = layer == 0 ? const Color(0xFF120A2B) : const Color(0xFF0A0518);
      final n = 7 + layer * 2;
      for (var i = 0; i < n; i++) {
        final x = (i + r.nextDouble() * 0.6) * s.width / (n - 1);
        final len = s.height * (0.07 + r.nextDouble() * 0.12) * (layer == 0 ? 0.8 : 1.2);
        final w = 18 + r.nextDouble() * 26;
        c.drawPath(
          Path()
            ..moveTo(x - w, -4)
            ..quadraticBezierTo(x - w * 0.25, len * 0.55, x, len)
            ..quadraticBezierTo(x + w * 0.25, len * 0.55, x + w, -4)
            ..close(),
          paint,
        );
      }
    }
    // glowing crystal clusters at the bottom
    final r = Random(9);
    final palette = const [Color(0xFF5CE1E6), Color(0xFFB07CFF), Color(0xFFFF7ADB)];
    for (var i = 0; i < 9; i++) {
      final x = (i + 0.3 + r.nextDouble() * 0.4) * s.width / 9;
      final h = s.height * (0.07 + r.nextDouble() * 0.12);
      final col = palette[i % 3];
      final pulse = 0.55 + 0.45 * sin(t * 2 * pi * 3 + i * 1.3);
      _glow(c, Offset(x, s.height - h * 0.4), h * 1.5, col.withValues(alpha: 0.22 * pulse));
      for (var k = 0; k < 3; k++) {
        final cx = x + (k - 1) * h * 0.28;
        final ch = h * (k == 1 ? 1.0 : 0.65);
        final cw = h * 0.16;
        final lean = (k - 1) * h * 0.12;
        final crystal = Path()
          ..moveTo(cx - cw, s.height + 6)
          ..lineTo(cx - cw * 0.9 + lean * 0.4, s.height - ch * 0.75)
          ..lineTo(cx + lean, s.height - ch)
          ..lineTo(cx + cw * 0.9 + lean * 0.4, s.height - ch * 0.75)
          ..lineTo(cx + cw, s.height + 6)
          ..close();
        final b = Rect.fromLTWH(cx - cw, s.height - ch, cw * 2, ch);
        c.drawPath(
          crystal,
          Paint()
            ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(col, Colors.white, 0.5)!, col, const Color(0xFF1A0B40)]).createShader(b)
            ..strokeJoin = StrokeJoin.round,
        );
        c.drawPath(crystal, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round..color = col.withValues(alpha: 0.5));
      }
    }
    // drifting motes
    final m = Random(3);
    for (var i = 0; i < 34; i++) {
      final speed = 1 + i % 3;
      final x = m.nextDouble() * s.width + sin(t * 2 * pi * 2 + i) * 12;
      final y = s.height - ((m.nextDouble() + t * speed) % 1.0) * s.height;
      final col = palette[i % 3];
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 * pi * 5 + i));
      _glow(c, Offset(x, y), 7, col.withValues(alpha: 0.35 * tw));
      c.drawCircle(Offset(x, y), 1.3, Paint()..color = Colors.white.withValues(alpha: 0.85 * tw));
    }
  }

  // --- Starfall Peak
  void _peak(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF050722), Color(0xFF1B1856), Color(0xFF5A2A7C), Color(0xFFB25A86)], const [0, 0.42, 0.78, 1]);
    _stars(c, s, t, 90, 0.7, 17);
    // aurora ribbons
    for (var k = 0; k < 3; k++) {
      final baseY = s.height * (0.2 + k * 0.07);
      final pts = [
        for (var i = 0; i <= 8; i++)
          Offset(s.width * i / 8, baseY + sin(i * 0.9 + t * 2 * pi * 2 + k * 2) * 22 + sin(i * 0.4 + t * 2 * pi + k) * 14),
      ];
      final band = _smooth(pts);
      final ribbon = Path.from(band);
      for (var i = pts.length - 1; i >= 0; i--) {
        ribbon.lineTo(pts[i].dx, pts[i].dy + 70 + 20 * sin(i + k));
      }
      ribbon.close();
      final col = [const Color(0xFF63F5C4), const Color(0xFF8F7CFF), const Color(0xFF53C6FF)][k];
      c.drawPath(
        ribbon,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withValues(alpha: 0.0), col.withValues(alpha: 0.26), col.withValues(alpha: 0)])
              .createShader(Rect.fromLTWH(0, baseY - 30, s.width, 160))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    // shooting stars
    for (var i = 0; i < 3; i++) {
      final life = (t * 3 + i / 3) % 1.0;
      if (life > 0.35) continue;
      final f = life / 0.35;
      final start = Offset(s.width * (0.15 + 0.3 * i), s.height * (0.04 + 0.07 * i));
      final head = start + Offset(f * s.width * 0.55, f * s.height * 0.28);
      final tail = head - Offset(s.width * 0.14, s.height * 0.07) * sin(f * pi);
      c.drawLine(
        tail,
        head,
        Paint()
          ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.9 * sin(f * pi))]).createShader(Rect.fromPoints(tail, head))
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      _glow(c, head, 9, Colors.white.withValues(alpha: 0.5 * sin(f * pi)));
    }
    // mountain ridges, rounded and snow-capped
    final defs = [
      (0.66, 0.10, 0xFF3B2A66, 3, 0.3),
      (0.78, 0.09, 0xFF211649, 8, 0.2),
      (0.9, 0.06, 0xFF0F0A26, 14, 0.0),
    ];
    for (var i = 0; i < defs.length; i++) {
      final (y, amp, col, seed, snow) = defs[i];
      final ridge = _ridge(s, s.height * y, s.height * amp, seed, steps: 7);
      final path = _smooth(ridge, closeBottom: true, bottom: s.height);
      c.drawPath(path, Paint()..color = Color(col));
      if (snow > 0) {
        c.save();
        c.clipPath(path);
        c.drawPath(
          _smooth([for (final p in ridge) p + const Offset(0, 14)], closeBottom: true, bottom: s.height * 2),
          Paint()..color = Color(col),
        );
        c.drawPath(
          _smooth(ridge),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.white.withValues(alpha: snow)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        c.restore();
      }
      if (i < 2) _mist(c, s, t, s.height * (y - 0.02), s.height * 0.1, const Color(0x44D7B8FF), 1.0, i * 0.4);
    }
    // gentle snow
    final r = Random(5);
    for (var i = 0; i < 40; i++) {
      final speed = 1 + i % 2;
      final x = r.nextDouble() * s.width + sin(t * 2 * pi * 3 + i) * 14;
      final y = ((r.nextDouble() + t * speed) % 1.0) * s.height;
      c.drawCircle(Offset(x, y), 0.8 + r.nextDouble() * 1.2, Paint()..color = Colors.white.withValues(alpha: 0.55));
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t || old.scene != scene;
}

/// A still frame of a scene, used on world cards.
class SceneArt extends StatelessWidget {
  const SceneArt(this.scene, {super.key});
  final WorldScene scene;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ScenePainter(scene, 0.12), child: const SizedBox.expand());
}
