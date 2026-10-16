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

const _ink = Color(0xFF05071A);

Layer _base(Color a, Color b, {double horizon = 0.6, bool floor = true}) => Layer.still((c, s) {
      fillSky(c, s, [mix(const Color(0xFF040616), a, 0.1), mix(const Color(0xFF080B24), b, 0.12), mix(const Color(0xFF0D1030), b, 0.26)], [0.0, 0.55, horizon.clamp(0.6, 0.95)]);
      if (floor) c.drawRect(Rect.fromLTRB(0, s.height * horizon, s.width, s.height), Paint()..color = _ink);
    });

Layer _stars(Color col, {int count = 70, double h = 0.55}) => Layer.live((c, s, k) => paintStars(c, s, k, count: count, seed: 3, region: Rect.fromLTRB(0, 0, 1, h), color: col, twinkleCycles: 8));

Layer _sparks(Color a, Color b, {Offset flow = const Offset(0, -0.12), int count = 18, ParticleShape shape = ParticleShape.glow}) => Layer.live((c, s, k) => paintParticles(c, s, k, ParticleSpec(count: count, seed: 9, colors: [a, b], minSize: 1.2, maxSize: 2.4, flow: flow, cycles: 1, spread: 1, wander: 10, twinkle: 0.6, shape: shape, region: const Rect.fromLTRB(0, 0.05, 1, 1), haloScale: 2.6, opacity: 0.8)));

Paint _line(Color col, [double w = 1.4, double al = 1]) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = col.withValues(alpha: al);

void _horizon(Canvas c, Size s, double h, Color a) => c.drawLine(Offset(0, s.height * h), Offset(s.width, s.height * h), _line(a, 2));

Path _wavePath(Size s, double y, double amp, int f1, int f2, double ph) {
  final p = Path();
  for (var i = 0; i <= 60; i++) {
    final x = s.width * i / 60;
    final t = tau * i / 60;
    final yy = s.height * y - amp * s.height * 0.5 * (0.7 * math.sin(t * f1 + ph) + 0.3 * math.sin(t * f2 + ph * 2.1));
    i == 0 ? p.moveTo(x, yy) : p.lineTo(x, yy);
  }
  return p;
}

Layer _ridgeLines(Color a, Color b, {double y = 0.56, int n = 2, double amp = 0.04}) => Layer.still((c, s) {
      for (var k = n - 1; k >= 0; k--) {
        final line = _wavePath(s, y - k * 0.04, amp * (1 - k * 0.15), 1 + k, 3 + k, 1.3 + k);
        final fill = Path.from(line)
          ..lineTo(s.width, s.height * y + 6)
          ..lineTo(0, s.height * y + 6)
          ..close();
        c.drawPath(fill, Paint()..color = const Color(0xFF060820));
        c.drawPath(line, _line(k == 0 ? a : b, 1.6, 0.85 - k * 0.3));
      }
    });

Layer _bigRing(Offset at, Color col, {double r = 0.2, int rings = 4}) => Layer.still((c, s) {
      final o = Offset(s.width * at.dx, s.height * at.dy);
      for (var i = 0; i < rings; i++) {
        c.drawCircle(o, s.width * (r + i * 0.07), _line(col, 1.4, 0.34 - i * 0.07));
      }
      c.drawCircle(o, s.width * (r - 0.03), Paint()..color = col.withValues(alpha: 0.14));
    });

Layer _synthGrid(Color a, {double horizon = 0.6}) => Layer.still((c, s) {
      _horizon(c, s, horizon, a);
      final vp = Offset(s.width / 2, s.height * horizon);
      for (var i = -12; i <= 12; i++) {
        c.drawLine(vp, Offset(s.width / 2 + i * s.width * 0.34, s.height * 1.02), _line(a, 1, 0.28));
      }
    });

Layer _gridFlow(Color a, {double horizon = 0.6}) => Layer.live((c, s, k) {
      final y0 = s.height * horizon, h = s.height - y0;
      for (var i = 0; i < 10; i++) {
        final t = (i + k.saw(2)) / 10;
        c.drawLine(Offset(0, y0 + h * math.pow(t, 2.2)), Offset(s.width, y0 + h * math.pow(t, 2.2)), _line(a, 1, 0.12 + 0.3 * t));
      }
    });

/// A simple tiered outline pine (symmetric).
void _pine(Canvas c, Offset base, double h, Color edge) {
  final p = Path()..moveTo(base.dx, base.dy - h);
  const tiers = 3;
  double ty(int i) => base.dy - h * 0.12 - h * 0.88 * (tiers - 1 - i) / tiers * 0.78;
  for (var i = 0; i < tiers; i++) {
    final w = h * (0.14 + i * 0.07);
    p.lineTo(base.dx + w, ty(i));
    p.lineTo(base.dx + w * 0.45, ty(i));
  }
  p.lineTo(base.dx + h * 0.04, base.dy);
  p.lineTo(base.dx - h * 0.04, base.dy);
  for (var i = tiers - 1; i >= 0; i--) {
    final w = h * (0.14 + i * 0.07);
    p.lineTo(base.dx - w * 0.45, ty(i));
    p.lineTo(base.dx - w, ty(i));
  }
  p.close();
  c.drawPath(p, Paint()..color = const Color(0xFF060820));
  c.drawPath(p, _line(edge, 1.2, 0.75));
}

Layer _outlineForest(Color a, Color b, {double y = 0.64}) => Layer.still((c, s) {
      final r = rng(4);
      for (var row = 0; row < 3; row++) {
        var x = -10.0;
        while (x < s.width + 10) {
          _pine(c, Offset(x, s.height * (y + row * 0.05)), s.height * (0.1 + row * 0.04 + r.nextDouble() * 0.04), row == 1 ? b : a);
          x += s.width * (0.1 + r.nextDouble() * 0.06);
        }
      }
    }, driftX: 0.01, driftCycles: 2, sway: 0.004, swayCycles: 5);

SceneSpec _spec(List<Layer> l, {double focusY = 0}) => SceneSpec(focusY: focusY, topShade: 0.0, bottomShade: 0.1, layers: l);

/// Dark, sleek animated backdrops. Every world has its own look and motion;
/// only outlines, flat glows and lines - no illustration.
SceneSpec neonScene(String id) {
  final (a, b) = neonPalette[id] ?? neonPalette['menu']!;
  const white = Color(0xFFDDE8FF);
  switch (id) {
    case 'forest':
      return _spec([_base(a, b), _stars(white, count: 40, h: 0.4), _bigRing(const Offset(0.7, 0.22), b, r: 0.12, rings: 3), _outlineForest(a, b), _sparks(const Color(0xFFFFF59A), a, count: 28)]);
    case 'desert':
      return _spec([
        _base(a, b, horizon: 0.58),
        _bigRing(const Offset(0.5, 0.5), a, r: 0.22, rings: 5),
        _ridgeLines(a, b, y: 0.62, n: 3, amp: 0.03),
        Layer.live((c, s, k) {
          for (var i = 0; i < 14; i++) {
            final y = s.height * (0.66 + (i * 0.37 % 1) * 0.3);
            final x = ((k.saw(2) + i * 0.173) % 1.0) * (s.width + 120) - 60;
            c.drawLine(Offset(x, y), Offset(x + 40 + (i % 3) * 20, y + 1), _line(a, 1.2, 0.35));
          }
        }),
        _sparks(a, b, flow: const Offset(0.1, -0.05)),
      ]);
    case 'coral':
    case 'tropical':
    case 'deepsea':
      final deep = id == 'deepsea';
      return _spec([
        _base(a, b, horizon: 0.9, floor: false),
        if (id == 'tropical') _bigRing(const Offset(0.5, 0.42), b, r: 0.16, rings: 3),
        Layer.live((c, s, k) {
          for (var i = 0; i < 9; i++) {
            final y0 = s.height * (0.45 + i * 0.06);
            final p = Path()..moveTo(-4, y0);
            for (var x = 0.0; x <= s.width + 8; x += 10) {
              p.lineTo(x, y0 + math.sin(x * 0.03 + tau * k.saw(3 + i % 2) * (i.isEven ? 1 : -1) + i) * (4 + i * 0.7));
            }
            c.drawPath(p, _line(i.isEven ? a : b, 1.4, 0.18 + i * 0.04));
          }
        }),
        if (deep)
          Layer.live((c, s, k) {
            for (var j = 0; j < 4; j++) {
              final cx = s.width * (0.2 + j * 0.2) + math.sin(tau * (k.u * 3 + j)) * 14;
              final cy = s.height * (0.18 + (j % 2) * 0.18) + math.cos(tau * (k.u * 2 + j)) * 10;
              final rr = s.width * (0.07 + (j % 3) * 0.02) * (1 + 0.1 * math.sin(tau * (k.u * 12 + j)));
              c.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: rr), math.pi, math.pi, false, _line(j.isEven ? a : b, 1.8, 0.9));
              c.drawCircle(Offset(cx, cy), rr * 1.8, Paint()..color = (j.isEven ? a : b).withValues(alpha: 0.07));
              for (var t = -2; t <= 2; t++) {
                final tp = Path()..moveTo(cx + t * rr * 0.4, cy);
                for (var q = 1; q <= 6; q++) {
                  tp.lineTo(cx + t * rr * 0.4 + math.sin(q * 0.9 + tau * k.saw(6) + t) * 5, cy + q * rr * 0.35);
                }
                c.drawPath(tp, _line(j.isEven ? a : b, 1, 0.45));
              }
            }
          }),
        _sparks(a, b, flow: const Offset(0, -0.2), count: 26, shape: ParticleShape.bubble),
      ]);
    case 'cosmic':
      return _spec([
        _base(a, b, horizon: 0.95, floor: false),
        Layer.live((c, s, k) {
          final o = Offset(s.width * 0.5, s.height * 0.42);
          for (var i = 0; i < 70; i++) {
            final ang = i * 2.399;
            final t = (k.saw(2) + i * 0.0617) % 1.0;
            final r0 = s.width * (0.04 + 0.9 * t * t);
            final r1 = r0 + s.width * 0.05 * t * t * t + 2;
            c.drawLine(o + Offset(math.cos(ang), math.sin(ang)) * r0, o + Offset(math.cos(ang), math.sin(ang)) * r1, _line(i.isEven ? a : white, 1.4, 0.8 * t));
          }
        }),
        _bigRing(const Offset(0.5, 0.42), b, r: 0.1, rings: 3),
        _sparks(a, b, count: 22),
      ]);
    case 'frozen':
    case 'moonlit':
      final moon = id == 'moonlit';
      return _spec([
        _base(a, b),
        _stars(white, count: 90, h: 0.5),
        if (moon) _bigRing(const Offset(0.66, 0.2), white, r: 0.1, rings: 4),
        Layer.live((c, s, k) {
          if (moon) return;
          for (var i = 0; i < 3; i++) {
            final p = Path()..moveTo(-4, s.height * 0.5);
            for (var x = 0.0; x <= s.width + 8; x += 8) {
              p.lineTo(x, s.height * (0.22 + 0.1 * i) + math.sin(x * 0.012 + tau * k.saw(2) + i * 1.7) * 26);
            }
            c.drawPath(p, _line(i.isEven ? a : b, 6, 0.1));
            c.drawPath(p, _line(i.isEven ? a : b, 1.4, 0.7));
          }
        }),
        _ridgeLines(a, b, y: 0.6),
        if (moon) _outlineForest(a, b, y: 0.66) else _sparks(white, a, flow: const Offset(0.05, 0.12), count: 40, shape: ParticleShape.snow),
        if (moon) _sparks(a, b, count: 24),
      ]);
    case 'volcanic':
      return _spec([
        _base(a, b, horizon: 0.64),
        _ridgeLines(a, b, y: 0.6, n: 2, amp: 0.06),
        Layer.still((c, s) {
          _horizon(c, s, 0.64, a);
          final r = rng(5);
          for (var i = 0; i < 9; i++) {
            final x = s.width * r.nextDouble();
            final p = Path()..moveTo(x, s.height * 0.64);
            var o = Offset(x, s.height * 0.64);
            for (var q = 0; q < 6; q++) {
              o += Offset((r.nextDouble() - 0.5) * 36, s.height * 0.06);
              p.lineTo(o.dx, o.dy);
            }
            c.drawPath(p, _line(a, 2, 0.8));
          }
        }, driftX: 0.008),
        _sparks(a, b, flow: const Offset(0.02, -0.3), count: 34, shape: ParticleShape.ember),
      ]);
    case 'jungle':
    case 'cyber':
      final city = id == 'cyber';
      return _spec([
        _base(a, b),
        if (city)
          Layer.still((c, s) {
            final r = rng(8);
            for (var layer = 0; layer < 2; layer++) {
              var x = -10.0;
              while (x < s.width + 10) {
                final w = s.width * (0.05 + r.nextDouble() * 0.07);
                final h = s.height * (0.08 + r.nextDouble() * (layer == 0 ? 0.3 : 0.18));
                final rect = Rect.fromLTWH(x, s.height * 0.62 - h, w, h);
                c.drawRect(rect, Paint()..color = const Color(0xFF060820));
                c.drawRect(rect, _line(layer == 0 ? a : b, 1.2, 0.75));
                for (var wy = rect.top + 8; wy < rect.bottom - 4; wy += 9) {
                  if (r.nextDouble() < 0.4) c.drawRect(Rect.fromLTWH(x + 4, wy, w - 8, 2), Paint()..color = (r.nextBool() ? a : b).withValues(alpha: 0.6));
                }
                x += w + 2;
              }
            }
            _horizon(c, s, 0.62, a);
          }, driftX: 0.006)
        else
          _outlineForest(a, b, y: 0.7),
        Layer.live((c, s, k) {
          for (var i = 0; i < 26; i++) {
            final x = s.width * ((i * 0.381) % 1.0);
            final t = (k.saw(3 + i % 3) + i * 0.11) % 1.0;
            final y = t * (s.height + 60) - 30;
            c.drawLine(Offset(x, y), Offset(x - 2, y + 22 + i % 4 * 6), _line(i.isEven ? a : b, 1.2, 0.35 * (1 - t * 0.4)));
          }
        }),
        _sparks(a, b),
      ]);
    case 'countryside':
      return _spec([
        _base(a, b),
        _bigRing(const Offset(0.75, 0.25), a, r: 0.09, rings: 3),
        _ridgeLines(a, b, y: 0.62, n: 3, amp: 0.035),
        Layer.live((c, s, k) {
          final o = Offset(s.width * 0.27, s.height * 0.57);
          c.drawLine(o, o + Offset(0, s.height * 0.06), _line(b, 2, 0.9));
          for (var i = 0; i < 4; i++) {
            final ang = tau * (k.saw(6) + i / 4);
            c.drawLine(o, o + Offset(math.cos(ang), math.sin(ang)) * s.width * 0.09, _line(a, 2, 0.9));
          }
        }),
        _gridFlow(b, horizon: 0.64),
        _sparks(a, b, flow: const Offset(0.1, -0.06)),
      ]);
    case 'candy':
    case 'fairytale':
      return _spec([
        _base(a, b, horizon: 0.95, floor: false),
        Layer.live((c, s, k) {
          final r = rng(id == 'candy' ? 3 : 4);
          for (var i = 0; i < 16; i++) {
            final x = s.width * r.nextDouble();
            final rad = s.width * (0.03 + r.nextDouble() * 0.09);
            final t = (k.saw(1 + i % 2) + r.nextDouble()) % 1.0;
            final y = s.height * (1.1 - t * 1.25);
            final col = i.isEven ? a : b;
            c.drawCircle(Offset(x + math.sin(t * 6 + i) * 12, y), rad, _line(col, 1.4, 0.5));
            c.drawCircle(Offset(x + math.sin(t * 6 + i) * 12, y), rad, Paint()..color = col.withValues(alpha: 0.06));
          }
        }),
        if (id == 'fairytale') _ridgeLines(a, b, y: 0.8, n: 2, amp: 0.03),
        _sparks(a, b, count: 24, shape: ParticleShape.spark),
      ]);
    case 'autumn':
    case 'sakura':
      return _spec([
        _base(a, b),
        _bigRing(const Offset(0.5, 0.36), a, r: 0.14, rings: 3),
        _ridgeLines(a, b, y: 0.6, n: 2, amp: 0.05),
        _synthGrid(b),
        _gridFlow(b),
        Layer.live((c, s, k) => paintParticles(c, s, k, ParticleSpec(count: 36, seed: 6, colors: [a, b], minSize: 2, maxSize: 3.6, flow: const Offset(0.12, 0.3), cycles: 2, spread: 2, wander: 14, shape: id == 'autumn' ? ParticleShape.leaf : ParticleShape.petal, region: const Rect.fromLTRB(0, 0, 1, 1), opacity: 0.85, spin: 2))),
      ]);
    case 'ruins':
    case 'treasure':
      return _spec([
        _base(a, b),
        Layer.still((c, s) {
          for (var i = 0; i < 6; i++) {
            final x = s.width * (0.08 + i * 0.17);
            final h = s.height * (0.18 + (i % 3) * 0.1);
            final rect = Rect.fromLTWH(x, s.height * 0.62 - h, s.width * 0.05, h);
            c.drawRect(rect, Paint()..color = const Color(0xFF060820));
            c.drawRect(rect, _line(i.isEven ? a : b, 1.3, 0.7));
          }
          _horizon(c, s, 0.62, a);
        }, driftX: 0.008),
        Layer.live((c, s, k) {
          final o = Offset(s.width * 0.5, s.height * 0.62);
          for (var i = 0; i < 5; i++) {
            final t = (k.saw(2) + i / 5) % 1.0;
            c.drawOval(Rect.fromCenter(center: o, width: s.width * (0.2 + t * 1.4), height: s.width * (0.05 + t * 0.35)), _line(a, 1.4, 0.5 * (1 - t)));
          }
        }),
        _sparks(a, b, flow: const Offset(0, -0.08), count: 30, shape: ParticleShape.spark),
      ]);
    case 'crystal':
      return _spec([
        _base(a, b),
        Layer.live((c, s, k) {
          final r = rng(11);
          for (var i = 0; i < 12; i++) {
            final cx = s.width * r.nextDouble();
            final cy = s.height * (0.1 + r.nextDouble() * 0.7) + math.sin(tau * (k.u * 3 + i)) * 8;
            final sz = s.width * (0.04 + r.nextDouble() * 0.07);
            final rot = tau * (k.saw(2) * (i.isEven ? 1 : -1) + r.nextDouble());
            final path = Path();
            for (var q = 0; q < 6; q++) {
              final aa = rot + q * tau / 6;
              final pt = Offset(cx + math.cos(aa) * sz, cy + math.sin(aa) * sz * 1.4);
              q == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
            }
            path.close();
            c.drawPath(path, Paint()..color = (i.isEven ? a : b).withValues(alpha: 0.08));
            c.drawPath(path, _line(i.isEven ? a : b, 1.5, 0.8));
          }
        }),
        _sparks(a, b, count: 26, shape: ParticleShape.spark),
      ]);
    case 'skyislands':
      return _spec([
        _base(a, b, horizon: 0.95, floor: false),
        _stars(white, count: 40, h: 0.5),
        Layer.live((c, s, k) {
          for (var i = 0; i < 4; i++) {
            final w = s.width * (0.28 + (i % 2) * 0.12);
            final x = s.width * (0.2 + i * 0.22);
            final y = s.height * (0.2 + i * 0.16) + math.sin(tau * (k.u * 3 + i * 0.4)) * 8;
            final top = Path()..moveTo(x - w / 2, y)..quadraticBezierTo(x, y - w * 0.12, x + w / 2, y);
            final under = Path()
              ..moveTo(x - w / 2, y)
              ..quadraticBezierTo(x - w * 0.2, y + w * 0.5, x, y + w * 0.65)
              ..quadraticBezierTo(x + w * 0.2, y + w * 0.5, x + w / 2, y);
            c.drawPath(under, Paint()..color = const Color(0xFF060820));
            c.drawPath(under, _line(i.isEven ? a : b, 1.4, 0.75));
            c.drawPath(top, _line(i.isEven ? a : b, 2, 0.95));
          }
        }),
        _sparks(a, b, count: 22),
      ]);
    default:
      const horizon = 0.6;
      return _spec([
        _base(a, b),
        _bigRing(const Offset(0.5, horizon), b),
        _ridgeLines(a, b, y: horizon - 0.04),
        _synthGrid(a),
        _gridFlow(a),
        _stars(white),
        _sparks(a, b),
      ]);
  }
}
