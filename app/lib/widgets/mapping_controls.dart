import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/mapping_controller.dart';

/// Widget that displays mapping controls, including starting, stopping, and saving a map.
/// 
/// Shows a "Discover Map" button when mapping is not active, and floating action buttons
/// for saving or stopping mapping when mapping is active.
class MappingControls extends StatelessWidget {
  /// The page controller used to animate between pages when mapping starts.
  final PageController pageController;

  /// Creates a [MappingControls] widget.
  const MappingControls({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    final mappingController = Provider.of<MappingController>(context);
    final mapService = mappingController.mapService;
    final colors = Theme.of(context).colorScheme;

    /// Prompts the user for a map name and attempts to save the current mapping.
    /// If a map with the same name exists, asks for confirmation to overwrite.
    Future<void> promptAndSaveMapping() async {
      final scaffold = ScaffoldMessenger.of(context);
      final controller = TextEditingController();

      // Step 1: Prompt the user for a map name using a dialog with a TextField.
      // The dialog returns the entered name (trimmed) or null if cancelled.
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

      // Step 2: If a name was entered, check if it already exists.
      if (result != null && result.isNotEmpty) {
        final existingMaps = await mapService.fetchMapList();
        if (existingMaps.contains(result)) {
          // Step 3: If the map name exists, prompt the user to confirm overwrite.
          // This is a second dialog, returning true if the user confirms.
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
          // If the user cancels, abort the save.
          if (overwrite != true) return;
        }
        // Step 4: Attempt to save the map with the given name.
        // Show a SnackBar with the result (success or failure).
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
          /// Starts mapping and animates to the mapping page.
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
              /// Floating action button to save the current map.
              FloatingActionButton(
                heroTag: 'saveMappingBtn',
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                onPressed: promptAndSaveMapping,
                child: const Icon(Icons.save),
              ),
              const SizedBox(width: 16),
              /// Floating action button to stop mapping.
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
