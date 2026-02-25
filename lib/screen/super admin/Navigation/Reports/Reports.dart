import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/dptlist.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/users/emplist.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = ["Department", "Manager", "Employee"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
           labelColor: Colors.white,
          labelStyle:Theme.of(context).textTheme.labelLarge ,
          unselectedLabelStyle: TextStyle(color:Colors.grey),
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
      ),
    body: TabBarView(
  controller: _tabController,
  children: const [
    DepartmentListPage(),         
    EmployeeReportsList(role: 'Manager',),
    EmployeeReportsList(role: 'Staff',),
  ],
),
    );
  }
}