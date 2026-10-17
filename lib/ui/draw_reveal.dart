import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/peg_draw.dart';
import '../sfx.dart';
import 'peg_view.dart';
import 'styles.dart';
import 'theme.dart';
import 'widgets.dart';

const _tile = 108.0;
const _winIndex = 46;
const _reelLength = 60;

Color _rarityColor(Rarity r) => switch (r) {
      Rarity.common => const Color(0xFF9AA7C0),
      Rarity.rare => const Color(0xFF4FA8FF),
      Rarity.epic => const Color(0xFFB06CFF),
      Rarity.legendary => const Color(0xFFFFC83A),
    };

/// Slot-machine style opening of a mystery peg: a reel of every peg spins past
/// the marker, slows down and stops on the one you won. Pegs are pre-rendered
/// to pictures once, so spinning only draws images and stays smooth.
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
  late final AnimationController _spin = AnimationController(vsync: this, duration: Duration(milliseconds: 5200 + widget.rarity.index * 500));
  late final AnimationController _after = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  final Map<String, ui.Image> _img = {};
  late final List<String> _reel;
  late final double _stopAt;
  bool _ready = false;
  int _lastTick = -1;
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final ids = [for (final t in pegThemes) t.id];
    _reel = [for (var i = 0; i < _reelLength; i++) ids[(i * 7 + rng.nextInt(ids.length)) % ids.length]];
    // no neighbour twice in a row, winner at a fixed spot
    for (var i = 1; i < _reel.length; i++) {
      if (_reel[i] == _reel[i - 1]) _reel[i] = ids[(ids.indexOf(_reel[i]) + 1) % ids.length];
    }
    _reel[_winIndex] = widget.theme.id;
    for (final j in [_winIndex - 1, _winIndex + 1]) {
      if (_reel[j] == widget.theme.id) _reel[j] = ids[(ids.indexOf(widget.theme.id) + 3) % ids.length];
    }
    // stop with the marker somewhere on the winner, not always dead centre
    _stopAt = _winIndex * _tile + _tile / 2 + (rng.nextDouble() - 0.5) * _tile * 0.5;
    _spin.addListener(_onSpin);
    _spin.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_landed) _land();
    });
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    for (final t in pegThemes) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(2);
      c.translate(24, 24);
      paintPeg(c, const Size(80, 80), t, 0.3);
      final pic = rec.endRecording();
      final img = await pic.toImage(256 ~/ 1, 256 ~/ 1).timeout(const Duration(seconds: 2));
      pic.dispose();
      if (!mounted) {
        img.dispose();
        return;
      }
      _img[t.id] = img;
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted) return;
    setState(() => _ready = true);
    _glow.repeat();
    if (reduceMotion(context)) {
      _spin.value = 1;
      _land();
    } else {
      _spin.forward();
    }
  }

  void _onSpin() {
    final x = _scroll;
    final idx = (x / _tile).floor();
    if (idx != _lastTick && _spin.value < 0.97) {
      _lastTick = idx;
      HapticFeedback.selectionClick();
    }
  }

  void _land() {
    _landed = true;
    HapticFeedback.heavyImpact();
    Sfx.play('unlock');
    _after.forward();
    setState(() {});
  }

  double get _scroll => _stopAt * Curves.easeOutQuart.transform(_spin.value);

  @override
  void dispose() {
    _spin.dispose();
    _after.dispose();
    _glow.dispose();
    for (final i in _img.values) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_ready && !_landed && _spin.value < 0.7) _spin.animateTo(0.7, duration: const Duration(milliseconds: 300));
      },
      child: Material(
        color: const Color(0xFF050716),
        child: AnimatedBuilder(
          animation: Listenable.merge([_spin, _after, _glow]),
          builder: (_, _) {
            final a = _after.value;
            final nameT = Curves.easeOut.transform(((a - 0.25) / 0.3).clamp(0.0, 1.0));
            final btnT = Curves.easeOut.transform(((a - 0.6) / 0.3).clamp(0.0, 1.0));
            final pop = Curves.elasticOut.transform((a / 0.6).clamp(0.0, 1.0));
            // marker colour follows the peg that is passing by
            final passing = _reel[((_scroll) / _tile).floor().clamp(0, _reel.length - 1)];
            final markCol = _landed ? col : _rarityColor(rarityOf(passing));
            return Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _BackPainter(_spin.value, a, markCol, widget.rarity)),
              SafeArea(
                child: Column(children: [
                  const Spacer(flex: 3),
                  Text(_landed ? widget.rarity.label.toUpperCase() : 'MYSTERY PEG',
                      style: TextStyle(fontSize: 15, letterSpacing: 5, fontWeight: FontWeight.w800, color: _landed ? col : Colors.white70, shadows: _landed ? [Shadow(color: col, blurRadius: 18)] : null)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: _ready
                        ? CustomPaint(painter: _ReelPainter(_reel, _img, _scroll, markCol, _landed ? a : 0, _winIndex))
                        : const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    height: 150,
                    child: _landed
                        ? Opacity(
                            opacity: nameT,
                            child: Column(children: [
                              Transform.scale(scale: 0.3 + 0.7 * pop, child: SizedBox(width: 96, height: 96, child: PegView(theme: widget.theme, glow: _glow.value))),
                              const SizedBox(height: 12),
                              Text(widget.theme.name, style: displayFont.copyWith(fontSize: 26, fontWeight: FontWeight.w800)),
                            ]),
                          )
                        : const SizedBox.shrink(),
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
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.spin, this.after, this.color, this.rarity);
  final double spin, after;
  final Color color;
  final Rarity rarity;

  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width / 2, s.height * 0.31);
    final k = after > 0 ? 1.0 : (0.25 + 0.5 * spin);
    final r = s.width * (0.9 + (after > 0 ? 0.7 * Curves.easeOut.transform(after) : 0));
    c.drawCircle(o, r, Paint()..shader = RadialGradient(colors: [color.withValues(alpha: 0.35 * k), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)));
    if (after > 0) {
      final rays = 8 + rarity.index * 5;
      final path = Path();
      for (var i = 0; i < rays; i++) {
        final a = after * 1.5 + i * 2 * pi / rays;
        const w = 0.06;
        final len = s.longestSide;
        path
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + cos(a - w) * len, o.dy + sin(a - w) * len)
          ..lineTo(o.dx + cos(a + w) * len, o.dy + sin(a + w) * len)
          ..close();
      }
      c.drawPath(path, Paint()..shader = RadialGradient(colors: [color.withValues(alpha: 0.3 * (1 - after * 0.3)), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: s.longestSide)));
      // shock rings from the winning tile
      for (var i = 0; i < 2 + rarity.index; i++) {
        final t = (after * 1.8 - i * 0.16).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) continue;
        c.drawCircle(o, 40 + t * s.width * 0.8, Paint()..style = PaintingStyle.stroke..strokeWidth = 4 * (1 - t) + 1..color = Color.lerp(Colors.white, color, 0.4)!.withValues(alpha: (1 - t) * 0.8));
      }
      final rnd = Random(9);
      final n = 20 + rarity.index * 18;
      for (var i = 0; i < n; i++) {
        final ang = rnd.nextDouble() * 2 * pi;
        final sp = 90 + rnd.nextDouble() * 240;
        final e = Curves.easeOutCubic.transform(after);
        final p = o + Offset(cos(ang) * sp * e, sin(ang) * sp * e + 40 * after * after * rnd.nextDouble() * 3);
        final tw = 0.5 + 0.5 * sin(after * 20 + i);
        c.drawCircle(p, 2 + rnd.nextDouble() * 3, Paint()..color = (i % 3 == 0 ? Colors.white : color).withValues(alpha: (1 - after * 0.6) * tw));
      }
    }
  }

  @override
  bool shouldRepaint(_BackPainter o) => true;
}

class _ReelPainter extends CustomPainter {
  _ReelPainter(this.reel, this.img, this.scroll, this.color, this.landed, this.winIndex);
  final List<String> reel;
  final Map<String, ui.Image> img;
  final double scroll;
  final Color color;
  final double landed; // 0 while spinning, then 0..1
  final int winIndex;

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final first = ((scroll - cx) / _tile).floor() - 1;
    final last = ((scroll + cx) / _tile).ceil() + 1;
    final pop = landed > 0 ? Curves.elasticOut.transform((landed / 0.5).clamp(0.0, 1.0)) : 0.0;
    c.save();
    c.clipRect(Offset.zero & s);
    for (var i = first; i <= last; i++) {
      if (i < 0 || i >= reel.length) continue;
      final x = cx + i * _tile + _tile / 2 - scroll;
      final center = Offset(x, s.height / 2);
      final dist = ((x - cx).abs() / (s.width * 0.5)).clamp(0.0, 1.0);
      final isWin = i == winIndex && landed > 0;
      final k = isWin ? 1.0 + 0.22 * pop : 1 - 0.18 * dist;
      final id = reel[i];
      final rc = _rarityColor(rarityOf(id));
      final dim = landed > 0 && !isWin ? 0.35 : 1.0;
      final box = Rect.fromCenter(center: center, width: (_tile - 12) * k, height: (_tile + 20) * k);
      final rr = RRect.fromRectAndRadius(box, const Radius.circular(18));
      c.drawRRect(rr, Paint()..color = const Color(0xFF12183F).withValues(alpha: 0.95 * dim));
      c.drawRRect(rr, Paint()..style = PaintingStyle.stroke..strokeWidth = isWin ? 3 : 2..color = rc.withValues(alpha: (isWin ? 1.0 : 0.65) * dim));
      c.drawRect(Rect.fromLTWH(box.left + 16, box.bottom - 9 * k, box.width - 32, 3.5), Paint()..color = rc.withValues(alpha: 0.9 * dim));
      final im = img[id];
      if (im != null) {
        final side = (_tile - 4) * k * 0.92;
        c.drawImageRect(
          im,
          Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
          Rect.fromCenter(center: center - Offset(0, 4 * k), width: side * 1.6, height: side * 1.6),
          Paint()..filterQuality = FilterQuality.medium..color = Colors.white.withValues(alpha: dim),
        );
      }
    }
    c.restore();

    // edge fade
    for (final left in [true, false]) {
      final r = left ? Rect.fromLTWH(0, 0, 70, s.height) : Rect.fromLTWH(s.width - 70, 0, 70, s.height);
      c.drawRect(
        r,
        Paint()..shader = LinearGradient(colors: left ? const [Color(0xFF050716), Color(0x00050716)] : const [Color(0x00050716), Color(0xFF050716)]).createShader(r),
      );
    }

    // marker: glowing line with pointers
    final line = Paint()..color = color.withValues(alpha: 0.9)..strokeWidth = 2.5;
    c.drawLine(Offset(cx, 14), Offset(cx, s.height - 14), line..color = color.withValues(alpha: landed > 0 ? 0.0 : 0.55));
    for (final top in [true, false]) {
      final y = top ? 2.0 : s.height - 2.0;
      final d = top ? 1.0 : -1.0;
      c.drawPath(Path()..moveTo(cx - 12, y)..lineTo(cx + 12, y)..lineTo(cx, y + 18 * d)..close(), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ReelPainter o) => true;
}
