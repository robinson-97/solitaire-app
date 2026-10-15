import 'package:flutter/material.dart';
import '../game/board_def.dart';
import '../game/peg_game.dart';
import 'game_screen.dart' show BoardGeometry;
import 'theme.dart';

/// Frosted dark panel used across menus.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14), this.glow = false});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x5524306B), Color(0x990A1230)],
          ),
          border: Border.all(color: glow ? lantern.withValues(alpha: 0.7) : Colors.white24, width: 1.2),
          boxShadow: [
            BoxShadow(color: glow ? lantern.withValues(alpha: 0.25) : Colors.black45, blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Medal as 3 gems: bronze=1, silver=2, gold=3.
class MedalStars extends StatelessWidget {
  const MedalStars(this.best, {super.key, this.size = 16});
  final int best;
  final double size;

  @override
  Widget build(BuildContext context) {
    final n = switch (ScoreBreakdown.medalFor(best)) {
      Medal.gold => 3,
      Medal.silver => 2,
      Medal.bronze => 1,
      Medal.none => 0,
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 3; i++)
        Icon(Icons.star_rounded, size: size, color: i < n ? const Color(0xFFFFD25A) : Colors.white24),
    ]);
  }
}

/// Tiny drawing of a board with its starting pegs.
class BoardPreview extends StatelessWidget {
  const BoardPreview(this.def, {super.key, this.size = 64});
  final BoardDef def;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PreviewPainter(def)),
      );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.def);
  final BoardDef def;

  @override
  void paint(Canvas canvas, Size s) {
    final n = def.cols > def.rows ? def.cols : def.rows;
    final cell = s.shortestSide / (n + 1);
    final geo = BoardGeometry(def, cell);
    canvas.translate((s.width - geo.width) / 2, (s.height - geo.height) / 2);
    final wood = Path();
    for (final h in def.holes) {
      wood.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: geo.centerOf(h), width: cell * 1.1, height: cell * 1.1),
        Radius.circular(cell * 0.4),
      ));
    }
    canvas.drawPath(wood, Paint()..color = woodLight);
    for (final h in def.holes) {
      final c = geo.centerOf(h);
      canvas.drawCircle(c, cell * 0.3, Paint()..color = holeColor);
      if (def.pegs.contains(h)) {
        canvas.drawCircle(c, cell * 0.3, Paint()..color = const Color(0xFFFFC46B));
      }
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.def.id != def.id;
}
