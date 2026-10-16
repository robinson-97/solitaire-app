// All peg themes in one picture:  flutter test tool/shots/pegs_shot_test.dart --no-test-assets --dart-define=OUT=/tmp/shots
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/ui/peg_view.dart';
import 'package:hopstone/ui/styles.dart';

const _out = String.fromEnvironment('OUT', defaultValue: '/tmp/shots');

void main() {
  testWidgets('pegs sheet', (t) async {
    Directory(_out).createSync(recursive: true);
    t.view.physicalSize = const Size(1200, 1500);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF7A5A3C),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(spacing: 14, runSpacing: 14, children: [
              for (final p in pegThemes) SizedBox(width: 78, height: 78, child: PegView(theme: p, glow: 0.3)),
              SizedBox(width: 78, height: 78, child: PegView(theme: pegThemes.first, glow: 0.3, selected: true)),
            ]),
          ),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/pegs.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
