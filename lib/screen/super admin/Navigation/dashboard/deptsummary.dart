import 'package:flutter/material.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class DepartmentSummaryPage extends StatefulWidget {
  const DepartmentSummaryPage({super.key});

  @override
  State<DepartmentSummaryPage> createState() => _DepartmentSummaryPageState();
}

class _DepartmentSummaryPageState extends State<DepartmentSummaryPage> {
  late Future<List<dynamic>> departmentData;

  @override
  void initState() {
    super.initState();
    departmentData = DashboardService.getDepartmentSummary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: departmentData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading data"));
        }

        final departments = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: departments.length,
          itemBuilder: (context, index) {
            final dept = departments[index];

            return DepartmentCard(
              departmentName: dept["department"],
              totalTasks: dept["totalTasks"],
              completed: dept["completed"],
              pending: dept["pending"],
              inProgress: dept["inProgress"],
              overdue: dept["overdue"],
              completedPercentage: dept["completedPercentage"].toDouble(),
               users: dept["totalStaff"],
            );
          },
        );
      },
    );
  }
}
