import 'package:flutter/foundation.dart';
import 'board_def.dart';

enum HintStatus { move, stuck, unknown }

/// Result of a hint search: the move to make, or why there is none.
class HintResult {
  const HintResult(this.status, [this.from, this.over, this.to]);
  final HintStatus status;
  final Pos? from, over, to;
}

/// Searches (off the UI thread) for a move that keeps the level winnable.
/// It first looks for a way to finish on one peg and, if there is none, for a
/// way to finish with [goal] pegs or fewer (what the level asks for).
Future<HintResult> findHint(BoardDef b, Set<Pos> pegs, {required int goal}) async {
  final args = <String, Object>{
    'holes': [for (final h in b.holes) [h.row, h.col]],
    'dirs': [for (final d in b.dirs) [d.$1, d.$2]],
    'pegs': [for (final p in pegs) [p.row, p.col]],
    'goal': goal,
  };
  final r = await compute(_search, args);
  if (r == null) return const HintResult(HintStatus.stuck);
  if (r.isEmpty) return const HintResult(HintStatus.unknown);
  return HintResult(HintStatus.move, Pos(r[0], r[1]), Pos(r[2], r[3]), Pos(r[4], r[5]));
}

/// null = proven stuck, empty = ran out of time, else [fr, fc, or, oc, tr, tc].
List<int>? _search(Map<String, Object> a) {
  final holes = [for (final h in a['holes']! as List) Pos((h as List)[0] as int, h[1] as int)];
  final dirs = [for (final d in a['dirs']! as List) ((d as List)[0] as int, d[1] as int)];
  final pegs = [for (final p in a['pegs']! as List) Pos((p as List)[0] as int, p[1] as int)];
  final goal = a['goal']! as int;
  if (holes.length > 62) return const [];
  final idx = {for (var i = 0; i < holes.length; i++) holes[i]: i};
  final moves = <List<int>>[];
  final nb = List.filled(holes.length, 0);
  for (final p in holes) {
    for (final (dr, dc) in dirs) {
      final o = Pos(p.row + dr, p.col + dc), t = Pos(p.row + 2 * dr, p.col + 2 * dc);
      if (idx.containsKey(o)) nb[idx[p]!] |= 1 << idx[o]!;
      if (idx.containsKey(o) && idx.containsKey(t)) moves.add([idx[p]!, idx[o]!, idx[t]!]);
    }
  }
  var start = 0;
  for (final p in pegs) {
    start |= 1 << idx[p]!;
  }
  int lonely(int s) {
    var c = 0;
    for (var i = 0; i < holes.length; i++) {
      if ((s >> i) & 1 == 1 && (nb[i] & s) == 0) c++;
    }
    return c;
  }

  // 1 = finish on one peg, then the level goal
  var timedOut = false;
  for (final target in {1, goal}) {
    final seen = <int>{};
    var nodes = 0;
    List<int>? first;
    bool go(int s, int n, bool top) {
      if (n <= target) return true;
      if (++nodes > 2500000) {
        timedOut = true;
        return false;
      }
      if (!seen.add(s)) return false;
      final next = <(int, int, List<int>)>[];
      for (final m in moves) {
        if ((s >> m[0]) & 1 == 1 && (s >> m[1]) & 1 == 1 && (s >> m[2]) & 1 == 0) {
          final ns = (s ^ (1 << m[0]) ^ (1 << m[1])) | (1 << m[2]);
          next.add((lonely(ns), ns, m));
        }
      }
      next.sort((x, y) => x.$1 - y.$1);
      for (final (_, ns, m) in next) {
        if (go(ns, n - 1, false)) {
          if (top) first = m;
          return true;
        }
        if (timedOut) return false;
      }
      return false;
    }

    final n0 = pegs.length;
    if (n0 <= target) continue;
    timedOut = false;
    if (go(start, n0, true) && first != null) {
      final m = first!;
      final f = holes[m[0]], o = holes[m[1]], t = holes[m[2]];
      return [f.row, f.col, o.row, o.col, t.row, t.col];
    }
    if (timedOut && target == 1) {
      // could not decide within the budget: still try the easier goal below
      continue;
    }
  }
  return timedOut ? const [] : null;
}
