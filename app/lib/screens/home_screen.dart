import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ros_socket_service.dart';
import '../services/settings_service.dart';
import '../widgets/selected_control.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/stream_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RosSocketService _rosService;
  final String _streamUrl =
      'http://10.0.2.2:8080/stream?topic=/camera/image_raw';

  @override
  void initState() {
    super.initState();
    _rosService = RosSocketService('ws://10.0.2.2:8000/ws/cmd_vel');
  }

  void _sendCommand(double linear, double angular) {
    _rosService.sendCommand(linear, angular);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final isJoystickMode = settings.controlMode == ControlMode.joystick;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NaviMate", style: TextStyle(fontSize: 24)),
        backgroundColor: colors.inversePrimary,
      ),
      drawer: const SettingsDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Center(child: StreamWidget(_streamUrl))),
            Expanded(
              child: Center(
                child: SelectedControl(
                  isJoystickMode: isJoystickMode,
                  onCommand: _sendCommand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rosService.close();
    super.dispose();
  }
}
