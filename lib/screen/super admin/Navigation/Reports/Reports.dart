import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/dahboard.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/dptlist.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/users/emplist.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String view = 'Department';

  void _pick(String value) {
    setState(() => view = value);
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !AppLayout.isMobile(context);
    if (isWeb) {
      bindWebHeader(context, menuItems: directorShellMenu(context));
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isWeb ? WebTheme.canvasOf(context) : null,
      drawer: isWeb
          ? null
          : AppMenuDrawer(
              title: 'Super Admin',
              subtitle: 'Admin Panel',
              icon: Icons.admin_panel_settings_rounded,
              items: directorShellMenu(context),
            ),
      endDrawer: _filterDrawer(context),
      appBar: isWeb
          ? null
          : AppBar(
              title: const Text('Reports'),
              actions: [
                IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  icon: Icon(Icons.filter_list, color: WebTheme.brand),
                ),
              ],
            ),
      body: Padding(
        padding: isWeb ? AppLayout.pagePadding(context) : const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWeb) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: AppLayout.isDesktop(context) ? 22 : 18,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filter',
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                    icon: Icon(Icons.filter_list, color: WebTheme.brand),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                view == 'Department'
                    ? 'Open a department to see its dashboard'
                    : 'Open a user to see their staff dashboard',
                style: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
              ),
              const SizedBox(height: 14),
            ],
            _viewSwitch(context),
            const SizedBox(height: 14),
            Expanded(
              child: view == 'Department'
                  ? const DepartmentListPage()
                  : const EmployeeReportsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewSwitch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Row(
        children: [
          for (final option in const ['Department', 'Users'])
            Expanded(
              child: _switchButton(
                context,
                label: option == 'Department' ? 'Departments' : 'Users',
                icon: option == 'Department'
                    ? Icons.apartment_rounded
                    : Icons.people_alt_rounded,
                selected: view == option,
                onTap: () => _pick(option),
              ),
            ),
        ],
      ),
    );
  }

  Widget _switchButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? WebTheme.brand : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : WebTheme.mutedOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : WebTheme.inkOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: WebTheme.surfaceOf(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            for (final option in const ['Department', 'Users'])
              ListTile(
                leading: Icon(
                  view == option
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: WebTheme.brand,
                ),
                title: Text(option == 'Department' ? 'Department list' : 'Users list'),
                selected: view == option,
                onTap: () => _pick(option),
              ),
          ],
        ),
      ),
    );
  }
}
