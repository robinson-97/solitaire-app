import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/board_def.dart';
import 'package:hopstone/game/levels_data.dart';
import 'package:hopstone/game/peg_game.dart';

void main() {
  test('board has 33 holes and starts with 32 pegs, center empty', () {
    final g = PegGame(classicBoard);
    expect(classicBoard.holes.length, 33);
    expect(g.pegsLeft, 32);
    expect(g.hasPeg(classicBoard.center!), isFalse);
  });

  test('opening position has exactly 4 moves, all into the center', () {
    final g = PegGame(classicBoard);
    expect(g.allMoves.length, 4);
    expect(g.allMoves.every((m) => m.to == classicBoard.center!), isTrue);
  });

  test('jump removes the jumped peg; undo restores and counts', () {
    final g = PegGame(classicBoard);
    final m = g.movesFrom(const Pos(1, 3)).single;
    g.apply(m);
    expect(g.pegsLeft, 31);
    expect(g.hasPeg(const Pos(2, 3)), isFalse);
    g.undo();
    expect(g.pegsLeft, 32);
    expect(g.undosUsed, 1);
    expect(g.firstJumpAt, isNull);
  });

  test('score: perfect game', () {
    final s = ScoreBreakdown.compute(
        pegsLeft: 1, lastPegInCenter: true, seconds: 60, undos: 0);
    expect(s.jumpPoints, 310);
    expect(s.total, 310 + 250 + 100 + 90 + 40);
    expect(s.rank, 'Genius');
    expect(s.medal, Medal.gold);
  });

  test('score: no bonuses above 4 pegs, speed never negative', () {
    final a = ScoreBreakdown.compute(
        pegsLeft: 5, lastPegInCenter: false, seconds: 10, undos: 0);
    expect(a.total, 270);
    expect(a.rank, 'Apprentice');
    final b = ScoreBreakdown.compute(
        pegsLeft: 4, lastPegInCenter: false, seconds: 999, undos: 2);
    expect(b.speedBonus, 0);
    expect(b.cleanBonus, 0);
    expect(b.total, 280 + 30);
  });

  test('medal thresholds', () {
    expect(ScoreBreakdown.medalFor(299), Medal.none);
    expect(ScoreBreakdown.medalFor(300), Medal.bronze);
    expect(ScoreBreakdown.medalFor(500), Medal.silver);
    expect(ScoreBreakdown.medalFor(700), Medal.gold);
  });
  test('every level starts with the promised peg count', () {
    for (final l in handmadeLevels) {
      expect(PegGame(l).pegsLeft, l.startPegs);
      expect(l.pegs.every(l.holes.contains), isTrue);
    }
    expect(PegGame(frenchBoard).pegsLeft, 36);
    expect(PegGame(triangleBoard).pegsLeft, 14);
  });

  test('triangle allows diagonal jumps', () {
    final g = PegGame(triangleBoard);
    expect(g.allMoves.length, 2);
    expect(g.allMoves.any((m) => m.from == const Pos(2, 0) && m.to == const Pos(0, 0)), isTrue);
  });
}
