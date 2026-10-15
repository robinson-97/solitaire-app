import 'package:flutter/material.dart';
import '../game/unlocks.dart';
import '../game/worlds.dart';
import '../storage.dart';
import 'background.dart';
import 'theme.dart';
import 'widgets.dart';
import 'world_screen.dart';

class WorldsPage extends StatefulWidget {
  const WorldsPage({super.key, required this.storage, required this.sceneNotifier});
  final Storage storage;
  final ValueNotifier<WorldScene> sceneNotifier;

  @override
  State<WorldsPage> createState() => _WorldsPageState();
}

class _WorldsPageState extends State<WorldsPage> {
  final PageController _pc = PageController(viewportFraction: 0.86);
  int page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _enter(World w) async {
    await Navigator.of(context).push(softRoute(WorldScreen(world: w, storage: widget.storage)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final u = Unlocks(widget.storage);
    final next = u.nextUnlock();
    return Padding(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Row(children: [
            Text('Hopstone', style: displayFont.copyWith(fontSize: 28, fontWeight: FontWeight.w700, shadows: [
              Shadow(color: lantern.withValues(alpha: 0.7), blurRadius: 18),
            ])),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome, size: 16, color: lantern),
                const SizedBox(width: 6),
                Text('${widget.storage.totalPoints}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (next != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: lantern.withValues(alpha: 0.16)),
                  child: const Icon(Icons.lock_open_rounded, color: lantern, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('NEXT UNLOCK', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                    Text(next.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(next.how, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                    const SizedBox(height: 6),
                    ProgressBar(next.progress, height: 6),
                  ]),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: worlds.length,
            onPageChanged: (i) {
              setState(() => page = i);
              widget.sceneNotifier.value = worlds[i].scene;
            },
            itemBuilder: (_, i) => AnimatedBuilder(
              animation: _pc,
              builder: (_, child) {
                final p = _pc.hasClients && _pc.position.haveDimensions ? _pc.page! : page.toDouble();
                final f = (1 - (p - i).abs()).clamp(0.0, 1.0);
                return Transform.scale(scale: 0.92 + 0.08 * f, child: Opacity(opacity: 0.55 + 0.45 * f, child: child));
              },
              child: _WorldCard(
                world: worlds[i],
                index: i,
                unlocks: u,
                onEnter: () => _enter(worlds[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < worlds.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == page ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == page ? lantern : Colors.white.withValues(alpha: 0.3),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.world, required this.index, required this.unlocks, required this.onEnter});
  final World world;
  final int index;
  final Unlocks unlocks;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final open = unlocks.worldUnlocked(world);
    final solved = unlocks.solvedIn(world);
    final total = world.levels.length;
    final prev = world.unlockedBy == null ? null : worldById(world.unlockedBy!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: open ? 0.28 : 0.12), width: 1.4),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 26, offset: const Offset(0, 12))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: Stack(fit: StackFit.expand, children: [
            SceneArt(world.scene),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: open ? 0.55 : 0.78)],
                  stops: const [0.35, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Chip2('WORLD ${index + 1}', color: Colors.white),
                  const Spacer(),
                  if (!open) const Icon(Icons.lock_rounded, color: Colors.white70),
                  if (open && solved == total) const Icon(Icons.verified_rounded, color: lantern),
                ]),
                const Spacer(),
                Text(world.name, style: displayFont.copyWith(fontSize: 30, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(world.tagline, style: TextStyle(fontSize: 13, height: 1.35, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 16),
                if (open) ...[
                  Text('$solved / $total levels cleared', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ProgressBar(solved / total),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: PillButton(label: 'Enter world', icon: Icons.arrow_forward_rounded, primary: true, onTap: onEnter)),
                ] else ...[
                  Text('Clear every ${prev!.name} level to unlock', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ProgressBar(unlocks.solvedIn(prev) / prev.levels.length),
                  const SizedBox(height: 4),
                  Text('${unlocks.solvedIn(prev)} / ${prev.levels.length}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 12),
                  const SizedBox(width: double.infinity, child: PillButton(label: 'Locked', icon: Icons.lock_rounded)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
