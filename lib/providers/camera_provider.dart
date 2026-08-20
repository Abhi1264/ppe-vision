import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/camera/camera_service.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = FlutterCameraService();
  ref.onDispose(service.dispose);
  return service;
});
