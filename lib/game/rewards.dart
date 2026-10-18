import 'board_def.dart';

/// Points a level pays out. Paid once per level; replaying only pays the
/// difference when you improve your stars (1 star: cleared, 2: no undo,
/// 3: one peg left).
int levelReward(BoardDef b, int stars) {
  if (stars <= 0) return 0;
  final base = 60 + 8 * b.startPegs;
  const mult = [0.0, 1.0, 1.6, 2.4];
  return ((base * mult[stars.clamp(0, 3)]) / 10).round() * 10;
}

/// Hints cost this many points.
const hintCost = 50;

/// Daily gift: base points plus a bonus per streak day (up to 6 extra days).
int dailyGift(int streak) => 100 + 50 * (streak.clamp(1, 7) - 1);

/// Extra points for clearing today's challenge level.
const dailyChallengeBonus = 200;

/// Local calendar day as "yyyy-mm-dd".
String todayKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String yesterdayKey([DateTime? now]) => todayKey((now ?? DateTime.now()).subtract(const Duration(days: 1)));
