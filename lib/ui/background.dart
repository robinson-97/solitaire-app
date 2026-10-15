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
      case WorldScene.desert:
        _desert(canvas, s);
      case WorldScene.ocean:
        _ocean(canvas, s);
      case WorldScene.volcano:
        _volcano(canvas, s);
      case WorldScene.tundra:
        _tundra(canvas, s);
      case WorldScene.sky:
        _skyIslands(canvas, s);
      case WorldScene.stadium:
        _stadium(canvas, s);
      case WorldScene.neon:
        _neon(canvas, s);
      case WorldScene.nebula:
        _nebula(canvas, s);
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


  // --- Sunbaked Dunes
  void _desert(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF140B3A), Color(0xFF5A2A6E), Color(0xFFD9663C), Color(0xFFF6B25E)], const [0, 0.4, 0.74, 1]);
    _stars(c, s, t, 40, 0.34, 3);
    final sun = Offset(s.width * 0.3, s.height * 0.64);
    _glow(c, sun, s.width * 0.6, const Color(0x55FFC27A));
    _glow(c, sun, 70, const Color(0x99FFD59A));
    c.drawCircle(sun, 32, Paint()..shader = const RadialGradient(colors: [Color(0xFFFFF3C4), Color(0xFFFFB45E)]).createShader(Rect.fromCircle(center: sun, radius: 32)));
    const dunes = [(0.70, 0xFFB5532F, 3), (0.79, 0xFF8E3B26, 8), (0.90, 0xFF4F1E16, 15)];
    for (var i = 0; i < dunes.length; i++) {
      final (y, col, seed) = dunes[i];
      final ridge = _ridge(s, s.height * y, s.height * 0.05, seed, steps: 8);
      c.drawPath(_smooth(ridge, closeBottom: true, bottom: s.height), Paint()..color = Color(col));
      c.drawPath(_smooth([for (final p in ridge) p + const Offset(0, 3)]), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0x44FFD59A));
      if (i < 2) _mist(c, s, t, s.height * (y - 0.02), s.height * 0.1, const Color(0x33FFC98A), 1.0, i * 0.4);
    }
    final r = Random(6);
    for (var i = 0; i < 40; i++) {
      final speed = 1 + i % 3;
      final x = ((r.nextDouble() + t * speed) % 1.0) * s.width;
      final y = s.height * (0.55 + r.nextDouble() * 0.4) + sin(t * 2 * pi * 4 + i) * 6;
      c.drawCircle(Offset(x, y), 0.8 + r.nextDouble(), Paint()..color = const Color(0xFFFFD8A0).withValues(alpha: 0.5));
    }
  }

  // --- Coral Deep
  void _ocean(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF031A38), Color(0xFF06466F), Color(0xFF0B7A94), Color(0xFF0C9AA0)], const [0, 0.4, 0.8, 1]);
    for (var i = 0; i < 4; i++) {
      final x = s.width * (0.1 + i * 0.27) + sin(t * 2 * pi + i * 1.7) * 22;
      final path = Path()
        ..moveTo(x - 10, 0)
        ..lineTo(x + 18, 0)
        ..lineTo(x + 110, s.height * 0.85)
        ..lineTo(x - 70, s.height * 0.85)
        ..close();
      c.drawPath(path, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.13 + 0.04 * sin(t * 2 * pi * 2 + i)), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromLTWH(x - 70, 0, 200, s.height * 0.85)));
    }
    final fr = Random(31);
    for (var i = 0; i < 6; i++) {
      final dir = i.isEven ? 1.0 : -1.0;
      final f = (fr.nextDouble() + t * (1 + i % 2)) % 1.0;
      final x = dir > 0 ? f * (s.width + 80) - 40 : s.width + 40 - f * (s.width + 80);
      final y = s.height * (0.2 + fr.nextDouble() * 0.5) + sin(t * 2 * pi * 6 + i) * 4;
      final body = Path()
        ..moveTo(x + dir * 12, y)
        ..quadraticBezierTo(x, y - 6, x - dir * 10, y)
        ..quadraticBezierTo(x, y + 6, x + dir * 12, y)
        ..moveTo(x - dir * 9, y)
        ..lineTo(x - dir * 17, y - 5)
        ..lineTo(x - dir * 17, y + 5)
        ..close();
      c.drawPath(body, Paint()..color = const Color(0xFF9FE6F0).withValues(alpha: 0.35));
    }
    final br = Random(12);
    for (var i = 0; i < 34; i++) {
      final speed = 1 + i % 3;
      final x = br.nextDouble() * s.width + sin(t * 2 * pi * 3 + i) * 10;
      final y = s.height - ((br.nextDouble() + t * speed) % 1.0) * s.height;
      final rad = 2 + br.nextDouble() * 4;
      c.drawCircle(Offset(x, y), rad, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white.withValues(alpha: 0.4));
      c.drawCircle(Offset(x - rad * 0.3, y - rad * 0.3), rad * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.6));
    }
    final floor = _ridge(s, s.height * 0.9, s.height * 0.03, 9, steps: 9);
    c.drawPath(_smooth(floor, closeBottom: true, bottom: s.height), Paint()..color = const Color(0xFF062A33));
    for (var i = 0; i < 9; i++) {
      final x = (i + 0.5) * s.width / 9;
      final base = Offset(x, _ridgeY(floor, x) + 2);
      final hgt = s.height * (0.08 + (i * 37 % 10) / 100);
      final sway = sin(t * 2 * pi * 2 + i) * 9;
      final p = Path()..moveTo(base.dx, base.dy)..quadraticBezierTo(base.dx + sway, base.dy - hgt * 0.55, base.dx + sway * 0.4, base.dy - hgt);
      c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..color = const Color(0xFF0F6A52));
    }
  }

  // --- Ember Crater
  void _volcano(Canvas c, Size s) {
    final pulse = 0.5 + 0.5 * sin(t * 2 * pi * 3);
    _sky(c, s, const [Color(0xFF0B0407), Color(0xFF2E0A0C), Color(0xFF7A1E10), Color(0xFFD9531E)], const [0, 0.45, 0.8, 1]);
    _mist(c, s, t, s.height * 0.3, s.height * 0.16, const Color(0x44301418), 1.0, 0.1);
    final crater = Offset(s.width * 0.3, s.height * 0.56);
    _glow(c, crater, 150, Color.fromRGBO(255, 110, 40, 0.35 + 0.15 * pulse));
    for (var k = 0; k < 4; k++) {
      final f = (t * 2 + k / 4) % 1.0;
      c.drawCircle(crater + Offset(sin(f * 6 + k) * 18, -f * s.height * 0.3), 18 + f * 34,
          Paint()..color = Color.fromRGBO(70, 40, 40, 0.28 * (1 - f))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    }
    final cone = Path()
      ..moveTo(-20, s.height)
      ..quadraticBezierTo(s.width * 0.12, s.height * 0.8, crater.dx - 38, crater.dy + 4)
      ..lineTo(crater.dx + 38, crater.dy + 4)
      ..quadraticBezierTo(s.width * 0.5, s.height * 0.8, s.width * 0.62, s.height)
      ..close();
    c.drawPath(cone, Paint()..color = const Color(0xFF140808));
    final river = Path()..moveTo(crater.dx - 6, crater.dy + 6)
      ..quadraticBezierTo(crater.dx - 30, s.height * 0.7, crater.dx - 12, s.height * 0.86)
      ..quadraticBezierTo(crater.dx + 6, s.height * 0.94, crater.dx - 20, s.height);
    c.drawPath(river, Paint()..style = PaintingStyle.stroke..strokeWidth = 12..color = Color.fromRGBO(255, 90, 30, 0.35 + 0.2 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    c.drawPath(river, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round..color = const Color(0xFFFFB347));
    c.drawOval(Rect.fromCenter(center: crater + const Offset(0, 4), width: 76, height: 14), Paint()..color = const Color(0xFFFF8A3A));
    final back = _ridge(s, s.height * 0.78, s.height * 0.04, 17, steps: 8);
    c.drawPath(_smooth(back, closeBottom: true, bottom: s.height), Paint()..color = const Color(0xFF1C0A0A));
    final e = Random(44);
    for (var i = 0; i < 46; i++) {
      final speed = 1 + i % 3;
      final x = crater.dx + (e.nextDouble() - 0.5) * s.width * 0.9 + sin(t * 2 * pi * 3 + i) * 14;
      final y = s.height - ((e.nextDouble() + t * speed) % 1.0) * s.height;
      final a = 0.5 + 0.5 * sin(t * 2 * pi * 5 + i);
      _glow(c, Offset(x, y), 7, Color.fromRGBO(255, 120, 40, 0.4 * a));
      c.drawCircle(Offset(x, y), 1.4, Paint()..color = const Color(0xFFFFD27A).withValues(alpha: a));
    }
  }

  // --- Frostwind Tundra
  void _aurora(Canvas c, Size s, double y0, List<Color> cols) {
    for (var k = 0; k < cols.length; k++) {
      final baseY = s.height * (y0 + k * 0.07);
      final pts = [
        for (var i = 0; i <= 8; i++)
          Offset(s.width * i / 8, baseY + sin(i * 0.9 + t * 2 * pi * 2 + k * 2) * 22 + sin(i * 0.4 + t * 2 * pi + k) * 14),
      ];
      final ribbon = Path.from(_smooth(pts));
      for (var i = pts.length - 1; i >= 0; i--) {
        ribbon.lineTo(pts[i].dx, pts[i].dy + 70 + 20 * sin(i + k));
      }
      ribbon.close();
      final col = cols[k];
      c.drawPath(ribbon, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withValues(alpha: 0), col.withValues(alpha: 0.28), col.withValues(alpha: 0)]).createShader(Rect.fromLTWH(0, baseY - 30, s.width, 160))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    }
  }

  void _tundra(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF040C26), Color(0xFF0C2D54), Color(0xFF3F86A6), Color(0xFFA8D8EA)], const [0, 0.4, 0.78, 1]);
    _stars(c, s, t, 70, 0.5, 21);
    _aurora(c, s, 0.16, const [Color(0xFF63F5C4), Color(0xFF53C6FF), Color(0xFF9B7CFF)]);
    const layers = [(0.66, 0xFFB9D6E8, 5, 70.0), (0.76, 0xFF86AEC8, 11, 95.0), (0.88, 0xFF3F6684, 19, 125.0)];
    for (var i = 0; i < layers.length; i++) {
      final (y, col, seed, treeH) = layers[i];
      final ridge = _ridge(s, s.height * y, s.height * 0.05, seed, steps: 10);
      c.drawPath(_smooth(ridge, closeBottom: true, bottom: s.height), Paint()..color = Color(col));
      final rnd = Random(seed + 2);
      final pine = Paint()..color = Color.lerp(Color(col), const Color(0xFF0B2236), 0.55)!;
      final n = 6 + i * 2;
      for (var k = 0; k < n; k++) {
        final x = (k + rnd.nextDouble() * 0.7) * s.width / (n - 1);
        final h = treeH * (0.6 + rnd.nextDouble() * 0.5);
        _pine(c, Offset(x, _ridgeY(ridge, x) + 3), h, sin(t * 2 * pi * 3 + k + i) * h * 0.01, pine);
      }
      if (i < 2) _mist(c, s, t, s.height * (y - 0.03), s.height * 0.1, const Color(0x44DDF3FF), 1.0, i * 0.4);
    }
    final r = Random(7);
    for (var i = 0; i < 70; i++) {
      final speed = 1 + i % 3;
      final x = r.nextDouble() * s.width + sin(t * 2 * pi * 3 + i) * 16;
      final y = ((r.nextDouble() + t * speed) % 1.0) * s.height;
      c.drawCircle(Offset(x, y), 0.9 + r.nextDouble() * 1.5, Paint()..color = Colors.white.withValues(alpha: 0.7));
    }
  }

  // --- Sky Gardens
  void _skyIslands(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF2B2A7A), Color(0xFF9C5DB0), Color(0xFFFFA879), Color(0xFFFFE2A6)], const [0, 0.42, 0.75, 1]);
    final sun = Offset(s.width * 0.7, s.height * 0.72);
    _glow(c, sun, s.width * 0.7, const Color(0x55FFE2A6));
    c.drawCircle(sun, 40, Paint()..color = const Color(0xFFFFF0C8));
    void cloud(double yy, double speed, double scale, Color col, double off) {
      final w = 240 * scale;
      for (var k = 0; k < 2; k++) {
        final x = ((t * speed + off + k * 0.5) % 1.0) * (s.width + w * 2) - w;
        for (var j = 0; j < 4; j++) {
          final rect = Rect.fromCenter(center: Offset(x + j * w * 0.22, yy + (j.isEven ? 0 : -10 * scale)), width: w * 0.55, height: 46 * scale);
          c.drawOval(rect, Paint()..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(rect));
        }
      }
    }
    cloud(s.height * 0.25, 1.0, 1.0, const Color(0x66FFFFFF), 0.1);
    cloud(s.height * 0.5, 1.0, 1.3, const Color(0x55FFD9E8), 0.5);
    for (var i = 0; i < 3; i++) {
      final cx = s.width * (0.2 + i * 0.32);
      final cy = s.height * (0.42 + (i % 2) * 0.16) + sin(t * 2 * pi * 2 + i * 2) * 8;
      final w = 80.0 + i * 14;
      final rock = Path()
        ..moveTo(cx - w, cy)
        ..quadraticBezierTo(cx - w * 0.5, cy + w * 0.8, cx, cy + w * 1.1)
        ..quadraticBezierTo(cx + w * 0.5, cy + w * 0.8, cx + w, cy)
        ..close();
      c.drawPath(rock, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7A4F6E), Color(0xFF3B2447)]).createShader(Rect.fromCenter(center: Offset(cx, cy + w * 0.5), width: w * 2, height: w * 1.1)));
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 2, height: w * 0.34), Paint()..color = const Color(0xFF5BB36B));
      for (var k = 0; k < 3; k++) {
        final tx = cx + (k - 1) * w * 0.5;
        c.drawCircle(Offset(tx, cy - 14), 12, Paint()..color = const Color(0xFF3E8F54));
        c.drawRect(Rect.fromLTWH(tx - 1.5, cy - 8, 3, 8), Paint()..color = const Color(0xFF5A3A2A));
      }
    }
    final r = Random(2);
    for (var i = 0; i < 22; i++) {
      final x = ((r.nextDouble() + t * (1 + i % 2)) % 1.0) * s.width;
      final y = s.height * (0.15 + r.nextDouble() * 0.7) + sin(t * 2 * pi * 4 + i) * 8;
      _glow(c, Offset(x, y), 7, const Color(0x44FFF0C8));
      c.drawCircle(Offset(x, y), 1.2, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
  }

  // --- Stadium Nights
  void _stadium(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF050818), Color(0xFF0E1B3E), Color(0xFF1B2F5E)], const [0, 0.55, 1]);
    _stars(c, s, t, 30, 0.3, 40);
    for (var i = 0; i < 2; i++) {
      final x = s.width * (i == 0 ? 0.14 : 0.86);
      final dir = i == 0 ? 1.0 : -1.0;
      final panel = Offset(x, s.height * 0.26);
      c.drawLine(Offset(x, s.height * 0.6), panel, Paint()..color = const Color(0xFF0A0F22)..strokeWidth = 5);
      final beam = Path()..moveTo(panel.dx, panel.dy)..lineTo(panel.dx + dir * s.width * 0.75, s.height * 0.5)..lineTo(panel.dx + dir * s.width * 0.55, s.height * 0.78)..close();
      c.drawPath(beam, Paint()..shader = LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: dir > 0 ? [const Color(0x33FFF6D0), const Color(0x00FFF6D0)] : [const Color(0x00FFF6D0), const Color(0x33FFF6D0)]).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
      _glow(c, panel, 48, const Color(0xAAFFF6D0));
      for (var a = 0; a < 3; a++) {
        for (var b = 0; b < 2; b++) {
          c.drawCircle(panel + Offset((a - 1) * 9.0, (b - 0.5) * 9.0), 3.2, Paint()..color = const Color(0xFFFFFBE8));
        }
      }
    }
    final crowd = _ridge(s, s.height * 0.62, s.height * 0.025, 50, steps: 26);
    c.drawPath(_smooth(crowd, closeBottom: true, bottom: s.height), Paint()..color = const Color(0xFF0A1024));
    final r = Random(13);
    for (var i = 0; i < 40; i++) {
      final x = r.nextDouble() * s.width;
      final y = _ridgeY(crowd, x) + 6 + r.nextDouble() * s.height * 0.06;
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 * pi * 4 + i * 1.7));
      final col = HSVColor.fromAHSV(1, (i * 47.0) % 360, 0.5, 1).toColor();
      _glow(c, Offset(x, y), 6, col.withValues(alpha: 0.35 * tw));
      c.drawCircle(Offset(x, y), 1.3, Paint()..color = col.withValues(alpha: tw));
    }
    final top = s.height * 0.7;
    final field = Rect.fromLTRB(0, top, s.width, s.height);
    c.drawRect(field, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1F6B34), Color(0xFF0F3E1E)]).createShader(field));
    for (var i = 0; i < 9; i++) {
      final y0 = top + (s.height - top) * pow(i / 9, 1.6);
      final y1 = top + (s.height - top) * pow((i + 1) / 9, 1.6);
      if (i.isEven) c.drawRect(Rect.fromLTRB(0, y0.toDouble(), s.width, y1.toDouble()), Paint()..color = const Color(0x22FFFFFF));
    }
    c.drawOval(Rect.fromCenter(center: Offset(s.width / 2, top + (s.height - top) * 0.45), width: s.width * 0.5, height: (s.height - top) * 0.35), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0x55FFFFFF));
    for (var i = 0; i < 26; i++) {
      final x = r.nextDouble() * s.width + sin(t * 2 * pi * 3 + i) * 12;
      final y = ((r.nextDouble() + t * (1 + i % 2)) % 1.0) * s.height;
      c.save();
      c.translate(x, y);
      c.rotate(t * 2 * pi * 4 + i);
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 3), Paint()..color = HSVColor.fromAHSV(0.8, (i * 61.0) % 360, 0.6, 1).toColor());
      c.restore();
    }
  }

  // --- Neon Arcade
  void _neon(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF0A0420), Color(0xFF2A0A5A), Color(0xFF7A1F8A), Color(0xFFFF3D9A)], const [0, 0.4, 0.7, 1]);
    _stars(c, s, t, 50, 0.4, 61);
    final horizon = s.height * 0.66;
    final sun = Offset(s.width / 2, horizon - s.width * 0.02);
    final sr = s.width * 0.28;
    _glow(c, sun, sr * 2.2, const Color(0x55FF5CA8));
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, s.width, horizon));
    c.drawCircle(sun, sr, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE45E), Color(0xFFFF4FA3)]).createShader(Rect.fromCircle(center: sun, radius: sr)));
    for (var i = 0; i < 6; i++) {
      final f = (i + t * 2) % 6 / 6;
      final y = sun.dy - sr * 0.1 + f * sr * 1.1;
      c.drawRect(Rect.fromLTWH(sun.dx - sr, y, sr * 2, 2 + f * 7), Paint()..color = const Color(0xFF2A0A5A));
    }
    c.restore();
    final rnd = Random(70);
    var x = 0.0;
    while (x < s.width) {
      final w = 18 + rnd.nextDouble() * 26;
      final h = s.height * (0.04 + rnd.nextDouble() * 0.12);
      c.drawRect(Rect.fromLTWH(x, horizon - h, w, h), Paint()..color = const Color(0xFF120630));
      for (var k = 0; k < 5; k++) {
        if (rnd.nextDouble() < 0.5) c.drawRect(Rect.fromLTWH(x + 3 + rnd.nextDouble() * (w - 8), horizon - h + 4 + rnd.nextDouble() * (h - 8), 3, 3), Paint()..color = Color.lerp(const Color(0xFF35F0FF), const Color(0xFFFF3DB4), rnd.nextDouble())!.withValues(alpha: 0.8));
      }
      x += w + 2;
    }
    c.drawRect(Rect.fromLTRB(0, horizon, s.width, s.height), Paint()..color = const Color(0xFF0B0424));
    final vp = Offset(s.width / 2, horizon);
    final glowLine = Paint()..color = const Color(0xFFFF3DB4).withValues(alpha: 0.6)..strokeWidth = 1.4;
    for (var i = -10; i <= 10; i++) {
      c.drawLine(vp, Offset(s.width / 2 + i * s.width * 0.18, s.height), glowLine);
    }
    for (var k = 0; k < 9; k++) {
      final f = ((k + t * 6) % 9) / 9;
      final y = horizon + (s.height - horizon) * f * f;
      c.drawLine(Offset(0, y), Offset(s.width, y), Paint()..color = const Color(0xFF35F0FF).withValues(alpha: 0.15 + 0.5 * f)..strokeWidth = 0.8 + f * 1.6);
    }
    c.drawLine(Offset(0, horizon), Offset(s.width, horizon), Paint()..color = const Color(0xFFFF3DB4)..strokeWidth = 2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  // --- Nebula Drift
  void _nebula(Canvas c, Size s) {
    _sky(c, s, const [Color(0xFF03010F), Color(0xFF0B0830), Color(0xFF150A3A)], const [0, 0.6, 1]);
    const cols = [Color(0xFFFF4FA3), Color(0xFF4F7BFF), Color(0xFF35F0D0), Color(0xFF9B5CFF), Color(0xFFFF8A4F)];
    final r = Random(33);
    for (var i = 0; i < 6; i++) {
      final cx = s.width * (0.1 + r.nextDouble() * 0.8) + sin(t * 2 * pi + i * 1.3) * 26;
      final cy = s.height * (0.1 + r.nextDouble() * 0.8) + cos(t * 2 * pi + i) * 20;
      final w = s.width * (0.6 + r.nextDouble() * 0.5);
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: w * 0.6);
      final col = cols[i % cols.length];
      c.drawOval(rect, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.30), col.withValues(alpha: 0)]).createShader(rect));
    }
    _stars(c, s, t, 130, 1.0, 88);
    final pl = Offset(s.width * 0.78, s.height * 0.2);
    _glow(c, pl, 70, const Color(0x44FFC27A));
    c.drawCircle(pl, 30, Paint()..shader = const RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFFFFE9C0), Color(0xFFC2742E), Color(0xFF4A2410)]).createShader(Rect.fromCircle(center: pl, radius: 30)));
    c.save();
    c.translate(pl.dx, pl.dy);
    c.rotate(-0.4);
    c.drawArc(Rect.fromCenter(center: Offset.zero, width: 100, height: 26), pi + 0.1, pi - 0.2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0x66EBD3A8));
    c.drawArc(Rect.fromCenter(center: Offset.zero, width: 100, height: 26), 0.1, pi - 0.2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0xCCEBD3A8));
    c.restore();
    final moon = Offset(s.width * 0.18, s.height * 0.78);
    c.drawCircle(moon, 12, Paint()..color = const Color(0xFF8FA0C8));
    c.drawCircle(moon + const Offset(-3, -3), 4, Paint()..color = const Color(0x33FFFFFF));
    for (var i = 0; i < 2; i++) {
      final life = (t * 2 + i / 2) % 1.0;
      if (life > 0.3) continue;
      final f = life / 0.3;
      final head = Offset(s.width * (0.2 + 0.4 * i) + f * s.width * 0.5, s.height * (0.1 + 0.3 * i) + f * s.height * 0.2);
      final tail = head - Offset(s.width * 0.12, s.height * 0.06) * sin(f * pi);
      c.drawLine(tail, head, Paint()..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.9)]).createShader(Rect.fromPoints(tail, head))..strokeWidth = 2);
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
