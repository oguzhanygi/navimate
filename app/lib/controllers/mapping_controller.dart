import 'package:flutter/material.dart';
import '../services/map_service.dart';

/// Controls the mapping process, including starting, stopping, and saving maps.
class MappingController extends ChangeNotifier {
  /// The map service used for mapping operations.
  final MapService mapService;

  /// Whether mapping is currently active.
  bool isMapping = false;

  /// Whether a mapping operation is loading.
  bool isLoading = false;

  /// Creates a [MappingController] with the given [mapService].
  MappingController(this.mapService);

  /// Checks if mapping is currently active and updates [isMapping].
  Future<void> checkMappingStatus() async {
    isLoading = true;
    notifyListeners();
    isMapping = await mapService.isMappingActive();
    isLoading = false;
    notifyListeners();
  }

  /// Starts the mapping process.
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

  /// Stops the mapping process.
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

  /// Saves the current map with the given [mapName].
  ///
  /// Returns `true` if the map was saved successfully, `false` otherwise.
  Future<bool> saveMapping(String mapName) async {
    isLoading = true;
    notifyListeners();
    final success = await mapService.saveMapping(mapName);
    isLoading = false;
    notifyListeners();
    return success;
  }
}
