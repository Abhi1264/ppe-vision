from ultralytics import YOLO
import cv2
import winsound
import time

# Load trained YOLO model
model = YOLO("best.pt")

# Open webcam
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)

print("Starting PPE Intelligence System...")

# Alarm cooldown timer
last_alert_time = 0
alert_cooldown = 2  # seconds

while True:

    ret, frame = cap.read()

    if not ret:
        print("Failed to access camera")
        break

    # Run YOLO detection
    results = model(frame)

    helmets = []
    vests = []
    persons = []

    # Process detections
    for r in results:

        boxes = r.boxes

        for box in boxes:

            cls = int(box.cls[0])
            conf = float(box.conf[0])

            x1, y1, x2, y2 = map(int, box.xyxy[0])

            label = model.names[cls]

            # Store objects
            if label == "helmet":
                helmets.append((x1, y1, x2, y2))

            elif label == "vest":
                vests.append((x1, y1, x2, y2))

            elif label == "person":
                persons.append((x1, y1, x2, y2))

            # Draw bounding boxes
            color = (0, 255, 0)

            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

            cv2.putText(
                frame,
                f"{label} {conf:.2f}",
                (x1, y1 - 10),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                color,
                2,
            )

    # PPE Intelligence Logic
    for (px1, py1, px2, py2) in persons:

        helmet_found = False
        vest_found = False

        # Check if helmet belongs to person
        for (hx1, hy1, hx2, hy2) in helmets:

            if hx1 > px1 and hx2 < px2:
                helmet_found = True

        # Check if vest belongs to person
        for (vx1, vy1, vx2, vy2) in vests:

            if vx1 > px1 and vx2 < px2:
                vest_found = True

        current_time = time.time()

        # NO HELMET ALERT
        if not helmet_found:

            cv2.putText(
                frame,
                "WARNING: NO HELMET",
                (px1, py1 - 40),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                (0, 0, 255),
                3,
            )

            # Play alarm with cooldown
            if current_time - last_alert_time > alert_cooldown:
                winsound.Beep(1000, 500)
                last_alert_time = current_time

        # NO VEST ALERT
        if not vest_found:

            cv2.putText(
                frame,
                "WARNING: NO SAFETY VEST",
                (px1, py1 - 70),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                (0, 0, 255),
                3,
            )

            # Play alarm with cooldown
            if current_time - last_alert_time > alert_cooldown:
                winsound.Beep(1500, 500)
                last_alert_time = current_time

    # Show output
    cv2.imshow("PPE Intelligence System", frame)

    # Press Q to quit
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

# Release resources
cap.release()
cv2.destroyAllWindows()