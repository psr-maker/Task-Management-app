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
  Map<String, dynamic>? reviewData;
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
      setState(() => isReviewLoading = true);

      final review = await AdminService.getReview(widget.taskCode);

      if (review != null) {
        setState(() {
          reviewData = review;
        });
      }
    } catch (e) {
      debugPrint("Review error: $e");
    } finally {
      if (mounted) {
        setState(() => isReviewLoading = false);
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

    final isSuperAdmin = loginUserRole == "director";

    final canEdit = isSuperAdmin || (loginUserId == createdById);

    debugPrint("=== PERMISSION CHECK ===");
    debugPrint("LOGIN ROLE: $loginUserRole");
    debugPrint("LOGIN ID: $loginUserId");
    debugPrint("TARGET CREATED BY: $createdById");
    debugPrint("CAN EDIT: $canEdit");
    debugPrint("========================");

    if (mounted) {
      setState(() {
        _canEditTask = canEdit;
        permissionLoaded = true;
      });
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
            enabled: _canEditTask,
            icon: Icon(
              Icons.more_vert,
              color: _canEditTask ? Colors.white : Colors.grey,
            ),
            onSelected: _canEditTask
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
                          if (role == "Director") {
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
                const SizedBox(height: 10),

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
                if (memberRoles.isNotEmpty) ...[
                  const Text(
                    "Roles",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: memberRoles
                        .map((role) => Chip(label: Text(role)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                if (departments.isNotEmpty) ...[
                  const Text(
                    "Departments",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 25),

                if (task!.status.toLowerCase() == "completed") ...[
                   Text(
                    "Review Details",
                   style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),

                  if (isReviewLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (reviewData != null)
                    _buildReviewCard()
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "No review submitted yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
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
        Icon(icon, ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Text(value,   style: Theme.of(context).textTheme.headlineSmall,),
      ],
    );
  }

  Widget _buildReviewCard() {
    final points = reviewData!['points'];
    final comment = reviewData!['comment'];
    final reviewedByRaw = reviewData!['reviewedBy'] ?? "";
    final reviewedAtRaw = reviewData!['reviewedAt'];

    String reviewerName = reviewedByRaw.toString().contains('-')
        ? reviewedByRaw.split('-')[1]
        : reviewedByRaw;

    String formattedDate = "";
    if (reviewedAtRaw != null) {
      final date = DateTime.parse(reviewedAtRaw);
      formattedDate =
          "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xfff2b705)),
            const SizedBox(width: 6),
            Text(
              "$points Points",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xfff2b705),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text("comments", style: Theme.of(context).textTheme.titleLarge,),
         const SizedBox(height: 12),
        Text(comment, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 5),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(
          "Reviewed by - $reviewerName",
        style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 3),
        Text(
          formattedDate,
         style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
