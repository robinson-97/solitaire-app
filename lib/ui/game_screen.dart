import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/board_def.dart';
import '../game/unlocks.dart';
import '../game/worlds.dart';
import '../game/peg_game.dart';
import '../sfx.dart';
import '../storage.dart';
import 'background.dart';
import 'fx.dart';
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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 640), value: 1);
  late final AnimationController _landC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  Pos? landAt;
  bool _landFired = false;
  late final AnimationController _glowC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void initState() {
    super.initState();
    _reset();
    _hopC.addListener(_onHopTick);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && game.inProgress && !game.isOver) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    confirmTimer?.cancel();
    _hopC.dispose();
    _landC.dispose();
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

  void _onHopTick() {
    if (!_landFired && hop != null && _hopC.value >= _arcEnd) {
      _landFired = true;
      landAt = hop!.to;
      if (!reduceMotion(context)) _landC.forward(from: 0);
    }
  }

  void _startHop(int id, Pos from, Pos to) {
    hop = _Hop(id, from, to);
    _landFired = false;
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
            Sfx.play('invalid');
            HapticFeedback.heavyImpact();
          } else {
            selected = p;
            targets = moves;
            Sfx.play('select');
            _buzz();
          }
        }
      } else if (selected != null) {
        final m = targets.where((m) => m.to == p).firstOrNull;
        if (m != null) {
          _jump(m);
        } else {
          _shake(selected!);
          Sfx.play('invalid');
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
    Sfx.play('jump');
    Timer(const Duration(milliseconds: 500), _landBuzz);
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
      Sfx.play('undo');
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
    final cleared = game.pegsLeft <= widget.board.passAt;
    final stars = !cleared ? 0 : 1 + (game.undosUsed == 0 ? 1 : 0) + (game.pegsLeft == 1 ? 1 : 0);
    final first = !submitted;
    submitted = true;
    var isBest = false;
    var unlocked = <String>[];
    if (first) {
      final u = Unlocks(widget.storage);
      final before = u.snapshot();
      isBest = await widget.storage.submitScore(widget.board.id, score.total);
      await widget.storage.addPoints(score.total);
      if (cleared) {
        await widget.storage.markSolved(widget.board.id);
        await widget.storage.submitStars(widget.board.id, stars);
      }
      unlocked = (u.snapshot().difference(before)).toList();
    }
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    Sfx.play(cleared ? 'win' : 'end');
    if (unlocked.isNotEmpty) Future.delayed(const Duration(milliseconds: 1300), () => Sfx.play('unlock'));
    _showResult(score, isBest, unlocked, cleared, stars);
  }

  void _showResult(ScoreBreakdown s, bool isBest, List<String> unlocked, bool cleared, int stars) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => _ResultDialog(
        score: s,
        isBest: isBest,
        unlocked: unlocked,
        storage: widget.storage,
        cleared: cleared,
        stars: stars,
        goal: widget.board.goalText,
        hasCenter: widget.board.center != null,
        onRetry: () {
          Navigator.pop(ctx);
          setState(_reset);
        },
        onNext: !cleared || widget.nextBoard == null
            ? null
            : () {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(softRoute(GameScreen(
                  board: widget.nextBoard!,
                  storage: widget.storage,
                  nextBoard: nextLevel(widget.nextBoard!),
                )));
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
    final u = Unlocks(widget.storage);
    final pegTheme = pegThemeById(u.pegUnlocked(widget.storage.pegTheme) ? widget.storage.pegTheme : 'acorn');
    final boardTheme = boardThemeById(u.boardUnlocked(widget.storage.boardTheme) ? widget.storage.boardTheme : 'oak');
    return Scaffold(
      body: SceneBackground(
        world: worldOfBoard(widget.board.id).id,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Material(
                  color: cocoa.withValues(alpha: 0.94),
                  shape: const CircleBorder(side: BorderSide(color: cocoaEdge, width: 1.6)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.arrow_back_rounded, size: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.board.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: displayFont.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(widget.board.goalText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: lantern)),
                  ]),
                ),
                Chip2(widget.board.difficulty.label.toUpperCase()),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Expanded(child: _stat(Icons.circle, 'Pegs', '${game.pegsLeft}')),
                const SizedBox(width: 10),
                Expanded(child: _stat(Icons.timer_outlined, 'Time', _fmt(game.secondsElapsed()))),
                const SizedBox(width: 10),
                Expanded(child: _stat(Icons.undo_rounded, 'Undos', '${game.undosUsed}')),
              ]),
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
                        animation: Listenable.merge([_hopC, _glowC, _landC]),
                        builder: (context, _) => _scene(tb, pegTheme, boardTheme, still),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Row(children: [
                Expanded(child: PillButton(label: 'Undo', icon: Icons.undo_rounded, onTap: hist.isEmpty ? null : _undo)),
                const SizedBox(width: 12),
                Expanded(
                  child: PillButton(
                    label: confirmRestart ? 'Tap again' : 'Restart',
                    icon: Icons.refresh_rounded,
                    danger: confirmRestart,
                    onTap: _restart,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: cocoa.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cocoaEdge, width: 1.4),
          boxShadow: const [BoxShadow(color: cocoaDeep, offset: Offset(0, 3))],
        ),
        child: Column(children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
          Text(value, style: displayFont.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
        ]),
      );

  bool get _hopping => hop != null && _hopC.value < 1;

  static const _arcEnd = 0.78;

  /// Where a hopping peg is at animation time [t]: how far along the ground
  /// (0..1), height above the board, and squash & stretch.
  ({double move, double lift, double sx, double sy}) _pose(double t, double cell) {
    if (t < _arcEnd) {
      final u = t / _arcEnd;
      final crouch = u < 0.14 ? 0.12 * (1 - u / 0.14) : 0.0;
      final sy = 1 - crouch + 0.14 * sin(pi * u);
      return (
        move: Curves.easeInOut.transform(u),
        lift: 4 * u * (1 - u) * cell * 1.25,
        sx: 1 / sy,
        sy: sy,
      );
    }
    final v = (t - _arcEnd) / (1 - _arcEnd);
    final squash = v < 0.4 ? 0.2 * sin(pi * v / 0.4) : 0.0;
    final bounce = v < 0.4 ? 0.0 : sin(pi * (v - 0.4) / 0.6) * cell * 0.18;
    final sy = 1 - squash;
    return (move: 1.0, lift: bounce, sx: 1 / sy, sy: sy);
  }

  bool _isHopper(int id) => hop != null && hop!.id == id && _hopC.value < 1;

  /// Flat (board-plane) position of a peg, including a hop in progress.
  Offset _flatPos(TiltedBoard tb, int id, Pos p) {
    if (_isHopper(id)) {
      final m = _pose(_hopC.value, tb.cell).move;
      return Offset.lerp(tb.flat.centerOf(hop!.from), tb.flat.centerOf(hop!.to), m)!;
    }
    return tb.flat.centerOf(p);
  }

  double _hopHeight(TiltedBoard tb, int id) => _isHopper(id) ? _pose(_hopC.value, tb.cell).lift : 0;

  Color _fxColor(PegTheme pt) => pt.fxColor ?? (pt.glowAlpha > 0 ? pt.glow : lantern);

  /// Positions of the sparkle trail behind the flying peg.
  List<(Offset, double, double)> _trailPoints(TiltedBoard tb) {
    final h = hop!;
    final t = _hopC.value;
    final out = <(Offset, double, double)>[];
    if (t >= _arcEnd) return out;
    for (var k = 1; k <= 7; k++) {
      final tt = t - k * 0.028;
      if (tt <= 0) continue;
      final pose = _pose(tt, tb.cell);
      final flat = Offset.lerp(tb.flat.centerOf(h.from), tb.flat.centerOf(h.to), pose.move)!;
      final d = tb.pegSize(tb.scaleAtFlat(flat));
      final pos = tb.project(flat) - Offset(0, d * 0.32 + pose.lift);
      final f = 1 - k / 8;
      out.add((pos, d * 0.3 * f, 0.9 * f));
    }
    return out;
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
      if (!still && _landC.isAnimating && landAt != null)
        Positioned.fill(
          child: CustomPaint(
            painter: _LandPainter(pt.fx, _fxColor(pt), tb.centerOf(landAt!), tb.pegSize(tb.scaleOf(landAt!)), _landC.value, true),
          ),
        ),
      if (_hopping && !still && pt.fx != FxKind.none)
        Positioned.fill(child: CustomPaint(painter: _TrailPainter(pt.fx, _fxColor(pt), _trailPoints(tb)))),
      for (final e in entries) _peg(tb, pt, e.id, e.pos, e.flat, e.screen, glow, still),
      for (final g in ghosts.entries) _ghost(tb, pt, g.key, g.value, glow, still),
      if (!still && _landC.isAnimating && landAt != null)
        Positioned.fill(
          child: CustomPaint(
            painter: _LandPainter(pt.fx, _fxColor(pt), tb.centerOf(landAt!), tb.pegSize(tb.scaleOf(landAt!)), _landC.value, false),
          ),
        ),
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
            child: Transform.scale(
              scaleX: _isHopper(id) ? _pose(_hopC.value, tb.cell).sx : 1,
              scaleY: _isHopper(id) ? _pose(_hopC.value, tb.cell).sy : 1,
              alignment: Alignment.bottomCenter,
              child: AnimatedScale(
                scale: sel ? 1.1 : 1,
                duration: quick,
                child: PegView(theme: pt, glow: (glow + id * 0.13) % 1, selected: sel),
              ),
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

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.kind, this.color, this.trail);
  final FxKind kind;
  final Color color;
  final List<(Offset, double, double)> trail; // position, radius, alpha

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < trail.length; i++) {
      final (pos, r, a) = trail[i];
      drawParticle(canvas, kind, pos + Offset(0, -i * 1.5), r, a, color, i * 0.9);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

class _LandPainter extends CustomPainter {
  _LandPainter(this.kind, this.color, this.at, this.px, this.v, this.ripple);
  final bool ripple;
  final FxKind kind;
  final Color color;
  final Offset at;
  final double px;
  final double v;

  @override
  void paint(Canvas canvas, Size size) => paintLanding(canvas, kind, at, px, v, color, ripple: ripple);

  @override
  bool shouldRepaint(_LandPainter old) => true;
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
    if (theme.kind == BoardKind.pitch) {
      // mown stripes and white pitch markings
      for (var i = 0; i < 14; i++) {
        if (i.isEven) {
          canvas.drawRect(Rect.fromLTWH(bounds.left + i * bounds.width / 14, bounds.top, bounds.width / 14, bounds.height), Paint()..color = Colors.white.withValues(alpha: 0.07));
        }
      }
      final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withValues(alpha: 0.55);
      canvas.drawCircle(bounds.center, cell * 1.3, line);
      canvas.drawLine(Offset(bounds.left, bounds.center.dy), Offset(bounds.right, bounds.center.dy), line);
      canvas.drawCircle(bounds.center, 3, Paint()..color = Colors.white.withValues(alpha: 0.6));
    } else if (theme.kind == BoardKind.neon) {
      // glowing synthwave grid
      final cyan = theme.accent.withValues(alpha: 0.18 + 0.1 * pulse);
      final gl = Paint()..color = cyan..strokeWidth = 4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final ln = Paint()..color = theme.accent.withValues(alpha: 0.5)..strokeWidth = 1;
      for (var x = bounds.left; x <= bounds.right; x += cell * 0.5) {
        canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), gl);
        canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), ln);
      }
      for (var y = bounds.top; y <= bounds.bottom; y += cell * 0.5) {
        canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), Paint()..color = theme.grain.withValues(alpha: 0.2 + 0.1 * pulse)..strokeWidth = 1);
      }
    } else if (theme.kind != BoardKind.wood) {
      final rnd = Random(3);
      for (var i = 0; i < 260; i++) {
        final o = Offset(bounds.left + rnd.nextDouble() * bounds.width, bounds.top + rnd.nextDouble() * bounds.height);
        canvas.drawCircle(o, cell * (0.02 + rnd.nextDouble() * 0.05),
            Paint()..color = (rnd.nextBool() ? Colors.black : Colors.white).withValues(alpha: 0.10));
      }
      final glowy = theme.kind != BoardKind.stone && theme.kind != BoardKind.marble;
      final crackAlpha = theme.kind == BoardKind.stone ? 0.5 : 0.35 + 0.3 * pulse;
      final crackColor = theme.grain.withValues(alpha: crackAlpha);
      final crack = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.kind == BoardKind.stone ? 1.1 : (theme.kind == BoardKind.lava ? 2.4 : 1.6)
        ..color = crackColor;
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = theme.accent.withValues(alpha: 0.25 + 0.2 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      if (theme.kind == BoardKind.rune) {
        // glowing carved glyphs
        final gr = Random(21);
        for (var i = 0; i < 16; i++) {
          final o = Offset(bounds.left + gr.nextDouble() * bounds.width, bounds.top + gr.nextDouble() * bounds.height);
          final sz = cell * (0.12 + gr.nextDouble() * 0.1);
          final g = Path();
          switch (i % 4) {
            case 0:
              g..moveTo(o.dx, o.dy - sz)..lineTo(o.dx, o.dy + sz)..moveTo(o.dx - sz * 0.7, o.dy - sz * 0.2)..lineTo(o.dx + sz * 0.7, o.dy + sz * 0.2);
            case 1:
              g..moveTo(o.dx - sz, o.dy + sz)..lineTo(o.dx, o.dy - sz)..lineTo(o.dx + sz, o.dy + sz);
            case 2:
              g..addArc(Rect.fromCircle(center: o, radius: sz), 0.4, 4.6)..moveTo(o.dx, o.dy)..lineTo(o.dx + sz * 0.8, o.dy - sz * 0.5);
            default:
              g..moveTo(o.dx - sz, o.dy - sz)..lineTo(o.dx + sz, o.dy + sz)..moveTo(o.dx + sz, o.dy - sz)..lineTo(o.dx - sz, o.dy + sz);
          }
          canvas.drawPath(g, glowPaint);
          canvas.drawPath(g, crack..strokeWidth = 1.6);
        }
      } else {
        for (var i = 0; i < (theme.kind == BoardKind.lava ? 11 : 7); i++) {
          final a = Offset(bounds.left + rnd.nextDouble() * bounds.width, bounds.top + rnd.nextDouble() * bounds.height);
          final p = Path()..moveTo(a.dx, a.dy);
          var cur = a;
          for (var k = 0; k < 4; k++) {
            cur += Offset((rnd.nextDouble() - 0.5) * cell * 0.7, (rnd.nextDouble() - 0.2) * cell * 0.6);
            p.lineTo(cur.dx, cur.dy);
          }
          if (glowy) canvas.drawPath(p, glowPaint);
          canvas.drawPath(p, crack);
        }
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
    final moss = Paint()..color = theme.moss.withValues(alpha: theme.kind == BoardKind.stone ? 0.7 : theme.kind == BoardKind.wood ? 0.5 : theme.kind == BoardKind.pitch || theme.kind == BoardKind.neon ? 0.0 : 0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final mossSpots = theme.kind == BoardKind.stone ? 7 : theme.kind == BoardKind.wood ? 3 : 4;
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

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({
    required this.score,
    required this.isBest,
    required this.unlocked,
    required this.storage,
    required this.cleared,
    required this.stars,
    required this.goal,
    required this.hasCenter,
    required this.onRetry,
    required this.onNext,
    required this.onMenu,
  });
  final ScoreBreakdown score;
  final bool isBest;
  final List<String> unlocked;
  final Storage storage;
  final bool cleared;
  final int stars;
  final String goal;
  final bool hasCenter;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final VoidCallback onMenu;

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> {
  Widget _row(String l, int v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
            child: Text(l,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: v == 0 && !bold ? Colors.white38 : parchment)),
          ),
          Text(v == 0 && !bold ? '-' : (bold ? '$v' : '+$v'),
              style: TextStyle(fontSize: bold ? 18 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? lantern : null)),
        ]),
      );

  Widget _unlockRow(String key) {
    final kind = key.split(':').first;
    final id = key.split(':').last;
    Widget lead;
    String title;
    Widget? action;
    switch (kind) {
      case 'peg':
        final t = pegThemeById(id);
        lead = SizedBox(width: 38, height: 38, child: PegView(theme: t, glow: 0.3));
        title = '${t.name} pegs';
        action = PillButton(
          label: widget.storage.pegTheme == id ? 'Equipped' : 'Equip',
          primary: widget.storage.pegTheme != id,
          compact: true,
          onTap: widget.storage.pegTheme == id
              ? null
              : () async {
                  await widget.storage.setPegTheme(id);
                  setState(() {});
                },
        );
      case 'board':
        final t = boardThemeById(id);
        lead = BoardPreview(classicBoard, size: 40, theme: t, showPegs: false);
        title = '${t.name} board';
        action = PillButton(
          label: widget.storage.boardTheme == id ? 'Equipped' : 'Equip',
          primary: widget.storage.boardTheme != id,
          compact: true,
          onTap: widget.storage.boardTheme == id
              ? null
              : () async {
                  await widget.storage.setBoardTheme(id);
                  setState(() {});
                },
        );
      default:
        lead = const Icon(Icons.public_rounded, color: lantern, size: 32);
        title = '${worldById(id).name} world';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        SizedBox(width: 42, child: Center(child: lead)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        if (action != null) action,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: cocoa,
          border: Border.all(color: lantern, width: 2.4),
          boxShadow: const [BoxShadow(color: cocoaDeep, offset: Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ShaderMask(
              shaderCallback: (r) => LinearGradient(
                colors: widget.cleared
                    ? const [Color(0xFFFFE9A8), Color(0xFFFFA43B)]
                    : const [Color(0xFFD8DCF5), Color(0xFF8E96C9)],
              ).createShader(r),
              child: Text(widget.cleared ? 'Level cleared!' : 'Not cleared yet',
                  style: displayFont.copyWith(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 6),
            if (widget.cleared)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 3; i++)
                  Icon(Icons.star_rounded, size: 34, color: i < widget.stars ? const Color(0xFFFFD25A) : Colors.white24),
              ])
            else
              Text(widget.goal, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: lantern)),
            const SizedBox(height: 4),
            Text('${score.rank} · ${score.pegsLeft} ${score.pegsLeft == 1 ? 'peg' : 'pegs'} left',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 14),
            _row('Jumps', score.jumpPoints),
            _row('Pegs-left bonus', score.pegsLeftBonus),
            if (widget.hasCenter) _row('Center finish', score.centerBonus),
            _row('Speed bonus', score.speedBonus),
            _row('Clean finish', score.cleanBonus),
            Divider(color: Colors.white.withValues(alpha: 0.18), height: 18),
            _row('Total', score.total, bold: true),
            if (medalName != null) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.workspace_premium_rounded, color: medalColor, size: 28),
                const SizedBox(width: 6),
                Text(medalName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: medalColor)),
              ]),
            ],
            if (widget.isBest)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip2('NEW BEST SCORE'),
              ),
            if (widget.unlocked.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: lantern.withValues(alpha: 0.1),
                  border: Border.all(color: lantern.withValues(alpha: 0.5)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.auto_awesome, color: lantern, size: 18),
                    SizedBox(width: 8),
                    Text('NEW UNLOCK', style: TextStyle(fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: lantern)),
                  ]),
                  for (final k in widget.unlocked) _unlockRow(k),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: PillButton(label: 'Menu', onTap: widget.onMenu, compact: true)),
              const SizedBox(width: 8),
              Expanded(child: PillButton(label: 'Retry', primary: widget.onNext == null, onTap: widget.onRetry, compact: true)),
              if (widget.onNext != null) ...[
                const SizedBox(width: 8),
                Expanded(child: PillButton(label: 'Next', primary: true, onTap: widget.onNext, compact: true)),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
