import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/worklog_date_picker.dart';
import 'package:staff_work_track/core/widgets/worklog_session_tile.dart';

class WorklogWebBoard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool loading;
  final List logs;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDate;
  final List<String> departments;
  final String selectedDepartment;
  final ValueChanged<String>? onDepartment;

  const WorklogWebBoard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.logs,
    required this.searchController,
    required this.onSearch,
    required this.selectedDate,
    required this.onDate,
    this.departments = const [],
    this.selectedDepartment = 'All',
    this.onDepartment,
  });

  @override
  Widget build(BuildContext context) {
    final open = logs.where((log) {
      final image = (log['outImageUrl'] ?? '').toString();
      final time = (log['outTime'] ?? '').toString();
      return image.isEmpty && time.isEmpty;
    }).length;

    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back, color: WebTheme.inkOf(context)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: WebTheme.inkOf(context),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: WebTheme.mutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stat(context, 'Sessions', '${logs.length}', Icons.fact_check_outlined),
                const SizedBox(width: 10),
                _stat(context, 'Still checked in', '$open', Icons.login_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: WebTheme.card(context),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _toolbar(context),
                    Divider(height: 1, color: WebTheme.lineOf(context)),
                    Expanded(child: _body(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WebTheme.lineOf(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: WebTheme.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: WebTheme.brand),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.inkOf(context),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.mutedOf(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search name or title',
                    hintStyle: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
                    prefixIcon: Icon(Icons.search, size: 18, color: WebTheme.mutedOf(context)),
                    filled: true,
                    fillColor: WebTheme.canvasOf(context),
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border.copyWith(
                      borderSide: BorderSide(color: WebTheme.brand),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              WorklogDateButton(date: selectedDate, onChanged: onDate),
            ],
          ),
          if (departments.length > 1) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final department in departments) ...[
                      _chip(context, department),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String department) {
    final selected = selectedDepartment == department;
    final label = department == 'All'
        ? 'All'
        : department.replaceAll(' Department', '');
    return Material(
      color: selected ? WebTheme.brand : WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onDepartment?.call(department),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? WebTheme.brand : WebTheme.lineOf(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : WebTheme.inkOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (loading) return const Center(child: RotatingFlower());
    if (logs.isEmpty) {
      return const AppEmptyState(
        icon: Icons.fact_check_outlined,
        title: 'No worklogs',
        message: 'Sessions that match this search will show here.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (var i = 0; i < logs.length; i += columns)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: 12),
                      Expanded(
                        child: i + column < logs.length
                            ? WorklogSessionTile(log: logs[i + column])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
