# PPE Vision

Detects hardhats and safety vests in a camera frame and scores each detected person as compliant or not.

`app/` is a Flutter client. It runs YOLO11s on device from `app/assets/models/ppe_model.tflite`. `ml/best.pt` is the checkpoint that export comes from. There is no inference server in this repository.

Ultralytics, which loads `ml/best.pt`, is AGPL-3.0.

## Run the app

CI uses Flutter 3.47.1. This tree was last run with Dart 3.13.

```bash
cd app
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run
```

`flutter run -d macos`, `-d chrome`, `-d windows`, and `-d linux` match the same project. On Linux the camera plugin needs GStreamer (`libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`, `gstreamer1.0-plugins-good`).

The `.tflite` file and the desktop runtime libraries in `app/blobs/` are not in git. Export the float32 model and copy it into place:

```bash
yolo export model=ml/best.pt format=tflite imgsz=640
```

Destination: `app/assets/models/ppe_model.tflite`. Without that file the detector does not load. The browser target shows the camera preview and does not run TFLite.

The camera list is back, then external, then front. The app does not switch cameras after start. If the camera cannot start, the detection screen sends a synthetic frame through the same model and labels the preview as a demo.

## Training files

`ml/best.pt` is YOLO11s, classes `hardhat`, `vest`, `person`, input 640. The checkpoint records a Kaggle run at `/kaggle/working/runs/detect/train3`, started from `yolo11s.pt` with data file `hardhat.yaml`. The labeled images and the split are not in this repo.

`ml/results.csv` is the 25-epoch log from that run. It is not a held-out test result.

```bash
cd ml
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python plot_graphs.py
.venv/bin/python test_model.py
```

`requirements.txt` pins the packages these scripts import, at the versions from the Windows venv that was stored with them. That install has not been re-run on this Mac.

`test_model.py` predicts on `ml/images/` (198 unlabeled stock photos). Those files are gitignored. They are not a test set.

`intelligence.py` opens a webcam with `cv2.CAP_DSHOW` and calls `winsound`. It does not run on macOS. It looks for the label `helmet`. The checkpoint class name is `hardhat`.

## Results

No held-out metrics have been computed from this repo. Reproduce nothing from `ml/results.csv` as test mAP: the images and labels for that log are absent, so the numbers cannot be regenerated here.

## Limitations

- A person box is estimated from a hardhat, or from a vest when no hardhat covers it (`app/lib/services/compliance/ppe_compliance_analyzer.dart`). Someone wearing neither is not detected, so a missing-hardhat violation cannot be logged from this model alone.
- History stores a count snapshot when capture is tapped. It does not store an image, a track id, or a violation interval. Settings last for the session only.
- No tracker, no event database, and no server API.
- The original labeled dataset is not here. A separate person detector has not been added. Both are undecided.

## Layout

- `app/` Flutter client and on-device TFLite decoder
- `ml/` checkpoint, training log, and the three scripts above

A `server/` package is not in this change. Add it when the inference API exists.
