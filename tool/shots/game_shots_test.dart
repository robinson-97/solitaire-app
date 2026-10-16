// ignore_for_file: invalid_use_of_visible_for_testing_member
// How a world looks in real use: behind the game board, and as a collection card.
//   flutter test tool/shots/game_shots_test.dart --no-test-assets \
//     --dart-define=SCENES=forest,desert --dart-define=OUT=/tmp/shots
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/catalog_data.dart';
import 'package:hopstone/game/worlds.dart';
import 'package:hopstone/storage.dart';
import 'package:hopstone/ui/game_screen.dart';
import 'package:hopstone/ui/scenes/scene_view.dart';
import 'package:hopstone/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _scenes = String.fromEnvironment('SCENES', defaultValue: 'forest');
const _out = String.fromEnvironment('OUT', defaultValue: '/tmp/shots');

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final l = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await l.load();
}

void main() {
  testWidgets('game + card views', (t) async {
    await _font('Nunito', 'assets/fonts/Nunito-Regular.ttf');
    await _font('MaterialIcons', '/opt/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    Directory(_out).createSync(recursive: true);
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({'seen_intro': true, 'unlock_all': true});
    final storage = await Storage.open();
    final ids = _scenes == 'all' ? [for (final w in worldCatalog) w.id] : _scenes.split(',');

    Future<void> shot(GlobalKey key, String name, double ratio) async {
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: ratio);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    for (final id in ids) {
      final w = worldById(id);
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(), home: GameScreen(board: w.levels[1], storage: storage)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 900));
      await shot(key, '${id}_game', 1.0);

      final ck = GlobalKey();
      await t.pumpWidget(RepaintBoundary(
        key: ck,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 170, height: 236, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: SceneArt(id)))),
        ),
      ));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await t.pump(const Duration(milliseconds: 100));
      await shot(ck, '${id}_card', 2.0);
    }
  });
}
