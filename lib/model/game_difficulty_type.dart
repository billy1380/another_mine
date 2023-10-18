const beginnerFieldWidth = 9;
const int beginnerFieldHeight = 9;
const int beginnerMines = 10;

const int intermediateFieldWidth = 16;
const int intermediateFieldHeight = 16;
const int intermediateMines = 40;

const int expertFieldWidth = 30;
const int expertFieldHeight = 16;
const int expertMines = 99;

enum GameDifficultyType {
  beginner(beginnerFieldWidth, beginnerFieldHeight, beginnerMines),
  intermediate(
      intermediateFieldWidth, intermediateFieldHeight, intermediateMines),
  expert(expertFieldWidth, expertFieldHeight, expertMines),
  ;

  final int width, height, mines;

  const GameDifficultyType(this.width, this.height, this.mines);

  static int difficultyArea(GameDifficultyType difficulty) {
    return calculateArea(difficulty.width, difficulty.height);
  }

  static int calculateArea(int width, int height) {
    return width * height;
  }

  String get description {
    return "$mines in $width x $height";
  }
}
