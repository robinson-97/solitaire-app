import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/board_def.dart';
import 'game/rewards.dart';

/// Everything is saved locally on the device. No account, no network.
class Storage {
  Storage._(this._prefs);
  final SharedPreferences _prefs;

  /// Bumped whenever points change, so badges elsewhere can refresh.
  static final ValueNotifier<int> changed = ValueNotifier(0);

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
  Future<void> addPoints(int n) async {
    await _prefs.setInt('total_points', totalPoints + n);
    changed.value++;
  }

  /// Stars of this level that have already been paid out.
  int paidStars(String boardId) => _prefs.getInt('paid_$boardId') ?? 0;

  /// Pays the level reward for [stars] (only the part not paid yet). Returns
  /// the points earned now.
  Future<int> payLevel(BoardDef b, int stars) async {
    final gain = levelReward(b, stars) - levelReward(b, paidStars(b.id));
    if (gain <= 0) return 0;
    await _prefs.setInt('paid_${b.id}', stars);
    await addPoints(gain);
    return gain;
  }

  // ---- daily gift & challenge (dates are local, "yyyy-mm-dd")
  String get lastGift => _prefs.getString('gift_date') ?? '';
  int get giftStreak => _prefs.getInt('gift_streak') ?? 0;
  Future<void> claimGift(String today, int streak) async {
    await _prefs.setString('gift_date', today);
    await _prefs.setInt('gift_streak', streak);
    await addPoints(dailyGift(streak));
  }

  String get lastChallenge => _prefs.getString('challenge_date') ?? '';
  Future<void> claimChallenge(String today) async {
    await _prefs.setString('challenge_date', today);
    await addPoints(dailyChallengeBonus);
  }

  bool get seenCollectionTip => _prefs.getBool('seen_collection_tip') ?? false;
  Future<void> setSeenCollectionTip() => _prefs.setBool('seen_collection_tip', true);

  int get spentPoints => _prefs.getInt('spent_points') ?? 0;

  /// Points available to spend on mystery pegs.
  int get points => totalPoints - spentPoints;
  Future<void> spendPoints(int n) async {
    await _prefs.setInt('spent_points', spentPoints + n);
    changed.value++;
  }

  Set<String> get ownedPegs => (_prefs.getStringList('owned_pegs') ?? const <String>[]).toSet();
  Future<void> addOwnedPeg(String id) => _prefs.setStringList('owned_pegs', {...ownedPegs, id}.toList());

  Set<String> get ownedBoards => (_prefs.getStringList('owned_boards') ?? const <String>[]).toSet();
  Future<void> addOwnedBoard(String id) => _prefs.setStringList('owned_boards', {...ownedBoards, id}.toList());

  bool get seenIntro => _prefs.getBool('seen_intro') ?? false;
  Future<void> setSeenIntro() => _prefs.setBool('seen_intro', true);

  /// Hidden test switch (no screen for it): stages open, draws and hints free.
  /// Test builds (built with TEST_MODE) start with everything open and free.
  static const _testBuild = bool.fromEnvironment('TEST_MODE');
  bool get unlockAll => _prefs.getBool('unlock_all') ?? _testBuild;
  Future<void> setUnlockAll(bool v) => _prefs.setBool('unlock_all', v);

  /// The one-time purchase that unlocks stage 4 and up.
  bool get fullVersion => _prefs.getBool('full_version') ?? false;
  Future<void> setFullVersion(bool v) async {
    await _prefs.setBool('full_version', v);
    changed.value++;
  }

  bool get sound => _prefs.getBool('sound') ?? true;
  Future<void> setSound(bool v) => _prefs.setBool('sound', v);

  bool get haptics => _prefs.getBool('haptics') ?? true;
  Future<void> setHaptics(bool v) => _prefs.setBool('haptics', v);

  String get pegTheme => _prefs.getString('peg_theme') ?? 'acorn';
  Future<void> setPegTheme(String id) => _prefs.setString('peg_theme', id);
  String get boardTheme => _prefs.getString('board_theme') ?? 'midnight';
  Future<void> setBoardTheme(String id) => _prefs.setString('board_theme', id);

  Future<void> resetAll() async {
    for (final k in _prefs.getKeys().toList()) {
      if (k.startsWith('best_') || k.startsWith('paid_') || k == 'gift_date' || k == 'gift_streak' || k == 'challenge_date' || k.startsWith('solved_') || k.startsWith('stars_') || k == 'total_points' || k == 'spent_points' || k == 'owned_pegs' || k == 'owned_boards') {
        await _prefs.remove(k);
      }
    }
    await setPegTheme('acorn');
    await setBoardTheme('midnight');
  }
}
