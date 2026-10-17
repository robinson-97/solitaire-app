// Thorough check that every level is winnable and every unlock reachable:
//   flutter test tool/verify_levels_test.dart --timeout=none
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/board_def.dart';
import 'package:hopstone/game/levels_data.dart';
import 'package:hopstone/game/peg_game.dart';
import 'package:hopstone/game/unlocks.dart';
import 'package:hopstone/game/worlds.dart';

/// Bitmask DFS that tries moves leaving the fewest lonely pegs first.
/// Returns the winning move list or null.
List<(Pos, Pos, Pos)>? solve(BoardDef b, {int limit = 80000000}) {
  final holes = b.holes.toList();
  final idx = {for (var i = 0; i < holes.length; i++) holes[i]: i};
  final moves = <List<int>>[];
  final nb = List.filled(holes.length, 0);
  for (final p in holes) {
    for (final (dr, dc) in b.dirs) {
      final o = Pos(p.row + dr, p.col + dc), t = Pos(p.row + 2 * dr, p.col + 2 * dc);
      if (idx.containsKey(o)) nb[idx[p]!] |= 1 << idx[o]!;
      if (idx.containsKey(o) && idx.containsKey(t)) moves.add([idx[p]!, idx[o]!, idx[t]!]);
    }
  }
  var start = 0;
  for (final p in b.pegs) {
    start |= 1 << idx[p]!;
  }
  int lonely(int s) {
    var c = 0;
    for (var i = 0; i < holes.length; i++) {
      if ((s >> i) & 1 == 1 && (nb[i] & s) == 0) c++;
    }
    return c;
  }

  final seen = <int>{};
  var nodes = 0;
  final path = <List<int>>[];
  bool go(int s, int n) {
    if (n == 1) return true;
    if (++nodes > limit) return false;
    if (!seen.add(s)) return false;
    final next = <(int, int, List<int>)>[];
    for (final m in moves) {
      if ((s >> m[0]) & 1 == 1 && (s >> m[1]) & 1 == 1 && (s >> m[2]) & 1 == 0) {
        final ns = (s ^ (1 << m[0]) ^ (1 << m[1])) | (1 << m[2]);
        next.add((lonely(ns), ns, m));
      }
    }
    next.sort((a, b) => a.$1 - b.$1);
    for (final (_, ns, m) in next) {
      if (go(ns, n - 1)) {
        path.add(m);
        return true;
      }
    }
    return false;
  }

  if (holes.length > 62 || !go(start, b.pegs.length)) return null;
  return [for (final m in path.reversed) (holes[m[0]], holes[m[1]], holes[m[2]])];
}

void main() {
  test('every level can be played to one peg (replayed with the real rules)', () {
    final unsolved = <String>[];
    for (final l in handmadeLevels) {
      final sol = solve(l);
      if (sol == null) {
        unsolved.add(l.id);
        continue;
      }
      final g = PegGame(l);
      for (final (f, o, t) in sol) {
        final m = g.movesFrom(f).where((m) => m.to == t && m.over == o);
        expect(m, isNotEmpty, reason: '${l.id} illegal move in solution');
        g.apply(m.first);
      }
      expect(g.pegsLeft, 1, reason: l.id);
      expect(g.isOver, isTrue);
    }
    // ignore: avoid_print
    print('unsolved within limit: $unsolved');
    expect(unsolved, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 30)));

  test('every unlock needs a score that a one-peg win can reach', () {
    for (final e in boardRules.entries) {
      final b = boardById(e.value.boardId);
      // a clean 1-peg win in 40 s
      final best = ScoreBreakdown.compute(pegsLeft: 1, startPegs: b.startPegs, maxScore: b.maxScore, lastPegInCenter: false, seconds: 40, undos: 0).total;
      expect(e.value.minScore <= best, isTrue, reason: '${e.key}: needs ${e.value.minScore}, a good run gives $best');
    }
  });
}
