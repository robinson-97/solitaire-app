import 'dart:math';

/// How rare a peg look is. Rarity is the only thing shown before a peg is won.
enum Rarity { common, rare, epic, legendary }

extension RarityText on Rarity {
  String get label => switch (this) {
        Rarity.common => 'Common',
        Rarity.rare => 'Rare',
        Rarity.epic => 'Epic',
        Rarity.legendary => 'Legendary',
      };
}

/// Pegs not listed here are common.
const pegRarity = <String, Rarity>{
  'firefly': Rarity.rare,
  'mushroom': Rarity.rare,
  'pixel': Rarity.rare,
  'vinyl': Rarity.rare,
  'pearl': Rarity.rare,
  'frost': Rarity.rare,
  'peppermint': Rarity.rare,
  'billiard': Rarity.rare,
  'planet': Rarity.rare,
  'moonstone': Rarity.rare,
  'ember': Rarity.epic,
  'geode': Rarity.epic,
  'disco': Rarity.epic,
  'amethyst': Rarity.epic,
  'onyx': Rarity.epic,
  'aurora': Rarity.epic,
  'tide': Rarity.epic,
  'koi': Rarity.epic,
  'lantern': Rarity.epic,
  'storm': Rarity.epic,
  'radar': Rarity.epic,
  'gold': Rarity.legendary,
  'magma': Rarity.legendary,
  'galaxy': Rarity.legendary,
  'starlight': Rarity.legendary,
  'plasma': Rarity.legendary,
  'clockwork': Rarity.legendary,
};

Rarity rarityOf(String pegId) => pegRarity[pegId] ?? Rarity.common;

/// Points one mystery draw costs (free in test mode).
const drawCost = 1200;

/// Chance (in %) of each rarity; tiers with nothing left to win are skipped.
const drawOdds = <Rarity, int>{Rarity.common: 60, Rarity.rare: 28, Rarity.epic: 9, Rarity.legendary: 3};

/// Picks a random peg the player does not own yet, or null if they own all.
String? rollPeg(Iterable<String> allIds, Set<String> owned, Random rng) {
  final left = [for (final id in allIds) if (!owned.contains(id)) id];
  if (left.isEmpty) return null;
  final tiers = [for (final r in Rarity.values) if (left.any((id) => rarityOf(id) == r)) r];
  final total = tiers.fold<int>(0, (a, r) => a + drawOdds[r]!);
  var roll = rng.nextInt(total);
  var tier = tiers.last;
  for (final r in tiers) {
    roll -= drawOdds[r]!;
    if (roll < 0) {
      tier = r;
      break;
    }
  }
  final pool = [for (final id in left) if (rarityOf(id) == tier) id];
  return pool[rng.nextInt(pool.length)];
}
