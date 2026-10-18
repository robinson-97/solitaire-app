import '../storage.dart';
import '../ui/styles.dart';
import 'worlds.dart';

/// "Reach [percent]% of the best possible score" on one level unlocks a peg
/// or board look. The level is named by world, pack (0-3) and level (1-5), so
/// the rules keep working if packs are renamed. Percentages keep it fair:
/// small levels need small scores, big levels need big ones.
class UnlockRule {
  const UnlockRule(this.world, this.pack, this.level, this.percent);
  final String world;
  final int pack;
  final int level;
  final int percent;

  String get boardId => '${worldById(world).levelPacks[pack]}-$level';
  int get minScore => ((boardById(boardId).maxScore * percent / 100) / 10).round() * 10;
  String get text => 'Score $minScore on ${boardById(boardId).name}';
}

/// Pegs and boards are won with mystery draws (see peg_draw.dart); nothing is
/// unlocked by score any more.
const boardRules = <String, UnlockRule>{};

/// Rewards that a given board can earn, for display on level/board cards.
List<({String kind, String id, String label, int minScore})> rewardsFor(String boardId) => [
      for (final e in boardRules.entries)
        if (e.value.boardId == boardId)
          (kind: 'board', id: e.key, label: '${boardLabel(e.key)} board', minScore: e.value.minScore),
    ];

class Unlocks {
  Unlocks(this.s);
  final Storage s;

  /// Pegs are won with mystery draws; only the starter peg is free.
  bool pegUnlocked(String id) => id == 'acorn' || s.ownedPegs.contains(id);
  /// Boards are won with mystery draws; Old Oak and Midnight Grid are free.
  bool boardUnlocked(String id) => id == 'oak' || id == 'midnight' || s.ownedBoards.contains(id);

  /// 0..1 progress towards a rule.
  double progress(UnlockRule r) =>
      (s.bestScore(r.boardId) / r.minScore).clamp(0.0, 1.0).toDouble();

  int solvedIn(World w) => w.levels.where((l) => s.solved(l.id)).length;
  bool worldCompleted(World w) => solvedIn(w) == w.levels.length;

  /// Stars earned in a stage (3 per level).
  int starsIn(World w) => w.levels.fold(0, (a, l) => a + s.stars(l.id));

  /// Stars needed in a stage to open the next one (two thirds of the maximum).
  static const starsToOpen = 40;

  bool worldUnlocked(World w) =>
      s.unlockAll || w.unlockedBy == null || starsIn(worldById(w.unlockedBy!)) >= starsToOpen;

  /// Everything currently unlocked, as "peg:id" / "board:id" / "world:id".
  Set<String> snapshot() => {
        for (final t in pegThemes)
          if (pegUnlocked(t.id)) 'peg:${t.id}',
        for (final t in boardThemes)
          if (boardUnlocked(t.id)) 'board:${t.id}',
        for (final w in worlds)
          if (worldUnlocked(w)) 'world:${w.id}',
      };

  /// The locked reward that is closest to being earned.
  ({String label, String how, double progress})? nextUnlock() {
    ({String label, String how, double progress})? best;
    void consider(String label, String how, double p) {
      if (best == null || p > best!.progress) {
        best = (label: label, how: how, progress: p);
      }
    }

    for (final w in worlds) {
      if (!worldUnlocked(w)) {
        final prev = worldById(w.unlockedBy!);
        consider('${w.name} stage', 'Earn $starsToOpen stars in ${prev.name}', starsIn(prev) / starsToOpen);
      }
    }
    return best;
  }
}

String pegLabel(String id) => pegThemeById(id).name;

String boardLabel(String id) => boardThemeById(id).name;
