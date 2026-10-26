import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';

class CameraView extends ConsumerWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(detectionSessionProvider);
    final jpeg = session.previewJpeg;
    if (jpeg != null && session.previewWidth > 0 && session.previewHeight > 0) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: Image.memory(
            jpeg,
            gaplessPlayback: true,
            width: session.previewWidth.toDouble(),
            height: session.previewHeight.toDouble(),
          ),
        ),
      );
    }

    final camera = ref.watch(cameraServiceProvider);
    final preview = camera.buildPreview();
    if (preview == null) {
      return const ColoredBox(color: AppColors.detectionBg);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = camera.previewSize;
        final child = previewSize == null
            ? preview
            : SizedBox(
                width: previewSize.width,
                height: previewSize.height,
                child: preview,
              );

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: child,
          ),
        );
      },
    );
  }
}
