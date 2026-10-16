import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Enchanted Forest in flat, graphic 2D: big friendly clouds, layered green
// hills and woods, one ancient tree, a clear stream. Seeds and forest lights
// drift in the air. Flat colours, two-tone shading, smooth rounded shapes.

const _sun = Offset(0.78, 0.15); // fractions of the screen

// palette
const _skyTop = Color(0xFF4FA8DA), _skyMid = Color(0xFF8ED0EA), _skyLow = Color(0xFFEAF5DF);
const _cloud = Color(0xFFFFFFFF), _cloudShade = Color(0xFFCFE2F2);
const _hillFar = Color(0xFFA6D4C6), _hillFarShade = Color(0xFF8FC6B9), _hillMid = Color(0xFF8CC9B2), _hillMidShade = Color(0xFF76B9A2);
const _woodA = Color(0xFF6FB796), _woodB = Color(0xFF52A67F), _woodC = Color(0xFF3C9569);
const _woodLightA = Color(0xFF90CDAE), _woodLightB = Color(0xFF72BD94), _woodLightC = Color(0xFF58AC7D);
const _meadowA = Color(0xFF86C766), _meadowB = Color(0xFF63B552), _meadowC = Color(0xFF489F49);
const _meadowLight = Color(0xFFB3E27C);
const _crown = Color(0xFF2E9A58), _crownDark = Color(0xFF247F4B), _crownLight = Color(0xFF66C96A);
const _water = Color(0xFF55C0D6), _waterLight = Color(0xFF9BE3EA), _bank = Color(0xFF2F8F6A);

SceneSpec forestScene() => SceneSpec(
      focusY: -0.1,
      topShade: 0.14,
      bottomShade: 0.3,
      layers: [
        Layer.still(_sky),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.4),
        Layer.still(_mountains, driftX: 0.005, driftCycles: 2),
        Layer.scroll(_cloudsFront, scrollCycles: 2, bandTop: 0.2, bandBottom: 0.5),
        Layer.still(_woods, driftX: 0.01, driftCycles: 2, sway: 0.004, swayCycles: 5),
        Layer.still(_meadow, driftX: 0.016, driftCycles: 2, driftPhase: 0.1),
        Layer.still(_hero, driftX: 0.022, driftCycles: 2, driftPhase: 0.15, sway: 0.003, swayCycles: 4, pivot: const Alignment(-0.2, 1)),
        Layer.still(_stream, driftX: 0.028, driftCycles: 2, driftPhase: 0.2),
        Layer.live(_glints),
        Layer.still(_ground, driftX: 0.034, driftCycles: 2, driftPhase: 0.25),
        Layer.still(_foreLeaves, driftX: 0.05, driftCycles: 2, driftPhase: 0.3, sway: 0.006, swayCycles: 6, pivot: const Alignment(0, 1)),
        Layer.live(_seeds),
        Layer.live(_spirits),
        Layer.live(_butterflies),
      ],
    );

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  fillSky(c, s, const [_skyTop, _skyMid, _skyLow, Color(0xFFF7F1CF)], const [0.0, 0.25, 0.46, 1.0]);
  flatSun(c, Offset(_sun.dx * s.width, _sun.dy * s.height), s.width * 0.065);
}

void _cloudsBack(Canvas c, Size s) {
  final r = rng(7);
  for (var i = 0; i < 3; i++) {
    final x = (i + 0.3 + r.nextDouble() * 0.4) * s.width / 3;
    flatCloud(c, Offset(x, s.height * (0.15 + r.nextDouble() * 0.12)), s.width * (0.44 + r.nextDouble() * 0.16), color: _cloud, shade: _cloudShade, seed: i + 17, puff: 1.1);
  }
}

void _cloudsFront(Canvas c, Size s) {
  final r = rng(19);
  for (var i = 0; i < 2; i++) {
    final x = (i + 0.3 + r.nextDouble() * 0.4) * s.width / 2;
    flatCloud(c, Offset(x, s.height * (0.34 + r.nextDouble() * 0.05)), s.width * (0.28 + r.nextDouble() * 0.1), color: const Color(0xFFFFFFFF), shade: const Color(0xFFD8E8F4), seed: i + 31, puff: 0.9);
  }
}

void _mountains(Canvas c, Size s) {
  final far = Ridge(s, y: 0.43, amp: 0.04, freq: 1.4, seed: 12, octaves: 2, sharp: 0.35);
  flatMountains(c, far, _hillFar, _hillFarShade);
  final mid = Ridge(s, y: 0.46, amp: 0.03, freq: 2.0, seed: 5, octaves: 2, sharp: 0.25);
  flatMountains(c, mid, _hillMid, _hillMidShade);
}

// ---------------------------------------------------------------- woods

void _woods(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final r = rng(21);
  const crowns = [_woodA, _woodB, _woodC];
  const lights = [_woodLightA, _woodLightB, _woodLightC];
  for (var row = 0; row < 3; row++) {
    final ridge = Ridge(s, y: 0.505 + row * 0.03, amp: 0.008, freq: 3, seed: 40 + row);
    var x = -w * 0.05;
    while (x < w * 1.05) {
      final th = h * (0.085 + r.nextDouble() * 0.05) * (1 + row * 0.25);
      final base = Offset(x, ridge.yAt(x) + 3);
      if (r.nextDouble() < 0.28) {
        flatPine(c, base, th * 1.15, color: crowns[row], shade: darken(crowns[row], 0.05), tiers: 3);
      } else {
        flatTree(c, base, th, crown: crowns[row], light: lights[row], trunk: darken(crowns[row], 0.12), trunkShade: darken(crowns[row], 0.16), seed: r.nextInt(999), lean: (r.nextDouble() - 0.5) * 0.3);
      }
      x += th * (0.5 + r.nextDouble() * 0.35);
    }
    flatRidge(c, ridge, crowns[row]);
  }
}

void _meadow(Canvas c, Size s) {
  final ridge = Ridge(s, y: 0.62, amp: 0.02, freq: 1.7, seed: 77, tilt: 0.02);
  flatRidge(c, ridge, _meadowA, light: _meadowLight, band: 3);
  final r2 = Ridge(s, y: 0.7, amp: 0.018, freq: 1.3, seed: 31, tilt: -0.03);
  flatRidge(c, r2, _meadowB, light: const Color(0xFF9ED86E), band: 3);
  // tiny flowers
  final r = rng(8);
  const cols = [Color(0xFFFFFFFF), Color(0xFFFFF0A0), Color(0xFFC7B6F2)];
  for (var i = 0; i < 40; i++) {
    final x = r.nextDouble() * s.width;
    final y = s.height * (0.65 + r.nextDouble() * 0.2);
    c.drawCircle(Offset(x, y), 1.4 + r.nextDouble() * 0.8, Paint()..color = cols[i % 3]);
  }
}

// ---------------------------------------------------------------- the ancient tree

void _hero(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final base = Offset(w * 0.33, h * 0.79);
  final rr = rng(5);
  final cr = Offset(w * 0.3, h * 0.23);

  // contact shadow on the grass
  c.drawOval(Rect.fromCenter(center: base + Offset(w * 0.12, h * 0.035), width: w * 0.7, height: h * 0.05), Paint()..color = const Color(0x33103A20));

  // trunk: lit on the left, dark on the right, flaring into roots
  final trunk = Path()
    ..moveTo(base.dx - w * 0.22, base.dy + h * 0.035)
    ..cubicTo(base.dx - w * 0.1, base.dy + h * 0.0, base.dx - w * 0.095, base.dy - h * 0.1, base.dx - w * 0.085, base.dy - h * 0.2)
    ..cubicTo(base.dx - w * 0.078, base.dy - h * 0.34, base.dx - w * 0.07, base.dy - h * 0.44, base.dx - w * 0.055, base.dy - h * 0.57)
    ..lineTo(base.dx + w * 0.1, base.dy - h * 0.57)
    ..cubicTo(base.dx + w * 0.105, base.dy - h * 0.4, base.dx + w * 0.115, base.dy - h * 0.3, base.dx + w * 0.128, base.dy - h * 0.18)
    ..cubicTo(base.dx + w * 0.145, base.dy - h * 0.05, base.dx + w * 0.2, base.dy, base.dx + w * 0.32, base.dy + h * 0.035)
    ..close();
  final tb = trunk.getBounds();
  c.drawPath(
    trunk,
    Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF9A6A47), Color(0xFF7A5238), Color(0xFF4A2F22)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(tb),
  );
  c.save();
  c.clipPath(trunk);
  // soft bark grain: long curved strokes, low contrast
  final grain = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3
    ..color = const Color(0x333A2418);
  for (var i = 0; i < 9; i++) {
    final x = base.dx - w * 0.07 + w * 0.17 * rr.nextDouble();
    final y = base.dy - h * (0.1 + 0.4 * rr.nextDouble());
    final len = h * (0.06 + 0.08 * rr.nextDouble());
    c.drawPath(Path()..moveTo(x, y)..cubicTo(x + 5, y + len * 0.3, x - 4, y + len * 0.7, x + 2, y + len), grain);
  }
  // shade cast by the crown, and moss creeping up from the roots
  c.drawRect(
    Rect.fromLTRB(tb.left, base.dy - h * 0.57, tb.right, base.dy - h * 0.38),
    Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x66102A18), Color(0x00102A18)]).createShader(Rect.fromLTRB(tb.left, base.dy - h * 0.57, tb.right, base.dy - h * 0.38)),
  );
  final mossRect = Rect.fromLTRB(tb.left, base.dy - h * 0.14, tb.right, base.dy + h * 0.04);
  c.drawRect(mossRect, Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xCC5DB55A), Color(0x005DB55A)]).createShader(mossRect));
  c.restore();

  // crown: ~40 soft clumps, back to front, lit from the upper left
  final clumps = <(Offset, double, double)>[];
  for (var i = 0; i < 170; i++) {
    final a = rr.nextDouble() * tau, d = math.pow(rr.nextDouble(), 0.6).toDouble();
    final o = cr + Offset(math.cos(a) * d * w * 0.46, math.sin(a) * d * h * 0.17 + h * 0.01);
    final rad = w * (0.04 + 0.04 * rr.nextDouble()) * (1.1 - d * 0.3);
    clumps.add((o, rad, ((o.dy - (cr.dy - h * 0.17)) / (h * 0.34)).clamp(0.0, 1.0)));
  }
  clumps.sort((p, q) => p.$1.dy.compareTo(q.$1.dy));
  // dark body first so no sky shows between the puffs
  for (final (o, rad, _) in clumps) {
    c.drawCircle(o, rad * 1.25, Paint()..color = _crownDark);
  }
  for (final (o, rad, t) in clumps) {
    final mid = Color.lerp(_crown, _crownDark, t * 0.7)!;
    softClump(c, o, rad, light: Color.lerp(_crownLight, mid, 0.25 + 0.5 * t)!, mid: mid, dark: darken(mid, 0.05));
  }
  // sun-dapples on the crown
  for (var i = 0; i < 26; i++) {
    final a = rr.nextDouble() * tau, d = math.sqrt(rr.nextDouble()) * 0.9;
    final o = cr + Offset(math.cos(a) * d * w * 0.42, math.sin(a) * d * h * 0.14 - h * 0.02);
    final rad = 4 + rr.nextDouble() * 5;
    c.drawCircle(o, rad, Paint()..shader = RadialGradient(colors: [const Color(0xAAD8FF9A), const Color(0x00D8FF9A)]).createShader(Rect.fromCircle(center: o, radius: rad)));
  }
  // hanging vines
  final vine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2
    ..color = const Color(0xFF3A9A4F);
  for (var i = 0; i < 8; i++) {
    final x = w * (0.06 + rr.nextDouble() * 0.55);
    final y0 = h * (0.27 + rr.nextDouble() * 0.03);
    final len = h * (0.03 + rr.nextDouble() * 0.06);
    c.drawPath(Path()..moveTo(x, y0)..quadraticBezierTo(x + 4, y0 + len * 0.5, x - 2, y0 + len), vine);
    c.drawCircle(Offset(x - 2, y0 + len), 2.6, Paint()..color = _crownLight);
  }
}

// ---------------------------------------------------------------- stream & ground

void _stream(Canvas c, Size s) {
  final w = s.width, h = s.height;
  flatRibbon(
    c,
    [Offset(w * 0.76, h * 0.612), Offset(w * 0.72, h * 0.64), Offset(w * 0.64, h * 0.71), Offset(w * 0.55, h * 0.79), Offset(w * 0.5, h * 0.88), Offset(w * 0.52, h * 1.06)],
    [w * 0.008, w * 0.03, w * 0.06, w * 0.09, w * 0.14, w * 0.2],
    color: _water,
    light: _waterLight,
    bank: _bank,
  );
}

void _glints(Canvas c, Size s, Clock k) {
  paintShimmer(c, s, k, region: const Rect.fromLTRB(0.3, 0.68, 0.78, 1.0), count: 26, seed: 6, color: const Color(0xFFFFFFFF), cycles: 8);
}

void _ground(Canvas c, Size s) {
  final w = s.width, h = s.height;
  for (final side in [-1, 1]) {
    final pts = <Offset>[];
    for (var i = 0; i <= 8; i++) {
      final t = i / 8;
      final x = side < 0 ? _lerp(-w * 0.1, w * 0.4, t) : _lerp(w * 1.1, w * 0.62, t);
      final y = h * (0.80 + 0.2 * t * t) - math.pow(1 - t, 1.5) * h * 0.08;
      pts.add(Offset(x, y));
    }
    final p = smoothPath(pts)
      ..lineTo(side < 0 ? w * 0.55 : w * 0.45, h * 1.1)
      ..lineTo(side < 0 ? -w * 0.1 : w * 1.1, h * 1.1)
      ..close();
    c.drawPath(p, Paint()..color = _meadowC);
    c
      ..save()
      ..clipPath(p)
      ..drawPath(p.shift(const Offset(0, 4)), Paint()..color = _meadowC)
      ..restore();
    c.drawPath(smoothPath(pts), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _meadowLight);
  }
  // grass tufts and flowers
  final r = rng(14);
  for (var i = 0; i < 34; i++) {
    final side = i.isEven ? -1 : 1;
    final x = side < 0 ? r.nextDouble() * w * 0.4 : w * 0.6 + r.nextDouble() * w * 0.4;
    final y = h * (0.88 + r.nextDouble() * 0.1);
    final th = h * (0.012 + r.nextDouble() * 0.014);
    for (var k = -1; k <= 1; k++) {
      final bx = x + k * th * 0.5;
      c.drawPath(
        Path()
          ..moveTo(bx - 2, y)
          ..quadraticBezierTo(bx + k * 3, y - th * 0.6, bx + k * th * 0.6, y - th * (k == 0 ? 1.1 : 0.85))
          ..quadraticBezierTo(bx + k * 3 + 3, y - th * 0.5, bx + 2, y)
          ..close(),
        Paint()..color = k == 0 ? _meadowLight : const Color(0xFF7FCF62),
      );
    }
  }
  const petals = [Color(0xFFFFFFFF), Color(0xFFFFE066), Color(0xFFF4A9C4), Color(0xFFC7B6F2)];
  for (var i = 0; i < 28; i++) {
    final side = i.isEven ? -1 : 1;
    final x = side < 0 ? r.nextDouble() * w * 0.38 : w * 0.62 + r.nextDouble() * w * 0.38;
    final y = h * (0.86 + r.nextDouble() * 0.12);
    c.drawCircle(Offset(x, y), 2.6 + r.nextDouble() * 1.4, Paint()..color = petals[i % 4]);
    c.drawCircle(Offset(x, y), 1.0, Paint()..color = const Color(0xFFFFB02E));
  }
  flatRock(c, Offset(w * 0.36, h * 0.945), w * 0.2, h * 0.045, seed: 12, color: const Color(0xFF93A29A), shade: const Color(0xFF788A82));
  flatRock(c, Offset(w * 0.66, h * 0.925), w * 0.15, h * 0.035, seed: 14, color: const Color(0xFF93A29A), shade: const Color(0xFF788A82));
  flatBush(c, Offset(w * 0.2, h * 0.9), w * 0.2, seed: 5, color: _crownDark, light: _crown);
}

// ---------------------------------------------------------------- foreground

void _leaf(Canvas c, Offset base, double len, double angle, Color color, Color shade) {
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angle);
  final w = len * 0.26;
  final p = Path()
    ..moveTo(0, 0)
    ..cubicTo(-w * 1.3, -len * 0.25, -w * 1.1, -len * 0.75, 0, -len)
    ..cubicTo(w * 1.1, -len * 0.75, w * 1.3, -len * 0.25, 0, 0)
    ..close();
  c.drawPath(p, Paint()..color = color);
  c
    ..save()
    ..clipPath(p)
    ..drawRect(Rect.fromLTRB(0, -len, w * 2, 0), Paint()..color = shade)
    ..restore();
  c.restore();
}

void _foreLeaves(Canvas c, Size s) {
  final w = s.width, h = s.height;
  for (final side in [-1, 1]) {
    final bx = side < 0 ? 0.0 : w;
    for (var i = 0; i < 6; i++) {
      final a = (side < 0 ? 0.25 : -0.25) + side * (i - 2.5) * 0.28 + (side < 0 ? 0.15 : -0.15);
      _leaf(c, Offset(bx + side * w * 0.02, h * 1.03), h * (0.2 + (i % 3) * 0.04), a, Color.lerp(const Color(0xFF3FAE5E), const Color(0xFF74D072), (i % 3) / 2)!, const Color(0xFF2E9A58));
    }
  }
}

// ---------------------------------------------------------------- live

void _seeds(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 36, seed: 3, colors: [Color(0xFFFFFFFF), Color(0xFFFFF3C2)], minSize: 1.0, maxSize: 2.2, flow: Offset(0.1, -0.22), cycles: 2, spread: 2, wander: 14, twinkle: 0.4, shape: ParticleShape.dot, region: Rect.fromLTRB(0.0, 0.2, 1.0, 0.98), opacity: 0.85));
}

void _spirits(Canvas c, Size s, Clock k) {
  paintParticles(c, s, k, const ParticleSpec(count: 16, seed: 8, colors: [Color(0xFFFFF0A0), Color(0xFFC4FF9A)], minSize: 2.0, maxSize: 3.4, flow: Offset(0.02, -0.05), cycles: 1, spread: 1, wander: 26, twinkle: 0.7, twinkleCycles: 8, shape: ParticleShape.glow, region: Rect.fromLTRB(0.0, 0.4, 1.0, 0.98), haloScale: 2.6));
}

void _butterflies(Canvas c, Size s, Clock k) {
  for (var i = 0; i < 3; i++) {
    final ph = i / 3.0;
    final t = k.saw(1, ph);
    final x = s.width * (0.15 + 0.7 * t) + math.sin(tau * (k.u * 5 + ph)) * 26;
    final y = s.height * (0.72 - 0.1 * i) + math.cos(tau * (k.u * 7 + ph * 2)) * 18;
    final flap = 0.45 + 0.55 * math.sin(tau * (k.u * 60 + i)).abs();
    final col = i == 1 ? const Color(0xFFFFD36B) : const Color(0xFFFFFFFF);
    for (final sd in [-1, 1]) {
      c
        ..save()
        ..translate(x, y)
        ..scale(sd * flap, 1);
      c.drawOval(Rect.fromLTWH(0, -5, 7, 6), Paint()..color = col);
      c.drawOval(Rect.fromLTWH(0, 0, 5, 5), Paint()..color = col.withValues(alpha: 0.85));
      c.restore();
    }
  }
}
