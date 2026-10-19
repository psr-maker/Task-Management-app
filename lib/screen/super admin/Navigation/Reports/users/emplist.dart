import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/dashboard.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class EmployeeReportsList extends StatefulWidget {
  final String backToLabel;

  const EmployeeReportsList({
    super.key,
    this.backToLabel = 'Back to reports',
  });

  @override
  State<EmployeeReportsList> createState() => _EmployeeReportsListState();
}

class _EmployeeReportsListState extends State<EmployeeReportsList> {
  late Future<List<UserModel>> usersFuture;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    usersFuture = SuperAdminService.getAllUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
        }

        if (snapshot.hasError) {
          return const AppLoadError();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: TextStyle(color: WebTheme.mutedOf(context)),
            ),
          );
        }

        final filteredByRole = snapshot.data!
            .where((emp) => emp.role != "1")
            .toList();

        final query = searchController.text.toLowerCase();
        final finalList = filteredByRole.where((user) {
          if (query.isEmpty) return true;
          return user.name.toLowerCase().contains(query) ||
              user.department.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            _searchField(context),
            const SizedBox(height: 12),
            Expanded(
              child: finalList.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: WebTheme.mutedOf(context)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: finalList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = finalList[index];
                        final initial = user.name.trim().isEmpty
                            ? '?'
                            : user.name.trim()[0].toUpperCase();
                        return Material(
                          color: WebTheme.surfaceOf(context),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StaffDashboard(
                                    userid: user.userId,
                                    role: user.role,
                                    backToLabel: widget.backToLabel,
                                    replaceShellMenu: true,
                                    onBackToManager: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: WebTheme.lineOf(context)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: WebTheme.brandSoftOf(context),
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color: WebTheme.brand,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
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
                                          user.department.trim().isEmpty
                                              ? 'Staff dashboard'
                                              : user.department,
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
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: WebTheme.mutedOf(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _searchField(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search users',
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
