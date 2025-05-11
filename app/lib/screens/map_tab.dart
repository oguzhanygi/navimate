import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/map_controller.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  bool _isZoomingOrPanning = false;

  late final MapController controller;

  @override
  void initState() {
    super.initState();
    controller = MapController();
    controller.loadMap();
    controller.startPositionUpdates();
  }

  @override
  void dispose() {
    controller.stopPositionUpdates();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<MapController>(
        builder: (context, map, _) {
          final colors = Theme.of(context).colorScheme;

          if (map.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (map.errorMessage.isNotEmpty) {
            return Center(child: Text(map.errorMessage));
          }
          if (map.mapFile == null || map.mapImage == null) {
            return const Center(child: Text('No map available'));
          }

          return GestureDetector(
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
                          color: colors.inversePrimary,
                          size: 40,
                        ),
                      ),
                    if (map.robotPixel != null)
                      Positioned(
                        left: map.robotPixel!.dx - 10,
                        top: map.robotPixel!.dy - 10,
                        child: Icon(
                          Icons.smart_toy,
                          color: colors.inversePrimary,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
