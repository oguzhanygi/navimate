import 'package:flutter/material.dart';

class ButtonControls extends StatelessWidget {
  final void Function(double linear, double angular) onCommand;

  const ButtonControls({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNavButton(Icons.arrow_upward, 3.0, 0.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavButton(Icons.arrow_back, 0.0, 1.0),
            _buildNavButton(Icons.stop, 0.0, 0.0),
            _buildNavButton(Icons.arrow_forward, 0.0, -1.0),
          ],
        ),
        _buildNavButton(Icons.arrow_downward, -0.5, 0.0),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, double linear, double angular) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(icon, size: 40),
        style: IconButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(25),
        ),
        onPressed: () => onCommand(linear, angular),
      ),
    );
  }
}
