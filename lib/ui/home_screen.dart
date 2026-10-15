import 'package:flutter/material.dart';
import '../game/board_def.dart';
import '../game/levels_data.dart';
import '../game/peg_game.dart';
import '../storage.dart';
import 'background.dart';
import 'game_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage});
  final Storage storage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BoardDef> get _boards =>
      [triangleBoard, classicBoard, frenchBoard, ...handmadeLevels];

  Future<void> _play(BoardDef b) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(board: b, storage: widget.storage, nextBoard: _next(b)),
    ));
    if (mounted) setState(() {});
  }

  BoardDef? _next(BoardDef b) {
    final i = _boards.indexWhere((x) => x.id == b.id);
    return i >= 0 && i + 1 < _boards.length ? _boards[i + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final levelsByDiff = {
      for (final d in [Difficulty.easy, Difficulty.medium, Difficulty.hard])
        d: handmadeLevels.where((l) => l.difficulty == d).toList(),
    };
    return Scaffold(
      body: TwilightBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              Center(
                child: Text('Glimmerwood',
                    style: displayFont.copyWith(fontSize: 44, shadows: const [
                      Shadow(color: lantern, blurRadius: 18),
                    ])),
              ),
              const SizedBox(height: 4),
              const Center(child: Text('A peg solitaire puzzle', style: TextStyle(fontSize: 18))),
              const SizedBox(height: 4),
              Center(
                child: Text('Total points: ${widget.storage.totalPoints}',
                    style: const TextStyle(color: lantern, fontSize: 16)),
              ),
              const SizedBox(height: 24),
              _heading('Boards'),
              for (final b in [triangleBoard, classicBoard, frenchBoard]) _boardCard(b),
              const SizedBox(height: 12),
              _heading('Handmade levels'),
              for (final e in levelsByDiff.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(e.key.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final l in e.value) _levelChip(l),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: displayFont.copyWith(fontSize: 26)),
      );

  Color _medalColor(int best) => switch (ScoreBreakdown.medalFor(best)) {
        Medal.gold => const Color(0xFFFFD25A),
        Medal.silver => const Color(0xFFC9D1D9),
        Medal.bronze => const Color(0xFFCD8B4A),
        Medal.none => Colors.white24,
      };

  Widget _boardCard(BoardDef b) {
    final best = widget.storage.bestScore(b.id);
    return Card(
      color: const Color(0x66000000),
      child: ListTile(
        onTap: () => _play(b),
        title: Text(b.name, style: displayFont.copyWith(fontSize: 22)),
        subtitle: Text('${b.difficulty.label} · ${b.description}'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.workspace_premium, color: _medalColor(best)),
          Text(best > 0 ? '$best' : '-'),
        ]),
      ),
    );
  }

  Widget _levelChip(BoardDef l) {
    final best = widget.storage.bestScore(l.id);
    return InkWell(
      onTap: () => _play(l),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 98,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _medalColor(best), width: 1.5),
        ),
        child: Column(children: [
          Text(l.name.split(' ').last, style: displayFont.copyWith(fontSize: 24)),
          Text('${l.startPegs} pegs', style: const TextStyle(fontSize: 13)),
          Text(best > 0 ? 'Best $best' : 'New', style: TextStyle(fontSize: 13, color: best > 0 ? lantern : Colors.white54)),
        ]),
      ),
    );
  }
}
