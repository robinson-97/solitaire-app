import 'package:flutter/material.dart';
import '../game/board_def.dart';
import '../game/unlocks.dart';
import '../game/worlds.dart';
import '../storage.dart';
import 'game_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// The home tab: one world at a time, 20 levels in a simple grid.
class PlayPage extends StatefulWidget {
  const PlayPage({super.key, required this.storage, required this.worldNotifier});
  final Storage storage;
  final ValueNotifier<World> worldNotifier;

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late int idx = _startWorld();

  /// The first world that still has levels to clear (or the last one).
  int _startWorld() {
    final u = Unlocks(widget.storage);
    for (var i = 0; i < worlds.length; i++) {
      if (u.worldUnlocked(worlds[i]) && !u.worldCompleted(worlds[i])) return i;
    }
    return worlds.length - 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.worldNotifier.value = worlds[idx];
    });
  }

  void _go(int d) {
    final n = idx + d;
    if (n < 0 || n >= worlds.length) return;
    setState(() => idx = n);
    widget.worldNotifier.value = worlds[n];
  }

  Future<void> _play(BoardDef b) async {
    await Navigator.of(context).push(softRoute(GameScreen(board: b, storage: widget.storage, nextBoard: nextLevel(b))));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = worlds[idx];
    final u = Unlocks(widget.storage);
    final open = u.worldUnlocked(w);
    final cleared = u.solvedIn(w);
    final nextToPlay = w.levels.where((l) => !widget.storage.solved(l.id)).firstOrNull ?? w.levels.last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 92),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Row(children: [
            Text('Hopstone', style: displayFont.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.auto_awesome, size: 15, color: lantern),
            const SizedBox(width: 6),
            Text('${widget.storage.totalPoints}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
            decoration: BoxDecoration(
              color: cocoa.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: cocoaEdge, width: 1.6),
              boxShadow: const [BoxShadow(color: cocoaDeep, offset: Offset(0, 4))],
            ),
            child: Column(children: [
              Row(children: [
                IconButton(onPressed: idx == 0 ? null : () => _go(-1), icon: const Icon(Icons.chevron_left_rounded, size: 32)),
                Expanded(
                  child: Column(children: [
                    Text('WORLD ${idx + 1}', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: lantern.withValues(alpha: 0.95))),
                    Text(w.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: displayFont.copyWith(fontSize: 26)),
                  ]),
                ),
                IconButton(onPressed: idx == worlds.length - 1 ? null : () => _go(1), icon: const Icon(Icons.chevron_right_rounded, size: 32)),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
                child: Row(children: [
                  Expanded(child: ProgressBar(open ? cleared / w.levels.length : 0, height: 7)),
                  const SizedBox(width: 12),
                  Text(open ? '$cleared / ${w.levels.length}' : 'Locked', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: open
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  children: [
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
                      children: [for (var i = 0; i < w.levels.length; i++) _tile(w.levels[i], i + 1, w.levels[i].id == nextToPlay.id)],
                    ),
                    if (w.challenges.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text('Bonus boards', style: displayFont.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      for (final b in w.challenges) ...[_bonus(b, u), const SizedBox(height: 10)],
                    ],
                  ],
                )
              : _lockedPanel(w, u),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
            child: SizedBox(
              width: double.infinity,
              child: PillButton(
                label: cleared == w.levels.length ? 'Play again' : 'Play level ${w.levels.indexOf(nextToPlay) + 1}',
                icon: Icons.play_arrow_rounded,
                primary: true,
                onTap: () => _play(nextToPlay),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _lockedPanel(World w, Unlocks u) {
    final prev = worldById(w.unlockedBy!);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_rounded, size: 40, color: lantern),
            const SizedBox(height: 12),
            Text(w.tagline, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 16),
            Text('Clear all ${prev.levels.length} levels of ${prev.name} to unlock.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ProgressBar(u.solvedIn(prev) / prev.levels.length),
            const SizedBox(height: 6),
            Text('${u.solvedIn(prev)} / ${prev.levels.length}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          ]),
        ),
      ),
    );
  }

  Widget _tile(BoardDef b, int n, bool current) {
    final stars = widget.storage.stars(b.id);
    return GlassCard(
      onTap: () => _play(b),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
      glow: current ? lantern : null,
      dim: false,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        BoardPreview(b, size: 34),
        const SizedBox(height: 3),
        Text('$n', style: displayFont.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 1),
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++) Icon(Icons.star_rounded, size: 11, color: i < stars ? const Color(0xFFFFD25A) : Colors.white24),
        ]),
      ]),
    );
  }

  Widget _bonus(BoardDef b, Unlocks u) {
    final best = widget.storage.bestScore(b.id);
    final rewards = rewardsFor(b.id);
    return GlassCard(
      onTap: () => _play(b),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        BoardPreview(b, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(rewards.isEmpty ? b.goalText : '${b.goalText} · unlocks ${rewards.map((r) => r.label.split(' ').first).join(', ')}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
          ]),
        ),
        Text(best > 0 ? '$best' : '—', style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
