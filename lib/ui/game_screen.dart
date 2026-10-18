import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/board_def.dart';
import '../game/unlocks.dart';
import '../game/hint.dart';
import '../game/rewards.dart';
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
  const GameScreen({super.key, required this.board, required this.storage, this.nextBoard, this.challenge = false});
  final BoardDef board;
  final Storage storage;
  final BoardDef? nextBoard;

  /// Today's challenge level: the first clear of the day pays a bonus.
  final bool challenge;

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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 760), value: 1);
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

  bool _hinting = false;

  Future<void> _hint() async {
    if (_hinting || game.isOver) return;
    final msg = ScaffoldMessenger.of(context);
    if (widget.storage.points < hintCost) {
      msg.showSnackBar(const SnackBar(content: Text('A hint costs $hintCost points')));
      return;
    }
    setState(() => _hinting = true);
    final r = await findHint(widget.board, game.pegs, goal: widget.board.passAt);
    if (!mounted) return;
    setState(() => _hinting = false);
    if (r.status == HintStatus.move) {
      await widget.storage.spendPoints(hintCost);
      final m = game.movesFrom(r.from!).where((m) => m.to == r.to).firstOrNull;
      if (m == null || !mounted) return;
      setState(() {
        selected = r.from;
        targets = [m];
        confirmRestart = false;
      });
      Sfx.play('select');
      _buzz();
    } else {
      msg.showSnackBar(SnackBar(
        content: Text(r.status == HintStatus.stuck ? 'No way to finish from here - undo a few moves or restart. (No points spent)' : 'Could not find a hint in time. (No points spent)'),
      ));
    }
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
    var reward = 0;
    var challengeBonus = false;
    if (first) {
      final u = Unlocks(widget.storage);
      final before = u.snapshot();
      isBest = await widget.storage.submitScore(widget.board.id, score.total);
      if (cleared) {
        await widget.storage.markSolved(widget.board.id);
        await widget.storage.submitStars(widget.board.id, stars);
        reward = await widget.storage.payLevel(widget.board, stars);
        final today = todayKey();
        if (widget.challenge && widget.storage.lastChallenge != today) {
          await widget.storage.claimChallenge(today);
          reward += dailyChallengeBonus;
          challengeBonus = true;
        }
      }
      unlocked = (u.snapshot().difference(before)).toList();
    }
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    Sfx.play(cleared ? 'win' : 'end');
    if (unlocked.isNotEmpty) Future.delayed(const Duration(milliseconds: 1300), () => Sfx.play('unlock'));
    _showResult(score, isBest, unlocked, cleared, stars, reward, challengeBonus);
  }

  void _showResult(ScoreBreakdown s, bool isBest, List<String> unlocked, bool cleared, int stars, int reward, bool challengeBonus) {
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
        reward: reward,
        challengeBonus: challengeBonus,
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
    final boardTheme = boardThemeById(u.boardUnlocked(widget.storage.boardTheme) ? widget.storage.boardTheme : 'midnight');
    return Scaffold(
      body: SceneBackground(
        world: 'neon:${worldOfBoard(widget.board.id).id}',
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
                Expanded(child: PillButton(label: 'Undo -${ScoreBreakdown.undoCost}', icon: Icons.undo_rounded, compact: true, onTap: hist.isEmpty ? null : _undo)),
                const SizedBox(width: 8),
                Expanded(
                  child: PillButton(
                    label: 'Hint -$hintCost',
                    icon: Icons.lightbulb_outline_rounded,
                    compact: true,
                    onTap: _hinting || game.isOver ? null : _hint,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PillButton(
                    label: confirmRestart ? 'Tap again' : 'Restart',
                    icon: Icons.refresh_rounded,
                    compact: true,
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

  static const _crouchEnd = 0.12;
  static const _arcEnd = 0.7;

  /// Where a hopping peg is at animation time [t]: how far along the ground
  /// (0..1), height above the board, and squash & stretch. Crouch, spring up,
  /// float over the arc, land with a squash and settle with a damped bounce.
  ({double move, double lift, double sx, double sy}) _pose(double t, double cell) {
    if (t < _crouchEnd) {
      final u = t / _crouchEnd;
      final sy = 1 - 0.22 * Curves.easeOut.transform(u);
      return (move: 0.0, lift: 0.0, sx: 1 / sy, sy: sy);
    }
    if (t < _arcEnd) {
      final u = (t - _crouchEnd) / (_arcEnd - _crouchEnd);
      final c = cos(pi * u);
      final sy = 1 + 0.24 * c * c * (u < 0.5 ? 1 : 0.55);
      return (
        move: 0.45 * u + 0.55 * Curves.easeInOutSine.transform(u),
        lift: 4 * u * (1 - u) * cell * 1.7,
        sx: 1 / sy,
        sy: sy,
      );
    }
    final v = (t - _arcEnd) / (1 - _arcEnd);
    final damp = exp(-4.2 * v);
    final sy = 1 - 0.28 * damp * cos(2 * pi * 1.4 * v);
    final bounce = cell * 0.2 * damp * sin(2 * pi * 1.1 * v).abs() * (v < 0.08 ? v / 0.08 : 1);
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
    for (var k = 1; k <= 9; k++) {
      final tt = t - k * 0.026;
      if (tt <= _crouchEnd) continue;
      final pose = _pose(tt, tb.cell);
      final flat = Offset.lerp(tb.flat.centerOf(h.from), tb.flat.centerOf(h.to), pose.move)!;
      final d = tb.pegSize(tb.scaleAtFlat(flat));
      final pos = tb.project(flat) - Offset(0, d * 0.32 + pose.lift);
      final f = 1 - k / 10;
      out.add((pos, d * 0.26 * f, 0.9 * f));
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
    // a soft comet tail first (tapering, fading), then the theme's particles
    for (var i = trail.length - 1; i > 0; i--) {
      final (a, ra, aa) = trail[i - 1];
      final (b, _, _) = trail[i];
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color.withValues(alpha: aa * 0.35)
          ..strokeWidth = ra * 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < trail.length; i += 2) {
      final (pos, r, a) = trail[i];
      drawParticle(canvas, kind, pos + Offset(sin(i * 1.7) * r, -i * 1.2), r, a, color, i * 0.9);
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
    } else if (theme.kind == BoardKind.sakura) {
      final grain = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: 0.2);
      for (var y = bounds.top; y < bounds.bottom; y += cell * 0.19) {
        final p = Path()..moveTo(bounds.left, y);
        for (var x = bounds.left; x <= bounds.right; x += cell * 0.5) {
          p.quadraticBezierTo(x + cell * 0.25, y + sin(x * 0.07 + y * 0.13) * 2.4, x + cell * 0.5, y);
        }
        canvas.drawPath(p, grain);
      }
      for (var i = 0; i < 16; i++) {
        final t = (glow * (1 + i % 2) + i * 0.173) % 1.0;
        final o = Offset(bounds.left + ((i * 0.37 + 0.2 * sin(t * 2 * pi + i)) % 1.0) * bounds.width, bounds.top + t * bounds.height);
        canvas.save();
        canvas.translate(o.dx, o.dy);
        canvas.rotate(t * 6 + i);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: cell * 0.2, height: cell * 0.11), Paint()..color = (i.isEven ? Colors.white : const Color(0xFFFF8FB4)).withValues(alpha: 0.75));
        canvas.restore();
      }
    } else if (theme.kind == BoardKind.galaxy) {
      final gr = Random(5);
      for (var i = 0; i < 110; i++) {
        final o = Offset(bounds.left + gr.nextDouble() * bounds.width, bounds.top + gr.nextDouble() * bounds.height);
        final tw = 0.35 + 0.65 * (0.5 + 0.5 * sin(glow * 2 * pi * (1 + i % 3) + i));
        canvas.drawCircle(o, cell * (0.015 + gr.nextDouble() * 0.03), Paint()..color = Colors.white.withValues(alpha: 0.85 * tw));
      }
      for (var i = 0; i < 3; i++) {
        final o = bounds.center + Offset(cos(glow * 2 * pi + i * 2.1) * bounds.width * 0.28, sin(glow * 2 * pi + i * 2.1) * bounds.height * 0.22);
        canvas.drawCircle(o, bounds.width * 0.22, Paint()..color = [const Color(0xFF7A4AE8), const Color(0xFFE04AB0), const Color(0xFF4A8AF0)][i].withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
      }
    } else if (theme.kind == BoardKind.ocean) {
      for (var row = 0; row < 14; row++) {
        final y0 = bounds.top + row * bounds.height / 13;
        final p = Path()..moveTo(bounds.left, y0);
        for (var x = bounds.left; x <= bounds.right; x += cell * 0.25) {
          p.lineTo(x, y0 + sin(x * 0.045 + glow * 2 * pi * (row.isEven ? 1 : -1) + row) * cell * 0.09);
        }
        canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.white.withValues(alpha: row.isEven ? 0.28 : 0.16));
      }
      final gr = Random(9);
      for (var i = 0; i < 18; i++) {
        final o = Offset(bounds.left + gr.nextDouble() * bounds.width, bounds.top + gr.nextDouble() * bounds.height);
        canvas.drawCircle(o, cell * 0.04, Paint()..color = Colors.white.withValues(alpha: 0.5 * (0.5 + 0.5 * sin(glow * 2 * pi * 2 + i))));
      }
    } else if (theme.kind == BoardKind.candy) {
      final w = cell * 0.7;
      final shift = glow * w * 2;
      for (var x = bounds.left - bounds.height - w * 2; x < bounds.right + w; x += w * 2) {
        final path = Path()
          ..moveTo(x + shift, bounds.bottom)
          ..lineTo(x + shift + w, bounds.bottom)
          ..lineTo(x + shift + w + bounds.height, bounds.top)
          ..lineTo(x + shift + bounds.height, bounds.top)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.5));
      }
      final gr = Random(2);
      for (var i = 0; i < 26; i++) {
        final o = Offset(bounds.left + gr.nextDouble() * bounds.width, bounds.top + gr.nextDouble() * bounds.height);
        canvas.save();
        canvas.translate(o.dx, o.dy);
        canvas.rotate(gr.nextDouble() * pi);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: cell * 0.16, height: cell * 0.05), Radius.circular(cell * 0.025)), Paint()..color = HSVColor.fromAHSV(1, gr.nextDouble() * 360, 0.55, 1).toColor());
        canvas.restore();
      }
    } else if (theme.kind == BoardKind.aurora) {
      const cols = [Color(0xFF5CFFB8), Color(0xFFB07CFF), Color(0xFF5CC8FF)];
      for (var i = 0; i < 3; i++) {
        final p = Path()..moveTo(bounds.left, bounds.bottom);
        for (var x = bounds.left; x <= bounds.right + cell * 0.3; x += cell * 0.3) {
          final t = (x - bounds.left) / bounds.width;
          final y = bounds.top + bounds.height * (0.25 + 0.25 * i) + sin(t * 6 + glow * 2 * pi + i * 1.9) * bounds.height * 0.1;
          p.lineTo(x, y);
        }
        p..lineTo(bounds.right, bounds.bottom)..close();
        canvas.drawPath(p, Paint()..color = cols[i].withValues(alpha: 0.13 + 0.05 * pulse));
      }
      final gr = Random(4);
      for (var i = 0; i < 50; i++) {
        final o = Offset(bounds.left + gr.nextDouble() * bounds.width, bounds.top + gr.nextDouble() * bounds.height);
        canvas.drawCircle(o, cell * 0.02, Paint()..color = Colors.white.withValues(alpha: 0.7 * (0.5 + 0.5 * sin(glow * 2 * pi * 3 + i))));
      }
    } else if (theme.kind == BoardKind.clockwork) {
      void gear(Offset o, double rad, double rot, int teeth) {
        final g = Path();
        for (var i = 0; i < teeth * 2; i++) {
          final a = rot + i * pi / teeth;
          final rr = i.isEven ? rad : rad * 0.82;
          g.lineTo(o.dx + cos(a) * rr, o.dy + sin(a) * rr);
          final a2 = a + pi / teeth * 0.5;
          g.lineTo(o.dx + cos(a2) * rr, o.dy + sin(a2) * rr);
        }
        g.close();
        canvas.drawPath(g, Paint()..color = const Color(0xFF5A3A12).withValues(alpha: 0.35));
        canvas.drawCircle(o, rad * 0.25, Paint()..color = const Color(0xFFFFE6A8).withValues(alpha: 0.5));
      }
      gear(bounds.center + Offset(-bounds.width * 0.22, -bounds.height * 0.12), cell * 1.3, glow * 2 * pi, 14);
      gear(bounds.center + Offset(bounds.width * 0.2, bounds.height * 0.14), cell * 1.0, -glow * 2 * pi * 14 / 11 - 0.2, 11);
      gear(bounds.center + Offset(bounds.width * 0.02, -bounds.height * 0.33), cell * 0.7, -glow * 2 * pi * 2, 8);
      gear(bounds.center + Offset(-bounds.width * 0.02, bounds.height * 0.36), cell * 0.8, glow * 2 * pi * 2, 9);
    } else if (theme.kind == BoardKind.circuit) {
      final tr = Random(11);
      final lines = <Path>[];
      for (var i = 0; i < 22; i++) {
        var o = Offset(bounds.left + tr.nextInt(14) * bounds.width / 14, bounds.top + tr.nextInt(14) * bounds.height / 14);
        final p = Path()..moveTo(o.dx, o.dy);
        for (var k = 0; k < 4; k++) {
          o += k.isEven ? Offset((tr.nextBool() ? 1 : -1) * cell * (0.6 + tr.nextInt(3) * 0.4), 0) : Offset(0, (tr.nextBool() ? 1 : -1) * cell * (0.6 + tr.nextInt(3) * 0.4));
          p.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = theme.accent.withValues(alpha: 0.22));
        canvas.drawCircle(o, cell * 0.06, Paint()..color = theme.accent.withValues(alpha: 0.5));
        lines.add(p);
      }
      for (var i = 0; i < lines.length; i++) {
        for (final m in lines[i].computeMetrics()) {
          final t = (glow * (1 + i % 2) + i * 0.13) % 1.0;
          final pos = m.getTangentForOffset(m.length * t);
          if (pos != null) canvas.drawCircle(pos.position, cell * 0.07, Paint()..color = theme.accent.withValues(alpha: 0.9));
        }
      }
    } else if (theme.kind == BoardKind.pond) {
      for (var i = 0; i < 4; i++) {
        final t = (glow + i * 0.25) % 1.0;
        final o = bounds.center + Offset(cos(i * 1.7) * bounds.width * 0.28, sin(i * 2.3) * bounds.height * 0.28);
        canvas.drawCircle(o, cell * (0.2 + t * 1.6), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.white.withValues(alpha: 0.4 * (1 - t)));
      }
      for (var f = 0; f < 3; f++) {
        final a = glow * 2 * pi * (f.isEven ? 1 : -1) + f * 2.1;
        final o = bounds.center + Offset(cos(a) * bounds.width * 0.34, sin(a) * bounds.height * 0.3);
        final dir = a + (f.isEven ? pi / 2 : -pi / 2);
        canvas.save();
        canvas.translate(o.dx, o.dy);
        canvas.rotate(dir);
        final col = f == 1 ? Colors.white : const Color(0xFFFF8A2E);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: cell * 0.9, height: cell * 0.4), Paint()..color = col.withValues(alpha: 0.85));
        canvas.drawPath(Path()..moveTo(-cell * 0.35, 0)..lineTo(-cell * 0.75, -cell * 0.2 + sin(glow * 2 * pi * 12) * cell * 0.06)..lineTo(-cell * 0.75, cell * 0.2 + sin(glow * 2 * pi * 12) * cell * 0.06)..close(), Paint()..color = col.withValues(alpha: 0.7));
        canvas.restore();
      }
      for (var i = 0; i < 5; i++) {
        final o = Offset(bounds.left + (i * 0.23 + 0.1) % 1.0 * bounds.width, bounds.top + (i * 0.37 + 0.15) % 1.0 * bounds.height);
        canvas.drawOval(Rect.fromCenter(center: o, width: cell * 0.8, height: cell * 0.7), Paint()..color = const Color(0xFF4FC36A).withValues(alpha: 0.7));
      }
    } else if (theme.kind == BoardKind.storm) {
      final cr = Random(6);
      for (var i = 0; i < 7; i++) {
        final x = bounds.left + ((cr.nextDouble() + glow * (1 + i % 2)) % 1.0) * bounds.width * 1.3 - bounds.width * 0.15;
        final y = bounds.top + cr.nextDouble() * bounds.height;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: cell * 2.4, height: cell * 0.9), Paint()..color = const Color(0xFF1A1D2C).withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }
      final fl = pow(max(0.0, sin(glow * 2 * pi * 3)), 16).toDouble();
      if (fl > 0.02) {
        final bx = bounds.left + bounds.width * (0.3 + 0.4 * ((glow * 3).floor() % 2));
        final bolt = Path()..moveTo(bx, bounds.top);
        var bo = Offset(bx, bounds.top);
        final br = Random((glow * 3).floor() + 1);
        while (bo.dy < bounds.bottom) {
          bo += Offset((br.nextDouble() - 0.5) * cell * 0.9, cell * 0.7);
          bolt.lineTo(bo.dx, bo.dy);
        }
        canvas.drawPath(bolt, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = const Color(0xFFFFF6B0).withValues(alpha: fl * 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawPath(bolt, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.white.withValues(alpha: fl));
        canvas.drawRect(bounds, Paint()..color = Colors.white.withValues(alpha: fl * 0.12));
      }
    } else if (theme.kind == BoardKind.honey) {
      final hr = cell * 0.55;
      var row = 0;
      for (var y = bounds.top - hr; y < bounds.bottom + hr; y += hr * 1.5) {
        for (var x = bounds.left - hr + (row.isOdd ? hr * 0.87 : 0); x < bounds.right + hr; x += hr * 1.74) {
          final hex = Path();
          for (var k = 0; k < 6; k++) {
            final a = k * pi / 3 + pi / 6;
            final pt = Offset(x + cos(a) * hr, y + sin(a) * hr);
            k == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
          }
          hex.close();
          final sh = 0.5 + 0.5 * sin(glow * 2 * pi + x * 0.03 + y * 0.04);
          canvas.drawPath(hex, Paint()..color = const Color(0xFFFFF0B0).withValues(alpha: 0.08 + 0.14 * sh));
          canvas.drawPath(hex, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = const Color(0xFF8A5410).withValues(alpha: 0.5));
        }
        row++;
      }
    } else if (theme.kind == BoardKind.jade) {
      final vr = Random(13);
      for (var i = 0; i < 9; i++) {
        var o = Offset(bounds.left + vr.nextDouble() * bounds.width, bounds.top + vr.nextDouble() * bounds.height);
        final p = Path()..moveTo(o.dx, o.dy);
        for (var k = 0; k < 6; k++) {
          o += Offset((vr.nextDouble() - 0.4) * cell * 0.9, (vr.nextDouble() - 0.3) * cell * 0.8);
          p.lineTo(o.dx, o.dy);
        }
        final pl = 0.5 + 0.5 * sin(glow * 2 * pi + i);
        canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = theme.accent.withValues(alpha: 0.12 + 0.14 * pl)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = theme.accent.withValues(alpha: 0.5 + 0.3 * pl));
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
    final moss = Paint()..color = theme.moss.withValues(alpha: theme.kind == BoardKind.stone ? 0.7 : theme.kind == BoardKind.wood ? 0.5 : const [BoardKind.pitch, BoardKind.neon, BoardKind.sakura, BoardKind.galaxy, BoardKind.ocean, BoardKind.candy, BoardKind.aurora, BoardKind.clockwork, BoardKind.circuit, BoardKind.pond, BoardKind.storm, BoardKind.honey, BoardKind.jade].contains(theme.kind) ? 0.0 : 0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
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
    required this.reward,
    required this.challengeBonus,
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
  final int reward;
  final bool challengeBonus;
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
          Text(v == 0 && !bold ? '-' : (bold || v < 0 ? '$v' : '+$v'),
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
        title = '${worldById(id).name} stage';
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
            if (score.undoPenalty > 0) _row('Undos (${score.undoPenalty ~/ ScoreBreakdown.undoCost})', -score.undoPenalty),
            Divider(color: Colors.white.withValues(alpha: 0.18), height: 18),
            _row('Level score', score.total, bold: true),
            if (widget.cleared) Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.reward > 0 ? '+${widget.reward} points${widget.challengeBonus ? ' (incl. daily bonus)' : ''}' : 'No new points: beat your stars for more',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.reward > 0 ? lantern : Colors.white54),
              ),
            ),
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
