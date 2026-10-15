import 'package:flutter/material.dart';
import '../game/board_def.dart';
import '../game/unlocks.dart';
import '../game/worlds.dart';
import '../storage.dart';
import 'background.dart';
import 'game_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key, required this.world, required this.storage});
  final World world;
  final Storage storage;

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  Future<void> _play(BoardDef b) async {
    await Navigator.of(context).push(softRoute(GameScreen(board: b, storage: widget.storage, nextBoard: nextLevel(b))));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.world;
    final u = Unlocks(widget.storage);
    final solved = u.solvedIn(w);
    final packs = <String, List<BoardDef>>{};
    for (final p in w.levelPacks) {
      packs[p] = w.levels.where((l) => l.id.startsWith('$p-')).toList();
    }
    return Scaffold(
      body: SceneBackground(
        scene: w.scene,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Row(children: [
                _BackButton(onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text(w.name, style: displayFont.copyWith(fontSize: 26, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.tagline, style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text('$solved / ${w.levels.length} cleared', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Flexible(child: Text('Leave one peg to clear', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)))),
                  ]),
                  const SizedBox(height: 8),
                  ProgressBar(solved / w.levels.length),
                ]),
              ),
              for (final e in packs.entries) ...[
                const SizedBox(height: 22),
                _packHeader(e.value.first),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < e.value.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _tile(e.value[i], i + 1)),
                  ],
                ]),
              ],
              if (w.challenges.isNotEmpty) ...[
                const SizedBox(height: 26),
                Text('Challenges', style: displayFont.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text('Optional boards with exclusive rewards.', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
                const SizedBox(height: 10),
                for (final b in w.challenges) ...[
                  _challenge(b),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _packHeader(BoardDef first) => Row(children: [
        Text(first.name.replaceAll(RegExp(r'\s*\d+$'), ''), style: displayFont.copyWith(fontSize: 20)),
        const SizedBox(width: 10),
        Chip2(first.difficulty.label.toUpperCase()),
      ]);

  Widget _tile(BoardDef b, int n) {
    final best = widget.storage.bestScore(b.id);
    final solved = widget.storage.solved(b.id);
    final hasReward = rewardsFor(b.id).isNotEmpty;
    return GlassCard(
      onTap: () => _play(b),
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      radius: 18,
      glow: solved ? lantern : null,
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          BoardPreview(b, size: 46),
          if (hasReward)
            const Positioned(right: -6, top: -6, child: Icon(Icons.auto_awesome, size: 14, color: lantern)),
        ]),
        const SizedBox(height: 4),
        Text('$n', style: displayFont.copyWith(fontSize: 17)),
        const SizedBox(height: 2),
        solved ? const Icon(Icons.check_circle_rounded, size: 14, color: lantern) : MedalStars(best, size: 11),
      ]),
    );
  }

  Widget _challenge(BoardDef b) {
    final best = widget.storage.bestScore(b.id);
    final u = Unlocks(widget.storage);
    return GlassCard(
      onTap: () => _play(b),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          BoardPreview(b, size: 62),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.name, style: displayFont.copyWith(fontSize: 20)),
              const SizedBox(height: 2),
              Text(b.description, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 6),
              Chip2(b.difficulty.label.toUpperCase()),
            ]),
          ),
          Column(children: [
            MedalStars(best),
            const SizedBox(height: 2),
            Text(best > 0 ? '$best' : '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ]),
        for (final r in rewardsFor(b.id)) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(
              (r.kind == 'peg' ? u.pegUnlocked(r.id) : u.boardUnlocked(r.id)) ? Icons.check_circle_rounded : Icons.lock_rounded,
              size: 16,
              color: lantern,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(r.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            Text('${r.minScore}+', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
          ]),
        ],
      ]),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.arrow_back_rounded, size: 22)),
        ),
      );
}
