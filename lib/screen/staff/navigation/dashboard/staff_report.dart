import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/utils/work_performance.dart';

typedef StaffListOpener = void Function(
  DashboardListKind kind,
  String title,
  WorkStatusFilter filter,
);

/// Staff home laid out as one analytics board: scores, trend, tasks, goals, leave.
class StaffReport extends StatefulWidget {
  final int year;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> previousSummary;
  final List<dynamic> monthly;
  final List<dynamic> breakdown;
  final List<dynamic> previousMonthly;
  final TaskTiming taskTiming;
  final Map<String, dynamic> attendance;
  final List<dynamic> leaves;
  final List<dynamic> permissions;
  final List<dynamic> compensations;
  final List<dynamic> overtimes;
  final bool showOvertime;
  final String staffName;
  final String department;
  final int warningCount;
  final int dueSoonGoals;
  final int dueSoonTasks;
  final VoidCallback? onWarnings;
  final VoidCallback onPickYear;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenSettings;
  final StaffListOpener onOpen;
  final int month;
  final ValueChanged<int> onSelectMonth;

  const StaffReport({
    super.key,
    required this.year,
    required this.summary,
    required this.previousSummary,
    required this.monthly,
    required this.breakdown,
    required this.previousMonthly,
    required this.taskTiming,
    required this.attendance,
    required this.leaves,
    required this.permissions,
    required this.compensations,
    required this.overtimes,
    required this.showOvertime,
    required this.staffName,
    required this.department,
    this.warningCount = 0,
    this.dueSoonGoals = 0,
    this.dueSoonTasks = 0,
    this.onWarnings,
    required this.onPickYear,
    required this.onOpenReports,
    required this.onOpenSettings,
    required this.onOpen,
    required this.month,
    required this.onSelectMonth,
  });

  @override
  State<StaffReport> createState() => _StaffReportState();
}

class _StaffReportState extends State<StaffReport> {
  static const _names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int get _month => widget.month.clamp(1, 12);

  int _n(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _d(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _trim(double value) {
    final rounded = (value * 100).round() / 100;
    final text = rounded.toStringAsFixed(2);
    if (text.endsWith('.00')) return rounded.toStringAsFixed(0);
    if (text.endsWith('0')) return rounded.toStringAsFixed(1);
    return text;
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Map<String, dynamic>? _find(List<dynamic> source, int month) {
    for (final item in source) {
      if (item is! Map) continue;
      if (_n(item['month'] ?? item['Month']) == month) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  static const _productivityKeys = ['productivity', 'Productivity'];
  static const _taskPenaltyKeys = [
    'taskpenaltypoints',
    'taskPenaltyPoints',
    'TaskPenaltyPoints',
    'taskPenalty',
  ];
  static const _warningKeys = [
    'warningPenaltyPoints',
    'WarningPenaltyPoints',
    'warningpenaltypoints',
    'warningPoints',
    'WarningPoints',
  ];

  double? _optional(Map<String, dynamic>? item, List<String> keys) {
    if (item == null) return null;
    for (final key in keys) {
      if (!item.containsKey(key) || item[key] == null) continue;
      return _d(item[key]);
    }
    return null;
  }

  double _first(Map<String, dynamic>? item, List<String> keys) {
    return _optional(item, keys) ?? 0;
  }

  double? _summaryValue(List<String> keys) {
    for (final key in keys) {
      if (!widget.summary.containsKey(key) || widget.summary[key] == null) {
        continue;
      }
      return _d(widget.summary[key]);
    }
    return null;
  }

  double? _recordProductivity(Map<String, dynamic>? item) {
    return _optional(item, _productivityKeys);
  }

  double? _reportPerformance(Map<String, dynamic>? item) {
    return _optional(item, const [
      'performance',
      'Performance',
      'totalScore',
      'totalscore',
      'TotalScore',
    ]);
  }

  double? _reportProductivity(Map<String, dynamic>? item) {
    return _optional(item, _productivityKeys);
  }

  String _points(double? value) {
    if (value == null) return '—';
    return _trim(value);
  }

  bool _applied(double value) => value.abs() >= 0.01;

  double _chartY(double? value) {
    if (value == null || value < 0) return 0;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!AppLayout.isMobile(context)) ...[
          _header(context),
          const SizedBox(height: 14),
        ],
        _scoreCards(context),
        const SizedBox(height: 12),
        _trendAndBreakdown(context),
        const SizedBox(height: 12),
        _taskAndGoalBoards(context),
        const SizedBox(height: 12),
        _approvedPair(
          context,
          leftTitle: 'Leave',
          leftUnit: 'days',
          leftValues: _leaveSeries(),
          leftTotal: _approvedTotal(
            const ['approvedLeaveCount', 'ApprovedLeaveCount'],
            _leaveSeries(),
          ),
          leftColor: WebTheme.brandOf(context),
          rightTitle: 'Permission',
          rightUnit: 'hours',
          rightValues: _permissionSeries(),
          rightTotal: _approvedTotal(
            const ['approvedPermissionCount', 'ApprovedPermissionCount'],
            _permissionSeries(),
          ),
          rightColor: WebTheme.warning,
          months: _visibleMonths,
        ),
        const SizedBox(height: 12),
        _approvedPair(
          context,
          leftTitle: 'Compensation',
          leftUnit: 'hours',
          leftValues: _monthlyAmounts(
            widget.compensations,
            const ['workDate', 'WorkDate', 'date', 'Date'],
            const ['expectedHours', 'ExpectedHours', 'totalHours', 'hours'],
          ),
          leftColor: WebTheme.brandOf(context),
          rightTitle: 'Overtime',
          rightUnit: 'hours',
          rightValues: widget.showOvertime
              ? _monthlyAmounts(
                  widget.overtimes,
                  const ['date', 'Date', 'overtimeDate', 'fromDate'],
                  const ['totalHours', 'TotalHours', 'hours', 'Hours'],
                )
              : const [],
          rightColor: WebTheme.brandOf(context),
          hideRight: !widget.showOvertime,
          months: _visibleMonths,
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final name = widget.staffName.trim().isEmpty
        ? 'Dashboard'
        : widget.staffName.trim();
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: AppLayout.isMobile(context) ? 20 : 22,
            fontWeight: FontWeight.w800,
            color: WebTheme.inkOf(context),
          ),
        ),
        if (widget.department.trim().isNotEmpty)
          Text(
            widget.department.trim(),
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
      ],
    );
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _menuChip(
          context,
          label: _names[_month - 1],
          onSelected: widget.onSelectMonth,
          months: [for (var month = 1; month <= 12; month++) month],
        ),
        _plainChip(context, '${widget.year}', widget.onPickYear),
        if (widget.warningCount > 0 && widget.onWarnings != null)
          _roundIcon(
            context,
            Icons.warning_amber_rounded,
            'Warnings',
            widget.onWarnings!,
            badge: widget.warningCount,
            iconColor: const Color(0xFFFFC107),
          ),
        _roundIcon(
          context,
          Icons.bar_chart_rounded,
          'Reports',
          widget.onOpenReports,
        ),
        _roundIcon(
          context,
          Icons.settings_outlined,
          'Settings',
          widget.onOpenSettings,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 10), controls],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            controls,
          ],
        );
      },
    );
  }

  Widget _roundIcon(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    int badge = 0,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: WebTheme.brand,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Badge(
          isLabelVisible: badge > 0,
          label: Text(badge > 99 ? '99+' : '$badge'),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }

  Widget _scoreCards(BuildContext context, {double? motion}) {
    if (motion == null) {
      return _ScrollPlay(
        builder: (context, t) => _scoreCards(context, motion: t),
      );
    }
    final play = motion;
    final yearlyPerformance = _summaryValue(const [
      'yearlyPerformance',
      'YearlyPerformance',
    ]);
    final yearlyProductivity = _summaryValue(const [
      'yearlyProductivity',
      'YearlyProductivity',
    ]);
    final monthRecord = _find(widget.monthly, _month);
    final monthPerformance = _reportPerformance(monthRecord);
    final monthProductivity = _reportProductivity(monthRecord);
    final doneThrough = _lastCompletedMonth();
    final range = doneThrough <= 0
        ? 'No completed month yet'
        : 'Jan – ${_names[doneThrough - 1]} ${widget.year}';
    final monthName = '${_names[_month - 1]} ${widget.year}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 560;
        final cols = mobile
            ? 2
            : constraints.maxWidth >= 900
                ? 4
                : 2;
        final gap = 10.0;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final yearlyPerformanceCard = _kpi(
          context,
          label: 'Yearly performance',
          value: _points(yearlyPerformance),
          now: null,
          before: null,
          foot: range,
          scale: 'out of 100',
          compact: mobile,
        );
        final yearlyProductivityCard = _kpi(
          context,
          label: 'Yearly productivity',
          value: _points(yearlyProductivity),
          now: null,
          before: null,
          foot: range,
          scale: 'out of 100',
          compact: mobile,
        );
        final cards = mobile
            ? [
                yearlyPerformanceCard,
                _kpi(
                  context,
                  label: 'Monthly performance',
                  value: _points(monthPerformance),
                  now: null,
                  before: null,
                  foot: monthName,
                  scale: 'out of 100',
                  compact: true,
                ),
                yearlyProductivityCard,
                _kpi(
                  context,
                  label: 'Monthly productivity',
                  value: _points(monthProductivity),
                  now: null,
                  before: null,
                  foot: monthName,
                  scale: 'out of 100',
                  compact: true,
                ),
              ]
            : [
                yearlyPerformanceCard,
                yearlyProductivityCard,
                _kpi(
                  context,
                  label: 'Monthly performance',
                  value: _points(monthPerformance),
                  now: null,
                  before: null,
                  foot: monthName,
                  scale: 'out of 100',
                ),
                _kpi(
                  context,
                  label: 'Monthly productivity',
                  value: _points(monthProductivity),
                  now: null,
                  before: null,
                  foot: monthName,
                  scale: 'out of 100',
                ),
              ];
        return _lift(
          play,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards) SizedBox(width: width, child: card),
            ],
          ),
        );
      },
    );
  }

  int _lastCompletedMonth() {
    final now = DateTime.now();
    if (widget.year < now.year) return 12;
    if (widget.year == now.year) return now.month - 1;
    return 0;
  }

  Widget _taskAndGoalBoards(BuildContext context) {
    final tasks = _workTotals(
      completedKey: 'completedTasks',
      pendingKey: 'pendingTasks',
      overdueKey: 'overdueTasks',
      totalKey: 'totalTasks',
    );
    final goals = _workTotals(
      completedKey: 'completedGoals',
      pendingKey: 'pendingGoals',
      overdueKey: 'overdueGoals',
      totalKey: 'totalGoals',
    );
    final taskOnTime = widget.summary.containsKey('onTimeTasks')
        ? _n(widget.summary['onTimeTasks'])
        : _countFromPercent(widget.taskTiming.onTime, tasks.completed);
    final taskDelayed = widget.summary.containsKey('delayedTasks')
        ? _n(widget.summary['delayedTasks'])
        : _countFromPercent(widget.taskTiming.delayed, tasks.completed);
    final goalOnTime = widget.summary.containsKey('onTimeGoals')
        ? _n(widget.summary['onTimeGoals'])
        : null;
    final goalDelayed = widget.summary.containsKey('delayedGoalsCount')
        ? _n(widget.summary['delayedGoalsCount'])
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 600;
        final taskCard = _measureCard(
          context,
          title: 'Tasks',
          subtitle: '${widget.year} · assigned to you',
          noun: 'tasks',
          totals: tasks,
          onTime: taskOnTime,
          delayed: taskDelayed,
          completedPercent: _storedPercent(const ['taskCompletionPercent']),
          onTimePercent: _storedPercent(const ['taskOnTimePercent']),
          delayedPercent: _storedPercent(const ['delayedTaskPercent']),
          onOpenTotal: () => widget.onOpen(
            DashboardListKind.tasks,
            'Tasks',
            WorkStatusFilter.all,
          ),
          onOpenCompleted: () => widget.onOpen(
            DashboardListKind.tasks,
            'Completed Tasks',
            WorkStatusFilter.completed,
          ),
          onOpenPending: () => widget.onOpen(
            DashboardListKind.tasks,
            'Pending Tasks',
            WorkStatusFilter.pending,
          ),
          onOpenOverdue: () => widget.onOpen(
            DashboardListKind.tasks,
            'Overdue Tasks',
            WorkStatusFilter.overdue,
          ),
          onOpenOnTime: () => widget.onOpen(
            DashboardListKind.tasks,
            'On time Tasks',
            WorkStatusFilter.onTime,
          ),
          onOpenDelayed: () => widget.onOpen(
            DashboardListKind.tasks,
            'Delayed Tasks',
            WorkStatusFilter.delayed,
          ),
        );
        final goalCard = _measureCard(
          context,
          title: 'Goals',
          subtitle: '${widget.year} · assigned to you',
          noun: 'goals',
          totals: goals,
          onTime: goalOnTime,
          delayed: goalDelayed,
          completedPercent: _storedPercent(const [
            'goalCompletionPercent',
            'goalCompletionPercentage',
          ]),
          onTimePercent: _storedPercent(const ['goalOnTimePercent']),
          delayedPercent: _storedPercent(const [
            'delayedGoalPercent',
            'delayedGoalPercentage',
          ]),
          onOpenTotal: () => widget.onOpen(
            DashboardListKind.goals,
            'Goals',
            WorkStatusFilter.all,
          ),
          onOpenCompleted: () => widget.onOpen(
            DashboardListKind.goals,
            'Completed Goals',
            WorkStatusFilter.completed,
          ),
          onOpenPending: () => widget.onOpen(
            DashboardListKind.goals,
            'Pending Goals',
            WorkStatusFilter.pending,
          ),
          onOpenOverdue: () => widget.onOpen(
            DashboardListKind.goals,
            'Overdue Goals',
            WorkStatusFilter.overdue,
          ),
          onOpenOnTime: () => widget.onOpen(
            DashboardListKind.goals,
            'On time Goals',
            WorkStatusFilter.onTime,
          ),
          onOpenDelayed: () => widget.onOpen(
            DashboardListKind.goals,
            'Delayed Goals',
            WorkStatusFilter.delayed,
          ),
        );
        final alerts = _alertsPanel(context);
        if (stacked) {
          return Column(
            children: [
              goalCard,
              const SizedBox(height: 12),
              taskCard,
              if (alerts != null) ...[
                const SizedBox(height: 12),
                alerts,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: goalCard),
            const SizedBox(width: 12),
            Expanded(child: taskCard),
            if (alerts != null) ...[
              const SizedBox(width: 12),
              Expanded(child: alerts),
            ],
          ],
        );
      },
    );
  }

  Widget? _alertsPanel(BuildContext context) {
    final goals = _workTotals(
      completedKey: 'completedGoals',
      pendingKey: 'pendingGoals',
      overdueKey: 'overdueGoals',
      totalKey: 'totalGoals',
    );
    final tasks = _workTotals(
      completedKey: 'completedTasks',
      pendingKey: 'pendingTasks',
      overdueKey: 'overdueTasks',
      totalKey: 'totalTasks',
    );
    final rows = <Widget>[
      if (widget.warningCount > 0)
        _alertLine(
          context,
          icon: Icons.warning_amber_rounded,
          title: widget.warningCount == 1
              ? '1 warning'
              : '${widget.warningCount} warnings',
          onTap: widget.onWarnings,
        ),
      if (goals.overdue > 0)
        _alertLine(
          context,
          icon: Icons.flag_outlined,
          title: goals.overdue == 1
              ? '1 overdue goal'
              : '${goals.overdue} overdue goals',
          onTap: () => widget.onOpen(
            DashboardListKind.goals,
            'Overdue Goals',
            WorkStatusFilter.overdue,
          ),
        ),
      if (tasks.overdue > 0)
        _alertLine(
          context,
          icon: Icons.assignment_late_outlined,
          title: tasks.overdue == 1
              ? '1 overdue task'
              : '${tasks.overdue} overdue tasks',
          onTap: () => widget.onOpen(
            DashboardListKind.tasks,
            'Overdue Tasks',
            WorkStatusFilter.overdue,
          ),
        ),
      if (widget.dueSoonGoals > 0)
        _alertLine(
          context,
          icon: Icons.event_outlined,
          title: widget.dueSoonGoals == 1
              ? '1 goal overdue within 7 days'
              : '${widget.dueSoonGoals} goals overdue within 7 days',
          onTap: () => widget.onOpen(
            DashboardListKind.goals,
            'Goals overdue within 7 days',
            WorkStatusFilter.dueSoon,
          ),
        ),
      if (widget.dueSoonTasks > 0)
        _alertLine(
          context,
          icon: Icons.event_outlined,
          title: widget.dueSoonTasks == 1
              ? '1 task overdue within 7 days'
              : '${widget.dueSoonTasks} tasks overdue within 7 days',
          onTap: () => widget.onOpen(
            DashboardListKind.tasks,
            'Tasks overdue within 7 days',
            WorkStatusFilter.dueSoon,
          ),
        ),
    ];
    if (rows.isEmpty) return null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Alerts',
              style: TextStyle(
                color: WebTheme.inkOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: WebTheme.lineOf(context)),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _alertLine(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: WebTheme.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: WebTheme.inkOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: WebTheme.mutedOf(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  _WorkTotals _workTotals({
    required String completedKey,
    required String pendingKey,
    required String overdueKey,
    required String totalKey,
  }) {
    final completed = _n(widget.summary[completedKey]);
    final pending = _n(widget.summary[pendingKey]);
    final overdue = _n(widget.summary[overdueKey]);
    final storedTotal = _n(widget.summary[totalKey]);
    final pendingIncludesOverdue =
        storedTotal == completed + pending && overdue <= pending;
    final pendingShown = pendingIncludesOverdue ? pending : pending + overdue;
    final total = storedTotal > 0 ? storedTotal : completed + pendingShown;
    return _WorkTotals(
      total: total,
      completed: completed,
      pending: pendingShown,
      overdue: overdue,
    );
  }

  int? _countFromPercent(double? percent, int completed) {
    if (percent == null || completed <= 0) return null;
    return (percent / 100 * completed).round();
  }

  double? _storedPercent(List<String> keys) {
    for (final key in keys) {
      if (!widget.summary.containsKey(key)) continue;
      return _d(widget.summary[key]);
    }
    return null;
  }

  Widget _measureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String noun,
    required _WorkTotals totals,
    required int? onTime,
    required int? delayed,
    double? completedPercent,
    double? onTimePercent,
    double? delayedPercent,
    required VoidCallback onOpenTotal,
    required VoidCallback onOpenCompleted,
    required VoidCallback onOpenPending,
    required VoidCallback onOpenOverdue,
    required VoidCallback onOpenOnTime,
    required VoidCallback onOpenDelayed,
    double? motion,
  }) {
    if (motion == null) {
      return _ScrollPlay(
        builder: (context, t) => _measureCard(
          context,
          title: title,
          subtitle: subtitle,
          noun: noun,
          totals: totals,
          onTime: onTime,
          delayed: delayed,
          completedPercent: completedPercent,
          onTimePercent: onTimePercent,
          delayedPercent: delayedPercent,
          onOpenTotal: onOpenTotal,
          onOpenCompleted: onOpenCompleted,
          onOpenPending: onOpenPending,
          onOpenOverdue: onOpenOverdue,
          onOpenOnTime: onOpenOnTime,
          onOpenDelayed: onOpenDelayed,
          motion: t,
        ),
      );
    }
    final play = motion;
    final timed = (onTime ?? 0) + (delayed ?? 0);
    final completedPct = completedPercent ??
        (totals.total <= 0 ? null : totals.completed / totals.total * 100);
    final onTimePct = onTimePercent ??
        (onTime == null || timed <= 0 ? null : onTime / timed * 100);
    final delayedPct = delayedPercent ??
        (delayed == null || timed <= 0 ? null : delayed / timed * 100);
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WebTheme.brandOf(context),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _figure(
                context,
                'Total',
                '${totals.total}',
                WebTheme.inkOf(context),
                onOpenTotal,
                motion: play,
              ),
              _figure(
                context,
                'Completed',
                '${totals.completed}',
                WebTheme.brandOf(context),
                onOpenCompleted,
                motion: play,
              ),
              _figure(
                context,
                'Pending',
                '${totals.pending}',
                WebTheme.inkOf(context),
                onOpenPending,
                motion: play,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _figure(
                context,
                'Overdue',
                '${totals.overdue}',
                WebTheme.danger,
                onOpenOverdue,
                motion: play,
              ),
              _figure(
                context,
                'On time',
                onTime == null ? '—' : '$onTime',
                WebTheme.brandOf(context),
                onOpenOnTime,
                motion: play,
              ),
              _figure(
                context,
                'Delayed',
                delayed == null ? '—' : '$delayed',
                WebTheme.warning,
                onOpenDelayed,
                motion: play,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Overdue $noun are part of Pending (${totals.pending} includes ${totals.overdue} overdue).',
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 10),
          _ratioBar(
            context,
            'Completed %',
            completedPct,
            WebTheme.brandOf(context),
            totals.total <= 0
                ? ''
                : '${totals.completed} completed ÷ ${totals.total} total',
            onTap: onOpenCompleted,
            motion: play,
          ),
          _ratioBar(
            context,
            'On-time %',
            onTimePct,
            WebTheme.inkOf(context),
            onTime == null
                ? ''
                : '$onTime on time ÷ $timed completed',
            onTap: onOpenOnTime,
            motion: play,
          ),
          _ratioBar(
            context,
            'Delayed %',
            delayedPct,
            WebTheme.warning,
            delayed == null
                ? ''
                : '$delayed delayed ÷ $timed completed',
            onTap: onOpenDelayed,
            motion: play,
          ),
        ],
      ),
    );
  }

  Widget _figure(
    BuildContext context,
    String label,
    String value,
    Color color,
    VoidCallback? onTap, {
    double motion = 1,
  }) {
    final number = double.tryParse(value);
    final shown = number == null || motion >= 1
        ? value
        : _fmt(number * motion.clamp(0, 1));
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Material(
          color: WebTheme.brandSoftOf(context),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: WebTheme.mutedOf(context),
                    ),
                  ),
                  Text(
                    shown,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratioBar(
    BuildContext context,
    String label,
    double? percent,
    Color color,
    String detail, {
    VoidCallback? onTap,
    double motion = 1,
  }) {
    final grown = (percent ?? 0).clamp(0, 100).toDouble() * motion.clamp(0, 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: WebTheme.inkOf(context),
                    ),
                  ),
                ),
                Text(
                  percent == null ? '—' : '${grown.round()}%',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
            if (detail.isNotEmpty)
              Text(
                detail,
                style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
              ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: percent == null ? 0 : grown / 100,
                color: color,
                backgroundColor: WebTheme.brandSoftOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _visibleMonths {
    final now = DateTime.now();
    if (widget.year > now.year) return 0;
    if (widget.year < now.year) return 12;
    return now.month;
  }

  Widget _approvedPair(
    BuildContext context, {
    required String leftTitle,
    required String leftUnit,
    required List<double> leftValues,
    required Color leftColor,
    required String rightTitle,
    required String rightUnit,
    required List<double> rightValues,
    required Color rightColor,
    double? leftTotal,
    double? rightTotal,
    int? months,
    bool hideRight = false,
  }) {
    final limit = months ?? _visibleMonths;
    final left = _approvedCard(
      context,
      title: leftTitle,
      unit: leftUnit,
      values: leftValues,
      total: leftTotal,
      color: leftColor,
      months: limit,
    );
    if (hideRight) return left;
    final right = _approvedCard(
      context,
      title: rightTitle,
      unit: rightUnit,
      values: rightValues,
      total: rightTotal,
      color: rightColor,
      months: limit,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [left, const SizedBox(height: 12), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _approvedCard(
    BuildContext context, {
    required String title,
    required String unit,
    required List<double> values,
    required Color color,
    double? total,
    int? months,
    double? motion,
  }) {
    if (motion == null) {
      return _ScrollPlay(
        builder: (context, t) => _approvedCard(
          context,
          title: title,
          unit: unit,
          values: values,
          color: color,
          total: total,
          months: months,
          motion: t,
        ),
      );
    }
    final play = motion;
    var shown = months ?? _visibleMonths;
    for (var month = shown; month < values.length; month++) {
      if (values[month] > 0) shown = month + 1;
    }
    final yearTotal = total ??
        values.take(shown).fold<double>(0, (sum, value) => sum + value);
    var peak = 0.0;
    for (var month = 0; month < shown && month < values.length; month++) {
      if (values[month] > peak) peak = values[month];
    }
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.brandOf(context),
                  ),
                ),
              ),
              Text(
                'Approved only',
                style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _fmt(yearTotal * play.clamp(0, 1)),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.inkOf(context),
                  ),
                ),
                TextSpan(
                  text: ' $unit this year',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.inkOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: shown <= 0
                ? _empty(context, 'No months in this year yet.')
                : BarChart(
                    BarChartData(
                      maxY: peak <= 0 ? 1 : peak,
                      minY: 0,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: _monthTitles(
                        context,
                        limit: shown,
                        top: (month) {
                          if (month < 1 || month > shown) {
                            return const SizedBox.shrink();
                          }
                          final value =
                              month <= values.length ? values[month - 1] : 0.0;
                          return Text(
                            _fmt(value),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: WebTheme.inkOf(context),
                            ),
                          );
                        },
                      ),
                      barGroups: [
                        for (var month = 1; month <= shown; month++)
                          BarChartGroupData(
                            x: month,
                            barRods: [
                              BarChartRodData(
                                toY: (month <= values.length
                                        ? values[month - 1]
                                        : 0) *
                                    _rise(month - 1, shown, play),
                                width: 18,
                                borderRadius:
                                    (month <= values.length
                                            ? values[month - 1]
                                            : 0) >
                                        0
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      )
                                    : BorderRadius.zero,
                                color:
                                    (month <= values.length
                                            ? values[month - 1]
                                            : 0) >
                                        0
                                    ? color
                                    : const Color(0x00000000),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<double> _leaveSeries() {
    return _countSeries(
      const ['approvedLeaveCount', 'ApprovedLeaveCount'],
      const [
        'leaveDays',
        'LeaveDays',
        'leave',
        'days',
        'totalDays',
        'TotalDays',
        'count',
        'Count',
        'value',
      ],
      'leave',
      widget.leaves,
      const ['fromDate', 'FromDate', 'date', 'Date'],
      const ['totalDays', 'TotalDays', 'days', 'Days'],
      daySpan: true,
    );
  }

  List<double> _permissionSeries() {
    return _countSeries(
      const ['approvedPermissionCount', 'ApprovedPermissionCount'],
      const [
        'permissionHours',
        'PermissionHours',
        'permission',
        'hours',
        'totalHours',
        'TotalHours',
        'count',
        'Count',
        'value',
      ],
      'permission',
      widget.permissions,
      const ['date', 'Date', 'fromDate', 'FromDate'],
      const ['totalHours', 'TotalHours', 'hours', 'Hours'],
    );
  }

  double? _scalarCount(List<String> keys) {
    for (final key in keys) {
      final raw = widget.summary[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) {
        final parsed = double.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  double _approvedTotal(List<String> keys, List<double> series) {
    final shown = series.take(_visibleMonths).fold<double>(0, (sum, value) => sum + value);
    final scalar = _scalarCount(keys);
    if (scalar != null && shown <= 0) return scalar;
    if (shown > 0) return shown;
    return scalar ?? 0;
  }

  List<double> _countSeries(
    List<String> keys,
    List<String> amountKeys,
    String attendanceKey,
    List<dynamic> items,
    List<String> dateKeys,
    List<String> itemAmountKeys, {
    bool daySpan = false,
  }) {
    final fromReport = _parseCountSeries(keys, amountKeys);
    if (fromReport != null && fromReport.any((value) => value > 0)) {
      return fromReport;
    }
    final fromAttendance = _approvedSeries(attendanceKey);
    if (fromAttendance.any((value) => value > 0)) return fromAttendance;
    final fromItems = _monthlyAmounts(
      items,
      dateKeys,
      itemAmountKeys,
      daySpan: daySpan,
    );
    if (fromItems.any((value) => value > 0)) return fromItems;
    final total = _scalarCount(keys);
    if (total != null && total > 0) {
      final values = List<double>.filled(12, 0);
      final month = _visibleMonths.clamp(1, 12);
      values[month - 1] = total;
      return values;
    }
    return fromItems;
  }

  List<double>? _parseCountSeries(List<String> keys, List<String> amountKeys) {
    dynamic raw;
    for (final key in keys) {
      if (!widget.summary.containsKey(key)) continue;
      raw = widget.summary[key];
      break;
    }
    if (raw is! List && raw is! Map) return null;
    final values = List<double>.filled(12, 0);
    if (raw is List) {
      final plain = raw.isEmpty || raw.every((item) => item is num || item is String);
      if (plain) {
        for (var index = 0; index < raw.length && index < 12; index++) {
          values[index] = _d(raw[index]);
        }
        return values;
      }
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final month = _n(map['month'] ?? map['Month']);
        if (month < 1 || month > 12) continue;
        values[month - 1] += _monthAmount(map, amountKeys);
      }
      return values;
    }
    final map = Map<String, dynamic>.from(raw as Map);
    for (final entry in map.entries) {
      final month = int.tryParse(entry.key) ?? _monthIndex(entry.key);
      if (month < 1 || month > 12) continue;
      final value = entry.value;
      if (value is Map) {
        values[month - 1] += _monthAmount(
          Map<String, dynamic>.from(value),
          amountKeys,
        );
      } else {
        values[month - 1] += _d(value);
      }
    }
    return values;
  }

  double _monthAmount(Map<String, dynamic> item, List<String> amountKeys) {
    final amount = _firstAmount(item, amountKeys);
    if (amount > 0) return amount;
    return _d(
      item['count'] ??
          item['Count'] ??
          item['total'] ??
          item['Total'] ??
          item['value'] ??
          item['Value'],
    );
  }

  int _monthIndex(Object? name) {
    final text = name?.toString().trim().toLowerCase() ?? '';
    const names = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    for (var index = 0; index < names.length; index++) {
      if (text.startsWith(names[index])) return index + 1;
    }
    return 0;
  }

  List<double> _approvedSeries(String key) {
    return [for (final name in _names) _seriesValue(name, key)];
  }

  double _seriesValue(String month, String key) {
    final item = widget.attendance[month];
    if (item is! Map) return 0;
    return _d(item[key]);
  }

  List<double> _monthlyAmounts(
    List<dynamic> items,
    List<String> dateKeys,
    List<String> amountKeys, {
    bool daySpan = false,
  }) {
    final values = List<double>.filled(12, 0);
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      if (!_isApproved(item)) continue;
      final from = _firstDate(item, dateKeys);
      if (from == null || from.year != widget.year) continue;
      var amount = _firstAmount(item, amountKeys);
      if (amount <= 0 && daySpan) {
        final to = _date(item['toDate'] ?? item['ToDate']) ?? from;
        amount = to.difference(from).inDays + 1;
        if (amount < 1) amount = 1;
      }
      if (amount <= 0) amount = 1;
      values[from.month - 1] += amount;
    }
    return values;
  }

  bool _isApproved(Map<String, dynamic> item) {
    final status = (
      item['status'] ??
          item['Status'] ??
          item['managerStatus'] ??
          item['ManagerStatus'] ??
          ''
    ).toString().toLowerCase();
    if (status.contains('reject') || status.contains('declin')) return false;
    return status.contains('approv') || status.contains('accept');
  }

  DateTime? _firstDate(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final date = _date(item[key]);
      if (date != null) return date;
    }
    return null;
  }

  double _firstAmount(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      if (!item.containsKey(key)) continue;
      final amount = _d(item[key]);
      if (amount > 0) return amount;
    }
    return 0;
  }

  Widget _trendAndBreakdown(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        final trend = _trendCard(context);
        final breakdown = _breakdownCard(context);
        if (stacked) {
          return Column(
            children: [
              trend,
              const SizedBox(height: 12),
              breakdown,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: trend),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: breakdown),
          ],
        );
      },
    );
  }

  Widget _trendCard(BuildContext context, {double? motion}) {
    if (motion == null) {
      return _ScrollPlay(
        builder: (context, t) => _trendCard(context, motion: t),
      );
    }
    final play = motion;
    final productivity = <FlSpot>[];
    final performance = <FlSpot>[];
    final last = _lastCompletedMonth();
    for (var month = 1; month <= last; month++) {
      final item = _find(widget.monthly, month);
      final productivityScore = _reportProductivity(item);
      final performanceScore = _reportPerformance(item);
      if (productivityScore == null && performanceScore == null) continue;
      productivity.add(FlSpot(month.toDouble(), _chartY(productivityScore)));
      performance.add(FlSpot(month.toDouble(), _chartY(performanceScore)));
    }
    final peak = [
      100.0,
      for (final spot in productivity) spot.y,
      for (final spot in performance) spot.y,
    ].reduce((a, b) => a > b ? a : b);
    final maxY = (peak <= 100 ? 112.0 : ((peak / 10).ceil() * 10).toDouble());
    final productivityLine = _line(_wave(productivity, play), WebTheme.brandOf(context));
    final performanceLine = _line(
      _wave(performance, play),
      WebTheme.inkOf(context),
      dashed: true,
    );
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics trend · ${widget.year}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WebTheme.brandOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'out of 100',
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              _legend(context, WebTheme.brandOf(context), 'Productivity'),
              _legend(context, WebTheme.inkOf(context), 'Performance'),
            ],
          ),
          const SizedBox(height: 8),
          if (productivity.isEmpty)
            _empty(context, 'No monthly scores for this year.')
          else
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 12,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: WebTheme.lineOf(context),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _monthTitles(context),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchSpotThreshold: 36,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => WebTheme.brand,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) {
                        return [
                          for (final spot in spots)
                            spot.barIndex == 0
                                ? _monthTooltip(spot.x.round())
                                : null,
                        ];
                      },
                    ),
                  ),
                  lineBarsData: [
                    productivityLine,
                    performanceLine,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  LineTooltipItem _monthTooltip(int month) {
    final item = _find(widget.monthly, month);
    final name = month >= 1 && month <= 12 ? _names[month - 1] : '';
    final text = item == null
        ? '$name\nNo score yet'
        : '$name\nPerformance - ${_points(_reportPerformance(item))}\nProductivity - ${_points(_reportProductivity(item))}';
    return LineTooltipItem(
      text,
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.45,
      ),
      textAlign: TextAlign.start,
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, {bool dashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: spots.length > 2,
      color: color,
      barWidth: 3,
      dashArray: dashed ? [6, 4] : null,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4.5,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _breakdownCard(BuildContext context, {double? motion}) {
    if (motion == null) {
      return _ScrollPlay(
        builder: (context, t) => _breakdownCard(context, motion: t),
      );
    }
    final play = motion;
    final selected = _find(widget.breakdown, _month);
    final performance = _optional(selected, const [
      'totalScore',
      'totalscore',
      'TotalScore',
    ]);
    final productivity = _recordProductivity(selected);
    final task = _first(selected, const ['taskPoints', 'TaskPoints']);
    final goal = _first(selected, const ['goalPoints', 'GoalPoints']);
    final attitude = _first(selected, const [
      'attitudeScore',
      'AttitudeScore',
      'attitude',
      'Attitude',
    ]);
    final taskPenalty = _first(selected, _taskPenaltyKeys);
    final warningPoints = _first(selected, _warningKeys);
    final both = task > 0 && goal > 0;
    final taskMax = both ? 45.0 : 85.0;
    final goalMax = both ? 40.0 : 85.0;
    final taskLabel = both
        ? 'Task · 45'
        : task > 0
            ? 'Task · 85'
            : 'Task';
    final goalLabel = both
        ? 'Goal · 40'
        : goal > 0
            ? 'Goal · 85'
            : 'Goal';
    final monthName = '${_names[_month - 1]} ${widget.year}';
    final hasWarning = _applied(warningPoints);
    final performanceNote = hasWarning
        ? 'Productivity + attitude − warning penalty'
        : 'Productivity + attitude';
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WebTheme.brandOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            monthName,
            style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _scaleCard(
                context,
                label: 'Performance',
                value: performance,
                scale: 'out of 100',
              ),
              const SizedBox(width: 8),
              _scaleCard(
                context,
                label: 'Productivity',
                value: productivity,
                scale: 'out of 85',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selected == null)
            _empty(context, 'No score recorded for this month.')
          else ...[
            _sectionLabel(context, 'Productivity'),
            _breakRow(context, taskLabel, task, null, taskMax, motion: play),
            _breakRow(context, goalLabel, goal, null, goalMax, motion: play),
            if (_applied(taskPenalty))
              _penaltyLine(
                context,
                'Task penalty',
                taskPenalty,
                note: 'Already taken off the task score',
              ),
            const SizedBox(height: 4),
            _sectionLabel(context, 'Performance'),
            Text(
              performanceNote,
              style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
            ),
            const SizedBox(height: 8),
            _breakRow(
              context,
              'Productivity',
              productivity ?? 0,
              null,
              85,
              motion: play,
            ),
            _breakRow(
              context,
              'Attitude · 15',
              attitude,
              null,
              15,
              motion: play,
            ),
            if (hasWarning) _penaltyLine(context, 'Warning penalty', warningPoints),
          ],
        ],
      ),
    );
  }

  Widget _scaleCard(
    BuildContext context, {
    required String label,
    required double? value,
    required String scale,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: WebTheme.brandSoftOf(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
            ),
            const SizedBox(height: 2),
            Text(
              _points(value),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: WebTheme.brandOf(context),
              ),
            ),
            Text(
              scale,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WebTheme.inkOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: WebTheme.mutedOf(context),
        ),
      ),
    );
  }

  Widget _penaltyLine(
    BuildContext context,
    String label,
    double value, {
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.remove_circle_outline, size: 16, color: WebTheme.danger),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.danger,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 11,
                      color: WebTheme.mutedOf(context),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '-${_trim(value.abs())}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: WebTheme.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(
    BuildContext context, {
    required String label,
    required String value,
    required double? now,
    required double? before,
    required String foot,
    String? scale,
    bool compact = false,
  }) {
    final delta = now == null || before == null ? null : now - before;
    final up = delta != null && delta >= 0;
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: WebTheme.mutedOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: WebTheme.brandOf(context),
            ),
          ),
          if (delta != null)
            Text(
              '${up ? '+' : ''}${_fmt(delta)} pts',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: up ? WebTheme.brandOf(context) : WebTheme.danger,
              ),
            ),
          if (scale != null)
            Text(
              scale,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WebTheme.inkOf(context),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            foot,
            style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
          ),
        ],
      ),
    );
  }

  Widget _breakRow(
    BuildContext context,
    String label,
    double now,
    double? before,
    double max, {
    double motion = 1,
  }) {
    final scale = max <= 0 ? 1.0 : max;
    final delta = before == null ? null : now - before;
    final up = delta != null && delta >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.inkOf(context),
                  ),
                ),
              ),
              Text(
                before == null
                    ? _fmt(now)
                    : '${_fmt(before)} → ${_fmt(now)}',
                style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
              ),
              if (delta != null) ...[
                const SizedBox(width: 6),
                Text(
                  '${up ? '+' : ''}${_fmt(delta)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: up ? WebTheme.brandOf(context) : WebTheme.danger,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: WebTheme.brandSoftOf(context)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (now / scale).clamp(0, 1) * motion.clamp(0, 1),
                    child: ColoredBox(color: WebTheme.brandOf(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.isMobile(context) ? 12 : 14),
      decoration: WebTheme.card(context, radius: 16),
      child: child,
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
        ),
      ],
    );
  }

  Widget _menuChip(
    BuildContext context, {
    required String label,
    required ValueChanged<int> onSelected,
    required List<int> months,
    bool filled = false,
  }) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final month in months)
          PopupMenuItem(value: month, child: Text(_names[month - 1])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? WebTheme.brand : WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled ? WebTheme.brand : WebTheme.brandOf(context),
            width: filled ? 0 : 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: filled ? Colors.white : WebTheme.brandOf(context),
          ),
        ),
      ),
    );
  }

  Widget _plainChip(
    BuildContext context,
    String label,
    VoidCallback? onTap, {
    bool filled = false,
  }) {
    return Material(
      color: filled ? WebTheme.brandSoftOf(context) : WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WebTheme.brandOf(context), width: 1.4),
          ),
          child: Text(
            label,
            style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: WebTheme.brandOf(context),
            ),
          ),
        ),
      ),
    );
  }

  FlTitlesData _monthTitles(
    BuildContext context, {
    Widget Function(int month)? top,
    int? limit,
  }) {
    final last = limit ?? 12;
    return FlTitlesData(
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: top != null,
          reservedSize: 22,
          getTitlesWidget: (value, meta) =>
              top?.call(value.toInt()) ?? const SizedBox.shrink(),
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final index = value.toInt() - 1;
            if (index < 0 || index >= last || index > 11) {
              return const SizedBox.shrink();
            }
            return Text(
              _names[index].substring(0, 1),
              style: TextStyle(fontSize: 10, color: WebTheme.mutedOf(context)),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, String message) {
    return Text(message, style: TextStyle(color: WebTheme.mutedOf(context)));
  }

  Widget _lift(double t, {required Widget child}) {
    final travel = (1 - t.clamp(0.0, 1.0)) * 16;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, travel),
        child: child,
      ),
    );
  }

  double _rise(int index, int count, double t) {
    if (t >= 1 || count <= 0) return 1;
    final clamped = t.clamp(0.0, 1.0);
    if (count <= 1) {
      return Curves.easeOutCubic.transform(clamped);
    }
    final start = index / count * 0.62;
    final local = ((clamped - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }

  List<FlSpot> _wave(List<FlSpot> spots, double t) {
    return [
      for (var i = 0; i < spots.length; i++)
        FlSpot(
          spots[i].x,
          spots[i].y * _waveAmount(i, spots.length, t),
        ),
    ];
  }

  double _waveAmount(int index, int count, double t) {
    if (t >= 1 || count <= 0) return 1;
    final clamped = t.clamp(0.0, 1.0);
    final start = count <= 1 ? 0.0 : index / count * 0.7;
    final local = ((clamped - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(local).clamp(0.0, 1.12);
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.startsWith('0001-01-01')) return null;
    return DateTime.tryParse(text);
  }

}

class _WorkTotals {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  const _WorkTotals({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });
}

class _ScrollPlay extends StatefulWidget {
  final Widget Function(BuildContext context, double t) builder;

  const _ScrollPlay({required this.builder});

  @override
  State<_ScrollPlay> createState() => _ScrollPlayState();
}

class _ScrollPlayState extends State<_ScrollPlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ScrollPosition? _position;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_onScroll);
      _position = next;
      _position?.addListener(_onScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) {
      _play();
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: viewport);
    final bottom = top.dy + box.size.height;
    if (top.dy < viewport.size.height * 0.92 && bottom > 16) _play();
  }

  void _play() {
    if (_started) return;
    _started = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _controller.value),
    );
  }
}
