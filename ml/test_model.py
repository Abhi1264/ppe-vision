from ultralytics import YOLO

# Load trained model
model = YOLO("best.pt")

# Predict on image or folder
results = model.predict(
    source="images",   # folder containing test images
    save=True,         # saves annotated images
    show=True,         # opens result window
    conf=0.25          # confidence threshold
)

print("Done")