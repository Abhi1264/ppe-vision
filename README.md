# PPE Vision

Detects people with YOLO11n (COCO) and hardhats and vests with `ml/best.pt` (YOLO11s). A violation event is one tracked person missing a required item for N frames in a row. The Flutter app reads those events from a local server.

Ultralytics is AGPL-3.0.

## Run

```bash
python3 -m venv server/.venv
server/.venv/bin/pip install -r server/requirements.txt
make test-server
make serve
```

In another terminal:

```bash
cd app
flutter pub get
flutter test
flutter run -d macos
```

The app expects `http://127.0.0.1:8000`. Change it in Settings. With "Use this device camera" off, the server opens webcam `0`. Turn that setting on to send this device's camera, then use Switch camera for front or back.

`make eval` writes `ml/eval_out/report.md`.

`server/.venv/bin/python ml/plot_graphs.py` writes `ml/training_log.png` from `ml/results.csv`.

## Model

`ml/best.pt` is YOLO11s, classes `hardhat`, `vest`, `person`, input 640. The checkpoint records a Kaggle run at `/kaggle/working/runs/detect/train3` from `yolo11s.pt` and `hardhat.yaml`. The labeled images and the split are not in this repo. `ml/results.csv` is that training log, not a test result.

The person class in `best.pt` does not emit boxes. The server uses `ml/yolo11n.pt` (downloaded on first start) for the person track and `best.pt` for hardhat and vest.

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
- Track ids are not names. They reset when a capture session restarts.
- One capture job at a time. Posting frames while a job is running returns 409.
- The server has no authentication.
- On-device TFLite files are still in `app/lib/services/detection/` and are not used by the live screen.
- `ml/images/` is 198 unlabeled stock photos. `test_model.py` only draws boxes on them.
