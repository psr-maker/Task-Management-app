import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

    return (maxY / 5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Segmented Status Selector
        /// Segmented Status Selector - Advanced Version
        /// Advanced Status Selector with Status Colors
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ["All", "Completed", "Pending", "Overdue"].map((status) {
              final bool isSelected = selectedStatus == status;

              // Assign colors based on status
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
                  statusColor = Colors.blue; // "All" or unknown
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

        /// Chart
        SizedBox(
          height: 230,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: widget.monthlyData.isEmpty
                  ? 0
                  : widget.monthlyData.length.toDouble() - 1,
              minY: 0,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),

              /// Axis Titles
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _calculateInterval(),
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              /// Dynamic Lines
              lineBarsData: _buildWaveLines(),

              /// Tooltip
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  //  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final data = widget.monthlyData[spot.x.toInt()];
                      return LineTooltipItem(
                        "Completed: ${data['completed'] ?? 0}\n"
                        "Pending: ${data['pending'] ?? 0}\n"
                        "Overdue: ${data['overdue'] ?? 0}",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
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

  /// Build Multiple Lines Based On Selected Status
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

  /// Create Single Wave Line
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

class MonthlyTrendCharts extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyTrend;

  const MonthlyTrendCharts({super.key, required this.monthlyTrend});

  static const List<String> _months = [
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
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(monthlyTrend.length, (index) {
          final data = monthlyTrend[index];

          final completed = (data['completed'] ?? 0).toDouble();
          final pending = (data['pending'] ?? 0).toDouble();
          final notStarted = (data['notStarted'] ?? 0).toDouble();
          final overdue = (data['overdue'] ?? 0).toDouble();
          final inprogress = (data['inProgress'] ?? 0).toDouble();
          return _buildMonthColumn(
            month: _months[index],
            completed: completed,
            pending: pending,
            notStarted: notStarted,
            overdue: overdue,
            inprogress: inprogress,
          );
        }),
      ),
    );
  }

  Widget _buildMonthColumn({
    required String month,
    required double completed,
    required double pending,
    required double notStarted,
    required double overdue,
    required double inprogress,
  }) {
    List<Widget> items = [];

    void addBar(double value, Color color) {
      if (value > 0) {
        items.add(_buildBar(value, color));
        items.add(const SizedBox(height: 4));
        items.add(
          Text(value.toInt().toString(), style: const TextStyle(fontSize: 11)),
        );
        items.add(const SizedBox(height: 14));
      }
    }

    addBar(completed, Colors.green);
    addBar(pending, Colors.orange);
    addBar(notStarted, Colors.grey);
    addBar(inprogress, Colors.deepOrange);
    addBar(overdue, Colors.red);

    if (items.isNotEmpty) {
      items.removeLast();
    }

    items.add(const SizedBox(height: 12));
    items.add(
      Text(
        month,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );

    return Column(mainAxisAlignment: MainAxisAlignment.end, children: items);
  }

  Widget _buildBar(double value, Color color) {
    return Container(
      width: 40,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
