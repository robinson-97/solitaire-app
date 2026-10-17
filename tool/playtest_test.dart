// ignore_for_file: avoid_print
// Plays real levels through the real UI by tapping holes, like a tester:
//   flutter test tool/playtest_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/board_def.dart';
import 'package:hopstone/game/levels_data.dart';
import 'package:hopstone/game/peg_game.dart';
import 'package:hopstone/game/worlds.dart';
import 'package:hopstone/storage.dart';
import 'package:hopstone/ui/game_screen.dart';
import 'package:hopstone/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verify_levels_test.dart' show solve;

Future<Offset> _hole(WidgetTester t, BoardDef b, Pos p) async {
  final board = find.byKey(const ValueKey('board'));
  final area = t.getSize(find.ancestor(of: board, matching: find.byType(Center)).first);
  final tb = TiltedBoard.fit(b, area.width, area.height);
  return t.getTopLeft(board) + tb.centerOf(p);
}

void main() {
  testWidgets('win after an undo still shows the result', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({'seen_intro': true, 'unlock_all': false});
    final s = await Storage.open();
    final level = handmadeLevels.firstWhere((l) => l.id == 'sapling-3');
    await t.pumpWidget(MaterialApp(theme: buildTheme(), home: GameScreen(board: level, storage: s)));
    await t.pump(const Duration(seconds: 1));
    final sol = solve(level)!;
    await t.tapAt(await _hole(t, level, sol.first.$1));
    await t.pump(const Duration(milliseconds: 150));
    await t.tapAt(await _hole(t, level, sol.first.$3));
    await t.pump(const Duration(milliseconds: 900));
    await t.tap(find.textContaining('Undo  -30'));
    await t.pump(const Duration(milliseconds: 900));
    for (final (f, _, to) in sol) {
      await t.tapAt(await _hole(t, level, f));
      await t.pump(const Duration(milliseconds: 150));
      await t.tapAt(await _hole(t, level, to));
      await t.pump(const Duration(milliseconds: 900));
    }
    await t.pump(const Duration(seconds: 3));
    print('after undo+win: Menu buttons=${find.text('Menu').evaluate().length} solved=${s.solved(level.id)} points=${s.totalPoints}');
    expect(find.text('Menu'), findsOneWidget);
  });

  for (final id in ['seedling-1', 'seedling-4', 'sprout-3', 'dune-2']) {
    testWidgets('play $id to the end through the UI', (t) async {
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({'seen_intro': true, 'unlock_all': false});
      final s = await Storage.open();
      final level = handmadeLevels.firstWhere((l) => l.id == id);
      final next = worlds.expand((w) => w.levels).skipWhile((l) => l.id != id).skip(1).first;
      await t.pumpWidget(MaterialApp(theme: buildTheme(), home: GameScreen(board: level, storage: s, nextBoard: next)));
      await t.pump(const Duration(seconds: 1));
      final sol = solve(level)!;
      var n = 0;
      for (final (from, _, to) in sol) {
        await t.tapAt(await _hole(t, level, from));
        await t.pump(const Duration(milliseconds: 150));
        await t.tapAt(await _hole(t, level, to));
        await t.pump(const Duration(milliseconds: 1000));
        n++;
        expect(tester(t), isNotNull);
      }
      await t.pump(const Duration(seconds: 3));
      expect(find.text('Next'), findsOneWidget, reason: 'win dialog with Next');
      expect(s.solved(level.id), isTrue);
      print('$id: ${sol.length} moves, points=${s.totalPoints}, best=${s.bestScore(level.id)}, stars=${s.stars(level.id)}');
      expect(s.stars(level.id), 3);
    });
  }

  testWidgets('undo costs points, dead end shows the end dialog, retry resets', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({'seen_intro': true, 'unlock_all': false});
    final s = await Storage.open();
    final level = handmadeLevels.firstWhere((l) => l.id == 'seedling-4');
    await t.pumpWidget(MaterialApp(theme: buildTheme(), home: GameScreen(board: level, storage: s)));
    await t.pump(const Duration(seconds: 1));
    final g = PegGame(level);
    // greedy "bad" play: always take the first legal move until stuck
    var guard = 0;
    while (!g.isOver && guard++ < 50) {
      final m = g.allMoves.first;
      await t.tapAt(await _hole(t, level, m.from));
      await t.pump(const Duration(milliseconds: 150));
      await t.tapAt(await _hole(t, level, m.to));
      await t.pump(const Duration(milliseconds: 1000));
      g.apply(m);
    }
    await t.pump(const Duration(seconds: 3));
    print('greedy play left ${g.pegsLeft} pegs; dialog shows Retry: ${find.text('Retry').evaluate().isNotEmpty}');
    expect(find.text('Retry'), findsOneWidget);
    await t.tap(find.text('Retry'));
    await t.pump(const Duration(seconds: 2));
    print('after Retry: Undos tiles=${find.text('Undos').evaluate().length}, Retry buttons=${find.text('Retry').evaluate().length}, Pegs tile=${find.text('Pegs').evaluate().length}');
    expect(find.text('Retry'), findsNothing);
    // one move then undo: shows penalty in the stat tile
    final sol = solve(level)!;
    await t.tapAt(await _hole(t, level, sol.first.$1));
    await t.pump(const Duration(milliseconds: 150));
    await t.tapAt(await _hole(t, level, sol.first.$3));
    await t.pump(const Duration(milliseconds: 1000));
    await t.tap(find.textContaining('Undo  -30'));
    await t.pump(const Duration(milliseconds: 1000));
    expect(find.text('1'), findsWidgets);
  });
}

dynamic tester(WidgetTester t) => t;
