/// The pages of Another Mine that a host can show.
///
/// What the game's own drawer offered, split out so that a host can list them
/// as sub pages.
enum AnotherMineSection {
  /// Playing. The difficulty is the one passed in or else the last one played.
  game,

  /// Choose a custom board size and mine count.
  custom,

  /// High scores.
  scores,

  /// Game settings.
  settings,
}
