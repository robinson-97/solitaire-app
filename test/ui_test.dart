import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/unlocks.dart';
import 'package:hopstone/game/worlds.dart';
import 'package:hopstone/main.dart';
import 'package:hopstone/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Storage> _storage([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return Storage.open();
}

void _bigScreen(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('worlds screen shows the first world; later worlds are locked', (t) async {
    _bigScreen(t);
    await t.pumpWidget(HopstoneApp(storage: await _storage()));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Glimmerwood'), findsOneWidget);
    expect(find.text('Enter world'), findsOneWidget);
  });

  testWidgets('entering a world and a level opens the game', (t) async {
    _bigScreen(t);
    await t.pumpWidget(HopstoneApp(storage: await _storage()));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Enter world'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Seedling'), findsOneWidget);
    await t.tap(find.text('1').first);
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('PEGS'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  test('worlds unlock by clearing the previous world', () async {
    final s = await _storage();
    final u = Unlocks(s);
    expect(u.worldUnlocked(worlds[1]), isFalse);
    for (final l in worlds[0].levels) {
      await s.markSolved(l.id);
    }
    expect(u.worldUnlocked(worlds[1]), isTrue);
    expect(u.worldUnlocked(worlds[2]), isFalse);
  });

  test('pegs unlock by score on their board', () async {
    final s = await _storage();
    final u = Unlocks(s);
    expect(u.pegUnlocked('ember'), isFalse);
    await s.submitScore('classic', 700);
    expect(u.pegUnlocked('ember'), isTrue);
    expect(u.pegUnlocked('moonstone'), isTrue);
    expect(u.snapshot().contains('peg:ember'), isTrue);
    expect(u.nextUnlock(), isNotNull);
  });
}
