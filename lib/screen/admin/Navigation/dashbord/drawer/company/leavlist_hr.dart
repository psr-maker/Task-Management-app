import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/dashboard_service.dart';

class HrLeaves extends StatefulWidget {
  const HrLeaves({super.key});

  @override
  State<HrLeaves> createState() => _HrLeavesState();
}

class _HrLeavesState extends State<HrLeaves> {
  List<Map<String, dynamic>> allLeaves = [];
  List<Map<String, dynamic>> filteredLeaves = [];

  List<String> departments = ["All Departments"];

  String selectedDepartment = "All Departments";

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await DashboardService.getHrLeaves();

      if (!mounted) return;

      setState(() {
        allLeaves = data;

        _buildDepartments();

        if (!departments.contains(selectedDepartment)) {
          selectedDepartment = "All Departments";
        }

        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _leaveOverlapsSelectedMonth(Map<String, dynamic> item) {
    final from = DateTime.tryParse(item["fromDate"]?.toString() ?? "");

    final to =
        DateTime.tryParse(item["toDate"]?.toString() ?? "") ?? from;

    if (from == null) return false;

    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);

    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final leaveEnd = to ?? from;

    return !leaveEnd.isBefore(monthStart) && !from.isAfter(monthEnd);
  }

  void _buildDepartments() {
    final Set<String> departmentSet = {};

    final monthFiltered = allLeaves.where(_leaveOverlapsSelectedMonth);

    for (final item in monthFiltered) {
      final department = item["department"]?.toString().trim();

      if (department != null && department.isNotEmpty) {
        departmentSet.add(department);
      }
    }

    final sortedDepartments = departmentSet.toList()..sort();

    departments = ["All Departments", ...sortedDepartments];
  }

  void _applyFilters() {
    final monthFiltered = allLeaves.where(_leaveOverlapsSelectedMonth).toList();

    if (selectedDepartment == "All Departments") {
      filteredLeaves = monthFiltered;
    } else {
      filteredLeaves = monthFiltered.where((item) {
        return item["department"]?.toString().trim() == selectedDepartment;
      }).toList();
    }
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(
        initialDate: selectedMonth,
        firstDate: DateTime(now.year - 2, 1),
        lastDate: DateTime(now.year, now.month),
      ),
    );

    if (picked == null) return;

    setState(() {
      selectedMonth = picked;

      _buildDepartments();

      if (!departments.contains(selectedDepartment)) {
        selectedDepartment = "All Departments";
      }

      _applyFilters();
    });
  }

  Future<void> _showDepartmentPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Select Department",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),

              ...departments.map((department) {
                return ListTile(
                  leading: Icon(
                    department == "All Departments"
                        ? Icons.business_rounded
                        : Icons.apartment_rounded,
                  ),
                  title: Text(department),
                  trailing: department == selectedDepartment
                      ? const Icon(Icons.check_rounded, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(ctx, department),
                );
              }),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != selectedDepartment) {
      setState(() {
        selectedDepartment = selected;

        _applyFilters();
      });
    }
  }

  String _monthName(DateTime date) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];

    return "${months[date.month - 1]} ${date.year}";
  }

  String _shortDate(String value) {
    try {
      final date = DateTime.parse(value);

      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
      ];

      return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}";
    } catch (_) {
      return value;
    }
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _groupByDepartmentAndStaff() {
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

    for (final item in filteredLeaves) {
      final department =
          item["department"]?.toString().trim().isNotEmpty == true
          ? item["department"].toString().trim()
          : "Unknown Department";

      final name = item["name"]?.toString().trim().isNotEmpty == true
          ? item["name"].toString().trim()
          : "Unknown Staff";

      grouped.putIfAbsent(department, () => {});

      grouped[department]!.putIfAbsent(name, () => []);

      grouped[department]![name]!.add(item);
    }

    return grouped;
  }

  static const List<String> _sessionOrder = ["Full Day", "First Half", "Second Half"];

  Map<String, List<Map<String, dynamic>>> _groupBySession(
    List<Map<String, dynamic>> entries,
  ) {
    final Map<String, List<Map<String, dynamic>>> bySession = {};

    for (final item in entries) {
      final session = item["leaveType"]?.toString().trim().isNotEmpty == true
          ? item["leaveType"].toString().trim()
          : "Full Day";

      bySession.putIfAbsent(session, () => []);

      bySession[session]!.add(item);
    }

    final ordered = <String, List<Map<String, dynamic>>>{};

    for (final key in _sessionOrder) {
      if (bySession.containsKey(key)) {
        ordered[key] = bySession[key]!;
      }
    }

    for (final entry in bySession.entries) {
      if (!ordered.containsKey(entry.key)) {
        ordered[entry.key] = entry.value;
      }
    }

    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Approved Leaves"),  leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),),

      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: isLoading
                ? RotatingFlower()
                : filteredLeaves.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _loadLeaves,
                    child: _buildGroupedList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedDepartment,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              IconButton(
                onPressed: _showDepartmentPicker,
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: "Filter by department",
              ),

              IconButton(
                onPressed: _selectMonth,
                icon: const Icon(Icons.calendar_month_rounded),
                tooltip: "Select month",
              ),
            ],
          ),

          Text(
            _monthName(selectedMonth),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

        
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final grouped = _groupByDepartmentAndStaff();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(15),
      children: grouped.entries.map((entry) {
        return _buildDepartmentCard(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildDepartmentCard(
    String department,
    Map<String, List<Map<String, dynamic>>> staffMap,
  ) {
    final totalLeaves = staffMap.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DEPARTMENT HEADER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: Colors.blue.shade700,
                    size: 15,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "$totalLeaves leaves",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    "${staffMap.length} Staff",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // STAFF LIST
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: staffMap.entries.map((entry) {
                return _buildStaffBlock(entry.key, entry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffBlock(String name, List<Map<String, dynamic>> entries) {
    final sortedEntries = List<Map<String, dynamic>>.from(entries);

    sortedEntries.sort((a, b) {
      final dateA =
          DateTime.tryParse(a["fromDate"]?.toString() ?? "") ?? DateTime(1900);

      final dateB =
          DateTime.tryParse(b["fromDate"]?.toString() ?? "") ?? DateTime(1900);

      return dateA.compareTo(dateB);
    });

    final reason = sortedEntries.first["reason"]?.toString().trim() ?? "";

    final bySession = _groupBySession(sortedEntries);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STAFF HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${entries.length} ${entries.length == 1 ? 'leave' : 'leaves'}",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            if (reason.isNotEmpty) ...[
            
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: Text(
                  reason,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 10),

            Divider(height: 1, color: Colors.grey.shade200),

            const SizedBox(height: 8),

            // SESSION GROUPS
            ...bySession.entries.map((sessionEntry) {
              return _buildSessionGroup(sessionEntry.key, sessionEntry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionGroup(String session, List<Map<String, dynamic>> entries) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 4),

          ...entries.map((item) => _buildLeaveDateRow(item)),
        ],
      ),
    );
  }

  Widget _buildLeaveDateRow(Map<String, dynamic> item) {
    final String fromDate = item["fromDate"]?.toString() ?? "";

    final String leaveTyp = item["leaveTyp"]?.toString().trim() ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.circle, size: 5, color: Colors.grey.shade400),

          const SizedBox(width: 8),

          Text(
            _shortDate(fromDate),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (leaveTyp.isNotEmpty) ...[
            Text(
              " - ",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),

            Text(
              leaveTyp,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(Icons.beach_access_outlined, size: 35),
            ),

            const SizedBox(height: 16),

            const Text(
              "No Approved Leaves",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              selectedDepartment == "All Departments"
                  ? "No leaves found for ${_monthName(selectedMonth)}"
                  : "No leaves found for $selectedDepartment",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MonthYearPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MonthYearPickerDialog> createState() =>
      _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int displayedYear;

  static const monthLabels = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  @override
  void initState() {
    super.initState();

    displayedYear = widget.initialDate.year;
  }

  bool _isMonthEnabled(int year, int month) {
    final candidate = DateTime(year, month);

    final first = DateTime(widget.firstDate.year, widget.firstDate.month);

    final last = DateTime(widget.lastDate.year, widget.lastDate.month);

    return !candidate.isBefore(first) && !candidate.isAfter(last);
  }

  void _changeYear(int delta) {
    final newYear = displayedYear + delta;

    if (newYear < widget.firstDate.year || newYear > widget.lastDate.year) {
      return;
    }

    setState(() {
      displayedYear = newYear;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: displayedYear > widget.firstDate.year
                      ? () => _changeYear(-1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),

                Text(
                  "$displayedYear",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                IconButton(
                  onPressed: displayedYear < widget.lastDate.year
                      ? () => _changeYear(1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),

            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;

                final enabled = _isMonthEnabled(displayedYear, month);

                final isSelected =
                    displayedYear == widget.initialDate.year &&
                    month == widget.initialDate.month;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: enabled
                      ? () => Navigator.pop(
                          context,
                          DateTime(displayedYear, month),
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monthLabels[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: !enabled
                            ? Colors.grey.shade400
                            : isSelected
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}