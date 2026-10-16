import 'dart:math' as math;
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

/// A non-animated look at a world, cropped to fit a card.
class SceneArt extends StatelessWidget {
  const SceneArt(this.world, {super.key, this.u = 0.12});
  final String world;
  final double u;

  @override
  Widget build(BuildContext context) {
    final spec = sceneFor(world);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment(0, spec.focusY),
        child: SizedBox(width: 390, height: 844, child: SceneStack(spec: spec, anim: AlwaysStoppedAnimation(u))),
      ),
    );
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

  Widget _still(Layer l, Size size) {
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

class _LivePainter extends CustomPainter {
  _LivePainter(this.fn, this.anim) : super(repaint: anim);
  final LivePaint fn;
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size, Clock(anim.value));

  @override
  bool shouldRepaint(_LivePainter old) => old.fn != fn;
}
