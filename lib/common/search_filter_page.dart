import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

class TaskFilterDropdown extends StatelessWidget {
  final TaskFilterModel filter;
  final List<String> departments;
  // final List<String> users;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const TaskFilterDropdown({
    super.key,
    required this.filter,
    required this.departments,
    // required this.users,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.onPrimary,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _statusDropdown(context),
            _priorityDropdown(context),
            _departmentDropdown(context),

            //  _assignedDropdown(context),
            const SizedBox(height: 14),
            Row(
              children: [
                AppButton(
                  text: 'Clear',
                  onPressed: onClear,
                  color: Theme.of(context).colorScheme.secondary,
                  txtcolor: Colors.white
                ),
                const Spacer(),
                AppButton(
                  text: 'Apply',
                  onPressed: onApply,
                  color: Theme.of(context).colorScheme.secondary,
                  txtcolor: Colors.white
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ... keep _statusDropdown, _priorityDropdown, _normalDropdown methods
  Widget _departmentDropdown(BuildContext context) {
    return _styledDropdown(
      label: "Department",
      value: filter.department,
      items: departments,
      onChanged: (v) => filter.department = v,
      itemBuilder: (e) =>
          Text(e, style: Theme.of(context).textTheme.titleSmall),
      context: context,
    );
  }

  // ---------------- STATUS ----------------
  Widget _statusDropdown(BuildContext context) {
    return _styledDropdown(
      label: "Status",
      value: filter.status,
      items: droptaskutils.getAllStatuses(),
      onChanged: (v) => filter.status = v,
      itemBuilder: (e) => _statusChip(context, e),
      selectedBuilder: (e) => _statusChip(context, e),
      context: context,
    );
  }

  Widget _statusChip(BuildContext context, String e) {
    final statusEnum = TaskUtils.parseStatus(e);
    final color = TaskUtils.getStatusColor(statusEnum);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        droptaskutils.getStatusDisplayName(e),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  // ---------------- PRIORITY ----------------

  Widget _priorityDropdown(BuildContext context) {
    return _styledDropdown(
      label: "Priority",
      value: filter.priority,
      items: droptaskutils.getAllPriorities(),
      onChanged: (v) => filter.priority = v,
      itemBuilder: (e) => _priorityChip(context, e),
      selectedBuilder: (e) => _priorityChip(context, e),
      context: context,
    );
  }

  Widget _priorityChip(BuildContext context, String e) {
    final color = TaskUtils.getPriorityColor(e);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        droptaskutils.getPriorityDisplayName(e),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------- COLORED DROPDOWN ----------------
  Widget _styledDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Widget Function(String) itemBuilder,
    Widget Function(String)? selectedBuilder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String?>(
        value: value,

        dropdownColor: Theme.of(context).colorScheme.onPrimary,

        style: Theme.of(context).textTheme.titleSmall,

        decoration: InputDecoration(
          labelText: label,

          labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),

          filled: true,
          fillColor: isDark
              ? Theme.of(context).colorScheme.background
              : Theme.of(context).colorScheme.onPrimary,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1.4,
            ),
          ),
        ),

        iconEnabledColor: Theme.of(context).colorScheme.secondary,

        isExpanded: true,

        items: [
          DropdownMenuItem(
            value: null,
            child: Text(
              "All",
             style: Theme.of(context).textTheme.titleSmall
            ),
          ),

          ...items.map(
            (e) => DropdownMenuItem(value: e, child: itemBuilder(e)),
          ),
        ],

        selectedItemBuilder: selectedBuilder != null
            ? (context) => [
                Text("All", style: Theme.of(context).textTheme.headlineSmall),
                ...items.map((e) => selectedBuilder(e)),
              ]
            : null,

        onChanged: onChanged,
      ),
    );
  }
}
