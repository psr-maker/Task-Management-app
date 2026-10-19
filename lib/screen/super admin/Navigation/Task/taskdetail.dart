import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/edit_task.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class TaskDetails extends StatefulWidget {
  final String taskCode;

  const TaskDetails({super.key, required this.taskCode});

  @override
  State<TaskDetails> createState() => _TaskDetailsState();
}

class _TaskDetailsState extends State<TaskDetails> {
  TaskModel? task;
  Map<String, dynamic> _rawTask = {};
  int? _userId;
  String? _role;
  bool isLoading = true;
  String? _loadError;
  bool _canEditTask = false;
  List<String> members = [];
  List<String> memberRoles = [];
  List<String> departments = [];
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  // Map<String, dynamic>? reviewData;
  List<Map<String, dynamic>> reviewData = [];

  bool isReviewLoading = false;

  bool permissionLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchTaskDetails();
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

  Future<void> fetchTaskDetails() async {
    try {
      final data = await SuperAdminService.getTaskByCode(widget.taskCode);
      final token = await AuthService.getToken();
      final userId = token == null
          ? null
          : int.tryParse(JwtHelper.getuid(token) ?? "");
      final role = token == null ? null : JwtHelper.getRole(token);
      final fetchedTask = TaskModel.fromJson(data);

      final assignedTo = _assigneesForViewer(
        fetchedTask.assignedTo,
        data,
        userId,
        role,
        createdBy: fetchedTask.assignedBy,
      );

      members = assignedTo.map((u) {
        if (u is! Map) {
          final text = u.toString().trim();
          if (text.contains('-')) {
            final name = text.split('-').skip(1).join('-').trim();
            if (name.isNotEmpty) return name;
          }
          return '';
        }
        return memberDisplayName(Map<String, dynamic>.from(u)) ??
            (u['name'] ?? u['Name'] ?? '').toString();
      }).where((e) => e.trim().isNotEmpty).toList();

      memberRoles = assignedTo
          .whereType<Map>()
          .map((u) => (u['role'] ?? u['Role'])?.toString() ?? "")
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      departments = assignedTo
          .whereType<Map>()
          .map((u) => (u['department'] ?? u['Department'])?.toString() ?? "")
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        task = fetchedTask;
        _rawTask = data;
        _userId = userId;
        _role = role;
        isLoading = false;
      });
      if (fetchedTask.status.toLowerCase() == "completed") {
        await fetchReview();
      }

      await _checkTaskPermission(fetchedTask);
    } catch (e) {
      debugPrint("Error: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _loadError = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  Future<void> fetchReview() async {
    try {
      setState(() {
        isReviewLoading = true;
      });

      final reviews = await AdminService.getReview(widget.taskCode);

      if (mounted) {
        setState(() {
          reviewData = reviews;
        });
      }
    } catch (e) {
      debugPrint("Review error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isReviewLoading = false;
        });
      }
    }
  }

  Future<void> _checkTaskPermission(TaskModel task) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final loginUserIdRaw = JwtHelper.getuid(token);
    if (loginUserIdRaw == null) return;

    final loginUserId = loginUserIdRaw.toString().trim();

    final assignedBy = task.assignedBy ?? '';
    final createdById = assignedBy.contains('-')
        ? assignedBy.split('-').first.trim()
        : assignedBy.trim();

    if (mounted) {
      setState(() {
        _canEditTask = createdById.isNotEmpty && loginUserId == createdById;
        permissionLoaded = true;
      });
    }
  }

  String _formatDate(String value) {
    if (value.isEmpty) return "—";

    try {
      final date = DateTime.parse(value);

      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: RotatingFlower()));
    }

    if (task == null) {
      return Scaffold(
        body: _loadError != null
            ? const AppLoadError()
            : const Center(child: Text("Task not found")),
      );
    }
    final shownStatus = task!.status;
    final isCompleted = shownStatus.toLowerCase().trim() == "completed";

    final canEditMenu = _canEditTask && !isCompleted;
    final statusEnum = TaskUtils.parseStatus(shownStatus);

    final isWeb = !AppLayout.isMobile(context);
    if (isWeb) return _webTaskPage(statusEnum, canEditMenu);
    return Scaffold(
      backgroundColor: isWeb ? WebTheme.canvasOf(context) : null,
      appBar: isWeb
          ? null
          : AppBar(
        title: const Text("Task Summary"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            enabled: canEditMenu,
            icon: Icon(
              Icons.more_vert,
              color: canEditMenu ? Colors.white : Colors.grey,
            ),
            onSelected: canEditMenu
                ? (value) async {
                    if (value == 'edit') {
                      openFormPage(
                        context,
                        EditTask(task: task!),
                      ).then((updated) {
                        if (updated == true) {
                          if (mounted) {
                            context.read<DataRefreshNotifier>().refreshTasks();
                            context.read<DataRefreshNotifier>().refreshGoals();
                          }
                          fetchTaskDetails();
                        }
                      });
                    } else if (value == 'delete') {
                      final confirmed = await showConfirmDialog(
                        context,
                        "Delete",
                        "task",
                      );

                      if (confirmed == true) {
                        final success = await SuperAdminService.deleteTask(
                          task!.taskCode,
                        );

                        if (success) {
                          showTopMessage(
                            "Task deleted successfully",
                            isError: false,
                          );
                          context.read<DataRefreshNotifier>().refreshTasks();
                          context.read<DataRefreshNotifier>().refreshGoals();
                          await Future.delayed(const Duration(seconds: 1));
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        } else {
                          showTopMessage("Failed to update task");
                        }
                      }
                    }
                  }
                : null,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  "Edit",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  "Delete",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 1100 : double.infinity),
          child: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 16 : 16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      task!.task,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    if (task!.wasEdited == true) _editedBadge(),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    StatusChip(
                      icon: Icons.animation_outlined,
                      text: task!.priority,
                      color: WebTheme.brand,
                    ),
                    const SizedBox(width: 10),
                    StatusChip(
                      icon: Icons.circle,
                      text: TaskUtils.getStatusText(statusEnum),
                      color: WebTheme.brand,
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _infoCard(),
                const SizedBox(height: 15),

                Text(
                  "Assignment Summary",
                  style: _heading(context),
                ),
                const SizedBox(height: 10),
                if (departments.isNotEmpty) ...[
                  Text(
                    "Departments",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: departments.map((dept) {
                      return Chip(
                        label: Text(
                          dept,
                          style: TextStyle(color: WebTheme.brand),
                        ),
                        backgroundColor: WebTheme.brand.withValues(alpha: 0.12),
                        side: BorderSide(color: WebTheme.brand),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 15),

                if (!_showShareList) ...[
                  Text(
                    "Assigned Members",
                    style: _heading(context),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WebTheme.brand.withValues(alpha: 0.12),
                          border: Border.all(color: WebTheme.brand, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            color: WebTheme.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 15),

                Text(
                  "Task Description",
                  style: _heading(context),
                ),
                const SizedBox(height: 10),
                Text(
                  task!.description,
                  style: isWeb
                      ? TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: WebTheme.inkOf(context),
                        )
                      : Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 15),

                if (task!.status.toLowerCase() == "completed") ...[
                  buildReviewDetails(),
                ],
              ],
            ),
            if (_topMessage != null)
              AnimatedPositioned(
                top: _showTopMessage ? 40 : -120,
                left: 16,
                right: 16,
                duration: const Duration(milliseconds: 300),
                child: Msgsnackbar(
                  context,
                  message: _topMessage!,
                  isError: _isErrorMessage,
                ),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _webTaskPage(TaskStatus statusEnum, bool canEditMenu) {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: AppLayout.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, size: 18, color: WebTheme.brand),
                    ),
                    Expanded(
                      child: Text(
                        task!.task,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: WebTheme.brand,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (task!.wasEdited == true) _editedBadge(),
                    const SizedBox(width: 6),
                    StatusChip(
                      icon: Icons.circle,
                      text: TaskUtils.getStatusText(statusEnum),
                      color: WebTheme.brand,
                    ),
                    const SizedBox(width: 6),
                    StatusChip(
                      icon: Icons.flag_outlined,
                      text: task!.priority,
                      color: WebTheme.brand,
                    ),
                    _taskMenu(canEditMenu),
                  ],
                ),
                const SizedBox(height: 8),
                _webDetails(),
                if (_hasQuantity) ...[
                  const SizedBox(height: 12),
                  _quantityStrip(),
                ],
                if (_showShareList) ...[
                  const SizedBox(height: 12),
                  _shareAssignments(),
                ],
                if (task!.status.toLowerCase() == 'completed') ...[
                  const SizedBox(height: 14),
                  buildReviewDetails(),
                ],
              ],
            ),
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 8 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _taskMenu(bool canEditMenu) {
    return PopupMenuButton<String>(
      enabled: canEditMenu,
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: canEditMenu ? WebTheme.brand : Colors.grey,
      ),
      onSelected: canEditMenu
          ? (value) async {
              if (value == 'edit') {
                openFormPage(context, EditTask(task: task!)).then((updated) {
                  if (updated == true) {
                    if (mounted) {
                      context.read<DataRefreshNotifier>().refreshTasks();
                      context.read<DataRefreshNotifier>().refreshGoals();
                    }
                    fetchTaskDetails();
                  }
                });
              } else if (value == 'delete') {
                final confirmed = await showConfirmDialog(context, 'Delete', 'task');
                if (confirmed == true) {
                  final success = await SuperAdminService.deleteTask(task!.taskCode);
                  if (success) {
                    showTopMessage('Task deleted successfully', isError: false);
                    context.read<DataRefreshNotifier>().refreshTasks();
                    context.read<DataRefreshNotifier>().refreshGoals();
                    await Future.delayed(const Duration(seconds: 1));
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  } else {
                    showTopMessage('Failed to update task');
                  }
                }
              }
            }
          : null,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Widget _webDetails() {
    final people = members.where((name) => name.trim().isNotEmpty).join(', ');
    final groups = departments.where((name) => name.trim().isNotEmpty).join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _webLine('Start', AppHelpers.formatDate(task!.createdAt)),
          _webLine('Due', AppHelpers.formatDate(task!.dueDate)),
          _webLine('Start time', task!.startTime ?? '—'),
          _webLine('Due time', task!.endTime ?? '—'),
          _webLine('Performance', task!.performanceType),
          _webLine('Assigned by', AppHelpers.extractName(task!.assignedBy)),
          _webLine('Department', AppHelpers.extractName(task!.assignerDepartment)),
          if (groups.isNotEmpty) _webLine('Departments', groups),
          if (people.isNotEmpty) _webLine('Members', people),
          if (task!.status.toLowerCase() == 'completed')
            _webLine('Completed', AppHelpers.formatDate(task!.completed_date)),
          const SizedBox(height: 8),
          Text(
            task!.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: WebTheme.inkOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webLine(String label, String value) {
    final text = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: WebTheme.inkOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editedBadge() {
    return GestureDetector(
      onTap: () async {
        final token = await AuthService.getToken();
        final role = JwtHelper.getRole(token!)?.toLowerCase().trim();
        if (role == "1") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuditLogPage(highlightid: task!.taskCode),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: WebTheme.brand.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Edited",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: WebTheme.brand,
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    final theme = Theme.of(context);
    final isWeb = !AppLayout.isMobile(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWeb
            ? WebTheme.surfaceOf(context)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.brand.withValues(alpha: isWeb ? 0.45 : 1),
          width: 1.2,
        ),
      ),
      child: isWeb
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoRow(
                        Icons.calendar_today,
                        "Start Date",
                        AppHelpers.formatDate(task!.createdAt),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _infoRow(
                        Icons.event,
                        "Due Date",
                        AppHelpers.formatDate(task!.dueDate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _infoRow(
                        Icons.access_time,
                        "Start Time",
                        task!.startTime ?? "—",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _infoRow(
                        Icons.access_time_filled,
                        "Due Time",
                        task!.endTime ?? "—",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _infoRow(
                        Icons.track_changes,
                        "Performance Type",
                        task!.performanceType,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _infoRow(
                        Icons.flag_outlined,
                        "Priority",
                        task!.priority,
                      ),
                    ),
                  ],
                ),
                if (_hasQuantity) ...[
                  const SizedBox(height: 14),
                  _quantityStrip(),
                ],
                if (_showShareList) ...[
                  const SizedBox(height: 14),
                  _shareAssignments(),
                ],
                if (task!.status.toLowerCase() == "completed") ...[
                  const SizedBox(height: 14),
                  _infoRow(
                    Icons.event,
                    "Completed Date",
                    AppHelpers.formatDate(task!.completed_date),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _infoRow(
                        Icons.person,
                        "Assigned By",
                        AppHelpers.extractName(task!.assignedBy),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _infoRow(
                        Icons.apartment,
                        "Department",
                        AppHelpers.extractName(task!.assignerDepartment),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
        children: [
          _infoRow(
            Icons.calendar_today,
            "Start Date",
            AppHelpers.formatDate(task!.createdAt),
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.event,
            "Due Date",
            AppHelpers.formatDate(task!.dueDate),
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.track_changes,
            "Performance Type",
            task!.performanceType,
          ),
          if (_hasQuantity) ...[
            const SizedBox(height: 14),
            _quantityStrip(),
          ],
          if (_showShareList) ...[
            const SizedBox(height: 14),
            _shareAssignments(),
          ],
          if (task!.startTime != null) ...[
            const SizedBox(height: 14),
            _infoRow(Icons.access_time, "Start Time", task!.startTime!),
          ],
          if (task!.endTime != null) ...[
            const SizedBox(height: 14),
            _infoRow(Icons.access_time_filled, "End Time", task!.endTime!),
          ],
          if (task!.status.toLowerCase() == "completed") ...[
            const SizedBox(height: 14),
            _infoRow(
              Icons.event,
              "Completed Date",
              AppHelpers.formatDate(task!.completed_date),
            ),
          ],
          const Divider(height: 24),
          _infoRow(
            Icons.person,
            "Assigned By",
            AppHelpers.extractName(task!.assignedBy),
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.apartment,
            "Department",
            AppHelpers.extractName(task!.assignerDepartment),
          ),
        ],
      ),
    );
  }
  
  bool get _hasQuantity => (task?.quantity ?? 0) > 0;

  bool _seesEveryShareFor(String? role) {
    if (AppRoles.isManager(role) || AppRoles.isAssistantManager(role)) {
      return true;
    }
    final value = (role ?? "").toLowerCase().trim();
    return value == "1" ||
        value.contains("director") ||
        value == "3" ||
        value.contains("manager");
  }

  bool _isCreator(String? assignedBy, int? userId) {
    if (userId == null || assignedBy == null || assignedBy.trim().isEmpty) {
      return false;
    }
    final createdById = assignedBy.contains('-')
        ? assignedBy.split('-').first.trim()
        : assignedBy.trim();
    return createdById.isNotEmpty && createdById == userId.toString();
  }

  bool get _createdThisTask => _isCreator(task?.assignedBy, _userId);

  bool get _seesEveryShare => _seesEveryShareFor(_role) || _createdThisTask;

  List _assigneesForViewer(
    List assignedTo,
    Map<String, dynamic> data,
    int? userId,
    String? role, {
    String? createdBy,
  }) {
    if (_seesEveryShareFor(role) ||
        _isCreator(createdBy, userId) ||
        userId == null) {
      return assignedTo;
    }
    final ids = quantityShareMemberIds(data, userId);
    if (ids == null || ids.isEmpty) return assignedTo;
    final mine = assignedTo.where((person) {
      final id = person is Map
          ? int.tryParse(memberUserId(Map<String, dynamic>.from(person)))
          : shareMemberId(person);
      return id != null && ids.contains(id);
    }).toList();
    return mine.isEmpty ? assignedTo : mine;
  }

  List<Map<String, dynamic>> get _quantitySplits {
    final raw = _rawTask["quantitySplits"] ?? _rawTask["QuantitySplits"];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((share) => Map<String, dynamic>.from(share))
        .toList();
  }

  bool get _showShareList => _seesEveryShare && _quantitySplits.isNotEmpty;

  List<Map<String, dynamic>> get _visibleSplits {
    final shares = _quantitySplits;
    if (shares.isEmpty || _seesEveryShare) return shares;
    final userId = _userId;
    if (userId == null) return shares;
    final mine = shares.where((share) {
      final members = share["members"] ?? share["memberIds"];
      if (members is! List) return false;
      return members.any((member) {
        if (member is Map) {
          return int.tryParse("${member["userId"] ?? member["UserId"]}") ==
              userId;
        }
        return int.tryParse("$member") == userId;
      });
    }).toList();
    return mine;
  }

  Widget _shareAssignments() {
    final shares = _visibleSplits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quantity shares",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...shares.map(_shareCard),
      ],
    );
  }

  String _memberStatus(Map person) {
    final direct = (person["userStatus"] ?? person["UserStatus"] ?? "")
        .toString()
        .trim();
    if (direct.isNotEmpty) return direct;
    final id = shareMemberId(person);
    final assigned = _rawTask["assignedTo"] ?? _rawTask["AssignedTo"];
    if (id == null || assigned is! List) return "";
    for (final item in assigned) {
      if (item is! Map || shareMemberId(item) != id) continue;
      return (item["userStatus"] ?? item["UserStatus"] ?? "").toString();
    }
    return "";
  }

  TaskStatus _shareDisplayStatus(Map share, List<Map> people) {
    final shareStatus = TaskUtils.parseStatus(
      (share["status"] ?? share["Status"] ?? "").toString(),
    );
    if (shareStatus == TaskStatus.completed) return TaskStatus.completed;
    if (TaskUtils.parseStatus(task?.status ?? "") == TaskStatus.completed) {
      return TaskStatus.completed;
    }
    if (people.isNotEmpty &&
        people.every(
          (person) =>
              TaskUtils.parseStatus(_memberStatus(person)) ==
              TaskStatus.completed,
        )) {
      return TaskStatus.completed;
    }
    return shareStatus;
  }

  Widget _shareCard(Map<String, dynamic> share) {
    final target = readGoalInt(share, const ["quantity", "Quantity"]) ?? 0;
    final done = readGoalInt(share, const [
          "completedQuantity",
          "CompletedQuantity",
        ]) ??
        0;
    final members = share["members"];
    final people = members is List
        ? members.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];
    final statusEnum = _shareDisplayStatus(share, people);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebTheme.brand.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Share ${formatGoalQty(target)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusChip(
                icon: Icons.circle,
                text: TaskUtils.getStatusText(statusEnum),
                color: WebTheme.brand,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Achieved ${formatGoalQty(done)} of ${formatGoalQty(target)}",
            style: TextStyle(fontSize: 13, color: WebTheme.brand),
          ),
          if (people.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...people.map((person) {
              final name = (person["name"] ?? person["Name"] ?? "").toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name.isEmpty ? "Member" : name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _quantityStrip() {
    final userId = _userId;
    final useShare = !_seesEveryShare && userId != null;
    final shareTarget = useShare ? memberShareQuantity(_rawTask, userId) : null;
    final shareDone = useShare ? memberShareCompleted(_rawTask, userId) : null;
    final target = shareTarget ?? task!.quantity ?? 0;
    final done = shareDone ?? task!.completedQuantity ?? 0;
    final pending = shareTarget != null
        ? (target - done < 0 ? 0 : target - done)
        : task!.pendingQuantity ?? (target - done < 0 ? 0 : target - done);
    final percent = quantityPercent(done, target);
    final percentColor = WebTheme.brand;
    final fraction = target <= 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Achieved ${formatGoalQty(done)} of ${formatGoalQty(target)}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _quantityFigure("Target", formatGoalQty(target)),
            _quantityFigure("Achieved", formatGoalQty(done)),
            _quantityFigure("Pending", formatGoalQty(pending)),
            _quantityFigure(
              "Percent",
              formatQuantityPercent(percent),
              percentColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: fraction,
            backgroundColor: WebTheme.brand.withValues(alpha: 0.15),
            color: percentColor,
          ),
        ),
      ],
    );
  }

  Widget _quantityFigure(String label, String value, [Color? color]) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _heading(BuildContext context) {
    if (!AppLayout.isMobile(context)) {
      return TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: WebTheme.brand,
      );
    }
    return Theme.of(context).textTheme.headlineLarge!.copyWith(
          color: WebTheme.brand,
        );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    final web = !AppLayout.isMobile(context);
    return Row(
      children: [
        Icon(icon, size: web ? 16 : 24, color: WebTheme.brand),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: web
                ? TextStyle(fontSize: 12, color: WebTheme.mutedOf(context))
                : Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Text(
          value,
          style: web
              ? TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: WebTheme.brand,
                )
              : Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: WebTheme.brand,
                  ),
        ),
      ],
    );
  }

  int? _asPoints(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return int.tryParse(text) ?? num.tryParse(text)?.round();
  }

  Widget buildReviewDetails() {
    if (!AppLayout.isMobile(context)) return _webReviews();
    if (isReviewLoading) {
      return const Center(child: RotatingFlower());
    }

    if (reviewData.isEmpty) {
      return Text(
        "Review not yet",
        style: TextStyle(
          color: WebTheme.mutedOf(context),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final reviewedBy = reviewData.first['reviewedBy']?.toString() ?? '';
    final reviewedAt = reviewData.first['reviewedAt']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Task points", style: _heading(context)),
        const SizedBox(height: 8),
        if (reviewedBy.trim().isNotEmpty)
          _reviewRow("Reviewed By", reviewedBy),
        if (reviewedAt.trim().isNotEmpty)
          _reviewRow("Date", _formatDate(reviewedAt)),
        const SizedBox(height: 10),
        ...reviewData.map((review) {
          final staffName = review['staffName']?.toString() ?? 'Unknown Staff';
          final system = _readPoints(review, const [
            'systemPoints',
            'SystemPoints',
          ]);
          final manager = _readPoints(review, const [
            'managerPoints',
            'ManagerPoints',
            'finalPoints',
            'FinalPoints',
          ]);
          final delayJustified = review['isDelayJustified'] == true;
          final reason = review['delayReason']?.toString() ?? '';
          final comment = review['comment']?.toString() ?? '';

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WebTheme.brand.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.brand,
                  ),
                ),
                const SizedBox(height: 8),
                _reviewRow("System points", _scoreOutOf(system)),
                _reviewRow("Manager points", _scoreOutOf(manager)),
                if (manager != null) ...[
                  _reviewRow("Delay justified", delayJustified ? "Yes" : "No"),
                  if (delayJustified)
                    _reviewRow(
                      "Justify reason",
                      reason.trim().isEmpty ? "—" : reason,
                    ),
                  if (comment.trim().isNotEmpty)
                    _reviewRow("Comment", comment),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  String _scoreOutOf(int? points) {
    if (points == null) return 'Not assigned';
    return '$points / 100';
  }

  int? _readPoints(Map<String, dynamic> review, List<String> keys) {
    for (final key in keys) {
      if (!review.containsKey(key)) continue;
      final points = _asPoints(review[key]);
      if (points != null) return points;
    }
    return null;
  }

  String _pointsText(int? points) {
    if (points == null) return 'Not assigned';
    return '$points points';
  }

  Widget _webReviews() {
    if (isReviewLoading) return const Center(child: RotatingFlower());
    if (reviewData.isEmpty) {
      return Text(
        'Review not yet',
        style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 13),
      );
    }
    final reviewedBy = reviewData.first['reviewedBy']?.toString() ?? '';
    final reviewedAt = reviewData.first['reviewedAt']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task points', style: _heading(context)),
        if (reviewedBy.trim().isNotEmpty || reviewedAt.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            [
              if (reviewedBy.trim().isNotEmpty) 'Reviewed by $reviewedBy',
              if (reviewedAt.trim().isNotEmpty) _formatDate(reviewedAt),
            ].join('  ·  '),
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: WebTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: Column(
            children: [
              _pointsHead(),
              for (var i = 0; i < reviewData.length; i++) ...[
                if (i > 0) Divider(height: 1, color: WebTheme.lineOf(context)),
                _pointsRow(reviewData[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _pointsHead() {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    return Container(
      width: double.infinity,
      color: WebTheme.brandSoftOf(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Staff', style: style)),
          Expanded(flex: 2, child: Text('System points', style: style)),
          Expanded(flex: 2, child: Text('Manager points', style: style)),
          Expanded(flex: 3, child: Text('Note', style: style)),
        ],
      ),
    );
  }

  Widget _pointsRow(Map<String, dynamic> review) {
    final name = review['staffName']?.toString().trim();
    final system = _readPoints(review, const ['systemPoints', 'SystemPoints']);
    final manager = _readPoints(review, const [
      'managerPoints',
      'ManagerPoints',
      'finalPoints',
      'FinalPoints',
    ]);
    final delay = review['isDelayJustified'] == true;
    final reason = (review['delayReason'] ?? '').toString().trim();
    final comment = (review['comment'] ?? '').toString().trim();
    final note = [
      if (delay) 'Delay justified',
      if (reason.isNotEmpty) reason,
      if (comment.isNotEmpty) comment,
    ].join(' · ');
    final style = TextStyle(fontSize: 13, color: WebTheme.inkOf(context));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name == null || name.isEmpty ? 'Staff' : name,
              style: style.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(flex: 2, child: Text(_pointsText(system), style: style)),
          Expanded(
            flex: 2,
            child: Text(
              _pointsText(manager),
              style: style.copyWith(
                color: manager == null ? WebTheme.mutedOf(context) : WebTheme.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              note.isEmpty ? '—' : note,
              style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 15, color: WebTheme.brand, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

}
