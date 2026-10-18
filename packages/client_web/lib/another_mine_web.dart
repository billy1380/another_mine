/// Another Mine for the web, as a Jaspr app and as views to embed in other
/// Jaspr apps.
library;

// Embeddable views
export "package:another_mine_common/embedding/another_mine_section.dart"
    show AnotherMineSection;
export "package:another_mine_common/model/game_difficulty.dart"
    show GameDifficulty;

export "ui/another_mine_web_view.dart" show AnotherMineWebView;
export "ui/screens/custom_game_screen.dart"
    show CustomGameScreen, CustomGameView;
export "ui/screens/game_screen.dart" show GameScreen, GameView;
export "ui/screens/scores_screen.dart" show ScoresScreen, ScoresView;
export "ui/screens/settings_screen.dart" show SettingsScreen, SettingsView;

// Layout
export "ui/layout.dart" show AppLayout;

// Routes
export "routes.dart" show AnotherMineWebRoutes;

// UI and components
export "ui/bloc_provider.dart";

// Storage
export "services/local_storage_pref_storage.dart";
