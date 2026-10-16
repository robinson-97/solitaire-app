import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Frozen Kingdom in flat, graphic 2D: a low pink-gold sun, pale peaks with a
// tall hero mountain, blue ice cliffs, snowy pine rows, a frozen lake and a
// tiny lit cabin. Light comes from the upper left, shade falls to the right.

const _sunPos = Offset(0.2, 0.185);

// palette
const _skyA = Color(0xFF93D3F7), _skyB = Color(0xFFBDE7FF), _skyC = Color(0xFFE2F4FF), _skyD = Color(0xFFFBEBE6);
const _snow = Color(0xFFFFFFFF), _snowShade = Color(0xFFCFE0F4), _snowShade2 = Color(0xFFB4CCEA);
const _farMtn = Color(0xFFCBE3F5), _farMtnShade = Color(0xFFB5D2EC);
const _midMtn = Color(0xFFA9CBEA), _midMtnShade = Color(0xFF8DB3DE);
const _heroLit = Color(0xFF9CC0E6), _heroShade = Color(0xFF6C94CC);
const _iceLit = Color(0xFFB9EEFB), _ice = Color(0xFF7FD8F5), _iceMid = Color(0xFF5BB8E6), _iceDeep = Color(0xFF3C7FC0);
const _pineFar = Color(0xFF8FC0C8), _pineMid = Color(0xFF4F9AA5), _pineNear = Color(0xFF1F5F6B);
const _pineFrost = Color(0xFFA8D6D0);
const _lake = Color(0xFF9ADFF5), _lakeLight = Color(0xFFD6F5FF), _lakeDeep = Color(0xFF63BCE6);
const _dune = Color(0xFFF2F8FF), _duneShade = Color(0xFFC4D9F0), _duneFront = Color(0xFFFFFFFF);
const _warm = Color(0xFFFFE9B8);

SceneSpec frozenScene() => SceneSpec(
      focusY: -0.35,
      topShade: 0.16,
      bottomShade: 0.16,
      layers: [
        Layer.still(_sky),
        Layer.live(_skyLive),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.04, bandBottom: 0.36),
        Layer.still(_farRange, driftX: 0.004, driftCycles: 2),
        Layer.still(_heroPeak, driftX: 0.008, driftCycles: 2, driftPhase: 0.05),
        Layer.scroll(_mistHigh, scrollCycles: 2, scrollLeft: false, bandTop: 0.3, bandBottom: 0.5),
        Layer.still(_cliffs, driftX: 0.012, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_forest, driftX: 0.016, driftCycles: 2, driftPhase: 0.15, sway: 0.004, swayCycles: 5),
        Layer.still(_lakeLayer, driftX: 0.02, driftCycles: 2, driftPhase: 0.2),
        Layer.live(_lakeGlints),
        Layer.scroll(_mistLow, scrollCycles: 3, bandTop: 0.58, bandBottom: 0.72),
        Layer.still(_foreground, driftX: 0.03, driftCycles: 2, driftPhase: 0.25),
        Layer.live(_sparkles),
        Layer.live(_smoke),
        Layer.live(_snowFar),
        Layer.live(_snowNear),
      ],
    );

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_skyA, _skyB, _skyC, _skyD], const [0.0, 0.25, 0.5, 0.72]);
  final o = Offset(_sunPos.dx * s.width, _sunPos.dy * s.height);
  final r = s.width * 0.05;
  // flat pink-gold glow rings
  c.drawCircle(o, r * 3.6, Paint()..color = const Color(0xFFFFE6C8).withValues(alpha: 0.18));
}

void _sunPulse(Canvas c, Size s, Clock k) {
  final o = Offset(_sunPos.dx * s.width, _sunPos.dy * s.height);
  final r = s.width * 0.05;
  final p = k.pulse(3);
  c.drawCircle(o, r * (2.3 + 0.12 * p), Paint()..color = const Color(0xFFFFD9A0).withValues(alpha: 0.2 + 0.06 * p));
  c.drawCircle(o, r * (1.6 + 0.06 * p), Paint()..color = const Color(0xFFFFE3B0).withValues(alpha: 0.34));
  c.drawCircle(o, r, Paint()..color = _warm);
  c.drawCircle(o, r * 0.72, Paint()..color = const Color(0xFFFFF7E0));
}

void _skyLive(Canvas c, Size s, Clock k) {
  _aurora(c, s, k);
  _sunPulse(c, s, k);
}

void _aurora(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  for (var b = 0; b < 2; b++) {
    final top = <Offset>[], bot = <Offset>[];
    for (var i = 0; i <= 8; i++) {
      final t = i / 8;
      final x = _lerp(-w * 0.1, w * 1.1, t);
      final y = h * (0.07 + b * 0.05) + math.sin(tau * (t * 1.3 + b * 0.3) + k.u * tau * 2) * h * 0.02 + t * h * 0.03;
      final th = h * (0.022 + 0.008 * math.sin(tau * (t * 2 + k.u * 3 + b)));
      top.add(Offset(x, y));
      bot.add(Offset(x, y + th));
    }
    final p = smoothPath([...top, ...bot.reversed], closed: true);
    c.drawPath(p, Paint()..color = (b == 0 ? const Color(0xFFD6F7F0) : const Color(0xFFFFE0F0)).withValues(alpha: 0.16));
  }
}

void _cloudsBack(Canvas c, Size s) {
  final r = rng(9);
  for (var i = 0; i < 3; i++) {
    final x = (i + 0.25 + r.nextDouble() * 0.5) * s.width / 3;
    final y = s.height * (0.27 + r.nextDouble() * 0.06);
    flatCloud(c, Offset(x, y), s.width * (0.3 + r.nextDouble() * 0.12), color: const Color(0xFFFFFFFF), shade: const Color(0xFFD7E6F7), seed: i + 40, puff: 0.95, opacity: 0.95);
  }
}

// ---------------------------------------------------------------- shape helpers

/// A rounded mountain with lit left face, shade right face and a snow cap.
void _peak(
  Canvas c,
  double ax,
  double ay,
  double halfW,
  double baseY, {
  required Color lit,
  required Color shade,
  required Color snow,
  required Color snowShade,
  double snowDepth = 0.35,
  double lean = 0,
  int seed = 1,
}) {
  final r = rng(seed);
  final hgt = baseY - ay;
  double jit() => (r.nextDouble() - 0.5);
  final left = <Offset>[
    Offset(ax - halfW, baseY),
    Offset(ax - halfW * 0.78, ay + hgt * (0.72 + jit() * 0.06)),
    Offset(ax - halfW * 0.55, ay + hgt * (0.5 + jit() * 0.08)),
    Offset(ax - halfW * 0.34, ay + hgt * (0.3 + jit() * 0.06)),
    Offset(ax - halfW * 0.14 + lean, ay + hgt * 0.09),
  ];
  final right = <Offset>[
    Offset(ax + halfW * 0.16 + lean, ay + hgt * 0.07),
    Offset(ax + halfW * 0.36, ay + hgt * (0.3 + jit() * 0.06)),
    Offset(ax + halfW * 0.6, ay + hgt * (0.52 + jit() * 0.08)),
    Offset(ax + halfW * 0.8, ay + hgt * (0.74 + jit() * 0.06)),
    Offset(ax + halfW, baseY),
  ];
  final apex = Offset(ax + lean, ay);
  final body = smoothPath([...left, apex, ...right], closed: true);
  c.drawPath(body, Paint()..color = lit);
  // shade face: right of a crease from the apex down to the base
  final crease = smoothPath([
    apex,
    Offset(ax + halfW * 0.04 + lean * 0.7, ay + hgt * 0.35),
    Offset(ax - halfW * 0.06, ay + hgt * 0.66),
    Offset(ax - halfW * 0.02, baseY + 4),
    Offset(ax + halfW * 1.2, baseY + 4),
    Offset(ax + halfW * 1.2, ay - 10),
  ], closed: true);
  c
    ..save()
    ..clipPath(body)
    ..drawPath(crease, Paint()..color = shade)
    ..restore();
  // snow cap with a scalloped hem
  final hemY = ay + hgt * snowDepth;
  final hem = <Offset>[];
  const n = 7;
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final x = ax - halfW * 0.9 + halfW * 1.8 * t;
    final prof = 1 - ((t - 0.5).abs() * 2);
    final y = hemY + (i.isEven ? 1 : -1) * hgt * 0.035 + (1 - prof) * hgt * 0.1 + jit() * hgt * 0.02;
    hem.add(Offset(x, y));
  }
  final cap = smoothPath([Offset(ax - halfW * 1.1, ay - 10), ...hem, Offset(ax + halfW * 1.1, ay - 10)], closed: true);
  c
    ..save()
    ..clipPath(body)
    ..drawPath(cap, Paint()..color = snow)
    ..save()
    ..clipPath(cap)
    ..drawPath(crease, Paint()..color = snowShade)
    ..restore()
    ..restore();
}

/// Snow-laden pine: pine tiers with a white snow band along the upper edges.
void _snowPine(Canvas c, Offset base, double h, {required Color color, required Color shade, required Color snow, required Color snowShade, double width = 0.5, int tiers = 4}) {
  final tw = h * 0.035;
  c.drawRect(Rect.fromLTRB(base.dx - tw, base.dy - h * 0.18, base.dx + tw, base.dy + 2), Paint()..color = shade);
  for (var i = 0; i < tiers; i++) {
    final t = i / tiers;
    final top = base.dy - h + h * 0.56 * t;
    final bot = base.dy - h * 0.1 - (tiers - 1 - i) * h * (0.7 / tiers);
    final half = h * width * (0.34 + 0.66 * (t + 0.18)) * 0.5;
    final cx = base.dx;
    final tier = Path()
      ..moveTo(cx, top)
      ..quadraticBezierTo(cx - half * 0.35, (top + bot) / 2, cx - half, bot - h * 0.005)
      ..quadraticBezierTo(cx - half * 0.96, bot + h * 0.03, cx - half * 0.6, bot + h * 0.025)
      ..quadraticBezierTo(cx, bot + h * 0.0, cx + half * 0.6, bot + h * 0.025)
      ..quadraticBezierTo(cx + half * 0.96, bot + h * 0.03, cx + half, bot - h * 0.005)
      ..quadraticBezierTo(cx + half * 0.35, (top + bot) / 2, cx, top)
      ..close();
    final d = (bot - top) * 0.3;
    final lower = tier.shift(Offset(-half * 0.04, d));
    c
      ..save()
      ..clipPath(tier)
      ..drawPath(tier, Paint()..color = snow)
      ..drawRect(Rect.fromLTRB(cx + half * 0.02, top - 2, cx + half * 1.2, bot + h), Paint()..color = snowShade)
      ..drawPath(lower, Paint()..color = color)
      ..save()
      ..clipPath(lower)
      ..drawRect(Rect.fromLTRB(cx + half * 0.02, top - 2, cx + half * 1.2, bot + h), Paint()..color = shade)
      ..restore()
      ..restore();
  }
}

// ---------------------------------------------------------------- mountains

void _farRange(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final far = Ridge(s, y: 0.33, amp: 0.045, freq: 2.1, seed: 12, octaves: 2, sharp: 0.45);
  flatMountains(c, far, _farMtn, _farMtnShade, bottomY: h * 0.6, snow: _snow, snowLine: h * 0.315);
  final mid = Ridge(s, y: 0.405, amp: 0.045, freq: 1.7, seed: 31, octaves: 2, sharp: 0.4);
  flatMountains(c, mid, _midMtn, _midMtnShade, bottomY: h * 0.65, snow: _snow, snowLine: h * 0.385);
  // a faint warm kiss on the left-facing snow
  c.drawCircle(Offset(w * 0.1, h * 0.37), 0, Paint());
}

void _heroPeak(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // second, smaller peak left of the hero for rhythm
  _peak(c, w * 0.3, h * 0.25, w * 0.34, h * 0.56, lit: _midMtn, shade: _midMtnShade, snow: _snow, snowShade: _snowShade, snowDepth: 0.36, seed: 3);
  _peak(c, w * 0.7, h * 0.115, w * 0.5, h * 0.62, lit: _heroLit, shade: _heroShade, snow: const Color(0xFFFFF8F0), snowShade: _snowShade2, snowDepth: 0.4, lean: w * 0.02, seed: 8);
}

void _mistHigh(Canvas c, Size s) {
  final w = s.width, h = s.height;
  for (var i = 0; i < 4; i++) {
    final x = w * (i + 0.5) / 4;
    softEllipse(c, Offset(x, h * 0.45), w * 0.7, h * 0.05, const Color(0xFFEAF6FF), 0.16);
  }
}

// ---------------------------------------------------------------- ice cliffs

void _iceCliff(Canvas c, Size s, {required double x0, required double x1, required double top, required double base, required int seed, bool flip = false}) {
  final h = s.height;
  final r = rng(seed);
  final n = 7;
  final pts = <Offset>[Offset(x0, base)];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final x = _lerp(x0, x1, t);
    final e = math.sin(math.pi * math.pow(t, flip ? 1.6 : 0.65));
    pts.add(Offset(x, base - (base - top) * (0.55 + 0.45 * e * (0.9 + r.nextDouble() * 0.15)) * (flip ? (1 - t * 0.2) : 1.0)));
  }
  pts.add(Offset(x1, base));
  final body = smoothPath(pts, closed: true);
  c.drawPath(body, Paint()..color = _ice);
  c
    ..save()
    ..clipPath(body);
  final wdt = x1 - x0;
  // facets: slanted columns, lit on the left, deep on the right
  for (var i = 0; i < 5; i++) {
    final fx = x0 + wdt * (0.1 + i * 0.2 + (r.nextDouble() - 0.5) * 0.06);
    final fw = wdt * (0.09 + r.nextDouble() * 0.05);
    final facet = smoothPath([
      Offset(fx, top - 40),
      Offset(fx + fw, top - 40),
      Offset(fx + fw * 1.4, base),
      Offset(fx + fw * 0.2, base),
    ], closed: true);
    c.drawPath(facet, Paint()..color = i < 2 ? _iceLit : (i < 4 ? _iceMid : _iceDeep).withValues(alpha: 0.85));
  }
  // deep shade on the right third
  c.drawRect(Rect.fromLTRB(x0 + wdt * 0.72, top - 20, x1 + 20, base + 20), Paint()..color = _iceMid.withValues(alpha: 0.55));
  // light streaks
  final st = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3
    ..color = const Color(0xFFE9FBFF);
  for (var i = 0; i < 6; i++) {
    final sx = x0 + wdt * (0.08 + r.nextDouble() * 0.6);
    final sy = top + (base - top) * (0.35 + r.nextDouble() * 0.45);
    final len = h * (0.025 + r.nextDouble() * 0.035);
    c.drawLine(Offset(sx, sy), Offset(sx + len * 0.25, sy + len), st);
  }
  // deep foot
  c.drawRect(Rect.fromLTRB(x0 - 10, base - (base - top) * 0.12, x1 + 10, base + 10), Paint()..color = _iceDeep.withValues(alpha: 0.7));
  c.restore();
  // snow cap on top following the edge
  final capPts = <Offset>[for (var i = 1; i < pts.length - 1; i++) pts[i]];
  final capLow = <Offset>[for (var i = capPts.length - 1; i >= 0; i--) Offset(capPts[i].dx, capPts[i].dy + h * (0.016 + (i % 2) * 0.012))];
  final cap = smoothPath([...capPts, ...capLow], closed: true);
  c.drawPath(cap, Paint()..color = _snow);
  c
    ..save()
    ..clipPath(cap)
    ..drawRect(Rect.fromLTRB(x0 + wdt * 0.62, top - 40, x1 + 20, base), Paint()..color = _snowShade)
    ..restore();
}

void _cliffs(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _iceCliff(c, s, x0: -w * 0.1, x1: w * 0.34, top: h * 0.3, base: h * 0.62, seed: 5);
  _iceCliff(c, s, x0: w * 0.78, x1: w * 1.1, top: h * 0.4, base: h * 0.62, seed: 9, flip: true);
}

// ---------------------------------------------------------------- forest

void _forest(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(21);
  final rows = [
    (0.56, 0.062, _pineFar, Color(0xFF7DAFBA), 0.0),
    (0.595, 0.085, _pineMid, Color(0xFF3F8691), 0.0),
    (0.64, 0.11, _pineNear, Color(0xFF174B57), 0.0),
  ];
  for (var row = 0; row < rows.length; row++) {
    final (y, ph, col, sh, _) = rows[row];
    // snowy rise under the trees
    final rise = Ridge(s, y: y + 0.012, amp: 0.008, freq: 2.4, seed: 60 + row);
    var x = -w * 0.06;
    while (x < w * 1.06) {
      final th = h * (ph + r.nextDouble() * ph * 0.5);
      _snowPine(c, Offset(x, rise.yAt(x) + 4), th, color: col, shade: sh, snow: _snow, snowShade: row == 0 ? _snowShade : _snowShade2, tiers: row == 0 ? 3 : 4);
      x += th * (0.34 + r.nextDouble() * 0.2);
    }
    flatRidge(c, rise, row == 0 ? const Color(0xFFE4F0FB) : (row == 1 ? const Color(0xFFD6E7F8) : const Color(0xFFC8DDF3)), bottomY: h * 0.75);
  }
  // frosted tint on a few trees
  final rr = rng(4);
  for (var i = 0; i < 10; i++) {
    final x = rr.nextDouble() * w;
    c.drawCircle(Offset(x, h * (0.585 + rr.nextDouble() * 0.04)), 1.8, Paint()..color = _pineFrost);
  }
}

// ---------------------------------------------------------------- lake

void _lakeLayer(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // snowy shore
  final shore = Ridge(s, y: 0.665, amp: 0.012, freq: 1.6, seed: 71, x0: -0.15, x1: 1.15);
  flatRidge(c, shore, _dune, light: _snow, band: 3, bottomY: h * 1.1);
  // the lake: wide rounded ellipse-like shape
  final lakePath = smoothPath([
    Offset(-w * 0.15, h * 0.74),
    Offset(w * 0.02, h * 0.7),
    Offset(w * 0.26, h * 0.685),
    Offset(w * 0.55, h * 0.69),
    Offset(w * 0.85, h * 0.695),
    Offset(w * 1.1, h * 0.715),
    Offset(w * 1.15, h * 0.8),
    Offset(w * 0.9, h * 0.85),
    Offset(w * 0.5, h * 0.865),
    Offset(w * 0.1, h * 0.85),
    Offset(-w * 0.15, h * 0.82),
  ], closed: true);
  c.drawPath(lakePath.shift(const Offset(0, 4)), Paint()..color = _duneShade);
  c.drawPath(lakePath, Paint()..color = _lake);
  c
    ..save()
    ..clipPath(lakePath);
  c.drawRect(Rect.fromLTWH(0, h * 0.68, w, h * 0.03), Paint()..color = _lakeDeep.withValues(alpha: 0.45));
  // lighter ice bands
  for (var i = 0; i < 4; i++) {
    final y = h * (0.72 + i * 0.03);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * (0.05 + (i % 2) * 0.3), y, w * (0.5 + (i % 3) * 0.1), 4), const Radius.circular(2)), Paint()..color = _lakeLight.withValues(alpha: 0.75));
  }
  // crack lines
  final crack = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6
    ..color = _snow.withValues(alpha: 0.85);
  final cr = rng(6);
  for (var i = 0; i < 4; i++) {
    var p = Offset(w * (0.12 + cr.nextDouble() * 0.76), h * (0.76 + cr.nextDouble() * 0.08));
    final path = Path()..moveTo(p.dx, p.dy);
    for (var j = 0; j < 4; j++) {
      p = p + Offset((cr.nextDouble() - 0.4) * 34, (cr.nextDouble() - 0.5) * 16);
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, crack);
  }
  c.restore();
}

void _lakeGlints(Canvas c, Size s, Clock k) {
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.0, 0.74, 1.0, 0.85), count: 20, seed: 4, cycles: 8);
}

void _mistLow(Canvas c, Size s) {
  final w = s.width, h = s.height;
  for (var i = 0; i < 3; i++) {
    softEllipse(c, Offset(w * (i + 0.5) / 3, h * 0.655), w * 0.75, h * 0.05, const Color(0xFFF2FAFF), 0.4);
  }
}

// ---------------------------------------------------------------- foreground

void _foreground(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // left knoll with cabin
  final back = Ridge(s, y: 0.905, amp: 0.012, freq: 1.2, seed: 91, tilt: 0.02);
  flatRidge(c, back, _dune, light: _snow, band: 3);
  final front = Ridge(s, y: 0.955, amp: 0.012, freq: 1.5, seed: 93, tilt: -0.02);
  flatRidge(c, front, _duneFront, light: _snow, band: 2);
  // snow shading drifts (flat shade strips)
  final sh = Ridge(s, y: 0.935, amp: 0.008, freq: 1.8, seed: 95);
  c.drawPath(sh.fill(h * 0.96), Paint()..color = _snowShade.withValues(alpha: 0.4));
  flatRidge(c, front, _duneFront, light: _snow, band: 2);

  _cabin(c, Offset(w * 0.3, back.yAt(w * 0.3) + 6), w * 0.2);

  // foreground pines at the corners, big and dark
  _snowPine(c, Offset(w * -0.02, h * 1.0), h * 0.3, color: _pineNear, shade: const Color(0xFF133F4A), snow: _snow, snowShade: _snowShade2, width: 0.55, tiers: 5);
  _snowPine(c, Offset(w * 0.07, h * 1.02), h * 0.15, color: _pineNear, shade: const Color(0xFF133F4A), snow: _snow, snowShade: _snowShade2, width: 0.55, tiers: 4);
  _snowPine(c, Offset(w * 1.0, h * 1.0), h * 0.34, color: _pineNear, shade: const Color(0xFF133F4A), snow: _snow, snowShade: _snowShade2, width: 0.55, tiers: 5);
  _snowPine(c, Offset(w * 0.89, h * 1.02), h * 0.19, color: _pineMid, shade: _pineNear, snow: _snow, snowShade: _snowShade2, width: 0.55, tiers: 4);

  // a few snow-capped rocks and little snow mounds
  flatRock(c, Offset(w * 0.62, h * 0.97), w * 0.16, h * 0.03, color: const Color(0xFF8FA8CC), shade: const Color(0xFF6F8CB8), seed: 3);
  c.drawOval(Rect.fromCenter(center: Offset(w * 0.62, h * 0.945), width: w * 0.13, height: h * 0.014), Paint()..color = _snow);
  flatRock(c, Offset(w * 0.45, h * 0.99), w * 0.1, h * 0.022, color: const Color(0xFF8FA8CC), shade: const Color(0xFF6F8CB8), seed: 7);
  // snow sparkle dots (static base)
  final r = rng(33);
  for (var i = 0; i < 20; i++) {
    c.drawCircle(Offset(r.nextDouble() * w, h * (0.9 + r.nextDouble() * 0.09)), 1.2, Paint()..color = _skyA.withValues(alpha: 0.5));
  }
}

void _cabin(Canvas c, Offset base, double w) {
  final h = w * 0.62;
  const wall = Color(0xFF8A5A47), wallShade = Color(0xFF6B4437);
  final wallRect = RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - w / 2, base.dy - h * 0.55, w, h * 0.55), const Radius.circular(2));
  c.drawRRect(wallRect, Paint()..color = wall);
  c.drawRect(Rect.fromLTWH(base.dx + w * 0.12, base.dy - h * 0.55, w * 0.38, h * 0.55), Paint()..color = wallShade);
  // chimney
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + w * 0.18, base.dy - h * 1.12, w * 0.1, h * 0.4), const Radius.circular(1.5)), Paint()..color = const Color(0xFF6A5A5E));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + w * 0.16, base.dy - h * 1.15, w * 0.14, h * 0.07), const Radius.circular(2)), Paint()..color = _snow);
  // roof
  final roof = Path()
    ..moveTo(base.dx - w * 0.6, base.dy - h * 0.5)
    ..quadraticBezierTo(base.dx - w * 0.3, base.dy - h * 0.78, base.dx, base.dy - h * 1.05)
    ..quadraticBezierTo(base.dx + w * 0.3, base.dy - h * 0.78, base.dx + w * 0.6, base.dy - h * 0.5)
    ..close();
  c.drawPath(roof, Paint()..color = const Color(0xFF4A6FA5));
  c
    ..save()
    ..clipPath(roof)
    ..drawRect(Rect.fromLTRB(base.dx + w * 0.04, base.dy - h * 1.2, base.dx + w, base.dy), Paint()..color = const Color(0xFF3A5A8E))
    ..restore();
  // snow on roof
  final snow = Path()
    ..moveTo(base.dx - w * 0.62, base.dy - h * 0.5)
    ..quadraticBezierTo(base.dx - w * 0.3, base.dy - h * 0.8, base.dx, base.dy - h * 1.08)
    ..quadraticBezierTo(base.dx + w * 0.3, base.dy - h * 0.8, base.dx + w * 0.62, base.dy - h * 0.5)
    ..quadraticBezierTo(base.dx + w * 0.5, base.dy - h * 0.58, base.dx + w * 0.38, base.dy - h * 0.6)
    ..quadraticBezierTo(base.dx + w * 0.22, base.dy - h * 0.52, base.dx + w * 0.1, base.dy - h * 0.66)
    ..quadraticBezierTo(base.dx - w * 0.1, base.dy - h * 0.58, base.dx - w * 0.2, base.dy - h * 0.7)
    ..quadraticBezierTo(base.dx - w * 0.4, base.dy - h * 0.55, base.dx - w * 0.62, base.dy - h * 0.5)
    ..close();
  c.drawPath(snow, Paint()..color = _snow);
  c
    ..save()
    ..clipPath(snow)
    ..drawRect(Rect.fromLTRB(base.dx + w * 0.04, base.dy - h * 1.2, base.dx + w, base.dy), Paint()..color = _snowShade)
    ..restore();
  // warm windows and door
  const glowC = Color(0xFFFFD27A);
  c.drawCircle(Offset(base.dx - w * 0.22, base.dy - h * 0.3), w * 0.12, Paint()..color = glowC.withValues(alpha: 0.28));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx - w * 0.22, base.dy - h * 0.3), width: w * 0.15, height: w * 0.15), const Radius.circular(2)), Paint()..color = glowC);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx + w * 0.3, base.dy - h * 0.3), width: w * 0.13, height: w * 0.13), const Radius.circular(2)), Paint()..color = const Color(0xFFFFE9A8));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - w * 0.06, base.dy - h * 0.38, w * 0.13, h * 0.38), Radius.circular(w * 0.04)), Paint()..color = const Color(0xFF4B2F28));
  // snow drift at the foot
  c.drawOval(Rect.fromCenter(center: Offset(base.dx - w * 0.1, base.dy + 1), width: w * 1.3, height: h * 0.16), Paint()..color = _snow);
}

// ---------------------------------------------------------------- live

void _smoke(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final ww = w * 0.2;
  final ch = Offset(w * 0.3 + ww * 0.23, h * 0.905 + 6 - ww * 0.62 * 1.12);
  // the cabin layer drifts a little; smoke offset follows approx via its own sway
  for (var i = 0; i < 5; i++) {
    final t = k.saw(6, i / 5);
    final x = ch.dx + math.sin(tau * (t * 1.2 + i * 0.2)) * 5 + t * 16;
    final y = ch.dy - t * h * 0.09;
    final r = (3 + t * 8) * w / 390;
    final a = (1 - t) * math.min(1.0, t * 6) * 0.8;
    c.drawCircle(Offset(x, y), r, Paint()..color = Colors.white.withValues(alpha: a));
  }
}

void _snowFar(Canvas c, Size s, Clock k) {
  paintParticles(
    c,
    s,
    k,
    const ParticleSpec(count: 48, seed: 21, colors: [Color(0xFFFFFFFF), Color(0xFFEAF6FF)], minSize: 0.8, maxSize: 1.7, flow: Offset(0.04, 1.0), cycles: 5, spread: 2, wander: 8, wanderCycles: 2, shape: ParticleShape.snow, fade: 0.06, opacity: 0.85),
  );
}

void _snowNear(Canvas c, Size s, Clock k) {
  paintParticles(
    c,
    s,
    k,
    const ParticleSpec(count: 26, seed: 44, colors: [Color(0xFFFFFFFF)], minSize: 2.2, maxSize: 4.0, flow: Offset(0.08, 1.0), cycles: 10, spread: 3, wander: 16, wanderCycles: 2, shape: ParticleShape.snow, fade: 0.05, opacity: 0.95),
  );
}

void _sparkles(Canvas c, Size s, Clock k) {
  paintStars(c, s, k, count: 22, seed: 77, region: const Rect.fromLTRB(0.0, 0.5, 1.0, 0.98), twinkleCycles: 9, sparkleShare: 0.5, minR: 0.6, maxR: 1.4, color: const Color(0xFFFFFFFF));
  paintStars(c, s, k, count: 10, seed: 78, region: const Rect.fromLTRB(0.0, 0.3, 0.35, 0.58), twinkleCycles: 11, sparkleShare: 0.7, minR: 0.8, maxR: 1.5, color: const Color(0xFFFFFFFF));
}
