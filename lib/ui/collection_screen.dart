import 'package:flutter/material.dart';
import '../game/board_def.dart';
import '../game/unlocks.dart';
import '../game/worlds.dart';
import '../storage.dart';
import 'background.dart';
import 'peg_view.dart';
import 'styles.dart';
import 'theme.dart';
import 'widgets.dart';

const _grey = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, required this.storage});
  final Storage storage;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> with SingleTickerProviderStateMixin {
  int tab = 0;
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _glow.stop();
    } else if (!_glow.isAnimating) {
      _glow.repeat();
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = Unlocks(widget.storage);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
      children: [
        Text('Collection', style: displayFont.copyWith(fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Earn exclusive pegs and boards with high scores.', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        _tabs(),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 12) / 2;
          if (tab == 0) {
            final cats = <String>[];
            for (final t in pegThemes) {
              if (!cats.contains(t.category)) cats.add(t.category);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final cat in cats) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                  child: Text(cat, style: displayFont.copyWith(fontSize: 17)),
                ),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final t in pegThemes.where((t) => t.category == cat)) SizedBox(width: w, child: _pegCard(t, u)),
                ]),
                const SizedBox(height: 14),
              ],
            ]);
          }
          final cards = switch (tab) {
            0 => const <Widget>[],
            1 => [for (final t in boardThemes) _boardCard(t, u)],
            _ => [for (final wd in worlds) _worldCard(wd, u)],
          };
          if (tab == 2) {
            return Column(children: [for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 12), child: c)]);
          }
          return Wrap(spacing: 12, runSpacing: 12, children: [for (final c in cards) SizedBox(width: w, child: c)]);
        }),
      ],
    );
  }

  Widget _tabs() {
    const labels = ['Pegs', 'Boards', 'Worlds'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: i == tab ? lantern.withValues(alpha: 0.2) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(labels[i],
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: i == tab ? lantern : Colors.white60)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _rulePanel(UnlockRule r, Unlocks u) {
    final best = widget.storage.bestScore(r.boardId);
    return Column(children: [
      Text(r.text, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.3, color: Colors.white.withValues(alpha: 0.8))),
      const SizedBox(height: 8),
      ProgressBar(u.progress(r), height: 6),
      const SizedBox(height: 4),
      Text('Best $best / ${r.minScore}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
    ]);
  }

  Widget _equipButton(bool equipped, VoidCallback onTap) => equipped
      ? const PillButton(label: 'Equipped', icon: Icons.check_rounded, compact: true)
      : PillButton(label: 'Equip', primary: true, compact: true, onTap: onTap);

  Widget _pegCard(PegTheme t, Unlocks u) {
    final open = u.pegUnlocked(t.id);
    final equipped = widget.storage.pegTheme == t.id;
    final rule = pegRules[t.id];
    return GlassCard(
      glow: equipped ? lantern : null,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      child: Column(children: [
        SizedBox(
          height: 84,
          child: Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (_, _) {
                final peg = SizedBox(width: 68, height: 68, child: PegView(theme: t, glow: _glow.value));
                return open ? peg : ColorFiltered(colorFilter: _grey, child: Opacity(opacity: 0.55, child: peg));
              },
            ),
            if (!open) const Icon(Icons.lock_rounded, size: 26, color: Colors.white70),
          ]),
        ),
        const SizedBox(height: 10),
        Text(t.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (open)
          _equipButton(equipped, () async {
            await widget.storage.setPegTheme(t.id);
            setState(() {});
          })
        else
          _rulePanel(rule!, u),
      ]),
    );
  }

  Widget _boardCard(BoardTheme t, Unlocks u) {
    final open = u.boardUnlocked(t.id);
    final equipped = widget.storage.boardTheme == t.id;
    final rule = boardRules[t.id];
    return GlassCard(
      glow: equipped ? lantern : null,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      child: Column(children: [
        SizedBox(
          height: 84,
          child: Stack(alignment: Alignment.center, children: [
            ColorFiltered(
              colorFilter: open ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : _grey,
              child: Opacity(opacity: open ? 1 : 0.55, child: BoardPreview(classicBoard, size: 84, theme: t, showPegs: false)),
            ),
            if (!open) const Icon(Icons.lock_rounded, size: 26, color: Colors.white70),
          ]),
        ),
        const SizedBox(height: 10),
        Text(t.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (open)
          _equipButton(equipped, () async {
            await widget.storage.setBoardTheme(t.id);
            setState(() {});
          })
        else
          _rulePanel(rule!, u),
      ]),
    );
  }

  Widget _worldCard(World w, Unlocks u) {
    final open = u.worldUnlocked(w);
    final prev = w.unlockedBy == null ? null : worldById(w.unlockedBy!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 150,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
        child: Stack(fit: StackFit.expand, children: [
          ColorFiltered(
            colorFilter: open ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : _grey,
            child: SceneArt(w.scene, art: w.art),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Row(children: [
                Expanded(child: Text(w.name, style: displayFont.copyWith(fontSize: 20, fontWeight: FontWeight.w700))),
                Icon(open ? Icons.check_circle_rounded : Icons.lock_rounded, color: open ? lantern : Colors.white70),
              ]),
              const SizedBox(height: 2),
              Text(open ? '${u.solvedIn(w)} / ${w.levels.length} levels cleared' : 'Clear every ${prev!.name} level',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
            ]),
          ),
        ]),
      ),
    );
  }
}
