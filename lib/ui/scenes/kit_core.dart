import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

const double tau = math.pi * 2;

// ---------------------------------------------------------------- time

/// Seamless loop clock. [u] runs 0 -> 1 over [loopSeconds] and then starts over,
/// so every animation must use a WHOLE number of cycles per loop to join up.
/// (60 cycles = once per second, 12 = every 5 s, 3 = every 20 s, 1 = once a minute.)
class Clock {
  const Clock(this.u);
  final double u;
  static const double loopSeconds = 60;

  /// 0..1 ramp that repeats [cycles] times per loop.
  double saw(int cycles, [double phase = 0]) {
    final v = (u * cycles + phase) % 1.0;
    return v < 0 ? v + 1 : v;
  }

  /// -1..1 sine.
  double sine(int cycles, [double phase = 0]) => math.sin(tau * (u * cycles + phase));

  /// 0..1 smooth pulse (0.5 + 0.5 * sine).
  double pulse(int cycles, [double phase = 0]) => 0.5 + 0.5 * sine(cycles, phase);
}

// ---------------------------------------------------------------- colour

Color mix(Color a, Color b, double t) => Color.lerp(a, b, t.clamp(0.0, 1.0))!;

/// Changes HSL lightness by [amt] (-1..1).
Color lighten(Color c, double amt) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amt).clamp(0.0, 1.0)).toColor();
}

Color darken(Color c, double amt) => lighten(c, -amt);

/// Changes HSL saturation by [amt] (-1..1).
Color saturate(Color c, double amt) {
  final h = HSLColor.fromColor(c);
  return h.withSaturation((h.saturation + amt).clamp(0.0, 1.0)).toColor();
}

Color hueShift(Color c, double degrees) {
  final h = HSLColor.fromColor(c);
  return h.withHue((h.hue + degrees) % 360).toColor();
}

Color alpha(Color c, double a) => c.withValues(alpha: a.clamp(0.0, 1.0));

/// Atmospheric perspective: blend [c] towards the [haze] colour.
Color hazeTo(Color c, Color haze, double amt) => mix(c, haze, amt);

// ---------------------------------------------------------------- noise

final Map<int, List<double>> _tables = {};

List<double> _table(int seed) => _tables.putIfAbsent(seed, () {
      final r = math.Random(seed * 7919 + 13);
      return List<double>.generate(512, (_) => r.nextDouble());
    });

/// Smooth 1-D value noise in 0..1 (period 512).
double vnoise(double x, [int seed = 0]) {
  final t = _table(seed);
  final i = x.floor();
  final f = x - i;
  final a = t[i & 511], b = t[(i + 1) & 511];
  final s = f * f * (3 - 2 * f);
  return a + (b - a) * s;
}

/// Fractal noise in 0..1.
double fbm(double x, {int seed = 0, int octaves = 4, double gain = 0.5, double lacunarity = 2.0}) {
  var amp = 1.0, freq = 1.0, sum = 0.0, norm = 0.0;
  for (var i = 0; i < octaves; i++) {
    sum += amp * vnoise(x * freq + i * 17.31, seed + i);
    norm += amp;
    amp *= gain;
    freq *= lacunarity;
  }
  return sum / norm;
}

/// Deterministic random numbers for decoration (same picture every time).
math.Random rng(int seed) => math.Random(seed * 2654435761 % 4294967296);

// ---------------------------------------------------------------- paint helpers

List<double>? _evenStops(List<Color> colors, List<double>? stops) =>
    stops ?? (colors.length == 2 ? null : [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)]);

/// Top-to-bottom gradient paint filling [r]. Stops default to even spacing.
Paint verticalPaint(Rect r, List<Color> colors, [List<double>? stops]) =>
    Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, colors, _evenStops(colors, stops));

Paint linearPaint(Offset a, Offset b, List<Color> colors, [List<double>? stops]) =>
    Paint()..shader = ui.Gradient.linear(a, b, colors, _evenStops(colors, stops));

Paint radialPaint(Offset center, double radius, List<Color> colors, [List<double>? stops]) =>
    Paint()..shader = ui.Gradient.radial(center, radius, colors, _evenStops(colors, stops));

/// Fills the whole canvas area with a vertical sky gradient.
void fillSky(Canvas c, Size s, List<Color> colors, [List<double>? stops]) {
  c.drawRect(Offset.zero & s, verticalPaint(Offset.zero & s, colors, stops));
}

final Map<int, Paint> _glowPaints = {};

/// Soft round glow (radial gradient, very cheap). [a] scales the opacity;
/// [add] adds light instead of covering (fire, neon, sun).
void glow(Canvas c, Offset o, double r, Color color, [double a = 1.0, bool add = false]) {
  if (r <= 0 || a <= 0) return;
  final key = color.toARGB32() & 0xFFFFFF;
  final p = _glowPaints.putIfAbsent(key, () {
    final base = Color(0xFF000000 | key);
    return Paint()
      ..shader = ui.Gradient.radial(Offset.zero, 1, [
        base.withValues(alpha: 1.0),
        base.withValues(alpha: 0.55),
        base.withValues(alpha: 0.2),
        base.withValues(alpha: 0.05),
        base.withValues(alpha: 0.0),
      ], const [0.0, 0.22, 0.5, 0.78, 1.0]);
  });
  p.color = Color.fromARGB((color.a * a * 255).round().clamp(0, 255), 255, 255, 255);
  p.blendMode = add ? BlendMode.plus : BlendMode.srcOver;
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..scale(r)
    ..drawCircle(Offset.zero, 1, p)
    ..restore();
}

// ---------------------------------------------------------------- layers

typedef StillPaint = void Function(Canvas canvas, Size size);
typedef LivePaint = void Function(Canvas canvas, Size size, Clock clock);

/// One slice of a world, drawn back to front.
///
/// * [Layer.still]: painted ONCE and cached as a picture; it can glide
///   ([driftX]/[driftY] as fractions of the screen), sway (skew, [sway] radians
///   around [pivot]), rotate or breathe. Cheap, use it for everything that does
///   not change shape.
/// * [Layer.live]: painted every frame from the [Clock]; use it for particles,
///   twinkling stars, fish, birds, waves, spinning blades ... keep it light.
class Layer {
  const Layer.still(
    StillPaint this.still, {
    this.driftX = 0,
    this.driftY = 0,
    this.driftCycles = 2,
    this.driftPhase = 0,
    this.sway = 0,
    this.rotate = 0,
    this.swayCycles = 4,
    this.swayPhase = 0,
    this.breathe = 0,
    this.breatheCycles = 3,
    this.pivot = Alignment.bottomCenter,
  })  : live = null,
        scrollCycles = 0,
        scrollLeft = true,
        bandTop = 0,
        bandBottom = 1;

  const Layer.live(LivePaint this.live)
      : still = null,
        scrollCycles = 0,
        scrollLeft = true,
        bandTop = 0,
        bandBottom = 1,
        driftX = 0,
        driftY = 0,
        driftCycles = 1,
        driftPhase = 0,
        sway = 0,
        rotate = 0,
        swayCycles = 1,
        swayPhase = 0,
        breathe = 0,
        breatheCycles = 1,
        pivot = Alignment.center;

  /// A horizontally endless strip (cloud decks, mist, waves, flocks): [paint]
  /// is called for the whole screen but must be PERIODIC in x (anything that
  /// crosses the left/right edge is drawn again on the other side by the kit,
  /// which calls [paint] three times side by side). Only rows between [top] and
  /// [bottom] (fractions of the height) are kept, which saves memory.
  /// It scrolls once across the screen every `60 / cycles` seconds.
  const Layer.scroll(
    StillPaint this.still, {
    this.scrollCycles = 1,
    this.scrollLeft = true,
    this.bandTop = 0,
    this.bandBottom = 1,
  })  : live = null,
        driftX = 0,
        driftY = 0,
        driftCycles = 1,
        driftPhase = 0,
        sway = 0,
        rotate = 0,
        swayCycles = 1,
        swayPhase = 0,
        breathe = 0,
        breatheCycles = 1,
        pivot = Alignment.center;

  final StillPaint? still;
  final LivePaint? live;
  final int scrollCycles;
  final bool scrollLeft;
  final double bandTop, bandBottom;
  final double driftX, driftY;
  final int driftCycles;
  final double driftPhase;
  final double sway, rotate;
  final int swayCycles;
  final double swayPhase;
  final double breathe;
  final int breatheCycles;
  final Alignment pivot;

  bool get moves => scrollCycles > 0 || driftX != 0 || driftY != 0 || sway != 0 || rotate != 0 || breathe != 0;
}

/// Everything the app needs to show one world.
class SceneSpec {
  SceneSpec({
    required this.layers,
    this.focusY = 0.0,
    this.topShade = 0.22,
    this.bottomShade = 0.38,
  });

  /// Back to front.
  final List<Layer> layers;

  /// Which horizontal band world cards show: -1 = top of the scene, 1 = bottom.
  final double focusY;

  /// Dark overlay strength (0..1) behind the title bar / bottom bar, for legible UI.
  final double topShade, bottomShade;

  /// [layers] with neighbouring non-moving still layers merged, so they share
  /// one cached picture (less memory, fewer textures).
  late final List<Layer> renderLayers = _merge(layers);

  static List<Layer> _merge(List<Layer> src) {
    final out = <Layer>[];
    for (final l in src) {
      final prev = out.isEmpty ? null : out.last;
      if (prev != null && prev.still != null && !prev.moves && l.still != null && !l.moves) {
        final a = prev.still!, b = l.still!;
        out[out.length - 1] = Layer.still((c, s) {
          a(c, s);
          b(c, s);
        });
      } else {
        out.add(l);
      }
    }
    return out;
  }
}
