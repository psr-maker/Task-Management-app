import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
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

      showAppMessage(context, e.toString());
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

  DateTime get _earliestMonth {
    final now = DateTime.now();
    return DateTime(now.year - 2, 1);
  }

  DateTime get _latestMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool _canShiftMonth(int delta) {
    final next = DateTime(selectedMonth.year, selectedMonth.month + delta);
    final candidate = DateTime(next.year, next.month);
    return !candidate.isBefore(_earliestMonth) && !candidate.isAfter(_latestMonth);
  }

  void _shiftMonth(int delta) {
    if (!_canShiftMonth(delta)) return;
    final next = DateTime(selectedMonth.year, selectedMonth.month + delta);
    setState(() {
      selectedMonth = DateTime(next.year, next.month);
      _buildDepartments();
      if (!departments.contains(selectedDepartment)) {
        selectedDepartment = "All Departments";
      }
      _applyFilters();
    });
  }

  void _chooseDepartment(String department) {
    if (department == selectedDepartment) return;
    setState(() {
      selectedDepartment = department;
      _applyFilters();
    });
  }

  String _deptLabel(String department) {
    if (department == "All Departments") return "All";
    return department.replaceAll(" Department", "");
  }

  Future<void> _selectMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(
        initialDate: selectedMonth,
        firstDate: _earliestMonth,
        lastDate: _latestMonth,
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
    if (WebPushedChrome.isWeb(context)) return _webPage();
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

  Widget _webPage() {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back, color: WebTheme.inkOf(context)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Reports',
                        style: TextStyle(
                          fontSize: AppLayout.isDesktop(context) ? 24 : 20,
                          fontWeight: FontWeight.w800,
                          color: WebTheme.inkOf(context),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Approved leave by department',
                        style: TextStyle(
                          fontSize: 13,
                          color: WebTheme.mutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _webFilters(),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: RotatingFlower())
                  : filteredLeaves.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadLeaves,
                      child: _webLeaveList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
        boxShadow: WebTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department',
            style: TextStyle(
              color: WebTheme.mutedOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final department in departments) _deptChip(department),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Month',
            style: TextStyle(
              color: WebTheme.mutedOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _monthControl(),
        ],
      ),
    );
  }

  Widget _deptChip(String department) {
    final selected = selectedDepartment == department;
    return Material(
      color: selected ? WebTheme.brand : WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _chooseDepartment(department),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? WebTheme.brand : WebTheme.lineOf(context),
            ),
          ),
          child: Text(
            _deptLabel(department),
            style: TextStyle(
              color: selected ? Colors.white : WebTheme.inkOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthControl() {
    return Row(
      children: [
        _monthStep(Icons.chevron_left_rounded, -1),
        const SizedBox(width: 8),
        Material(
          color: WebTheme.brandSoftOf(context),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _selectMonth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18, color: WebTheme.brand),
                  const SizedBox(width: 8),
                  Text(
                    _monthName(selectedMonth),
                    style: TextStyle(
                      color: WebTheme.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _monthStep(Icons.chevron_right_rounded, 1),
        const Spacer(),
        Text(
          '${filteredLeaves.length} ${filteredLeaves.length == 1 ? 'leave' : 'leaves'}',
          style: TextStyle(
            color: WebTheme.mutedOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _monthStep(IconData icon, int delta) {
    final enabled = _canShiftMonth(delta);
    return Material(
      color: WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? () => _shiftMonth(delta) : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: Icon(
            icon,
            color: enabled ? WebTheme.inkOf(context) : WebTheme.mutedOf(context),
          ),
        ),
      ),
    );
  }

  String _mediumDate(String value) {
    try {
      final date = DateTime.parse(value);
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
      ];
      return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
    } catch (_) {
      return value;
    }
  }

  String _leaveWhen(Map<String, dynamic> item) {
    final from = item["fromDate"]?.toString() ?? "";
    final to = item["toDate"]?.toString() ?? "";
    final start = _mediumDate(from);
    if (to.isEmpty) return start;
    final end = _mediumDate(to);
    if (end == start || end.isEmpty) return start;
    return "$start – $end";
  }

  Widget _webLeaveList() {
    final grouped = _groupByDepartmentAndStaff();
    final showDepartment = selectedDepartment == "All Departments";
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final department in grouped.entries) ...[
          if (showDepartment)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.apartment_rounded, size: 16, color: WebTheme.brand),
                  const SizedBox(width: 6),
                  Text(
                    department.key.replaceAll(" Department", ""),
                    style: TextStyle(
                      color: WebTheme.inkOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          for (final staff in department.value.entries)
            _webStaffCard(staff.key, staff.value),
        ],
      ],
    );
  }

  Widget _webStaffCard(String name, List<Map<String, dynamic>> entries) {
    final sorted = List<Map<String, dynamic>>.from(entries)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a["fromDate"]?.toString() ?? "") ?? DateTime(1900);
        final dateB = DateTime.tryParse(b["fromDate"]?.toString() ?? "") ?? DateTime(1900);
        return dateA.compareTo(dateB);
      });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
        boxShadow: WebTheme.cardShadow(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: WebTheme.brand,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: WebTheme.inkOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    "${sorted.length} ${sorted.length == 1 ? 'day' : 'days'}",
                    style: TextStyle(
                      color: WebTheme.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (wide) _webLeaveHeading(),
              for (final item in sorted)
                wide ? _webLeaveRow(item) : _compactLeave(item),
            ],
          );
        },
      ),
    );
  }

  Widget _webLeaveHeading() {
    final style = TextStyle(
      color: WebTheme.mutedOf(context),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 168, child: Text("Date", style: style)),
          SizedBox(width: 110, child: Text("Day", style: style)),
          SizedBox(width: 72, child: Text("Type", style: style)),
          Expanded(child: Text("Reason", style: style)),
        ],
      ),
    );
  }

  Widget _compactLeave(Map<String, dynamic> item) {
    final session = item["leaveType"]?.toString().trim();
    final day = (session == null || session.isEmpty) ? "Full Day" : session;
    final type = item["leaveTyp"]?.toString().trim() ?? "";
    final reason = item["reason"]?.toString().trim() ?? "";
    final detail = [
      day,
      if (type.isNotEmpty) type,
    ].join(" · ");
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: WebTheme.lineOf(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _leaveWhen(item),
            style: TextStyle(
              color: WebTheme.inkOf(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(color: WebTheme.brand, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              reason,
              style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _webLeaveRow(Map<String, dynamic> item) {
    final session = item["leaveType"]?.toString().trim();
    final day = (session == null || session.isEmpty) ? "Full Day" : session;
    final type = item["leaveTyp"]?.toString().trim() ?? "";
    final reason = item["reason"]?.toString().trim() ?? "";
    final ink = TextStyle(
      color: WebTheme.inkOf(context),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: WebTheme.lineOf(context))),
      ),
      child: Row(
        children: [
          SizedBox(width: 168, child: Text(_leaveWhen(item), style: ink)),
          SizedBox(width: 110, child: Text(day, style: ink)),
          SizedBox(
            width: 72,
            child: Text(type.isEmpty ? "—" : type, style: ink),
          ),
          Expanded(
            child: Text(
              reason.isEmpty ? "—" : reason,
              style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 13),
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
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WebTheme.lineOf(context)),
        boxShadow: WebTheme.cardShadow(context),
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
                    color: WebTheme.brandSoftOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: WebTheme.brand,
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
                        style: TextStyle(
                          color: WebTheme.inkOf(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "$totalLeaves leaves",
                        style: TextStyle(
                          color: WebTheme.mutedOf(context),
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
                    color: WebTheme.canvasOf(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: WebTheme.lineOf(context)),
                  ),
                  child: Text(
                    "${staffMap.length} Staff",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WebTheme.inkOf(context),
                    ),
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
        color: WebTheme.canvasOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.lineOf(context)),
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
                  backgroundColor: WebTheme.brand,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: WebTheme.inkOf(context),
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
                    color: WebTheme.brandSoftOf(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${entries.length} ${entries.length == 1 ? 'leave' : 'leaves'}",
                    style: TextStyle(
                      color: WebTheme.brand,
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
                  style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 10),

            Divider(height: 1, color: WebTheme.lineOf(context)),

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
              color: WebTheme.mutedOf(context),
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
          Icon(Icons.circle, size: 5, color: WebTheme.mutedOf(context)),

          const SizedBox(width: 8),

          Text(
            _shortDate(fromDate),
            style: TextStyle(
              color: WebTheme.inkOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (leaveTyp.isNotEmpty) ...[
            Text(
              " - ",
              style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 12),
            ),

            Text(
              leaveTyp,
              style: TextStyle(
                color: WebTheme.mutedOf(context),
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

            Text(
              "No Approved Leaves",
              style: TextStyle(
                color: WebTheme.inkOf(context),
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
              style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 12),
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
    final ink = WebTheme.inkOf(context);
    final muted = WebTheme.mutedOf(context);
    return Dialog(
      backgroundColor: WebTheme.surfaceOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select month',
              style: TextStyle(
                color: ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: displayedYear > widget.firstDate.year
                      ? () => _changeYear(-1)
                      : null,
                  icon: Icon(Icons.chevron_left_rounded, color: ink),
                ),

                Text(
                  "$displayedYear",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),

                IconButton(
                  onPressed: displayedYear < widget.lastDate.year
                      ? () => _changeYear(1)
                      : null,
                  icon: Icon(Icons.chevron_right_rounded, color: ink),
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
                          ? WebTheme.brand
                          : enabled
                          ? WebTheme.canvasOf(context)
                          : WebTheme.canvasOf(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? WebTheme.brand
                            : WebTheme.lineOf(context),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monthLabels[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: !enabled
                            ? muted
                            : isSelected
                            ? Colors.white
                            : ink,
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
                child: Text(
                  "Cancel",
                  style: TextStyle(color: WebTheme.brand, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}