import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/report_export.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/time_utils.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class ReportsTable extends StatefulWidget {
  final int? userId;
  final String? department;

  const ReportsTable({super.key, this.userId, this.department});

  @override
  State<ReportsTable> createState() => _DeadlineReportsTabState();
}

class _DeadlineReportsTabState extends State<ReportsTable> {
  String selectedType = "Goals";
  String selectedView = "Work";
  String? selectedLeaveView = "Leave";
  bool _isLoading = false;
  List<dynamic> allTasks = [];
  List<dynamic> filteredTasks = [];

  List<dynamic> allGoals = [];
  List<dynamic> filteredGoals = [];
  List<dynamic> allLeaves = [];
  List<dynamic> allPermissions = [];
  List<dynamic> filteredLeaves = [];
  List<dynamic> filteredPermissions = [];
  List<Map<String, dynamic>> reportUsers = [];
  String? selectedStatus;
  String? selectedPriority;
  String? selectedOverdue;
  String? selectedLeaveStatus;
  String? selectedLeaveType;
  DateTime? selectedLeaveDate;

  DateTime? selectedPermissionDate;
  DateTime? startDate;
  DateTime? endDate;
  String workDateBy = "Due Date";

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final result = await ReportsService.getFullReport(
        userId: widget.userId,
        department: widget.department,
      );
      final tasks = List<dynamic>.from(result["tasks"] ?? []);
      final goals = List<dynamic>.from(result["goals"] ?? []);
      await _attachAssigneeNames(goals, tasks);

      if (!mounted) return;
      setState(() {
        reportUsers = (result["users"] as List? ?? [])
            .whereType<Map>()
            .map((user) => Map<String, dynamic>.from(user))
            .toList();
        allTasks = tasks;
        filteredTasks = List<dynamic>.from(allTasks);
        allGoals = goals;
        filteredGoals = List<dynamic>.from(allGoals);
        allLeaves = List<dynamic>.from(result["leaveList"] ?? []);
        filteredLeaves = List<dynamic>.from(allLeaves);
        allPermissions = List<dynamic>.from(result["permissionList"] ?? []);
        filteredPermissions = List<dynamic>.from(allPermissions);
        loadError = null;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadError = "Could not load the report";
        isLoading = false;
      });
    }
  }

  Future<void> _attachAssigneeNames(
    List<dynamic> goals,
    List<dynamic> tasks,
  ) async {
    try {
      final detailed = await SuperAdminService.getGoals();
      final goalsByCode = <String, Map>{};
      final tasksByCode = <String, Map>{};

      void indexGoal(Map goal) {
        final code = (goal["goalCode"] ?? goal["GoalCode"] ?? "").toString();
        if (code.isNotEmpty) goalsByCode[code] = goal;
        final nested = goal["tasks"];
        if (nested is List) {
          for (final task in nested) {
            if (task is! Map) continue;
            final taskCode = (task["taskCode"] ?? task["TaskCode"] ?? "")
                .toString();
            if (taskCode.isNotEmpty) tasksByCode[taskCode] = task;
          }
        }
        final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
        if (months is List) {
          for (final month in months) {
            if (month is Map) indexGoal(month);
          }
        }
      }

      for (final item in detailed) {
        if (item is Map) indexGoal(item);
      }

      void apply(Map target, Map source) {
        for (final key in [
          "assignedUsers",
          "AssignedUsers",
          "assignedTo",
          "AssignedTo",
          "assignTo",
          "quantity",
          "Quantity",
          "targetQuantity",
          "TargetQuantity",
          "completedQuantity",
          "CompletedQuantity",
          "pendingQuantity",
          "PendingQuantity",
          "performanceType",
          "PerformanceType",
          "quantitySplits",
          "QuantitySplits",
        ]) {
          final value = source[key];
          if (value == null) continue;
          if (value is List && value.isEmpty) continue;
          if (value is String && value.trim().isEmpty) continue;
          target[key] = value;
        }
      }

      for (final goal in goals) {
        if (goal is! Map) continue;
        final code = (goal["goalCode"] ?? goal["GoalCode"] ?? "").toString();
        final source = goalsByCode[code];
        if (source != null) apply(goal, source);
        final nested = goal["tasks"];
        if (nested is List) {
          for (final task in nested) {
            if (task is! Map) continue;
            final taskCode = (task["taskCode"] ?? task["TaskCode"] ?? "")
                .toString();
            final taskSource = tasksByCode[taskCode];
            if (taskSource != null) apply(task, taskSource);
          }
        }
      }

      for (final task in tasks) {
        if (task is! Map) continue;
        final taskCode = (task["taskCode"] ?? task["TaskCode"] ?? "")
            .toString();
        final taskSource = tasksByCode[taskCode];
        if (taskSource != null) apply(task, taskSource);
      }
    } catch (e) {
      debugPrint("Assigned names were not loaded: $e");
    }

    await _fillMissingTaskNames(goals, tasks);
  }

  Future<void> _fillMissingTaskNames(
    List<dynamic> goals,
    List<dynamic> tasks,
  ) async {
    final pending = <String, List<Map>>{};

    void collect(dynamic task) {
      if (task is! Map) return;
      if (_namesFrom(task).isNotEmpty) return;
      final code = (task["taskCode"] ?? task["TaskCode"] ?? "").toString();
      if (code.isEmpty) return;
      pending.putIfAbsent(code, () => []).add(task);
    }

    for (final task in tasks) {
      collect(task);
    }
    for (final goal in goals) {
      if (goal is! Map) continue;
      final nested = goal["tasks"];
      if (nested is! List) continue;
      for (final task in nested) {
        collect(task);
      }
    }

    final codes = pending.keys.toList();
    const batchSize = 6;
    for (var start = 0; start < codes.length; start += batchSize) {
      final end = start + batchSize > codes.length
          ? codes.length
          : start + batchSize;
      await Future.wait(codes.sublist(start, end).map((code) async {
        try {
          final details = await SuperAdminService.getTaskByCode(code);
          final people = details["assignedTo"] ?? details["AssignedTo"];
          if (people is! List || people.isEmpty) return;
          for (final task in pending[code]!) {
            task["assignedTo"] = people;
          }
        } catch (e) {
          debugPrint("Task assignees $code: $e");
        }
      }));
    }
  }

  void applyFilters() {
    setState(() {
      filteredTasks = allTasks.where((task) {
        if (selectedStatus != null &&
            (task["status"] ?? "").toLowerCase() !=
                selectedStatus!.toLowerCase()) {
          return false;
        }

        if (selectedPriority != null &&
            (task["priority"] ?? "").toLowerCase() !=
                selectedPriority!.toLowerCase()) {
          return false;
        }

        if (selectedOverdue != null) {
          bool overdueValue = selectedOverdue == "Yes";
          if ((task["isOverdue"] ?? false) != overdueValue) {
            return false;
          }
        }

        if (!_matchesWorkDate(task)) return false;

        return true;
      }).toList();

      filteredGoals = allGoals.where((goal) {
        if (selectedStatus != null &&
            (goal["status"] ?? "").toLowerCase() !=
                selectedStatus!.toLowerCase()) {
          return false;
        }

        if (selectedPriority != null &&
            (goal["priority"] ?? "").toLowerCase() !=
                selectedPriority!.toLowerCase()) {
          return false;
        }

        if (selectedOverdue != null) {
          bool overdueValue = selectedOverdue == "Yes";
          if ((goal["isOverdue"] ?? false) != overdueValue) {
            return false;
          }
        }

        if (!_matchesWorkDate(goal)) return false;

        return true;
      }).toList();

      // ---------------- LEAVE FILTER ----------------
      filteredLeaves = allLeaves.where((leave) {
        if (selectedLeaveStatus != null &&
            (leave["status"] ?? "").toLowerCase() !=
                selectedLeaveStatus!.toLowerCase())
          return false;

        if (selectedLeaveType != null &&
            (leave["type"] ?? "").toLowerCase() !=
                selectedLeaveType!.toLowerCase())
          return false;

        if (selectedLeaveDate != null) {
          final leaveDate = leave["fromDate"];
          if (leaveDate == null) return false;

          final date = DateTime.parse(leaveDate.toString());
          if (date.year != selectedLeaveDate!.year ||
              date.month != selectedLeaveDate!.month ||
              date.day != selectedLeaveDate!.day) {
            return false;
          }
        }

        return true;
      }).toList();

      // ---------------- PERMISSION FILTER ----------------
      filteredPermissions = allPermissions.where((p) {
        final filterDate = selectedPermissionDate ?? selectedLeaveDate;
        if (filterDate != null) {
          final rawDate = p["date"];
          if (rawDate == null) return false;
          final date = DateTime.tryParse(rawDate.toString());
          if (date == null) return false;

          if (date.year != filterDate.year ||
              date.month != filterDate.month ||
              date.day != filterDate.day) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  bool _matchesWorkDate(dynamic item) {
    if (startDate == null && endDate == null) return true;
    if (item is! Map) return false;
    final raw = workDateBy == "Completed Date"
        ? (item["completedDate"] ?? item["completed_Date"])
        : (item["dueDate"] ?? item["due_Date"]);
    final day = _parseDay(raw);
    if (day == null) return false;
    if (startDate != null) {
      final from = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (day.isBefore(from)) return false;
    }
    if (endDate != null) {
      final to = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (day.isAfter(to)) return false;
    }
    return true;
  }

  DateTime? _parseDay(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.startsWith("0001-01-01")) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  bool _isQuantityTask(dynamic task) {
    if (task is! Map) return false;
    final map = Map<String, dynamic>.from(task);
    final type = (map["performanceType"] ?? map["PerformanceType"] ?? "")
        .toString()
        .toLowerCase();
    if (type == "qty" || type == "quantity") return true;
    if (taskAssignedQty(map) > 0) return true;
    return (readGoalInt(map, const [
          "targetQuantity",
          "TargetQuantity",
        ]) ??
        0) >
        0;
  }

  String _qtyText(dynamic task, {required bool completed}) {
    if (!_isQuantityTask(task)) return "-";
    final map = Map<String, dynamic>.from(task as Map);
    if (completed) {
      final done = taskAchievedQty(map);
      return (done > 0 ? done : goalDone(map)).toString();
    }
    final assigned = taskAssignedQty(map);
    if (assigned > 0) return assigned.toString();
    return goalTarget(map).toString();
  }

  String? _qtyCaption(dynamic item) {
    if (!_isQuantityTask(item)) return null;
    return "Target ${_qtyText(item, completed: false)}  ·  Completed ${_qtyText(item, completed: true)}";
  }

  List<({String name, String? caption})> _goalTaskEntries(dynamic goal) {
    final items = <dynamic>[];
    void add(dynamic raw) {
      if (raw is List) items.addAll(raw);
    }

    if (goal is Map) {
      add(goal["tasks"]);
      if (_isYearly(goal)) {
        for (final month in _monthlyChildren(goal)) {
          add(month["tasks"]);
        }
      }
    }

    final lines = <({String name, String? caption})>[];
    final seen = <String>{};
    for (final item in items) {
      final name = item is String
          ? item
          : item is Map
          ? (item["task"] ?? item["title"] ?? "").toString()
          : item.toString();
      if (name.trim().isEmpty) continue;
      final caption = item is Map ? _qtyCaption(item) : null;
      final key = "$name|${caption ?? ""}".toLowerCase();
      if (!seen.add(key)) continue;
      lines.add((name: "${lines.length + 1}. $name", caption: caption));
    }
    return lines;
  }

  List<String> _goalTaskLines(dynamic goal) {
    return [
      for (final entry in _goalTaskEntries(goal))
        entry.caption == null ? entry.name : "${entry.name}\n${entry.caption}",
    ];
  }

  Widget _nameWithQty(String name, String? caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: Theme.of(context).textTheme.labelMedium),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              caption,
              style: const TextStyle(
                color: WebTheme.brand,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  String get _activeTable {
    if (selectedView == "Work") return selectedType;
    return selectedLeaveView ?? "Leave";
  }

  void _selectTable(String type) {
    setState(() {
      if (type == "Goals" || type == "Tasks") {
        selectedView = "Work";
        selectedType = type;
      } else {
        selectedView = "Leave";
        selectedLeaveView = type;
      }
    });
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
        title: const Text("Reports Table"),
        actions: [
          PopupMenuButton<String>(
            tooltip: "Download",
            icon: const Icon(Icons.download_rounded),
            color: const Color(0xFF163824),
            onSelected: _downloadReport,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "pdf",
                child: _DownloadChoice(
                  icon: Icons.picture_as_pdf_rounded,
                  label: "PDF",
                ),
              ),
              PopupMenuItem(
                value: "excel",
                child: _DownloadChoice(
                  icon: Icons.table_view_rounded,
                  label: "Excel",
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, modalSetState) {
                      return buildFilterSheet(modalSetState);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : Padding(
              padding: AppLayout.pagePadding(context),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in const [
                      "Goals",
                      "Tasks",
                      "Leave",
                      "Permission",
                    ])
                      ChoiceChip(
                        label: Text(type),
                        selected: _activeTable == type,
                        selectedColor: WebTheme.brandSoft,
                        labelStyle: TextStyle(
                          color: _activeTable == type
                              ? WebTheme.brand
                              : WebTheme.inkOf(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        onSelected: (_) => _selectTable(type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                /// 🔹 FILTER CHIPS SECTION - FOR GOALS/TASKS
                if (selectedView == "Work" &&
                    (selectedStatus != null ||
                        selectedPriority != null ||
                        selectedOverdue != null ||
                        startDate != null ||
                        endDate != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (selectedStatus != null)
                          _buildFilterChip("Status: $selectedStatus", () {
                            setState(() {
                              selectedStatus = null;
                              applyFilters();
                            });
                          }),
                        if (selectedPriority != null)
                          _buildFilterChip("Priority: $selectedPriority", () {
                            setState(() {
                              selectedPriority = null;
                              applyFilters();
                            });
                          }),
                        if (selectedOverdue != null)
                          _buildFilterChip("Overdue: $selectedOverdue", () {
                            setState(() {
                              selectedOverdue = null;
                              applyFilters();
                            });
                          }),
                        if (startDate != null || endDate != null)
                          _buildFilterChip(_dateRangeLabel(), () {
                            setState(() {
                              startDate = null;
                              endDate = null;
                              applyFilters();
                            });
                          }),
                      ],
                    ),
                  ),

                if (selectedView == "Leave" &&
                    (selectedLeaveType != null ||
                        selectedLeaveStatus != null ||
                        selectedLeaveDate != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (selectedLeaveType != null)
                          _buildFilterChip(
                            "Leave Type: $selectedLeaveType",
                            () {
                              setState(() {
                                selectedLeaveType = null;
                                applyFilters();
                              });
                            },
                          ),
                        if (selectedLeaveStatus != null)
                          _buildFilterChip("Status: $selectedLeaveStatus", () {
                            setState(() {
                              selectedLeaveStatus = null;
                              applyFilters();
                            });
                          }),
                        if (selectedLeaveDate != null)
                          _buildFilterChip(
                            "Date: ${AppHelpers.formatDate(selectedLeaveDate!.toString())}",
                            () {
                              setState(() {
                                selectedLeaveDate = null;
                                applyFilters();
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      final currentList = selectedView == "Work"
                          ? (selectedType == "Tasks"
                                ? filteredTasks
                                : filteredGoals)
                          : (selectedLeaveView == "Leave"
                                ? filteredLeaves
                                : filteredPermissions);
                      if (loadError != null && currentList.isEmpty) {
                        return const AppLoadError();
                      }
                      if (currentList.isEmpty) {
                        return Center(
                          child: Text(
                            "No data available",
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        );
                      }
                      final table = selectedView == "Work"
                          ? (selectedType == "Tasks"
                                ? _buildTaskTable()
                                : _buildGoalTable())
                          : (selectedLeaveView == "Leave"
                                ? _buildLeaveTable()
                                : _buildPermissionTable());
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: WebTheme.surfaceOf(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WebTheme.lineOf(context)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(child: table),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            ),
    );
  }

  Widget _buildLeaveTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(WebTheme.brandSoftOf(context)),
      headingTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: WebTheme.brand,
      ),
      columns: const [
        DataColumn(label: Text("Leave Category")),
        DataColumn(label: Text("Leave Type")),
        DataColumn(label: Text("Date")),
        DataColumn(label: Text("Reason")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Approved Date")),
        DataColumn(label: Text("Reject Reason")),
        DataColumn(label: Text("Compensation Date")),
      ],
      rows: filteredLeaves.map((item) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                item["leavecategory"] ?? "-",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                item["type"] ?? "-",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                AppHelpers.formatDate(item["fromDate"] ?? "-"),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                item["reason"] ?? "",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),

            DataCell(
              Text(
                item["status"] ?? "",
                style: TextStyle(
                  color: item["status"] == "Approved"
                      ? Colors.green
                      : item["status"] == "Rejected"
                      ? Colors.red
                      : Colors.orange,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Text(
                AppHelpers.formatDate(item["approvedate"] ?? "-"),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                item["rejreason"] ?? "-",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),

            DataCell(
              Text(
                AppHelpers.formatDate(item["compensationDate"] ?? "-"),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPermissionTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(WebTheme.brandSoftOf(context)),
      headingTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: WebTheme.brand,
      ),
      columns: const [
        DataColumn(label: Text("Reason")),
        DataColumn(label: Text("Date")),
        DataColumn(label: Text("From Time")),
        DataColumn(label: Text("To Time")),
        DataColumn(label: Text("Total Hours")),
        DataColumn(label: Text("Submitted Date")),
        DataColumn(label: Text("Status")),
      ],
      rows: filteredPermissions.map((item) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                item["reason"] ?? "",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                AppHelpers.formatDate(item["date"] ?? "-"),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                item["fromTime"] ?? "-",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                item["toTime"] ?? "-",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                _hoursLabel(item["totalHours"] ?? item["totalhours"]),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                _cellDate(item["submittedDate"] ?? item["submdate"]),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DataCell(
              Text(
                item["status"] ?? "",
                style: TextStyle(
                  color: item["status"] == "Approved"
                      ? Colors.green
                      : item["status"] == "Rejected"
                      ? Colors.red
                      : Colors.orange,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTaskTable() {
    return DataTable(
      showCheckboxColumn: false,
      headingRowColor: WidgetStateProperty.all(WebTheme.brandSoftOf(context)),
      headingTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: WebTheme.brand,
      ),
      columns: const [
        DataColumn(label: Text("Sl.No")),
        DataColumn(label: Text("Task")),
        DataColumn(label: Text("Assigned To")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Priority")),
        DataColumn(label: Text("Points")),
        DataColumn(label: Text("Due Date")),
        DataColumn(label: Text("Completed Date")),
        DataColumn(label: Text("Overdue")),
      ],
      rows: [
        for (var index = 0; index < filteredTasks.length; index++)
          _taskRow(filteredTasks[index], index),
      ],
    );
  }

  DataRow _taskRow(dynamic task, int index) {
    final dueDate = _cellDate(task["dueDate"] ?? task["due_Date"]);
    final completedDate = _cellDate(
      task["completedDate"] ?? task["completed_Date"],
    );

    return DataRow(
      onSelectChanged: (_) => _openTask(task),
      cells: [
        DataCell(
          Text("${index + 1}", style: Theme.of(context).textTheme.labelMedium),
        ),
        DataCell(
          _nameWithQty((task["task"] ?? "-").toString(), _qtyCaption(task)),
        ),
        DataCell(
          Text(
            _assigneeLabel(task),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(
            task["status"] ?? "-",
            style: TextStyle(
              color: TaskUtils.getStatusColor(
                TaskUtils.parseStatus(task["status"] ?? ""),
              ),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            task["priority"] ?? "-",
            style: TextStyle(
              color: TaskUtils.getPriorityColor(task["priority"]),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            (task["points"] ?? 0).toString(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(dueDate, style: Theme.of(context).textTheme.labelMedium),
        ),
        DataCell(
          Text(
            completedDate,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(
            task["isOverdue"] == true ? "Yes" : "No",
            style: TextStyle(
              color: task["isOverdue"] == true ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        dataRowMinHeight: 60,
        dataRowMaxHeight: double.infinity,

        headingRowColor: WidgetStateProperty.all(WebTheme.brandSoftOf(context)),
        headingTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: WebTheme.brand,
        ),

        columns: const [
          DataColumn(label: Text("Sl.No")),
          DataColumn(label: Text("Goal")),
          DataColumn(label: Text("Goal Type")),
          DataColumn(label: Text("Assigned To")),
          DataColumn(label: Text("Tasks")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Priority")),
          DataColumn(label: Text("Due Date")),
          DataColumn(label: Text("Completed Date")),
          DataColumn(label: Text("Progress")),
          DataColumn(label: Text("Points")),
          DataColumn(label: Text("Overdue")),
        ],

        rows: [
          for (var index = 0; index < filteredGoals.length; index++)
            _goalRow(filteredGoals[index], index),
        ],
      ),
    );
  }

  DataRow _goalRow(dynamic goal, int index) {
    final tasksList = _goalTaskEntries(goal);
    final goalType = (goal["goalType"] ?? goal["GoalType"] ?? "-").toString();

    return DataRow(
      onSelectChanged: (_) => _openGoal(goal),
      cells: [
        DataCell(
          Text("${index + 1}", style: Theme.of(context).textTheme.labelMedium),
        ),
        DataCell(
          _nameWithQty((goal["title"] ?? "").toString(), _qtyCaption(goal)),
        ),
        DataCell(
          Text(
            goalType.isEmpty ? "-" : goalType,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(
            _assigneeLabel(goal),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: tasksList.isNotEmpty
                  ? [
                      for (final entry in tasksList)
                        Padding(
                          padding: const EdgeInsets.only(top: 3, bottom: 3),
                          child: _nameWithQty(entry.name, entry.caption),
                        ),
                    ]
                  : [const Text("-")],
            ),
          ),
        ),
        DataCell(
          Text(
            goal["status"] ?? "-",
            style: TextStyle(
              color: TaskUtils.getStatusColor(
                TaskUtils.parseStatus(goal["status"] ?? ""),
              ),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            goal["priority"] ?? "",
            style: TextStyle(
              color: TaskUtils.getPriorityColor(goal["priority"]),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            _cellDate(goal["dueDate"] ?? goal["due_Date"]),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(
            _cellDate(goal["completedDate"] ?? goal["completed_Date"]),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(
            _percentLabel(goal["progress"]),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(
            (goal["points"] ?? 0).toString(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        DataCell(
          Text(
            goal["isOverdue"] == true ? "Yes" : "No",
            style: TextStyle(
              color: goal["isOverdue"] == true ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _openTask(dynamic task) {
    final code = (task["taskCode"] ?? task["TaskCode"] ?? "").toString();
    if (code.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetails(taskCode: code)),
    );
  }

  void _openGoal(dynamic goal) {
    final cardGoal = goal is Map<String, dynamic>
        ? Map<String, dynamic>.from(goal)
        : Map<String, dynamic>.from(goal as Map);
    cardGoal["goalpoints"] = cardGoal["goalpoints"] ?? cardGoal["points"] ?? 0;
    cardGoal["completed_Date"] =
        cardGoal["completed_Date"] ?? cardGoal["completedDate"];
    cardGoal["tasks"] = _cardTasks(cardGoal["tasks"]);

    final months = _monthlyChildren(cardGoal);
    cardGoal["monthlyGoals"] = months;

    final names = _assigneeNames(cardGoal);
    if (names.isNotEmpty) {
      cardGoal["assignedUsers"] = [
        for (final name in names) {"name": name},
      ];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text((cardGoal["title"] ?? "Goal").toString()),
          ),
          body: SingleChildScrollView(
            padding: AppLayout.pagePadding(context),
            child: GoalCard(goal: cardGoal),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _cardTasks(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((task) {
      final copy = Map<String, dynamic>.from(task);
      copy["dueDate"] = copy["dueDate"] ?? copy["due_Date"];
      copy["task"] = copy["task"] ?? copy["title"] ?? "";
      final names = _namesFrom(copy);
      if (names.isEmpty && reportUsers.length == 1) {
        final only = (reportUsers.first["name"] ?? reportUsers.first["Name"] ?? "")
            .toString()
            .trim();
        if (only.isNotEmpty) names.add(only);
      }
      if (names.isNotEmpty) {
        copy["assignedTo"] = [
          for (final name in names) {"name": name},
        ];
      }
      return copy;
    }).toList();
  }

  List<Map<String, dynamic>> _monthlyChildren(Map yearly) {
    final parentId = _idOf(yearly["goalId"] ?? yearly["id"] ?? yearly["Id"]);
    if (parentId.isEmpty) return [];

    final months = <Map<String, dynamic>>[];
    for (final item in allGoals) {
      if (item is! Map) continue;
      final parent = _idOf(item["parentGoalId"] ?? item["ParentGoalId"]);
      if (parent != parentId) continue;
      final month = Map<String, dynamic>.from(item);
      month["goalType"] = (month["goalType"] ?? "Monthly").toString();
      month["goalpoints"] = month["goalpoints"] ?? month["points"] ?? 0;
      month["tasks"] = _cardTasks(month["tasks"]);
      month["monthlyGoals"] = <Map<String, dynamic>>[];
      months.add(month);
    }
    return months;
  }

  bool _isYearly(Map goal) {
    return (goal["goalType"] ?? goal["GoalType"] ?? "")
        .toString()
        .toLowerCase() ==
        "yearly";
  }

  String _idOf(dynamic value) {
    if (value == null) return "";
    final text = value.toString().trim();
    if (text.isEmpty || text == "null") return "";
    return text;
  }

  String _assigneeLabel(dynamic item) {
    final names = _assigneeNames(item);
    if (names.isEmpty) return "-";
    return names.join(", ");
  }

  List<String> _assigneeNames(dynamic item) {
    final names = _namesFrom(item);
    if (names.isEmpty && reportUsers.length == 1) {
      _addName(
        names,
        (reportUsers.first["name"] ?? reportUsers.first["Name"] ?? "")
            .toString(),
      );
    }
    if (names.isEmpty && widget.userId != null) {
      _addName(names, _userNameById(widget.userId.toString()));
    }
    return names;
  }

  List<String> _namesFrom(dynamic item) {
    final names = <String>[];

    void read(dynamic raw) {
      if (raw == null || raw is num || raw is bool) return;
      if (raw is String) {
        if (int.tryParse(raw.trim()) != null) return;
        for (final part in raw.split(",")) {
          _addName(names, part);
        }
        return;
      }
      if (raw is Map) {
        final named = (raw["name"] ?? raw["Name"] ?? raw["userName"] ?? "")
            .toString();
        if (named.trim().isNotEmpty) {
          _addName(names, named);
          return;
        }
        final id = (raw["userId"] ?? raw["UserId"] ?? raw["id"] ?? "")
            .toString();
        _addName(names, _userNameById(id));
        return;
      }
      if (raw is List) {
        for (final entry in raw) {
          read(entry);
        }
      }
    }

    if (item is Map) {
      read(item["assignedUsers"] ?? item["AssignedUsers"]);
      read(item["assignedTo"] ?? item["AssignedTo"] ?? item["assignTo"]);
      read(item["members"] ?? item["Members"]);
    }
    return names;
  }

  void _addName(List<String> names, String raw) {
    final name = AppHelpers.extractName(raw).trim();
    if (name.isEmpty || name.toLowerCase() == "n/a") return;
    if (int.tryParse(name) != null) return;
    final exists = names.any(
      (current) => current.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) names.add(name);
  }

  String _userNameById(String rawId) {
    final id = rawId.split("-").first.trim();
    if (id.isEmpty) return "";
    for (final user in reportUsers) {
      final userId = (user["userId"] ?? user["UserId"] ?? "").toString();
      if (userId == id) {
        return (user["name"] ?? user["Name"] ?? "").toString();
      }
    }
    return "";
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      backgroundColor: const Color(0xFF194D26),
      side: BorderSide.none,
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
      onDeleted: onDelete,
    );
  }

  String _cellDate(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    if (text.isEmpty || text.startsWith("0001-01-01")) return "-";
    return AppHelpers.formatDate(text);
  }

  String _hoursLabel(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    if (text.isEmpty) return "-";
    return "$text hrs";
  }

  String _percentLabel(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? "") ?? 0;
    return "${number.toStringAsFixed(0)}%";
  }

  String _dateRangeLabel() {
    final from = startDate == null ? "Any" : TimeUtils.formatDate(startDate!);
    final to = endDate == null ? "Any" : TimeUtils.formatDate(endDate!);
    return "$workDateBy: $from - $to";
  }

  Future<void> _pickWorkBound({
    required bool isStart,
    required void Function(void Function()) modalSetState,
  }) async {
    final current = isStart ? startDate : endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    modalSetState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
      if (startDate != null &&
          endDate != null &&
          startDate!.isAfter(endDate!)) {
        final swap = startDate;
        startDate = endDate;
        endDate = swap;
      }
    });
    applyFilters();
  }

  Future<void> _downloadReport(String kind) async {
    final headers = _exportHeaders();
    final rows = _exportRows();
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No rows to download")),
      );
      return;
    }
    final title = "${_activeTable} Report";
    try {
      final path = kind == "excel"
          ? await ReportExport.saveExcel(
              title: title,
              headers: headers,
              rows: rows,
            )
          : await ReportExport.savePdf(
              title: title,
              headers: headers,
              rows: rows,
            );
      if (!mounted || path.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kind == "excel" ? "Excel saved. Open it from your Files app." : "Saved to $path",
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save the file")),
      );
    }
  }

  List<String> _exportHeaders() {
    switch (_activeTable) {
      case "Tasks":
        return const [
          "Sl.No",
          "Task",
          "Assigned To",
          "Status",
          "Priority",
          "Points",
          "Target Qty",
          "Completed Qty",
          "Due Date",
          "Completed Date",
          "Overdue",
        ];
      case "Leave":
        return const [
          "Leave Category",
          "Leave Type",
          "Date",
          "Reason",
          "Status",
          "Approved Date",
          "Reject Reason",
          "Compensation Date",
        ];
      case "Permission":
        return const [
          "Reason",
          "Date",
          "From Time",
          "To Time",
          "Total Hours",
          "Submitted Date",
          "Status",
        ];
      default:
        return const [
          "Sl.No",
          "Goal",
          "Goal Type",
          "Assigned To",
          "Tasks",
          "Status",
          "Priority",
          "Due Date",
          "Completed Date",
          "Progress",
          "Points",
          "Overdue",
        ];
    }
  }

  List<List<String>> _exportRows() {
    switch (_activeTable) {
      case "Tasks":
        return [
          for (var index = 0; index < filteredTasks.length; index++)
            [
              "${index + 1}",
              (filteredTasks[index]["task"] ?? "-").toString(),
              _assigneeLabel(filteredTasks[index]),
              (filteredTasks[index]["status"] ?? "-").toString(),
              (filteredTasks[index]["priority"] ?? "-").toString(),
              (filteredTasks[index]["points"] ?? 0).toString(),
              _qtyText(filteredTasks[index], completed: false),
              _qtyText(filteredTasks[index], completed: true),
              _cellDate(
                filteredTasks[index]["dueDate"] ??
                    filteredTasks[index]["due_Date"],
              ),
              _cellDate(
                filteredTasks[index]["completedDate"] ??
                    filteredTasks[index]["completed_Date"],
              ),
              filteredTasks[index]["isOverdue"] == true ? "Yes" : "No",
            ],
        ];
      case "Leave":
        return [
          for (final item in filteredLeaves)
            [
              (item["leavecategory"] ?? "-").toString(),
              (item["type"] ?? "-").toString(),
              AppHelpers.formatDate(item["fromDate"] ?? "-"),
              (item["reason"] ?? "").toString(),
              (item["status"] ?? "").toString(),
              AppHelpers.formatDate(item["approvedate"] ?? "-"),
              (item["rejreason"] ?? "-").toString(),
              AppHelpers.formatDate(item["compensationDate"] ?? "-"),
            ],
        ];
      case "Permission":
        return [
          for (final item in filteredPermissions)
            [
              (item["reason"] ?? "").toString(),
              AppHelpers.formatDate(item["date"] ?? "-"),
              (item["fromTime"] ?? "-").toString(),
              (item["toTime"] ?? "-").toString(),
              _hoursLabel(item["totalHours"] ?? item["totalhours"]),
              _cellDate(item["submittedDate"] ?? item["submdate"]),
              (item["status"] ?? "").toString(),
            ],
        ];
      default:
        return [
          for (var index = 0; index < filteredGoals.length; index++)
            [
              "${index + 1}",
              (filteredGoals[index]["title"] ?? "").toString(),
              (filteredGoals[index]["goalType"] ??
                      filteredGoals[index]["GoalType"] ??
                      "-")
                  .toString(),
              _assigneeLabel(filteredGoals[index]),
              _goalTaskLines(filteredGoals[index]).join("\n"),
              (filteredGoals[index]["status"] ?? "-").toString(),
              (filteredGoals[index]["priority"] ?? "").toString(),
              _cellDate(
                filteredGoals[index]["dueDate"] ??
                    filteredGoals[index]["due_Date"],
              ),
              _cellDate(
                filteredGoals[index]["completedDate"] ??
                    filteredGoals[index]["completed_Date"],
              ),
              _percentLabel(filteredGoals[index]["progress"]),
              (filteredGoals[index]["points"] ?? 0).toString(),
              filteredGoals[index]["isOverdue"] == true ? "Yes" : "No",
            ],
        ];
    }
  }

  Widget buildFilterSheet(void Function(void Function()) modalSetState) {
    const ink = Color(0xFF194D26);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              "Filters",
              style: TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose what to show in the table",
              style: TextStyle(color: Color(0xFF66756C), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (selectedView == "Work") ...[
              _filterCard(
                "Status",
                _buildChoiceChips(
                  values: const [
                    "Not Started",
                    "InProgress",
                    "Completed",
                    "Pending",
                    "Pause",
                  ],
                  selectedValue: selectedStatus,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedStatus = selectedStatus == value ? null : value;
                    applyFilters();
                  },
                ),
              ),
              _filterCard(
                "Priority",
                _buildChoiceChips(
                  values: const ["Normal", "Medium", "High"],
                  selectedValue: selectedPriority,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedPriority = selectedPriority == value ? null : value;
                    applyFilters();
                  },
                ),
              ),
              _filterCard(
                "Overdue",
                _buildChoiceChips(
                  values: const ["Yes", "No"],
                  selectedValue: selectedOverdue,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedOverdue = selectedOverdue == value ? null : value;
                    applyFilters();
                  },
                ),
              ),
              _filterCard(
                "Date",
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _dateModeButton(
                          label: "Due Date",
                          selected: workDateBy == "Due Date",
                          onTap: () {
                            modalSetState(() => workDateBy = "Due Date");
                            applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _dateModeButton(
                          label: "Completed Date",
                          selected: workDateBy == "Completed Date",
                          onTap: () {
                            modalSetState(() => workDateBy = "Completed Date");
                            applyFilters();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _rangeDateButton(
                          caption: "From date",
                          value: startDate == null
                              ? "Pick date"
                              : TimeUtils.formatDate(startDate!),
                          onTap: () => _pickWorkBound(
                            isStart: true,
                            modalSetState: modalSetState,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _rangeDateButton(
                          caption: "To date",
                          value: endDate == null
                              ? "Pick date"
                              : TimeUtils.formatDate(endDate!),
                          onTap: () => _pickWorkBound(
                            isStart: false,
                            modalSetState: modalSetState,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (selectedView == "Leave") ...[
              _filterCard(
                "Type",
                _buildChoiceChips(
                  values: const ["Leave", "Permission"],
                  selectedValue: selectedLeaveView,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedLeaveView = selectedLeaveView == value
                        ? "Leave"
                        : value;
                    applyFilters();
                  },
                ),
              ),
              if (selectedLeaveView == "Leave") ...[
                _filterCard(
                  "Leave Type",
                  _buildChoiceChips(
                    values: const ["Full Day", "First Half", "Second Half"],
                    selectedValue: selectedLeaveType,
                    modalSetState: modalSetState,
                    onSelected: (value) {
                      selectedLeaveType = selectedLeaveType == value
                          ? null
                          : value;
                      applyFilters();
                    },
                  ),
                ),
                _filterCard(
                  "Status",
                  _buildChoiceChips(
                    values: const ["Pending", "Approved", "Rejected"],
                    selectedValue: selectedLeaveStatus,
                    modalSetState: modalSetState,
                    onSelected: (value) {
                      selectedLeaveStatus = selectedLeaveStatus == value
                          ? null
                          : value;
                      applyFilters();
                    },
                  ),
                ),
              ],
              _filterCard(
                "Date",
                Row(
                  children: [
                    _rangeDateButton(
                  caption: "Date",
                  value: selectedLeaveDate != null
                      ? AppHelpers.formatDate(
                          selectedLeaveDate!.toIso8601String(),
                        )
                      : "Pick date",
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedLeaveDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked == null) return;
                    modalSetState(() {
                      selectedLeaveDate = selectedLeaveDate == picked
                          ? null
                          : picked;
                      selectedPermissionDate = selectedLeaveDate;
                    });
                    applyFilters();
                  },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: "Clear Filters",
                isLoading: _isLoading,
                onPressed: () {
                  modalSetState(() {
                    selectedStatus = null;
                    selectedPriority = null;
                    selectedOverdue = null;
                    startDate = null;
                    endDate = null;
                    workDateBy = "Due Date";
                    selectedLeaveType = null;
                    selectedLeaveStatus = null;
                    selectedLeaveDate = null;
                    selectedPermissionDate = null;
                    selectedLeaveView = null;
                  });
                  applyFilters();
                },
                color: ink,
                txtcolor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E5DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF194D26),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _dateModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF194D26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF194D26)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF194D26),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rangeDateButton({
    required String caption,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF194D26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: const TextStyle(
                    color: Color(0xFF66756C),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF194D26),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF194D26),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> values,
    required String? selectedValue,
    required void Function(void Function()) modalSetState,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = selectedValue == value;
        return Material(
          color: isSelected ? const Color(0xFF194D26) : const Color(0xFFE7F0EA),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              modalSetState(() {
                onSelected(value);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                value,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF194D26),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DownloadChoice extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DownloadChoice({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
