import 'dart:math' as math;
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

/// Simple, sleek dark backdrop: night gradient, neon horizon, perspective grid
/// racing towards you, outlined ridge lines, stars and drifting sparks.
SceneSpec neonScene(String id) {
  final (a, b) = neonPalette[id] ?? neonPalette['menu']!;
  const horizon = 0.6;
  return SceneSpec(
    focusY: 0.0,
    topShade: 0.0,
    bottomShade: 0.12,
    layers: [
      Layer.still((c, s) {
        fillSky(c, s, [mix(const Color(0xFF040616), a, 0.1), mix(const Color(0xFF080B24), b, 0.12), mix(const Color(0xFF0D1030), b, 0.28)], const [0.0, 0.55, horizon]);
        c.drawRect(Rect.fromLTRB(0, s.height * horizon, s.width, s.height), Paint()..color = const Color(0xFF05071A));
        // neon sun ring and horizon glow rings (flat)
        final o = Offset(s.width * 0.5, s.height * horizon);
        for (var i = 0; i < 4; i++) {
          c.drawCircle(o, s.width * (0.22 + i * 0.07), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = b.withValues(alpha: 0.32 - i * 0.07));
        }
        c.drawCircle(o, s.width * 0.19, Paint()..color = b.withValues(alpha: 0.14));
        c.save();
        c.clipRect(Rect.fromLTRB(0, 0, s.width, s.height * horizon));
        // outlined ridge lines
        for (var k = 0; k < 2; k++) {
          final r = Ridge(s, y: horizon - 0.04 - k * 0.05, amp: 0.035 + k * 0.01, freq: 2.0 + k, seed: 7 + k, octaves: 2, sharp: 0.4);
          c.drawPath(r.fill(s.height * horizon), Paint()..color = const Color(0xFF060820));
          c.drawPath(r.edge(), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = (k == 0 ? a : b).withValues(alpha: 0.7 - k * 0.25));
        }
        c.restore();
        c.drawLine(Offset(0, s.height * horizon), Offset(s.width, s.height * horizon), Paint()
          ..strokeWidth = 2
          ..color = a);
        // perspective grid: fixed vertical fan
        final vp = Offset(s.width / 2, s.height * horizon);
        for (var i = -12; i <= 12; i++) {
          c.drawLine(vp, Offset(s.width / 2 + i * s.width * 0.34, s.height * 1.02), Paint()
            ..strokeWidth = 1
            ..color = a.withValues(alpha: 0.28));
        }
      }, driftX: 0.004, driftCycles: 2),
      Layer.live((c, s, k) {
        // horizontal grid lines flowing towards the viewer
        final y0 = s.height * horizon, h = s.height - y0;
        for (var i = 0; i < 10; i++) {
          final t = (i + k.saw(2)) / 10;
          final y = y0 + h * math.pow(t, 2.2);
          c.drawLine(Offset(0, y), Offset(s.width, y), Paint()
            ..strokeWidth = 1
            ..color = a.withValues(alpha: 0.12 + 0.3 * t));
        }
      }),
      Layer.live((c, s, k) {
        paintStars(c, s, k, count: 70, seed: 3, region: const Rect.fromLTRB(0, 0, 1, 0.55), color: const Color(0xFFDDE8FF), twinkleCycles: 8);
        paintParticles(c, s, k, ParticleSpec(count: 18, seed: 9, colors: [a, b], minSize: 1.2, maxSize: 2.4, flow: const Offset(0, -0.12), cycles: 1, spread: 1, wander: 10, twinkle: 0.6, shape: ParticleShape.glow, region: const Rect.fromLTRB(0, 0.1, 1, 1), haloScale: 2.6, opacity: 0.8));
      }),
    ],
  );
}
