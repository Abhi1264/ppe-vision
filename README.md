# PPE Vision

[![CI](https://github.com/Abhi1264/ppe-vision/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhi1264/ppe-vision/actions/workflows/ci.yml)

Real-time **helmet and safety vest** monitoring for site PPE compliance. Camera pipeline, detection overlay, PPE association, statistics, history, and settings are in place. The YOLO11 detector is bundled as `assets/models/ppe_model.tflite` and runs on Android, iOS, macOS, Windows, and Linux.

## Project overview

PPE Vision watches a live camera feed, runs object detection, then decides for every detected person:

- whether they are wearing a helmet
- whether they are wearing a safety vest
- whether they are PPE compliant

Detected classes (current and future):

- `person`
- `helmet`
- `vest`

## Architecture

The UI never talks to YOLO or TFLite. Everything downstream of detection consumes a generic `List<Detection>` with **normalized** bounding boxes (`0.0`–`1.0`).

```text
Live Camera
    ↓
FrameData            (camera-agnostic frame payload)
    ↓
ImagePreprocessor    (YUV/BGRA → RGB, rotate, letterbox)
    ↓
DetectionProvider    (ModelDetectionProvider)
    ↓
List<Detection>
    ↓
PPEComplianceAnalyzer
    ↓
PersonDetection + ComplianceResult + statistics
    ↓
Camera preview, overlay, status cards, history
```

### Where each concern lives

| Concern | Location |
| --- | --- |
| Camera permission, stream, lifecycle | `lib/services/camera/camera_service.dart` |
| Detection interface | `lib/services/detection/detection_provider.dart` |
| Bundled YOLO11 backend | `lib/services/detection/model_detection_io.dart` |
| Frame preprocessing contract | `lib/services/image/image_preprocessor.dart` |
| Helmet/vest ↔ person association | `lib/services/compliance/ppe_compliance_analyzer.dart` |
| IoU / containment | `lib/core/utils/bounding_box_utils.dart` |
| Session, FPS, throttling | `lib/providers/detection_provider.dart` |
| Overlay painter | `lib/widgets/detection_overlay.dart` |

Swapping in a real model should not require rewriting camera UI, overlays, compliance cards, statistics, history, navigation, settings, PPE logic, or Riverpod session state.

## Running

Requires the Flutter SDK (this project was developed with Flutter 3.47 / Dart 3.13).

```bash
flutter pub get
flutter devices
```

| Platform | Run | Camera |
| --- | --- | --- |
| Android / iOS | `flutter run` | Live preview and frame stream from the first working camera (back, then external, then front). Falls back to the demo preview if init fails (simulators, missing permission). |
| Web | `flutter run -d chrome` | Live preview when camera permission is granted. The TFLite model does not run in the browser. Serve over HTTPS or `localhost`. |
| macOS | `flutter run -d macos` | Live preview and frame stream from any detected webcam (built-in or USB). Grant camera permission when prompted. |
| Windows | `flutter run -d windows` | Live preview and the bundled model. Frame streaming depends on the camera plugin; inference uses `blobs/libtensorflowlite_c-win.dll`. |
| Linux | `flutter run -d linux` | Live preview and frame stream from any detected V4L2 webcam. Requires GStreamer (`libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`, `gstreamer1.0-plugins-good` on Debian/Ubuntu). |

```bash
flutter run                 # default device (usually a connected phone)
flutter run -d chrome
flutter run -d macos
flutter run -d windows
flutter run -d linux
flutter build web
```

Portrait orientation is locked on mobile. Grant camera permission when prompted.

On any platform where the camera cannot start, the detection screen uses `FallbackCameraBackground`.

## Settings

Stored in memory for this phase (no database):

- Confidence threshold
- Overlay and confidence labels
- Target inference FPS
- FPS and inference-time indicators

## Capture and history

**Capture** on the detection screen snapshots the current counts into detection history. Captures are stored on the device and restored the next time the app opens. Image persistence is intentionally omitted.

## Bundled model

`helmet-vest-detection/best.pt` is a YOLO11s detector (`hardhat`, `vest`, `person`, 640×640). The app loads the float32 TFLite export at `assets/models/ppe_model.tflite`. `hardhat` is shown and scored as a helmet. The `person` channel in the weights stays near zero, so a worker box is estimated from each helmet (or from a vest when no helmet covers it). Desktop inference libraries live in `blobs/`.

```bash
yolo export model=helemt-vest-detection/best.pt format=tflite imgsz=640
```

Copy the float32 `.tflite` to `assets/models/ppe_model.tflite`.

The rest of the app filters by the confidence slider, associates PPE with people, and renders overlays from `Detection`.

Expected output shape:

```dart
Detection(
  classType: DetectionClass.person,
  label: 'person',
  confidence: 0.94,
  x1: 0.12,
  y1: 0.08,
  x2: 0.61,
  y2: 0.91,
)
```

## Tests

```bash
flutter analyze
flutter test
```

Unit tests cover IoU, containment, PPE association, compliance, and statistics, including the three-person mock scene.

## CI

GitHub Actions runs the same gate on `main`, pull requests, and manual dispatch:

1. `flutter pub get`
2. `flutter analyze --fatal-infos`
3. `flutter test --coverage`

There is no store deployment. Builds are still produced locally with `flutter run`.
