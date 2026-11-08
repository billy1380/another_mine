import "package:another_mine_common/bloc/game/game_bloc.dart";
import "package:another_mine_common/model/auto_solver_type.dart";
import "package:another_mine_common/scores/online_scores.dart";
import "package:another_mine_common/services/pref.dart";
import "package:another_mine_common/services/provider.dart";
import "package:another_mine_common/strings.dart";
import "package:flutter/material.dart";
import "package:another_mine_flutter/widgets/small_picture.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";
import "package:willshex_embedding/willshex_embedding.dart";
import "package:go_router/go_router.dart";

class SettingsPage extends StatefulWidget {
  static const String routePath = "/settings";

  static GoRouterWidgetBuilder builder = (context, state) =>
      const SettingsPage._();

  const SettingsPage._() : showAppBar = true;

  /// For use inside another app, which supplies the page title.
  const SettingsPage.embedded({super.key}) : showAppBar = false;

  final bool showAppBar;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _animate;
  late int _scoresRetained;
  late bool _remoteScoresEnabled;
  late bool _customBgEnabled;
  int? _customBgColor;
  late AutoSolverType _autoSolverType;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    setState(() {
      _animate = Provider.pref.animate;
      _scoresRetained = Provider.pref.scoresRetained;
      _remoteScoresEnabled = Provider.pref.remoteScoresEnabled;
      _customBgEnabled = Provider.pref.customBgEnabled;
      _customBgColor = Provider.pref.customBgColor;
      _autoSolverType = Provider.pref.autoSolverType;
    });
  }

  /// `name · [logo] service · [flag] country`; hovering, or pressing and
  /// holding, a picture says what it is.
  Widget _onlinePlayerSummary() {
    final OnlinePlayer player = onlineScores.player;
    final DialogImage? flag = flagOf(player.country);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text("${player.name} ·"),
        SmallPicture(serviceImage(player.service), height: 20),
        Text("${serviceName(player.service)} ·"),
        if (flag != null) SmallPicture(flag),
        Text(countryName(player.country)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text(Strings.settingsTitle))
          : null,
      body: ListView(
        children: [
          ListTile(
            title: Text(
              Strings.gameSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text(Strings.animationsTitle),
            subtitle: const Text(Strings.animationsSubtitle),
            value: _animate,
            onChanged: (value) async {
              setState(() {
                _animate = value;
              });
              await Provider.pref.setBool(Pref.keyAnimate, value);
            },
          ),
          ListTile(
            title: const Text(Strings.autoSolverStrategyTitle),
            subtitle: Text(_autoSolverType.description),
            trailing: DropdownButton<AutoSolverType>(
              value: _autoSolverType,
              onChanged: (AutoSolverType? value) async {
                if (value != null) {
                  setState(() {
                    _autoSolverType = value;
                  });
                  await Provider.pref.setString(
                    Pref.keyAutoSolverType,
                    value.name,
                  );
                }
              },
              items: AutoSolverType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.title)))
                  .toList(),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(
              Strings.highScoresSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            title: const Text(Strings.localScoresRetainedTitle),
            subtitle: Text(
              Strings.keepUpToScores.replaceFirst(
                "%s",
                _scoresRetained.toString(),
              ),
            ),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                min: 10,
                max: 99,
                divisions: 89,
                value: _scoresRetained.toDouble(),
                label: _scoresRetained.toString(),
                onChanged: (value) async {
                  setState(() {
                    _scoresRetained = value.round();
                  });
                  await Provider.pref.setInt(
                    Pref.keyScoresRetained,
                    _scoresRetained,
                  );
                },
              ),
            ),
          ),
          SwitchListTile(
            title: const Text(Strings.onlineHighScoresTitle),
            subtitle: const Text(Strings.onlineHighScoresSubtitle),
            value: _remoteScoresEnabled,
            onChanged: (value) async {
              final bool changed = value
                  ? await onlineScores.turnOn()
                  : await onlineScores.turnOff();

              if (changed && mounted) {
                setState(() => _remoteScoresEnabled = value);
              }
            },
          ),
          if (_remoteScoresEnabled)
            ListTile(
              title: const Text(Strings.onlinePlayerTitle),
              subtitle: _onlinePlayerSummary(),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                await onlineScores.edit();
                if (mounted) setState(() {});
              },
            ),
          const Divider(),
          ListTile(
            title: Text(
              Strings.appearanceSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text(Strings.customBgColorEnabledTitle),
            subtitle: const Text(Strings.customBgColorEnabledSubtitle),
            value: _customBgEnabled,
            onChanged: (value) async {
              final bloc = context.read<GameBloc>();
              setState(() {
                _customBgEnabled = value;
              });
              await Provider.pref.setBool(Pref.keyCustomBgEnabled, value);

              if (mounted) {
                bloc.add(const RefreshSettings());
              }
            },
          ),
          if (_customBgEnabled)
            ListTile(
              title: const Text(Strings.backgroundColorTitle),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _customBgColor != null
                      ? Color(_customBgColor!)
                      : Colors.blue,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onTap: () async {
                final bloc = context.read<GameBloc>();
                Color pickerColor = _customBgColor != null
                    ? Color(_customBgColor!)
                    : Colors.blue;

                final Color? color = await showDialog<Color>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(Strings.chooseBackgroundColorTitle),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: pickerColor,
                          onColorChanged: (Color color) {
                            pickerColor = color;
                          },
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(Strings.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, pickerColor),
                          child: const Text(Strings.select),
                        ),
                      ],
                    );
                  },
                );
                if (color != null) {
                  setState(() {
                    _customBgColor = color.toARGB32();
                  });
                  await Provider.pref.setInt(
                    Pref.keyCustomBgColor,
                    color.toARGB32(),
                  );

                  if (mounted) {
                    bloc.add(const RefreshSettings());
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
