import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class ReportsTable extends StatefulWidget {
  final int? userId;
  final String? department;

  const ReportsTable({super.key, this.userId, this.department});

  @override
  State<ReportsTable> createState() => _DeadlineReportsTabState();
}

class _DeadlineReportsTabState extends State<ReportsTable> {
  final ReportsService _service = ReportsService();
  String selectedType = "Goals";
  bool _isLoading = false;
  List<dynamic> allTasks = [];
  List<dynamic> filteredTasks = [];

  List<dynamic> allGoals = [];
  List<dynamic> filteredGoals = [];

  String? selectedStatus;
  String? selectedPriority;
  String? selectedOverdue;

  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final result = await _service.getFullReport(
        userId: widget.userId,
        department: widget.department,
      );

      setState(() {
        allTasks = result["tasks"] ?? [];
        filteredTasks = result["tasks"] ?? [];
        allGoals = result["goals"] ?? [];
        filteredGoals = result["goals"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Reports Table"),
        actions: [
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),

                /// 🔹 FILTER CHIPS SECTION
                if (selectedStatus != null ||
                    selectedPriority != null ||
                    selectedOverdue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                      ],
                    ),
                  ),

                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton("Goals"),
                      _buildToggleButton("Tasks"),
                    ],
                  ),
                ),

                /// 🔹 TABLE SECTION
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) {
                        final currentList = selectedType == "Tasks"
                            ? filteredTasks
                            : filteredGoals;

                        return currentList.isEmpty
                            ? Center(
                                child: Text(
                                  "No data available",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                              )
                            : Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: selectedType == "Tasks"
                                          ? _buildTaskTable()
                                          : _buildGoalTable(),
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTaskTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        Theme.of(context).colorScheme.secondary,
      ),
      headingTextStyle: Theme.of(context).textTheme.labelLarge,
      columns: const [
        DataColumn(label: Text("Task")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Priority")),
        DataColumn(label: Text("Points")),
        DataColumn(label: Text("Due Date")),
        DataColumn(label: Text("Completed Date")),
        DataColumn(label: Text("Overdue")),
      ],
      rows: filteredTasks.map((task) {
        String dueDate = task["due_Date"] != null
            ? AppHelpers.formatDate(task["due_Date"])
            : "-";

        String completedDate = task["completed_Date"] != null
            ? AppHelpers.formatDate(task["completed_Date"])
            : "-";

        return DataRow(
          cells: [
            DataCell(
              Text(
                task["task"] ?? "-",
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
                  fontSize: 14
                ),
              ),
            ),
            DataCell(
              Text(
                task["priority"] ?? "-",
                style: TextStyle(
                  color: TaskUtils.getPriorityColor(task["priority"]),
                  fontWeight: FontWeight.w600,
                  fontSize: 14
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
      }).toList(),
    );
  }

  Widget _buildGoalTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 60,
        dataRowMaxHeight: double.infinity,

        headingRowColor: WidgetStateProperty.all(
          Theme.of(context).colorScheme.secondary,
        ),
        headingTextStyle: Theme.of(context).textTheme.labelLarge,

        columns: const [
          DataColumn(label: Text("Goal")),
          DataColumn(label: Text("Tasks")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Priority")),
          DataColumn(label: Text("Due Date")),
          DataColumn(label: Text("Completed Date")),
          DataColumn(label: Text("Progress")),
          DataColumn(label: Text("Points")),
          DataColumn(label: Text("Overdue")),
        ],

        rows: filteredGoals.map((goal) {
          final tasksList = (goal["tasks"] is List)
              ? List<String>.from(goal["tasks"])
              : [];

          return DataRow(
            cells: [
              /// GOAL
              DataCell(
                Text(
                  goal["title"] ?? "",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),

              /// TASKS (MULTI-LINE, NO OVERFLOW)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: tasksList.isNotEmpty
                        ? tasksList.map((task) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 3,bottom: 3),
                              child: Text(
                                task,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            );
                          }).toList()
                        : [const Text("-")],
                  ),
                ),
              ),

              /// STATUS
              DataCell(
                Text(
                  goal["status"] ?? "-",
                  style: TextStyle(
                    color: TaskUtils.getStatusColor(
                      TaskUtils.parseStatus(goal["status"] ?? ""),
                    ),
                    fontWeight: FontWeight.w600,
                    fontSize: 14
                  ),
                ),
              ),

              /// PRIORITY
              DataCell(
                Text(
                  goal["priority"] ?? "",
                  style: TextStyle(
                    color: TaskUtils.getPriorityColor(goal["priority"]),
                    fontWeight: FontWeight.w600,
                    fontSize: 14
                  ),
                ),
              ),

              /// DUE DATE
              DataCell(
                Text(
                  goal["dueDate"] != null
                      ? AppHelpers.formatDate(goal["dueDate"])
                      : "-",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),

              /// COMPLETED DATE
              DataCell(
                Text(
                  goal["completed_Date"] != null
                      ? AppHelpers.formatDate(goal["completed_Date"])
                      : "-",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),

              /// PROGRESS
              DataCell(
                Text(
                  "${(goal["progress"] ?? 0).toStringAsFixed(0)}%",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),

              /// POINTS
              DataCell(
                Text(
                  (goal["points"] ?? 0).toString(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),

              /// OVERDUE
              DataCell(
                Text(
                  goal["isOverdue"] == true ? "Yes" : "No",
                  style: TextStyle(
                    color: goal["isOverdue"] == true
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleButton(String type) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedType = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == "Tasks" ? Icons.task_alt : Icons.flag,
                color: isSelected ? Colors.white : Colors.black54,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close),
      onDeleted: onDelete,
    );
  }

  Widget buildFilterSheet(void Function(void Function()) modalSetState) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 STATUS
            _buildHeading("Status"),
            const SizedBox(height: 12),
            _buildChoiceChips(
              values: [
                "Not Started",
                "InProgress",
                "Completed",
                "Pending",
                "Pause",
              ],
              selectedValue: selectedStatus,
              activeColor: Colors.blue,
              modalSetState: modalSetState,
              onSelected: (value) {
                selectedStatus = selectedStatus == value ? null : value;
                applyFilters();
              },
            ),

            const SizedBox(height: 24),

            /// 🔹 PRIORITY
            _buildHeading("Priority"),
            const SizedBox(height: 12),
            _buildChoiceChips(
              values: ["Normal", "Medium", "High"],
              selectedValue: selectedPriority,
              activeColor: Colors.orange,
              modalSetState: modalSetState,
              onSelected: (value) {
                selectedPriority = selectedPriority == value ? null : value;
                applyFilters();
              },
            ),

            const SizedBox(height: 24),

            /// 🔹 OVERDUE
            _buildHeading("Overdue"),
            const SizedBox(height: 12),
            _buildChoiceChips(
              values: ["Yes", "No"],
              selectedValue: selectedOverdue,
              activeColor: Theme.of(context).colorScheme.error,
              modalSetState: modalSetState,
              onSelected: (value) {
                selectedOverdue = selectedOverdue == value ? null : value;
                applyFilters();
              },
            ),

            const SizedBox(height: 30),

            Center(
              child: AppButton(
                text: "Clear Filters",
                isLoading: _isLoading,
                onPressed: () {
                  modalSetState(() {
                    selectedStatus = null;
                    selectedPriority = null;
                    selectedOverdue = null;
                  });

                  applyFilters();
                },
                color: Theme.of(context).colorScheme.secondary,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading(String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }

  Widget _buildChoiceChips({
    required List<String> values,
    required String? selectedValue,
    required Color activeColor,
    required void Function(void Function()) modalSetState,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((value) {
        final isSelected = selectedValue == value;

        return ChoiceChip(
          label: Text(value),
          selected: isSelected,
          onSelected: (_) {
            modalSetState(() {
              onSelected(value);
            });
          },
          selectedColor: activeColor,
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isSelected ? 4 : 0,
          shadowColor: activeColor.withOpacity(0.4),
        );
      }).toList(),
    );
  }
}
