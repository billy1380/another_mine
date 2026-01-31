import "package:another_mine/bloc/game/game_bloc.dart";
import "package:another_mine/model/auto_solver_type.dart";
import "package:another_mine/services/pref.dart";
import "package:another_mine/services/provider.dart";
import "package:another_mine/strings.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";
import "package:go_router/go_router.dart";

class SettingsPage extends StatefulWidget {
  static const String routePath = "/settings";

  static GoRouterWidgetBuilder builder =
      (context, state) => const SettingsPage._();

  const SettingsPage._();

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _animate;
  late int _scoresRetained;
  late bool _remoteScoresEnabled;
  late String _defaultCountry;
  late bool _customBgEnabled;
  int? _customBgColor;
  late AutoSolverType _autoSolverType;

  final List<String> _countries = [
    "United Kingdom",
    "United States",
    "Canada",
    "Australia",
    "Germany",
    "France",
    "Spain",
    "Italy",
    "Japan",
    "China",
    "Brazil",
    "India",
  ];

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
      _defaultCountry = Provider.pref.defaultCountry;
      _customBgEnabled = Provider.pref.customBgEnabled;
      _customBgColor = Provider.pref.customBgColor;
      _autoSolverType = Provider.pref.autoSolverType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.settingsTitle),
      ),
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
            subtitle: Text(Strings.keepUpToScores
                .replaceFirst("%s", _scoresRetained.toString())),
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
                  await Provider.pref
                      .setInt(Pref.keyScoresRetained, _scoresRetained);
                },
              ),
            ),
          ),
          SwitchListTile(
            title: const Text(Strings.onlineHighScoresTitle),
            subtitle: const Text(Strings.onlineHighScoresSubtitle),
            value: _remoteScoresEnabled,
            onChanged: (value) async {
              setState(() {
                _remoteScoresEnabled = value;
              });
              await Provider.pref.setBool(Pref.keyRemoteScoresEnabled, value);
            },
          ),
          ListTile(
            title: const Text(Strings.defaultCountryTitle),
            subtitle: Text(_defaultCountry),
            enabled: _remoteScoresEnabled,
            trailing: DropdownButton<String>(
              value: _countries.contains(_defaultCountry)
                  ? _defaultCountry
                  : _countries.first,
              onChanged: _remoteScoresEnabled
                  ? (String? value) async {
                      if (value != null) {
                        setState(() {
                          _defaultCountry = value;
                        });
                        await Provider.pref
                            .setString(Pref.keyDefaultCountry, value);
                      }
                    }
                  : null,
              items: _countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
            ),
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
                  await Provider.pref
                      .setInt(Pref.keyCustomBgColor, color.toARGB32());

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