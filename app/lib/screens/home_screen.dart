import 'package:flutter/material.dart';

import '../widgets/settings_drawer.dart';
import 'camera_tab.dart';
import 'map_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("NaviMate", style: TextStyle(fontSize: 24)),
          backgroundColor: colors.inversePrimary,
          bottom: TabBar(
            tabs: [Tab(text: "Camera"), Tab(text: "Map")],
            labelColor: colors.inverseSurface,
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
