import 'package:flutter/material.dart';
import 'kit.dart';

/// Neon accent pair per world (used for the dark "neon night" backdrops).
const neonPalette = <String, (Color, Color)>{
  'menu': (Color(0xFF35F0FF), Color(0xFFFF3DB4)),
  'forest': (Color(0xFF35FFA0), Color(0xFF35F0FF)),
  'desert': (Color(0xFFFFB040), Color(0xFFFF4A7A)),
  'coral': (Color(0xFF35F0FF), Color(0xFFFF6AC8)),
  'cosmic': (Color(0xFFB07CFF), Color(0xFFFF3DB4)),
  'frozen': (Color(0xFF7CE8FF), Color(0xFF9AB8FF)),
  'volcanic': (Color(0xFFFF5A2A), Color(0xFFFFB02E)),
  'jungle': (Color(0xFF5AFF8A), Color(0xFF35F0C8)),
  'cyber': (Color(0xFF35F0FF), Color(0xFFFF2BD6)),
  'countryside': (Color(0xFFFFD84A), Color(0xFF7CFF6A)),
  'candy': (Color(0xFFFF7AC8), Color(0xFF7AE8FF)),
  'moonlit': (Color(0xFF9AB8FF), Color(0xFF35F0FF)),
  'autumn': (Color(0xFFFF9A2E), Color(0xFFFF4A4A)),
  'ruins': (Color(0xFFFFD98A), Color(0xFF5AFFB8)),
  'tropical': (Color(0xFF35F0FF), Color(0xFFFFD84A)),
  'crystal': (Color(0xFFB07CFF), Color(0xFF35F0FF)),
  'fairytale': (Color(0xFF7AA8FF), Color(0xFFFFD84A)),
  'treasure': (Color(0xFFFFC83A), Color(0xFFFF8A2E)),
  'sakura': (Color(0xFFFF8AC0), Color(0xFFB07CFF)),
  'deepsea': (Color(0xFF35F0FF), Color(0xFF7A5CFF)),
  'skyislands': (Color(0xFF7AD0FF), Color(0xFFB07CFF)),
};

const _ink = Color(0xFF05071A);

Layer _blob(Color col, Offset at, double radius, {double alpha = 0.42, double dx = 0.1, double dy = 0.05, double phase = 0}) => Layer.still((c, s) {
      final o = Offset(s.width * at.dx, s.height * at.dy);
      final r = s.width * radius;
      c.drawCircle(
        o,
        r,
        Paint()..shader = RadialGradient(colors: [col.withValues(alpha: alpha), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }, driftX: dx, driftY: dy, driftCycles: 1, driftPhase: phase);

/// Simple dark backdrop in one world's colours: two big soft glows that drift
/// very slowly, plus a few tiny lights floating up.
SceneSpec neonScene(String id) {
  final (a, b) = neonPalette[id] ?? neonPalette['menu']!;
  final h = id.codeUnits.fold<int>(7, (x, y) => (x * 31 + y) & 0xFFFF);
  double f(int k) => ((h >> k) & 7) / 7.0;
  return SceneSpec(
    focusY: 0,
    topShade: 0.0,
    bottomShade: 0.1,
    layers: [
      Layer.still((c, s) => fillSky(c, s, [mix(_ink, a, 0.07), mix(_ink, b, 0.07), mix(_ink, b, 0.14)], const [0.0, 0.55, 1.0])),
      _blob(a, Offset(0.1 + 0.3 * f(0), 0.12 + 0.25 * f(2)), 0.6, alpha: 0.6, dx: 0.10, dy: 0.05),
      _blob(b, Offset(0.65 + 0.3 * f(1), 0.62 + 0.3 * f(3)), 0.62, alpha: 0.5, dx: -0.10, dy: -0.04, phase: 0.5),
      Layer.live((c, s, k) => paintParticles(
          c,
          s,
          k,
          ParticleSpec(count: 16, seed: 9, colors: [a, b, const Color(0xFFFFFFFF)], minSize: 1.2, maxSize: 2.6, flow: const Offset(0, -0.1), cycles: 1, spread: 1, wander: 8, twinkle: 0.6, shape: ParticleShape.glow, region: const Rect.fromLTRB(0, 0.05, 1, 1), haloScale: 2.6, opacity: 0.8))),
    ],
  );
}
