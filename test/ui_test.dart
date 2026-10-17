import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/peg_draw.dart';
import 'package:hopstone/game/rewards.dart';
import 'package:hopstone/ui/styles.dart';
import 'package:hopstone/game/unlocks.dart';
import 'package:hopstone/game/worlds.dart';
import 'package:hopstone/main.dart';
import 'package:hopstone/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Storage> _storage([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues({'unlock_all': false, ...values});
  return Storage.open();
}

void _bigScreen(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('first launch shows the short explanation, then world 1', (t) async {
    _bigScreen(t);
    await t.pumpWidget(HopstoneApp(storage: await _storage()));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Jump to clear'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Enchanted Forest'), findsOneWidget);
    expect(find.text('Play level 1'), findsOneWidget);
  });

  testWidgets('a level opens from the grid and shows its goal', (t) async {
    _bigScreen(t);
    await t.pumpWidget(HopstoneApp(storage: await _storage({'seen_intro': true})));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Play level 1'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('PEGS'), findsOneWidget);
    expect(find.text('Leave just 1 peg'), findsOneWidget);
  });

  test('stages unlock with stars in the previous stage', () async {
    final s = await _storage();
    final u = Unlocks(s);
    expect(u.worldUnlocked(worlds[1]), isFalse);
    // 19 levels with 2 stars is not enough (38 < 40) ...
    for (final l in worlds[0].levels.take(19)) {
      await s.markSolved(l.id);
      await s.submitStars(l.id, 2);
    }
    expect(u.worldUnlocked(worlds[1]), isFalse);
    // ... one more level with 2 stars is (40)
    await s.submitStars(worlds[0].levels.last.id, 2);
    expect(u.worldUnlocked(worlds[1]), isTrue);
    expect(u.worldUnlocked(worlds[2]), isFalse);
  });

  test('a level pays once; only better stars pay the difference', () async {
    final s = await _storage();
    final b = worlds[0].levels.first;
    expect(await s.payLevel(b, 1), levelReward(b, 1));
    expect(await s.payLevel(b, 1), 0);
    expect(await s.payLevel(b, 3), levelReward(b, 3) - levelReward(b, 1));
    expect(await s.payLevel(b, 2), 0);
    expect(s.totalPoints, levelReward(b, 3));
    expect(levelReward(b, 3) > levelReward(b, 2) && levelReward(b, 2) > levelReward(b, 1), isTrue);
  });

  test('mystery pegs: drawn pegs are owned, rarity odds skip empty tiers', () async {
    final s = await _storage();
    final u = Unlocks(s);
    expect(u.pegUnlocked('acorn'), isTrue);
    expect(u.pegUnlocked('ember'), isFalse);
    final ids = [for (final t in pegThemes) t.id];
    final rng = Random(1);
    final owned = <String>{};
    for (var i = 0; i < ids.length; i++) {
      final id = rollPeg(ids, owned, rng)!;
      expect(owned.add(id), isTrue);
    }
    expect(rollPeg(ids, owned, rng), isNull);
    await s.addPoints(2000);
    await s.spendPoints(drawCost);
    expect(s.points, 2000 - drawCost);
    await s.addOwnedPeg('ember');
    expect(u.pegUnlocked('ember'), isTrue);
    expect(u.snapshot().contains('peg:ember'), isTrue);
  });
}
