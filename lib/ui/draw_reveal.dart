import 'dart:math';
import 'package:flutter/material.dart';
import '../game/peg_draw.dart';
import 'peg_view.dart';
import 'styles.dart';
import 'theme.dart';
import 'widgets.dart';

/// Full-screen "mystery peg" opening: a glowing capsule shakes and charges up,
/// bursts in the rarity's colour, then the new peg pops out. The rarer the peg,
/// the bigger the show. Tap anywhere to skip to the end.
class DrawReveal extends StatefulWidget {
  const DrawReveal({super.key, required this.theme, required this.rarity, required this.color, required this.onEquip, required this.onClose});
  final PegTheme theme;
  final Rarity rarity;
  final Color color;
  final VoidCallback onEquip;
  final VoidCallback onClose;

  @override
  State<DrawReveal> createState() => _DrawRevealState();
}

class _DrawRevealState extends State<DrawReveal> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: 3800 + widget.rarity.index * 400));
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  // timeline (fractions of the whole animation)
  static const _charge = 0.34, _flash = 0.38;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _glow.dispose();
    super.dispose();
  }

  double _seg(double a, double b) => ((_c.value - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final col = widget.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_c.value < 0.78) _c.animateTo(0.78, duration: const Duration(milliseconds: 250));
      },
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _glow]),
          builder: (_, _) {
            final t = _c.value;
            final chargeT = _seg(0, _charge);
            final popT = _seg(_flash, _flash + 0.28);
            final pop = Curves.elasticOut.transform(popT);
            final flash = t < _charge ? 0.0 : (1 - _seg(_charge, _flash + 0.1)).clamp(0.0, 1.0) * _seg(_charge, _charge + 0.03);
            final shake = t < _charge ? sin(t * 140) * (1 + chargeT * 7) : (t < _flash + 0.12 && widget.rarity.index >= 2 ? sin(t * 200) * 5 * (1 - _seg(_flash, _flash + 0.12)) : 0.0);
            final textT = Curves.easeOut.transform(_seg(0.56, 0.7));
            final nameT = Curves.easeOut.transform(_seg(0.62, 0.76));
            final btnT = Curves.easeOut.transform(_seg(0.78, 0.9));
            final opened = t >= _flash;
            return Stack(fit: StackFit.expand, children: [
              Container(color: Color.lerp(const Color(0xF2050716), const Color(0xF2050716), 0)),
              CustomPaint(painter: _RevealPainter(t, col, widget.rarity, _charge, _flash)),
              if (flash > 0) Positioned.fill(child: ColoredBox(color: Color.lerp(Colors.white, col, 0.25)!.withValues(alpha: flash * 0.85))),
              SafeArea(
                child: Column(children: [
                  const Spacer(flex: 2),
                  Opacity(
                    opacity: textT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - textT) * 16),
                      child: Text(widget.rarity.label.toUpperCase(),
                          style: TextStyle(fontSize: 15, letterSpacing: 5, fontWeight: FontWeight.w800, color: col, shadows: [Shadow(color: col, blurRadius: 18)])),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: Center(
                      child: opened
                          ? Transform.scale(scale: 0.15 + 0.85 * pop, child: SizedBox(width: 160, height: 160, child: PegView(theme: widget.theme, glow: _glow.value)))
                          : Transform.translate(
                              offset: Offset(shake, 0),
                              child: Transform.scale(scale: 0.9 + 0.2 * chargeT + 0.04 * sin(t * 60), child: _capsule(chargeT, col)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: nameT,
                    child: Transform.translate(offset: Offset(0, (1 - nameT) * 14), child: Text(widget.theme.name, style: displayFont.copyWith(fontSize: 28, fontWeight: FontWeight.w800))),
                  ),
                  if (!opened)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Opening…', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6 + 0.3 * sin(t * 50)))),
                    ),
                  const Spacer(flex: 2),
                  Opacity(
                    opacity: btnT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - btnT) * 24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(children: [
                          PillButton(label: 'Equip', primary: true, onTap: btnT > 0.8 ? widget.onEquip : null),
                          const SizedBox(height: 12),
                          PillButton(label: 'Nice!', onTap: btnT > 0.8 ? widget.onClose : null),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _capsule(double charge, Color col) {
    final hot = Color.lerp(const Color(0xFF6A7BFF), col, charge)!;
    return Container(
      width: 130,
      height: 130,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.35, -0.45), colors: [Color.lerp(hot, Colors.white, 0.55)!, hot, const Color(0xFF14194A)], stops: const [0.0, 0.45, 1.0]),
        boxShadow: [BoxShadow(color: hot.withValues(alpha: 0.35 + 0.5 * charge), blurRadius: 30 + 40 * charge, spreadRadius: 4 + 14 * charge)],
        border: Border.all(color: Colors.white.withValues(alpha: 0.25 + 0.4 * charge), width: 2),
      ),
      child: Text('?', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.9))),
    );
  }
}

class _RevealPainter extends CustomPainter {
  _RevealPainter(this.t, this.color, this.rarity, this.charge, this.flash);
  final double t;
  final Color color;
  final Rarity rarity;
  final double charge, flash;

  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width / 2, s.height * 0.43);
    final rays = 8 + rarity.index * 5;
    final n = 24 + rarity.index * 22;
    final maxR = s.longestSide;

    // phase 1: charging - dim rays and motes sucked into the capsule
    if (t < flash) {
      final k = (t / charge).clamp(0.0, 1.0);
      _rays(c, o, maxR * 0.6, 10, t * 3, Color.lerp(const Color(0xFF6A7BFF), color, k)!, 0.05 + 0.2 * k);
      final rnd = Random(4);
      for (var i = 0; i < 26; i++) {
        final a = rnd.nextDouble() * 2 * pi;
        final life = ((k * 1.6 + rnd.nextDouble()) % 1.0);
        final d = (1 - life) * (120 + rnd.nextDouble() * 150) + 30;
        final p = o + Offset(cos(a + life * 1.5) * d, sin(a + life * 1.5) * d);
        c.drawCircle(p, 2.2, Paint()..color = Color.lerp(const Color(0xFFBFC8FF), color, k)!.withValues(alpha: life * 0.9 * k.clamp(0.2, 1.0)));
      }
    }

    // phase 2: burst
    if (t >= charge) {
      final b = ((t - charge) / (1 - charge)).clamp(0.0, 1.0);
      final fade = (1 - (b - 0.55).clamp(0.0, 1.0) * 1.2).clamp(0.3, 1.0);
      c.drawCircle(o, 150 + 160 * b, Paint()..shader = RadialGradient(colors: [color.withValues(alpha: 0.5 * fade), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: 150 + 160 * b)));
      _rays(c, o, maxR, rays, t * 2.2, color, 0.34 * fade);
      for (var i = 0; i < 3 + rarity.index; i++) {
        final r = ((b * 2.4 - i * 0.14)).clamp(0.0, 1.0);
        if (r <= 0 || r >= 1) continue;
        c.drawCircle(o, 40 + r * maxR * 0.55, Paint()..style = PaintingStyle.stroke..strokeWidth = 5 * (1 - r) + 1..color = Color.lerp(Colors.white, color, 0.4)!.withValues(alpha: (1 - r) * 0.8));
      }
      final rnd = Random(9);
      for (var i = 0; i < n; i++) {
        final a = rnd.nextDouble() * 2 * pi;
        final sp = 120 + rnd.nextDouble() * 260 * (1 + rarity.index * 0.3);
        final e = Curves.easeOutCubic.transform(b);
        final p = o + Offset(cos(a) * sp * e, sin(a) * sp * e + 60 * b * b * rnd.nextDouble() * 3);
        final tw = 0.5 + 0.5 * sin(b * 20 + i);
        final rad = 2 + rnd.nextDouble() * 3.5;
        final col = i % 3 == 0 ? Colors.white : color;
        c.drawCircle(p, rad * 2.6, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.5 * fade * tw), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: p, radius: rad * 2.6)));
        c.drawCircle(p, rad * 0.7, Paint()..color = Colors.white.withValues(alpha: fade * tw));
      }
    }
  }

  void _rays(Canvas c, Offset o, double len, int count, double rot, Color col, double alpha) {
    for (var i = 0; i < count; i++) {
      final a = rot + i * 2 * pi / count;
      const w = 0.07;
      final path = Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + cos(a - w) * len, o.dy + sin(a - w) * len)
        ..lineTo(o.dx + cos(a + w) * len, o.dy + sin(a + w) * len)
        ..close();
      c.drawPath(path, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: alpha), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: len)));
    }
  }

  @override
  bool shouldRepaint(_RevealPainter o) => o.t != t;
}
