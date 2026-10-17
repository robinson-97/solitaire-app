import 'dart:math';
import 'package:flutter/material.dart';
import '../game/peg_draw.dart';
import '../game/board_def.dart';
import '../game/unlocks.dart';
import '../game/worlds.dart';
import '../storage.dart';
import 'background.dart';
import 'draw_reveal.dart';
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
        Text('Spend points on mystery pegs. Boards unlock with high scores.', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        _tabs(),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 12) / 2;
          if (tab == 0) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!widget.storage.seenCollectionTip) ...[_tip(), const SizedBox(height: 12)],
              _drawPanel(),
              const SizedBox(height: 18),
              for (final r in Rarity.values) ...[
                _rarityHeader(r),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final t in pegThemes.where((t) => rarityOf(t.id) == r)) SizedBox(width: w, child: _pegCard(t, u)),
                ]),
                const SizedBox(height: 14),
              ],
            ]);
          }
          final cards = switch (tab) {
            0 => const <Widget>[],
            1 => [for (final t in boardThemes) _boardCard(t, u)],
            _ => [for (var i = 0; i < worlds.length; i++) _worldCard(worlds[i], u, i)],
          };
          return Wrap(spacing: 12, runSpacing: 12, children: [for (final c in cards) SizedBox(width: w, child: c)]);
        }),
      ],
    );
  }

  Widget _tabs() {
    const labels = ['Pegs', 'Boards', 'Stages'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cocoa.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cocoaEdge, width: 1.6),
        boxShadow: const [BoxShadow(color: cocoaDeep, offset: Offset(0, 3))],
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

  Widget _tip() => GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, color: lantern),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Tip: earn points by clearing levels with more stars, then spend them on a mystery peg. Every draw gives a peg you do not have yet.',
                style: TextStyle(fontSize: 12.5, height: 1.35)),
          ),
          TextButton(
            onPressed: () async {
              await widget.storage.setSeenCollectionTip();
              setState(() {});
            },
            child: const Text('Got it'),
          ),
        ]),
      );

  Widget _rarityHeader(Rarity r) {
    final all = pegThemes.where((t) => rarityOf(t.id) == r).toList();
    final got = all.where((t) => widget.storage.ownedPegs.contains(t.id) || t.id == 'acorn').length;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: rarityColor(r), shape: BoxShape.circle, boxShadow: [BoxShadow(color: rarityColor(r).withValues(alpha: 0.7), blurRadius: 8)])),
        const SizedBox(width: 8),
        Text(r.label, style: displayFont.copyWith(fontSize: 17)),
        const Spacer(),
        Text('$got / ${all.length}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _drawPanel() {
    final s = widget.storage;
    final free = s.unlockAll;
    final left = pegThemes.where((t) => !Unlocks(s).pegUnlocked(t.id)).length;
    final canDraw = left > 0 && (free || s.points >= drawCost);
    return GlassCard(
      glow: canDraw ? lantern : null,
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFF6A7BFF), Color(0xFF1B2358)]),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: const Text('?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mystery peg', style: displayFont.copyWith(fontSize: 18)),
              const SizedBox(height: 2),
              Text(left == 0 ? 'You own every peg!' : '${s.points} points  ·  $left left to win',
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.75))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
          for (final r in Rarity.values) Chip2('${r.label} ${drawOdds[r]}%', color: rarityColor(r)),
        ]),
        const SizedBox(height: 14),
        PillButton(
          label: left == 0 ? 'Collection complete' : (free ? 'Draw  ·  free in test mode' : 'Draw  ·  $drawCost points'),
          icon: Icons.auto_awesome_rounded,
          primary: true,
          onTap: canDraw ? _draw : null,
        ),
      ]),
    );
  }

  Future<void> _draw() async {
    final s = widget.storage;
    final id = rollPeg([for (final t in pegThemes) t.id], {...s.ownedPegs, 'acorn'}, Random());
    if (id == null) return;
    if (!s.unlockAll) await s.spendPoints(drawCost);
    await s.addOwnedPeg(id);
    if (!mounted) return;
    final t = pegThemeById(id);
    final r = rarityOf(id);
    // an opaque route: the screens underneath stop painting while it plays
    _glow.stop();
    await Navigator.of(context).push<void>(PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      pageBuilder: (ctx, _, _) => DrawReveal(
        theme: t,
        rarity: r,
        left: pegThemes.where((p) => !Unlocks(s).pegUnlocked(p.id)).length,
        color: rarityColor(r),
        onEquip: () async {
          await s.setPegTheme(id);
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onClose: () => Navigator.pop(ctx),
      ),
    ));
    if (mounted && !reduceMotion(context)) _glow.repeat();
    if (mounted) setState(() {});
  }

  Widget _pegCard(PegTheme t, Unlocks u) {
    final open = u.pegUnlocked(t.id);
    final equipped = widget.storage.pegTheme == t.id;
    final r = rarityOf(t.id);
    return GlassCard(
      glow: equipped ? lantern : null,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      child: Column(children: [
        SizedBox(
          height: 84,
          child: Center(
            child: open
                ? AnimatedBuilder(animation: _glow, builder: (_, _) => SizedBox(width: 68, height: 68, child: PegView(theme: t, glow: _glow.value)))
                : Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rarityColor(r).withValues(alpha: 0.14),
                      border: Border.all(color: rarityColor(r).withValues(alpha: 0.55), width: 1.6),
                    ),
                    child: Text('?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: rarityColor(r))),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(open ? t.name : 'Mystery peg', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (open)
          _equipButton(equipped, () async {
            await widget.storage.setPegTheme(t.id);
            setState(() {});
          })
        else
          Chip2(r.label, color: rarityColor(r)),
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

  Widget _worldCard(World w, Unlocks u, int index) {
    final open = u.worldUnlocked(w);
    final prev = w.unlockedBy == null ? null : worldById(w.unlockedBy!);
    return AspectRatio(
      aspectRatio: 0.72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
          child: Stack(fit: StackFit.expand, children: [
            ColorFiltered(
              colorFilter: open ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : _grey,
              child: SceneArt('neon:${w.id}', delay: Duration(milliseconds: 90 * (index % 6))),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent, Colors.black.withValues(alpha: 0.78)], stops: const [0.0, 0.4, 1.0]),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Icon(open ? Icons.check_circle_rounded : Icons.lock_rounded, size: 22, color: open ? lantern : Colors.white70),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(w.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: displayFont.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(open ? '${u.solvedIn(w)} / ${w.levels.length} cleared' : 'Earn ${Unlocks.starsToOpen} stars in ${prev!.name}',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.82))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

Color rarityColor(Rarity r) => switch (r) {
      Rarity.common => const Color(0xFF9AA7C0),
      Rarity.rare => const Color(0xFF4FA8FF),
      Rarity.epic => const Color(0xFFB06CFF),
      Rarity.legendary => const Color(0xFFFFC83A),
    };
