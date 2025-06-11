import 'package:flutter/material.dart';

import 'button_controls.dart';
import 'joystick_controls.dart';

/// Widget that displays either joystick or button controls based on [isJoystickMode].
class SelectedControl extends StatelessWidget {
  /// Whether to use joystick mode (true) or button mode (false).
  final bool isJoystickMode;

  /// Callback for sending movement commands with linear and angular velocities.
  final void Function(double linear, double angular) onCommand;

  /// Creates a [SelectedControl] widget.
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
