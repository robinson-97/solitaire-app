import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Volcanic Wasteland in flat, graphic 2D: one enormous cone with a glowing
// crater and a rising smoke plume, lava rivers with light travelling along
// them, black basalt planes in red haze and obsidian boulders with orange rim
// light. Embers rise, ash drifts down. Light comes from the left.

// palette
const _sky0 = Color(0xFF1A0A12), _sky1 = Color(0xFF5A1420), _sky2 = Color(0xFFC03A1A), _sky3 = Color(0xFFFF8A2A);
const _lava = Color(0xFFFF4A12), _lavaMid = Color(0xFFFF9A1F), _lavaHot = Color(0xFFFFD25A), _lavaDeep = Color(0xFFC0300F);
const _basalt = Color(0xFF2B1E22), _basaltDark = Color(0xFF1C1417), _obsidian = Color(0xFF14101C), _obsidianLit = Color(0xFF3A2C4C);
const _smoke = Color(0xFF3A2A2E), _smokeDark = Color(0xFF2A1D24);

const double _cx = 0.60; // volcano axis (fraction of width)
const double _craterY = 0.262; // fraction of height

Offset _o(Size s, double x, double y) => Offset(x * s.width, y * s.height);

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Applies the same horizontal glide as a still layer with driftX, so live
/// overlays stay glued to their painted layer.
void _drift(Canvas c, Size s, Clock k, double dx, int cycles, double phase) {
  c.translate(dx * s.width * k.sine(cycles, phase), 0);
}

class _River {
  _River(this.pts, this.w0, this.w1);
  final List<Offset> pts;
  final double w0, w1;
  late final Path line = smoothPath(pts);
  List<double> widths(double k0) => [for (var i = 0; i < pts.length; i++) (w0 + (w1 - w0) * i / (pts.length - 1)) * k0];
}

class _Geo {
  _Geo(this.s) {
    final w = s.width, h = s.height;
    outline = smoothPath([
      _o(s, _cx - 0.78, 0.66),
      _o(s, _cx - 0.42, 0.55),
      _o(s, _cx - 0.24, 0.42),
      _o(s, _cx - 0.145, 0.30),
      _o(s, _cx - 0.115, 0.262),
      _o(s, _cx - 0.07, 0.245),
      _o(s, _cx - 0.02, 0.255),
      _o(s, _cx + 0.03, 0.238),
      _o(s, _cx + 0.085, 0.25),
      _o(s, _cx + 0.115, 0.265),
      _o(s, _cx + 0.15, 0.30),
      _o(s, _cx + 0.26, 0.42),
      _o(s, _cx + 0.44, 0.55),
      _o(s, _cx + 0.8, 0.66),
      _o(s, _cx + 0.8, 0.9),
      _o(s, _cx - 0.78, 0.9),
    ], closed: true);
    shade = smoothPath([
      _o(s, _cx - 0.015, 0.2),
      _o(s, _cx + 0.0, 0.26),
      _o(s, _cx + 0.03, 0.34),
      _o(s, _cx + 0.045, 0.45),
      _o(s, _cx + 0.09, 0.56),
      _o(s, _cx + 0.2, 0.7),
      _o(s, _cx + 1.0, 0.9),
      _o(s, _cx + 1.0, 0.2),
    ], closed: true);
    rivers = [
      _River([_o(s, 0.57, 0.275), _o(s, 0.555, 0.34), _o(s, 0.535, 0.43), _o(s, 0.52, 0.53), _o(s, 0.515, 0.64)], 3, 8),
      _River([_o(s, 0.65, 0.275), _o(s, 0.665, 0.34), _o(s, 0.69, 0.43), _o(s, 0.715, 0.53), _o(s, 0.745, 0.64)], 2.6, 8),
      _River([_o(s, 0.535, 0.28), _o(s, 0.47, 0.34), _o(s, 0.42, 0.42), _o(s, 0.375, 0.52), _o(s, 0.33, 0.62)], 1.8, 5),
      _River([_o(s, 0.545, 0.43), _o(s, 0.5, 0.47), _o(s, 0.46, 0.55), _o(s, 0.44, 0.63)], 1.2, 3.4),
      _River([_o(s, 0.70, 0.45), _o(s, 0.77, 0.5), _o(s, 0.83, 0.58), _o(s, 0.86, 0.66)], 1.2, 3.6),
    ];
    final cr = rng(41);
    for (final st in const [Offset(0.03, 0.81), Offset(0.22, 0.86), Offset(0.4, 0.83), Offset(0.58, 0.8), Offset(0.92, 0.95), Offset(0.66, 0.985), Offset(0.98, 0.84), Offset(0.3, 0.79)]) {
      final pts = <Offset>[Offset(st.dx * w, st.dy * h)];
      var ang = (st.dx < 0.5 ? 0.3 : math.pi - 0.3) + (cr.nextDouble() - 0.5) * 0.8;
      for (var i = 0; i < 4; i++) {
        ang += (cr.nextDouble() - 0.5) * 1.1;
        final len = (16 + cr.nextDouble() * 18) * w / 390;
        pts.add(pts.last + Offset(math.cos(ang), math.sin(ang) * 0.6) * len);
      }
      cracks.add(smoothPath(pts));
    }
    nearRiver = _River([_o(s, 1.15, 0.75), _o(s, 0.9, 0.79), _o(s, 0.72, 0.84), _o(s, 0.76, 0.9), _o(s, 0.55, 0.935), _o(s, 0.32, 0.93), _o(s, 0.14, 0.975), _o(s, -0.12, 1.0)], 7, 15);
  }
  final Size s;
  late final Path outline, shade;
  late final List<_River> rivers;
  late final _River nearRiver;
  final List<Path> cracks = [];
}

_Geo? _geoCache;
_Geo _geo(Size s) {
  final g = _geoCache;
  if (g != null && g.s == s) return g;
  return _geoCache = _Geo(s);
}

SceneSpec volcanicScene() => SceneSpec(
      focusY: -0.42,
      topShade: 0.12,
      bottomShade: 0.2,
      layers: [
        Layer.still(_sky),
        Layer.still(_farLands, driftX: 0.004, driftCycles: 2),
        Layer.scroll(_smokeBack, scrollCycles: 1, bandTop: 0.22, bandBottom: 0.46),
        Layer.still(_hero, driftX: 0.008, driftCycles: 2, driftPhase: 0.05),
        Layer.live(_heroLive),
        Layer.scroll(_smokeFront, scrollCycles: 2, bandTop: 0.0, bandBottom: 0.27),
        Layer.live(_lightning),
        Layer.still(_mid, driftX: 0.014, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_near, driftX: 0.022, driftCycles: 2, driftPhase: 0.2),
        Layer.live(_nearLive),
        Layer.still(_fore, driftX: 0.036, driftCycles: 2, driftPhase: 0.3),
        Layer.live(_embers),
        Layer.live(_ash),
      ],
    );

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_sky0, _sky1, _sky2, _sky3], const [0.0, 0.22, 0.46, 0.64]);
  final o = _o(s, _cx, _craterY + 0.04);
  // flat translucent halo rings around the crater
  c.drawCircle(o, s.width * 0.82, Paint()..color = _sky3.withValues(alpha: 0.07));
  c.drawCircle(o, s.width * 0.56, Paint()..color = _sky3.withValues(alpha: 0.09));
  c.drawCircle(o, s.width * 0.34, Paint()..color = _lavaMid.withValues(alpha: 0.12));
  // a few cold stars high up between the smoke
  final r = rng(5);
  for (var i = 0; i < 14; i++) {
    c.drawCircle(Offset(r.nextDouble() * s.width, r.nextDouble() * s.height * 0.12), 0.7 + r.nextDouble() * 0.7, Paint()..color = const Color(0xFFFFC9B0).withValues(alpha: 0.5));
  }
}

// ---------------------------------------------------------------- far lands

void _cone(Canvas c, Size s, double cx, double baseY, double topY, double half, Color col, Color shade) {
  final top = _o(s, cx, topY);
  final p = smoothPath([
    _o(s, cx - half, baseY),
    _o(s, cx - half * 0.55, baseY - (baseY - topY) * 0.28),
    _o(s, cx - half * 0.2, topY + (baseY - topY) * 0.12),
    Offset(top.dx - half * s.width * 0.06, top.dy),
    Offset(top.dx + half * s.width * 0.06, top.dy + 1),
    _o(s, cx + half * 0.2, topY + (baseY - topY) * 0.12),
    _o(s, cx + half * 0.55, baseY - (baseY - topY) * 0.28),
    _o(s, cx + half, baseY),
    _o(s, cx + half, baseY + 0.3),
    _o(s, cx - half, baseY + 0.3),
  ], closed: true);
  c.drawPath(p, Paint()..color = col);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(smoothPath([_o(s, cx, topY - 0.05), _o(s, cx + half * 0.04, topY + 0.05), _o(s, cx + half * 0.15, baseY - 0.05), _o(s, cx + half * 2, baseY + 0.3), _o(s, cx + half * 2, topY - 0.1)], closed: true), Paint()..color = shade)
    ..restore();
  // glowing crater lip
  c.drawOval(Rect.fromCenter(center: top + Offset(0, 1.5), width: half * s.width * 0.2, height: 3.5), Paint()..color = _lavaMid);
}

void _farLands(Canvas c, Size s) {
  _cone(c, s, 0.06, 0.58, 0.36, 0.3, const Color(0xFF9A3027), const Color(0xFF86262A));
  _cone(c, s, 0.98, 0.58, 0.39, 0.28, const Color(0xFF9A3027), const Color(0xFF86262A));
  _cone(c, s, 0.26, 0.6, 0.47, 0.2, const Color(0xFF7C2630), const Color(0xFF6C212E));
  _cone(c, s, 0.9, 0.6, 0.5, 0.17, const Color(0xFF7C2630), const Color(0xFF6C212E));
  final r1 = Ridge(s, y: 0.575, amp: 0.012, freq: 2.2, seed: 8, octaves: 2, sharp: 0.1);
  flatRidge(c, r1, const Color(0xFF5E1D2A), light: const Color(0xFF8A3030), band: 2.5);
}

// ---------------------------------------------------------------- smoke decks

void _smokeBack(Canvas c, Size s) {
  final w = s.width, h = s.height;
  const spots = [
    [0.18, 0.34, 0.62, 3],
    [0.62, 0.30, 0.5, 5],
    [0.9, 0.4, 0.46, 9],
  ];
  for (final sp in spots) {
    flatCloud(c, Offset(sp[0] * w, sp[1] * h), sp[2] * w, color: const Color(0xFF6A2832), shade: const Color(0xFFE0642A), seed: sp[3].toInt(), puff: 0.95, opacity: 0.9);
  }
}

void _smokeFront(Canvas c, Size s) {
  final w = s.width, h = s.height;
  const spots = [
    [0.12, 0.085, 0.66, 11],
    [0.45, 0.16, 0.4, 13],
    [0.82, 0.075, 0.7, 17],
    [0.34, 0.01, 0.8, 23],
  ];
  for (final sp in spots) {
    flatCloud(c, Offset(sp[0] * w, sp[1] * h + h * 0.05), sp[2] * w, color: sp[3] % 2 == 1 && sp[0] > 0.3 ? const Color(0xFF4A3038) : _smoke, shade: const Color(0xFFC8501E), seed: sp[3].toInt(), puff: 1.15);
  }
}

// ---------------------------------------------------------------- the volcano

void _hero(Canvas c, Size s) {
  final g = _geo(s);
  final k0 = s.width / 390;
  // lit (left) rim, body, shade
  c.drawPath(g.outline, Paint()..color = const Color(0xFF6A3438));
  c
    ..save()
    ..clipPath(g.outline)
    ..drawPath(g.outline.shift(Offset(s.width * 0.012, s.height * 0.004)), Paint()..color = const Color(0xFF4A2A32))
    ..drawPath(g.outline.shift(Offset(s.width * 0.04, s.height * 0.012)), Paint()..color = _basalt)
    ..drawPath(g.shade, Paint()..color = _basaltDark);
  // soft gullies on the flank (flat darker strokes)
  final gp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 5 * k0
    ..color = _basaltDark.withValues(alpha: 0.55);
  final lp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 7 * k0
    ..color = const Color(0xFF3C2530);
  for (final gl in [
    [0.5, 0.45, 0.44, 0.52, 0.38, 0.6],
    [0.46, 0.34, 0.4, 0.42, 0.35, 0.5],
  ]) {
    c.drawPath(smoothPath([_o(s, gl[0], gl[1]), _o(s, gl[2], gl[3]), _o(s, gl[4], gl[5])]), lp);
  }
  final rp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 8 * k0
    ..color = _basalt;
  for (final gl in [
    [0.8, 0.45, 0.88, 0.52, 0.94, 0.6],
    [0.74, 0.34, 0.8, 0.42, 0.86, 0.5],
    [0.6, 0.45, 0.63, 0.52, 0.64, 0.6],
  ]) {
    c.drawPath(smoothPath([_o(s, gl[0], gl[1]), _o(s, gl[2], gl[3]), _o(s, gl[4], gl[5])]), rp);
  }
  for (final gl in [
    [0.54, 0.3, 0.505, 0.4, 0.46, 0.5],
    [0.5, 0.36, 0.44, 0.46, 0.4, 0.56],
    [0.68, 0.3, 0.74, 0.4, 0.8, 0.52],
    [0.72, 0.38, 0.84, 0.46, 0.92, 0.58],
  ]) {
    c.drawPath(smoothPath([_o(s, gl[0], gl[1]), _o(s, gl[2], gl[3]), _o(s, gl[4], gl[5])]), gp);
  }
  c.restore();

  // lava rivers: dark bank, red body, orange stripe
  for (final r in g.rivers) {
    if (r.pts.isEmpty) continue;
    final hw = r.widths(k0);
    flatRibbon(c, r.pts, [for (final v in hw) v + 3 * k0], color: _lavaDeep.withValues(alpha: 0.4));
    flatRibbon(c, r.pts, hw, color: _lava, light: _lavaMid);
  }
  _lake(c, s);
}

void _lake(Canvas c, Size s) {
  final cr = _o(s, _cx, _craterY);
  final lw = s.width * 0.1;
  final lake = Path()
    ..moveTo(cr.dx - lw, cr.dy)
    ..quadraticBezierTo(cr.dx, cr.dy - s.height * 0.03, cr.dx + lw, cr.dy)
    ..quadraticBezierTo(cr.dx, cr.dy + s.height * 0.012, cr.dx - lw, cr.dy)
    ..close();
  c.drawPath(lake, Paint()..color = _lava);
  c
    ..save()
    ..clipPath(lake)
    ..drawOval(Rect.fromCenter(center: cr + Offset(-lw * 0.1, -s.height * 0.003), width: lw * 1.5, height: s.height * 0.016), Paint()..color = _lavaMid)
    ..drawOval(Rect.fromCenter(center: cr + Offset(-lw * 0.2, -s.height * 0.004), width: lw * 0.7, height: s.height * 0.007), Paint()..color = _lavaHot)
    ..restore();
}

void _heroLive(Canvas c, Size s, Clock k) {
  c.save();
  _drift(c, s, k, 0.008, 2, 0.05);
  final g = _geo(s);
  final k0 = s.width / 390;
  _plume(c, s, k);
  _lake(c, s);
  // crater pulse: translucent flat rings
  final cr = _o(s, _cx, _craterY);
  final p = k.pulse(6);
  c.drawOval(Rect.fromCenter(center: cr + Offset(0, -s.height * 0.012), width: s.width * (0.3 + 0.03 * p), height: s.height * (0.06 + 0.006 * p)), Paint()..color = _lavaMid.withValues(alpha: 0.1 + 0.08 * p));
  c.drawOval(Rect.fromCenter(center: cr + Offset(0, -s.height * 0.006), width: s.width * 0.18, height: s.height * 0.032), Paint()..color = _lavaHot.withValues(alpha: 0.12 + 0.2 * p));
  c.drawOval(Rect.fromCenter(center: cr, width: s.width * 0.1, height: s.height * 0.009), Paint()..color = _lavaHot.withValues(alpha: 0.6 + 0.4 * p));
  // light travelling down the rivers
  final glowP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3 * k0
    ..color = _lavaHot;
  final softP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 5.5 * k0
    ..color = _lavaMid.withValues(alpha: 0.55);
  var i = 0;
  for (final r in g.rivers) {
    if (r.pts.isEmpty) continue;
    paintFlowDashes(c, r.line, softP, phase: k.saw(6, i * 0.31), dash: 20 * k0, gap: 46 * k0);
    paintFlowDashes(c, r.line, glowP, phase: k.saw(6, i * 0.31), dash: 12 * k0, gap: 54 * k0);
    i++;
  }
  c.restore();
}

void _plume(Canvas c, Size s, Clock k) {
  final cr = _o(s, _cx, _craterY - 0.012);
  const n = 12;
  final order = List<int>.generate(n, (i) => i)..sort((a, b) => k.saw(3, b / n).compareTo(k.saw(3, a / n)));
  final under = Paint(), top = Paint();
  for (final i in order) {
    final t = k.saw(3, i / n);
    final fadeIn = _smooth(0.0, 0.07, t);
    final fadeOut = 1 - _smooth(0.62, 1.0, t);
    final a = fadeIn * fadeOut;
    if (a < 0.02) continue;
    final x = cr.dx + s.width * (t * 0.17 + 0.03 * math.sin(i * 2.3 + t * 3) + (i % 3 - 1) * 0.012);
    final y = cr.dy - t * s.height * 0.255;
    final r = s.width * (0.055 + 0.1 * math.pow(t, 0.7));
    under.color = mix(const Color(0xFFE8602A), const Color(0xFF5A3640), math.min(1.0, t * 1.7)).withValues(alpha: a);
    top.color = mix(const Color(0xFF4A2D33), _smokeDark, t).withValues(alpha: a);
    for (final b in const [Offset(0, 0), Offset(-0.75, -0.18), Offset(0.78, -0.12)]) {
      final rr = r * (b.dx == 0 ? 1.0 : 0.72);
      final o = Offset(x + b.dx * r, y + b.dy * r);
      c.drawCircle(o + Offset(0, rr * 0.2), rr, under);
    }
    for (final b in const [Offset(0, 0), Offset(-0.75, -0.18), Offset(0.78, -0.12)]) {
      final rr = r * (b.dx == 0 ? 1.0 : 0.72);
      final o = Offset(x + b.dx * r, y + b.dy * r);
      c.drawCircle(o + Offset(0, -rr * 0.1), rr * 0.93, top);
    }
  }
}

void _lightning(Canvas c, Size s, Clock k) {
  final t = k.saw(2);
  double bump(double x) => x <= 0 || x >= 1 ? 0.0 : math.pow(math.sin(math.pi * x), 2).toDouble();
  final f = bump((t - 0.3) / 0.05) + 0.6 * bump((t - 0.4) / 0.04);
  if (f < 0.02) return;
  final first = k.u < 0.5;
  final o = _o(s, first ? 0.24 : 0.84, first ? 0.1 : 0.12);
  final col = const Color(0xFFFFA890);
  c.drawOval(Rect.fromCenter(center: o, width: s.width * 0.62, height: s.height * 0.1), Paint()..color = col.withValues(alpha: 0.1 * f));
  c.drawOval(Rect.fromCenter(center: o, width: s.width * 0.4, height: s.height * 0.065), Paint()..color = col.withValues(alpha: 0.14 * f));
  c.drawOval(Rect.fromCenter(center: o, width: s.width * 0.2, height: s.height * 0.035), Paint()..color = const Color(0xFFFFE0C8).withValues(alpha: 0.16 * f));
}

// ---------------------------------------------------------------- the plain

void _lavaPool(Canvas c, Offset o, double w, double h) {
  c.drawOval(Rect.fromCenter(center: o, width: w * 1.5, height: h * 1.7), Paint()..color = _lava.withValues(alpha: 0.2));
  c.drawOval(Rect.fromCenter(center: o, width: w, height: h), Paint()..color = _lava);
  c.drawOval(Rect.fromCenter(center: o + Offset(-w * 0.06, -h * 0.12), width: w * 0.72, height: h * 0.62), Paint()..color = _lavaMid);
  c.drawOval(Rect.fromCenter(center: o + Offset(-w * 0.12, -h * 0.2), width: w * 0.3, height: h * 0.26), Paint()..color = _lavaHot);
}

void _mid(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final a = Ridge(s, y: 0.61, amp: 0.012, freq: 2.4, seed: 21, octaves: 2, sharp: 0.15);
  flatRidge(c, a, const Color(0xFF3A1B24), light: const Color(0xFF7A3430), band: 3);
  final b = Ridge(s, y: 0.665, amp: 0.012, freq: 1.8, seed: 33, octaves: 2, tilt: -0.02);
  flatRidge(c, b, const Color(0xFF2B181E), light: const Color(0xFF5E2A2C), band: 3);
  _lavaPool(c, _o(s, 0.1, 0.655), w * 0.2, h * 0.014);
  _lavaPool(c, _o(s, 0.93, 0.675), w * 0.17, h * 0.012);
  _boulder(c, Offset(w * 0.07, b.yAt(w * 0.07) + 8), w * 0.2, h * 0.06, 4);
  _boulder(c, Offset(w * 0.2, b.yAt(w * 0.2) + 8), w * 0.1, h * 0.032, 7);
  _boulder(c, Offset(w * 0.93, b.yAt(w * 0.93) + 8), w * 0.18, h * 0.055, 9);
  final cc = Ridge(s, y: 0.74, amp: 0.012, freq: 1.5, seed: 44, octaves: 2, tilt: 0.02);
  flatRidge(c, cc, _basalt, light: const Color(0xFF55282A), band: 3);
}

void _near(Canvas c, Size s) {
  final k0 = s.width / 390;
  final g = _geo(s);
  final ground = Ridge(s, y: 0.79, amp: 0.012, freq: 1.4, seed: 52, octaves: 2, tilt: 0.01);
  flatRidge(c, ground, _basaltDark, light: const Color(0xFF4A2428), band: 3.5);
  final r = g.nearRiver;
  final hw = r.widths(k0);
  flatRibbon(c, r.pts, [for (final v in hw) v + 7 * k0], color: _lavaDeep.withValues(alpha: 0.28));
  flatRibbon(c, r.pts, [for (final v in hw) v + 3 * k0], color: _lavaDeep);
  flatRibbon(c, r.pts, hw, color: _lava, light: _lavaMid);
  // dim cracks
  final cp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 2.2 * k0
    ..color = _lavaDeep;
  for (final p in g.cracks) {
    c.drawPath(p, cp);
  }
}

void _nearLive(Canvas c, Size s, Clock k) {
  c.save();
  _drift(c, s, k, 0.022, 2, 0.2);
  final g = _geo(s);
  final k0 = s.width / 390;
  final cp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (var i = 0; i < g.cracks.length; i++) {
    final p = k.pulse(6 + i % 3, i * 0.17);
    cp
      ..strokeWidth = 1.6 * k0
      ..color = _lavaMid.withValues(alpha: 0.25 + 0.7 * p);
    c.drawPath(g.cracks[i], cp);
  }
  final r = g.nearRiver;
  paintFlowDashes(
    c,
    r.line,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9 * k0
      ..color = _lavaMid.withValues(alpha: 0.7),
    phase: k.saw(8),
    dash: 40 * k0,
    gap: 110 * k0,
  );
  paintFlowDashes(
    c,
    r.line,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5 * k0
      ..color = _lavaHot,
    phase: k.saw(8),
    dash: 26 * k0,
    gap: 124 * k0,
  );
  paintFlowDashes(
    c,
    r.line,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5 * k0
      ..color = _lavaHot.withValues(alpha: 0.85),
    phase: k.saw(8, 0.5),
    dash: 14 * k0,
    gap: 136 * k0,
  );
  c.restore();
}

// ---------------------------------------------------------------- obsidian boulders

void _boulder(Canvas c, Offset base, double w, double h, int seed) {
  final r = rng(seed);
  double j() => 0.9 + r.nextDouble() * 0.2;
  final pts = [
    Offset(base.dx - w * 0.5, base.dy + h * 0.1),
    Offset(base.dx - w * 0.5, base.dy - h * 0.35 * j()),
    Offset(base.dx - w * 0.3, base.dy - h * 0.8 * j()),
    Offset(base.dx - w * 0.02, base.dy - h * j()),
    Offset(base.dx + w * 0.28, base.dy - h * 0.82 * j()),
    Offset(base.dx + w * 0.5, base.dy - h * 0.4 * j()),
    Offset(base.dx + w * 0.5, base.dy + h * 0.1),
  ];
  final p = smoothPath(pts, closed: true);
  c.drawPath(p, Paint()..color = const Color(0xFFFF7A2A));
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(w * 0.018, h * 0.02)), Paint()..color = _obsidianLit)
    ..drawPath(p.shift(Offset(w * 0.06, h * 0.06)), Paint()..color = _obsidian)
    ..drawPath(
        smoothPath([
          Offset(base.dx + w * 0.02, base.dy - h * 1.2),
          Offset(base.dx + w * 0.05, base.dy - h * 0.6),
          Offset(base.dx + w * 0.12, base.dy - h * 0.1),
          Offset(base.dx + w * 0.1, base.dy + h * 0.3),
          Offset(base.dx + w, base.dy + h * 0.3),
          Offset(base.dx + w, base.dy - h * 1.2),
        ], closed: true),
        Paint()..color = const Color(0xFF0C0A14))
    ..restore();
  // glossy facet: a small flat lighter sliver
  c.drawPath(
      smoothPath([
        Offset(base.dx - w * 0.3, base.dy - h * 0.55),
        Offset(base.dx - w * 0.2, base.dy - h * 0.7),
        Offset(base.dx - w * 0.14, base.dy - h * 0.5),
      ]),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2
        ..color = const Color(0xFF6A5A82));
}

void _fore(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _boulder(c, Offset(w * 0.04, h * 1.0), w * 0.36, h * 0.12, 3);
  _boulder(c, Offset(w * 0.2, h * 1.03), w * 0.17, h * 0.06, 8);
  _boulder(c, Offset(w * 0.97, h * 0.99), w * 0.34, h * 0.105, 5);
  _boulder(c, Offset(w * 0.8, h * 1.03), w * 0.15, h * 0.05, 14);
  _boulder(c, Offset(w * 0.5, h * 1.06), w * 0.2, h * 0.04, 20);
  // pebbles near the river
  final r = rng(2);
  for (var i = 0; i < 12; i++) {
    final x = r.nextDouble() * w, y = h * (0.82 + r.nextDouble() * 0.15);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 5 + r.nextDouble() * 6, height: 3 + r.nextDouble() * 3), Paint()..color = _obsidian);
  }
}

// ---------------------------------------------------------------- air

void _embers(Canvas c, Size s, Clock k) {
  final k0 = s.width / 390;
  const cols = [Color(0xFFFFB03A), Color(0xFFFF6A1A), Color(0xFFFFD25A), Color(0xFFFF8A2A)];
  void group(int count, int seed, Rect reg, double rise, int cyc, double size) {
    final r = rng(seed);
    for (var i = 0; i < count; i++) {
      final x0 = reg.left + r.nextDouble() * reg.width;
      final y0 = r.nextDouble();
      final ph = r.nextDouble();
      final lap = k.saw(cyc + i % 3, ph);
      final p = (y0 - lap) % 1.0;
      final life = math.min(p, 1 - p) / 0.14;
      final a = life.clamp(0.0, 1.0);
      final x = (x0 + 0.03 * lap) * s.width + math.sin(tau * (k.u * (3 + i % 4) + ph)) * 7 * k0;
      final y = (reg.top + p * reg.height * rise) * s.height;
      final rad = (0.8 + r.nextDouble() * size) * k0;
      final col = cols[r.nextInt(cols.length)];
      final tw = 0.65 + 0.35 * k.pulse(14 + i % 5, ph);
      c.drawCircle(Offset(x, y), rad * 2.3, Paint()..color = col.withValues(alpha: 0.2 * a * tw));
      c.drawCircle(Offset(x, y), rad, Paint()..color = col.withValues(alpha: a * tw));
    }
  }

  group(16, 31, const Rect.fromLTWH(0.38, 0.06, 0.4, 0.3), 1.0, 2, 1.3);
  group(26, 32, const Rect.fromLTWH(0.0, 0.1, 1.0, 0.88), 1.0, 2, 1.4);
  group(14, 33, const Rect.fromLTWH(0.0, 0.7, 1.0, 0.3), 1.0, 3, 1.6);
}

void _ash(Canvas c, Size s, Clock k) {
  paintParticles(
    c,
    s,
    k,
    const ParticleSpec(
      count: 36,
      seed: 61,
      colors: [Color(0xFFD2B6BC), Color(0xFFA88A94)],
      minSize: 0.7,
      maxSize: 1.8,
      flow: Offset(0.1, 1.0),
      cycles: 2,
      spread: 2,
      wander: 9,
      shape: ParticleShape.dot,
      opacity: 0.5,
    ),
  );
}
