import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/board_def.dart';
import '../game/peg_game.dart';
import '../storage.dart';
import '../game/journey.dart';
import 'background.dart';
import 'theme.dart';
import 'widgets.dart';

/// Maps board holes to screen coordinates for a given cell size.
class BoardGeometry {
  BoardGeometry(this.def, this.cell);
  final BoardDef def;
  final double cell;

  double get pad => cell * 0.5;
  double get width => def.cols * cell + pad * 2;
  double get height => def.rows * cell + pad * 2;

  Offset centerOf(Pos p) {
    final shift = def.triangle ? (def.cols - 1 - p.row) / 2 : 0.0;
    return Offset(
      pad + (p.col + shift) * cell + cell / 2,
      pad + p.row * cell + cell / 2,
    );
  }

  Pos? hit(Offset o) {
    Pos? best;
    var bestD = cell * 0.55;
    for (final h in def.holes) {
      final d = (centerOf(h) - o).distance;
      if (d < bestD) {
        bestD = d;
        best = h;
      }
    }
    return best;
  }
}

class _Rec {
  _Rec(this.move, this.movedId, this.removedId);
  final Move move;
  final int movedId;
  final int removedId;
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.board, required this.storage, this.nextBoard});
  final BoardDef board;
  final Storage storage;
  final BoardDef? nextBoard;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PegGame game;
  late Map<Pos, int> ids;
  int nextId = 0;
  final List<_Rec> hist = [];
  Pos? selected;
  List<Move> targets = [];
  final Map<int, Pos> ghosts = {};
  int? shakeId;
  int shakeTick = 0;
  Timer? ticker;
  Timer? confirmTimer;
  bool confirmRestart = false;
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    _reset();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && game.inProgress && !game.isOver) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    confirmTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    game = PegGame(widget.board);
    nextId = 0;
    ids = {for (final p in widget.board.pegs) p: nextId++};
    hist.clear();
    ghosts.clear();
    selected = null;
    targets = [];
    submitted = false;
    confirmRestart = false;
  }

  void _buzz([bool strong = false]) {
    if (!widget.storage.haptics) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }

  void _onTap(Pos p) {
    if (game.isOver) return;
    setState(() {
      confirmRestart = false;
      if (game.hasPeg(p)) {
        if (selected == p) {
          selected = null;
          targets = [];
        } else {
          final moves = game.movesFrom(p);
          if (moves.isEmpty) {
            _shake(p);
            HapticFeedback.heavyImpact();
          } else {
            selected = p;
            targets = moves;
            _buzz();
          }
        }
      } else if (selected != null) {
        final m = targets.where((m) => m.to == p).firstOrNull;
        if (m != null) {
          _jump(m);
        } else {
          _shake(selected!);
        }
      }
    });
  }

  void _shake(Pos p) {
    shakeId = ids[p];
    shakeTick++;
  }

  void _jump(Move m) {
    final movedId = ids.remove(m.from)!;
    final removedId = ids.remove(m.over)!;
    ids[m.to] = movedId;
    ghosts[removedId] = m.over;
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => ghosts.remove(removedId));
    });
    game.apply(m);
    hist.add(_Rec(m, movedId, removedId));
    selected = null;
    targets = [];
    _buzz(true);
    if (game.isOver) _finish();
  }

  void _undo() {
    if (hist.isEmpty) return;
    setState(() {
      final r = hist.removeLast();
      game.undo();
      ids.remove(r.move.to);
      ids[r.move.from] = r.movedId;
      ids[r.move.over] = r.removedId;
      ghosts.remove(r.removedId);
      selected = null;
      targets = [];
      confirmRestart = false;
      _buzz();
    });
  }

  void _restart() {
    if (game.inProgress && !game.isOver && !confirmRestart) {
      setState(() => confirmRestart = true);
      confirmTimer?.cancel();
      confirmTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => confirmRestart = false);
      });
      return;
    }
    setState(_reset);
  }

  Future<void> _finish() async {
    final score = game.score();
    final first = !submitted;
    submitted = true;
    var isBest = false;
    if (first) {
      isBest = await widget.storage.submitScore(widget.board.id, score.total);
      await widget.storage.addPoints(score.total);
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _showResult(score, isBest);
  }

  void _showResult(ScoreBreakdown s, bool isBest) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ResultDialog(
        score: s,
        isBest: isBest,
        onRetry: () {
          Navigator.pop(ctx);
          setState(_reset);
        },
        onNext: widget.nextBoard == null
            ? null
            : () {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => GameScreen(
                    board: widget.nextBoard!,
                    storage: widget.storage,
                    nextBoard: nextInJourney(widget.nextBoard!),
                  ),
                ));
              },
        onMenu: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _fmt(int sec) => '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return Scaffold(
      body: TwilightBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(widget.board.name,
                      style: displayFont.copyWith(fontSize: 26)),
                ),
                Text(widget.board.difficulty.label,
                    style: const TextStyle(color: lantern, fontSize: 16)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat('Pegs', '${game.pegsLeft}'),
                  _stat('Time', _fmt(game.secondsElapsed())),
                  _stat('Undos', '${game.undosUsed}'),
                ]),
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final cols = widget.board.cols + 1;
                final rows = widget.board.rows + 1;
                final cell = min(min(box.maxWidth / cols, box.maxHeight / rows), 64.0);
                final geo = BoardGeometry(widget.board, cell);
                return Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final p = geo.hit(d.localPosition);
                      if (p != null) _onTap(p);
                    },
                    child: SizedBox(
                      width: geo.width,
                      height: geo.height,
                      child: Stack(children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BoardPainter(geo, targets.map((m) => m.to).toSet()),
                          ),
                        ),
                        for (final e in ids.entries) _peg(e.value, e.key, geo, still),
                        for (final e in ghosts.entries) _ghost(e.key, e.value, geo, still),
                      ]),
                    ),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hist.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmRestart ? Colors.red.shade800 : woodDark,
                      foregroundColor: parchment,
                    ),
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh),
                    label: Text(confirmRestart ? 'Tap again to restart' : 'Restart'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        Text(value, style: displayFont.copyWith(fontSize: 26)),
      ]);

  Widget _peg(int id, Pos p, BoardGeometry geo, bool still) {
    final c = geo.centerOf(p);
    final d = geo.cell * 0.76;
    final sel = selected == p;
    final quick = still ? Duration.zero : const Duration(milliseconds: 130);
    return AnimatedPositioned(
      key: ValueKey('peg$id'),
      duration: still ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      left: c.dx - d / 2,
      top: c.dy - d / 2,
      width: d,
      height: d,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: still ? Duration.zero : const Duration(milliseconds: 220),
        builder: (_, t, child) => Transform.scale(scale: t, child: child),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('shake${id == shakeId ? shakeTick : 0}'),
          tween: Tween(begin: 0, end: 1),
          duration: id == shakeId && !still ? const Duration(milliseconds: 350) : Duration.zero,
          builder: (_, t, child) => Transform.translate(
              offset: Offset(sin(t * pi * 6) * (1 - t) * 6, 0), child: child),
          child: AnimatedSlide(
            offset: sel ? const Offset(0, -0.14) : Offset.zero,
            duration: quick,
            child: AnimatedScale(
              scale: sel ? 1.12 : 1,
              duration: quick,
              child: _PegBody(selected: sel),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghost(int id, Pos p, BoardGeometry geo, bool still) {
    final c = geo.centerOf(p);
    final d = geo.cell * 0.76;
    return Positioned(
      key: ValueKey('ghost$id'),
      left: c.dx - d / 2,
      top: c.dy - d / 2,
      width: d,
      height: d,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: still ? const Duration(milliseconds: 200) : const Duration(milliseconds: 420),
          builder: (_, t, _) => Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            if (!still)
              Transform.scale(
                scale: 1 + t * 1.1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: lantern.withValues(alpha: (1 - t) * 0.8), width: 2),
                  ),
                ),
              ),
            Opacity(
              opacity: 1 - t,
              child: Transform.scale(scale: 1 - t * 0.3, child: const _PegBody(selected: false)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PegBody extends StatelessWidget {
  const _PegBody({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.45),
            radius: 1.0,
            colors: [Color(0xFFFFE3A8), Color(0xFFE9A04A), Color(0xFFA85F1E), Color(0xFF4A230A)],
            stops: [0.0, 0.3, 0.75, 1.0],
          ),
          border: Border.all(color: const Color(0xFF3A1B07), width: 1),
          boxShadow: [
            BoxShadow(
              color: selected ? lantern.withValues(alpha: 0.95) : Colors.black87,
              blurRadius: selected ? 20 : 5,
              spreadRadius: selected ? 2 : 0,
              offset: selected ? Offset.zero : const Offset(1, 3),
            ),
          ],
        ),
        // glossy highlight
        child: LayoutBuilder(
          builder: (_, c) => Stack(children: [
            Positioned(
              left: c.maxWidth * 0.2,
              top: c.maxHeight * 0.12,
              width: c.maxWidth * 0.42,
              height: c.maxHeight * 0.26,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(c.maxWidth),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.geo, this.targets);
  final BoardGeometry geo;
  final Set<Pos> targets;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = geo.cell;
    // One merged outline (no seams between neighbouring cells).
    var wood = Path();
    for (final h in geo.def.holes) {
      wood = Path.combine(
        PathOperation.union,
        wood,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: geo.centerOf(h), width: cell * 1.2, height: cell * 1.2),
            Radius.circular(cell * 0.3),
          )),
      );
    }
    final bounds = wood.getBounds();

    // lantern glow + drop shadow under the board
    canvas.drawPath(wood,
        Paint()..color = lantern.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
    canvas.drawPath(wood.shift(const Offset(0, 7)),
        Paint()..color = Colors.black87..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));

    // wood body
    canvas.drawPath(
      wood,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC48A52), Color(0xFF9A6234), Color(0xFF6B4423)],
        ).createShader(bounds),
    );

    // wood grain, clipped to the board
    canvas.save();
    canvas.clipPath(wood);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF3B200C).withValues(alpha: 0.22);
    for (var y = bounds.top; y < bounds.bottom; y += cell * 0.17) {
      final p = Path()..moveTo(bounds.left, y);
      for (var x = bounds.left; x <= bounds.right; x += cell * 0.5) {
        p.quadraticBezierTo(x + cell * 0.25, y + sin(x * 0.07 + y * 0.13) * 2.4, x + cell * 0.5, y);
      }
      canvas.drawPath(p, grain);
    }
    // carved bevel: light edge top-left, dark edge bottom-right
    canvas.drawPath(wood.shift(const Offset(2.5, 2.5)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawPath(wood.shift(const Offset(-2.5, -2.5)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0xFFFFD9A0).withValues(alpha: 0.45));
    // moss patches
    final moss = Paint()..color = const Color(0xFF3F7A3A).withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(bounds.topLeft + Offset(cell * 2.1, cell * 0.2), cell * 0.35, moss);
    canvas.drawCircle(bounds.bottomRight - Offset(cell * 2.1, cell * 0.15), cell * 0.4, moss);
    canvas.drawCircle(bounds.centerLeft + Offset(cell * 0.2, cell * 0.4), cell * 0.28, moss);
    canvas.restore();
    canvas.drawPath(wood,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF2E1808));

    // recessed holes
    for (final h in geo.def.holes) {
      final c = geo.centerOf(h);
      final r = cell * 0.37;
      // lower lip catches light
      canvas.drawCircle(c + const Offset(0, 2), r + 1, Paint()..color = const Color(0x66FFE2B0));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, 0.55),
            radius: 1.0,
            colors: [Color(0xFF4A2A14), Color(0xFF1B0D05)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      // inner shadow from the top edge
      canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1.5), pi * 1.05, pi * 0.9, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.black.withValues(alpha: 0.6));
      if (targets.contains(h)) {
        canvas.drawCircle(c, r * 1.25,
            Paint()..color = lantern.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(c, r * 0.55, Paint()..color = lantern.withValues(alpha: 0.85));
        canvas.drawCircle(c, r * 0.9,
            Paint()..color = const Color(0xFFFFE0A0)..style = PaintingStyle.stroke..strokeWidth = 2.5);
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => old.targets != targets || old.geo.cell != geo.cell;
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.score,
    required this.isBest,
    required this.onRetry,
    required this.onNext,
    required this.onMenu,
  });
  final ScoreBreakdown score;
  final bool isBest;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final VoidCallback onMenu;

  Widget _row(String l, int v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(
            child: Text(l,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: v == 0 && !bold ? Colors.white38 : parchment)),
          ),
          Text(v == 0 && !bold ? '-' : (bold ? '$v' : '+$v'),
              style: TextStyle(fontSize: 17, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final medal = score.medal;
    final medalName = switch (medal) {
      Medal.gold => 'Gold medal',
      Medal.silver => 'Silver medal',
      Medal.bronze => 'Bronze medal',
      Medal.none => null,
    };
    final medalColor = switch (medal) {
      Medal.gold => const Color(0xFFFFD25A),
      Medal.silver => const Color(0xFFC9D1D9),
      _ => const Color(0xFFCD8B4A),
    };
    return Dialog(
      backgroundColor: const Color(0xEE14183A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lantern, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(score.rank, style: displayFont.copyWith(fontSize: 38, color: lantern)),
            Text('${score.pegsLeft} ${score.pegsLeft == 1 ? 'peg' : 'pegs'} left',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            _row('Jumps', score.jumpPoints),
            _row('Pegs-left bonus', score.pegsLeftBonus),
            _row('Center finish', score.centerBonus),
            _row('Speed bonus', score.speedBonus),
            _row('Clean finish', score.cleanBonus),
            const Divider(color: Colors.white24),
            _row('Total', score.total, bold: true),
            if (medalName != null) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.workspace_premium, color: medalColor, size: 30),
                const SizedBox(width: 6),
                Text(medalName, style: TextStyle(fontSize: 18, color: medalColor)),
              ]),
            ],
            if (isBest)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('New best score!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: lantern)),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: onMenu, child: const Text('Menu'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: onRetry, child: const Text('Retry'))),
              if (onNext != null) ...[
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: onNext, child: const Text('Next'))),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
