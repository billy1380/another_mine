const BEGINNER_FIELD_WIDTH = 9;
const int BEGINNER_FIELD_HEIGHT = 9;
const int BEGINNER_MINES = 10;

const String BEGINNER_NAME = "beginner";

const int INTERMEDIATE_FIELD_WIDTH = 16;
const int INTERMEDIATE_FIELD_HEIGHT = 16;
const int INTERMEDIATE_MINES = 40;

const String INTERMEDIATE_NAME = "intermediate";

const int EXPERT_FIELD_WIDTH = 30;
const int EXPERT_FIELD_HEIGHT = 16;
const int EXPERT_MINES = 99;
const String EXPERT_NAME = "expert";

class GameDifficulty {
  final int width, height, mines;

  static const GameDifficulty BEGINNER = GameDifficulty(
      BEGINNER_FIELD_WIDTH, BEGINNER_FIELD_HEIGHT, BEGINNER_MINES);
  static const GameDifficulty INTERMEDIATE = GameDifficulty(
      INTERMEDIATE_FIELD_WIDTH, INTERMEDIATE_FIELD_HEIGHT, INTERMEDIATE_MINES);
  static const GameDifficulty EXPERT =
      GameDifficulty(EXPERT_FIELD_WIDTH, EXPERT_FIELD_HEIGHT, EXPERT_MINES);

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
  bool operator ==(Object obj) {
    bool equal = super == obj;

    if (!equal) {
      if (obj is GameDifficulty) {
        equal =
            width == obj.width && height == obj.height && mines == obj.mines;
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
      case INTERMEDIATE_NAME:
        difficulty = GameDifficulty.INTERMEDIATE;
        break;
      case EXPERT_NAME:
        difficulty = GameDifficulty.EXPERT;
        break;
      case BEGINNER_NAME:
      default:
        difficulty = GameDifficulty.BEGINNER;
        break;
    }

    return difficulty;
  }
}
