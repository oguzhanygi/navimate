import 'package:flutter/material.dart';

import 'button_controls.dart';
import 'joystick_controls.dart';

class SelectedControl extends StatelessWidget {
  final bool isJoystickMode;
  final void Function(double linear, double angular) onCommand;

  const SelectedControl({
    super.key,
    required this.isJoystickMode,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return isJoystickMode
        ? Joystick(onMove: onCommand, onStop: () => onCommand(0.0, 0.0))
        : ButtonControls(onCommand: onCommand);
  }
}
