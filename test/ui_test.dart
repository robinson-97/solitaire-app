import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/main.dart';
import 'package:hopstone/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home lists boards and a game opens with 32 pegs', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    await t.pumpWidget(HopstoneApp(storage: storage));
    expect(find.text('Hopstone'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Classic English'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Classic English'));
    await t.pump();
    await t.tap(find.text('Classic English'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Pegs'), findsOneWidget);
    expect(find.text('32'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('a level opens and shows its peg count', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    await t.pumpWidget(HopstoneApp(storage: storage));
    await t.scrollUntilVisible(find.text('Seedling'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('1').first);
    await t.pump();
    await t.tap(find.text('1').first);
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Seedling 1'), findsOneWidget);
  });
}
