import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Sunny Countryside in flat, graphic 2D: towering cumulus, rolling green hills,
// golden wheat fields cut in contour stripes, a red barn, a winding dirt path
// with a wooden fence and a windmill whose blades turn slowly. Light comes from
// the upper left, shade sits on the right of every form.

const _sunPos = Offset(0.2, 0.125);

// sky
const _skyTop = Color(0xFF4FB3F6), _skyMid = Color(0xFF86CEF8), _skyLow = Color(0xFFBDE8FF), _skyHor = Color(0xFFFFF4D2);
const _cloud = Color(0xFFFFFFFF), _cloudShade = Color(0xFFD2E6F8);
// greens
const _gLight = Color(0xFF8FD14F), _gMid = Color(0xFF5DB83E), _gDark = Color(0xFF3E9A35), _gDeep = Color(0xFF2F8630);
// wheat
const _wheatA = Color(0xFFF4C542), _wheatB = Color(0xFFE0A52A), _wheatEdge = Color(0xFFC48A22);
// barn & wood
const _red = Color(0xFFC8352B), _redShade = Color(0xFFA32A2A), _roof = Color(0xFF8E2C2E), _roofShade = Color(0xFF722326);
const _white = Color(0xFFFFFFFF), _cream = Color(0xFFFFF1D6), _creamShade = Color(0xFFE6CFA6);
const _wood = Color(0xFFB5814A), _woodShade = Color(0xFF8E5F35);
const _path = Color(0xFFC9A26B), _pathLight = Color(0xFFE2C28F), _pathEdge = Color(0xFFA9824D);

SceneSpec countrysideScene() => SceneSpec(
      focusY: -0.12,
      topShade: 0.08,
      bottomShade: 0.3,
      layers: [
        Layer.still(_sky),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.36),
        Layer.live(_birds),
        Layer.still(_farHills, driftX: 0.005, driftCycles: 2),
        Layer.scroll(_cloudsFront, scrollCycles: 2, bandTop: 0.22, bandBottom: 0.45),
        Layer.still(_midHills, driftX: _midDrift, driftCycles: 2, driftPhase: _midPhase),
        Layer.live(_blades),
        Layer.still(_field, driftX: 0.016, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_wheatGlints),
        Layer.still(_foreMounds, driftX: 0.026, driftCycles: 2, driftPhase: 0.2),
        Layer.still(_foreGrass, driftX: 0.036, driftCycles: 2, driftPhase: 0.25, sway: 0.012, swayCycles: 6, pivot: Alignment.bottomCenter),
        Layer.live(_pollen),
        Layer.live(_butterflies),
      ],
    );

const double _midDrift = 0.01;
const double _midPhase = 0.1;

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ---------------------------------------------------------------- hills

/// Rolling hill line built from gaussian bumps: bumps = [centre, amp, width].
class _Hill {
  _Hill(this.s, double y, List<List<double>> bumps, {double rolling = 0.006, int seed = 1}) {
    final w = s.width, h = s.height;
    final p = <Offset>[];
    for (var x = -0.12 * w; x <= 1.12 * w + 6; x += 6) {
      final u = x / w;
      var yy = y;
      for (final b in bumps) {
        yy -= b[1] * math.exp(-math.pow((u - b[0]) / b[2], 2));
      }
      yy -= rolling * (math.sin(u * 5.1 + seed) * 0.6 + math.sin(u * 11.7 + seed * 2) * 0.4);
      p.add(Offset(x, yy * h));
    }
    pts = p;
  }
  final Size s;
  late final List<Offset> pts;

  double yAt(double x) {
    final step = pts[1].dx - pts[0].dx;
    final i = ((x - pts.first.dx) / step).floor().clamp(0, pts.length - 2);
    final t = (x - pts[i].dx) / step;
    return _lerp(pts[i].dy, pts[i + 1].dy, t);
  }

  Path fill([double? bottom]) {
    final b = bottom ?? s.height * 1.1;
    return smoothPath(pts)
      ..lineTo(pts.last.dx, b)
      ..lineTo(pts.first.dx, b)
      ..close();
  }

  /// flat colour with a lighter crest strip
  void paint(Canvas c, Color color, {Color? light, double band = 3, Color? shade}) {
    final path = fill();
    c.drawPath(path, Paint()..color = light ?? color);
    c
      ..save()
      ..clipPath(path)
      ..drawPath(path.shift(Offset(0, band)), Paint()..color = color)
      ..restore();
    if (shade != null) {
      // flat darker underside band on the shade (right) flank
      c
        ..save()
        ..clipPath(path)
        ..restore();
    }
  }
}

// ---------------------------------------------------------------- sky & clouds

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_skyTop, _skyMid, _skyLow, _skyHor], const [0.0, 0.2, 0.38, 0.5]);
  final o = Offset(_sunPos.dx * s.width, _sunPos.dy * s.height);
  flatSun(c, o, s.width * 0.058, core: const Color(0xFFFFF6C8), halo: const Color(0xFFFFF0A8));
}

void _cloudsBack(Canvas c, Size s) {
  final w = s.width, h = s.height;
  flatCloud(c, Offset(w * 0.5, h * 0.17), w * 0.42, color: _cloud, shade: _cloudShade, seed: 4, puff: 1.2);
  flatCloud(c, Offset(w * 0.9, h * 0.09), w * 0.36, color: _cloud, shade: _cloudShade, seed: 9, puff: 1.1);
  flatCloud(c, Offset(w * 0.08, h * 0.3), w * 0.3, color: _cloud, shade: _cloudShade, seed: 13, puff: 1.0);
}

void _cloudsFront(Canvas c, Size s) {
  final w = s.width, h = s.height;
  flatCloud(c, Offset(w * 0.36, h * 0.385), w * 0.3, color: _cloud, shade: _cloudShade, seed: 33, puff: 1.0);
  flatCloud(c, Offset(w * 0.85, h * 0.34), w * 0.22, color: _cloud, shade: _cloudShade, seed: 35, puff: 0.9);
}

void _birds(Canvas c, Size s, Clock k) {
  paintBirds(c, s, k, count: 4, seed: 12, y: 0.17, band: 0.12, color: const Color(0xFF3B4C6B), size: 6.5, cycles: 1, dir: 1);
}

// ---------------------------------------------------------------- hills far / mid

void _farHills(Canvas c, Size s) {
  final w = s.width;
  final far = _Hill(s, 0.405, [[0.12, 0.025, 0.2], [0.55, 0.012, 0.2], [0.95, 0.03, 0.18]], seed: 3);
  final haze = mix(_gLight, _skyLow, 0.62);
  far.paint(c, haze, light: mix(haze, Colors.white, 0.35), band: 3);
  // distant round trees on the far hill
  final r = rng(3);
  for (var x = -w * 0.05; x < w * 1.05; x += 9 + r.nextDouble() * 12) {
    final rad = 5 + r.nextDouble() * 4;
    final y = far.yAt(x) + 3;
    c.drawCircle(Offset(x, y - rad * 0.5), rad, Paint()..color = mix(_gMid, _skyLow, 0.5));
  }
  final far2 = _Hill(s, 0.43, [[0.35, 0.02, 0.22], [0.85, 0.012, 0.15]], seed: 8);
  far2.paint(c, mix(_gLight, _skyLow, 0.38), light: mix(_gLight, Colors.white, 0.3), band: 3);
}

void _midHills(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // right hill with the windmill
  final hb = _Hill(s, 0.452, [[0.78, 0.038, 0.17], [0.3, 0.012, 0.2]], seed: 5);
  hb.paint(c, mix(_gLight, _skyLow, 0.12), light: mix(_gLight, Colors.white, 0.28), band: 3);
  // left hill with the barn
  final ha = _Hill(s, 0.47, [[0.24, 0.03, 0.18], [0.62, 0.008, 0.2]], seed: 11);
  ha.paint(c, _gLight, light: const Color(0xFFB4E56E), band: 3);

  // trees on hills
  final r = rng(17);
  for (final (x, sc) in [(0.04, 0.9), (0.1, 1.2), (0.415, 0.8), (0.46, 1.0), (0.55, 0.75), (0.93, 0.9), (0.99, 1.1)]) {
    final hill = x < 0.55 ? ha : hb;
    final base = Offset(w * x, hill.yAt(w * x) + 4);
    flatTree(c, base, h * 0.07 * sc, crown: _gMid, light: const Color(0xFFA6E066), trunk: const Color(0xFF8A5A3A), trunkShade: const Color(0xFF6D452D), seed: r.nextInt(99), lean: (r.nextDouble() - 0.5) * 0.3);
  }

  // barn (left), light from the left: shade on the right wall and roof
  final bx = w * 0.235, by = ha.yAt(w * 0.235) + 3;
  c.drawPath(
    Path()
      ..moveTo(bx - w * 0.012, by - 2)
      ..lineTo(bx + w * 0.012, by - 2)
      ..quadraticBezierTo(bx + w * 0.016, h * 0.5, w * 0.255 + w * 0.032, h * 0.545)
      ..lineTo(w * 0.255 - w * 0.032, h * 0.545)
      ..quadraticBezierTo(bx - w * 0.016, h * 0.5, bx - w * 0.012, by - 2)
      ..close(),
    Paint()..color = _path);
  _barn(c, Offset(bx, by), w * 0.2);
  // silo
  _silo(c, Offset(bx + w * 0.135, by + 1), w * 0.03, h * 0.058);

  // windmill body (right)
  final wx = w * 0.78, wy = hb.yAt(w * 0.78) + 4;
  _windmillBody(c, Offset(wx, wy), h);
  // fence-like hedge row along the base of both hills
  final bush = rng(5);
  for (var x = 0.0; x < 1.0; x += 0.045 + bush.nextDouble() * 0.04) {
    if (x > 0.15 && x < 0.34) continue;
    final hill = x < 0.55 ? ha : hb;
    final bw = w * (0.05 + bush.nextDouble() * 0.03);
    flatBush(c, Offset(w * x, hill.yAt(w * x) + 6), bw, color: _gMid, light: const Color(0xFFA6E066), seed: bush.nextInt(99));
  }
}

void _barn(Canvas c, Offset base, double bw) {
  final bh = bw * 0.56; // wall height
  final x0 = base.dx - bw / 2, x1 = base.dx + bw / 2;
  final yTop = base.dy - bh;
  final wall = Rect.fromLTRB(x0, yTop, x1, base.dy);
  c.drawRect(wall, Paint()..color = _red);
  c.drawRect(Rect.fromLTRB(base.dx + bw * 0.18, yTop, x1, base.dy), Paint()..color = _redShade);
  // gambrel roof
  final roof = Path()
    ..moveTo(x0 - bw * 0.05, yTop + bw * 0.02)
    ..lineTo(x0 + bw * 0.1, yTop - bw * 0.2)
    ..quadraticBezierTo(base.dx, yTop - bw * 0.36, x1 - bw * 0.1, yTop - bw * 0.2)
    ..lineTo(x1 + bw * 0.05, yTop + bw * 0.02)
    ..close();
  c.drawPath(roof, Paint()..color = _roof);
  c
    ..save()
    ..clipPath(roof)
    ..drawRect(Rect.fromLTRB(base.dx + bw * 0.18, yTop - bw * 0.4, x1 + bw, yTop + bw * 0.05), Paint()..color = _roofShade)
    ..restore();
  // gable wall peeking under roof (front face is the wall; small hay window)
  final win = Rect.fromCenter(center: Offset(base.dx, yTop - bw * 0.08), width: bw * 0.16, height: bw * 0.12);
  c.drawRRect(RRect.fromRectAndRadius(win, Radius.circular(bw * 0.02)), Paint()..color = const Color(0xFFFFF1D6));
  // big door with white trim and X
  final door = Rect.fromCenter(center: Offset(base.dx - bw * 0.02, base.dy - bh * 0.4), width: bw * 0.34, height: bh * 0.8);
  c.drawRect(door, Paint()..color = _white);
  c.drawRect(door.deflate(bw * 0.018), Paint()..color = _red);
  final xp = Paint()
    ..color = _white
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.6, bw * 0.02);
  final d = door.deflate(bw * 0.018);
  c.drawLine(d.topLeft, d.bottomRight, xp);
  c.drawLine(d.topRight, d.bottomLeft, xp);
  c.drawLine(Offset(d.center.dx, d.top), Offset(d.center.dx, d.bottom), xp);
  // corner trim
  c.drawRect(Rect.fromLTRB(x0, yTop, x0 + bw * 0.03, base.dy), Paint()..color = _white);
  c.drawRect(Rect.fromLTRB(x1 - bw * 0.03, yTop, x1, base.dy), Paint()..color = _white);
}

void _silo(Canvas c, Offset base, double r, double h) {
  final body = RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - r, base.dy - h, base.dx + r, base.dy), Radius.circular(r * 0.2));
  c.drawRRect(body, Paint()..color = const Color(0xFFE9EEF4));
  c
    ..save()
    ..clipRRect(body)
    ..drawRect(Rect.fromLTRB(base.dx + r * 0.2, base.dy - h, base.dx + r, base.dy), Paint()..color = const Color(0xFFC6D2E2))
    ..restore();
  final dome = Path()
    ..moveTo(base.dx - r * 1.12, base.dy - h + 1)
    ..quadraticBezierTo(base.dx, base.dy - h - r * 1.7, base.dx + r * 1.12, base.dy - h + 1)
    ..close();
  c.drawPath(dome, Paint()..color = _roof);
  c
    ..save()
    ..clipPath(dome)
    ..drawRect(Rect.fromLTRB(base.dx + r * 0.2, base.dy - h - r * 2, base.dx + r * 2, base.dy - h + 2), Paint()..color = _roofShade)
    ..restore();
  for (var i = 1; i < 4; i++) {
    c.drawRect(Rect.fromLTRB(base.dx - r, base.dy - h * i / 4 - 0.6, base.dx + r, base.dy - h * i / 4 + 0.6), Paint()..color = const Color(0xFFB4C2D6));
  }
}

// windmill geometry shared by body (still) and blades (live)
Offset _hubPos(Size s) {
  final w = s.width, h = s.height;
  final hb = _Hill(s, 0.452, [[0.78, 0.038, 0.17], [0.3, 0.012, 0.2]], seed: 5);
  return Offset(w * 0.78, hb.yAt(w * 0.78) + 4 - h * 0.168);
}

void _windmillBody(Canvas c, Offset base, double h) {
  final th = h * 0.15; // tower height
  final bw = h * 0.034; // half width at the base
  final tw = h * 0.02; // half width at the top
  final top = base.dy - th;
  final tower = Path()
    ..moveTo(base.dx - bw, base.dy)
    ..lineTo(base.dx - tw, top)
    ..lineTo(base.dx + tw, top)
    ..lineTo(base.dx + bw, base.dy)
    ..close();
  c.drawPath(tower, Paint()..color = _cream);
  c
    ..save()
    ..clipPath(tower)
    ..drawRect(Rect.fromLTRB(base.dx + bw * 0.1, top, base.dx + bw * 2, base.dy), Paint()..color = _creamShade)
    ..restore();
  // timber bands
  for (final t in [0.3, 0.62]) {
    final y = top + th * t;
    final hw = _lerp(tw, bw, t);
    c.drawRect(Rect.fromLTRB(base.dx - hw, y - 1.5, base.dx + hw, y + 1.5), Paint()..color = _woodShade);
  }
  // door and window
  c.drawRRect(RRect.fromRectAndCorners(Rect.fromCenter(center: Offset(base.dx - bw * 0.1, base.dy - h * 0.014), width: h * 0.018, height: h * 0.028), topLeft: Radius.circular(h * 0.009), topRight: Radius.circular(h * 0.009)), Paint()..color = _woodShade);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx - tw * 0.1, top + th * 0.46), width: h * 0.012, height: h * 0.016), Radius.circular(h * 0.004)), Paint()..color = const Color(0xFF7FC3EA));
  // cap: rounded roof
  final cap = Path()
    ..moveTo(base.dx - tw * 1.35, top + 2)
    ..quadraticBezierTo(base.dx - tw * 1.2, top - h * 0.032, base.dx, top - h * 0.034)
    ..quadraticBezierTo(base.dx + tw * 1.2, top - h * 0.032, base.dx + tw * 1.35, top + 2)
    ..close();
  c.drawPath(cap, Paint()..color = _red);
  c
    ..save()
    ..clipPath(cap)
    ..drawRect(Rect.fromLTRB(base.dx + tw * 0.2, top - h * 0.05, base.dx + tw * 2, top + 4), Paint()..color = _redShade)
    ..restore();
}

void _blades(Canvas c, Size s, Clock k) {
  final dx = _midDrift * s.width * k.sine(2, _midPhase);
  final hub = _hubPos(s) + Offset(dx, 0);
  final len = s.height * 0.115;
  final rot = tau * k.saw(5);
  for (var i = 0; i < 4; i++) {
    c
      ..save()
      ..translate(hub.dx, hub.dy)
      ..rotate(rot + i * math.pi / 2);
    // spoke
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-1.4, -len, 1.4, len * 0.0), const Radius.circular(1.4)), Paint()..color = _woodShade);
    // sail (lattice frame): lit face + shade strip on the trailing side
    final sail = RRect.fromRectAndRadius(Rect.fromLTRB(1.4, -len * 0.97, len * 0.2, -len * 0.2), Radius.circular(len * 0.02));
    c.drawRRect(sail, Paint()..color = _cream);
    c
      ..save()
      ..clipRRect(sail)
      ..drawRect(Rect.fromLTRB(len * 0.11, -len, len * 0.3, 0), Paint()..color = _creamShade)
      ..restore();
    final bar = Paint()..color = _wood;
    for (var j = 1; j < 4; j++) {
      final y = -len * 0.2 - j * len * 0.19;
      c.drawRect(Rect.fromLTRB(1.4, y - 0.6, len * 0.2, y + 0.6), bar);
    }
    c.restore();
  }
  c.drawCircle(hub, s.height * 0.0085, Paint()..color = _woodShade);
  c.drawCircle(hub, s.height * 0.0045, Paint()..color = _wood);
}

// ---------------------------------------------------------------- field layer

List<Offset> _pathCentre(Size s) {
  final w = s.width, h = s.height;
  return [
    Offset(w * 0.255, h * 0.535),
    Offset(w * 0.27, h * 0.55),
    Offset(w * 0.40, h * 0.575),
    Offset(w * 0.62, h * 0.625),
    Offset(w * 0.64, h * 0.69),
    Offset(w * 0.42, h * 0.76),
    Offset(w * 0.33, h * 0.83),
    Offset(w * 0.45, h * 0.91),
    Offset(w * 0.52, h * 1.08),
  ];
}

List<double> _pathHalf(Size s) => [for (final t in [0.03, 0.034, 0.04, 0.05, 0.05, 0.07, 0.095, 0.125, 0.18]) s.width * t];

/// wheat strips: contour-following bands inside [area]
void _wheat(Canvas c, Path area, double x0, double x1, double yTop, double yBot, {int bands = 9, double amp = 5, double tilt = 0, int seed = 1, double freq = 3.2}) {
  c.drawPath(area, Paint()..color = _wheatB);
  c
    ..save()
    ..clipPath(area);
  List<Offset> curve(double t) {
    final y = yTop + (yBot - yTop) * math.pow(t, 1.25);
    return [
      for (var x = x0; x <= x1; x += 8) Offset(x, y + math.sin((x - x0) / (x1 - x0) * freq + seed) * amp * (0.4 + t) + tilt * (x - (x0 + x1) / 2)),
    ];
  }
  for (var i = 0; i < bands; i++) {
    if (i.isOdd) continue;
    final a = curve(i / bands), b = curve((i + 1) / bands);
    c.drawPath(smoothPath([...a, ...b.reversed], closed: true), Paint()..color = _wheatA);
  }
  c.restore();
}

void _field(Canvas c, Size s) {
  final w = s.width, h = s.height;

  // plane C: mid green
  final hc = _Hill(s, 0.545, [[0.5, 0.012, 0.3], [0.05, 0.02, 0.15], [0.95, 0.015, 0.14]], seed: 21);
  hc.paint(c, _gMid, light: _gLight, band: 3);
  // right wheat field on plane C
  final f1 = smoothPath([
    Offset(w * 0.5, h * 0.585),
    Offset(w * 0.74, h * 0.56),
    Offset(w * 1.12, h * 0.55),
    Offset(w * 1.12, h * 0.665),
    Offset(w * 0.86, h * 0.67),
    Offset(w * 0.6, h * 0.64),
  ], closed: true);
  _wheat(c, f1, w * 0.45, w * 1.12, h * 0.55, h * 0.68, bands: 8, amp: 3, tilt: 0.02, seed: 2);
  // field edge shadow (flat strip under the field)
  c.drawPath(f1.shift(const Offset(0, 4)), Paint()..color = _gDark);
  _wheat(c, f1, w * 0.45, w * 1.12, h * 0.55, h * 0.68, bands: 8, amp: 3, tilt: 0.02, seed: 2);
  // trees at the field edge
  final r = rng(31);
  for (final (x, sc) in [(0.08, 1.3), (0.15, 0.95), (0.47, 0.7), (0.94, 1.0)]) {
    final base = Offset(w * x, hc.yAt(w * x) + 8);
    flatTree(c, base, h * 0.085 * sc, crown: _gDark, light: _gLight, trunk: const Color(0xFF7A5238), trunkShade: const Color(0xFF5E3E2B), seed: r.nextInt(99), lean: (r.nextDouble() - 0.5) * 0.3);
  }

  // plane D: nearer, darker
  final hd = _Hill(s, 0.715, [[0.15, 0.03, 0.22], [0.85, 0.02, 0.22]], seed: 4);
  hd.paint(c, _gDark, light: _gMid, band: 3);
  // big left wheat field with wide stripes
  final f2 = smoothPath([
    Offset(-w * 0.1, h * 0.745),
    Offset(w * 0.2, h * 0.725),
    Offset(w * 0.36, h * 0.76),
    Offset(w * 0.3, h * 0.82),
    Offset(w * 0.1, h * 0.85),
    Offset(-w * 0.1, h * 0.85),
  ], closed: true);
  c.drawPath(f2.shift(const Offset(0, 4)), Paint()..color = _wheatEdge);
  _wheat(c, f2, -w * 0.1, w * 0.4, h * 0.725, h * 0.85, bands: 7, amp: 7, tilt: -0.05, seed: 5, freq: 2.2);

  // path + fence
  final centre = _pathCentre(s);
  flatRibbon(c, _smooth(centre), _smoothW(_pathHalf(s)), color: _path, light: _pathLight, bank: _pathEdge);
  // stones on the path
  final pr = rng(2);
  for (var i = 0; i < 14; i++) {
    final t = 0.25 + pr.nextDouble() * 0.7;
    final p = _sampleAt(_smooth(centre), t);
    final hw = _lerpW(_smoothW(_pathHalf(s)), t);
    c.drawOval(Rect.fromCenter(center: p + Offset((pr.nextDouble() - 0.5) * hw * 1.2, 0), width: hw * 0.16, height: hw * 0.08), Paint()..color = _pathEdge);
  }
  _fence(c, s);

  // little white chimney-less cottage? keep calm: sheep-free. Add scattered flowers in meadow
  const petals = [Color(0xFFFFE04A), Color(0xFFE5483D), Color(0xFFFFFFFF), Color(0xFF7FA8F5)];
  final fr = rng(8);
  for (var i = 0; i < 70; i++) {
    final x = fr.nextDouble() * w * 1.1;
    final y = h * (0.73 + fr.nextDouble() * 0.27);
    if (_nearPath(centre, _pathHalf(s), x, y, s)) continue;
    if (x < w * 0.38 && y > h * 0.725 && y < h * 0.96) continue;
    _flower(c, Offset(x, y), 1.8 + (y / h - 0.7) * 6, petals[i % 4]);
  }
}

List<Offset> _smooth(List<Offset> p) {
  // Catmull-Rom resample
  final out = <Offset>[];
  for (var i = 0; i < p.length - 1; i++) {
    final p0 = p[math.max(i - 1, 0)], p1 = p[i], p2 = p[i + 1], p3 = p[math.min(i + 2, p.length - 1)];
    for (var j = 0; j < 8; j++) {
      final t = j / 8, t2 = t * t, t3 = t2 * t;
      out.add(Offset(
        0.5 * ((2 * p1.dx) + (-p0.dx + p2.dx) * t + (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 + (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3),
        0.5 * ((2 * p1.dy) + (-p0.dy + p2.dy) * t + (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 + (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3),
      ));
    }
  }
  out.add(p.last);
  return out;
}

List<double> _smoothW(List<double> w) {
  final out = <double>[];
  for (var i = 0; i < w.length - 1; i++) {
    for (var j = 0; j < 8; j++) {
      out.add(_lerp(w[i], w[i + 1], j / 8));
    }
  }
  out.add(w.last);
  return out;
}

Offset _sampleAt(List<Offset> p, double t) {
  final f = t * (p.length - 1);
  final i = f.floor().clamp(0, p.length - 2);
  return Offset.lerp(p[i], p[i + 1], f - i)!;
}

double _lerpW(List<double> w, double t) {
  final f = t * (w.length - 1);
  final i = f.floor().clamp(0, w.length - 2);
  return _lerp(w[i], w[i + 1], f - i);
}

bool _nearPath(List<Offset> centre, List<double> half, double x, double y, Size s) {
  final sm = _smooth(centre), sw = _smoothW(half);
  for (var i = 0; i < sm.length; i++) {
    if ((sm[i].dy - y).abs() < 14 && (sm[i].dx - x).abs() < sw[i] * 1.5 + 8) return true;
  }
  return false;
}

void _fence(Canvas c, Size s) {
  final sm = _smooth(_pathCentre(s));
  final sw = _smoothW(_pathHalf(s));
  // fence runs along the left side of the lower path
  final pts = <Offset>[];
  final hs = <double>[];
  for (var i = 0; i < sm.length; i++) {
    final a = sm[math.max(i - 1, 0)], b = sm[math.min(i + 1, sm.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(d.dy, -d.dx); // points left of travel (downwards => ... choose consistently)
    pts.add(sm[i] + n * (sw[i] * 1.28 + 2));
    hs.add(sw[i]);
  }
  // draw from index where the path is wide enough
  final start = (sm.length * 0.38).round(), end = start + 4 * ((sm.length * 0.48) / 4).floor();
  final rail = Paint()..color = _wood;
  for (var i = start; i < end; i += 4) {
    final j = math.min(i + 4, end);
    final h0 = hs[i] * 0.55 + 3, h1 = hs[j] * 0.55 + 3;
    for (final f in [0.88, 0.45]) {
      c.drawPath(
        Path()
          ..moveTo(pts[i].dx, pts[i].dy - h0 * f)
          ..lineTo(pts[j].dx, pts[j].dy - h1 * f)
          ..lineTo(pts[j].dx, pts[j].dy - h1 * f + math.max(2.4, h1 * 0.14))
          ..lineTo(pts[i].dx, pts[i].dy - h0 * f + math.max(2.4, h0 * 0.14))
          ..close(),
        rail,
      );
    }
  }
  for (var i = start; i <= end; i += 4) {
    final hh = hs[i] * 0.55 + 3;
    final pw = math.max(2.0, hh * 0.17);
    final post = RRect.fromRectAndRadius(Rect.fromLTRB(pts[i].dx - pw, pts[i].dy - hh, pts[i].dx + pw, pts[i].dy), Radius.circular(pw * 0.6));
    c.drawRRect(post, Paint()..color = _wood);
    c.drawRect(Rect.fromLTRB(pts[i].dx + pw * 0.1, pts[i].dy - hh + pw, pts[i].dx + pw, pts[i].dy), Paint()..color = _woodShade);
  }
  // grass at the fence foot
  for (var i = start; i <= end; i += 4) {
    final hh = hs[i] * 0.55 + 3;
    c.drawOval(Rect.fromCenter(center: pts[i] + Offset(0, 1), width: hh * 0.9, height: hh * 0.25), Paint()..color = _gDeep);
  }
}

void _flower(Canvas c, Offset o, double r, Color color) {
  for (var i = 0; i < 5; i++) {
    final a = tau * i / 5;
    c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.9, r * 0.62, Paint()..color = color);
  }
  c.drawCircle(o, r * 0.55, Paint()..color = color == _white || color == const Color(0xFFFFE04A) ? const Color(0xFFF2A21E) : const Color(0xFFFFE04A));
}

// ---------------------------------------------------------------- foreground

void _foreMounds(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // two dark grassy mounds in the bottom corners
  final left = smoothPath([Offset(-w * 0.12, h * 0.9), Offset(w * 0.0, h * 0.885), Offset(w * 0.14, h * 0.915), Offset(w * 0.3, h * 1.0), Offset(w * 0.3, h * 1.1), Offset(-w * 0.12, h * 1.1)], closed: true);
  final right = smoothPath([Offset(w * 1.12, h * 0.92), Offset(w * 1.0, h * 0.9), Offset(w * 0.88, h * 0.93), Offset(w * 0.74, h * 1.01), Offset(w * 0.74, h * 1.1), Offset(w * 1.12, h * 1.1)], closed: true);
  for (final p in [left, right]) {
    c.drawPath(p, Paint()..color = _gLight);
    c
      ..save()
      ..clipPath(p)
      ..drawPath(p.shift(const Offset(0, 4)), Paint()..color = _gDeep)
      ..restore();
  }
}

void _blade(Canvas c, Offset base, double len, double lean, Color color) {
  final wd = len * 0.09;
  final p = Path()
    ..moveTo(base.dx - wd, base.dy)
    ..quadraticBezierTo(base.dx - wd * 0.5 + lean * 0.3, base.dy - len * 0.6, base.dx + lean, base.dy - len)
    ..quadraticBezierTo(base.dx + wd * 0.5 + lean * 0.5, base.dy - len * 0.55, base.dx + wd, base.dy)
    ..close();
  c.drawPath(p, Paint()..color = color);
}

void _sunflower(Canvas c, Offset base, double h, double lean) {
  final head = base + Offset(lean, -h);
  final stem = Path()
    ..moveTo(base.dx - 2.2, base.dy)
    ..quadraticBezierTo(base.dx + lean * 0.1, base.dy - h * 0.5, head.dx - 2, head.dy)
    ..lineTo(head.dx + 2, head.dy)
    ..quadraticBezierTo(base.dx + lean * 0.1 + 4, base.dy - h * 0.5, base.dx + 2.2, base.dy)
    ..close();
  c.drawPath(stem, Paint()..color = _gDark);
  // leaves
  for (final side in [-1, 1]) {
    final o = base + Offset(lean * 0.2 * 0.5, -h * (side < 0 ? 0.3 : 0.45));
    final leaf = Path()
      ..moveTo(o.dx, o.dy)
      ..quadraticBezierTo(o.dx + side * h * 0.2, o.dy - h * 0.14, o.dx + side * h * 0.3, o.dy - h * 0.04)
      ..quadraticBezierTo(o.dx + side * h * 0.16, o.dy + h * 0.02, o.dx, o.dy)
      ..close();
    c.drawPath(leaf, Paint()..color = side < 0 ? _gMid : _gDark);
  }
  final r = h * 0.2;
  const n = 14;
  for (var i = 0; i < n; i++) {
    final a = tau * i / n;
    final tip = head + Offset(math.cos(a), math.sin(a)) * r * 1.25;
    final pp = Path()
      ..moveTo(head.dx + math.cos(a - 0.3) * r * 0.6, head.dy + math.sin(a - 0.3) * r * 0.6)
      ..quadraticBezierTo(head.dx + math.cos(a - 0.2) * r * 1.2, head.dy + math.sin(a - 0.2) * r * 1.2, tip.dx, tip.dy)
      ..quadraticBezierTo(head.dx + math.cos(a + 0.2) * r * 1.2, head.dy + math.sin(a + 0.2) * r * 1.2, head.dx + math.cos(a + 0.3) * r * 0.6, head.dy + math.sin(a + 0.3) * r * 0.6)
      ..close();
    c.drawPath(pp, Paint()..color = i.isEven ? const Color(0xFFFFD83A) : const Color(0xFFF7B928));
  }
  c.drawCircle(head, r * 0.72, Paint()..color = const Color(0xFF6B3F1E));
  c.drawCircle(head + Offset(-r * 0.12, -r * 0.1), r * 0.5, Paint()..color = const Color(0xFF85501F));
}

void _foreGrass(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(44);
  const cols = [_gDeep, _gDark, _gMid, _gLight];
  for (final side in [-1, 1]) {
    final cx = side < 0 ? w * 0.02 : w * 0.98;
    for (var i = 0; i < 26; i++) {
      final off = (r.nextDouble() - 0.4) * w * 0.3 * side;
      final x = cx + off.abs() * side * 1.0;
      final len = h * (0.03 + r.nextDouble() * 0.07) * (1 - (off.abs() / (w * 0.3)) * 0.5);
      _blade(c, Offset(x, h * 1.02), len, (r.nextDouble() - 0.5) * 16 - side * 6, cols[r.nextInt(4)]);
    }
  }
  // sunflowers in the corners
  _sunflower(c, Offset(w * 0.07, h * 1.0), h * 0.16, 8);
  _sunflower(c, Offset(w * 0.17, h * 1.02), h * 0.1, -5);
  _sunflower(c, Offset(w * 0.93, h * 1.01), h * 0.14, -8);
  // wildflowers in the grass
  const petals = [Color(0xFFFFE04A), Color(0xFFE5483D), Color(0xFFFFFFFF), Color(0xFF7FA8F5)];
  final fr = rng(51);
  for (var i = 0; i < 22; i++) {
    final side = i.isEven ? -1 : 1;
    final x = side < 0 ? fr.nextDouble() * w * 0.33 : w * 0.67 + fr.nextDouble() * w * 0.33;
    final y = h * (0.94 + fr.nextDouble() * 0.07);
    final len = h * (0.025 + fr.nextDouble() * 0.03);
    c.drawLine(Offset(x, y), Offset(x + 2, y - len), Paint()
      ..color = _gDark
      ..strokeWidth = 1.6);
    _flower(c, Offset(x + 2, y - len), 3.4, petals[(i ~/ 2) % 4]);
  }
}

// ---------------------------------------------------------------- live

void _wheatGlints(Canvas c, Size s, Clock k) {
  // light sweeps over the golden fields
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.48, 0.55, 1.0, 0.67), count: 16, seed: 3, color: const Color(0xFFFFF4B8), cycles: 6);
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.0, 0.74, 0.36, 0.94), count: 18, seed: 4, color: const Color(0xFFFFF4B8), cycles: 6);
}

void _pollen(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 34, seed: 6, colors: [Color(0xFFFFFFFF), Color(0xFFFFF3B0)], minSize: 1.0, maxSize: 2.2, flow: Offset(0.12, -0.12), cycles: 2, spread: 2, wander: 12, twinkle: 0.4, shape: ParticleShape.dot, region: Rect.fromLTRB(0, 0.45, 1, 1), opacity: 0.85));
  paintParticles(c, s, k, const ParticleSpec(count: 6, seed: 9, colors: [Color(0xFFFFFFFF)], minSize: 3, maxSize: 4.5, flow: Offset(0.35, 0.18), cycles: 1, spread: 1, wander: 20, shape: ParticleShape.petal, spin: 2, region: Rect.fromLTRB(0, 0.1, 1, 0.5), opacity: 0.9));
}

void _butterflies(Canvas c, Size s, Clock k) {
  const cols = [Color(0xFFFFE04A), Color(0xFFFFFFFF), Color(0xFFFF9BB0)];
  for (var i = 0; i < 3; i++) {
    final ph = i / 3.0;
    final t = k.saw(1, ph);
    final x = s.width * (-0.05 + 1.1 * t) + math.sin(tau * (k.u * 6 + ph)) * 24;
    final y = s.height * (0.78 + 0.07 * i) + math.cos(tau * (k.u * 8 + ph * 2)) * 16;
    final flap = 0.35 + 0.65 * math.sin(tau * (k.u * 60 + i * 0.3)).abs();
    for (final sd in [-1, 1]) {
      c
        ..save()
        ..translate(x, y)
        ..scale(sd * flap, 1);
      c.drawOval(Rect.fromLTWH(0, -6, 7, 7), Paint()..color = cols[i]);
      c.drawOval(Rect.fromLTWH(0, 0, 5, 5), Paint()..color = cols[i].withValues(alpha: 0.8));
      c.restore();
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 1.8, height: 6), const Radius.circular(1)), Paint()..color = const Color(0xFF5A4030));
  }
}
