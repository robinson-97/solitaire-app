import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit.dart';

// COSMIC GALAXY: deep indigo sky, flat stacked nebula bands, a slowly turning
// spiral galaxy (hero), a banded ringed gas giant, a teal ocean planet, a moon.
// Light comes from the upper left on every planet.

const _indigo = Color(0xFF0B0724);
const _night = Color(0xFF160B3D);
const _violet = Color(0xFF2B0F5C);
const _purple = Color(0xFF5B2BA8);
const _magenta = Color(0xFFC0268E);
const _pink = Color(0xFFFF4FB8);
const _cyan = Color(0xFF5FD2FF);
const _gold = Color(0xFFFFD27A);

// ---------------------------------------------------------------- helpers

Path _ribbon(List<Offset> pts, List<double> w, [double scale = 1.0]) {
  final n = pts.length;
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i < n; i++) {
    final a = pts[math.max(i - 1, 0)], b = pts[math.min(i + 1, n - 1)];
    final d = b - a;
    final len = d.distance == 0 ? 1.0 : d.distance;
    final nx = -d.dy / len, ny = d.dx / len;
    final hw = w[i] * scale / 2;
    left.add(Offset(pts[i].dx + nx * hw, pts[i].dy + ny * hw));
    right.add(Offset(pts[i].dx - nx * hw, pts[i].dy - ny * hw));
  }
  return smoothPath([...left, ...right.reversed], closed: true);
}

/// A nebula band: three nested flat tones with hard edges.
void _nebula(Canvas c, List<Offset> pts, List<double> w, List<Color> tones, List<double> alphas) {
  final scales = [1.0, 0.62, 0.3];
  for (var i = 0; i < 3 && i < tones.length; i++) {
    c.drawPath(_ribbon(pts, w, scales[i]), Paint()..color = alpha(tones[i], alphas[i]));
  }
}

Offset _p(Size s, double fx, double fy) => Offset(fx * s.width, fy * s.height);

List<Offset> _pts(Size s, List<List<double>> f) => [for (final e in f) _p(s, e[0], e[1])];

Path _crescent(Offset o, double r, Offset shift) {
  // planet disc minus a disc moved by [shift]: a flat crescent on the side away from the shift
  return Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: o, radius: r))
    ..addOval(Rect.fromCircle(center: o + shift, radius: r));
}

void _fourStar(Canvas c, Offset o, double r, Paint p) {
  final path = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx + r * 0.1, o.dy - r * 0.1, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx + r * 0.1, o.dy + r * 0.1, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx - r * 0.1, o.dy + r * 0.1, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx - r * 0.1, o.dy - r * 0.1, o.dx, o.dy - r)
    ..close();
  c.drawPath(path, p);
}

// ---------------------------------------------------------------- still layers

void _paintSky(Canvas c, Size s) {
  fillSky(c, s, const [_indigo, _night, Color(0xFF241056), Color(0xFF3A1473), Color(0xFF5A1C7E)], const [0.0, 0.3, 0.58, 0.82, 1.0]);
}

void _paintNebulaTop(Canvas c, Size s) {
  // big violet sweep behind the galaxy
  _nebula(c, _pts(s, [[-0.2, 0.30], [0.1, 0.20], [0.45, 0.27], [0.85, 0.16], [1.2, 0.24]]), const [10, 120, 150, 130, 10], [_violet, _purple, _magenta], const [0.55, 0.32, 0.22]);
  // pink wisp top right
  _nebula(c, _pts(s, [[1.2, 0.02], [0.9, 0.06], [0.62, 0.04], [0.35, 0.09], [0.1, 0.05]]), const [10, 70, 80, 60, 10], [_purple, _magenta, _pink], const [0.4, 0.3, 0.26]);
  // dark lanes cutting through
  _nebula(c, _pts(s, [[-0.1, 0.25], [0.2, 0.2], [0.5, 0.265], [0.9, 0.2]]), const [6, 22, 26, 8], [_indigo, _indigo, _indigo], const [0.35, 0.0, 0.0]);
  // lower lobe of the nebula toward the board edge (kept dim)
  _nebula(c, _pts(s, [[1.2, 0.36], [0.9, 0.34], [0.7, 0.40], [0.55, 0.37]]), const [10, 60, 70, 10], [_violet, _purple, _magenta], const [0.5, 0.25, 0.15]);
}

void _paintNebulaLow(Canvas c, Size s) {
  // calm middle band
  _nebula(c, _pts(s, [[-0.2, 0.54], [0.2, 0.50], [0.6, 0.58], [1.2, 0.52]]), const [10, 100, 120, 10], [_violet, _purple, _purple], const [0.5, 0.26, 0.0]);
  // big magenta swirl in the lower third
  _nebula(c, _pts(s, [[1.25, 0.64], [0.9, 0.67], [0.55, 0.76], [0.2, 0.70], [-0.2, 0.78]]), const [10, 130, 150, 120, 10], [_violet, _magenta, _pink], const [0.5, 0.34, 0.2]);
  // dark lane through the swirl
  _nebula(c, _pts(s, [[1.1, 0.70], [0.75, 0.74], [0.4, 0.80], [0.0, 0.76]]), const [6, 24, 30, 8], [_indigo, _indigo, _indigo], const [0.4, 0.0, 0.0]);
}

void _paintDeepStars(Canvas c, Size s) {
  final r = rng(404);
  final k0 = s.width / 390;
  final cols = [const Color(0xFFFFFFFF), const Color(0xFFCFE6FF), const Color(0xFFFFD0EE), _gold];
  final paint = Paint();
  for (var i = 0; i < 300; i++) {
    final y = math.pow(r.nextDouble(), 1.25) * s.height * 1.06 - 0.03 * s.height;
    final x = (r.nextDouble() * 1.12 - 0.06) * s.width;
    final size = (0.45 + math.pow(r.nextDouble(), 3) * 1.1) * k0;
    final col = cols[r.nextDouble() < 0.7 ? 0 : 1 + r.nextInt(3)];
    paint.color = alpha(col, 0.35 + r.nextDouble() * 0.5);
    c.drawCircle(Offset(x, y), size, paint);
  }
  // distant tiny spiral galaxies
  _tinyGalaxy(c, _p(s, 0.88, 0.285), 20 * k0, -0.5, 3);
  _tinyGalaxy(c, _p(s, 0.07, 0.62), 15 * k0, 0.4, 5);
  _tinyGalaxy(c, _p(s, 0.74, 0.035), 11 * k0, 0.1, 8);
}

void _tinyGalaxy(Canvas c, Offset o, double r, double rot, int seed) {
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(rot)
    ..scale(1, 0.4);
  c.drawCircle(Offset.zero, r, Paint()..color = alpha(_purple, 0.45));
  c.drawCircle(Offset.zero, r * 0.62, Paint()..color = alpha(_pink, 0.4));
  c.drawCircle(Offset.zero, r * 0.3, Paint()..color = alpha(_gold, 0.8));
  c.drawCircle(Offset.zero, r * 0.14, Paint()..color = const Color(0xFFFFFFFF));
  c.restore();
}

// ---------------------------------------------------------------- planets

void _stripes(Canvas c, Offset o, double r, double tilt, List<Color> cols, List<double> edges, int seed) {
  // flat wavy bands clipped to the disc; edges are fractions of the diameter from top
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(tilt);
  final rr = rng(seed);
  for (var i = 0; i < cols.length; i++) {
    final y0 = -r + edges[i] * 2 * r;
    final y1 = i + 1 < edges.length ? -r + edges[i + 1] * 2 * r : r + 4;
    final top = <Offset>[], bot = <Offset>[];
    final ph = rr.nextDouble() * 6;
    final ph2 = rr.nextDouble() * 6;
    for (var j = 0; j <= 8; j++) {
      final x = -r * 1.1 + r * 2.2 * j / 8;
      top.add(Offset(x, y0 + math.sin(j * 1.2 + ph) * r * 0.035));
      bot.add(Offset(x, y1 + math.sin(j * 1.2 + ph2) * r * 0.035));
    }
    c.drawPath(smoothPath([...top, ...bot.reversed], closed: true), Paint()..color = cols[i]);
  }
  c.restore();
}

void _paintGiant(Canvas c, Size s) {
  final k0 = s.width / 390;
  final o = _p(s, 0.15, 0.915);
  final r = 104 * k0;
  const tilt = -0.30;
  final ringPaintsBack = [
    (1.78, 0.0, 15.0, const Color(0xFF8C3FC0)),
    (1.52, 0.0, 9.0, const Color(0xFFE88FB8)),
    (1.30, 0.0, 6.0, const Color(0xFFFFD27A)),
  ];
  void ring(bool front) {
    c
      ..save()
      ..translate(o.dx, o.dy)
      ..rotate(tilt);
    for (final rp in ringPaintsBack) {
      final rx = rp.$1 * r, ry = rp.$1 * r * 0.27;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rp.$3 * k0
        ..color = rp.$4;
      c.drawArc(Rect.fromLTRB(-rx, -ry, rx, ry), front ? 0 : math.pi, math.pi, false, p);
    }
    c.restore();
  }

  ring(false);
  final disc = Rect.fromCircle(center: o, radius: r);
  c.drawOval(disc, Paint()..color = const Color(0xFF9A52D8));
  c
    ..save()
    ..clipPath(Path()..addOval(disc));
  _stripes(c, o, r, tilt, const [
    Color(0xFF9A52D8),
    Color(0xFFC65BC7),
    Color(0xFFE877B5),
    Color(0xFFF6A4A2),
    Color(0xFFE877B5),
    Color(0xFFB252CE),
    Color(0xFF8A44C8),
    Color(0xFFC65BC7),
  ], const [0.0, 0.12, 0.26, 0.36, 0.47, 0.6, 0.76, 0.9], 21);
  // shadow cast by the ring onto the planet
  c
    ..save()
    ..translate(o.dx + 10 * k0, o.dy + 20 * k0)
    ..rotate(tilt);
  final rsx = 1.52 * r, rsy = 1.52 * r * 0.27;
  c.drawArc(Rect.fromLTRB(-rsx, -rsy, rsx, rsy), 0, math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 30 * k0..color = alpha(_indigo, 0.4));
  c.restore();
  // hard cel shade on the side away from the light
  c.drawPath(_crescent(o, r, Offset(-r * 0.26, -r * 0.26)), Paint()..color = alpha(_violet, 0.6));
  c.drawPath(_crescent(o, r, Offset(r * 0.07, r * 0.07)), Paint()..color = alpha(const Color(0xFFFFE6F6), 0.32));
  c.restore();
  ring(true);
}

void _paintOcean(Canvas c, Size s) {
  final k0 = s.width / 390;
  final o = _p(s, 0.83, 0.815);
  final r = 47 * k0;
  // flat atmosphere rings
  c.drawCircle(o, r + 13 * k0, Paint()..color = alpha(_cyan, 0.12));
  c.drawCircle(o, r + 6 * k0, Paint()..color = alpha(_cyan, 0.22));
  final disc = Rect.fromCircle(center: o, radius: r);
  c.drawOval(disc, Paint()..color = const Color(0xFF2B9CCB));
  c
    ..save()
    ..clipPath(Path()..addOval(disc));
  // continents
  final land = Paint()..color = const Color(0xFF39D6A8);
  c.drawPath(blobPath(o + Offset(-r * 0.3, -r * 0.35), r * 0.5, r * 0.28, seed: 3, wobble: 0.2), land);
  c.drawPath(blobPath(o + Offset(r * 0.42, r * 0.12), r * 0.34, r * 0.42, seed: 8, wobble: 0.2), land);
  c.drawPath(blobPath(o + Offset(-r * 0.35, r * 0.5), r * 0.4, r * 0.2, seed: 11, wobble: 0.2), land);
  // cloud streaks
  final cl = Paint()..color = alpha(const Color(0xFFFFFFFF), 0.7);
  for (final e in [
    [-0.1, -0.05, 0.9, 0.1],
    [0.1, 0.38, 0.7, 0.08],
    [-0.2, -0.62, 0.6, 0.07],
  ]) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(e[0] * r, e[1] * r), width: e[2] * r, height: e[3] * r), Radius.circular(r * 0.1)), cl);
  }
  c.drawPath(_crescent(o, r, Offset(-r * 0.28, -r * 0.28)), Paint()..color = alpha(const Color(0xFF1B1F7A), 0.55));
  c.drawPath(_crescent(o, r, Offset(r * 0.07, r * 0.07)), Paint()..color = alpha(const Color(0xFFE6FBFF), 0.35));
  c.restore();
  // small cratered moon
  final mo = _p(s, 0.58, 0.945);
  final mr = 15 * k0;
  final md = Rect.fromCircle(center: mo, radius: mr);
  c.drawOval(md, Paint()..color = const Color(0xFFE9DEFF));
  c
    ..save()
    ..clipPath(Path()..addOval(md));
  c.drawCircle(mo + Offset(mr * 0.3, -mr * 0.2), mr * 0.26, Paint()..color = const Color(0xFFC9B8EE));
  c.drawCircle(mo + Offset(-mr * 0.35, mr * 0.3), mr * 0.18, Paint()..color = const Color(0xFFC9B8EE));
  c.drawCircle(mo + Offset(mr * 0.1, mr * 0.55), mr * 0.12, Paint()..color = const Color(0xFFC9B8EE));
  c.drawPath(_crescent(mo, mr, Offset(-mr * 0.3, -mr * 0.3)), Paint()..color = alpha(_purple, 0.5));
  c.restore();
}

void _paintGoldPlanet(Canvas c, Size s) {
  final k0 = s.width / 390;
  final o = _p(s, 0.91, 0.085);
  final r = 19 * k0;
  final disc = Rect.fromCircle(center: o, radius: r);
  c.drawOval(disc, Paint()..color = _gold);
  c
    ..save()
    ..clipPath(Path()..addOval(disc));
  _stripes(c, o, r, 0.4, const [Color(0xFFFFD27A), Color(0xFFFFB07A), Color(0xFFFFD27A), Color(0xFFFF9F8A)], const [0.0, 0.3, 0.5, 0.72], 5);
  c.drawPath(_crescent(o, r, Offset(-r * 0.28, -r * 0.28)), Paint()..color = alpha(_magenta, 0.55));
  c.restore();
}

// ---------------------------------------------------------------- scrolling clouds

void _paintCloudsLow(Canvas c, Size s) {
  final w = s.width;
  final items = [
    [0.10, 0.80, 190.0, 1],
    [0.52, 0.90, 240.0, 2],
    [0.86, 0.73, 150.0, 3],
    [0.30, 0.64, 130.0, 4],
  ];
  for (final e in items) {
    flatCloud(c, Offset(e[0] * w, e[1] * s.height), (e[2] as double) * w / 390, color: const Color(0xFF8E4FCB), shade: const Color(0xFF5B2BA8), seed: e[3] as int, opacity: 0.6);
  }
}

void _paintCloudsTop(Canvas c, Size s) {
  final w = s.width;
  final items = [
    [0.25, 0.115, 170.0, 5],
    [0.78, 0.25, 140.0, 6],
  ];
  for (final e in items) {
    flatCloud(c, Offset(e[0] * w, e[1] * s.height), (e[2] as double) * w / 390, color: const Color(0xFFB45BC8), shade: const Color(0xFF7A3BB0), seed: e[3] as int, opacity: 0.32);
  }
}

// ---------------------------------------------------------------- live: galaxy

class _GalaxyData {
  _GalaxyData(this.width);
  final double width;
  final dots = <List<Offset>>[for (var i = 0; i < 9; i++) <Offset>[]]; // size(3) x colour(3)
  late final List<Float32List> out = [for (final l in dots) Float32List(l.length * 2)];
  final arms = <Path>[];
  final lanes = <Path>[];
}

_GalaxyData? _gal;

Offset _spiral(double t, double a0, double r) {
  const turns = 1.75 * math.pi;
  final th = t * turns;
  final rad = r * (0.07 + 0.93 * math.pow(t, 1.15));
  return Offset(math.cos(th + a0) * rad, math.sin(th + a0) * rad);
}

_GalaxyData _galaxyData(double width) {
  final g = _gal;
  if (g != null && g.width == width) return g;
  final d = _GalaxyData(width);
  final R = width * 0.40;
  final rr = rng(77);
  for (var a = 0; a < 3; a++) {
    final a0 = a * tau / 3;
    final center = <Offset>[for (var i = 0; i <= 28; i++) _spiral(0.04 + 0.96 * i / 28, a0, R)];
    d.arms.add(smoothPath(center));
    d.lanes.add(smoothPath([for (var i = 0; i <= 28; i++) _spiral(0.2 + 0.7 * i / 28, a0 + 0.95, R)]));
    for (var i = 0; i < 120; i++) {
      final t = math.pow(rr.nextDouble(), 0.8).toDouble() * 0.96 + 0.03;
      final p = _spiral(t, a0, R);
      final rad = p.distance;
      final ang = math.atan2(p.dy, p.dx);
      final sc = (0.02 + 0.07 * t) * R * (rr.nextDouble() + rr.nextDouble() - 1) * 2.2;
      final q = Offset(p.dx + math.cos(ang + math.pi / 2) * sc + math.cos(ang) * sc * 0.3, p.dy + math.sin(ang + math.pi / 2) * sc + math.sin(ang) * sc * 0.3);
      final sz = rr.nextDouble() < 0.12 ? 2 : (rr.nextDouble() < 0.4 ? 1 : 0);
      final col = rad < R * 0.3 ? 0 : (rad < R * 0.65 ? 1 : 2);
      d.dots[sz * 3 + col].add(q);
    }
  }
  // a few dots scattered in the halo
  for (var i = 0; i < 70; i++) {
    final ang = rr.nextDouble() * tau, rad = R * (0.2 + rr.nextDouble() * 0.9);
    d.dots[(rr.nextDouble() < 0.1 ? 3 : 0) + 1 + rr.nextInt(2)].add(Offset(math.cos(ang) * rad, math.sin(ang) * rad));
  }
  _gal = d;
  return d;
}

void _paintGalaxy(Canvas c, Size s, Clock k) {
  final k0 = s.width / 390;
  final R = s.width * 0.40;
  final g = _galaxyData(s.width);
  final o = _p(s, 0.43, 0.19);
  final spin = k.saw(2) * tau;
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(-0.38)
    ..scale(1, 0.58);
  final cs = math.cos(spin), sn = math.sin(spin);
  // flat disc backdrop
  c.drawCircle(Offset.zero, R * 1.12, Paint()..color = alpha(_purple, 0.16));
  c.drawCircle(Offset.zero, R * 0.78, Paint()..color = alpha(_magenta, 0.12));
  c.rotate(spin);
  final wide = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = R * 0.2
    ..color = alpha(_magenta, 0.2);
  final mid = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = R * 0.095
    ..color = alpha(_pink, 0.26);
  final lane = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = R * 0.07
    ..color = alpha(_indigo, 0.22);
  for (final p in g.arms) {
    c.drawPath(p, wide);
  }
  for (final p in g.lanes) {
    c.drawPath(p, lane);
  }
  for (final p in g.arms) {
    c.drawPath(p, mid);
  }
  const cols = [Color(0xFFFFF1C8), Color(0xFFFFFFFF), Color(0xFFBFE9FF)];
  final dp = Paint()..strokeCap = StrokeCap.round;
  const sizes = [1.8, 2.8, 4.0];
  c.restore();
  // dots are placed by hand so they stay round while the disc is tilted
  final tc = math.cos(-0.38), ts = math.sin(-0.38);
  for (var i = 0; i < 9; i++) {
    final src = g.dots[i];
    if (src.isEmpty) continue;
    final dst = g.out[i];
    for (var j = 0; j < src.length; j++) {
      final x = src[j].dx * cs - src[j].dy * sn;
      final y = (src[j].dx * sn + src[j].dy * cs) * 0.58;
      dst[2 * j] = o.dx + x * tc - y * ts;
      dst[2 * j + 1] = o.dy + x * ts + y * tc;
    }
    dp
      ..strokeWidth = sizes[i ~/ 3] * k0
      ..color = alpha(cols[i % 3], 0.92);
    c.drawRawPoints(ui.PointMode.points, dst, dp);
  }
  // pulsing core
  final pu = k.pulse(6);
  final cr = 1 + 0.12 * (pu - 0.5) * 2;
  c.drawCircle(o, R * 0.30 * cr, Paint()..color = alpha(_pink, 0.20 + 0.06 * pu));
  c.drawCircle(o, R * 0.20 * cr, Paint()..color = alpha(_pink, 0.32));
  c.drawCircle(o, R * 0.125 * cr, Paint()..color = alpha(_gold, 0.9));
  c.drawCircle(o, R * 0.07 * cr, Paint()..color = const Color(0xFFFFFAE6));
  // a flat four-point flare on the core
  _fourStar(c, o, R * (0.22 + 0.06 * pu), Paint()..color = alpha(const Color(0xFFFFFFFF), 0.55 + 0.3 * pu));
}

// ---------------------------------------------------------------- live: stars + sparkles

void _paintTwinkle(Canvas c, Size s, Clock k) {
  final r = rng(909);
  final k0 = s.width / 390;
  final paint = Paint();
  final cols = [const Color(0xFFFFFFFF), const Color(0xFFCFE6FF), const Color(0xFFFFD0EE), _gold];
  for (var i = 0; i < 70; i++) {
    final x = r.nextDouble() * s.width;
    final y = math.pow(r.nextDouble(), 1.2) * s.height;
    final size = (0.7 + r.nextDouble() * 0.9) * k0;
    final ph = r.nextDouble();
    final col = cols[r.nextDouble() < 0.65 ? 0 : 1 + r.nextInt(3)];
    final tw = 0.2 + 0.8 * k.pulse(12 + i % 6, ph);
    paint.color = alpha(col, 0.95 * tw);
    c.drawCircle(Offset(x, y), size, paint);
  }
  // big sparkles
  final sp = [
    [0.08, 0.05], [0.93, 0.19], [0.66, 0.31], [0.05, 0.27], [0.74, 0.115], [0.28, 0.955], [0.95, 0.60], [0.47, 0.50]
  ];
  for (var i = 0; i < sp.length; i++) {
    final o = _p(s, sp[i][0], sp[i][1]);
    final tw = k.pulse(8 + i % 4, i * 0.21);
    final rad = (4 + 3 * (i % 3)) * k0 * (0.7 + 0.5 * tw);
    final col = i % 3 == 0 ? _cyan : (i % 3 == 1 ? const Color(0xFFFFFFFF) : const Color(0xFFFFF0C8));
    c.drawCircle(o, rad * 1.1, Paint()..color = alpha(col, 0.10 + 0.08 * tw));
    _fourStar(c, o, rad * 1.7, Paint()..color = alpha(col, 0.7 + 0.3 * tw));
    c.drawCircle(o, rad * 0.22, Paint()..color = const Color(0xFFFFFFFF));
  }
}

// ---------------------------------------------------------------- live: shooting stars + dust

const _shoot = [
  [0.80, 0.10, 2.55, 0.16], // x, y, angle (down-left), delay in cycle
  [0.28, 0.07, 0.65, 0.12],
  [0.95, 0.40, 2.7, 0.2],
  [0.18, 0.40, 0.5, 0.1],
];

void _paintShooting(Canvas c, Size s, Clock k) {
  final k0 = s.width / 390;
  final idx = (k.u * 4).floor().clamp(0, 3);
  final t = k.saw(4);
  final e = _shoot[idx];
  final st = e[3];
  const dur = 0.2;
  if (t >= st && t <= st + dur) {
    final q = (t - st) / dur;
    final env = math.sin(q * math.pi);
    final dir = Offset(math.cos(e[2]), math.sin(e[2]));
    final nrm = Offset(-dir.dy, dir.dx);
    final head = _p(s, e[0], e[1]) + dir * (q * 190 * k0);
    final len = 95 * k0 * (0.4 + 0.6 * env);
    final tail = head - dir * len;
    for (final w in [(3.4, _cyan, 0.28), (1.7, const Color(0xFFFFFFFF), 0.9)]) {
      final hw = w.$1 * k0 / 2;
      final path = Path()
        ..moveTo(tail.dx, tail.dy)
        ..lineTo(head.dx + nrm.dx * hw, head.dy + nrm.dy * hw)
        ..lineTo(head.dx - nrm.dx * hw, head.dy - nrm.dy * hw)
        ..close();
      c.drawPath(path, Paint()..color = alpha(w.$2, w.$3 * env));
    }
    c.drawCircle(head, 1.9 * k0, Paint()..color = alpha(const Color(0xFFFFFFFF), env));
  }
}

void _paintDust(Canvas c, Size s, Clock k) {
  paintParticles(
    c,
    s,
    k,
    const ParticleSpec(
      count: 24,
      seed: 31,
      colors: [_pink, _cyan, _gold, Color(0xFFFFFFFF)],
      minSize: 1.2,
      maxSize: 2.6,
      flow: Offset(0.04, -0.22),
      cycles: 1,
      spread: 1,
      wander: 9,
      twinkle: 0.5,
      shape: ParticleShape.glow,
      haloScale: 2.6,
      opacity: 0.8,
    ),
  );
  paintParticles(
    c,
    s,
    k,
    const ParticleSpec(
      count: 7,
      seed: 61,
      colors: [Color(0xFFFFFFFF), _gold, _cyan],
      minSize: 1.6,
      maxSize: 2.6,
      flow: Offset(-0.03, -0.12),
      cycles: 1,
      spread: 1,
      wander: 6,
      twinkle: 0.6,
      shape: ParticleShape.spark,
      opacity: 0.85,
    ),
  );
  _paintShooting(c, s, k);
}

// ---------------------------------------------------------------- scene

SceneSpec cosmicScene() => SceneSpec(
      focusY: -0.55,
      topShade: 0.12,
      bottomShade: 0.2,
      layers: [
        Layer.still(_paintSky),
        Layer.still(_paintNebulaTop, driftX: 0.018, driftY: 0.004, driftCycles: 2),
        Layer.still(_paintNebulaLow, driftX: -0.022, driftY: -0.004, driftCycles: 2, driftPhase: 0.3),
        Layer.still(_paintDeepStars, driftX: 0.008, driftCycles: 3),
        Layer.scroll(_paintCloudsTop, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.34),
        Layer.live(_paintGalaxy),
        Layer.live(_paintTwinkle),
        Layer.scroll(_paintCloudsLow, scrollCycles: 1, scrollLeft: false, bandTop: 0.56, bandBottom: 0.97),
        Layer.still(_paintGiant, driftX: 0.004, driftY: 0.005, driftCycles: 5),
        Layer.still(_paintOcean, driftX: -0.004, driftY: 0.006, driftCycles: 6, driftPhase: 0.4),
        Layer.still(_paintGoldPlanet, driftY: 0.004, driftCycles: 7, driftPhase: 0.2),
        Layer.live(_paintDust),
      ],
    );

