import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/addattnbhv.dart';
import 'package:staff_work_track/services/admin_service.dart';

class BehaviourScoreDisplay extends StatefulWidget {
  final String Dept;

  const BehaviourScoreDisplay({super.key, required this.Dept});

  @override
  State<BehaviourScoreDisplay> createState() => _BehaviourScoreDisplayState();
}

class _BehaviourScoreDisplayState extends State<BehaviourScoreDisplay> {
  int? selectedMonth;

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
    if (selectedMonth == null) {
      return allStaffScores;
    }

    return allStaffScores.where((staff) {
      final dateValue = staff["date"];

      if (dateValue == null) {
        return false;
      }

      final date = DateTime.tryParse(dateValue.toString());

      if (date == null) {
        return false;
      }

      return date.month == selectedMonth;
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
          IconButton(
            tooltip: "Add Score",

            onPressed: () async {
              await Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (_) => AddBehaviourScore(department: widget.Dept),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),

            const SizedBox(height: 10),

            const Text(
              "Failed to load scores",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadScores,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff194d26),
                foregroundColor: Colors.white,
              ),

              child: const Text("Retry"),
            ),
          ],
        ),
      );
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
              selectedMonth == null
                  ? "No behaviour scores available"
                  : "No behaviour scores for "
                        "${_monthName(selectedMonth!)}",

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

              columns: const [
                DataColumn(label: Text("Staff Name")),

                DataColumn(label: Text("Communication")),

                DataColumn(label: Text("Punctuality")),

                DataColumn(label: Text("Integrity")),

                DataColumn(label: Text("Total")),
              ],

              rows: scores.map((staff) {
                final total = totalScore(staff);

                return DataRow(
                  cells: [
                    // STAFF
                    DataCell(
                      Text(
                        staff["staffName"] ?? "-",

                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    // COMMUNICATION
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

  Widget _scoreText(dynamic score) {
    return Text(
      "${score ?? 0} / 5",

      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
