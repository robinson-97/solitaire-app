/// Board shapes and puzzle definitions. Pure data, no UI.
library;

class Pos {
  const Pos(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is Pos && other.row == row && other.col == col;
  @override
  int get hashCode => row * 100 + col;
  @override
  String toString() => 'Pos($row,$col)';
}

enum Difficulty { easy, medium, hard, expert }

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
        Difficulty.expert => 'Expert',
      };
}

const orthogonal = [(-1, 0), (1, 0), (0, -1), (0, 1)];
const triangular = [(0, -1), (0, 1), (-1, 0), (1, 0), (-1, -1), (1, 1)];

class BoardDef {
  const BoardDef({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.holes,
    required this.pegs,
    this.dirs = orthogonal,
    this.center,
    this.triangle = false,
  });

  final String id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final Set<Pos> holes;
  final Set<Pos> pegs;
  final List<(int, int)> dirs;

  /// Hole that earns the "center finish" bonus (null = none on this board).
  final Pos? center;

  /// Triangle boards are drawn with every row centred.
  final bool triangle;

  int get rows => holes.map((p) => p.row).reduce((a, b) => a > b ? a : b) + 1;
  int get cols => holes.map((p) => p.col).reduce((a, b) => a > b ? a : b) + 1;
  int get startPegs => pegs.length;

  /// A level counts as cleared when this many pegs (or fewer) are left.
  int get passAt => startPegs < 10 ? 1 : (startPegs < 20 ? 2 : 3);
  String get goalText => passAt == 1 ? 'Leave just 1 peg' : 'Leave $passAt or fewer pegs';

  /// Highest possible jump count (every peg but the last one).
  int get maxJumps => startPegs - 1;
}

Set<Pos> _grid(int n, bool Function(int r, int c) keep) => {
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++)
          if (keep(r, c)) Pos(r, c),
    };

bool _english(int r, int c) => (r >= 2 && r <= 4) || (c >= 2 && c <= 4);
bool _frenchShape(int r, int c) {
  // 7x7 with each corner cut by three holes (37 holes).
  const widths = [3, 5, 7, 7, 7, 5, 3];
  final w = widths[r];
  final start = (7 - w) ~/ 2;
  return c >= start && c < start + w;
}

final englishHoles = _grid(7, _english);
const _c33 = Pos(3, 3);

final BoardDef classicBoard = BoardDef(
  id: 'classic',
  name: 'Classic English',
  description: '33 holes. The original puzzle.',
  difficulty: Difficulty.hard,
  holes: englishHoles,
  pegs: {...englishHoles}..remove(_c33),
  center: _c33,
);

final BoardDef frenchBoard = () {
  final holes = _grid(7, (r, c) => _frenchShape(r, c));
  return BoardDef(
    id: 'french',
    name: 'French',
    description: '37 holes. The empty hole starts off-center.',
    difficulty: Difficulty.expert,
    holes: holes,
    pegs: {...holes}..remove(const Pos(3, 5)),
    center: _c33,
  );
}();

final BoardDef triangleBoard = () {
  final holes = {
    for (var r = 0; r < 5; r++)
      for (var c = 0; c <= r; c++) Pos(r, c),
  };
  return BoardDef(
    id: 'triangle',
    name: 'Triangle',
    description: '15 holes. Pegs also jump diagonally.',
    difficulty: Difficulty.medium,
    holes: holes,
    pegs: {...holes}..remove(const Pos(0, 0)),
    dirs: triangular,
    triangle: true,
  );
}();

enum BoardShape { english, french, triangle }

final Set<Pos> frenchHoles = _grid(7, (r, c) => _frenchShape(r, c));
final Set<Pos> triangleHoles = {
  for (var r = 0; r < 5; r++)
    for (var c = 0; c <= r; c++) Pos(r, c),
};

Set<Pos> shapeHoles(BoardShape s) => switch (s) {
      BoardShape.english => englishHoles,
      BoardShape.french => frenchHoles,
      BoardShape.triangle => triangleHoles,
    };

/// Handmade puzzles, built backwards from one peg so each one is guaranteed
/// solvable (see tool/gen_levels.dart).
BoardDef levelBoard(String id, String name, Difficulty d, BoardShape shape,
        List<(int, int)> p) =>
    BoardDef(
      id: id,
      name: name,
      description: '${p.length} pegs. Leave just one.',
      difficulty: d,
      holes: shapeHoles(shape),
      pegs: {for (final (r, c) in p) Pos(r, c)},
      dirs: shape == BoardShape.triangle ? triangular : orthogonal,
      center: shape == BoardShape.triangle ? null : _c33,
      triangle: shape == BoardShape.triangle,
    );
