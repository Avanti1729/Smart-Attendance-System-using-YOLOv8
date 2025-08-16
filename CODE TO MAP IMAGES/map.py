import csv
import os
from datetime import datetime

# Paths
students_file = "students.csv"
face_folder = "extracted_faces"
attendance_file = "attendance.csv"

# Load all student data
usn_to_name = {}
with open(students_file, mode='r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        usn_to_name[int(row["USN"])] = row["Name"]

# Set of present USNs from detected faces
present_usns = set()

for filename in sorted(os.listdir(face_folder)):
    if filename.startswith("USN_") and filename.endswith(".jpg"):
        try:
            usn = int(filename.split("_")[1].split(".")[0])
            present_usns.add(usn)
        except ValueError:
            continue

# Prepare attendance list
attendance_data = []
timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

for usn, name in usn_to_name.items():
    status = "Present" if usn in present_usns else "Absent"
    attendance_data.append([usn, name, status, timestamp])

# Save attendance to CSV
with open(attendance_file, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(["USN", "Name", "Status", "Timestamp"])
    writer.writerows(attendance_data)

print("✅ Full attendance saved with present & absent!")