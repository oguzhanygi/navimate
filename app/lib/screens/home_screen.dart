import 'package:flutter/material.dart';

import '../services/ros_socket_service.dart';
import '../widgets/stream_widget.dart';
import '../widgets/selected_control.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RosSocketService _rosService;
  final String _streamUrl =
      'http://10.0.2.2:8080/stream?topic=/camera/image_raw';
  bool _isJoystickMode = true;

  @override
  void initState() {
    super.initState();
    _rosService = RosSocketService('ws://10.0.2.2:8000/ws/cmd_vel');
  }

  void _sendCommand(double linear, double angular) {
    _rosService.sendCommand(linear, angular);
  }

  void _toggleControlMode() {
    setState(() {
      _isJoystickMode = !_isJoystickMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NaviMate", style: TextStyle(fontSize: 24)),
        backgroundColor: colors.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: StreamWidget(_streamUrl))),
          Expanded(
            child: Center(
              child: SelectedControl(
                isJoystickMode: _isJoystickMode,
                onCommand: _sendCommand,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleControlMode,
        tooltip: 'Switch Control Mode',
        child: Icon(_isJoystickMode ? Icons.touch_app : Icons.gamepad),
      ),
    );
  }

  @override
  void dispose() {
    _rosService.close();
    super.dispose();
  }
}
