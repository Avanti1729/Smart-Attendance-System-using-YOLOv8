import 'package:flutter/material.dart';
import '../models/student_model.dart';

class StudentAttendancePage extends StatefulWidget {
  final Student? student;

  const StudentAttendancePage({super.key, this.student});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'This Semester', 'This Year'];
  
  // Sample attendance data
  final Map<String, dynamic> _attendanceData = {
    'overall': 78.5,
    'totalClasses': 45,
    'attended': 35,
    'absent': 10,
    'subjects': {
      'Machine Learning': {'attended': 8, 'total': 10, 'percentage': 80.0},
      'Data Structures': {'attended': 7, 'total': 9, 'percentage': 77.8},
      'Database Systems': {'attended': 6, 'total': 8, 'percentage': 75.0},
      'Software Engineering': {'attended': 9, 'total': 10, 'percentage': 90.0},
      'Computer Networks': {'attended': 5, 'total': 8, 'percentage': 62.5},
    },
    'recentAttendance': [
      {'date': '2024-01-15', 'subject': 'Machine Learning', 'status': 'Present'},
      {'date': '2024-01-15', 'subject': 'Data Structures', 'status': 'Present'},
      {'date': '2024-01-14', 'subject': 'Database Systems', 'status': 'Absent'},
      {'date': '2024-01-14', 'subject': 'Software Engineering', 'status': 'Present'},
      {'date': '2024-01-13', 'subject': 'Computer Networks', 'status': 'Present'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter
            _buildHeader(),
            const SizedBox(height: 20),

            // Overall Attendance Card
            _buildOverallAttendanceCard(),
            const SizedBox(height: 20),

            // Subject-wise Attendance
            _buildSubjectWiseAttendance(),
            const SizedBox(height: 20),

            // Recent Attendance
            _buildRecentAttendance(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.indigo, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Attendance Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
              items: _periods.map((period) => DropdownMenuItem(
                value: period,
                child: Text(period),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallAttendanceCard() {
    final percentage = _attendanceData['overall'];
    final color = _getAttendanceColor(percentage);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '${_attendanceData['attended']} out of ${_attendanceData['totalClasses']} classes',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceMetric(
                    'Present',
                    '${_attendanceData['attended']}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAttendanceMetric(
                    'Absent',
                    '${_attendanceData['absent']}',
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildAttendanceMetric(
                    'Total Classes',
                    '${_attendanceData['totalClasses']}',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectWiseAttendance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject-wise Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_attendanceData['subjects'] as Map<String, dynamic>).entries.map(
              (entry) {
                final subject = entry.key;
                final data = entry.value;
                final percentage = data['percentage'];
                final color = _getAttendanceColor(percentage);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${data['attended']}/${data['total']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAttendance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_attendanceData['recentAttendance'] as List).map(
              (record) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: record['status'] == 'Present' 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Icon(
                    record['status'] == 'Present' ? Icons.check : Icons.close,
                    color: record['status'] == 'Present' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(record['subject']),
                subtitle: Text(record['date']),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record['status'] == 'Present' 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record['status'],
                    style: TextStyle(
                      color: record['status'] == 'Present' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMetric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }
}