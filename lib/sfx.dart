import 'package:audioplayers/audioplayers.dart';

/// Soft sound effects (synthesised, see tool/gen_sfx.py). Safe to call when
/// audio is unavailable: every call quietly does nothing.
class Sfx {
  static bool enabled = true;
  static final Map<String, AudioPlayer> _players = {};
  static const names = ['select', 'jump', 'invalid', 'undo', 'win', 'end', 'unlock'];

  static Future<void> init() async {
    for (final n in names) {
      try {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource('sfx/$n.wav'));
        await p.setVolume(0.8);
        _players[n] = p;
      } catch (_) {}
    }
  }

  static Future<void> play(String name) async {
    if (!enabled) return;
    final p = _players[name];
    if (p == null) return;
    try {
      await p.stop();
      await p.resume();
    } catch (_) {}
  }
}
