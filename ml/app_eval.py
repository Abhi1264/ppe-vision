"""How closely the phone's detection pipeline reproduces the PyTorch models.

There are no labels in this repo, so this is agreement with best.pt (helmet,
vest) and yolo11n.pt (person) on the same photos, not accuracy against ground
truth. `make eval-app` runs the three steps:

    python -m ml.app_eval prepare   # reference boxes + each photo as camera YUV
    flutter test test/app_eval_test.dart   # the app's Dart pipeline and TFLite files
    python -m ml.app_eval score     # writes ml/eval_out/app_eval.md
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

from ml.eval import IMAGES, ROOT, hardware

OUT = ROOT / "ml" / "eval_out"
WORK = OUT / "app_eval"
CONF = 0.25
NMS_IOU = 0.7
MATCH_IOU = 0.5
CLASSES = ("helmet", "vest", "person")


def camera_yuv(rgb: np.ndarray) -> bytes:
    """I420 the way the Android camera delivers it: full-range BT.601, 4:2:0."""
    f = rgb.astype(np.float32)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    y = 0.299 * r + 0.587 * g + 0.114 * b
    u = -0.168736 * r - 0.331264 * g + 0.5 * b + 128
    v = 0.5 * r - 0.418688 * g - 0.081312 * b + 128
    pad = ((0, y.shape[0] % 2), (0, y.shape[1] % 2))

    def half(plane: np.ndarray) -> np.ndarray:
        p = np.pad(plane, pad, mode="edge")
        return p.reshape(p.shape[0] // 2, 2, p.shape[1] // 2, 2).mean((1, 3))

    def byte(plane: np.ndarray) -> bytes:
        return np.clip(np.rint(plane), 0, 255).astype(np.uint8).tobytes()

    return byte(y) + byte(half(u)) + byte(half(v))


def prepare() -> None:
    import cv2
    from ultralytics.models import YOLO

    ppe = YOLO(str(ROOT / "ml" / "best.pt"))
    person = YOLO(str(ROOT / "ml" / "yolo11n.pt"))
    (WORK / "frames").mkdir(parents=True, exist_ok=True)
    manifest, reference = [], {}
    for index, path in enumerate(sorted(IMAGES.iterdir())):
        bgr = cv2.imread(str(path))
        if bgr is None:
            continue
        h, w = bgr.shape[:2]
        boxes = []
        for model, keep in ((ppe, {"hardhat": "helmet", "vest": "vest"}), (person, {"person": "person"})):
            result = model.predict(bgr, conf=CONF, iou=NMS_IOU, verbose=False)[0]
            for box in result.boxes:
                name = keep.get(result.names[int(box.cls[0])])
                if name:
                    x1, y1, x2, y2 = box.xyxy[0].tolist()
                    boxes.append({"cls": name, "conf": float(box.conf[0]), "box": [x1 / w, y1 / h, x2 / w, y2 / h]})
        file = f"frames/{index}.yuv"
        (WORK / file).write_bytes(camera_yuv(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)))
        manifest.append({"name": path.name, "file": file, "width": w, "height": h})
        reference[path.name] = boxes
    (WORK / "manifest.json").write_text(json.dumps(manifest))
    (WORK / "reference.json").write_text(json.dumps(reference))
    print(f"Prepared {len(manifest)} photos in {WORK}")


def iou(a: list[float], b: list[float]) -> float:
    w = min(a[2], b[2]) - max(a[0], b[0])
    h = min(a[3], b[3]) - max(a[1], b[1])
    if w <= 0 or h <= 0:
        return 0.0
    inter = w * h
    return inter / ((a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter)


def match(app: list[dict], ref: list[dict]) -> list[float]:
    """Greedy by app confidence: each reference box agrees with at most one app box."""
    free = list(ref)
    found = []
    for box in sorted(app, key=lambda d: -d["conf"]):
        if not free:
            break
        best = max(free, key=lambda r: iou(box["box"], r["box"]))
        overlap = iou(box["box"], best["box"])
        if overlap >= MATCH_IOU:
            free.remove(best)
            found.append(overlap)
    return found


def score() -> None:
    reference = json.loads((WORK / "reference.json").read_text())
    app = json.loads((WORK / "app.json").read_text())
    rows = []
    for cls in CLASSES:
        n_ref = n_app = 0
        overlaps: list[float] = []
        for name, ref_boxes in reference.items():
            r = [d for d in ref_boxes if d["cls"] == cls]
            a = [d for d in app["images"][name] if d["cls"] == cls]
            n_ref += len(r)
            n_app += len(a)
            overlaps += match(a, r)
        agree = len(overlaps)
        precision = agree / n_app if n_app else 0.0
        recall = agree / n_ref if n_ref else 0.0
        f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
        mean_iou = float(np.mean(overlaps)) if overlaps else 0.0
        rows.append(f"| {cls} | {n_ref} | {n_app} | {agree} | {precision:.3f} | {recall:.3f} | {f1:.3f} | {mean_iou:.3f} |")
    report = "\n".join(
        [
            "# Phone pipeline vs PyTorch models",
            "",
            f"{len(reference)} photos from ml/images. They are unlabeled, so this is agreement with the trained models, not accuracy.",
            "",
            f"Reference: best.pt (helmet, vest) and yolo11n.pt (person) through Ultralytics, conf {CONF}, NMS IoU {NMS_IOU}.",
            "App: app/lib/services/detection/frame_detector.dart with the bundled TFLite files,"
            " fed each photo as the Android camera delivers it (YUV 4:2:0, full range).",
            f"A box agrees when the class matches and IoU >= {MATCH_IOU}.",
            "",
            "| Class | Reference boxes | App boxes | Agree | Precision | Recall | F1 | Mean IoU |",
            "|-------|-----------------|-----------|-------|-----------|--------|----|----------|",
            *rows,
            "",
            f"App pipeline: {app['ms_per_frame']:.0f} ms per photo on {hardware()} (both models, 4 threads). A phone is slower.",
            "",
        ]
    )
    (OUT / "app_eval.md").write_text(report)
    print(report)


if __name__ == "__main__":
    {"prepare": prepare, "score": score}[sys.argv[1]]()
