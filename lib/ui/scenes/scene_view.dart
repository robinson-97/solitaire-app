import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'kit.dart';
import 'registry.dart';

bool _reduceMotion(BuildContext c) => MediaQuery.maybeOf(c)?.disableAnimations ?? false;

/// Animated world scenery behind a screen. Stops moving when the phone's
/// "reduce motion" setting is on.
class SceneBackground extends StatefulWidget {
  const SceneBackground({super.key, required this.world, this.child = const SizedBox.shrink(), this.freezeAt});

  /// World id from the catalog, e.g. 'forest'.
  final String world;
  final Widget child;

  /// Show a still frame at this point of the loop (0..1) instead of animating.
  final double? freezeAt;

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(seconds: Clock.loopSeconds.toInt()));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.freezeAt != null || _reduceMotion(context)) {
      _c.stop();
      _c.value = widget.freezeAt ?? 0.12;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = sceneFor(widget.world);
    return Stack(fit: StackFit.expand, children: [
      Positioned.fill(child: RepaintBoundary(child: SceneStack(spec: spec, anim: _c))),
      // soft darkening so titles and buttons stay readable
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: spec.topShade),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: spec.bottomShade),
                ],
                stops: const [0.0, 0.2, 0.62, 1.0],
              ),
            ),
          ),
        ),
      ),
      widget.child,
    ]);
  }
}

final Map<String, Future<ui.Image>> _thumbs = {};

/// One still frame of a world as an image (drawn once, then cached).
Future<ui.Image> sceneThumbnail(String world, {double u = 0.12}) => _thumbs.putIfAbsent('$world@$u', () {
      final spec = sceneFor(world);
      const size = Size(390, 844);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final clock = Clock(u);
      for (final l in spec.layers) {
        if (l.live != null) {
          l.live!(c, size, clock);
        } else {
          l.still!(c, size);
        }
      }
      return rec.endRecording().toImage(size.width.round(), size.height.round());
    });

/// A non-animated picture of a world for cards (rendered once and cached).
class SceneArt extends StatefulWidget {
  const SceneArt(this.world, {super.key, this.u = 0.12, this.delay = Duration.zero});
  final String world;
  final double u;

  /// Staggers the first drawing of many cards so scrolling stays smooth.
  final Duration delay;

  @override
  State<SceneArt> createState() => _SceneArtState();
}

class _SceneArtState extends State<SceneArt> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SceneArt old) {
    super.didUpdateWidget(old);
    if (old.world != widget.world || old.u != widget.u) _load();
  }

  Future<void> _load() async {
    if (widget.delay > Duration.zero) await Future<void>.delayed(widget.delay);
    final img = await sceneThumbnail(widget.world, u: widget.u);
    if (mounted) setState(() => _image = img);
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) return const ColoredBox(color: Color(0xFF16204A));
    return RawImage(image: img, fit: BoxFit.cover, alignment: Alignment(0, sceneFor(widget.world).focusY), filterQuality: FilterQuality.medium);
  }
}

/// Builds the layers of a scene. [anim] drives the loop clock (0..1).
class SceneStack extends StatelessWidget {
  const SceneStack({super.key, required this.spec, required this.anim});
  final SceneSpec spec;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        if (size.isEmpty) return const SizedBox.shrink();
        return Stack(fit: StackFit.expand, clipBehavior: Clip.hardEdge, children: [
          for (final l in spec.renderLayers)
            if (l.live != null)
              Positioned.fill(child: CustomPaint(painter: _LivePainter(l.live!, anim)))
            else
              _still(l, size),
        ]);
      });

  Widget _scroll(Layer l, Size size) {
    final w = size.width, top = l.bandTop * size.height, bh = (l.bandBottom - l.bandTop) * size.height;
    final strip = RepaintBoundary(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 3 * w,
        maxWidth: 3 * w,
        minHeight: bh,
        maxHeight: bh,
        child: CustomPaint(size: Size(3 * w, bh), painter: _ScrollPainter(l.still!, size, top)),
      ),
    );
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: anim,
        child: strip,
        builder: (_, child) {
          final k = Clock(anim.value).saw(l.scrollCycles);
          final dx = l.scrollLeft ? -w * k : w * k;
          return Transform.translate(offset: Offset(-w + dx, top), child: child);
        },
      ),
    );
  }

  Widget _still(Layer l, Size size) {
    if (l.scrollCycles > 0) return _scroll(l, size);
    final bx = (l.driftX.abs() + 0.05) * size.width + l.rotate.abs() * size.height * 0.5;
    final by = (l.driftY.abs() + 0.03) * size.height + l.sway.abs() * size.height * 0.5;
    final big = Size(size.width + 2 * bx, size.height + 2 * by);
    Widget art = RepaintBoundary(
      child: OverflowBox(
        minWidth: big.width,
        maxWidth: big.width,
        minHeight: big.height,
        maxHeight: big.height,
        child: CustomPaint(size: big, painter: _StillPainter(l.still!, size, Offset(bx, by))),
      ),
    );
    if (l.moves) {
      art = AnimatedBuilder(
        animation: anim,
        child: art,
        builder: (_, child) => Transform(transform: _matrix(l, anim.value, size), alignment: l.pivot, child: child),
      );
    }
    return Positioned.fill(child: art);
  }
}

Matrix4 _matrix(Layer l, double u, Size s) {
  final k = Clock(u);
  final m = Matrix4.identity();
  if (l.driftX != 0 || l.driftY != 0) {
    m.translateByDouble(l.driftX * s.width * k.sine(l.driftCycles, l.driftPhase), l.driftY * s.height * k.sine(l.driftCycles, l.driftPhase + 0.25), 0, 1);
  }
  if (l.rotate != 0) m.rotateZ(l.rotate * k.sine(l.swayCycles, l.swayPhase));
  if (l.sway != 0) {
    final sk = Matrix4.identity();
    sk.setEntry(0, 1, math.tan(l.sway * k.sine(l.swayCycles, l.swayPhase))); // horizontal skew
    m.multiply(sk);
  }
  if (l.breathe != 0) {
    final sc = 1 + l.breathe * k.sine(l.breatheCycles);
    m.scaleByDouble(sc, sc, 1, 1);
  }
  return m;
}

class _StillPainter extends CustomPainter {
  _StillPainter(this.fn, this.screen, this.offset);
  final StillPaint fn;
  final Size screen;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(offset.dx, offset.dy);
    fn(canvas, screen);
  }

  @override
  bool shouldRepaint(_StillPainter old) => old.fn != fn || old.screen != screen;
}

class _ScrollPainter extends CustomPainter {
  _ScrollPainter(this.fn, this.screen, this.top);
  final StillPaint fn;
  final Size screen;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    for (var t = 0; t < 3; t++) {
      canvas
        ..save()
        ..translate(t * screen.width, -top);
      fn(canvas, screen);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScrollPainter old) => old.fn != fn || old.screen != screen;
}

class _LivePainter extends CustomPainter {
  _LivePainter(this.fn, this.anim) : super(repaint: anim);
  final LivePaint fn;
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size, Clock(anim.value));

  @override
  bool shouldRepaint(_LivePainter old) => old.fn != fn;
}
