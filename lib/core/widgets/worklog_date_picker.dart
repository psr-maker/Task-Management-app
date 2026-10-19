import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class WorklogDateSelection {
  final DateTime? date;

  const WorklogDateSelection(this.date);
}

Future<WorklogDateSelection?> showWorklogDatePicker(
  BuildContext context, {
  DateTime? selected,
}) {
  final picker = _WorklogDatePicker(selected: selected);
  if (AppLayout.isMobile(context)) {
    return showModalBottomSheet<WorklogDateSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WebTheme.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => picker,
    );
  }
  return showDialog<WorklogDateSelection>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: WebTheme.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: picker,
        ),
      );
    },
  );
}

class WorklogDateButton extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  const WorklogDateButton({
    super.key,
    required this.date,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showWorklogDatePicker(context, selected: date);
    if (picked == null) return;
    onChanged(picked.date);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = date != null;
    final label = chosen ? TimeUtils.formatDate(date!) : 'Any date';
    final borderColor = chosen ? WebTheme.brand : WebTheme.lineOf(context);
    return Material(
      color: chosen
          ? WebTheme.brand.withValues(alpha: 0.1)
          : WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _open(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: chosen ? WebTheme.brand : WebTheme.mutedOf(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: chosen ? WebTheme.brand : WebTheme.inkOf(context),
                      ),
                    ),
                    if (!chosen) ...[
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more,
                        size: 18,
                        color: WebTheme.mutedOf(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (chosen)
              IconButton(
                tooltip: 'Any date',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => onChanged(null),
                icon: Icon(Icons.close, size: 16, color: WebTheme.brand),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorklogDatePicker extends StatefulWidget {
  final DateTime? selected;

  const _WorklogDatePicker({required this.selected});

  @override
  State<_WorklogDatePicker> createState() => _WorklogDatePickerState();
}

class _WorklogDatePickerState extends State<_WorklogDatePicker> {
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  late DateTime _visible;

  @override
  void initState() {
    super.initState();
    final seed = widget.selected ?? DateTime.now();
    _visible = DateTime(seed.year, seed.month);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _choose(DateTime? date) {
    Navigator.pop(context, WorklogDateSelection(date));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(_visible.year, _visible.month + 1, 0).day;
    final lead = DateTime(_visible.year, _visible.month, 1).weekday % 7;
    final ink = WebTheme.inkOf(context);
    final muted = WebTheme.mutedOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (AppLayout.isMobile(context))
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: WebTheme.lineOf(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Worklog date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: muted),
              ),
            ],
          ),
          Text(
            widget.selected == null
                ? 'Showing every date'
                : TimeUtils.formatDate(widget.selected!),
            style: TextStyle(fontSize: 13, color: muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _choice(
                context,
                'Any date',
                widget.selected == null,
                () => _choose(null),
              ),
              const SizedBox(width: 8),
              _choice(
                context,
                'Today',
                widget.selected != null && _sameDay(widget.selected!, today),
                () => _choose(today),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () {
                  setState(() {
                    _visible = DateTime(_visible.year, _visible.month - 1);
                  });
                },
                icon: Icon(Icons.chevron_left, color: ink),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_visible),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () {
                  setState(() {
                    _visible = DateTime(_visible.year, _visible.month + 1);
                  });
                },
                icon: Icon(Icons.chevron_right, color: ink),
              ),
            ],
          ),
          Row(
            children: [
              for (final name in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lead + days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < lead) return const SizedBox.shrink();
              final day = DateTime(_visible.year, _visible.month, index - lead + 1);
              final selected =
                  widget.selected != null && _sameDay(widget.selected!, day);
              final isToday = _sameDay(day, today);
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _choose(day),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? WebTheme.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? WebTheme.brand
                          : isToday
                              ? WebTheme.brand
                              : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : ink,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _choice(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return Material(
      color: selected ? WebTheme.brand : WebTheme.canvasOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? WebTheme.brand : WebTheme.lineOf(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : WebTheme.inkOf(context),
            ),
          ),
        ),
      ),
    );
  }
}
