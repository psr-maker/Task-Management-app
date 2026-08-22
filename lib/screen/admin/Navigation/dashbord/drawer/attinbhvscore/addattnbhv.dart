import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';

class AddBehaviourScore extends StatefulWidget {
  final String department;

  const AddBehaviourScore({super.key, required this.department});

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

  int get totalScore => communication + punctuality + integrity;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      final result = await AdminService.getEmployeesByDepartment(
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load employees: $e")));
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
        selectedMonth = DateTime(picked.year, picked.month, 1);
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

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTopMessage = false;
      });
    });
  }

  Future<void> submitScore() async {
    if (selectedStaffId == null) {
      showTopMessage("Please select a staff", isError: true);
      return;
    }

    if (communication == 0 || punctuality == 0 || integrity == 0) {
      showTopMessage("Please give a score for all criteria", isError: true);
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final success = await AdminService.addAttitudeBehaviourScore(
        staffId: selectedStaffId!,
        communication: communication,
        punctuality: punctuality,
        integrity: integrity,
        date: selectedMonth,
      );

      if (!mounted) return;

      if (success) {
        showTopMessage(
          "Behaviour score submitted successfully",
          isError: false,
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
        showTopMessage("Failed to submit behaviour score", isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      showTopMessage("Error: $e", isError: true);
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
        title: const Text("Add Behaviour Score"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),

                  child: isLoadingEmployees
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedStaffId,
                            isExpanded: true,
                            hint: const Text("Select Staff"),

                            icon: const Icon(Icons.keyboard_arrow_down),

                            items: employees.map((employee) {
                              return DropdownMenuItem<int>(
                                value: employee.userId,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(
                                        0xff194d26,
                                      ).withOpacity(.1),

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
                                        fontWeight: FontWeight.w600,
                                        color: Color.fromARGB(255, 25, 77, 38),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            onChanged: (value) {
                              if (value == null) return;

                              final employee = employees.firstWhere(
                                (e) => e.userId == value,
                              );

                              setState(() {
                                selectedStaffId = value;
                                selectedStaffName = employee.name;
                              });
                            },
                          ),
                        ),
                ),

                const SizedBox(height: 20),

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
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
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

                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _scoreCard(
                  title: "Communication",
                  subtitle: "Ability to communicate clearly and effectively",
                  score: communication,
                  onChanged: (value) {
                    setState(() {
                      communication = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                _scoreCard(
                  title: "Punctuality & Discipline",
                  subtitle: "Attendance, punctuality and workplace discipline",
                  score: punctuality,
                  onChanged: (value) {
                    setState(() {
                      punctuality = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                _scoreCard(
                  title: "Ethics",
                  subtitle: "Honesty, responsibility and ethical behaviour",
                  score: integrity,
                  onChanged: (value) {
                    setState(() {
                      integrity = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

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
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "$totalScore / 15",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                Center(
                  child: AppButton(
                    text: "Submit",
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : submitScore,
                    color: const Color(0xff194d26),
                    txtcolor: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
            if (_topMessage != null)
              AnimatedPositioned(
                top: _showTopMessage ? 20 : -120,
                left: 16,
                right: 16,
                duration: const Duration(milliseconds: 300),
                child: Msgsnackbar(
                  context,
                  message: _topMessage!,
                  isError: _isErrorMessage,
                ),
              ),
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
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= score;

              return GestureDetector(
                onTap: () {
                  onChanged(value);
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),

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
                        fontWeight: FontWeight.bold,

                        color: selected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text("Poor", style: TextStyle(fontSize: 11, color: Colors.grey)),

              Text(
                "Excellent",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
