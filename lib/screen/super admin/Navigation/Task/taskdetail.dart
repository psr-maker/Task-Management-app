import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/userstask.dart';
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

      final assignedTo = fetchedTask.assignedTo;

      members = assignedTo
          .map((u) => u['name']?.toString() ?? "")
          .where((e) => e.isNotEmpty)
          .toList();

      memberRoles = assignedTo
          .map((u) => u['role']?.toString() ?? "")
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      departments = assignedTo
          .map((u) => u['department']?.toString() ?? "")
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
    final isCompleted = (task!.status).toLowerCase().trim() == "completed";

    final canEditMenu = _canEditTask && !isCompleted;
    final statusEnum = TaskUtils.parseStatus(task!.status);

    final isWeb = !AppLayout.isMobile(context);
    return Scaffold(
      backgroundColor: isWeb ? WebTheme.canvasOf(context) : null,
      appBar: AppBar(
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
                          await Future.delayed(const Duration(seconds: 1));
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
          constraints: BoxConstraints(maxWidth: isWeb ? 980 : double.infinity),
          child: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 28 : 16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWeb)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: WebTheme.surfaceOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WebTheme.lineOf(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task!.task,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: WebTheme.inkOf(context),
                                ),
                              ),
                            ),
                            if (task!.wasEdited == true)
                              _editedBadge(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            StatusChip(
                              icon: Icons.animation_outlined,
                              text: task!.priority,
                              color: TaskUtils.getPriorityColor(task!.priority),
                            ),
                            StatusChip(
                              icon: Icons.circle,
                              text: TaskUtils.getStatusText(statusEnum),
                              color: TaskUtils.getStatusColor(statusEnum),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else ...[
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
                      color: TaskUtils.getPriorityColor(task!.priority),
                    ),
                    const SizedBox(width: 10),
                    StatusChip(
                      icon: Icons.circle,
                      text: TaskUtils.getStatusText(statusEnum),
                      color: TaskUtils.getStatusColor(statusEnum),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ],

                _infoCard(),
                const SizedBox(height: 15),

                Text(
                  "Assignment Summary",
                  style: Theme.of(context).textTheme.headlineLarge,
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
                    children: departments
                        .map((dept) => Chip(label: Text(dept)))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 15),

                if (!_showShareList) ...[
                  Text(
                    "Assigned Members",
                    style: Theme.of(context).textTheme.headlineLarge,
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
                          color: Colors.green.withOpacity(0.08),
                          border: Border.all(color: Colors.green, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
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
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  task!.description,
                  style: Theme.of(context).textTheme.labelMedium,
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
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "Edited",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    final theme = Theme.of(context);
    final isWeb = !AppLayout.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: isWeb
            ? WebTheme.surfaceOf(context)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWeb ? WebTheme.lineOf(context) : theme.colorScheme.primary,
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

  bool get _seesEveryShare {
    final role = (_role ?? "").toLowerCase().trim();
    return role == "1" ||
        role.contains("director") ||
        role == "3" ||
        role.contains("manager");
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
        Text(
          "Quantity shares",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...shares.map(_shareCard),
      ],
    );
  }

  Widget _shareCard(Map<String, dynamic> share) {
    final target = readGoalInt(share, const ["quantity", "Quantity"]) ?? 0;
    final done = readGoalInt(share, const [
          "completedQuantity",
          "CompletedQuantity",
        ]) ??
        0;
    final status = (share["status"] ?? "").toString();
    final members = share["members"];
    final people = members is List ? members.whereType<Map>().toList() : [];
    final statusEnum = TaskUtils.parseStatus(status);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
                color: TaskUtils.getStatusColor(statusEnum),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Achieved ${formatGoalQty(done)} of ${formatGoalQty(target)}",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          if (people.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...people.map((person) {
              final name = (person["name"] ?? person["Name"] ?? "").toString();
              final userStatus =
                  (person["userStatus"] ?? person["UserStatus"] ?? "")
                      .toString();
              final personStatus = TaskUtils.parseStatus(userStatus);
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
                    Text(
                      TaskUtils.getStatusText(personStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: TaskUtils.getStatusColor(personStatus),
                        fontWeight: FontWeight.w600,
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
    final percentColor = percent >= 100
        ? const Color(0xFF1B7A3A)
        : percent > 0
            ? const Color(0xFFB45309)
            : Colors.grey.shade700;
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
            backgroundColor: Colors.grey.shade300,
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

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget buildReviewDetails() {
    if (isReviewLoading) {
      return const Center(child: RotatingFlower());
    }

    if (reviewData.isEmpty) {
      return const Text(
        "No reviews available",
        style: TextStyle(color: Colors.grey),
      );
    }

    final systemPoints = reviewData.first['systemPoints'] ?? 0;

    final reviewedBy = reviewData.first['reviewedBy']?.toString() ?? '';

    final reviewedAt = reviewData.first['reviewedAt']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Review Details",
          style: Theme.of(context).textTheme.headlineLarge,
        ),

        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "System Points",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              Text(
                "$systemPoints / 100",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),

        _reviewRow("Reviewed By", reviewedBy.isEmpty ? "—" : reviewedBy),
        _reviewRow("Date", reviewedAt.isEmpty ? "—" : _formatDate(reviewedAt)),

        const SizedBox(height: 20),
        Text(
          "Member Reviews",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ...reviewData.map((review) {
          final staffName = review['staffName']?.toString() ?? 'Unknown Staff';

          final finalPoints = review['finalPoints'] ?? 0;

          final delayJustified = review['isDelayJustified'] == true;

          final reason = review['delayReason']?.toString() ?? '';

          final comment = review['comment']?.toString() ?? '';

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        staffName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      "$finalPoints / 100",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _reviewRow("Delay Justified", delayJustified ? "Yes" : "No"),
                if (delayJustified)
                  _reviewRow("Justify Reason", reason.isEmpty ? "—" : reason),
                if (delayJustified)
                  _reviewRow("Comment", comment.isEmpty ? "—" : comment),
              ],
            ),
          );
        }),
      ],
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
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

}
