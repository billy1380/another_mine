import "dart:js_interop";

import "package:another_mine_common/another_mine_common.dart";
import "package:web/web.dart" as web;
import "package:willshex_embedding/willshex_embedding.dart";

/// The Willshex colours, light and dark, as its own host gives them.
const EmbeddingTheme _light = EmbeddingTheme(
  primaryColor: 0xFF059669,
  surfaceColor: 0xFFFFFFFF,
  onSurfaceColor: 0xFF0F172A,
  dividerColor: 0xFFE2E8F0,
  backgroundColor: 0xFFF8FAFC,
  onBackgroundColor: 0xFF0F172A,
);

const EmbeddingTheme _dark = EmbeddingTheme(
  primaryColor: 0xFF06D8A0,
  surfaceColor: 0xFF0F1A2A,
  onSurfaceColor: 0xFFDDE1E4,
  dividerColor: 0xFF1E2F47,
  backgroundColor: 0xFF080F19,
  onBackgroundColor: 0xFFDDE1E4,
);

/// Gives the game's own embedding host the site's theme, and keeps it to the
/// system's light or dark setting, as the page does, for the Flutter views in
/// the page.
void followSiteTheme() {
  final web.MediaQueryList query = web.window.matchMedia(
    "(prefers-color-scheme: dark)",
  );

  void apply() =>
      AnotherMineDialogs.local.setTheme(query.matches ? _dark : _light);

  apply();
  query.addEventListener("change", ((web.Event _) => apply()).toJS);
}
