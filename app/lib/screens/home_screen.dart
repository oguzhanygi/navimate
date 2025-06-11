import 'package:flutter/material.dart';

import '../widgets/settings_drawer.dart';
import 'camera_tab.dart';
import 'map_tab.dart';

/// The main home screen of the app, providing navigation between Camera and Map tabs.
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("NaviMate", style: TextStyle(fontSize: 24)),
          backgroundColor: colors.primary,
          foregroundColor: colors.surface,
          bottom: TabBar(
            tabs: [Tab(text: "Camera"), Tab(text: "Map")],
            labelColor: colors.surface,
            indicatorColor: colors.onSurface,
            unselectedLabelColor: colors.surface.withValues(alpha: 0.8),
          ),
        ),
        drawer: const SettingsDrawer(),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [CameraTab(), MapTab()],
        ),
      ),
    );
  }
}
