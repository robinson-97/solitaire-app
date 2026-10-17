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

/// Boards unlock with high scores (pegs are won with points instead, see peg_draw.dart).
const boardRules = <String, UnlockRule>{
  'mossy': UnlockRule('forest', 2, 3, 68),
  'lava': UnlockRule('volcanic', 3, 5, 73),
  'neon': UnlockRule('cyber', 3, 5, 76),
  'crystal': UnlockRule('crystal', 3, 3, 70),
  'rune': UnlockRule('crystal', 3, 5, 72),
  'pitch': UnlockRule('fairytale', 3, 5, 76),
  'marble': UnlockRule('skyislands', 2, 5, 76),
  'sakura': UnlockRule('sakura', 3, 3, 74),
  'galaxy': UnlockRule('cosmic', 2, 5, 75),
  'ocean': UnlockRule('coral', 2, 5, 74),
  'candy': UnlockRule('candy', 2, 3, 74),
  'aurora': UnlockRule('frozen', 3, 5, 75),
  'clockwork': UnlockRule('ruins', 2, 3, 74),
  'circuit': UnlockRule('cyber', 2, 3, 75),
  'pond': UnlockRule('sakura', 2, 5, 74),
  'storm': UnlockRule('skyislands', 3, 3, 76),
  'honey': UnlockRule('countryside', 3, 5, 74),
  'jade': UnlockRule('jungle', 3, 3, 75),
};

/// Rewards that a given board can earn, for display on level/board cards.
List<({String kind, String id, String label, int minScore})> rewardsFor(String boardId) => [
      for (final e in boardRules.entries)
        if (e.value.boardId == boardId)
          (kind: 'board', id: e.key, label: '${boardLabel(e.key)} board', minScore: e.value.minScore),
    ];

class Unlocks {
  Unlocks(this.s);
  final Storage s;

  bool _met(UnlockRule? r) => s.unlockAll || r == null || s.bestScore(r.boardId) >= r.minScore;

  /// Pegs are won with mystery draws; only the starter peg is free.
  bool pegUnlocked(String id) => id == 'acorn' || s.ownedPegs.contains(id);
  bool boardUnlocked(String id) => _met(boardRules[id]);

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
        for (final id in boardRules.keys.followedBy(['oak', 'midnight']))
          if (boardUnlocked(id)) 'board:$id',
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

    boardRules.forEach((id, r) {
      if (!boardUnlocked(id)) consider('${boardLabel(id)} board', r.text, progress(r));
    });
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
