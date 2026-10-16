import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit.dart';

// Ancient Ruins in flat, graphic 2D: colossal fluted pillars and a broken
// arch wrapped in moss, a quiet waterfall from a crumbled terrace wall, mist
// between the planes and golden shafts of light falling through the gap in the
// arch while dust motes drift in them. Flat colours, two-tone cel shading.
// Light comes from the upper right: shade is always on the left of a form.

const _sunPos = Offset(0.79, 0.14);

// palette
const _skyA = Color(0xFF86BCE8), _skyB = Color(0xFFBFD9F0), _skyC = Color(0xFFFFEBC2), _skyD = Color(0xFFFFF4DA);
const _mist = Color(0xFFF5EAD0), _haze = Color(0xFFD3DEE6);
const _sandL = Color(0xFFDDC89C), _sandS = Color(0xFF9A8A6A), _deep = Color(0xFF4A4338);
const _stoneL = Color(0xFF9AA09A), _stoneS = Color(0xFF6C7370);
const _mossD = Color(0xFF3F8450), _moss = Color(0xFF5FA05A), _mossL = Color(0xFF93CC72);
const _gold = Color(0xFFFFD98A);
const _water = Color(0xFF8FDCD2), _waterL = Color(0xFFDDF6EE), _waterD = Color(0xFF5FB9B2);

double _lerp(double a, double b, double t) => a + (b - a) * t;

Color _hz(Color c, double amt) => hazeTo(c, _haze, amt);

SceneSpec ruinsScene() => SceneSpec(
      focusY: -0.42,
      topShade: 0.2,
      bottomShade: 0.3,
      layers: [
        Layer.still(_sky),
        Layer.scroll(_clouds, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.36),
        Layer.still(_sun),
        Layer.still(_far, driftX: 0.004, driftCycles: 2),
        Layer.scroll(_mistFar, scrollCycles: 1, scrollLeft: false, bandTop: 0.42, bandBottom: 0.66),
        Layer.still(_mid, driftX: 0.009, driftCycles: 2, driftPhase: 0.1),
        Layer.scroll(_mistMid, scrollCycles: 2, bandTop: 0.56, bandBottom: 0.8),
        Layer.still(_hero, driftX: 0.016, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_light),
        Layer.still(_ground, driftX: 0.026, driftCycles: 2, driftPhase: 0.25),
        Layer.live(_waterFx),
        Layer.still(_vines, driftX: 0.016, driftCycles: 2, driftPhase: 0.15, sway: 0.012, swayCycles: 5, pivot: Alignment.topCenter),
        Layer.live(_dust),
        Layer.live(_skyLife),
      ],
    );

// ---------------------------------------------------------------- helpers

/// Polygon with rounded corners (radius [r]).
Path _rpoly(List<Offset> p, double r) {
  final n = p.length;
  final path = Path();
  for (var i = 0; i < n; i++) {
    final a = p[(i - 1 + n) % n], b = p[i], c = p[(i + 1) % n];
    final d1 = a - b, d2 = c - b;
    final l1 = d1.distance, l2 = d2.distance;
    final rr = math.min(r, math.min(l1, l2) / 2);
    final s1 = b + d1 / l1 * rr, s2 = b + d2 / l2 * rr;
    if (i == 0) {
      path.moveTo(s1.dx, s1.dy);
    } else {
      path.lineTo(s1.dx, s1.dy);
    }
    path.quadraticBezierTo(b.dx, b.dy, s2.dx, s2.dy);
  }
  path.close();
  return path;
}

Paint _fill(Color c) => Paint()..color = c;

/// Draws [shape] in [lit], then the part left of [edgeX] in [shade] (hard edge).
void _twoTone(Canvas c, Path shape, Color lit, Color shade, double edgeX) {
  c.drawPath(shape, _fill(lit));
  final b = shape.getBounds();
  c
    ..save()
    ..clipPath(shape)
    ..drawRect(Rect.fromLTRB(b.left - 2, b.top - 2, edgeX, b.bottom + 2), _fill(shade))
    ..restore();
}

/// A lumpy cap of moss: flat dark green with a flat lighter crescent on the lit (upper right) side.
void _mossBlob(Canvas c, Offset o, double r, {double angle = 0, double haze = 0}) {
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(angle);
  final p = Path()
    ..addOval(Rect.fromCenter(center: Offset(-r * 0.55, r * 0.05), width: r * 1.5, height: r * 1.0))
    ..addOval(Rect.fromCenter(center: Offset(r * 0.1, -r * 0.1), width: r * 1.9, height: r * 1.3))
    ..addOval(Rect.fromCenter(center: Offset(r * 0.75, r * 0.05), width: r * 1.3, height: r * 0.9));
  c.drawPath(p, _fill(_hz(_mossL, haze)));
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(-r * 0.12, r * 0.2)), _fill(_hz(_moss, haze)))
    ..drawPath(p.shift(Offset(-r * 0.3, r * 0.45)), _fill(_hz(_mossD, haze)))
    ..restore()
    ..restore();
}

void _mossRow(Canvas c, double x0, double x1, double y, double size, int seed, {double haze = 0}) {
  final r = rng(seed);
  var x = x0;
  while (x < x1) {
    final rad = size * (0.8 + r.nextDouble() * 0.6);
    _mossBlob(c, Offset(x, y - rad * 0.2), rad, haze: haze);
    x += rad * (1.5 + r.nextDouble() * 0.7);
  }
}

/// A colossal fluted pillar; [base] is the centre of its foot. Light from the right.
void _pillar(
  Canvas c,
  Offset base,
  double h,
  double w, {
  required Color lit,
  required Color shade,
  bool broken = false,
  double lean = 0,
  bool moss = true,
  double haze = 0,
  int seed = 1,
}) {
  final r = rng(seed);
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(lean);
  final hw0 = w * 0.5, hw1 = w * 0.43;
  final foot = w * 0.16;
  final capH = broken ? 0.0 : w * 0.36;
  final top = -h + capH;
  // plinth
  _twoTone(c, _rpoly([Offset(-w * 0.64, -foot), Offset(w * 0.64, -foot), Offset(w * 0.68, 0), Offset(-w * 0.68, 0)], 3), lit, shade, -w * 0.02);
  // shaft
  final Path shaft;
  if (broken) {
    shaft = _rpoly([
      Offset(-hw0, -foot + 2),
      Offset(-hw1, top + w * 0.7),
      Offset(-hw1 * 0.55, top + w * 0.46),
      Offset(-hw1 * 0.1, top + w * 0.6),
      Offset(hw1 * 0.25, top + w * 0.12),
      Offset(hw1 * 0.65, top),
      Offset(hw1, top + w * 0.3),
      Offset(hw0, -foot + 2),
    ], w * 0.05);
  } else {
    shaft = _rpoly([Offset(-hw0, -foot + 2), Offset(-hw1, top), Offset(hw1, top), Offset(hw0, -foot + 2)], 2);
  }
  _twoTone(c, shaft, lit, shade, -w * 0.04);
  c
    ..save()
    ..clipPath(shaft);
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, w * 0.022);
  for (final fx in [-0.32, -0.16, 0.1, 0.26]) {
    line.color = (fx < 0 ? _deep : _sandS).withValues(alpha: fx < 0 ? 0.2 : 0.4);
    c.drawLine(Offset(w * fx, top), Offset(w * fx * 1.12, -foot), line);
  }
  // drum joints
  line
    ..strokeWidth = math.max(1.0, w * 0.025)
    ..color = _deep.withValues(alpha: 0.22);
  for (var y = -foot - w * 1.15; y > top + w * 0.3; y -= w * (1.0 + r.nextDouble() * 0.5)) {
    c.drawPath(
      Path()
        ..moveTo(-hw0, y)
        ..quadraticBezierTo(0, y + w * 0.07, hw0, y),
      line,
    );
  }
  // weathering: pale stains, a crack and a chipped edge
  final cx0 = w * (0.12 + r.nextDouble() * 0.15), cy0 = top + (h - capH) * (0.3 + r.nextDouble() * 0.3);
  c.drawPath(
    Path()
      ..moveTo(cx0, cy0)
      ..lineTo(cx0 - w * 0.06, cy0 + w * 0.22)
      ..lineTo(cx0 + w * 0.02, cy0 + w * 0.4)
      ..lineTo(cx0 - w * 0.05, cy0 + w * 0.7),
    line
      ..strokeWidth = math.max(1.2, w * 0.03)
      ..color = _deep.withValues(alpha: 0.45),
  );
  // moss creeping up the base
  if (moss) {
    for (var i = 0; i < 4; i++) {
      _mossBlob(c, Offset(-hw0 * 0.6 + i * w * 0.3, -foot + w * 0.04), w * (0.12 + r.nextDouble() * 0.08), haze: haze);
    }
  }
  c.restore();
  // capital
  if (!broken) {
    final s = top;
    _twoTone(c, _rpoly([Offset(-hw1, s + 1), Offset(hw1, s + 1), Offset(w * 0.58, s - w * 0.18), Offset(-w * 0.58, s - w * 0.18)], w * 0.05), lit, shade, -w * 0.04);
    _twoTone(c, _rr(RRect.fromRectAndRadius(Rect.fromLTRB(-w * 0.66, s - w * 0.34, w * 0.66, s - w * 0.16), Radius.circular(w * 0.05))), lit, shade, -w * 0.04);
  }
  if (moss) {
    final topY = broken ? top + w * 0.1 : top - w * 0.34;
    final n = 3 + r.nextInt(2);
    for (var i = 0; i < n; i++) {
      final x = -w * 0.45 + w * 0.9 * (i + 0.5) / n;
      _mossBlob(c, Offset(x, topY + (broken ? w * 0.28 * (1 - (i / n)) : 0) + w * 0.02), w * (0.1 + r.nextDouble() * 0.07), haze: haze);
    }
    // drips down the shaded side
    for (var i = 0; i < 3; i++) {
      final x = -w * (0.1 + r.nextDouble() * 0.36);
      final len = w * (0.22 + r.nextDouble() * 0.45);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, topY + w * 0.2, w * 0.07, len), Radius.circular(w * 0.035)), _fill(_hz(_moss, haze)));
    }
  }
  c.restore();
}

Path _rr(RRect r) => Path()..addRRect(r);

Path _ringPath(Offset c, double outer, double inner, double a0, double a1) {
  final p = Path()..arcTo(Rect.fromCircle(center: c, radius: outer), a0, a1 - a0, true);
  final e = c + Offset(math.cos(a1), math.sin(a1)) * inner;
  p.lineTo(e.dx, e.dy);
  p.arcTo(Rect.fromCircle(center: c, radius: inner), a1, a0 - a1, false);
  p.close();
  return p;
}

/// Wall with round-headed openings (an aqueduct / arcade).
void _arcade(Canvas c, double x0, double x1, double baseY, double hgt, int n, Color lit, Color shade, {double pier = 0.34}) {
  final wall = Path()..fillType = PathFillType.evenOdd;
  wall.addPath(_rpoly([Offset(x0, baseY), Offset(x0, baseY - hgt), Offset(x1, baseY - hgt), Offset(x1, baseY)], 2), Offset.zero);
  final span = (x1 - x0) / n;
  final opW = span * (1 - pier);
  final openings = <Path>[];
  for (var i = 0; i < n; i++) {
    final cx = x0 + span * (i + 0.5);
    final top = baseY - hgt * 0.78;
    final o = Path()
      ..moveTo(cx - opW / 2, baseY + 1)
      ..lineTo(cx - opW / 2, top + opW / 2)
      ..arcTo(Rect.fromCircle(center: Offset(cx, top + opW / 2), radius: opW / 2), math.pi, math.pi, false)
      ..lineTo(cx + opW / 2, baseY + 1)
      ..close();
    openings.add(o);
    wall.addPath(o, Offset.zero);
  }
  c.drawPath(wall, _fill(lit));
  c
    ..save()
    ..clipPath(wall);
  for (final o in openings) {
    c.drawPath(o.shift(Offset(-span * 0.1, 0)), _fill(shade));
  }
  c.drawRect(Rect.fromLTRB(x0, baseY - hgt, x1, baseY - hgt + hgt * 0.07), _fill(shade));
  c.restore();
}

void _steps(Canvas c, double cx, double baseY, double w, double h, int n, Color lit, Color shade, {double shrink = 0.07}) {
  for (var i = 0; i < n; i++) {
    final tw = w * (1 - shrink * i);
    final y = baseY - h * (i + 1) / n;
    final sh = h / n;
    // top face (lit) and front face (shade)
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - tw / 2, y, tw, sh + 1), Radius.circular(sh * 0.25)), _fill(lit));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - tw / 2, y + sh * 0.36, tw, sh * 0.64 + 1), Radius.circular(sh * 0.2)), _fill(shade));
  }
}

void _leaf(Canvas c, Offset base, double len, double angle, Color color, Color shade) {
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angle);
  final w = len * 0.27;
  final p = Path()
    ..moveTo(0, 0)
    ..cubicTo(-w * 1.3, -len * 0.25, -w * 1.1, -len * 0.75, 0, -len)
    ..cubicTo(w * 1.1, -len * 0.75, w * 1.3, -len * 0.25, 0, 0)
    ..close();
  c.drawPath(p, _fill(color));
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(-w * 2, -len, 0.02 * len, 0), _fill(shade))
    ..restore()
    ..restore();
}

void _plant(Canvas c, Offset base, double len, int n, {double spread = 1.5, Color color = _moss, Color shade = _mossD, int seed = 1}) {
  final r = rng(seed);
  for (var i = 0; i < n; i++) {
    final t = n == 1 ? 0.0 : (i / (n - 1) - 0.5);
    _leaf(c, base, len * (0.7 + r.nextDouble() * 0.4), t * spread + (r.nextDouble() - 0.5) * 0.2, i.isEven ? color : mix(color, _mossL, 0.4), shade);
  }
}

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_skyA, _skyB, _skyC, _skyD], const [0.0, 0.3, 0.55, 1.0]);
}

void _sun(Canvas c, Size s) {
  final o = Offset(_sunPos.dx * s.width, _sunPos.dy * s.height);
  flatSun(c, o, s.width * 0.06, core: const Color(0xFFFFF8DE), halo: _gold);
}

void _clouds(Canvas c, Size s) {
  final r = rng(11);
  for (var i = 0; i < 3; i++) {
    final x = (i + 0.25 + r.nextDouble() * 0.5) * s.width / 3;
    flatCloud(c, Offset(x, s.height * (0.12 + r.nextDouble() * 0.12)), s.width * (0.4 + r.nextDouble() * 0.16), color: const Color(0xFFFFFBF0), shade: const Color(0xFFE6E3EC), seed: i + 5, puff: 1.0);
  }
  flatCloud(c, Offset(s.width * 0.55, s.height * 0.31), s.width * 0.3, color: const Color(0xFFFFF6E4), shade: const Color(0xFFF0E2D0), seed: 41, puff: 0.8);
}

// ---------------------------------------------------------------- far plane

void _far(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final lit = _hz(_sandL, 0.55), shade = _hz(_sandS, 0.55);
  // distant blue hills
  final hills = Ridge(s, y: 0.5, amp: 0.02, freq: 1.6, seed: 9, octaves: 2);
  flatRidge(c, hills, _hz(_stoneL, 0.78), light: _hz(_sandL, 0.82), band: 3);
  // ziggurat
  _steps(c, w * 0.62, h * 0.53, w * 0.4, h * 0.25, 6, lit, shade, shrink: 0.15);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.62, h * 0.27), width: w * 0.1, height: h * 0.04), Radius.circular(3)), _fill(lit));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.62 - w * 0.05, h * 0.25, w * 0.62 - w * 0.01, h * 0.29), const Radius.circular(3)), _fill(shade));
  // aqueduct
  _arcade(c, -w * 0.05, w * 0.46, h * 0.52, h * 0.1, 6, lit, shade);
  // slim far columns
  for (final (x, t) in [(0.5, 0.4), (0.545, 0.43), (0.585, 0.37)]) {
    _pillar(c, Offset(w * x, h * 0.52), h * (0.52 - t), w * 0.03, lit: lit, shade: shade, moss: false, seed: (x * 100).round());
  }
  // far trees
  final r = rng(3);
  for (var i = 0; i < 9; i++) {
    final x = w * (0.02 + i * 0.12 + r.nextDouble() * 0.06);
    flatTree(c, Offset(x, hills.yAt(x) + 6), h * (0.05 + r.nextDouble() * 0.03), crown: _hz(_moss, 0.7), light: _hz(_mossL, 0.7), trunk: _hz(_sandS, 0.7), seed: i + 2);
  }
  c.drawRect(Rect.fromLTRB(-w * 0.1, h * 0.52, w * 1.1, h * 1.1), _fill(_hz(_stoneL, 0.72)));
}

void _mistFar(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(5);
  for (var i = 0; i < 4; i++) {
    final x = (i + 0.5) * w / 4;
    softEllipse(c, Offset(x, h * (0.52 + r.nextDouble() * 0.08)), w * 0.6, h * 0.07, _mist, 0.6);
  }
  paintMist(c, Rect.fromLTRB(0, h * 0.46, w, h * 0.64), _mist, 0.45);
}

// ---------------------------------------------------------------- mid plane

void _mid(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final lit = _hz(_sandL, 0.4), shade = _hz(_sandS, 0.36);
  final stoneL = _hz(_stoneL, 0.38), stoneS = _hz(_stoneS, 0.34);
  final groundY = h * 0.64;

  // facade on the right: back wall, columns, broken entablature
  final back = _rpoly([Offset(w * 0.52, groundY), Offset(w * 0.52, h * 0.42), Offset(w * 0.9, h * 0.41), Offset(w * 1.1, h * 0.46), Offset(w * 1.1, groundY)], 5);
  c.drawPath(back, _fill(_hz(_sandS, 0.5)));
  // dark doorway
  c.drawRRect(RRect.fromRectAndCorners(Rect.fromLTRB(w * 0.72, h * 0.5, w * 0.84, groundY + 2), topLeft: Radius.circular(w * 0.06), topRight: Radius.circular(w * 0.06)), _fill(mix(_hz(_sandS, 0.3), _deep, 0.5)));
  // courses and window slits on the back wall
  final wl = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = _hz(_deep, 0.4).withValues(alpha: 0.22);
  for (var i = 0; i < 6; i++) {
    c.drawLine(Offset(w * 0.52, h * (0.45 + i * 0.03)), Offset(w * 1.1, h * (0.45 + i * 0.03)), wl);
  }
  for (final x in [0.6, 0.66, 0.9]) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * x, h * 0.46, w * 0.022, h * 0.045), Radius.circular(w * 0.011)), _fill(mix(_hz(_sandS, 0.3), _deep, 0.4)));
  }
  final cols = <(double, double, bool)>[(0.56, 0.37, false), (0.645, 0.385, false), (0.93, 0.375, true), (1.0, 0.4, false)];
  for (final (x, t, br) in cols) {
    _pillar(c, Offset(w * x, groundY), h * (0.64 - t), w * 0.06, lit: lit, shade: shade, broken: br, haze: 0.38, seed: (x * 91).round());
  }
  // entablature slab (broken on the right)
  final slab = _rpoly([Offset(w * 0.52, h * 0.335), Offset(w * 0.52, h * 0.37), Offset(w * 0.66, h * 0.37), Offset(w * 0.69, h * 0.355), Offset(w * 0.66, h * 0.335)], 3);
  _twoTone(c, slab, lit, shade, w * 0.545);
  _mossRow(c, w * 0.52, w * 0.67, h * 0.337, w * 0.016, 7, haze: 0.38);
  // trees on the ruin
  flatTree(c, Offset(w * 0.6, h * 0.336), h * 0.09, crown: _hz(_moss, 0.4), light: _hz(_mossL, 0.4), trunk: _hz(_sandS, 0.3), seed: 21);

  // terrace cliff on the left (waterfall source)
  final cliff = _rpoly([
    Offset(-w * 0.1, groundY + 10),
    Offset(-w * 0.1, h * 0.31),
    Offset(w * 0.1, h * 0.3),
    Offset(w * 0.12, h * 0.285),
    Offset(w * 0.3, h * 0.285),
    Offset(w * 0.33, h * 0.3),
    Offset(w * 0.42, h * 0.3),
    Offset(w * 0.45, h * 0.35),
    Offset(w * 0.5, h * 0.36),
    Offset(w * 0.53, groundY + 10),
  ], 5);
  _twoTone(c, cliff, stoneL, stoneS, w * 0.19);
  c
    ..save()
    ..clipPath(cliff);
  // shadow band under the lip and block courses
  c.drawRect(Rect.fromLTRB(-w * 0.1, h * 0.31, w * 0.6, h * 0.335), _fill(_hz(_deep, 0.45).withValues(alpha: 0.35)));
  final course = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = _hz(_deep, 0.4).withValues(alpha: 0.3);
  final rr = rng(31);
  for (var row = 0; row < 8; row++) {
    final y = h * (0.35 + row * 0.036);
    c.drawLine(Offset(-w * 0.1, y), Offset(w * 0.6, y), course);
    var x = -w * 0.1 + rr.nextDouble() * w * 0.06;
    while (x < w * 0.55) {
      c.drawLine(Offset(x, y), Offset(x, y + h * 0.036), course);
      x += w * (0.07 + rr.nextDouble() * 0.06);
    }
  }
  c.restore();
  _mossRow(c, w * 0.0, w * 0.2, h * 0.3, w * 0.022, 3, haze: 0.3);
  _mossRow(c, w * 0.3, w * 0.52, h * 0.3, w * 0.022, 8, haze: 0.3);
  // mossy drips down the cliff face
  for (final (x, len) in [(0.1, 0.07), (0.15, 0.04), (0.33, 0.09), (0.38, 0.05), (0.02, 0.05)]) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * x, h * 0.3, w * 0.014, h * len), Radius.circular(w * 0.007)), _fill(_hz(_moss, 0.3)));
  }
  // broken colonnade on the cliff top
  _pillar(c, Offset(w * 0.34, h * 0.298), h * 0.15, w * 0.052, lit: lit, shade: shade, haze: 0.34, seed: 5);
  _pillar(c, Offset(w * 0.41, h * 0.305), h * 0.085, w * 0.052, lit: lit, shade: shade, broken: true, haze: 0.34, seed: 6);
  _pillar(c, Offset(w * 0.23, h * 0.286), h * 0.06, w * 0.05, lit: lit, shade: shade, broken: true, haze: 0.34, seed: 12, lean: 0.05);

  // waterfall (body); streaks are animated in _waterFx
  final fx0 = w * 0.205, fx1 = w * 0.275;
  final fall = Path()
    ..moveTo(fx0 - 3, h * 0.283)
    ..quadraticBezierTo(fx0 - 4, h * 0.3, fx0, h * 0.31)
    ..lineTo(fx0 - 2, h * 0.84)
    ..lineTo(fx1 + 3, h * 0.84)
    ..lineTo(fx1, h * 0.31)
    ..quadraticBezierTo(fx1 + 4, h * 0.3, fx1 + 3, h * 0.283)
    ..close();
  c.drawPath(fall, _fill(_waterL));
  c
    ..save()
    ..clipPath(fall)
    ..drawRect(Rect.fromLTRB(fx0 - 6, h * 0.28, fx0 + (fx1 - fx0) * 0.38, h * 0.85), _fill(_hz(_water, 0.1)))
    ..restore();
  // spout stone
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(fx0 - 8, h * 0.274, fx1 + 8, h * 0.292), const Radius.circular(5)), _fill(stoneL));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(fx0 - 8, h * 0.274, fx0 + 10, h * 0.292), const Radius.circular(5)), _fill(stoneS));
  flatBush(c, Offset(fx0 - 12, h * 0.282), w * 0.07, color: _hz(_mossD, 0.3), light: _hz(_moss, 0.3), seed: 4);
  flatBush(c, Offset(fx1 + 14, h * 0.282), w * 0.06, color: _hz(_mossD, 0.3), light: _hz(_moss, 0.3), seed: 9);

  // ground of this plane
  final g = Ridge(s, y: 0.64, amp: 0.008, freq: 2.2, seed: 61);
  flatRidge(c, g, _hz(_moss, 0.3), light: _hz(_mossL, 0.3), band: 3);
  // trees
  final r = rng(17);
  for (var i = 0; i < 9; i++) {
    final x = w * (0.04 + i * 0.12 + r.nextDouble() * 0.05);
    if (x > w * 0.5 && x < w * 0.7) continue;
    flatTree(c, Offset(x, g.yAt(x) + 3), h * (0.07 + r.nextDouble() * 0.04), crown: _hz(_moss, 0.46), light: _hz(_mossL, 0.46), trunk: _hz(_sandS, 0.4), seed: i + 40, lean: (r.nextDouble() - 0.5) * 0.4);
  }
  c.drawRect(Rect.fromLTRB(-w * 0.1, h * 0.655, w * 1.1, h * 1.1), _fill(_hz(_moss, 0.3)));
  // low broken walls and column stumps on the lawn
  for (final (x, hh, ww) in [(0.3, 0.014, 0.09), (0.47, 0.03, 0.05), (0.6, 0.012, 0.11), (0.74, 0.02, 0.07)]) {
    final top = h * (0.675 - hh);
    final blk = _rpoly([Offset(w * (x - ww / 2), h * 0.68), Offset(w * (x - ww / 2), top + 6), Offset(w * (x - ww * 0.2), top), Offset(w * (x + ww / 2), top + 4), Offset(w * (x + ww / 2), h * 0.68)], 4);
    _twoTone(c, blk, lit, shade, w * x);
    _mossRow(c, w * (x - ww * 0.4), w * (x + ww * 0.4), top + 3, w * 0.012, (x * 100).round(), haze: 0.3);
  }
}

void _mistMid(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(14);
  for (var i = 0; i < 4; i++) {
    final x = (i + 0.3 + r.nextDouble() * 0.4) * w / 4;
    softEllipse(c, Offset(x, h * (0.62 + r.nextDouble() * 0.1)), w * 0.55, h * 0.07, _mist, 0.42);
  }
}

// ---------------------------------------------------------------- hero: the broken arch

void _hero(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final lit = _sandL, shade = _sandS;
  final baseY = h * 0.84;
  final cy = h * 0.3;
  final centre = Offset(w * 0.5, cy);
  final outer = w * 0.46, inner = w * 0.36, t = outer - inner;

  // pillars
  _pillar(c, Offset(w * 0.09, baseY), baseY - cy, w * 0.17, lit: lit, shade: shade, seed: 2);
  _pillar(c, Offset(w * 0.91, baseY), baseY - cy, w * 0.17, lit: lit, shade: shade, seed: 3);

  // arch ring pieces: left (long) and right (stub); outer half runs further than the inner half
  void piece(double a0, double a1, double extra) {
    final full = _ringPath(centre, outer, inner, a0, a1);
    final outerHalf = _ringPath(centre, outer, inner + t * 0.5, a0, a1 + extra);
    c.drawPath(full, _fill(lit));
    c.drawPath(outerHalf, _fill(lit));
    final under = _ringPath(centre, inner + t * 0.3, inner, a0, a1);
    c.drawPath(under, _fill(shade));
    // keystone joints
    final joint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = shade.withValues(alpha: 0.7);
    for (var a = a0 + 0.07; a < a1 - 0.02; a += 0.085) {
      final p0 = centre + Offset(math.cos(a), math.sin(a)) * (inner + t * 0.3);
      final p1 = centre + Offset(math.cos(a), math.sin(a)) * outer;
      c.drawLine(p0, p1, joint);
    }
    // shade on the left-facing part of the ring face (cel): thin strip on the outer rim
    final rim = _ringPath(centre, outer, outer - t * 0.12, a0, a1);
    c.drawPath(rim, _fill(mix(lit, const Color(0xFFFFF0C8), 0.45)));
  }

  piece(math.pi, math.pi * 1.62, 0.07);
  piece(math.pi * 1.8, math.pi * 2.0, 0.0);
  // moss on the ring
  final r = rng(9);
  for (var a = math.pi * 1.02; a < math.pi * 1.6; a += 0.1 + r.nextDouble() * 0.14) {
    final p = centre + Offset(math.cos(a), math.sin(a)) * (outer - 2);
    _mossBlob(c, p, w * (0.022 + r.nextDouble() * 0.018), angle: a + math.pi / 2);
  }
  for (var a = math.pi * 1.82; a < math.pi * 1.97; a += 0.08 + r.nextDouble() * 0.1) {
    final p = centre + Offset(math.cos(a), math.sin(a)) * (outer - 2);
    _mossBlob(c, p, w * (0.022 + r.nextDouble() * 0.014), angle: a + math.pi / 2);
  }
  // lintel stones fallen at the inner side of the left end
  final endP = centre + Offset(math.cos(math.pi * 1.62), math.sin(math.pi * 1.62)) * ((outer + inner) / 2);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: endP + Offset(w * 0.0, h * 0.028), width: w * 0.04, height: h * 0.018), const Radius.circular(4)), _fill(shade));
}

// ---------------------------------------------------------------- light shafts

(double, double) _shaftAt(Clock k, int i) {
  const base = [1.74, 1.88, 2.0, 2.12, 2.26, 2.42];
  const wid = [0.07, 0.11, 0.06, 0.12, 0.08, 0.1];
  return (base[i] + 0.028 * k.sine(2 + i % 3, i * 0.17), wid[i]);
}

Offset _shaftOrigin(Size s) => Offset(_sunPos.dx * s.width, _sunPos.dy * s.height + s.height * 0.006);

void _light(Canvas c, Size s, Clock k) {
  final o = _shaftOrigin(s);
  final len = s.height * 1.25;
  for (var i = 0; i < 6; i++) {
    final (a, wd) = _shaftAt(k, i);
    final p1 = o + Offset(math.cos(a - wd / 2), math.sin(a - wd / 2)) * len;
    final p2 = o + Offset(math.cos(a + wd / 2), math.sin(a + wd / 2)) * len;
    final mid = o + Offset(math.cos(a), math.sin(a)) * len;
    final pulse = 0.8 + 0.2 * k.sine(3 + i % 2, i * 0.31);
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    c.drawPath(
      path,
      Paint()..shader = ui.Gradient.linear(o, mid, [_gold.withValues(alpha: 0.34 * pulse), _gold.withValues(alpha: 0.17 * pulse), _gold.withValues(alpha: 0.0)], const [0.0, 0.55, 1.0]),
    );
  }
}

// ---------------------------------------------------------------- ground & foreground

void _ground(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // mossy lawn
  final lawn = Ridge(s, y: 0.805, amp: 0.012, freq: 1.8, seed: 77);
  flatRidge(c, lawn, _moss, light: _mossL, band: 4);
  final lawn2 = Ridge(s, y: 0.9, amp: 0.012, freq: 1.4, seed: 23, tilt: 0.02);
  flatRidge(c, lawn2, _mossD, light: _moss, band: 3);

  // pool at the foot of the waterfall
  final pool = smoothPath([
    Offset(w * 0.0, h * 0.842),
    Offset(w * 0.12, h * 0.832),
    Offset(w * 0.27, h * 0.836),
    Offset(w * 0.42, h * 0.846),
    Offset(w * 0.5, h * 0.865),
    Offset(w * 0.4, h * 0.89),
    Offset(w * 0.2, h * 0.894),
    Offset(w * 0.0, h * 0.886),
  ], closed: true);
  c.drawPath(pool.shift(const Offset(0, 4)), _fill(_mossD));
  c.drawPath(pool, _fill(_water));
  c
    ..save()
    ..clipPath(pool)
    ..drawPath(pool.shift(const Offset(0, 5)), _fill(_waterD))
    ..restore();
  // stepping stones
  for (final (x, y, rw) in [(0.38, 0.872, 0.05), (0.3, 0.885, 0.04), (0.46, 0.86, 0.034)]) {
    final o = Offset(w * x, h * y);
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, 3), width: w * rw * 2, height: h * 0.013), _fill(_stoneS));
    c.drawOval(Rect.fromCenter(center: o, width: w * rw * 2, height: h * 0.013), _fill(_stoneL));
  }
  // lily pads
  for (final (x, y) in [(0.1, 0.862), (0.14, 0.875), (0.2, 0.86)]) {
    c.drawOval(Rect.fromCenter(center: Offset(w * x, h * y), width: w * 0.04, height: h * 0.01), _fill(_moss));
  }

  // broken staircase rising to the right pillar: lit tread, shaded riser, joints, chipped corner
  final stoneTop = mix(_sandL, _stoneL, 0.25), stoneFront = mix(_sandS, _stoneS, 0.35);
  final jr = rng(44);
  const stepN = 3;
  for (var i = 0; i < stepN; i++) {
    final sw = w * (0.56 - 0.1 * i);
    final x0 = w * 0.78 - sw / 2 + (i == 2 ? w * 0.04 : 0);
    final y1 = h * (0.99 - 0.045 * i), y0 = y1 - h * 0.045;
    final tread = RRect.fromRectAndRadius(Rect.fromLTRB(x0, y0, x0 + sw, y0 + h * 0.02), const Radius.circular(5));
    final riser = RRect.fromRectAndRadius(Rect.fromLTRB(x0 + 2, y0 + h * 0.012, x0 + sw - 2, y1), const Radius.circular(4));
    c.drawRRect(riser, _fill(stoneFront));
    c.drawRRect(tread, _fill(stoneTop));
    final jl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _deep.withValues(alpha: 0.3);
    var jx = x0 + sw * (0.12 + jr.nextDouble() * 0.1);
    while (jx < x0 + sw - 8) {
      c.drawLine(Offset(jx, y0 + h * 0.022), Offset(jx, y1 - 2), jl);
      jx += sw * (0.2 + jr.nextDouble() * 0.12);
    }
    _mossRow(c, x0 + 4, x0 + sw * (0.3 + 0.2 * jr.nextDouble()), y0 + h * 0.004, w * 0.018, 50 + i);
  }
  // fallen column drum lying on the lawn
  final drumTop = h * 0.915, drumH = h * 0.052;
  final drum = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.5, drumTop, w * 0.78, drumTop + drumH), Radius.circular(h * 0.012));
  c.drawRRect(drum, _fill(mix(_sandL, _stoneL, 0.2)));
  c
    ..save()
    ..clipRRect(drum)
    ..drawRect(Rect.fromLTRB(w * 0.48, drumTop + drumH * 0.52, w * 0.8, drumTop + drumH + 2), _fill(mix(_sandS, _stoneS, 0.3)))
    ..restore();
  final fl = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = _deep.withValues(alpha: 0.25);
  for (final f in [0.22, 0.5, 0.78]) {
    c.drawLine(Offset(w * 0.54, drumTop + drumH * f), Offset(w * 0.78, drumTop + drumH * f), fl);
  }
  final cap = Rect.fromCenter(center: Offset(w * 0.5, drumTop + drumH / 2), width: w * 0.04, height: drumH);
  c.drawOval(cap, _fill(mix(_sandS, _stoneS, 0.3)));
  c.drawOval(cap.deflate(drumH * 0.14), _fill(mix(_sandL, _stoneL, 0.2)));
  c.drawOval(cap.deflate(drumH * 0.3), _fill(mix(_sandS, _stoneS, 0.3)));
  _mossRow(c, w * 0.56, w * 0.74, drumTop + 2, w * 0.016, 19);

  // foreground blocks bottom-left
  final blockA = _rpoly([Offset(-w * 0.1, h * 1.02), Offset(-w * 0.1, h * 0.93), Offset(w * 0.12, h * 0.915), Offset(w * 0.2, h * 0.94), Offset(w * 0.22, h * 1.02)], 10);
  _twoTone(c, blockA, _stoneL, _stoneS, w * 0.08);
  _mossRow(c, -w * 0.05, w * 0.2, h * 0.92, w * 0.026, 6);
  final blockB = _rpoly([Offset(w * 0.17, h * 1.02), Offset(w * 0.19, h * 0.965), Offset(w * 0.34, h * 0.955), Offset(w * 0.38, h * 1.02)], 8);
  _twoTone(c, blockB, _hz(_stoneL, 0.0), _stoneS, w * 0.255);
  _mossRow(c, w * 0.19, w * 0.35, h * 0.957, w * 0.02, 22);
  // ferns and plants
  _plant(c, Offset(w * 0.04, h * 0.93), h * 0.1, 7, spread: 1.7, seed: 3);
  _plant(c, Offset(w * 0.28, h * 0.965), h * 0.07, 5, spread: 1.5, seed: 8);
  _plant(c, Offset(w * 0.92, h * 0.935), h * 0.09, 7, spread: 1.7, seed: 12);
  _plant(c, Offset(w * 0.6, h * 0.935), h * 0.05, 4, spread: 1.3, seed: 15);
  // grass tufts
  final gr = rng(51);
  for (var i = 0; i < 26; i++) {
    final x = w * (0.02 + gr.nextDouble() * 0.5);
    final y = h * (0.945 + gr.nextDouble() * 0.05);
    final th = h * (0.012 + gr.nextDouble() * 0.014);
    for (var k = -1; k <= 1; k++) {
      final bx = x + k * th * 0.5;
      c.drawPath(
        Path()
          ..moveTo(bx - 2, y)
          ..quadraticBezierTo(bx + k * 3, y - th * 0.6, bx + k * th * 0.6, y - th * (k == 0 ? 1.1 : 0.85))
          ..quadraticBezierTo(bx + k * 3 + 3, y - th * 0.5, bx + 2, y)
          ..close(),
        _fill(k == 0 ? _mossL : _moss),
      );
    }
  }
  // flowers
  final r = rng(33);
  for (var i = 0; i < 16; i++) {
    final x = w * (0.02 + r.nextDouble() * 0.96);
    final y = h * (0.915 + r.nextDouble() * 0.07);
    final col = i % 3 == 0 ? const Color(0xFFFFE9A0) : const Color(0xFFFFFFFF);
    c.drawCircle(Offset(x, y), 2.2, _fill(col));
    c.drawCircle(Offset(x, y), 0.9, _fill(const Color(0xFFF0A040)));
  }
}

// ---------------------------------------------------------------- vines and canopy

void _vines(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(2);
  final centre = Offset(w * 0.5, h * 0.3);
  final stem = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.8
    ..color = _mossD;
  void vine(Offset a, double len) {
    final sway = (r.nextDouble() - 0.5) * 12;
    c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx + sway, a.dy + len * 0.35, a.dx - sway, a.dy + len * 0.7, a.dx + sway * 0.4, a.dy + len),
      stem,
    );
    final n = (len / 7).floor();
    for (var i = 1; i <= n; i++) {
      final t = i / (n + 1);
      final p = Offset(a.dx + sway * 0.4 * t * t, a.dy + len * t);
      final side = i.isEven ? 1.0 : -1.0;
      _leaf(c, p, 12 + r.nextDouble() * 5, side * 1.0 + (r.nextDouble() - 0.5) * 0.4, i % 3 == 0 ? _mossL : _moss, _mossD);
    }
    _leaf(c, Offset(a.dx + sway * 0.4, a.dy + len), 9, math.pi, _mossL, _moss);
  }

  for (var i = 0; i < 7; i++) {
    final a = math.pi * 1.07 + i * 0.08 + r.nextDouble() * 0.03;
    vine(centre + Offset(math.cos(a), math.sin(a)) * (w * 0.36 + 2), h * (0.04 + r.nextDouble() * 0.09));
  }
  for (var i = 0; i < 4; i++) {
    final a = math.pi * 1.84 + i * 0.07;
    vine(centre + Offset(math.cos(a), math.sin(a)) * (w * 0.36 + 2), h * (0.03 + r.nextDouble() * 0.07));
  }
  // vines from the pillar capitals
  for (final x in [0.03, 0.065, 0.12, 0.87, 0.935, 0.97]) {
    vine(Offset(w * x, h * 0.305), h * (0.06 + r.nextDouble() * 0.12));
  }
  // leafy canopy in the top corners
  for (final (x, y, rad) in [(-0.04, 0.0, 0.1), (0.07, -0.015, 0.075), (0.17, -0.02, 0.05), (0.97, 0.0, 0.085), (0.88, -0.02, 0.06), (0.4, -0.03, 0.045)]) {
    _mossBlob(c, Offset(w * x, h * y), w * rad);
  }
  for (final x in [0.03, 0.1, 0.18, 0.88, 0.95, 0.42]) {
    vine(Offset(w * x, h * 0.03), h * (0.05 + r.nextDouble() * 0.06));
  }
}

// ---------------------------------------------------------------- live: water, dust, sky life

void _waterFx(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final fx0 = w * 0.205, fx1 = w * 0.275;
  final top = h * 0.29, bot = h * 0.842;
  final streak = Paint();
  for (var i = 0; i < 9; i++) {
    final x = _lerp(fx0 + 4, fx1 - 4, (i * 0.37 + 0.11) % 1.0);
    final lap = k.saw(14 + (i % 3) * 2, i * 0.13);
    final y = _lerp(top, bot, lap);
    final len = h * (0.035 + (i % 3) * 0.012);
    final a = (lap < 0.06 ? lap / 0.06 : (lap > 0.94 ? (1 - lap) / 0.06 : 1.0));
    streak.color = Colors.white.withValues(alpha: 0.7 * a);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.2, y - len, 2.4, len), const Radius.circular(1.2)), streak);
  }
  // spray puffs where the water lands
  for (var i = 0; i < 5; i++) {
    final ph = i / 5.0;
    final lift = k.saw(6, ph);
    final x = (fx0 + fx1) / 2 + (i - 2) * w * 0.022;
    final y = bot - lift * h * 0.014;
    final rad = w * (0.016 + lift * 0.014);
    c.drawCircle(Offset(x, y), rad, _fill(Colors.white.withValues(alpha: 0.5 * (1 - lift))));
  }
  // ripples
  final rp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  for (var i = 0; i < 4; i++) {
    final t = k.saw(4, i / 4);
    final cx = _lerp(w * 0.12, w * 0.42, (i * 0.31 + 0.1) % 1.0);
    final cyy = h * (0.862 + (i % 2) * 0.016);
    rp.color = Colors.white.withValues(alpha: 0.5 * (1 - t));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cyy), width: w * (0.02 + t * 0.09), height: h * (0.004 + t * 0.012)), rp);
  }
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.04, 0.845, 0.46, 0.89), count: 10, seed: 4, color: Colors.white, cycles: 8);
}

void _dust(Canvas c, Size s, Clock k) {
  final o = _shaftOrigin(s);
  final r = rng(21);
  final k0 = s.width / 390;
  final len = s.height * 1.0;
  final p = Paint();
  for (var i = 0; i < 44; i++) {
    final shaft = r.nextInt(6);
    final across = (r.nextDouble() - 0.5) * 0.9;
    final ph = r.nextDouble();
    final size = (1.0 + r.nextDouble() * 1.6) * k0;
    final (a, wd) = _shaftAt(k, shaft);
    // slow drift along the shaft, a small wobble across it
    final tt = 0.1 + 0.9 * k.saw(1 + i % 2, ph);
    final dist = len * tt;
    final ang = a + across * wd + 0.012 * math.sin(tau * (k.u * (4 + i % 4) + ph));
    final pos = o + Offset(math.cos(ang), math.sin(ang)) * dist + Offset(0, math.sin(tau * (k.u * (3 + i % 3) + ph * 2)) * 5 * k0);
    final fade = (tt < 0.2 ? (tt - 0.1) / 0.1 : (tt > 0.85 ? (1 - tt) / 0.15 : 1.0)).clamp(0.0, 1.0);
    final tw = 0.5 + 0.5 * k.pulse(8 + i % 5, ph);
    p.color = const Color(0xFFFFF1C4).withValues(alpha: 0.85 * fade * tw);
    c.drawCircle(pos, size, p);
  }
}

void _skyLife(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  // birds circling far away
  for (var i = 0; i < 5; i++) {
    final lap = k.saw(2 + (i % 2), i / 5.0);
    final a = tau * lap;
    final cx = w * (0.34 + (i % 2) * 0.03), cyy = h * (0.17 + (i % 3) * 0.012);
    final x = cx + math.cos(a) * w * (0.2 + 0.015 * i);
    final y = cyy + math.sin(a) * h * 0.03;
    final depth = 0.75 + 0.25 * math.sin(a);
    paintBird(c, Offset(x, y), (4.2 + i % 3 * 0.8) * depth * w / 390, k.sine(40 + i * 3, i * 0.2), const Color(0xFF6F7F90));
  }
  // tiny stone fragments hovering around the gap in the arch
  final r = rng(8);
  for (var i = 0; i < 7; i++) {
    final bx = w * (0.64 + r.nextDouble() * 0.3), by = h * (0.07 + r.nextDouble() * 0.18);
    final size = w * (0.012 + r.nextDouble() * 0.014);
    final ph = r.nextDouble();
    final bob = k.sine(3 + i % 4, ph) * 5;
    final dx = k.sine(2 + i % 3, ph + 0.3) * 3;
    c
      ..save()
      ..translate(bx + dx, by + bob)
      ..rotate(0.5 * k.sine(2 + i % 2, ph));
    final stone = _rpoly([Offset(-size, -size * 0.6), Offset(size * 0.9, -size * 0.8), Offset(size, size * 0.7), Offset(-size * 0.7, size * 0.8)], size * 0.3);
    _twoTone(c, stone, _sandL, _sandS, 0);
    c.restore();
  }
}
