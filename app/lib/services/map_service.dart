import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

class MapService {
  static Future<(File, img.Image)?> fetchMapImage() async {
    try {
      final response = await http.get(Uri.parse(AppConfig.mapUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/map.png');
        await file.writeAsBytes(response.bodyBytes);
        final imageData = img.decodeImage(response.bodyBytes);
        if (imageData == null) return null;
        return (file, imageData);
      }
    } catch (_) {}
    return null;
  }

  static Future<(double, double)?> fetchRobotPosition() async {
    try {
      final response = await http.get(Uri.parse(AppConfig.positionUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double x = (data['x'] as num).toDouble();
        final double y = (data['y'] as num).toDouble();
        return (x, y);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> sendGoal(double x, double y) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.goalUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'x': x, 'y': y}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
