import 'package:flutter/material.dart';
import '../game/board_def.dart';
import '../game/unlocks.dart';
import '../game/worlds.dart';
import '../storage.dart';
import 'game_screen.dart';
import 'scenes/scene_neon.dart' show neonPalette;
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

  Color _accent(World w) => neonPalette[w.id]?.$1 ?? lantern;

  Future<void> _allLevels(World w, Unlocks u, BoardDef current) async {
    final picked = await showModalBottomSheet<BoardDef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E2C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: cocoaEdge, width: 1.6),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 14),
              Text('${w.name} - all levels', style: displayFont.copyWith(fontSize: 20)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
                children: [
                  for (var i = 0; i < w.levels.length; i++)
                    _tile(w.levels[i], i + 1, w.levels[i].id == current.id, onTap: () => Navigator.pop(ctx, w.levels[i])),
                ],
              ),
              if (w.challenges.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text('Bonus boards', style: displayFont.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                for (final b in w.challenges) ...[_bonus(b, u, onTap: () => Navigator.pop(ctx, b)), const SizedBox(height: 10)],
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) _play(picked);
  }

  @override
  Widget build(BuildContext context) {
    final w = worlds[idx];
    final u = Unlocks(widget.storage);
    final open = u.worldUnlocked(w);
    final cleared = u.solvedIn(w);
    final nextToPlay = w.levels.where((l) => !widget.storage.solved(l.id)).firstOrNull ?? w.levels.last;
    final nextIdx = w.levels.indexOf(nextToPlay);
    final accent = _accent(w);
    final upcoming = [for (var i = nextIdx + 1; i < w.levels.length && i <= nextIdx + 4; i++) i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 92),
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), children: [
        Row(children: [
          Text('HOPSTONE', style: displayFont.copyWith(fontSize: 20, letterSpacing: 4)),
          const Spacer(),
          Icon(Icons.auto_awesome, size: 15, color: accent),
          const SizedBox(width: 6),
          Text('${widget.storage.totalPoints}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 18),
        GlassCard(
          glow: accent.withValues(alpha: 0.55),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 14),
          child: Column(children: [
            Row(children: [
              IconButton(onPressed: idx == 0 ? null : () => _go(-1), icon: const Icon(Icons.chevron_left_rounded, size: 32)),
              Expanded(
                child: Column(children: [
                  Text('STAGE ${idx + 1} OF ${worlds.length}', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: accent)),
                  const SizedBox(height: 2),
                  Text(w.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: displayFont.copyWith(fontSize: 25)),
                ]),
              ),
              IconButton(onPressed: idx == worlds.length - 1 ? null : () => _go(1), icon: const Icon(Icons.chevron_right_rounded, size: 32)),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(children: [
                Expanded(child: ProgressBar(open ? cleared / w.levels.length : 0, color: accent, height: 6)),
                const SizedBox(width: 12),
                Text(open ? '$cleared / ${w.levels.length}' : 'Locked', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        if (!open) _lockedPanel(w, u) else ...[
          GlassCard(
            padding: const EdgeInsets.all(18),
            onTap: () => _play(nextToPlay),
            child: Row(children: [
              BoardPreview(nextToPlay, size: 92),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cleared == w.levels.length ? 'ALL CLEARED' : 'UP NEXT', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: accent)),
                  const SizedBox(height: 2),
                  Text('Level ${nextIdx + 1}', style: displayFont.copyWith(fontSize: 28)),
                  const SizedBox(height: 2),
                  Text(nextToPlay.goalText, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
                  const SizedBox(height: 6),
                  Row(children: [
                    for (var i = 0; i < 3; i++) Icon(Icons.star_rounded, size: 18, color: i < widget.storage.stars(nextToPlay.id) ? const Color(0xFFFFD25A) : Colors.white24),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PillButton(
              label: cleared == w.levels.length ? 'Play again' : 'Play level ${nextIdx + 1}',
              icon: Icons.play_arrow_rounded,
              primary: true,
              onTap: () => _play(nextToPlay),
            ),
          ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('COMING UP', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.55))),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: Row(children: [
                for (final i in upcoming) ...[
                  Expanded(child: _tile(w.levels[i], i + 1, false, onTap: () => _play(w.levels[i]))),
                  if (i != upcoming.last) const SizedBox(width: 8),
                ],
                for (var k = upcoming.length; k < 4; k++) ...[const SizedBox(width: 8), const Expanded(child: SizedBox())],
              ]),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PillButton(label: 'All levels', icon: Icons.grid_view_rounded, onTap: () => _allLevels(w, u, nextToPlay)),
          ),
        ],
      ]),
    );
  }

  Widget _lockedPanel(World w, Unlocks u) {
    final prev = worldById(w.unlockedBy!);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_rounded, size: 40, color: _accent(w)),
        const SizedBox(height: 12),
        Text(w.tagline, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 16),
        Text('Clear all ${prev.levels.length} levels of ${prev.name} to unlock.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ProgressBar(u.solvedIn(prev) / prev.levels.length, color: _accent(w)),
        const SizedBox(height: 6),
        Text('${u.solvedIn(prev)} / ${prev.levels.length}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _tile(BoardDef b, int n, bool current, {required VoidCallback onTap}) {
    final stars = widget.storage.stars(b.id);
    return GlassCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
      glow: current ? lantern : null,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        BoardPreview(b, size: 34),
        const SizedBox(height: 3),
        Text('$n', style: displayFont.copyWith(fontSize: 16)),
        const SizedBox(height: 1),
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++) Icon(Icons.star_rounded, size: 11, color: i < stars ? const Color(0xFFFFD25A) : Colors.white24),
        ]),
      ]),
    );
  }

  Widget _bonus(BoardDef b, Unlocks u, {required VoidCallback onTap}) {
    final best = widget.storage.bestScore(b.id);
    final rewards = rewardsFor(b.id);
    return GlassCard(
      onTap: onTap,
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
