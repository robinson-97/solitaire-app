import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Autumn Valley in flat, graphic 2D: low golden sun, lavender mountains, rows of
// red / orange / amber / gold woods, a winding river that mirrors the canopy, a
// tiny cabin with a curl of smoke, a giant maple entering from the right and a
// carpet of fallen leaves. Leaves keep drifting down through the warm light.

const _sunPos = Offset(0.2, 0.19);

// palette
const _red = Color(0xFFD9412B), _orange = Color(0xFFF28A2E), _amber = Color(0xFFF6B93B), _gold = Color(0xFFFFD25C);
const _trunk = Color(0xFF5A2E22), _trunkShade = Color(0xFF43211A);
const _haze = Color(0xFFFFD9A0);
const _water = Color(0xFFDC9A90), _waterSky = Color(0xFFFAD6C4);

class _Tone {
  const _Tone(this.shade, this.mid, this.light);
  final Color shade, mid, light;
  _Tone haze(double a) => a <= 0 ? this : _Tone(hazeTo(shade, _haze, a), hazeTo(mid, _haze, a), hazeTo(light, _haze, a));
}

const _tRed = _Tone(Color(0xFFA9302A), _red, Color(0xFFEE6A45));
const _tOrange = _Tone(Color(0xFFCB6420), _orange, Color(0xFFF9B05A));
const _tAmber = _Tone(Color(0xFFD38F22), _amber, Color(0xFFFBD375));
const _tGold = _Tone(Color(0xFFE0AC3A), _gold, Color(0xFFFFEA9C));
const _tGreen = _Tone(Color(0xFF55693F), Color(0xFF6E8A4C), Color(0xFF93AE63));
const _tRust = _Tone(Color(0xFF8C2F26), Color(0xFFB8402B), Color(0xFFD85F3A));
const _mix = [_tRed, _tOrange, _tOrange, _tAmber, _tAmber, _tGold, _tGold, _tRed, _tRust];

const _leafCols = [_red, _orange, _amber, _gold, Color(0xFFB8402B)];
const _leafShade = [Color(0xFFA9302A), Color(0xFFCB6420), Color(0xFFD38F22), Color(0xFFE0AC3A), Color(0xFF8C2F26)];

SceneSpec autumnScene() => SceneSpec(
      focusY: -0.35,
      topShade: 0.18,
      bottomShade: 0.3,
      layers: [
        Layer.still(_sky),
        Layer.live(_skyLive),
        Layer.scroll(_clouds, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.3),
        Layer.still(_mountains, driftX: 0.004, driftCycles: 2),
        Layer.still(_hillsFar, driftX: 0.008, driftCycles: 2, driftPhase: 0.05, sway: 0.003, swayCycles: 5),
        Layer.scroll(_mist, scrollCycles: 1, scrollLeft: false, bandTop: 0.3, bandBottom: 0.45),
        Layer.still(_hillsNear, driftX: 0.012, driftCycles: 2, driftPhase: 0.1, sway: 0.004, swayCycles: 4, swayPhase: 0.3),
        Layer.still(_valley, driftX: 0.016, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_midLive),
        Layer.still(_foreground, driftX: 0.03, driftCycles: 2, driftPhase: 0.2),
        Layer.still(_hero, driftX: 0.02, driftCycles: 2, driftPhase: 0.25, sway: 0.005, swayCycles: 3, pivot: Alignment.bottomRight),
        Layer.live(_leavesFront),
      ],
    );

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ---------------------------------------------------------------- shared shapes

Path _unitLeaf() => Path()
  ..moveTo(-1, 0)
  ..cubicTo(-0.55, -0.75, 0.45, -0.8, 1, 0)
  ..cubicTo(0.45, 0.8, -0.55, 0.75, -1, 0)
  ..close();

Path _unitLeafHalf() => Path()
  ..moveTo(-1, 0)
  ..cubicTo(-0.55, 0.75, 0.45, 0.8, 1, 0)
  ..close();

final Path _leafP = _unitLeaf();
final Path _leafH = _unitLeafHalf();

Path _mapleUnit() {
  const outer = [1.0, 0.78, 0.66, 0.66, 0.78];
  final pts = <Offset>[];
  for (var i = 0; i < 5; i++) {
    final a = -math.pi / 2 + tau * i / 5;
    pts.add(Offset(math.cos(a), math.sin(a)) * outer[i]);
    final b = a + tau / 10;
    pts.add(Offset(math.cos(b), math.sin(b)) * 0.42);
  }
  return smoothPath(pts, closed: true);
}

final Path _mapleP = _mapleUnit();

/// Static leaf (flat, two tones: darker lower half).
void _leaf(Canvas c, Offset o, double len, double ang, Color col, Color shade) {
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(ang)
    ..scale(len, len);
  c.drawPath(_leafP, Paint()..color = col);
  c.drawPath(_leafH, Paint()..color = shade);
  c.restore();
}

Paint _fill(Color c) => Paint()..color = c;

/// Scalloped leaf-clump crown: three flat tones, light from the upper left.
void _crown(Canvas c, Offset cc, double r, _Tone t, int seed, {int n = 6, double squash = 0.88}) {
  final rg = rng(seed);
  final circles = <(Offset, double)>[(cc, r * 0.78)];
  for (var i = 0; i < n; i++) {
    final a = tau * i / n + rg.nextDouble() * 0.5;
    final d = r * (0.52 + rg.nextDouble() * 0.12);
    circles.add((cc + Offset(math.cos(a) * d * 1.1, math.sin(a) * d * squash), r * (0.5 + rg.nextDouble() * 0.16)));
  }
  _crownFrom(c, cc, r, circles, t);
}

void _crownFrom(Canvas c, Offset cc, double r, List<(Offset, double)> circles, _Tone t) {
  final sil = Path();
  for (final (o, rad) in circles) {
    sil.addOval(Rect.fromCircle(center: o, radius: rad));
  }
  c.drawPath(sil, _fill(t.shade));
  c
    ..save()
    ..clipPath(sil)
    ..drawPath(sil.shift(Offset(-r * 0.1, -r * 0.14)), _fill(t.mid));
  for (final (o, rad) in circles) {
    final d = o - cc;
    if (d.dx + d.dy < r * 0.25) {
      c.drawCircle(o + Offset(-rad * 0.16, -rad * 0.22), rad * 0.58, _fill(t.light));
    }
  }
  c.restore();
}

enum _Kind { round, tall }

/// Trunk + crown tree in the house style.
void _tree(Canvas c, Offset base, double h, _Tone t, Color trunk, {int seed = 1, double lean = 0, _Kind kind = _Kind.round}) {
  final r = rng(seed);
  final tw = h * 0.055;
  final cx = base.dx + lean * h * 0.12;
  final trunkTop = kind == _Kind.round ? 0.62 : 0.5;
  final tp = Path()
    ..moveTo(base.dx - tw * 1.5, base.dy)
    ..quadraticBezierTo(base.dx - tw * 0.6, base.dy - h * 0.28, cx - tw * 0.6, base.dy - h * trunkTop)
    ..lineTo(cx + tw * 0.6, base.dy - h * trunkTop)
    ..quadraticBezierTo(base.dx + tw * 0.6, base.dy - h * 0.28, base.dx + tw * 1.5, base.dy)
    ..close();
  c.drawPath(tp, _fill(trunk));
  c
    ..save()
    ..clipPath(tp)
    ..drawRect(Rect.fromLTRB(base.dx + tw * 0.1, base.dy - h, base.dx + tw * 2, base.dy), _fill(darken(trunk, 0.07)))
    ..restore();
  if (kind == _Kind.round) {
    _crown(c, Offset(cx, base.dy - h * 0.66), h * 0.3, t, r.nextInt(9999), n: 5 + r.nextInt(2));
  } else {
    final cc = Offset(cx, base.dy - h * 0.6);
    final rr = h * 0.2;
    final cs = <(Offset, double)>[];
    for (var j = 0; j < 5; j++) {
      final u = j / 4;
      cs.add((cc + Offset((r.nextDouble() - 0.5) * rr * 0.3, -h * 0.28 + u * h * 0.56), rr * (0.55 + 0.5 * math.sin(math.pi * (0.12 + 0.76 * u)))));
    }
    _crownFrom(c, cc, h * 0.3, cs, t);
  }
}

void _bareTree(Canvas c, Offset base, double h, Color col, int seed) {
  final r = rng(seed);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = col;
  void branch(Offset o, double ang, double len, double wd, int depth) {
    final e = o + Offset(math.cos(ang), math.sin(ang)) * len;
    final mid = Offset.lerp(o, e, 0.5)! + Offset(-math.sin(ang), math.cos(ang)) * len * (r.nextDouble() - 0.5) * 0.3;
    p.strokeWidth = wd;
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, e.dx, e.dy),
      p,
    );
    if (depth <= 0) return;
    final kids = 2 + (depth > 1 && r.nextBool() ? 1 : 0);
    for (var i = 0; i < kids; i++) {
      final da = (i - (kids - 1) / 2) * (0.62 + r.nextDouble() * 0.2);
      branch(e, ang + da + (r.nextDouble() - 0.5) * 0.25, len * (0.66 + r.nextDouble() * 0.12), wd * 0.66, depth - 1);
    }
  }

  branch(base, -math.pi / 2 + (r.nextDouble() - 0.5) * 0.15, h * 0.34, h * 0.05, 3);
}

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  final w = s.width, h = s.height;
  fillSky(c, s, const [Color(0xFFF1B27A), Color(0xFFF8CE96), Color(0xFFFFE9B8), Color(0xFFFFF3D6)], const [0.0, 0.2, 0.36, 0.62]);
  final sun = Offset(_sunPos.dx * w, _sunPos.dy * h);
  flatSun(c, sun, w * 0.07, core: const Color(0xFFFFF8E0), halo: const Color(0xFFFFE19A));
}

void _skyLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  final sun = Offset(_sunPos.dx * w, _sunPos.dy * h);
  final pulse = k.pulse(3);
  c.drawCircle(sun, w * 0.07 * (3.0 + 0.5 * pulse), _fill(const Color(0xFFFFE19A).withValues(alpha: 0.07 + 0.05 * pulse)));

  // V-shaped flock crossing the sky
  void flock(int n, double cyc, double y, double size, Color col, double phase) {
    final t = k.saw(cyc.toInt(), phase);
    final lead = Offset(-0.25 * w + t * 1.5 * w, y * h + math.sin(tau * (k.u * 5 + phase)) * 6 * k0);
    for (var i = 0; i < n; i++) {
      final row = (i + 1) ~/ 2;
      final side = i.isOdd ? -1 : 1;
      final o = lead + Offset(-row * 15 * size * k0, side * row * 8 * size * k0 + math.sin(tau * (k.u * 7 + i)) * 1.5);
      paintBird(c, o, 6.5 * size * k0, k.sine(30 + i * 2, i * 0.13), col);
    }
  }

  flock(7, 1, 0.12, 1.5, const Color(0xFF7B3F3A), 0.0);
  flock(4, 1, 0.215, 0.9, const Color(0xFFB77563), 0.5);
}

void _clouds(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final spots = [(0.5, 0.075, 0.42, 1.3), (0.12, 0.06, 0.3, 1.1), (0.82, 0.135, 0.46, 1.3), (0.3, 0.115, 0.26, 1.0)];
  var seed = 3;
  for (final (x, y, wd, pf) in spots) {
    for (final dx in [0.0, -w]) {
      flatCloud(c, Offset(x * w + dx, y * h), w * wd, color: const Color(0xFFFFF4D8), shade: const Color(0xFFFAC98E), seed: seed, puff: pf);
    }
    seed += 5;
  }
}

// ---------------------------------------------------------------- far land

void _peaks(Canvas c, Size s, double base, List<(double, double, double)> pk, Color color, Color shade) {
  final w = s.width, h = s.height;
  double yAt(double x) {
    var v = 0.0;
    for (final (px, ph, sg) in pk) {
      v = math.max(v, ph * math.exp(-math.pow((x - px * w).abs() / (sg * w), 1.7)));
    }
    return base * h - v * h;
  }

  final pts = <Offset>[for (var x = -w * 0.1; x <= w * 1.1; x += 5) Offset(x, yAt(x))];
  final bottom = h * 0.5;
  final body = smoothPath(pts)
    ..lineTo(w * 1.1, bottom)
    ..lineTo(-w * 0.1, bottom)
    ..close();
  c.drawPath(body, _fill(color));
  c
    ..save()
    ..clipPath(body);
  for (final (px, ph, sg) in pk) {
    final top = Offset(px * w, base * h - ph * h);
    final sp = <Offset>[
      for (var x = top.dx; x <= top.dx + sg * w * 2.2; x += 5) Offset(x, yAt(x)),
    ];
    final poly = smoothPath([top - const Offset(0, 4), ...sp, Offset(sp.last.dx, bottom), Offset(top.dx + sg * w * 0.5, bottom)], closed: true);
    c.drawPath(poly, _fill(shade));
  }
  c.restore();
}

void _mountains(Canvas c, Size s) {
  _peaks(c, s, 0.3, const [(0.48, 0.105, 0.2), (0.86, 0.125, 0.16), (0.05, 0.05, 0.14)], const Color(0xFFE9BBA2), const Color(0xFFDDA898));
  _peaks(c, s, 0.325, const [(0.3, 0.07, 0.17), (0.68, 0.085, 0.15), (1.02, 0.07, 0.12)], const Color(0xFFC895A3), const Color(0xFFB98AA0));
}

void _row(Canvas c, Size s, {required double y, required double amp, required int seed, required double hLo, required double hHi, required double haze, required Color ground, double pine = 0.1, double tall = 0.14, double bare = 0.04, double skipA = -1, double skipB = -1, Color? rim, void Function()? behind}) {
  final h = s.height, w = s.width;
  final r = rng(seed);
  final ridge = Ridge(s, y: y, amp: amp, freq: 3, seed: seed);
  final trunk = hazeTo(_trunk, _haze, haze);
  var x = -w * 0.06;
  while (x < w * 1.06) {
    final th = h * (hLo + r.nextDouble() * (hHi - hLo));
    final p = r.nextDouble();
    final base = Offset(x, ridge.yAt(x) + th * 0.07);
    final skip = x > skipA * w && x < skipB * w;
    if (!skip) {
      if (p < pine) {
        final g = _tGreen.haze(haze);
        flatPine(c, base, th * 1.12, color: g.mid, shade: g.shade, trunk: trunk, tiers: 3, width: 0.42);
      } else if (p < pine + bare) {
        _bareTree(c, base, th * 1.1, hazeTo(const Color(0xFF6B3A2E), _haze, haze), r.nextInt(999));
      } else {
        final t = _mix[r.nextInt(_mix.length)].haze(haze);
        _tree(c, base, th, t, trunk, seed: r.nextInt(9999), lean: (r.nextDouble() - 0.5) * 0.3, kind: p < pine + bare + tall ? _Kind.tall : _Kind.round);
      }
    }
    x += th * (0.4 + r.nextDouble() * 0.28);
  }
  behind?.call();
  flatRidge(c, ridge, ground, light: rim, band: 2.5);
}

const _cabinX = 0.745;

void _hillsFar(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _row(c, s, y: 0.3, amp: 0.008, seed: 41, hLo: 0.042, hHi: 0.06, haze: 0.58, ground: hazeTo(const Color(0xFFD8894F), _haze, 0.55), pine: 0.08, tall: 0.07);
  final r1 = Ridge(s, y: 0.335, amp: 0.008, freq: 3, seed: 42);
  _row(c, s, y: 0.335, amp: 0.008, seed: 42, hLo: 0.05, hHi: 0.07, haze: 0.42, ground: hazeTo(const Color(0xFFCF7A45), _haze, 0.4), skipA: _cabinX - 0.09, skipB: _cabinX + 0.09, behind: () {
    _cabin(c, Offset(_cabinX * w, r1.yAt(_cabinX * w) + 5), w * 0.17);
    final g = _tGreen.haze(0.4);
    for (final (dx, hh) in [(-0.07, 0.062), (0.075, 0.055), (0.095, 0.045)]) {
      flatPine(c, Offset((_cabinX + dx) * w, r1.yAt((_cabinX + dx) * w) + 4), h * hh, color: g.mid, shade: g.shade, trunk: _trunk, tiers: 3, width: 0.42);
    }
  });
}

void _cabin(Canvas c, Offset base, double w) {
  const wall = Color(0xFFA85A3C), wallS = Color(0xFF8A4630), roof = Color(0xFFC44A30), roofS = Color(0xFFA23926);
  final bw = w * 0.5, bh = w * 0.3;
  final body = RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - bw / 2, base.dy - bh, bw, bh), Radius.circular(w * 0.02));
  // chimney
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + bw * 0.16, base.dy - bh - w * 0.3, w * 0.07, w * 0.26), Radius.circular(w * 0.01)), _fill(const Color(0xFF7A4034)));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + bw * 0.16, base.dy - bh - w * 0.32, w * 0.07, w * 0.04), Radius.circular(w * 0.01)), _fill(const Color(0xFF5A2E22)));
  c.drawRRect(body, _fill(wall));
  c
    ..save()
    ..clipRRect(body)
    ..drawRect(Rect.fromLTWH(base.dx + bw * 0.1, base.dy - bh, bw, bh), _fill(wallS))
    ..restore();
  // window (flat warm glow) + door
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - bw * 0.32, base.dy - bh * 0.78, bw * 0.2, bw * 0.17), Radius.circular(w * 0.012)), _fill(_gold));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + bw * 0.02, base.dy - bh * 0.7, bw * 0.17, bh * 0.7), Radius.circular(w * 0.015)), _fill(const Color(0xFF5A2E22)));
  // roof: rounded gable, flat half shade
  final ov = w * 0.05;
  final rp = Path()
    ..moveTo(base.dx - bw / 2 - ov, base.dy - bh + w * 0.015)
    ..quadraticBezierTo(base.dx - bw * 0.3, base.dy - bh - w * 0.1, base.dx - w * 0.02, base.dy - bh - w * 0.22)
    ..quadraticBezierTo(base.dx, base.dy - bh - w * 0.245, base.dx + w * 0.02, base.dy - bh - w * 0.22)
    ..quadraticBezierTo(base.dx + bw * 0.3, base.dy - bh - w * 0.1, base.dx + bw / 2 + ov, base.dy - bh + w * 0.015)
    ..quadraticBezierTo(base.dx + bw / 2 + ov + w * 0.01, base.dy - bh + w * 0.04, base.dx + bw / 2 + ov - w * 0.03, base.dy - bh + w * 0.04)
    ..lineTo(base.dx - bw / 2 - ov + w * 0.03, base.dy - bh + w * 0.04)
    ..quadraticBezierTo(base.dx - bw / 2 - ov - w * 0.01, base.dy - bh + w * 0.04, base.dx - bw / 2 - ov, base.dy - bh + w * 0.015)
    ..close();
  c.drawPath(rp, _fill(roof));
  c
    ..save()
    ..clipPath(rp)
    ..drawRect(Rect.fromLTWH(base.dx + w * 0.01, base.dy - bh - w * 0.3, bw, w * 0.4), _fill(roofS))
    ..restore();
}

void _mist(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(9);
  for (var i = 0; i < 6; i++) {
    final x = (i + r.nextDouble() * 0.6) * w / 6;
    final y = h * (0.335 + r.nextDouble() * 0.05);
    final mw = w * (0.3 + r.nextDouble() * 0.25), mh = h * (0.014 + r.nextDouble() * 0.01);
    for (final dx in [0.0, -w]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + dx, y), width: mw, height: mh), Radius.circular(mh / 2)), _fill(const Color(0xFFFFE6BA).withValues(alpha: 0.38)));
    }
  }
}

void _hillsNear(Canvas c, Size s) {
  _row(c, s, y: 0.375, amp: 0.009, seed: 43, hLo: 0.062, hHi: 0.085, haze: 0.26, ground: hazeTo(const Color(0xFFBE6440), _haze, 0.22), bare: 0.06, pine: 0.1, tall: 0.07, skipA: _cabinX - 0.09, skipB: _cabinX + 0.09);
  _row(c, s, y: 0.425, amp: 0.01, seed: 44, hLo: 0.075, hHi: 0.1, haze: 0.1, ground: const Color(0xFFA9503A), bare: 0.05, pine: 0.1, tall: 0.08, skipA: _cabinX - 0.1, skipB: _cabinX + 0.1);
}

// ---------------------------------------------------------------- river

class _River {
  _River(Size s) {
    final w = s.width, h = s.height;
    final ctrl = <Offset>[
      Offset(w * 1.12, h * 0.475), Offset(w * 0.82, h * 0.485), Offset(w * 0.56, h * 0.51), Offset(w * 0.37, h * 0.56), Offset(w * 0.34, h * 0.62),
      Offset(w * 0.5, h * 0.67), Offset(w * 0.68, h * 0.74), Offset(w * 0.62, h * 0.83), Offset(w * 0.45, h * 0.91), Offset(w * 0.42, h * 1.0), Offset(w * 0.45, h * 1.14),
    ];
    final path = smoothPath(ctrl);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        final t = m.getTangentForOffset(d)!;
        final y = t.position.dy / h;
        final hwv = w * (0.012 + 0.17 * math.pow(((y - 0.47) / 0.68).clamp(0.0, 1.2), 1.7));
        final n = Offset(-t.vector.dy, t.vector.dx);
        c.add(t.position);
        hw.add(hwv);
        nrm.add(n);
      }
    }
  }
  final c = <Offset>[], nrm = <Offset>[];
  final hw = <double>[];

  static final Map<Size, _River> _cache = {};
  static _River of(Size s) => _cache.putIfAbsent(s, () => _River(s));

  List<Offset> edge(double sign, [double scale = 1, double extra = 0]) => [for (var i = 0; i < c.length; i++) c[i] + nrm[i] * (sign * (hw[i] * scale + extra))];

  Path ribbon([double scale = 1, double extra = 0]) => smoothPath([...edge(1, scale, extra), ...edge(-1, scale, extra).reversed], closed: true);
}

void _valley(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // golden valley floor, two tiers
  final f1 = Ridge(s, y: 0.455, amp: 0.012, freq: 1.6, seed: 61);
  flatRidge(c, f1, const Color(0xFFE2A445), light: const Color(0xFFF3C766), band: 3);
  final f2 = Ridge(s, y: 0.66, amp: 0.018, freq: 1.3, seed: 62, tilt: -0.03);
  flatRidge(c, f2, const Color(0xFFD58A38), light: const Color(0xFFEBA853), band: 3);
  final rg = rng(17);
  // grass dashes and fallen leaves scattered on the meadow
  for (var i = 0; i < 60; i++) {
    final x = rg.nextDouble() * w, y = h * (0.45 + rg.nextDouble() * 0.45);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 9 + rg.nextDouble() * 8, height: 2.2), const Radius.circular(1.2)), _fill(y < f2.yAt(x) ? const Color(0xFFC8872F) : const Color(0xFFBE7430)));
  }
  for (var i = 0; i < 40; i++) {
    final i5 = rg.nextInt(5);
    _leaf(c, Offset(rg.nextDouble() * w, h * (0.46 + rg.nextDouble() * 0.45)), 3.5 + rg.nextDouble() * 2.5, rg.nextDouble() * tau, _leafCols[i5], _leafShade[i5]);
  }

  // far bank trees along the river
  final rv = _River.of(s);
  for (var i = 0; i < rv.c.length; i += 9) {
    final y = rv.c[i].dy / h;
    if (y < 0.45 || y > 0.72) continue;
    for (final sd in [-1.0, 1.0]) {
      final o = rv.c[i] + rv.nrm[i] * (sd * (rv.hw[i] + 18 + rg.nextDouble() * 10));
      if (o.dx < w * 0.12 || o.dx > w * 0.9) continue;
      final th = h * (0.06 + 0.06 * (y - 0.4));
      _tree(c, o, th, _mix[rg.nextInt(_mix.length)], _trunk, seed: rg.nextInt(999), lean: sd * 0.3);
    }
  }

  // river: bank lip, water, mirrored canopy
  c.drawPath(rv.ribbon(1, 3), _fill(const Color(0xFFF1C56E)));
  final rp = rv.ribbon();
  c.drawPath(rp, _fill(_water));
  c
    ..save()
    ..clipPath(rp);
  // pale sky mirrored down the middle
  c.drawPath(
    smoothPath(rv.c),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.05
      ..color = _waterSky,
  );
  const refl = [Color(0xFFE2683F), Color(0xFFF08A3A), Color(0xFFF6B445), Color(0xFFD5502F), Color(0xFFFFCC66)];
  for (var i = 0; i < rv.c.length; i += 3) {
    final o = rv.c[i];
    final hw = rv.hw[i];
    if (hw < 5) continue;
    for (final sd in [-1.0, 1.0]) {
      final ci = (i ~/ 7 + (sd > 0 ? 2 : 0)) % refl.length;
      final p = o + rv.nrm[i] * (sd * hw * (0.55 + 0.3 * rg.nextDouble()));
      final len = hw * (0.25 + 0.75 * rg.nextDouble());
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p + Offset(0, len * 0.5), width: 3.5 + hw * 0.04, height: len * 1.7), const Radius.circular(4)), _fill(mix(_water, refl[ci], 0.78)));
    }
  }
  c.restore();
}

// ---------------------------------------------------------------- live (river glints, smoke, back leaves)

void _midLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, k0 = w / 390;
  final rv = _River.of(s);
  // river glints
  final r = rng(23);
  for (var i = 0; i < 30; i++) {
    final idx = (rv.c.length * (0.3 + 0.7 * r.nextDouble())).floor().clamp(0, rv.c.length - 1);
    final o = rv.c[idx] + rv.nrm[idx] * ((r.nextDouble() - 0.5) * 1.3 * rv.hw[idx]);
    final len = (5 + rv.hw[idx] * (0.25 + r.nextDouble() * 0.35));
    final ph = r.nextDouble();
    final a = math.pow(k.pulse(6 + i % 5, ph), 3).toDouble();
    if (a < 0.04) continue;
    final dx = k.sine(3 + i % 3, ph) * 3 * k0;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(dx, 0), width: len, height: 2.2 * k0), const Radius.circular(1.1)), _fill(const Color(0xFFFFF6DC).withValues(alpha: 0.85 * a)));
  }

  // chimney smoke (follows the drift + sway of the far hills layer)
  final sk = k.sine(2, 0.05);
  final dxl = 0.008 * w * sk;
  final by = h * 0.0 + 0.03 * h + 0.004 * 0.5 * h;
  final ground = h + by;
  final cabinY = h * 0.335;
  final shear = math.tan(0.003 * k.sine(5)) * (ground - cabinY);
  final cw = w * 0.17;
  final chim = Offset(_cabinX * w + cw * 0.5 * 0.16 + cw * 0.035 + dxl + shear, cabinY + 5 - cw * 0.62);
  for (var i = 0; i < 6; i++) {
    final t = k.saw(6, i / 6);
    final o = chim + Offset(math.sin(tau * (t * 1.5 + i * 0.1)) * 3 * k0 + t * 26 * k0, -t * h * 0.075);
    final rad = (2.6 + t * 5.2) * k0;
    c.drawCircle(o, rad, _fill(const Color(0xFFFFF1D6).withValues(alpha: 0.85 * math.min(1.0, (1 - t) * 1.6) * math.min(1.0, t * 8))));
  }

  // sunlit motes
  paintParticles(c, s, k, const ParticleSpec(count: 18, seed: 31, colors: [Color(0xFFFFE9A8), Color(0xFFFFF6DC)], minSize: 1.0, maxSize: 1.9, flow: Offset(0.05, -0.12), cycles: 2, spread: 2, wander: 12, twinkle: 0.5, shape: ParticleShape.dot, region: Rect.fromLTRB(0.0, 0.25, 1.0, 0.95), opacity: 0.8));

  _fall(c, s, k, seed: 71, count: 15, minS: 2.6, maxS: 4.0, cyc0: 2, spread: 1, alphaMax: 0.7, haze: 0.4, maple: false);
  _fall(c, s, k, seed: 72, count: 13, minS: 4.4, maxS: 6.4, cyc0: 3, spread: 2, alphaMax: 0.95, haze: 0.12, maple: false);
}

void _leavesFront(Canvas c, Size s, Clock k) {
  _fall(c, s, k, seed: 73, count: 7, minS: 9.0, maxS: 13.0, cyc0: 4, spread: 2, alphaMax: 1.0, haze: 0.0, maple: true);
}

void _fall(Canvas c, Size s, Clock k, {required int seed, required int count, required double minS, required double maxS, required int cyc0, required int spread, required double alphaMax, required double haze, required bool maple}) {
  final w = s.width, h = s.height, k0 = w / 390;
  final r = rng(seed);
  final fill = Paint();
  for (var i = 0; i < count; i++) {
    final x0 = r.nextDouble(), ph = r.nextDouble();
    final size = (minS + r.nextDouble() * (maxS - minS)) * k0;
    final ci = r.nextInt(_leafCols.length);
    final fc = cyc0 + i % (spread + 1);
    final lap = k.saw(fc, ph);
    final fx = x0 + 0.16 * lap;
    final px = (-0.05 + 1.1 * (fx - fx.floorToDouble())) * w;
    final py = (-0.06 + 1.12 * lap) * h;
    final swc = fc * 3 + i % 3;
    final ang = tau * (k.u * swc + ph * 3);
    final x = px + math.sin(ang) * (12 + size * 1.6);
    final rot = math.cos(ang) * 0.9 + 0.5 + (maple ? i : 0);
    final flip = 0.35 + 0.65 * math.cos(tau * (k.u * (fc * 2 + 1 + i % 2) + ph * 5)).abs();
    final a = alphaMax * math.min(1.0, math.min(lap / 0.06, (1 - lap) / 0.06));
    if (a <= 0.02) continue;
    final col = hazeTo(_leafCols[ci], _haze, haze), shade = hazeTo(_leafShade[ci], _haze, haze);
    c
      ..save()
      ..translate(x, py)
      ..rotate(rot)
      ..scale(size, size * flip);
    if (maple) {
      fill.color = col.withValues(alpha: a);
      c.drawPath(_mapleP, fill);
      fill.color = shade.withValues(alpha: a);
      c
        ..save()
        ..clipRect(const Rect.fromLTRB(0, -2, 2, 2))
        ..drawPath(_mapleP, fill)
        ..restore();
    } else {
      fill.color = col.withValues(alpha: a);
      c.drawPath(_leafP, fill);
      fill.color = shade.withValues(alpha: a);
      c.drawPath(_leafH, fill);
    }
    c.restore();
  }
}

// ---------------------------------------------------------------- foreground

void _foreground(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final rv = _River.of(s);
  // indices of the river part that is in the foreground
  final i0 = rv.c.indexWhere((p) => p.dy > h * 0.755);
  final sideA = <Offset>[], sideB = <Offset>[];
  final ea = rv.edge(1, 1, 5), eb = rv.edge(-1, 1, 5);
  for (var i = i0; i < rv.c.length; i++) {
    sideA.add(ea[i]);
    sideB.add(eb[i]);
  }
  // decide which edge is on screen-left
  final aLeft = sideA.last.dx < sideB.last.dx;
  final left = aLeft ? sideA : sideB, right = aLeft ? sideB : sideA;

  final lp = smoothPath([Offset(-w * 0.2, h * 0.79), Offset(w * 0.1, h * 0.775), ...left, Offset(left.last.dx, h * 1.12), Offset(-w * 0.2, h * 1.12)], closed: true);
  final rp = smoothPath([Offset(w * 1.2, h * 0.79), Offset(w * 0.9, h * 0.77), ...right, Offset(right.last.dx, h * 1.12), Offset(w * 1.2, h * 1.12)], closed: true);
  const ground = Color(0xFFA9503A), rim = Color(0xFFD9803F);
  for (final p in [lp, rp]) {
    c.drawPath(p, _fill(rim));
    c
      ..save()
      ..clipPath(p)
      ..drawPath(p.shift(const Offset(0, 4)), _fill(ground))
      ..restore();
  }
  _crown(c, Offset(w * 0.02, h * 1.0), w * 0.2, _tRust, 14, n: 7);

  // leaf carpet
  final r = rng(33);
  void scatter(Path area, Rect box, int n, double lo, double hi) {
    var placed = 0, tries = 0;
    while (placed < n && tries < n * 8) {
      tries++;
      final o = Offset(box.left + r.nextDouble() * box.width, box.top + r.nextDouble() * box.height);
      if (!area.contains(o)) continue;
      placed++;
      final ci = r.nextInt(5);
      _leaf(c, o, lo + r.nextDouble() * (hi - lo), r.nextDouble() * tau, _leafCols[ci], _leafShade[ci]);
    }
  }

  scatter(lp, Rect.fromLTRB(-w * 0.1, h * 0.8, w * 0.5, h * 1.02), 60, 5, 9);
  scatter(rp, Rect.fromLTRB(w * 0.5, h * 0.8, w * 1.1, h * 1.02), 60, 5, 9);
  
  // fence on the left bank
  final post = _fill(const Color(0xFF6E3C2B)), postS = _fill(const Color(0xFF53291E));
  final fy = h * 0.855;
  for (final (x, dy) in [(0.02, 0.0), (0.1, -0.004), (0.18, -0.006), (0.26, -0.004)]) {
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x * w, fy + dy * h, 9, h * 0.05), const Radius.circular(3));
    c.drawRRect(rr, post);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x * w + 5, fy + dy * h + 2, 4, h * 0.05 - 2), const Radius.circular(2)), postS);
  }
  for (final yy in [fy + 7, fy + 21]) {
    final rail = Path()
      ..moveTo(w * 0.02, yy)
      ..quadraticBezierTo(w * 0.15, yy - 4, w * 0.29, yy - 1)
      ..lineTo(w * 0.29, yy + 5)
      ..quadraticBezierTo(w * 0.15, yy + 1, w * 0.02, yy + 6)
      ..close();
    c.drawPath(rail, _fill(const Color(0xFF82492F)));
  }

  // pumpkins by the fence
  _pumpkin(c, Offset(w * 0.34, h * 0.915), w * 0.07);
  _pumpkin(c, Offset(w * 0.27, h * 0.935), w * 0.045);

  // red bush on the right
  _crown(c, Offset(w * 0.93, h * 0.905), w * 0.09, _tRed, 5, n: 6);
  _crown(c, Offset(w * 0.84, h * 0.925), w * 0.06, _tOrange, 6, n: 5);

  // stepping stones in the river
  for (final (x, y, sw) in [(0.46, 0.925, 0.07), (0.41, 0.955, 0.05), (0.5, 0.97, 0.06)]) {
    final o = Offset(w * x, h * y);
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, 3), width: w * sw * 1.5, height: w * sw * 0.45), _fill(const Color(0xFFFFE1B0).withValues(alpha: 0.9)));
    c.drawOval(Rect.fromCenter(center: o, width: w * sw, height: w * sw * 0.42), _fill(const Color(0xFF8E6A62)));
    c.drawOval(Rect.fromCenter(center: o + Offset(-w * sw * 0.08, -w * sw * 0.05), width: w * sw * 0.7, height: w * sw * 0.26), _fill(const Color(0xFFB08A80)));
  }
}

void _pumpkin(Canvas c, Offset o, double w) {
  final hh = w * 0.78;
  c.drawOval(Rect.fromCenter(center: o, width: w, height: hh), _fill(const Color(0xFFD96E1C)));
  c.drawOval(Rect.fromCenter(center: o + Offset(-w * 0.1, 0), width: w * 0.72, height: hh), _fill(const Color(0xFFF28A2E)));
  c.drawOval(Rect.fromCenter(center: o + Offset(-w * 0.22, -hh * 0.02), width: w * 0.34, height: hh * 0.96), _fill(const Color(0xFFF9A24A)));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(w * 0.02, -hh * 0.52), width: w * 0.12, height: hh * 0.24), Radius.circular(w * 0.04)), _fill(const Color(0xFF5A2E22)));
}

// ---------------------------------------------------------------- hero: the giant maple

void _hero(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final pts = [Offset(w * 0.97, h * 1.1), Offset(w * 0.965, h * 0.88), Offset(w * 0.98, h * 0.55), Offset(w * 0.965, h * 0.3), Offset(w * 0.91, h * 0.15), Offset(w * 0.85, h * 0.085)];
  final hws = [w * 0.2, w * 0.07, w * 0.052, w * 0.04, w * 0.032, w * 0.024];
  final left = <Offset>[], right = <Offset>[], mid = <Offset>[];
  for (var i = 0; i < pts.length; i++) {
    final a = pts[math.max(i - 1, 0)], b = pts[math.min(i + 1, pts.length - 1)];
    var d = b - a;
    d = d / d.distance;
    final n = Offset(-d.dy, d.dx);
    left.add(pts[i] + n * hws[i]);
    right.add(pts[i] - n * hws[i]);
    mid.add(pts[i]);
  }
  // left edge has smaller x
  final l = left.first.dx < right.first.dx ? left : right, rr = left.first.dx < right.first.dx ? right : left;

  // side branch toward the sun
  final br = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = _trunk;
  br.strokeWidth = w * 0.035;
  c.drawPath(
    Path()
      ..moveTo(w * 0.95, h * 0.2)
      ..quadraticBezierTo(w * 0.78, h * 0.16, w * 0.62, h * 0.085),
    br,
  );
  br.strokeWidth = w * 0.022;
  c.drawPath(
    Path()
      ..moveTo(w * 0.7, h * 0.13)
      ..quadraticBezierTo(w * 0.6, h * 0.14, w * 0.5, h * 0.12),
    br,
  );

  final body = smoothPath([...l, ...rr.reversed], closed: true);
  c.drawPath(body, _fill(_trunk));
  final shadeSide = smoothPath([...mid, ...rr.reversed], closed: true);
  c
    ..save()
    ..clipPath(body)
    ..drawPath(shadeSide, _fill(_trunkShade));
  final litEdge = smoothPath([...l, ...[for (var i = l.length - 1; i >= 0; i--) Offset.lerp(l[i], mid[i], 0.5)!]], closed: true);
  c.drawPath(litEdge, _fill(const Color(0xFF74402F)));
  // flat bark slivers on the lit side
  final rg = rng(8);
  for (var i = 0; i < 10; i++) {
    final y = h * (0.3 + rg.nextDouble() * 0.68);
    final t = (y / h - 0.3) / 0.7;
    final x = _lerp(w * 0.925, w * 0.9, t) - rg.nextDouble() * w * 0.03;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 3.5, height: 22 + rg.nextDouble() * 26), const Radius.circular(2)), _fill(const Color(0xFF7A4332)));
  }
  c.restore();
  // crown, back to front
  _crown(c, Offset(w * 0.98, h * 0.06), w * 0.17, _tOrange, 31, n: 7);
  _crown(c, Offset(w * 0.9, h * 0.145), w * 0.12, _tRust, 32, n: 6);
  _crown(c, Offset(w * 0.6, h * 0.075), w * 0.12, _tAmber, 33, n: 6);
  _crown(c, Offset(w * 0.78, h * 0.04), w * 0.19, _tRed, 34, n: 8);
  _crown(c, Offset(w * 0.66, h * 0.14), w * 0.085, _tGold, 35, n: 6);
  _crown(c, Offset(w * 0.52, h * 0.115), w * 0.075, _tOrange, 36, n: 5);
  _crown(c, Offset(w * 0.8, h * 0.115), w * 0.09, _tOrange, 37, n: 6);
  // tiny leaf flecks scattered on the crown
  final fr = rng(12);
  for (var i = 0; i < 26; i++) {
    final o = Offset(w * (0.5 + fr.nextDouble() * 0.55), h * (-0.02 + fr.nextDouble() * 0.2));
    final ci = fr.nextInt(5);
    _leaf(c, o, 4.5 + fr.nextDouble() * 3, fr.nextDouble() * tau, ci == 4 ? _gold : _leafCols[(ci + 2) % 4], _leafShade[(ci + 2) % 4]);
  }
}
