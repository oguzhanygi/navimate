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
  void _sendCommand(double linear, double angular) {
    final rosService = Provider.of<RosSocketService>(context, listen: false);
    rosService.sendCommand(linear, angular);
  }

  @override
  void dispose() {
    final rosService = Provider.of<RosSocketService>(context, listen: false);
    rosService.close();
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
            child: Center(
              child: StreamWidget(
                AppConfig.cameraStreamUrl(settings.ip, settings.port),
              ),
            ),
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
