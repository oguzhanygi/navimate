import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../widgets/stream_widget.dart';
import '../widgets/selected_control.dart';
import '../widgets/mapping_controls.dart';
import '../controllers/mapping_controller.dart';
import '../services/ros_socket_service.dart';
import '../services/settings_service.dart';
import '../services/map_service.dart';

/// The camera tab, showing the camera stream and mapping controls.
class CameraTab extends StatefulWidget {
  /// Creates a [CameraTab].
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  RosSocketService? _rosService;
  late MapService _mapService;
  late SettingsService _settings;
  late MappingController _mappingController;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // - We use listen: false here because we only want to grab the current value,
    //   not rebuild this widget when the provider changes.
    // - RosSocketService is provided as a ProxyProvider in main.dart, so it is
    //   automatically updated if the SettingsService changes.
    _rosService = Provider.of<RosSocketService>(context, listen: false);
    _settings = Provider.of<SettingsService>(context, listen: false);
    _mapService = MapService(_settings);
    _mappingController = MappingController(_mapService);
    _mappingController.checkMappingStatus();
  }

  /// Sends a velocity command to the robot.
  void _sendCommand(double linear, double angular) {
    _rosService?.sendCommand(linear, angular);
  }

  /// Builds the camera stream page.
  Widget _buildCameraPage(SettingsService settings) {
    return StreamWidget(AppConfig.cameraStreamUrl(settings.ip, settings.port));
  }

  /// Builds the mapping page, showing mapping controls and stream.
  Widget _buildMappingPage(BuildContext context) {
    return Consumer<MappingController>(
      builder: (context, mappingController, _) {
        if (!mappingController.isMapping) {
          return MappingControls(pageController: _pageController);
        }
        return Stack(
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: StreamWidget(
                  AppConfig.mappingStreamUrl(_settings.ip, _settings.port),
                ),
              ),
            ),
            MappingControls(pageController: _pageController),
          ],
        );
      },
    );
  }

  /// Builds the page indicator for the camera/mapping pages.
  Widget _buildPageIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          width: _currentPage == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    // Note: _rosService is provided by Provider and disposed in main.dart's ProxyProvider.
    // Calling close() here is safe because the service's close() method is idempotent,
    // but be careful if you change the disposal logic in the future.
    _rosService?.close();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final isJoystickMode = settings.controlMode == ControlMode.joystick;

    // We use ChangeNotifierProvider.value here because _mappingController is created
    // in didChangeDependencies and reused for the lifetime of this widget.
    // This avoids creating a new controller on every build.
    return ChangeNotifierProvider.value(
      value: _mappingController,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            Widget mainContent;

            if (isWide) {
              mainContent = Row(
                children: [
                  Expanded(child: _buildCameraPage(settings)),
                  Expanded(child: _buildMappingPage(context)),
                ],
              );
            } else {
              mainContent = Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildCameraPage(settings),
                        _buildMappingPage(context),
                      ],
                    ),
                  ),
                  _buildPageIndicator(2),
                ],
              );
            }

            return Column(
              children: [
                Expanded(child: mainContent),
                Expanded(
                  child: Center(
                    child: SelectedControl(
                      isJoystickMode: isJoystickMode,
                      onCommand: _sendCommand,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
