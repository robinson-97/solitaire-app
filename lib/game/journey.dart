import 'board_def.dart';
import 'levels_data.dart';

/// The order in which boards are suggested ("Play" / "Next" buttons).
List<BoardDef> get journey {
  List<BoardDef> pack(String id) =>
      handmadeLevels.where((l) => l.id.startsWith(id)).toList();
  return [
    ...pack('seedling'),
    triangleBoard,
    ...pack('sapling'),
    classicBoard,
    ...pack('elder'),
    frenchBoard,
  ];
}

BoardDef? nextInJourney(BoardDef b) {
  final j = journey;
  final i = j.indexWhere((x) => x.id == b.id);
  return i >= 0 && i + 1 < j.length ? j[i + 1] : null;
}
