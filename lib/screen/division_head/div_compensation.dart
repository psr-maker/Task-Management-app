import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class DivCompensation extends StatefulWidget {
  final String department;
  const DivCompensation({super.key, required this.department});

  @override
  State<DivCompensation> createState() => _DivCompensationState();
}

class _DivCompensationState extends State<DivCompensation> {
  bool isLoading = true;
  late String selectedDepartment;
  List<Map<String, dynamic>> extraWorks = [];

  List<String> get departments =>
      DivisionConfig.childDepartments(widget.department);

  @override
  void initState() {
    super.initState();
    selectedDepartment = _defaultDepartment();
    _loadData();
  }

  String _defaultDepartment() {
    final children = departments;
    final purchase = children.where(
      (dept) => DivisionConfig.isAllowedDepartment(dept, [
        "Purchase Department",
      ]),
    );
    if (purchase.isNotEmpty) return purchase.first;
    if (children.isNotEmpty) return children.first;
    return widget.department;
  }

  dynamic _field(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) return item[key];
    }
    final lower = {
      for (final entry in item.entries) entry.key.toString().toLowerCase(): entry.value,
    };
    for (final key in keys) {
      final value = lower[key.toLowerCase()];
      if (value != null) return value;
    }
    return null;
  }

  bool _isApproved(Map<String, dynamic> item) {
    final status = (_field(item, ["status"]) ?? "").toString().toLowerCase().trim();
    return status == "approved";
  }

  Future<void> _selectDepartment(String department) async {
    if (selectedDepartment == department) return;
    setState(() => selectedDepartment = department);
    await _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final result = await OvertimeService.getExtraWorkByDepartments([
        selectedDepartment,
      ]);

      if (!mounted) return;
      setState(() {
        extraWorks = result.where(_isApproved).toList();
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        extraWorks = [];
        isLoading = false;
      });
    }
  }

  Widget _buildDeptChip(String dept) {
    final selected = selectedDepartment == dept;
    final label = dept.replaceAll(" Department", "");
    final secondary = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _selectDepartment(dept),
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

  String _formatDate(dynamic value) {
    if (value == null) return "-";
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return DateFormat("dd MMM yyyy").format(parsed);
  }

  String _formatTime(dynamic value) {
    if (value == null || value.toString().isEmpty) return "--:--";
    final text = value.toString();
    try {
      if (text.contains("T") || text.contains("-")) {
        final parsed = DateTime.tryParse(text);
        if (parsed != null) {
          return DateFormat("HH:mm").format(parsed.toLocal());
        }
      }
    } catch (_) {}
    final parts = text.split(":");
    if (parts.length >= 2) return "${parts[0]}:${parts[1]}";
    return text;
  }

  String _formatHours(dynamic value) {
    if (value == null) return "0";
    final number = double.tryParse(value.toString());
    if (number == null) return value.toString();
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number.toStringAsFixed(2);
  }

  String _formatWorkType(String value) {
    switch (value) {
      case "WeeklyOff":
        return "Weekly Off";
      case "PublicHoliday":
        return "Public Holiday";
      case "CompanyHoliday":
        return "Company Holiday";
      default:
        return value.isEmpty ? "Other" : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approved Compensation"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: departments.map(_buildDeptChip).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: RotatingFlower())
                : extraWorks.isEmpty
                ? Center(
                    child: Text(
                      "No approved compensation found for $selectedDepartment",
                      textAlign: TextAlign.center,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(15),
                      itemCount: extraWorks.length,
                      itemBuilder: (context, index) => _card(extraWorks[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final staffName = (_field(item, ["staffName", "name", "reason"]) ?? "")
        .toString()
        .trim();
    final taskName =
        (_field(item, ["taskName", "task", "taskCode", "taskId"]) ?? "")
            .toString()
            .trim();
    final workType = (_field(item, ["workType"]) ?? "").toString();
    final totalHours = _field(item, [
      "expectedHours",
      "totalHours",
      "totalhours",
    ]);
    final workDate = _field(item, ["workDate", "date"]);
    final startTime = _field(item, ["startTime"]);
    final endTime = _field(item, ["endTime"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    staffName.isNotEmpty ? staffName[0].toUpperCase() : "?",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffName.isEmpty ? "Unknown Staff" : staffName,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        taskName.isEmpty ? "No Task" : taskName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "APPROVED",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _labeledRow("Name", staffName.isEmpty ? "-" : staffName),
            _labeledRow("Task", taskName.isEmpty ? "-" : taskName),
            _labeledRow("Start Time", _formatTime(startTime)),
            _labeledRow("End Time", _formatTime(endTime)),
            _labeledRow("Total Hours", "${_formatHours(totalHours)} Hours"),
            _labeledRow("Date", _formatDate(workDate)),
            _labeledRow("Work Type", _formatWorkType(workType)),
            _labeledRow("Status", "Approved"),
          ],
        ),
      ),
    );
  }

  Widget _labeledRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
