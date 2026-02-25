import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emptasklist.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class Employeelist extends StatefulWidget {
  const Employeelist({super.key});

  @override
  State<Employeelist> createState() => _EmployeelistState();
}

class _EmployeelistState extends State<Employeelist>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedRole = "Staff";
  String department = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAdminDepartment();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<int> getAdminIdFromToken() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final decodedToken = JwtDecoder.decode(token);

    return int.parse(decodedToken['UserId'].toString());
  }

  Future<void> loadAdminDepartment() async {
    try {
      final adminId = await getAdminIdFromToken();
      final adminDetails = await SuperAdminService.getAdminDetails(adminId);

      if (!mounted) return;

      setState(() {
        department = adminDetails.department;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      isLoading = false;
    }
  }

  final List<String> tabs = ["Staff", "Staff Task"];
  @override
  Widget build(BuildContext context) {
    if (isLoading || department == null) {
      return const Center(child: RotatingFlower(size: 30));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(department),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          labelStyle: Theme.of(context).textTheme.labelLarge,
          unselectedLabelStyle: TextStyle(color: Colors.grey),
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EmployeeList(department: department, searchQuery: ''),

          Emptasklist(department: department),
        ],
      ),
    );
  }
}
