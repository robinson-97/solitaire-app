import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit.dart';

// Crystal Caverns in flat, graphic 2D: a deep violet cave, a still underground
// lake and giant gemstone clusters that breathe with inner light. Light comes
// from the ceiling opening at the upper right, so every right-hand facet is the
// bright one. Flat fills, hard two-tone facets, translucent flat halo rings.

// palette
const _caveTop = Color(0xFF0A0720), _caveMid = Color(0xFF1B1240), _caveLow = Color(0xFF2A1A5E);
const _rockDark = Color(0xFF1E1736), _rockMid = Color(0xFF2D2250), _rockLit = Color(0xFF42347A);
const _rockFar = Color(0xFF30226A), _rockFar2 = Color(0xFF3A2A80);
const _violet = Color(0xFF8A5BFF), _amethyst = Color(0xFFB07CFF), _blue = Color(0xFF4C7CFF);
const _pink = Color(0xFFE58BFF), _teal = Color(0xFF38C8CC), _ice = Color(0xFFD9E4FF), _glow = Color(0xFFC9A8FF);
const _waterA = Color(0xFF4A37A4), _waterB = Color(0xFF3A2A8C), _waterC = Color(0xFF2A1E70);
const _lantern = Color(0xFFFFC46B);

const _lightX = 0.66; // ceiling opening, fraction of width
const _waterY = 0.795; // far shore line of the lake
const _driftMid = 0.012, _driftNear = 0.024;
const _cycMid = 2, _cycNear = 2;
const _phMid = 0.1, _phNear = 0.2;

SceneSpec crystalScene() => SceneSpec(
      focusY: 0.35,
      topShade: 0.12,
      bottomShade: 0.22,
      layers: [
        Layer.still(_sky),
        Layer.still(_farWall, driftX: 0.005, driftCycles: 2),
        Layer.live((c, s, k) => _glowPlane(c, s, k, 0, 0.005, 2, 0)),
        Layer.still(_shafts, rotate: 0.03, swayCycles: 3, pivot: const Alignment(0.32, -1.05)),
        Layer.still(_midWall, driftX: _driftMid, driftCycles: _cycMid, driftPhase: _phMid),
        Layer.live((c, s, k) => _glowPlane(c, s, k, 1, _driftMid, _cycMid, _phMid)),
        Layer.still(_lake, driftX: _driftMid, driftCycles: _cycMid, driftPhase: _phMid),
        Layer.scroll(_mist, scrollCycles: 1, bandTop: 0.74, bandBottom: 0.9),
        Layer.still(_islands, driftX: _driftNear, driftCycles: _cycNear, driftPhase: _phNear),
        Layer.live((c, s, k) => _glowPlane(c, s, k, 2, _driftNear, _cycNear, _phNear)),
        Layer.live(_ripples),
        Layer.still(_foreground, driftX: 0.04, driftCycles: 2, driftPhase: 0.3),
        Layer.live(_motes),
        Layer.live(_lanternGlow),
      ],
    );

// ---------------------------------------------------------------- crystals

class _Cry {
  _Cry(this.base, this.w, this.len, this.tip, this.ang, this.c, this.plane, this.ph, this.cyc, this.big);
  final Offset base;
  final double w, len, tip, ang;
  final Color c;
  final int plane;
  final double ph;
  final int cyc;
  final bool big;
  Offset get dir => Offset(math.sin(ang), -math.cos(ang));
  Offset get nrm => Offset(math.cos(ang), math.sin(ang));
}

class _World {
  _World(this.size);
  final Size size;
  final List<List<_Cry>> planes = [[], [], [], []];
  final List<_Cry> hangers = []; // hanging from the ceiling (foreground layer)
}

_World? _worldCache;

_World _world(Size s) {
  final cached = _worldCache;
  if (cached != null && cached.size == s) return cached;
  final w = _World(s);
  final k = s.width / 390;
  final W = s.width, H = s.height;
  var seed = 100;
  void add(int plane, double fx, double fy, double scale, int n, List<Color> pal, {double lean = 0, double spread = 0.5, double width = 0.2, bool flip = false}) {
    final r = rng(seed++);
    final list = <_Cry>[];
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.0 : (i / (n - 1) - 0.5) * 2;
      final centre = 1 - 0.5 * math.pow(t.abs(), 1.2);
      final len = scale * k * centre * (0.75 + r.nextDouble() * 0.4);
      final cw = scale * k * width * (0.7 + r.nextDouble() * 0.5) * (0.6 + 0.4 * centre);
      final ang = (flip ? math.pi : 0) + lean + t * spread + (r.nextDouble() - 0.5) * 0.18;
      final bx = fx * W + t * scale * k * 0.3 * (flip ? -1 : 1);
      list.add(_Cry(Offset(bx, fy * H), cw, len, cw * (0.9 + r.nextDouble() * 0.5), ang, pal[r.nextInt(pal.length)], plane, r.nextDouble(), 3 + r.nextInt(3), scale > 110));
    }
    list.sort((a, b) => b.len.compareTo(a.len));
    (flip ? w.hangers : w.planes[plane]).addAll(list);
  }

  // far wall: small, hazy
  add(0, 0.10, 0.60, 62, 3, [_violet, _blue], lean: 0.1);
  add(0, 0.52, 0.595, 46, 3, [_blue, _violet], spread: 0.6);
  add(0, 0.93, 0.6, 70, 4, [_violet, _amethyst, _blue], lean: -0.1);
  // mid: wall clusters and the far shore
  add(1, 0.95, 0.30, 130, 4, [_amethyst, _violet, _pink], lean: -0.95, spread: 0.4, width: 0.17);
  add(1, 0.07, 0.205, 105, 4, [_blue, _violet, _teal], lean: 0.95, spread: 0.4, width: 0.18);
  add(1, 0.33, 0.79, 72, 4, [_blue, _teal, _violet], lean: -0.08, spread: 0.55);
  add(1, 0.70, 0.79, 96, 5, [_violet, _amethyst, _pink, _blue], lean: 0.1, spread: 0.55);
  add(1, 0.95, 0.795, 60, 3, [_teal, _blue], lean: -0.2);
  // near islands: the hero is the big amethyst cluster at the left
  add(2, 0.2, 0.845, 235, 6, [_amethyst, _violet, _pink, _violet, _blue], lean: -0.05, spread: 0.62, width: 0.165);
  add(2, 0.8, 0.855, 165, 5, [_blue, _violet, _teal, _amethyst], lean: 0.12, spread: 0.6, width: 0.2);
  add(2, 0.55, 0.835, 52, 3, [_pink, _amethyst], spread: 0.7);
  // foreground specks and ceiling
  add(3, 0.06, 0.975, 70, 4, [_pink, _amethyst, _violet], lean: 0.25, spread: 0.55);
  add(3, 0.93, 0.985, 46, 3, [_teal, _blue], lean: -0.3);
  add(3, 0.88, -0.01, 120, 4, [_violet, _amethyst, _blue], lean: 0.2, spread: 0.5, flip: true);
  add(3, 0.10, 0.0, 70, 3, [_blue, _teal], lean: -0.15, spread: 0.5, flip: true);
  _worldCache = w;
  return w;
}

Color _shade(Color c, double f, Color haze) => f > 0 ? mix(c, haze, f) : c;

Path _poly(List<Offset> p) {
  final path = Path()..moveTo(p[0].dx, p[0].dy);
  for (var i = 1; i < p.length; i++) {
    path.lineTo(p[i].dx, p[i].dy);
  }
  return path..close();
}

final Paint _fillP = Paint(), _lineP = Paint()..style = PaintingStyle.stroke;

void _facet(Canvas c, List<Offset> pts, Color col, double round) {
  final p = _poly(pts);
  _fillP.color = col;
  c.drawPath(p, _fillP);
  _lineP
    ..color = col
    ..strokeWidth = round
    ..strokeJoin = StrokeJoin.round;
  c.drawPath(p, _lineP);
}

/// One hexagonal gem: three flat facets on the shaft and three on the tip.
void _drawCry(Canvas c, _Cry k, {double fade = 0, Color haze = _caveLow, bool detail = true}) {
  final hw = k.w / 2, d = k.dir, n = k.nrm;
  Offset p(double t, double u) => k.base + n * (hw * t) + d * u;
  final flip = n.dx < 0;
  final col = _shade(k.c, fade, haze);
  final dark = _shade(mix(k.c, const Color(0xFF1B1240), 0.5), fade, haze);
  final lite = _shade(mix(k.c, _ice, 0.42), fade, haze);
  final side = [dark, col, lite];
  final order = flip ? side.reversed.toList() : side;
  const ts = [-1.0, -0.3, 0.32, 1.0];
  final ext = hw * 1.2;
  final tipP = k.base + d * (k.len + k.tip) + n * (hw * 0.14);
  final round = math.max(1.2, hw * 0.07);
  for (var i = 0; i < 3; i++) {
    _facet(c, [p(ts[i], -ext), p(ts[i + 1], -ext), p(ts[i + 1], k.len), p(ts[i], k.len)], order[i], round);
  }
  for (var i = 0; i < 3; i++) {
    final tc = mix(order[i], _shade(_ice, fade, haze), 0.2);
    _facet(c, [p(ts[i], k.len), p(ts[i + 1], k.len), tipP], tc, round);
  }
  if (detail) {
    final st = flip ? -0.64 : 0.64;
    final hp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.6, hw * 0.13)
      ..color = Colors.white.withValues(alpha: 0.5 * (1 - fade));
    c.drawLine(p(st, k.len * 0.14), p(st, k.len * 0.68), hp);
    c.drawCircle(p(st, k.len * 0.84), math.max(1.1, hw * 0.07), Paint()..color = Colors.white.withValues(alpha: 0.5 * (1 - fade)));
    // second facet line: a dark seam low on the shaft keeps big gems from looking empty
    final sp = Paint()
      ..color = alpha(const Color(0xFF1B1240), 0.22)
      ..strokeWidth = math.max(1.0, hw * 0.05)
      ..strokeCap = StrokeCap.round;
    c.drawLine(p(flip ? 0.2 : -0.12, k.len * 0.3), p(flip ? 0.2 : -0.12, k.len * 0.55), sp);
  }
}

Path _silhouette(_Cry k) {
  final hw = k.w / 2, d = k.dir, n = k.nrm;
  Offset p(double t, double u) => k.base + n * (hw * t) + d * u;
  return _poly([p(-1, 0), p(1, 0), p(1, k.len), k.base + d * (k.len + k.tip) + n * (hw * 0.14), p(-1, k.len)]);
}

// ---------------------------------------------------------------- rock helpers

Path _teardrop(double x, double y0, double hw, double len) => Path()
  ..moveTo(x - hw, y0 - 8)
  ..cubicTo(x - hw * 0.95, y0 + len * 0.45, x - hw * 0.34, y0 + len * 0.82, x, y0 + len)
  ..cubicTo(x + hw * 0.34, y0 + len * 0.82, x + hw * 0.95, y0 + len * 0.45, x + hw, y0 - 8)
  ..close();

void _stalactite(Canvas c, double x, double y0, double hw, double len, Color col, Color lit) {
  final p = _teardrop(x, y0, hw, len);
  c.drawPath(p, Paint()..color = col);
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(x + hw * 0.18, y0 - 10, x + hw * 1.5, y0 + len + 4), Paint()..color = lit)
    ..restore();
}

/// A ceiling edge y(x) for the cave roof; rises into the light opening.
double _roofY(double x, Size s, double base, double amp, int seed) {
  final u = x / s.width;
  var y = base + amp * vnoise(u * 3.2 + 2.1, seed);
  final hole = math.exp(-math.pow((u - _lightX) / 0.13, 4));
  y = y * (1 - hole) - s.height * 0.03 * hole;
  return y * s.height;
}

Path _roofPath(Size s, double base, double amp, int seed) {
  final pts = <Offset>[];
  for (var x = -s.width * 0.1; x <= s.width * 1.1; x += 14) {
    pts.add(Offset(x, _roofY(x, s, base, amp, seed)));
  }
  final p = smoothPath(pts);
  p
    ..lineTo(pts.last.dx, -s.height * 0.1)
    ..lineTo(pts.first.dx, -s.height * 0.1)
    ..close();
  return p;
}

// ---------------------------------------------------------------- sky & far wall

void _sky(Canvas c, Size s) {
  final w = s.width, h = s.height;
  fillSky(c, s, const [_caveTop, _caveMid, _caveLow, Color(0xFF3A2A80)], const [0.0, 0.34, 0.68, 1.0]);
  // flat halo rings around the ceiling opening
  final o = Offset(_lightX * w, -h * 0.01);
  const ringCols = [Color(0xFF2E2478), Color(0xFF4A40B4), Color(0xFF7C80F0), Color(0xFFBFD4FF), Color(0xFFEAF2FF)];
  const ringW = [0.62, 0.44, 0.31, 0.2, 0.12];
  for (var i = 0; i < 5; i++) {
    final rr = ringW[i] * w;
    c.drawOval(Rect.fromCenter(center: o, width: rr * 2, height: rr * 1.35), Paint()..color = alpha(ringCols[i], i == 0 ? 0.5 : (i == 1 ? 0.55 : 1.0)));
  }
  // distant lit chamber far down the cave
  final f = Offset(w * 0.46, h * 0.585);
  for (var i = 0; i < 3; i++) {
    final rr = [0.42, 0.28, 0.16][i] * w;
    c.drawOval(Rect.fromCenter(center: f, width: rr * 2, height: rr * 0.8), Paint()..color = alpha(_glow, [0.05, 0.07, 0.1][i]));
  }
}

void _farWall(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final world = _world(s);
  // far humps with hazy crystals
  final far = Ridge(s, y: 0.575, amp: 0.035, freq: 2.2, seed: 8, octaves: 2, x0: -0.15, x1: 1.15);
  flatRidge(c, far, _rockFar2, light: const Color(0xFF4A3A94), band: 3);
  for (final k in world.planes[0]) {
    _drawCry(c, k, fade: 0.58, haze: _rockFar2, detail: false);
  }
  final near = Ridge(s, y: 0.63, amp: 0.03, freq: 1.7, seed: 21, octaves: 2, x0: -0.15, x1: 1.15);
  flatRidge(c, near, _rockFar, light: const Color(0xFF3D2D86), band: 3);
  // far stalactites on the back roof, hazy
  final r = rng(14);
  c.drawPath(_roofPath(s, 0.075, 0.03, 4), Paint()..color = _rockFar);
  for (var i = 0; i < 9; i++) {
    final x = (0.04 + i * 0.115 + r.nextDouble() * 0.05) * w;
    if ((x / w - _lightX).abs() < 0.16) continue;
    _stalactite(c, x, _roofY(x, s, 0.075, 0.03, 4) - 2, (7 + r.nextDouble() * 6) * w / 390, h * (0.045 + r.nextDouble() * 0.05), _rockFar, const Color(0xFF3D2D86));
  }
}

void _shafts(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final o = Offset(_lightX * w, -h * 0.02);
  paintRays(c, o, length: h * 0.95, centerAngle: math.pi / 2 + 0.25, spread: 0.55, count: 4, color: const Color(0xFFBFD0FF), opacity: 0.11, seed: 9, minWidth: 0.1, maxWidth: 0.2);
  paintRays(c, o, length: h * 0.7, centerAngle: math.pi / 2 + 0.25, spread: 0.4, count: 3, color: _glow, opacity: 0.1, seed: 12, minWidth: 0.04, maxWidth: 0.07);
}

// ---------------------------------------------------------------- mid wall

void _midWall(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final world = _world(s);
  // back roof row, lighter, with a few stalactites
  c.drawPath(_roofPath(s, 0.05, 0.035, 9), Paint()..color = _rockMid);
  final r = rng(33);
  for (var i = 0; i < 7; i++) {
    final x = (0.02 + i * 0.15 + r.nextDouble() * 0.06) * w;
    if ((x / w - _lightX).abs() < 0.15) continue;
    _stalactite(c, x, _roofY(x, s, 0.05, 0.035, 9) - 3, (9 + r.nextDouble() * 8) * w / 390, h * (0.05 + r.nextDouble() * 0.07), _rockMid, _rockLit);
  }
  // side walls
  final left = smoothPath([
    Offset(-w * 0.15, -h * 0.05),
    Offset(w * 0.1, -h * 0.02),
    Offset(w * 0.075, h * 0.12),
    Offset(w * 0.15, h * 0.24),
    Offset(w * 0.08, h * 0.38),
    Offset(w * 0.12, h * 0.52),
    Offset(w * 0.07, h * 0.7),
    Offset(w * 0.14, h * 0.82),
    Offset(-w * 0.15, h * 0.82),
  ], closed: true);
  c.drawPath(left, Paint()..color = _rockMid);
  final right = smoothPath([
    Offset(w * 1.15, -h * 0.05),
    Offset(w * 0.93, -h * 0.02),
    Offset(w * 0.96, h * 0.12),
    Offset(w * 0.86, h * 0.2),
    Offset(w * 0.93, h * 0.34),
    Offset(w * 0.9, h * 0.5),
    Offset(w * 0.94, h * 0.66),
    Offset(w * 0.88, h * 0.8),
    Offset(w * 1.15, h * 0.82),
  ], closed: true);
  c.drawPath(right, Paint()..color = _rockMid);
  c
    ..save()
    ..clipPath(right)
    ..drawPath(right.shift(Offset(w * 0.025, 0)), Paint()..color = _rockLit)
    ..restore();
  // rock outcrops the wall crystals grow from
  for (final o in [Offset(w * 0.95, h * 0.305), Offset(w * 0.07, h * 0.21)]) {
    c.drawPath(blobPath(o, w * 0.11, h * 0.03, seed: 3, wobble: 0.1), Paint()..color = _rockMid);
  }
  // wall crystals
  for (final k in world.planes[1].where((k) => k.base.dy < h * 0.5)) {
    _drawCry(c, k, fade: 0.15, haze: _caveLow);
  }
  // far shore of the lake
  final shore = Ridge(s, y: 0.745, amp: 0.012, freq: 2.0, seed: 55, octaves: 2, x0: -0.15, x1: 1.15);
  flatRidge(c, shore, _rockMid, light: _rockLit, band: 3, bottomY: h * 0.82);
  for (final k in world.planes[1].where((k) => k.base.dy >= h * 0.5)) {
    _drawCry(c, k, fade: 0.1, haze: _caveLow);
  }
}

// ---------------------------------------------------------------- lake

/// Mirrors [list] about [axis] with a rippled, fading look.
void _reflect(Canvas c, Size s, List<_Cry> list, double axis, double strength, double fadeLen, {double fade = 0}) {
  final bounds = Rect.fromLTRB(-s.width * 0.3, axis, s.width * 1.3, math.min(axis + fadeLen, s.height * 1.15));
  c.saveLayer(bounds, Paint()..color = Color.fromRGBO(255, 255, 255, strength));
  final band = 3.0 * s.width / 390;
  var j = 0;
  for (var y = bounds.top; y < bounds.bottom; y += band, j++) {
    final dist = (y - axis) / fadeLen;
    final dx = (math.sin(j * 0.55 + 0.6) + 0.5 * math.sin(j * 1.3)) * (0.8 + 2.4 * dist) * s.width / 390;
    c
      ..save()
      ..clipRect(Rect.fromLTRB(bounds.left, y, bounds.right, y + band + 0.5))
      ..translate(dx, 2 * axis)
      ..scale(1, -1);
    for (final k in list) {
      _drawCry(c, k, fade: fade, haze: _waterB, detail: false);
    }
    c.restore();
  }
  c.drawRect(
    bounds,
    Paint()
      ..blendMode = BlendMode.dstOut
      ..shader = ui.Gradient.linear(bounds.topCenter, bounds.bottomCenter, [const Color(0x00000000), const Color(0xFF000000)], const [0.0, 1.0]),
  );
  c.restore();
}

void _lake(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final world = _world(s);
  final top = Ridge(s, y: _waterY, amp: 0.003, freq: 2, seed: 3, octaves: 2, x0: -0.15, x1: 1.15);
  c.drawPath(top.fill(h * 1.1), Paint()..color = _waterA);
  final b1 = Ridge(s, y: 0.86, amp: 0.004, freq: 1.5, seed: 4, octaves: 2, x0: -0.15, x1: 1.15);
  c.drawPath(b1.fill(h * 1.1), Paint()..color = _waterB);
  final b2 = Ridge(s, y: 0.93, amp: 0.004, freq: 1.3, seed: 6, octaves: 2, x0: -0.15, x1: 1.15);
  c.drawPath(b2.fill(h * 1.1), Paint()..color = _waterC);
  // reflections of the far shore crystals
  final shoreCry = world.planes[1].where((k) => k.base.dy >= h * 0.5).toList();
  c.save();
  c.clipRect(Rect.fromLTRB(-w * 0.3, h * _waterY, w * 1.3, h * 1.1));
  _reflect(c, s, shoreCry, h * _waterY - 2, 0.42, h * 0.17, fade: 0.25);
  c.restore();
  // soft light band on the water at the horizon
  c.drawRect(Rect.fromLTRB(-w * 0.2, h * _waterY, w * 1.2, h * _waterY + 3), Paint()..color = alpha(_glow, 0.35));
}

void _mist(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(5);
  for (var i = 0; i < 5; i++) {
    final x = (i + 0.2 + r.nextDouble() * 0.5) * w / 5;
    final y = h * (0.77 + r.nextDouble() * 0.1);
    final ww = w * (0.25 + r.nextDouble() * 0.15), hh = h * (0.012 + r.nextDouble() * 0.01);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: ww, height: hh), Radius.circular(hh)), Paint()..color = alpha(_glow, 0.1 + r.nextDouble() * 0.06));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + ww * 0.15, y - hh * 0.9), width: ww * 0.6, height: hh * 0.9), Radius.circular(hh)), Paint()..color = alpha(_glow, 0.07));
  }
}

// ---------------------------------------------------------------- islands (hero)

void _island(Canvas c, Size s, double fx, double fy, double fw, double fh, int seed) {
  final w = s.width, h = s.height;
  final cx = fx * w, base = fy * h, hw = fw * w / 2, hh = fh * h;
  final p = smoothPath([
    Offset(cx - hw * 1.02, base + hh * 0.9),
    Offset(cx - hw * 0.8, base + hh * 0.1),
    Offset(cx - hw * 0.35, base - hh * 0.55),
    Offset(cx + hw * 0.2, base - hh * 0.62),
    Offset(cx + hw * 0.72, base - hh * 0.1),
    Offset(cx + hw * 1.02, base + hh * 0.9),
    Offset(cx, base + hh * 1.15),
  ], closed: true);
  c.drawPath(p, Paint()..color = _rockDark);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(-hw * 0.0, hh * 0.28)), Paint()..color = const Color(0xFF150F2C))
    ..drawPath(p.shift(Offset(0, hh * 0.12)), Paint()..color = _rockDark)
    ..restore();
  // lit rim on the upper right
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(cx + hw * 0.18, base - hh * 1.2, cx + hw * 1.3, base + hh * 0.2), Paint()..color = _rockMid)
    ..restore();
  // ripple ring where the rock meets the water
  c.drawOval(Rect.fromCenter(center: Offset(cx, base + hh * 1.05), width: hw * 2.5, height: hh * 0.5), Paint()..color = alpha(_glow, 0.1));
}

void _islands(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final world = _world(s);
  final near = world.planes[2];
  // reflections first, in the water
  final hero = near.where((k) => k.base.dx < w * 0.4).toList();
  final east = near.where((k) => k.base.dx > w * 0.7).toList();
  final tiny = near.where((k) => k.base.dx >= w * 0.4 && k.base.dx <= w * 0.7).toList();
  _reflect(c, s, hero, h * 0.852, 0.6, h * 0.24);
  _reflect(c, s, east, h * 0.86, 0.55, h * 0.16);
  _reflect(c, s, tiny, h * 0.842, 0.4, h * 0.08);
  // rocks
  _island(c, s, 0.5, 0.835, 0.2, 0.014, 2);
  _island(c, s, 0.83, 0.856, 0.4, 0.028, 3);
  _island(c, s, 0.2, 0.846, 0.58, 0.034, 1);
  for (final k in hero) {
    _drawCry(c, k);
  }
  for (final k in east) {
    _drawCry(c, k);
  }
  for (final k in tiny) {
    _drawCry(c, k);
  }
  // stepping stones leading across the lake to the lantern
  const stones = [Offset(0.70, 0.905), Offset(0.62, 0.925), Offset(0.53, 0.915), Offset(0.45, 0.93), Offset(0.37, 0.915)];
  for (var i = 0; i < stones.length; i++) {
    final o = Offset(stones[i].dx * w, stones[i].dy * h);
    final sw = w * (0.1 - i * 0.006), sh = sw * 0.3;
    c.drawOval(Rect.fromCenter(center: o.translate(0, sh * 0.3), width: sw * 1.5, height: sh * 0.9), Paint()..color = alpha(_glow, 0.12));
    c.drawOval(Rect.fromCenter(center: o.translate(0, sh * 0.35), width: sw, height: sh), Paint()..color = _rockDark);
    c.drawOval(Rect.fromCenter(center: o, width: sw, height: sh), Paint()..color = _rockMid);
    c.drawOval(Rect.fromCenter(center: o.translate(sw * 0.08, -sh * 0.12), width: sw * 0.72, height: sh * 0.6), Paint()..color = _rockLit);
  }
  // pebbles in front of the hero island
  final r = rng(44);
  for (var i = 0; i < 6; i++) {
    final x = w * (0.04 + r.nextDouble() * 0.36), y = h * (0.855 + r.nextDouble() * 0.02);
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 9 + r.nextDouble() * 10, height: 5 + r.nextDouble() * 3), Paint()..color = _rockDark);
  }
}

// ---------------------------------------------------------------- foreground

void _foreground(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final world = _world(s);
  // front roof with stalactites
  c.drawPath(_roofPath(s, 0.03, 0.03, 17), Paint()..color = _rockDark);
  final r = rng(61);
  final xs = [0.03, 0.17, 0.30, 0.43, 0.56, 0.88, 0.97];
  for (var i = 0; i < xs.length; i++) {
    final x = (xs[i] + (r.nextDouble() - 0.5) * 0.03) * w;
    final long = i == 2 ? 0.14 : 0.04 + r.nextDouble() * 0.08;
    _stalactite(c, x, _roofY(x, s, 0.03, 0.03, 17) - 3, (9 + r.nextDouble() * 9) * w / 390, h * long, _rockDark, _rockMid);
  }
  for (final k in world.hangers) {
    _drawCry(c, k);
  }
  c.drawPath(_roofPath(s, 0.03, 0.03, 17), Paint()..color = _rockDark);
  // thin dark edges of the cave at both sides
  final le = smoothPath([Offset(-w * 0.2, -h * 0.1), Offset(w * 0.03, h * 0.0), Offset(w * 0.0, h * 0.4), Offset(w * 0.025, h * 0.7), Offset(-w * 0.2, h * 0.8)], closed: true);
  c.drawPath(le, Paint()..color = _rockDark);
  final re = smoothPath([Offset(w * 1.2, -h * 0.1), Offset(w * 0.97, h * 0.0), Offset(w * 1.0, h * 0.42), Offset(w * 0.975, h * 0.72), Offset(w * 1.2, h * 0.8)], closed: true);
  c.drawPath(re, Paint()..color = _rockDark);
  // bottom shore rocks
  final bl = smoothPath([
    Offset(-w * 0.2, h * 0.93),
    Offset(w * 0.04, h * 0.945),
    Offset(w * 0.2, h * 0.975),
    Offset(w * 0.3, h * 1.02),
    Offset(w * 0.3, h * 1.15),
    Offset(-w * 0.2, h * 1.15),
  ], closed: true);
  c.drawPath(bl, Paint()..color = _rockLit);
  c
    ..save()
    ..clipPath(bl)
    ..drawPath(bl.shift(Offset(0, h * 0.007)), Paint()..color = _rockMid)
    ..drawPath(bl.shift(Offset(0, h * 0.016)), Paint()..color = _rockDark)
    ..restore();
  final br = smoothPath([
    Offset(w * 1.2, h * 0.935),
    Offset(w * 0.96, h * 0.945),
    Offset(w * 0.8, h * 0.975),
    Offset(w * 0.68, h * 1.03),
    Offset(w * 0.68, h * 1.15),
    Offset(w * 1.2, h * 1.15),
  ], closed: true);
  c.drawPath(br, Paint()..color = _rockLit);
  c
    ..save()
    ..clipPath(br)
    ..drawPath(br.shift(Offset(0, h * 0.007)), Paint()..color = _rockMid)
    ..drawPath(br.shift(Offset(0, h * 0.016)), Paint()..color = _rockDark)
    ..restore();
  for (final k in world.planes[3]) {
    _drawCry(c, k);
  }
  // the lantern: a little warm lamp on the right rock
  final lp = Offset(w * 0.8, h * 0.972);
  final k = w / 390 * 1.5;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lp + Offset(0, 4 * k), width: 16 * k, height: 5 * k), Radius.circular(2 * k)), Paint()..color = const Color(0xFF3A2D5E));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lp - Offset(0, 6 * k), width: 13 * k, height: 17 * k), Radius.circular(6 * k)), Paint()..color = _lantern);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lp - Offset(-2.5 * k, 6 * k), width: 5 * k, height: 14 * k), Radius.circular(3 * k)), Paint()..color = const Color(0xFFFFE6A8));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lp - Offset(0, 16.5 * k), width: 15 * k, height: 4.5 * k), Radius.circular(2.2 * k)), Paint()..color = const Color(0xFF3A2D5E));
  c.drawCircle(lp - Offset(0, 21.5 * k), 2.4 * k, Paint()..color = const Color(0xFF3A2D5E));
}

// ---------------------------------------------------------------- scroll / live

double _dx(Clock k, Size s, double drift, int cycles, double phase) => drift * s.width * k.sine(cycles, phase);

/// Inner-light pulse, halo rings and travelling glints for one depth plane.
void _glowPlane(Canvas c, Size s, Clock k, int plane, double drift, int cycles, double phase) {
  final world = _world(s);
  final list = world.planes[plane];
  c
    ..save()
    ..translate(_dx(k, s, drift, cycles, phase), 0);
  final ice = Paint();
  for (var i = 0; i < list.length; i++) {
    final cry = list[i];
    final pu = k.pulse(cry.cyc, cry.ph);
    final mid = cry.base + cry.dir * (cry.len * 0.55);
    if (cry.big) {
      c.drawCircle(mid, cry.len * 0.78, Paint()..color = alpha(cry.c, 0.02 + 0.035 * pu));
      c.drawCircle(mid, cry.len * 0.5, Paint()..color = alpha(cry.c, 0.03 + 0.04 * pu));
    }
    final far = plane == 0 ? 0.5 : 1.0;
    ice.color = alpha(mix(cry.c, _ice, 0.75), (0.02 + 0.2 * pu) * far);
    c.drawPath(_silhouette(cry), ice);
    // glint travelling up the bright edge
    if (plane > 0 && (i % 2 == 0 || cry.big)) {
      final t = k.saw(cry.cyc + 1, cry.ph * 1.7);
      final a = math.pow(math.sin(math.pi * t), 6).toDouble();
      if (a > 0.04) {
        final flip = cry.nrm.dx < 0;
        final pos = cry.base + cry.dir * (cry.len * (0.15 + 0.85 * t)) + cry.nrm * (cry.w * (flip ? -0.2 : 0.2));
        sparkle(c, pos, (3.0 + cry.w * 0.07).clamp(3.0, 7.0), Colors.white, a);
      }
    }
  }
  c.restore();
}

void _ripples(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final k0 = w / 390;
  final dx = _dx(k, s, _driftMid, _cycMid, _phMid);
  // slow expanding rings around a few spots
  final spots = <Offset>[Offset(w * 0.46, h * 0.9), Offset(w * 0.68, h * 0.935), Offset(w * 0.33, h * 0.925), Offset(w * 0.3, h * 0.87)];
  final ringP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3 * k0;
  for (var i = 0; i < spots.length; i++) {
    final t = k.saw(4 + i % 2, i * 0.27);
    final rr = (5 + 30 * t) * k0;
    ringP.color = alpha(_ice, 0.4 * (1 - t) * (1 - t));
    c.drawOval(Rect.fromCenter(center: spots[i] + Offset(dx, 0), width: rr * 2.4, height: rr * 0.7), ringP);
  }
  // the drip from the long stalactite
  final dropX = w * 0.30 + _dx(k, s, 0.04, 2, 0.3), tipY = h * 0.15, endY = h * 0.87;
  final t = k.saw(5, 0.0);
  if (t < 0.55) {
    final f = t / 0.55;
    final y = tipY + (endY - tipY) * f * f;
    c.drawOval(Rect.fromCenter(center: Offset(dropX, y), width: 3.2 * k0, height: 5 * k0), Paint()..color = alpha(_ice, 0.85 * math.min(1.0, f * 6)));
  } else {
    final f = (t - 0.55) / 0.45;
    final rr = (3 + 26 * f) * k0;
    ringP.color = alpha(_ice, 0.55 * (1 - f));
    c.drawOval(Rect.fromCenter(center: Offset(dropX, endY), width: rr * 2.6, height: rr * 0.7), ringP);
  }
  // sliding glints on the water
  paintShimmer(c, s, k, region: Rect.fromLTRB(w * 0.05, h * 0.8, w * 0.95, h * 0.96), count: 26, seed: 31, color: _ice, cycles: 8);
  paintShimmer(c, s, k, region: Rect.fromLTRB(w * 0.1, h * 0.8, w * 0.9, h * 0.9), count: 12, seed: 7, color: _glow, cycles: 6);
}

void _motes(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 34, seed: 5, colors: [_glow, _ice, _pink, _teal, _amethyst], minSize: 1.2, maxSize: 2.6, flow: Offset(0.04, -1), cycles: 1, spread: 2, wander: 12, shape: ParticleShape.glow, region: Rect.fromLTRB(0, 0.05, 1, 0.98), opacity: 0.9, haloScale: 3.4));
  paintParticles(c, s, k, const ParticleSpec(count: 9, seed: 12, colors: [_ice, _glow], minSize: 1.4, maxSize: 2.4, wander: 6, twinkle: 0.9, twinkleCycles: 9, shape: ParticleShape.spark, region: Rect.fromLTRB(0.05, 0.08, 0.95, 0.9), opacity: 0.85));
}

void _lanternGlow(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final k0 = w / 390;
  final dx = _dx(k, s, 0.04, 2, 0.3);
  final o = Offset(w * 0.8 + dx, h * 0.972 - 10 * k0);
  final pu = k.pulse(7, 0.2);
  c.drawCircle(o, (66 + 6 * pu) * k0, Paint()..color = alpha(_lantern, 0.08 + 0.03 * pu));
  c.drawCircle(o, (40 + 4 * pu) * k0, Paint()..color = alpha(_lantern, 0.13 + 0.04 * pu));
}
