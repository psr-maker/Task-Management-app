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
  final TextEditingController searchController = TextEditingController();
  List<String> allDepartments = [];
  @override
  void initState() {
    super.initState();
    departmentsFuture = ReportsService.getAllDepartments().then((list) {
      allDepartments = list;
      return list;
    });
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

        // Filter based on search text
        final searchText = searchController.text.toLowerCase();
        final filteredDepartments = allDepartments
            .where((dept) => dept.toLowerCase().contains(searchText))
            .toList();

        if (filteredDepartments.isEmpty) {
          return const Center(child: Text("No Departments Found"));
        }
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search Department...",
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDepartments.length,
                  itemBuilder: (context, index) {
                    final dept = filteredDepartments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.background,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.apartment),
                        title: Text(
                          dept,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DepartmentReportsTab(department: dept),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
