import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/detection_provider.dart';

/// Owns session start/stop so [DetectionScreen] can stay a pure view.
class DetectionSessionBinder extends ConsumerStatefulWidget {
  const DetectionSessionBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DetectionSessionBinder> createState() =>
      _DetectionSessionBinderState();
}

class _DetectionSessionBinderState
    extends ConsumerState<DetectionSessionBinder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(detectionSessionProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        ref.read(detectionSessionProvider.notifier).stop();
      },
      child: widget.child,
    );
  }
}
