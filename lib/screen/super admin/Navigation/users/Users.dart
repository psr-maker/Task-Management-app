import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Employee/empdetails.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/user_create.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/users_data_table.dart';

class Usersview extends StatefulWidget {
  final bool showAppBar;

  const Usersview({super.key, this.showAppBar = false});

  @override
  State<Usersview> createState() => _UsersviewState();
}

class _UsersviewState extends State<Usersview> {
  late Future<List<UserModel>> employeesFuture;

  bool isSelectionMode = false;
  Set<int> selectedEmpIds = {};

  bool isSearching = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    employeesFuture = SuperAdminService.getAllUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _refreshUsers() {
    setState(() {
      employeesFuture = SuperAdminService.getAllUsers();
    });
  }

  void _toggleSelection(int userId) {
    setState(() {
      if (selectedEmpIds.contains(userId)) {
        selectedEmpIds.remove(userId);

        if (selectedEmpIds.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedEmpIds.add(userId);
        isSelectionMode = true;
      }
    });
  }

  List<UserModel> _filterEmployees(List<UserModel> employees) {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return employees;
    }

    return employees.where((emp) {
      return emp.name.toLowerCase().contains(query) ||
          emp.email.toLowerCase().contains(query) ||
          emp.department.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _onAddPressed() async {
    if (selectedEmpIds.isNotEmpty) {
      await openFormPage(
        context,
        Createtask(assignedToIds: selectedEmpIds.toList()),
        maxWidth: 880,
      );
      return;
    }

    final result = await openFormPage(
      context,
      const CreateUsers(),
      maxWidth: 560,
    );

    if (result == true) {
      _refreshUsers();
    }
  }

  Widget _addChip() {
    return GestureDetector(
      onTap: _onAddPressed,
      child: Chip(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        label: Text(
          selectedEmpIds.isNotEmpty ? "Add Task" : "Users +",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !AppLayout.isMobile(context);

    return Scaffold(
      appBar: isWeb && !widget.showAppBar
          ? null
          : AppBar(
              title: isSearching
                  ? TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Search employee",
                        hintStyle: Theme.of(context).textTheme.headlineSmall,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    )
                  : Text(
                      "Users List",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              actions: [
                IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      isSearching = !isSearching;

                      if (!isSearching) {
                        searchController.clear();
                      }
                    });
                  },
                ),
              ],
            ),
      body: Padding(
        padding: isWeb
            ? AppLayout.pagePadding(context)
            : const EdgeInsets.all(10),
        child: Column(
          children: [
            if (isWeb)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppLayout.isTablet(context)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const WebPageHeader(
                            title: 'Users',
                            subtitle: 'People, roles and departments',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Search name, email or department',
                                    hintStyle: const TextStyle(fontSize: 13),
                                    prefixIcon: const Icon(Icons.search, size: 18),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _addChip(),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const WebPageHeader(
                            title: 'Users',
                            subtitle: 'People, roles and departments',
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search name, email or department',
                                hintStyle: const TextStyle(fontSize: 13),
                                prefixIcon: const Icon(Icons.search, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _addChip(),
                        ],
                      ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_addChip()],
              ),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: employeesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: RotatingFlower());
                  }

                  if (snapshot.hasError) {
                    return const AppLoadError();
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No Users Found"));
                  }

                  final employees = snapshot.data!
                      .where((emp) => emp.role != "1")
                      .toList();

                  final filteredEmployees = _filterEmployees(employees);

                  if (filteredEmployees.isEmpty) {
                    return const Center(child: Text("No Users Found"));
                  }

                  if (isWeb) {
                    return UsersDataTable(
                      users: filteredEmployees,
                      selectedIds: selectedEmpIds,
                      selectionMode: isSelectionMode,
                      onToggle: (emp) => _toggleSelection(emp.userId),
                      onTap: (emp) async {
                        if (isSelectionMode) {
                          _toggleSelection(emp.userId);
                          return;
                        }
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeeDetail(employee: emp),
                          ),
                        );
                        if (result == true) {
                          _refreshUsers();
                        }
                      },
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredEmployees.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      final isSelected = selectedEmpIds.contains(emp.userId);

                      return Card(
                        color: Theme.of(context).colorScheme.background,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onLongPress: () {
                            _toggleSelection(emp.userId);
                          },
                          leading: isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  onChanged: (_) {
                                    _toggleSelection(emp.userId);
                                  },
                                )
                              : CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  child: Text(
                                    emp.name.isNotEmpty
                                        ? emp.name[0].toUpperCase()
                                        : "?",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                          title: Text(
                            emp.name,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                emp.department,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1C2B22),
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelectionMode
                              ? null
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            if (isSelectionMode) {
                              _toggleSelection(emp.userId);
                              return;
                            }

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetail(employee: emp),
                              ),
                            );

                            if (result == true) {
                              _refreshUsers();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
