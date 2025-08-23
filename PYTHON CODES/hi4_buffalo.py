import cv2
import os
import numpy as np
import csv
from insightface.app import FaceAnalysis

# ------------------------------
# 1. Init InsightFace
# ------------------------------
face_app = FaceAnalysis(name="buffalo_l")
face_app.prepare(ctx_id=0, det_size=(256, 256))

# ------------------------------
# 2. Build embeddings DB from train/
# ------------------------------
DB_FOLDER = "train"
embeddings_db = {}

print("Building embeddings database...")

for student_id in os.listdir(DB_FOLDER):
    student_path = os.path.join(DB_FOLDER, student_id)
    if not os.path.isdir(student_path):
        continue

    student_embeddings = []

    for img_name in os.listdir(student_path):
        img_path = os.path.join(student_path, img_name)
        img = cv2.imread(img_path)
        if img is None:
            continue

        faces = face_app.get(img)
        if not faces:
            continue

        emb = faces[0].embedding
        emb = emb / np.linalg.norm(emb)  # normalize
        student_embeddings.append(emb)

    if student_embeddings:
        # Average embedding for stability
        mean_emb = np.mean(student_embeddings, axis=0)
        mean_emb = mean_emb / np.linalg.norm(mean_emb)
        embeddings_db[student_id] = mean_emb
        print(f"✅ Loaded {student_id} with {len(student_embeddings)} images")

print(f"\nDatabase built with {len(embeddings_db)} students.\n")

# ------------------------------
# 3. Recognize function (Cosine Similarity)
# ------------------------------
def recognize_face(embedding, threshold=0.4):
    embedding = embedding / np.linalg.norm(embedding)
    best_match, best_score = "Unknown", -1

    for student_id, db_emb in embeddings_db.items():
        sim = np.dot(db_emb, embedding)  # cosine similarity
        if sim > best_score:
            best_score, best_match = sim, student_id

    if best_score > threshold:
        return best_match, best_score
    return "Unknown", best_score

# ------------------------------
# 4. Test extracted faces
# ------------------------------
EXTRACTED = "extracted_faces"
results = []

for img_name in os.listdir(EXTRACTED):
    img_path = os.path.join(EXTRACTED, img_name)
    img = cv2.imread(img_path)
    if img is None:
        print(f"⚠️ Could not read {img_name}")
        continue

    faces = face_app.get(img)
    if not faces:
        print(f"❌ No face detected in {img_name}")
        continue

    emb = faces[0].embedding
    student, score = recognize_face(emb)

    print(f"📷 {img_name} → {student} (similarity={score:.3f})")
    results.append([img_name, student, round(score, 3)])

# ------------------------------
# 5. Save results to CSV
# ------------------------------
csv_file = "recognized_faces.csv"
with open(csv_file, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["img_name", "assigned_label", "similarity"])
    writer.writerows(results)

print(f"\n✅ Results saved to {csv_file}")
