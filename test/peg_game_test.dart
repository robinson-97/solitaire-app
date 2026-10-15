import 'package:flutter_test/flutter_test.dart';
import 'package:glimmerwood/game/peg_game.dart';

void main() {
  test('board has 33 holes and starts with 32 pegs, center empty', () {
    final g = PegGame();
    expect(Board.holes.length, 33);
    expect(g.pegsLeft, 32);
    expect(g.hasPeg(Board.center), isFalse);
  });

  test('opening position has exactly 4 moves, all into the center', () {
    final g = PegGame();
    expect(g.allMoves.length, 4);
    expect(g.allMoves.every((m) => m.to == Board.center), isTrue);
  });

  test('jump removes the jumped peg; undo restores and counts', () {
    final g = PegGame();
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
}
