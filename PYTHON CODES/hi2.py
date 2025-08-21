from ultralytics import YOLO
import cv2
from deepface import DeepFace
import matplotlib.pyplot as plt
# Load YOLO model (face detector)
model = YOLO('yolov8n-face.pt')  # your trained Roboflow model

# Path to your reference dataset
reference_db = "./train/"

# Load a single image
img_path = "B_SECTION.jpeg"
frame = cv2.imread(img_path)

# Detect faces
results = model.predict(frame, conf=0.75)

for r in results[0].boxes.xyxy:  # Loop through detections
    x1, y1, x2, y2 = map(int, r)
    face_crop = frame[y1:y2, x1:x2]

    # Recognize face with DeepFace
    try:
        result = DeepFace.find(face_crop, db_path=reference_db, enforce_detection=False)
        if len(result[0]) > 0:
            student_id = result[0].iloc[0]['identity'].split("\\")[-2]
            label = f"{student_id}"
        else:
            label = "Unknown"
    except:
        label = "Unknown"

    # Draw results
    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
    cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

# Show the output
frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

# Show the output with matplotlib
plt.figure(figsize=(12, 12)) 
plt.imshow(frame_rgb)
plt.axis("off")
plt.title("Image Face Recognition")
plt.show()
