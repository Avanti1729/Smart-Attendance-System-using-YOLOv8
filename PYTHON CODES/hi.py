import cvzone
from ultralytics import YOLO
import cv2
import os

# Path to your test image
image_path = "P section.jpg"
image = cv2.imread(image_path)

# Load YOLOv8 face model
facemodel = YOLO("yolov8n-face.pt")

# Resize for faster detection
new_width, new_height = 1200, 800
image_resized = cv2.resize(image, (new_width, new_height))

# Detect faces
face_result = facemodel.predict(image_resized, conf=0.40)

# Output folder for faces
output_folder = "extracted_faces"
os.makedirs(output_folder, exist_ok=True)

counter = 0

for info in face_result:
    for box in info.boxes:
        # Get bounding box on resized image
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        w, h = x2 - x1, y2 - y1

        # Scale back to original image
        scale_x = image.shape[1] / new_width
        scale_y = image.shape[0] / new_height
        ox1, oy1 = int(x1 * scale_x), int(y1 * scale_y)
        ox2, oy2 = int(x2 * scale_x), int(y2 * scale_y)

        # Crop from original image
        face_crop = image[oy1:oy2, ox1:ox2]

        if face_crop.size > 0:
            face_filename = os.path.join(output_folder, f"face_{counter}.jpg")
            cv2.imwrite(face_filename, face_crop)
            counter += 1
            print(f"Saved: {face_filename}")

        # Draw rectangle on resized image
        cvzone.cornerRect(image_resized, [x1, y1, w, h], l=3, rt=3)

cv2.imshow("Detected Faces", image_resized)
cv2.waitKey(0)
cv2.destroyAllWindows()

print(f"✅ {counter} faces saved in '{output_folder}'")
