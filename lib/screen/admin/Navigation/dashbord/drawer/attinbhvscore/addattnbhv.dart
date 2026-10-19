import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class AddBehaviourScore extends StatefulWidget {
  final String department;
  final bool scoreLeaders;

  const AddBehaviourScore({
    super.key,
    required this.department,
    this.scoreLeaders = false,
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
  bool scoreDivisionManagers = false;

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
    final token = await AuthService.getToken();
    final role = token == null ? "" : (JwtHelper.getRole(token) ?? "");
    final forDivisionHead =
        !widget.scoreLeaders && AppRoles.isDivisionHead(role);

    try {
      final List<UserModel> result;
      if (widget.scoreLeaders) {
        final users = await SuperAdminService.getAllUsers();
        result = users.where((user) {
          if (!AppRoles.isScoreLeader(user.role)) return false;
          return user.status.trim().toLowerCase() != "inactive";
        }).toList()
          ..sort((a, b) {
            final roleCompare = AppRoles.leaderLabel(
              a.role,
            ).compareTo(AppRoles.leaderLabel(b.role));
            if (roleCompare != 0) return roleCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
      } else if (forDivisionHead) {
        result = await AdminService.managersUnderDivisionHead(
          ownDepartment: widget.department,
        );
      } else {
        result = await AdminService.getEmployeesByDepartment(
          widget.department,
        );
      }

      if (!mounted) return;

      setState(() {
        scoreDivisionManagers = forDivisionHead;
        employees = result;
        isLoadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingEmployees = false;
      });

      showAppMessage(
        context,
        widget.scoreLeaders
            ? "Failed to load managers and division heads: $e"
            : forDivisionHead
            ? "Failed to load managers: $e"
            : "Failed to load employees: $e",
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
      showTopMessage(
        widget.scoreLeaders
            ? "Please select a department manager or division head"
            : scoreDivisionManagers
            ? "Please select a manager"
            : "Please select a staff",
        isError: true,
      );
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
        asDirector: widget.scoreLeaders,
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

  String get _personLabel {
    if (widget.scoreLeaders) return 'Manager or division head';
    if (scoreDivisionManagers) return 'Manager';
    return 'Staff';
  }

  @override
  Widget build(BuildContext context) {
    final web = WebPushedChrome.isWeb(context);
    return Scaffold(
      backgroundColor: web
          ? WebTheme.canvasOf(context)
          : WebPushedChrome.background(context),
      appBar: web
          ? null
          : AppBar(
              title: const Text('Add Behaviour Score'),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
              ),
            ),
      body: WebFormPage.adapt(
        context,
        title: 'Add behaviour score',
        subtitle: 'Rate communication, punctuality, and integrity',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final scores = [
              _scoreCard(
                title: 'Communication',
                subtitle: 'Clarity, responsiveness, and on-time communication',
                score: communication,
                onChanged: (value) => setState(() => communication = value),
              ),
              _scoreCard(
                title: 'Punctuality & Discipline',
                subtitle: 'Attendance, punctuality, and workplace discipline',
                score: punctuality,
                onChanged: (value) => setState(() => punctuality = value),
              ),
              _scoreCard(
                title: 'Ethics',
                subtitle: 'Honesty, responsibility, and ethical behaviour',
                score: integrity,
                onChanged: (value) => setState(() => integrity = value),
              ),
            ];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _personPicker()),
                            const SizedBox(width: 16),
                            Expanded(child: _monthPicker()),
                          ],
                        )
                      else ...[
                        _personPicker(),
                        const SizedBox(height: 16),
                        _monthPicker(),
                      ],
                      const SizedBox(height: 20),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < scores.length; i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              Expanded(child: scores[i]),
                            ],
                          ],
                        )
                      else
                        for (final card in scores) ...[
                          card,
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: WebTheme.brand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total behaviour score',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '$totalScore / 15',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppButton(
                          text: 'Submit',
                          isLoading: isSubmitting,
                          onPressed: isSubmitting ? null : submitScore,
                          color: WebTheme.brand,
                          txtcolor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                  if (_topMessage != null)
                    AnimatedPositioned(
                      top: _showTopMessage ? 8 : -120,
                      left: 0,
                      right: 0,
                      duration: const Duration(milliseconds: 300),
                      child: Msgsnackbar(
                        context,
                        message: _topMessage!,
                        isError: _isErrorMessage,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: WebTheme.mutedOf(context),
        ),
      ),
    );
  }

  Widget _personPicker() {
    final ink = WebTheme.inkOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(_personLabel),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: WebTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: isLoadingEmployees
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    menuMaxHeight: 360,
                    value: employees.any(
                      (employee) => employee.userId == selectedStaffId,
                    )
                        ? selectedStaffId
                        : null,
                    isExpanded: true,
                    hint: Text('Select $_personLabel'),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: WebTheme.mutedOf(context),
                    ),
                    items: employees.map((employee) {
                      final roleLabel = AppRoles.leaderLabel(employee.role);
                      final subtitle = [
                        if (roleLabel.isNotEmpty) roleLabel,
                        if (employee.department.trim().isNotEmpty)
                          employee.department.trim(),
                      ].join(' · ');
                      return DropdownMenuItem<int>(
                        value: employee.userId,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WebTheme.mutedOf(context),
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
      ],
    );
  }

  Widget _monthPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Score month'),
        InkWell(
          onTap: selectMonth,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: WebTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WebTheme.lineOf(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: WebTheme.brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: WebTheme.inkOf(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: WebTheme.mutedOf(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreCard({
    required String title,
    required String subtitle,
    required int score,
    required Function(int) onChanged,
    List<String> details = const [],
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: WebTheme.inkOf(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),

          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...details.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 6, color: Color(0xff194d26)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= score;
              return InkWell(
                onTap: () => onChanged(value),
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? WebTheme.brand
                        : WebTheme.canvasOf(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? WebTheme.brand
                          : WebTheme.lineOf(context),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : WebTheme.mutedOf(context),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poor',
                style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
              ),
              Text(
                '$score / 5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: WebTheme.brand,
                ),
              ),
              Text(
                'Excellent',
                style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
