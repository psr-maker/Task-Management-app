import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class FiveSpoints extends StatefulWidget {
  const FiveSpoints({super.key});

  @override
  State<FiveSpoints> createState() => _FiveSpointsState();
}

class _FiveSpointsState extends State<FiveSpoints> {
  List<String> allDepartments = [];
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  bool _isLoading = false;
  String? selectedDept;
  UserModel? selectedUser;

  int selectedMonth = DateTime.now().month;
  int selectedWeek = _getCurrentWeek();
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  final TextEditingController pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  static int _getCurrentWeek() {
    final day = DateTime.now().day;
    return ((day - 1) ~/ 7) + 1;
  }

  Future<void> loadData() async {
    final depts = await ReportsService.getAllDepartments();
    final users = await SuperAdminService.getAllUsers();

    setState(() {
      allDepartments = depts;
      allUsers = users;
    });
  }

  void filterUsers(String dept) {
    final users = allUsers.where((u) => u.department == dept).toList();

    setState(() {
      selectedDept = dept;
      filteredUsers = users;
      selectedUser = null;
    });
  }

  void _savePoints() async {
    if (selectedUser == null || selectedDept == null) return;

    final success = await AdminService.saveFiveSPoints(
      staffId: selectedUser!.userId,
      dept: selectedDept!,
      month: selectedMonth,
      week: selectedWeek,
      points: int.tryParse(pointsController.text) ?? 0,
    );

    if (success) {
      showTopMessage("Points saved successfully", isError: false);
    } else {
      showTopMessage("Failed to save points", isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("5S Points"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weekly 5S Entry",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Fill details to record staff 5S performance...⭐",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 25),

                  _label("Department"),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    dropdownColor: Colors.white,
                    style: Theme.of(context).textTheme.headlineSmall,
                    items: allDepartments.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(
                          d,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => filterUsers(val!),
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 15),

                  _label("Staff"),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserModel>(
                    value: selectedUser,
                    dropdownColor: Colors.white,
                    style: Theme.of(context).textTheme.headlineSmall,
                    items: filteredUsers.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(
                          u.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedUser = val),
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("Month"),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<int>(
                              value: selectedMonth,
                              style: Theme.of(context).textTheme.headlineSmall,
                              items: List.generate(12, (i) => i + 1)
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        _monthName(m),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedMonth = val!),
                              decoration: _inputDecoration(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label("Week"),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<int>(
                              value: selectedWeek,
                              style: Theme.of(context).textTheme.headlineSmall,
                              items: List.generate(5, (i) => i + 1)
                                  .map(
                                    (w) => DropdownMenuItem(
                                      value: w,
                                      child: Text(
                                        "Week $w",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedWeek = val!),
                              decoration: _inputDecoration(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  _label("5S Points"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(hint: "Enter points"),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: AppButton(
                      text: "Save",
                      isLoading: _isLoading,
                      onPressed: _savePoints,
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
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
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: Theme.of(context).textTheme.headlineLarge);
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.headlineSmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  String _monthName(int m) {
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
    return months[m - 1];
  }
}
