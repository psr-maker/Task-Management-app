import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/time_utils.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/role_hierarchy.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:staff_work_track/widgets/staff_picker.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';

class EditGoalPage extends StatefulWidget {
  final Map goal;

  const EditGoalPage({super.key, required this.goal});

  @override
  State<EditGoalPage> createState() => _EditGoalPageState();
}

class _EditGoalPageState extends State<EditGoalPage> {
  final TextEditingController goalTitleController = TextEditingController();
  final TextEditingController goalStartController = TextEditingController();
  final TextEditingController goalDueController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  String? selectedPriority;
  bool isLoading = false;
  bool _loadingUsers = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  List<UserModel> _users = [];
  final Map<int, String> _namesById = {};
  late final Set<int> _originalAssignedIds;
  late final Set<int> _assignedIds;
  late final bool _canEditStaff;

  static const _priorities = ["Normal", "Medium", "High"];

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    goalTitleController.text = (goal["title"] ?? "").toString();
    goalStartController.text = AppHelpers.formatDate(
      goal["startDate"]?.toString(),
    );
    goalDueController.text = AppHelpers.formatDate(goal["dueDate"]?.toString());
    selectedPriority = _knownPriority(goal["priority"]);

    final quantity = _readInt(goal["targetQuantity"] ?? goal["TargetQuantity"]);
    if (quantity != null && quantity > 0) {
      quantityController.text = quantity.toString();
    }

    final goalType = (goal["goalType"] ?? goal["GoalType"] ?? "")
        .toString()
        .toLowerCase();
    _canEditStaff = goalType != "yearly";
    _originalAssignedIds = _assignedIdsFrom(goal);
    _assignedIds = {..._originalAssignedIds};
    if (_canEditStaff) _loadUsers();
  }

  @override
  void dispose() {
    goalTitleController.dispose();
    goalStartController.dispose();
    goalDueController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  int? _readInt(dynamic raw) {
    if (raw is num) return raw.round();
    return int.tryParse("${raw ?? ""}".trim());
  }

  Set<int> _assignedIdsFrom(Map goal) {
    final raw = goal["assignedUsers"] ??
        goal["AssignedUsers"] ??
        goal["assignments"] ??
        goal["goalAssignments"] ??
        goal["assignedTo"];
    final ids = <int>{};
    if (raw is! List) return ids;
    for (final user in raw) {
      if (user is Map) {
        final id = _readInt(
          user["userId"] ?? user["UserId"] ?? user["id"] ?? user["Id"],
        );
        if (id != null) ids.add(id);
      } else {
        final id = _readInt(user);
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  String? _knownPriority(dynamic raw) {
    final text = (raw ?? "").toString().trim();
    if (text.isEmpty) return null;
    for (final item in _priorities) {
      if (item.toLowerCase() == text.toLowerCase()) return item;
    }
    return null;
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final token = await AuthService.getToken();
      var department =
          (token != null ? JwtHelper.getDepartment(token) : null)?.trim();
      final loginUserId = int.tryParse(
        (token != null ? JwtHelper.getuid(token) : null)?.toString() ?? "",
      );
      if ((department == null || department.isEmpty) && loginUserId != null) {
        try {
          final details = await SuperAdminService.getAdminDetails(loginUserId);
          if (details.department.trim().isNotEmpty) {
            department = details.department.trim();
          }
        } catch (_) {}
      }

      final ownDepartment = department?.trim() ?? "";
      var users = <UserModel>[];
      final names = <int, String>{};
      try {
        final allUsers = await SuperAdminService.getAllUsers();
        for (final user in allUsers) {
          final name = user.displayName;
          if (user.userId > 0 && name.isNotEmpty) names[user.userId] = name;
        }
        if (ownDepartment.isEmpty) users = allUsers;
      } catch (_) {}

      if (ownDepartment.isNotEmpty) {
        try {
          users = await AdminService.getEmployeesByDepartments([ownDepartment]);
        } catch (_) {}
        if (users.isEmpty) {
          final ownKey = ownDepartment.toLowerCase();
          try {
            final allUsers = await SuperAdminService.getAllUsers();
            users = allUsers
                .where(
                  (user) => user.department.trim().toLowerCase() == ownKey,
                )
                .toList();
          } catch (_) {}
        }
      }

      users = users.map((user) {
        final known = names[user.userId];
        if (user.displayName.isNotEmpty || known == null) return user;
        return UserModel(
          userId: user.userId,
          name: known,
          email: user.email,
          department: user.department,
          role: user.role,
          status: user.status,
          createdBy: user.createdBy,
          wasEdited: user.wasEdited,
        );
      }).toList();

      final active = users
          .where((user) => user.status.toLowerCase() != "inactive")
          .toList();
      final assignable = await keepAssignableUsers(active);
      if (!mounted) return;
      setState(() {
        _namesById
          ..clear()
          ..addAll(names);
        for (final user in assignable) {
          final name = user.displayName;
          if (user.userId > 0 && name.isNotEmpty) _namesById[user.userId] = name;
        }
        _users = assignable;
        _loadingUsers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUsers = false);
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

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: TimeUtils.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = TimeUtils.formatDate(picked);
      setState(() {});
    }
  }

  bool _sameIds(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  String _userName(int id) {
    for (final user in _users) {
      final name = user.displayName;
      if (user.userId == id && name.isNotEmpty) return name;
    }
    final known = _namesById[id]?.trim() ?? '';
    if (known.isNotEmpty && known != '$id') return known;
    final raw = widget.goal["assignedUsers"] ?? widget.goal["AssignedUsers"];
    if (raw is List) {
      for (final user in raw) {
        if (user is! Map) continue;
        final userId = _readInt(user["userId"] ?? user["UserId"] ?? user["id"]);
        if (userId == id) {
          final named = (user["name"] ??
                  user["Name"] ??
                  user["staffName"] ??
                  user["StaffName"] ??
                  user["userName"] ??
                  user["UserName"] ??
                  "")
              .toString()
              .trim();
          if (named.isNotEmpty && named != '$id') return named;
        }
      }
    }
    return "User $id";
  }

  Future<void> _pickStaff() async {
    final picker = StaffPicker(
      users: _users,
      selectedIds: _assignedIds,
      title: "Assign staff",
    );
    final result = AppLayout.isMobile(context)
        ? await showModalBottomSheet<Set<int>>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.78,
                child: picker,
              ),
            ),
          )
        : await showDialog<Set<int>>(
            context: context,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(width: 520, height: 620, child: picker),
            ),
          );
    if (result == null || !mounted) return;
    setState(() {
      _assignedIds
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> updateGoal() async {
    final title = goalTitleController.text.trim();
    if (title.isEmpty) {
      showTopMessage("Goal title cannot be empty");
      return;
    }
    final dueDate = TimeUtils.tryParse(goalDueController.text.trim());
    if (dueDate == null) {
      showTopMessage("Choose a valid due date");
      return;
    }

    final quantityText = quantityController.text.trim();
    int? targetQuantity;
    if (quantityText.isNotEmpty) {
      targetQuantity = int.tryParse(quantityText);
      if (targetQuantity == null || targetQuantity <= 0) {
        showTopMessage("Target quantity must be greater than 0");
        return;
      }
    }

    List<int>? assignedUserIds;
    if (_canEditStaff && !_sameIds(_assignedIds, _originalAssignedIds)) {
      if (_assignedIds.isEmpty) {
        showTopMessage("At least one staff member must be assigned");
        return;
      }
      assignedUserIds = _assignedIds.toList();
    }

    final goalCode = (widget.goal["goalCode"] ?? widget.goal["GoalCode"] ?? "")
        .toString()
        .trim();
    if (goalCode.isEmpty) {
      showTopMessage("Goal code is missing");
      return;
    }

    setState(() => isLoading = true);
    final error = await SuperAdminService.updateGoal(
      goalCode: goalCode,
      title: title,
      priority: selectedPriority,
      dueDate: dueDate,
      targetQuantity: targetQuantity,
      assignedUserIds: assignedUserIds,
    );
    if (!mounted) return;
    setState(() => isLoading = false);

    if (error != null) {
      showTopMessage(error);
      return;
    }

    showTopMessage("Goal updated successfully", isError: false);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pop(context, {
      "title": title,
      "dueDate": dueDate.toIso8601String(),
      "priority": selectedPriority,
      "targetQuantity": targetQuantity ??
          _readInt(
            widget.goal["targetQuantity"] ?? widget.goal["TargetQuantity"],
          ),
      if (assignedUserIds != null)
        "assignedUsers": assignedUserIds
            .map(
              (id) => {
                "userId": id,
                "name": _userName(id),
              },
            )
            .toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Goal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomFormWidgets.label(context, "Goal Title"),
                const SizedBox(height: 8),
                CustomFormWidgets.textField(
                  context,
                  goalTitleController,
                  hint: "Enter goal title",
                  maxLines: 1,
                ),
                const SizedBox(height: 20),
                CustomFormWidgets.label(context, "Start Date"),
                const SizedBox(height: 8),
                CustomFormWidgets.dateField(
                  controller: goalStartController,
                  onTap: null,
                  enabled: false,
                ),
                const SizedBox(height: 20),
                CustomFormWidgets.label(context, "Due Date"),
                const SizedBox(height: 8),
                CustomFormWidgets.dateField(
                  controller: goalDueController,
                  onTap: () => _pickDate(goalDueController),
                ),
                const SizedBox(height: 20),
                CustomFormWidgets.label(context, "Priority"),
                const SizedBox(height: 8),
                CustomFormWidgets.dropdown(
                  context: context,
                  value: selectedPriority,
                  items: _priorities,
                  onChanged: (v) => setState(() => selectedPriority = v),
                  hint: "Select Priority",
                ),
                const SizedBox(height: 20),
                CustomFormWidgets.label(context, "Target quantity"),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: InputDecoration(
                    hintText: "Optional. Leave blank if this goal has no quantity",
                    hintStyle: Theme.of(context).textTheme.headlineSmall,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 25, 77, 38),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 25, 77, 38),
                      ),
                    ),
                  ),
                ),
                if (_canEditStaff) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomFormWidgets.label(context, "Assigned staff"),
                      ),
                      TextButton.icon(
                        onPressed: _loadingUsers ? null : _pickStaff,
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text("Add or change"),
                      ),
                    ],
                  ),
                  Text(
                    "Tap × on a person to remove them. At least one person must stay assigned.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingUsers)
                    const LinearProgressIndicator(minHeight: 2)
                  else if (_assignedIds.isEmpty)
                    Text(
                      "No staff assigned",
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _assignedIds.map((id) {
                        return InputChip(
                          label: Text(_userName(id)),
                          onDeleted: () => setState(() => _assignedIds.remove(id)),
                        );
                      }).toList(),
                    ),
                ],
                const SizedBox(height: 30),
                Center(
                  child: AppButton(
                    text: "Update Goal",
                    isLoading: isLoading,
                    onPressed: isLoading ? null : updateGoal,
                    color: Theme.of(context).colorScheme.secondary,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            if (_showTopMessage && _topMessage != null)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Msgsnackbar(
                  context,
                  message: _topMessage!,
                  isError: _isErrorMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
