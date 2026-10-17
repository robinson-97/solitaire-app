// Frames of the mystery-peg opening:
//   flutter test tool/shots/reveal_shot_test.dart --no-test-assets --dart-define=OUT=/tmp/shots
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/peg_draw.dart';
import 'package:hopstone/ui/collection_screen.dart';
import 'package:hopstone/ui/draw_reveal.dart';
import 'package:hopstone/ui/styles.dart';

const _out = String.fromEnvironment('OUT', defaultValue: '/tmp/shots');
const _skip = bool.fromEnvironment('SKIP');
const _peg = String.fromEnvironment('PEG', defaultValue: 'magma');

void main() {
  testWidgets('reveal frames', (t) async {
    Directory(_out).createSync(recursive: true);
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    final r = rarityOf(_peg);
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: DrawReveal(theme: pegThemeById(_peg), rarity: r, color: rarityColor(r), onEquip: () {}, onClose: () {})),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await t.pump();
    var at = 0;
    for (final ms in [300, 1200, 2500, 4000, 6000, 7000, 7600, 9500]) {
      await t.pump(Duration(milliseconds: ms - at));
      if (_skip && ms == 1200) await t.tapAt(const Offset(200, 400));
      at = ms;
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/rev_$ms.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
  });
}
