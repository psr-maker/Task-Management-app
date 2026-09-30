import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/dptlist.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/users/emplist.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = ["Departments", "Users"];

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
    final isWeb = !AppLayout.isMobile(context);
    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              title: const Text("Reports"),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.onPrimary,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                labelStyle: Theme.of(context).textTheme.labelLarge,
                unselectedLabelStyle: const TextStyle(color: Colors.grey),
                tabs: tabs.map((e) => Tab(text: e)).toList(),
              ),
            ),
      body: Padding(
        padding: isWeb ? AppLayout.pagePadding(context) : EdgeInsets.zero,
        child: Column(
          children: [
            if (isWeb) ...[
              const WebPageHeader(
                title: 'Reports',
                subtitle: 'Department and people performance',
              ),
              const SizedBox(height: 8),
              WebPillTabs(
                controller: _tabController,
                tabs: tabs.map((e) => Tab(text: e)).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  DepartmentListPage(),
                  EmployeeReportsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
