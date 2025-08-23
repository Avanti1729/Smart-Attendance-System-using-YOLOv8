import cvzone
from ultralytics import YOLO
import cv2
import os

# Replace with the path to your image
image_path = "img/raa.jpeg"
image = cv2.imread(image_path)

# Load the face detection model
facemodel = YOLO('yolov8n-face.pt')

# Resize the image (optional, based on your requirements)
new_width = 1200  # Increase width
new_height = 800  # Increase height
image_resized = cv2.resize(image, (new_width, new_height))

# Perform face detection on resized image
face_result = facemodel.predict(image_resized, conf=0.40)

# Create a folder to save the extracted faces (if it doesn't exist)
output_folder = "extracted_faces"
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# Initialize a counter to name the face images
counter = 0

# Draw bounding boxes around detected faces and save them
for info in face_result:
    parameters = info.boxes
    for box in parameters:
        x1, y1, x2, y2 = box.xyxy[0]
        x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
        h, w = y2 - y1, x2 - x1

        # Scale the bounding box coordinates based on the resized image size
        scale_x = image.shape[1] / new_width
        scale_y = image.shape[0] / new_height

        # Adjust the coordinates to match the original image size
        x1 = int(x1 * scale_x)
        y1 = int(y1 * scale_y)
        x2 = int(x2 * scale_x)
        y2 = int(y2 * scale_y)

        # Crop the face from the original image
        face_crop = image[y1:y2, x1:x2]

        # Save the cropped face in the output folder
        face_filename = os.path.join(output_folder, f"face_{counter}.jpg")
        cv2.imwrite(face_filename, face_crop)

        # Increment the counter for unique filenames
        counter += 1

        # Optionally, draw a thinner rectangle around the face
        cvzone.cornerRect(image_resized, [x1, y1, w, h], l=3, rt=3)  # Thin bounding box

# Show the output image with the detected faces
cv2.imshow('Detected Faces', image_resized)
cv2.waitKey(0)
cv2.destroyAllWindows()

print(f"Extracted faces saved in '{output_folder}'")