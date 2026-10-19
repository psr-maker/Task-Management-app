import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/department_dashboard.dart';
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
  void dispose() {
    searchController.dispose();
    super.dispose();
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
          return const AppLoadError();
        }

        final searchText = searchController.text.toLowerCase();
        final filteredDepartments = allDepartments
            .where((dept) => dept.toLowerCase().contains(searchText))
            .toList();

        return Column(
          children: [
            _searchField(context, 'Search department'),
            const SizedBox(height: 12),
            Expanded(
              child: filteredDepartments.isEmpty
                  ? Center(
                      child: Text(
                        'No departments found',
                        style: TextStyle(color: WebTheme.mutedOf(context)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredDepartments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final dept = filteredDepartments[index];
                        return _ReportTile(
                          title: dept,
                          subtitle: 'Department dashboard',
                          icon: Icons.apartment_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DepartmentDashboardPage(department: dept),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _searchField(BuildContext context, String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
        prefixIcon: Icon(Icons.search, size: 18, color: WebTheme.mutedOf(context)),
        filled: true,
        fillColor: WebTheme.surfaceOf(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: WebTheme.brand),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ReportTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WebTheme.brandSoftOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: WebTheme.brand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebTheme.inkOf(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebTheme.mutedOf(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: WebTheme.mutedOf(context)),
            ],
          ),
        ),
      ),
    );
  }
}
