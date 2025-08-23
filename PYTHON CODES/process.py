import os
import cv2
from ultralytics import YOLO
import shutil

UPLOAD_FOLDER = "uploads"
OUTPUT_FOLDER = "extracted_faces"

# Ensure output folder exists
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Load YOLO model
facemodel = YOLO("yolov8n-face.pt")

# Get the latest uploaded image
files = sorted(os.listdir(UPLOAD_FOLDER))
if not files:
    print("No uploaded image found in uploads/")
    exit()

filepath = os.path.join(UPLOAD_FOLDER, files[-1])  # take the latest file
image = cv2.imread(filepath)
if image is None:
    print("Failed to read the uploaded image")
    exit()

# --- Clear previous extracted faces ---
if os.path.exists(OUTPUT_FOLDER):
    shutil.rmtree(OUTPUT_FOLDER)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# --- Extract faces ---
results = facemodel.predict(image, conf=0.4)
counter = 0
for result in results[0].boxes.xyxy:
    x1, y1, x2, y2 = map(int, result)
    face_crop = image[y1:y2, x1:x2]
    if face_crop.size > 0:
        face_path = os.path.join(OUTPUT_FOLDER, f"face_{counter}.jpg")
        cv2.imwrite(face_path, face_crop)
        counter += 1

print(f"Processed {files[-1]}, extracted {counter} face(s)")
