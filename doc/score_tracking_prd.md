# PRD: Another Mine score tracking (local and remote)

Status: draft for review. Companion: [SpaceCloud admin Users and Scores](../../flutter-willshex/docs/spacecloud_admin_prd.md), which depends on this one.

## Why

The macOS Objective-C Another Mine (`/Users/billy1380/git/anothermine`) had local and online high scores. The Flutter/Jaspr port has the settings for them (`remoteHighScoresEnabled`, `defaultCountry`, `scoresRetained` in `Pref`) but the Scores page is a stub and nothing is recorded or sent. This completes the port, and makes Another Mine the first app to send the richer score data the SpaceCloud admin will show.

## What the original did (reference, not to be copied blindly)

- **Local:** a plist per difficulty (`scores.<type>.plist`) holding name, difficulty, seconds; custom games kept width, height and mines. A slider kept the top N (default from `scoresRetained`). Medals for ranks 1 to 3.
- **Remote:** `RemoteHighScores` called `SubmitScore` and `GetScores` on the scores service with the Willshex **publisher key as the session access code**. Categories were hard-coded ids 1 to 4 (Beginner, Intermediate, Expert, Custom). Score value was seconds, unit `"seconds"`, and the description held the game name (`Custom (40 in 16 x 16)` for custom). The player was only a name and a country, so there was no stable user.
- **Congratulations sheet:** name field (default the macOS full name), country menu with flags (default United Kingdom, disabled unless online scores are on), a rank medal, then the local table, then a submit.
- **Gaps it had:** the online tab only showed the top 20 of one category; `isScoreHigh` for online always returned true; failures were only logged; every custom game landed in one category so times for different boards were mixed together; no extra data, so no way to show the finished board.

## Goals

1. Local high scores per difficulty (including custom) on every platform.
2. Optional online scores, off until the player turns them on.
3. A player profile dialog (username, country, and which leaderboard) reused from the existing settings.
4. Every submitted score carries enough data for the admin to show the game: board size, mines, solver used, and a text picture of the won board (a character grid, which the admin can draw as an image).
5. Custom games ranked against games of like difficulty, by mine density (Easy, Medium, Hard), with the exact board kept on every score.

## Non-goals

- No SpaceCloud admin UI here (see companion PRD).
- No sign-in with Game Center or Google yet; the scores service already supports those user types, so this must not close the door on them.
- No cheating prevention beyond what the service does today (see open questions).

## Users and flows

**First win with online scores off:** congratulations dialog shows time, rank and name; saved locally; Scores page lists them.

**Turning online scores on:** the settings switch opens the **online player dialog** (done). It follows the Delta-V Hosted user page (Name, Service) with a country added:

| Field | Notes |
| --- | --- |
| Name | required, more than three characters, trimmed; kept as the player name used for local scores too. For an outside system it is a display name that gets updated (below) |
| Service | The list Delta-V Hosted's Compare Scores uses (`UserTypeType`, named as there). Default **Willshex Scores**, meaning no outside account. The player does not type an id; the platform supplies one where it can |
| Country | A drop down of every SpaceCloud `Country`, by name. Stored as its code, such as `GB` |

The dialog says that scores are saved outside the device and for which games. Cancelling leaves online scores off.

**Settings once online is on:** the old "Default country" row is gone. A row "Online player" shows `name · service · country` and opens the same dialog to edit. Turning the switch off asks for confirmation ("Stop saving online?"); on yes the row is hidden and nothing is sent. The name, service and country are kept, so turning it back on starts from them.

**Win with online scores on:** same congratulations dialog as with them off, but without the name field (the online player is known, and keeps the local score too). The score is sent without asking, under the online player's name, whether or not it places locally; a failed send is queued and retried silently (see requirements).

**Scores page:** the same category tabs. With online scores off they list this device's scores; with them on, the online ones (a window of the category's board chosen as in Leaderboard window below; flag, name and service icon), and the Custom Easy tab is hidden because those games are local only. Each row shows country, board and date. The online tabs have no delete.

## Requirements

### Local scores
- Stored with `willshex_storage` (`/Users/billy1380/git/willshex-dart-storage`), the local storage the other Willshex apps use (Delta-V's `LocalScoresManager` is the model), not `PrefStorage`. Settings stay in `Pref`. `willshex_storage` is built on `fs_shim` and `idb_shim`, so it should also run on the web; the Jaspr site is checked for this first, since the web currently uses `localStorage`.
- One list per difficulty key; custom keyed by `WxHxM`. Keep top N (`scoresRetained`). Ascending seconds, ties by earlier date.
- Record: name, seconds, difficulty, width, height, mines, solver (human, simple, probability), date.
- **Games the auto solver played are not kept at all**, locally or online: its times would crowd the player's out of the best N. (The record carries the solver, `human`, `simple` or `probability`, for any future use.) A game counts as the solver's if it played any part of it.

### Remote scores
- Scores and SpaceCloud clients come from shared packages (see Packages), not from copies in this repo.
- Session access code is the Willshex publisher key, as before. It is committed and not secret, so no build define (the same decision as the SpaceCloud admin key).
- **Game and categories:** an `Application` "Another Mine" under the Willshex publisher in SpaceCloud, with five scores categories: **Beginner, Intermediate, Expert, Custom Medium and Custom Hard** (Easy custom games are not sent; the local store keeps all six), matched by name and game, not by the legacy ids 1 to 4. Scores service does not create categories on submit, so these must exist before release (a step in the rollout).
- **Legacy data (decided: migrate):** the old app's scores in categories 1 to 4 are moved to the new categories by a script the user runs (it needs the admin session). Beginner, Intermediate and Expert map one to one. Old Custom (4) scores carry their board only in the description (`Custom (40 in 16 x 16)`), so the script parses it, works out the density and files each under Easy, Medium or Hard; any it cannot parse go to a report and stay put. The script prints what it will do and asks before changing anything.
- **User (decided, as in Delta-V Hosted):** the player types a **username** and picks a **system** (the same list as Delta-V Hosted's Service box); SpaceCloud finds or creates the user from that name and system type, which is `name@system` in Delta-V Hosted. Country is added to the same user.
  - **When the platform knows the player's id** (Game Center on Apple devices, Google, and so on), it is sent as the `externalSystemId`. SpaceCloud finds the user by that id and **updates the username** (and country) to what was entered, so a rename keeps the same player and the same account on two devices is one player.
  - **Without an id** (the web, or the Another Mine system), the user is the name plus the system. Two people choosing the same name on the same system are the same player, which is how Delta-V Hosted already works.
  - Usernames follow Delta-V Hosted's rule of more than three characters, trimmed and sanitised.
  - The Willshex user id is not involved.
- **Score:** `value` seconds, `unit` seconds, `description` the board (`Expert`, or `Custom 40 mines on 16 x 16`; the same wording for every custom game so the legacy migration and new scores read alike), `attempt`, `when`, `additionalData`.
- **Additional data** (JSON, gzip then base64, the same encoding Delta-V uses so the admin has one decoder). It is a recording of the game, so the admin (or the game) can show what the player did and replay it at any speed:
  ```
  { "game": "anothermine", "version": 2,
    "difficulty": "expert", "width": 30, "height": 16, "mines": 99,
    "solver": "human",
    "layout": "<base64 bitset, one bit per tile, 1 = mine>",
    "events": [ [0, "p", 212], [830, "f", 40], [1500, "prob", 1], [4210, "pause"], ... ] }
  ```
  - **`events`** are `[ms, code, argument]`, in order, `ms` since the first move: `p` reveal tile, `f` flag or unflag tile (the argument is the tile index, `y * width + x`), `pause` and `resume`, `prob` and `focus` when probability mode or focus mode is turned on (`1`) or off (`0`). Both modes are off when a game begins. A replay feeds the events to the same game logic from `layout`, so it needs no stored board and runs at 1x, or faster or slower by scaling `ms`. Paused time is visible from `pause` and `resume`.
  - **`layout`** is the mines as they stand at the win, which is after the first-move protection has moved a mine away from the first tile.
  - **Size:** about 14 bytes an event as JSON, a few hundred events for Expert, so a few KB compressed. The biggest custom board (50 by 50) with a long game stays well under 100 KB, hundreds of times under the 1 MB row limit.
  - **Never sent for solver games:** a game the auto solver played any part of is not kept or sent at all, so its events are never recorded either. Probability and focus mode are the player's own aids and are recorded, not blocked.
  - The final board as a text grid is not stored: a replay to the last event gives it.
- **Custom games (decided):** a custom board is ranked by mine density, `mines / (width x height)`, against the three presets (Beginner 10 in 9 x 9 is 0.123, Intermediate 40 in 16 x 16 is 0.156, Expert 99 in 30 x 16 is 0.206):
  - a board that is exactly a preset counts as that preset;
  - otherwise, density below Beginner is **Easy**, below Intermediate is **Medium**, and everything else is **Hard**. A custom board that is denser than Expert is Hard, since there is no category beyond it;
  - the board is recorded on the score (in `description` and in the additional data as `width`, `height`, `mines`), so the admin can still show or filter by it.
  - Density ignores size, and the custom dialog's sliders allow boards from 5 by 5 with a single mine. Whatever the sliders allow is a valid online game: there is no extra minimum board size for online scores. A tiny board is just a very easy Easy game, and the minimum-time guard below covers cheating.
- Failures never block the game: store the submission in prefs, retry on next launch or next win, give up after N attempts.
- Reading: a window of the board by value ascending, chosen as in Leaderboard window below, with player and country filled (`GetScores` already does this), plus paging both ways.

### Settings
- Online scores switch (opens the online player dialog, off asks first), the online player row to edit it, scores retained, "clear local scores" with confirmation.

## Packages

Everything shared is a package picked up by path, as `willshex`, `willshex_storage` and `willshex_dart_service_discovery` already are:

- **`willshex_storage`:** local scores (above).
- **Scores and SpaceCloud clients:** `flame_delta_v/lib/api` holds generated clients (`scores` and `space_cloud`, 84 files) that are not yet packages. They are extracted into **`willshex_scores`** and **`willshex_space_cloud`**, siblings of the other `willshex_*` packages in `/Users/billy1380/git`, and `flame_delta_v` is switched to use them so there is one copy.
  - The data types, requests, responses and service clients move as they are; only four imports tie them to Delta-V (`constants.dart`, `provider.dart`, `date_time_helper.dart`, `time_stamp_helper.dart`).
  - The only real coupling is `AbstractCachingJsonServiceClient`, which reads the cache folder and file system from Delta-V's `Provider`. The packages' clients extend the plain `AbstractJsonServiceClient` from `willshex`; Delta-V keeps its caching in its own code (or the cache location is passed in) when it switches over.
  - **Core and admin are separate packages.** `willshex_space_cloud` and `willshex_scores` hold the data types and the core calls a game needs. Admin calls live in `willshex_space_cloud_admin` (and a `willshex_scores_admin` once the scores admin endpoint in the admin PRD exists), which depend on the core packages. Games never ship the admin code.
  - The SpaceCloud client the Willshex admin uses (`blogwt_common/api/spacecloud`) is a separate generation of the same service. Whether admin moves onto `willshex_space_cloud` is a later decision; Another Mine does not need to wait for it.
  - The server added by the admin PRD (new calls, keys) is added to the generator output, so both packages are regenerated rather than hand edited.

## Rollout

0. Extract `willshex_scores` and `willshex_space_cloud` from `flame_delta_v` and switch Delta-V to them (it must still build and its tests pass).
1. Create the Another Mine application and the five categories on the live SpaceCloud/scores (the old-score migration is probably not needed, see Status).
2. Local scores and the congratulations/Scores page, behind no flag.
3. Player dialog and submit, online off by default.
4. Text board and the other additional data.

## Decisions

Decided with the owner:

1. **Custom games:** three categories by mine density (Easy, Medium, Hard), board recorded on the score. See above.
2. **Legacy scores:** migrated to the new categories by a script.
3. **Anti-cheat:** a minimum-time guard, per board. The client does not send a time under a floor for the board. The floor values are set when implementing, from the fastest times in the legacy data, and live in one table in `client_common`.
4. **Evidence of the win:** a text board (with the mine, flag and number values above), not an image. Colours are omitted.
5. **Same player on two devices (decided):** by system and name as in Delta-V Hosted, and by the platform's id where there is one. No ids are typed or copied.
6. **Custom board limits:** none beyond the custom dialog's sliders. If the sliders allow it, it is fine online.

7. **Which games go online (decided 2026-11-08):** to keep easy custom games from flooding the tables, only Beginner, Intermediate, Expert, custom Medium and custom Hard are sent. Custom Easy games are kept locally only. Local scores keep all six categories.
8. **No scores backfill (decided 2026-11-08):** a score belongs to a category and a category has a game (application) key, so scores need no application column and Delta-V's existing rows need no migration. Another Mine's categories are created under its application.
9. **Turning online off** hides the player row after a confirmation; it does not delete what was saved online or the stored player.
10. **Leaderboard window (decided 2026-11-09, as in Delta-V):** the online table does not always start at the top.
    - **A player with no score in the category** sees the top of the board, from first place.
    - **A player with scores** sees the board around their best time in that category: some places above it and some below, with their own row marked, so they see who they are chasing and who is behind them. The window is about ten places each way, fewer at either end of the board (a player in first place sees first place and the ten below).
    - **Paging** goes up and down from the window, and there is a way back to the top.
    - A player is the online player (name and service), so the window follows who is set in the online player dialog, and changes when that changes.
    - **How it is read** is chosen when it is built. The scores service has `GetScores` (one category, paged, optionally for one player, so a player's best is `GetScores` for them sorted by value, count 1), `GetSimilarScores` (the scores within a margin of a value, one per player) and `GetRankings`. A window by place needs the player's rank first; if that is not cheap, a window by value (`GetSimilarScores`, or `GetScores` after working the rank out) is the fallback. Delta-V's own comparison uses `GetCompetingStatusCategories` and `GetTopScores`, which are the model for who counts as above and below.


## Status and what is left

Done: local scores and Scores page, the online player dialog and the settings switch/row (Flutter and Jaspr), in the shared `willshex_online_player` package (Another Mine keeps only its `Pref` store and wording), stored in `Pref` (`playerName`, `playerService`, `defaultCountry`, `remoteHighScoresEnabled`).

Left, in order:

1. Create the WillShex Limited publisher, the Another Mine application and the five categories under it (rollout step 1). The server's `AddPublisher` and `AddApplication` calls are empty stubs, so they need implementing in `javaspacecloud` first (or the entities added to the datastore directly). The old game's own key is not registered anywhere I could find, so its scores probably never arrived and a legacy migration is likely not needed (to confirm).
2. Make a `GameRecorder` (events above, fed from `GameBloc.onEvent`) and a `ScoreSubmitter` in `client_common` using `willshex_scores`: find or create the user from name and service (see User above; verified 2026-11-08: `SubmitScore` rejects a player SpaceCloud does not know, with "Nonexistent or deleted user", so call `AddUser` first, tolerating a failure when the player already exists; a player is matched by external system id and type, then by name and type, so send a name as well), map the stored country to `Country`, send the score with the density rule above, skipping Easy and solver games and anything under the minimum time for the board.
3. (Done: online wins are sent automatically, with a failed-send queue.) The replay viewer is done: an online row with a recording has a play button that opens the game played back from its mines and events (`Recording`, `ReplayCubit`), with a speed control and markers for probability, focus and pause (Flutter `ReplayPage`, Jaspr through `EmbeddedReplay`).
4. Online tab on the Scores page (the leaderboard window per category, paging, board). Each row shows the country flag, the name and the service icon, using `flagOf(country)` and `serviceImage(service)` from `willshex_online_player` (flags are the 16 by 11 images from the Objective-C game; a few countries have none and show no flag).
5. Text board and additional data (gzip + base64) on each send.
6. A searchable country list (all SpaceCloud countries are listed now, with flags, in `willshex_online_player`).
7. Move Delta-V Hosted and flame Delta-V onto `willshex_online_player` (it already has `asksNameAndService: false` for Game Center and Google Play, which leaves only the country).

## Acceptance

- A win on each difficulty and a custom board shows in Local, in order, on Flutter and on the Jaspr site, and survives a restart.
- With online on, the same win appears in the Online tab within a few seconds, with the right flag, and the admin can open its additional data and see the board.
- With the network off, a win is kept and sent later, once.
- An autosolver win is never sent.
- Changing the name keeps the same SpaceCloud user.
