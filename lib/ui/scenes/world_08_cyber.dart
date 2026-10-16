import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Neon Cyber City in flat, graphic 2D: a rainy violet dusk, a big striped
// hologram sun behind four planes of skyscrapers, sky bridges with moving
// lights, flying cars on lanes, blinking windows, a warm noodle kiosk and a
// wet street that mirrors the neon. Flat colours, hard two-tone shading.

// palette
const _sky0 = Color(0xFF0B0830), _sky1 = Color(0xFF2A0F5E), _sky2 = Color(0xFF7A1FA0), _sky3 = Color(0xFFFF3DB8);
const _cyan = Color(0xFF19F3FF), _mag = Color(0xFFFF2BD6), _vio = Color(0xFF8A5BFF), _blue = Color(0xFF3A6BFF);
const _win = Color(0xFFFFE9A8), _fog = Color(0xFF5A2A9A);
const _ink = Color(0xFF0E0724), _road = Color(0xFF170B3D), _warm = Color(0xFFFFB35C);
const _neons = [_cyan, _mag, _vio, _blue, _cyan, _mag];

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _kk(Size s) => s.width / 390;

// ---------------------------------------------------------------- layers

SceneSpec cyberScene() => SceneSpec(
      focusY: -0.3,
      topShade: 0.12,
      bottomShade: 0.2,
      layers: [
        Layer.still(_sky),
        Layer.live(_skyLive),
        Layer.still((c, s) => _paintPlane(c, s, 0), driftX: 0.004, driftCycles: 2, driftPhase: 0),
        Layer.scroll(_fogFar, scrollCycles: 1, bandTop: 0.46, bandBottom: 0.72),
        Layer.still((c, s) => _paintPlane(c, s, 1), driftX: 0.008, driftCycles: 2, driftPhase: 0.03),
        Layer.live(_vehiclesBack),
        Layer.scroll(_fogNear, scrollCycles: 2, bandTop: 0.62, bandBottom: 0.9),
        Layer.still((c, s) => _paintPlane(c, s, 2), driftX: 0.013, driftCycles: 2, driftPhase: 0.06),
        Layer.still(_street, driftX: 0.013, driftCycles: 2, driftPhase: 0.06),
        Layer.still((c, s) => _paintPlane(c, s, 3), driftX: 0.02, driftCycles: 2, driftPhase: 0.1),
        Layer.live(_cityLife),
        Layer.still(_foreground, driftX: 0.03, driftCycles: 2, driftPhase: 0.15),
        Layer.live(_foreLife),
      ],
    );

// ---------------------------------------------------------------- sky + hero

const _sunC = Offset(0.66, 0.235);
const _sunR = 0.145; // of width

void _sky(Canvas c, Size s) {
  final w = s.width, h = s.height, k = _kk(s);
  fillSky(c, s, const [_sky0, _sky1, _sky2, _sky3, Color(0xFFB02296)], const [0.0, 0.26, 0.46, 0.64, 1.0]);
  final o = Offset(_sunC.dx * w, _sunC.dy * h);
  final r = _sunR * w;
  // flat translucent halo rings
  c.drawCircle(o, r * 2.1, Paint()..color = _mag.withValues(alpha: 0.07));
  c.drawCircle(o, r * 1.5, Paint()..color = _mag.withValues(alpha: 0.12));
  // the hologram sun: a disc cut by growing horizontal gaps
  final strips = Path();
  var y = o.dy - r;
  var gap = 0.0;
  var band = r * 0.55;
  while (y < o.dy + r) {
    final bot = math.min(y + band, o.dy + r);
    strips.addRect(Rect.fromLTRB(o.dx - r - 2, y, o.dx + r + 2, bot));
    y = bot;
    if (y > o.dy - r * 0.05) {
      gap += r * 0.035;
      y += gap;
      band = math.max(r * 0.16, band * 0.72);
    }
  }
  c.save();
  c.clipPath(strips);
  c.drawCircle(o, r, Paint()..color = const Color(0xFFFF4FC2));
  // lit upper-left crescent in a lighter flat tone
  c.save();
  c.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: r)));
  c.drawCircle(o + Offset(r * 0.2, r * 0.26), r, Paint()..color = const Color(0xFFFF2FB0));
  c.restore();
  c.restore();
  // faint concentric ring + tick marks
  c.drawCircle(o, r * 1.32, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2 * k
    ..color = _cyan.withValues(alpha: 0.35));
  final tp = Paint()..color = _cyan.withValues(alpha: 0.5);
  for (var i = 0; i < 48; i++) {
    final a = tau * i / 48;
    final l = (i % 4 == 0 ? 6.0 : 3.0) * k;
    final p0 = o + Offset(math.cos(a), math.sin(a)) * (r * 1.4);
    final p1 = o + Offset(math.cos(a), math.sin(a)) * (r * 1.4 + l);
    c.drawLine(p0, p1, tp..strokeWidth = 1 * k);
  }
}

void _skyLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, kk = _kk(s);
  paintStars(c, s, k, count: 46, seed: 9, region: const Rect.fromLTRB(0, 0.0, 1, 0.38), color: const Color(0xFFE8DCFF), minR: 0.5, maxR: 1.5, twinkleCycles: 10, sparkleShare: 0.1);
  // rotating dashed hologram ring (tilted ellipse) in front of the sun
  final o = Offset(_sunC.dx * w, _sunC.dy * h);
  final r = _sunR * w;
  const n = 18;
  final rot = k.saw(2) * tau / n;
  final tilt = -0.28;
  final ct = math.cos(tilt), st = math.sin(tilt);
  final rx = r * 1.95, ry = r * 0.5;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.4 * kk
    ..color = _cyan.withValues(alpha: 0.8);
  for (var i = 0; i < n; i++) {
    final a0 = tau * i / n + rot;
    final a1 = a0 + tau / n * 0.55;
    final path = Path();
    for (var j = 0; j <= 4; j++) {
      final a = _lerp(a0, a1, j / 4);
      final ex = math.cos(a) * rx, ey = math.sin(a) * ry;
      final pt = Offset(o.dx + ex * ct - ey * st, o.dy + ex * st + ey * ct);
      if (j == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    // dashes on the far (upper) half are dimmer
    final far = math.sin((a0 + a1) / 2) < 0;
    p.color = _cyan.withValues(alpha: far ? 0.35 : 0.85);
    c.drawPath(path, p);
  }
}

// ---------------------------------------------------------------- skyline model

class _Spec {
  const _Spec(this.seed, this.base, this.cTop, this.eTop, this.minW, this.maxW, this.color, this.shade, this.winP, this.px, this.py, this.neonP, this.neonA, this.lit);
  final int seed;
  final double base, cTop, eTop, minW, maxW;
  final Color color, shade;
  final double winP, px, py, neonP, neonA;
  final Color lit;
}

const _specs = [
  _Spec(3, 0.66, 0.50, 0.40, 24, 44, Color(0xFF5A2A9A), Color(0xFF4B2287), 0.10, 6, 8, 0.0, 0.0, Color(0xFFFFC2EC)),
  _Spec(11, 0.755, 0.47, 0.31, 32, 56, Color(0xFF3B1A78), Color(0xFF301565), 0.17, 8, 10, 0.3, 0.55, Color(0xFFFFD2A0)),
  _Spec(23, 0.87, 0.53, 0.17, 40, 68, Color(0xFF231257), Color(0xFF1A0D45), 0.26, 9, 11, 0.75, 0.95, _win),
  _Spec(0, 0.885, 0.5, 0.2, 40, 60, Color(0xFF140A33), Color(0xFF0D0623), 0.2, 11, 13, 1.0, 1.0, _win),
];
const _drift = [0.004, 0.008, 0.013, 0.02];
const _driftPh = [0.0, 0.03, 0.06, 0.1];

class _Tier {
  _Tier(this.x0, this.x1, this.top, this.roof);
  final double x0, x1, top;
  final int roof;
  double get w => x1 - x0;
}

class _Win {
  _Win(this.rect, this.col, this.cyc, this.ph);
  final Rect rect;
  final Color col;
  final int cyc;
  final double ph;
}

class _Neon {
  _Neon(this.rect, this.col, this.band);
  final Rect rect;
  final Color col;
  final bool band;
}

class _Bld {
  final tiers = <_Tier>[];
  final lit = <Rect>[];
  final litCol = <Color>[];
  final dim = <Rect>[];
  final neons = <_Neon>[];
  Color? edge;
  double? spireX, spireTop;
}

class _Bridge {
  _Bridge(this.x0, this.x1, this.y);
  final double x0, x1, y;
}

class _PlaneData {
  final blds = <_Bld>[];
  final blinks = <_Win>[];
  final beacons = <Offset>[];
  final bridges = <_Bridge>[];
}

final Map<String, _PlaneData> _cache = {};

_PlaneData _plane(int pi, Size s) => _cache.putIfAbsent('$pi:${s.width.round()}x${s.height.round()}', () => _build(pi, s));

_PlaneData _build(int pi, Size s) {
  final sp = _specs[pi];
  final w = s.width, h = s.height, k = _kk(s);
  final r = rng(sp.seed + 5);
  final d = _PlaneData();
  final base = sp.base * h;

  // list of (x0, x1, top, roof, upperInset, upperRise, spire)
  final defs = <List<double>>[];
  if (pi == 3) {
    defs.addAll([
      [-0.06, 0.15, 0.17, 0, 0.30, 0.055, 1],
      [0.15, 0.245, 0.35, 1, 0, 0, 0],
      [0.245, 0.30, 0.55, 0, 0, 0, 0],
      [0.84, 1.07, 0.21, 3, 0.26, 0.06, 0],
      [0.745, 0.845, 0.41, 0, 0, 0, 0],
      [0.70, 0.745, 0.58, 2, 0, 0, 0],
    ]);
  } else {
    var x = -0.07 * w;
    while (x < 1.07 * w) {
      final bw = _lerp(sp.minW, sp.maxW, r.nextDouble()) * k;
      final xc = (x + bw / 2) / w;
      final edge = ((xc - 0.5).abs() * 2).clamp(0.0, 1.0);
      final tf = _lerp(sp.cTop, sp.eTop, math.pow(edge, 1.15) * (0.45 + 0.55 * r.nextDouble())) + (r.nextDouble() - 0.5) * 0.03;
      final u = r.nextDouble();
      final roof = u < 0.28 ? 0 : (u < 0.43 ? 1 : (u < 0.58 ? 2 : (u < 0.78 ? 3 : 4)));
      final tiered = r.nextDouble() < 0.45;
      defs.add([x / w, (x + bw) / w, tf, roof.toDouble(), tiered ? 0.16 + r.nextDouble() * 0.14 : 0, 0.03 + r.nextDouble() * 0.045, r.nextDouble() < 0.3 ? 1 : 0]);
      x += bw * 0.97;
    }
  }

  for (final df in defs) {
    final b = _Bld();
    final x0 = df[0] * w, x1 = df[1] * w, top = df[2] * h;
    final t0 = _Tier(x0, x1, top, df[3].toInt());
    b.tiers.add(t0);
    var topTier = t0;
    if (df[4] > 0) {
      final t1 = _Tier(x0 + (x1 - x0) * df[4], x1 - (x1 - x0) * df[4], top - df[5] * h, (df[3].toInt() + 2) % 5);
      b.tiers.add(t1);
      topTier = t1;
    }
    if (df[6] > 0) {
      b.spireX = (topTier.x0 + topTier.x1) / 2;
      b.spireTop = topTier.top - h * (0.035 + r.nextDouble() * 0.03);
      d.beacons.add(Offset(b.spireX!, b.spireTop!));
    }
    // neon accents
    final ef = pi == 3 ? 1.0 : (0.3 + 0.7 * ((x0 + x1) / 2 / w - 0.5).abs() * 2).clamp(0.0, 1.0);
    if (r.nextDouble() < sp.neonP * ef) {
      final col = _neons[r.nextInt(_neons.length)];
      b.edge = col;
      if (r.nextDouble() < 0.55) {
        final tx = x0 + (x1 - x0) * (0.55 + r.nextDouble() * 0.25);
        final len = h * (0.05 + r.nextDouble() * 0.12);
        b.neons.add(_Neon(Rect.fromLTWH(tx, top + 14 * k, 2.4 * k, len), col, false));
      }
      if (r.nextDouble() < 0.5) {
        final by = top + h * (0.05 + r.nextDouble() * 0.14);
        b.neons.add(_Neon(Rect.fromLTWH(x0, by, x1 - x0, 3 * k), _neons[r.nextInt(_neons.length)], true));
      }
    }
    // windows
    final bot = base - 4 * k;
    for (final t in b.tiers) {
      final m = 0.16 * t.w;
      final px = sp.px * k, py = sp.py * k;
      final cols = ((t.w - 2 * m) / px).floor();
      if (cols < 1) continue;
      final ww = px * 0.5, wh = py * 0.5;
      final ox = t.x0 + (t.w - cols * px) / 2 + (px - ww) / 2;
      var y = t.top + 11 * k;
      while (y + wh < bot) {
        final bias = r.nextDouble();
        final pl = sp.winP * ef * (0.25 + 1.5 * bias * bias);
        for (var i = 0; i < cols; i++) {
          final rect = Rect.fromLTWH(ox + i * px, y, ww, wh);
          final lit = r.nextDouble() < pl;
          final cu = r.nextDouble();
          final col = cu < 0.8 ? sp.lit : (cu < 0.9 ? _cyan : const Color(0xFFFF8AE8));
          final bl = pi >= 2 && r.nextDouble() < 0.1 && y > h * 0.1 && y < h * 0.85;
          if (bl) {
            d.blinks.add(_Win(rect, col, 2 + r.nextInt(5), r.nextDouble()));
            b.dim.add(rect);
          } else if (lit) {
            b.lit.add(rect);
            b.litCol.add(col);
          } else {
            b.dim.add(rect);
          }
        }
        y += py;
      }
    }
    d.blds.add(b);
  }

  // sky bridges
  const bdefs = {
    1: [0.52, 0.9],
    2: [0.26, 0.77],
  };
  final bd = bdefs[pi];
  if (bd != null) {
    _Bld? a, c;
    var ba = 9e9, bc = 9e9;
    for (final b in d.blds) {
      final cx = (b.tiers[0].x0 + b.tiers[0].x1) / 2;
      if ((cx - bd[0] * w).abs() < ba) {
        ba = (cx - bd[0] * w).abs();
        a = b;
      }
      if ((cx - bd[1] * w).abs() < bc) {
        bc = (cx - bd[1] * w).abs();
        c = b;
      }
    }
    if (a != null && c != null) {
      final y = math.min(a.tiers[0].top, c.tiers[0].top) + (pi == 2 ? 26 : 16) * k;
      d.bridges.add(_Bridge(a.tiers[0].x1 - 6 * k, c.tiers[0].x0 + 6 * k, y));
    }
  }
  return d;
}

// ---------------------------------------------------------------- building drawing

Path _rpoly(List<Offset> p, List<double> rad) {
  final path = Path();
  final n = p.length;
  for (var i = 0; i < n; i++) {
    final v = p[i], a = p[(i - 1 + n) % n], b = p[(i + 1) % n];
    final da = a - v, db = b - v;
    final la = da.distance, lb = db.distance;
    final rr = math.min(rad[i], math.min(la, lb) / 2);
    final st = v + da / la * rr, en = v + db / lb * rr;
    if (i == 0) {
      path.moveTo(st.dx, st.dy);
    } else {
      path.lineTo(st.dx, st.dy);
    }
    path.quadraticBezierTo(v.dx, v.dy, en.dx, en.dy);
  }
  return path..close();
}

Path _tierPath(_Tier t, double bot, double k) {
  final x0 = t.x0, x1 = t.x1, top = t.top, bw = t.w;
  final rr = math.min(bw * 0.22, 12 * k);
  switch (t.roof) {
    case 1:
      return _rpoly([Offset(x0, top), Offset(x1, top + bw * 0.42), Offset(x1, bot), Offset(x0, bot)], [3 * k, 3 * k, 0, 0]);
    case 2:
      return _rpoly([Offset(x0, top + bw * 0.42), Offset(x1, top), Offset(x1, bot), Offset(x0, bot)], [3 * k, 3 * k, 0, 0]);
    case 3:
      final ch = bw * 0.2;
      return _rpoly([Offset(x0, top + ch), Offset(x0 + ch, top), Offset(x1 - ch, top), Offset(x1, top + ch), Offset(x1, bot), Offset(x0, bot)], [4 * k, 4 * k, 4 * k, 4 * k, 0, 0]);
    case 4:
      return _rpoly([Offset(x0, top), Offset(x1, top), Offset(x1, bot), Offset(x0, bot)], [bw * 0.5, bw * 0.5, 0, 0]);
    default:
      return _rpoly([Offset(x0, top), Offset(x1, top), Offset(x1, bot), Offset(x0, bot)], [rr, rr, 0, 0]);
  }
}

void _paintPlane(Canvas c, Size s, int pi) {
  final sp = _specs[pi];
  final d = _plane(pi, s);
  final h = s.height, k = _kk(s);
  final bot = sp.base * h + 2 * k;
  final dimC = lighten(sp.color, pi == 0 ? 0.03 : 0.045);
  final pc = Paint(), pw = Paint();
  for (final b in d.blds) {
    for (final t in b.tiers) {
      final path = _tierPath(t, bot, k);
      c.drawPath(path, pc..color = sp.color);
      c.save();
      c.clipPath(path);
      c.drawRect(Rect.fromLTRB(t.x0 + t.w * 0.68, t.top - 2, t.x1 + 2, bot), pc..color = sp.shade);
      c.restore();
    }
    if (b.spireX != null) {
      final sx = b.spireX!;
      c.drawRRect(RRect.fromLTRBR(sx - 0.9 * k, b.spireTop!, sx + 0.9 * k, b.tiers.last.top + 3, Radius.circular(k)), pc..color = sp.shade);
      c.drawCircle(Offset(sx, b.spireTop!), 2 * k, pc..color = _mag.withValues(alpha: pi == 3 ? 0.5 : 0.3));
    }
    // dim windows
    final dp = Path();
    for (final r in b.dim) {
      dp.addRect(r);
    }
    c.drawPath(dp, pw..color = pi == 3 ? const Color(0xFF1B0E40) : dimC);
    // lit windows, batched per colour
    for (final col in [sp.lit, _cyan, const Color(0xFFFF8AE8)]) {
      final lp = Path();
      for (var i = 0; i < b.lit.length; i++) {
        if (b.litCol[i] == col) lp.addRect(b.lit[i]);
      }
      c.drawPath(lp, pw..color = col);
    }
    // neon accents
    if (b.edge != null) {
      final t = b.tiers[0];
      final a = sp.neonA;
      c.drawRRect(RRect.fromLTRBR(t.x0, t.top + math.min(t.w * 0.22, 12 * k), t.x0 + 1.8 * k, bot - 2 * k, Radius.circular(k)), pc..color = b.edge!.withValues(alpha: 0.9 * a));
      if (t.roof == 0 || t.roof == 3) {
        final inset = t.roof == 3 ? t.w * 0.2 : math.min(t.w * 0.22, 12 * k);
        c.drawRRect(RRect.fromLTRBR(t.x0 + inset, t.top, t.x1 - inset, t.top + 1.6 * k, Radius.circular(k)), pc..color = b.edge!.withValues(alpha: 0.9 * a));
      }
    }
    for (final n in b.neons) {
      final a = sp.neonA;
      final rr = n.rect;
      if (n.band) {
        c.drawRect(rr.inflate(2.5 * k), pc..color = n.col.withValues(alpha: 0.12 * a));
        c.drawRect(rr, pc..color = n.col.withValues(alpha: 0.85 * a));
      } else {
        c.drawRRect(RRect.fromRectAndRadius(rr.inflate(2.5 * k), Radius.circular(3 * k)), pc..color = n.col.withValues(alpha: 0.14 * a));
        c.drawRRect(RRect.fromRectAndRadius(rr, Radius.circular(1.2 * k)), pc..color = n.col.withValues(alpha: 0.95 * a));
      }
    }
  }
  for (final br in d.bridges) {
    _paintBridge(c, br, sp, k, pi);
  }
  if (pi == 3) _paintP3Details(c, s);
}

void _paintBridge(Canvas c, _Bridge br, _Spec sp, double k, int pi) {
  final sc = pi == 2 ? 1.0 : 0.75;
  final th = 10 * k * sc;
  final body = lighten(sp.color, 0.08);
  final p = Paint();
  c.drawRRect(RRect.fromLTRBR(br.x0 - 4 * k, br.y - th * 1.2, br.x0 + 12 * k, br.y + th * 1.7, Radius.circular(4 * k)), p..color = sp.shade);
  c.drawRRect(RRect.fromLTRBR(br.x1 - 12 * k, br.y - th * 1.2, br.x1 + 4 * k, br.y + th * 1.7, Radius.circular(4 * k)), p..color = sp.shade);
  final tube = RRect.fromLTRBR(br.x0, br.y - th / 2, br.x1, br.y + th / 2, Radius.circular(th / 2));
  c.drawRRect(tube, p..color = body);
  c.save();
  c.clipRRect(tube);
  c.drawRect(Rect.fromLTRB(br.x0, br.y + th * 0.12, br.x1, br.y + th), p..color = sp.shade);
  c.restore();
  // little lit windows along the tube
  final r = rng(pi + 40);
  final wp = Path();
  for (var x = br.x0 + 14 * k; x < br.x1 - 14 * k; x += 7 * k * sc) {
    if (r.nextDouble() < 0.7) wp.addRect(Rect.fromLTWH(x, br.y - th * 0.3, 3 * k * sc, 2.4 * k * sc));
  }
  c.drawPath(wp, p..color = sp.lit);
  // neon under-rail
  c.drawRect(Rect.fromLTRB(br.x0 + 6 * k, br.y + th / 2 + 0.5 * k, br.x1 - 6 * k, br.y + th / 2 + 2.2 * k), p..color = (pi == 2 ? _cyan : _vio).withValues(alpha: 0.9));
  c.drawRect(Rect.fromLTRB(br.x0 + 6 * k, br.y + th / 2 + 2.2 * k, br.x1 - 6 * k, br.y + th / 2 + 6 * k), p..color = (pi == 2 ? _cyan : _vio).withValues(alpha: 0.12));
}

// ---- hand-placed signs on the near towers

class _Sign {
  const _Sign(this.x, this.y, this.col, this.col2, this.kind);
  final double x, y; // fractions
  final Color col, col2;
  final int kind;
}

const _signsDef = [
  _Sign(0.13, 0.25, _mag, _cyan, 0),
  _Sign(0.865, 0.355, _cyan, _mag, 1),
];

void _drawSign(Canvas c, Size s, _Sign g, double a) {
  final k = _kk(s);
  final o = Offset(g.x * s.width, g.y * s.height);
  final p = Paint();
  if (g.kind == 0) {
    // vertical sign: ring + 3 bars
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, 24 * k), width: 18 * k, height: 62 * k), Radius.circular(5 * k)), p..color = _ink);
    c.drawCircle(o + Offset(0, 6 * k), 5.5 * k, p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * k
      ..color = g.col.withValues(alpha: a));
    p.style = PaintingStyle.fill;
    final ws = [11.0, 7.0, 11.0];
    for (var i = 0; i < 3; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, (20 + i * 9) * k), width: ws[i] * k, height: 3.4 * k), Radius.circular(2 * k)), p..color = (i == 1 ? g.col2 : g.col).withValues(alpha: a));
    }
  } else {
    // horizontal sign: two rings + bar
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 56 * k, height: 24 * k), Radius.circular(8 * k)), p..color = _ink);
    for (var i = 0; i < 2; i++) {
      c.drawCircle(o + Offset((-16 + i * 9) * k, 0), 5 * k, p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..color = (i == 0 ? g.col : g.col2).withValues(alpha: a));
    }
    p.style = PaintingStyle.fill;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(14 * k, -4 * k), width: 16 * k, height: 3.4 * k), Radius.circular(2 * k)), p..color = g.col.withValues(alpha: a));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(12 * k, 4 * k), width: 12 * k, height: 3.4 * k), Radius.circular(2 * k)), p..color = g.col2.withValues(alpha: a));
  }
}

void _paintP3Details(Canvas c, Size s) {
  final w = s.width, h = s.height, k = _kk(s);
  final p = Paint();
  // holographic panel on the left tower: translucent cyan plate with bars
  final panel = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.01, h * 0.205, w * 0.085, h * 0.075), Radius.circular(4 * k));
  c.drawRRect(panel, p..color = _cyan.withValues(alpha: 0.2));
  final bars = [0.8, 0.5, 0.65, 0.35];
  for (var i = 0; i < bars.length; i++) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.018, h * 0.215 + i * 11 * k, w * 0.07 * bars[i], 3 * k), Radius.circular(1.5 * k)), p..color = _cyan.withValues(alpha: 0.75));
  }
  // satellite dish + antenna on the right tower
  final rp = Offset(w * 0.94, h * 0.15 - 3 * k);
  c.drawCircle(rp, 3.2 * k, p..color = const Color(0xFF241352));
  // scan-lined hologram ring on the right tower
  final ro = Offset(w * 0.935, h * 0.255);
  c.drawCircle(ro, 17 * k, p..color = _mag.withValues(alpha: 0.14));
  c.drawCircle(ro, 17 * k, p
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2 * k
    ..color = _mag.withValues(alpha: 0.8));
  c.drawCircle(ro, 9 * k, p
    ..strokeWidth = 1.4 * k
    ..color = _cyan.withValues(alpha: 0.8));
  p.style = PaintingStyle.fill;
  for (var i = -2; i <= 2; i++) {
    c.drawRect(Rect.fromCenter(center: ro + Offset(0, i * 6 * k), width: (i.abs() == 2 ? 18 : 28) * k, height: 1.2 * k), p..color = _mag.withValues(alpha: 0.55));
  }
  for (final g in _signsDef) {
    _drawSign(c, s, g, 0.6);
  }
}

// ---------------------------------------------------------------- fog

void _fogFar(Canvas c, Size s) {
  final w = s.width, h = s.height, k = _kk(s);
  final p = Paint();
  final xs = [0.1, 0.45, 0.8];
  for (var i = 0; i < 3; i++) {
    final cw = w * (0.5 + 0.1 * (i % 2));
    final cy = h * (0.575 + 0.02 * (i % 2));
    final cx = xs[i] * w;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: cw, height: 22 * k), Radius.circular(11 * k)), p..color = const Color(0xFFB04AD0).withValues(alpha: 0.2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 20 * k, cy + 18 * k), width: cw * 0.7, height: 15 * k), Radius.circular(8 * k)), p..color = const Color(0xFFB04AD0).withValues(alpha: 0.14));
  }
}

void _fogNear(Canvas c, Size s) {
  final w = s.width, h = s.height, k = _kk(s);
  final p = Paint();
  final xs = [0.2, 0.7];
  for (var i = 0; i < 2; i++) {
    final cw = w * 0.7;
    final cy = h * (0.72 + 0.1 * i);
    final cx = xs[i] * w;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: cw, height: 26 * k), Radius.circular(13 * k)), p..color = _fog.withValues(alpha: 0.28));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 30 * k, cy + 20 * k), width: cw * 0.6, height: 16 * k), Radius.circular(8 * k)), p..color = _fog.withValues(alpha: 0.2));
  }
}

// ---------------------------------------------------------------- street

void _street(Canvas c, Size s) {
  final w = s.width, h = s.height, k = _kk(s);
  final y0 = 0.87 * h;
  final p = Paint();
  c.drawRect(Rect.fromLTRB(-0.2 * w, y0, 1.2 * w, 1.2 * h), p..color = _road);
  // mirrored city
  c.save();
  c.clipRect(Rect.fromLTRB(-0.2 * w, y0, 1.2 * w, 1.2 * h));
  c.translate(0, 2 * y0);
  c.scale(1, -1);
  for (final pi in [2, 3]) {
   final d = _plane(pi, s);
   final sp = _specs[pi];
   for (final b in d.blds) {
    for (final t in b.tiers) {
      c.drawPath(_tierPath(t, y0 + 2, k), p..color = const Color(0xFF3B2080).withValues(alpha: 0.5));
    }
    final lp = Path();
    for (final r in b.lit) {
      lp.addRect(r);
    }
    c.drawPath(lp, p..color = sp.lit.withValues(alpha: 0.5));
    for (final n in b.neons) {
      c.drawRect(n.rect.inflate(n.band ? 0 : 1.5 * k), p..color = n.col.withValues(alpha: 0.5));
    }
    if (b.edge != null) {
      final t = b.tiers[0];
      c.drawRect(Rect.fromLTRB(t.x0, t.top, t.x0 + 2 * k, y0), p..color = b.edge!.withValues(alpha: 0.4));
    }
   }
  }
  c.restore();
  // fade the reflection into the road with depth (soft depth haze)
  final fr = Rect.fromLTRB(-0.2 * w, y0, 1.2 * w, 1.2 * h);
  c.drawRect(fr, verticalPaint(fr, [_road.withValues(alpha: 0.0), _road.withValues(alpha: 0.96)], [0.0, 0.55]));
  // wet ripple gaps: flat road-coloured bars cut the reflection
  final r = rng(77);
  var y = y0 + 5 * k;
  while (y < h * 1.05) {
    final th = (1.4 + (y - y0) / h * 14) * k;
    final x = r.nextDouble() * w * 0.4;
    c.drawRect(Rect.fromLTWH(-20 * k, y, w + 40 * k, th), p..color = _road.withValues(alpha: 0.9));
    c.drawRect(Rect.fromLTWH(x - 10, y + th + 1.5 * k, w * (0.3 + r.nextDouble() * 0.4), 1.2 * k), p..color = const Color(0xFF3A2090).withValues(alpha: 0.35));
    y += th + (5 + (y - y0) / h * 24) * k;
  }
  // kerb with neon strip
  c.drawRect(Rect.fromLTRB(-0.2 * w, y0 - 1 * k, 1.2 * w, y0 + 2.4 * k), p..color = _mag.withValues(alpha: 0.85));
  c.drawRect(Rect.fromLTRB(-0.2 * w, y0 + 2.4 * k, 1.2 * w, y0 + 8 * k), p..color = _mag.withValues(alpha: 0.12));
  // lane dashes in perspective
  for (var i = 0; i < 9; i++) {
    final x = w * (0.5 + (i - 4) * 0.19);
    final yy = h * 0.965;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, yy), width: 26 * k, height: 3 * k), Radius.circular(1.5 * k)), p..color = _cyan.withValues(alpha: 0.18));
  }
}

// ---------------------------------------------------------------- foreground

Offset _bez(Offset a, Offset b, Offset c, double t) => Offset.lerp(Offset.lerp(a, b, t)!, Offset.lerp(b, c, t)!, t)!;

class _Cable {
  const _Cable(this.a, this.b, this.c, this.ts);
  final Offset a, b, c;
  final List<double> ts;
}

List<_Cable> _cables(Size s) {
  final w = s.width, h = s.height;
  return [
    _Cable(Offset(-0.05 * w, 0.06 * h), Offset(0.22 * w, 0.17 * h), Offset(0.5 * w, 0.115 * h), const [0.22, 0.45, 0.72, 0.9]),
    _Cable(Offset(0.5 * w, 0.115 * h), Offset(0.78 * w, 0.19 * h), Offset(1.06 * w, 0.075 * h), const [0.3, 0.6, 0.85]),
  ];
}

List<Offset> _lanternPos(Size s) {
  final out = <Offset>[];
  for (final cb in _cables(s)) {
    for (final t in cb.ts) {
      out.add(_bez(cb.a, cb.b, cb.c, t));
    }
  }
  return out;
}

void _foreground(Canvas c, Size s) {
  final w = s.width, h = s.height, k = _kk(s);
  final p = Paint();
  // cables
  final cp = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5 * k
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF0B0524);
  for (final cb in _cables(s)) {
    final path = Path()
      ..moveTo(cb.a.dx, cb.a.dy)
      ..quadraticBezierTo(cb.b.dx, cb.b.dy, cb.c.dx, cb.c.dy);
    c.drawPath(path, cp);
  }
  // paper lanterns
  for (final o in _lanternPos(s)) {
    c.drawLine(o, o + Offset(0, 5 * k), cp..strokeWidth = 1 * k);
    final body = Rect.fromCenter(center: o + Offset(0, 11 * k), width: 11 * k, height: 13 * k);
    c.drawOval(body, p..color = _warm);
    c.save();
    c.clipPath(Path()..addOval(body));
    c.drawRect(Rect.fromLTRB(body.center.dx + 1.2 * k, body.top, body.right, body.bottom), p..color = const Color(0xFFE5703F));
    c.restore();
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(o.dx, body.top + 0.5 * k), width: 5 * k, height: 2 * k), Radius.circular(k)), p..color = _ink);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(o.dx, body.bottom - 0.5 * k), width: 4 * k, height: 2 * k), Radius.circular(k)), p..color = _ink);
  }

  // ---- kiosk (bottom left)
  final kx0 = w * 0.0, kx1 = w * 0.31, ky0 = h * 0.855, ky1 = h * 0.975;
  c.drawRRect(RRect.fromLTRBR(kx0 - 20 * k, ky0, kx1, ky1, Radius.circular(8 * k)), p..color = const Color(0xFF2E1A78));
  c.save();
  c.clipRRect(RRect.fromLTRBR(kx0 - 20 * k, ky0, kx1, ky1, Radius.circular(8 * k)));
  c.drawRect(Rect.fromLTRB(kx0 + (kx1 - kx0) * 0.74, ky0, kx1 + 2, ky1), p..color = const Color(0xFF231363));
  c.restore();
  // warm window
  final win = RRect.fromLTRBR(kx0 + 14 * k, ky0 + 30 * k, kx0 + 78 * k, ky0 + 62 * k, Radius.circular(5 * k));
  c.drawRRect(win, p..color = _warm);
  c.save();
  c.clipRRect(win);
  c.drawRect(Rect.fromLTRB(win.left + 30 * k, win.top, win.right, win.bottom), p..color = const Color(0xFFFFD27A));
  c.drawRect(Rect.fromLTRB(win.left, win.bottom - 7 * k, win.right, win.bottom), p..color = const Color(0xFF8A3A5C));
  // bowls silhouettes
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(win.left + 8 * k, win.bottom - 14 * k, 14 * k, 9 * k), Radius.circular(5 * k)), p..color = const Color(0xFFB4504E));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(win.left + 30 * k, win.bottom - 16 * k, 12 * k, 11 * k), Radius.circular(5 * k)), p..color = const Color(0xFFB4504E));
  c.restore();
  // awning with scallops
  const n = 6;
  final aw0 = kx0 - 8 * k, aw1 = kx1 + 8 * k;
  final aw = (aw1 - aw0) / n;
  c.drawRRect(RRect.fromLTRBR(aw0, ky0 + 2 * k, aw1, ky0 + 22 * k, Radius.circular(5 * k)), p..color = _mag);
  for (var i = 0; i < n; i++) {
    final col = i.isEven ? _mag : const Color(0xFF3A1B7A);
    c.drawRect(Rect.fromLTWH(aw0 + i * aw, ky0 + 2 * k, aw, 18 * k), p..color = col);
    c.drawCircle(Offset(aw0 + (i + 0.5) * aw, ky0 + 20 * k), aw / 2, p..color = col);
  }
  c.drawRRect(RRect.fromLTRBR(aw0, ky0 - 1 * k, aw1, ky0 + 6 * k, Radius.circular(4 * k)), p..color = const Color(0xFFFF73E6));
  // little neon bar sign above
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx0 + 40 * k, ky0 - 14 * k, 34 * k, 9 * k), Radius.circular(4.5 * k)), p..color = _ink);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx0 + 44 * k, ky0 - 11 * k, 12 * k, 3 * k), Radius.circular(1.5 * k)), p..color = _cyan);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx0 + 58 * k, ky0 - 11 * k, 12 * k, 3 * k), Radius.circular(1.5 * k)), p..color = _warm);
  // chimney pipe for steam
  c.drawRRect(RRect.fromLTRBR(kx1 - 24 * k, ky0 - 24 * k, kx1 - 14 * k, ky0 + 2 * k, Radius.circular(3 * k)), p..color = const Color(0xFF241352));
  c.drawRRect(RRect.fromLTRBR(kx1 - 26 * k, ky0 - 27 * k, kx1 - 12 * k, ky0 - 21 * k, Radius.circular(3 * k)), p..color = const Color(0xFF3A2090));
  // the cat on the roof
  final cb = Offset(kx0 + 100 * k - 20 * k, ky0 - 1 * k);
  c.drawOval(Rect.fromCenter(center: cb + Offset(0, -6 * k), width: 20 * k, height: 12 * k), p..color = const Color(0xFF6A44C8));
  c.drawCircle(cb + Offset(9 * k, -13 * k), 5.2 * k, p..color = const Color(0xFF6A44C8));
  for (final sx in [-1.0, 1.0]) {
    c.drawPath(_rpoly([cb + Offset((9 + sx * 4.2) * k, -15 * k), cb + Offset((9 + sx * 1.2) * k, -19.5 * k), cb + Offset((9 + sx * 0.3) * k, -14 * k)], [1 * k, 1 * k, 1 * k]), p..color = const Color(0xFF6A44C8));
  }
  c.drawCircle(cb + Offset(11 * k, -13.5 * k), 0.9 * k, p..color = _win);
  c.drawCircle(cb + Offset(7.4 * k, -13.5 * k), 0.9 * k, p..color = _win);
  c.drawPath(
      Path()
        ..moveTo(cb.dx - 9 * k, cb.dy - 5 * k)
        ..quadraticBezierTo(cb.dx - 19 * k, cb.dy - 6 * k, cb.dx - 15 * k, cb.dy - 16 * k),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6 * k
        ..color = const Color(0xFF6A44C8));

  // ---- lamp post (bottom right)
  final lx = w * 0.9;
  c.drawRRect(RRect.fromLTRBR(lx - 3 * k, h * 0.64, lx + 3 * k, h * 1.05, Radius.circular(3 * k)), p..color = const Color(0xFF3A2090));
  c.drawRRect(RRect.fromLTRBR(lx - 7 * k, h * 0.97, lx + 7 * k, h * 1.05, Radius.circular(4 * k)), p..color = const Color(0xFF3A2090));
  c.drawPath(
      Path()
        ..moveTo(lx, h * 0.655)
        ..quadraticBezierTo(lx - 2 * k, h * 0.625, lx - 26 * k, h * 0.628),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4 * k
        ..color = const Color(0xFF3A2090));
  final lamp = Offset(lx - 28 * k, h * 0.634);
  c.drawCircle(lamp, 13 * k, p..color = _cyan.withValues(alpha: 0.14));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lamp, width: 20 * k, height: 7 * k), Radius.circular(3.5 * k)), p..color = _cyan);
  // neon ring sign on the post
  final rg = Offset(lx, h * 0.8);
  c.drawCircle(rg, 11 * k, p
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2 * k
    ..color = _mag);
  p.style = PaintingStyle.fill;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: rg, width: 11 * k, height: 3 * k), Radius.circular(1.5 * k)), p..color = _cyan);
  // manhole + hydrant-like vents on the road
  c.drawOval(Rect.fromCenter(center: Offset(w * 0.6, h * 0.935), width: 36 * k, height: 8 * k), p..color = const Color(0xFF0E0724));
  c.drawOval(Rect.fromCenter(center: Offset(w * 0.6, h * 0.933), width: 28 * k, height: 5 * k), p..color = const Color(0xFF2A1670));
}

// ---------------------------------------------------------------- live: vehicles

class _V {
  const _V(this.y, this.size, this.dir, this.cyc, this.ph, this.col);
  final double y, size;
  final int dir, cyc;
  final double ph;
  final Color col;
}

const _vBack = [
  _V(0.235, 0.7, 1, 3, 0.1, _cyan),
  _V(0.30, 0.75, -1, 2, 0.55, _mag),
  _V(0.345, 0.6, 1, 2, 0.8, _win),
  _V(0.405, 0.8, -1, 3, 0.3, _cyan),
];
const _vFront = [
  _V(0.115, 1.5, -1, 3, 0.35, _mag),
  _V(0.19, 1.15, 1, 4, 0.7, _cyan),
  _V(0.435, 1.0, 1, 2, 0.05, _vio),
];

void _paintVehicles(Canvas c, Size s, Clock k, List<_V> vs) {
  final w = s.width, h = s.height, kk = _kk(s);
  final p = Paint();
  for (final v in vs) {
    final t = k.saw(v.cyc, v.ph);
    final m = 130 * kk;
    final span = w + 2 * m;
    final x = v.dir > 0 ? -m + t * span : w + m - t * span;
    final y = v.y * h + k.sine(v.cyc * 2, v.ph) * 1.6 * kk;
    final sz = v.size * kk;
    final hh = 1.3 * sz;
    for (var i = 0; i < 3; i++) {
      final len = 18.0 * sz * (3 - i) * 1.1;
      final a = [0.22, 0.34, 0.5][i];
      final rect = v.dir > 0 ? Rect.fromLTRB(x - len, y - hh, x, y + hh) : Rect.fromLTRB(x, y - hh, x + len, y + hh);
      c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(hh)), p..color = v.col.withValues(alpha: a));
    }
    final body = Rect.fromCenter(center: Offset(x, y), width: 13 * sz, height: 4.4 * sz);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(2.2 * sz)), p..color = v.col);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + v.dir * 1.5 * sz, y - 2.1 * sz), width: 6 * sz, height: 3 * sz), Radius.circular(1.5 * sz)), p..color = _ink);
    c.drawCircle(Offset(x + v.dir * 6.5 * sz, y), 1.2 * sz, p..color = const Color(0xFFFFFFFF));
  }
}

void _vehiclesBack(Canvas c, Size s, Clock k) => _paintVehicles(c, s, k, _vBack);

// ---------------------------------------------------------------- live: city life

double _dx(Clock k, Size s, int pi) => _drift[pi] * s.width * k.sine(2, _driftPh[pi]);

double _blinkA(double v) => (v * 14).clamp(0.0, 1.0) * ((0.55 - v) * 14).clamp(0.0, 1.0);

void _cityLife(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, kk = _kk(s);
  final p = Paint();
  for (final pi in [2, 3]) {
    final d = _plane(pi, s);
    c.save();
    c.translate(_dx(k, s, pi), 0);
    for (final b in d.blinks) {
      final a = _blinkA(k.saw(b.cyc, b.ph));
      if (a <= 0) continue;
      c.drawRect(b.rect, p..color = b.col.withValues(alpha: a));
    }
    // antenna beacons
    var i = 0;
    for (final o in d.beacons) {
      final a = k.pulse(6, i * 0.31);
      c.drawCircle(o, 4.5 * kk, p..color = _mag.withValues(alpha: 0.16 * a));
      c.drawCircle(o, 2 * kk, p..color = Color.lerp(const Color(0xFFB0207F), const Color(0xFFFF5EDD), a)!);
      i++;
    }
    // light dots gliding along the sky bridges
    for (final br in d.bridges) {
      final sc = pi == 2 ? 1.0 : 0.75;
      for (var j = 0; j < 6; j++) {
        final up = j.isEven;
        final t = k.saw(3 + (j % 2), j / 6);
        final x = _lerp(br.x0 + 14 * kk, br.x1 - 14 * kk, up ? t : 1 - t);
        final col = j % 3 == 0 ? _cyan : (j % 3 == 1 ? _win : _mag);
        c.drawCircle(Offset(x, br.y - 0.2 * kk), 3.4 * kk * sc, p..color = col.withValues(alpha: 0.2));
        c.drawCircle(Offset(x, br.y - 0.2 * kk), 1.7 * kk * sc, p..color = col);
      }
    }
    if (pi == 3) {
      // pulsing neon signs
      final pu = k.pulse(8);
      for (final g in _signsDef) {
        final o = Offset(g.x * w, g.y * h);
        final plate = g.kind == 0 ? Rect.fromCenter(center: o + Offset(0, 24 * kk), width: 24 * kk, height: 68 * kk) : Rect.fromCenter(center: o, width: 62 * kk, height: 30 * kk);
        c.drawRRect(RRect.fromRectAndRadius(plate, Radius.circular(8 * kk)), p..color = g.col.withValues(alpha: 0.05 + 0.1 * pu));
        _drawSign(c, s, g, 0.2 + 0.4 * pu);
      }
      // searchlight sweeping from the right tower
      final apex = Offset(w * 0.94, h * 0.15 - 3 * kk);
      final ang = -math.pi / 2 - 0.25 - 0.55 * (0.5 + 0.5 * k.sine(2));
      final len = h * 0.85;
      Offset tip(double a) => apex + Offset(math.cos(a), math.sin(a)) * len;
      c.drawPath(Path()..moveTo(apex.dx, apex.dy)..lineTo(tip(ang - 0.07).dx, tip(ang - 0.07).dy)..lineTo(tip(ang + 0.07).dx, tip(ang + 0.07).dy)..close(), p..color = const Color(0xFFE5D4FF).withValues(alpha: 0.1));
      c.drawPath(Path()..moveTo(apex.dx, apex.dy)..lineTo(tip(ang - 0.03).dx, tip(ang - 0.03).dy)..lineTo(tip(ang + 0.03).dx, tip(ang + 0.03).dy)..close(), p..color = const Color(0xFFE5D4FF).withValues(alpha: 0.1));
      c.drawCircle(apex, 2.6 * kk, p..color = const Color(0xFFFFFFFF));
    }
    c.restore();
  }
  _paintVehicles(c, s, k, _vFront);
}

// ---------------------------------------------------------------- live: foreground + rain

void _foreLife(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height, kk = _kk(s);
  final p = Paint();
  // lantern halos + steam share the foreground's drift
  c.save();
  c.translate(0.03 * w * k.sine(2, 0.15), 0);
  var i = 0;
  for (final o in _lanternPos(s)) {
    final a = k.pulse(5, i * 0.17);
    final ctr = o + Offset(0, 11 * kk);
    c.drawCircle(ctr, 17 * kk, p..color = _warm.withValues(alpha: 0.05 + 0.07 * a));
    c.drawCircle(ctr, 11 * kk, p..color = _warm.withValues(alpha: 0.08 + 0.08 * a));
    i++;
  }
  // steam from the kiosk pipe
  final px = w * 0.31 - 19 * kk, py = h * 0.855 - 28 * kk;
  for (var j = 0; j < 5; j++) {
    final t = k.saw(6, j / 5);
    final r = (3 + 8 * t) * kk;
    final o = Offset(px + math.sin(t * 5 + j) * 6 * kk + t * 10 * kk, py - t * 58 * kk);
    c.drawCircle(o, r, p..color = const Color(0xFFD9C9FF).withValues(alpha: 0.5 * math.sin(t * math.pi)));
  }
  // lamp halo + rippling puddle rings on the road
  c.restore();
  c.save();
  c.translate(_dx(k, s, 2), 0);
  for (var j = 0; j < 4; j++) {
    final cx = [0.38, 0.55, 0.7, 0.46][j] * w;
    final cy = [0.91, 0.945, 0.9, 0.975][j] * h;
    final t = k.saw(5, j * 0.25 + 0.1);
    final a = (1 - t) * 0.5;
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: (4 + 22 * t) * kk, height: (1.4 + 7 * t) * kk), p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * kk
      ..color = _cyan.withValues(alpha: a));
    p.style = PaintingStyle.fill;
  }
  c.restore();
  // light rain (diagonal streaks)
  final r = rng(5);
  final rp = Paint()
    ..strokeWidth = 1.1 * kk
    ..strokeCap = StrokeCap.round;
  final fall = h + 60 * kk;
  for (var j = 0; j < 38; j++) {
    final cyc = 12 + (j % 4) * 2;
    final x0 = r.nextDouble() * (w + 0.25 * fall);
    final t = k.saw(cyc, r.nextDouble());
    final y = -30 * kk + t * fall;
    final x = x0 - t * fall * 0.25;
    final len = (10 + r.nextDouble() * 10) * kk;
    rp.color = Color.lerp(const Color(0xFFB9A4FF), const Color(0xFF9FE9FF), (j % 3) / 2)!.withValues(alpha: 0.38);
    c.drawLine(Offset(x, y), Offset(x + len * 0.25, y - len), rp);
  }
}
