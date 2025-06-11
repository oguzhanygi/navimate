import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/map_service.dart';
import '../config/app_config.dart';
import '../services/settings_service.dart';

/// Controls map loading, robot position updates, and goal management for the map tab.
class MapController extends ChangeNotifier {
  /// The settings service used for configuration.
  final SettingsService settings;

  /// The map service for network operations.
  final MapService mapService;

  /// The currently selected map name.
  String currentMapName = 'turtlebot3_house';

  /// The currently loaded map file.
  File? mapFile;

  /// The decoded map image.
  img.Image? mapImage;

  /// The robot's position in pixel coordinates.
  Offset? robotPixel;

  /// The selected goal position in pixel coordinates.
  Offset? selectedPixel;

  /// Whether the map is currently loading.
  bool isLoading = false;

  /// The error message, if any.
  String errorMessage = '';

  /// Whether there is an active goal.
  bool hasActiveGoal = false;

  /// The key for the main map image widget.
  final GlobalKey mainImageKey = GlobalKey();

  Timer? _positionTimer;

  /// Creates a [MapController] with the given [settings].
  MapController(this.settings) : mapService = MapService(settings);

  /// Loads the current map image and notifies listeners.
  Future<void> loadMap() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final result = await mapService.fetchMapImage(currentMapName);
    if (result != null) {
      mapFile = result.$1;
      mapImage = result.$2;
    } else {
      errorMessage = 'Failed to load map.';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Starts periodic updates of the robot's position.
  void startPositionUpdates() {
    _positionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateRobotPosition(),
    );
  }

  /// Stops periodic updates of the robot's position.
  void stopPositionUpdates() {
    _positionTimer?.cancel();
  }

  /// Updates the robot's position on the map.
  Future<void> updateRobotPosition() async {
    if (mapImage == null || mainImageKey.currentContext == null) return;

    final pos = await mapService.fetchRobotPosition();
    if (pos == null) return;

    final (x, y) = pos;

    // Convert robot world coordinates (meters) to map image pixel coordinates.
    // The map origin (AppConfig.mapOriginX/Y) and resolution (pixels per meter) are used.
    final pixelX = (x - AppConfig.mapOriginX) * AppConfig.mapResolution;
    // Y axis is typically inverted in image coordinates, so subtract from image height.
    final pixelY =
        mapImage!.height - (y - AppConfig.mapOriginY) * AppConfig.mapResolution;

    final renderBox =
        mainImageKey.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    // Scale pixel coordinates to widget coordinates, accounting for widget size vs. image size.
    final widgetX = pixelX * size.width / mapImage!.width;
    final widgetY = pixelY * size.height / mapImage!.height;

    robotPixel = Offset(widgetX, widgetY);
    notifyListeners();
  }

  /// Handles a tap on the map, sending a goal if appropriate.
  Future<void> handleTap(TapUpDetails details) async {
    if (mapFile == null || mapImage == null) return;

    final renderBox =
        mainImageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Convert the tap's global position to a local position within the map widget.
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final Size renderSize = renderBox.size;

    // Map the local widget coordinates to image pixel coordinates.
    final pixelX = localPos.dx * mapImage!.width / renderSize.width;
    final pixelY = localPos.dy * mapImage!.height / renderSize.height;

    // Ensure the tap is within the bounds of the image.
    if (pixelX < 0 ||
        pixelY < 0 ||
        pixelX >= mapImage!.width ||
        pixelY >= mapImage!.height) {
      return;
    }

    // Get the color of the tapped pixel.
    final pixel = mapImage!.getPixel(pixelX.toInt(), pixelY.toInt());
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;

    // Only allow goal setting on "white" pixels (r==254, g==254, b==254),
    // which are assumed to represent free/navigable space in the map.
    final isWhite = r == 254 && g == 254 && b == 254;
    if (!isWhite) return;

    // Show marker immediately for UI feedback.
    selectedPixel = localPos;
    hasActiveGoal = true;
    notifyListeners();

    // Cancel previous goal if there is one.
    // This ensures only one goal is active at a time.
    if (hasActiveGoal) {
      await mapService.cancelGoal();
    }

    // Convert image pixel coordinates back to world coordinates for the robot.
    final goalX = pixelX / AppConfig.mapResolution + AppConfig.mapOriginX;
    final goalY =
        (mapImage!.height - pixelY) / AppConfig.mapResolution +
        AppConfig.mapOriginY;

    final sent = await mapService.sendGoal(goalX, goalY);

    // If sending goal failed, clear marker and FAB to reflect failure.
    if (!sent) {
      hasActiveGoal = false;
      selectedPixel = null;
      notifyListeners();
    }
  }

  /// Cancels the current goal.
  Future<void> cancelGoal() async {
    await mapService.cancelGoal();
    hasActiveGoal = false;
    selectedPixel = null;
    notifyListeners();
  }
}
