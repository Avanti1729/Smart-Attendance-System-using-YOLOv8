from flask import Flask, request, jsonify
from ultralytics import YOLO
import cv2
import numpy as np
import os
import time
import shutil

app = Flask(__name__)

# Load YOLO face model once at startup
facemodel = YOLO("yolov8n-face.pt")

# Output folder path
OUTPUT_FOLDER = "extracted_faces"


@app.route("/", methods=["GET"])
def home():
    return "Server is running ✅", 200


@app.route("/upload", methods=["POST"])
def upload_image():
    file = request.files.get("file")
    if not file:
        return jsonify({"error": "No file uploaded"}), 400

    # Convert uploaded file to OpenCV image
    file_bytes = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

    if image is None:
        return jsonify({"error": "Invalid image file"}), 400

    # --- Reset the folder for every new upload ---
    if os.path.exists(OUTPUT_FOLDER):
        shutil.rmtree(OUTPUT_FOLDER)  # delete old folder
    os.makedirs(OUTPUT_FOLDER, exist_ok=True)  # create new folder

    # Resize for detection (faster processing)
    new_width, new_height = 640, 480
    image_resized = cv2.resize(image, (new_width, new_height))

    # Perform face detection
    results = facemodel.predict(image_resized, conf=0.40)

    counter = 0
    saved_faces = []

    for result in results:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])

            # Scale back to original image size
            scale_x = image.shape[1] / new_width
            scale_y = image.shape[0] / new_height
            x1, y1, x2, y2 = (
                int(x1 * scale_x),
                int(y1 * scale_y),
                int(x2 * scale_x),
                int(y2 * scale_y),
            )

            # Ensure coordinates are within image bounds
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(image.shape[1], x2), min(image.shape[0], y2)

            # Crop face region
            face_crop = image[y1:y2, x1:x2]

            if face_crop.size > 0:
                filename = f"face_{counter}.jpg"
                filepath = os.path.join(OUTPUT_FOLDER, filename)
                success = cv2.imwrite(filepath, face_crop)
                if success:
                    print(f"Saved face → {filepath}")
                    saved_faces.append(filepath)
                    counter += 1

    return jsonify(
        {"message": f"{counter} faces extracted", "faces": saved_faces}
    ), 200


if __name__ == "__main__":
    # Run on all interfaces so Flutter (phone) can connect
    app.run(host="0.0.0.0", port=5000)
