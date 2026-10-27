import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_vision/core/utils/image_utils.dart';
import 'package:ppe_vision/models/detection.dart';
import 'package:ppe_vision/models/frame_data.dart';
import 'package:ppe_vision/services/detection/yolo_decode.dart';
import 'package:ppe_vision/services/image/image_preprocessor.dart';

void main() {
  test('decodes hardhat as helmet and drops the weaker duplicate', () {
    // Channels-first [1, 7, 3]: cx, cy, w, h, hardhat, vest, person.
    final values = Float32List.fromList([
      320, 322, 100, // cx
      320, 322, 100, // cy
      100, 100, 40, // w
      100, 100, 40, // h
      0, 0, 0.8, // hardhat
      0, 0, 0, // vest
      0.95, 0.4, 0, // person
    ]);

    final detections = decodeYoloOutput(
      values: values,
      shape: const [1, 7, 3],
      modelWidth: 640,
      modelHeight: 640,
      padX: 0,
      padY: 0,
      letterboxScale: 1,
      uprightWidth: 640,
      uprightHeight: 640,
    );

    expect(detections, hasLength(2));
    expect(detections[0].classType, DetectionClass.person);
    expect(detections[0].confidence, closeTo(0.95, 1e-6));
    expect(detections[1].classType, DetectionClass.helmet);
    expect(detections[1].label, 'helmet');
  });

  test('undoes letterbox padding into upright normalized boxes', () {
    final values = Float32List.fromList([
      320, 320, 100, 200, 0, 0, 0.9,
    ]);

    final detections = decodeYoloOutput(
      values: values,
      shape: const [1, 1, 7],
      modelWidth: 640,
      modelHeight: 640,
      padX: 160,
      padY: 0,
      letterboxScale: 1,
      uprightWidth: 320,
      uprightHeight: 640,
    );

    expect(detections, hasLength(1));
    expect(detections.single.centerX, closeTo(0.5, 1e-6));
    expect(detections.single.centerY, closeTo(0.5, 1e-6));
    expect(detections.single.classType, DetectionClass.person);
  });

  test('reads boxes divided by the input size, as newer exports emit them', () {
    final values = Float32List.fromList([0.5, 0.5, 0.25, 0.5, 0.9]);

    final detections = decodeYoloOutput(
      values: values,
      shape: const [1, 1, 5],
      modelWidth: 640,
      modelHeight: 640,
      padX: 0,
      padY: 0,
      letterboxScale: 1,
      uprightWidth: 640,
      uprightHeight: 640,
      labels: const ['person'],
    );

    expect(detections.single.x1, closeTo(0.375, 1e-6));
    expect(detections.single.y2, closeTo(0.75, 1e-6));
  });

  test('letterboxes with a bilinear resize and integer gray pads', () {
    final frame = FrameData(
      width: 2,
      height: 1,
      timestamp: DateTime.utc(2026),
      format: FrameFormat.rgba8888,
      planes: [
        FramePlane(
          bytes: Uint8List.fromList([0, 0, 0, 255, 255, 255, 255, 255]),
          bytesPerRow: 8,
          bytesPerPixel: 4,
        ),
      ],
    );

    final image = const DefaultImagePreprocessor(
      targetWidth: 4,
      targetHeight: 4,
    ).processSync(frame);

    expect(image.padX, 0);
    expect(image.padY, 1);
    expect(image.rgbBytes.sublist(0, 3), [114, 114, 114]);
    final row = [for (var x = 0; x < 4; x++) image.rgbBytes[(4 + x) * 3]];
    expect(row, [0, 64, 191, 255]);
  });

  test('reads camera YUV as full range', () {
    final frame = FrameData(
      width: 2,
      height: 2,
      timestamp: DateTime.utc(2026),
      format: FrameFormat.yuv420,
      planes: [
        FramePlane(bytes: Uint8List.fromList([16, 16, 16, 16]), bytesPerRow: 2),
        FramePlane(bytes: Uint8List.fromList([128]), bytesPerRow: 1),
        FramePlane(bytes: Uint8List.fromList([128]), bytesPerRow: 1),
      ],
    );

    final image = const DefaultImagePreprocessor(
      targetWidth: 2,
      targetHeight: 2,
    ).processSync(frame);

    expect(image.rgbBytes.sublist(0, 3), [16, 16, 16]);
  });

  test('rotates a BGRA frame 90 degrees clockwise into RGB', () async {
    // Sensor (0,0) red maps to upright (1,0) after a 90° clockwise turn.
    final frame = FrameData(
      width: 2,
      height: 2,
      timestamp: DateTime.utc(2026),
      rotationDegrees: 90,
      format: FrameFormat.bgra8888,
      planes: [
        FramePlane(
          bytes: Uint8List.fromList([
            0, 0, 255, 255, // red
            0, 255, 0, 255, // green
            255, 0, 0, 255, // blue
            255, 255, 255, 255, // white
          ]),
          bytesPerRow: 8,
          bytesPerPixel: 4,
        ),
      ],
    );

    final image = await const DefaultImagePreprocessor(
      targetWidth: 2,
      targetHeight: 2,
    ).process(frame);

    expect(image.rgbBytes[3], 255);
    expect(image.rgbBytes[4], 0);
    expect(image.rgbBytes[5], 0);
  });

  test('reads RGBA desktop frames without swapping channels', () async {
    final frame = FrameData(
      width: 1,
      height: 1,
      timestamp: DateTime.utc(2026),
      format: FrameFormat.rgba8888,
      planes: [
        FramePlane(
          bytes: Uint8List.fromList([10, 20, 30, 255]),
          bytesPerRow: 4,
          bytesPerPixel: 4,
        ),
      ],
    );

    final image = await const DefaultImagePreprocessor(
      targetWidth: 1,
      targetHeight: 1,
    ).process(frame);

    expect(image.rgbBytes.sublist(0, 3), [10, 20, 30]);
  });

  test('cover rect centers a wide frame', () {
    final rect = ImageUtils.coverRect(
      viewWidth: 100,
      viewHeight: 100,
      imageWidth: 200,
      imageHeight: 100,
    );
    expect(rect.left, -50);
    expect(rect.top, 0);
    expect(rect.width, 200);
    expect(rect.height, 100);
  });
}
