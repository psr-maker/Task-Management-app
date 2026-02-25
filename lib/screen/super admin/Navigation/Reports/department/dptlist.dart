import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/dept.dart';
import 'package:staff_work_track/services/reports_service.dart';

class DepartmentListPage extends StatefulWidget {
  const DepartmentListPage({super.key});

  @override
  State<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
  late Future<List<String>> departmentsFuture;

  @override
  void initState() {
    super.initState();
    departmentsFuture = ReportsService.getAllDepartments();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: departmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final departments = snapshot.data ?? [];

        if (departments.isEmpty) {
          return const Center(child: Text("No Departments Found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: departments.length,
          itemBuilder: (context, index) {
            final dept = departments[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color.fromARGB(255, 134, 170, 136),
              ),
              child: ListTile(
                leading: const Icon(Icons.apartment),
                title: Text(
                  dept,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DepartmentReportsTab(department: dept),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
