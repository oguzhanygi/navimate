import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

/// A widget that displays an MJPEG video stream from the given [streamUrl].
///
/// Shows an error message if the stream is unavailable.
class StreamWidget extends StatelessWidget {
  /// The URL of the MJPEG stream to display.
  final String streamUrl;

  /// Creates a [StreamWidget] for the given [streamUrl].
  const StreamWidget(this.streamUrl, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Mjpeg(
      stream: streamUrl,
      isLive: true,
      fit: BoxFit.contain,
      error: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 128, color: colors.error),
            const SizedBox(height: 16),
            Text(
              "Stream unavailable:\n${error.toString()}.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        );
      },
    );
  }
}
