import 'board_def.dart';
import 'levels_data.dart';

enum WorldScene { forest, cavern, peak, desert, ocean, volcano, tundra, sky, stadium, neon, nebula }

class World {
  const World({
    required this.id,
    required this.name,
    required this.tagline,
    required this.scene,
    required this.levelPacks,
    required this.challenges,
    this.unlockedBy,
  });

  final String id;
  final String name;
  final String tagline;
  final WorldScene scene;
  final List<String> levelPacks; // id prefixes in levels_data.dart
  final List<BoardDef> challenges; // optional boards, not needed to finish
  final String? unlockedBy; // world that must be completed first

  /// Levels needed to complete this world (each must be cleared to one peg).
  List<BoardDef> get levels => [
        for (final p in levelPacks)
          ...handmadeLevels.where((l) => l.id.startsWith('$p-')),
      ];

  List<BoardDef> get allBoards => [...levels, ...challenges];
}

final List<World> worlds = [
  World(
    id: 'glimmerwood',
    name: 'Glimmerwood',
    tagline: 'A twilight forest where the fireflies keep watch.',
    scene: WorldScene.forest,
    levelPacks: const ['seedling', 'sprout', 'sapling', 'grove'],
    challenges: [triangleBoard, classicBoard],
  ),
  World(
    id: 'cavern',
    name: 'Crystal Cavern',
    tagline: 'Deep caves, humming with glowing geodes.',
    scene: WorldScene.cavern,
    levelPacks: const ['geode', 'facet', 'prism', 'lumen'],
    challenges: [frenchBoard],
    unlockedBy: 'glimmerwood',
  ),
  World(
    id: 'peak',
    name: 'Starfall Peak',
    tagline: 'A frozen summit under a rain of falling stars.',
    scene: WorldScene.peak,
    levelPacks: const ['comet', 'nova', 'meteor', 'aurora'],
    challenges: const [],
    unlockedBy: 'cavern',
  ),
  World(
    id: 'dunes',
    name: 'Sunbaked Dunes',
    tagline: 'Golden sands and a sky that never quite goes dark.',
    scene: WorldScene.desert,
    levelPacks: const ['dune', 'oasis', 'mirage', 'pharaoh'],
    challenges: const [],
    unlockedBy: 'peak',
  ),
  World(
    id: 'coral',
    name: 'Coral Deep',
    tagline: 'Sunlight drifts down through the quiet blue.',
    scene: WorldScene.ocean,
    levelPacks: const ['tide', 'reef', 'kelp', 'abyss'],
    challenges: const [],
    unlockedBy: 'dunes',
  ),
  World(
    id: 'crater',
    name: 'Ember Crater',
    tagline: 'Rivers of glowing lava under a restless sky.',
    scene: WorldScene.volcano,
    levelPacks: const ['magma', 'ash', 'obsidian', 'cinder'],
    challenges: const [],
    unlockedBy: 'coral',
  ),
  World(
    id: 'tundra',
    name: 'Frostwind Tundra',
    tagline: 'Northern lights over endless snow.',
    scene: WorldScene.tundra,
    levelPacks: const ['flurry', 'drift', 'glacier', 'icicle'],
    challenges: const [],
    unlockedBy: 'crater',
  ),
  World(
    id: 'sky',
    name: 'Sky Gardens',
    tagline: 'Floating islands above a sea of clouds.',
    scene: WorldScene.sky,
    levelPacks: const ['cloud', 'breeze', 'zephyr', 'gale'],
    challenges: const [],
    unlockedBy: 'tundra',
  ),
  World(
    id: 'stadium',
    name: 'Stadium Nights',
    tagline: 'Floodlights, a roaring crowd and a perfect pitch.',
    scene: WorldScene.stadium,
    levelPacks: const ['kickoff', 'dribble', 'slam', 'final'],
    challenges: const [],
    unlockedBy: 'sky',
  ),
  World(
    id: 'arcade',
    name: 'Neon Arcade',
    tagline: 'Synthwave sunsets and glowing retro screens.',
    scene: WorldScene.neon,
    levelPacks: const ['pixel', 'combo', 'glitch', 'boss'],
    challenges: const [],
    unlockedBy: 'stadium',
  ),
  World(
    id: 'nebula',
    name: 'Nebula Drift',
    tagline: 'Clouds of colour between the stars.',
    scene: WorldScene.nebula,
    levelPacks: const ['nebula', 'pulsar', 'quasar', 'zenith'],
    challenges: const [],
    unlockedBy: 'arcade',
  ),
];

World worldById(String id) => worlds.firstWhere((w) => w.id == id);

final List<BoardDef> allBoards = [for (final w in worlds) ...w.allBoards];

BoardDef boardById(String id) => allBoards.firstWhere((b) => b.id == id);

World worldOfBoard(String boardId) =>
    worlds.firstWhere((w) => w.allBoards.any((b) => b.id == boardId));

/// Next level in the same world (bonus boards have no "next").
BoardDef? nextLevel(BoardDef b) {
  final levels = worldOfBoard(b.id).levels;
  final i = levels.indexWhere((x) => x.id == b.id);
  return i >= 0 && i + 1 < levels.length ? levels[i + 1] : null;
}
