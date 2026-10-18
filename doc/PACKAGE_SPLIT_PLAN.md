# Another Mine: split into packages

Split the single Flutter app into a Dart workspace, following
[willshex_triangles](../../willshex_triangles). The result is one shared game
engine, a Flutter client for mobile and desktop, and a Jaspr client for web.

## Goals

- A pure Dart `client_common` package with the game engine, runnable and testable without Flutter.
- A Flutter client (`client_flutter`) for iOS, Android, macOS, Windows and Linux, still embeddable in other Flutter hosts.
- A Jaspr client (`client_web`) for the web, embeddable in Jaspr hosts.
- Move to the latest Flutter, Dart and Jaspr, and get CocoaPods out of the Apple builds.

## Target layout

```
another_mine/
  pubspec.yaml              # workspace root
  analysis_options.yaml
  docs/
  packages/
    client_common/          # package another_mine_common   (pure Dart)
    client_flutter/         # package another_mine_flutter  (Flutter app + embeddable views)
    client_web/             # package another_mine_web      (Jaspr app + embeddable views)
    mine_images/            # package mine_images           (shared tile images, like subtle_backgrounds)
```

Directory names and `resolution: workspace` follow triangles. The platform
folders (`android/`, `ios/`, `macos/`, `windows/`, `linux/`) move into
`client_flutter`, as they do in triangles. The images go in `mine_images`.

## What goes where

### `client_common` (pure Dart, no `package:flutter`, no `dart:ui`)

| From `lib/` | Notes |
|---|---|
| `model/`, `logic/`, `ai/` | Needs the `Color` change below. |
| `bloc/game/` | Needs the `Color` and `Size` changes below. |
| `strings.dart` | |
| `services/pref.dart`, `provider*.dart`, `registrar*.dart` | `Pref` takes a `PrefStorage` instead of using `SharedPreferences`. |
| title and actions publishing from `widgets/another_mine_view.dart` | Becomes a controller around `PageSession` from `willshex_embedding`, so Flutter and Jaspr share it. |

Dependencies: `bloc`, `equatable`, `logging`, `collection`, `willshex`,
`willshex_dart_service_discovery`, `main_thread_processor`, `willshex_embedding`.
`main_thread_processor` must be confirmed free of `dart:ui` and `dart:html`.

### `client_flutter`

- `widgets/`, `pages/`, `routes.dart`, `app.dart`, `main.dart`, `assets.dart`.
- `AnotherMineView`, `AnotherMineSection` and `GameDifficulty` stay exported so existing hosts keep working.
- `SharedPreferencesPrefStorage`, which implements `PrefStorage`.
- `StartupBloc`, which keeps `kIsWeb` and `BrowserContextMenu`.
- Conversion from ARGB ints to `Color`, and from the size type to `Size`.
- Dependencies: `flutter_bloc`, `go_router`, `shared_preferences`, `flutter_colorpicker`.

### `mine_images`

Modelled on `subtle_backgrounds` in triangles.

- `assets/images/` holds the tile, counter, face and medal images, moved out of the app's `images/`.
- `lib/` has an enum of the image file names (pure Dart), so both clients refer to images by name.
- Flutter bundles them with `flutter: assets: - assets/images/` and loads them with `package: "mine_images"`. That replaces the `AnotherMineAssets.package` switch.
- The web client does not draw the board itself, so it needs no copy: the embedded Flutter bundle carries the images.
- The launcher icon source (`images/icon.png`) stays with `client_flutter`.

### `client_web` (Jaspr)

Jaspr provides the page, and the game board stays Flutter.

- **Flutter, through `jaspr_flutter_embed`:** the mine count, new game button, timer and minefield. This is `EmbeddedGame` in `client_flutter`, the same `GameBody` the Flutter app uses, hosted in a `FlutterEmbedView`. It is given the page's `GameBloc`, so the page and the board play the same game.
- **Jaspr:** the sidebar (difficulty list with mines-left badge, scores, settings), the header with the auto solver, probabilities and focus mode buttons, the custom game form and the settings page.
- `LocalStoragePrefStorage` implements `PrefStorage`.
- `AnotherMineWebView` is the embeddable component, like `AnotherMineView` on Flutter.
- Config: `jaspr.flutter: embedded`, a Flutter SDK dependency, and `web/flutter_bootstrap.js`, as in `flutter-willshex`.
- Images come from `mine_images` through the Flutter bundle, so the web client has no copy of them.

Run it with the "another_mine (web, Jaspr)" launch configuration, or `jaspr serve` in `packages/client_web` (http://localhost:8082).

## Changes needed to make the engine pure Dart

1. **`Color`** is used in `TileModel.colour`, `GameState.colour`, `GameBuilder.build`, `RandomGameBuilder`, `PatternGameBuilder` and `GameBloc._refreshSettings`. Replace it with an ARGB `int`. `Pref.defaultBackgroundColour` becomes an int, and luminance moves into a small helper.
2. **`Size`** is used in `GameState.gameSize`. Replace it with a small `width`/`height` value type, or two doubles.
3. **`Pref`** gets an abstract `PrefStorage` (get/set string, bool and int, remove). The key prefix and typed getters stay in `Pref`.
4. **`StartupBloc`** drops its Flutter imports. The `BrowserContextMenu` call moves to the Flutter client, and the web client needs no equivalent.
5. **`game_bloc.dart`** drops `package:flutter/material.dart` once 1 and 2 are done.

## Tooling: latest versions and no CocoaPods

Upgraded on 2026-10-18: Flutter 3.47.7, Dart 3.13.5, Jaspr 0.23.5 (already the
latest). Triangles pins `jaspr ^0.23.4`, so bump to `^0.23.5`.

1. Update the toolchain first, before moving any code:
   - `flutter upgrade`, `jaspr update` (done), then check `flutter --version` and `jaspr --version`.
2. Set the SDK constraints in every package:
   - `sdk: ^3.13.0` (current stable Dart is 3.13.5).
   - `flutter: ">=3.47.0"` for Flutter packages.
   - Workspace members use `resolution: workspace`.
3. Upgrade dependencies per package:
   - `dart pub upgrade --major-versions`, then `dart pub outdated`.
   - Remove `dependency_overrides` that are no longer needed (triangles has overrides for `build`, `analyzer`, `dart_style` and `cli_util`).
   - `willshex` still declares `sdk: <3.0.0`, which will need relaxing in `willshex-dart`.
4. **iOS and macOS: replace CocoaPods with Swift Package Manager.**
   - `flutter config --enable-swift-package-manager`.
   - Build once for iOS and once for macOS. Flutter migrates the Xcode projects.
   - Plugins that support SwiftPM use it. A plugin that doesn't support it keeps a Podfile, so check `shared_preferences` and any others the app uses.
   - When every plugin is on SwiftPM, delete `ios/Podfile`, `macos/Podfile`, their `Podfile.lock` files and `Pods/`. Add `Pods/` and `Podfile.lock` to `.gitignore`. Confirm the Xcode workspaces still open.
   - Do this after the files are moved into `client_flutter`, so it is done once, in the final location.
5. **Android: there is no CocoaPods.** The equivalent is the Gradle toolchain.
   - Update the wrapper (currently Gradle 8.14), the Android Gradle Plugin (8.11.1) and Kotlin (2.2.20) to the latest versions Flutter 3.47 supports.
   - Raise `compileSdk`, `targetSdk` and `minSdk` as the Flutter template does.
   - Run `flutter build apk` and `flutter build appbundle` to confirm.

## Status

Done on the `package-split` branch (uncommitted):

- Workspace, `client_common`, `client_flutter`, `client_web` and `mine_images` created, with files moved by `git mv` so history follows.
- Engine is pure Dart (`Colour` and `BoardSize` replace Flutter's `Color` and `Size`; `PrefStorage` replaces `shared_preferences`). `dart test` runs it without Flutter.
- Flutter client analyzes clean and its tests pass. Built for macOS, iOS and Android with the new toolchain.
- CocoaPods removed from iOS and macOS. Android on Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0.
- Web client builds with `jaspr build` and `jaspr serve` serves it on port 8082. Not yet run in a browser.
- `flutter-willshex` still depends on the old `another_mine` package and has not been touched (see Steps, 4).

Known issues:

- `simple_guesser_test.dart` "clicks remaining neighbours if flags equal tile value" fails. It failed before the split too.
- `willshex_dart_service_discovery` depends on `build ^3`, which forces the `dependency_overrides` in the root `pubspec.yaml` and `build_runner` 2.16.1 in the web client.

## Steps

Each step ends with tests passing and the app running. Steps 1 to 3 and 5 are done, and step 6 is started (README updated; embedding guide still to write).

1. **Prepare.** Work is committed. Split happens on the `package-split` branch (the repo's main branch is `master`). Toolchain updated (done).
2. **Workspace and `client_common`.**
   - Create the root `pubspec.yaml` with `workspace:`.
   - Make `client_common` pure Dart with the five engine changes above.
   - Move `test/ai` and `test/bloc` over as plain `dart test` (`test`, `bloc_test` and `mocktail` replace the Flutter test runner). Keep the `comparison` tag in `dart_test.yaml`.
   - These tests running without Flutter prove the package is pure Dart.
3. **`client_flutter`.**
   - Move the Flutter code, platform folders, images and widget tests.
   - Add `SharedPreferencesPrefStorage`.
   - Apply the SwiftPM and Gradle changes from Tooling.
   - Check the app runs on macOS and an Android emulator or device.
4. **Update hosts.** `flutter-willshex` (both `client_flutter` and `client_web`) depends on `../../../another_mine` and imports `package:another_mine/another_mine.dart`. Point it at `another_mine_flutter`, and replace the Flutter embed view in its Jaspr client with `AnotherMineWebView`. Not done: that repo has uncommitted changes of its own. No other project uses Another Mine.
5. **`client_web`.**
   - Scaffold the Jaspr app, with `jaspr.mode: client`, as in triangles.
   - Jaspr for the sidebar, header, custom game and settings; the Flutter board embedded with `jaspr_flutter_embed`. Scores stays a stub.
   - Add `WebGameView` and wire it into the Jaspr host.
6. **Docs.** Add a README for the workspace and an embedding guide, as in `willshex_triangles/docs/EMBEDDING_GUIDE.md`.

## Testing

Browser and UI checks are done by you, not by an automated browser (see
AGENTS.md). For each UI change I'll give the command to run, say what to look
for, and ask for a screenshot.

## Decisions made

- The plan lives in `doc/`. Existing markdown files are not merged or moved.
- The work in progress is committed (`8707db1 using embedding`).
- The whole game is available on the web. The board (mine count, restart button, timer, minefield) is the Flutter widgets embedded in the Jaspr page; the rest is Jaspr.
- Images are shared through a `mine_images` package, consistent with `subtle_backgrounds` in triangles. The web client gets them through the embedded Flutter bundle.
