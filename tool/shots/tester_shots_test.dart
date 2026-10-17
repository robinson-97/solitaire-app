// ignore_for_file: invalid_use_of_visible_for_testing_member, avoid_print
// A fresh install played like a tester, with screenshots of what the player sees.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/board_def.dart';
import 'package:hopstone/game/levels_data.dart';
import 'package:hopstone/main.dart';
import 'package:hopstone/storage.dart';
import 'package:hopstone/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../verify_levels_test.dart' show solve;

const _out = String.fromEnvironment('OUT', defaultValue: '/tmp/shots');

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final l = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await l.load();
}

void main() {
  testWidgets('fresh install walk-through', (t) async {
    await _font('Nunito', 'assets/fonts/Nunito-Regular.ttf');
    await _font('MaterialIcons', '/opt/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    Directory(_out).createSync(recursive: true);
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({'unlock_all': false});
    final s = await Storage.open();
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(key: key, child: HopstoneApp(storage: s)));
    await t.pump(const Duration(milliseconds: 600));

    Future<void> shot(String name) async {
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.0);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    await shot('t1_first_launch');
    // intro screen (first launch): continue until the home screen
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 600));
    await shot('t1_intro_1');
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 600));
    await shot('t1_intro_2');
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 600));
    await shot('t2_home');
    await t.tap(find.text('Collection'));
    await t.pump(const Duration(milliseconds: 500));
    await shot('t3_collection_pegs');
    await t.tap(find.text('Boards'));
    await t.pump(const Duration(milliseconds: 500));
    await shot('t4_collection_boards');
    await t.tap(find.text('Settings'));
    await t.pump(const Duration(milliseconds: 500));
    await shot('t5_settings');
    await t.tap(find.text('Play'));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('All levels'));
    await t.pump(const Duration(milliseconds: 800));
    await shot('t6_all_levels');
    print('done');
  });

  testWidgets('result dialogs', (t) async {
    await _font('Nunito', 'assets/fonts/Nunito-Regular.ttf');
    await _font('MaterialIcons', '/opt/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({'seen_intro': true, 'unlock_all': false});
    final s = await Storage.open();
    final key = GlobalKey();
    final level = handmadeLevels.firstWhere((l) => l.id == 'sapling-3');
    await t.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(home: GameScreen(board: level, storage: s))));
    await t.pump(const Duration(seconds: 1));
    Future<Offset> hole(Pos p) async {
      final board = find.byKey(const ValueKey('board'));
      final area = t.getSize(find.ancestor(of: board, matching: find.byType(Center)).first);
      return t.getTopLeft(board) + TiltedBoard.fit(level, area.width, area.height).centerOf(p);
    }

    Future<void> shot(String name) async {
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.0);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    final sol = solve(level)!;
    // one wasted undo, then win
    await t.tapAt(await hole(sol.first.$1));
    await t.pump(const Duration(milliseconds: 150));
    await t.tapAt(await hole(sol.first.$3));
    await t.pump(const Duration(milliseconds: 900));
    await shot('t7_mid_game');
    await t.tap(find.textContaining('Undo  -30'));
    await t.pump(const Duration(milliseconds: 900));
    for (final (f, _, to) in sol) {
      await t.tapAt(await hole(f));
      await t.pump(const Duration(milliseconds: 150));
      await t.tapAt(await hole(to));
      await t.pump(const Duration(milliseconds: 900));
    }
    await t.pump(const Duration(seconds: 3));
    await shot('t8_win_with_undo');
  });
}
