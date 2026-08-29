import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/edit_task.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class TaskDetails extends StatefulWidget {
  final String taskCode;

  const TaskDetails({super.key, required this.taskCode});

  @override
  State<TaskDetails> createState() => _TaskDetailsState();
}

class _TaskDetailsState extends State<TaskDetails> {
  TaskModel? task;
  bool isLoading = true;
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
        isLoading = false;
      });
      if (fetchedTask.status.toLowerCase() == "completed") {
        await fetchReview();
      }

      await _checkTaskPermission(fetchedTask);
    } catch (e) {
      isLoading = false;
      debugPrint("Error: $e");
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
    final loginUserRoleRaw = JwtHelper.getRole(token);
    if (loginUserIdRaw == null || loginUserRoleRaw == null) return;

    final loginUserId = loginUserIdRaw.toString().trim();
    final loginUserRole = loginUserRoleRaw.toLowerCase().trim();

    String createdById = '';
    if (task.assignedBy!.contains('-')) {
      createdById = task.assignedBy!.split('-')[0].trim();
    } else {
      createdById = task.assignedBy!.trim();
    }

    final isDirector = loginUserRole.contains("1");
    final isManager = loginUserRole.contains("2");

    // ✅ Directors can always edit
    if (isDirector) {
      if (mounted) {
        setState(() {
          _canEditTask = true;
          permissionLoaded = true;
        });
      }
      return;
    }

    // ✅ Check if login user is the creator
    if (loginUserId == createdById) {
      if (mounted) {
        setState(() {
          _canEditTask = true;
          permissionLoaded = true;
        });
      }
      return;
    }

    // ✅ Managers can always edit
    if (isManager) {
      if (mounted) {
        setState(() {
          _canEditTask = true;
          permissionLoaded = true;
        });
      }
      return;
    }

    // ✅ Check if login staff is assigned to this task
    final assignedTo = task.assignedTo;
    bool isStaffAssigned = false;
    for (var staff in assignedTo) {
      final staffUserId = (staff['userId'] as dynamic)?.toString().trim();
      if (staffUserId == loginUserId) {
        isStaffAssigned = true;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _canEditTask = isStaffAssigned;
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
      return const Scaffold(body: Center(child: Text("Task not found")));
    }
    final isCompleted = (task!.status).toLowerCase().trim() == "completed";

    final canEditMenu = _canEditTask && !isCompleted;
    final statusEnum = TaskUtils.parseStatus(task!.status);

    return Scaffold(
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTask(task: task!),
                        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                    if (task!.wasEdited == true)
                      GestureDetector(
                        onTap: () async {
                          final token = await AuthService.getToken();
                          final role = JwtHelper.getRole(
                            token!,
                          )?.toLowerCase().trim();
                          if (role == "1") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AuditLogPage(highlightid: task!.taskCode),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
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
                      ),
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
    );
  }

  Widget _infoCard() {
    final theme = Theme.of(context);
    final isQty = task!.performanceType.toLowerCase().trim() == "qty";
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, // <-- uses theme card color
        borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
            ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
            : BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary, width: 1.2),
      ),
      child: Column(
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
          // Performance Type
          const SizedBox(height: 14),

          _infoRow(
            Icons.track_changes,
            "Performance Type",
            task!.performanceType,
          ),

          // Qty task only
          if (isQty && task!.quantity != null) ...[
            const SizedBox(height: 14),

            _infoRow(
              Icons.production_quantity_limits,
              "Quantity",
              task!.quantity.toString(),
            ),
          ],

          // Qty task only
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

    final review = reviewData.first;

    final systemPoints = review['systemPoints'] ?? 0;
    final delayJustified = review['isDelayJustified'] == true;
    final reason = review['delayReason'] ?? '';
    final comment = review['comment'] ?? '';
    final reviewedBy = review['reviewedBy'] ?? '';
    final reviewedAt = review['reviewedAt']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Review Details",
          style: Theme.of(context).textTheme.headlineLarge,
        ),

        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "System Point",
               style: const TextStyle(
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

        _reviewRow("Delay Justified", delayJustified ? "Yes" : "No"),
        if (delayJustified) ...[
          _reviewRow(
            "Reason",
            reason.toString().isEmpty ? "—" : reason.toString(),
          ),

          _reviewRow(
            "Comment",
            comment.toString().isEmpty ? "—" : comment.toString(),
          ),
        ],
        _reviewRow(
          "Reviewed By",
          reviewedBy.toString().isEmpty ? "—" : reviewedBy.toString(),
        ),

        _reviewRow("Date", _formatDate(reviewedAt)),

        const SizedBox(height: 20),

        Text(
          "Final Points",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ...reviewData.map((review) {
          final staffName = review['staffName'] ?? 'Unknown Staff';

          final finalPoints = review['finalPoints'] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    staffName.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),

                Text(
                  "$finalPoints ",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
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
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
