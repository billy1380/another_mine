/// The Another Mine engine: board, solvers, game state and settings. Pure Dart,
/// shared by the Flutter and Jaspr clients.
library;

export "ai/game_move.dart";
export "ai/guesser.dart";
export "ai/interaction_type.dart";
export "ai/probability_guesser.dart";
export "ai/random_guesser.dart";
export "ai/simple_guesser.dart";

export "bloc/game/game_bloc.dart";

export "logic/game_builder.dart";
export "logic/pattern_game_builder.dart";
export "logic/probability_calculator.dart";
export "logic/random_game_builder.dart";

export "model/auto_solver_type.dart";
export "model/board_size.dart";
export "model/colour.dart";
export "model/game_difficulty.dart";
export "model/game_state_type.dart";
export "model/tile_model.dart";
export "model/tile_state_type.dart";

export "services/pref.dart";
export "services/pref_storage.dart";
export "services/provider.dart";
export "services/services.dart";

export "strings.dart";
export "presentation/presentation.dart";

export "embedding/another_mine_section.dart";
export "embedding/game_session_publisher.dart";
export "presentation/custom_game.dart";
export "presentation/game_routes.dart";
export "presentation/settings_options.dart";
