import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/table.dart';
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
  bool _isLoading = false;
  List<ReportTask> allTasks = [];
  List<ReportTask> filteredTasks = [];

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
      final tasks = await _service.getFilteredTasks(
        userId: widget.userId,
        department: widget.department,
      );

      setState(() {
        allTasks = tasks;
        filteredTasks = tasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      filteredTasks = allTasks.where((task) {
        if (selectedStatus != null &&
            task.status.toLowerCase() != selectedStatus!.toLowerCase()) {
          return false;
        }

        if (selectedPriority != null &&
            task.priority.toLowerCase() != selectedPriority!.toLowerCase()) {
          return false;
        }

        if (selectedOverdue != null) {
          bool overdueValue = selectedOverdue == "Yes";
          if (task.isOverdue != overdueValue) {
            return false;
          }
        }

        // 🔥 DATE FILTER
        if (startDate != null && endDate != null) {
          if (task.createdAt == null) return false;

          if (task.createdAt!.isBefore(startDate!) ||
              task.createdAt!.isAfter(endDate!)) {
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
                backgroundColor: Color.fromARGB(255, 30, 45, 38),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: buildFilterDropdowns(),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: startDate != null && endDate != null
                    ? DateTimeRange(start: startDate!, end: endDate!)
                    : null,
              );

              if (picked != null) {
                setState(() {
                  startDate = picked.start;
                  endDate = picked.end;
                  applyFilters();
                });
              }
            },
          ),

          // ✅ SHOW CLEAR ICON ONLY WHEN DATE SELECTED
          if (startDate != null && endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                  applyFilters();
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                /// 🔹 TABLE SECTION
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: filteredTasks.isEmpty
                        ? Center(
                            child: Text(
                              "No data available",
                              style: Theme.of(context).textTheme.displaySmall,
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
                                  child: DataTable(
                                    headingTextStyle: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,

                                    dataTextStyle: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,

                                    headingRowHeight: 50,
                                    dataRowMinHeight: 45,
                                    headingRowColor: MaterialStateProperty.all(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text("User")),
                                      DataColumn(label: Text("Department")),
                                      DataColumn(label: Text("Task")),
                                      DataColumn(label: Text("Assigner")),
                                      DataColumn(label: Text("Status")),
                                      DataColumn(label: Text("Priority")),
                                      DataColumn(label: Text("Members")),
                                      DataColumn(label: Text("Start Date")),
                                      DataColumn(label: Text("Due Date")),
                                      DataColumn(label: Text("Completed Date")),
                                      DataColumn(label: Text("Overdue")),
                                    ],
                                    rows: filteredTasks.map((task) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(task.name ?? "")),
                                          DataCell(Text(task.department ?? "")),
                                          DataCell(Text(task.task ?? "")),
                                          DataCell(
                                            Text(
                                              AppHelpers.extractName(
                                                    task.assignBy,
                                                  ) ??
                                                  "",
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              task.status,
                                              style: TextStyle(
                                                color: TaskUtils.getStatusColor(
                                                  TaskUtils.parseStatus(
                                                    task.status,
                                                  ),
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              task.priority,
                                              style: TextStyle(
                                                color:
                                                    TaskUtils.getPriorityColor(
                                                      task.priority,
                                                    ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(task.members.toString()),
                                          ),
                                          DataCell(
                                            Text(
                                              task.createdAt?.toString().split(
                                                    " ",
                                                  )[0] ??
                                                  "",
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              task.dueDate?.toString().split(
                                                    " ",
                                                  )[0] ??
                                                  "",
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              task.status == "completed"
                                                  ? task.completedDate
                                                            ?.toString()
                                                            .split(" ")[0] ??
                                                        "-"
                                                  : "-",
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              task.isOverdue == true
                                                  ? "Yes"
                                                  : "No",
                                              style: TextStyle(
                                                color: task.isOverdue == true
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
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

  Color _getDropdownItemColor(BuildContext context, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (value.toLowerCase()) {
      /// STATUS COLORS
      case "completed":
        return Colors.green;
      case "inprogress":
        return Colors.amber;
      case "pending":
        return Colors.red;
      case "pause":
        return Colors.purple;
      case "not started":
        return Colors.grey;

      /// PRIORITY COLORS
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "normal":
        return Colors.green;

      default:
        return isDark ? Colors.white : Colors.black;
    }
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w700,
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: theme.colorScheme.surface,
        style: TextStyle(
          color: value != null
              ? _getDropdownItemColor(context, value)
              : theme.colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        iconEnabledColor: theme.colorScheme.onSurface,
        items: items.map((e) {
          return DropdownMenuItem<String>(
            value: e,
            child: Text(
              e,
              style: TextStyle(
                color: _getDropdownItemColor(context, e),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildFilterDropdowns() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// STATUS
              _buildDropdown(
                context: context,
                label: "Status",
                value: selectedStatus,
                items: [
                  "Not Started",
                  "InProgress",
                  "Completed",
                  "Pending",
                  "Pause",
                ],
                onChanged: (value) {
                  setLocalState(() => selectedStatus = value);
                  applyFilters();
                },
              ),

              const SizedBox(height: 16),

              /// PRIORITY
              _buildDropdown(
                context: context,
                label: "Priority",
                value: selectedPriority,
                items: ["Normal", "Medium", "High"],
                onChanged: (value) {
                  setLocalState(() => selectedPriority = value);
                  applyFilters();
                },
              ),

              const SizedBox(height: 16),

              /// OVERDUE
              _buildDropdown(
                context: context,
                label: "Overdue",
                value: selectedOverdue,
                items: ["Yes", "No"],
                onChanged: (value) {
                  setLocalState(() => selectedOverdue = value);
                  applyFilters();
                },
              ),

              const SizedBox(height: 20),
              Center(
                child: AppButton(
                  text: "Clear Filters",
                  isLoading: _isLoading,
                  onPressed: () {
                    setLocalState(() {
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
              // /// CLEAR BUTTON
              // ElevatedButton(
              //   onPressed: () {
              //     setLocalState(() {
              //       selectedStatus = null;
              //       selectedPriority = null;
              //       selectedOverdue = null;
              //     });
              //     applyFilters();
              //   },
              //   child: const Text("Clear Filters"),
              // ),
            ],
          ),
        );
      },
    );
  }
}
