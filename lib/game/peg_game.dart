/// Core rules of English peg solitaire (33 holes, 32 pegs). No UI code here.
library;

import 'board_def.dart';

class Move {
  const Move(this.from, this.over, this.to);
  final Pos from;
  final Pos over;
  final Pos to;
}

class PegGame {
  PegGame(this.board) : _pegs = {...board.pegs};

  final BoardDef board;
  Set<Pos> _pegs;
  final List<Move> _history = [];
  int undosUsed = 0;
  DateTime? firstJumpAt;
  DateTime? finishedAt;

  Set<Pos> get pegs => Set.unmodifiable(_pegs);
  int get pegsLeft => _pegs.length;
  int get jumps => _history.length;
  bool get canUndo => _history.isNotEmpty;
  bool get inProgress => _history.isNotEmpty;
  bool hasPeg(Pos p) => _pegs.contains(p);
  bool isEmptyHole(Pos p) => board.holes.contains(p) && !_pegs.contains(p);

  /// All legal jumps for the peg at [from] (empty if none).
  List<Move> movesFrom(Pos from) {
    if (!hasPeg(from)) return const [];
    final result = <Move>[];
    for (final (dr, dc) in board.dirs) {
      final over = Pos(from.row + dr, from.col + dc);
      final to = Pos(from.row + 2 * dr, from.col + 2 * dc);
      if (hasPeg(over) && isEmptyHole(to)) result.add(Move(from, over, to));
    }
    return result;
  }

  List<Move> get allMoves => [for (final p in _pegs) ...movesFrom(p)];

  bool get isOver => pegsLeft == 1 || allMoves.isEmpty;

  /// Performs [m]; [now] is injectable for tests.
  void apply(Move m, {DateTime? now}) {
    now ??= DateTime.now();
    _pegs = {..._pegs}
      ..remove(m.from)
      ..remove(m.over)
      ..add(m.to);
    _history.add(m);
    firstJumpAt ??= now;
    if (isOver) finishedAt = now;
  }

  /// Takes back the last jump. Returns it, or null if nothing to undo.
  Move? undo() {
    if (_history.isEmpty) return null;
    final m = _history.removeLast();
    _pegs = {..._pegs}
      ..remove(m.to)
      ..add(m.from)
      ..add(m.over);
    undosUsed++;
    finishedAt = null;
    if (_history.isEmpty) firstJumpAt = null; // timer restarts on first jump
    return m;
  }

  int secondsElapsed({DateTime? now}) {
    final start = firstJumpAt;
    if (start == null) return 0;
    return (finishedAt ?? now ?? DateTime.now()).difference(start).inSeconds;
  }

  ScoreBreakdown score({DateTime? now}) => ScoreBreakdown.compute(
        pegsLeft: pegsLeft,
        startPegs: board.startPegs,
        lastPegInCenter:
            pegsLeft == 1 && board.center != null && hasPeg(board.center!),
        seconds: secondsElapsed(now: now),
        undos: undosUsed,
      );
}

enum Medal { none, bronze, silver, gold }

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.pegsLeft,
    required this.jumpPoints,
    required this.pegsLeftBonus,
    required this.centerBonus,
    required this.speedBonus,
    required this.cleanBonus,
  });

  final int pegsLeft;
  final int jumpPoints;
  final int pegsLeftBonus;
  final int centerBonus;
  final int speedBonus;
  final int cleanBonus;

  int get total =>
      jumpPoints + pegsLeftBonus + centerBonus + speedBonus + cleanBonus;

  static const _pegsLeftBonus = {1: 250, 2: 120, 3: 60, 4: 30};

  factory ScoreBreakdown.compute({
    required int pegsLeft,
    int startPegs = 32,
    required bool lastPegInCenter,
    required int seconds,
    required int undos,
  }) {
    final jumps = startPegs - pegsLeft;
    final bonuses = pegsLeft <= 4; // bonuses only with 4 or fewer pegs left
    return ScoreBreakdown(
      pegsLeft: pegsLeft,
      jumpPoints: jumps * 10,
      pegsLeftBonus: bonuses ? (_pegsLeftBonus[pegsLeft] ?? 0) : 0,
      centerBonus: bonuses && pegsLeft == 1 && lastPegInCenter ? 100 : 0,
      speedBonus: bonuses ? (150 - seconds).clamp(0, 150) : 0,
      cleanBonus: bonuses && undos == 0 ? 40 : 0,
    );
  }

  String get rank => switch (pegsLeft) {
        1 => 'Genius',
        2 => 'Expert',
        3 => 'Clever',
        4 => 'Skilled',
        _ => 'Apprentice',
      };

  Medal get medal => medalFor(total);

  static Medal medalFor(int score) {
    if (score >= 700) return Medal.gold;
    if (score >= 500) return Medal.silver;
    if (score >= 300) return Medal.bronze;
    return Medal.none;
  }
}
