import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Fairytale Kingdom in flat, graphic 2D: a pale-stone castle with royal-blue
// roofs on a sunny green hill, a windmill, far waterfalls, a winding river with
// a stone bridge, flowering gardens, towering clouds and a far hot-air balloon.
// Flags flutter on the towers and magic sparkles twinkle around the castle.
// Light comes from the upper left, so every shade side is on the right.

const _sun = Offset(0.2, 0.115);

// sky & clouds
const _skyTop = Color(0xFF4FB0FF), _skyMid = Color(0xFF86CDFF), _skyLow = Color(0xFFCDEBFF), _skyHorizon = Color(0xFFFFF1CF);
const _cloud = Color(0xFFFFFFFF), _cloudShade = Color(0xFFE0ECFC);
// far land
const _mtnBack = Color(0xFFC3D6F4), _mtnBackShade = Color(0xFFB2C7EA);
const _mtnFront = Color(0xFFABC1E8), _mtnFrontShade = Color(0xFF97AEDC);
const _fallWater = Color(0xFFCDEEFF), _fallStreak = Color(0xFFFFFFFF);
// hills (far -> near)
const _hillFar = Color(0xFFB4E2AE), _hillFarLight = Color(0xFFCDEFBE);
const _hillCastle = Color(0xFF7ED957), _hillCastleLight = Color(0xFFB0F07F), _hillCastleShade = Color(0xFF63C957);
const _meadow = Color(0xFF58C45B), _meadowLight = Color(0xFF8BE37A);
const _valley = Color(0xFF3FB65E), _valleyLight = Color(0xFF6ED46E);
const _deep = Color(0xFF1F8F4A), _deepLight = Color(0xFF3FB65E);
// stone, roofs
const _stone = Color(0xFFEFE9D8), _stoneShade = Color(0xFFCFC5AB), _stoneDark = Color(0xFFB4AA90);
const _roof = Color(0xFF2E6BD9), _roofShade = Color(0xFF1F4FB0), _roofLight = Color(0xFF5B94EE);
const _gold = Color(0xFFFFD25E), _goldDeep = Color(0xFFF0A93C), _navy = Color(0xFF28397C);
// river
const _water = Color(0xFF7FD3FF), _waterLight = Color(0xFFC7EEFF), _waterDeep = Color(0xFF4FA9E6);
const _path = Color(0xFFF3E6BA);
// flowers
const _pink = Color(0xFFFF8FC0), _yellow = Color(0xFFFFE066), _white = Color(0xFFFFFFFF), _lilac = Color(0xFFC9B3FF);
const _flagRed = Color(0xFFE8475A), _flagRedShade = Color(0xFFC2304A);

SceneSpec fairytaleScene() => SceneSpec(
      focusY: -0.5,
      topShade: 0.08,
      bottomShade: 0.3,
      layers: [
        Layer.still(_skyPaint),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.02, bandBottom: 0.36),
        Layer.live(_skyLife),
        Layer.still(_farMountains, driftX: 0.004, driftCycles: 2),
        Layer.live(_falls),
        Layer.scroll(_cloudsFront, scrollCycles: 2, bandTop: 0.14, bandBottom: 0.36),
        Layer.still(_farHills, driftX: 0.008, driftCycles: 2),
        Layer.still(_hero, driftX: 0.012, driftCycles: 2),
        Layer.live(_heroLive),
        Layer.still(_meadowLayer, driftX: 0.018, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_valleyLayer, driftX: 0.026, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_glints),
        Layer.still(_fore, driftX: 0.038, driftCycles: 2, driftPhase: 0.2, sway: 0.005, swayCycles: 5),
        Layer.live(_drifters),
      ],
    );

double _dx(Size s, Clock k, double d, double phase) => d * s.width * k.sine(2, phase);

// ---------------------------------------------------------------- sky

void _skyPaint(Canvas c, Size s) {
  fillSky(c, s, const [_skyTop, _skyMid, _skyLow, _skyHorizon], const [0.0, 0.2, 0.36, 0.5]);
  final o = Offset(_sun.dx * s.width, _sun.dy * s.height);
  // flat translucent shafts of light fanning from the sun
  for (var i = 0; i < 6; i++) {
    final a = 0.2 + i * 0.26;
    final w = 0.07;
    final len = s.height * 0.8;
    final p = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + math.cos(a - w) * len, o.dy + math.sin(a - w) * len)
      ..lineTo(o.dx + math.cos(a + w) * len, o.dy + math.sin(a + w) * len)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFFFF6D6).withValues(alpha: i.isEven ? 0.2 : 0.11));
  }
  flatSun(c, o, s.width * 0.058, core: const Color(0xFFFFF6D0), halo: const Color(0xFFFFE08A));
}

void _cloudsBack(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // towering friendly clouds
  flatCloud(c, Offset(w * 0.94, h * 0.32), w * 0.44, color: _cloud, shade: _cloudShade, seed: 4, puff: 1.3);
  flatCloud(c, Offset(w * 0.47, h * 0.075), w * 0.24, color: _cloud, shade: _cloudShade, seed: 21, puff: 0.9);
}

void _cloudsFront(Canvas c, Size s) {
  final w = s.width, h = s.height;
  flatCloud(c, Offset(w * 0.18, h * 0.24), w * 0.3, seed: 33, puff: 0.85, shade: _cloudShade);
  flatCloud(c, Offset(w * 0.68, h * 0.2), w * 0.24, seed: 36, puff: 0.8, shade: _cloudShade);
  flatCloud(c, Offset(w * 0.93, h * 0.3), w * 0.22, seed: 39, puff: 0.7, shade: _cloudShade);
}

// ---------------------------------------------------------------- far land

// waterfalls: x (fraction), width (px at 390), top y, bottom y (fractions)
const _fallsSpec = <(double, double, double, double)>[(0.2, 22, 0.27, 0.392), (0.36, 12, 0.29, 0.392)];

void _farMountains(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final k0 = w / 390;
  final back = Ridge(s, y: 0.345, amp: 0.045, freq: 1.5, seed: 3, octaves: 2, sharp: 0.25);
  flatMountains(c, back, _mtnBack, _mtnBackShade);
  final front = Ridge(s, y: 0.37, amp: 0.03, freq: 2.1, seed: 8, octaves: 2, sharp: 0.2);
  flatMountains(c, front, _mtnFront, _mtnFrontShade);
  // a plateau with the waterfalls
  final plate = RRect.fromLTRBAndCorners(w * 0.06, h * 0.262, w * 0.46, h * 0.5, topLeft: Radius.circular(w * 0.07), topRight: Radius.circular(w * 0.05));
  final pp = Path()..addRRect(plate);
  c.drawPath(pp, Paint()..color = _mtnFront);
  c
    ..save()
    ..clipPath(pp)
    ..drawRect(Rect.fromLTRB(w * 0.3, 0, w * 0.5, h), Paint()..color = _mtnFrontShade)
    ..restore();
  // little green cap on the plateau
  final cap = Path()
    ..moveTo(w * 0.06, h * 0.28)
    ..quadraticBezierTo(w * 0.06, h * 0.262, w * 0.13, h * 0.262)
    ..lineTo(w * 0.39, h * 0.266)
    ..quadraticBezierTo(w * 0.46, h * 0.27, w * 0.46, h * 0.284)
    ..quadraticBezierTo(w * 0.26, h * 0.3, w * 0.06, h * 0.28)
    ..close();
  c.drawPath(cap, Paint()..color = const Color(0xFF8FD58C));
  final r = rng(5);
  for (var i = 0; i < 7; i++) {
    final x = w * (0.1 + r.nextDouble() * 0.34);
    c.drawCircle(Offset(x, h * 0.268), (3.5 + r.nextDouble() * 2.5) * k0, Paint()..color = const Color(0xFF6FC47A));
  }
  for (final (fx, fw, t, b) in _fallsSpec) {
    final rect = RRect.fromLTRBR(w * fx - fw * k0 / 2, h * t, w * fx + fw * k0 / 2, h * b, Radius.circular(fw * k0 * 0.5));
    c.drawRRect(rect, Paint()..color = _fallWater);
    // splash pool
    c.drawOval(Rect.fromCenter(center: Offset(w * fx, h * b), width: fw * k0 * 2.6, height: fw * k0 * 0.7), Paint()..color = _fallWater);
  }
}

void _falls(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  c.save();
  c.translate(_dx(s, k, 0.004, 0), 0);
  var n = 0;
  for (final (fx, fw, t, b) in _fallsSpec) {
    final top = h * t, bot = h * b, len = bot - top;
    for (var j = 0; j < 3; j++) {
      final f = k.saw(6 + n, j / 3 + n * 0.17);
      final y0 = top + f * (len + 14 * k0) - 14 * k0;
      final y1 = y0 + 12 * k0;
      final a0 = math.max(y0, top), a1 = math.min(y1, bot);
      if (a1 <= a0) continue;
      final x = w * fx + (j - 1) * fw * k0 * 0.26;
      c.drawRRect(RRect.fromLTRBR(x - 1.1 * k0, a0, x + 1.1 * k0, a1, Radius.circular(k0)), Paint()..color = _fallStreak.withValues(alpha: 0.95));
    }
    // foam puffs
    final pu = k.pulse(8 + n);
    c.drawOval(Rect.fromCenter(center: Offset(w * fx, bot), width: fw * k0 * (1.6 + 0.4 * pu), height: fw * k0 * 0.5), Paint()..color = _fallStreak.withValues(alpha: 0.85));
    n++;
  }
  c.restore();
}

// ---------------------------------------------------------------- the hot-air balloon, birds

void _balloon(Canvas c, Offset o, double r) {
  final env = Path()..addOval(Rect.fromCircle(center: o, radius: r));
  env.addPath(
    Path()
      ..moveTo(o.dx - r * 0.84, o.dy + r * 0.5)
      ..lineTo(o.dx + r * 0.84, o.dy + r * 0.5)
      ..lineTo(o.dx + r * 0.32, o.dy + r * 1.5)
      ..lineTo(o.dx - r * 0.32, o.dy + r * 1.5)
      ..close(),
    Offset.zero,
  );
  final rope = Paint()
    ..color = const Color(0xFF8A6A4A)
    ..strokeWidth = math.max(1.0, r * 0.07);
  c.drawLine(Offset(o.dx - r * 0.28, o.dy + r * 1.5), Offset(o.dx - r * 0.2, o.dy + r * 1.85), rope);
  c.drawLine(Offset(o.dx + r * 0.28, o.dy + r * 1.5), Offset(o.dx + r * 0.2, o.dy + r * 1.85), rope);
  c.drawPath(env, Paint()..color = _flagRed);
  c
    ..save()
    ..clipPath(env)
    ..drawRect(Rect.fromLTRB(o.dx - r * 0.38, o.dy - r * 1.1, o.dx + r * 0.38, o.dy + r * 1.6), Paint()..color = _gold)
    ..drawRect(Rect.fromLTRB(o.dx + r * 0.22, o.dy - r * 1.1, o.dx + r * 1.2, o.dy + r * 1.6), Paint()..color = const Color(0x332A3A8A))
    ..restore();
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(o.dx, o.dy + r * 1.98), width: r * 0.52, height: r * 0.3), Radius.circular(r * 0.06)), Paint()..color = const Color(0xFF9A6B3F));
}

void _skyLife(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  // far hot-air balloon crossing the sky once per loop, gently bobbing
  final t = k.saw(1, 0.35);
  final bx = -w * 0.15 + t * w * 1.3;
  final by = h * 0.15 + k.sine(6) * 5 * k0 + math.sin(t * math.pi) * -h * 0.01;
  _balloon(c, Offset(bx, by), 13 * k0);
  // birds
  paintBirds(c, s, k, count: 3, seed: 12, y: 0.08, band: 0.1, color: const Color(0xFF3B5A9E), size: 6.5, cycles: 1, dir: -1);
}

void _farHills(Canvas c, Size s) {
  final h = s.height;
  final a = Ridge(s, y: 0.4, amp: 0.016, freq: 1.8, seed: 21, octaves: 2);
  flatRidge(c, a, _hillFar, light: _hillFarLight, band: 3);
  // a few tiny round trees on the far ridge
  final r = rng(17);
  for (var i = 0; i < 26; i++) {
    final x = r.nextDouble() * s.width;
    final th = h * (0.012 + r.nextDouble() * 0.01);
    flatTree(c, Offset(x, a.yAt(x) + 2), th * 3, crown: const Color(0xFF93D28F), light: const Color(0xFFAAE0A2), trunk: const Color(0xFF93D28F), trunkShade: const Color(0xFF93D28F), seed: i);
  }
}

// ---------------------------------------------------------------- the castle

double _cx(Size s) => s.width * 0.575;
double _cy(Size s) => s.height * 0.418;
double _csc(Size s) => s.width / 390 * 1.05;

// x, width, body height, roof height, window rows, flag colour
const _towerList = <(double, double, double, double, int)>[
  (-92, 32, 78, 50, 1),
  (92, 36, 120, 70, 2),
  (0, 66, 142, 88, 2),
  (-56, 40, 104, 64, 2),
  (56, 40, 92, 56, 1),
];

Offset _flagBase(Size s, int i) {
  final (x, _, th, rh, _) = _towerList[i];
  return Offset(_cx(s) + x * _csc(s), _cy(s) + (-th - rh - 12) * _csc(s));
}

void _twoTone(Canvas c, Path p, Color base, Color shade, double splitX) {
  c.drawPath(p, Paint()..color = base);
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(splitX, -2000, splitX + 3000, 2000), Paint()..color = shade)
    ..restore();
}

Path _archPath(double cx, double bottom, double w, double h) {
  final r = w / 2;
  return Path()
    ..moveTo(cx - r, bottom)
    ..lineTo(cx - r, bottom - h + r)
    ..arcTo(Rect.fromLTWH(cx - r, bottom - h, w, w), math.pi, math.pi, false)
    ..lineTo(cx + r, bottom)
    ..close();
}

void _window(Canvas c, double cx, double bottom, double w, double h) {
  c.drawPath(_archPath(cx, bottom + 1.6, w + 3.2, h + 2.4), Paint()..color = _stoneDark);
  c.drawPath(_archPath(cx, bottom, w, h), Paint()..color = _gold);
  c
    ..save()
    ..clipPath(_archPath(cx, bottom, w, h))
    ..drawRect(Rect.fromLTRB(cx + w * 0.12, bottom - h, cx + w, bottom), Paint()..color = _goldDeep)
    ..restore();
}

void _tower(Canvas c, double x, double tw, double th, double rh, int rows) {
  final body = Rect.fromLTRB(x - tw / 2, -th, x + tw / 2, 10);
  final split = x + tw * 0.14;
  _twoTone(c, Path()..addRect(body), _stone, _stoneShade, split);
  // stone course lines
  final line = Paint()..color = _stoneShade.withValues(alpha: 0.7);
  for (var y = -th + 16; y < 0; y += 16) {
    c.drawRect(Rect.fromLTRB(x - tw / 2, y, x + tw * 0.14, y + 1.2), line);
  }
  // windows
  final ww = math.min(7.0, tw * 0.2), wh = ww * 2.1;
  for (var i = 0; i < rows; i++) {
    _window(c, x - tw * 0.06, -(math.max(th * 0.5, 60) + i * th * 0.2), ww, wh);
  }
  // cornice
  final cor = Path()..addRRect(RRect.fromLTRBR(x - tw / 2 - 3.5, -th - 2, x + tw / 2 + 3.5, -th + 6, const Radius.circular(3)));
  _twoTone(c, cor, _stone, _stoneShade, split);
  // conical roof
  final ay = -th - rh;
  final roof = Path()
    ..moveTo(x - tw / 2 - 8, -th + 1)
    ..quadraticBezierTo(x - tw * 0.2, -th - rh * 0.5, x, ay)
    ..quadraticBezierTo(x + tw * 0.2, -th - rh * 0.5, x + tw / 2 + 8, -th + 1)
    ..quadraticBezierTo(x, -th + 10, x - tw / 2 - 8, -th + 1)
    ..close();
  _twoTone(c, roof, _roof, _roofShade, x + tw * 0.02);
  c
    ..save()
    ..clipPath(roof)
    ..drawRect(Rect.fromLTRB(x - tw / 2 - 12, ay, x - tw * 0.3, -th + 12), Paint()..color = _roofLight)
    ..restore();
  // gold band on the roof
  c.drawPath(
    Path()
      ..moveTo(x - tw * 0.3, -th - rh * 0.28)
      ..quadraticBezierTo(x, -th - rh * 0.2, x + tw * 0.3, -th - rh * 0.28),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = _gold,
  );
  // pole + finial
  c.drawRect(Rect.fromLTRB(x - 0.8, ay - 12, x + 0.8, ay + 2), Paint()..color = _stoneDark);
  c.drawCircle(Offset(x, ay + 0.5), 2.4, Paint()..color = _gold);
}

void _battlements(Canvas c, double x0, double x1, double y, double tooth, double gap, double hgt) {
  var x = x0;
  while (x + tooth <= x1) {
    c.drawRRect(RRect.fromLTRBR(x, y - hgt, x + tooth, y + 2, const Radius.circular(1.2)), Paint()..color = _stone);
    x += tooth + gap;
  }
}

void _castle(Canvas c, Size s) {
  final sc = _csc(s);
  c
    ..save()
    ..translate(_cx(s), _cy(s))
    ..scale(sc);
  // draw order: outer towers, keep, mid towers, wall
  for (final i in [0, 1, 2, 3, 4]) {
    final (x, tw, th, rh, rows) = _towerList[i];
    _tower(c, x, tw, th, rh, rows);
  }
  // curtain wall
  final wall = Path()..addRRect(RRect.fromLTRBR(-116, -50, 116, 50, const Radius.circular(3)));
  _twoTone(c, wall, _stone, _stoneShade, 60);
  _battlements(c, -112, 112, -50, 10, 6.4, 8);
  c.drawRect(const Rect.fromLTRB(-116, -50, 116, -44), Paint()..color = _stoneShade);
  // wall windows (arrow slits)
  for (final x in [-84.0, -40.0, 42.0, 84.0]) {
    c.drawRRect(RRect.fromLTRBR(x - 1.8, -34, x + 1.8, -20, const Radius.circular(1.8)), Paint()..color = _navy);
  }
  // the gate
  c.drawPath(_archPath(0, 12, 34, 42), Paint()..color = _stoneDark);
  c.drawPath(_archPath(0, 12, 28, 37), Paint()..color = _navy);
  c.drawPath(_archPath(0, 12, 20, 26), Paint()..color = _gold);
  c.drawRect(const Rect.fromLTRB(-0.8, -14, 0.8, 12), Paint()..color = _goldDeep);
  // hanging blue banners
  for (final x in [-66.0, 66.0]) {
    final p = Path()
      ..moveTo(x - 5, -44)
      ..lineTo(x + 5, -44)
      ..lineTo(x + 5, -16)
      ..lineTo(x, -21)
      ..lineTo(x - 5, -16)
      ..close();
    c.drawPath(p, Paint()..color = _roof);
    c.drawCircle(Offset(x, -35), 2.2, Paint()..color = _gold);
  }
  c.restore();
}

Path _mound(double cx, double topY, double hw, double depth) {
  final pts = <Offset>[
    Offset(cx - hw, topY + depth),
    Offset(cx - hw * 0.86, topY + depth * 0.62),
    Offset(cx - hw * 0.6, topY + depth * 0.2),
    Offset(cx - hw * 0.34, topY + depth * 0.03),
    Offset(cx, topY),
    Offset(cx + hw * 0.34, topY + depth * 0.03),
    Offset(cx + hw * 0.6, topY + depth * 0.2),
    Offset(cx + hw * 0.86, topY + depth * 0.62),
    Offset(cx + hw, topY + depth),
  ];
  return smoothPath(pts)
    ..lineTo(cx + hw, topY + depth * 3)
    ..lineTo(cx - hw, topY + depth * 3)
    ..close();
}

void _paintMound(Canvas c, Path m, Color body, Color light, Color shade, double w) {
  c.drawPath(m, Paint()..color = light);
  c
    ..save()
    ..clipPath(m)
    ..drawPath(m.shift(Offset(w * 0.018, w * 0.012)), Paint()..color = body)
    ..restore();
  // flat shade on the right slope
  final b = m.getBounds();
  c
    ..save()
    ..clipPath(m)
    ..drawPath(
      Path()
        ..moveTo(b.center.dx + b.width * 0.2, b.top)
        ..quadraticBezierTo(b.center.dx + b.width * 0.34, b.top + b.height * 0.16, b.center.dx + b.width * 0.36, b.bottom)
        ..lineTo(b.right + 20, b.bottom)
        ..lineTo(b.right + 20, b.top)
        ..close(),
      Paint()..color = shade,
    )
    ..restore();
}

// windmill
Offset _mill(Size s) => Offset(s.width * 0.17, s.height * 0.452);
double _millSc(Size s) => s.width / 390 * 1.1;

void _windmill(Canvas c, Size s) {
  final o = _mill(s), sc = _millSc(s);
  c
    ..save()
    ..translate(o.dx, o.dy + 4 * sc)
    ..scale(sc);
  final body = Path()
    ..moveTo(-15, 0)
    ..quadraticBezierTo(-12, -30, -9, -52)
    ..lineTo(9, -52)
    ..quadraticBezierTo(12, -30, 15, 0)
    ..close();
  _twoTone(c, body, _stone, _stoneShade, 1);
  final roof = Path()
    ..moveTo(-12, -51)
    ..quadraticBezierTo(-12, -66, 0, -70)
    ..quadraticBezierTo(12, -66, 12, -51)
    ..quadraticBezierTo(0, -47, -12, -51)
    ..close();
  _twoTone(c, roof, _roof, _roofShade, 0);
  c.drawPath(_archPath(0, 0, 9, 14), Paint()..color = _navy);
  _window(c, 0, -30, 5, 9);
  c.restore();
}

void _hero(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // windmill hill (behind the castle hill)
  final mm = _mound(w * 0.16, h * 0.452, w * 0.42, h * 0.1);
  _paintMound(c, mm, _hillCastle, _hillCastleLight, _hillCastleShade, w);
  _windmill(c, s);
  // castle, then the castle hill over its feet
  _castle(c, s);
  final m = _mound(_cx(s), _cy(s) + 12 * _csc(s), w * 0.82, h * 0.16);
  _paintMound(c, m, _hillCastle, _hillCastleLight, _hillCastleShade, w);
  // winding stone path from the gate down the hill
  final k0 = w / 390;
  final pathPts = <Offset>[
    Offset(_cx(s), _cy(s) + 12 * k0),
    Offset(_cx(s) - 12 * k0, _cy(s) + h * 0.035),
    Offset(_cx(s) + 22 * k0, _cy(s) + h * 0.07),
    Offset(_cx(s) - 6 * k0, _cy(s) + h * 0.11),
    Offset(_cx(s) - 30 * k0, _cy(s) + h * 0.15),
  ];
  flatRibbon(c, pathPts, [5 * k0, 7 * k0, 10 * k0, 14 * k0, 20 * k0], color: _path);
  // a few round trees and shrubs on the castle hill
  final r = rng(44);
  for (var i = 0; i < 8; i++) {
    final x = i < 2 ? w * (0.3 + i * 0.05) : w * (0.84 + (i - 2) * 0.035);
    final y = _cy(s) + h * (0.045 + r.nextDouble() * 0.035);
    flatTree(c, Offset(x, y), h * (0.05 + r.nextDouble() * 0.025), crown: const Color(0xFF3CB35C), light: const Color(0xFF6BD36B), trunk: const Color(0xFF8A5A3A), trunkShade: const Color(0xFF6E4630), seed: i + 3);
  }
}

// flags, windmill sails, castle sparkles
void _flag(Canvas c, Offset p, double len, double hgt, double phase, Color col, Color shade) {
  const n = 9;
  final top = <Offset>[], bot = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final wave = math.sin(phase - t * 5.2) * hgt * 0.34 * (0.15 + t);
    top.add(Offset(p.dx + len * t * (1 - 0.06 * math.cos(phase - t * 5.2)), p.dy + wave));
    bot.add(Offset(p.dx + len * t * (1 - 0.06 * math.cos(phase - t * 5.2)), p.dy + hgt + wave));
  }
  // swallowtail
  final tailMid = Offset(p.dx + len * 0.8, p.dy + hgt * 0.5 + math.sin(phase - 4.2) * hgt * 0.3);
  final poly = [...top, tailMid, ...bot.reversed];
  final path = Path()..moveTo(poly.first.dx, poly.first.dy);
  for (var i = 1; i < poly.length; i++) {
    path.lineTo(poly[i].dx, poly[i].dy);
  }
  path.close();
  c.drawPath(path, Paint()..color = col);
  final low = Path()..moveTo(top[0].dx, top[0].dy + hgt * 0.5);
  for (var i = 1; i <= n; i++) {
    low.lineTo(top[i].dx, top[i].dy + hgt * 0.5);
  }
  low.lineTo(tailMid.dx, tailMid.dy);
  for (var i = n; i >= 0; i--) {
    low.lineTo(bot[i].dx, bot[i].dy);
  }
  low.close();
  c
    ..save()
    ..clipPath(path)
    ..drawPath(low, Paint()..color = shade)
    ..restore();
}

void _star(Canvas c, Offset o, double r, Color color, double a) {
  final p = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx + r * 0.14, o.dy - r * 0.14, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx + r * 0.14, o.dy + r * 0.14, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx - r * 0.14, o.dy + r * 0.14, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx - r * 0.14, o.dy - r * 0.14, o.dx, o.dy - r)
    ..close();
  c.drawCircle(o, r * 1.25, Paint()..color = color.withValues(alpha: 0.2 * a));
  c.drawPath(p, Paint()..color = color.withValues(alpha: a));
}

void _heroLive(Canvas c, Size s, Clock k) {
  final w = s.width, k0 = w / 390, sc = _csc(s);
  c.save();
  c.translate(_dx(s, k, 0.012, 0), 0);
  // flags
  const cols = [_flagRed, _gold, _flagRed, _gold, _flagRed];
  const shades = [_flagRedShade, _goldDeep, _flagRedShade, _goldDeep, _flagRedShade];
  for (var i = 0; i < _towerList.length; i++) {
    final big = i == 2;
    _flag(c, _flagBase(s, i) + Offset(0, 0), (big ? 28 : 20) * sc, (big ? 13 : 9.5) * sc, tau * k.saw(24, i * 0.13), cols[i], shades[i]);
  }
  // windmill sails
  final m = _mill(s), ms = _millSc(s);
  final hub = Offset(m.dx, m.dy + (4 - 56) * ms);
  c
    ..save()
    ..translate(hub.dx, hub.dy)
    ..rotate(tau * k.saw(6));
  for (var i = 0; i < 4; i++) {
    c.rotate(math.pi / 2);
    c.drawRRect(RRect.fromLTRBR(-0.9 * ms, -34 * ms, 0.9 * ms, 0, const Radius.circular(1)), Paint()..color = _stoneDark);
    c.drawRRect(RRect.fromLTRBR(0.9 * ms, -33 * ms, 8.5 * ms, -14 * ms, Radius.circular(1.4 * ms)), Paint()..color = _white);
    c.drawRRect(RRect.fromLTRBR(5 * ms, -33 * ms, 8.5 * ms, -14 * ms, Radius.circular(1.4 * ms)), Paint()..color = _cloudShade);
  }
  c.restore();
  c.drawCircle(hub, 3 * ms, Paint()..color = _goldDeep);
  // magic sparkles around the castle
  final cx = _cx(s), cy = _cy(s);
  for (var i = 0; i < 22; i++) {
    final cyc = 4 + i % 4;
    final ph = (i * 0.37) % 1.0;
    final lap = (k.u * cyc + ph);
    final f = lap - lap.floorToDouble();
    final idx = lap.floor() % cyc;
    final r = rng(i * 17 + idx * 5 + 1);
    final x = cx + (r.nextDouble() * 2 - 1) * 150 * sc;
    final y = cy + (-250 + r.nextDouble() * 270) * sc - f * 16 * k0;
    final a = math.pow(math.sin(math.pi * f), 1.5).toDouble();
    if (a < 0.04) continue;
    _star(c, Offset(x, y), (3.2 + (i % 3) * 1.5) * k0 * (0.7 + 0.3 * a), i % 3 == 0 ? _white : const Color(0xFFFFEA9A), a);
  }
  c.restore();
}

// ---------------------------------------------------------------- the meadow

void _cottage(Canvas c, Offset base, double sc, {bool flip = false}) {
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..scale(flip ? -sc : sc, sc);
  final body = Path()..addRRect(RRect.fromLTRBR(-14, -17, 14, 1, const Radius.circular(1.5)));
  _twoTone(c, body, _stone, _stoneShade, 3);
  final roof = Path()
    ..moveTo(-19, -15)
    ..quadraticBezierTo(-9, -22, 0, -33)
    ..quadraticBezierTo(9, -22, 19, -15)
    ..quadraticBezierTo(0, -12, -19, -15)
    ..close();
  _twoTone(c, roof, _roof, _roofShade, 1);
  c.drawPath(_archPath(-4, 1, 6, 10), Paint()..color = const Color(0xFF8A5A3A));
  c.drawRRect(RRect.fromLTRBR(5, -13, 10, -8, const Radius.circular(1)), Paint()..color = _gold);
  c.drawRect(const Rect.fromLTRB(6, -31, 11, -22), Paint()..color = _stoneShade);
  c.restore();
}

Size? _memoSize;
List<Offset> _memoCottages = const [];
List<Offset> _cottageSpots(Size s) {
  if (_memoSize == s) return _memoCottages;
  final ridge = Ridge(s, y: 0.535, amp: 0.012, freq: 1.8, seed: 61, octaves: 2, tilt: 0.01);
  _memoSize = s;
  return _memoCottages = [for (final f in [0.06, 0.9, 0.8]) Offset(s.width * f, ridge.yAt(s.width * f) + 5)];
}

void _meadowLayer(Canvas c, Size s) {
  final w = s.width, h = s.height, k0 = w / 390;
  final ridge = Ridge(s, y: 0.535, amp: 0.012, freq: 1.8, seed: 61, octaves: 2, tilt: 0.01);
  // trees and cottages sit on this ridge
  final r = rng(23);
  final xs = <double>[];
  for (var i = 0; i < 20; i++) {
    final left = i < 10;
    xs.add(left ? w * (-0.02 + r.nextDouble() * 0.3) : w * (0.76 + r.nextDouble() * 0.28));
  }
  xs.sort();
  for (final x in xs) {
    final th = h * (0.045 + r.nextDouble() * 0.025);
    if (r.nextDouble() < 0.25) {
      flatPine(c, Offset(x, ridge.yAt(x) + 4), th * 1.15, color: const Color(0xFF2E9E55), shade: const Color(0xFF248A49), tiers: 3);
    } else {
      flatTree(c, Offset(x, ridge.yAt(x) + 4), th, crown: const Color(0xFF34A85B), light: const Color(0xFF68D06C), trunk: const Color(0xFF8A5A3A), trunkShade: const Color(0xFF6E4630), seed: r.nextInt(999), lean: (r.nextDouble() - 0.5) * 0.3);
    }
  }
  final spots = _cottageSpots(s);
  _cottage(c, spots[0], k0 * 1.1);
  _cottage(c, spots[1], k0 * 1.0, flip: true);
  _cottage(c, spots[2] + Offset(0, k0), k0 * 0.75);
  flatRidge(c, ridge, _meadow, light: _meadowLight, band: 3);
  // flower dots on the meadow
  final rf = rng(8);
  const cols = [_white, _yellow, _pink, _lilac];
  for (var i = 0; i < 44; i++) {
    final x = (i.isEven ? rf.nextDouble() * 0.3 : 0.7 + rf.nextDouble() * 0.3) * w;
    final y = h * (0.555 + rf.nextDouble() * 0.06);
    c.drawCircle(Offset(x, y), (1.3 + rf.nextDouble() * 1.0) * k0, Paint()..color = cols[i % 4]);
  }
}

// ---------------------------------------------------------------- valley: river, bridge, roads

void _bridge(Canvas c, Size s) {
  final w = s.width, h = s.height, k0 = w / 390;
  final cx = w * 0.62, deckC = h * 0.886, deckE = h * 0.908, water = h * 0.948;
  final half = w * 0.21;
  final top = <Offset>[
    Offset(cx - half, deckE + 2),
    Offset(cx - half * 0.7, deckE - 2),
    Offset(cx - half * 0.35, deckC + 4),
    Offset(cx, deckC),
    Offset(cx + half * 0.35, deckC + 4),
    Offset(cx + half * 0.7, deckE - 2),
    Offset(cx + half, deckE + 2),
  ];
  final body = smoothPath(top)
    ..quadraticBezierTo(cx + half * 1.02, water - 2, cx + half * 0.86, water)
    ..lineTo(cx - half * 0.86, water)
    ..quadraticBezierTo(cx - half * 1.02, water - 2, cx - half, deckE + 2)
    ..close();
  _twoTone(c, body, _stone, _stoneShade, cx + half * 0.3);
  // parapet cap (lighter strip along the crest)
  c
    ..save()
    ..clipPath(body)
    ..drawPath(smoothPath(top).shift(Offset(0, 7 * k0)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * k0
      ..color = _stoneDark)
    ..restore();
  c.drawPath(
    smoothPath(top),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k0
      ..color = const Color(0xFFFFFBEC),
  );
  // arch with a lighter stone ring
  final ax = cx, aw = w * 0.085, ah = h * 0.026;
  c.drawOval(Rect.fromCenter(center: Offset(ax, water), width: (aw + 4 * k0) * 2, height: (ah + 3.5 * k0) * 2), Paint()..color = const Color(0xFFF7F1DF));
  c
    ..save()
    ..clipRect(Rect.fromLTRB(0, 0, w, water))
    ..drawOval(Rect.fromCenter(center: Offset(ax, water), width: aw * 2, height: ah * 2), Paint()..color = _waterDeep)
    ..restore();
  // stone seams
  final seam = Paint()..color = _stoneShade.withValues(alpha: 0.8);
  for (final x in [-0.17, -0.13, 0.13, 0.17, 0.2 - 0.005]) {
    c.drawRect(Rect.fromLTWH(cx + w * x, deckE - 1 * k0, 1.2 * k0, 10 * k0), seam);
  }
  // lamp posts at both ends
  for (final side in [-1, 1]) {
    final x = cx + side * (half - 6 * k0);
    c.drawRRect(RRect.fromLTRBR(x - 1.2 * k0, deckE - 22 * k0, x + 1.2 * k0, deckE + 2 * k0, Radius.circular(k0)), Paint()..color = _navy);
    c.drawCircle(Offset(x, deckE - 25 * k0), 5.5 * k0, Paint()..color = _gold.withValues(alpha: 0.35));
    c.drawCircle(Offset(x, deckE - 25 * k0), 3 * k0, Paint()..color = _gold);
  }
}

void _valleyLayer(Canvas c, Size s) {
  final w = s.width, h = s.height, k0 = w / 390;
  final ridge = Ridge(s, y: 0.64, amp: 0.012, freq: 1.5, seed: 77, octaves: 2, tilt: -0.012);
  flatRidge(c, ridge, _valley, light: _valleyLight, band: 3);
  // river
  final cx = <Offset>[
    Offset(w * 0.6, h * 0.6),
    Offset(w * 0.54, h * 0.64),
    Offset(w * 0.4, h * 0.7),
    Offset(w * 0.3, h * 0.748),
    Offset(w * 0.34, h * 0.8),
    Offset(w * 0.5, h * 0.84),
    Offset(w * 0.62, h * 0.875),
    Offset(w * 0.62, h * 0.93),
    Offset(w * 0.58, h * 1.0),
    Offset(w * 0.56, h * 1.08),
  ];
  final hw = <double>[0.03, 0.034, 0.042, 0.056, 0.07, 0.086, 0.1, 0.108, 0.125, 0.15].map((e) => e * w).toList();
  c
    ..save()
    ..clipPath(ridge.fill(h * 1.3));
  flatRibbon(c, cx, hw, color: _water, light: _waterLight, bank: _deep);
  c.restore();
  // bushes hide the spring of the river
  flatBush(c, Offset(w * 0.55, h * 0.648), w * 0.2, color: const Color(0xFF2E9E55), light: const Color(0xFF5CC866), seed: 3);
  flatBush(c, Offset(w * 0.68, h * 0.642), w * 0.16, color: const Color(0xFF2E9E55), light: const Color(0xFF5CC866), seed: 6);
  // dirt roads leading to the bridge
  flatRibbon(c, [Offset(w * 0.44, h * 0.918), Offset(w * 0.3, h * 0.93), Offset(w * 0.1, h * 0.905), Offset(-w * 0.12, h * 0.9)], [10 * k0, 13 * k0, 15 * k0, 17 * k0], color: _path);
  flatRibbon(c, [Offset(w * 0.8, h * 0.918), Offset(w * 0.9, h * 0.89), Offset(w * 1.0, h * 0.86), Offset(w * 1.12, h * 0.85)], [10 * k0, 12 * k0, 14 * k0, 16 * k0], color: _path);
  _bridge(c, s);
  // flower beds on both banks
  final r = rng(31);
  const cols = [_pink, _yellow, _white, _lilac];
  void bed(double x0, double x1, double y0, double y1, int n) {
    for (var i = 0; i < n; i++) {
      final x = (x0 + r.nextDouble() * (x1 - x0)) * w;
      final y = (y0 + r.nextDouble() * (y1 - y0)) * h;
      final rr = (1.8 + r.nextDouble() * 1.4) * k0;
      c.drawCircle(Offset(x, y), rr, Paint()..color = cols[r.nextInt(4)]);
      c.drawCircle(Offset(x, y), rr * 0.4, Paint()..color = _goldDeep);
    }
  }
  bed(0.0, 0.26, 0.66, 0.84, 26);
  bed(0.78, 1.0, 0.68, 0.84, 22);
  bed(0.0, 0.34, 0.95, 1.0, 10);
  // round garden trees
  flatTree(c, Offset(w * 0.9, h * 0.8), h * 0.085, crown: const Color(0xFF2E9E55), light: const Color(0xFF5CC866), trunk: const Color(0xFF8A5A3A), trunkShade: const Color(0xFF6E4630), seed: 71);
  flatTree(c, Offset(w * 0.07, h * 0.8), h * 0.07, crown: const Color(0xFF2E9E55), light: const Color(0xFF5CC866), trunk: const Color(0xFF8A5A3A), trunkShade: const Color(0xFF6E4630), seed: 73);
}

void _smoke(Canvas c, Size s, Clock k) {
  final k0 = s.width / 390;
  c.save();
  c.translate(_dx(s, k, 0.018, 0.1), 0);
  final spots = _cottageSpots(s);
  const chim = [(5.0, -31.0, 1.1), (-5.0, -31.0, 1.0), (4.5, -31.0, 0.75)];
  for (var j = 0; j < 3; j++) {
    final (cxo, cyo, sc) = chim[j];
    final base = spots[j] + Offset(cxo * sc * k0 * (j == 1 ? 1 : 1), cyo * sc * k0);
    for (var i = 0; i < 3; i++) {
      final f = k.saw(8, i / 3 + j * 0.2);
      final a = math.sin(math.pi * f);
      c.drawCircle(base + Offset(f * 9 * k0 + math.sin(f * 5 + j) * 2 * k0, -f * 30 * k0), (2 + f * 3.6) * k0, Paint()..color = _white.withValues(alpha: 0.75 * a));
    }
  }
  c.restore();
}

void _glints(Canvas c, Size s, Clock k) {
  _smoke(c, s, k);
  c.save();
  c.translate(_dx(s, k, 0.026, 0.15), 0);
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.28, 0.7, 0.72, 0.87), count: 16, seed: 6, color: _white, cycles: 8);
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.5, 0.95, 0.68, 1.0), count: 7, seed: 9, color: _white, cycles: 9);
  c.restore();
}

// ---------------------------------------------------------------- foreground garden

void _flowerHead(Canvas c, Offset o, double r, Color petal) {
  final p = Paint()..color = petal;
  for (var i = 0; i < 5; i++) {
    final a = tau * i / 5 - math.pi / 2;
    c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.78, r * 0.55, p);
  }
  c.drawCircle(o, r * 0.5, Paint()..color = _goldDeep);
}

void _fore(Canvas c, Size s) {
  final w = s.width, h = s.height, k0 = w / 390;
  // hedges in the corners
  flatBush(c, Offset(w * 0.04, h * 1.02), w * 0.5, color: _deep, light: _deepLight, seed: 5);
  flatBush(c, Offset(w * 0.98, h * 1.02), w * 0.44, color: _deep, light: _deepLight, seed: 8);
  flatBush(c, Offset(w * 0.3, h * 1.03), w * 0.26, color: const Color(0xFF248A49), light: const Color(0xFF45BC63), seed: 12);
  // rose dots on the hedges
  final r = rng(19);
  for (var i = 0; i < 26; i++) {
    final left = i < 14;
    final x = left ? w * (-0.02 + r.nextDouble() * 0.4) : w * (0.76 + r.nextDouble() * 0.26);
    final y = h * (0.965 + r.nextDouble() * 0.04);
    c.drawCircle(Offset(x, y), (2.4 + r.nextDouble() * 1.4) * k0, Paint()..color = i % 3 == 0 ? _yellow : (i % 3 == 1 ? _pink : _white));
  }
  // tall flowers with stems
  const heads = [_pink, _yellow, _white, _lilac, _pink];
  final stem = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2 * k0
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF2E9E55);
  for (var i = 0; i < 16; i++) {
    final left = i < 9;
    final x = left ? w * (0.0 + r.nextDouble() * 0.42) : w * (0.78 + r.nextDouble() * 0.24);
    final top = h * (0.925 + r.nextDouble() * 0.035);
    final bend = (r.nextDouble() - 0.5) * 10 * k0;
    c.drawPath(
      Path()
        ..moveTo(x, h * 1.02)
        ..quadraticBezierTo(x + bend, (top + h * 1.02) / 2, x + bend * 1.4, top),
      stem,
    );
    _flowerHead(c, Offset(x + bend * 1.4, top), (4.2 + r.nextDouble() * 1.8) * k0, heads[i % 5]);
  }
}

// ---------------------------------------------------------------- drifting petals & pollen

void _drifters(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 20, seed: 4, colors: [Color(0xFFFFC2DC), Color(0xFFFFFFFF), Color(0xFFFF9EC6)], minSize: 2.0, maxSize: 3.2, flow: Offset(0.35, 0.5), cycles: 2, spread: 1, wander: 16, shape: ParticleShape.petal, region: Rect.fromLTRB(-0.1, 0.0, 1.1, 1.0), fade: 0.1, spin: 2, opacity: 0.95));
  paintParticles(c, s, k, const ParticleSpec(count: 22, seed: 9, colors: [Color(0xFFFFF3B0), Color(0xFFFFFFFF)], minSize: 1.0, maxSize: 1.9, flow: Offset(0.08, -0.2), cycles: 2, spread: 2, wander: 14, twinkle: 0.5, twinkleCycles: 10, shape: ParticleShape.dot, region: Rect.fromLTRB(0.0, 0.3, 1.0, 1.0), opacity: 0.9));
}
