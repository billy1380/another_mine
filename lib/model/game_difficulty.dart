const beginnerFieldWidth = 9;
const int beginnerFieldHeight = 9;
const int beginnerMines = 10;
const String beginnerName = "beginner";

const int intermediateFieldWidth = 16;
const int intermediateFieldHeight = 16;
const int intermediateMines = 40;
const String intermediateName = "intermediate";

const int expertFieldWidth = 30;
const int expertFieldHeight = 16;
const int expertMines = 99;
const String expertName = "expert";

const String customName = "custom";

class GameDifficulty {
  final int width;
  final int height;
  final int mines;
  final String name;

  const GameDifficulty({
    required this.width,
    required this.height,
    required this.mines,
    required this.name,
  });

  static const List<GameDifficulty> values = [beginner, intermediate, expert];

  static const GameDifficulty beginner = GameDifficulty(
    width: beginnerFieldWidth,
    height: beginnerFieldHeight,
    mines: beginnerMines,
    name: beginnerName,
  );

  static const GameDifficulty intermediate = GameDifficulty(
    width: intermediateFieldWidth,
    height: intermediateFieldHeight,
    mines: intermediateMines,
    name: intermediateName,
  );

  static const GameDifficulty expert = GameDifficulty(
    width: expertFieldWidth,
    height: expertFieldHeight,
    mines: expertMines,
    name: expertName,
  );

  factory GameDifficulty.custom({
    required int width,
    required int height,
    required int mines,
  }) {
    return values.firstWhere(
      (element) => element.sameAs(width, height, mines),
      orElse: () => GameDifficulty(
        width: width,
        height: height,
        mines: mines,
        name: customName,
      ),
    );
  }

  int get area => width * height;

  double get difficultyFactor {
    return mines / area;
  }

  String get description {
    return "$mines in $width x $height";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GameDifficulty &&
        other.width == width &&
        other.height == height &&
        other.mines == mines &&
        other.name == name;
  }

  @override
  int get hashCode {
    return width.hashCode ^ height.hashCode ^ mines.hashCode ^ name.hashCode;
  }

  bool sameAs(int width, int height, int mines) {
    return this.width == width && this.height == height && this.mines == mines;
  }
}
