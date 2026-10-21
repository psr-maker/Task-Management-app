import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/admintask_list.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/allgoals.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/craete_warnings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/edit_user.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/widgets/adaptive_goal_cards.dart';

class EmployeeDetail extends StatefulWidget {
  final UserModel employee;

  const EmployeeDetail({super.key, required this.employee});

  @override
  State<EmployeeDetail> createState() => _EmployeeDetailState();
}

class _EmployeeDetailState extends State<EmployeeDetail> {
  bool isLoading = true;
  bool isActive = false;
  bool isUpdating = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  bool showFilter = false;
  String searchQuery = "";
  final TaskFilterModel taskFilter = TaskFilterModel();
  List<String> departmentsList = [];
  bool permissionLoaded = false;
  bool canEditDelete = false;
  bool canSendWarning = false;
  bool canShowMenu = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  List<dynamic> staffGoals = [];
  List<Map<String, dynamic>> standaloneTasks = [];
  final Set<String> _removedGoalCodes = {};
  DateTime? _lastRefreshTime;
  DateTime? _lastGoalRefreshTime;
  late UserModel employee;
  List<Role> roles = [];

  List<dynamic> applyGoalSearch(List<dynamic> goals) {
    List<dynamic> filtered = goals;

    // SEARCH
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();

      filtered = filtered.where((goal) {
        final title = (goal["title"] ?? "").toString().toLowerCase();
        final code = (goal["goalCode"] ?? "").toString().toLowerCase();
        final months = goal["monthlyGoals"];
        final monthText = months is List
            ? months
                .whereType<Map>()
                .map((month) =>
                    "${month["title"] ?? ""} ${month["goalCode"] ?? ""}")
                .join(" ")
                .toLowerCase()
            : "";
        final department = (goal["department"] ?? "").toString().toLowerCase();
        final status = (goal["status"] ?? "").toString().toLowerCase();
        final priority = (goal["priority"] ?? "").toString().toLowerCase();

        return title.contains(query) ||
            code.contains(query) ||
            monthText.contains(query) ||
            department.contains(query) ||
            status.contains(query) ||
            priority.contains(query);
      }).toList();
    }

    // STATUS FILTER
    if (taskFilter.status != null && taskFilter.status!.isNotEmpty) {
      filtered = filtered.where((goal) {
        String goalStatus = (goal["status"] ?? "")
            .toString()
            .toLowerCase()
            .replaceAll(' ', '');

        String filterStatus = taskFilter.status!.toLowerCase().replaceAll(
          ' ',
          '',
        );

        return goalStatus == filterStatus;
      }).toList();
    }
    // PRIORITY FILTER
    if (taskFilter.priority != null && taskFilter.priority!.isNotEmpty) {
      filtered = filtered.where((goal) {
        return (goal["priority"] ?? "").toString().toLowerCase() ==
            taskFilter.priority!.toLowerCase();
      }).toList();
    }

    // DEPARTMENT FILTER
    if (taskFilter.department != null && taskFilter.department!.isNotEmpty) {
      filtered = filtered.where((goal) {
        return (goal["department"] ?? "").toString().toLowerCase() ==
            taskFilter.department!.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  List<Map<String, dynamic>> applyTaskSearch(
    List<Map<String, dynamic>> tasks,
  ) {
    List<Map<String, dynamic>> filtered = tasks;

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        final title = (task["task"] ?? task["title"] ?? "")
            .toString()
            .toLowerCase();
        final code = (task["taskCode"] ?? "").toString().toLowerCase();
        final department = (task["department"] ?? task["assignerDepartment"] ?? "")
            .toString()
            .toLowerCase();
        final status = (task["status"] ?? "").toString().toLowerCase();
        final priority = (task["priority"] ?? "").toString().toLowerCase();

        return title.contains(query) ||
            code.contains(query) ||
            department.contains(query) ||
            status.contains(query) ||
            priority.contains(query);
      }).toList();
    }

    if (taskFilter.status != null && taskFilter.status!.isNotEmpty) {
      filtered = filtered.where((task) {
        final taskStatus = (task["status"] ?? "")
            .toString()
            .toLowerCase()
            .replaceAll(' ', '');
        final filterStatus = taskFilter.status!.toLowerCase().replaceAll(
          ' ',
          '',
        );
        return taskStatus == filterStatus;
      }).toList();
    }

    if (taskFilter.priority != null && taskFilter.priority!.isNotEmpty) {
      filtered = filtered.where((task) {
        return (task["priority"] ?? "").toString().toLowerCase() ==
            taskFilter.priority!.toLowerCase();
      }).toList();
    }

    if (taskFilter.department != null && taskFilter.department!.isNotEmpty) {
      filtered = filtered.where((task) {
        final department =
            (task["department"] ?? task["assignerDepartment"] ?? "")
                .toString()
                .toLowerCase();
        return department == taskFilter.department!.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  List<dynamic> _tasksOf(dynamic goal) {
    if (goal is! Map) return [];
    final tasks = <dynamic>[];
    final own = goal["tasks"];
    if (own is List) tasks.addAll(own);
    final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
    if (months is List) {
      for (final month in months) {
        tasks.addAll(_tasksOf(month));
      }
    }
    return tasks;
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadRoles();
    employee = widget.employee;
  }

  void _initializeData() {
    _checkEditPermission(widget.employee);
    _reloadEmployeeStatus();
    loadEmployeeGoals(showLoader: true);
  }

  /// Reload the latest employee status and role from server
  Future<void> _reloadEmployeeStatus() async {
    try {
      final details = await SuperAdminService.getAdminDetails(
        widget.employee.userId,
      );

      if (!mounted) return;
      setState(() {
        isActive = details.status.toLowerCase() == "active";
        employee = UserModel(
          userId: details.userId,
          name: details.name,
          email: details.email,
          department: details.department,
          role: details.role,
          status: details.status,
          createdBy: details.createdBy,
          wasEdited: details.wasEdited,
        );
      });
      return;
    } catch (e) {
      debugPrint("Failed to reload employee details: $e");
    }

    try {
      final users = await SuperAdminService.getEmployees();

      if (!mounted) return;
      for (var user in users) {
        if (user.userId == widget.employee.userId) {
          setState(() {
            isActive = user.status.toLowerCase() == "active";
            employee = user;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Failed to reload employee status: $e");
    }
  }

  Future<void> _loadRoles() async {
    try {
      final rolesList = await SuperAdminService.getRoles();

      if (!mounted) return;

      setState(() {
        roles = rolesList;
      });
    } catch (e) {
      debugPrint("Failed to fetch Roles: $e");

      if (!mounted) return;

      showTopMessage("Failed to load roles", isError: true);
    }
  }

  String getRoleName(dynamic roleId) {
    if (roleId == null) return '-';
    final name = AppRoles.displayName(
      roleId.toString(),
      roles: roles,
      fallback: '-',
    );
    return name.isEmpty ? '-' : name;
  }

  Future<void> loadEmployeeGoals({bool showLoader = false}) async {
    try {
      if (showLoader && mounted) setState(() => isLoading = true);

      final goals = await AdminService.getusergoalbyid(widget.employee.userId);

      List<Map<String, dynamic>> tasks = [];
      try {
        tasks = await AdminService.getAdminTasks(widget.employee.userId);
      } catch (e) {
        debugPrint("Task load error: $e");
      }

      List<dynamic> detailed = [];
      try {
        detailed = await SuperAdminService.getGoals();
      } catch (e) {
        debugPrint("Detailed goals load error: $e");
      }

      final visible = goals.where((goal) {
        final code = (goal["goalCode"] ?? goal["GoalCode"] ?? "")
            .toString()
            .trim();
        return !_removedGoalCodes.contains(code);
      }).toList();

      final employeeId = widget.employee.userId;
      final cards = goalsForCards(
        goalsVisibleToUser(
          [...visible, ...detailed],
          userId: employeeId,
          listedForUser: visible,
        ),
      );
      final employeeGoalCodes = <String>{};
      void collectGoalCodes(dynamic raw) {
        if (raw is! Map) return;
        final code = (raw["goalCode"] ?? raw["GoalCode"] ?? "")
            .toString()
            .trim()
            .toLowerCase();
        if (code.isNotEmpty && code != "null") employeeGoalCodes.add(code);
        final months = raw["monthlyGoals"] ?? raw["MonthlyGoals"];
        if (months is List) {
          for (final month in months) {
            collectGoalCodes(month);
          }
        }
      }
      for (final goal in cards) {
        collectGoalCodes(goal);
      }

      final fromDetailed = <Map<String, dynamic>>[];
      void collectDetailed(dynamic raw) {
        if (raw is! Map) return;
        final nested = raw["tasks"] ?? raw["Tasks"];
        if (nested is List) {
          for (final task in nested) {
            if (task is! Map) continue;
            final goalCode = taskGoalCode(task).toLowerCase();
            if (!employeeGoalCodes.contains(goalCode)) continue;
            fromDetailed.add(Map<String, dynamic>.from(task));
          }
        }
        final months = raw["monthlyGoals"] ?? raw["MonthlyGoals"];
        if (months is List) {
          for (final month in months) {
            collectDetailed(month);
          }
        }
      }
      for (final goal in detailed) {
        collectDetailed(goal);
      }

      final standalone = attachTasksToGoals(cards, [...fromDetailed, ...tasks]);

      if (mounted) {
        setState(() {
          staffGoals = cards;
          standaloneTasks = standalone;

          departmentsList = {
            ...goals.map((g) => (g["department"] ?? "").toString()),
            ...standalone.map(
              (t) =>
                  (t["department"] ?? t["assignerDepartment"] ?? "").toString(),
            ),
          }.where((d) => d.isNotEmpty).toList();

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Goal load error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkEditPermission(UserModel employee) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final loginUserIdRaw = JwtHelper.getuid(token);
    final loginUserRoleRaw = JwtHelper.getRole(token);

    if (loginUserIdRaw == null || loginUserRoleRaw == null) return;

    final loginUserId = loginUserIdRaw.toString().trim();
    final loginUserRole = loginUserRoleRaw.toString().trim();

    String createdById = "";
    if (employee.createdBy.isNotEmpty) {
      if (employee.createdBy.contains('-')) {
        createdById = employee.createdBy.split('-')[0].trim();
      } else {
        createdById = employee.createdBy.trim();
      }
    }

    await SuperAdminService.ensureRolesLoaded();
    final isDirector = AppRoles.isDirector(loginUserRole);
    final isManager = AppRoles.isManager(loginUserRole);
    final isTargetDirector = AppRoles.isDirector(employee.role);
    final createdByMatch = loginUserId == createdById;

    var loginDept = (JwtHelper.getDepartment(token) ?? "")
        .toString()
        .trim()
        .toLowerCase();
    if (loginDept.isEmpty) {
      try {
        final details = await SuperAdminService.getAdminDetails(
          int.parse(loginUserId),
        );
        loginDept = details.department.trim().toLowerCase();
      } catch (_) {}
    }

    final employeeDept = employee.department.trim().toLowerCase();
    final sameDepartment =
        loginDept.isNotEmpty &&
        employeeDept.isNotEmpty &&
        loginDept == employeeDept;

    final allowEditDelete =
        isDirector ||
        (isManager &&
            !isTargetDirector &&
            (sameDepartment || createdByMatch));
    final isHr =
        isManager && DivisionConfig.normalize(loginDept) == "hr";
    final allowWarning = isDirector || isHr;

    final showMenu = allowEditDelete || allowWarning;

    if (mounted) {
      setState(() {
        canEditDelete = allowEditDelete;
        canSendWarning = allowWarning;
        canShowMenu = showMenu;
        permissionLoaded = true;
      });
    }
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTopMessage = false);
    });
  }

  @override
  void didUpdateWidget(EmployeeDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if the employee parameter changed
    if (oldWidget.employee.userId != widget.employee.userId) {
      _initializeData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for refresh signals and reload data
    final refreshNotifier = context.watch<DataRefreshNotifier>();

    // Reload if user refresh signal changed
    if (refreshNotifier.lastUserRefresh != null &&
        (_lastRefreshTime == null ||
            refreshNotifier.lastUserRefresh!.isAfter(_lastRefreshTime!))) {
      _lastRefreshTime = refreshNotifier.lastUserRefresh;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadEmployeeStatus();
      });
    }

    // Reload if goal refresh signal changed
    if (refreshNotifier.lastGoalRefresh != null &&
        (_lastGoalRefreshTime == null ||
            refreshNotifier.lastGoalRefresh!.isAfter(_lastGoalRefreshTime!))) {
      _lastGoalRefreshTime = refreshNotifier.lastGoalRefresh;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) loadEmployeeGoals();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !AppLayout.isMobile(context);

    return Scaffold(
      backgroundColor: isWeb ? WebTheme.canvasOf(context) : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: isWeb
            ? Text(
                employee.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: Theme.of(context).textTheme.labelLarge,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
              )
            : const Text("Employee Details"),
        actions: isWeb
            ? [_userMenu(iconColor: Colors.white)]
            : [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                searchQuery = "";
              });
            },
          ),

          IconButton(
            icon: Icon(showFilter ? Icons.close : Icons.filter_list),
            onPressed: () {
              setState(() => showFilter = !showFilter);
            },
          ),

          _userMenu(),
        ],
      ),
      body: isLoading ? const Center(child: RotatingFlower()) : _buildBody(),
    );
  }

  Widget _userMenu({Color? iconColor}) {
    return PopupMenuButton<String>(
            enabled: canShowMenu,
            icon: Icon(
              Icons.more_vert,
              color: iconColor ?? (canShowMenu ? Colors.white : Colors.grey),
            ),
            onSelected: (value) async {
              if (value == 'edit' && canEditDelete) {
                final result = await openFormPage(
                  context,
                  EditUser(user: widget.employee),
                  maxWidth: 560,
                );

                if (result != null) {
                  setState(() {
                    employee = UserModel(
                      userId: employee.userId,
                      name: result["name"],
                      email: result["email"],
                      department: result["department"],
                      status: employee.status,
                      createdBy: employee.createdBy,
                      wasEdited: employee.wasEdited,
                      role: result["role"] ?? employee.role,
                    );
                  });
                }
              }

              if (value == 'delete' && canEditDelete) {
                final confirm = await showConfirmDialog(
                  context,
                  "Delete",
                  "User",
                );

                if (confirm == true) {
                  try {
                    final success = await SuperAdminService.deleteUser(
                      widget.employee.userId,
                    );

                    if (success) {
                      showTopMessage(
                        "User deleted successfully",
                        isError: false,
                      );

                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) Navigator.pop(context, true);
                      });
                    } else {
                      showTopMessage("Failed to delete user", isError: true);
                    }
                  } catch (e) {
                    showTopMessage("Something went wrong", isError: true);
                  }
                }
              }

              if (value == 'send warning' && canSendWarning) {
                final result = await openFormPage(
                  context,
                  SendWarningPage(
                    receiverId: widget.employee.userId,
                    receivername: employee.name,
                  ),
                  maxWidth: 560,
                );

                if (result == true) setState(() {});
              }
            },
            itemBuilder: (_) => [
              if (canEditDelete)
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    "Edit",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),

              if (canEditDelete)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    "Delete",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),

              if (canSendWarning)
                PopupMenuItem(
                  value: 'send warning',
                  child: Text(
                    "Send Warning",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
            ],
    );
  }

  Widget _webDetailsHeader() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: _inlineFilter(
                label: 'Status',
                value: taskFilter.status,
                items: droptaskutils.getAllStatuses(),
                onChanged: (value) => setState(() => taskFilter.status = value),
                chip: (item) => _filterChip(
                  droptaskutils.getStatusDisplayName(item),
                  TaskUtils.getStatusColor(TaskUtils.parseStatus(item)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _inlineFilter(
                label: 'Priority',
                value: taskFilter.priority,
                items: droptaskutils.getAllPriorities(),
                onChanged: (value) =>
                    setState(() => taskFilter.priority = value),
                chip: (item) => _filterChip(
                  droptaskutils.getPriorityDisplayName(item),
                  TaskUtils.getPriorityColor(item),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _inlineFilter(
                label: 'Dept',
                value: taskFilter.department,
                items: departmentsList
                    .map((name) => name.trim())
                    .where((name) => name.isNotEmpty)
                    .toSet()
                    .toList(),
                onChanged: (value) =>
                    setState(() => taskFilter.department = value),
                chip: (item) => _filterChip(item, WebTheme.brandOf(context)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: WebTheme.mutedOf(context),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: WebTheme.mutedOf(context),
                  ),
                  filled: true,
                  fillColor: WebTheme.surfaceOf(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: BorderSide(color: WebTheme.brandOf(context)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _inlineFilter({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Widget Function(String item) chip,
  }) {
    final selected = items.contains(value) ? value : null;
    final labelStyle = TextStyle(
      color: WebTheme.brandOf(context),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    final choices = <String?>[null, ...items];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            isExpanded: true,
            value: selected,
            dropdownColor: WebTheme.surfaceOf(context),
            iconEnabledColor: WebTheme.brandOf(context),
            hint: Text(label, style: labelStyle),
            selectedItemBuilder: (context) => [
              for (final item in choices)
                item == null
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(label, style: labelStyle),
                      )
                    : chip(item),
            ],
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(label, style: labelStyle),
              ),
              for (final item in items)
                DropdownMenuItem<String?>(
                  value: item,
                  child: chip(item),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final isWeb = !AppLayout.isMobile(context);
    final filteredGoals = applyGoalSearch(staffGoals);
    final filteredTasks = applyTaskSearch(standaloneTasks);

    final nestedTasks = staffGoals.expand((g) => _tasksOf(g)).toList();
    final allTasksCount = nestedTasks.length + standaloneTasks.length;

    return Padding(
      padding: EdgeInsets.all(isWeb ? 12 : 15),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWeb) ...[
                  _webDetailsHeader(),
                  const SizedBox(height: 16),
                ],
                _employeeCard(allTasksCount),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Text(
                      "Goals : ${staffGoals.length}",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: isWeb ? 16 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        final result = await openFormPage(
                          context,
                          Createtask(
                            assignedToIds: [widget.employee.userId],
                          ),
                          maxWidth: 880,
                        );
                        if (result == true) {
                          context.read<DataRefreshNotifier>().refreshGoals();
                          loadEmployeeGoals();
                        }
                      },
                      child: Chip(
                        backgroundColor: Theme.of(context).primaryColor,
                        label: Text(
                          "Add Goal/Task",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (filteredGoals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "No goals found",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )
                else
                  AdaptiveGoalCards(
                    shrinkWrap: true,
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      final goalCode =
                          (goal["goalCode"] ?? goal["GoalCode"] ?? "")
                              .toString()
                              .trim();
                      return GoalCard(
                        key: ValueKey(goalCode),
                        goal: goal,
                        onDelete: (msg, isError) {
                          if (!isError) {
                            setState(() {
                              if (goalCode.isNotEmpty) {
                                _removedGoalCodes.add(goalCode.trim());
                              }
                              staffGoals = staffGoals
                                  .where(
                                    (item) =>
                                        (item["goalCode"] ??
                                                item["GoalCode"] ??
                                                "")
                                            .toString()
                                            .trim() !=
                                        goalCode.trim(),
                                  )
                                  .toList();
                            });
                          }
                          showTopMessage(msg, isError: isError);
                        },
                        onRefresh: () => loadEmployeeGoals(),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                Text(
                  "Tasks : ${standaloneTasks.length}",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                if (filteredTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "No tasks without a goal",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )
                else
                  Alltasklist(
                    tasks: filteredTasks,
                    searchQuery: '',
                    onTaskDataUpdated: () => loadEmployeeGoals(),
                  ),
              ],
            ),
          ),

          // 🔽 FILTER UI
          if (showFilter && !isWeb)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 8,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: TaskFilterDropdown(
                  filter: taskFilter,
                  departments: departmentsList,
                  onClear: () {
                    setState(() {
                      taskFilter.clear();
                      showFilter = false;
                    });
                  },
                  onApply: () {
                    setState(() {
                      showFilter = false;
                    });
                  },
                ),
              ),
            ),

          // 🔽 TOP MESSAGE
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 0 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
                backgroundColor: Theme.of(context).colorScheme.primary,
                iconColor: Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _employeeCard(int taskCount) {
    final isWeb = !AppLayout.isMobile(context);
    final initial = employee.name.isNotEmpty
        ? employee.name[0].toUpperCase()
        : '?';

    if (isWeb) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WebTheme.lineOf(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: WebTheme.brand,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: WebTheme.inkOf(context),
                          ),
                        ),
                      ),
                      if (employee.wasEdited == true)
                        IconButton(
                          tooltip: 'Audit log',
                          onPressed: () async {
                            final token = await AuthService.getToken();
                            final role = JwtHelper.getRole(token!);
                            await SuperAdminService.ensureRolesLoaded();
                            if (!context.mounted) return;
                            if (AppRoles.isDirector(role)) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AuditLogPage(
                                    highlightid: employee.userId.toString(),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: WebTheme.mutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _infoChip(Icons.business, employee.department),
                      _infoChip(Icons.badge_outlined, getRoleName(employee.role)),
                      _infoChip(Icons.assignment_outlined, '$taskCount tasks'),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isActive ? "Active" : "Deactive",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 6),
                          isUpdating
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: RotatingFlower(size: 10),
                                )
                              : Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: isActive,
                                    activeThumbColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    onChanged: !canEditDelete
                                        ? null
                                        : _onStatusChanged,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.person),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                employee.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (employee.wasEdited == true)
              IconButton(
                onPressed: () async {
                  final token = await AuthService.getToken();
                  final role = JwtHelper.getRole(token!);
                  await SuperAdminService.ensureRolesLoaded();
                  if (!context.mounted) return;
                  if (AppRoles.isDirector(role)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuditLogPage(
                          highlightid: employee.userId.toString(),
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.edit_outlined),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _row(Icons.email, employee.email),
        const SizedBox(height: 10),
        _row(Icons.business, employee.department),
        const SizedBox(height: 10),
        _row(Icons.work, getRoleName(employee.role)),
        Row(
          children: [
            Text(
              isActive ? "Active" : "Deactive",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            isUpdating
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: RotatingFlower(size: 10),
                  )
                : Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      activeThumbColor: Theme.of(
                        context,
                      ).colorScheme.secondary,
                      onChanged: !canEditDelete ? null : _onStatusChanged,
                    ),
                  ),
          ],
        ),
        Divider(height: 10, color: Theme.of(context).colorScheme.secondary),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WebTheme.brandSoftOf(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WebTheme.brandOf(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WebTheme.brandOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStatusChanged(bool value) async {
    setState(() {
      isActive = value;
      isUpdating = true;
    });

    try {
      await SuperAdminService.updateusersstatus(
        employee.userId,
        value ? "Active" : "Deactive",
      );

      if (mounted) {
        context.read<DataRefreshNotifier>().refreshUsers();
        showTopMessage("Status updated successfully", isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isActive = !value;
        });
      }
      if (!mounted) return;
      showAppMessage(context, "Failed to update status: $e");
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Widget _row(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.headlineLarge),
        ),
      ],
    );
  }
}
