import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'kit.dart';

// Tropical Paradise in flat, graphic 2D: a turquoise lagoon under towering
// clouds, islands on the horizon, a curved white-sand beach with rolling foam,
// swaying palms, hibiscus, shells and a little wooden jetty.
// Light comes from the upper right, so shade sits on the left of every form.

const _horizon = 0.40; // fraction of height

// palette
const _skyTop = Color(0xFF2EA7F2), _skyA = Color(0xFF5CBFF6), _skyB = Color(0xFF9BE0FF), _skyLow = Color(0xFFD9F4FF);
const _cloud = Color(0xFFFFFFFF), _cloudShade = Color(0xFFCDE6FA);
const _deep = Color(0xFF0E7CC0), _ocean = Color(0xFF1593CF), _sea = Color(0xFF1AA7D8), _lagoon = Color(0xFF19C6CB), _turq = Color(0xFF19D3C5);
const _shallow = Color(0xFF5CE3D0), _shallow2 = Color(0xFF9EF0DD);
const _sand = Color(0xFFFFF1D0), _sandShade = Color(0xFFF4DFB4), _sandWet = Color(0xFFE3C58F);
const _palm = Color(0xFF1F9F4A), _palmDark = Color(0xFF16803F), _palmLight = Color(0xFF7BD13E), _palmMid = Color(0xFF3DB448);
const _trunk = Color(0xFFB07A48), _trunkShade = Color(0xFF8A5A36), _trunkDeep = Color(0xFF6F462B);
const _coral = Color(0xFFFF6F61), _hibiscus = Color(0xFFFF4F7B), _hibiscusDark = Color(0xFFD93466);

SceneSpec tropicalScene() => SceneSpec(
      focusY: 0.4,
      topShade: 0.12,
      bottomShade: 0.16,
      layers: [
        Layer.still(_sky),
        Layer.scroll(_cloudsBack, scrollCycles: 1, bandTop: 0.0, bandBottom: 0.45),
        Layer.still(_islands, driftX: 0.006, driftCycles: 2),
        Layer.scroll(_cloudsFront, scrollCycles: 2, bandTop: 0.0, bandBottom: 0.4),
        Layer.still(_seaBands),
        Layer.live(_seaLive),
        Layer.still(_beach),
        Layer.live(_foamLive),
        Layer.still(_shoreProps, driftX: 0.012, driftCycles: 2, driftPhase: 0.2),
        Layer.live(_palmsLive),
        Layer.still(_fore, driftX: 0.026, driftCycles: 2, driftPhase: 0.3, sway: 0.004, swayCycles: 5, pivot: Alignment.bottomCenter),
        Layer.live(_birds),
        Layer.live(_air),
      ],
    );

// ---------------------------------------------------------------- helpers

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Two flat tones: [dark] everywhere, [light] shifted away from the shade side
/// (shade on the left / bottom, light from the upper right).
void _twoTone(Canvas c, Path p, Color dark, Color light, double dx, double dy) {
  c.drawPath(p, Paint()..color = dark);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(dx, dy)), Paint()..color = light)
    ..restore();
}

/// Wavy horizontal band edge, filled down to the bottom.
Path _bandPath(Size s, double y, double amp, int seed, {double freq = 3}) {
  final pts = <Offset>[];
  for (var x = -s.width * 0.1; x <= s.width * 1.1 + 8; x += 12) {
    final n = fbm(x / s.width * freq + 2.1, seed: seed, octaves: 2);
    pts.add(Offset(x, (y + (n - 0.5) * 2 * amp) * s.height));
  }
  return smoothPath(pts)
    ..lineTo(s.width * 1.1 + 8, s.height * 1.1)
    ..lineTo(-s.width * 0.1, s.height * 1.1)
    ..close();
}

/// Smooth shoreline height (screen px) at x. Beach rises on the left, a bay
/// opens in the middle, a small spit curls up at the right.
double _shoreY(Size s, double x) {
  const t = [-0.12, 0.0, 0.18, 0.4, 0.62, 0.82, 0.95, 1.12];
  const y = [0.785, 0.795, 0.825, 0.852, 0.862, 0.852, 0.85, 0.815];
  final u = x / s.width;
  var i = 0;
  while (i < t.length - 2 && u > t[i + 1]) {
    i++;
  }
  final f = ((u - t[i]) / (t[i + 1] - t[i])).clamp(0.0, 1.0);
  final e = f * f * (3 - 2 * f);
  return (_lerp(y[i], y[i + 1], e) + 0.004 * math.sin(u * 11 + 1)) * s.height;
}

Path _shoreLine(Size s, {double dy = 0, double wob = 0, double phase = 0, double x0 = -0.1, double x1 = 1.1}) {
  final pts = <Offset>[];
  for (var x = x0 * s.width; x <= x1 * s.width + 1; x += 14) {
    pts.add(Offset(x, _shoreY(s, x) + dy + wob * math.sin(x * 0.045 + phase)));
  }
  return smoothPath(pts);
}

Path _shoreFill(Size s, {double dy = 0, double wob = 0, double phase = 0}) {
  final p = _shoreLine(s, dy: dy, wob: wob, phase: phase);
  return p
    ..lineTo(s.width * 1.1, s.height * 1.1)
    ..lineTo(-s.width * 0.1, s.height * 1.1)
    ..close();
}

// ---------------------------------------------------------------- sky

void _sky(Canvas c, Size s) {
  final r = Rect.fromLTWH(0, 0, s.width, s.height * (_horizon + 0.02));
  c.drawRect(Offset.zero & s, verticalPaint(r, const [_skyTop, _skyA, _skyB, _skyLow], const [0.0, 0.35, 0.78, 1.0]));
  flatSun(c, Offset(s.width * 0.62, s.height * 0.185), s.width * 0.062, core: const Color(0xFFFFFAE0), halo: const Color(0xFFFFF3B0));
}

void _cloudsBack(Canvas c, Size s) {
  // towering cumulus banks near the horizon
  final w = s.width, h = s.height;
  flatCloud(c, Offset(w * 0.16, h * 0.4), w * 0.46, color: _cloud, shade: _cloudShade, seed: 4, puff: 1.25);
  flatCloud(c, Offset(w * 0.2, h * 0.37), w * 0.28, color: _cloud, shade: _cloudShade, seed: 14, puff: 1.2);
  flatCloud(c, Offset(w * 0.7, h * 0.405), w * 0.5, color: _cloud, shade: _cloudShade, seed: 9, puff: 1.3);
  flatCloud(c, Offset(w * 0.66, h * 0.375), w * 0.3, color: _cloud, shade: _cloudShade, seed: 27, puff: 1.2);
}

void _cloudsFront(Canvas c, Size s) {
  final w = s.width, h = s.height;
  flatCloud(c, Offset(w * 0.3, h * 0.25), w * 0.36, color: _cloud, shade: _cloudShade, seed: 12, puff: 1.0);
  flatCloud(c, Offset(w * 0.88, h * 0.14), w * 0.3, color: _cloud, shade: _cloudShade, seed: 33, puff: 0.9);
  flatCloud(c, Offset(w * 0.5, h * 0.085), w * 0.3, color: _cloud, shade: _cloudShade, seed: 41, puff: 0.9);
  flatCloud(c, Offset(w * 0.58, h * 0.33), w * 0.22, color: _cloud, shade: _cloudShade, seed: 5, puff: 0.9);
}

// ---------------------------------------------------------------- islands

void _miniPalm(Canvas c, Offset base, double h, double lean, Color trunk, Color leaf, Color leafLight) {
  final top = base + Offset(lean * h, -h);
  c.drawPath(
    Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + lean * h * 0.1, base.dy - h * 0.6, top.dx, top.dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, h * 0.07)
      ..color = trunk,
  );
  for (var i = 0; i < 6; i++) {
    final a = -math.pi * 0.95 + math.pi * 0.9 * i / 5;
    final dir = Offset(math.cos(a), math.sin(a));
    final len = h * 0.55;
    final tip = top + dir * len + Offset(0, len * 0.35);
    final mid = top + dir * len * 0.55 + Offset(0, -len * 0.12);
    final nrm = Offset(-dir.dy, dir.dx) * (len * 0.16);
    final p = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(mid.dx + nrm.dx, mid.dy + nrm.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx - nrm.dx, mid.dy - nrm.dy, top.dx, top.dy);
    c.drawPath(p, Paint()..color = i >= 3 ? leafLight : leaf);
  }
}

void _island(Canvas c, Size s, {required double cx, required double w, required double hgt, required Color dark, required Color light, required Color sandC, required Color foam, required int seed, required List<(double, double, double)> palms, required Color trunk}) {
  final base = s.height * (_horizon + 0.004);
  final r = rng(seed);
  final pts = <Offset>[Offset(cx - w * 0.62, base + 6)];
  const n = 9;
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final bell = math.pow(math.sin(math.pi * t), 0.8).toDouble();
    final bump = 0.8 + r.nextDouble() * 0.4;
    pts.add(Offset(cx - w * 0.5 + w * t, base - hgt * bell * bump * (t > 0.2 && t < 0.8 ? 1.0 : 0.7)));
  }
  pts.add(Offset(cx + w * 0.62, base + 6));
  final p = smoothPath(pts, closed: true);
  // sand rim and foam
  final rim = Rect.fromCenter(center: Offset(cx, base + 2), width: w * 1.2, height: hgt * 0.16);
  c.drawOval(rim.inflate(3), Paint()..color = foam);
  c.drawOval(rim, Paint()..color = sandC);
  _twoTone(c, p, dark, light, w * 0.07, -hgt * 0.05);
  for (final (px, py, ph) in palms) {
    final b = Offset(cx + w * px, base - hgt * py);
    _miniPalm(c, b, ph, px > 0 ? -0.18 : 0.22, mix(trunk, dark, 0.3), dark, mix(light, dark, 0.2));
  }
}

void _islands(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // hazy far islands
  _island(c, s, cx: w * 0.2, w: w * 0.5, hgt: h * 0.09, dark: const Color(0xFF6CC3C2), light: const Color(0xFF86D4CC), sandC: const Color(0xFFD8F1E2), foam: const Color(0xFFBDEBF3), seed: 3, palms: const [(-0.1, 0.8, 22), (0.0, 0.92, 28), (0.12, 0.76, 20)], trunk: const Color(0xFF5CB2B0));
  _island(c, s, cx: w * 0.55, w: w * 0.26, hgt: h * 0.04, dark: const Color(0xFF63BCC0), light: const Color(0xFF7ECFCB), sandC: const Color(0xFFD8F1E2), foam: const Color(0xFFBDEBF3), seed: 8, palms: const [(0.0, 0.8, 12)], trunk: const Color(0xFF5CB2B0));
  // nearer green island with palms
  _island(c, s, cx: w * 0.84, w: w * 0.44, hgt: h * 0.12, dark: const Color(0xFF2A9A5E), light: const Color(0xFF45B96C), sandC: _sand, foam: const Color(0xFFD7F6F7), seed: 15, palms: const [(-0.2, 0.62, 36), (-0.06, 0.88, 44), (0.1, 0.78, 38), (0.22, 0.4, 30)], trunk: const Color(0xFF7A5A3E));
}

// ---------------------------------------------------------------- sea (flat bands)

void _seaBands(Canvas c, Size s) {
  final w = s.width, h = s.height;
  final hy = h * _horizon;
  c.drawRect(Rect.fromLTWH(-w, hy, w * 3, h), Paint()..color = _deep);
  // bright horizon haze strip
  c.drawRect(Rect.fromLTWH(-w, hy, w * 3, 3), Paint()..color = const Color(0xFF7FD3F2));
  c.drawPath(_bandPath(s, 0.455, 0.008, 3), Paint()..color = _ocean);
  c.drawPath(_bandPath(s, 0.51, 0.012, 7), Paint()..color = _sea);
  c.drawPath(_bandPath(s, 0.585, 0.014, 11, freq: 2), Paint()..color = _lagoon);
  c.drawPath(_bandPath(s, 0.66, 0.018, 19, freq: 2), Paint()..color = _turq);
  // sea stripes (flat lighter swell lines)
  for (final (y, seed, col) in [(0.43, 31, _ocean), (0.485, 32, _sea), (0.55, 33, _lagoon), (0.62, 34, _turq)]) {
    final sh = HSLColor.fromColor(col);
    final stripe = sh.withLightness((sh.lightness + 0.05).clamp(0.0, 1.0)).toColor();
    final r = rng(seed);
    for (var i = 0; i < 6; i++) {
      final x = r.nextDouble() * w * 1.1 - w * 0.05;
      final len = w * (0.1 + r.nextDouble() * 0.16);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y * h + r.nextDouble() * h * 0.03, len, 3.2), const Radius.circular(2)), Paint()..color = stripe);
    }
  }
  // shallow lagoon steps toward the beach
  c.drawPath(_shoreFill(s, dy: -h * 0.12, wob: 5, phase: 1), Paint()..color = _shallow);
  c.drawPath(_shoreFill(s, dy: -h * 0.05, wob: 4, phase: 2), Paint()..color = _shallow2);
  // sea-grass / reef patches in the lagoon, sand bar patches
  final r = rng(5);
  for (var i = 0; i < 5; i++) {
    final x = (0.1 + 0.8 * r.nextDouble()) * w;
    final y = h * (0.7 + r.nextDouble() * 0.08);
    final p = blobPath(Offset(x, y), w * (0.07 + r.nextDouble() * 0.06), h * 0.012, seed: i + 3, wobble: 0.2);
    c.drawPath(p, Paint()..color = const Color(0xFF15B3BC));
  }
  for (var i = 0; i < 3; i++) {
    final x = w * (0.15 + 0.35 * i + r.nextDouble() * 0.1);
    final y = h * (0.815 + r.nextDouble() * 0.02);
    c.drawPath(blobPath(Offset(x, y), w * 0.09, h * 0.01, seed: i + 20, wobble: 0.15), Paint()..color = const Color(0xFFBDF7E6));
  }
}

// ---------------------------------------------------------------- sea (live: swell dashes, glitter)

final List<(double, double, double, double)> _dashes = () {
  final r = rng(41);
  return [
    for (var i = 0; i < 46; i++) (r.nextDouble(), r.nextDouble(), 0.5 + r.nextDouble(), r.nextDouble()),
  ];
}();

void _seaLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final p = Paint();
  // swells drifting sideways: rows of little light dashes, nearer = longer
  for (var i = 0; i < _dashes.length; i++) {
    final (a, b, sz, ph) = _dashes[i];
    final row = b * b; // more rows far away
    final y = h * (_horizon + 0.02 + row * 0.33);
    final persp = 0.35 + (y / h - _horizon) * 2.2;
    final len = w * 0.07 * sz * persp * 1.8;
    final dir = i.isEven ? 1 : -1;
    final lap = k.saw(2 + i % 3, ph) * dir;
    var x = (a + lap) * w;
    x = x - (x / w).floorToDouble() * w;
    final bob = math.sin(tau * (k.u * (3 + i % 4) + ph)) * 1.6;
    final al = 0.35 + 0.35 * k.pulse(4 + i % 3, ph);
    p.color = Colors.white.withValues(alpha: al * (0.5 + persp * 0.35).clamp(0.0, 1.0));
    final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + bob), width: len, height: 2.2 + persp * 1.6), const Radius.circular(3));
    c.drawRRect(rr, p);
    if (x < len) c.drawRRect(rr.shift(Offset(w, 0)), p);
    if (x > w - len) c.drawRRect(rr.shift(Offset(-w, 0)), p);
  }
  // sun glitter column on the water below the sun
  final sx = w * 0.66;
  final r = rng(77);
  for (var i = 0; i < 30; i++) {
    final t = r.nextDouble();
    final y = h * (_horizon + 0.012 + t * 0.34);
    final spread = w * (0.03 + t * 0.2);
    final x = sx + (r.nextDouble() - 0.5) * 2 * spread;
    final ph = r.nextDouble();
    final a = math.pow(k.pulse(8 + i % 5, ph), 2.2).toDouble();
    if (a < 0.05) continue;
    final len = (5 + r.nextDouble() * 12) * (0.6 + t) * (w / 390);
    p.color = const Color(0xFFFFFBE0).withValues(alpha: 0.9 * a);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: len, height: 1.8 + t * 1.2), const Radius.circular(2)), p);
  }
  // star glints near the lagoon
  final r2 = rng(90);
  for (var i = 0; i < 9; i++) {
    final x = (0.06 + 0.88 * r2.nextDouble()) * w;
    final y = h * (0.52 + r2.nextDouble() * 0.3);
    final ph = r2.nextDouble();
    final a = math.pow(k.pulse(10 + i % 4, ph), 3).toDouble();
    if (a < 0.08) continue;
    sparkle(c, Offset(x, y), (3 + r2.nextDouble() * 3) * (w / 390), Colors.white, a);
  }
}

// ---------------------------------------------------------------- beach

void _beach(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // dry sand everywhere below the water line, a wet band hugging the water
  c.drawPath(_shoreFill(s), Paint()..color = _sand);
  Path band(double d0, double d1, double ph) {
    final top = <Offset>[], low = <Offset>[];
    for (var x = -w * 0.1; x <= w * 1.1 + 1; x += 14) {
      final sy = _shoreY(s, x);
      top.add(Offset(x, sy + d0));
      low.add(Offset(x, sy + d1 + 3 * math.sin(x * 0.03 + ph)));
    }
    return smoothPath([...top, ...low.reversed], closed: true);
  }

  c.drawPath(band(-4, h * 0.026, 0), Paint()..color = _sandWet);
  c.drawPath(band(h * 0.004, h * 0.0095, 1), Paint()..color = const Color(0xFFF3DFB4));
  // dune shadow in the lower part (flat second tone)
  final dune = <Offset>[
    for (var x = -w * 0.1; x <= w * 1.1; x += 16) Offset(x, h * (0.955 - 0.03 * math.sin(x / w * 2.4 + 0.5)) + 5 * math.sin(x * 0.03)),
  ];
  c.drawPath(
    smoothPath(dune)
      ..lineTo(w * 1.1, h * 1.1)
      ..lineTo(-w * 0.1, h * 1.1)
      ..close(),
    Paint()..color = _sandShade,
  );
  // sand ripples
  final r = rng(12);
  final pr = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2
    ..color = _sandShade;
  for (var i = 0; i < 14; i++) {
    final x = r.nextDouble() * w;
    final y = h * (0.875 + r.nextDouble() * 0.07);
    if (y < _shoreY(s, x) + 24) continue;
    final len = 14 + r.nextDouble() * 24;
    c.drawPath(
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + len / 2, y - 3, x + len, y),
      pr,
    );
  }
}

// ---------------------------------------------------------------- foam (live): the signature swash

void _foamLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final k0 = w / 390;
  // rolling wave lines arriving from the lagoon
  const nWaves = 5;
  for (var j = 0; j < nWaves; j++) {
    final lap = k.saw(3, j / nWaves);
    final dist = math.pow(1 - lap, 1.45).toDouble() * h * 0.13; // px above the shoreline
    final fade = (lap / 0.18).clamp(0.0, 1.0) * (1 - ((lap - 0.88) / 0.12).clamp(0.0, 1.0));
    final width = (1.6 + 2.2 * lap) * k0;
    final path = Path();
    var open = false;
    Offset? last;
    for (var x = -12.0; x <= w + 12; x += 9) {
      final n = vnoise(x * 0.016 + j * 9.7 + math.sin(tau * k.u * 3) * 0.3, 3);
      final y = _shoreY(s, x) - dist - 12 * k0 - 3 * math.sin(x * 0.05 + j * 2 + tau * k.u * 6);
      if (n > 0.32) {
        if (!open) {
          path.moveTo(x, y);
          open = true;
        } else {
          path.lineTo(x, y);
        }
        last = Offset(x, y);
      } else {
        open = false;
      }
    }
    if (last == null) continue;
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..color = Colors.white.withValues(alpha: 0.85 * fade),
    );
  }
  // the swash: shallow water creeping up the wet sand, with a white foam rim on its leading edge
  final off = 17.0 * k0 * (0.5 + 0.5 * k.sine(6, -0.25));
  final ph = 2.0 + k.saw(6) * tau;
  final lead = <Offset>[], back = <Offset>[];
  for (var x = -w * 0.1; x <= w * 1.1 + 1; x += 14) {
    final sy = _shoreY(s, x);
    lead.add(Offset(x, sy + off + 3 * math.sin(x * 0.045 + ph)));
    back.add(Offset(x, sy - 8 * k0));
  }
  final area = Path()..moveTo(back.first.dx, back.first.dy);
  for (final p in back) {
    area.lineTo(p.dx, p.dy);
  }
  for (final p in lead.reversed) {
    area.lineTo(p.dx, p.dy);
  }
  area.close();
  c.drawPath(area, Paint()..color = _shallow2);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = Colors.white;
  c.drawPath(smoothPath(lead), stroke..strokeWidth = 3.6 * k0);
  // a second thin trailing foam line
  final trail = <Offset>[for (final p in lead) Offset(p.dx, p.dy - (9 + 4 * math.sin(p.dx * 0.03 + ph * 2)) * k0 - off * 0.3)];
  c.drawPath(smoothPath(trail), stroke..strokeWidth = 2 * k0..color = Colors.white.withValues(alpha: 0.75));
  _boat(c, s, k);
}

void _boat(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final bob = math.sin(tau * (k.u * 6 + 0.2)) * 2.2;
  c
    ..save()
    ..translate(w * 0.43, h * 0.8 + bob)
    ..rotate(0.03 * math.sin(tau * (k.u * 6 + 0.45)))
    ..scale(w / 390);
  final hull = Path()
    ..moveTo(-26, -6)
    ..lineTo(26, -8)
    ..cubicTo(24, 4, 12, 9, 0, 9)
    ..cubicTo(-12, 9, -22, 4, -26, -6)
    ..close();
  c.drawOval(Rect.fromCenter(center: const Offset(0, 8), width: 66, height: 9), Paint()..color = const Color(0xCCF3FFFC));
  _twoTone(c, hull, const Color(0xFFD9483B), _coral, 5, -2);
  c.drawRect(const Rect.fromLTWH(-24, -4.5, 48, 3), Paint()..color = const Color(0xFFFFF1D0));
  c.drawOval(const Rect.fromLTWH(-24, -9.5, 48, 4), Paint()..color = const Color(0xFF9A5E34));
  c.drawRect(const Rect.fromLTWH(-3, -22, 2.4, 14), Paint()..color = const Color(0xFFB07A48));
  c.restore();
}

// ---------------------------------------------------------------- props: jetty and rocks

void _shoreProps(Canvas c, Size s) {
  final w = s.width, h = s.height;
  _jetty(c, s);
  // smooth coastal rocks with a foam ring
  void rock(double x, double y, double rw, double rh, int seed) {
    c.drawOval(Rect.fromCenter(center: Offset(x, y + 2), width: rw * 1.25, height: rh * 0.55), Paint()..color = const Color(0xFFE9FBF7));
    c.drawOval(Rect.fromCenter(center: Offset(x, y + 3), width: rw * 1.08, height: rh * 0.38), Paint()..color = _shallow2);
    final r = rng(seed);
    final pts = <Offset>[
      Offset(x - rw / 2, y),
      Offset(x - rw * 0.47, y - rh * (0.4 + r.nextDouble() * 0.15)),
      Offset(x - rw * 0.2, y - rh * (0.9 + r.nextDouble() * 0.1)),
      Offset(x + rw * 0.18, y - rh * (0.9 + r.nextDouble() * 0.1)),
      Offset(x + rw * 0.46, y - rh * (0.4 + r.nextDouble() * 0.15)),
      Offset(x + rw / 2, y),
    ];
    _twoTone(c, smoothPath(pts, closed: true), const Color(0xFFA7919A), const Color(0xFFDCC9B6), rw * 0.14, -rh * 0.1);
  }

  rock(w * 0.3, h * 0.865, w * 0.16, h * 0.04, 4);
  rock(w * 0.385, h * 0.872, w * 0.09, h * 0.026, 9);
  rock(w * 0.07, h * 0.78, w * 0.12, h * 0.032, 2);
}

void _jetty(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // planked walkway running from the right shore out into the lagoon (receding)
  const wood = Color(0xFFE2AC70), woodLight = Color(0xFFF2C890), woodDark = Color(0xFFB07846), post = Color(0xFF8A5A36), postDark = Color(0xFF6F462B);
  final near = Offset(w * 1.02, h * 0.875), far = Offset(w * 0.52, h * 0.805);
  final nearT = h * 0.03, farT = h * 0.016; // deck thickness (visible top width)
  Offset at(double t) => Offset.lerp(near, far, t)!;
  double th(double t) => _lerp(nearT, farT, t);
  // posts under the deck, with a foam ring
  for (var i = 0; i < 7; i++) {
    final t = i / 6 * 0.92 + 0.04;
    final p = at(t);
    final len = _lerp(26, 12, t) * w / 390;
    final pw = _lerp(8, 4.5, t) * w / 390;
    c.drawOval(Rect.fromCenter(center: Offset(p.dx, p.dy + th(t) + len), width: pw * 3.2, height: pw * 0.9), Paint()..color = const Color(0xAAF3FFFC));
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - pw / 2, p.dy + th(t) * 0.5, pw, len + th(t) * 0.5), Radius.circular(pw / 2));
    c.drawRRect(rr, Paint()..color = post);
    c.drawRect(Rect.fromLTWH(p.dx - pw / 2, p.dy + th(t) * 0.5, pw * 0.4, len + th(t) * 0.5 - pw * 0.3), Paint()..color = postDark);
  }
  // deck: dark side face, then planks
  final deck = Path()
    ..moveTo(far.dx, far.dy)
    ..lineTo(near.dx, near.dy)
    ..lineTo(near.dx, near.dy + nearT)
    ..lineTo(far.dx, far.dy + farT)
    ..close();
  c.drawPath(deck.shift(Offset(0, h * 0.007)), Paint()..color = woodDark);
  c.drawPath(deck, Paint()..color = wood);
  c.save();
  c.clipPath(deck);
  final seam = Paint()
    ..color = woodDark
    ..strokeWidth = 1.5;
  for (var i = 1; i < 26; i++) {
    final t = 1 - math.pow(i / 26, 1.0).toDouble();
    final p = at(t);
    c.drawLine(p, p + Offset(-3, th(t)), seam);
  }
  c.drawPath(
    Path()
      ..moveTo(far.dx, far.dy)
      ..lineTo(near.dx, near.dy)
      ..lineTo(near.dx, near.dy + nearT * 0.22)
      ..lineTo(far.dx, far.dy + farT * 0.22)
      ..close(),
    Paint()..color = woodLight,
  );
  c.restore();
  // end platform rounding and mooring posts with a rope
  final mp = [at(0.05), at(0.45), at(0.85)];
  for (var i = 0; i < mp.length; i++) {
    final p = mp[i];
    final t = [0.05, 0.45, 0.85][i];
    final rw = _lerp(7, 4, t) * w / 390, rh = _lerp(22, 12, t) * w / 390;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - rw / 2, p.dy - rh, rw, rh + 3), Radius.circular(rw / 2)), Paint()..color = post);
    c.drawRect(Rect.fromLTWH(p.dx - rw / 2, p.dy - rh + 2, rw * 0.4, rh - 2), Paint()..color = postDark);
    c.drawCircle(Offset(p.dx, p.dy - rh), rw * 0.62, Paint()..color = woodLight);
  }
  c.drawPath(
    Path()
      ..moveTo(mp[0].dx, mp[0].dy - 16)
      ..quadraticBezierTo((mp[0].dx + mp[1].dx) / 2, (mp[0].dy + mp[1].dy) / 2 - 8, mp[1].dx, mp[1].dy - 12)
      ..quadraticBezierTo((mp[1].dx + mp[2].dx) / 2, (mp[1].dy + mp[2].dy) / 2 - 4, mp[2].dx, mp[2].dy - 8),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF4E2BC),
  );
}

// ---------------------------------------------------------------- palms (live: per-frond sway)

class _Frond {
  _Frond(this.angle, this.len, this.tone, this.variant, this.cyc, this.phase);
  final double angle; // radians
  final double len; // fraction of the palm's frond size
  final int tone; // 0 = back (darker), 1 = front
  final int variant;
  final int cyc;
  final double phase;
}

class _PalmSpec {
  _PalmSpec({required this.base, required this.ctrl, required this.crown, required this.w0, required this.w1, required this.frondSize, required this.fronds, required this.seed});
  final Offset base, ctrl, crown; // fractions of the screen
  final double w0, w1, frondSize; // trunk widths and frond length as fractions of the width
  final List<_Frond> fronds;
  final int seed;
}

List<_Frond> _frondSet(int seed, int n, {double spread = 1.0}) {
  final r = rng(seed);
  final out = <_Frond>[];
  for (var i = 0; i < n; i++) {
    final t = i / (n - 1);
    final a = _lerp(-math.pi * 1.04, math.pi * 0.04, t) * 1.0;
    final ang = -math.pi / 2 + (a + math.pi / 2) * spread + (r.nextDouble() - 0.5) * 0.12;
    final up = (math.sin(math.pi * t)).abs();
    out.add(_Frond(ang, 0.78 + r.nextDouble() * 0.22 - up * 0.12, i.isOdd ? 0 : 1, i % 3, 4 + (i + seed) % 4, r.nextDouble()));
  }
  // a couple of young fronds shooting up from the middle
  out.add(_Frond(-math.pi / 2 - 0.22, 0.5, 0, 1, 5, 0.3));
  out.add(_Frond(-math.pi / 2 + 0.25, 0.46, 0, 2, 6, 0.7));
  out.sort((a, b) => a.tone.compareTo(b.tone));
  return out;
}

final List<_PalmSpec> _palms = [
  // big left palm
  _PalmSpec(base: const Offset(0.07, 0.94), ctrl: const Offset(-0.02, 0.58), crown: const Offset(0.21, 0.2), w0: 0.058, w1: 0.03, frondSize: 0.36, fronds: _frondSet(2, 9), seed: 2),
  // big right palm
  _PalmSpec(base: const Offset(0.97, 0.93), ctrl: const Offset(1.06, 0.6), crown: const Offset(0.77, 0.27), w0: 0.05, w1: 0.026, frondSize: 0.3, fronds: _frondSet(7, 9), seed: 7),
];

class _Frond0 {
  _Frond0(this.dark, this.light, this.rib);
  final Path dark, light, rib;
}

final Map<int, _Frond0> _frondCache = {};

_Frond0 _frondShape(int variant) => _frondCache.putIfAbsent(variant, () {
      final bend = 0.14 + variant * 0.05;
      Offset rib(double t) {
        final a = Offset.zero, b = Offset(0.5, -0.17), cc = Offset(1, bend);
        final u = 1 - t;
        return a * (u * u) + b * (2 * u * t) + cc * (t * t);
      }

      Offset tan(double t) {
        final a = Offset.zero, b = const Offset(0.5, -0.17), cc = Offset(1, bend);
        final d = (b - a) * (2 * (1 - t)) + (cc - b) * (2 * t);
        return d / d.distance;
      }

      final dark = Path(), light = Path(), ribP = Path();
      final n = 14 + variant * 2;
      for (var i = 0; i < n; i++) {
        final t = 0.07 + 0.93 * i / (n - 1);
        final p = rib(t), tg = tan(t);
        final up = Offset(tg.dy, -tg.dx);
        final len = 0.24 * (1 - 0.7 * t) * math.min(1.0, t * 7 + 0.35);
        final wd = len * 0.34;
        for (final side in [1, -1]) {
          var dir = tg * 0.55 + up * (0.8 * side) + const Offset(0, 0.2);
          dir = dir / dir.distance;
          final tip = p + dir * len;
          final perp = Offset(-dir.dy, dir.dx);
          final leaf = Path()
            ..moveTo(p.dx - tg.dx * 0.012, p.dy - tg.dy * 0.012)
            ..cubicTo(p.dx + dir.dx * len * 0.3 + perp.dx * wd * 1.5, p.dy + dir.dy * len * 0.3 + perp.dy * wd * 1.5, p.dx + dir.dx * len * 0.8 + perp.dx * wd * 1.0, p.dy + dir.dy * len * 0.8 + perp.dy * wd * 1.0, tip.dx, tip.dy)
            ..cubicTo(p.dx + dir.dx * len * 0.8 - perp.dx * wd * 0.2, p.dy + dir.dy * len * 0.8 - perp.dy * wd * 0.2, p.dx + dir.dx * len * 0.3 - perp.dx * wd * 0.6, p.dy + dir.dy * len * 0.3 - perp.dy * wd * 0.6, p.dx + tg.dx * 0.03, p.dy + tg.dy * 0.03)
            ..close();
          (side > 0 ? light : dark).addPath(leaf, Offset.zero);
        }
      }
      // slim tapered rib
      final lp = <Offset>[], rp = <Offset>[];
      for (var i = 0; i <= 10; i++) {
        final t = i / 10;
        final p = rib(t), tg = tan(t);
        final nrm = Offset(-tg.dy, tg.dx);
        final hw = 0.012 * (1 - t) + 0.002;
        lp.add(p - nrm * hw);
        rp.add(p + nrm * hw);
      }
      ribP.addPath(smoothPath([...lp, ...rp.reversed], closed: true), Offset.zero);
      return _Frond0(dark, light, ribP);
    });

class _Trunk {
  _Trunk(this.body, this.shade, this.rings, this.crown, this.scale);
  final Path body, shade, rings;
  final Offset crown;
  final double scale;
}

final Map<String, _Trunk> _trunks = {};

_Trunk _buildTrunk(Size s, _PalmSpec sp) {
  final w = s.width, h = s.height;
  final base = Offset(sp.base.dx * w, sp.base.dy * h);
  final ctrl = Offset(sp.ctrl.dx * w, sp.ctrl.dy * h);
  final top = Offset(sp.crown.dx * w, sp.crown.dy * h);
  Offset at(double t) {
    final u = 1 - t;
    return base * (u * u) + ctrl * (2 * u * t) + top * (t * t);
  }

  Offset nrm(double t) {
    final d = (ctrl - base) * (2 * (1 - t)) + (top - ctrl) * (2 * t);
    final n = Offset(-d.dy, d.dx);
    return n / n.distance;
  }

  const n = 18;
  final l = <Offset>[], r = <Offset>[], m = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final hw = _lerp(sp.w0, sp.w1, math.pow(t, 0.8).toDouble()) * w / 2 * (i == 0 ? 1.0 : 1.0);
    final flare = t < 0.08 ? (1 + (0.08 - t) * 5) : 1.0;
    final p = at(t), nv = nrm(t);
    l.add(p - nv * hw * flare);
    r.add(p + nv * hw * flare);
    m.add(p - nv * hw * flare * 0.1);
  }
  // pick the side that faces left as the shade side
  final leftSide = (l[n ~/ 2].dx < r[n ~/ 2].dx) ? l : r;
  final rightSide = identical(leftSide, l) ? r : l;
  final body = smoothPath([...leftSide, ...rightSide.reversed], closed: true);
  final shade = smoothPath([
    ...leftSide,
    for (var i = n; i >= 0; i--) Offset.lerp(leftSide[i], rightSide[i], 0.42)!,
  ], closed: true);
  final rings = Path();
  for (var i = 1; i < n; i++) {
    final a = Offset.lerp(leftSide[i], rightSide[i], 0.0)!;
    final b = Offset.lerp(leftSide[i], rightSide[i], 1.0)!;
    final a2 = Offset.lerp(leftSide[i - 1], rightSide[i - 1], 0.0)!;
    final b2 = Offset.lerp(leftSide[i - 1], rightSide[i - 1], 1.0)!;
    final mid = Offset.lerp(a, b, 0.5)!;
    final mid2 = Offset.lerp(a2, b2, 0.5)!;
    final sag = (mid - mid2) * 0.18;
    rings.addPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx + sag.dx * 0 + 0, mid.dy + 3, b.dx, b.dy)
        ..lineTo(b.dx, b.dy - 2.4)
        ..quadraticBezierTo(mid.dx, mid.dy + 0.6, a.dx, a.dy - 2.4)
        ..close(),
      Offset.zero,
    );
  }
  return _Trunk(body, shade, rings, top, w);
}

void _palmsLive(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  final gust = k.sine(2);
  final driftX = math.sin(tau * (k.u * 2 + 0.15)) * w * 0.012;
  for (var pi = 0; pi < _palms.length; pi++) {
    final sp = _palms[pi];
    final key = '${w.round()}x${h.round()}#$pi';
    final tr = _trunks.putIfAbsent(key, () => _buildTrunk(s, sp));
    final base = Offset(sp.base.dx * w, sp.base.dy * h);
    final sway = 0.007 * math.sin(tau * (k.u * 3 + pi * 0.31)) + 0.003 * gust;
    c
      ..save()
      ..translate(driftX * (0.6 + pi * 0.15), 0)
      ..translate(base.dx, base.dy)
      ..rotate(sway)
      ..translate(-base.dx, -base.dy);
    final sh = darken(_trunkShade, 0.0);
    c.drawPath(tr.body, Paint()..color = _trunk);
    c.drawPath(tr.shade, Paint()..color = sh);
    c.drawPath(tr.rings, Paint()..color = _trunkDeep.withValues(alpha: 0.5));
    // fronds
    final cr = tr.crown;
    final size = sp.frondSize * w;
    for (final f in sp.fronds) {
      final shape = _frondShape(f.variant);
      final a = f.angle + 0.055 * math.sin(tau * (k.u * f.cyc + f.phase)) + 0.02 * gust;
      c
        ..save()
        ..translate(cr.dx, cr.dy)
        ..rotate(a)
        ..scale(size * f.len, (a.abs() > math.pi / 2 ? -1 : 1) * size * f.len);
      final dk = f.tone == 0 ? _palmDark : _palm;
      final lt = f.tone == 0 ? _palm : _palmLight;
      c.drawPath(shape.dark, Paint()..color = dk);
      c.drawPath(shape.light, Paint()..color = lt);
      c.drawPath(shape.rib, Paint()..color = _palmDark);
      c.restore();
    }
    // crown knot and coconuts
    c.drawCircle(cr + Offset(0, w * 0.006), w * 0.022 * (sp.w0 / 0.056).clamp(0.5, 1.0) + 3, Paint()..color = _palmDark);
    {
      final nr = w * 0.016 * (sp.w0 / 0.056).clamp(0.55, 1.0);
      for (final (dx, dy) in [(-0.7, 1.7), (0.5, 2.0), (-0.05, 2.6)]) {
        final o = cr + Offset(dx * nr, dy * nr);
        c.drawCircle(o, nr, Paint()..color = const Color(0xFF7A4A2A));
        c.drawCircle(o + Offset(nr * 0.28, -nr * 0.28), nr * 0.5, Paint()..color = const Color(0xFF9A6338));
      }
    }
    c.restore();
  }
}

// ---------------------------------------------------------------- foreground (still)

void _flower(Canvas c, Offset o, double r, {double rot = 0, Color petal = _hibiscus, Color dark = _hibiscusDark}) {
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(rot);
  for (var i = 0; i < 5; i++) {
    final a = tau * i / 5;
    c
      ..save()
      ..rotate(a);
    final p = Path()
      ..moveTo(0, 0)
      ..cubicTo(-r * 0.75, -r * 0.25, -r * 0.7, -r * 1.05, 0, -r * 1.05)
      ..cubicTo(r * 0.7, -r * 1.05, r * 0.75, -r * 0.25, 0, 0)
      ..close();
    c.drawPath(p, Paint()..color = dark);
    c.save();
    c.clipPath(p);
    c.drawPath(p.shift(Offset(r * 0.14, -r * 0.1)), Paint()..color = petal);
    c.restore();
    c.restore();
  }
  c.drawCircle(Offset.zero, r * 0.2, Paint()..color = const Color(0xFFFFD36B));
  c.drawLine(Offset.zero, Offset(r * 0.5, -r * 0.62), Paint()
    ..strokeWidth = r * 0.12
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFFE9A0));
  c.drawCircle(Offset(r * 0.5, -r * 0.62), r * 0.11, Paint()..color = _coral);
  c.restore();
}

void _leafBlade(Canvas c, Offset base, double len, double angle, Color color, Color light) {
  c
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angle);
  final wd = len * 0.2;
  final p = Path()
    ..moveTo(0, 0)
    ..cubicTo(-wd * 1.4, -len * 0.3, -wd * 0.9, -len * 0.8, 0, -len)
    ..cubicTo(wd * 0.9, -len * 0.8, wd * 1.4, -len * 0.3, 0, 0)
    ..close();
  c.drawPath(p, Paint()..color = color);
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(-wd * 0.9, 0)), Paint()..color = light)
    ..restore();
  c.restore();
}

void _starfish(Canvas c, Offset o, double r, double rot) {
  final pts = <Offset>[];
  for (var i = 0; i < 10; i++) {
    final a = rot + tau * i / 10 - math.pi / 2;
    final rr = i.isEven ? r : r * 0.42;
    pts.add(o + Offset(math.cos(a), math.sin(a)) * rr);
  }
  final p = smoothPath(pts, closed: true);
  c.drawPath(p, Paint()..color = const Color(0xFFE5543F));
  c
    ..save()
    ..clipPath(p)
    ..drawPath(p.shift(Offset(r * 0.14, -r * 0.12)), Paint()..color = const Color(0xFFFF8468))
    ..restore();
  for (var i = 0; i < 5; i++) {
    final a = rot + tau * i / 5 - math.pi / 2;
    c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.52, r * 0.07, Paint()..color = const Color(0xFFFFE2B8));
  }
}

void _shell(Canvas c, Offset o, double r, double rot, Color col, Color dark) {
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..rotate(rot);
  final p = Path()
    ..moveTo(0, r * 0.7)
    ..cubicTo(-r * 1.3, r * 0.2, -r * 1.0, -r * 0.9, 0, -r * 0.9)
    ..cubicTo(r * 1.0, -r * 0.9, r * 1.3, r * 0.2, 0, r * 0.7)
    ..close();
  c.drawPath(p, Paint()..color = col);
  c.save();
  c.clipPath(p);
  c.drawPath(p.shift(Offset(-r * 0.35, r * 0.15)), Paint()..color = dark);
  c.restore();
  final rib = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, r * 0.08)
    ..strokeCap = StrokeCap.round
    ..color = mix(dark, col, 0.2);
  for (var i = -2; i <= 2; i++) {
    c.drawLine(Offset(0, r * 0.6), Offset(i * r * 0.38, -r * 0.7 + (i.abs() * r * 0.14)), rib);
  }
  c.restore();
}

void _fore(Canvas c, Size s) {
  final w = s.width, h = s.height;
  // hibiscus bush at the foot of the left palm
  void bush(Offset base, double sc, int seed, int flip) {
    final r = rng(seed);
    for (var i = 0; i < 9; i++) {
      final a = flip * (-0.15 + (i - 4) * 0.27) + (r.nextDouble() - 0.5) * 0.1;
      final dark = i.isEven;
      _leafBlade(c, base + Offset((i - 4) * 4 * sc, 0), h * (0.07 + r.nextDouble() * 0.05) * sc, a, dark ? _palmDark : _palm, dark ? _palm : _palmMid);
    }
    for (var i = 0; i < 4; i++) {
      final o = base + Offset((r.nextDouble() - 0.5) * w * 0.14 * sc, -h * (0.02 + r.nextDouble() * 0.05) * sc);
      _flower(c, o, w * (0.03 + r.nextDouble() * 0.014) * sc, rot: r.nextDouble() * tau, petal: i == 1 ? _coral : _hibiscus, dark: i == 1 ? const Color(0xFFD8493D) : _hibiscusDark);
    }
  }

  bush(Offset(w * 0.1, h * 0.975), 1.0, 3, 1);
  bush(Offset(w * 0.93, h * 0.985), 0.95, 11, -1);
  // dry beach grass tufts
  final r = rng(21);
  for (final bx in [0.22, 0.58, 0.72]) {
    final base = Offset(w * bx, h * (0.9 + r.nextDouble() * 0.015));
    for (var i = 0; i < 5; i++) {
      _leafBlade(c, base + Offset((i - 2) * 3, 0), h * (0.025 + r.nextDouble() * 0.02), (i - 2) * 0.32, const Color(0xFF6FBE45), _palmLight);
    }
  }
  _starfish(c, Offset(w * 0.5, h * 0.89), w * 0.04, 0.3);
  _starfish(c, Offset(w * 0.79, h * 0.9), w * 0.022, 1.2);
  _shell(c, Offset(w * 0.3, h * 0.885), w * 0.028, -0.3, const Color(0xFFFFD9CE), const Color(0xFFEFAFA3));
  _shell(c, Offset(w * 0.64, h * 0.875), w * 0.02, 0.5, const Color(0xFFFFF7EA), const Color(0xFFE6C9A8));
  _shell(c, Offset(w * 0.4, h * 0.9), w * 0.018, 0.9, const Color(0xFFFFE6A8), const Color(0xFFEBC36B));
  // pebbles
  for (var i = 0; i < 7; i++) {
    c.drawOval(Rect.fromCenter(center: Offset(w * (0.2 + r.nextDouble() * 0.6), h * (0.87 + r.nextDouble() * 0.04)), width: 7 + r.nextDouble() * 5, height: 4.5), Paint()..color = i.isEven ? const Color(0xFFE2CBA3) : const Color(0xFFD1B58A));
  }
}

// ---------------------------------------------------------------- live air

void _birds(Canvas c, Size s, Clock k) {
  final w = s.width, h = s.height;
  // seagulls: two small flocks gliding in opposite directions
  const white = Color(0xFFFFFFFF);
  for (var i = 0; i < 4; i++) {
    final t = k.saw(1, i * 0.045);
    final x = -50 + t * (w + 100);
    final y = h * (0.2 + 0.01 * i) + math.sin(tau * (k.u * 3 + i * 0.2)) * 7 + i * 7;
    paintBird(c, Offset(x, y), (8 - i * 0.8) * w / 390, k.sine(24 + i, i * 0.1), white);
  }
  for (var i = 0; i < 2; i++) {
    final t = k.saw(2, 0.4 + i * 0.05);
    final x = w + 50 - t * (w + 100);
    final y = h * (0.29 + 0.015 * i) + math.sin(tau * (k.u * 4 + i * 0.3)) * 6;
    paintBird(c, Offset(x, y), (5.5 - i) * w / 390, k.sine(30 + i, i * 0.2), const Color(0xFFF2FAFF));
  }
}

void _air(Canvas c, Size s, Clock k) {
  // hibiscus petals and pollen on the breeze
  paintParticles(c, s, k, const ParticleSpec(count: 14, seed: 4, colors: [Color(0xFFFF4F7B), Color(0xFFFF8F80), Color(0xFFFFFFFF)], minSize: 2.2, maxSize: 3.4, flow: Offset(0.3, 0.25), cycles: 2, spread: 2, wander: 12, shape: ParticleShape.petal, region: Rect.fromLTRB(0.0, 0.2, 1.0, 0.95), spin: 2, opacity: 0.95));
  paintParticles(c, s, k, const ParticleSpec(count: 22, seed: 9, colors: [Color(0xFFFFFFFF), Color(0xFFFFF3B0)], minSize: 1.0, maxSize: 1.9, flow: Offset(0.12, -0.12), cycles: 2, spread: 2, wander: 10, twinkle: 0.5, shape: ParticleShape.dot, region: Rect.fromLTRB(0.0, 0.05, 1.0, 0.9), opacity: 0.8));
}
