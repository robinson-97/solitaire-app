// Landing effects of every kind at a few moments:
//   flutter test tool/shots/fx_shot_test.dart --no-test-assets --dart-define=OUT=/tmp/shots
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/ui/fx.dart';
import 'package:hopstone/ui/styles.dart';

const _out = String.fromEnvironment('OUT', defaultValue: '/tmp/shots');

class _P extends CustomPainter {
  _P(this.k, this.v, this.color);
  final FxKind k;
  final double v;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    c.drawCircle(Offset(s.width / 2, s.height * 0.72), 18, Paint()..color = const Color(0xFF0A0E2A));
    paintLanding(c, k, Offset(s.width / 2, s.height * 0.72), 36, v, color, ripple: false);
  }

  @override
  bool shouldRepaint(_P o) => true;
}

void main() {
  testWidgets('fx sheet', (t) async {
    Directory(_out).createSync(recursive: true);
    final kinds = [for (final k in FxKind.values) if (k != FxKind.none) k];
    const vs = [0.12, 0.3, 0.55, 0.8];
    final color = {for (final p in pegThemes) p.fx: p.fxColor ?? (p.glowAlpha > 0 ? p.glow : const Color(0xFF35F0FF))};
    t.view.physicalSize = Size(vs.length * 150.0 * 2, kinds.length * 150.0 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF151A3A),
          child: Column(children: [
            for (final k in kinds)
              Row(children: [
                for (final v in vs) SizedBox(width: 150, height: 150, child: CustomPaint(painter: _P(k, v, color[k] ?? const Color(0xFF35F0FF)))),
              ]),
          ]),
        ),
      ),
    ));
    await t.pump();
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1.0);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/fx.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
    stdout.writeln(kinds.map((k) => k.name).join(','));
  });
}
