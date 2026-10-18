// ignore_for_file: invalid_use_of_visible_for_testing_member
// Phone screenshots for the Play Store (1080x2160):
//   flutter test tool/shots/store_shots_test.dart --no-test-assets --dart-define=OUT=store/screenshots
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/board_def.dart';
import 'package:hopstone/game/peg_draw.dart';
import 'package:hopstone/game/worlds.dart';
import 'package:hopstone/main.dart';
import 'package:hopstone/storage.dart';
import 'package:hopstone/ui/collection_screen.dart';
import 'package:hopstone/ui/draw_reveal.dart';
import 'package:hopstone/ui/game_screen.dart';
import 'package:hopstone/ui/peg_view.dart';
import 'package:hopstone/ui/styles.dart';
import 'package:hopstone/ui/theme.dart';
import 'package:hopstone/ui/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../verify_levels_test.dart' show solve;

const _out = String.fromEnvironment('OUT', defaultValue: 'store/screenshots');

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final l = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await l.load();
}

void main() {
  Future<void> setup(WidgetTester t) async {
    await _font('Nunito', 'assets/fonts/Nunito-Regular.ttf');
    await _font('Nunito', 'assets/fonts/Nunito-Bold.ttf');
    await _font('MaterialIcons', '/opt/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    Directory(_out).createSync(recursive: true);
    t.view.physicalSize = const Size(1080, 2160);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<void> shot(WidgetTester t, GlobalKey key, String name) => t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.0);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });

  final progress = {
    'seen_intro': true,
    'unlock_all': false,
    'total_points': 6200,
    'spent_points': 2500,
    'owned_pegs': ['pearl', 'magma', 'galaxy', 'koi', 'frost', 'cookie', 'soccer', 'disco'],
    'owned_boards': ['crystal', 'aurora', 'lava'],
    'peg_theme': 'magma',
    'board_theme': 'midnight',
    for (final l in worlds.first.levels.take(6)) ...{'solved_${l.id}': true, 'stars_${l.id}': 3},
  };

  testWidgets('home and collection', (t) async {
    await setup(t);
    SharedPreferences.setMockInitialValues(progress);
    final s = await Storage.open();
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(key: key, child: HopstoneApp(storage: s)));
    await t.pump(const Duration(milliseconds: 600));
    await shot(t, key, '1_home');
    await t.tap(find.text('Collection'));
    await t.pump(const Duration(milliseconds: 600));
    await shot(t, key, '3_collection_pegs');
    await t.tap(find.text('Boards'));
    await t.pump(const Duration(milliseconds: 600));
    await shot(t, key, '4_collection_boards');
  });

  testWidgets('a game in progress', (t) async {
    await setup(t);
    SharedPreferences.setMockInitialValues(progress);
    final s = await Storage.open();
    final key = GlobalKey();
    final level = worlds.first.levels[6];
    await t.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(theme: buildTheme(), home: GameScreen(board: level, storage: s))));
    await t.pump(const Duration(seconds: 1));
    Future<Offset> hole(Pos p) async {
      final board = find.byKey(const ValueKey('board'));
      final area = t.getSize(find.ancestor(of: board, matching: find.byType(Center)).first);
      return t.getTopLeft(board) + TiltedBoard.fit(level, area.width, area.height).centerOf(p);
    }

    final sol = solve(level)!;
    for (final (f, _, to) in sol.take(2)) {
      await t.tapAt(await hole(f));
      await t.pump(const Duration(milliseconds: 150));
      await t.tapAt(await hole(to));
      await t.pump(const Duration(milliseconds: 1000));
    }
    await t.tapAt(await hole(sol[2].$1));
    await t.pump(const Duration(milliseconds: 400));
    await shot(t, key, '2_game');
  });

  testWidgets('the draw reel', (t) async {
    await setup(t);
    final key = GlobalKey();
    const win = 'galaxy';
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: DrawReveal(
            items: [for (final p in pegThemes) RevealItem(p.id, p.name, rarityOf(p.id), (c, size) => paintPeg(c, size, p, 0.3))],
            winnerId: win,
            live: (g) => PegView(theme: pegThemeById(win), glow: g),
            color: rarityColor(rarityOf(win)),
            left: 24,
            onEquip: () {},
            onClose: () {},
          ),
        ),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 3600));
    await shot(t, key, '5_draw');
    await t.pump(const Duration(milliseconds: 6500));
    await shot(t, key, '5b_draw_result');
  });
}
