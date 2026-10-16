import 'dart:math';
import 'package:flutter/material.dart';
import 'background.dart';
import 'theme.dart';
import 'widgets.dart';

/// Short, friendly explanation shown on first launch (and from Settings).
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> with SingleTickerProviderStateMixin {
  final PageController _pc = PageController();
  int page = 0;
  late final AnimationController _demo =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  static const _pages = [
    ('Jump to clear', 'Tap a peg, then tap an empty hole two steps away. The peg hops over its neighbour.'),
    ('Hopped pegs vanish', 'The peg you jump over disappears. Keep jumping and the board slowly empties.'),
    ('Reach the goal', 'Every level shows how many pegs you may leave. Leave just one for a perfect finish. Undo is free, but a clean run earns more stars.'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _demo.value = 0.5;
    } else if (!_demo.isAnimating) {
      _demo.repeat();
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    _demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = page == _pages.length - 1;
    return Scaffold(
      body: SceneBackground(
        world: 'forest',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: widget.onDone, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => page = i),
                  itemBuilder: (_, i) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(
                      height: 150,
                      child: AnimatedBuilder(
                        animation: _demo,
                        builder: (_, _) => CustomPaint(size: const Size(300, 150), painter: _DemoPainter(_demo.value, i)),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(_pages[i].$1, textAlign: TextAlign.center, style: displayFont.copyWith(fontSize: 28, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(_pages[i].$2, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white.withValues(alpha: 0.82))),
                  ]),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == page ? lantern : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: last ? "Let's play" : 'Next',
                  primary: true,
                  onTap: last
                      ? widget.onDone
                      : () => _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Three holes in a row: the left peg hops over the middle one.
class _DemoPainter extends CustomPainter {
  _DemoPainter(this.t, this.step);
  final double t;
  final int step;

  void _peg(Canvas c, Offset o, double r, {double alpha = 1, double lift = 0}) {
    final at = o - Offset(0, r * 0.3 + lift);
    c.drawCircle(o + Offset(0, r * 0.45), r * 0.8 * (1 - lift / 120), Paint()..color = Colors.black.withValues(alpha: 0.35 * alpha));
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [const Color(0xFFFFE3A8).withValues(alpha: alpha), const Color(0xFFE9A04A).withValues(alpha: alpha), const Color(0xFF7A4012).withValues(alpha: alpha)],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  @override
  void paint(Canvas c, Size s) {
    final y = s.height * 0.62;
    final gap = s.width * 0.3;
    final xs = [s.width / 2 - gap, s.width / 2, s.width / 2 + gap];
    const r = 26.0;
    for (final x in xs) {
      c.drawCircle(Offset(x, y), r + 5, Paint()..color = const Color(0xFF3A2312));
      c.drawCircle(Offset(x, y), r + 5, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF9A6234));
    }
    // timeline: 0-0.15 rest, 0.15-0.4 select, 0.4-0.7 hop, 0.7-0.9 rest, 0.9-1 reset
    final hop = ((t - 0.4) / 0.3).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(hop);
    final landed = hop >= 1;
    final selected = t > 0.15 && t < 0.4;
    final fade = t < 0.9 ? 1.0 : ((1 - t) / 0.1).clamp(0.0, 1.0);

    // target glow
    if (selected || (t >= 0.4 && t < 0.7 && !landed)) {
      c.drawCircle(Offset(xs[2], y), r + 8, Paint()..color = lantern.withValues(alpha: 0.5 + 0.2 * sin(t * 30))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      c.drawCircle(Offset(xs[2], y), r - 6, Paint()..color = lantern.withValues(alpha: 0.9));
    }
    // jumped peg (middle) vanishes mid-hop
    final midAlpha = t < 0.55 ? 1.0 : (1 - (t - 0.55) / 0.12).clamp(0.0, 1.0);
    if (step >= 0 && midAlpha > 0) _peg(c, Offset(xs[1], y), r, alpha: midAlpha * fade);
    if (t >= 0.55 && t < 0.7) {
      final k = (t - 0.55) / 0.15;
      c.drawCircle(Offset(xs[1], y - 8), r + k * 30, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = lantern.withValues(alpha: (1 - k)));
    }
    // moving peg
    final x = xs[0] + (xs[2] - xs[0]) * eased;
    final lift = sin(pi * hop) * 70 + (selected ? 8 : 0);
    _peg(c, Offset(x, y), r, alpha: fade, lift: lift);
  }

  @override
  bool shouldRepaint(_DemoPainter old) => old.t != t;
}
