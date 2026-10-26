"""Write ml/eval_out/report.md from what this repo can actually measure.

Held-out mAP, leakage, class counts, and event precision need labels this
repo does not have. Those sections say so. FPS is measured only when the
weights and runtime import.
"""

from __future__ import annotations

import platform
import statistics
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ml" / "eval_out"
IMAGES = ROOT / "ml" / "images"
PPE = ROOT / "ml" / "best.pt"
PERSON = ROOT / "ml" / "yolo11n.pt"


def hardware() -> str:
    try:
        chip = subprocess.check_output(["sysctl", "-n", "machdep.cpu.brand_string"], text=True).strip()
    except Exception:
        chip = platform.processor() or platform.machine()
    mem = ""
    try:
        pages = int(subprocess.check_output(["sysctl", "-n", "hw.memsize"], text=True))
        mem = f", {pages / (1024 ** 3):.0f} GB"
    except Exception:
        pass
    return f"{platform.system()} {platform.release()}, {chip}{mem}"


def measure() -> str | None:
    if not IMAGES.is_dir() or not PPE.is_file():
        return None
    try:
        import cv2
        from ultralytics import YOLO
    except Exception as error:
        return f"Runtime import failed: {error}"
    paths = sorted(
        [*IMAGES.glob("*.jpg"), *IMAGES.glob("*.jpeg"), *IMAGES.glob("*.png")]
    )[:20]
    if not paths:
        return "No images in ml/images, so FPS was not measured."
    lines = [f"Images timed: {len(paths)} from ml/images (unlabeled, not a test set)."]
    variants = [("ppe best.pt", PPE)]
    if PERSON.is_file():
        variants.append(("coco yolo11n.pt", PERSON))
    else:
        lines.append("ml/yolo11n.pt is not on disk, so the smaller variant was not timed.")
    for name, path in variants:
        model = YOLO(str(path))
        samples = []
        shapes: set[str] = set()
        for image_path in paths:
            frame = cv2.imread(str(image_path))
            if frame is None:
                continue
            shapes.add(f"{frame.shape[1]}x{frame.shape[0]}")
            start = time.perf_counter()
            model.predict(frame, verbose=False)
            samples.append((time.perf_counter() - start) * 1000)
        if not samples:
            lines.append(f"{name}: no readable images")
            continue
        samples.sort()
        mean = statistics.fmean(samples)
        p95 = samples[max(0, int(len(samples) * 0.95) - 1)]
        fps = 1000 / mean if mean else 0
        size = next(iter(shapes)) if len(shapes) == 1 else f"mixed ({len(shapes)} sizes, not resized)"
        lines.append(
            f"{name}: n={len(samples)} image={size} mean_ms={mean:.3f} p95_ms={p95:.3f} fps={fps:.3f}"
        )
    return "\n".join(lines)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    perf = measure()
    text = f"""# Eval

Hardware: {hardware()}

## Detection metrics

Not computed. `ml/best.pt` was trained from `hardhat.yaml` on Kaggle (`/kaggle/working/runs/detect/train3`). The images, labels, and split are not in this repo. `ml/results.csv` is that run's training log. It is not a held-out test result, and it is not copied here as one.

Leakage was not checked, because there is no split to compare.

## Class imbalance

Not computed. Instance counts need the label files.

## Event metrics

Not computed. A hand-labeled clip file is required.

One row per violation interval, CSV:

```
clip,camera_id,violation_type,start_sec,end_sec
```

`start_sec` is when the violation becomes true in the video. The eval should compare those intervals to rows in `server/data/events.db` for that clip. Precision, recall, false alarms per minute, and latency (logged timestamp minus labeled start) are undefined until that file exists.

## Performance

{perf or "Not measured. Install server/.venv and keep ml/images on disk, then rerun."}

## Ablation of confirm_frames

Not computed. False alarms and latency need the labeled clips above. `server/test_events.py` only checks that N missing frames become one event.

## Failure analysis

Not computed. Ranking misses and false positives needs ground-truth boxes.
"""
    path = OUT / "report.md"
    path.write_text(text)
    print(path)
    print(text)


if __name__ == "__main__":
    main()
