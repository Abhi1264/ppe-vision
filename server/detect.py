"""YOLO11s PPE weights plus a COCO person model.

best.pt's person class does not produce boxes, so a person with neither
hardhat nor vest would never be seen. yolo11n supplies the person track.
"""

from __future__ import annotations

from pathlib import Path

from server.events import assign_ppe

ROOT = Path(__file__).resolve().parents[1]
PPE_WEIGHTS = ROOT / "ml" / "best.pt"
PERSON_WEIGHTS = ROOT / "ml" / "yolo11n.pt"


def load_models():
    from ultralytics import YOLO

    if not PPE_WEIGHTS.is_file():
        raise FileNotFoundError(f"Missing {PPE_WEIGHTS}")
    # ultralytics downloads yolo11n.pt into this path when it is absent
    person = YOLO(str(PERSON_WEIGHTS))
    ppe = YOLO(str(PPE_WEIGHTS))
    return person, ppe


def _rows(result, wanted: set[str] | None):
    rows = []
    boxes = result.boxes
    if boxes is None:
        return rows
    names = result.names
    for box in boxes:
        cls_id = int(box.cls[0])
        label = names[cls_id]
        if wanted is not None and label not in wanted:
            continue
        xyxy = [float(v) for v in box.xyxy[0]]
        conf = float(box.conf[0])
        track_id = None if box.id is None else int(box.id[0])
        rows.append((label, xyxy, conf, track_id))
    return rows


def infer(person_model, ppe_model, frame, conf: float) -> list[dict]:
    person_result = person_model.track(
        frame,
        persist=True,
        classes=[0],
        tracker="bytetrack.yaml",
        conf=conf,
        verbose=False,
    )[0]
    ppe_result = ppe_model.predict(
        frame,
        classes=[0, 1],
        conf=conf,
        verbose=False,
    )[0]
    height, width = frame.shape[:2]
    people = []
    for label, xyxy, score, track_id in _rows(person_result, {"person"}):
        if track_id is None:
            continue
        people.append({"track_id": track_id, "xyxy": xyxy, "confidence": score, "label": label})
    items = [(label, xyxy, score) for label, xyxy, score, _track in _rows(ppe_result, {"hardhat", "vest"})]
    owned = assign_ppe(people, items)
    tracks = []
    for person in people:
        boxes = {}
        for label, xyxy in owned.get(person["track_id"], {}).items():
            boxes[label] = [_unit(v, width if i % 2 == 0 else height) for i, v in enumerate(xyxy)]
        px1, py1, px2, py2 = person["xyxy"]
        tracks.append(
            {
                "track_id": person["track_id"],
                "confidence": person["confidence"],
                "present": set(boxes),
                "person": [
                    _unit(px1, width),
                    _unit(py1, height),
                    _unit(px2, width),
                    _unit(py2, height),
                ],
                "boxes": boxes,
                "xyxy": person["xyxy"],
            }
        )
    return tracks


def decode_and_infer(models, raw: bytes, conf: float):
    import cv2
    import numpy as np

    frame = cv2.imdecode(np.frombuffer(raw, dtype=np.uint8), cv2.IMREAD_COLOR)
    if frame is None:
        raise ValueError("Could not decode image")
    return infer(models[0], models[1], frame, conf), frame


def _unit(value: float, size: int) -> float:
    if size <= 0:
        return 0.0
    return min(1.0, max(0.0, value / size))
