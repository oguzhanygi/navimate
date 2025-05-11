import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../widgets/stream_widget.dart';
import '../widgets/selected_control.dart';
import '../services/ros_socket_service.dart';
import '../services/settings_service.dart';

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  late RosSocketService _rosService;

  @override
  void initState() {
    super.initState();
    _rosService = RosSocketService(AppConfig.velocityWebSocketUrl);
  }

  void _sendCommand(double linear, double angular) {
    _rosService.sendCommand(linear, angular);
  }

  @override
  void dispose() {
    _rosService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final isJoystickMode = settings.controlMode == ControlMode.joystick;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(child: StreamWidget(AppConfig.cameraStreamUrl)),
          ),
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
    );
  }
}
