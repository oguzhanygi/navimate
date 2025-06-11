import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for sending velocity commands to the robot via WebSocket.
class RosSocketService {
  final WebSocketChannel _channel;

  /// Creates a [RosSocketService] and connects to the given [url].
  RosSocketService(String url)
    : _channel = WebSocketChannel.connect(Uri.parse(url));

  /// Sends a velocity command with [linear] and [angular] values to the robot.
  void sendCommand(double linear, double angular) {
    final command = {"linear": linear, "angular": angular};
    final message = jsonEncode(command);
    if (kDebugMode) print("Sending: $message");
    _channel.sink.add(message);
  }

  /// Closes the WebSocket connection.
  void close() => _channel.sink.close();
}
