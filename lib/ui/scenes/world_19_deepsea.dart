import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Bioluminescent Deep Sea in flat, graphic 2D: dark blue water, giant lantern
// jellyfish pulsing and trailing waving tentacles, a faint whale far away,
// dark seabed rock with glowing coral and plankton snow. Light comes from the
// upper left (surface rays); every lit edge is on the upper left.

// palette
const _w0 = Color(0xFF020617), _w1 = Color(0xFF04204A), _w2 = Color(0xFF07396B), _wTop = Color(0xFF0A4A86);
const _cyan = Color(0xFF38F2FF), _turq = Color(0xFF3CF0C8), _purple = Color(0xFFA66BFF), _blue = Color(0xFF2F7BFF);
const _rock = Color(0xFF050B1F), _rockMid = Color(0xFF0A1C47), _rockFar = Color(0xFF0D3166);
const _plankton = Color(0xFF9FE9FF);

SceneSpec deepseaScene() => SceneSpec(
      focusY: -0.35,
      topShade: 0.1,
      bottomShade: 0.16,
      layers: [
        Layer.still(_water),
        Layer.still(_rays, sway: 0.03, swayCycles: 2, pivot: Alignment.topLeft, driftX: 0.01, driftCycles: 2),
        Layer.still(_farLights, driftX: 0.006, driftCycles: 2, driftPhase: 0.3),
        Layer.live(_creatures),
        Layer.still(_farSeabed, driftX: 0.008, driftCycles: 2),
        Layer.live(_jellies),
        Layer.still(_midSeabed, driftX: 0.014, driftCycles: 2, driftPhase: 0.05),
        Layer.live(_plankton1),
        Layer.still(_nearSeabed, driftX: _nearDrift, driftCycles: 2, driftPhase: _nearPhase),
        Layer.live(_coralTips),
        Layer.live(_jelliesLow),
        Layer.still(_foreKelp, driftX: 0.04, driftCycles: 2, driftPhase: 0.2, sway: 0.03, swayCycles: 5, pivot: Alignment.bottomCenter),
        Layer.live(_plankton2),
      ],
    );

const double _nearDrift = 0.022, _nearPhase = 0.1;

// ---------------------------------------------------------------- water & light

void _water(Canvas c, Size s) {
  fillSky(c, s, const [_wTop, Color(0xFF05295A), _w1, Color(0xFF031230), _w0, Color(0xFF031636), Color(0xFF052B5C), _w2], const [0.0, 0.09, 0.24, 0.42, 0.56, 0.74, 0.9, 1.0]);
}

void _rays(Canvas c, Size s) {
  final w = s.width, h = s.height;
  paintRays(c, Offset(-w * 0.12, -h * 0.1), length: h * 1.05, centerAngle: 1.12, spread: 0.9, count: 6, color: _cyan, opacity: 0.12, seed: 9, minWidth: 0.07, maxWidth: 0.16);
  paintRays(c, Offset(w * 0.35, -h * 0.12), length: h * 0.8, centerAngle: 1.2, spread: 0.55, count: 3, color: _turq, opacity: 0.05, seed: 3, minWidth: 0.05, maxWidth: 0.1);
}

// ---------------------------------------------------------------- distant glow life

void _farLights(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(19);
  // far dim jellies, tiny flat lanterns
  const cols = [_purple, _blue, _cyan];
  for (var i = 0; i < 7; i++) {
    final o = Offset(w * (0.04 + r.nextDouble() * 0.92), h * (0.1 + r.nextDouble() * 0.5));
    final jw = w * (0.035 + r.nextDouble() * 0.035);
    _farJelly(c, o, jw, cols[i % 3], 0.2 + r.nextDouble() * 0.12);
  }
  // distant lights in clusters
  for (var g = 0; g < 5; g++) {
    final cx = w * (0.1 + r.nextDouble() * 0.8), cy = h * (0.12 + r.nextDouble() * 0.5);
    for (var i = 0; i < 6; i++) {
      final o = Offset(cx + (r.nextDouble() - 0.5) * w * 0.14, cy + (r.nextDouble() - 0.5) * h * 0.04);
      c.drawCircle(o, 3.2, Paint()..color = alpha(_cyan, 0.08));
      c.drawCircle(o, 1.3, Paint()..color = alpha(_plankton, 0.5));
    }
  }
}

void _farJelly(Canvas c, Offset o, double w, Color col, double a) {
  final bell = _bellPath(w, w * 0.55, 5).shift(o);
  final tent = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = alpha(col, a * 0.8);
  for (var i = 0; i < 4; i++) {
    final x = o.dx + (i - 1.5) * w * 0.22;
    c.drawPath(smoothPath([Offset(x, o.dy), Offset(x + 3, o.dy + w * 0.7), Offset(x - 3, o.dy + w * 1.3), Offset(x + 2, o.dy + w * 1.9)]), tent);
  }
  c.drawPath(bell, Paint()..color = alpha(col, a));
  c.drawPath(bell.shift(Offset(-w * 0.05, -w * 0.05)), Paint()..color = alpha(Colors.white, a * 0.12));
}

// ---------------------------------------------------------------- creatures (whale, glow fish)

void _creatures(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  // a huge faint whale gliding left to right, once per loop
  final t = k.saw(1);
  final wl = w * 0.85;
  final x = -wl * 0.7 + t * (w + wl * 1.4);
  final y = h * 0.47 + math.sin(tau * k.u * 3) * h * 0.012;
  c
    ..save()
    ..translate(x, y)
    ..scale(wl / 400);
  final flap = k.sine(10) * 0.5;
  final body = Path()
    ..moveTo(190, -4)
    ..cubicTo(190, -44, 120, -62, 40, -60)
    ..cubicTo(-60, -58, -130, -30, -190, -16 + 14 * flap)
    ..lineTo(-196, -16 + 14 * flap)
    ..cubicTo(-232, -30 + 24 * flap, -250, -44 + 26 * flap, -262, -40 + 28 * flap)
    ..cubicTo(-256, -22 + 20 * flap, -246, -8 + 14 * flap, -226, 0 + 10 * flap)
    ..cubicTo(-246, 12 + 6 * flap, -258, 26 + 4 * flap, -262, 40 + 6 * flap)
    ..cubicTo(-246, 36 + 8 * flap, -226, 26 + 6 * flap, -196, 14 + 6 * flap)
    ..cubicTo(-130, 32, -60, 50, 30, 52)
    ..cubicTo(120, 52, 190, 34, 190, -4)
    ..close();
  c.drawPath(body, Paint()..color = alpha(_blue, 0.15));
  c.drawPath(body.shift(const Offset(0, 8)), Paint()..color = alpha(_w0, 0.18));
  // flipper
  final fl = Path()
    ..moveTo(60, 38)
    ..cubicTo(20, 60, -10, 84 + 8 * flap, -34, 92 + 10 * flap)
    ..cubicTo(-14, 70, 10, 52, 30, 40)
    ..close();
  c.drawPath(fl, Paint()..color = alpha(_blue, 0.15));
  // belly lights
  for (var i = 0; i < 9; i++) {
    final px = 150 - i * 26.0, py = 34 - math.sin(i * 0.3) * 4 + 4;
    final a = 0.25 + 0.3 * k.pulse(12 + i % 3, i * 0.13);
    c.drawCircle(Offset(px, py), 3.2, Paint()..color = alpha(_cyan, a * 0.4));
    c.drawCircle(Offset(px, py), 1.5, Paint()..color = alpha(_plankton, a + 0.2));
  }
  c.restore();

  // small glowing fish schools
  for (var g = 0; g < 3; g++) {
    final dir = g == 1 ? -1.0 : 1.0;
    final tt = k.saw(g == 0 ? 2 : (g == 1 ? 3 : 1), g * 0.37);
    final gx = dir > 0 ? -0.2 * w + tt * 1.4 * w : 1.2 * w - tt * 1.4 * w;
    final gy = h * (g == 0 ? 0.47 : (g == 1 ? 0.2 : 0.62)) + math.sin(tau * (k.u * (4 + g))) * 8;
    final col = g == 1 ? _turq : (g == 2 ? _purple : _cyan);
    for (var i = 0; i < 6; i++) {
      final o = Offset(gx - dir * (i % 3) * 16 * (w / 390), gy + (i ~/ 3) * 12 + math.sin(tau * (k.u * 6 + i * 0.2)) * 3);
      final f = 3.6 * w / 390;
      c.drawOval(Rect.fromCenter(center: o, width: f * 2.4, height: f), Paint()..color = alpha(col, 0.75));
      final tail = Path()
        ..moveTo(o.dx - dir * f * 1.0, o.dy)
        ..lineTo(o.dx - dir * f * 2.0, o.dy - f * 0.7)
        ..lineTo(o.dx - dir * f * 2.0, o.dy + f * 0.7)
        ..close();
      c.drawPath(tail, Paint()..color = alpha(col, 0.75));
    }
  }
}

// ---------------------------------------------------------------- jellyfish

Path _bellPath(double bw, double bh, int lobes) {
  final p = Path()
    ..moveTo(-bw / 2, 0)
    ..cubicTo(-bw / 2, -bh * 1.36, bw / 2, -bh * 1.36, bw / 2, 0);
  final lob = bh * 0.14;
  for (var i = 0; i < lobes; i++) {
    final x0 = bw / 2 - bw * i / lobes, x1 = bw / 2 - bw * (i + 1) / lobes;
    p.quadraticBezierTo((x0 + x1) / 2, lob * 2, x1, 0);
  }
  p.close();
  return p;
}

class _J {
  const _J(this.x, this.y, this.w, this.cyc, this.ph, this.bell, this.shade, this.lit, this.rim, this.arm, this.tent, {this.a = 1, this.tl = 2.2, this.n = 9, this.dx = 14, this.dy = 18});
  final double x, y, w; // fractions of the screen
  final int cyc;
  final double ph;
  final Color bell, shade, lit, rim, arm, tent;
  final double a, tl;
  final int n;
  static const wave = 6, dcyc = 2;
  final double dx, dy;
}

const _js = [
  // far, small, dim
  _J(0.07, 0.45, 0.2, 14, 0.3, Color(0xFF3568D8), Color(0xFF1C3C96), Color(0xFF5D93FF), Color(0xFF8CC4FF), Color(0xFF6C9BFF), Color(0xFF4F86FF), a: 0.42, tl: 1.8, n: 6, dx: 8, dy: 10),
  _J(0.9, 0.36, 0.17, 12, 0.6, Color(0xFF5E48C8), Color(0xFF362890), Color(0xFF8A6BFF), Color(0xFFB9A2FF), Color(0xFF8E75F0), Color(0xFF7B63E0), a: 0.6, tl: 2.1, n: 6, dx: 8, dy: 10),
  // hero, top right
  _J(0.68, 0.225, 0.46, 10, 0.0, Color(0xFF7A55E8), Color(0xFF4528B0), Color(0xFFB693FF), Color(0xFF63F6FF), Color(0xFFD0B4FF), Color(0xFF8AF6FF), a: 1, tl: 2.1, n: 10, dx: 16, dy: 14),
  // upper left, small turquoise
  _J(0.2, 0.2, 0.22, 12, 0.4, Color(0xFF1FB6B0), Color(0xFF0E7C86), Color(0xFF58F0D8), Color(0xFFB4FFF0), Color(0xFF7FF4E0), Color(0xFF4DE8D0), a: 1, tl: 2.4, n: 7, dx: 12, dy: 12),
  // bottom, cyan medium
  _J(0.76, 0.855, 0.3, 15, 0.7, Color(0xFF1C8FE0), Color(0xFF0F55B0), Color(0xFF5CD0FF), Color(0xFF9CFBFF), Color(0xFF7CDCFF), Color(0xFF38F2FF), a: 1, tl: 0.9, n: 8, dx: 10, dy: 10),
  // lower left purple-ish
  _J(0.2, 0.86, 0.2, 12, 0.15, Color(0xFF8A4FE0), Color(0xFF5330A8), Color(0xFFC09AFF), Color(0xFFFF9EF2), Color(0xFFD7B2FF), Color(0xFFB27BFF), a: 0.9, tl: 0.9, n: 6, dx: 8, dy: 8),
];

void _jellies(Canvas c, Size s, Clock k) {
  for (var i = 0; i < 4; i++) {
    _jelly(c, s, k, _js[i], i);
  }
}

void _jelliesLow(Canvas c, Size s, Clock k) {
  for (var i = 4; i < _js.length; i++) {
    _jelly(c, s, k, _js[i], i);
  }
}

void _jelly(Canvas c, Size s, Clock k, _J j, int idx) {
  final k0 = s.width / 390;
  final w = j.w * s.width;
  final p = k.sine(j.cyc, j.ph); // pulse: +1 contracted
  final bw = w * (1 - 0.09 * p), bh = w * 0.5 * (1 + 0.1 * p);
  final o = Offset(
    j.x * s.width + k.sine(_J.dcyc, j.ph) * j.dx * k0,
    j.y * s.height + k.sine(_J.dcyc + 1, j.ph + 0.2) * j.dy * k0 - p * w * 0.035,
  );
  final a = j.a;
  final ph = k.saw(_J.wave, j.ph);

  // flat halo rings
  c.drawCircle(o + Offset(0, -bh * 0.45), bw * 0.9, Paint()..color = alpha(j.rim, 0.045 * a));
  c.drawCircle(o + Offset(0, -bh * 0.45), bw * 0.68, Paint()..color = alpha(j.rim, 0.06 * a));

  // tentacles (thin, long, travelling wave) and oral arms (thick, short)
  final tp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final r = rng(idx * 13 + 5);
  const seg = 9;
  for (var t = 0; t < j.n; t++) {
    final fx = (t + 0.5) / j.n - 0.5; // -0.5..0.5 across the rim
    final len = w * j.tl * (0.75 + r.nextDouble() * 0.5);
    final amp = w * 0.045 * (0.7 + r.nextDouble() * 0.6);
    final off = r.nextDouble() * tau;
    final pts = <Offset>[];
    for (var m = 0; m <= seg; m++) {
      final u = m / seg;
      final wob = math.sin(tau * (u * 1.35 - ph) + off) * amp * math.pow(u, 0.8);
      pts.add(Offset(o.dx + fx * bw * 0.86 * (1 - 0.3 * u) + wob, o.dy + bh * 0.1 + u * len * (1 + 0.04 * p)));
    }
    tp
      ..strokeWidth = math.max(1.1, w * 0.012)
      ..color = alpha(j.tent, 0.55 * a);
    c.drawPath(smoothPath(pts), tp);
  }
  for (var t = 0; t < 4; t++) {
    final fx = (t - 1.5) * 0.17;
    final len = w * (0.5 + r.nextDouble() * 0.3);
    final off = r.nextDouble() * tau;
    final pts = <Offset>[];
    for (var m = 0; m <= 7; m++) {
      final u = m / 7;
      final wob = math.sin(tau * (u * 1.8 - ph) + off) * w * 0.05 * u;
      pts.add(Offset(o.dx + fx * bw + wob, o.dy + bh * 0.08 + u * len));
    }
    tp
      ..strokeWidth = math.max(1.8, w * 0.026)
      ..color = alpha(j.arm, 0.5 * a);
    c.drawPath(smoothPath(pts), tp);
    tp
      ..strokeWidth = math.max(0.9, w * 0.01)
      ..color = alpha(Colors.white, 0.2 * a);
    c.drawPath(smoothPath([for (final q in pts) q + Offset(-w * 0.008, 0)]), tp);
  }

  // bell: lit base, flat shade shifted over it (light from upper left)
  final bell = _bellPath(bw, bh, 6).shift(o);
  c.drawPath(bell, Paint()..color = j.lit.withValues(alpha: a));
  c
    ..save()
    ..clipPath(bell)
    ..drawPath(bell.shift(Offset(bw * 0.13, bh * 0.17)), Paint()..color = j.bell.withValues(alpha: a))
    ..drawPath(bell.shift(Offset(bw * 0.34, bh * 0.4)), Paint()..color = j.shade.withValues(alpha: a));
  // inner translucent dome and ribs
  final inner = _bellPath(bw * 0.7, bh * 0.66, 4).shift(o + Offset(bw * 0.02, -bh * 0.02));
  c.drawPath(inner, Paint()..color = alpha(Colors.white, 0.07 * a));
  final rib = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, w * 0.012)
    ..color = alpha(j.shade, 0.5 * a);
  for (var i = -3; i <= 3; i++) {
    final x = o.dx + i * bw * 0.125;
    c.drawPath(
        Path()
          ..moveTo(o.dx + i * bw * 0.02, o.dy - bh * 1.0)
          ..quadraticBezierTo(o.dx + i * bw * 0.115, o.dy - bh * 0.5, x, o.dy + bh * 0.06),
        rib);
  }
  c.restore();
  // glowing organs (horseshoe)
  for (var i = 0; i < 5; i++) {
    final an = math.pi * (0.15 + 0.7 * i / 4);
    final q = o + Offset(-math.cos(an) * bw * 0.17, -bh * 0.34 - math.sin(an) * bh * 0.17);
    c.drawCircle(q, w * 0.026, Paint()..color = alpha(j.rim, 0.95 * a));
  }
  // rim glow line along the scalloped lower edge + bright beads on it
  final rimPath = Path()..moveTo(o.dx - bw / 2, o.dy);
  const lobes = 6;
  final lob = bh * 0.14;
  for (var i = 0; i < lobes; i++) {
    final x0 = o.dx - bw / 2 + bw * i / lobes, x1 = o.dx - bw / 2 + bw * (i + 1) / lobes;
    rimPath.quadraticBezierTo((x0 + x1) / 2, o.dy + lob * 2, x1, o.dy);
  }
  c.drawPath(
      rimPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.8, w * 0.02)
        ..strokeCap = StrokeCap.round
        ..color = alpha(j.rim, 0.95 * a));
  for (var i = 0; i < lobes; i++) {
    final x = o.dx - bw / 2 + bw * (i + 0.5) / lobes;
    c.drawCircle(Offset(x, o.dy + lob), math.max(1.4, w * 0.014), Paint()..color = alpha(Colors.white, 0.9 * a));
  }
  // lit highlight slash, upper left
  final hl = Path()
    ..moveTo(o.dx - bw * 0.36, o.dy - bh * 0.42)
    ..quadraticBezierTo(o.dx - bw * 0.3, o.dy - bh * 0.85, o.dx - bw * 0.1, o.dy - bh * 0.98);
  c.drawPath(
      hl,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, w * 0.03)
        ..strokeCap = StrokeCap.round
        ..color = alpha(Colors.white, 0.45 * a));
}

// ---------------------------------------------------------------- seabed

void _litShape(Canvas c, Path p, Color body, Color lit, Offset shift) {
  c.drawPath(p, Paint()..color = lit);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(shift), Paint()..color = body)
    ..restore();
}

void _farSeabed(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final far = Ridge(s, y: 0.8, amp: 0.03, freq: 1.6, seed: 61, octaves: 2);
  flatRidge(c, far, _rockFar, light: const Color(0xFF16468E), band: 2.5);
  // distant rock towers
  for (final t in [(0.1, 0.7, 0.07), (0.88, 0.69, 0.08), (0.5, 0.76, 0.06)]) {
    final bx = w * t.$1, top = h * t.$2, tw = w * t.$3;
    final p = smoothPath([Offset(bx - tw * 1.3, h * 0.86), Offset(bx - tw * 0.75, top + h * 0.05), Offset(bx - tw * 0.3, top), Offset(bx + tw * 0.3, top + h * 0.012), Offset(bx + tw * 0.8, top + h * 0.06), Offset(bx + tw * 1.4, h * 0.86)], closed: true);
    _litShape(c, p, _rockFar, const Color(0xFF16468E), Offset(tw * 0.18, 2.5));
  }
  // faint far corals: small glowing dots on the far ridge
  final r = rng(44);
  for (var i = 0; i < 16; i++) {
    final x = r.nextDouble() * w;
    final y = far.yAt(x) + 2;
    final col = [_cyan, _purple, _turq][i % 3];
    final hh = 10 + r.nextDouble() * 14;
    c.drawPath(smoothPath([Offset(x, y), Offset(x + 2, y - hh * 0.6), Offset(x - 1, y - hh)]), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = alpha(col, 0.35));
    c.drawCircle(Offset(x - 1, y - hh), 2, Paint()..color = alpha(col, 0.8));
  }
}

void _midSeabed(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final mid = Ridge(s, y: 0.875, amp: 0.025, freq: 2.1, seed: 22, octaves: 2, tilt: 0.02);
  // side rock masses
  final left = smoothPath([Offset(-w * 0.2, h * 1.05), Offset(-w * 0.12, h * 0.66), Offset(w * 0.03, h * 0.6), Offset(w * 0.1, h * 0.7), Offset(w * 0.2, h * 0.8), Offset(w * 0.32, h * 0.9), Offset(w * 0.4, h * 1.05)], closed: true);
  _litShape(c, left, _rockMid, const Color(0xFF1B4C9C), Offset(5, 4));
  final right = smoothPath([Offset(w * 1.2, h * 1.05), Offset(w * 1.12, h * 0.7), Offset(w * 0.98, h * 0.64), Offset(w * 0.9, h * 0.72), Offset(w * 0.82, h * 0.8), Offset(w * 0.7, h * 0.9), Offset(w * 0.62, h * 1.05)], closed: true);
  _litShape(c, right, _rockMid, const Color(0xFF1B4C9C), Offset(5, 4));
  flatRidge(c, mid, _rockMid, light: const Color(0xFF1B4C9C), band: 3);
  // mid coral gardens (dimmer)
  _coralGarden(c, null, s, mid, 5, 9, h * 0.06, h * 0.11, dim: 0.5);
}

void _nearSeabed(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final near = Ridge(s, y: 0.93, amp: 0.02, freq: 1.7, seed: 8, octaves: 2, tilt: -0.015);
  // big foreground rocks left and right
  final bl = smoothPath([Offset(-w * 0.15, h * 1.1), Offset(-w * 0.12, h * 0.8), Offset(w * 0.0, h * 0.75), Offset(w * 0.12, h * 0.8), Offset(w * 0.2, h * 0.9), Offset(w * 0.3, h * 1.1)], closed: true);
  _litShape(c, bl, _rock, const Color(0xFF123A82), Offset(5, 4));
  final br = smoothPath([Offset(w * 1.15, h * 1.1), Offset(w * 1.12, h * 0.8), Offset(w * 1.0, h * 0.77), Offset(w * 0.9, h * 0.83), Offset(w * 0.82, h * 0.92), Offset(w * 0.72, h * 1.1)], closed: true);
  _litShape(c, br, _rock, const Color(0xFF123A82), Offset(5, 4));
  flatRidge(c, near, _rock, light: const Color(0xFF123A82), band: 3);
  final tips = <_Tip>[];
  _coralGarden(c, tips, s, near, 9, 6, h * 0.08, h * 0.15, dim: 1);
  _nearTips = tips;
  // seabed pebbles
  final r = rng(2);
  for (var i = 0; i < 18; i++) {
    final x = r.nextDouble() * w;
    final y = near.yAt(x) + 10 + r.nextDouble() * (h * 0.05);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 6 + r.nextDouble() * 8, height: 3 + r.nextDouble() * 3), Paint()..color = const Color(0xFF0A1A44));
  }
}

// ---------------------------------------------------------------- corals

class _Tip {
  const _Tip(this.p, this.r, this.c, this.ph);
  final Offset p;
  final double r, ph;
  final Color c;
}

List<_Tip> _nearTips = const [];

const _coralCols = [_cyan, _turq, _purple, _blue, Color(0xFFFF8AD8)];

void _coralGarden(Canvas c, List<_Tip>? tips, Size s, Ridge ground, int seed, int count, double hMin, double hMax, {required double dim}) {
  final r = rng(seed);
  final w = s.width;
  var x = -w * 0.03;
  var i = 0;
  while (x < w * 1.03) {
    final gh = hMin + r.nextDouble() * (hMax - hMin);
    final col = _coralCols[(i + seed) % _coralCols.length];
    final base = Offset(x, ground.yAt(x) + 4);
    final kind = r.nextInt(6);
    final body = mix(_rockMid, col, 0.3 * dim);
    final lit = mix(_rockMid, col, 0.58 * dim);
    switch (kind) {
      case 0:
      case 1:
        _branchCoral(c, tips, base, gh, r.nextInt(999), body, lit, col, dim);
      case 2:
      case 3:
        _fanCoral(c, tips, base, gh, r.nextInt(999), body, lit, col, dim);
      case 4:
        _tubeCoral(c, tips, base, gh * 0.8, r.nextInt(999), body, lit, col, dim);
      default:
        _orbPlant(c, tips, base, gh, r.nextInt(999), body, lit, col, dim);
    }
    x += w / count * (0.7 + r.nextDouble() * 0.7);
    i++;
  }
}

void _branchCoral(Canvas c, List<_Tip>? tips, Offset base, double h, int seed, Color body, Color lit, Color col, double dim) {
  final r = rng(seed);
  void branch(Offset o, double ang, double len, double wd, int depth) {
    final end = o + Offset(math.cos(ang), math.sin(ang)) * len;
    final mid = Offset.lerp(o, end, 0.5)! + Offset(math.cos(ang + 1.57), math.sin(ang + 1.57)) * len * (r.nextDouble() - 0.5) * 0.25;
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = wd
      ..color = body;
    c.drawPath(path, p);
    p
      ..strokeWidth = wd * 0.38
      ..color = lit;
    c.drawPath(path.shift(Offset(-wd * 0.2, -wd * 0.1)), p);
    if (depth <= 0) {
      tips?.add(_Tip(end, wd * 1.3 + h * 0.03, col, r.nextDouble()));
      c.drawCircle(end, wd * 0.9, Paint()..color = alpha(col, 0.95 * dim));
      return;
    }
    final kids = depth == 1 ? 2 : 2 + r.nextInt(2);
    for (var i = 0; i < kids; i++) {
      final spread = kids == 1 ? 0.0 : (i / (kids - 1) - 0.5) * 1.1;
      branch(end, ang + spread + (r.nextDouble() - 0.5) * 0.25, len * (0.68 + r.nextDouble() * 0.1), wd * 0.72, depth - 1);
    }
  }

  branch(base, -math.pi / 2 + (r.nextDouble() - 0.5) * 0.3, h * 0.36, h * 0.085, 2);
}

void _fanCoral(Canvas c, List<_Tip>? tips, Offset base, double h, int seed, Color body, Color lit, Color col, double dim) {
  final r = rng(seed);
  final n = 7;
  final len = h * 0.95;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < n; i++) {
    final t = i / (n - 1);
    final ang = -math.pi / 2 + (t - 0.5) * 2.0;
    final l = len * (0.7 + 0.3 * math.cos((t - 0.5) * 3)) * (0.9 + r.nextDouble() * 0.15);
    final end = base + Offset(math.cos(ang), math.sin(ang)) * l;
    final mid = base + Offset(math.cos(ang + 0.15), math.sin(ang + 0.15)) * l * 0.5;
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    p
      ..strokeWidth = h * 0.07
      ..color = body;
    c.drawPath(path, p);
    p
      ..strokeWidth = h * 0.025
      ..color = lit;
    c.drawPath(path.shift(Offset(-h * 0.012, 0)), p);
    c.drawCircle(end, h * 0.05, Paint()..color = alpha(col, 0.95 * dim));
    tips?.add(_Tip(end, h * 0.09, col, r.nextDouble()));
  }
  c.drawOval(Rect.fromCenter(center: base, width: h * 0.3, height: h * 0.14), Paint()..color = body);
}

void _tubeCoral(Canvas c, List<_Tip>? tips, Offset base, double h, int seed, Color body, Color lit, Color col, double dim) {
  final r = rng(seed);
  final n = 3 + r.nextInt(2);
  for (var i = 0; i < n; i++) {
    final tw = h * (0.11 + r.nextDouble() * 0.05);
    final th = h * (0.4 + r.nextDouble() * 0.5);
    final x = base.dx + (i - (n - 1) / 2) * tw * 1.25;
    final rr = RRect.fromRectAndRadius(Rect.fromLTRB(x - tw / 2, base.dy - th, x + tw / 2, base.dy + 4), Radius.circular(tw * 0.5));
    c.drawRRect(rr, Paint()..color = body);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - tw / 2, base.dy - th, x - tw * 0.1, base.dy + 4), Radius.circular(tw * 0.25)), Paint()..color = lit);
    final top = Offset(x, base.dy - th);
    c.drawOval(Rect.fromCenter(center: top, width: tw * 0.8, height: tw * 0.4), Paint()..color = alpha(col, 0.95 * dim));
    tips?.add(_Tip(top, tw * 0.9, col, r.nextDouble()));
  }
}

void _orbPlant(Canvas c, List<_Tip>? tips, Offset base, double h, int seed, Color body, Color lit, Color col, double dim) {
  final r = rng(seed);
  final lean = (r.nextDouble() - 0.5) * h * 0.4;
  final top = base + Offset(lean, -h);
  final stalk = Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(base.dx - lean * 0.2, base.dy - h * 0.6, top.dx, top.dy);
  c.drawPath(
      stalk,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * 0.06
        ..color = body);
  for (var i = 0; i < 3; i++) {
    final o = Offset.lerp(base, top, 0.35 + i * 0.2)! + Offset((i.isEven ? 1 : -1) * h * 0.1, 0);
    c.drawCircle(o, h * 0.045, Paint()..color = alpha(col, 0.85 * dim));
  }
  c.drawCircle(top, h * 0.13, Paint()..color = alpha(col, 0.14 * dim));
  c.drawCircle(top, h * 0.085, Paint()..color = alpha(col, 0.95 * dim));
  c.drawCircle(top + Offset(-h * 0.025, -h * 0.025), h * 0.025, Paint()..color = alpha(Colors.white, 0.7 * dim));
  tips?.add(_Tip(top, h * 0.2, col, r.nextDouble()));
}

void _coralTips(Canvas c, Size s, Clock k) {
  final dx = _nearDrift * s.width * k.sine(2, _nearPhase);
  final dy = 0.0;
  final p = Paint();
  for (var i = 0; i < _nearTips.length; i++) {
    final t = _nearTips[i];
    final a = 0.25 + 0.75 * k.pulse(6 + i % 3, t.ph);
    final o = t.p + Offset(dx, dy);
    p.color = alpha(t.c, 0.16 * a);
    c.drawCircle(o, t.r * (1.1 + 0.5 * a), p);
    p.color = alpha(Colors.white, 0.75 * a);
    c.drawCircle(o, t.r * 0.28, p);
  }
}

// ---------------------------------------------------------------- foreground kelp

void _foreKelp(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(31);
  for (var side = 0; side < 2; side++) {
    for (var i = 0; i < 4; i++) {
      final dir = side == 0 ? 1.0 : -1.0;
      final x = side == 0 ? -w * 0.02 + i * w * 0.05 + r.nextDouble() * 8 : w * 1.02 - i * w * 0.05 - r.nextDouble() * 8;
      final bh = h * (0.09 + r.nextDouble() * 0.09) * (1 - i * 0.1);
      final lean = dir * w * (0.02 + r.nextDouble() * 0.05);
      final base = Offset(x, h * 1.04);
      final tip = base + Offset(lean, -bh);
      final stalk = Path()
        ..moveTo(base.dx, base.dy)
        ..cubicTo(base.dx - lean * 0.6, base.dy - bh * 0.4, tip.dx + lean * 0.5, base.dy - bh * 0.65, tip.dx, tip.dy);
      c.drawPath(
          stalk,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = w * 0.034 - i * 1.2
            ..color = const Color(0xFF040A1C));
      final col = [_cyan, _turq, _purple, _blue][i % 4];
      c.drawCircle(tip, w * 0.011, Paint()..color = alpha(col, 0.95));
      c.drawCircle(tip, w * 0.026, Paint()..color = alpha(col, 0.16));
    }
  }
}

// ---------------------------------------------------------------- particles

void _plankton1(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 34, seed: 3, colors: [_plankton, _cyan, _turq], minSize: 0.9, maxSize: 2.0, flow: Offset(0.04, -1), cycles: 1, spread: 2, wander: 8, twinkle: 0.5, shape: ParticleShape.dot, fade: 0.1, opacity: 0.8));
  paintParticles(c, s, k, const ParticleSpec(count: 12, seed: 8, colors: [_plankton, _purple], minSize: 1.4, maxSize: 2.4, flow: Offset(-0.03, -1), cycles: 1, spread: 1, wander: 10, twinkle: 0.6, shape: ParticleShape.glow, haloScale: 3.0, opacity: 0.8));
}

void _plankton2(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 16, seed: 5, colors: [_plankton, _cyan], minSize: 1.8, maxSize: 3.0, flow: Offset(0.05, -1), cycles: 2, spread: 1, wander: 14, twinkle: 0.4, shape: ParticleShape.dot, fade: 0.08, opacity: 0.55));
  paintParticles(c, s, k, const ParticleSpec(count: 14, seed: 12, colors: [Color(0xFFBFF6FF)], minSize: 2.0, maxSize: 7.0, flow: Offset(0.04, -1), cycles: 2, spread: 1, wander: 6, shape: ParticleShape.bubble, fade: 0.1, opacity: 0.8));
}
