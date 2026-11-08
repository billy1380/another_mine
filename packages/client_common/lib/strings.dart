abstract class Strings {
  Strings._();

  static const String settingsTitle = "Settings";
  static const String gameSection = "Game";
  static const String animationsTitle = "Animations";
  static const String animationsSubtitle = "Enable tile reveal animations";
  static const String autoSolverStrategyTitle = "Auto Solver Strategy";
  static const String highScoresSection = "High Scores";
  static const String localScoresRetainedTitle = "Local Scores Retained";
  static const String keepUpToScores = "Keep up to %s scores";
  static const String onlineHighScoresTitle = "Online High Scores";
  static const String onlineHighScoresSubtitle = "Enable online leaderboards";
  static const String onlinePlayerTitle = "Online player";
  static const String onlinePlayerMessage =
      "Your scores are saved online, outside this device, for Beginner, Intermediate, Expert and custom Medium and Hard games.";
  static const String appearanceSection = "Appearance";
  static const String customBgColorEnabledTitle = "Custom Background Color";
  static const String customBgColorEnabledSubtitle =
      "Use a custom background color";
  static const String backgroundColorTitle = "Background Color";
  static const String chooseBackgroundColorTitle = "Choose Background Color";
  static const String cancel = "Cancel";
  static const String select = "Select";

  static const String gameToolsTooltip = "Game Tools";
  static const String autoSolver = "Auto Solver";
  static const String probabilities = "Probabilities";
  static const String focusMode = "Focus Mode";
  static const String startupPageTitle = "Another Mine";

  static const String difficulty = "Difficulty";
  static const String scores = "Scores";
  static const String start = "Start";

  static const String wonTitle = "You won!";
  static const String nameLabel = "Name";
  static const String save = "Save";
  static const String skip = "Skip";
  static const String noScoresYet = "No scores yet.";
  static const String bestTime = "A new best time!";

  /// "42 seconds on Beginner".
  static String timeOnBoard(int seconds, String board) =>
      "$seconds ${seconds == 1 ? "second" : "seconds"} on $board";

  /// "Place 3 in Beginner".
  static String placeIn(int place, String category) =>
      "Place $place in $category";

  static const String delete = "Delete";
  static const String deleteScoreTooltip = "Delete this score";
  static const String deleteScoreTitle = "Delete score?";

  /// "billy's 37 s on Beginner will be deleted."
  static String deleteScoreQuestion(String name, int seconds, String board) =>
      "$name's $seconds s on $board will be deleted.";

  /// "Delete all Beginner scores".
  static String deleteAll(String category) => "Delete all $category scores";
  static const String deleteAllTitle = "Delete scores?";

  /// "Every Beginner score on this device will be deleted."
  static String deleteAllQuestion(String category) =>
      "Every $category score on this device will be deleted.";

  static const String customGameTitle = "Custom game";
  static const String customWidth = "Width";
  static const String customHeight = "Height";
  static const String customMines = "Mines";
}
