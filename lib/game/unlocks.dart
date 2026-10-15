import '../storage.dart';
import '../ui/styles.dart';
import 'worlds.dart';

/// "Reach [percent]% of the best possible score on [boardId]" unlocks a peg
/// or board look. Percentages keep every level fair: small levels need small
/// scores, big levels need big ones.
class UnlockRule {
  const UnlockRule(this.boardId, this.percent);
  final String boardId;
  final int percent;

  int get minScore => ((boardById(boardId).maxScore * percent / 100) / 10).round() * 10;
  String get text => 'Score $minScore on ${boardById(boardId).name}';
}

/// Edit these to rebalance the game. Items without a rule are free.
const pegRules = <String, UnlockRule>{
  // Glimmerwood
  'firefly': UnlockRule('sprout-5', 72),
  'moonstone': UnlockRule('sapling-5', 74),
  'mushroom': UnlockRule('grove-5', 70),
  // Crystal Cavern
  'geode': UnlockRule('facet-5', 74),
  'ember': UnlockRule('prism-5', 75),
  // Starfall Peak
  'starlight': UnlockRule('comet-5', 80),
  'frost': UnlockRule('nova-5', 73),
  // Sunbaked Dunes / Sky Gardens
  'cookie': UnlockRule('oasis-5', 72),
  'donut': UnlockRule('breeze-5', 72),
  // Stadium Nights
  'soccer': UnlockRule('kickoff-3', 72),
  'baseball': UnlockRule('kickoff-5', 74),
  'tennis': UnlockRule('dribble-3', 72),
  'basketball': UnlockRule('slam-3', 72),
  'golf': UnlockRule('slam-5', 75),
  'billiard': UnlockRule('final-3', 74),
  // Neon Arcade
  'pixel': UnlockRule('pixel-5', 72),
  'disco': UnlockRule('combo-5', 74),
  'vinyl': UnlockRule('glitch-5', 74),
  'smiley': UnlockRule('boss-3', 75),
  // Nebula Drift
  'planet': UnlockRule('nebula-5', 76),
};

const boardRules = <String, UnlockRule>{
  'mossy': UnlockRule('sapling-3', 68),
  'crystal': UnlockRule('lumen-3', 67),
  'rune': UnlockRule('lumen-5', 70),
  'marble': UnlockRule('comet-3', 74),
  'lava': UnlockRule('meteor-5', 73),
  'pitch': UnlockRule('final-5', 75),
  'neon': UnlockRule('boss-5', 76),
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
