# PPE Vision

A Flutter app that watches the device camera and checks whether each person is wearing a hardhat and a safety vest. Detection runs on the device. Nothing is uploaded.

Ultralytics is AGPL-3.0.

## What it does

Each frame goes through two TensorFlow Lite models, both at 640×640:

- `app/assets/models/person_model.tflite` is the float32 export of `ml/yolo11n.pt` (COCO). Only the person class is kept.
- `app/assets/models/ppe_model.tflite` is the float32 export of `ml/best.pt` (YOLO11s). Hardhat and vest boxes are kept. The person class in `best.pt` does not emit boxes, which is why the second model exists.

A hardhat or vest counts only when its center falls inside a person box. A hardhat on a table is not a person. A person wearing neither item is still a person, and is a violation of both items.

A violation becomes an event after the same item stays missing for N frames in a row. The default is 8, and Settings can change it. The event is stored on the device. There is no track id: the on-device models do not follow one person from frame to frame, so two people missing the same item in one view count as one streak.

The screens:

- **Start detection** opens the camera and runs both models. The switch icon in the viewfinder corner flips between the front and back camera. The HUD line `Detect` is how many frames finish inference per second, not the screen refresh. `Inference` is the time for one frame through both models.
- **Event log** lists saved violations. Filter by type, camera (`front` or `back`), and day, then copy them as CSV.
- **Report** shows the event count, how many person-frames were compliant, and counts by type, day, and camera.
- **Settings** changes the required items, the frames before an event, the confidence threshold (default 0.25), the overlay, and the target frame cap (default 8, range 5–15). The cap cannot make the models faster than they are.

## Run the app

Flutter 3.47.1, Dart 3.13. A phone or a desktop with a camera.

```bash
cd app
flutter pub get
flutter test
flutter devices
flutter run -d <device-id>
```

`flutter test` skips the photo benchmark unless `PPE_EVAL_DIR` is set. `make eval-app` is the way to run that.

Android asks for the camera on first launch. iOS uses the same permission. On macOS the first launch of an unsigned build needs System Settings, Privacy & Security, Open Anyway.

Linux and Windows builds also need the TensorFlow Lite runtime files in `app/blobs/`. macOS copies its runtime from the `tflite_flutter` package during the build. A Linux machine running the app needs GTK 3 and GStreamer with the good plugins:

```bash
sudo apt install libgtk-3-0 gstreamer1.0-plugins-good
```

## Training and eval tools

`ml/` and `server/` are not used by the app. They time the PyTorch weights and compare the phone pipeline to those weights. The labeled training images and the train/test split are not in this repo, so none of this is a held-out accuracy number.

```bash
python3 -m venv server/.venv
server/.venv/bin/pip install -r server/requirements.txt
```

`ml/yolo11n.pt` is gitignored. Download it once before the evals that need a person reference:

```bash
cd ml && ../server/.venv/bin/python -c "from ultralytics.models import YOLO; YOLO('yolo11n.pt')"
```

`ml/images/` is also gitignored. It is 198 unlabeled stock photos on this machine. Without that folder the commands below have nothing to time.

```bash
make test-server   # event log and API tests, no model
make eval          # writes ml/eval_out/report.md, PyTorch timing only
make eval-app      # writes ml/eval_out/app_eval.md
```

`make eval-app` runs three steps: the venv writes reference boxes and converts each photo to the YUV layout the Android camera uses, `flutter test` runs `app/lib/services/detection/frame_detector.dart` on those frames with the bundled TFLite files, and the venv scores agreement. A box agrees when the class matches and the overlap is at least 0.5. The latest run of that file is the number to quote, and only for this machine.

`server/.venv/bin/python ml/plot_graphs.py` writes `ml/training_log.png` from `ml/results.csv`. That CSV is the Kaggle training log, not a test result.

`make serve` starts the old FastAPI tool on port 8000. The app does not call it.

## Model

`ml/best.pt` is YOLO11s, classes `hardhat`, `vest`, `person`, input 640. The checkpoint records a Kaggle run at `/kaggle/working/runs/detect/train3` from `yolo11s.pt` and `hardhat.yaml`. The labeled images and the split are not in this repo.

## Results

`make eval` on this machine wrote `ml/eval_out/report.md`. Held-out mAP, leakage, class counts, event precision, the confirm-frames ablation, and failure analysis are not in that file because the labeled split and labeled clips are not here.

```
ppe best.pt: n=20 image=mixed (11 sizes, not resized) mean_ms=124.682 p95_ms=560.981 fps=8.020
coco yolo11n.pt: n=20 image=mixed (11 sizes, not resized) mean_ms=32.273 p95_ms=58.474 fps=30.986
```

Hardware in the same file: Darwin 27.0.0, Apple M3, 8 GB. The 20 images are unlabeled files in `ml/images/`. They are not a test set. Rerun `make eval` rather than quoting this block after the images or the machine change.

## Releases

Pushing a `vX.Y.Z` tag runs `.github/workflows/release.yml` and attaches one file per platform to a GitHub release. The tag is the app version. iOS has no file: an iPhone only installs through the App Store or TestFlight.

```bash
git tag v1.0.0
git push origin v1.0.0
```

| File | Install |
|------|---------|
| `-android.apk` | Allow installs from the browser or file manager when Android asks. |
| `-macos.zip` | Unzip and open `PPE Vision.app`. It is not notarized, so the first launch needs System Settings, Privacy & Security, Open Anyway. |
| `-windows-x64.zip` | Unzip and run `ppe_vision.exe`. SmartScreen asks once because the app is not code-signed. |
| `-linux-x64.tar.gz` | Extract and run `bundle/ppe_vision`. Needs GTK 3 and `gstreamer1.0-plugins-good`. |

The Android job refuses to publish without a signing key, so each release can update the last one. Create the key once, keep `upload.jks` outside the repo, and back it up:

```bash
keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
base64 -i upload.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_STORE_PASSWORD
gh secret set ANDROID_KEY_ALIAS --body upload
gh secret set ANDROID_KEY_PASSWORD
```

## Limitations

- No labeled test split, so no mAP, no leakage check, and no event precision.
- No track id. A streak is per missing item, not per person.
- Gear outside a person box is ignored.
- `ml/images/` is unlabeled stock photos. `ml/test_model.py` only draws boxes on them.
