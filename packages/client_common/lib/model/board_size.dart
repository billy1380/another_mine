/// The width and height of the board in logical pixels.
class BoardSize {
  final double width;
  final double height;

  const BoardSize(this.width, this.height);

  @override
  bool operator ==(Object other) =>
      other is BoardSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => "BoardSize($width, $height)";
}
