import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../services/settings_service.dart';

class MapService {
  final SettingsService settings;

  MapService(this.settings);

  Future<(File, img.Image)?> fetchMapImage() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.mapUrl(settings.ip, settings.port)),
      );
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/map.png');
        await file.writeAsBytes(response.bodyBytes);
        final imageData = img.decodeImage(response.bodyBytes);
        if (imageData == null) return null;
        final rgbImage = imageData.convert(numChannels: 3);
        return (file, rgbImage);
      }
    } catch (_) {}
    return null;
  }

  Future<(double, double)?> fetchRobotPosition() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.positionUrl(settings.ip, settings.port)),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double x = (data['x'] as num).toDouble();
        final double y = (data['y'] as num).toDouble();
        return (x, y);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> sendGoal(double x, double y) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.goalUrl(settings.ip, settings.port)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'x': x, 'y': y}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
