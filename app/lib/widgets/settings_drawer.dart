import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.inversePrimary,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Row(
              children: const [
                Icon(Icons.settings, size: 32),
                SizedBox(width: 12),
                Text("Settings", style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text("Controls", style: TextStyle(fontSize: 18)),
                ),
                const Divider(thickness: 2),
                Consumer<SettingsService>(
                  builder:
                      (_, settings, __) => Column(
                        children: [
                          RadioListTile<ControlMode>(
                            title: const Text("Buttons"),
                            value: ControlMode.buttons,
                            groupValue: settings.controlMode,
                            onChanged:
                                (value) => settings.updateControlMode(value!),
                          ),
                          RadioListTile<ControlMode>(
                            title: const Text("Joystick"),
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
                  child: Text("Theme", style: TextStyle(fontSize: 18)),
                ),
                const Divider(thickness: 2),
                Consumer<SettingsService>(
                  builder:
                      (_, settings, __) => Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: const Text("System"),
                            value: ThemeMode.system,
                            groupValue: settings.themeMode,
                            onChanged: (value) => settings.updateTheme(value!),
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text("Light"),
                            value: ThemeMode.light,
                            groupValue: settings.themeMode,
                            onChanged: (value) => settings.updateTheme(value!),
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text("Dark"),
                            value: ThemeMode.dark,
                            groupValue: settings.themeMode,
                            onChanged: (value) => settings.updateTheme(value!),
                          ),
                          SwitchListTile(
                            title: const Text("Dynamic colors"),
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
