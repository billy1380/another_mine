/// 2x1 grid: [Safe, Mine]
const List<List<bool>> safeAndMine = [
  [false, true]
];

/// 4x1 grid: [Mine, Safe, Safe, Safe]
/// Useful for "lowest probability" scenarios if we reveal index 1.
const List<List<bool>> oneMineOneRow = [
  [true, false, false, false]
];

/// 2x1 grid: [Safe, Safe]
const List<List<bool>> safePair = [
  [false, false]
];

/// 2x2 grid:
/// false 1 (Mine at top-right)
/// false false
const List<List<bool>> cornerMine2x2 = [
  [false, true],
  [false, false]
];

/// 3x3 grid with mine in center
const List<List<bool>> centerMine3x3 = [
  [false, false, false],
  [false, true, false],
  [false, false, false]
];
