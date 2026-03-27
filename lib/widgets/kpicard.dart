import 'package:flutter/material.dart';

class KpiCircleCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final bool isPercentage;

  const KpiCircleCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isPercentage = false,
  });

  Color getKpiColor(double percent) {
    if (percent < 40) {
      return Colors.red;
    } else if (percent < 70) {
      return Colors.orange;
    } else if (percent < 85) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = isPercentage ? value : value * 100;

    double progress =
        isPercentage ? (value / 100).clamp(0.0, 1.0) : value.clamp(0.0, 1.0);

    final kpiColor = getKpiColor(percent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(kpiColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: kpiColor),
                const SizedBox(height: 4),
                Text(
                  isPercentage
                      ? "${value.toStringAsFixed(0)}%"
                      : value.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kpiColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 80,
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
  }
}
