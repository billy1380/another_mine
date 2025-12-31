import "package:another_mine/services/pref.dart";
import "package:flutter/material.dart";
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
      _animate = Pref.service.animate;
      _scoresRetained = Pref.service.scoresRetained;
      _remoteScoresEnabled = Pref.service.remoteScoresEnabled;
      _defaultCountry = Pref.service.defaultCountry;
      _customBgEnabled = Pref.service.customBgEnabled;
      _customBgColor = Pref.service.customBgColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              "Game",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text("Animations"),
            subtitle: const Text("Enable tile reveal animations"),
            value: _animate,
            onChanged: (value) async {
              setState(() {
                _animate = value;
              });
              await Pref.service.setBool(Pref.keyAnimate, value);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(
              "High Scores",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            title: const Text("Local Scores Retained"),
            subtitle: Text("Keep up to $_scoresRetained scores"),
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
                  await Pref.service
                      .setInt(Pref.keyScoresRetained, _scoresRetained);
                },
              ),
            ),
          ),
          SwitchListTile(
            title: const Text("Online High Scores"),
            subtitle: const Text("Enable online leaderboards"),
            value: _remoteScoresEnabled,
            onChanged: (value) async {
              setState(() {
                _remoteScoresEnabled = value;
              });
              await Pref.service.setBool(Pref.keyRemoteScoresEnabled, value);
            },
          ),
          ListTile(
            title: const Text("Default Country"),
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
                        await Pref.service
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
              "Appearance",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text("Custom Background Color"),
            subtitle: const Text("Use a custom background color"),
            value: _customBgEnabled,
            onChanged: (value) async {
              setState(() {
                _customBgEnabled = value;
              });
              await Pref.service.setBool(Pref.keyCustomBgEnabled, value);
            },
          ),
          if (_customBgEnabled)
            ListTile(
              title: const Text("Background Color"),
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
                Color pickerColor = _customBgColor != null
                    ? Color(_customBgColor!)
                    : Colors.blue;

                final Color? color = await showDialog<Color>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Choose Background Color"),
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
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, pickerColor),
                          child: const Text("Select"),
                        ),
                      ],
                    );
                  },
                );
                if (color != null) {
                  setState(() {
                    _customBgColor = color.toARGB32();
                  });
                  await Pref.service
                      .setInt(Pref.keyCustomBgColor, color.toARGB32());
                }
              },
            ),
        ],
      ),
    );
  }
}
