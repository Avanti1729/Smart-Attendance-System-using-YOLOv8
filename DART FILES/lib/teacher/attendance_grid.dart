import 'package:flutter/material.dart';

class AttendanceGrid extends StatelessWidget {
  final Map<String, bool> attendance;
  final Function(String) onToggle;

  const AttendanceGrid({
    super.key,
    required this.attendance,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Sort the roll numbers in ascending order
    List<String> sortedRollNumbers = attendance.keys.toList()..sort();
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Reduced from 5 to 3 for larger cells
        childAspectRatio: 1.2, // Reduced from 2 to 1.2 for taller cells
        crossAxisSpacing: 8, // Added spacing between columns
        mainAxisSpacing: 8, // Added spacing between rows
      ),
      itemCount: sortedRollNumbers.length,
      itemBuilder: (context, i) {
        String rollNumber = sortedRollNumbers[i];
        bool present = attendance[rollNumber] ?? false;
        return GestureDetector(
          onTap: () => onToggle(rollNumber),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: present ? Colors.green[600] : Colors.red[600],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rollNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Increased from 10 to 12
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // Increased from 2 to 4
                  Icon(
                    present ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 20, // Increased from 16 to 20
                  ),
                  const SizedBox(height: 2),
                  Text(
                    present ? 'Present' : 'Absent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
