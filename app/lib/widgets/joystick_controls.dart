import 'package:flutter/material.dart';

class Joystick extends StatefulWidget {
  final void Function(double linear, double angular) onMove;
  final VoidCallback onStop;

  const Joystick({super.key, required this.onMove, required this.onStop});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _dragOffset = Offset.zero;

  void _handleDrag(Offset localPosition, Size size) {
    final center = size.center(Offset.zero);
    Offset offset = localPosition - center;

    final maxDistance = size.width / 2;
    if (offset.distance > maxDistance) {
      offset = Offset.fromDirection(offset.direction, maxDistance);
    }

    final normalized = offset / maxDistance;

    final linear = -normalized.dy; // forward/backward
    final angular = -normalized.dx; // left/right

    widget.onMove(linear, angular);

    setState(() {
      _dragOffset = offset;
    });
  }

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

class _JoystickPainter extends CustomPainter {
  final Offset offset;
  final Color outerColor;
  final Color knobColor;

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
