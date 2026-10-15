import '../storage.dart';
import 'worlds.dart';

/// "Reach [minScore] on [boardId]" unlocks a peg or board look.
class UnlockRule {
  const UnlockRule(this.boardId, this.minScore);
  final String boardId;
  final int minScore;
  String get text => 'Score $minScore on ${boardById(boardId).name}';
}

/// Edit these numbers to rebalance the game. Items without a rule are free.
const pegRules = <String, UnlockRule>{
  // Glimmerwood
  'firefly': UnlockRule('sprout-5', 400),
  'moonstone': UnlockRule('sapling-5', 450),
  'mushroom': UnlockRule('grove-5', 450),
  // Crystal Cavern
  'geode': UnlockRule('facet-5', 450),
  'ember': UnlockRule('prism-5', 500),
  // Starfall Peak
  'starlight': UnlockRule('comet-5', 550),
  'frost': UnlockRule('nova-5', 520),
};

const boardRules = <String, UnlockRule>{
  'mossy': UnlockRule('sapling-3', 400),
  'crystal': UnlockRule('lumen-3', 450),
  'rune': UnlockRule('lumen-5', 500),
  'marble': UnlockRule('comet-3', 500),
  'lava': UnlockRule('meteor-5', 520),
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

  bool _met(UnlockRule? r) => r == null || s.bestScore(r.boardId) >= r.minScore;

  bool pegUnlocked(String id) => _met(pegRules[id]);
  bool boardUnlocked(String id) => _met(boardRules[id]);

  /// 0..1 progress towards a rule.
  double progress(UnlockRule r) =>
      (s.bestScore(r.boardId) / r.minScore).clamp(0.0, 1.0);

  int solvedIn(World w) => w.levels.where((l) => s.solved(l.id)).length;
  bool worldCompleted(World w) => solvedIn(w) == w.levels.length;

  bool worldUnlocked(World w) =>
      w.unlockedBy == null || worldCompleted(worldById(w.unlockedBy!));

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

String pegLabel(String id) => const {
      'acorn': 'Acorn Wood',
      'firefly': 'Firefly Glass',
      'geode': 'Geode Crystal',
      'moonstone': 'Moonstone',
      'ember': 'Ember Crystal',
      'starlight': 'Starlight Gold',
      'frost': 'Frost Pearl',
      'mushroom': 'Mushroom',
    }[id]!;

String boardLabel(String id) => const {
      'oak': 'Old Oak',
      'mossy': 'Mossy Stone',
      'crystal': 'Crystal Slab',
      'marble': 'Frost Marble',
      'rune': 'Rune Stone',
      'lava': 'Lava Rock',
    }[id]!;
