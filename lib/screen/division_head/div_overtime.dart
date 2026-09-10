import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class DivOvertime extends StatefulWidget {
  final String department;
  const DivOvertime({super.key, required this.department});

  @override
  State<DivOvertime> createState() => _DivOvertimeState();
}

class _DivOvertimeState extends State<DivOvertime> {
  bool isLoading = true;
  late String selectedDepartment;
  List<Map<String, dynamic>> overtimes = [];

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
      for (final entry in item.entries)
        entry.key.toString().toLowerCase(): entry.value,
    };
    for (final key in keys) {
      final value = lower[key.toLowerCase()];
      if (value != null) return value;
    }
    return null;
  }

  String _statusOf(Map<String, dynamic> item) {
    final status = (_field(item, ["status"]) ?? "").toString().trim();
    if (status.isNotEmpty) return status;
    final approved = _field(item, ["isApproved", "approved"]);
    if (approved == true || approved.toString().toLowerCase() == "true") {
      return "Approved";
    }
    return "Pending";
  }

  Future<void> _selectDepartment(String department) async {
    if (selectedDepartment == department) return;
    setState(() => selectedDepartment = department);
    await _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final result = await OvertimeService.getOvertimeByDepartments([
        selectedDepartment,
      ]);

      if (!mounted) return;
      setState(() {
        overtimes = result;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        overtimes = [];
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
      final parsed = DateFormat("HH:mm:ss").parse(text);
      return DateFormat("HH:mm").format(parsed);
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

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value == "approved" || value == "accepted") return Colors.green;
    if (value.contains("reject")) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Overtime"),
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
                : overtimes.isEmpty
                ? Center(
                    child: Text(
                      "No overtime found for $selectedDepartment",
                      textAlign: TextAlign.center,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(15),
                      itemCount: overtimes.length,
                      itemBuilder: (context, index) => _card(overtimes[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final staffName = (_field(item, ["staffName", "name"]) ?? "")
        .toString()
        .trim();
    final status = _statusOf(item);
    final statusColor = _statusColor(status);
    final totalHours = _field(item, ["totalHours", "totalhours"]);
    final date = _field(item, ["date", "workDate"]);
    final fromTime = _field(item, ["fromTime", "startTime"]);
    final toTime = _field(item, ["toTime", "endTime"]);
    final reason = (_field(item, ["reason"]) ?? "").toString().trim();

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
                        "Overtime",
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _labeledRow("Name", staffName.isEmpty ? "-" : staffName),
            _labeledRow("Date", _formatDate(date)),
            _labeledRow("From Time", _formatTime(fromTime)),
            _labeledRow("To Time", _formatTime(toTime)),
            _labeledRow("Total Hours", "${_formatHours(totalHours)} Hours"),
            _labeledRow("Reason", reason.isEmpty ? "-" : reason),
            _labeledRow("Status", status),
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
