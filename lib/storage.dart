import 'package:shared_preferences/shared_preferences.dart';

/// Everything is saved locally on the device. No account, no network.
class Storage {
  Storage._(this._prefs);
  final SharedPreferences _prefs;

  static Future<Storage> open() async =>
      Storage._(await SharedPreferences.getInstance());

  int bestScore(String boardId) => _prefs.getInt('best_$boardId') ?? 0;

  /// Saves [score] if it beats the old best. Returns true when it did.
  Future<bool> submitScore(String boardId, int score) async {
    if (score <= bestScore(boardId)) return false;
    await _prefs.setInt('best_$boardId', score);
    return true;
  }

  /// 0 = not cleared, 1-3 = stars earned.
  int stars(String boardId) => _prefs.getInt('stars_$boardId') ?? 0;
  Future<void> submitStars(String boardId, int n) async {
    if (n > stars(boardId)) await _prefs.setInt('stars_$boardId', n);
  }

  bool solved(String boardId) => _prefs.getBool('solved_$boardId') ?? false;
  Future<void> markSolved(String boardId) => _prefs.setBool('solved_$boardId', true);

  int get totalPoints => _prefs.getInt('total_points') ?? 0;
  Future<void> addPoints(int n) =>
      _prefs.setInt('total_points', totalPoints + n);

  bool get seenIntro => _prefs.getBool('seen_intro') ?? false;
  Future<void> setSeenIntro() => _prefs.setBool('seen_intro', true);

  bool get haptics => _prefs.getBool('haptics') ?? true;
  Future<void> setHaptics(bool v) => _prefs.setBool('haptics', v);

  String get pegTheme => _prefs.getString('peg_theme') ?? 'acorn';
  Future<void> setPegTheme(String id) => _prefs.setString('peg_theme', id);
  String get boardTheme => _prefs.getString('board_theme') ?? 'oak';
  Future<void> setBoardTheme(String id) => _prefs.setString('board_theme', id);

  Future<void> resetAll() async {
    for (final k in _prefs.getKeys().toList()) {
      if (k.startsWith('best_') || k.startsWith('solved_') || k.startsWith('stars_') || k == 'total_points') {
        await _prefs.remove(k);
      }
    }
    await setPegTheme('acorn');
    await setBoardTheme('oak');
  }
}
