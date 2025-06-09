import 'package:flutter/material.dart';
import '../services/map_service.dart';

class MappingController extends ChangeNotifier {
  final MapService mapService;

  bool isMapping = false;
  bool isLoading = false;

  MappingController(this.mapService);

  Future<void> checkMappingStatus() async {
    isLoading = true;
    notifyListeners();
    isMapping = await mapService.isMappingActive();
    isLoading = false;
    notifyListeners();
  }

  Future<void> startMapping() async {
    isLoading = true;
    notifyListeners();
    final started = await mapService.startMapping();
    if (started) {
      isMapping = true;
    }
    isLoading = false;
    notifyListeners();
    await checkMappingStatus();
  }

  Future<void> stopMapping() async {
    isLoading = true;
    notifyListeners();
    final stopped = await mapService.stopMapping();
    if (stopped) {
      isMapping = false;
    }
    isLoading = false;
    notifyListeners();
    await checkMappingStatus();
  }

  Future<bool> saveMapping(String mapName) async {
    isLoading = true;
    notifyListeners();
    final success = await mapService.saveMapping(mapName);
    isLoading = false;
    notifyListeners();
    return success;
  }
}
