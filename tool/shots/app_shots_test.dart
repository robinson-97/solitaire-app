// ignore_for_file: invalid_use_of_visible_for_testing_member
// Screenshots of the real app screens over the animated world backgrounds.
//   flutter test tool/shots/app_shots_test.dart --no-test-assets --dart-define=OUT=/tmp/shots
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/worlds.dart';
import 'package:hopstone/main.dart';
import 'package:hopstone/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _out = String.fromEnvironment('OUT', defaultValue: '/tmp/shots');
const _world = int.fromEnvironment('WORLD', defaultValue: 0);

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final l = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await l.load();
}

void main() {
  testWidgets('app screens', (t) async {
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
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(key: key, child: HopstoneApp(storage: storage)));
    await t.pump(const Duration(milliseconds: 500));

    Future<void> shot(String name) async {
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.0);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    await shot('home_w0');
    await t.tap(find.text('Collection'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await shot('collection_pegs');
    await t.tap(find.textContaining('Draw'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Nice!'), findsOneWidget);
    await shot('draw_reveal');
    await t.tap(find.text('Nice!'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Stages'));
    await t.pump(const Duration(milliseconds: 400));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
    await t.pump(const Duration(milliseconds: 300));
    await shot('collection_worlds');
    await t.tap(find.text('Play'));
    await t.pump(const Duration(milliseconds: 400));
    // swipe through worlds with the chevrons (if requested)
    for (var i = 0; i < _world; i++) {
      final next = find.byIcon(Icons.chevron_right_rounded);
      if (next.evaluate().isNotEmpty) {
        await t.tap(next.first);
        await t.pump(const Duration(milliseconds: 900));
      }
    }
    if (_world > 0) await shot('home_w$_world');
    await t.tap(find.textContaining('Play level').first);
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 900));
    await shot('game_w$_world');
    expect(worlds.length, 20);
  });
}
