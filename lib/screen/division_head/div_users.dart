import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/users/emp.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/user_create.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class DivUsers extends StatefulWidget {
  final String department;
  const DivUsers({super.key, required this.department});

  @override
  State<DivUsers> createState() => _DivUsersState();
}

class _DivUsersState extends State<DivUsers> {
  late Future<List<UserModel>> employeesFuture;
  List<Role> roles = [];
  bool isSelectionMode = false;
  Set<int> selectedEmpIds = {};
  bool isSearching = false;
  String selectedDepartment = "All";
  final TextEditingController searchController = TextEditingController();

  List<String> get childDepartments =>
      DivisionConfig.childDepartments(widget.department);

  @override
  void initState() {
    super.initState();
    employeesFuture = AdminService.getEmployeesByDepartments(childDepartments);
    _loadRoles();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final rolesList = await SuperAdminService.getRoles();
      if (!mounted) return;
      setState(() => roles = rolesList);
    } catch (e) {
      debugPrint("Failed to fetch Roles: $e");
    }
  }

  String getRoleName(dynamic roleId) {
    if (roleId == null) return '-';
    final raw = roleId.toString().trim();
    if (raw.isEmpty) return '-';

    final id = int.tryParse(raw);
    if (id == null) return raw;

    for (final role in roles) {
      if (role.id == id) return role.name;
    }
    return raw;
  }

  void _refreshUsers() {
    setState(() {
      employeesFuture = AdminService.getEmployeesByDepartments(
        childDepartments,
      );
      selectedEmpIds.clear();
      isSelectionMode = false;
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
    return employees.where((emp) {
      final matchesDept =
          selectedDepartment == "All" ||
          DivisionConfig.isAllowedDepartment(emp.department, [
            selectedDepartment,
          ]);
      if (!matchesDept) return false;
      if (query.isEmpty) return true;
      final roleName = getRoleName(emp.role).toLowerCase();
      return emp.name.toLowerCase().contains(query) ||
          emp.email.toLowerCase().contains(query) ||
          emp.department.toLowerCase().contains(query) ||
          roleName.contains(query);
    }).toList();
  }

  void _clearSelection() {
    setState(() {
      selectedEmpIds.clear();
      isSelectionMode = false;
    });
  }

  Future<void> _onAddGoalOrTask() async {
    if (selectedEmpIds.isEmpty) return;

    final employees = await employeesFuture;
    final selectedUsers = employees
        .where((emp) => selectedEmpIds.contains(emp.userId))
        .toList();
    final departments = selectedUsers
        .map((emp) => emp.department)
        .where((dept) => dept.trim().isNotEmpty)
        .toSet()
        .toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Createtask(
          assignedToIds: selectedEmpIds.toList(),
          assignedDepartments: departments,
        ),
      ),
    );

    if (!mounted) return;
    _clearSelection();
  }

  Future<void> _onAddUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateUsers()),
    );
    if (result == true) _refreshUsers();
  }

  Widget _buildDeptChip(String dept) {
    final selected = selectedDepartment == dept;
    final label = dept == "All" ? "All" : dept.replaceAll(" Department", "");
    final secondary = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => selectedDepartment = dept),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? secondary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? secondary : const Color(0xFFD0D5D2),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        title: isSelectionMode
            ? Text("${selectedEmpIds.length} selected")
            : isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "Search employee",
                  hintStyle: Theme.of(context).textTheme.headlineSmall,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text("Users"),
        actions: [
          if (isSelectionMode)
            TextButton.icon(
              onPressed: _onAddGoalOrTask,
              icon: const Icon(Icons.add_task, color: Colors.white),
              label: const Text(
                "Add Goal/Task",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else ...[
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) searchController.clear();
                });
              },
            ),
            IconButton(
              tooltip: "Add User",
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: _onAddUser,
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ["All", ...childDepartments]
                    .map(_buildDeptChip)
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: employeesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: RotatingFlower());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No Users Found"));
                  }

                  final filteredEmployees = _filterEmployees(snapshot.data!);
                  if (filteredEmployees.isEmpty) {
                    return const Center(child: Text("No Users Found"));
                  }

                  return ListView.builder(
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      final isSelected = selectedEmpIds.contains(emp.userId);
                      return Card(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onLongPress: () => _toggleSelection(emp.userId),
                          leading: isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  activeColor: secondary,
                                  onChanged: (_) =>
                                      _toggleSelection(emp.userId),
                                )
                              : CircleAvatar(
                                  backgroundColor: secondary,
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
                            style: TextStyle(
                              color: secondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            getRoleName(emp.role),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: isSelectionMode
                              ? null
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            if (isSelectionMode) {
                              _toggleSelection(emp.userId);
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeReportPage(
                                  userid: emp.userId,
                                  username: emp.name,
                                  role: emp.role,
                                ),
                              ),
                            );
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
    ),
    );
  }
}
