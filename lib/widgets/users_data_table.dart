import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/status_badge.dart';

class UsersDataTable extends StatelessWidget {
  final List<UserModel> users;
  final Set<int> selectedIds;
  final bool selectionMode;
  final bool shrinkWrap;
  final ValueChanged<UserModel> onTap;
  final ValueChanged<UserModel> onToggle;
  final String Function(UserModel)? roleLabel;

  const UsersDataTable({
    super.key,
    required this.users,
    required this.selectedIds,
    required this.selectionMode,
    this.shrinkWrap = false,
    required this.onTap,
    required this.onToggle,
    this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final headingStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: WebTheme.brand,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: WebTheme.inkOf(context),
    );
    final nameStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: WebTheme.inkOf(context),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _scroll(
          shrinkWrap: shrinkWrap,
          child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width - 280,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  WebTheme.brandSoftOf(context),
                ),
                headingTextStyle: headingStyle,
                dataTextStyle: cellStyle,
                headingRowHeight: 40,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 44,
                columnSpacing: 22,
                horizontalMargin: 16,
                columns: [
                  if (selectionMode) const DataColumn(label: Text('')),
                  DataColumn(label: Text('Name', style: headingStyle)),
                  DataColumn(label: Text('Email', style: headingStyle)),
                  DataColumn(label: Text('Department', style: headingStyle)),
                  DataColumn(label: Text('Role', style: headingStyle)),
                  DataColumn(label: Text('Status', style: headingStyle)),
                ],
                rows: [
                  for (final user in users)
                    DataRow(
                      selected: selectedIds.contains(user.userId),
                      onSelectChanged: selectionMode
                          ? (_) => onToggle(user)
                          : null,
                      cells: [
                        if (selectionMode)
                          DataCell(
                            Checkbox(
                              value: selectedIds.contains(user.userId),
                              onChanged: (_) => onToggle(user),
                            ),
                          ),
                        DataCell(
                          Text(user.name, style: nameStyle),
                          onTap: () => onTap(user),
                        ),
                        DataCell(
                          Text(user.email, style: cellStyle),
                          onTap: () => onTap(user),
                        ),
                        DataCell(
                          Text(user.department, style: cellStyle),
                          onTap: () => onTap(user),
                        ),
                        DataCell(
                          Text(
                            roleLabel?.call(user) ?? user.role,
                            style: cellStyle,
                          ),
                          onTap: () => onTap(user),
                        ),
                        DataCell(
                          StatusBadge(
                            user.status.isEmpty ? 'Unknown' : user.status,
                          ),
                          onTap: () => onTap(user),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _scroll({required bool shrinkWrap, required Widget child}) {
    final horizontal = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
    if (shrinkWrap) return horizontal;
    return SingleChildScrollView(child: horizontal);
  }
}
