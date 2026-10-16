import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Candy Wonderland in flat, graphic 2D: cotton-candy clouds, frosted gumdrop
// mountains, pink gumdrop hills, a forest of cone drops / lollipops, a strawberry
// syrup river, one giant peppermint lollipop tree, striped canes and whipped
// cream piles. Sprinkles tumble down in three depths. Light comes from the left,
// shade tones are violet-pink, shapes are flat with hard cel edges.

// palette
const _cream = Color(0xFFFFF6EA), _creamShade = Color(0xFFFFD3E6);
const _pink = Color(0xFFFF8FC8), _berry = Color(0xFFFF4F8B), _berryDark = Color(0xFFE63479), _berryLight = Color(0xFFFF93B9);
const _mint = Color(0xFF8FF0C8), _blue = Color(0xFF7FD0FF), _red = Color(0xFFFF4A5E), _choc = Color(0xFF7A4A3A);
const _lav = Color(0xFFC9A8FF);
const _sprinkleCols = [Color(0xFFFF4F8B), Color(0xFF7FD0FF), Color(0xFF8FF0C8), Color(0xFFFFFFFF), Color(0xFFFFE27A), Color(0xFFC9A8FF), Color(0xFFFF4A5E), _choc];

SceneSpec candyScene() => SceneSpec(
      focusY: -0.2,
      topShade: 0.07,
      bottomShade: 0.09,
      layers: [
        Layer.still(_sky),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.04, bandBottom: 0.34),
        Layer.still(_mountains, driftX: 0.005, driftCycles: 2),
        Layer.scroll(_cloudsFront, scrollCycles: 2, bandTop: 0.26, bandBottom: 0.46),
        Layer.still(_hills, driftX: 0.009, driftCycles: 2, driftPhase: 0.05),
        Layer.still(_forest, driftX: 0.014, driftCycles: 2, driftPhase: 0.1, sway: 0.004, swayCycles: 5),
        Layer.still(_meadow, driftX: 0.019, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_glints),
        Layer.live(_lollipops),
        Layer.still(_canes, driftX: 0.03, driftCycles: 2, driftPhase: 0.25, sway: 0.012, swayCycles: 4, pivot: Alignment.bottomCenter),
        Layer.still(_fore, driftX: 0.04, driftCycles: 2, driftPhase: 0.3),
        Layer.live(_sprinkles),
        Layer.live(_sparkles),
      ],
    );

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ---------------------------------------------------------------- helpers

Paint _fill(Color c) => Paint()..color = c;

/// Rotated flat sprinkle capsule.
void _sprinkle(Canvas c, Offset o, double len, double th, double ang, Color col) {
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(ang)
    ..drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: len, height: th), Radius.circular(th / 2)), _fill(col))
    ..restore();
}

/// Four-pointed flat star with a translucent flat ring.
final Path _starUnit = () {
  const k = 0.16;
  return Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(k, -k, 1, 0)
    ..quadraticBezierTo(k, k, 0, 1)
    ..quadraticBezierTo(-k, k, -1, 0)
    ..quadraticBezierTo(-k, -k, 0, -1)
    ..close();
}();

void _star(Canvas c, Offset o, double r, Color col, {double a = 1, bool ring = true}) {
  if (a <= 0.02 || r <= 0.3) return;
  if (ring) c.drawCircle(o, r * 0.95, _fill(col.withValues(alpha: 0.22 * a)));
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..scale(r)
    ..drawPath(_starUnit, _fill(col.withValues(alpha: a)))
    ..restore();
}

/// Twisted pie wedges on a unit disc (cached): the peppermint swirl.
final Map<int, Path> _wedgeCache = {};
Path _wedges(int n, double twist) => _wedgeCache.putIfAbsent(n * 1000 + (twist * 100).round(), () {
      final p = Path();
      const steps = 14;
      for (var i = 0; i < n; i++) {
        final a0 = tau * i / n, sweep = tau / n * 0.5;
        p.moveTo(0, 0);
        for (var j = 1; j <= steps; j++) {
          final t = j / steps, a = a0 + twist * t;
          p.lineTo(math.cos(a) * t, math.sin(a) * t);
        }
        p.arcTo(const Rect.fromLTRB(-1, -1, 1, 1), a0 + twist, sweep, false);
        for (var j = steps; j >= 0; j--) {
          final t = j / steps, a = a0 + sweep + twist * t;
          p.lineTo(math.cos(a) * t, math.sin(a) * t);
        }
        p.close();
      }
      return p;
    });

/// Glossy swirl disc: cream rim with a flat shade crescent, two-colour swirl,
/// white rim light and a specular blob.
void _disc(Canvas c, Offset o, double r, {required Color a, required Color b, int n = 8, double twist = 1.5, double angle = 0, Color rim = _cream, Color rimShade = _creamShade}) {
  c.drawCircle(o + Offset(r * 0.05, r * 0.06), r, _fill(rimShade));
  c.drawCircle(o, r, _fill(rim));
  final ri = r * 0.9;
  c.drawCircle(o, ri, _fill(b));
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(angle)
    ..scale(ri)
    ..drawPath(_wedges(n, twist), _fill(a))
    ..restore();
  // flat shade crescent on the lower right of the swirl (light from the upper left)
  final cres = Path()..addOval(Rect.fromCircle(center: o, radius: ri));
  c
    ..save()
    ..clipPath(cres)
    ..drawPath(
      Path()
        ..addOval(Rect.fromCircle(center: o, radius: ri * 1.4))
        ..addOval(Rect.fromCircle(center: o + Offset(-r * 0.12, -r * 0.14), radius: ri * 1.0))
        ..fillType = PathFillType.evenOdd,
      _fill(const Color(0x1F8A3DB0)),
    )
    ..restore();
  c.drawArc(Rect.fromCircle(center: o, radius: r * 0.93), math.pi * 1.02, math.pi * 0.5, false, Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(1.4, r * 0.05)
    ..color = const Color(0xFFFFFFFF));
  c
    ..save()
    ..translate(o.dx - r * 0.42, o.dy - r * 0.46)
    ..rotate(-0.7)
    ..drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.3, height: r * 0.15), _fill(const Color(0xCCFFFFFF)))
    ..restore();
}

/// Straight lollipop stick (cream, flat shade side, white gloss line).
void _stick(Canvas c, Offset base, double len, double tw, {bool striped = false}) {
  final p = Path()
    ..moveTo(base.dx - tw * 1.15, base.dy)
    ..lineTo(base.dx - tw * 0.9, base.dy - len)
    ..lineTo(base.dx + tw * 0.9, base.dy - len)
    ..lineTo(base.dx + tw * 1.15, base.dy);
  p.close();
  c.drawPath(p, _fill(_cream));
  c
    ..save()
    ..clipPath(p);
  if (striped) {
    final sp = tw * 2.4;
    final pa = _fill(_red)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sp * 0.5;
    for (var y = base.dy + sp; y > base.dy - len - sp; y -= sp) {
      c.drawLine(Offset(base.dx - tw * 1.6, y + tw * 1.1), Offset(base.dx + tw * 1.6, y - tw * 1.1), pa);
    }
  }
  c.drawRect(Rect.fromLTRB(base.dx + tw * 0.25, base.dy - len, base.dx + tw * 2, base.dy), _fill(const Color(0x30B5409A)));
  c.drawRect(Rect.fromLTRB(base.dx - tw * 0.62, base.dy - len, base.dx - tw * 0.4, base.dy), _fill(const Color(0xB3FFFFFF)));
  c.restore();
}

/// Rounded dome (gumdrop mountain / hill) path.
Path _domePath(double cx, double base, double wd, double ht) {
  final l = cx - wd / 2, r = cx + wd / 2, top = base - ht;
  return Path()
    ..moveTo(l, base)
    ..cubicTo(l + wd * 0.02, base - ht * 0.66, cx - wd * 0.2, top, cx, top)
    ..cubicTo(cx + wd * 0.2, top, r - wd * 0.02, base - ht * 0.66, r, base)
    ..close();
}

void _mountain(Canvas c, double cx, double base, double wd, double ht, Color col, Color shade, {Color? frost, Color? frostShade}) {
  final p = _domePath(cx, base, wd, ht);
  c.drawPath(p, _fill(shade));
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(-wd * 0.09, 0)), _fill(col));
  if (frost != null) {
    final l = cx - wd / 2, top = base - ht, yc = top + ht * 0.17;
    final n = math.max(5, (wd / (ht * 0.2)).round());
    void cap(Offset d, Color k) {
      final f = _fill(k);
      c.drawRect(Rect.fromLTRB(l - 10, top - 10, l + wd + 10, yc).shift(d), f);
      for (var i = 0; i < n; i++) {
        final x = l + wd * (i + 0.5) / n;
        final rr = wd / n * (0.6 + 0.12 * ((i * 7) % 3));
        c.drawCircle(Offset(x, yc) + d, rr, f);
        if (i % 3 == 1) {
          final dw = wd * 0.042, dl = ht * (0.1 + 0.05 * (i % 2));
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - dw, yc, x + dw, yc + dl).shift(d), Radius.circular(dw)), f);
        }
      }
    }

    cap(Offset.zero, frostShade ?? _creamShade);
    cap(Offset(-wd * 0.035, -ht * 0.02), frost);
  }
  c.restore();
}

/// Cone-shaped gumdrop tree with sugar dots, flat shade and a specular blob.
void _gumdrop(Canvas c, Offset base, double h, Color col, Color shade, {int seed = 1, double bw = 0.34}) {
  final b = h * bw;
  final p = Path()
    ..moveTo(base.dx - b, base.dy)
    ..cubicTo(base.dx - b * 1.02, base.dy - h * 0.45, base.dx - b * 0.34, base.dy - h * 0.96, base.dx, base.dy - h)
    ..cubicTo(base.dx + b * 0.34, base.dy - h * 0.96, base.dx + b * 1.02, base.dy - h * 0.45, base.dx + b, base.dy)
    ..close();
  c.drawPath(p, _fill(shade));
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(-b * 0.28, 0)), _fill(col))
    ..restore();
  final r = rng(seed);
  for (var i = 0; i < 6; i++) {
    final t = 0.18 + r.nextDouble() * 0.7;
    final half = b * (0.15 + 0.7 * t);
    final x = base.dx + (r.nextDouble() * 2 - 1) * half * 0.62;
    c.drawCircle(Offset(x, base.dy - h * (1 - t) - h * 0.03), math.max(0.9, h * 0.016), _fill(const Color(0xCCFFFFFF)));
  }
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx - b * 0.38, base.dy - h * 0.55), width: b * 0.2, height: h * 0.2), Radius.circular(b * 0.1)), _fill(const Color(0xB3FFFFFF)));
}

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [Color(0xFFF7A9DD), Color(0xFFDDB6FA), Color(0xFFBFE6FF), Color(0xFFF1F3FF)], const [0.0, 0.26, 0.5, 0.64]);
  flatSun(c, Offset(s.width * 0.8, s.height * 0.085), s.width * 0.05, core: _cream, halo: const Color(0xFFFFE6F4));
}

void _cloudsBack(Canvas c, Size s) {
  final r = rng(5);
  for (var i = 0; i < 3; i++) {
    final x = (i + 0.3 + r.nextDouble() * 0.4) * s.width / 3;
    flatCloud(c, Offset(x, s.height * (0.15 + r.nextDouble() * 0.12)), s.width * (0.44 + r.nextDouble() * 0.14), color: const Color(0xFFFFE3F3), shade: const Color(0xFFF5BEE0), seed: i + 3, puff: 1.1);
  }
}

void _cloudsFront(Canvas c, Size s) {
  final r = rng(9);
  for (var i = 0; i < 2; i++) {
    final x = (i + 0.3 + r.nextDouble() * 0.4) * s.width / 2;
    flatCloud(c, Offset(x, s.height * (0.36 + r.nextDouble() * 0.04)), s.width * (0.3 + r.nextDouble() * 0.1), color: const Color(0xFFEAF7FF), shade: const Color(0xFFBFDFF8), seed: i + 41, puff: 0.9);
  }
}

// ---------------------------------------------------------------- mountains & hills

void _mountains(Canvas c, Size s) {
  final w = s.width, h = s.height;
  const back = [(0.08, 0.5, 0.2), (0.45, 0.52, 0.27), (0.8, 0.46, 0.22), (1.1, 0.5, 0.18)];
  var bi = 0;
  for (final (x, wd, ht) in back) {
    final blue = bi++ % 2 == 1;
    _mountain(c, w * x, h * 0.56, w * wd, h * ht, blue ? const Color(0xFFA6D8FF) : const Color(0xFFC0A8F8), blue ? const Color(0xFF8CC3F4) : const Color(0xFFA78EEB), frost: _cream, frostShade: const Color(0xFFF1D9F0));
  }
  const front = [(-0.02, 0.5, 0.14), (0.3, 0.46, 0.115), (0.62, 0.52, 0.15), (0.95, 0.46, 0.12)];
  for (final (x, wd, ht) in front) {
    _mountain(c, w * x, h * 0.58, w * wd, h * ht, const Color(0xFFF7A6DA), const Color(0xFFE48DC8), frost: _cream, frostShade: _creamShade);
  }
  c.drawRect(Rect.fromLTRB(-w * 0.2, h * 0.575, w * 1.2, h * 1.1), _fill(const Color(0xFFF7BFEA)));
}

void _hills(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(31);
  // back gumdrop hills
  final ridge = Ridge(s, y: 0.572, amp: 0.012, freq: 1.8, seed: 61, octaves: 2);
  flatRidge(c, ridge, const Color(0xFFF7BFEA), light: const Color(0xFFFFD9F3), band: 3);
  const domes = [(0.18, 0.46, 0.05, Color(0xFFFFB3DE), Color(0xFFF59ACF)), (0.62, 0.52, 0.06, Color(0xFFB9EBDD), Color(0xFFA0DCCC)), (0.92, 0.4, 0.045, Color(0xFFFFB3DE), Color(0xFFF59ACF))];
  for (final (x, wd, ht, col, sh) in domes) {
    _mountain(c, w * x, h * 0.605, w * wd, h * ht, col, sh);
  }
  final ridge2 = Ridge(s, y: 0.6, amp: 0.014, freq: 2.2, seed: 62, octaves: 2);
  flatRidge(c, ridge2, const Color(0xFFFFA9D6), light: const Color(0xFFFFC6E6), band: 3);
  for (var i = 0; i < 46; i++) {
    final x = r.nextDouble() * w * 1.1 - w * 0.05;
    final y = h * (0.61 + r.nextDouble() * 0.03);
    if (y < ridge2.yAt(x) + 5) continue;
    _sprinkle(c, Offset(x, y), 5, 2, r.nextDouble() * math.pi, i % 3 == 0 ? _cream : (i % 3 == 1 ? const Color(0xFFFFE27A) : const Color(0xFFD7F7EA)));
  }
}

// ---------------------------------------------------------------- forest

void _forest(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(77);
  const dropCols = [(_mint, Color(0xFF6FD6AE)), (_blue, Color(0xFF5CB6EE)), (_lav, Color(0xFFA886EE)), (Color(0xFFFFE08A), Color(0xFFF2C25F)), (Color(0xFFFFB0DA), Color(0xFFF08DC3))];
  const swirls = [(_red, _cream), (_berry, _cream), (_blue, _cream), (Color(0xFFB48CFF), _cream)];
  for (var row = 0; row < 2; row++) {
    final ridge = Ridge(s, y: 0.63 + row * 0.04, amp: 0.01, freq: 2.6 + row, seed: 80 + row, octaves: 2);
    var x = -w * 0.05;
    while (x < w * 1.05) {
      final th = h * (0.06 + r.nextDouble() * 0.035) * (1 + row * 0.4);
      final base = Offset(x, ridge.yAt(x) + 3);
      final kind = r.nextDouble();
      if (kind < 0.72) {
        final (col, sh) = dropCols[r.nextInt(dropCols.length)];
        _gumdrop(c, base, th * 1.2, row == 0 ? hazeTo(col, const Color(0xFFFFD2EC), 0.25) : col, row == 0 ? hazeTo(sh, const Color(0xFFFFD2EC), 0.25) : sh, seed: r.nextInt(999));
      } else {
        final (a, b) = swirls[r.nextInt(swirls.length)];
        final sl = th * 0.75, dr = th * 0.34;
        _stick(c, base, sl, th * 0.04);
        _disc(c, base + Offset(0, -sl), dr, a: row == 0 ? hazeTo(a, const Color(0xFFFFD2EC), 0.25) : a, b: b, n: 7 + r.nextInt(3), twist: 1.2 + r.nextDouble());
      }
      x += th * (0.62 + r.nextDouble() * 0.5);
    }
    flatRidge(c, ridge, row == 0 ? const Color(0xFFFF9BCF) : const Color(0xFFFF8CC4), light: row == 0 ? const Color(0xFFFFB8DE) : const Color(0xFFFFA6D5), band: 3);
  }
}

// ---------------------------------------------------------------- meadow & river

Size? _rSize;
List<Offset> _rPts = const [];
List<double> _rHw = const [];

void _ensureRiver(Size s) {
  if (_rSize == s) return;
  final w = s.width, h = s.height;
  final ctrl = <Offset>[
    Offset(w * 0.7, h * 0.675),
    Offset(w * 0.69, h * 0.7),
    Offset(w * 0.64, h * 0.75),
    Offset(w * 0.62, h * 0.8),
    Offset(w * 0.6, h * 0.86),
    Offset(w * 0.54, h * 0.92),
    Offset(w * 0.5, h * 0.98),
    Offset(w * 0.5, h * 1.07),
  ];
  final hws = [w * 0.01, w * 0.03, w * 0.055, w * 0.07, w * 0.085, w * 0.1, w * 0.12, w * 0.14];
  final pts = <Offset>[], hw = <double>[];
  Offset at(int i) => ctrl[i.clamp(0, ctrl.length - 1)];
  for (var i = 0; i < ctrl.length - 1; i++) {
    for (var j = 0; j < 12; j++) {
      final t = j / 12, t2 = t * t, t3 = t2 * t;
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      pts.add((p1 * 2.0 + (p2 - p0) * t + (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t2 + (p1 * 3.0 - p0 - p2 * 3.0 + p3) * t3) * 0.5);
      final e = t * t * (3 - 2 * t);
      hw.add(_lerp(hws[i], hws[i + 1], e));
    }
  }
  pts.add(ctrl.last);
  hw.add(hws.last);
  _rSize = s;
  _rPts = pts;
  _rHw = hw;
}

Path _ribbonPath(double extra) {
  final l = <Offset>[], r = <Offset>[];
  for (var i = 0; i < _rPts.length; i++) {
    final a = _rPts[math.max(i - 1, 0)], b = _rPts[math.min(i + 1, _rPts.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    l.add(_rPts[i] - n * (_rHw[i] + extra));
    r.add(_rPts[i] + n * (_rHw[i] + extra));
  }
  return smoothPath([...l, ...r.reversed], closed: true);
}

void _meadow(Canvas c, Size s) {
  _ensureRiver(s);
  final w = s.width, h = s.height;
  final ridge = Ridge(s, y: 0.7, amp: 0.016, freq: 1.5, seed: 93, octaves: 2, tilt: 0.02);
  flatRidge(c, ridge, const Color(0xFF9BF0CF), light: const Color(0xFFC9FBE5), band: 3);
  final ridge2 = Ridge(s, y: 0.84, amp: 0.02, freq: 1.2, seed: 17, octaves: 2, tilt: -0.04);
  // river, clipped by the meadow crest so it appears from behind the hill
  c
    ..save()
    ..clipPath(ridge.fill());
  c.drawPath(_ribbonPath(5), _fill(_cream));
  final water = _ribbonPath(0);
  c.drawPath(water, _fill(_berry));
  c
    ..save()
    ..clipPath(water);
  // flat shade on the right half, light strip on the left bank
  final shade = Path();
  for (var i = 0; i < _rPts.length; i++) {
    final a = _rPts[math.max(i - 1, 0)], b = _rPts[math.min(i + 1, _rPts.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    final p = _rPts[i] + n * (_rHw[i] * 0.35);
    i == 0 ? shade.moveTo(p.dx, p.dy) : shade.lineTo(p.dx, p.dy);
  }
  for (var i = _rPts.length - 1; i >= 0; i--) {
    final a = _rPts[math.max(i - 1, 0)], b = _rPts[math.min(i + 1, _rPts.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    final p = _rPts[i] + n * (_rHw[i] * 1.2);
    shade.lineTo(p.dx, p.dy);
  }
  shade.close();
  c.drawPath(shade, _fill(_berryDark));
  final light = Path();
  for (var i = 0; i < _rPts.length; i++) {
    final a = _rPts[math.max(i - 1, 0)], b = _rPts[math.min(i + 1, _rPts.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    final p = _rPts[i] - n * (_rHw[i] * 0.72);
    i == 0 ? light.moveTo(p.dx, p.dy) : light.lineTo(p.dx, p.dy);
  }
  c.drawPath(light, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = _berryLight);
  c
    ..restore()
    ..restore();
  // wafer bridge across the syrup
  final bi = (_rPts.length * 0.5).floor();
  final bp = _rPts[bi], bw = _rHw[bi] + w * 0.07;
  final by = bp.dy - 2;
  Path arch(double dy) => Path()
    ..moveTo(bp.dx - bw, by + dy)
    ..cubicTo(bp.dx - bw * 0.55, by - h * 0.065 + dy, bp.dx + bw * 0.55, by - h * 0.065 + dy, bp.dx + bw, by + dy)
    ..lineTo(bp.dx + bw, by + 12 + dy)
    ..cubicTo(bp.dx + bw * 0.55, by - h * 0.065 + 12 + dy, bp.dx - bw * 0.55, by - h * 0.05 + 9 + dy, bp.dx - bw, by + 12 + dy)
    ..close();
  c.drawPath(arch(5), _fill(const Color(0xFF5E3829)));
  c.drawPath(arch(0), _fill(const Color(0xFF9A6450)));
  for (var i = 0; i < 7; i++) {
    final t = (i + 0.5) / 7;
    final x = _lerp(bp.dx - bw * 0.9, bp.dx + bw * 0.9, t);
    final yy = by - h * 0.0488 * (1 - math.pow(2 * t - 1, 2)) * 1.0 - 3 + 4;
    c.drawCircle(Offset(x, yy), 2.4, _fill(_cream));
  }
  for (final sx in [-1, 1]) {
    final o = Offset(bp.dx + sx * bw, by + 2);
    c.drawCircle(o, w * 0.022, _fill(sx < 0 ? _pink : _mint));
    c.drawCircle(o + Offset(-w * 0.007, -w * 0.007), w * 0.006, _fill(const Color(0xCCFFFFFF)));
  }
  // side meadows in front of the river, framing it
  final left = smoothPath([
    Offset(-w * 0.1, h * 0.8),
    Offset(w * 0.1, h * 0.8 + ridge2.yAt(w * 0.1) * 0 - h * 0.012),
    Offset(w * 0.3, h * 0.87),
    Offset(w * 0.4, h * 1.0),
    Offset(w * 0.4, h * 1.1),
  ])
    ..lineTo(-w * 0.1, h * 1.1)
    ..close();
  c.drawPath(left, _fill(const Color(0xFF7FE3BC)));
  c.drawPath(left.shift(const Offset(0, 5)), _fill(const Color(0xFF7FE3BC)));
  final right = smoothPath([
    Offset(w * 1.1, h * 0.82),
    Offset(w * 0.9, h * 0.83),
    Offset(w * 0.74, h * 0.9),
    Offset(w * 0.66, h * 1.0),
    Offset(w * 0.66, h * 1.1),
  ])
    ..lineTo(w * 1.1, h * 1.1)
    ..close();
  c.drawPath(right, _fill(const Color(0xFF7FE3BC)));
  for (final p in [left, right]) {
    c
      ..save()
      ..clipPath(p)
      ..restore();
  }
  c.drawPath(smoothPath([Offset(-w * 0.1, h * 0.8), Offset(w * 0.1, h * 0.788), Offset(w * 0.3, h * 0.87), Offset(w * 0.4, h * 1.0)]), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFC9FBE5));
  c.drawPath(smoothPath([Offset(w * 1.1, h * 0.82), Offset(w * 0.9, h * 0.83), Offset(w * 0.74, h * 0.9), Offset(w * 0.66, h * 1.0)]), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFC9FBE5));
  // sprinkles on the grass
  final r = rng(44);
  for (var i = 0; i < 40; i++) {
    final side = i.isEven;
    final x = side ? r.nextDouble() * w * 0.34 : w * 0.7 + r.nextDouble() * w * 0.3;
    final y = h * (0.9 + r.nextDouble() * 0.08);
    _sprinkle(c, Offset(x, y), 7, 2.6, r.nextDouble() * math.pi, _sprinkleCols[i % _sprinkleCols.length]);
  }
  // gumdrops dotted in the grass and a stepping-stone path of sugar candies
  for (var i = 0; i < 5; i++) {
    final x = w * (0.04 + i * 0.07), y = h * (0.865 + (i % 2) * 0.03) + (i * 4);
    c.drawCircle(Offset(x, y), 5.5, _fill(const [_pink, _blue, Color(0xFFFFE27A), _lav, _pink][i]));
    c.drawCircle(Offset(x - 1.6, y - 1.8), 1.6, _fill(const Color(0xCCFFFFFF)));
  }
}

void _glints(Canvas c, Size s, Clock k) {
  _ensureRiver(s);
  final r = rng(12);
  final k0 = s.width / 390;
  final n = _rPts.length - 1;
  for (var i = 0; i < 22; i++) {
    final t0 = r.nextDouble(), lat = (r.nextDouble() - 0.5) * 1.1, ph = r.nextDouble();
    final cyc = 2 + i % 3;
    final f = (t0 + k.saw(cyc, ph)) % 1.0;
    final t = 0.2 + 0.74 * f;
    final fi = t * n;
    final j = fi.floor().clamp(0, n - 1);
    final p = Offset.lerp(_rPts[j], _rPts[j + 1], fi - j)!;
    final hw = _lerp(_rHw[j], _rHw[j + 1], fi - j);
    final d = _rPts[j + 1] - _rPts[j];
    final ang = math.atan2(d.dy, d.dx);
    final nrm = Offset(-d.dy, d.dx) / d.distance;
    final a = math.sin(math.pi * f) * (0.55 + 0.45 * k.pulse(6 + i % 3, ph));
    if (a < 0.05) continue;
    final len = (7 + hw * 0.22 + (i % 3) * 3) * (k0 > 0 ? 1 : 1);
    c
      ..save()
      ..translate(p.dx + nrm.dx * lat * hw, p.dy + nrm.dy * lat * hw)
      ..rotate(ang)
      ..drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: len, height: 2.4), const Radius.circular(1.2)), _fill(Color.fromRGBO(255, 255, 255, a * 0.85)))
      ..restore();
  }
}

// ---------------------------------------------------------------- lollipops (live: spinning swirls)

void _lollipops(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  c
    ..save()
    ..translate(w * 0.022 * k.sine(2, 0.2), 0);
  // (x, baseY, discRadius, stickLen, a, b, rotation cycles, direction)
  final specs = <(double, double, double, double, Color, Color, int, int)>[
    (0.66, 0.725, 14, 46, _blue, _cream, 2, 1),
    (0.9, 0.79, 24, 80, _berry, _cream, 3, -1),
    (0.07, 0.8, 21, 72, Color(0xFFB48CFF), _cream, 2, 1),
    (0.5, 0.69, 11, 34, _red, _cream, 3, -1),
  ];
  var idx = 0;
  for (final (x, by, dr, sl, a, b, cyc, dir) in specs) {
    idx++;
    _lollipop(c, Offset(w * x, h * by), dr * k0, sl * k0, a, b, k.saw(cyc, idx * 0.13) * tau * dir, 0.025 * k.sine(4, idx * 0.2), 9 + idx % 3);
  }
  // the hero: giant peppermint lollipop tree
  final base = Offset(w * 0.3, h * 0.82);
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(0.014 * k.sine(5, 0.1))
    ..translate(-base.dx, -base.dy);
  c.drawOval(Rect.fromCenter(center: base + Offset(w * 0.02, 2), width: w * 0.2, height: h * 0.022), _fill(const Color(0xFF6DD6AE)));
  final sl = h * 0.5, dr = w * 0.25;
  _stick(c, base, sl, w * 0.026, striped: true);
  _disc(c, base + Offset(0, -sl - dr * 0.1), dr, a: _red, b: _cream, n: 10, twist: 1.7, angle: tau * k.saw(1) * -1, rim: const Color(0xFFFFFFFF), rimShade: _creamShade);
  for (final (dx, col) in [(-0.06, _blue), (0.07, _pink), (0.1, Color(0xFFFFE27A))]) {
    final o = base + Offset(w * dx, h * 0.005);
    c.drawCircle(o, w * 0.018, _fill(col));
    c.drawCircle(o + Offset(-w * 0.006, -w * 0.006), w * 0.005, _fill(const Color(0xCCFFFFFF)));
  }
  c.restore();
  c.restore();
}

void _lollipop(Canvas c, Offset base, double dr, double sl, Color a, Color b, double angle, double sway, int n) {
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(sway);
  c.drawOval(Rect.fromCenter(center: Offset(dr * 0.4, 1), width: dr * 2, height: dr * 0.28), _fill(const Color(0xFF6DD6AE)));
  _stick(c, Offset.zero, sl, dr * 0.11);
  _disc(c, Offset(0, -sl - dr * 0.1), dr, a: a, b: b, n: n, twist: 1.5, angle: angle);
  c.restore();
}

// ---------------------------------------------------------------- canes

void _cane(Canvas c, double bx, double baseY, double top, double wd, double hookR, int dir) {
  final pts = <Offset>[];
  final yTop = top + hookR;
  for (var i = 0; i <= 10; i++) {
    pts.add(Offset(bx, _lerp(baseY, yTop, i / 10)));
  }
  final cc = Offset(bx - hookR * dir, yTop);
  for (var i = 1; i <= 28; i++) {
    final th = math.pi * 1.04 * i / 28;
    pts.add(cc + Offset(dir * hookR * math.cos(th), -hookR * math.sin(th)));
  }
  final l = <Offset>[], r = <Offset>[], ms = <Offset>[], gl = <Offset>[];
  final tans = <Offset>[];
  for (var i = 0; i < pts.length; i++) {
    final a = pts[math.max(i - 1, 0)], b = pts[math.min(i + 1, pts.length - 1)];
    var d = b - a;
    d = d / d.distance;
    tans.add(d);
    final n = Offset(-d.dy, d.dx);
    l.add(pts[i] - n * wd);
    r.add(pts[i] + n * wd);
    ms.add(pts[i] + n * wd * 0.4);
    gl.add(pts[i] - n * wd * 0.55);
  }
  final body = Path()..moveTo(l.first.dx, l.first.dy);
  for (final p in l.skip(1)) {
    body.lineTo(p.dx, p.dy);
  }
  for (final p in r.reversed) {
    body.lineTo(p.dx, p.dy);
  }
  body.close();
  c.drawPath(body, _fill(_cream));
  c.drawCircle(pts.last, wd, _fill(_red));
  c
    ..save()
    ..clipPath(body);
  final sp = wd * 2.6;
  final stripe = _fill(_red)
    ..style = PaintingStyle.stroke
    ..strokeWidth = sp * 0.46;
  var acc = 0.0;
  for (var i = 1; i < pts.length; i++) {
    final seg = (pts[i] - pts[i - 1]).distance;
    acc += seg;
    if (acc >= sp) {
      acc = 0;
      final t = tans[i], n = Offset(-t.dy, t.dx);
      c.drawLine(pts[i] + n * wd * 1.4 - t * wd * 0.5, pts[i] - n * wd * 1.4 + t * wd * 0.5, stripe);
    }
  }
  // shade band on the side facing away from the light
  final shade = Path()..moveTo(r.first.dx, r.first.dy);
  for (final p in r.take(11).skip(1)) {
    shade.lineTo(p.dx, p.dy);
  }
  for (final p in ms.take(11).toList().reversed) {
    shade.lineTo(p.dx, p.dy);
  }
  shade.close();
  c.drawPath(shade, _fill(const Color(0x30B5409A)));
  final gloss = Path()..moveTo(gl.first.dx, gl.first.dy);
  for (final p in gl.take(11).skip(1)) {
    gloss.lineTo(p.dx, p.dy);
  }
  final gloss2 = Path();
  for (var i = 12; i < 24; i++) {
    final o = pts[i] + Offset(-tans[i].dy, tans[i].dx) * wd * 0.55 * dir.toDouble();
    i == 12 ? gloss2.moveTo(o.dx, o.dy) : gloss2.lineTo(o.dx, o.dy);
  }
  c.drawPath(gloss2, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.2, wd * 0.2)
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xB3FFFFFF));
  c.drawPath(gloss, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.2, wd * 0.2)
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xB3FFFFFF));
  c.restore();
}

void _canes(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _cane(c, w * 0.92, h * 1.08, h * 0.5, w * 0.027, w * 0.1, 1);
  // tiny gumdrop pair at the cane foot
  c.drawCircle(Offset(w * 0.8, h * 0.955), 9, _fill(_blue));
  c.drawCircle(Offset(w * 0.8 - 3, h * 0.955 - 3), 2.4, _fill(const Color(0xCCFFFFFF)));
}

// ---------------------------------------------------------------- foreground

void _pile(Canvas c, Offset base, double w, double th, {required int seed, required Color topping}) {
  final r = rng(seed);
  var y = base.dy;
  var cw = w;
  for (var i = 0; i < 3; i++) {
    final rect = Rect.fromCenter(center: Offset(base.dx, y - th / 2), width: cw, height: th);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(th / 2)), _fill(_creamShade));
    c
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(th / 2)))
      ..drawRRect(RRect.fromRectAndRadius(rect.shift(Offset(-cw * 0.035, -th * 0.12)), Radius.circular(th / 2)), _fill(_cream))
      ..restore();
    y -= th * 0.72;
    cw *= 0.74;
  }
  // curled tip
  final tw = cw * 0.55, ty = y + th * 0.3;
  final tip = Path()
    ..moveTo(base.dx - tw, ty)
    ..cubicTo(base.dx - tw, ty - th * 0.6, base.dx - tw * 0.1, ty - th * 0.8, base.dx + tw * 0.3, ty - th * 1.2)
    ..cubicTo(base.dx + tw * 0.3, ty - th * 0.7, base.dx + tw, ty - th * 0.5, base.dx + tw, ty)
    ..close();
  c.drawPath(tip, _fill(_creamShade));
  c
    ..save()
    ..clipPath(tip)
    ..drawPath(tip.shift(Offset(-tw * 0.25, -th * 0.1)), _fill(_cream))
    ..restore();
  // topping: glossy cherry
  final co = Offset(base.dx + tw * 0.3, ty - th * 1.0);
  c.drawCircle(co + Offset(0, -th * 0.34), th * 0.42, _fill(topping));
  c.drawCircle(co + Offset(th * 0.08, -th * 0.28), th * 0.34, _fill(darken(topping, 0.08)));
  c.drawCircle(co + Offset(0, -th * 0.34), th * 0.42, _fill(topping));
  c
    ..save()
    ..clipPath(Path()..addOval(Rect.fromCircle(center: co + Offset(0, -th * 0.34), radius: th * 0.42)))
    ..drawCircle(co + Offset(th * 0.2, -th * 0.2), th * 0.42, _fill(darken(topping, 0.1)))
    ..drawCircle(co + Offset(-th * 0.04, -th * 0.38), th * 0.4, _fill(topping))
    ..restore();
  c.drawOval(Rect.fromCenter(center: co + Offset(-th * 0.17, -th * 0.5), width: th * 0.2, height: th * 0.12), _fill(const Color(0xCCFFFFFF)));
  c.drawLine(co + Offset(0, -th * 0.74), co + Offset(th * 0.12, -th * 1.05), Paint()
    ..color = const Color(0xFF3E9E6C)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round);
  // sprinkles
  for (var i = 0; i < 8; i++) {
    final x = base.dx + (r.nextDouble() - 0.5) * w * 0.8;
    final yy = base.dy - th * (0.15 + r.nextDouble() * 0.55);
    _sprinkle(c, Offset(x, yy), 7, 2.6, r.nextDouble() * math.pi, _sprinkleCols[(i + seed) % _sprinkleCols.length]);
  }
}

void _fore(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // whipped cream wave bed
  final n = 7;
  void bed(Offset d, Color col) {
    final f = _fill(col);
    c.drawRect(Rect.fromLTRB(-w * 0.2, h * 0.975, w * 1.2, h * 1.2).shift(d), f);
    for (var i = -1; i <= n; i++) {
      final x = w * (i + 0.5) / n * (1.0) + (i % 2 == 0 ? 0 : 0);
      c.drawCircle(Offset(x, h * 0.985 + (i % 2) * h * 0.004) + d, w / n * 0.62, f);
    }
  }

  bed(Offset.zero, _creamShade);
  bed(Offset(-w * 0.012, -h * 0.006), _cream);
  _pile(c, Offset(w * 0.1, h * 1.01), w * 0.36, h * 0.05, seed: 3, topping: _red);
  _pile(c, Offset(w * 0.84, h * 1.015), w * 0.3, h * 0.045, seed: 7, topping: _berry);
  final r = rng(21);
  for (var i = 0; i < 14; i++) {
    final x = w * (0.3 + r.nextDouble() * 0.4);
    final y = h * (0.975 + r.nextDouble() * 0.025);
    _sprinkle(c, Offset(x, y), 8, 3, r.nextDouble() * math.pi, _sprinkleCols[i % _sprinkleCols.length]);
  }
}

// ---------------------------------------------------------------- live: sprinkles & sparkles

void _sprinkles(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  // (count, size, speed cycles, alpha, seed)
  const depths = [(26, 1.0, 2, 0.55, 3), (22, 1.5, 3, 0.8, 4), (11, 2.0, 4, 0.95, 5)];
  for (final (count, sz, cyc, al, seed) in depths) {
    final r = rng(seed);
    for (var i = 0; i < count; i++) {
      final x0 = r.nextDouble(), ph = r.nextDouble();
      final col = _sprinkleCols[r.nextInt(_sprinkleCols.length)];
      final lap = k.saw(cyc + i % 2, ph);
      final x = (x0 + 0.035 * math.sin(tau * (k.u * (3 + i % 3) + ph))) * w;
      final y = (-0.05 + 1.1 * lap) * h;
      final fade = math.min(1.0, math.min(lap / 0.08, (1 - lap) / 0.08));
      final ang = tau * (ph + k.saw(2 + i % 3, ph)) * (i.isEven ? 1 : -1);
      final tumble = 0.55 + 0.45 * k.sine(5 + i % 4, ph).abs();
      _sprinkle(c, Offset(x, y), 7 * sz * k0 * tumble + 2, 2.6 * sz * k0, ang, col.withValues(alpha: al * fade));
    }
  }
}

void _sparkles(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  const pts = [
    (0.1, 0.07, 7.0), (0.55, 0.05, 5.0), (0.92, 0.2, 6.0), (0.35, 0.27, 5.5), (0.18, 0.42, 4.5), (0.7, 0.4, 5.0), (0.05, 0.62, 4.0),
    (0.95, 0.6, 5.0), (0.62, 0.72, 4.5), (0.4, 0.86, 5.5), (0.76, 0.9, 6.0), (0.22, 0.93, 4.5), (0.48, 0.15, 4.0), (0.84, 0.34, 4.0),
  ];
  var i = 0;
  for (final (x, y, r) in pts) {
    i++;
    final ph = (i * 0.137) % 1.0;
    final t = math.pow(k.pulse(10 + i % 5, ph), 2.0).toDouble();
    _star(c, Offset(w * x, h * y), r * 1.5 * k0 * (0.35 + 0.75 * t), i % 3 == 0 ? const Color(0xFFFFF3B0) : const Color(0xFFFFFFFF), a: 0.35 + 0.65 * t);
  }
}
