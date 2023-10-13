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

class GameDifficulty {
  final int width, height, mines;

  static const GameDifficulty beginner =
      GameDifficulty(beginnerFieldWidth, beginnerFieldHeight, beginnerMines);
  static const GameDifficulty intermediate = GameDifficulty(
      intermediateFieldWidth, intermediateFieldHeight, intermediateMines);
  static const GameDifficulty expert =
      GameDifficulty(expertFieldWidth, expertFieldHeight, expertMines);

  const GameDifficulty(this.width, this.height, this.mines);

  factory GameDifficulty.clone(GameDifficulty difficulty) {
    return GameDifficulty(
        difficulty.width, difficulty.height, difficulty.mines);
  }

  static int difficultyArea(GameDifficulty difficulty) {
    return calculateArea(difficulty.width, difficulty.height);
  }

  static int calculateArea(int width, int height) {
    return width * height;
  }

  @override
  int get hashCode => "$width:$height:$mines".hashCode;

  @override
  bool operator ==(Object other) {
    bool equal = super == other;

    if (!equal) {
      if (other is GameDifficulty) {
        equal = width == other.width &&
            height == other.height &&
            mines == other.mines;
      }
    }

    return equal;
  }

  String describe() {
    return "$mines in $width x $height";
  }

  static GameDifficulty fromString(String s) {
    GameDifficulty difficulty;

    switch (s) {
      case intermediateName:
        difficulty = GameDifficulty.intermediate;
        break;
      case expertName:
        difficulty = GameDifficulty.expert;
        break;
      case beginnerName:
      default:
        difficulty = GameDifficulty.beginner;
        break;
    }

    return difficulty;
  }
}
