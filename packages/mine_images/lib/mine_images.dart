/// The images Another Mine draws its board with.
///
/// Bundled for Flutter through this package's assets, and served from
/// `packages/mine_images/assets/images/` by the web client.
library;

/// A bundled image, by file name.
enum MineImage {
  cool("cool.png"),
  counter0("counter0.png"),
  counter1("counter1.png"),
  counter2("counter2.png"),
  counter3("counter3.png"),
  counter4("counter4.png"),
  counter5("counter5.png"),
  counter6("counter6.png"),
  counter7("counter7.png"),
  counter8("counter8.png"),
  counter9("counter9.png"),
  dead("dead.png"),
  dunno("dunno.png"),
  eight("eight.png"),
  five("five.png"),
  found("found.png"),
  four("four.png"),
  hidden("hidden.png"),
  medal1("medal1.png"),
  medal2("medal2.png"),
  medal3("medal3.png"),
  mine2("mine2.png"),
  not("not.png"),
  one("one.png"),
  restin("restin.png"),
  seven("seven.png"),
  six("six.png"),
  thinking("thinking.png"),
  three("three.png"),
  two("two.png"),
  well("well.png");

  const MineImage(this.fileName);

  /// The file name within the images folder.
  final String fileName;

  /// The asset key, to use with the `package` argument set to [package].
  String get asset => "assets/images/$fileName";

  /// The URL the web client serves the image from.
  String get webPath => "packages/$package/$asset";

  /// The name of this package, which the images are bundled under.
  static const String package = "mine_images";

  /// The image shown for a revealed tile that touches [count] mines, or null
  /// for none (the plain revealed tile is used then).
  static MineImage? counter(int count) =>
      count >= 0 && count <= 9 ? _counters[count] : null;

  static const List<MineImage> _counters = [
    counter0,
    counter1,
    counter2,
    counter3,
    counter4,
    counter5,
    counter6,
    counter7,
    counter8,
    counter9,
  ];
}
