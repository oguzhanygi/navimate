import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

import '../services/ros_socket_service.dart';
import '../widgets/controls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RosSocketService _rosService;
  final String _streamUrl = 'http://10.0.2.2:8080/stream?topic=/camera/image_raw';

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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NaviMate", style: TextStyle(fontSize: 24)),
        backgroundColor: colors.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Mjpeg(
                stream: _streamUrl,
                isLive: true,
                fit: BoxFit.contain,
                error: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 128,
                        color: colors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Stream unavailable:\n${error.toString()}.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ButtonControls(onCommand: _sendCommand),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rosService.close();
    super.dispose();
  }
}