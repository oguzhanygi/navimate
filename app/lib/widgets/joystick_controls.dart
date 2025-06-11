import 'package:flutter/material.dart';

/// A widget that displays a virtual joystick for controlling the robot.
/// 
/// [onMove] is called with normalized linear and angular values as the user drags the knob.
/// [onStop] is called when the user releases the joystick.
class Joystick extends StatefulWidget {
  /// Callback for joystick movement, provides [linear] and [angular] values.
  final void Function(double linear, double angular) onMove;

  /// Callback when joystick is released or cancelled.
  final VoidCallback onStop;

  /// Creates a [Joystick] widget.
  const Joystick({super.key, required this.onMove, required this.onStop});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _dragOffset = Offset.zero;

  /// Handles drag updates, calculates normalized joystick values, and calls [onMove].
  void _handleDrag(Offset localPosition, Size size) {
    // The center of the joystick widget
    final center = size.center(Offset.zero);
    // Offset from center to the current drag position
    Offset offset = localPosition - center;

    // The maximum distance the knob can move from the center (radius)
    final maxDistance = size.width / 2;
    // Clamp the offset to the joystick's circular boundary
    if (offset.distance > maxDistance) {
      offset = Offset.fromDirection(offset.direction, maxDistance);
    }

    // Normalize the offset to the range [-1, 1] for both axes
    final normalized = offset / maxDistance;

    // Map the normalized values to robot velocity commands:
    // - Y axis is inverted (up is negative in Flutter, but should be positive for forward)
    // - X axis is inverted for angular (right is negative, left is positive)
    final linear = -normalized.dy; // forward/backward
    final angular = -normalized.dx; // left/right

    // Send the normalized values to the callback
    widget.onMove(linear, angular);

    setState(() {
      _dragOffset = offset;
    });
  }

  /// Handles the end of a drag gesture, resets the joystick and calls [onStop].
  void _handleEnd() {
    widget.onStop();
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final outerColor = colors.primary.withValues(alpha: 0.3);
    final knobColor = colors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size.square(200);
        return GestureDetector(
          onPanUpdate: (details) => _handleDrag(details.localPosition, size),
          onPanEnd: (_) => _handleEnd(),
          onPanCancel: _handleEnd,
          child: CustomPaint(
            size: size,
            painter: _JoystickPainter(
              offset: _dragOffset,
              outerColor: outerColor,
              knobColor: knobColor,
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the joystick widget.
class _JoystickPainter extends CustomPainter {
  /// The offset of the joystick knob from the center.
  final Offset offset;

  /// The color of the joystick's outer circle.
  final Color outerColor;

  /// The color of the joystick knob.
  final Color knobColor;

  /// Creates a [_JoystickPainter] with the given [offset], [outerColor], and [knobColor].
  _JoystickPainter({
    required this.offset,
    required this.outerColor,
    required this.knobColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerPaint = Paint()..color = outerColor;
    final knobPaint = Paint()..color = knobColor;

    canvas.drawCircle(center, size.width / 2, outerPaint);
    canvas.drawCircle(center + offset, 20, knobPaint);
  }

  @override
  bool shouldRepaint(_JoystickPainter old) {
    return old.offset != offset ||
        old.outerColor != outerColor ||
        old.knobColor != knobColor;
  }
}
