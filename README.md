# PPE Vision

[![CI](https://github.com/Abhi1264/ppe-vision/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhi1264/ppe-vision/actions/workflows/ci.yml)

Real-time **helmet and safety vest** monitoring for site PPE compliance. This repository is a production-quality Flutter scaffold: camera pipeline, detection overlay, PPE association, statistics, history, and settings are complete. The computer-vision model is intentionally not wired in yet.

The app ships with a working **mock detection mode**, so the full UI can be demonstrated without a TFLite model.

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
ImagePreprocessor    (YUV→RGB, letterbox — used by the future model path)
    ↓
DetectionProvider    (MockDetectionProvider | ModelDetectionProvider)
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
| Working demo backend | `lib/services/detection/mock_detection_provider.dart` |
| Future TFLite/YOLO backend | `lib/services/detection/model_detection_provider.dart` |
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
flutter run
```

Portrait orientation is locked. Grant camera permission when prompted.

On simulators without a camera, the detection screen falls back to a demo preview and still runs mock detections.

## Mock mode

Settings → **Detection provider → Mock** (default).

`MockDetectionProvider` returns a stable three-person scene:

1. Helmet **and** vest → compliant
2. Helmet only → vest violation
3. Vest only → helmet violation

Inference time is simulated (~90–140 ms). Camera frames are throttled to the configured target FPS (5–15). Concurrent inference is blocked with an `isProcessing` guard.

## Settings

Stored in memory for this phase (no database):

- Confidence threshold
- Provider: Mock (functional) / Model (disabled)
- Overlay and confidence labels
- Target inference FPS
- FPS and inference-time indicators

## Capture and history

**Capture** on the detection screen snapshots the current counts into an in-memory history list. Image persistence is intentionally omitted.

## Future model integration

1. Export the detector as TFLite and place it at:

   ```text
   assets/models/ppe_model.tflite
   ```

   See `assets/models/README.md`. Do not commit the file until the model is finalized.

2. Implement **only** `ModelDetectionProvider` (and, if needed, `DefaultImagePreprocessor`):

   - load interpreter + labels
   - convert `FrameData` → RGB, resize/letterbox, normalize
   - run inference
   - decode YOLO output, confidence filter, NMS
   - convert boxes to normalized `Detection` objects

3. Enable the Model radio in Settings once `initialize()` succeeds.

The rest of the app already filters by confidence threshold, associates PPE with people, and renders overlays from `Detection`.

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
