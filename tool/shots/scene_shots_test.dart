// Renders world scenes to PNG files for visual review. Run with e.g.
//   flutter test tool/shots/scene_shots_test.dart --dart-define=SCENES=forest,desert \
//     --dart-define=US=0.12,0.6 --dart-define=OUT=/tmp/shots
// (SCENES=all renders every world in the catalog.)
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/catalog_data.dart';
import 'package:hopstone/ui/scenes/scene_view.dart';

const _scenes = String.fromEnvironment('SCENES', defaultValue: 'forest');
const _out = String.fromEnvironment('OUT', defaultValue: '/tmp/shots');
const _us = String.fromEnvironment('US', defaultValue: '0.12');
final _w = double.parse(const String.fromEnvironment('W', defaultValue: '390'));
final _h = double.parse(const String.fromEnvironment('H', defaultValue: '844'));
final _ratio = double.parse(const String.fromEnvironment('RATIO', defaultValue: '2'));

void main() {
  testWidgets('render scenes', (tester) async {
    tester.view.physicalSize = Size(_w * _ratio, _h * _ratio);
    tester.view.devicePixelRatio = _ratio;
    addTearDown(tester.view.reset);
    Directory(_out).createSync(recursive: true);
    final ids = _scenes == 'all' ? [for (final w in worldCatalog) w.id] : _scenes.split(',');
    for (final id in ids) {
      for (final u in _us.split(',')) {
        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(key: key, child: SceneBackground(world: id, freezeAt: double.parse(u))),
        ));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: _ratio);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/${id}_u$u.png').writeAsBytesSync(data!.buffer.asUint8List());
        });
      }
    }
  });
}
