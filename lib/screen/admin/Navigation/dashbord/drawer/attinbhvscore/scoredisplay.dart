import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/addattnbhv.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class BehaviourScoreDisplay extends StatefulWidget {
  final String Dept;
  final bool scoreLeaders;

  const BehaviourScoreDisplay({
    super.key,
    this.Dept = '',
    this.scoreLeaders = false,
  });

  @override
  State<BehaviourScoreDisplay> createState() => _BehaviourScoreDisplayState();
}

class _BehaviourScoreDisplayState extends State<BehaviourScoreDisplay> {
  int? selectedMonth;
  String departmentFilter = "All";
  List<String> departments = [];

  List<Map<String, dynamic>> allStaffScores = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  Future<void> loadScores() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (widget.scoreLeaders) {
        final scores = await AdminService.getDirectorAttitudeBehaviourScores();
        List<UserModel> users = [];
        try {
          users = await SuperAdminService.getAllUsers();
        } catch (_) {}

        final leaderUsers = users.where((user) {
          if (!AppRoles.isScoreLeader(user.role)) return false;
          return user.status.trim().toLowerCase() != "inactive";
        }).toList();

        final visible = scores
            .where((score) => _isLeaderScore(score, leaderUsers))
            .map((score) => _withLeaderDetails(score, leaderUsers))
            .toList();
        final departmentNames = <String>[];
        for (final user in leaderUsers) {
          final name = user.department.trim();
          if (name.isEmpty) continue;
          if (departmentNames.any(
            (item) => DivisionConfig.isAllowedDepartment(name, [item]),
          )) {
            continue;
          }
          departmentNames.add(name);
        }
        departmentNames.sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );

        if (!mounted) return;
        setState(() {
          allStaffScores = visible;
          departments = departmentNames;
          if (departmentFilter != "All" &&
              !departmentNames.any(
                (item) => DivisionConfig.isAllowedDepartment(
                  departmentFilter,
                  [item],
                ),
              )) {
            departmentFilter = "All";
          }
          isLoading = false;
        });
        return;
      }

      final scores = await AdminService.getDepartmentAttitudeBehaviourScores();

      if (!mounted) return;

      setState(() {
        allStaffScores = scores;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get filteredStaffScores {
    return allStaffScores.where((staff) {
      if (selectedMonth != null) {
        final dateValue = staff["date"];
        if (dateValue == null) return false;
        final date = DateTime.tryParse(dateValue.toString());
        if (date == null || date.month != selectedMonth) return false;
      }

      if (!widget.scoreLeaders || departmentFilter == "All") return true;
      return DivisionConfig.isAllowedDepartment(
        "${staff["department"] ?? ""}",
        [departmentFilter],
      );
    }).toList();
  }

  Future<void> selectMonth() async {
    final selected = await showDialog<int?>(
      context: context,

      builder: (context) {
        return SimpleDialog(
          title: const Text("Select Month"),

          children: [
            // ALL
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, null);
              },

              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),

                child: Text(
                  "All",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            ...List.generate(12, (index) {
              final month = index + 1;

              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, month);
                },

                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),

                  child: Text(
                    _monthName(month),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );

    setState(() {
      selectedMonth = selected;
    });
  }

  String _monthName(int month) {
    const months = [
      "",
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

    return months[month];
  }

  String get selectedMonthName {
    if (selectedMonth == null) {
      return "All";
    }

    return _monthName(selectedMonth!);
  }

  int totalScore(Map<String, dynamic> staff) {
    return (staff["communication"] ?? 0) +
        (staff["punctuality"] ?? 0) +
        (staff["integrity"] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text(
          "Behaviour & Attitude",
       
        ),

        actions: [
          if (widget.scoreLeaders)
            IconButton(
              tooltip: "Filter",
              onPressed: _openDepartmentFilter,
              icon: Badge(
                isLabelVisible: departmentFilter != "All",
                smallSize: 8,
                child: const Icon(Icons.filter_alt_outlined),
              ),
            ),
          IconButton(
            tooltip: "Add Score",

            onPressed: () async {
              await Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (_) => AddBehaviourScore(
                    department: widget.Dept,
                    scoreLeaders: widget.scoreLeaders,
                  ),
                ),
              );

              await loadScores();
            },

            icon: const Icon(Icons.add),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Filter Month",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            GestureDetector(
              onTap: selectMonth,

              child: Container(
                height: 52,

                padding: const EdgeInsets.symmetric(horizontal: 16),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: Colors.grey.shade300),
                ),

                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xff194d26)),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        selectedMonthName,

                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (isLoading) {
      return RotatingFlower();
    }

    if (errorMessage != null) {
      return AppLoadError(onRetry: loadScores);
    }

    final scores = filteredStaffScores;

    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              Icons.assignment_outlined,
              size: 55,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            Text(
              "No scores found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _emptyScoreMessage(),

              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xff194d26)),

              columnSpacing: 22,

              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),

              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),

              columns: [
                DataColumn(
                  label: Text(widget.scoreLeaders ? "Name" : "Staff Name"),
                ),
                if (widget.scoreLeaders) ...const [
                  DataColumn(label: Text("Role")),
                  DataColumn(label: Text("Department")),
                ],
                const DataColumn(label: Text("Communication")),
                const DataColumn(label: Text("Punctuality")),
                const DataColumn(label: Text("Integrity")),
                const DataColumn(label: Text("Total")),
              ],

              rows: scores.map((staff) {
                final total = totalScore(staff);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        staff["staffName"] ?? "-",

                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    if (widget.scoreLeaders) ...[
                      DataCell(Text("${staff["roleLabel"] ?? "-"}")),
                      DataCell(Text("${staff["department"] ?? "-"}")),
                    ],

                    DataCell(_scoreText(staff["communication"])),

                    // PUNCTUALITY
                    DataCell(_scoreText(staff["punctuality"])),

                    // INTEGRITY
                    DataCell(_scoreText(staff["integrity"])),

                    // TOTAL
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: total >= 12
                              ? Colors.green.shade50
                              : Colors.orange.shade50,

                          borderRadius: BorderRadius.circular(8),
                        ),

                        child: Text(
                          "$total / 15",

                          style: TextStyle(
                            fontWeight: FontWeight.bold,

                            color: total >= 12
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
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
    );
  }

  String _emptyScoreMessage() {
    if (widget.scoreLeaders && departmentFilter != "All") {
      return "No scores for $departmentFilter";
    }
    if (selectedMonth != null) {
      return "No behaviour scores for ${_monthName(selectedMonth!)}";
    }
    if (widget.scoreLeaders) {
      return "No scores for department managers or division heads";
    }
    return "No behaviour scores available";
  }

  Future<void> _openDepartmentFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  "Filter by department",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              _filterTile("All"),
              ...departments.map(_filterTile),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => departmentFilter = selected);
  }

  Widget _filterTile(String name) {
    final selected = departmentFilter == name ||
        (name != "All" &&
            DivisionConfig.isAllowedDepartment(departmentFilter, [name]));
    return ListTile(
      title: Text(name == "All" ? "All" : name),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xff194d26))
          : null,
      onTap: () => Navigator.pop(context, name),
    );
  }

  int? _readId(Map<String, dynamic> item) {
    for (final key in ["staffId", "StaffId", "userId", "UserId", "employeeId"]) {
      final value = int.tryParse("${item[key] ?? ""}");
      if (value != null && value > 0) return value;
    }
    return null;
  }

  String _readName(Map<String, dynamic> item) {
    for (final key in ["staffName", "StaffName", "name", "Name", "userName"]) {
      final value = (item[key] ?? "").toString().trim();
      if (value.isNotEmpty) return value;
    }
    return "";
  }

  UserModel? _findLeader(Map<String, dynamic> score, List<UserModel> users) {
    final id = _readId(score);
    if (id != null) {
      for (final user in users) {
        if (user.userId == id) return user;
      }
    }

    final name = _readName(score).toLowerCase();
    if (name.isEmpty) return null;
    for (final user in users) {
      if (user.name.trim().toLowerCase() == name) return user;
    }
    return null;
  }

  bool _isLeaderScore(Map<String, dynamic> score, List<UserModel> users) {
    if (users.isEmpty) return true;
    if (_findLeader(score, users) != null) return true;
    final role = (score["role"] ?? score["Role"] ?? score["roleName"] ?? "")
        .toString();
    return AppRoles.isScoreLeader(role);
  }

  Map<String, dynamic> _withLeaderDetails(
    Map<String, dynamic> score,
    List<UserModel> users,
  ) {
    final user = _findLeader(score, users);
    final role = user?.role ??
        (score["role"] ?? score["Role"] ?? score["roleName"] ?? "").toString();
    final department = user?.department ??
        (score["department"] ?? score["Department"] ?? "").toString();
    return {
      ...score,
      "staffName": _readName(score).isNotEmpty
          ? _readName(score)
          : (user?.name ?? "-"),
      "roleLabel": AppRoles.leaderLabel(role).isNotEmpty
          ? AppRoles.leaderLabel(role)
          : (role.isEmpty ? "-" : role),
      "department": department.trim().isEmpty ? "-" : department,
    };
  }

  Widget _scoreText(dynamic score) {
    return Text(
      "${score ?? 0} / 5",

      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
