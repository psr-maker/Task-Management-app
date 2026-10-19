import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/admin_approval.dart';
import 'package:staff_work_track/utils/work_performance.dart';

/// Director company dashboard: totals, performance circle, and year difference.
class DirectorReport extends StatelessWidget {
  final int year;
  final int month;
  final ValueChanged<int> onSelectMonth;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> productivity;
  final List<Map<String, dynamic>> previousProductivity;
  final TaskTiming taskTiming;
  final TaskTiming goalTiming;
  final int warningCount;
  final List<({String department, int count})> departmentWarnings;
  final int dueSoonGoals;
  final int dueSoonTasks;
  final ValueChanged<String>? onOpenDepartmentWarnings;
  final VoidCallback onPickYear;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenSettings;
  final VoidCallback onWarnings;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenDepartments;
  final ValueChanged<String>? onOpenDepartment;
  final void Function(String title, WorkStatusFilter filter) onOpenTasks;
  final void Function(String title, WorkStatusFilter filter) onOpenGoals;
  final String heading;
  final String scoreLabel;
  final String performanceTitle;

  const DirectorReport({
    super.key,
    required this.year,
    required this.month,
    required this.onSelectMonth,
    required this.summary,
    required this.departments,
    required this.productivity,
    this.previousProductivity = const [],
    required this.taskTiming,
    this.goalTiming = TaskTiming.empty,
    required this.warningCount,
    this.departmentWarnings = const [],
    this.dueSoonGoals = 0,
    this.dueSoonTasks = 0,
    this.onOpenDepartmentWarnings,
    required this.onPickYear,
    required this.onOpenReports,
    required this.onOpenSettings,
    required this.onWarnings,
    required this.onOpenUsers,
    required this.onOpenDepartments,
    this.onOpenDepartment,
    required this.onOpenTasks,
    required this.onOpenGoals,
    this.heading = 'Company dashboard',
    this.scoreLabel = 'COMPANY SCORE',
    this.performanceTitle = 'Company performance by month',
  });

  static const _names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _performanceKeys = ['totalScore', 'totalscore', 'TotalScore', 'performance', 'Performance'];
  static const _productivityKeys = ['productivity', 'Productivity'];

  int _n(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _d(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _pct(double? value) {
    if (value == null) return '-';
    return '${value.round()}%';
  }

  String _points(double? value) {
    if (value == null) return '-';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> get _tasks => _asMap(summary['tasks']);
  Map<String, dynamic> get _goals => _asMap(summary['goals']);

  double _field(Map<String, dynamic>? item, List<String> keys) {
    if (item == null) return 0;
    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) return _d(item[key]);
    }
    return 0;
  }

  Map<String, dynamic>? _monthRow(Map<String, dynamic> dept, int month) {
    final monthly = dept['monthlyData'] ?? dept['MonthlyData'] ?? dept['monthlyPerformance'];
    if (monthly is! List) return null;
    for (final item in monthly) {
      if (item is! Map) continue;
      if (_n(item['month'] ?? item['Month']) == month) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  String _deptName(Map<String, dynamic> dept) {
    return (dept['department'] ?? dept['Department'] ?? '').toString().trim();
  }

  String _key(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+department$'), '').trim();
  }

  List<Map<String, dynamic>> _monthList(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) _asMap(item),
    ];
  }

  List<Map<String, dynamic>> get _companyMonths => _monthList(summary['monthlyCompanyPerformance']);

  List<Map<String, dynamic>> get _previousCompanyMonths =>
      _monthList(summary['previousMonthlyCompanyPerformance']);

  /// Current year runs from January through the month the API returned.
  int get _shownMonths {
    final available = _n(summary['availableMonths']);
    if (available > 0) return available.clamp(1, 12);
    final now = DateTime.now();
    if (year < now.year) return 12;
    if (year > now.year) return month.clamp(1, 12);
    return now.month.clamp(1, 12);
  }

  String get _rangeLabel {
    final end = _shownMonths;
    if (end >= 12) return 'Full year $year';
    return '${_names.first} - ${_names[end - 1]} $year';
  }

  double? _averageMonth(List<Map<String, dynamic>> rows, int month, List<String> keys) {
    final values = <double>[];
    for (final dept in rows) {
      final value = _field(_monthRow(dept, month), keys);
      if (value <= 0) continue;
      values.add(value);
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? _optional(Map<String, dynamic>? item, List<String> keys) {
    if (item == null) return null;
    for (final key in keys) {
      if (!item.containsKey(key) || item[key] == null) continue;
      return _d(item[key]);
    }
    return null;
  }

  double? _summaryNumber(List<String> keys) => _optional(summary, keys);

  double? _listedMonth(List<Map<String, dynamic>> months, int month, List<String> keys) {
    for (final row in months) {
      if (_n(row['month'] ?? row['Month']) != month) continue;
      return _optional(row, keys);
    }
    return null;
  }

  List<double> _companySeries(List<Map<String, dynamic>> months, List<String> keys, int shown) {
    return [
      for (var month = 1; month <= 12; month++)
        month > shown
            ? 0.0
            : (_listedMonth(months, month, keys) ?? 0).clamp(0, 100).toDouble(),
    ];
  }

  int get _compareMonth {
    for (var month = _shownMonths; month >= 1; month--) {
      final performance = _averageMonth(productivity, month, _performanceKeys);
      final productivityScore = _averageMonth(productivity, month, _productivityKeys);
      if ((performance ?? 0) > 0 || (productivityScore ?? 0) > 0) return month;
    }
    return _shownMonths;
  }

  _WorkTotals _workFrom(Map<String, dynamic> data) {
    final completed = _n(data['completed'] ?? data['Completed']);
    final pending = _n(data['pending'] ?? data['Pending']);
    final overdue = _n(data['overdue'] ?? data['Overdue']);
    final stored = _n(data['total'] ?? data['Total']);
    final pendingIncludesOverdue =
        stored == completed + pending && overdue <= pending;
    final overdueAlreadySeparate = stored == completed + pending + overdue;
    final pendingShown = pendingIncludesOverdue || overdueAlreadySeparate
        ? pending
        : pending + overdue;
    final total = stored > 0 ? stored : completed + pendingShown;
    return _WorkTotals(total: total, completed: completed, pending: pendingShown, overdue: overdue);
  }

  int get _userCount => _n(summary['totalUsers']);

  int get _departmentCount {
    final stored = _n(summary['totalDepartments']);
    if (stored > 0) return stored;
    return _directory().length;
  }

  List<_DirectoryRow> _directory() {
    final rows = <String, _DirectoryRow>{};
    final scoreMonth = _compareMonth;
    for (final dept in productivity) {
      final name = _deptName(dept);
      if (name.isEmpty) continue;
      final monthRow = _monthRow(dept, scoreMonth);
      rows[_key(name)] = _DirectoryRow(
        name: name,
        performance: _field(monthRow, _performanceKeys),
        productivityScore: _field(monthRow, _productivityKeys),
      );
    }
    for (final dept in departments) {
      final name = _deptName(dept);
      if (name.isEmpty) continue;
      final key = _key(name);
      final existing = rows[key];
      rows[key] = _DirectoryRow(
        name: existing?.name ?? name,
        performance: existing?.performance ?? 0,
        productivityScore: existing?.productivityScore ?? 0,
      );
    }
    final list = rows.values.toList();
    list.sort((a, b) => b.performance.compareTo(a.performance));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppLayout.isMobile(context);
    final tasks = _workFrom(_tasks);
    final goals = _workFrom(_goals);
    return SingleChildScrollView(
      padding: mobile
          ? const EdgeInsets.fromLTRB(12, 8, 12, 24)
          : const EdgeInsets.fromLTRB(12, 8, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, mobile),
          const SizedBox(height: 16),
          _scoreBand(context, tasks, goals),
          const SizedBox(height: 16),
          _difference(context),
          const SizedBox(height: 16),
          _departments(context),
          const SizedBox(height: 16),
          PendingApprovals(aside: _alertsPanel(context, tasks, goals)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, bool mobile) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: TextStyle(
            fontSize: mobile ? 22 : 26,
            fontWeight: FontWeight.w800,
            color: WebTheme.inkOf(context),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(_rangeLabel, style: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context))),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onOpenReports,
          icon: const Icon(Icons.bar_chart_rounded, size: 18),
          label: const Text('Reports'),
          style: FilledButton.styleFrom(
            backgroundColor: WebTheme.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        _yearChip(context),
        if (warningCount > 0)
          _iconButton(
            context,
            Icons.warning_amber_rounded,
            'Warnings',
            onWarnings,
            badge: warningCount,
            iconColor: const Color(0xFFFFC107),
          ),
        _iconButton(context, Icons.settings_outlined, 'Settings', onOpenSettings),
      ],
    );
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), actions],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: title), actions],
    );
  }

  String _pace(double? value) => value == null ? '-' : '${value.round()}%';

  double? _readPace(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (!data.containsKey(key) || data[key] == null) continue;
      return _d(data[key]);
    }
    return null;
  }

  double? get _taskOnTime =>
      taskTiming.onTime ??
      _readPace(_tasks, const [
        'onTimeTaskCompletionPercentage',
        'onTimeCompletionPercentage',
        'taskOnTimePercent',
      ]) ??
      _readPace(summary, const [
        'onTimeTaskCompletionPercentage',
        'taskOnTimePercent',
      ]);

  double? get _taskDelayed =>
      taskTiming.delayed ??
      _readPace(_tasks, const [
        'delayedTaskPercentage',
        'delayedPercentage',
        'delayedTaskPercent',
      ]) ??
      _readPace(summary, const ['delayedTaskPercentage', 'delayedTaskPercent']);

  double? get _goalOnTime =>
      goalTiming.onTime ??
      _readPace(_goals, const [
        'onTimeGoalCompletionPercentage',
        'onTimeCompletionPercentage',
        'goalOnTimePercent',
      ]) ??
      _readPace(summary, const [
        'onTimeGoalCompletionPercentage',
        'goalOnTimePercent',
      ]);

  double? get _goalDelayed =>
      goalTiming.delayed ??
      _readPace(_goals, const [
        'delayedGoalPercentage',
        'delayedPercentage',
        'delayedGoalPercent',
      ]) ??
      _readPace(summary, const ['delayedGoalPercentage', 'delayedGoalPercent']);

  ({int up, int steady, int down}) _departmentMovement() {
    var up = 0;
    var steady = 0;
    var down = 0;
    final month = _compareMonth;
    final previous = <String, double>{};
    for (final dept in previousProductivity) {
      final name = _deptName(dept);
      if (name.isEmpty) continue;
      previous[_key(name)] = _field(_monthRow(dept, month), _performanceKeys);
    }
    final seen = <String>{};
    for (final dept in productivity) {
      final name = _deptName(dept);
      if (name.isEmpty) continue;
      final key = _key(name);
      if (!seen.add(key)) continue;
      final current = _field(_monthRow(dept, month), _performanceKeys);
      if (current <= 0) continue;
      final past = previous[key] ?? 0;
      if (past <= 0) {
        steady++;
        continue;
      }
      final gap = current - past;
      if (gap >= 1) {
        up++;
      } else if (gap <= -1) {
        down++;
      } else {
        steady++;
      }
    }
    return (up: up, steady: steady, down: down);
  }

  Widget _scoreBand(BuildContext context, _WorkTotals tasks, _WorkTotals goals) {
    final performance = _summaryNumber(const [
      'yearlyOverallCompanyScore',
      'YearlyOverallCompanyScore',
    ]);
    final previousPerformance = _summaryNumber(const [
      'previousYearlyOverallCompanyScore',
    ]);
    final productivityScore = _summaryNumber(const [
      'yearlyCompanyProductivity',
      'YearlyCompanyProductivity',
    ]);
    final previousProductivityScore = _summaryNumber(const [
      'previousYearlyCompanyProductivity',
    ]);
    final scoreSide = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scoreLabel,
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _yearMark(
                'Performance',
                performance,
                previousPerformance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _yearMark(
                'Productivity',
                productivityScore,
                previousProductivityScore,
              ),
            ),
          ],
        ),
      ],
    );
    const white = Color(0xFFFFFFFF);
    const green = Color(0xFF3DDC97);
    const red = Color(0xFFF87171);
    const amber = Color(0xFFFBBF24);
    final counts = Column(
      children: [
        _metricRow([
          _scoreTile('Total users', '$_userCount', white, onOpenUsers),
          _scoreTile('Total departments', '$_departmentCount', white, onOpenDepartments),
        ]),
        const SizedBox(height: 10),
        _metricRow([
          _scoreTile('Total goals', '${goals.total}', white, () => onOpenGoals('Goals', WorkStatusFilter.all)),
          _scoreTile('Completed', '${goals.completed}', green, () => onOpenGoals('Completed Goals', WorkStatusFilter.completed)),
          _scoreTile('Pending', '${goals.pending}', white, () => onOpenGoals('Pending Goals', WorkStatusFilter.pending)),
          _scoreTile('Overdue', '${goals.overdue}', goals.overdue > 0 ? red : white, () => onOpenGoals('Overdue Goals', WorkStatusFilter.overdue)),
        ]),
        const SizedBox(height: 10),
        _metricRow([
          _scoreTile('Total tasks', '${tasks.total}', white, () => onOpenTasks('Tasks', WorkStatusFilter.all)),
          _scoreTile('Completed', '${tasks.completed}', green, () => onOpenTasks('Completed Tasks', WorkStatusFilter.completed)),
          _scoreTile('Pending', '${tasks.pending}', white, () => onOpenTasks('Pending Tasks', WorkStatusFilter.pending)),
          _scoreTile('Overdue', '${tasks.overdue}', tasks.overdue > 0 ? red : white, () => onOpenTasks('Overdue Tasks', WorkStatusFilter.overdue)),
        ]),
        const SizedBox(height: 10),
        _metricRow([
          _scoreTile('Task on-time', _pace(_taskOnTime), green, () => onOpenTasks('On-time Tasks', WorkStatusFilter.onTime)),
          _scoreTile('Task delayed', _pace(_taskDelayed), amber, () => onOpenTasks('Delayed Tasks', WorkStatusFilter.delayed)),
          _scoreTile('Goal on-time', _pace(_goalOnTime), green, () => onOpenGoals('On-time Goals', WorkStatusFilter.onTime)),
          _scoreTile('Goal delayed', _pace(_goalDelayed), amber, () => onOpenGoals('Delayed Goals', WorkStatusFilter.delayed)),
        ]),
      ],
    );
    final scoreCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF071A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: scoreSide,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              scoreCard,
              const SizedBox(height: 10),
              counts,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: scoreCard),
              const SizedBox(width: 10),
              Expanded(flex: 8, child: counts),
            ],
          ),
        );
      },
    );
  }

  Widget _metricRow(List<Widget> tiles) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _yearMark(String label, double? now, double? before) {
    //final delta = now != null && before != null ? now - before : null;
    // final up = delta != null && delta >= 1;
    // final down = delta != null && delta <= -1;
    // final color = up
    //     ? const Color(0xFF3DDC97)
    //     : down
    //         ? const Color(0xFFF87171)
    //         : const Color(0xB3FFFFFF);
    // final change = delta == null
    //     ? 'No ${year - 1} score'
    //     : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} vs ${year - 1}';
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        _scoreRing(now),
        // const SizedBox(height: 8),
        // Text(
        //   change,
        //   textAlign: TextAlign.center,
        //   style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
        // ),
      ],
    );
  }

  Widget _scoreRing(double? score) {
    final value = ((score ?? 0) / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFF163552),
              color: const Color(0xFF3DDC97),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score == null ? '-' : '${score.round()}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1),
              ),
              const SizedBox(height: 2),
              const Text('of 100', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreTile(String label, String value, Color color, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF071A2E),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difference(BuildContext context) {
    final performance = _diffChart(
      context,
      title: performanceTitle,
      current: _companySeries(_companyMonths, _performanceKeys, _shownMonths),
      previous: _companySeries(_previousCompanyMonths, _performanceKeys, _shownMonths),
    );
    final productivityChart = _diffChart(
      context,
      title: 'Company productivity by month',
      current: _companySeries(_companyMonths, _productivityKeys, _shownMonths),
      previous: _companySeries(_previousCompanyMonths, _productivityKeys, _shownMonths),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(children: [performance, const SizedBox(height: 12), productivityChart]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: performance),
            const SizedBox(width: 12),
            Expanded(child: productivityChart),
          ],
        );
      },
    );
  }

  Widget _diffChart(
    BuildContext context, {
    required String title,
    required List<double> current,
    required List<double> previous,
  }) {
    final shown = _shownMonths;
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: WebTheme.inkOf(context))),
          const SizedBox(height: 2),
          Text(
            'Bar $year    Line ${year - 1}',
            style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: 100,
                    alignment: BarChartAlignment.spaceAround,
                    groupsSpace: 8,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(color: WebTheme.lineOf(context), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: _axis(context, shown),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => WebTheme.dark,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final index = group.x.toInt() - 1;
                          if (index < 0 || index > 11) return null;
                          final past = index < previous.length ? previous[index] : 0.0;
                          return BarTooltipItem(
                            '${_names[index]}\n$year ${rod.toY.round()}\n${year - 1} ${past.round()}',
                            const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.35),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (var month = 1; month <= shown; month++)
                        BarChartGroupData(
                          x: month,
                          barRods: [
                            BarChartRodData(
                              toY: current[month - 1],
                              width: 14,
                              color: WebTheme.brand,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: LineChart(
                    LineChartData(
                      minX: 0.5,
                      maxX: shown + 0.5,
                      minY: 0,
                      maxY: 100,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: _hiddenAxis(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var month = 1; month <= shown; month++)
                              FlSpot(month.toDouble(), previous[month - 1]),
                          ],
                          isCurved: shown > 2,
                          color: const Color(0xFF64748B),
                          barWidth: 2.4,
                          dashArray: [6, 4],
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortDept(String name) {
    final clean = name.replaceAll(RegExp(r'\s+department$', caseSensitive: false), '').trim();
    if (clean.length <= 8) return clean;
    return clean.substring(0, 7);
  }

  Widget _departments(BuildContext context) {
    return _DepartmentComparison(
      year: year,
      month: month.clamp(1, 12),
      shownMonths: _shownMonths,
      departments: productivity,
      onSelectMonth: onSelectMonth,
      onOpenDepartment: onOpenDepartment,
    );
  }


  Widget _barKey(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context))),
      ],
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: child,
    );
  }

  Widget? _alertsPanel(BuildContext context, _WorkTotals tasks, _WorkTotals goals) {
    final rows = <Widget>[
      for (final row in departmentWarnings)
        if (row.count > 0)
          _alertLine(
            context,
            icon: Icons.warning_amber_rounded,
            title: row.count == 1
                ? '1 warning in ${row.department}'
                : '${row.count} warnings in ${row.department}',
            onTap: () => onOpenDepartmentWarnings == null
                ? onWarnings()
                : onOpenDepartmentWarnings!(row.department),
          ),
      if (departmentWarnings.isEmpty && warningCount > 0)
        _alertLine(
          context,
          icon: Icons.warning_amber_rounded,
          title: warningCount == 1 ? '1 warning' : '$warningCount warnings',
          onTap: onWarnings,
        ),
      if (goals.overdue > 0)
        _alertLine(
          context,
          icon: Icons.flag_outlined,
          title: goals.overdue == 1 ? '1 overdue goal' : '${goals.overdue} overdue goals',
          onTap: () => onOpenGoals('Overdue Goals', WorkStatusFilter.overdue),
        ),
      if (tasks.overdue > 0)
        _alertLine(
          context,
          icon: Icons.assignment_late_outlined,
          title: tasks.overdue == 1 ? '1 overdue task' : '${tasks.overdue} overdue tasks',
          onTap: () => onOpenTasks('Overdue Tasks', WorkStatusFilter.overdue),
        ),
      if (dueSoonGoals > 0)
        _alertLine(
          context,
          icon: Icons.event_outlined,
          title: dueSoonGoals == 1
              ? '1 goal overdue within 7 days'
              : '$dueSoonGoals goals overdue within 7 days',
          onTap: () => onOpenGoals('Goals overdue within 7 days', WorkStatusFilter.dueSoon),
        ),
      if (dueSoonTasks > 0)
        _alertLine(
          context,
          icon: Icons.event_outlined,
          title: dueSoonTasks == 1
              ? '1 task overdue within 7 days'
              : '$dueSoonTasks tasks overdue within 7 days',
          onTap: () => onOpenTasks('Tasks overdue within 7 days', WorkStatusFilter.dueSoon),
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
    required VoidCallback onTap,
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
            Icon(Icons.chevron_right_rounded, color: WebTheme.mutedOf(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _yearChip(BuildContext context) {
    return InkWell(
      onTap: onPickYear,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WebTheme.lineOf(context)),
        ),
        child: Text(
          '$year',
          style: TextStyle(fontWeight: FontWeight.w700, color: WebTheme.inkOf(context)),
        ),
      ),
    );
  }

  Widget _iconButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    int badge = 0,
    Color? iconColor,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: badge > 0,
        label: Text('$badge'),
        child: Icon(icon, color: iconColor ?? WebTheme.inkOf(context)),
      ),
    );
  }

  FlTitlesData _axis(BuildContext context, int shown) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 25,
          reservedSize: 28,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: TextStyle(fontSize: 10, color: WebTheme.mutedOf(context)),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final index = value.toInt() - 1;
            if (index < 0 || index >= shown) return const SizedBox.shrink();
            return Text(_names[index], style: TextStyle(fontSize: 10, color: WebTheme.mutedOf(context)));
          },
        ),
      ),
    );
  }

  FlTitlesData _hiddenAxis() {
    return const FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 28)),
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 22)),
    );
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

class _DepartmentComparison extends StatefulWidget {
  final int year;
  final int month;
  final int shownMonths;
  final List<Map<String, dynamic>> departments;
  final ValueChanged<int> onSelectMonth;
  final ValueChanged<String>? onOpenDepartment;

  const _DepartmentComparison({
    required this.year,
    required this.month,
    required this.shownMonths,
    required this.departments,
    required this.onSelectMonth,
    required this.onOpenDepartment,
  });

  @override
  State<_DepartmentComparison> createState() => _DepartmentComparisonState();
}

class _DepartmentComparisonState extends State<_DepartmentComparison> {
  static const _names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  bool _yearly = false;

  int _n(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _d(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _points(double? value) {
    if (value == null) return '-';
    final rounded = (value * 100).round() / 100;
    if (rounded == rounded.roundToDouble()) return rounded.toStringAsFixed(0);
    return rounded.toStringAsFixed(1);
  }

  Map<String, dynamic>? _monthRow(Map<String, dynamic> dept, int month) {
    final monthly = dept['monthlyData'] ?? dept['MonthlyData'] ?? dept['monthlyPerformance'];
    if (monthly is! List) return null;
    for (final item in monthly) {
      if (item is! Map) continue;
      if (_n(item['month'] ?? item['Month']) == month) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  double? _optional(Map<String, dynamic>? item, List<String> keys) {
    if (item == null) return null;
    for (final key in keys) {
      if (!item.containsKey(key) || item[key] == null) continue;
      return _d(item[key]);
    }
    return null;
  }

  double? _monthScore(Map<String, dynamic> dept, int month, List<String> keys) {
    return _optional(_monthRow(dept, month), keys);
  }

  double? _yearScore(Map<String, dynamic> dept, List<String> keys) {
    final values = <double>[];
    final last = widget.shownMonths.clamp(0, 12);
    for (var month = 1; month <= last; month++) {
      final value = _monthScore(dept, month, keys);
      if (value == null) continue;
      values.add(value);
    }
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _name(Map<String, dynamic> dept) {
    return (dept['department'] ?? dept['Department'] ?? '').toString().trim();
  }

  String _short(String name) {
    final clean = name.replaceAll(RegExp(r'\s+department$', caseSensitive: false), '').trim();
    if (clean.length <= 8) return clean;
    return clean.substring(0, 7);
  }

  List<_DirectoryRow> _rows() {
    const performanceKeys = ['totalScore', 'totalscore', 'TotalScore', 'performance', 'Performance'];
    const productivityKeys = ['productivity', 'Productivity'];
    final rows = <_DirectoryRow>[];
    final seen = <String>{};
    for (final dept in widget.departments) {
      final name = _name(dept);
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      final performance = _yearly
          ? _yearScore(dept, performanceKeys)
          : _monthScore(dept, widget.month, performanceKeys);
      final productivity = _yearly
          ? _yearScore(dept, productivityKeys)
          : _monthScore(dept, widget.month, productivityKeys);
      rows.add(_DirectoryRow(
        name: name,
        performance: performance ?? 0,
        productivityScore: productivity ?? 0,
      ));
    }
    rows.sort((a, b) => b.performance.compareTo(a.performance));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    final shown = widget.shownMonths.clamp(1, 12);
    final month = widget.month.clamp(1, shown);
    final when = _yearly
        ? 'Yearly average, ${_names.first} - ${_names[shown - 1]} ${widget.year}'
        : '${_names[month - 1]} ${widget.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department comparison',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: WebTheme.inkOf(context)),
          ),
          const SizedBox(height: 2),
          Text(
            when,
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _choice(context, 'Month', !_yearly, () => setState(() => _yearly = false)),
              _choice(context, 'Year', _yearly, () => setState(() => _yearly = true)),
              if (!_yearly)
                PopupMenuButton<int>(
                  onSelected: widget.onSelectMonth,
                  itemBuilder: (context) => [
                    for (var value = 1; value <= shown; value++)
                      PopupMenuItem(value: value, child: Text(_names[value - 1])),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: WebTheme.surfaceOf(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: WebTheme.brandOf(context), width: 1.4),
                    ),
                    child: Text(
                      _names[month - 1],
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WebTheme.brandOf(context)),
                    ),
                  ),
                ),
              _barKey(context, WebTheme.brand, 'Performance'),
              _barKey(context, const Color(0xFF94A3B8), 'Productivity'),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text('No departments to show yet.', style: TextStyle(color: WebTheme.mutedOf(context)))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final needed = rows.length * 42.0;
                final chartWidth = needed < constraints.maxWidth ? constraints.maxWidth : needed;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: 280,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: 100,
                        alignment: BarChartAlignment.spaceAround,
                        groupsSpace: 10,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(color: WebTheme.lineOf(context), strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchCallback: (event, response) {
                            if (event is! FlTapUpEvent || widget.onOpenDepartment == null) return;
                            final index = response?.spot?.touchedBarGroupIndex;
                            if (index == null || index < 0 || index >= rows.length) return;
                            widget.onOpenDepartment!(rows[index].name);
                          },
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => WebTheme.dark,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              if (groupIndex < 0 || groupIndex >= rows.length) return null;
                              final row = rows[groupIndex];
                              final text = rodIndex == 0
                                  ? '${row.name}\nPerformance - ${_points(row.performance)}'
                                  : 'Productivity - ${_points(row.productivityScore)}';
                              return BarTooltipItem(
                                text,
                                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 25,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 10, color: WebTheme.mutedOf(context)),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= rows.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Transform.rotate(
                                    angle: -0.7,
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      _short(rowName(rows, index)),
                                      style: TextStyle(fontSize: 9, color: WebTheme.mutedOf(context)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < rows.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: rows[i].performance.clamp(0, 100),
                                  width: 8,
                                  color: WebTheme.brand,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                                BarChartRodData(
                                  toY: rows[i].productivityScore.clamp(0, 100),
                                  width: 8,
                                  color: const Color(0xFF94A3B8),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ],
                            ),
                        ],
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

  String rowName(List<_DirectoryRow> rows, int index) => rows[index].name;

  Widget _choice(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? WebTheme.brand : WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? WebTheme.brand : WebTheme.brandOf(context), width: 1.4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : WebTheme.brandOf(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _barKey(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context))),
      ],
    );
  }
}

class _DirectoryRow {
  final String name;
  final double performance;
  final double productivityScore;
  const _DirectoryRow({
    required this.name,
    required this.performance,
    required this.productivityScore,
  });
}
