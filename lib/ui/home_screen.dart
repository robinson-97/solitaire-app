import 'package:flutter/material.dart';
import '../game/board_def.dart';
import '../game/journey.dart';
import '../game/levels_data.dart';
import '../storage.dart';
import 'background.dart';
import 'game_screen.dart';
import 'peg_view.dart';
import 'styles.dart';
import 'theme.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage});
  final Storage storage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _play(BoardDef b) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(board: b, storage: widget.storage, nextBoard: nextInJourney(b)),
    ));
    if (mounted) setState(() {});
  }

  BoardDef get _continueBoard => journey.firstWhere(
        (b) => widget.storage.bestScore(b.id) == 0,
        orElse: () => classicBoard,
      );

  @override
  Widget build(BuildContext context) {
    final cont = _continueBoard;
    final played = journey.where((b) => widget.storage.bestScore(b.id) > 0).length;
    return Scaffold(
      body: TwilightBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
            children: [
              const SizedBox(height: 8),
              _logo(),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _statPill(Icons.auto_awesome, '${widget.storage.totalPoints}', 'points')),
                const SizedBox(width: 12),
                Expanded(child: _statPill(Icons.flag_rounded, '$played / ${journey.length}', 'cleared')),
              ]),
              const SizedBox(height: 18),
              _playButton(cont),
              const SizedBox(height: 18),
              _stylePicker(),
              const SizedBox(height: 28),
              _heading('Boards'),
              for (final b in [triangleBoard, classicBoard, frenchBoard]) ...[
                _boardCard(b),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              _heading('Handmade levels'),
              for (final d in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) ...[
                _packRow(d),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() => Column(children: [
        SizedBox(
          height: 54,
          child: CustomPaint(size: const Size(160, 54), painter: _HopMark()),
        ),
        Text('Hopstone',
            style: displayFont.copyWith(fontSize: 58, fontWeight: FontWeight.w700, shadows: [
              Shadow(color: lantern.withValues(alpha: 0.9), blurRadius: 26),
              const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 3)),
            ])),
        const Text('Hop. Jump. Leave one.', style: TextStyle(fontSize: 18, letterSpacing: 1.5, color: Color(0xFFCFC3A0))),
      ]);

  Widget _statPill(IconData icon, String value, String label) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(icon, color: lantern),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: displayFont.copyWith(fontSize: 22)),
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
              ]),
            ),
          ),
        ]),
      );

  Widget _playButton(BoardDef b) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [Color(0xFFFFC46B), Color(0xFFE08A1E)]),
          boxShadow: [BoxShadow(color: lantern.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _play(b),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(children: [
                BoardPreview(b, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Play', style: displayFont.copyWith(fontSize: 34, color: const Color(0xFF2B1604))),
                    Text(b.name, style: const TextStyle(fontSize: 17, color: Color(0xFF4A2A0A), fontWeight: FontWeight.w700)),
                  ]),
                ),
                const Icon(Icons.play_arrow_rounded, size: 46, color: Color(0xFF2B1604)),
              ]),
            ),
          ),
        ),
      );

  Widget _stylePicker() => GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pegs', style: displayFont.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in pegThemes)
              ChoiceChip(
                avatar: SizedBox(width: 22, height: 22, child: PegView(theme: t, glow: 0.25)),
                label: Text(t.name),
                selected: widget.storage.pegTheme == t.id,
                onSelected: (_) async {
                  await widget.storage.setPegTheme(t.id);
                  if (mounted) setState(() {});
                },
              ),
          ]),
          const SizedBox(height: 12),
          Text('Board', style: displayFont.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in boardThemes)
              ChoiceChip(
                avatar: CircleAvatar(backgroundColor: t.body[1]),
                label: Text(t.name),
                selected: widget.storage.boardTheme == t.id,
                onSelected: (_) async {
                  await widget.storage.setBoardTheme(t.id);
                  if (mounted) setState(() {});
                },
              ),
          ]),
        ]),
      );

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Row(children: [
          Flexible(child: Text(t, style: displayFont.copyWith(fontSize: 28))),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: Colors.white24)),
        ]),
      );

  Widget _boardCard(BoardDef b) {
    final best = widget.storage.bestScore(b.id);
    return GlassCard(
      onTap: () => _play(b),
      child: Row(children: [
        BoardPreview(b, size: 62),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.name, style: displayFont.copyWith(fontSize: 24)),
            Text(b.description, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(b.difficulty.label.toUpperCase(),
                style: const TextStyle(fontSize: 12, letterSpacing: 1.4, color: lantern, fontWeight: FontWeight.w700)),
          ]),
        ),
        Column(children: [
          MedalStars(best),
          const SizedBox(height: 2),
          Text(best > 0 ? '$best' : '—', style: const TextStyle(fontSize: 15)),
        ]),
      ]),
    );
  }

  Widget _packRow(Difficulty d) {
    final levels = handmadeLevels.where((l) => l.difficulty == d).toList();
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(levels.first.name.split(' ').first,
              style: displayFont.copyWith(fontSize: 22)),
        ),
        Row(children: [
          for (final l in levels)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _play(l),
                child: Column(children: [
                  BoardPreview(l, size: 50),
                  const SizedBox(height: 2),
                  Text(l.name.split(' ').last, style: displayFont.copyWith(fontSize: 18)),
                  MedalStars(widget.storage.bestScore(l.id), size: 12),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }
}

/// Logo mark: a peg hopping over another into an empty hole.
class _HopMark extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height * 0.78;
    final r = 11.0;
    final xs = [s.width * 0.14, s.width * 0.5, s.width * 0.86];
    for (final x in [xs[2]]) {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = holeColor);
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = lantern.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    for (final x in [xs[1]]) {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = holeColor);
      canvas.drawCircle(Offset(x, y), r - 2, Paint()..color = woodLight);
    }
    final arc = Path()
      ..moveTo(xs[0], y - r)
      ..quadraticBezierTo(xs[1], -s.height * 0.35, xs[2], y - r);
    canvas.drawPath(arc, Paint()..color = lantern..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(xs[0], y), r,
        Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFE0A0), Color(0xFFE08A1E), Color(0xFF7A3E08)]).createShader(Rect.fromCircle(center: Offset(xs[0], y), radius: r)));
  }

  @override
  bool shouldRepaint(_HopMark old) => false;
}
