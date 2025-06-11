import 'package:flutter/material.dart';

/// A widget that displays button controls for robot navigation.
///
/// Provides up, down, left, right, and stop buttons, and calls [onCommand]
/// with the appropriate linear and angular velocities when pressed.
class ButtonControls extends StatelessWidget {
  /// Callback when a navigation button is pressed.
  /// [linear] and [angular] represent the velocity commands.
  final void Function(double linear, double angular) onCommand;

  /// Creates a [ButtonControls] widget.
  const ButtonControls({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNavButton(colors, Icons.arrow_upward, 3.0, 0.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavButton(colors, Icons.arrow_back, 0.0, 1.0),
            _buildNavButton(colors, Icons.stop, 0.0, 0.0),
            _buildNavButton(colors, Icons.arrow_forward, 0.0, -1.0),
          ],
        ),
        _buildNavButton(colors, Icons.arrow_downward, -0.5, 0.0),
      ],
    );
  }

  /// Builds a navigation button with the given [icon], [linear], and [angular] values.
  Widget _buildNavButton(
    ColorScheme colors,
    IconData icon,
    double linear,
    double angular,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(icon, size: 40),
        style: IconButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.surface,
          padding: const EdgeInsets.all(25),
        ),
        onPressed: () => onCommand(linear, angular),
      ),
    );
  }
}
