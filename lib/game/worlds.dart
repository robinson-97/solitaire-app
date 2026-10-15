import 'board_def.dart';
import 'catalog_data.dart';
import 'levels_data.dart';

/// Built-in animated scenery, used until a world has its own illustration.
enum WorldScene { forest, cavern, peak, desert, ocean, volcano, tundra, sky, stadium, neon, nebula }

class World {
  const World({
    required this.id,
    required this.name,
    required this.tagline,
    required this.scene,
    required this.art,
    required this.levelPacks,
    required this.challenges,
    this.unlockedBy,
  });

  final String id;
  final String name;
  final String tagline;
  final WorldScene scene;
  final String art; // assets/worlds/world_NN.jpg (optional)
  final List<String> levelPacks; // id prefixes in levels_data.dart
  final List<BoardDef> challenges; // optional boards, not needed to finish
  final String? unlockedBy; // world that must be completed first

  /// Levels needed to complete this world (each must be cleared).
  List<BoardDef> get levels => [
        for (final p in levelPacks)
          ...handmadeLevels.where((l) => l.id.startsWith('$p-')),
      ];

  List<BoardDef> get allBoards => [...levels, ...challenges];
}

final List<World> worlds = [
  for (var i = 0; i < worldCatalog.length; i++)
    World(
      id: worldCatalog[i].id,
      name: worldCatalog[i].name,
      tagline: worldCatalog[i].tagline,
      scene: WorldScene.values.byName(worldCatalog[i].fallback),
      art: worldCatalog[i].art,
      levelPacks: [for (final p in worldCatalog[i].packs) p.toLowerCase()],
      challenges: i == 0 ? [triangleBoard, classicBoard] : (i == 1 ? [frenchBoard] : const []),
      unlockedBy: i == 0 ? null : worldCatalog[i - 1].id,
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
