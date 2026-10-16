import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../shaders.dart';

/// Look of one backdrop: which shader variant, palette and extras.
class WorldLook {
  const WorldLook(this.kind, this.c0, this.c1, this.c2, this.c3, {this.ridges = 0, this.particles = 0, this.seed = 0.0});

  /// 0 nebula, 1 aurora, 2 underwater, 3 synthwave, 4 lava, 5 misty sky, 6 bokeh
  final int kind;
  final int c0, c1, c2, c3;
  final int ridges;

  /// 0 none, 1 rising glows (fireflies, embers, bubbles), 2 falling (petals, snow)
  final int particles;
  final double seed;
}

const worldLooks = <String, WorldLook>{
  'menu': WorldLook(3, 0xFF05041A, 0xFF1C0C46, 0xFF35F0FF, 0xFFFF3DB4, seed: 0.1),
  'forest': WorldLook(5, 0xFF03161A, 0xFF0F4A45, 0xFFB5FFE0, 0xFF7DFFB0, ridges: 4, particles: 1, seed: 0.2),
  'desert': WorldLook(5, 0xFF1A0B24, 0xFF8A3A3A, 0xFFFFB36A, 0xFFFFD9A0, ridges: 2, particles: 2, seed: 0.3),
  'coral': WorldLook(2, 0xFF06103A, 0xFF1478B8, 0xFFFF7AC8, 0xFFAEF4FF, particles: 1, seed: 0.4),
  'cosmic': WorldLook(0, 0xFF05040F, 0xFF2A1060, 0xFFFF3DB4, 0xFF4AA8FF, seed: 0.5),
  'frozen': WorldLook(1, 0xFF030A1C, 0xFF0B2A4A, 0xFF5AFFD0, 0xFF9A7AFF, ridges: 2, particles: 2, seed: 0.6),
  'volcanic': WorldLook(4, 0xFF120404, 0xFF7A1A05, 0xFFFF6A1A, 0xFFFFD060, ridges: 2, particles: 1, seed: 0.7),
  'jungle': WorldLook(5, 0xFF02120A, 0xFF0A4A2A, 0xFFD0FF90, 0xFF7AFF6A, ridges: 3, particles: 1, seed: 0.8),
  'cyber': WorldLook(3, 0xFF0A0414, 0xFF2A0A40, 0xFFFF2BD6, 0xFF2AFFD8, ridges: 3, seed: 0.9),
  'countryside': WorldLook(5, 0xFF0C1430, 0xFFA8584E, 0xFFFFD98A, 0xFFFFF0B0, ridges: 3, particles: 1, seed: 1.0),
  'candy': WorldLook(6, 0xFF1A0A30, 0xFF5A1A6A, 0xFFFF7AC8, 0xFF7AE8FF, seed: 1.1),
  'moonlit': WorldLook(5, 0xFF050A1E, 0xFF1A3060, 0xFFD8E4FF, 0xFF9AB8FF, ridges: 3, particles: 1, seed: 1.2),
  'autumn': WorldLook(5, 0xFF140804, 0xFF8A3A10, 0xFFFFB040, 0xFFFF7A2A, ridges: 3, particles: 2, seed: 1.3),
  'ruins': WorldLook(0, 0xFF0A0814, 0xFF3A2A18, 0xFFFFD98A, 0xFF5AFFB8, ridges: 2, particles: 1, seed: 1.4),
  'tropical': WorldLook(2, 0xFF031A2A, 0xFF1AB0B0, 0xFFFFD84A, 0xFFB0FFF0, particles: 1, seed: 1.5),
  'crystal': WorldLook(0, 0xFF06041A, 0xFF2A1A6A, 0xFFB07CFF, 0xFF35F0FF, particles: 1, seed: 1.6),
  'fairytale': WorldLook(6, 0xFF0A1030, 0xFF2A3A8A, 0xFFFFD84A, 0xFF7AA8FF, ridges: 2, seed: 1.7),
  'treasure': WorldLook(4, 0xFF100A02, 0xFF6A4A08, 0xFFFFC83A, 0xFFFFF0A0, particles: 1, seed: 1.8),
  'sakura': WorldLook(5, 0xFF140A24, 0xFF6A2A5A, 0xFFFFC0D8, 0xFFFF8AC0, ridges: 3, particles: 2, seed: 1.9),
  'deepsea': WorldLook(2, 0xFF02061A, 0xFF0A2A6A, 0xFF35F0FF, 0xFF7A5CFF, particles: 1, seed: 2.0),
  'skyislands': WorldLook(0, 0xFF0A1030, 0xFF3A50B0, 0xFFB8D0FF, 0xFFFF9AD0, particles: 1, seed: 2.1),
};

bool get shadersReady => Gfx.world != null;

/// Full-bleed animated shader backdrop. [freezeAt] shows a still frame
/// (seconds into the animation) - used for screenshots and reduced motion.
class ShaderBackdrop extends StatefulWidget {
  const ShaderBackdrop({super.key, required this.world, this.freezeAt});
  final String world;
  final double? freezeAt;

  @override
  State<ShaderBackdrop> createState() => _ShaderBackdropState();
}

class _ShaderBackdropState extends State<ShaderBackdrop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6 + 20);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = widget.freezeAt != null || (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (_still) {
      _ticker.stop();
      _t.value = widget.freezeAt ?? 30;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = worldLooks[widget.world] ?? worldLooks['menu']!;
    return RepaintBoundary(child: CustomPaint(painter: _ShaderPainter(look, _t), size: Size.infinite));
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.look, this.t) : super(repaint: t);
  final WorldLook look;
  final ValueNotifier<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final prog = Gfx.world;
    final rect = Offset.zero & size;
    if (prog == null) {
      canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(look.c0), Color(look.c1), Color(look.c0)]).createShader(rect));
      return;
    }
    final sh = prog.fragmentShader();
    var i = 0;
    sh
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      ..setFloat(i++, t.value)
      ..setFloat(i++, look.kind.toDouble())
      ..setFloat(i++, look.ridges.toDouble())
      ..setFloat(i++, look.particles.toDouble())
      ..setFloat(i++, look.seed);
    for (final c in [look.c0, look.c1, look.c2, look.c3]) {
      final k = Color(c);
      sh
        ..setFloat(i++, k.r)
        ..setFloat(i++, k.g)
        ..setFloat(i++, k.b);
    }
    canvas.drawRect(rect, Paint()..shader = sh);
    sh.dispose();
  }

  @override
  bool shouldRepaint(_ShaderPainter old) => old.look != look;
}
