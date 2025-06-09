import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/mapping_controller.dart';

class MappingControls extends StatelessWidget {
  final PageController pageController;

  const MappingControls({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    final mappingController = Provider.of<MappingController>(context);
    final mapService = mappingController.mapService;
    final colors = Theme.of(context).colorScheme;

    Future<void> promptAndSaveMapping() async {
      final scaffold = ScaffoldMessenger.of(context);
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Save Map'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Map Name',
                  hintText: 'Enter map name',
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).pop(controller.text.trim()),
                  child: Text('Save'),
                ),
              ],
            ),
      );

      if (result != null && result.isNotEmpty) {
        final existingMaps = await mapService.fetchMapList();
        if (existingMaps.contains(result)) {
          final overwrite = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Overwrite Map?'),
                  content: Text(
                    'A map named "$result" already exists. Overwrite it?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Overwrite'),
                    ),
                  ],
                ),
          );
          if (overwrite != true) return;
        }
        final success = await mappingController.saveMapping(result);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(success ? "Map saved!" : "Failed to save map"),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }

    if (!mappingController.isMapping) {
      if (mappingController.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.map),
          label: Text("Discover Map"),
          onPressed: () async {
            await mappingController.startMapping();
            pageController.animateToPage(
              1,
              duration: Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        // The mapping stream should be rendered by the parent
        Positioned(
          bottom: 24,
          right: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'saveMappingBtn',
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                onPressed: promptAndSaveMapping,
                child: const Icon(Icons.save),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'stopMappingBtn',
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                onPressed: mappingController.stopMapping,
                child: const Icon(Icons.stop),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
