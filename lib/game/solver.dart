import 'board_def.dart';

/// Depth-first search: can [start] be cleared down to a single peg?
bool canSolve(BoardDef b, Set<Pos> start, {int nodeLimit = 3000000}) {
  final seen = <String>{};
  var nodes = 0;
  String key(Set<Pos> s) =>
      (s.map((p) => p.row * 10 + p.col).toList()..sort()).join(',');
  bool go(Set<Pos> s) {
    if (s.length == 1) return true;
    if (++nodes > nodeLimit) return false;
    if (!seen.add(key(s))) return false;
    for (final p in s) {
      for (final (dr, dc) in b.dirs) {
        final over = Pos(p.row + dr, p.col + dc);
        final to = Pos(p.row + 2 * dr, p.col + 2 * dc);
        if (s.contains(over) && b.holes.contains(to) && !s.contains(to)) {
          if (go({...s}..remove(p)..remove(over)..add(to))) return true;
        }
      }
    }
    return false;
  }

  return go(start);
}
