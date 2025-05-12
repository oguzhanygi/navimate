import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/map_service.dart';
import '../config/app_config.dart';
import '../services/settings_service.dart';

class MapController extends ChangeNotifier {
  final SettingsService settings;
  final MapService mapService;
  File? mapFile;
  img.Image? mapImage;
  Offset? robotPixel;
  Offset? selectedPixel;
  bool isLoading = false;
  String errorMessage = '';

  final GlobalKey mainImageKey = GlobalKey();
  Timer? _positionTimer;

  MapController(this.settings) : mapService = MapService(settings);

  Future<void> loadMap() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final result = await mapService.fetchMapImage();
    if (result != null) {
      mapFile = result.$1;
      mapImage = result.$2;
    } else {
      errorMessage = 'Failed to load map.';
    }

    isLoading = false;
    notifyListeners();
  }

  void startPositionUpdates() {
    _positionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateRobotPosition(),
    );
  }

  void stopPositionUpdates() {
    _positionTimer?.cancel();
  }

  Future<void> updateRobotPosition() async {
    if (mapImage == null || mainImageKey.currentContext == null) return;

    final pos = await mapService.fetchRobotPosition();
    if (pos == null) return;

    final (x, y) = pos;
    final pixelX = (x - AppConfig.mapOriginX) * AppConfig.mapResolution;
    final pixelY =
        mapImage!.height - (y - AppConfig.mapOriginY) * AppConfig.mapResolution;

    final renderBox =
        mainImageKey.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    final widgetX = pixelX * size.width / mapImage!.width;
    final widgetY = pixelY * size.height / mapImage!.height;

    robotPixel = Offset(widgetX, widgetY);
    notifyListeners();
  }

  Future<void> handleTap(TapUpDetails details) async {
    if (mapFile == null || mapImage == null) return;

    final renderBox =
        mainImageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(details.globalPosition);
    final Size renderSize = renderBox.size;

    final pixelX = localPos.dx * mapImage!.width / renderSize.width;
    final pixelY = localPos.dy * mapImage!.height / renderSize.height;

    if (pixelX < 0 ||
        pixelY < 0 ||
        pixelX >= mapImage!.width ||
        pixelY >= mapImage!.height) {
      return;
    }

    final pixel = mapImage!.getPixel(pixelX.toInt(), pixelY.toInt());
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;

    final isWhite = r == 254 && g == 254 && b == 254;
    if (!isWhite) return;

    selectedPixel = localPos;
    notifyListeners();

    final goalX = pixelX / AppConfig.mapResolution + AppConfig.mapOriginX;
    final goalY =
        (mapImage!.height - pixelY) / AppConfig.mapResolution +
        AppConfig.mapOriginY;

    await mapService.sendGoal(goalX, goalY);
  }
}
