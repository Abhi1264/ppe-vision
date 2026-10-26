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

Put `ppe_model.tflite` in `app/assets/models/`. It is the float32 export of `ml/best.pt` and is gitignored. Switch camera flips front and back.

`make eval` writes `ml/eval_out/report.md`. That path still uses the PyTorch weights.

`server/.venv/bin/python ml/plot_graphs.py` writes `ml/training_log.png` from `ml/results.csv`.

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
