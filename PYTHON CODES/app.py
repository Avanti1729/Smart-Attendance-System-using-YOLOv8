from flask import Flask, request, jsonify
import os
import shutil

app = Flask(__name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route("/", methods=["GET"])
def home():
    return "Server is running ✅", 200

@app.route("/upload", methods=["POST"])
def upload_image():
    file = request.files.get("file")
    if not file:
        return jsonify({"error": "No file uploaded"}), 400

    # --- Clear uploads folder for fresh image ---
    if os.path.exists(UPLOAD_FOLDER):
        shutil.rmtree(UPLOAD_FOLDER)
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)

    # Save the uploaded image
    filepath = os.path.join(UPLOAD_FOLDER, "attendance.jpg")
    file.save(filepath)

    return jsonify({
        "message": "Attendance image saved successfully",
        "image_path": filepath
    }), 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
