import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class StreamWidget extends StatelessWidget {
  final String streamUrl;

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
