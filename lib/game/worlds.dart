import 'board_def.dart';
import 'levels_data.dart';

enum WorldScene { forest, cavern, peak }

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
    levelPacks: const ['seedling', 'sapling'],
    challenges: [triangleBoard, classicBoard],
  ),
  World(
    id: 'cavern',
    name: 'Crystal Cavern',
    tagline: 'Deep caves, humming with glowing geodes.',
    scene: WorldScene.cavern,
    levelPacks: const ['geode', 'facet'],
    challenges: [frenchBoard],
    unlockedBy: 'glimmerwood',
  ),
  World(
    id: 'peak',
    name: 'Starfall Peak',
    tagline: 'A frozen summit under a rain of falling stars.',
    scene: WorldScene.peak,
    levelPacks: const ['comet', 'meteor'],
    challenges: const [],
    unlockedBy: 'cavern',
  ),
];

World worldById(String id) => worlds.firstWhere((w) => w.id == id);

final List<BoardDef> allBoards = [for (final w in worlds) ...w.allBoards];

BoardDef boardById(String id) => allBoards.firstWhere((b) => b.id == id);

World worldOfBoard(String boardId) =>
    worlds.firstWhere((w) => w.allBoards.any((b) => b.id == boardId));

BoardDef? nextLevel(BoardDef b) {
  final w = worldOfBoard(b.id);
  final i = w.allBoards.indexWhere((x) => x.id == b.id);
  return i + 1 < w.allBoards.length ? w.allBoards[i + 1] : null;
}
