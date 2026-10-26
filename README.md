# PPE Vision

The phone and desktop apps run the camera and the YOLO11s TFLite model on the device. A missing hardhat or vest becomes an event after it stays missing for N frames. Events stay on the device.

`ml/` and `server/` are the training and eval tools. The app does not call them.

Ultralytics is AGPL-3.0.

## Run

```bash
cd app
flutter pub get
flutter test
flutter run
```

`app/assets/models/ppe_model.tflite` is the float32 export of `ml/best.pt`. `app/blobs/` holds the TensorFlow Lite runtime that Linux and Windows builds install; macOS copies it from the `tflite_flutter` package. Switch camera flips front and back.

`make eval` writes `ml/eval_out/report.md`. That path still uses the PyTorch weights.

`server/.venv/bin/python ml/plot_graphs.py` writes `ml/training_log.png` from `ml/results.csv`.

## Releases

Pushing a `vX.Y.Z` tag runs `.github/workflows/release.yml`, which builds every platform and attaches the files to a GitHub release. The tag sets the app version.

```bash
git tag v1.0.0
git push origin v1.0.0
```

| File | Install |
|------|---------|
| `-android.apk` | Allow installs from your browser or file manager when Android asks. |
| `-macos.zip` | Unzip and open `PPE Vision.app`. It is not notarized, so the first launch needs System Settings > Privacy & Security > Open Anyway. |
| `-windows-x64.zip` | Unzip and run `ppe_vision.exe`. SmartScreen asks once because the app is not code-signed. |
| `-linux-x64.tar.gz` | Extract and run `bundle/ppe_vision`. Needs GTK 3 and GStreamer with `gstreamer1.0-plugins-good`. |

iOS has no release file. An iPhone only installs through the App Store or TestFlight.

The Android build refuses to publish without a signing key, so every release can update the last one. Create the key once, keep `upload.jks` out of the repo, and back it up:

```bash
keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
base64 -i upload.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_STORE_PASSWORD
gh secret set ANDROID_KEY_ALIAS --body upload
gh secret set ANDROID_KEY_PASSWORD
```

## Model

`ml/best.pt` is YOLO11s, classes `hardhat`, `vest`, `person`, input 640. The checkpoint records a Kaggle run at `/kaggle/working/runs/detect/train3` from `yolo11s.pt` and `hardhat.yaml`. The labeled images and the split are not in this repo. `ml/results.csv` is that training log, not a test result.

The person class in `best.pt` does not emit boxes. The on-device app estimates a person from a hardhat or a vest. Someone wearing neither is not seen. The eval server can still use `ml/yolo11n.pt` for a real person box. That model is not in the app.

## Results

`make eval` on this machine wrote `ml/eval_out/report.md`. Held-out mAP, leakage, class counts, event precision, the confirm-frames ablation, and failure analysis are not in that file because the labeled split and labeled clips are not here.

Performance lines from that run, unchanged:

```
ppe best.pt: n=20 image=mixed (11 sizes, not resized) mean_ms=124.682 p95_ms=560.981 fps=8.020
coco yolo11n.pt: n=20 image=mixed (11 sizes, not resized) mean_ms=32.273 p95_ms=58.474 fps=30.986
```

Hardware in the same file: Darwin 27.0.0, Apple M3, 8 GB. The 20 images are the unlabeled files in `ml/images/`. They are not a test set. Rerun `make eval` rather than quoting this block after the images or the machine change.

## Limitations

- No labeled test split, so no mAP, no leakage check, and no event precision.
- Track ids are not in the app. The on-device model does not track a person across frames.
- Someone with neither a hardhat nor a vest is not detected.
- `ml/images/` is 198 unlabeled stock photos. `test_model.py` only draws boxes on them.
