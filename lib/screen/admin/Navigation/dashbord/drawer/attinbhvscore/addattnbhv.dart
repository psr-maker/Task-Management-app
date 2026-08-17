import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/services/admin_service.dart';

class AddBehaviourScore extends StatefulWidget {
  final String department;

  const AddBehaviourScore({
    super.key,
    required this.department,
  });

  @override
  State<AddBehaviourScore> createState() => _AddBehaviourScoreState();
}

class _AddBehaviourScoreState extends State<AddBehaviourScore> {
  int communication = 0;
  int punctuality = 0;
  int integrity = 0;

  int? selectedStaffId;
  String? selectedStaffName;

  DateTime selectedMonth = DateTime.now();

  List<UserModel> employees = [];

  bool isLoadingEmployees = true;
  bool isSubmitting = false;

  int get totalScore =>
      communication + punctuality + integrity;

  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      final result =
          await AdminService.getEmployeesByDepartment(
        widget.department,
      );

      if (!mounted) return;

      setState(() {
        employees = result;
        isLoadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingEmployees = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load employees: $e",
          ),
        ),
      );
    }
  }

  Future<void> selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(
          picked.year,
          picked.month,
          1,
        );
      });
    }
  }

  String get monthName {
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

    return "${months[selectedMonth.month]} "
        "${selectedMonth.year}";
  }

  Future<void> submitScore() async {
    if (selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a staff"),
        ),
      );
      return;
    }

    if (communication == 0 ||
        punctuality == 0 ||
        integrity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please give a score for all criteria",
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final success =
          await AdminService.addAttitudeBehaviourScore(
        staffId: selectedStaffId!,
        communication: communication,
        punctuality: punctuality,
        integrity: integrity,
        date: selectedMonth,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Behaviour score submitted successfully",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          selectedStaffId = null;
          selectedStaffName = null;
          communication = 0;
          punctuality = 0;
          integrity = 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to submit behaviour score",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        
        title: const Text(
          "Add Behaviour Score",
         
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ==========================
            // STAFF
            // ==========================

            const Text(
              "Select Staff",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),

              child: isLoadingEmployees
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedStaffId,
                        isExpanded: true,
                        hint: const Text(
                          "Select Staff",
                        ),

                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                        ),

                        items: employees.map((employee) {

                          return DropdownMenuItem<int>(
                            value: employee.userId,
                            child: Row(
                              children: [

                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      const Color(0xff194d26)
                                          .withOpacity(.1),

                                  child: const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Color(0xff194d26),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );

                        }).toList(),

                        onChanged: (value) {

                          if (value == null) return;

                          final employee =
                              employees.firstWhere(
                            (e) => e.userId == value,
                          );

                          setState(() {
                            selectedStaffId = value;
                            selectedStaffName =
                                employee.name;
                          });
                        },
                      ),
                    ),
            ),

        
            const SizedBox(height: 20),

            // ==========================
            // MONTH
            // ==========================

            const Text(
              "Score Month",
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: Row(
                  children: [

                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xff194d26),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================
            // COMMUNICATION
            // ==========================

            _scoreCard(
              title: "Communication",
              subtitle:
                  "Ability to communicate clearly and effectively",
              score: communication,
              onChanged: (value) {
                setState(() {
                  communication = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // ==========================
            // PUNCTUALITY
            // ==========================

            _scoreCard(
              title: "Punctuality & Discipline",
              subtitle:
                  "Attendance, punctuality and workplace discipline",
              score: punctuality,
              onChanged: (value) {
                setState(() {
                  punctuality = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // ==========================
            // INTEGRITY
            // ==========================

            _scoreCard(
              title: "Integrity",
              subtitle:
                  "Honesty, responsibility and ethical behaviour",
              score: integrity,
              onChanged: (value) {
                setState(() {
                  integrity = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // ==========================
            // TOTAL
            // ==========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xff194d26),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                children: [

                  const Text(
                    "Total Behaviour Score",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "$totalScore / 15",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==========================
            // SUBMIT
            // ==========================

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed:
                    isSubmitting ? null : submitScore,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff194d26),
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "SUBMIT SCORE",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard({
    required String title,
    required String subtitle,
    required int score,
    required Function(int) onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: List.generate(5, (index) {

              final value = index + 1;
              final selected = value <= score;

              return GestureDetector(
                onTap: () {
                  onChanged(value);
                },

                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 200),

                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xff194d26)
                        : Colors.grey.shade100,

                    shape: BoxShape.circle,

                    border: Border.all(
                      color: selected
                          ? const Color(0xff194d26)
                          : Colors.grey.shade300,
                    ),
                  ),

                  child: Center(
                    child: Text(
                      "$value",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,

                        color: selected
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Text(
                "Poor",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),

              Text(
                "Excellent",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}