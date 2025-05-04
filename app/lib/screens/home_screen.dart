import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import '../widgets/controls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late WebSocketChannel _rosChannel;
  final String _streamUrl = 'http://10.0.2.2:8080/stream?topic=/camera/image_raw';

  @override
  void initState() {
    super.initState();
    _connectToROS();
  }

  void _connectToROS() {
    _rosChannel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8000/ws/cmd_vel'),
    );
  }

  void _sendCommand(double linear, double angular) {
    final command = {
      "linear": linear,
      "angular": angular,
    };
    final message = jsonEncode(command);
    if (kDebugMode) {
      print("Sending: $message");
    }
    _rosChannel.sink.add(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NaviMate")),
      body: Column(
        children: [
          // Video stream
          Expanded(
            child: Center(
              child: Mjpeg(
                stream: _streamUrl,
                isLive: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Button controls
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
    _rosChannel.sink.close();
    super.dispose();
  }
}
