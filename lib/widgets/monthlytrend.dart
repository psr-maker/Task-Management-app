import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';

class MonthlyTrendChart extends StatefulWidget {
  final List<Map<String, dynamic>> monthlyData;

  const MonthlyTrendChart({super.key, required this.monthlyData});

  @override
  State<MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

class _MonthlyTrendChartState extends State<MonthlyTrendChart> {
  String selectedStatus = "All";
  double _calculateInterval() {
    if (widget.monthlyData.isEmpty) return 1;

    double maxY = 0;

    for (var data in widget.monthlyData) {
      maxY = [
        maxY,
        (data["completed"] ?? 0).toDouble(),
        (data["pending"] ?? 0).toDouble(),
        (data["overdue"] ?? 0).toDouble(),
      ].reduce((a, b) => a > b ? a : b);
    }

    if (maxY <= 0) return 1;

    final interval = (maxY / 5).ceilToDouble();

    return interval <= 0 ? 1 : interval;
  }

  double _getSafeMaxY() {
    if (widget.monthlyData.isEmpty) return 5;

    double maxY = 0;

    for (var data in widget.monthlyData) {
      maxY = [
        maxY,
        (data["completed"] ?? 0).toDouble(),
        (data["pending"] ?? 0).toDouble(),
        (data["overdue"] ?? 0).toDouble(),
      ].reduce((a, b) => a > b ? a : b);
    }

    return maxY <= 0 ? 5 : maxY + 2;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.monthlyData.any((data) {
      return (data["completed"] ?? 0) > 0 ||
          (data["pending"] ?? 0) > 0 ||
          (data["overdue"] ?? 0) > 0;
    });

    if (!hasData) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text("Monthly Trend", style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ["All", "Completed", "Pending", "Overdue"].map((status) {
              final bool isSelected = selectedStatus == status;

              Color statusColor;
              switch (status) {
                case "Completed":
                  statusColor = Colors.green;
                  break;
                case "Pending":
                  statusColor = Colors.orange;
                  break;
                case "Overdue":
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.blue;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedStatus = status;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.85),
                              statusColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : statusColor.withOpacity(0.2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: statusColor.withOpacity(0.4),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ]
                        : [],
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: isSelected ? 14 : 12,
                      color: isSelected ? Colors.white : statusColor,
                    ),
                    child: Text(status),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 30),

        SizedBox(
          height: 230,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: widget.monthlyData.isEmpty
                  ? 0
                  : widget.monthlyData.length.toDouble() - 1,
              minY: 0,
              maxY: _getSafeMaxY(),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _calculateInterval(),
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.labelSmall,
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= widget.monthlyData.length) {
                        return const SizedBox();
                      }

                      final monthNumber =
                          widget.monthlyData[index]["month"] as int;

                      const months = [
                        "Jan",
                        "Feb",
                        "Mar",
                        "Apr",
                        "May",
                        "Jun",
                        "Jul",
                        "Aug",
                        "Sep",
                        "Oct",
                        "Nov",
                        "Dec",
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          months[monthNumber - 1],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),

              lineBarsData: _buildWaveLines(),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => Colors.black87,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final index = spot.x.toInt();
                      final data = widget.monthlyData[index];

                      String label = "";
                      Color color =
                          spot.bar.gradient?.colors.first ?? Colors.white;

                      if (spot.barIndex == 0) {
                        label = "Completed: ${data['completed'] ?? 0}";
                      } else if (spot.barIndex == 1) {
                        label = "Pending: ${data['pending'] ?? 0}";
                      } else if (spot.barIndex == 2) {
                        label = "Overdue: ${data['overdue'] ?? 0}";
                      }

                      return LineTooltipItem(
                        "$label\n",
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<LineChartBarData> _buildWaveLines() {
    List<LineChartBarData> lines = [];

    if (selectedStatus == "All" || selectedStatus == "Completed") {
      lines.add(
        _createWaveLine(
          "completed",
          TaskUtils.getStatusColor(TaskStatus.completed),
        ),
      );
    }

    if (selectedStatus == "All" || selectedStatus == "Pending") {
      lines.add(
        _createWaveLine(
          "pending",
          TaskUtils.getStatusColor(TaskStatus.pending),
        ),
      );
    }

    if (selectedStatus == "All" || selectedStatus == "Overdue") {
      lines.add(_createWaveLine("overdue", Colors.red));
    }

    return lines;
  }

  LineChartBarData _createWaveLine(String key, Color color) {
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.4,
      barWidth: 3,
      isStrokeCapRound: true,
      gradient: LinearGradient(colors: [color, color.withOpacity(0.4)]),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
        ),
      ),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      spots: List.generate(widget.monthlyData.length, (i) {
        final value = (widget.monthlyData[i][key] ?? 0).toDouble();
        return FlSpot(i.toDouble(), value);
      }),
    );
  }
}

class ProductivityBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const ProductivityBarChart({super.key, required this.data});

  // ✅ MOVE months here (global inside class)
  static const List<String> months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Monthly Productivity",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 230,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: data.length < 4
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: List.generate(data.length, (index) {
                final value = (data[index]["productivity"] ?? 0)
                    .toDouble()
                    .clamp(0, 100);

                return GestureDetector(
                  onTap: () => _showDetails(context, data[index]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "${value.toInt()}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // BAR
                        Container(
                          height: 180,
                          width: 22,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: (value / 100) * 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: _getColor(value),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          months[(data[index]["month"] ?? 1) - 1],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getColor(double value) {
    if (value >= 90) return [Colors.green, Colors.greenAccent];
    if (value >= 70) return [Colors.blue, Colors.lightBlueAccent];
    if (value >= 40) return [Colors.orange, Colors.amber];
    return [Colors.red, Colors.redAccent];
  }

  void _showDetails(BuildContext context, Map item) {
    final monthIndex = (item["month"] ?? 1) - 1;
    final monthName = months[monthIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔘 HANDLE BAR (modern touch)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // 📅 HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$monthName ${DateTime.now().year}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${item["productivity"]}%",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Productivity",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),

              // 📊 CLEAN LIST
              _cleanRow(context, "Task Points", item["taskPoints"]),
              _cleanRow(context, "Goal Points", item["goalPoints"]),
              _cleanRow(context, "5S Points", item["fiveSPoints"]),
              _cleanRow(context, "Warranty Points", item["warrantyPoints"]),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _cleanRow(BuildContext context, String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          Text(
            value?.toString() ?? "0",
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class CapsuleBarChart extends StatelessWidget {
  final List<dynamic> data;

  const CapsuleBarChart({super.key, required this.data});

  String getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    const double maxHeight = 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SizedBox(
        //   height: 200,
        // child:
        const SizedBox(height: 20),
        Text(
          "Monthly Productivity",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: data.length < 4
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final int month = item["month"] ?? 1;

              final int value = item["productivity"] ?? 0;

              final double fillHeight = (value / 100) * maxHeight;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 🔥 % TEXT
                    Text(
                      "${value.toInt()}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 🔥 CAPSULE BACKGROUND
                    GestureDetector(
                      onTap: () => _showDetails(context, item),
                      child: SizedBox(
                        height: maxHeight,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // BACKGROUND (EMPTY CAPSULE)
                            Container(
                              width: 22,
                              height: maxHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),

                            // 🔥 FILLED PART
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOut,
                              width: 22,
                              height: fillHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: _getColor(value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 🔥 MONTH
                    Text(
                      getMonthName(month),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        //),
      ],
    );
  }

  // 🎨 COLOR BASED ON %
  Color _getColor(int value) {
    if (value >= 90) return Colors.green;
    if (value >= 70) return Colors.blue;
    if (value >= 40) return Colors.orange;
    return Colors.red;
  }

  void _showDetails(BuildContext context, Map item) {
    String monthName = getMonthName(item["month"] ?? 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔘 HANDLE BAR (modern touch)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // 📅 HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$monthName ${DateTime.now().year}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${item["productivity"]}%",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Productivity",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),

              // 📊 CLEAN LIST
              _cleanRow(context, "Task Points", item["taskPoints"]),
              _cleanRow(context, "Goal Points", item["goalPoints"]),
              _cleanRow(context, "5S Points", item["fiveSPoints"]),
              _cleanRow(context, "Warranty Points", item["warrantyPoints"]),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _cleanRow(BuildContext context, String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          Text(
            value?.toString() ?? "0",
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class YearlyProductivityPage extends StatelessWidget {
  final double yearlyProductivity;
  final int year;

  const YearlyProductivityPage({
    super.key,
    required this.yearlyProductivity,
    required this.year,
  });

  Color getProgressColor(double value) {
    if (value < 40) return Colors.red;
    if (value < 70) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (yearlyProductivity.clamp(0, 100)) / 100;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.background,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Yearly Productivity",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 10),

            Text(
              "$year",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 10.0,
              animation: true,
              percent: percent,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: Colors.white.withOpacity(0.2),
              progressColor: getProgressColor(yearlyProductivity),
              center: Text(
                '${yearlyProductivity.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.0,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              yearlyProductivity >= 80
                  ? "Excellent Performance 🚀"
                  : yearlyProductivity >= 60
                  ? "Good Performance 👍"
                  : "Needs Improvement ⚡",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class Alldeptproducticity extends StatefulWidget {
  const Alldeptproducticity({super.key});

  @override
  State<Alldeptproducticity> createState() => _AlldeptproducticityState();
}

class _AlldeptproducticityState extends State<Alldeptproducticity> {
  late int currentYear;
  late int currentMonth;

  late Future<List<Map<String, dynamic>>> futureData;

  @override
  void initState() {
    super.initState();
    currentYear = DateTime.now().year;
    currentMonth = DateTime.now().month;
    final selectedMonth = currentMonth > 1 ? currentMonth - 1 : 1;
    futureData = DashboardService.allgetDepartmentsProductivity(
      year: currentYear,
      month: selectedMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department Productivity',
          style: Theme.of(context).textTheme.displaySmall,
        ),

        const SizedBox(height: 12),

        FutureBuilder<List<Map<String, dynamic>>>(
          future: futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data'));
            }
            final departments = snapshot.data!;
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                  },
                  border: TableBorder(
                    verticalInside: BorderSide(color: Colors.grey),
                    horizontalInside: BorderSide(color: Colors.grey),
                  ),
                  children: [
                    // ================= HEADER =================
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      children: [
                        _tableHeader('Department'),
                        _tableHeader('Month'),
                        _tableHeader('Productivity'),
                      ],
                    ),
                    // ================= DATA =================
                    ...departments.map((dept) {
                      final monthlyData = List<Map<String, dynamic>>.from(
                        dept['monthlyData'],
                      );
                      int month = currentMonth > 1 ? currentMonth - 1 : 1;
                      double productivity = 0;
                      if (monthlyData.isNotEmpty) {
                        month = monthlyData.first['month'];
                        productivity =
                            (monthlyData.first['productivity'] as num)
                                .toDouble();
                      }
                      return TableRow(
                        children: [
                          _tableCell(dept['department']),
                          _tableCell(_getMonthName(month)),
                          _tableCell(
                            '${productivity.toInt()} %',
                            color: _getProductivityColor(productivity),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ================= HEADER =================
  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }

  // ================= CELL =================
  Widget _tableCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  // ================= COLOR =================
  Color _getProductivityColor(double value) {
    if (value >= 80) return Theme.of(context).colorScheme.secondary;
    if (value >= 50) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }

  // ================= MONTH =================
  String _getMonthName(int month) {
    const months = [
      '',
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
    return months[month];
  }
}
