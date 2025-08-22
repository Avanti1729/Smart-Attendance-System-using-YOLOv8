import time
import os
import subprocess

UPLOAD_FOLDER = "uploads"
processed_mtime = None

print("Worker started, monitoring uploads/ ...")

while True:
    files = os.listdir(UPLOAD_FOLDER)
    if files:
        latest_file = files[0]  # assuming only 1 file
        filepath = os.path.join(UPLOAD_FOLDER, latest_file)
        mtime = os.path.getmtime(filepath)

        if processed_mtime is None or mtime != processed_mtime:
            print(f"New or updated image detected: {latest_file}. Running process.py ...")
            subprocess.run(["python3", "process.py"])
            processed_mtime = mtime  # update last processed time

    time.sleep(1)  # check every 1 second
