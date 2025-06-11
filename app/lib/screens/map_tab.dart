import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/map_controller.dart';
import '../services/map_service.dart';
import '../services/settings_service.dart';

/// The tab that displays the map, robot position, and allows goal setting and map switching.
class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

/// State for [MapTab], manages map loading, robot position updates, and user interactions.
class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  bool _isZoomingOrPanning = false;

  late final MapController controller;

  @override
  void initState() {
    super.initState();
    // We use listen: false here because this is called only once at init,
    // and we don't want this widget to rebuild if SettingsService changes.
    final settings = Provider.of<SettingsService>(context, listen: false);
    controller = MapController(settings);
    controller.loadMap();
    controller.startPositionUpdates();
  }

  /// Stops robot position updates when the widget is disposed.
  @override
  void dispose() {
    controller.stopPositionUpdates();
    super.dispose();
  }

  /// Keeps the map tab alive when switching tabs.
  @override
  bool get wantKeepAlive => true;

  /// Shows a dialog for selecting a map from the available list.
  /// If a new map is selected, attempts to switch to it and reloads the map.
  Future<void> _showMapSelectionDialog(
    BuildContext context,
    MapController mapController,
  ) async {
    final mapService = MapService(mapController.settings);
    final maps = await mapService.fetchMapList();
    final current = mapController.currentMapName;

    if (maps.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No maps found!')));
      return;
    }

    // Show a dialog with a grid of available maps.
    // Each map is displayed as a thumbnail (loaded asynchronously) and its name.
    // The currently selected map is visually highlighted.
    // When a map is tapped, the dialog closes and returns the selected map name.
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Map'),
          content: SizedBox(
            width: 400,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: maps.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, idx) {
                final mapName = maps[idx];
                final isSelected = mapName == current;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(mapName),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.8)
                              : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    // Use FutureBuilder to asynchronously load the map thumbnail.
                    // This allows the dialog to show a loading spinner for each map until its image is fetched.
                    // If the image fails to load, show a placeholder icon.
                    child: FutureBuilder(
                      future: mapService.fetchMapImage(mapName),
                      builder: (context, snapshot) {
                        Widget imageWidget;
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          imageWidget = const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasData && snapshot.data != null) {
                          final file = snapshot.data!.$1;
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                          );
                        } else {
                          imageWidget = Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          );
                        }
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: imageWidget),
                            const SizedBox(height: 8),
                            Text(
                              mapName,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    // If a new map was selected, attempt to switch to it and reload the map.
    // Show a snackbar to indicate success or failure.
    if (selected != null && selected != current) {
      final changed = await mapService.changeMap(selected);
      if (changed) {
        mapController.currentMapName = selected;
        await mapController.loadMap();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Switched to map "$selected"')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch map!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Builds the map tab UI, including the map image, robot and goal markers, and map switching.
  @override
  Widget build(BuildContext context) {
    super.build(context);

    // We use ChangeNotifierProvider.value here because the controller is created
    // and owned by this State object, not by the Provider. This avoids issues
    // with disposing the controller at the wrong time.
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<MapController>(
        builder: (context, map, _) {
          final colors = Theme.of(context).colorScheme;

          Widget content;
          if (map.isLoading) {
            content = const Center(child: CircularProgressIndicator());
          } else if (map.errorMessage.isNotEmpty) {
            content = Center(child: Text(map.errorMessage));
          } else if (map.mapFile == null || map.mapImage == null) {
            content = const Center(child: Text('No map available'));
          } else {
            content = GestureDetector(
              onTapUp: (details) {
                if (!_isZoomingOrPanning) {
                  controller.handleTap(details);
                }
              },
              onScaleStart: (_) => setState(() => _isZoomingOrPanning = true),
              onScaleEnd: (_) => setState(() => _isZoomingOrPanning = false),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                clipBehavior: Clip.none,
                child: Center(
                  child: Stack(
                    children: [
                      Image.file(map.mapFile!, key: map.mainImageKey),
                      if (map.selectedPixel != null)
                        Positioned(
                          left: map.selectedPixel!.dx - 25,
                          top: map.selectedPixel!.dy - 30,
                          child: Icon(
                            Icons.location_pin,
                            color: colors.primary,
                            size: 40,
                          ),
                        ),
                      if (map.robotPixel != null)
                        Positioned(
                          left: map.robotPixel!.dx - 10,
                          top: map.robotPixel!.dy - 10,
                          child: Icon(
                            Icons.smart_toy,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text("Map"),
              actions: [
                IconButton(
                  icon: Icon(Icons.layers),
                  tooltip: "Switch Map",
                  onPressed: () => _showMapSelectionDialog(context, map),
                ),
              ],
            ),
            body: content,
            floatingActionButton:
                map.hasActiveGoal
                    ? FloatingActionButton.extended(
                      icon: Icon(Icons.cancel),
                      label: Text("Cancel Goal"),
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                      onPressed: () {
                        controller.cancelGoal();
                      },
                    )
                    : null,
          );
        },
      ),
    );
  }
}
