import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Floating Sky Islands in flat, graphic 2D: a golden sky above a sea of
// towering clouds, a hero island with a tiny wood, stone arch and waterfall,
// a smaller island, far islets, a little home island with a lit cottage.
// Light comes from the upper right (sun), shade sides face left... no: the
// sun sits upper right, so lit crescents are on the RIGHT and shade on the LEFT.

// ---- palette
const _skyTop = Color(0xFF3FA9F5), _skyMid = Color(0xFFBCE6FF), _skyLow = Color(0xFFFFE9B8);
const _cloudShadeA = Color(0xFFBFD3F2), _cloudShadeB = Color(0xFFC9C2F0);
const _water = Color(0xFF8FE3F0), _waterLight = Color(0xFFBFF3FF), _waterWhite = Color(0xFFF2FDFF);

class _Pal {
  const _Pal({
    required this.grassL,
    required this.grass,
    required this.rockL,
    required this.rock,
    required this.rockS,
    required this.crown,
    required this.crownL,
    required this.pine,
    required this.trunk,
    required this.stone,
    required this.stoneS,
  });
  final Color grassL, grass, rockL, rock, rockS, crown, crownL, pine, trunk, stone, stoneS;

  _Pal haze(Color h, double a) => _Pal(
        grassL: hazeTo(grassL, h, a),
        grass: hazeTo(grass, h, a),
        rockL: hazeTo(rockL, h, a),
        rock: hazeTo(rock, h, a),
        rockS: hazeTo(rockS, h, a),
        crown: hazeTo(crown, h, a),
        crownL: hazeTo(crownL, h, a),
        pine: hazeTo(pine, h, a),
        trunk: hazeTo(trunk, h, a),
        stone: hazeTo(stone, h, a),
        stoneS: hazeTo(stoneS, h, a),
      );
}

const _pal = _Pal(
  grassL: Color(0xFF8FE25F),
  grass: Color(0xFF3FB65E),
  rockL: Color(0xFFB4A18C),
  rock: Color(0xFF9C8A76),
  rockS: Color(0xFF7A6678),
  crown: Color(0xFF2FA056),
  crownL: Color(0xFF7ED957),
  pine: Color(0xFF248A4E),
  trunk: Color(0xFF7A5238),
  stone: Color(0xFFE2D8C6),
  stoneS: Color(0xFFB5A8A0),
);

// ---- island motion (shared by the cached layer and the live details on it)
class _Bob {
  const _Bob(this.dx, this.dy, this.cycles, this.phase);
  final double dx, dy, phase;
  final int cycles;
  Offset at(Size s, Clock k) => Offset(dx * s.width * k.sine(cycles, phase), dy * s.height * k.sine(cycles, phase + 0.25));
}

const _bobHero = _Bob(0.004, 0.0075, 3, 0.0);
const _bobMid = _Bob(0.006, 0.0095, 4, 0.3);
const _bobFar = _Bob(0.004, 0.0055, 5, 0.6);
const _bobHome = _Bob(0.007, 0.009, 3, 0.5);

SceneSpec skyislandsScene() => SceneSpec(
      focusY: -0.45,
      topShade: 0.1,
      bottomShade: 0.1,
      layers: [
        Layer.still(_sky),
        Layer.still(_mountains),
        Layer.still(_rays, rotate: 0.05, swayCycles: 2, pivot: const Alignment(0.6, -0.86)),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.03, bandBottom: 0.86),
        Layer.still(_farIslands, driftX: _bobFar.dx, driftY: _bobFar.dy, driftCycles: _bobFar.cycles, driftPhase: _bobFar.phase),
        Layer.still(_midIsland, driftX: _bobMid.dx, driftY: _bobMid.dy, driftCycles: _bobMid.cycles, driftPhase: _bobMid.phase),
        Layer.still(_heroIsland, driftX: _bobHero.dx, driftY: _bobHero.dy, driftCycles: _bobHero.cycles, driftPhase: _bobHero.phase),
        Layer.live(_islandLife),
        Layer.scroll(_cloudsMid, scrollCycles: 2, bandTop: 0.5, bandBottom: 1.0),
        Layer.still(_homeIsland, driftX: _bobHome.dx, driftY: _bobHome.dy, driftCycles: _bobHome.cycles, driftPhase: _bobHome.phase),
        Layer.live(_homeLife),
        Layer.scroll(_cloudsFront, scrollCycles: 3, bandTop: 0.78, bandBottom: 1.0),
        Layer.live(_air),
        Layer.live(_birds),
      ],
    );

// ---------------------------------------------------------------- sky

Offset _sunPos(Size s) => Offset(s.width * 0.8, s.height * 0.075);

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_skyTop, _skyMid, _skyLow], const [0.0, 0.36, 0.7]);
  final o = _sunPos(s), r = s.width * 0.062;
  c.drawCircle(o, r * 2.5, Paint()..color = const Color(0xFFFFF6C8).withValues(alpha: 0.16));
  c.drawCircle(o, r * 1.65, Paint()..color = const Color(0xFFFFF6C8).withValues(alpha: 0.28));
  c.drawCircle(o, r, Paint()..color = const Color(0xFFFFF9D6));
}

void _mountains(Canvas c, Size s) {
  const sky = Color(0xFFD8ECFB);
  final far = Ridge(s, y: 0.53, amp: 0.08, freq: 1.5, seed: 4, octaves: 2, sharp: 0.45);
  flatMountains(c, far, hazeTo(const Color(0xFFB8C8F0), sky, 0.25), hazeTo(const Color(0xFF9FB1E6), sky, 0.25), bottomY: s.height * 0.8, snow: const Color(0xFFF4F8FF), snowLine: s.height * 0.47);
  final near = Ridge(s, y: 0.58, amp: 0.05, freq: 2.2, seed: 9, octaves: 2, sharp: 0.3);
  flatMountains(c, near, const Color(0xFF9DB6EA), const Color(0xFF879FDC), bottomY: s.height * 0.85);
}

void _rays(Canvas c, Size s) {
  paintRays(c, _sunPos(s), length: s.height * 0.95, centerAngle: math.pi / 2, spread: 5.6, count: 12, color: const Color(0xFFFFF4C8), opacity: 0.2, seed: 6, minWidth: 0.05, maxWidth: 0.1);
}

// ---------------------------------------------------------------- clouds

void _puff(Canvas c, Offset o, double r, Color lit, Color shade) {
  // flat cel-shaded puff, light from the upper right: shade crescent lower-left
  c.drawCircle(o, r, Paint()..color = shade);
  c.drawCircle(o + Offset(r * 0.1, -r * 0.14), r * 0.88, Paint()..color = lit);
}

void _deck(
  Canvas c,
  Size s, {
  required double top,
  required double bottom,
  required int n,
  required double rMin,
  required double rMax,
  required int seed,
  required Color lit,
  required Color shade,
  required Color fill,
  int rows = 2,
  List<(double, double)> towers = const [],
}) {
  final w = s.width, h = s.height;
  final r = rng(seed);
  // towering cumulus first (behind)
  for (final (fx, sc) in towers) {
    final x = fx * w;
    final base = top * h + w * 0.05;
    const stack = [(0.0, 0.0, 0.12), (0.03, -0.09, 0.1), (-0.02, -0.17, 0.085), (0.03, -0.24, 0.065), (0.0, -0.3, 0.045)];
    for (final o in [-w, 0.0, w]) {
      for (final (dx, dy, rr) in stack) {
        _puff(c, Offset(x + o + dx * w * sc, base + dy * w * sc), rr * w * sc, lit, shade);
      }
    }
  }
  var rowY = top * h;
  var lastR = 0.0;
  for (var row = 0; row < rows; row++) {
    final list = <(double, double, double)>[];
    for (var i = 0; i < n; i++) {
      final x = (i + (row.isOdd ? 0.5 : 0.0) + 0.25 * r.nextDouble()) * w / n;
      final rad = (rMin + (rMax - rMin) * r.nextDouble()) * w * (0.9 + 0.2 * row);
      list.add((x, rad, r.nextDouble()));
    }
    for (final (x, rad, j) in list) {
      for (final o in [-w, 0.0, w]) {
        _puff(c, Offset(x + o, rowY + rad * (0.8 + 0.3 * j)), rad, lit, shade);
      }
      lastR = rad;
    }
    rowY += (rMin + rMax) * w * 0.28;
  }
  c.drawRect(Rect.fromLTRB(-w, rowY + lastR * 0.85, 2 * w, bottom * h + 4), Paint()..color = fill);
}

void _cloudsBack(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // small sky clouds drifting between the islands
  final specs = <(double, double, double, int)>[
    (0.10, 0.215, 0.30, 3),
    (0.62, 0.09, 0.26, 5),
    (0.86, 0.285, 0.30, 8),
    (0.38, 0.425, 0.34, 11),
    (0.90, 0.5, 0.26, 14),
    (0.02, 0.5, 0.24, 17),
  ];
  for (final (fx, fy, fw, sd) in specs) {
    for (final o in [-w, 0.0, w]) {
      flatCloud(c, Offset(fx * w + o, fy * h), fw * w, color: const Color(0xFFFFFFFF), shade: const Color(0xFFD6E6FA), seed: sd, puff: 1.0);
    }
  }
  _deck(c, s, top: 0.6, bottom: 0.9, n: 6, rMin: 0.07, rMax: 0.1, seed: 31, lit: const Color(0xFFEFF7FF), shade: const Color(0xFFB4CBF0), fill: const Color(0xFFB4CBF0), towers: const [(0.14, 1.15), (0.6, 0.8), (0.92, 1.0)]);
}

void _cloudsMid(Canvas c, Size s) {
  _deck(c, s, top: 0.7, bottom: 1.0, n: 5, rMin: 0.09, rMax: 0.13, seed: 41, lit: const Color(0xFFFDFEFF), shade: _cloudShadeA, fill: _cloudShadeA, towers: const [(0.3, 0.8), (0.84, 0.65)]);
}

void _cloudsFront(Canvas c, Size s) {
  _deck(c, s, top: 0.875, bottom: 1.03, n: 4, rMin: 0.11, rMax: 0.16, seed: 51, lit: const Color(0xFFFFFFFF), shade: _cloudShadeB, fill: const Color(0xFFFFFFFF), rows: 2);
}

// ---------------------------------------------------------------- island geometry

class _Geo {
  _Geo(this.cx, this.yTop, this.w, this.depth, this.seed, {this.hump = 0.05});
  final double cx, yTop, w, depth, hump;
  final int seed;
  double get hw => w / 2;
  double get th => w * 0.075;
  double topAt(double x) {
    final t = ((x - cx) / hw).clamp(-1.05, 1.05);
    return yTop + w * hump * t * t;
  }

  double get tipY => yTop + th * 0.6 + depth;
}

_Geo _heroG(Size s) => _Geo(s.width * 0.42, s.height * 0.168, s.width * 0.76, s.height * 0.21, 3);
_Geo _midG(Size s) => _Geo(s.width * 0.9, s.height * 0.3, s.width * 0.42, s.height * 0.13, 7, hump: 0.06);
_Geo _homeG(Size s) => _Geo(s.width * 0.7, s.height * 0.805, s.width * 0.46, s.height * 0.09, 11, hump: 0.045);

Path _bodyPath(_Geo g) {
  final r = rng(g.seed);
  const prof = [
    (-1.0, 0.0),
    (-0.94, 0.18),
    (-0.8, 0.32),
    (-0.66, 0.4),
    (-0.52, 0.58),
    (-0.34, 0.68),
    (-0.22, 0.84),
    (-0.06, 0.97),
    (0.04, 1.0),
    (0.15, 0.86),
    (0.28, 0.7),
    (0.44, 0.64),
    (0.56, 0.45),
    (0.72, 0.36),
    (0.88, 0.2),
    (1.0, 0.0),
  ];
  final pts = <Offset>[];
  for (final (tx, ty) in prof) {
    final x = g.cx + tx * g.hw * 0.99;
    final jy = (r.nextDouble() - 0.5) * g.depth * 0.025;
    pts.add(Offset(x, g.topAt(x) + g.th * 0.55 + ty * (g.tipY - g.topAt(x) - g.th * 0.55) + jy));
  }
  for (final tx in [0.7, 0.35, 0.0, -0.35, -0.7]) {
    final x = g.cx + tx * g.hw;
    pts.add(Offset(x, g.topAt(x) + g.th * 0.3));
  }
  return smoothPath(pts, closed: true);
}

void _drawBody(Canvas c, _Geo g, _Pal p, {bool strata = true}) {
  final body = _bodyPath(g);
  // light from the upper right: lit crescent on the right, flat shade on the left
  c.drawPath(body, Paint()..color = p.rock);
  c.save();
  c.clipPath(body);
  final sh = smoothPath([
    Offset(g.cx - g.hw * 1.3, g.yTop - 10),
    Offset(g.cx - g.hw * 1.3, g.tipY + 20),
    Offset(g.cx - g.hw * 0.08, g.tipY + 20),
    Offset(g.cx - g.hw * 0.02, g.yTop + g.depth * 0.78),
    Offset(g.cx - g.hw * 0.22, g.yTop + g.depth * 0.45),
    Offset(g.cx - g.hw * 0.3, g.yTop + g.depth * 0.18),
    Offset(g.cx - g.hw * 0.2, g.yTop - 4),
  ], closed: true);
  c.drawPath(sh, Paint()..color = p.rockS);
  // lit crescent on the right edge
  c.drawPath(body, Paint()..color = p.rockL);
  c.drawPath(body.shift(Offset(-g.w * 0.025, g.w * 0.004)), Paint()..color = p.rock);
  c.drawPath(sh, Paint()..color = p.rockS);
  if (strata) {
    final sp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.6, g.w * 0.007)
      ..color = mix(p.rock, p.rockS, 0.55);
    final sp2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.6, g.w * 0.007)
      ..color = mix(p.rockS, p.rock, 0.3);
    for (var i = 0; i < 3; i++) {
      final f = 0.2 + i * 0.2;
      final y0 = g.yTop + g.th + f * g.depth;
      final pts = [for (var j = -5; j <= 5; j++) Offset(g.cx + j * g.hw * 0.22, y0 + g.w * 0.035 * (1 - (j / 5.0) * (j / 5.0)))];
      c.drawPath(smoothPath(pts), (g.cx > 0 && i.isEven) ? sp : sp2);
    }
  }
  c.restore();
}

Path _grassPath(_Geo g) {
  final r = rng(g.seed + 100);
  final pts = <Offset>[];
  for (var i = 0; i <= 10; i++) {
    final tx = -1.02 + i * 0.204;
    final x = g.cx + tx * g.hw;
    pts.add(Offset(x, g.topAt(x) + ((i == 0 || i == 10) ? g.th * 0.35 : 0)));
  }
  for (var i = 8; i >= 0; i--) {
    final tx = -0.92 + (8 - i) * 0.23;
    final x = g.cx + tx * g.hw;
    final drip = i.isEven ? 0.8 + r.nextDouble() * 0.5 : 0.55 + r.nextDouble() * 0.25;
    final edge = (1 - tx.abs()) < 0.15 ? 0.6 : 1.0;
    pts.add(Offset(x, g.topAt(x) + g.th * drip * edge));
  }
  return smoothPath(pts, closed: true);
}

void _drawGrass(Canvas c, _Geo g, _Pal p) {
  final gp = _grassPath(g);
  c.drawPath(gp, Paint()..color = p.grassL);
  c
    ..save()
    ..clipPath(gp)
    ..drawPath(gp.shift(Offset(0, g.th * 0.3)), Paint()..color = p.grass)
    ..restore();
}

void _crystal(Canvas c, Offset top, double w, double h, Color col, Color light, {double lean = 0}) {
  final p = Path()
    ..moveTo(top.dx - w / 2, top.dy)
    ..lineTo(top.dx + w / 2, top.dy)
    ..lineTo(top.dx + w * 0.38, top.dy + h * 0.4)
    ..lineTo(top.dx + lean, top.dy + h)
    ..lineTo(top.dx - w * 0.38, top.dy + h * 0.4)
    ..close();
  c.drawPath(p, Paint()..color = col);
  c.drawPath(p, Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 1.4
    ..color = col);
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(top.dx + w * 0.02 + lean * 0.3, top.dy, top.dx + w, top.dy + h), Paint()..color = light)
    ..restore();
}

void _roots(Canvas c, _Geo g, _Pal p, int count, double len) {
  final r = rng(g.seed + 50);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(1.4, g.w * 0.006)
    ..color = mix(p.trunk, p.rockS, 0.3);
  final leaf = Paint()..color = p.crown;
  final body = _bodyPath(g);
  for (var i = 0; i < count; i++) {
    final x = g.cx + (-0.7 + 1.4 * (i + r.nextDouble() * 0.6) / count) * g.hw * 0.7;
    // find the underside y at x by scanning the body path downward
    var y = g.yTop + g.th;
    for (var yy = g.tipY; yy > g.yTop; yy -= 2) {
      if (body.contains(Offset(x, yy))) {
        y = yy;
        break;
      }
    }
    final l = len * (0.5 + r.nextDouble() * 0.7);
    final sw = (r.nextDouble() - 0.5) * 10;
    c.drawPath(
      Path()
        ..moveTo(x, y - 2)
        ..quadraticBezierTo(x + sw, y + l * 0.5, x + sw * 0.4, y + l),
      stroke,
    );
    c.drawCircle(Offset(x + sw * 0.4, y + l), math.max(1.6, g.w * 0.008), leaf);
  }
}

void _pebbles(Canvas c, _Geo g, _Pal p, List<(double, double, double)> spec) {
  for (var i = 0; i < spec.length; i++) {
    final (dx, dy, sz) = spec[i];
    final o = Offset(g.cx + dx * g.w, g.tipY + dy * g.depth);
    final w = g.w * sz;
    final pth = blobPath(o, w, w * 0.8, seed: 5 + i, wobble: 0.1, lumps: 7);
    c.drawPath(pth, Paint()..color = p.rock);
    c
      ..save()
      ..clipPath(pth)
      ..drawOval(Rect.fromCenter(center: o + Offset(-w * 0.55, w * 0.1), width: w * 1.6, height: w * 1.9), Paint()..color = p.rockS)
      ..restore();
    c.drawCircle(o + Offset(w * 0.45, -w * 0.4), w * 0.16, Paint()..color = p.rockL);
  }
}

void _flora(Canvas c, _Geo g, _Pal p, {double from = -0.82, double to = 0.82, double size = 0.15, int seed = 1, List<(double, double)> gaps = const [], double step = 0.13}) {
  final r = rng(seed);
  final k0 = g.w / 290;
  final trees = <(double, double, bool)>[];
  var tx = from;
  while (tx < to) {
    final inGap = gaps.any((e) => tx > e.$1 && tx < e.$2);
    if (!inGap) trees.add((tx, size * (0.65 + r.nextDouble() * 0.7), r.nextDouble() < 0.3));
    tx += step * (0.75 + r.nextDouble() * 0.6);
  }
  // back to front: tall first
  trees.sort((a, b) => b.$2.compareTo(a.$2));
  for (final (t, hh, pine) in trees) {
    final x = g.cx + t * g.hw;
    final base = Offset(x, g.topAt(x) + g.th * 0.3);
    final th = g.w * hh;
    if (pine) {
      flatPine(c, base, th * 1.25, color: p.pine, shade: darken(p.pine, 0.07), trunk: p.trunk, tiers: 3, width: 0.55);
    } else {
      flatTree(c, base, th, crown: p.crown, light: p.crownL, trunk: p.trunk, trunkShade: darken(p.trunk, 0.08), seed: r.nextInt(999), lean: (r.nextDouble() - 0.5) * 0.3);
    }
  }
  // bushes and flowers in the gaps of the trees
  var bx = from + 0.05;
  while (bx < to) {
    final inGap = gaps.any((e) => bx > e.$1 && bx < e.$2);
    if (!inGap && r.nextDouble() < 0.5) {
      final x = g.cx + bx * g.hw;
      flatBush(c, Offset(x, g.topAt(x) + g.th * 0.3), g.w * (0.06 + r.nextDouble() * 0.04), color: p.crown, light: p.crownL, seed: r.nextInt(99));
    }
    bx += 0.18;
  }
  const petals = [Color(0xFFFFFFFF), Color(0xFFFFE066), Color(0xFFF7A8C8), Color(0xFFD2C4FA)];
  for (var i = 0; i < 16; i++) {
    final t = from + r.nextDouble() * (to - from) * 1.1;
    if (gaps.any((e) => t > e.$1 && t < e.$2)) continue;
    final x = g.cx + t * g.hw;
    c.drawCircle(Offset(x, g.topAt(x) + g.th * (0.06 + r.nextDouble() * 0.18)), math.max(1.2, 1.9 * k0), Paint()..color = petals[i % 4]);
  }
}

void _ruins(Canvas c, Offset base, double u, _Pal p, {bool arch = true}) {
  final st = Paint()..color = p.stone;
  final ss = Paint()..color = p.stoneS;
  void column(double cx, double hgt, double wd) {
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(cx - wd / 2, base.dy - hgt, wd, hgt), Radius.circular(wd * 0.22));
    c.drawRRect(rr, ss);
    c
      ..save()
      ..clipRRect(rr)
      ..drawRect(Rect.fromLTWH(cx + wd * 0.02, base.dy - hgt, wd, hgt), st)
      ..restore();
  }

  final slab = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx, base.dy - u * 0.08), width: u * 3.6, height: u * 0.3), Radius.circular(u * 0.12));
  c.drawRRect(slab, ss);
  c.drawRRect(slab.shift(Offset(u * 0.1, -u * 0.04)), st);
  if (arch) {
    column(base.dx - u * 0.95, u * 1.9, u * 0.5);
    column(base.dx + u * 0.95, u * 1.9, u * 0.5);
    final lin = RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - u * 1.5, base.dy - u * 2.3, base.dx + u * 1.5, base.dy - u * 1.9), Radius.circular(u * 0.2));
    c.drawRRect(lin, ss);
    c
      ..save()
      ..clipRRect(lin)
      ..drawRect(Rect.fromLTRB(base.dx - u * 1.4, lin.top, base.dx + u * 2, lin.bottom - u * 0.14), st)
      ..restore();
    // moss on the lintel
    c.drawOval(Rect.fromCenter(center: Offset(base.dx - u * 0.5, lin.top + u * 0.02), width: u * 1.5, height: u * 0.3), Paint()..color = _pal.grass);
    c.drawOval(Rect.fromCenter(center: Offset(base.dx - u * 0.4, lin.top - u * 0.01), width: u * 0.9, height: u * 0.2), Paint()..color = _pal.grassL);
    column(base.dx + u * 2.1, u * 0.9, u * 0.5);
  } else {
    column(base.dx - u * 0.6, u * 1.3, u * 0.5);
    column(base.dx + u * 0.5, u * 0.7, u * 0.5);
  }
}

// ---------------------------------------------------------------- waterfall

class _Fall {
  const _Fall(this.x, this.y0, this.w, this.y1);
  final double x, y0, w, y1;
}

_Fall _heroFall(Size s) {
  final g = _heroG(s);
  final x = g.cx - g.hw * 0.9;
  return _Fall(x, g.topAt(x) + g.th * 0.55, s.width * 0.036, s.height * 0.8);
}

_Fall _midFall(Size s) {
  final g = _midG(s);
  final x = g.cx - g.hw * 0.86;
  return _Fall(x, g.topAt(x) + g.th * 0.55, s.width * 0.022, s.height * 0.8);
}

void _drawFall(Canvas c, _Fall f) {
  final h = f.y1 - f.y0;
  final p = Path()
    ..moveTo(f.x - f.w * 0.5, f.y0)
    ..cubicTo(f.x - f.w * 0.75, f.y0 + h * 0.04, f.x - f.w * 0.6, f.y0 + h * 0.15, f.x - f.w * 0.5, f.y0 + h * 0.3)
    ..lineTo(f.x - f.w * 0.62, f.y1)
    ..lineTo(f.x + f.w * 0.62, f.y1)
    ..lineTo(f.x + f.w * 0.5, f.y0 + h * 0.3)
    ..cubicTo(f.x + f.w * 0.6, f.y0 + h * 0.15, f.x + f.w * 0.75, f.y0 + h * 0.04, f.x + f.w * 0.5, f.y0)
    ..close();
  c.drawPath(p, Paint()..color = _water);
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(f.x - f.w * 0.1, f.y0, f.x + f.w, f.y1), Paint()..color = _waterLight)
    ..restore();
}

// ---------------------------------------------------------------- islands

void _island(Canvas c, _Geo g, _Pal p, {int roots = 0, double rootLen = 20, bool crystals = false}) {
  if (roots > 0) _roots(c, g, p, roots, rootLen);
  _drawBody(c, g, p);
  if (crystals) {
    const cc = Color(0xFF36D4C8), cl = Color(0xFFA6F5EA);
    final sz = g.depth * 0.6;
    final cy = g.tipY - g.depth * 0.06;
    _crystal(c, Offset(g.cx - g.w * 0.12, cy - g.depth * 0.3), g.w * 0.03, sz * 0.32, cc, cl, lean: -2);
    _crystal(c, Offset(g.cx + g.w * 0.02, cy - g.depth * 0.04), g.w * 0.038, sz * 0.38, cc, cl, lean: 1);
    _crystal(c, Offset(g.cx + g.w * 0.13, cy - g.depth * 0.34), g.w * 0.028, sz * 0.26, cc, cl, lean: 3);
  }
  _drawGrass(c, g, p);
}

void _farIslands(Canvas c, Size s) {
  const sky = Color(0xFFCFE9FB);
  final p = _pal.haze(sky, 0.55);
  final w = s.width, h = s.height;
  final list = [
    _Geo(w * 0.6, h * 0.108, w * 0.15, h * 0.05, 21, hump: 0.07),
    _Geo(w * 0.04, h * 0.5, w * 0.13, h * 0.045, 22, hump: 0.07),
    _Geo(w * 0.97, h * 0.56, w * 0.12, h * 0.04, 23, hump: 0.07),
    _Geo(w * 0.25, h * 0.46, w * 0.1, h * 0.035, 24, hump: 0.07),
  ];
  for (var i = 0; i < list.length; i++) {
    final g = list[i];
    _island(c, g, p, roots: 0);
    // tiny trees
    final r = rng(i + 70);
    for (var k = -1; k <= 1; k++) {
      final x = g.cx + k * g.hw * 0.4 + (r.nextDouble() - 0.5) * 4;
      flatTree(c, Offset(x, g.topAt(x) + g.th * 0.3), g.w * (0.22 + r.nextDouble() * 0.1), crown: p.crown, light: p.crownL, trunk: p.trunk, seed: 3 + k + i);
    }
  }
}

void _midIsland(Canvas c, Size s) {
  final g = _midG(s);
  _island(c, g, _pal.haze(const Color(0xFFD4EAFB), 0.18), roots: 4, rootLen: 14);
  _drawFall(c, _midFall(s));
  final p = _pal.haze(const Color(0xFFD4EAFB), 0.18);
  _ruins(c, Offset(g.cx - g.hw * 0.25, g.topAt(g.cx - g.hw * 0.25) + g.th * 0.25), g.w * 0.07, p, arch: false);
  _flora(c, g, p, from: -0.75, to: 0.85, size: 0.17, seed: 14, gaps: const [(-0.45, 0.0)], step: 0.2);
  _drawFallOverlay(c, _midFall(s));
}

// the lip of the fall sits in front of the grass edge
void _drawFallOverlay(Canvas c, _Fall f) {
  c.drawOval(Rect.fromCenter(center: Offset(f.x, f.y0 + 1), width: f.w * 1.05, height: f.w * 0.28), Paint()..color = _waterLight);
}

void _heroIsland(Canvas c, Size s) {
  final g = _heroG(s);
  _island(c, g, _pal, roots: 6, rootLen: 26, crystals: true);
  _pebbles(c, g, _pal, const [(-0.22, 0.22, 0.04), (0.2, 0.34, 0.03), (-0.34, 0.5, 0.022)]);
  _drawFall(c, _heroFall(s));
  // the forest, with the stone arch on the right
  final ax = g.cx + g.hw * 0.3;
  _flora(c, g, _pal, from: -0.78, to: 0.86, size: 0.15, seed: 6, gaps: const [(0.1, 0.55)]);
  _ruins(c, Offset(ax, g.topAt(ax) + g.th * 0.25), g.w * 0.07, _pal);
  _drawFallOverlay(c, _heroFall(s));
}

// ---------------------------------------------------------------- home island

Offset _cottage(Size s) {
  final g = _homeG(s);
  final x = g.cx - g.hw * 0.12;
  return Offset(x, g.topAt(x) + g.th * 0.25);
}

void _homeIsland(Canvas c, Size s) {
  final g = _homeG(s);
  _island(c, g, _pal, roots: 4, rootLen: 14);
  _flora(c, g, _pal, from: -0.85, to: 0.85, size: 0.12, seed: 33, gaps: const [(-0.4, 0.25)], step: 0.2);
  final b = _cottage(s);
  final u = g.w * 0.075;
  // walls
  final wall = RRect.fromRectAndRadius(Rect.fromLTWH(b.dx - u * 1.1, b.dy - u * 1.5, u * 2.2, u * 1.5), Radius.circular(u * 0.12));
  c.drawRRect(wall, Paint()..color = const Color(0xFFD9B58F));
  c
    ..save()
    ..clipRRect(wall)
    ..drawRect(Rect.fromLTRB(b.dx - u * 0.9, wall.top, b.dx + u * 2, wall.bottom), Paint()..color = const Color(0xFFFFEBC9))
    ..restore();
  // chimney
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.dx + u * 0.45, b.dy - u * 3.0, u * 0.42, u * 1.2), Radius.circular(u * 0.08)), Paint()..color = _pal.stoneS);
  // roof
  final roof = smoothPath([
    Offset(b.dx - u * 1.5, b.dy - u * 1.35),
    Offset(b.dx - u * 0.2, b.dy - u * 2.55),
    Offset(b.dx + u * 0.2, b.dy - u * 2.55),
    Offset(b.dx + u * 1.5, b.dy - u * 1.35),
    Offset(b.dx + u * 1.3, b.dy - u * 1.15),
    Offset(b.dx - u * 1.3, b.dy - u * 1.15),
  ], closed: true);
  c.drawPath(roof, Paint()..color = const Color(0xFFC94E3F));
  c
    ..save()
    ..clipPath(roof)
    ..drawRect(Rect.fromLTRB(b.dx - u * 2, b.dy - u * 3, b.dx + u * 0.05, b.dy), Paint()..color = const Color(0xFFC94E3F))
    ..drawRect(Rect.fromLTRB(b.dx + u * 0.05, b.dy - u * 3, b.dx + u * 2, b.dy), Paint()..color = const Color(0xFFEE7A58))
    ..restore();
  // door + lit window
  c.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(b.dx - u * 0.75, b.dy - u * 0.85, u * 0.5, u * 0.85), topLeft: Radius.circular(u * 0.25), topRight: Radius.circular(u * 0.25)), Paint()..color = const Color(0xFF7A4B33));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.dx + u * 0.2, b.dy - u * 1.0, u * 0.6, u * 0.55), Radius.circular(u * 0.1)), Paint()..color = const Color(0xFFFFD66B));
  c.drawLine(Offset(b.dx + u * 0.5, b.dy - u * 1.0), Offset(b.dx + u * 0.5, b.dy - u * 0.45), Paint()
    ..color = const Color(0xFFE8A93A)
    ..strokeWidth = 1.2);
  // garden tree right of the house
  flatTree(c, Offset(b.dx + u * 2.6, g.topAt(b.dx + u * 2.6) + g.th * 0.3), g.w * 0.2, crown: const Color(0xFF3FB65E), light: const Color(0xFF9BE86B), trunk: _pal.trunk, seed: 9);
}

// ---------------------------------------------------------------- live details

void _islandLife(Canvas c, Size s, Clock k) {
  final k0 = s.width / 390;
  // waterfalls: streaks rushing down + spray
  void fall(_Fall f, Offset bob, int seed, int n) {
    final r = rng(seed);
    final len = f.y1 - f.y0;
    for (var i = 0; i < n; i++) {
      final lx = (r.nextDouble() - 0.5) * 0.8;
      final ll = len * (0.12 + r.nextDouble() * 0.12);
      final t = k.saw(6 + i % 3, r.nextDouble());
      final y = f.y0 + (t * (len + ll)) - ll;
      final y0 = math.max(y, f.y0 + len * 0.02), y1 = math.min(y + ll, f.y1);
      if (y1 <= y0) continue;
      final grow = 0.5 + 0.5 * ((y0 - f.y0) / len);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(f.x + bob.dx + lx * f.w - 1.1 * k0, y0 + bob.dy, f.x + bob.dx + lx * f.w + 1.1 * k0 * (1 + grow), y1 + bob.dy), const Radius.circular(1.5)),
        Paint()..color = _waterWhite.withValues(alpha: 0.9),
      );
    }
    // spray puffs where the water meets the clouds
    for (var i = 0; i < 5; i++) {
      final ph = i / 5;
      final t = k.saw(3, ph);
      final rad = (f.w * 0.5 + 6 * k0) * (0.7 + 0.6 * t);
      final dx = (i - 2) * f.w * 0.45;
      c.drawCircle(Offset(f.x + bob.dx + dx, f.y1 - f.w * 0.9 - t * 8 * k0 + bob.dy), rad, Paint()..color = Colors.white.withValues(alpha: 0.85 * (1 - t * 0.5)));
    }
  }

  final hb = _bobHero.at(s, k), mb = _bobMid.at(s, k);
  fall(_heroFall(s), hb, 3, 7);
  fall(_midFall(s), mb, 5, 4);
  // pennant on the arch
  final g = _heroG(s);
  final ax = g.cx + g.hw * 0.3;
  final u = g.w * 0.07;
  final top = Offset(ax + hb.dx, g.topAt(ax) + g.th * 0.25 - u * 2.3 + hb.dy);
  c.drawLine(top, top + Offset(0, -u * 1.3), Paint()
    ..color = _pal.stoneS
    ..strokeWidth = 1.6 * k0
    ..strokeCap = StrokeCap.round);
  final fl = k.sine(12) * 1.8 * k0, fl2 = k.sine(12, 0.3) * 1.8 * k0;
  final pole = top + Offset(0, -u * 1.3);
  c.drawPath(
    Path()
      ..moveTo(pole.dx, pole.dy)
      ..quadraticBezierTo(pole.dx + u * 0.5, pole.dy + u * 0.05 + fl, pole.dx + u * 1.0, pole.dy + u * 0.25 + fl2)
      ..quadraticBezierTo(pole.dx + u * 0.5, pole.dy + u * 0.4 + fl, pole.dx, pole.dy + u * 0.5)
      ..close(),
    Paint()..color = const Color(0xFFFF8A5B),
  );
  // crystal twinkles under the hero
  final cy = g.tipY - g.depth * 0.1;
  for (var i = 0; i < 3; i++) {
    final a = math.pow(k.pulse(6 + i, i * 0.31), 3).toDouble();
    sparkle(c, Offset(g.cx + (i - 1) * g.w * 0.1 + hb.dx, cy - g.depth * (0.1 + 0.15 * (i % 2)) + hb.dy), (3 + 2 * a) * k0, const Color(0xFFD8FFF8), a);
  }
}

void _homeLife(Canvas c, Size s, Clock k) {
  final k0 = s.width / 390;
  final hb = _bobHome.at(s, k);
  final g = _homeG(s);
  final b = _cottage(s);
  final u = g.w * 0.075;
  final o = Offset(b.dx + u * 0.66 + hb.dx, b.dy - u * 3.0 + hb.dy);
  // chimney smoke: flat puffs rising and thinning
  for (var i = 0; i < 4; i++) {
    final t = k.saw(6, i / 4);
    final p = o + Offset(math.sin(tau * (t * 1.2 + i * 0.2)) * 4 * k0 + t * 10 * k0, -t * 46 * k0);
    c.drawCircle(p, (2.5 + 5 * t) * k0, Paint()..color = Colors.white.withValues(alpha: 0.9 * (1 - t)));
  }
  // window glow pulse (flat halo ring)
  final wp = Offset(b.dx + u * 0.5 + hb.dx, b.dy - u * 0.72 + hb.dy);
  c.drawCircle(wp, u * (0.7 + 0.12 * k.pulse(5)), Paint()..color = const Color(0xFFFFE08A).withValues(alpha: 0.28));
}

void _air(Canvas c, Size s, Clock k) {
  paintParticles(
      c,
      s,
      k,
      const ParticleSpec(
          count: 10,
          seed: 4,
          colors: [Color(0xFFBFF08A), Color(0xFF8FE25F), Color(0xFFFFFFFF)],
          minSize: 2.2,
          maxSize: 3.4,
          flow: Offset(-0.25, 0.15),
          cycles: 2,
          spread: 1,
          wander: 10,
          shape: ParticleShape.leaf,
          region: Rect.fromLTRB(0.05, 0.08, 1.0, 0.7),
          fade: 0.12));
  paintParticles(
      c,
      s,
      k,
      const ParticleSpec(
          count: 26,
          seed: 9,
          colors: [Color(0xFFFFF6CF), Color(0xFFFFFFFF)],
          minSize: 1.0,
          maxSize: 2.1,
          flow: Offset(0.1, -0.2),
          cycles: 2,
          spread: 2,
          wander: 12,
          twinkle: 0.5,
          shape: ParticleShape.dot,
          region: Rect.fromLTRB(0.0, 0.05, 1.0, 0.95),
          opacity: 0.85));
  // twinkling sky sparkles
  const spots = [(0.66, 0.2), (0.25, 0.07), (0.92, 0.16), (0.52, 0.31), (0.12, 0.58), (0.86, 0.72), (0.4, 0.75), (0.62, 0.9)];
  for (var i = 0; i < spots.length; i++) {
    final a = math.pow(k.pulse(8 + i % 3, i * 0.17), 4).toDouble();
    if (a < 0.05) continue;
    sparkle(c, Offset(spots[i].$1 * s.width, spots[i].$2 * s.height), (3 + 3 * a) * s.width / 390, const Color(0xFFFFFFFF), a);
  }
}

void _birds(Canvas c, Size s, Clock k) {
  paintBirds(c, s, k, count: 3, seed: 3, y: 0.045, band: 0.05, color: const Color(0xFF4A5496), size: 6, cycles: 1, dir: 1);
  paintBirds(c, s, k, count: 3, seed: 8, y: 0.655, band: 0.05, color: const Color(0xFF5A5FA0), size: 8, cycles: 1, dir: -1);
}
