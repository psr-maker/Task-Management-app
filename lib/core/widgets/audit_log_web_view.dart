import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/auditlog.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/list_download_button.dart';

class AuditWebEntry {
  final String when;
  final String actor;
  final String meta;
  final String action;
  final String title;
  final String changes;
  final Color color;
  final IconData icon;
  final bool highlighted;
  final VoidCallback? onTap;

  const AuditWebEntry({
    required this.when,
    required this.actor,
    required this.meta,
    required this.action,
    required this.title,
    required this.changes,
    required this.color,
    required this.icon,
    this.highlighted = false,
    this.onTap,
  });
}

Future<DateTimeRange?> pickCompactDateRange(
  BuildContext context, {
  DateTimeRange? initial,
}) {
  final now = DateTime.now();
  if (AppLayout.isMobile(context)) {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: initial,
    );
  }

  return showDialog<DateTimeRange>(
    context: context,
    builder: (dialogContext) {
      var start = initial?.start;
      var end = initial?.end;
      String label(DateTime? value) {
        if (value == null) return 'Select date';
        return '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/'
            '${value.year}';
      }

      return StatefulBuilder(
        builder: (context, setLocal) {
          Future<void> choose(bool isStart) async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 5),
              lastDate: now,
              initialDate: (isStart ? start : end) ?? now,
              builder: (context, child) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 520,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
            if (picked == null) return;
            setLocal(() {
              if (isStart) {
                start = picked;
              } else {
                end = picked;
              }
            });
          }

          return AlertDialog(
            title: const Text('Filter dates'),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_month, color: WebTheme.brandOf(context)),
                    title: const Text('From'),
                    subtitle: Text(
                      label(start),
                      style: TextStyle(color: WebTheme.inkOf(context)),
                    ),
                    onTap: () => choose(true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event, color: WebTheme.brandOf(context)),
                    title: const Text('To'),
                    subtitle: Text(
                      label(end),
                      style: TextStyle(color: WebTheme.inkOf(context)),
                    ),
                    onTap: () => choose(false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: WebTheme.brand,
                  foregroundColor: Colors.white,
                ),
                onPressed: start == null || end == null
                    ? null
                    : () {
                        var from = DateTime(
                          start!.year,
                          start!.month,
                          start!.day,
                        );
                        var to = DateTime(end!.year, end!.month, end!.day);
                        if (to.isBefore(from)) {
                          final swap = from;
                          from = to;
                          to = swap;
                        }
                        Navigator.pop(
                          dialogContext,
                          DateTimeRange(start: from, end: to),
                        );
                      },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

String auditWhenLabel(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute';
}

String auditChangeSummary(AuditLogGroupModel log) {
  final action = log.action.toLowerCase();
  if (action == 'delete') return 'Permanently deleted';
  if (action == 'login') return 'Signed in';
  if (action == 'logout') return 'Signed out';
  if (log.changes.isEmpty) return '';
  return log.changes.map((change) {
    final field = (change.fieldChanged ?? 'Field').trim();
    final from = (change.oldValue ?? '').trim();
    final to = (change.newValue ?? '').trim();
    if (from.isEmpty && to.isEmpty) return field;
    if (from.isEmpty) return '$field → $to';
    if (to.isEmpty) return '$field: $from';
    return '$field: $from → $to';
  }).join('   ·   ');
}

class AuditLogWebView extends StatefulWidget {
  final List<AuditWebEntry> entries;
  final DateTimeRange? selectedRange;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;
  final List<String> departments;
  final String? selectedDepartment;
  final bool Function(String department)? departmentSelected;
  final ValueChanged<String>? onDepartment;

  const AuditLogWebView({
    super.key,
    required this.entries,
    required this.selectedRange,
    required this.onPickRange,
    required this.onClearRange,
    this.departments = const [],
    this.selectedDepartment,
    this.departmentSelected,
    this.onDepartment,
  });

  @override
  State<AuditLogWebView> createState() => _AuditLogWebViewState();
}

class _AuditLogWebViewState extends State<AuditLogWebView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AuditWebEntry> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.entries;
    return widget.entries.where((entry) {
      final haystack = [
        entry.when,
        entry.actor,
        entry.meta,
        entry.action,
        entry.title,
        entry.changes,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  String get _rangeLabel {
    final range = widget.selectedRange;
    if (range == null) return 'All dates';
    String day(DateTime value) =>
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    return '${day(range.start)} – ${day(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visible;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );

    return Padding(
      padding: AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: WebTheme.inkOf(context)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Log',
                      style: TextStyle(
                        fontSize: AppLayout.isDesktop(context) ? 22 : 18,
                        fontWeight: FontWeight.w700,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                    Text(
                      '${entries.length} records',
                      style: TextStyle(
                        fontSize: 13,
                        color: WebTheme.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              ListDownloadButton(
                title: 'Audit log',
                headers: const [
                  'When',
                  'User',
                  'Role / Department',
                  'Action',
                  'Item',
                  'Changes',
                ],
                rows: () => [
                  for (final entry in _visible)
                    [
                      entry.when,
                      entry.actor,
                      entry.meta,
                      entry.action,
                      entry.title,
                      entry.changes,
                    ],
                ],
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.onPickRange,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(_rangeLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WebTheme.brandOf(context),
                  side: BorderSide(color: WebTheme.brandOf(context)),
                ),
              ),
              if (widget.selectedRange != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onClearRange,
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search user, action, item, or change',
              hintStyle: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
              prefixIcon: Icon(Icons.search, size: 18, color: WebTheme.mutedOf(context)),
              filled: true,
              fillColor: WebTheme.surfaceOf(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: WebTheme.brand),
              ),
            ),
          ),
          if (widget.departments.length > 1) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final dept in widget.departments)
                  _deptChip(dept),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'No audit logs found',
                      style: TextStyle(
                        color: WebTheme.mutedOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: WebTheme.surfaceOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WebTheme.lineOf(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AppLayout.isDesktop(context)
                        ? _table(entries)
                        : _cards(entries),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _deptChip(String dept) {
    final selected = widget.departmentSelected != null
        ? widget.departmentSelected!(dept)
        : widget.selectedDepartment == dept;
    final label = dept == 'All' ? 'All' : dept.replaceAll(' Department', '');
    return Material(
      color: selected ? WebTheme.brand : WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onDepartment?.call(dept),
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
              color: selected ? Colors.white : WebTheme.brandOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _table(List<AuditWebEntry> entries) {
    return Column(
      children: [
        Container(
          color: WebTheme.brandSoftOf(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Row(
            children: [
              Expanded(flex: 2, child: _Head('When')),
              Expanded(flex: 3, child: _Head('User')),
              Expanded(flex: 2, child: _Head('Action')),
              Expanded(flex: 3, child: _Head('Item')),
              Expanded(flex: 4, child: _Head('Changes')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: WebTheme.lineOf(context)),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Material(
                color: entry.highlighted
                    ? WebTheme.brandSoftOf(context)
                    : Colors.transparent,
                child: InkWell(
                  onTap: entry.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _cell(entry.when)),
                        Expanded(
                          flex: 3,
                          child: _cell(entry.actor, sub: entry.meta),
                        ),
                        Expanded(flex: 2, child: _action(entry)),
                        Expanded(flex: 3, child: _cell(entry.title)),
                        Expanded(flex: 4, child: _cell(entry.changes, muted: true)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cards(List<AuditWebEntry> entries) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Material(
          color: entry.highlighted
              ? WebTheme.brandSoftOf(context)
              : WebTheme.canvasOf(context),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: entry.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _action(entry),
                      const Spacer(),
                      Text(
                        entry.when,
                        style: TextStyle(
                          fontSize: 12,
                          color: WebTheme.mutedOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.title,
                    style: TextStyle(
                      color: WebTheme.inkOf(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.actor,
                    style: TextStyle(
                      color: WebTheme.inkOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.meta.isNotEmpty)
                    Text(
                      entry.meta,
                      style: TextStyle(
                        color: WebTheme.mutedOf(context),
                        fontSize: 12,
                      ),
                    ),
                  if (entry.changes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.changes,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebTheme.mutedOf(context),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _action(AuditWebEntry entry) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(entry.icon, size: 14, color: entry.color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                entry.action,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: entry.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {String? sub, bool muted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.isEmpty ? '—' : text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: muted ? WebTheme.mutedOf(context) : WebTheme.inkOf(context),
            fontSize: 13,
            fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
            height: 1.3,
          ),
        ),
        if (sub != null && sub.isNotEmpty)
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 12),
          ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  final String label;

  const _Head(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: WebTheme.brandOf(context),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
