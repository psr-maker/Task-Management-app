import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

/// Manager home in the staff-board layout, scored for one department.
class ManagerReport extends StatelessWidget {
  final String department;
  final int year;
  final int month;
  final Map<String, dynamic> summary;
  final List monthly;
  final List breakdown;
  final VoidCallback onPickYear;
  final ValueChanged<int> onSelectMonth;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenSettings;
  final void Function(String title, WorkStatusFilter filter) onOpenTasks;
  final void Function(String title, WorkStatusFilter filter) onOpenGoals;
  final int warningCount;
  final int dueSoonGoals;
  final int dueSoonTasks;
  final VoidCallback? onWarnings;
  final String roleLabel;
  final List<String> scopedDepartments;
  final List<Map<String, dynamic>> departmentSeries;
  final VoidCallback? onOpenUsers;
  final ValueChanged<String>? onOpenDepartment;
  final void Function(
    int userId,
    String role,
    String name,
    String department,
  )? onOpenStaff;

  const ManagerReport({
    super.key,
    required this.department,
    required this.year,
    required this.month,
    required this.summary,
    required this.monthly,
    this.breakdown = const [],
    required this.onPickYear,
    required this.onSelectMonth,
    required this.onOpenReports,
    required this.onOpenSettings,
    required this.onOpenTasks,
    required this.onOpenGoals,
    this.warningCount = 0,
    this.dueSoonGoals = 0,
    this.dueSoonTasks = 0,
    this.onWarnings,
    this.roleLabel = 'Manager',
    this.scopedDepartments = const [],
    this.departmentSeries = const [],
    this.onOpenUsers,
    this.onOpenDepartment,
    this.onOpenStaff,
  });

  bool get _divisionView => departmentSeries.isNotEmpty;

  static const _names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int get _month => month.clamp(1, 12);

  int _n(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _d(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _pct(double? value) {
    if (value == null) return '—';
    return '${value.round()}%';
  }

  String _points(double? value) {
    if (value == null) return '—';
    return _fmt(value);
  }

  String _trim(double value) {
    final rounded = (value * 100).round() / 100;
    final text = rounded.toStringAsFixed(2);
    if (text.endsWith('.00')) return rounded.toStringAsFixed(0);
    if (text.endsWith('0')) return rounded.toStringAsFixed(1);
    return text;
  }

  String _score(double? value) {
    if (value == null) return '—';
    return _trim(value);
  }

  double? _summaryValue(List<String> keys) {
    for (final key in keys) {
      if (!summary.containsKey(key) || summary[key] == null) continue;
      return _d(summary[key]);
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

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Map<String, dynamic>? _find(int month) {
    for (final item in monthly) {
      if (item is! Map) continue;
      if (_n(item['month'] ?? item['Month']) == month) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  double _field(Map<String, dynamic>? item, List<String> keys) {
    if (item == null) return 0;
    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) return _d(item[key]);
    }
    return 0;
  }

  int _completedThrough() {
    final now = DateTime.now();
    if (year < now.year) return 12;
    if (year == now.year) return now.month <= 1 ? 0 : now.month - 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppLayout.isMobile(context);
    return SingleChildScrollView(
      padding: mobile
          ? const EdgeInsets.fromLTRB(12, 8, 12, 20)
          : AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mobile) ...[
            _header(context),
            const SizedBox(height: 14),
          ],
          if (_divisionView) ...[
            _divisionCounts(context),
            const SizedBox(height: 12),
            _divisionCharts(context),
            const SizedBox(height: 12),
          ] else
            _scoreCards(context),
          if (!_divisionView) ...[
            const SizedBox(height: 12),
            _DepartmentUsersCard(
              department: department,
              departments: scopedDepartments,
              reportedCount: _n(summary['totalUsers'] ?? summary['TotalUsers']),
              onOpenUsers: onOpenUsers,
            ),
            const SizedBox(height: 12),
            _trendAndBreakdown(context),
          ],
          const SizedBox(height: 12),
          _taskAndGoalBoards(context),
          const SizedBox(height: 12),
          _performers(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          department.trim().isEmpty ? 'Department' : department.trim(),
          style: TextStyle(
            fontSize: AppLayout.isMobile(context) ? 20 : 22,
            fontWeight: FontWeight.w800,
            color: WebTheme.inkOf(context),
          ),
        ),
        Text(
          roleLabel,
          style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
        ),
      ],
    );
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _menuChip(context, label: _names[_month - 1]),
        _plainChip(context, '$year', onPickYear),
        if (onWarnings != null)
          _roundIcon(
            context,
            Icons.warning_amber_rounded,
            'Warnings',
            onWarnings!,
            badge: warningCount,
            iconColor: const Color(0xFFFFC107),
          ),
        _roundIcon(context, Icons.bar_chart_rounded, 'Reports', onOpenReports),
        _roundIcon(
          context,
          Icons.settings_outlined,
          'Settings',
          onOpenSettings,
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
          children: [Expanded(child: title), controls],
        );
      },
    );
  }

  Widget _scoreCards(BuildContext context) {
    final doneThrough = _completedThrough();
    final range = doneThrough <= 0
        ? 'No department score yet'
        : 'Jan – ${_names[doneThrough - 1]} $year';
    final monthName = '${_names[_month - 1]} $year';
    final yearlyPerformance = _summaryValue(const [
      'departmentYearlyPerformance',
      'DepartmentYearlyPerformance',
      'departmentPerformance',
      'DepartmentPerformance',
    ]);
    final yearlyProductivity = _summaryValue(const [
      'departmentYearlyProductivity',
      'DepartmentYearlyProductivity',
      'departmentProductivity',
      'DepartmentProductivity',
    ]);
    final monthRow = _find(_month);
    final monthPerformance = _optional(monthRow, const [
      'performance',
      'Performance',
      'totalScore',
      'totalscore',
      'TotalScore',
    ]);
    final monthProductivity = _optional(monthRow, const [
      'productivity',
      'Productivity',
    ]);
    return _ScrollPlay(
      builder: (context, motion) => _lift(
        motion,
        child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final cols = compact
            ? 2
            : constraints.maxWidth >= 900
            ? 4
            : 2;
        final gap = 10.0;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final cards = [
          _kpi(
            context,
            label: 'Yearly performance',
            value: _score(yearlyPerformance),
            foot: range,
            scale: 'out of 100',
            compact: compact,
          ),
          _kpi(
            context,
            label: 'Monthly performance',
            value: _score(monthPerformance),
            foot: monthName,
            scale: 'out of 100',
            compact: compact,
          ),
          _kpi(
            context,
            label: 'Yearly productivity',
            value: _score(yearlyProductivity),
            foot: range,
            scale: 'out of 100',
            compact: compact,
          ),
          _kpi(
            context,
            label: 'Monthly productivity',
            value: _score(monthProductivity),
            foot: monthName,
            scale: 'out of 100',
            compact: compact,
          ),
        ];
        if (!compact && cols == 4) {
          final ordered = [cards[0], cards[2], cards[1], cards[3]];
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in ordered) SizedBox(width: width, child: card),
            ],
          );
        }
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    ),
      ),
    );
  }

  Widget _divisionCounts(BuildContext context) {
    final users = _n(summary['totalUsers'] ?? summary['TotalUsers']);
    final departments = departmentSeries.length;
    final mobile = AppLayout.isMobile(context);
    return Row(
      children: [
        Expanded(
          child: _countCard(
            context,
            label: 'Total users',
            value: '$users',
            foot: 'Tap to open a person',
            icon: Icons.people_outline_rounded,
            onTap: () => _openDivisionUsers(context),
            compact: mobile,
          ),
        ),
        SizedBox(width: mobile ? 8 : 12),
        Expanded(
          child: _countCard(
            context,
            label: 'Total departments',
            value: '$departments',
            foot: 'Tap to open a department',
            icon: Icons.apartment_rounded,
            onTap: () => _openDivisionDepartments(context),
            compact: mobile,
          ),
        ),
      ],
    );
  }

  Widget _countCard(
    BuildContext context, {
    required String label,
    required String value,
    required String foot,
    required IconData icon,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: WebTheme.card(context, radius: 16),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WebTheme.brandSoftOf(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: WebTheme.brandOf(context), size: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: WebTheme.mutedOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                  ],
                )
              : Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WebTheme.brandSoftOf(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: WebTheme.brandOf(context), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.mutedOf(context),
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                    Text(
                      foot,
                      style: TextStyle(
                        fontSize: 11,
                        color: WebTheme.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: WebTheme.mutedOf(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _openDivisionUsers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScopedUserList(
          departments: scopedDepartments,
          onOpen: onOpenStaff,
        ),
      ),
    );
  }

  void _openDivisionDepartments(BuildContext context) {
    final names = [
      for (final row in departmentSeries)
        (row['department'] ?? '').toString().trim(),
    ].where((name) => name.isNotEmpty).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScopedDepartmentList(
          departments: names,
          onOpen: onOpenDepartment,
        ),
      ),
    );
  }

  Widget _divisionCharts(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        final comparison = _departmentComparison(context);
        final breakdown = _SelectableBreakdown(
          departments: [
            for (final row in departmentSeries)
              (row['department'] ?? '').toString().trim(),
          ].where((name) => name.isNotEmpty).toList(),
          builder: (selected) => _breakdownCard(
            context,
            focusDepartment: selected,
          ),
        );
        if (stacked) {
          return Column(
            children: [
              comparison,
              const SizedBox(height: 12),
              breakdown,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: comparison),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: breakdown),
          ],
        );
      },
    );
  }

  List<({String name, double performance, double productivity})> _compareRows() {
    final rows = <({String name, double performance, double productivity})>[];
    for (final dept in departmentSeries) {
      final name = (dept['department'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final row = _monthIn(dept['monthlyData'], _month);
      rows.add((
        name: name,
        performance: _field(row, const [
          'totalScore',
          'totalscore',
          'TotalScore',
        ]),
        productivity: _field(row, const ['productivity', 'Productivity']),
      ));
    }
    return rows;
  }

  Map<String, dynamic>? _monthIn(dynamic monthly, int month) {
    if (monthly is! List) return null;
    for (final item in monthly) {
      if (item is! Map) continue;
      if (_n(item['month'] ?? item['Month']) == month) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  Map<String, dynamic>? _departmentMonth(String departmentName) {
    final key = DivisionConfig.normalize(departmentName);
    for (final dept in departmentSeries) {
      final name = (dept['department'] ?? '').toString();
      if (DivisionConfig.normalize(name) != key) continue;
      return _monthIn(dept['monthlyData'], _month);
    }
    return null;
  }

  Widget _departmentComparison(BuildContext context) {
    final rows = _compareRows();
    final when = '${_names[_month - 1]} $year';
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WebTheme.brandOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rows.length <= 8
                ? '$when · tap a bar to see its scores'
                : '$when · scroll across ${rows.length} departments. Tap a bar to see its scores.',
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              _legend(context, WebTheme.brandOf(context), 'Performance'),
              _legend(context, const Color(0xFF94A3B8), 'Productivity'),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              'No departments to show yet.',
              style: TextStyle(color: WebTheme.mutedOf(context)),
            )
          else
            _ComparisonChart(
              rows: rows,
              onOpen: onOpenDepartment,
            ),
        ],
      ),
    );
  }

  Widget _trendAndBreakdown(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        final trend = _trendCard(context);
        final breakdown = _breakdownCard(context);
        if (stacked) {
          return Column(
            children: [trend, const SizedBox(height: 12), breakdown],
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
    final last = _completedThrough();
    for (var month = 1; month <= last; month++) {
      final row = _find(month);
      final productivityScore = _optional(row, const [
        'productivity',
        'Productivity',
      ]);
      final performanceScore = _optional(row, const [
        'performance',
        'Performance',
        'totalScore',
        'totalscore',
        'TotalScore',
      ]);
      if (productivityScore == null && performanceScore == null) continue;
      productivity.add(
        FlSpot(month.toDouble(), (productivityScore ?? 0).clamp(0, 100)),
      );
      performance.add(
        FlSpot(month.toDouble(), (performanceScore ?? 0).clamp(0, 100)),
      );
    }
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics trend · $year',
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
            Text(
              'No monthly scores for this year.',
              style: TextStyle(color: WebTheme.mutedOf(context)),
            )
          else
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 12,
                  minY: 0,
                  maxY: 112,
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
                    _line(_wave(productivity, play), WebTheme.brandOf(context)),
                    _line(_wave(performance, play), WebTheme.inkOf(context), dashed: true),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  LineTooltipItem _monthTooltip(int month) {
    final name = month >= 1 && month <= 12 ? _names[month - 1] : '';
    final row = _find(month);
    final text = row == null
        ? '$name\nNo department score yet'
        : '$name\nPerformance - ${_score(_optional(row, const ['performance', 'Performance', 'totalScore', 'totalscore', 'TotalScore']))}\nProductivity - ${_score(_optional(row, const ['productivity', 'Productivity']))}';
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

  Widget _breakdownCard(
    BuildContext context, {
    double? motion,
    String? focusDepartment,
  }) {
    if (motion == null) {
      return _ScrollPlay(
        builder: (context, t) => _breakdownCard(
          context,
          motion: t,
          focusDepartment: focusDepartment,
        ),
      );
    }
    final play = motion;
    final selected = focusDepartment == null
        ? _monthIn(breakdown, _month)
        : _departmentMonth(focusDepartment);
    final performance = _optional(selected, const [
      'totalScore',
      'totalscore',
      'TotalScore',
      'performance',
      'Performance',
    ]);
    final productivity = _optional(selected, const [
      'productivity',
      'Productivity',
    ]);
    final goal = _field(selected, const ['goalPoints', 'GoalPoints']);
    final task = _field(selected, const ['taskPoints', 'TaskPoints']);
    final attitude = _field(selected, const ['attitudeScore', 'AttitudeScore']);
    final fiveS = _field(selected, const ['fiveS', 'FiveS', 'fiveSPoints']);
    final monthName = '${_names[_month - 1]} $year';
    final titleName = (focusDepartment ?? department).trim();
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
            '${titleName.isEmpty ? 'Department' : titleName} · $monthName',
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
                scale: 'out of 75',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selected == null)
            Text(
              'No score recorded for this month.',
              style: TextStyle(color: WebTheme.mutedOf(context)),
            )
          else ...[
            Text(
              'PRODUCTIVITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: WebTheme.mutedOf(context),
              ),
            ),
            const SizedBox(height: 6),
            _breakRow(context, 'Task · 35', task, 35, motion: play),
            _breakRow(context, 'Goal · 40', goal, 40, motion: play),
            const SizedBox(height: 4),
            Text(
              'PERFORMANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: WebTheme.mutedOf(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Productivity + attitude + 5S',
              style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
            ),
            const SizedBox(height: 8),
            _breakRow(
              context,
              'Productivity',
              productivity ?? 0,
              75,
              motion: play,
            ),
            _breakRow(context, 'Attitude · 15', attitude, 15, motion: play),
            _breakRow(context, '5S · 10', fiveS, 10, motion: play),
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
              _score(value),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;
        final taskCard = _measureCard(
          context,
          title: 'Tasks',
          subtitle: 'Department tasks in this year',
          noun: 'tasks',
          totals: tasks,
          onTime: summary.containsKey('onTimeTasks')
              ? _n(summary['onTimeTasks'])
              : null,
          delayed: summary.containsKey('delayedTasks')
              ? _n(summary['delayedTasks'])
              : null,
          completedPercent: _stored(const [
            'taskCompletionPercentage',
            'taskCompletionPercent',
          ]),
          onTimePercent: _stored(const [
            'onTimeTaskCompletionPercentage',
            'taskOnTimePercent',
          ]),
          delayedPercent: _stored(const [
            'delayedTaskPercentage',
            'delayedTaskPercent',
          ]),
          onOpen: onOpenTasks,
        );
        final goalCard = _measureCard(
          context,
          title: 'Goals',
          subtitle: 'Department goals this year',
          noun: 'goals',
          totals: goals,
          onTime: summary.containsKey('onTimeGoals')
              ? _n(summary['onTimeGoals'])
              : null,
          delayed: summary.containsKey('delayedGoals')
              ? _n(summary['delayedGoals'])
              : summary.containsKey('delayedGoalsCount')
              ? _n(summary['delayedGoalsCount'])
              : null,
          completedPercent: _stored(const [
            'goalCompletionPercentage',
            'goalCompletionPercent',
          ]),
          onTimePercent: _stored(const [
            'onTimeGoalCompletionPercentage',
            'goalOnTimePercent',
          ]),
          delayedPercent: _stored(const [
            'delayedGoalPercentage',
            'delayedGoalPercent',
          ]),
          onOpen: onOpenGoals,
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

  Widget _performers(BuildContext context, {double? motion}) {
    if (motion == null) {
      return _ScrollPlay(
        builder: (context, t) => _performers(context, motion: t),
      );
    }
    final play = motion;
    final top = _people('topPerformers');
    final low = _people('lowPerformers');
    return _lift(
      play,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 860;
          final topCard = _peopleCard(
            context,
            title: 'Top performers',
            subtitle: 'Above 80 on performance or productivity',
            people: top,
            accent: WebTheme.brandOf(context),
            icon: Icons.emoji_events_outlined,
            mark: 80,
            high: true,
            empty: 'No one in $department is above 80.',
            motion: play,
          );
          final lowCard = _peopleCard(
            context,
            title: 'Low performers',
            subtitle: '50 or below on performance or productivity',
            people: low,
            accent: WebTheme.danger,
            icon: Icons.trending_down_rounded,
            mark: 50,
            high: false,
            empty: 'No one in $department is at 50 or below.',
            motion: play,
          );
          if (stacked) {
            return Column(
              children: [topCard, const SizedBox(height: 12), lowCard],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: topCard),
              const SizedBox(width: 12),
              Expanded(child: lowCard),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _people(String key) {
    final raw = summary[key] ?? summary[_pascal(key)];
    if (raw is! List) return [];
    final people = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final person = Map<String, dynamic>.from(item);
      final dept = (person['department'] ?? person['Department'] ?? '')
          .toString()
          .trim();
      if (dept.isNotEmpty && !_personInScope(dept)) continue;
      people.add(person);
    }
    return people;
  }

  bool _personInScope(String departmentName) {
    if (scopedDepartments.isNotEmpty) {
      return DivisionConfig.isAllowedDepartment(
        departmentName,
        scopedDepartments,
      );
    }
    return departmentName.toLowerCase() == department.trim().toLowerCase();
  }

  String _pascal(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  Widget _peopleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> people,
    required Color accent,
    required IconData icon,
    required double mark,
    required bool high,
    required String empty,
    required double motion,
  }) {
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.inkOf(context),
                  ),
                ),
              ),
              Text(
                '${people.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
          ),
          const SizedBox(height: 4),
          if (people.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(empty, style: TextStyle(color: WebTheme.mutedOf(context))),
            )
          else
            for (var i = 0; i < people.length; i++)
              _personRow(
                context,
                people[i],
                accent,
                index: i,
                count: people.length,
                mark: mark,
                high: high,
                motion: motion,
              ),
        ],
      ),
    );
  }

  Widget _personRow(
    BuildContext context,
    Map<String, dynamic> person,
    Color accent, {
    required int index,
    required int count,
    required double mark,
    required bool high,
    required double motion,
  }) {
    final rise = _rise(index, count, motion);
    final name = (person['employeeName'] ?? person['name'] ?? 'Staff')
        .toString();
    final performance = _d(
      person['performance'] ?? person['Performance'] ?? person['totalScore'],
    );
    final productivity = _d(person['productivity'] ?? person['Productivity']);
    final scoreMonth = _n(person['scoreMonth'] ?? person['month']);
    final scoreYear = _n(person['scoreYear'] ?? person['year']);
    final when = scoreMonth >= 1 && scoreMonth <= 12 && scoreYear > 0
        ? '${_names[scoreMonth - 1]} $scoreYear'
        : 'Latest score';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final userId = _personId(person);
    final role = (person['role'] ?? person['Role'] ?? '').toString();
    final department = (person['department'] ??
            person['Department'] ??
            person['departmentName'] ??
            person['DepartmentName'] ??
            '')
        .toString();
    return Opacity(
      opacity: rise.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * 14),
        child: GestureDetector(
          onTap: onOpenStaff == null || userId <= 0
              ? null
              : () => onOpenStaff!(userId, role, name, department),
          child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WebTheme.canvasOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                  ),
                  Text(
                    when,
                    style: TextStyle(
                      fontSize: 11,
                      color: WebTheme.mutedOf(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _scoreLine(
                      context,
                      'Performance',
                      performance,
                      100,
                      accent,
                      hot: high ? performance > mark : performance <= mark,
                      motion: rise,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _scoreLine(
                      context,
                      'Productivity',
                      productivity,
                      90,
                      accent,
                      hot: high ? productivity > mark : productivity <= mark,
                      motion: rise,
                    ),
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

  int _personId(Map<String, dynamic> person) {
    for (final key in const [
      'userId',
      'UserId',
      'employeeId',
      'EmployeeId',
      'id',
      'Id',
    ]) {
      final value = _n(person[key]);
      if (value > 0) return value;
    }
    return 0;
  }

  Widget _scoreLine(
    BuildContext context,
    String label,
    double value,
    double max,
    Color accent, {
    required bool hot,
    required double motion,
  }) {
    final scale = max <= 0 ? 1.0 : max;
    final grown = motion.clamp(0, 1);
    final shown = value * grown;
    final color = hot ? accent : WebTheme.inkOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
        ),
        const SizedBox(height: 2),
        Text(
          '${_fmt(shown)} / ${_fmt(max)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 4,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: WebTheme.lineOf(context)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ((value / scale).clamp(0, 1) * grown).toDouble(),
                  child: ColoredBox(color: hot ? accent : WebTheme.mutedOf(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _WorkTotals _workTotals({
    required String completedKey,
    required String pendingKey,
    required String overdueKey,
    required String totalKey,
  }) {
    final completed = _n(summary[completedKey]);
    final pending = _n(summary[pendingKey]);
    final overdue = _n(summary[overdueKey]);
    final storedTotal = _n(summary[totalKey]);
    final pendingIncludesOverdue =
        storedTotal == completed + pending && overdue <= pending;
    final overdueAlreadySeparate =
        storedTotal == completed + pending + overdue;
    final pendingShown = pendingIncludesOverdue || overdueAlreadySeparate
        ? pending
        : pending + overdue;
    final total = storedTotal > 0 ? storedTotal : completed + pendingShown;
    return _WorkTotals(
      total: total,
      completed: completed,
      pending: pendingShown,
      overdue: overdue,
    );
  }

  double? _stored(List<String> keys) {
    for (final key in keys) {
      if (!summary.containsKey(key) || summary[key] == null) continue;
      return _d(summary[key]);
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
    required double? completedPercent,
    required double? onTimePercent,
    required double? delayedPercent,
    required void Function(String title, WorkStatusFilter filter) onOpen,
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
          onOpen: onOpen,
          motion: t,
        ),
      );
    }
    final play = motion;
    final timed = (onTime ?? 0) + (delayed ?? 0);
    final completedPct =
        completedPercent ??
        (totals.total <= 0 ? null : totals.completed / totals.total * 100);
    final onTimePct = onTimePercent ??
        (onTime == null || timed <= 0 ? null : onTime / timed * 100);
    final delayedPct = delayedPercent ??
        (delayed == null || timed <= 0 ? null : delayed / timed * 100);
    return _lift(
      play,
      child: _panel(
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
                () => onOpen(title, WorkStatusFilter.all),
                motion: play,
              ),
              _figure(
                context,
                'Completed',
                '${totals.completed}',
                WebTheme.brandOf(context),
                () => onOpen('Completed $title', WorkStatusFilter.completed),
                motion: play,
              ),
              _figure(
                context,
                'Pending',
                '${totals.pending}',
                WebTheme.inkOf(context),
                () => onOpen('Pending $title', WorkStatusFilter.pending),
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
                () => onOpen('Overdue $title', WorkStatusFilter.overdue),
                motion: play,
              ),
              _figure(
                context,
                'On time',
                onTime == null ? '—' : '$onTime',
                WebTheme.brandOf(context),
                () => onOpen('On time $title', WorkStatusFilter.onTime),
                motion: play,
              ),
              _figure(
                context,
                'Delayed',
                delayed == null ? '—' : '$delayed',
                WebTheme.warning,
                () => onOpen('Delayed $title', WorkStatusFilter.delayed),
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
            motion: play,
          ),
          _ratioBar(
            context,
            'On-time %',
            onTimePct,
            WebTheme.inkOf(context),
            onTime == null ? '' : '$onTime on time ÷ $timed completed',
            motion: play,
          ),
          _ratioBar(
            context,
            'Delayed %',
            delayedPct,
            WebTheme.warning,
            delayed == null ? '' : '$delayed delayed ÷ $timed completed',
            motion: play,
          ),
        ],
      ),
    ),
    );
  }

  Widget _figure(
    BuildContext context,
    String label,
    String value,
    Color color,
    VoidCallback onTap, {
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
    double motion = 1,
  }) {
    final shown = (percent ?? 0).clamp(0, 100).toDouble() * motion.clamp(0, 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                percent == null ? '—' : '${shown.round()}%',
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
              value: percent == null ? 0 : shown / 100,
              color: color,
              backgroundColor: WebTheme.brandSoftOf(context),
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
    required String foot,
    String? scale,
    bool compact = false,
  }) {
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
    double max, {
    double motion = 1,
  }) {
    final scale = max <= 0 ? 1.0 : max;
    final grown = motion.clamp(0, 1);
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
                '${_fmt(now)} / ${_fmt(max)}',
                style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
              ),
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
                    widthFactor: ((now / scale).clamp(0, 1) * grown).toDouble(),
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
      if (warningCount > 0)
        _alertLine(
          context,
          icon: Icons.warning_amber_rounded,
          title: _divisionView
              ? (warningCount == 1
                    ? '1 warning in your departments'
                    : '$warningCount warnings in your departments')
              : warningCount == 1
              ? '1 employee warning'
              : '$warningCount employee warnings',
          onTap: onWarnings,
        ),
      if (goals.overdue > 0)
        _alertLine(
          context,
          icon: Icons.flag_outlined,
          title: _divisionView
              ? (goals.overdue == 1
                    ? '1 overdue goal in your departments'
                    : '${goals.overdue} overdue goals in your departments')
              : goals.overdue == 1
              ? '1 overdue goal'
              : '${goals.overdue} overdue goals',
          onTap: () => onOpenGoals('Overdue Goals', WorkStatusFilter.overdue),
        ),
      if (tasks.overdue > 0)
        _alertLine(
          context,
          icon: Icons.assignment_late_outlined,
          title: _divisionView
              ? (tasks.overdue == 1
                    ? '1 overdue task in your departments'
                    : '${tasks.overdue} overdue tasks in your departments')
              : tasks.overdue == 1
              ? '1 overdue task'
              : '${tasks.overdue} overdue tasks',
          onTap: () => onOpenTasks('Overdue Tasks', WorkStatusFilter.overdue),
        ),
      if (dueSoonGoals > 0)
        _alertLine(
          context,
          icon: Icons.event_outlined,
          title: dueSoonGoals == 1
              ? '1 goal overdue within 7 days'
              : '$dueSoonGoals goals overdue within 7 days',
          onTap: () => onOpenGoals(
            'Goals overdue within 7 days',
            WorkStatusFilter.dueSoon,
          ),
        ),
      if (dueSoonTasks > 0)
        _alertLine(
          context,
          icon: Icons.event_outlined,
          title: dueSoonTasks == 1
              ? '1 task overdue within 7 days'
              : '$dueSoonTasks tasks overdue within 7 days',
          onTap: () => onOpenTasks(
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

  Widget _menuChip(BuildContext context, {required String label}) {
    return PopupMenuButton<int>(
      onSelected: onSelectMonth,
      itemBuilder: (context) => [
        for (var month = 1; month <= 12; month++)
          PopupMenuItem(value: month, child: Text(_names[month - 1])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
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
    );
  }

  Widget _plainChip(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: WebTheme.surfaceOf(context),
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

  FlTitlesData _monthTitles(BuildContext context) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final index = value.toInt() - 1;
            if (index < 0 || index > 11) return const SizedBox.shrink();
            return Text(
              _names[index].substring(0, 1),
              style: TextStyle(fontSize: 10, color: WebTheme.mutedOf(context)),
            );
          },
        ),
      ),
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
    if (count <= 1) return Curves.easeOutCubic.transform(clamped);
    final start = index / count * 0.62;
    final local = ((clamped - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }

  List<FlSpot> _wave(List<FlSpot> spots, double t) {
    return [
      for (var i = 0; i < spots.length; i++)
        FlSpot(spots[i].x, spots[i].y * _waveAmount(i, spots.length, t)),
    ];
  }

  double _waveAmount(int index, int count, double t) {
    if (t >= 1 || count <= 0) return 1;
    final clamped = t.clamp(0.0, 1.0);
    final start = count <= 1 ? 0.0 : index / count * 0.7;
    final local = ((clamped - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(local).clamp(0.0, 1.12);
  }
}

class _DepartmentUsersCard extends StatefulWidget {
  final String department;
  final List<String> departments;
  final int reportedCount;
  final VoidCallback? onOpenUsers;

  const _DepartmentUsersCard({
    required this.department,
    this.departments = const [],
    required this.reportedCount,
    this.onOpenUsers,
  });

  @override
  State<_DepartmentUsersCard> createState() => _DepartmentUsersCardState();
}

class _DepartmentUsersCardState extends State<_DepartmentUsersCard> {
  int? _loadedCount;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final users = widget.departments.isEmpty
          ? await AdminService.getEmployeesByDepartment(widget.department)
          : await AdminService.getEmployeesByDepartments(widget.departments);
      if (!mounted) return;
      setState(() => _loadedCount = users.length);
    } catch (_) {}
  }

  int get _count {
    if (_loadedCount != null) return _loadedCount!;
    return widget.reportedCount;
  }

  void _openUsers() {
    if (widget.onOpenUsers != null) {
      widget.onOpenUsers!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Employees'),
          ),
          body: EmployeeList(
            department: widget.department,
            searchQuery: '',
            staffBoard: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openUsers,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppLayout.isMobile(context) ? 12 : 14),
          decoration: WebTheme.card(context, radius: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WebTheme.brandSoftOf(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  color: WebTheme.brandOf(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total users',
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.mutedOf(context),
                      ),
                    ),
                    Text(
                      '$_count',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                    Text(
                      widget.departments.length > 1
                          ? 'Everyone in your departments'
                          : 'Everyone in this department',
                      style: TextStyle(
                        fontSize: 11,
                        color: WebTheme.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: WebTheme.mutedOf(context),
              ),
            ],
          ),
        ),
      ),
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

class _SelectableBreakdown extends StatefulWidget {
  final List<String> departments;
  final Widget Function(String department) builder;

  const _SelectableBreakdown({
    required this.departments,
    required this.builder,
  });

  @override
  State<_SelectableBreakdown> createState() => _SelectableBreakdownState();
}

class _SelectableBreakdownState extends State<_SelectableBreakdown> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final names = widget.departments;
    final selected = names.contains(_selected)
        ? _selected!
        : (names.isEmpty ? '' : names.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (names.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: WebTheme.card(context, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.mutedOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final name in names) ...[
                        _deptChip(context, name, name == selected),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        widget.builder(selected),
      ],
    );
  }

  Widget _deptChip(BuildContext context, String name, bool selected) {
    final label = name.replaceAll(
      RegExp(r'\s+department$', caseSensitive: false),
      '',
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = name),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? WebTheme.brand : WebTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? WebTheme.brand : WebTheme.lineOf(context),
            ),
          ),
          child: Text(
            label.trim().isEmpty ? name : label.trim(),
            style: TextStyle(
              color: selected ? Colors.white : WebTheme.inkOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopedUserList extends StatefulWidget {
  final List<String> departments;
  final void Function(
    int userId,
    String role,
    String name,
    String department,
  )? onOpen;

  const _ScopedUserList({required this.departments, this.onOpen});

  @override
  State<_ScopedUserList> createState() => _ScopedUserListState();
}

class _ScopedUserListState extends State<_ScopedUserList> {
  late Future<List<UserModel>> _future;
  List<Role> _roles = [];

  @override
  void initState() {
    super.initState();
    _future = AdminService.getEmployeesByDepartments(widget.departments);
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await SuperAdminService.getRoles();
      if (!mounted) return;
      setState(() => _roles = roles);
    } catch (_) {}
  }

  String _roleName(String role) {
    final name = AppRoles.displayName(role, roles: _roles, fallback: 'Staff');
    return name.isEmpty ? 'Staff' : name;
  }

  Map<String, List<UserModel>> _group(List<UserModel> users) {
    final groups = <String, List<UserModel>>{};
    for (final user in users) {
      final name = user.department.trim().isEmpty
          ? 'Other'
          : user.department.trim();
      groups.putIfAbsent(name, () => []).add(user);
    }
    final names = groups.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final name in names) name: groups[name]!};
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Total users'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users in these departments'));
          }
          final groups = _group(users);
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            children: [
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final user in entry.value) _userTile(user, secondary),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _userTile(UserModel user, Color secondary) {
    final name = user.displayName.isEmpty ? user.name : user.displayName;
    final shown = name.trim().isEmpty ? 'Staff' : name.trim();
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: secondary,
          child: Text(
            shown.isNotEmpty ? shown[0].toUpperCase() : '?',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        title: Text(
          shown,
          style: TextStyle(
            color: secondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _roleName(user.role),
          style: TextStyle(
            color: WebTheme.inkOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: widget.onOpen == null || user.userId <= 0
            ? null
            : () => widget.onOpen!(
                  user.userId,
                  user.role,
                  shown,
                  user.department,
                ),
      ),
    );
  }
}

class _ScopedDepartmentList extends StatelessWidget {
  final List<String> departments;
  final ValueChanged<String>? onOpen;

  const _ScopedDepartmentList({required this.departments, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Departments'),
      ),
      body: departments.isEmpty
          ? const Center(child: Text('No departments'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: departments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final name = departments[index];
                final label = name
                    .replaceAll(
                      RegExp(r'\s+department$', caseSensitive: false),
                      '',
                    )
                    .trim();
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpen == null ? null : () => onOpen!(name),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: WebTheme.card(context, radius: 16),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: WebTheme.brandSoftOf(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.apartment_rounded,
                              color: WebTheme.brandOf(context),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label.isEmpty ? name : label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: WebTheme.inkOf(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Open department dashboard',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: WebTheme.mutedOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: WebTheme.mutedOf(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ComparisonChart extends StatefulWidget {
  final List<({String name, double performance, double productivity})> rows;
  final ValueChanged<String>? onOpen;

  const _ComparisonChart({required this.rows, this.onOpen});

  @override
  State<_ComparisonChart> createState() => _ComparisonChartState();
}

class _ComparisonChartState extends State<_ComparisonChart> {
  String _short(String name) {
    final clean = name
        .replaceAll(RegExp(r'\s+department$', caseSensitive: false), '')
        .trim();
    if (clean.length <= 10) return clean;
    return clean.substring(0, 9);
  }

  String _pct(double value) => '${value.round()}%';

  String _points(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final muted = WebTheme.mutedOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 248,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 42, top: 4, right: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final label in const ['100', '75', '50', '25', '0'])
                      Text(
                        label,
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final needed = rows.length * 72.0;
                    final chartWidth = needed < constraints.maxWidth
                        ? constraints.maxWidth
                        : needed;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        height: 248,
                        child: BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: 100,
                            alignment: BarChartAlignment.spaceAround,
                            groupsSpace: 12,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              checkToShowHorizontalLine: (value) => value <= 100,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: WebTheme.lineOf(context),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              handleBuiltInTouches: true,
                              touchCallback: (event, response) {
                                if (event is! FlTapUpEvent) return;
                                final index =
                                    response?.spot?.touchedBarGroupIndex;
                                if (index == null ||
                                    index < 0 ||
                                    index >= rows.length) {
                                  return;
                                }
                                widget.onOpen?.call(rows[index].name);
                              },
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => const Color(0xFF0F172A),
                                tooltipBorderRadius: BorderRadius.circular(8),
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                tooltipMargin: 6,
                                maxContentWidth: 220,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  if (groupIndex < 0 || groupIndex >= rows.length) {
                                    return null;
                                  }
                                  final row = rows[groupIndex];
                                  return BarTooltipItem(
                                    '${row.name}\nPerformance ${_pct(row.performance)}\nProductivity ${_points(row.productivity)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 42,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= rows.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _short(rows[index].name),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: muted,
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
                                  barsSpace: 4,
                                  barRods: [
                                    BarChartRodData(
                                      toY: rows[i].performance.clamp(0, 100),
                                      width: 10,
                                      color: WebTheme.brandOf(context),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
                                    ),
                                    BarChartRodData(
                                      toY: rows[i].productivity.clamp(0, 100),
                                      width: 10,
                                      color: const Color(0xFF94A3B8),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
