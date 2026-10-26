from pathlib import Path

from ultralytics.models import YOLO

root = Path(__file__).resolve().parent
model = YOLO(root / "best.pt")
model.predict(
    source=root / "images",
    save=True,
    show=False,
    conf=0.25,
    project=root / "runs",
    name="predict",
    exist_ok=True,
)
print("Done")
