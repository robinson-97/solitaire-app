import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/board_def.dart';
import '../game/journey.dart';
import '../game/peg_game.dart';
import '../storage.dart';
import 'background.dart';
import 'peg_view.dart';
import 'styles.dart';
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

/// The board seen from a tilted camera: flat geometry plus a perspective
/// matrix. Pegs are drawn upright on top of the projected hole positions.
class TiltedBoard {
  TiltedBoard._(this.flat, this.matrix, this.size, this.thick, this._centers, this._scales);
  final BoardGeometry flat;
  final Matrix4 matrix;
  final Size size;
  final double thick;
  final Map<Pos, Offset> _centers;
  final Map<Pos, double> _scales;

  static const tilt = 0.52;
  double get cell => flat.cell;

  static TiltedBoard build(BoardDef def, double cell) {
    final flat = BoardGeometry(def, cell);
    final w = flat.width, h = flat.height;
    final persp = Matrix4.identity()..setEntry(3, 2, 0.32 / w);
    final m0 = Matrix4.translationValues(w / 2, h / 2, 0) *
        persp *
        Matrix4.rotationX(-tilt) *
        Matrix4.translationValues(-w / 2, -h / 2, 0);
    Offset pr(Matrix4 m, Offset o) => MatrixUtils.transformPoint(m, o);
    final corners = [Offset.zero, Offset(w, 0), Offset(0, h), Offset(w, h)].map((o) => pr(m0, o));
    final b = corners.map((o) => Rect.fromPoints(o, o)).reduce((a, c) => a.expandToInclude(c));
    final top = cell * 0.95;
    final thick = cell * 0.3;
    final m = Matrix4.translationValues(-b.left, -b.top + top, 0) * m0;
    final centers = <Pos, Offset>{};
    final scales = <Pos, double>{};
    for (final p in def.holes) {
      final q = flat.centerOf(p);
      centers[p] = pr(m, q);
      scales[p] = (pr(m, q + Offset(cell, 0)) - centers[p]!).dx / cell;
    }
    return TiltedBoard._(flat, m, Size(b.width, b.height + top + thick + cell * 0.3), thick, centers, scales);
  }

  /// Largest board that fits the box.
  static TiltedBoard fit(BoardDef def, double maxW, double maxH) {
    final probe = build(def, 10);
    final k = min(maxW / probe.size.width, maxH / probe.size.height) * 10;
    return build(def, min(k, 64));
  }

  Offset centerOf(Pos p) => _centers[p]!;
  double scaleOf(Pos p) => _scales[p]!;

  /// Same as [centerOf] for a position between holes (flat coordinates).
  Offset project(Offset flatPoint) => MatrixUtils.transformPoint(matrix, flatPoint);
  double scaleAtFlat(Offset f) => (project(f + Offset(cell, 0)) - project(f)).dx / cell;

  double pegSize(double scale) => cell * scale * 0.8;

  Pos? hit(Offset o) {
    Pos? best;
    var bestD = double.infinity;
    for (final p in flat.def.holes) {
      final s = scaleOf(p);
      // pegs sit raised above their hole, so aim a little above it
      final d = (centerOf(p) - Offset(0, pegSize(s) * 0.28) - o).distance;
      if (d < cell * s * 0.58 && d < bestD) {
        bestD = d;
        best = p;
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

class _Hop {
  _Hop(this.id, this.from, this.to);
  final int id;
  final Pos from;
  final Pos to;
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.board, required this.storage, this.nextBoard});
  final BoardDef board;
  final Storage storage;
  final BoardDef? nextBoard;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
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
  _Hop? hop;

  late final AnimationController _hopC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520), value: 1);
  late final AnimationController _glowC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

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
    _hopC.dispose();
    _glowC.dispose();
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
    hop = null;
    _hopC.value = 1;
  }

  void _buzz([bool strong = false]) {
    if (!widget.storage.haptics) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }

  void _startHop(int id, Pos from, Pos to) {
    hop = _Hop(id, from, to);
    if (reduceMotion(context)) {
      _hopC.value = 1;
    } else {
      _hopC.forward(from: 0);
    }
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
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => ghosts.remove(removedId));
    });
    _startHop(movedId, m.from, m.to);
    game.apply(m);
    hist.add(_Rec(m, movedId, removedId));
    selected = null;
    targets = [];
    Timer(const Duration(milliseconds: 440), _landBuzz);
    if (game.isOver) _finish();
  }

  void _landBuzz() {
    if (mounted) _buzz(true);
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
      _startHop(r.movedId, r.move.to, r.move.from);
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
    await Future.delayed(const Duration(milliseconds: 1100));
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
    final pegTheme = pegThemeById(widget.storage.pegTheme);
    final boardTheme = boardThemeById(widget.storage.boardTheme);
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
                  child: Text(widget.board.name, style: displayFont.copyWith(fontSize: 26)),
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
                final tb = TiltedBoard.fit(widget.board, box.maxWidth, box.maxHeight);
                return Center(
                  child: GestureDetector(
                    key: const ValueKey('board'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final p = tb.hit(d.localPosition);
                      if (p != null) _onTap(p);
                    },
                    child: SizedBox(
                      width: tb.size.width,
                      height: tb.size.height,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_hopC, _glowC]),
                        builder: (context, _) => _scene(tb, pegTheme, boardTheme, still),
                      ),
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

  bool get _hopping => hop != null && _hopC.value < 1;

  /// Flat (board-plane) position of a peg, including a hop in progress.
  Offset _flatPos(TiltedBoard tb, int id, Pos p) {
    final h = hop;
    if (h != null && h.id == id && _hopC.value < 1) {
      final t = Curves.easeInOut.transform(_hopC.value);
      return Offset.lerp(tb.flat.centerOf(h.from), tb.flat.centerOf(h.to), t)!;
    }
    return tb.flat.centerOf(p);
  }

  double _hopHeight(TiltedBoard tb, int id) {
    final h = hop;
    if (h != null && h.id == id && _hopC.value < 1) {
      return sin(pi * _hopC.value) * tb.cell * 1.15;
    }
    return 0;
  }

  Widget _scene(TiltedBoard tb, PegTheme pt, BoardTheme bt, bool still) {
    final glow = still ? 0.0 : _glowC.value;
    // peg entries sorted back to front so nearer pegs overlap farther ones
    final entries = ids.entries.map((e) {
      final f = _flatPos(tb, e.value, e.key);
      return (id: e.value, pos: e.key, flat: f, screen: tb.project(f));
    }).toList()
      ..sort((a, b) {
        final am = a.id == hop?.id && _hopping ? 1 : 0;
        final bm = b.id == hop?.id && _hopping ? 1 : 0;
        if (am != bm) return am - bm;
        return a.screen.dy.compareTo(b.screen.dy);
      });
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: CustomPaint(
          painter: _BoardPainter(tb, bt, targets.map((m) => m.to).toSet(), glow),
        ),
      ),
      Positioned.fill(
        child: CustomPaint(
          painter: _ShadowPainter(
            tb,
            [for (final e in entries) (e.screen, tb.pegSize(tb.scaleAtFlat(e.flat)), _hopHeight(tb, e.id))],
          ),
        ),
      ),
      for (final e in entries) _peg(tb, pt, e.id, e.pos, e.flat, e.screen, glow, still),
      for (final g in ghosts.entries) _ghost(tb, pt, g.key, g.value, glow, still),
    ]);
  }

  Widget _peg(TiltedBoard tb, PegTheme pt, int id, Pos p, Offset flat, Offset screen, double glow, bool still) {
    final d = tb.pegSize(tb.scaleAtFlat(flat));
    final lift = _hopHeight(tb, id);
    final sel = selected == p;
    final quick = still ? Duration.zero : const Duration(milliseconds: 130);
    // sphere rests in its hole: centre sits above the hole centre
    final cx = screen.dx;
    final cy = screen.dy - d * 0.32 - lift;
    return Positioned(
      key: ValueKey('peg$id'),
      left: cx - d / 2,
      top: cy - d / 2,
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
            offset: sel ? const Offset(0, -0.16) : Offset.zero,
            duration: quick,
            child: AnimatedScale(
              scale: sel ? 1.1 : 1 + 0.12 * sin(pi * (_hopping && hop!.id == id ? _hopC.value : 0)),
              duration: _hopping && hop!.id == id ? Duration.zero : quick,
              child: PegView(theme: pt, glow: (glow + id * 0.13) % 1, selected: sel),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghost(TiltedBoard tb, PegTheme pt, int id, Pos p, double glow, bool still) {
    final d = tb.pegSize(tb.scaleOf(p));
    final c = tb.centerOf(p) - Offset(0, d * 0.32);
    return Positioned(
      key: ValueKey('ghost$id'),
      left: c.dx - d / 2,
      top: c.dy - d / 2,
      width: d,
      height: d,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: still ? const Duration(milliseconds: 200) : const Duration(milliseconds: 800),
          builder: (_, raw, _) {
            // wait until the jumping peg flies overhead, then poof
            final t = still ? raw : ((raw - 0.3) / 0.7).clamp(0.0, 1.0);
            return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              if (!still && t > 0) ...[
                Transform.scale(
                  scale: 1 + t * 1.3,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: lantern.withValues(alpha: (1 - t) * 0.9), width: 2.5),
                    ),
                  ),
                ),
                for (var i = 0; i < 6; i++)
                  Transform.translate(
                    offset: Offset(cos(i * pi / 3) * d * 0.9 * t, sin(i * pi / 3) * d * 0.9 * t - d * 0.2 * t),
                    child: Container(
                      width: d * 0.12 * (1 - t) + 1,
                      height: d * 0.12 * (1 - t) + 1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pt.glow == pegThemes.first.glow ? lantern : pt.glow,
                      ),
                    ),
                  ),
              ],
              Opacity(
                opacity: 1 - t,
                child: Transform.scale(
                  scale: 1 - t * 0.5,
                  child: PegView(theme: pt, glow: glow),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  _ShadowPainter(this.tb, this.pegs);
  final TiltedBoard tb;
  final List<(Offset, double, double)> pegs; // screen pos, size, height

  @override
  void paint(Canvas canvas, Size size) {
    for (final (pos, d, h) in pegs) {
      final f = 1 - (h / (tb.cell * 1.5)).clamp(0.0, 0.5);
      canvas.drawOval(
        Rect.fromCenter(center: pos + Offset(d * 0.08, d * 0.02), width: d * 0.95 * f, height: d * 0.42 * f),
        Paint()..color = Colors.black.withValues(alpha: 0.5 * f)..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.1),
      );
    }
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => true;
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.tb, this.theme, this.targets, this.glow);
  final TiltedBoard tb;
  final BoardTheme theme;
  final Set<Pos> targets;
  final double glow;

  Path? _wood;
  Path get wood => _wood ??= _buildWood();

  Path _buildWood() {
    final cell = tb.cell;
    var path = Path();
    for (final h in tb.flat.def.holes) {
      path = Path.combine(
        PathOperation.union,
        path,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: tb.flat.centerOf(h), width: cell * 1.2, height: cell * 1.2),
            Radius.circular(cell * 0.3),
          )),
      );
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = tb.cell;
    final m = tb.matrix.storage;
    final bounds = wood.getBounds();
    final pulse = 0.5 + 0.5 * sin(glow * 2 * pi);

    // soft shadow on the table
    canvas.save();
    canvas.translate(0, tb.thick + 6);
    canvas.transform(m);
    canvas.drawPath(wood, Paint()..color = Colors.black.withValues(alpha: 0.75)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.restore();

    // lantern glow around the board
    canvas.save();
    canvas.transform(m);
    canvas.drawPath(wood, Paint()..color = lantern.withValues(alpha: 0.10 + 0.06 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
    canvas.restore();

    // thickness: stack of darker copies pushed down the screen
    final steps = tb.thick.ceil();
    for (var i = steps; i >= 1; i--) {
      canvas.save();
      canvas.translate(0, i.toDouble());
      canvas.transform(m);
      canvas.drawPath(wood, Paint()..color = Color.lerp(theme.body[2], theme.side, i / steps)!);
      canvas.restore();
    }

    canvas.save();
    canvas.transform(m);
    // top surface
    canvas.drawPath(
      wood,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.body,
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipPath(wood);
    if (theme.stone) {
      final rnd = Random(3);
      for (var i = 0; i < 260; i++) {
        final o = Offset(bounds.left + rnd.nextDouble() * bounds.width, bounds.top + rnd.nextDouble() * bounds.height);
        canvas.drawCircle(o, cell * (0.02 + rnd.nextDouble() * 0.05),
            Paint()..color = (rnd.nextBool() ? Colors.black : Colors.white).withValues(alpha: 0.10));
      }
      final crack = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = theme.grain.withValues(alpha: 0.5);
      for (var i = 0; i < 7; i++) {
        final a = Offset(bounds.left + rnd.nextDouble() * bounds.width, bounds.top + rnd.nextDouble() * bounds.height);
        final p = Path()..moveTo(a.dx, a.dy);
        var cur = a;
        for (var k = 0; k < 4; k++) {
          cur += Offset((rnd.nextDouble() - 0.5) * cell * 0.7, (rnd.nextDouble() - 0.2) * cell * 0.6);
          p.lineTo(cur.dx, cur.dy);
        }
        canvas.drawPath(p, crack);
      }
    } else {
      final grain = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = theme.grain.withValues(alpha: 0.22);
      for (var y = bounds.top; y < bounds.bottom; y += cell * 0.17) {
        final p = Path()..moveTo(bounds.left, y);
        for (var x = bounds.left; x <= bounds.right; x += cell * 0.5) {
          p.quadraticBezierTo(x + cell * 0.25, y + sin(x * 0.07 + y * 0.13) * 2.4, x + cell * 0.5, y);
        }
        canvas.drawPath(p, grain);
      }
    }
    // carved bevel
    canvas.drawPath(wood.shift(const Offset(2.5, 2.5)), Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawPath(wood.shift(const Offset(-2.5, -2.5)), Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = Colors.white.withValues(alpha: 0.3));
    // moss
    final moss = Paint()..color = theme.moss.withValues(alpha: theme.stone ? 0.7 : 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final mossSpots = theme.stone ? 7 : 3;
    final mr = Random(8);
    for (var i = 0; i < mossSpots; i++) {
      final x = bounds.left + mr.nextDouble() * bounds.width;
      final y = bounds.top + (i.isEven ? 0.1 : 0.9) * bounds.height + (mr.nextDouble() - 0.5) * cell;
      canvas.drawCircle(Offset(x, y), cell * (0.3 + mr.nextDouble() * 0.25), moss);
    }
    canvas.restore();
    canvas.drawPath(wood, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black.withValues(alpha: 0.6));

    // recessed holes
    for (final h in tb.flat.def.holes) {
      final c = tb.flat.centerOf(h);
      final r = cell * 0.37;
      canvas.drawCircle(c + const Offset(0, 2), r + 1, Paint()..color = Colors.white.withValues(alpha: 0.25));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.55),
            radius: 1.0,
            colors: [theme.holeInner, theme.holeOuter],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1.5), pi * 1.05, pi * 0.9, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.black.withValues(alpha: 0.6));
      if (targets.contains(h)) {
        canvas.drawCircle(c, r * 1.3, Paint()..color = lantern.withValues(alpha: 0.45 + 0.25 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(c, r * 0.55, Paint()..color = lantern.withValues(alpha: 0.85));
        canvas.drawCircle(c, r * (0.9 + 0.08 * pulse), Paint()..color = const Color(0xFFFFE0A0)..style = PaintingStyle.stroke..strokeWidth = 2.5);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
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
