import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late String _originalIp;
  late String _originalPort;
  bool _ipChanged = false;
  bool _portChanged = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsService>(context, listen: false);
    _originalIp = settings.ip;
    _originalPort = settings.port.toString();
    _ipController = TextEditingController(text: _originalIp);
    _portController = TextEditingController(text: _originalPort);

    _ipController.addListener(() {
      setState(() {
        _ipChanged = _ipController.text != _originalIp;
      });
    });
    _portController.addListener(() {
      setState(() {
        _portChanged = _portController.text != _originalPort;
      });
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      width: 250,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
            child: Row(
              children: [
                Icon(Icons.settings, size: 24, color: colorScheme.surface),
                SizedBox(width: 12),
                Text(
                  "Settings",
                  style: TextStyle(fontSize: 20, color: colorScheme.surface),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),

              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text("Connection", style: TextStyle(fontSize: 15)),
                ),
                const Divider(thickness: 2),
                Consumer<SettingsService>(
                  builder:
                      (_, settings, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'IP Address',
                              hintText: '10.0.2.2',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.check),
                                onPressed:
                                    _ipChanged
                                        ? () {
                                          settings.updateIp(_ipController.text);
                                          setState(() {
                                            _originalIp = _ipController.text;
                                            _ipChanged = false;
                                          });
                                        }
                                        : null,
                                tooltip: 'Apply',
                                disabledColor: Colors.grey,
                              ),
                            ),
                            controller: _ipController,
                          ),
                          SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Port',
                              hintText: '8000',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.check),
                                onPressed:
                                    _portChanged
                                        ? () {
                                          final port = int.tryParse(
                                            _portController.text,
                                          );
                                          if (port != null) {
                                            settings.updatePort(
                                              port.toString(),
                                            );
                                            setState(() {
                                              _originalPort =
                                                  _portController.text;
                                              _portChanged = false;
                                            });
                                          }
                                        }
                                        : null,
                                tooltip: 'Apply',
                                disabledColor: Colors.grey,
                              ),
                            ),
                            controller: _portController,
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 12),
                        ],
                      ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text("Controls", style: TextStyle(fontSize: 15)),
                ),
                const Divider(thickness: 2),
                Consumer<SettingsService>(
                  builder:
                      (_, settings, __) => Column(
                        children: [
                          RadioListTile<ControlMode>(
                            title: const Text(
                              "Buttons",
                              style: TextStyle(fontSize: 15),
                            ),
                            value: ControlMode.buttons,
                            groupValue: settings.controlMode,
                            onChanged:
                                (value) => settings.updateControlMode(value!),
                          ),
                          RadioListTile<ControlMode>(
                            title: const Text(
                              "Joystick",
                              style: TextStyle(fontSize: 15),
                            ),
                            value: ControlMode.joystick,
                            groupValue: settings.controlMode,
                            onChanged:
                                (value) => settings.updateControlMode(value!),
                          ),
                        ],
                      ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text("Theme", style: TextStyle(fontSize: 15)),
                ),
                const Divider(thickness: 2),
                Consumer<SettingsService>(
                  builder:
                      (_, settings, __) => Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: const Text(
                              "System",
                              style: TextStyle(fontSize: 15),
                            ),
                            value: ThemeMode.system,
                            groupValue: settings.themeMode,
                            onChanged: (value) => settings.updateTheme(value!),
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text(
                              "Light",
                              style: TextStyle(fontSize: 15),
                            ),
                            value: ThemeMode.light,
                            groupValue: settings.themeMode,
                            onChanged: (value) => settings.updateTheme(value!),
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text(
                              "Dark",
                              style: TextStyle(fontSize: 15),
                            ),
                            value: ThemeMode.dark,
                            groupValue: settings.themeMode,
                            onChanged: (value) => settings.updateTheme(value!),
                          ),
                          SwitchListTile(
                            title: const Text(
                              "Dynamic colors",
                              style: TextStyle(fontSize: 15),
                            ),
                            value: settings.useDynamicColor,
                            contentPadding: EdgeInsets.symmetric(horizontal: 5),
                            onChanged:
                                (value) =>
                                    settings.updateUseDynamicColor(value),
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
