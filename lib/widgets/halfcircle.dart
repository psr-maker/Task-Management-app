import 'package:flutter/material.dart';

class PerformanceDashboard extends StatelessWidget {
  final List<dynamic> topEmployees;
  final List<dynamic> lowEmployees;
  final List<dynamic> topDepartments;
  final List<dynamic> lowDepartments;

  const PerformanceDashboard({
    super.key,
    required this.topEmployees,
    required this.lowEmployees,
    required this.topDepartments,
    required this.lowDepartments,
  });

  Widget buildPerformanceCard(String title, List<dynamic> list) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...list.map((e) => ListTile(
                  title: Text(e['EmployeeName'] ?? e['DepartmentName']),
                  subtitle: Text(
                      "Completion: ${e['CompletionPercentage'].toStringAsFixed(2)}%"),
                  trailing: Text("Tasks: ${e['TotalTasks']}"),
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildPerformanceCard("Top 5 Employees", topEmployees),
          buildPerformanceCard("Low 5 Employees", lowEmployees),
          buildPerformanceCard("Top Departments", topDepartments),
          buildPerformanceCard("Low Departments", lowDepartments),
        ],
      ),
    );
  }
}