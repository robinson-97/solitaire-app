import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Golden Desert in flat, graphic 2D: a blazing low sun, towering warm clouds,
// hazy mesas, wind-sculpted dunes in flat two-tone, red sandstone buttes with
// pale strata, one big rock arch, a cairn and a lone dry tree. Wind carries
// sand streaks and glowing dust across the dunes. Light comes from the left.

const _sunPos = Offset(0.29, 0.27);

// palette
const _skyA = Color(0xFFE2603A), _skyB = Color(0xFFF4A04A), _skyC = Color(0xFFFFD98A), _skyD = Color(0xFFFFE7B0);
const _sunCore = Color(0xFFFFF4C8), _sunHalo = Color(0xFFFFD27A);
const _cloudLit = Color(0xFFFFF1D2), _cloudShade = Color(0xFFF7B98A);
const _mesaA = Color(0xFFF6C08C), _mesaAShade = Color(0xFFEBA67E);
const _mesaB = Color(0xFFF0AE78), _mesaBShade = Color(0xFFDD9572);
const _duneA = Color(0xFFF0A468), _duneAShade = Color(0xFFCB7B5E);
const _duneB = Color(0xFFE88A4A), _duneBShade = Color(0xFFB4625A);
const _duneC = Color(0xFFD4693A), _duneCShade = Color(0xFF93453F);
const _duneD = Color(0xFFB8502E), _duneDShade = Color(0xFF7A2E2A);
const _butte = Color(0xFFC4552F), _butteShade = Color(0xFF8E3526);
const _strata = Color(0xFFEDA37C), _strataShade = Color(0xFFB45A4A);
const _cactus = Color(0xFF8A8F4E), _cactusShade = Color(0xFF5E6038);
const _wood = Color(0xFF5B2A2A);

double _ss(double t) => t * t * (3 - 2 * t);

SceneSpec desertScene() => SceneSpec(
      focusY: -0.3,
      topShade: 0.2,
      bottomShade: 0.3,
      layers: [
        Layer.still(_sky),
        Layer.live(_sun),
        Layer.scroll(_clouds, scrollCycles: 1, bandTop: 0.05, bandBottom: 0.45),
        Layer.still(_mesas, driftX: 0.004, driftCycles: 2),
        Layer.live(_haze),
        Layer.still(_buttes, driftX: 0.009, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_duneBLayer, driftX: 0.015, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_birds),
        Layer.live(_streaksFar),
        Layer.still(_duneCLayer, driftX: 0.022, driftCycles: 2, driftPhase: 0.2),
        Layer.still(_duneDLayer, driftX: 0.03, driftCycles: 2, driftPhase: 0.25),
        Layer.still(_tree, driftX: 0.03, driftCycles: 2, driftPhase: 0.25, sway: 0.012, swayCycles: 6, pivot: const Alignment(0.62, 0.72)),
        Layer.live(_streaksNear),
        Layer.live(_dust),
      ],
    );

// ---------------------------------------------------------------- helpers

/// Polygon with rounded corners of radius [r].
Path _roundPoly(List<Offset> p, double r) {
  final n = p.length;
  final path = Path();
  for (var i = 0; i < n; i++) {
    final prev = p[(i + n - 1) % n], cur = p[i], next = p[(i + 1) % n];
    final d1 = prev - cur, d2 = next - cur;
    final rr = math.min(r, math.min(d1.distance, d2.distance) / 2);
    final a = cur + d1 / d1.distance * rr, b = cur + d2 / d2.distance * rr;
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
  }
  path.close();
  return path;
}

/// A wind-sculpted dune ridge: gentle windward slopes, steep lee slopes.
class _Dune {
  _Dune(Size s, List<Offset> peaks, {double drop = 0.02, double lee = 0.32}) {
    final w = s.width, h = s.height;
    for (var i = 0; i < peaks.length - 1; i++) {
      final p0 = Offset(peaks[i].dx * w, peaks[i].dy * h), p1 = Offset(peaks[i + 1].dx * w, peaks[i + 1].dy * h);
      final vx = p0.dx + (p1.dx - p0.dx) * lee;
      final vy = math.max(p0.dy, p1.dy) + drop * h;
      peakIdx.add(pts.length);
      var n = ((vx - p0.dx) / 4).ceil();
      for (var j = 0; j < n; j++) {
        final t = j / n;
        pts.add(Offset(p0.dx + (vx - p0.dx) * t, p0.dy + (vy - p0.dy) * _ss(t)));
      }
      valIdx.add(pts.length);
      n = ((p1.dx - vx) / 4).ceil();
      for (var j = 0; j < n; j++) {
        final t = j / n;
        pts.add(Offset(vx + (p1.dx - vx) * t, vy + (p1.dy - vy) * _ss(t)));
      }
    }
    pts.add(Offset(peaks.last.dx * w, peaks.last.dy * h));
  }

  final List<Offset> pts = [];
  final List<int> peakIdx = [], valIdx = [];

  double yAt(double x) {
    if (x <= pts.first.dx) return pts.first.dy;
    if (x >= pts.last.dx) return pts.last.dy;
    var lo = 0, hi = pts.length - 1;
    while (hi - lo > 1) {
      final m = (lo + hi) >> 1;
      if (pts[m].dx <= x) {
        lo = m;
      } else {
        hi = m;
      }
    }
    final t = (x - pts[lo].dx) / (pts[hi].dx - pts[lo].dx);
    return pts[lo].dy + (pts[hi].dy - pts[lo].dy) * t;
  }

  Path fill(double bottom) => smoothPath(pts)
    ..lineTo(pts.last.dx, bottom)
    ..lineTo(pts.first.dx, bottom)
    ..close();

  /// Flat lit dune, flat shadow crescents on the lee slopes, thin sunlit rim.
  void paint(Canvas c, Size s, Color lit, Color shade, {double rim = 2.5, Color? rimColor}) {
    final b = s.height * 1.1;
    final body = fill(b);
    c.drawPath(body, Paint()..color = rimColor ?? lighten(lit, 0.06));
    c
      ..save()
      ..clipPath(body)
      ..drawPath(body.shift(Offset(0, rim)), Paint()..color = lit);
    for (var i = 0; i < peakIdx.length; i++) {
      final a = peakIdx[i], v = valIdx[i];
      final pk = pts[a], vl = pts[v];
      final dx = vl.dx - pk.dx;
      final slope = smoothPath(pts.sublist(a, v + 1));
      slope
        ..cubicTo(vl.dx - dx * 0.75, vl.dy + (vl.dy - pk.dy) * 0.3, pk.dx - dx * 0.1, pk.dy + (vl.dy - pk.dy) * 0.95, pk.dx + 1, pk.dy + rim)
        ..close();
      c.drawPath(slope, Paint()..color = shade);
    }
    c.restore();
  }

  /// Faint wind ripples on the windward slopes.
  void ripples(Canvas c, Color color, double k, int seed) {
    final r = rng(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5 * k
      ..color = color;
    for (var i = 0; i < valIdx.length; i++) {
      final v = valIdx[i];
      final e = i + 1 < peakIdx.length ? peakIdx[i + 1] : pts.length - 1;
      final len = e - v;
      if (len < 12) continue;
      for (var row = 1; row <= 4; row++) {
        final a = v + (len * (0.1 + r.nextDouble() * 0.25)).floor();
        final z = v + (len * (0.65 + r.nextDouble() * 0.25)).floor();
        if (z - a < 5) continue;
        final dy = row * 9.0 * k + r.nextDouble() * 3;
        final seg = <Offset>[for (var j = a; j <= z; j += 2) pts[j] + Offset(0, dy + math.sin(j * 0.35 + row) * 0.8)];
        c.drawPath(smoothPath(seg), paint);
      }
    }
  }
}

void _strataBands(Canvas c, Rect r, Color base, Color band, List<double> ys, double th) {
  c.drawRect(r, Paint()..color = base);
  for (final y in ys) {
    c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * y, r.width, th), Paint()..color = band);
  }
}

/// Flat-topped mesa silhouette in two flat tones.
void _mesa(Canvas c, double cx, double baseY, double w, double h, Color lit, Color shade, {double skirt = 0.22, double step = 0.0}) {
  final top = baseY - h;
  final pts = <Offset>[
    Offset(cx - w * (0.5 + skirt), baseY + 6),
    Offset(cx - w * 0.5, baseY - h * 0.3),
    Offset(cx - w * 0.47, baseY - h * 0.88),
    Offset(cx - w * 0.43, top + h * step),
    Offset(cx - w * 0.1, top + h * step),
    Offset(cx - w * 0.06, top),
    Offset(cx + w * 0.44, top),
    Offset(cx + w * 0.5, baseY - h * 0.85),
    Offset(cx + w * 0.5, baseY - h * 0.3),
    Offset(cx + w * (0.5 + skirt), baseY + 6),
  ];
  final p = _roundPoly(pts, w * 0.045);
  c.drawPath(p, Paint()..color = lit);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(
        Path()
          ..moveTo(cx + w * 0.14, top - 4)
          ..lineTo(cx + w, top - 4)
          ..lineTo(cx + w, baseY + 10)
          ..lineTo(cx + w * 0.3, baseY + 10)
          ..quadraticBezierTo(cx + w * 0.16, baseY - h * 0.5, cx + w * 0.14, top - 4)
          ..close(),
        Paint()..color = shade)
    ..restore();
}

/// Sandstone butte with a capstone and pale strata, shade on the right.
void _butteShape(Canvas c, double cx, double baseY, double w, double h, {Color lit = _butte, Color shade = _butteShade, Color band = _strata, Color bandShade = _strataShade, double skirt = 0.28, int seed = 1}) {
  final r = rng(seed);
  final top = baseY - h;
  final pts = <Offset>[
    Offset(cx - w * (0.5 + skirt), baseY + 8),
    Offset(cx - w * 0.46, baseY - h * 0.26),
    Offset(cx - w * 0.4, baseY - h * 0.62),
    Offset(cx - w * 0.47, baseY - h * 0.8),
    Offset(cx - w * 0.55, baseY - h * 0.86),
    Offset(cx - w * 0.5, top + h * 0.03),
    Offset(cx - w * 0.2, top - h * 0.01),
    Offset(cx + w * 0.2, top + h * 0.015),
    Offset(cx + w * 0.5, top + h * 0.04),
    Offset(cx + w * 0.56, baseY - h * 0.85),
    Offset(cx + w * 0.44, baseY - h * 0.78),
    Offset(cx + w * 0.4, baseY - h * 0.6),
    Offset(cx + w * 0.46, baseY - h * 0.26),
    Offset(cx + w * (0.5 + skirt), baseY + 8),
  ];
  final p = _roundPoly(pts, w * 0.07);
  final shadeRegion = Path()
    ..moveTo(cx + w * 0.08, top - 6)
    ..lineTo(cx + w * 1.4, top - 6)
    ..lineTo(cx + w * 1.4, baseY + 12)
    ..lineTo(cx + w * 0.34, baseY + 12)
    ..cubicTo(cx + w * 0.16, baseY - h * 0.3, cx + w * 0.2, baseY - h * 0.7, cx + w * 0.08, top - 6)
    ..close();
  final ys = <double>[];
  var y = 0.12;
  while (y < 0.98) {
    ys.add(y);
    y += 0.07 + r.nextDouble() * 0.09;
  }
  final bounds = Rect.fromLTRB(cx - w * 1.2, top - 4, cx + w * 1.4, baseY + 12);
  c
    ..save()
    ..clipPath(p);
  _strataBands(c, bounds, lit, band, ys, h * 0.028);
  c
    ..save()
    ..clipPath(shadeRegion);
  _strataBands(c, bounds, shade, bandShade, ys, h * 0.028);
  c
    ..restore()
    ..restore();
}

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_skyA, _skyB, _skyC, _skyD], const [0.0, 0.26, 0.47, 1.0]);
  // flat sun-glow bands around the horizon (hard-edged, translucent)
  final cx = _sunPos.dx * s.width, cy = _sunPos.dy * s.height;
  c.drawCircle(Offset(cx, cy), s.width * 0.42, Paint()..color = _skyC.withValues(alpha: 0.12));
  c.drawCircle(Offset(cx, cy), s.width * 0.3, Paint()..color = _skyC.withValues(alpha: 0.14));
}

void _sun(Canvas c, Size s, Clock k) {
  final o = Offset(_sunPos.dx * s.width, _sunPos.dy * s.height);
  final r = s.width * 0.07;
  final p = k.pulse(3);
  c.drawCircle(o, r * (2.5 + 0.12 * p), Paint()..color = _sunHalo.withValues(alpha: 0.12 + 0.05 * p));
  c.drawCircle(o, r * (1.7 + 0.08 * p), Paint()..color = _sunHalo.withValues(alpha: 0.24 + 0.06 * p));
  c.drawCircle(o, r, Paint()..color = _sunCore);
}

void _clouds(Canvas c, Size s) {
  final w = s.width, h = s.height;
  flatCloud(c, Offset(w * 0.16, h * 0.2), w * 0.52, color: _cloudLit, shade: _cloudShade, seed: 4, puff: 1.35);
  flatCloud(c, Offset(w * 0.62, h * 0.33), w * 0.36, color: _cloudLit, shade: _cloudShade, seed: 9, puff: 1.0);
  flatCloud(c, Offset(w * 0.9, h * 0.16), w * 0.3, color: _cloudLit, shade: _cloudShade, seed: 13, puff: 1.2);
  flatCloud(c, Offset(w * 0.4, h * 0.405), w * 0.22, color: _cloudLit, shade: _cloudShade, seed: 21, puff: 0.8);
}

// ---------------------------------------------------------------- far land

void _mesas(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // distant row
  _mesa(c, w * 0.12, h * 0.475, w * 0.3, h * 0.07, _mesaA, _mesaAShade, skirt: 0.3, step: 0.2);
  _mesa(c, w * 0.52, h * 0.475, w * 0.2, h * 0.05, _mesaA, _mesaAShade, skirt: 0.3);
  _mesa(c, w * 0.93, h * 0.475, w * 0.34, h * 0.085, _mesaA, _mesaAShade, skirt: 0.3, step: 0.18);
  // nearer row
  _mesa(c, w * 0.36, h * 0.49, w * 0.26, h * 0.05, _mesaB, _mesaBShade, skirt: 0.35);
  _mesa(c, w * 0.76, h * 0.495, w * 0.18, h * 0.04, _mesaB, _mesaBShade, skirt: 0.35);
  // first dune plane
  final d = _Dune(s, const [Offset(-0.15, 0.505), Offset(0.3, 0.495), Offset(0.78, 0.51), Offset(1.3, 0.495)], drop: 0.012, lee: 0.3);
  d.paint(c, s, _duneA, _duneAShade, rim: 2);
}

void _haze(Canvas c, Size s, Clock k) {
  final r = rng(33);
  final kk = s.width / 390;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.2 * kk;
  for (var i = 0; i < 8; i++) {
    final y = (0.43 + i * 0.0085) * s.height;
    final len = (0.25 + r.nextDouble() * 0.35) * s.width;
    final x0 = r.nextDouble() * s.width * 0.8 + math.sin(tau * (k.u * (3 + i % 3) + i * 0.2)) * 14 * kk;
    final ph = tau * (k.u * (6 + i % 2) + i * 0.13);
    p.color = const Color(0xFFFFF0C4).withValues(alpha: 0.2 + 0.04 * (i % 3));
    final path = Path()..moveTo(x0, y + math.sin(ph) * 1.4 * kk);
    for (var j = 1; j <= 8; j++) {
      final x = x0 + len * j / 8;
      path.lineTo(x, y + math.sin(ph + x * 0.05) * 1.4 * kk);
    }
    c.drawPath(path, p);
  }
}

// ---------------------------------------------------------------- buttes & arch

void _buttes(Canvas c, Size s) {
  final w = s.width, h = s.height;
  const hz = Color(0xFFF0A468);
  // small far buttes, hazed
  _butteShape(c, w * 0.52, h * 0.545, w * 0.12, h * 0.1, lit: hazeTo(_butte, hz, 0.45), shade: hazeTo(_butteShade, hz, 0.45), band: hazeTo(_strata, hz, 0.3), bandShade: hazeTo(_strataShade, hz, 0.4), skirt: 0.3, seed: 3);
  _butteShape(c, w * 0.0, h * 0.58, w * 0.26, h * 0.17, lit: hazeTo(_butte, hz, 0.22), shade: hazeTo(_butteShade, hz, 0.22), band: hazeTo(_strata, hz, 0.15), bandShade: hazeTo(_strataShade, hz, 0.2), skirt: 0.3, seed: 8);
  // hero: the arch
  _arch(c, s, w * 0.72, h * 0.62, w * 0.6, h * 0.48);
  // tall spire on the left
  _butteShape(c, w * 0.3, h * 0.6, w * 0.15, h * 0.17, skirt: 0.3, seed: 12);
}

void _arch(Canvas c, Size s, double ax, double base, double w, double h) {
  Offset o(double fx, double fy) => Offset(ax + w * fx, base - h * fy);
  final outer = _roundPoly([
    o(-0.6, -0.05),
    o(-0.5, 0.3),
    o(-0.46, 0.7),
    o(-0.4, 0.9),
    o(-0.2, 1.0),
    o(0.1, 1.0),
    o(0.32, 0.9),
    o(0.43, 0.68),
    o(0.46, 0.3),
    o(0.58, -0.05),
  ], w * 0.12);
  final hole = _roundPoly([
    o(-0.3, -0.1),
    o(-0.3, 0.45),
    o(-0.24, 0.66),
    o(-0.05, 0.74),
    o(0.12, 0.72),
    o(0.22, 0.6),
    o(0.25, 0.4),
    o(0.25, -0.1),
  ], w * 0.14);
  final body = Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(outer, Offset.zero)
    ..addPath(hole, Offset.zero);
  c.drawPath(body, Paint()..color = _butte);
  // strata
  final r = rng(5);
  final ys = <double>[];
  var y = 0.05;
  while (y < 1.0) {
    ys.add(y);
    y += 0.06 + r.nextDouble() * 0.07;
  }
  final bounds = Rect.fromLTRB(ax - w, base - h * 1.05, ax + w, base + 20);
  c
    ..save()
    ..clipPath(body);
  for (final yy in ys) {
    c.drawRect(Rect.fromLTWH(bounds.left, bounds.bottom - bounds.height * yy * 0.95 - 20, bounds.width, h * 0.022), Paint()..color = _strata);
  }
  // shade: right half + soffit under the arch + left inner face
  final shade = Path()
    ..moveTo(ax + w * 0.0, base - h * 1.1)
    ..lineTo(ax + w, base - h * 1.1)
    ..lineTo(ax + w, base + 20)
    ..lineTo(ax + w * 0.2, base + 20)
    ..cubicTo(ax + w * 0.3, base - h * 0.3, ax + w * 0.18, base - h * 0.8, ax + w * 0.0, base - h * 1.1)
    ..close();
  final shadePaint = Paint()..color = _butteShade;
  c.drawPath(shade, shadePaint);
  c.drawPath(hole.shift(Offset(w * 0.03, -h * 0.065)), shadePaint);
  // re-draw pale strata in shade on the shaded parts
  c
    ..save()
    ..clipPath(shade);
  for (final yy in ys) {
    c.drawRect(Rect.fromLTWH(bounds.left, bounds.bottom - bounds.height * yy * 0.95 - 20, bounds.width, h * 0.022), Paint()..color = _strataShade);
  }
  c
    ..restore()
    ..restore();
}

// ---------------------------------------------------------------- dunes

_Dune _dB(Size s) => _Dune(s, const [Offset(-0.2, 0.62), Offset(0.22, 0.6), Offset(0.7, 0.625), Offset(1.25, 0.6)], drop: 0.02, lee: 0.3);
_Dune _dC(Size s) => _Dune(s, const [Offset(-0.1, 0.74), Offset(0.45, 0.715), Offset(1.0, 0.75), Offset(1.4, 0.72)], drop: 0.022, lee: 0.28);
_Dune _dD(Size s) => _Dune(s, const [Offset(-0.15, 0.9), Offset(0.2, 0.86), Offset(0.7, 0.895), Offset(1.3, 0.87)], drop: 0.02, lee: 0.3);

void _cactusShape(Canvas c, Offset base, double h) {
  final w = h * 0.2;
  void draw(Color col, double dx, double wScale) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * wScale
      ..color = col;
    c.drawLine(base + Offset(dx, 0), base + Offset(dx, -h + w * 0.5), p);
    c.drawPath(
        Path()
          ..moveTo(base.dx + dx, base.dy - h * 0.45)
          ..lineTo(base.dx + dx - h * 0.28, base.dy - h * 0.45)
          ..lineTo(base.dx + dx - h * 0.28, base.dy - h * 0.72),
        p..strokeWidth = w * 0.75 * wScale);
    c.drawPath(
        Path()
          ..moveTo(base.dx + dx, base.dy - h * 0.3)
          ..lineTo(base.dx + dx + h * 0.24, base.dy - h * 0.3)
          ..lineTo(base.dx + dx + h * 0.24, base.dy - h * 0.52),
        p);
  }

  draw(_cactusShade, 0, 1);
  draw(_cactus, -w * 0.14, 0.62);
}

void _duneBLayer(Canvas c, Size s) {
  final d = _dB(s);
  _cactusShape(c, Offset(s.width * 0.9, d.yAt(s.width * 0.9) + 4), s.height * 0.07);
  _cactusShape(c, Offset(s.width * 0.1, d.yAt(s.width * 0.1) + 4), s.height * 0.045);
  d.paint(c, s, _duneB, _duneBShade, rim: 2.5);
  d.ripples(c, mix(_duneB, _duneBShade, 0.3), s.width / 390, 4);
}

void _duneCLayer(Canvas c, Size s) {
  final d = _dC(s);
  d.paint(c, s, _duneC, _duneCShade, rim: 3);
  d.ripples(c, mix(_duneC, _duneCShade, 0.35), s.width / 390, 6);
}

void _duneDLayer(Canvas c, Size s) {
  final d = _dD(s);
  d.paint(c, s, _duneD, _duneDShade, rim: 3.5);
  d.ripples(c, mix(_duneD, _duneDShade, 0.4), s.width / 390, 9);
  final k = s.width / 390;
  // cairn on the crest
  final x = s.width * 0.2;
  var y = d.yAt(x) + 3;
  const stones = [(40.0, 14.0), (31.0, 12.0), (22.0, 10.5), (14.0, 9.0)];
  for (var i = 0; i < stones.length; i++) {
    final (sw, sh) = stones[i];
    final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + (i.isEven ? -1 : 1) * 1.2 * k, y - sh * k / 2), width: sw * k, height: sh * k), Radius.circular(sh * k * 0.5));
    c.drawRRect(rr, Paint()..color = const Color(0xFFE9A06E));
    c
      ..save()
      ..clipRRect(rr)
      ..drawRect(Rect.fromLTRB(rr.center.dx + sw * k * 0.1, rr.top, rr.right, rr.bottom), Paint()..color = const Color(0xFFB56654))
      ..restore();
    y -= sh * k * 0.88;
  }
  // a few pebbles
  final r = rng(14);
  for (var i = 0; i < 9; i++) {
    final px = r.nextDouble() * s.width;
    final py = d.yAt(px) + (10 + r.nextDouble() * 50) * k;
    c.drawOval(Rect.fromCenter(center: Offset(px, py), width: (4 + r.nextDouble() * 5) * k, height: 2.6 * k), Paint()..color = _duneDShade);
  }
}

void _tree(Canvas c, Size s) {
  final d = _dD(s);
  final k = s.width / 390;
  final bx = s.width * 0.82;
  final base = Offset(bx, d.yAt(bx) + 3);
  final h = s.height * 0.15;
  final trunk = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _wood;
  trunk.strokeWidth = 6 * k;
  c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..cubicTo(base.dx - 5 * k, base.dy - h * 0.3, base.dx + 12 * k, base.dy - h * 0.55, base.dx + 4 * k, base.dy - h * 0.78),
      trunk);
  trunk.strokeWidth = 3.4 * k;
  final tip = Offset(base.dx + 4 * k, base.dy - h * 0.78);
  c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx - 14 * k, tip.dy - 8 * k, tip.dx - 30 * k, tip.dy - 6 * k),
      trunk);
  c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx + 12 * k, tip.dy - 14 * k, tip.dx + 26 * k, tip.dy - 16 * k),
      trunk);
  c.drawPath(
      Path()
        ..moveTo(base.dx + 5 * k, base.dy - h * 0.5)
        ..quadraticBezierTo(base.dx + 22 * k, base.dy - h * 0.52, base.dx + 32 * k, base.dy - h * 0.62),
      trunk);
  trunk.strokeWidth = 2 * k;
  c.drawPath(
      Path()
        ..moveTo(tip.dx - 14 * k, tip.dy - 8 * k)
        ..quadraticBezierTo(tip.dx - 18 * k, tip.dy - 16 * k, tip.dx - 16 * k, tip.dy - 24 * k),
      trunk);
  c.drawPath(
      Path()
        ..moveTo(tip.dx + 12 * k, tip.dy - 14 * k)
        ..quadraticBezierTo(tip.dx + 14 * k, tip.dy - 24 * k, tip.dx + 8 * k, tip.dy - 30 * k),
      trunk);
  // sparse dry leaf tufts
  const tufts = [(-30.0, -6.0), (-16.0, -24.0), (26.0, -16.0), (8.0, -30.0)];
  for (var i = 0; i < 4; i++) {
    final (dx, dy) = tufts[i];
    final p = tip + Offset(dx * k, dy * k);
    c.drawOval(Rect.fromCenter(center: p, width: 15 * k, height: 7 * k), Paint()..color = const Color(0xFFD08A3E));
    c.drawOval(Rect.fromCenter(center: p + Offset(2 * k, 1.5 * k), width: 9 * k, height: 3.5 * k), Paint()..color = const Color(0xFFA9692F));
  }
  // flat shadow on the sand, falling to the right (light from the left)
  c.drawOval(Rect.fromLTWH(base.dx + 2 * k, base.dy - 1 * k, 44 * k, 6 * k), Paint()..color = _duneDShade);
}

// ---------------------------------------------------------------- live

void _birds(Canvas c, Size s, Clock k) {
  final kk = s.width / 390;
  for (var i = 0; i < 4; i++) {
    final ph = i * 0.07;
    final a = tau * (k.u * 3 + ph);
    final cx = s.width * (0.56 + 0.04 * i), cy = s.height * (0.145 + 0.012 * i);
    final o = Offset(cx + math.cos(a) * s.width * (0.2 + 0.02 * i), cy + math.sin(a) * s.height * 0.025);
    paintBird(c, o, (5.5 - i * 0.4) * kk, k.sine(30 + i * 3, ph), _duneDShade);
  }
}

void _streak(Canvas c, Size s, Clock k, math.Random r, int cycles, double y0, double y1, double len0, double len1, Paint p, int i) {
  final kk = s.width / 390;
  final len = (len0 + r.nextDouble() * (len1 - len0)) * kk;
  final span = s.width + 2 * len;
  final x = (r.nextDouble() + k.saw(cycles)) % 1.0 * span - len;
  final ph = r.nextDouble();
  final y = (y0 + r.nextDouble() * (y1 - y0)) * s.height + math.sin(tau * (k.u * 3 + ph)) * 4 * kk + math.sin(x * 0.02 + ph * 6) * 3 * kk;
  final path = Path()
    ..moveTo(x, y)
    ..quadraticBezierTo(x + len * 0.5, y - 3 * kk * math.sin(tau * (k.u * 2 + ph)), x + len, y + 1.5 * kk);
  c.drawPath(path, p);
}

void _streaksFar(Canvas c, Size s, Clock k) {
  final r = rng(41);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.4 * s.width / 390
    ..color = const Color(0xFFFFE6B0).withValues(alpha: 0.5);
  for (var i = 0; i < 14; i++) {
    _streak(c, s, k, r, 2 + i % 2, 0.48, 0.74, 24, 70, p, i);
  }
}

void _streaksNear(Canvas c, Size s, Clock k) {
  final r = rng(57);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.8 * s.width / 390
    ..color = const Color(0xFFFFD79A).withValues(alpha: 0.42);
  for (var i = 0; i < 14; i++) {
    _streak(c, s, k, r, 5 + i % 2, 0.6, 1.0, 40, 110, p, i);
  }
}

void _dust(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 20, seed: 5, colors: [Color(0xFFFFF4C8), Color(0xFFFFD98A)], minSize: 1.4, maxSize: 2.8, flow: Offset(0.06, -0.08), cycles: 1, spread: 2, wander: 12, twinkle: 0.6, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.08, 0.75, 0.5), haloScale: 2.4));
  paintParticles(c, s, k, const ParticleSpec(count: 36, seed: 9, colors: [Color(0xFFFFE2A0), Color(0xFFFFF4D0)], minSize: 0.9, maxSize: 1.8, flow: Offset(1.0, -0.04), cycles: 2, spread: 2, wander: 5, twinkle: 0.3, shape: ParticleShape.dot, region: Rect.fromLTRB(0.0, 0.3, 1.0, 1.0), opacity: 0.8));
}
