import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Lost Jungle Temple in flat, graphic 2D: a mossy stepped temple swallowed by
// giant trees, golden sunbeams from the upper left, a waterfall into a
// turquoise pool, big ferns and fronds framing the frame. Vines and leaves sway,
// motes drift in the light, birds cross. Light comes from the upper left, so
// every shade tone sits on the right / underneath.

// palette
const _shadow = Color(0xFF06261F), _turq = Color(0xFF3CC9C0);
const _moss = Color(0xFF7BBF4A), _gold = Color(0xFFFFD27A);
const _stone = Color(0xFFA9B79A), _stoneDark = Color(0xFF7C8F7A);
const _haze = Color(0xFFBFE6CC);

SceneSpec jungleScene() => SceneSpec(
      focusY: -0.35,
      topShade: 0.12,
      bottomShade: 0.22,
      layers: [
        Layer.still(_skyAndFar),
        Layer.scroll(_mistFar, scrollCycles: 1, bandTop: 0.3, bandBottom: 0.62),
        Layer.still(_templeLayer, driftX: 0.006, driftCycles: 2),
        Layer.scroll(_mistMid, scrollCycles: 2, scrollLeft: false, bandTop: 0.46, bandBottom: 0.78),
        Layer.still(_midTrees, driftX: 0.011, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_cliffAndGround),
        Layer.live(_waterfallLive),
        Layer.still(_rays, rotate: 0.012, swayCycles: 3, pivot: const Alignment(-1.1, -1.1)),
        Layer.still(_trunks, driftX: 0.018, driftCycles: 2, driftPhase: 0.2),
        Layer.still(_canopy, driftX: 0.022, driftCycles: 2, driftPhase: 0.3, sway: 0.007, swayCycles: 5, pivot: Alignment.topCenter),
        Layer.still(_vines, driftX: 0.026, driftCycles: 2, driftPhase: 0.35, sway: 0.016, swayCycles: 7, swayPhase: 0.2, pivot: Alignment.topCenter),
        Layer.still(_foreA, driftX: 0.04, driftCycles: 2, driftPhase: 0.4, sway: 0.007, swayCycles: 4, pivot: Alignment.bottomCenter),
        Layer.still(_foreB, driftX: 0.05, driftCycles: 2, driftPhase: 0.5, sway: 0.01, swayCycles: 6, swayPhase: 0.4, pivot: Alignment.bottomCenter),
        Layer.live(_motesAndBirds),
      ],
    );

Paint _f(Color c) => Paint()..color = c;

// ---------------------------------------------------------------- shape helpers

/// Pointed leaf along a gently drooping spine; the lit half (upper left) and the
/// shade half are two flat tones.
void _blade(Canvas c, Offset base, double len, double ang, double wid, Color light, Color dark, {double droop = 0, double bend = 0, Color? rib, double ribW = 1.4}) {
  const n = 8;
  final dir = Offset(math.sin(ang), -math.cos(ang));
  final perp = Offset(-dir.dy, dir.dx);
  final sp = <Offset>[
    for (var i = 0; i <= n; i++)
      () {
        final t = i / n;
        return base + dir * (len * t) + Offset(0, droop * len * t * t) + perp * (bend * len * t * t);
      }(),
  ];
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final a = sp[math.max(i - 1, 0)], b = sp[math.min(i + 1, n)];
    var d = b - a;
    d = d / d.distance;
    final nrm = Offset(d.dy, -d.dx);
    final t = i / n;
    final w = wid * math.pow(math.sin(math.pi * math.pow(t, 0.65)), 0.75);
    left.add(sp[i] + nrm * w);
    right.add(sp[i] - nrm * w);
  }
  final mid = left[n ~/ 2] - sp[n ~/ 2];
  final leftLit = mid.dx * -0.6 + mid.dy * -0.8 > 0;
  final lp = smoothPath([...sp, ...left.reversed.skip(1).take(n - 1)], closed: true);
  final rp = smoothPath([...sp, ...right.reversed.skip(1).take(n - 1)], closed: true);
  c.drawPath(lp, _f(leftLit ? light : dark));
  c.drawPath(rp, _f(leftLit ? dark : light));
  if (rib != null) {
    c.drawPath(
        smoothPath(sp),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = ribW
          ..color = rib);
  }
}

/// Pinnate frond (palm / fern): drooping spine with flat leaflets on both sides.
void _frond(Canvas c, Offset base, double len, double ang, Color light, Color dark, {double droop = 0.25, double leaf = 0.34, int count = 11, double spread = 0.9, Color? spine}) {
  final dir = Offset(math.sin(ang), -math.cos(ang));
  Offset pt(double t) => base + dir * (len * t) + Offset(0, droop * len * t * t);
  final sc = spine ?? dark;
  c.drawPath(
      smoothPath([for (var i = 0; i <= 6; i++) pt(i / 6)]),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.6, len * 0.018)
        ..color = sc);
  for (var i = 0; i < count; i++) {
    final t = 0.1 + 0.88 * i / (count - 1);
    final p = pt(t), q = pt(math.min(t + 0.03, 1.0));
    var d = q - p;
    d = d / d.distance;
    final l = len * leaf * math.sin(math.pi * math.pow(t, 0.55)) * 0.95 + len * 0.02;
    for (final side in [-1, 1]) {
      final a = math.atan2(d.dy, d.dx) + side * spread;
      final e = p + Offset(math.cos(a), math.sin(a)) * l + Offset(0, l * 0.32);
      final m = Offset.lerp(p, e, 0.5)!;
      final nrm = Offset(-(e - p).dy, (e - p).dx) / (e - p).distance;
      final wd = l * 0.3;
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(m.dx + nrm.dx * wd, m.dy + nrm.dy * wd + 1, e.dx, e.dy)
        ..quadraticBezierTo(m.dx - nrm.dx * wd * 0.6, m.dy - nrm.dy * wd * 0.6, p.dx, p.dy)
        ..close();
      c.drawPath(path, _f(side < 0 ? light : dark));
    }
  }
}

/// Hanging liana with small heart leaves.
void _vine(Canvas c, double x, double y0, double len, int seed, {required Color color, required Color leafLight, required Color leafDark, double thick = 3.0, double leafSize = 1.0}) {
  final r = rng(seed);
  final amp = 6 + r.nextDouble() * 10;
  final ph = r.nextDouble() * tau;
  final pts = <Offset>[for (var i = 0; i <= 8; i++) Offset(x + math.sin(ph + i * 0.7) * amp * (i / 8), y0 + len * i / 8)];
  c.drawPath(
      smoothPath(pts),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = thick
        ..color = color);
  final leaves = (len / 34).round().clamp(2, 12);
  for (var i = 0; i < leaves; i++) {
    final t = 0.18 + 0.8 * (i + r.nextDouble() * 0.5) / leaves;
    final idx = (t * 8).floor().clamp(0, 7);
    final p = Offset.lerp(pts[idx], pts[idx + 1], t * 8 - idx)!;
    final side = i.isEven ? -1.0 : 1.0;
    final ls = (9 + r.nextDouble() * 6) * leafSize;
    _blade(c, p, ls * 1.5, side * (1.1 + r.nextDouble() * 0.5) + math.pi, ls * 0.42, leafLight, leafDark, droop: 0.2);
  }
  _blade(c, pts.last, 15 * leafSize, math.pi + 0.15, 6 * leafSize, leafLight, leafDark);
}

/// Scalloped foliage mass from overlapping circles (flat dark, flat light crescent).
void _puffs(Canvas c, List<(Offset, double)> blobs, Color dark, Color light, {Color? mid}) {
  final all = Path();
  for (final (o, r) in blobs) {
    all.addOval(Rect.fromCircle(center: o, radius: r));
  }
  c.drawPath(all, _f(dark));
  final lit = Path();
  for (final (o, r) in blobs) {
    lit.addOval(Rect.fromCircle(center: o + Offset(-r * 0.1, -r * 0.14), radius: r * 0.78));
  }
  c
    ..save()
    ..clipPath(all)
    ..drawPath(lit, _f(mid ?? light))
    ..restore();
  if (mid != null) {
    final top = Path();
    for (final (o, r) in blobs) {
      top.addOval(Rect.fromCircle(center: o + Offset(-r * 0.2, -r * 0.3), radius: r * 0.5));
    }
    c
      ..save()
      ..clipPath(all)
      ..drawPath(top, _f(light))
      ..restore();
  }
}

void _palm(Canvas c, Offset base, double h, double lean, Color trunk, Color light, Color dark, {int fronds = 8, double frondLen = 0.34}) {
  final tw = h * 0.028;
  final top = base + Offset(lean * h, -h);
  final ctrl = base + Offset(lean * h * 0.1, -h * 0.55);
  final path = Path()
    ..moveTo(base.dx - tw * 1.6, base.dy)
    ..quadraticBezierTo(ctrl.dx - tw, ctrl.dy, top.dx - tw * 0.7, top.dy)
    ..lineTo(top.dx + tw * 0.7, top.dy)
    ..quadraticBezierTo(ctrl.dx + tw, ctrl.dy, base.dx + tw * 1.6, base.dy)
    ..close();
  c.drawPath(path, _f(trunk));
  c
    ..save()
    ..clipPath(path)
    ..drawRect(Rect.fromLTRB(base.dx + tw * 0.1 + lean * h * 0.3, top.dy, base.dx + h, base.dy), _f(darken(trunk, 0.06)))
    ..restore();
  for (var i = 0; i < fronds; i++) {
    final a = -1.9 + i * (3.8 / (fronds - 1));
    _frond(c, top, h * frondLen, a, light, dark, droop: 0.3 + 0.2 * (a.abs() / 1.9), leaf: 0.32, count: 9);
  }
  c.drawCircle(top, h * 0.025, _f(dark));
}

// ---------------------------------------------------------------- sky and far hills

void _skyAndFar(Canvas c, Size s) {
  final w = s.width, h = s.height;
  fillSky(c, s, const [Color(0xFF2FA08C), Color(0xFF86D2A8), Color(0xFFD7EDB0), Color(0xFFF1F0B6)], const [0.0, 0.22, 0.42, 0.62]);
  flatSun(c, Offset(w * 0.22, h * 0.1), w * 0.055, core: const Color(0xFFFFF4C2), halo: _gold);
  // soft far clouds, barely there
  flatCloud(c, Offset(w * 0.7, h * 0.2), w * 0.42, color: const Color(0xFFF4FBE0), shade: const Color(0xFFD2EBC0), seed: 5, puff: 0.8, opacity: 0.8);
  flatCloud(c, Offset(w * 0.2, h * 0.28), w * 0.36, color: const Color(0xFFF4FBE0), shade: const Color(0xFFD2EBC0), seed: 9, puff: 0.7, opacity: 0.7);
  // far misty hills
  final far = Ridge(s, y: 0.38, amp: 0.045, freq: 1.5, seed: 31, octaves: 2, sharp: 0.2);
  flatMountains(c, far, const Color(0xFFA6DBBB), const Color(0xFF93CDAB));
  final far2 = Ridge(s, y: 0.43, amp: 0.035, freq: 2.0, seed: 8, octaves: 2, sharp: 0.2);
  flatMountains(c, far2, const Color(0xFF86C9A6), const Color(0xFF74BB97));
  // distant tall trees silhouettes
  final r = rng(3);
  for (var row = 0; row < 2; row++) {
    final ridge = Ridge(s, y: 0.47 + row * 0.03, amp: 0.008, freq: 3, seed: 60 + row);
    final col = row == 0 ? const Color(0xFF6FBB9A) : const Color(0xFF55AB88);
    var x = -w * 0.05;
    while (x < w * 1.05) {
      final th = h * (0.07 + r.nextDouble() * 0.05);
      flatTree(c, Offset(x, ridge.yAt(x) + 3), th, crown: col, light: lighten(col, 0.07), trunk: darken(col, 0.1), trunkShade: darken(col, 0.14), seed: r.nextInt(999), crownScale: 1.25);
      x += th * (0.45 + r.nextDouble() * 0.3);
    }
    flatRidge(c, ridge, col);
  }
}

void _mistFar(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(41);
  for (var i = 0; i < 3; i++) {
    flatCloud(c, Offset((i + 0.3 + r.nextDouble() * 0.3) * w / 3, h * (0.5 + r.nextDouble() * 0.06)), w * (0.34 + r.nextDouble() * 0.1), color: const Color(0xFFE6F6D6), shade: const Color(0xFFBFE4CC), seed: 70 + i, puff: 0.5, opacity: 0.55);
  }
}

void _mistMid(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(43);
  for (var i = 0; i < 4; i++) {
    flatCloud(c, Offset((i + 0.25 + r.nextDouble() * 0.4) * w / 4, h * (0.6 + r.nextDouble() * 0.14)), w * (0.3 + r.nextDouble() * 0.12), color: const Color(0xFFD5F0D8), shade: const Color(0xFFA6D9B8), seed: 80 + i, puff: 0.45, opacity: 0.4);
  }
}

// ---------------------------------------------------------------- the temple

void _templeLayer(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _temple(c, s, w * 0.6, h * 0.665, 1.12, hz: 0.1);
}

void _temple(Canvas c, Size s, double cx, double baseY, double sc, {required double hz}) {
  final w = s.width, h = s.height;
  Color hx(Color col) => hazeTo(col, _haze, hz);
  final stone = hx(mix(_stone, _stoneDark, 0.4)), stoneLight = hx(const Color(0xFFC6D3B0)), stoneShade = hx(_stoneDark), niche = hx(const Color(0xFF2D5A4B));
  final moss = hx(const Color(0xFF58B25E)), mossDark = hx(const Color(0xFF3E9A55)), mossLight = hx(const Color(0xFF9AD25A));
  final th = h * 0.062 * sc;
  const tiers = 4;
  final widths = <double>[for (var i = 0; i < tiers; i++) w * 0.8 * sc * (1 - 0.16 * i)];
  final r = rng(17);
  // stair first so the tiers' faces can overlap it
  for (var i = 0; i < tiers; i++) {
    final tw = widths[i];
    final yb = baseY - i * th, yt = yb - th;
    final inset = th * 0.1;
    final face = Path()
      ..moveTo(cx - tw / 2, yb)
      ..lineTo(cx - tw / 2 + inset, yt)
      ..lineTo(cx + tw / 2 - inset, yt)
      ..lineTo(cx + tw / 2, yb)
      ..close();
    c.drawPath(face, _f(stone));
    c
      ..save()
      ..clipPath(face)
      ..drawRect(Rect.fromLTRB(cx + tw * 0.2, yt - 2, cx + tw, yb + 2), _f(stoneShade))
      ..drawRect(Rect.fromLTRB(cx - tw, yt, cx + tw, yt + th * 0.16), _f(mix(stone, stoneShade, 0.55)))
      ..restore();
    // top slab lip
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - tw / 2 + inset * 0.2, yt - th * 0.1, cx + tw / 2 - inset * 0.2, yt + th * 0.08), Radius.circular(th * 0.05)), _f(stoneLight));
    // carved niches
    final nn = (tw / (th * 1.05)).floor();
    final stairHalf = widths[tiers - 1] * 0.3 + (tiers - i) * w * 0.012 * sc;
    for (var j = 0; j < nn; j++) {
      final x = cx - tw / 2 + tw * (j + 0.5) / nn;
      if ((x - cx).abs() < stairHalf) continue;
      final nw = th * 0.34, nh = th * 0.5;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, yt + th * 0.52), width: nw, height: nh), Radius.circular(nw * 0.5)), _f(niche));
      c.drawRect(Rect.fromLTWH(x - nw * 0.5, yt + th * 0.52 + nh * 0.2, nw, nh * 0.3), _f(darken(niche, 0.04)));
    }
    // moss cap with drips
    final top = <Offset>[];
    final bot = <Offset>[];
    final steps = (tw / (th * 0.55)).round().clamp(5, 24);
    for (var j = 0; j <= steps; j++) {
      final t = j / steps;
      final x = cx - tw / 2 + inset * 0.2 + (tw - inset * 0.4) * t;
      top.add(Offset(x, yt - th * 0.14 - r.nextDouble() * th * 0.05));
      bot.add(Offset(x, yt + th * (0.05 + (r.nextDouble() < 0.4 ? 0.25 + r.nextDouble() * 0.4 : 0.1))));
    }
    final mp = smoothPath([...top, ...bot.reversed], closed: true);
    c.drawPath(mp, _f(mossDark));
    c
      ..save()
      ..clipPath(mp)
      ..drawPath(mp.shift(Offset(th * 0.05, th * 0.09)), _f(moss))
      ..restore();
    // moss highlight crescent on the left lit end
    c.drawCircle(Offset(cx - tw / 2 + th * 0.55, yt - th * 0.1), th * 0.12, _f(mossLight));
  }
  // central stair
  final stTop = baseY - tiers * th + th * 0.05;
  final bw = widths[0] * 0.2, tw2 = widths[tiers - 1] * 0.28;
  const steps = 20;
  for (var i = 0; i < steps; i++) {
    final t0 = i / steps, t1 = (i + 1) / steps;
    final y0 = baseY - (baseY - stTop) * t0, y1 = baseY - (baseY - stTop) * t1;
    final h0 = bw + (tw2 - bw) * t0, h1 = bw + (tw2 - bw) * t1;
    final tread = i.isEven ? stoneLight : mix(stoneLight, stone, 0.55);
    c.drawPath(
        Path()
          ..moveTo(cx - h0 / 2, y0)
          ..lineTo(cx - h1 / 2, y1)
          ..lineTo(cx + h1 / 2, y1)
          ..lineTo(cx + h0 / 2, y0)
          ..close(),
        _f(tread));
    c.drawRect(Rect.fromLTRB(cx - h0 / 2, y0 - (y0 - y1) * 0.35, cx + h0 / 2, y0), _f(stoneShade.withValues(alpha: 0.55)));
  }
  // moss patches on the stairs
  for (var i = 0; i < 5; i++) {
    final t = 0.1 + r.nextDouble() * 0.75;
    final x = cx + (r.nextDouble() - 0.5) * (bw + (tw2 - bw) * t) * 0.8;
    final y = baseY - (baseY - stTop) * t;
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: th * (0.5 + r.nextDouble() * 0.6), height: th * 0.22), _f(moss));
  }
  // shrine
  final sw = widths[tiers - 1] * 0.82, sh = h * 0.088 * sc;
  final sx = cx, sy = baseY - tiers * th;
  final shrine = RRect.fromRectAndCorners(Rect.fromLTRB(sx - sw / 2, sy - sh, sx + sw / 2, sy + 1), topLeft: Radius.circular(sw * 0.04), topRight: Radius.circular(sw * 0.04));
  c.drawRRect(shrine, _f(stone));
  c
    ..save()
    ..clipRRect(shrine)
    ..drawRect(Rect.fromLTRB(sx + sw * 0.18, sy - sh, sx + sw, sy + 2), _f(stoneShade))
    ..restore();
  // doorway: dark arch with a warm golden inside
  final dw = sw * 0.38, dh = sh * 0.62;
  Path arch(double inset) => Path()
    ..moveTo(sx - dw / 2 + inset, sy)
    ..lineTo(sx - dw / 2 + inset, sy - dh + dw / 2)
    ..arcToPoint(Offset(sx + dw / 2 - inset, sy - dh + dw / 2), radius: Radius.circular(dw / 2 - inset))
    ..lineTo(sx + dw / 2 - inset, sy)
    ..close();
  c.drawPath(arch(0), _f(hx(_shadow)));
  c.drawPath(arch(dw * 0.12), _f(hazeTo(_gold, _haze, hz * 0.4)));
  c.drawPath(
      Path()
        ..moveTo(sx - dw / 2 + dw * 0.12, sy)
        ..lineTo(sx - dw / 2 + dw * 0.12, sy - dh * 0.35)
        ..lineTo(sx + dw / 2 - dw * 0.12, sy - dh * 0.35)
        ..lineTo(sx + dw / 2 - dw * 0.12, sy)
        ..close(),
      _f(hazeTo(const Color(0xFFFFE9A8), _haze, hz * 0.4)));
  // totem eyes / glyph band above door
  final gy = sy - sh * 0.86;
  for (final dx in [-0.3, 0.3]) {
    c.drawCircle(Offset(sx + sw * dx, gy + sh * 0.06), sh * 0.075, _f(hx(_turq)));
    c.drawCircle(Offset(sx + sw * dx, gy + sh * 0.06), sh * 0.03, _f(hx(_gold)));
  }
  // roof slabs + comb
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(sx - sw * 0.6, sy - sh - sh * 0.1, sx + sw * 0.6, sy - sh + sh * 0.04), Radius.circular(sh * 0.04)), _f(stoneLight));
  c.drawRect(Rect.fromLTRB(sx - sw * 0.6 + sw * 0.9, sy - sh - sh * 0.1, sx + sw * 0.6, sy - sh + sh * 0.04), _f(stone));
  c.drawRect(Rect.fromLTRB(sx - sw * 0.6, sy - sh - sh * 0.02, sx + sw * 0.6, sy - sh + sh * 0.04), _f(stoneShade.withValues(alpha: 0.5)));
  var cw = sw * 0.8, cy = sy - sh - sh * 0.1;
  for (var i = 0; i < 3; i++) {
    final chh = sh * (0.17 - i * 0.025);
    final rr = RRect.fromRectAndRadius(Rect.fromLTRB(sx - cw / 2, cy - chh, sx + cw / 2, cy + 1), Radius.circular(sh * 0.03));
    c.drawRRect(rr, _f(i.isEven ? stone : stoneLight));
    c
      ..save()
      ..clipRRect(rr)
      ..drawRect(Rect.fromLTRB(sx + cw * 0.22, cy - chh, sx + cw, cy + 1), _f(stoneShade))
      ..restore();
    cy -= chh;
    cw *= 0.62;
  }
  // sun-disc emblem on top
  c.drawCircle(Offset(sx, cy - sh * 0.1), sh * 0.1, _f(hx(_turq)));
  c.drawCircle(Offset(sx - sh * 0.015, cy - sh * 0.115), sh * 0.045, _f(hx(_gold)));
  // overgrowth: leafy clumps on the terraces and roof
  for (var i = 0; i < tiers; i++) {
    final tw = widths[i];
    final yt = baseY - (i + 1) * th;
    for (final sd in [-1, 1]) {
      final x = cx + sd * (tw / 2 - th * (0.5 + r.nextDouble() * 0.4));
      flatBush(c, Offset(x, yt + th * 0.12), th * (0.75 + r.nextDouble() * 0.4), seed: i * 3 + (sd + 1), color: mossDark, light: moss);
    }
  }
  flatBush(c, Offset(sx - sw * 0.5, sy - sh * 0.95), th * 0.8, seed: 77, color: mossDark, light: moss);
  flatTree(c, Offset(sx + sw * 0.58, sy - sh * 0.04), th * 1.25, crown: mossDark, light: moss, trunk: hx(const Color(0xFF4F6A4A)), trunkShade: hx(const Color(0xFF3F5A3F)), seed: 21, lean: 0.3);
  // hanging vines down the terraces
  for (var i = 0; i < 6; i++) {
    final tier = r.nextInt(tiers);
    final tw = widths[tier];
    final x = cx + (r.nextDouble() - 0.5) * tw * 0.9;
    final yt = baseY - (tier + 1) * th;
    if ((x - cx).abs() < bw * 0.5) continue;
    final len = th * (0.8 + r.nextDouble() * 1.4);
    c.drawPath(
        smoothPath([Offset(x, yt + th * 0.2), Offset(x + 2, yt + len * 0.5), Offset(x - 1, yt + len)]),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.4, th * 0.07)
          ..color = mossDark);
    c.drawCircle(Offset(x - 1, yt + len), th * 0.1, _f(moss));
  }
  // ground apron: base shadow
  c.drawOval(Rect.fromCenter(center: Offset(cx, baseY + th * 0.12), width: widths[0] * 1.08, height: th * 0.5), _f(hx(const Color(0xFF3E9A55))));
  if (w < 0) c.drawPaint(_f(_shadow));
}

// ---------------------------------------------------------------- mid trees

void _midTrees(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(23);
  const crowns = [Color(0xFF3FA683), Color(0xFF2E9370), Color(0xFF217D5F)];
  for (var row = 0; row < 3; row++) {
    final ridge = Ridge(s, y: 0.575 + row * 0.04, amp: 0.01, freq: 3, seed: 90 + row);
    final col = crowns[row];
    var x = -w * 0.06;
    while (x < w * 1.06) {
      final th = h * (0.07 + r.nextDouble() * 0.04) * (1 + row * 0.22);
      final base = Offset(x, ridge.yAt(x) + 3);
      final roll = r.nextDouble();
      if (roll < 0.3 && (x - w * 0.6).abs() > w * 0.3) {
        _palm(c, base, th * 1.5, (r.nextDouble() - 0.5) * 0.25, mix(col, const Color(0xFF6B5A3A), 0.35), lighten(col, 0.06 + row * 0.01), darken(col, 0.04), fronds: 8);
      } else {
        flatTree(c, base, th, crown: col, light: lighten(col, 0.08), trunk: darken(col, 0.16), trunkShade: darken(col, 0.2), seed: r.nextInt(999), lean: (r.nextDouble() - 0.5) * 0.3, crownScale: 1.2);
      }
      x += th * (0.5 + r.nextDouble() * 0.35);
    }
    flatRidge(c, ridge, col);
  }
  // dark understory ridge
  final und = Ridge(s, y: 0.7, amp: 0.012, freq: 2.2, seed: 5);
  flatRidge(c, und, const Color(0xFF176B52), light: const Color(0xFF3F9E6C), band: 3);
}

// ---------------------------------------------------------------- cliff, waterfall, pool, ground

const _rockLit = Color(0xFF86AB8F), _rockMid = Color(0xFF668F78), _rockShade = Color(0xFF477562);

void _cliffAndGround(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(37);
  // cliff on the left
  final cliff = smoothPath([
    Offset(-w * 0.15, h * 0.95),
    Offset(-w * 0.15, h * 0.2),
    Offset(-w * 0.02, h * 0.135),
    Offset(w * 0.12, h * 0.125),
    Offset(w * 0.26, h * 0.15),
    Offset(w * 0.33, h * 0.26),
    Offset(w * 0.345, h * 0.5),
    Offset(w * 0.36, h * 0.8),
    Offset(w * 0.3, h * 0.95),
  ], closed: true);
  c.drawPath(cliff, _f(_rockMid));
  c
    ..save()
    ..clipPath(cliff)
    ..drawRect(Rect.fromLTRB(w * 0.2, 0, w, h), _f(_rockShade))
    ..drawPath(smoothPath([Offset(-w * 0.15, h * 0.2), Offset(-w * 0.02, h * 0.135), Offset(w * 0.1, h * 0.128), Offset(w * 0.06, h * 0.3), Offset(-w * 0.15, h * 0.42)], closed: true), _f(_rockLit))
    ..restore();
  // rock ledges
  for (var i = 0; i < 6; i++) {
    final y = h * (0.22 + i * 0.1 + r.nextDouble() * 0.03);
    final x = w * (0.0 + r.nextDouble() * 0.28);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: w * (0.1 + r.nextDouble() * 0.08), height: h * 0.012), const Radius.circular(5)), _f(i.isEven ? _rockLit : _rockShade));
  }
  // boulders stacked along the cliff face (rounded, two flat tones)
  for (var i = 0; i < 7; i++) {
    final bx = w * (0.27 + r.nextDouble() * 0.07), by = h * (0.22 + i * 0.085);
    final bw = w * (0.075 + r.nextDouble() * 0.05);
    final bp = blobPath(Offset(bx, by), bw, bw * 0.62, seed: 300 + i, wobble: 0.08);
    c.drawPath(bp, _f(_rockMid));
    c
      ..save()
      ..clipPath(bp)
      ..drawPath(bp.shift(Offset(bw * 0.18, bw * 0.16)), _f(_rockShade))
      ..drawPath(blobPath(Offset(bx - bw * 0.3, by - bw * 0.3), bw * 0.4, bw * 0.16, seed: 330 + i, wobble: 0.08), _f(_rockLit))
      ..restore();
    c
      ..save()
      ..clipPath(bp)
      ..drawOval(Rect.fromCenter(center: Offset(bx - bw * 0.05, by - bw * 0.62), width: bw * 2.4, height: bw * 0.95), _f(const Color(0xFF3E9A55)))
      ..drawOval(Rect.fromCenter(center: Offset(bx - bw * 0.2, by - bw * 0.7), width: bw * 1.6, height: bw * 0.7), _f(const Color(0xFF58B25E)))
      ..restore();
  }
  // mossy top of cliff + overhang
  final mossTop = smoothPath([
    Offset(-w * 0.16, h * 0.2),
    Offset(-w * 0.02, h * 0.125),
    Offset(w * 0.12, h * 0.115),
    Offset(w * 0.27, h * 0.145),
    Offset(w * 0.3, h * 0.19),
    Offset(w * 0.25, h * 0.2),
    Offset(w * 0.2, h * 0.17),
    Offset(w * 0.1, h * 0.165),
    Offset(w * 0.0, h * 0.2),
    Offset(-w * 0.1, h * 0.215),
  ], closed: true);
  c.drawPath(mossTop, _f(const Color(0xFF3E9A55)));
  c
    ..save()
    ..clipPath(mossTop)
    ..drawPath(mossTop.shift(Offset(3, 6)), _f(const Color(0xFF58B25E)))
    ..restore();
  // waterfall: lip at the top, falls to the pool
  final fx = w * 0.15;
  final fall = Path()
    ..moveTo(fx - w * 0.04, h * 0.165)
    ..cubicTo(fx - w * 0.045, h * 0.4, fx - w * 0.05, h * 0.6, fx - w * 0.06, h * 0.805)
    ..lineTo(fx + w * 0.075, h * 0.805)
    ..cubicTo(fx + w * 0.06, h * 0.6, fx + w * 0.05, h * 0.4, fx + w * 0.045, h * 0.165)
    ..close();
  c.drawPath(fall, _f(const Color(0xFF63D6CF)));
  c
    ..save()
    ..clipPath(fall)
    ..drawRect(Rect.fromLTRB(fx + w * 0.012, 0, w, h), _f(const Color(0xFF3CC9C0)))
    ..drawRect(Rect.fromLTRB(fx - w * 0.07, 0, fx - w * 0.02, h), _f(const Color(0xFF8DEBE0)))
    ..restore();
  // foam and mist at the base
  for (var i = 0; i < 7; i++) {
    c.drawCircle(Offset(fx - w * 0.05 + i * w * 0.02, h * 0.805 + (i.isEven ? 2 : -3)), w * (0.02 + (i % 3) * 0.006), _f(const Color(0xFFE8FFF6)));
  }
  // moss clumps and ferns at the cliff foot
  for (var i = 0; i < 4; i++) {
    flatBush(c, Offset(w * (0.0 + i * 0.12), h * (0.79 + (i % 2) * 0.02)), w * 0.2, seed: 110 + i, color: const Color(0xFF176B52), light: const Color(0xFF2E9370));
  }
  // jungle ground planes
  final g1 = Ridge(s, y: 0.835, amp: 0.012, freq: 1.8, seed: 12, tilt: 0.03);
  flatRidge(c, g1, const Color(0xFF1C7A58), light: const Color(0xFF6DBF58), band: 3);
  // pool / stream
  final pool = Path()
    ..moveTo(-w * 0.1, h * 0.845)
    ..cubicTo(w * 0.1, h * 0.815, w * 0.32, h * 0.83, w * 0.46, h * 0.88)
    ..cubicTo(w * 0.58, h * 0.93, w * 0.62, h * 1.0, w * 0.66, h * 1.1)
    ..lineTo(-w * 0.1, h * 1.1)
    ..close();
  c.drawPath(pool.shift(const Offset(0, 4)), _f(const Color(0xFF1C7A58)));
  c.drawPath(pool, _f(const Color(0xFF2AB5B3)));
  c
    ..save()
    ..clipPath(pool)
    ..drawPath(pool.shift(Offset(0, h * 0.04)), _f(const Color(0xFF1EA3A6)))
    ..restore();
  // ripples (flat arcs)
  final rip = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.2
    ..color = const Color(0xFF9DEFE4);
  for (var i = 0; i < 9; i++) {
    final x = w * (0.04 + r.nextDouble() * 0.4), y = h * (0.87 + r.nextDouble() * 0.12);
    final rw = w * (0.04 + r.nextDouble() * 0.05);
    c.drawArc(Rect.fromCenter(center: Offset(x, y), width: rw, height: rw * 0.3), 0.2, 2.7, false, rip);
  }
  // stepping stones across the water
  for (var i = 0; i < 4; i++) {
    final x = w * (0.1 + i * 0.1), y = h * (0.915 + i * 0.012);
    flatRock(c, Offset(x, y), w * 0.11, h * 0.02, seed: 50 + i, color: _stone, shade: _stoneDark);
    c.drawOval(Rect.fromCenter(center: Offset(x - w * 0.015, y - h * 0.016), width: w * 0.05, height: h * 0.01), _f(const Color(0xFF7BBF4A)));
  }
  // right ground
  final g2 = Ridge(s, y: 0.9, amp: 0.012, freq: 1.5, seed: 44, tilt: -0.06);
  flatRidge(c, g2, const Color(0xFF14664C), light: const Color(0xFF58B25E), band: 3);
  _ruinsRight(c, s);
  // lower ground
  final g3 = Ridge(s, y: 0.965, amp: 0.012, freq: 1.2, seed: 18, tilt: 0.02);
  flatRidge(c, g3, const Color(0xFF0E4D3A), light: const Color(0xFF2E9370), band: 3);
}

void _ruinsRight(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final bx = w * 0.8, by = h * 0.925;
  // fallen stone steps
  for (var i = 0; i < 4; i++) {
    final x = bx - w * 0.14 + i * w * 0.045, y = by - i * h * 0.012;
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, y - h * 0.02, w * 0.14, h * 0.028), Radius.circular(h * 0.006));
    c.drawRRect(rr, _f(_stone));
    c
      ..save()
      ..clipRRect(rr)
      ..drawRect(Rect.fromLTWH(x + w * 0.08, y - h * 0.02, w * 0.1, h * 0.03), _f(_stoneDark))
      ..drawRect(Rect.fromLTWH(x, y - h * 0.02, w * 0.14, h * 0.007), _f(const Color(0xFFD1DDBE)))
      ..restore();
    c.drawOval(Rect.fromLTWH(x + w * 0.01, y - h * 0.026, w * 0.06, h * 0.014), _f(_moss));
  }
  // broken pillar
  final px = w * 0.9;
  final pillar = RRect.fromRectAndCorners(Rect.fromLTRB(px - w * 0.045, by - h * 0.12, px + w * 0.045, by + h * 0.02), topLeft: Radius.circular(w * 0.01), topRight: Radius.circular(w * 0.03));
  c.drawRRect(pillar, _f(_stone));
  c
    ..save()
    ..clipRRect(pillar)
    ..drawRect(Rect.fromLTRB(px + w * 0.01, by - h * 0.13, px + w * 0.06, by + h * 0.03), _f(_stoneDark))
    ..restore();
  c.drawRect(Rect.fromLTRB(px - w * 0.045, by - h * 0.075, px + w * 0.045, by - h * 0.068), _f(_stoneDark));
  c.drawRect(Rect.fromLTRB(px - w * 0.045, by - h * 0.03, px + w * 0.045, by - h * 0.023), _f(_stoneDark));
  final cap = smoothPath([Offset(px - w * 0.05, by - h * 0.115), Offset(px - w * 0.02, by - h * 0.133), Offset(px + w * 0.03, by - h * 0.128), Offset(px + w * 0.05, by - h * 0.105), Offset(px + w * 0.0, by - h * 0.1)], closed: true);
  c.drawPath(cap, _f(const Color(0xFF58B25E)));
  c.drawCircle(Offset(px, by - h * 0.05), w * 0.016, _f(_turq));
  c.drawCircle(Offset(px, by - h * 0.05), w * 0.007, _f(_gold));
  flatBush(c, Offset(px - w * 0.05, by + h * 0.02), w * 0.2, seed: 7, color: const Color(0xFF14664C), light: const Color(0xFF2E9370));
}

// ---------------------------------------------------------------- live waterfall

void _waterfallLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final fx = w * 0.15;
  final x0 = fx - w * 0.04, x1 = fx + w * 0.045;
  final top = h * 0.17, bot = h * 0.8;
  final p = Paint()..color = const Color(0xFFEFFFF8);
  for (var i = 0; i < 9; i++) {
    final col = (i + 0.5) / 9;
    final x = x0 + (x1 - x0) * col - (col - 0.5) * 0.0 + (i % 2 == 0 ? -1 : 1);
    final cyc = 6 + i % 3 * 2;
    final t = k.saw(cyc, i * 0.37);
    final len = h * (0.05 + (i % 3) * 0.025);
    final y = top + (bot - top + len) * t - len;
    final a = math.max(top, y), b = math.min(bot, y + len);
    if (b <= a) continue;
    // fall slightly widens towards the bottom
    final widen = (a - top) / (bot - top) * w * 0.012;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - 1.6 + (col - 0.5) * widen * 2, a, x + 1.6 + (col - 0.5) * widen * 2, b), const Radius.circular(1.6)), p..color = const Color(0xFFEFFFF8).withValues(alpha: 0.85));
  }
  // foam puffs pulsing at the base
  for (var i = 0; i < 5; i++) {
    final a = 0.35 + 0.35 * k.pulse(10 + i, i * 0.2);
    c.drawCircle(Offset(fx - w * 0.04 + i * w * 0.025, h * 0.797 - k.pulse(8 + i, i * 0.3) * 3), w * 0.012, _f(Colors.white.withValues(alpha: a)));
  }
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.02, 0.88, 0.45, 0.99), count: 14, seed: 9, color: const Color(0xFFE9FFF9), cycles: 8);
}

// ---------------------------------------------------------------- sunbeams

void _rays(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final o = Offset(-w * 0.1, -h * 0.08);
  final r = rng(12);
  final angles = [0.62, 0.8, 0.98, 1.16, 1.34, 0.46];
  for (var i = 0; i < angles.length; i++) {
    final a = angles[i];
    final wd = 0.035 + r.nextDouble() * 0.04;
    final len = h * 1.6;
    final p1 = o + Offset(math.cos(a - wd / 2), math.sin(a - wd / 2)) * len;
    final p2 = o + Offset(math.cos(a + wd / 2), math.sin(a + wd / 2)) * len;
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    c.drawPath(path, _f(const Color(0xFFFFE9A0).withValues(alpha: 0.1)));
    final a2 = a + (r.nextDouble() - 0.5) * 0.01;
    final w2 = wd * 0.4;
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + math.cos(a2 - w2 / 2) * len, o.dy + math.sin(a2 - w2 / 2) * len)
          ..lineTo(o.dx + math.cos(a2 + w2 / 2) * len, o.dy + math.sin(a2 + w2 / 2) * len)
          ..close(),
        _f(const Color(0xFFFFF4C2).withValues(alpha: 0.08)));
  }
}

// ---------------------------------------------------------------- big trunks

void _trunkAt(Canvas c, Size s, double xc, double tw, {required bool left, required int seed}) {
  final w = s.width, h = s.height;
  const bark = Color(0xFF3B5B3E), barkLit = Color(0xFF55804F), barkShade = Color(0xFF254632);
  final dir = left ? 1.0 : -1.0;
  final path = Path()
    ..moveTo(xc - tw * 0.5, -h * 0.1)
    ..cubicTo(xc - tw * 0.52, h * 0.3, xc - tw * 0.42, h * 0.6, xc - tw * 0.55, h * 0.88)
    ..cubicTo(xc - tw * 0.7, h * 0.96, xc - tw * 1.3, h * 0.98, xc - tw * 1.9, h * 1.1)
    ..lineTo(xc + tw * 1.9, h * 1.1)
    ..cubicTo(xc + tw * 1.3, h * 0.98, xc + tw * 0.7, h * 0.96, xc + tw * 0.55, h * 0.88)
    ..cubicTo(xc + tw * 0.42, h * 0.6, xc + tw * 0.5, h * 0.3, xc + tw * 0.5, -h * 0.1)
    ..close();
  c.drawPath(path, _f(bark));
  c
    ..save()
    ..clipPath(path)
    ..drawRect(Rect.fromLTRB(xc + tw * 0.08, -h * 0.1, xc + tw * 3, h * 1.2), _f(barkShade))
    ..drawRect(Rect.fromLTRB(xc - tw * 3, -h * 0.1, xc - tw * 0.28, h * 1.2), _f(barkLit))
    ..restore();
  // bark ridges (flat curved strokes)
  final r = rng(seed);
  final ridge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.4
    ..color = const Color(0xFF1A3626);
  for (var i = 0; i < 10; i++) {
    final x = xc + (r.nextDouble() - 0.35) * tw * 0.8;
    final y = h * (0.05 + r.nextDouble() * 0.8);
    final l = h * (0.04 + r.nextDouble() * 0.07);
    c.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 5 * dir, y + l * 0.5, x - 1, y + l),
        ridge);
  }
  // moss on the lit side, in clumps
  for (var i = 0; i < 5; i++) {
    final y = h * (0.12 + i * 0.17 + r.nextDouble() * 0.05);
    final mp = blobPath(Offset(xc - tw * 0.3, y), tw * 0.32, h * 0.03, seed: seed + i, wobble: 0.18);
    c
      ..save()
      ..clipPath(path)
      ..drawPath(mp, _f(const Color(0xFF58B25E)))
      ..drawPath(blobPath(Offset(xc - tw * 0.36, y - 4), tw * 0.16, h * 0.014, seed: seed + i + 9, wobble: 0.15), _f(const Color(0xFF9AD25A)))
      ..restore();
  }
  if (w < 0) c.drawPaint(_f(_shadow));
}

void _trunks(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _trunkAt(c, s, w * 0.0, w * 0.2, left: true, seed: 3);
  _trunkAt(c, s, w * 1.0, w * 0.17, left: false, seed: 8);
  // leafy bracket on trunks
  for (final (x, y, sd) in [(w * 0.1, h * 0.52, 1.0), (w * 0.9, h * 0.38, -1.0), (w * 0.08, h * 0.2, 1.0)]) {
    for (var i = 0; i < 4; i++) {
      _blade(c, Offset(x - sd * w * 0.04, y), w * (0.14 + i * 0.015), sd * (1.0 + i * 0.28) + 0.0, w * 0.035, const Color(0xFF2E9A70), const Color(0xFF14664C), droop: 0.35, rib: const Color(0xFF0E4D3A));
    }
  }
}

// ---------------------------------------------------------------- canopy

void _canopy(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(55);
  // back leafy mass along the top
  final back = <(Offset, double)>[];
  for (var x = -0.12; x < 1.14; x += 0.07) {
    // leave a few gaps so the sun can enter
    final gap = (x > 0.14 && x < 0.3) ? 1.0 : (x > 0.5 && x < 0.62 ? 0.65 : 0.0);
    final yy = h * (0.045 + 0.02 * math.sin(x * 9)) - gap * h * 0.07;
    back.add((Offset(w * x, yy + r.nextDouble() * h * 0.01), w * (0.09 + r.nextDouble() * 0.03)));
  }
  _puffs(c, back, const Color(0xFF0B4033), const Color(0xFF1D7C5B), mid: const Color(0xFF14624A));
  // large fronds hanging from top corners
  for (var i = 0; i < 6; i++) {
    _frond(c, Offset(-w * 0.04, h * 0.0), h * (0.19 + (i % 3) * 0.03), 0.9 + i * 0.28, const Color(0xFF2FA37A), const Color(0xFF14664C), droop: 0.55, leaf: 0.3, count: 11, spine: const Color(0xFF0E4D3A));
  }
  for (var i = 0; i < 6; i++) {
    _frond(c, Offset(w * 1.05, h * 0.0), h * (0.19 + (i % 3) * 0.03), -0.9 - i * 0.28, const Color(0xFF2FA37A), const Color(0xFF14664C), droop: 0.55, leaf: 0.3, count: 11, spine: const Color(0xFF0E4D3A));
  }
  // middle top fronds
  for (final (x, a) in [(0.46, 0.5), (0.56, -0.5), (0.7, -0.3), (0.34, 0.4)]) {
    _frond(c, Offset(w * x, -h * 0.01), h * 0.15, a + math.pi * 0.5 * (a > 0 ? 1 : -1) * 0.7, const Color(0xFF3FB383), const Color(0xFF1C7A58), droop: 0.5, leaf: 0.28, count: 9);
  }
  // front scalloped edge, darker, with a lit crescent
  final front = <(Offset, double)>[];
  for (var x = -0.1; x < 1.12; x += 0.1) {
    final gap = (x > 0.12 && x < 0.32) ? 1.0 : 0.0;
    front.add((Offset(w * x, h * 0.0 - gap * h * 0.05), w * (0.085 + r.nextDouble() * 0.03)));
  }
  _puffs(c, front, const Color(0xFF083528), const Color(0xFF1B7556), mid: const Color(0xFF0E4D3A));
}

// ---------------------------------------------------------------- hanging vines

void _vines(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(61);
  const xs = [0.04, 0.11, 0.2, 0.33, 0.42, 0.55, 0.66, 0.77, 0.86, 0.94];
  for (var i = 0; i < xs.length; i++) {
    final x = w * (xs[i] + (r.nextDouble() - 0.5) * 0.02);
    final len = h * (0.1 + r.nextDouble() * 0.18);
    _vine(c, x, -h * 0.01, len, 200 + i, color: i.isEven ? const Color(0xFF14664C) : const Color(0xFF0E4D3A), leafLight: i % 3 == 0 ? _moss : const Color(0xFF3FB383), leafDark: const Color(0xFF1C7A58), thick: 2.6 + r.nextDouble() * 1.4);
  }
  // a few thick lianas hanging from the canopy at the sides
  _vine(c, w * 0.17, -h * 0.01, h * 0.34, 300, color: const Color(0xFF0E4D3A), leafLight: _moss, leafDark: const Color(0xFF2E9A55), thick: 5, leafSize: 1.3);
  _vine(c, w * 0.88, -h * 0.01, h * 0.3, 301, color: const Color(0xFF0E4D3A), leafLight: _moss, leafDark: const Color(0xFF2E9A55), thick: 5, leafSize: 1.3);
  // orchids / red flowers on vines: a bright accent
  for (final (x, y) in [(w * 0.27, h * 0.14), (w * 0.72, h * 0.12), (w * 0.91, h * 0.24)]) {
    for (var i = 0; i < 5; i++) {
      final a = tau * i / 5;
      c.drawCircle(Offset(x + math.cos(a) * 4.5, y + math.sin(a) * 4.5), 3.4, _f(const Color(0xFFFF8A5C)));
    }
    c.drawCircle(Offset(x, y), 2.4, _f(_gold));
    c.drawLine(Offset(x, y - 5), Offset(x, y - h * 0.05), Paint()
      ..color = const Color(0xFF14664C)
      ..strokeWidth = 2);
  }
}

// ---------------------------------------------------------------- foreground

void _fern(Canvas c, Offset base, double len, double spreadA, int n, Color light, Color dark, {Color? spine}) {
  for (var i = 0; i < n; i++) {
    final a = n == 1 ? 0.0 : -spreadA + 2 * spreadA * i / (n - 1);
    _frond(c, base, len * (0.82 + 0.18 * math.cos(a * 1.4)), a, light, dark, droop: 0.28 + 0.3 * a.abs(), leaf: 0.3, count: 12, spread: 1.05, spine: spine ?? dark);
  }
}

void _foreA(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // big dark broad leaves in the bottom corners
  for (var i = 0; i < 4; i++) {
    _blade(c, Offset(-w * 0.04, h * 1.02), h * (0.2 + i * 0.03), 0.3 + i * 0.3, w * 0.11, const Color(0xFF237F5E), const Color(0xFF0F5640), droop: 0.1, rib: const Color(0xFF0E4D3A), ribW: 2);
  }
  for (var i = 0; i < 3; i++) {
    _blade(c, Offset(w * 1.04, h * 1.02), h * (0.2 + i * 0.03), -0.3 - i * 0.3, w * 0.11, const Color(0xFF237F5E), const Color(0xFF0F5640), droop: 0.1, rib: const Color(0xFF0E4D3A), ribW: 2);
  }
  _fern(c, Offset(w * 0.3, h * 1.02), h * 0.17, 1.1, 7, const Color(0xFF3FB383), const Color(0xFF1C7A58));
  _fern(c, Offset(w * 0.74, h * 1.02), h * 0.15, 1.1, 7, const Color(0xFF58C28A), const Color(0xFF2E9A70));
}

void _foreB(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _fern(c, Offset(w * 0.1, h * 1.03), h * 0.22, 1.2, 8, const Color(0xFF58C28A), const Color(0xFF1C7A58));
  _fern(c, Offset(w * 0.92, h * 1.03), h * 0.2, 1.2, 8, const Color(0xFF3FB383), const Color(0xFF14664C));
  _fern(c, Offset(w * 0.52, h * 1.06), h * 0.11, 1.0, 5, const Color(0xFF7BBF4A), const Color(0xFF2E9A55));
  // tall palm fronds at the very corners, dark
  _frond(c, Offset(-w * 0.03, h * 0.98), h * 0.26, 0.55, const Color(0xFF237F5E), const Color(0xFF0B4033), droop: 0.45, leaf: 0.3, count: 12);
  _frond(c, Offset(w * 1.03, h * 0.98), h * 0.26, -0.55, const Color(0xFF237F5E), const Color(0xFF0B4033), droop: 0.45, leaf: 0.3, count: 12);
  // little flowers in the foreground
  final r = rng(91);
  for (var i = 0; i < 7; i++) {
    final x = w * (r.nextDouble() < 0.5 ? 0.05 + r.nextDouble() * 0.25 : 0.7 + r.nextDouble() * 0.25);
    final y = h * (0.94 + r.nextDouble() * 0.05);
    c.drawCircle(Offset(x, y), 3.2, _f(i % 2 == 0 ? const Color(0xFFFF8A5C) : const Color(0xFFFFE08A)));
    c.drawCircle(Offset(x, y), 1.2, _f(Colors.white));
  }
}

// ---------------------------------------------------------------- motes and birds

void _motesAndBirds(Canvas c, Size s, Clock k) {
  // glowing motes drifting up in the sunbeams
  paintParticles(c, s, k, const ParticleSpec(count: 40, seed: 4, colors: [Color(0xFFFFE9A0), Color(0xFFFFF6D0)], minSize: 1.1, maxSize: 2.4, flow: Offset(0.04, -0.12), cycles: 1, spread: 2, wander: 14, twinkle: 0.5, twinkleCycles: 9, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.05, 0.9, 0.95), haloScale: 2.4));
  paintParticles(c, s, k, const ParticleSpec(count: 12, seed: 9, colors: [Color(0xFFB8FF8A), Color(0xFF9FF0E0)], minSize: 1.6, maxSize: 2.8, flow: Offset(0.0, -0.04), cycles: 1, spread: 1, wander: 22, twinkle: 0.7, twinkleCycles: 7, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.5, 1.0, 0.97), haloScale: 2.6));
  paintParticles(c, s, k, const ParticleSpec(count: 7, seed: 15, colors: [Color(0xFF7BBF4A), Color(0xFF3FB383)], minSize: 2.6, maxSize: 3.6, flow: Offset(0.12, 0.45), cycles: 2, spread: 1, wander: 20, shape: ParticleShape.leaf, region: Rect.fromLTRB(0.0, 0.0, 1.0, 1.0), spin: 1.5));
  // tropical birds crossing
  const cols = [Color(0xFFE5483B), Color(0xFF2FC4D6), Color(0xFFFFB63A)];
  for (var i = 0; i < 3; i++) {
    final ph = i * 0.33;
    final t = k.saw(i == 0 ? 1 : 2, ph);
    final dirR = i != 1;
    final x = dirR ? -30 + t * (s.width + 60) : s.width + 30 - t * (s.width + 60);
    final y = s.height * (0.1 + i * 0.07) + math.sin(tau * (k.u * (5 + i) + ph)) * 6;
    final flap = k.sine(40 + i * 4, ph);
    final sz = s.width / 390 * (8.5 - i * 0.8);
    c
      ..save()
      ..translate(x, y)
      ..scale(dirR ? 1 : -1, 1);
    // tail streak
    c.drawPath(
        Path()
          ..moveTo(-sz * 0.7, 0)
          ..quadraticBezierTo(-sz * 1.8, sz * 0.15, -sz * 2.6, sz * 0.5)
          ..quadraticBezierTo(-sz * 1.8, -sz * 0.05, -sz * 0.7, -sz * 0.3)
          ..close(),
        _f(cols[i]));
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: sz * 1.8, height: sz * 0.85), _f(cols[i]));
    c.drawCircle(Offset(sz * 0.75, -sz * 0.12), sz * 0.3, _f(cols[i]));
    c.drawPath(
        Path()
          ..moveTo(sz * 1.0, -sz * 0.12)
          ..lineTo(sz * 1.45, -sz * 0.02)
          ..lineTo(sz * 1.0, sz * 0.1)
          ..close(),
        _f(const Color(0xFFFFF0C0)));
    paintBird(c, Offset(-sz * 0.1, -sz * 0.1), sz * 1.05, flap, darken(cols[i], 0.18));
    c.restore();
  }
}
