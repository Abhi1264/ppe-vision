import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_vision/services/camera/camera_service.dart';

CameraDescription _cam(String name, CameraLensDirection lens) {
  return CameraDescription(
    name: name,
    lensDirection: lens,
    sensorOrientation: 0,
  );
}

void main() {
  test('ranks back, then external, then front, keeping original order', () {
    final frontA = _cam('FaceTime', CameraLensDirection.front);
    final usb = _cam('USB Cam', CameraLensDirection.external);
    final back = _cam('Rear', CameraLensDirection.back);
    final frontB = _cam('Continuity', CameraLensDirection.front);

    expect(rankDetectedCameras([frontA, usb, back, frontB]), [
      back,
      usb,
      frontA,
      frontB,
    ]);
  });

  test('uses the only detected webcam as-is', () {
    final webcam = _cam('FaceTime HD', CameraLensDirection.front);
    expect(rankDetectedCameras([webcam]), [webcam]);
  });
}
