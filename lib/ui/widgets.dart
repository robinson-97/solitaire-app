import 'dart:math';
import 'package:flutter/material.dart';
import '../game/board_def.dart';
import 'game_screen.dart' show BoardGeometry;
import 'styles.dart';
import 'theme.dart';

/// Gentle fade + rise used for every screen change.
Route<T> softRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );

/// Frosted dark panel used across menus.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.glow,
    this.radius = 24,
    this.dim = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? glow;
  final double radius;
  final bool dim;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: dim ? 0.62 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x9926307A), Color(0xCC0A1030)],
            ),
            border: Border.all(
              color: glow?.withValues(alpha: 0.7) ?? Colors.white.withValues(alpha: 0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glow?.withValues(alpha: 0.28) ?? Colors.black.withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      );
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.danger = false,
    this.compact = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = primary ? const Color(0xFF2B1604) : parchment;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.4,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: primary
              ? const LinearGradient(colors: [Color(0xFFFFCB78), Color(0xFFE58E22)])
              : danger
                  ? const LinearGradient(colors: [Color(0xFFB4372E), Color(0xFF7E1F1A)])
                  : const LinearGradient(colors: [Color(0x33FFFFFF), Color(0x14FFFFFF)]),
          border: primary ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: primary
              ? [BoxShadow(color: lantern.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22, vertical: compact ? 10 : 14),
              child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1,
                        style: TextStyle(fontSize: compact ? 14 : 16, fontWeight: FontWeight.w600, color: fg)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key, this.color = lantern, this.height = 8});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Container(
          height: height,
          color: Colors.white.withValues(alpha: 0.12),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
              ),
            ),
          ),
        ),
      );
}

class Chip2 extends StatelessWidget {
  const Chip2(this.text, {super.key, this.color = lantern});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.4)),
      );
}

/// Tiny drawing of a board with its starting pegs.
class BoardPreview extends StatelessWidget {
  const BoardPreview(this.def, {super.key, this.size = 64, this.theme, this.showPegs = true});
  final BoardDef def;
  final double size;
  final BoardTheme? theme;
  final bool showPegs;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PreviewPainter(def, theme, showPegs)),
      );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.def, this.theme, this.showPegs);
  final BoardDef def;
  final BoardTheme? theme;
  final bool showPegs;

  @override
  void paint(Canvas canvas, Size s) {
    final n = max(def.cols, def.rows);
    final cell = s.shortestSide / (n + 1);
    final geo = BoardGeometry(def, cell);
    canvas.translate((s.width - geo.width) / 2, (s.height - geo.height) / 2);
    var wood = Path();
    for (final h in def.holes) {
      wood = Path.combine(
        PathOperation.union,
        wood,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: geo.centerOf(h), width: cell * 1.15, height: cell * 1.15),
            Radius.circular(cell * 0.32),
          )),
      );
    }
    final b = wood.getBounds();
    final colors = theme?.body ?? const [Color(0xFFC48A52), Color(0xFF9A6234), Color(0xFF6B4423)];
    canvas.drawPath(wood.shift(const Offset(0, 1.5)), Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawPath(
      wood,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors).createShader(b),
    );
    for (final h in def.holes) {
      final c = geo.centerOf(h);
      canvas.drawCircle(c, cell * 0.3, Paint()..color = theme?.holeOuter ?? holeColor);
      if (showPegs && def.pegs.contains(h)) {
        canvas.drawCircle(c, cell * 0.27, Paint()..color = const Color(0xFFFFC46B));
      }
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.def.id != def.id || old.theme != theme;
}

/// Floating bottom navigation.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.explore_rounded, 'Play'),
    (Icons.diamond_rounded, 'Collection'),
    (Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(colors: [Color(0xEE1B2160), Color(0xEE0B1033)]),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: i == index ? lantern.withValues(alpha: 0.18) : Colors.transparent,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_items[i].$1, size: 24, color: i == index ? lantern : Colors.white60),
                    const SizedBox(height: 2),
                    Text(_items[i].$2,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: i == index ? lantern : Colors.white60)),
                  ]),
                ),
              ),
            ),
        ]),
      );
}
