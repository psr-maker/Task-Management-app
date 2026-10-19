import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

class UsersPageBar extends StatelessWidget {
  final List<String> departments;
  final String selectedDepartment;
  final ValueChanged<String>? onDepartmentChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onAdd;
  final String addLabel;
  final String listTitle;

  const UsersPageBar({
    super.key,
    required this.departments,
    required this.selectedDepartment,
    this.onDepartmentChanged,
    required this.searchController,
    required this.onSearchChanged,
    this.onAdd,
    this.addLabel = 'Add users',
    this.listTitle = 'Users',
  });

  @override
  Widget build(BuildContext context) {
    final options = departments
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    final selected = options.contains(selectedDepartment)
        ? selectedDepartment
        : (options.isEmpty ? selectedDepartment : options.first);
    final headingStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: WebTheme.inkOf(context),
      letterSpacing: -0.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onDepartmentChanged != null && options.length > 1)
          PopupMenuButton<String>(
            tooltip: 'Department',
            onSelected: onDepartmentChanged,
            itemBuilder: (context) => [
              for (final dept in options)
                PopupMenuItem(
                  value: dept,
                  child: Text(_departmentHeading(dept)),
                ),
            ],
            child: Text(_departmentHeading(selected), style: headingStyle),
          )
        else
          Text(_departmentHeading(selected), style: headingStyle),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: _fieldDecoration(context).copyWith(
                hintText: 'Search',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: WebTheme.mutedOf(context),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: WebTheme.mutedOf(context),
                ),
              ),
            );
            final add = onAdd == null
                ? null
                : FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(addLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: WebTheme.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
            if (add == null) return search;
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: add),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                add,
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          listTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: WebTheme.inkOf(context),
          ),
        ),
      ],
    );
  }

  String _departmentHeading(String name) {
    final text = name.trim();
    if (text.isEmpty || text.toLowerCase() == 'all') return 'All Departments';
    if (text.toLowerCase().contains('department')) return text;
    return '$text Department';
  }

  InputDecoration _fieldDecoration(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: WebTheme.surfaceOf(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: WebTheme.brand),
      ),
    );
  }
}
