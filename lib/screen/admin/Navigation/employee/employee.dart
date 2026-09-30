import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class Employeelist extends StatefulWidget {
  final bool showAppBar;
  final bool openReports;

  const Employeelist({
    super.key,
    this.showAppBar = false,
    this.openReports = false,
  });

  @override
  State<Employeelist> createState() => _EmployeelistState();
}

class _EmployeelistState extends State<Employeelist>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String department = "";
  bool isLoading = true;
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAdminDepartment();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  final List<String> tabs = ["Staff", "Staff Goals"];
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (!widget.showAppBar) {
        return const Center(child: RotatingFlower(size: 30));
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(department.isEmpty ? 'Staff' : department),
        ),
        body: const Center(child: RotatingFlower(size: 30)),
      );
    }
    final showBar = AppLayout.isMobile(context) || widget.showAppBar;
    return Scaffold(
      appBar: showBar
          ? AppBar(
              title: widget.openReports && _searching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        hintText: "Search staff",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    )
                  : Text(department.isEmpty ? 'Staff' : department),
              actions: widget.openReports
                  ? [
                      IconButton(
                        icon: Icon(_searching ? Icons.close : Icons.search),
                        onPressed: () {
                          setState(() {
                            _searching = !_searching;
                            if (!_searching) _searchController.clear();
                          });
                        },
                      ),
                    ]
                  : null,
            )
          : null,
      body: EmployeeList(
        department: department,
        searchQuery: _searchController.text,
        openReports: widget.openReports,
      ),
      // TabBarView(
      //   controller: _tabController,
      //   children: [
      //     EmployeeList(department: department, searchQuery: ''),
      //     Empgoals(department: department),
          
      //   ],
      // ),
    );
  }
}
