import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:willshex_embedding/willshex_embedding.dart";

/// A [DialogImage] drawn small, with its label as the tooltip (hover).
Component smallPicture(DialogImage image, {int height = 18}) => img(
  src: image.webPath,
  alt: image.label ?? "",
  attributes: {
    if (image.label != null) "title": image.label!,
    "style":
        "height: ${height}px; width: auto; border-radius: ${height >= 32 ? 8 : 3}px;"
        "${image.crisp ? " image-rendering: pixelated;" : ""}",
  },
);
