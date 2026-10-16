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

/// Edit these to rebalance the game. Items without a rule are free.
const pegRules = <String, UnlockRule>{
  'firefly': UnlockRule('forest', 1, 5, 72),
  'cookie': UnlockRule('desert', 1, 5, 72),
  'marble': UnlockRule('desert', 0, 3, 72),
  'pearl': UnlockRule('coral', 1, 5, 72),
  'planet': UnlockRule('cosmic', 2, 5, 74),
  'frost': UnlockRule('frozen', 2, 5, 73),
  'ember': UnlockRule('volcanic', 2, 5, 74),
  'magma': UnlockRule('volcanic', 3, 3, 74),
  'mushroom': UnlockRule('jungle', 2, 5, 72),
  'pixel': UnlockRule('cyber', 1, 5, 72),
  'disco': UnlockRule('cyber', 2, 5, 74),
  'baseball': UnlockRule('countryside', 1, 3, 72),
  'donut': UnlockRule('candy', 1, 5, 72),
  'moonstone': UnlockRule('moonlit', 2, 5, 74),
  'basketball': UnlockRule('autumn', 1, 3, 72),
  'soccer': UnlockRule('ruins', 1, 3, 72),
  'tennis': UnlockRule('tropical', 1, 3, 73),
  'golf': UnlockRule('tropical', 3, 3, 74),
  'geode': UnlockRule('crystal', 1, 5, 74),
  'amethyst': UnlockRule('crystal', 2, 5, 75),
  'billiard': UnlockRule('fairytale', 2, 3, 75),
  'gold': UnlockRule('treasure', 2, 5, 77),
  'onyx': UnlockRule('treasure', 3, 5, 78),
  'vinyl': UnlockRule('sakura', 1, 5, 75),
  'smiley': UnlockRule('sakura', 2, 3, 75),
  'starlight': UnlockRule('skyislands', 3, 5, 80),
  'aurora': UnlockRule('frozen', 3, 3, 76),
  'galaxy': UnlockRule('cosmic', 3, 5, 77),
  'tide': UnlockRule('coral', 3, 5, 76),
  'clockwork': UnlockRule('ruins', 3, 5, 77),
  'storm': UnlockRule('skyislands', 2, 3, 76),
  'plasma': UnlockRule('cyber', 3, 3, 77),
  'koi': UnlockRule('sakura', 3, 5, 78),
  'lantern': UnlockRule('autumn', 3, 5, 76),
  'radar': UnlockRule('jungle', 3, 5, 77),
  'peppermint': UnlockRule('candy', 3, 5, 76),
};

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
};

/// Rewards that a given board can earn, for display on level/board cards.
List<({String kind, String id, String label, int minScore})> rewardsFor(String boardId) => [
      for (final e in pegRules.entries)
        if (e.value.boardId == boardId)
          (kind: 'peg', id: e.key, label: '${pegLabel(e.key)} pegs', minScore: e.value.minScore),
      for (final e in boardRules.entries)
        if (e.value.boardId == boardId)
          (kind: 'board', id: e.key, label: '${boardLabel(e.key)} board', minScore: e.value.minScore),
    ];

class Unlocks {
  Unlocks(this.s);
  final Storage s;

  bool _met(UnlockRule? r) => s.unlockAll || r == null || s.bestScore(r.boardId) >= r.minScore;

  bool pegUnlocked(String id) => _met(pegRules[id]);
  bool boardUnlocked(String id) => _met(boardRules[id]);

  /// 0..1 progress towards a rule.
  double progress(UnlockRule r) =>
      (s.bestScore(r.boardId) / r.minScore).clamp(0.0, 1.0).toDouble();

  int solvedIn(World w) => w.levels.where((l) => s.solved(l.id)).length;
  bool worldCompleted(World w) => solvedIn(w) == w.levels.length;

  bool worldUnlocked(World w) =>
      s.unlockAll || w.unlockedBy == null || worldCompleted(worldById(w.unlockedBy!));

  /// Everything currently unlocked, as "peg:id" / "board:id" / "world:id".
  Set<String> snapshot() => {
        for (final id in pegRules.keys.followedBy(['acorn']))
          if (pegUnlocked(id)) 'peg:$id',
        for (final id in boardRules.keys.followedBy(['oak']))
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

    pegRules.forEach((id, r) {
      if (!pegUnlocked(id)) consider('${pegLabel(id)} pegs', r.text, progress(r));
    });
    boardRules.forEach((id, r) {
      if (!boardUnlocked(id)) consider('${boardLabel(id)} board', r.text, progress(r));
    });
    for (final w in worlds) {
      if (!worldUnlocked(w)) {
        final prev = worldById(w.unlockedBy!);
        consider('${w.name} world', 'Clear every ${prev.name} level',
            solvedIn(prev) / prev.levels.length);
      }
    }
    return best;
  }
}

String pegLabel(String id) => pegThemeById(id).name;

String boardLabel(String id) => boardThemeById(id).name;
