import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../services/settings_service.dart';

/// Provides methods for interacting with the robot's map and navigation services.
class MapService {
  /// The settings service used for configuration.
  final SettingsService settings;

  /// Creates a [MapService] with the given [settings].
  MapService(this.settings);

  /// Fetches the map image for the given [mapName].
  ///
  /// Returns a [File] and decoded [img.Image] tuple if successful, or null on failure.
  Future<(File, img.Image)?> fetchMapImage(String mapName) async {
    try {
      final response = await http.get(
        Uri.parse(
          AppConfig.mapDownloadUrl(settings.ip, settings.port, mapName),
        ),
      );
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/map_$mapName.png');
        await file.writeAsBytes(response.bodyBytes);
        final imageData = img.decodeImage(response.bodyBytes);
        if (imageData == null) return null;
        final rgbImage = imageData.convert(numChannels: 3);
        return (file, rgbImage);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches the robot's current position as an (x, y) tuple.
  ///
  /// Returns null if the position could not be retrieved.
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

  /// Sends a navigation goal to the robot at position ([x], [y]).
  ///
  /// Returns true if the goal was sent successfully.
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

  /// Cancels the current navigation goal.
  ///
  /// Returns true if the goal was cancelled successfully.
  Future<bool> cancelGoal() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.cancelGoalUrl(settings.ip, settings.port)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Starts the mapping process on the robot.
  ///
  /// Returns true if mapping started successfully.
  Future<bool> startMapping() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.mappingStartUrl(settings.ip, settings.port)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Stops the mapping process on the robot.
  ///
  /// Returns true if mapping stopped successfully.
  Future<bool> stopMapping() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.mappingStopUrl(settings.ip, settings.port)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Checks if mapping is active by attempting to connect to the mapping stream.
  ///
  /// Returns true if the stream is available (status 200), false otherwise.
  Future<bool> isMappingActive() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.mappingStreamUrl(settings.ip, settings.port)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Saves the current mapping with the given [mapName].
  ///
  /// Returns true if the map was saved successfully.
  Future<bool> saveMapping(String mapName) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.mapSaveUrl(settings.ip, settings.port)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'map_name': mapName}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the list of available maps from the robot.
  ///
  /// Returns a list of map names (without the .yaml extension).
  Future<List<String>> fetchMapList() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.mapListUrl(settings.ip, settings.port)),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['maps'] is List) {
          // Remove .yaml extension for comparison
          return (data['maps'] as List)
              .map((e) => e.toString().replaceAll('.yaml', ''))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Changes the currently active map to [mapName].
  ///
  /// Returns true if the map was changed successfully.
  Future<bool> changeMap(String mapName) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.mapChangeUrl(settings.ip, settings.port)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'map_name': mapName}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
