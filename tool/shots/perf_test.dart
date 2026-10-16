// Rough cost check for world scenes (Dart-side recording time, JIT, so real
// phones are several times faster). Live layers should stay under ~3 ms/frame here.
//   flutter test tool/shots/perf_test.dart --no-test-assets --dart-define=SCENES=forest
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:hopstone/game/catalog_data.dart';
import 'package:hopstone/ui/scenes/kit.dart';
import 'package:hopstone/ui/scenes/registry.dart';

const _scenes = String.fromEnvironment('SCENES', defaultValue: 'all');

void main() {
  test('scene cost', () {
    const size = ui.Size(390, 844);
    final ids = _scenes == 'all' ? [for (final w in worldCatalog) w.id] : _scenes.split(',');
    for (final id in ids) {
      final spec = sceneFor(id);
      var liveTotal = 0.0, stillTotal = 0.0;
      final lines = <String>[];
      for (var i = 0; i < spec.layers.length; i++) {
        final l = spec.layers[i];
        if (l.live != null) {
          final sw = Stopwatch()..start();
          const frames = 120;
          for (var f = 0; f < frames; f++) {
            final rec = ui.PictureRecorder();
            l.live!(ui.Canvas(rec), size, Clock(f / frames));
            rec.endRecording().dispose();
          }
          final ms = sw.elapsedMicroseconds / 1000 / frames;
          liveTotal += ms;
          lines.add('  layer $i live  ${ms.toStringAsFixed(2)} ms/frame');
        } else {
          final sw = Stopwatch()..start();
          final rec = ui.PictureRecorder();
          l.still!(ui.Canvas(rec), size);
          final pic = rec.endRecording();
          final ms = sw.elapsedMicroseconds / 1000;
          pic.dispose();
          stillTotal += ms;
          lines.add('  layer $i still ${ms.toStringAsFixed(1)} ms once${l.moves ? ' (moves)' : ''}');
        }
      }
      // ignore: avoid_print
      print('$id: live ${liveTotal.toStringAsFixed(2)} ms/frame, still ${stillTotal.toStringAsFixed(0)} ms once, ${spec.layers.length} layers\n${lines.join('\n')}');
    }
  });
}
