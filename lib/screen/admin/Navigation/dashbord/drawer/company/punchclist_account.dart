import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class PunchCompany extends StatefulWidget {
  final int managerId;

  const PunchCompany({super.key, required this.managerId});

  @override
  State<PunchCompany> createState() => _PunchCompanyState();
}

class _PunchCompanyState extends State<PunchCompany> {
  List<Map<String, dynamic>> allCorrections = [];
  List<Map<String, dynamic>> filteredCorrections = [];

  List<String> departments = ["All Departments"];

  String selectedDepartment = "All Departments";

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _loadCorrections();
  }

  Future<void> _loadCorrections() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await DashboardService.getPunchCorrections(
        managerId: widget.managerId,
        month: selectedMonth.month,
        year: selectedMonth.year,
      );

      if (!mounted) return;

      setState(() {
        allCorrections = data;

        _buildDepartments();

        // If selected department is no longer available
        if (!departments.contains(selectedDepartment)) {
          selectedDepartment = "All Departments";
        }

        _applyDepartmentFilter();
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

  void _buildDepartments() {
    final Set<String> departmentSet = {};
    final monthFiltered = allCorrections.where((item) {
      final date = DateTime.tryParse(item["date"]?.toString() ?? "");

      if (date == null) return false;

      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    });

    for (final item in monthFiltered) {
      final department = item["department"]?.toString().trim();

      if (department != null && department.isNotEmpty) {
        departmentSet.add(department);
      }
    }

    final sortedDepartments = departmentSet.toList()..sort();

    departments = ["All Departments", ...sortedDepartments];
  }

  void _applyDepartmentFilter() {
    final monthFiltered = allCorrections.where((item) {
      final date = DateTime.tryParse(item["date"]?.toString() ?? "");

      if (date == null) return false;

      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();

    if (selectedDepartment == "All Departments") {
      filteredCorrections = monthFiltered;
    } else {
      filteredCorrections = monthFiltered.where((item) {
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

  Future<void> _shiftMonth(int delta) async {
    if (!_canShiftMonth(delta)) return;
    final next = DateTime(selectedMonth.year, selectedMonth.month + delta);
    setState(() => selectedMonth = DateTime(next.year, next.month));
    await _loadCorrections();
  }

  void _chooseDepartment(String department) {
    if (department == selectedDepartment) return;
    setState(() {
      selectedDepartment = department;
      _applyDepartmentFilter();
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
    });

    await _loadCorrections();
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

        _applyDepartmentFilter();
      });
    }
  }

  String _monthName(DateTime date) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${months[date.month - 1]} ${date.year}";
  }

  String _formatTime(String value) {
    return TimeUtils.formatTime12(value, empty: value);
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _groupCorrections() {
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

    for (final item in filteredCorrections) {
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

  @override
  Widget build(BuildContext context) {
    if (WebPushedChrome.isWeb(context)) return _webPage();
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        title: WebPushedChrome.isWeb(context)
            ? null
            : const Text("Punch Corrections"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: WebPushedChrome.body(
        context,
        title: 'Punch Corrections',
        subtitle: 'Company attendance correction requests',
        panel: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: RotatingFlower())
                  : filteredCorrections.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadCorrections,
                      child: _buildGroupedList(),
                    ),
            ),
          ],
        ),
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
                        'Attendance Reports',
                        style: TextStyle(
                          fontSize: AppLayout.isDesktop(context) ? 24 : 20,
                          fontWeight: FontWeight.w800,
                          color: WebTheme.inkOf(context),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Approved punch corrections',
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
                  : filteredCorrections.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadCorrections,
                      child: _webCorrectionList(),
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
          '${filteredCorrections.length} ${filteredCorrections.length == 1 ? 'correction' : 'corrections'}',
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
      return value.isEmpty ? "—" : value;
    }
  }

  Widget _webCorrectionList() {
    final grouped = _groupCorrections();
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

  Widget _webStaffCard(String name, List<Map<String, dynamic>> corrections) {
    final sorted = List<Map<String, dynamic>>.from(corrections)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a["date"]?.toString() ?? "") ?? DateTime(1900);
        final dateB = DateTime.tryParse(b["date"]?.toString() ?? "") ?? DateTime(1900);
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
                    "${sorted.length} ${sorted.length == 1 ? 'correction' : 'corrections'}",
                    style: TextStyle(
                      color: WebTheme.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (wide) _webCorrectionHeading(),
              for (final item in sorted)
                wide ? _webCorrectionRow(item) : _compactCorrection(item),
            ],
          );
        },
      ),
    );
  }

  Widget _webCorrectionHeading() {
    final style = TextStyle(
      color: WebTheme.mutedOf(context),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text("Date", style: style)),
          SizedBox(width: 120, child: Text("Punch", style: style)),
          SizedBox(width: 100, child: Text("Time", style: style)),
          Expanded(child: Text("Reason", style: style)),
        ],
      ),
    );
  }

  bool _isPunchIn(Map<String, dynamic> item) {
    return (item["correctionType"] ?? "").toString() == "Missing Punch In";
  }

  String _punchLabel(Map<String, dynamic> item) {
    return _isPunchIn(item) ? "Punch In" : "Punch Out";
  }

  String _reasonOf(Map<String, dynamic> item) {
    final reason = (item["reason"] ?? "").toString().trim();
    return reason.isEmpty || reason.toLowerCase() == "null" ? "—" : reason;
  }

  Widget _webCorrectionRow(Map<String, dynamic> item) {
    final punchIn = _isPunchIn(item);
    final tone = punchIn ? const Color(0xFF047857) : const Color(0xFFB45309);
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
          SizedBox(
            width: 150,
            child: Text(_mediumDate(item["date"]?.toString() ?? ""), style: ink),
          ),
          SizedBox(
            width: 120,
            child: Text(
              _punchLabel(item),
              style: TextStyle(color: tone, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(_formatTime(item["punchTime"]?.toString() ?? ""), style: ink),
          ),
          Expanded(
            child: Text(
              _reasonOf(item),
              style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactCorrection(Map<String, dynamic> item) {
    final punchIn = _isPunchIn(item);
    final tone = punchIn ? const Color(0xFF047857) : const Color(0xFFB45309);
    final reason = _reasonOf(item);
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
            _mediumDate(item["date"]?.toString() ?? ""),
            style: TextStyle(
              color: WebTheme.inkOf(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${_punchLabel(item)} · ${_formatTime(item["punchTime"]?.toString() ?? "")}",
            style: TextStyle(color: tone, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          if (reason != "—") ...[
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

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.fact_check_rounded,
                size: 18,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 6),

              Text(
                "${filteredCorrections.length} Corrections",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final grouped = _groupCorrections();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(15),

      children: grouped.entries.map((departmentEntry) {
        final department = departmentEntry.key;

        final staffMap = departmentEntry.value;

        return _buildDepartmentCard(department, staffMap);
      }).toList(),
    );
  }

  Widget _buildDepartmentCard(
    String department,
    Map<String, List<Map<String, dynamic>>> staffMap,
  ) {
    final totalCorrections = staffMap.values.fold<int>(
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "$totalCorrections corrections",
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

          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
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

  Widget _buildStaffBlock(String name, List<Map<String, dynamic>> corrections) {
    final sortedCorrections = List<Map<String, dynamic>>.from(corrections);

    sortedCorrections.sort((a, b) {
      final dateA =
          DateTime.tryParse(a["date"]?.toString() ?? "") ?? DateTime(1900);

      final dateB =
          DateTime.tryParse(b["date"]?.toString() ?? "") ?? DateTime(1900);

      return dateA.compareTo(dateB);
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,

                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",

                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

                Text(
                  "${corrections.length}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Divider(height: 1, color: Colors.grey.shade200),

            const SizedBox(height: 4),

            ...sortedCorrections.map((item) {
              return _buildCorrectionRow(item);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionRow(Map<String, dynamic> item) {
    final String date = item["date"]?.toString() ?? "";

    final String type = item["correctionType"]?.toString() ?? "";

    final String time = item["punchTime"]?.toString() ?? "";

    final bool isIn = type == "Missing Punch In";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          // DATE
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortDate(date),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // TYPE ICON
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isIn
                  ? Colors.green.withOpacity(0.10)
                  : Colors.orange.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.login_rounded : Icons.logout_rounded,
              size: 16,
              color: isIn ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),

          const SizedBox(width: 10),

          // TYPE
          Expanded(
            child: Text(
              isIn ? "Punch In" : "Punch Out",
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // TIME
          Text(
            _formatTime(time),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String value) {
    try {
      final date = DateTime.parse(value);

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      return "${date.day.toString().padLeft(2, '0')} "
          "${months[date.month - 1]}";
    } catch (_) {
      return value;
    }
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

              decoration: BoxDecoration(shape: BoxShape.circle),

              child: Icon(Icons.fact_check_outlined, size: 35),
            ),

            const SizedBox(height: 16),

            Text(
              "No Punch Corrections",
              style: TextStyle(
                color: WebTheme.inkOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              selectedDepartment == "All Departments"
                  ? "No corrections found for ${_monthName(selectedMonth)}"
                  : "No corrections found for $selectedDepartment",
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
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int displayedYear;

  static const monthLabels = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
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

            // MONTH GRID
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
                      color: isSelected ? WebTheme.brand : WebTheme.canvasOf(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? WebTheme.brand : WebTheme.lineOf(context),
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
                  style: TextStyle(
                    color: WebTheme.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
