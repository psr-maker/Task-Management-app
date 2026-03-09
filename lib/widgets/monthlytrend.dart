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
                        TextStyle(color: color, fontWeight: FontWeight.w600),
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
