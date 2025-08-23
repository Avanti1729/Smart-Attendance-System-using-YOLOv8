import cv2
import numpy as np
import insightface
import os
from numpy.linalg import norm

# Load face detector + ArcFace model
print("Loading InsightFace model...")
model = insightface.app.FaceAnalysis(name="buffalo_l")  # Strong model
model.prepare(ctx_id=0, det_size=(640, 640))
print("Model loaded successfully!")

def get_embedding(img):
    """Extract face embedding from image"""
    faces = model.get(img)
    if len(faces) == 0:
        return None
    return faces[0].normed_embedding  # 512-D vector

def load_database_from_test_folder(test_folder_path="test"):
    """Load all student images from test folder and create embeddings database"""
    database = {}

    print(f"Loading training images from '{test_folder_path}' folder...")

    # Get all student directories
    if not os.path.exists(test_folder_path):
        print(f"Error: {test_folder_path} folder not found!")
        return database

    student_dirs = [d for d in os.listdir(test_folder_path)
                   if os.path.isdir(os.path.join(test_folder_path, d))]

    print(f"Found {len(student_dirs)} student directories: {student_dirs}")

    for student_id in student_dirs:
        student_path = os.path.join(test_folder_path, student_id)
        database[student_id] = []

        # Get all image files in student directory
        image_files = [f for f in os.listdir(student_path)
                      if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp'))]

        print(f"Processing {student_id}: {len(image_files)} images")

        for img_file in image_files:
            img_path = os.path.join(student_path, img_file)
            try:
                img = cv2.imread(img_path)
                if img is None:
                    print(f"  Warning: Could not load {img_path}")
                    continue

                emb = get_embedding(img)
                if emb is not None:
                    database[student_id].append(emb)
                    print(f"  ✓ Added embedding for {img_file}")
                else:
                    print(f"  ⚠ No face detected in {img_file}")
            except Exception as e:
                print(f"  ✗ Error processing {img_file}: {e}")

        if len(database[student_id]) == 0:
            print(f"  Warning: No valid embeddings found for {student_id}")
        else:
            print(f"  Success: {len(database[student_id])} embeddings stored for {student_id}")

    # Remove students with no embeddings
    database = {k: v for k, v in database.items() if len(v) > 0}

    print(f"\nDatabase loaded successfully!")
    print(f"Total students with valid embeddings: {len(database)}")
    for student_id, embeddings in database.items():
        print(f"  {student_id}: {len(embeddings)} embedding(s)")

    return database

def recognize_face(img, database, threshold=0.8):
    """Recognize face in image against database"""
    emb = get_embedding(img)
    if emb is None:
        return "No face detected", 1.0

    best_match = None
    best_score = float('inf')  # lower is better

    for person, embeddings in database.items():
        for ref_emb in embeddings:
            # Calculate cosine distance
            dist = norm(emb - ref_emb)
            if dist < best_score:
                best_score = dist
                best_match = person

    if best_score < threshold:  # threshold (tune between 0.6 - 1.0)
        return f"{best_match}", best_score
    else:
        return "Unknown", best_score

# Load database from test folder
database = load_database_from_test_folder()

if len(database) == 0:
    print("No valid training data found. Exiting...")
    exit()

print(f"\nStarting webcam... Press 'q' to quit")
print("Recognition threshold: 0.8 (lower = stricter)")

# Start webcam
cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Error: Could not open webcam")
    exit()

# Try to use GUI, fallback to console mode if it fails
use_gui = True
try:
    # Test if GUI is available
    test_frame = np.zeros((100, 100, 3), dtype=np.uint8)
    cv2.imshow("Test", test_frame)
    cv2.waitKey(1)
    cv2.destroyAllWindows()
    print("GUI mode available - using webcam display")
except cv2.error:
    use_gui = False
    print("GUI mode not available - using console mode")
    print("Recognition results will be printed to console and saved as images")

import time
frame_count = 0
start_time = time.time()

while True:
    ret, frame = cap.read()
    if not ret:
        print("Error: Could not read frame")
        break

    frame_count += 1

    # Process every 10th frame in console mode to reduce load
    if not use_gui and frame_count % 10 != 0:
        continue

    # Detect faces in current frame
    faces = model.get(frame)

    if len(faces) > 0 and not use_gui:
        timestamp = time.strftime("%H:%M:%S")
        print(f"\n[{timestamp}] Frame {frame_count}: {len(faces)} face(s) detected")

    for i, face in enumerate(faces):
        # Get bounding box coordinates
        x1, y1, x2, y2 = face.bbox.astype(int)

        # Extract face region
        face_crop = frame[y1:y2, x1:x2]

        # Recognize face
        label, score = recognize_face(face_crop, database)

        # Choose color based on recognition result
        if label == "Unknown" or label == "No face detected":
            color = (0, 0, 255)  # Red for unknown
            display_text = f"{label}"
        else:
            color = (0, 255, 0)  # Green for recognized
            display_text = f"{label} ({score:.2f})"

        # Draw bounding box and label
        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

        # Add background for text
        text_size = cv2.getTextSize(display_text, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)[0]
        cv2.rectangle(frame, (x1, y1 - text_size[1] - 10),
                     (x1 + text_size[0], y1), color, -1)

        # Add text
        cv2.putText(frame, display_text, (x1, y1 - 5),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)

        # Print results in console mode
        if not use_gui:
            print(f"  Face {i+1}: {label} (distance: {score:.3f})")

            # Save detection image
            if label != "Unknown":
                output_folder = "detections"
                os.makedirs(output_folder, exist_ok=True)
                filename = f"detection_{timestamp.replace(':', '-')}_{label}.jpg"
                filepath = os.path.join(output_folder, filename)
                cv2.imwrite(filepath, frame)
                print(f"    Saved: {filepath}")

    if use_gui:
        # Display frame (only if GUI is available)
        try:
            cv2.imshow("Face Recognition - Press 'q' to quit", frame)

            # Check for quit key
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
        except cv2.error:
            print("GUI display failed, switching to console mode")
            use_gui = False
    else:
        # In console mode, run for 30 seconds or until Ctrl+C
        if time.time() - start_time > 30:
            print("\n30 seconds completed. Stopping...")
            break

        # Check for keyboard interrupt
        try:
            time.sleep(0.1)
        except KeyboardInterrupt:
            print("\nStopping due to keyboard interrupt...")
            break

# Cleanup
cap.release()
if use_gui:
    cv2.destroyAllWindows()
print("Webcam closed.")