import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RosSocketService {
  final WebSocketChannel _channel;

  RosSocketService(String url)
    : _channel = WebSocketChannel.connect(Uri.parse(url));

  void sendCommand(double linear, double angular) {
    final command = {"linear": linear, "angular": angular};
    final message = jsonEncode(command);
    if (kDebugMode) print("Sending: $message");
    _channel.sink.add(message);
  }

  void close() => _channel.sink.close();
}
