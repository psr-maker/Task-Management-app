import 'package:flutter/material.dart';

double completionPercent(dynamic completed, dynamic total) {
  final done = completed is num
      ? completed.toDouble()
      : double.tryParse('${completed ?? ''}') ?? 0;
  final all = total is num
      ? total.toDouble()
      : double.tryParse('${total ?? ''}') ?? 0;
  if (all <= 0) return 0;
  final value = done / all * 100;
  if (value < 0) return 0;
  if (value > 100) return 100;
  return value;
}

double? ringPercent(dynamic total, double? value) {
  final count = total is num
      ? total.toDouble()
      : double.tryParse('${total ?? ''}') ?? 0;
  if (count <= 0 || value == null) return null;
  if (value < 0) return 0;
  if (value > 100) return 100;
  return value;
}

class KpiCircleCard extends StatelessWidget {
  final String title;
  final double? goalPercent;
  final double? taskPercent;
  final VoidCallback? onTap;

  const KpiCircleCard({
    super.key,
    required this.title,
    this.goalPercent,
    this.taskPercent,
    this.onTap,
  });

  Color getKpiColor(double percent) {
    if (percent < 40) {
      return Colors.red;
    } else if (percent < 70) {
      return Colors.orange;
    } else if (percent < 85) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGoal = goalPercent != null;
    final hasTask = taskPercent != null;
    final dual = hasGoal && hasTask;
    final goalColor = hasGoal ? getKpiColor(goalPercent!) : Colors.grey;
    final taskColor = hasTask ? getKpiColor(taskPercent!) : Colors.grey;
    final outerSize = dual ? 92.0 : 78.0;

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (hasGoal)
              SizedBox(
                width: outerSize,
                height: outerSize,
                child: CircularProgressIndicator(
                  value: (goalPercent! / 100).clamp(0.0, 1.0),
                  strokeWidth: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                ),
              ),
            if (hasTask)
              SizedBox(
                width: dual ? 62 : outerSize,
                height: dual ? 62 : outerSize,
                child: CircularProgressIndicator(
                  value: (taskPercent! / 100).clamp(0.0, 1.0),
                  strokeWidth: dual ? 6 : 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(taskColor),
                ),
              ),
            if (!hasGoal && !hasTask)
              SizedBox(
                width: outerSize,
                height: outerSize,
                child: CircularProgressIndicator(
                  value: 0,
                  strokeWidth: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasGoal)
                  Text(
                    "G-${goalPercent!.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      height: 1.15,
                      color: goalColor,
                    ),
                  ),
                if (hasTask)
                  Text(
                    "T-${taskPercent!.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      height: 1.15,
                      color: taskColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: card,
        ),
      ),
    );
  }
}
