import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/admin_service.dart';

class TaskPointDetail extends StatefulWidget {
  final String taskName;
  final String assignedTo;
  final String taskId;
  final int staffId;

  final int systemPoints;
  final int? finalPoints;
  final bool isReviewed;
  final bool delayJustified;
  final String? delayReason;
  final String? comment;
  final Function(String message, {bool isError})? onShowMessage;
  final VoidCallback? onReviewSubmitted;
  const TaskPointDetail({
    super.key,
    required this.taskName,
    required this.assignedTo,
    required this.taskId,
    required this.systemPoints,
    this.finalPoints,
    required this.isReviewed,
    required this.delayJustified,
    this.delayReason,
    this.comment,
    this.onShowMessage,
    this.onReviewSubmitted, required this.staffId,
  });

  @override
  State<TaskPointDetail> createState() => _TaskPointDetailState();
}

class _TaskPointDetailState extends State<TaskPointDetail> {
  late int systemPoints;
  late int points;
  bool isSubmitted = false;
  late bool isReviewed;
  late bool delayJustified;

  bool isLoading = true;

  final TextEditingController commentController = TextEditingController();
  final TextEditingController delayReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();

    systemPoints = widget.systemPoints;
    points = widget.finalPoints ?? widget.systemPoints;

    delayJustified = widget.delayJustified;
    isReviewed = widget.finalPoints != null;
    commentController.text = widget.comment ?? "";
    delayReasonController.text = widget.delayReason ?? "";

    isLoading = false;
  }

  @override
  void dispose() {
    commentController.dispose();
    delayReasonController.dispose();
    super.dispose();
  }

  late final Function(String, {bool isError})? onShowMessage;

  void submitReview() async {
    try {
      await AdminService.submitReview(
        taskCode: widget.taskId,
        staffId: widget.staffId,
        managerPoints: points,
        isDelayJustified: delayJustified,
        delayReason: delayReasonController.text,
        comment: commentController.text,
      );
      widget.onShowMessage?.call(
        "Review submitted successfully",
        isError: false,
      );
      widget.onReviewSubmitted?.call();
    } catch (e) { 
      widget.onShowMessage?.call(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = Color.fromARGB(255, 25, 77, 38);
    final ink = isDark ? Colors.white : const Color(0xFF1C2B22);
    final muted = isDark ? const Color(0xFFB7C7BC) : const Color(0xFF66756C);
    final fieldFill = isDark ? const Color(0xFF102018) : const Color(0xFFF4F7F5);

    InputDecoration fieldDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: muted),
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3EBE6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3EBE6)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10241A) : const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Review",
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "System Points",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  "$systemPoints / 100",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Justified",
              style: TextStyle(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            value: delayJustified,
            activeThumbColor: Colors.white,
            activeTrackColor: green,
            onChanged: isReviewed
                ? null
                : (value) {
                    setState(() {
                      delayJustified = value;
                      if (!delayJustified) points = systemPoints;
                    });
                  },
          ),
          if (delayJustified) ...[
            Text(
              "Final points  $points / 100",
              style: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Slider(
              value: points.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: "$points",
              activeColor: green,
              onChanged: isReviewed
                  ? null
                  : (value) => setState(() => points = value.toInt()),
            ),
            Text(
              "Reason",
              style: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: delayReasonController,
              enabled: !isReviewed,
              maxLines: 2,
              style: TextStyle(color: ink),
              decoration: fieldDecoration("Add a reason"),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            "Comment",
            style: TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: commentController,
            enabled: !isReviewed,
            maxLines: 3,
            style: TextStyle(color: ink),
            decoration: fieldDecoration("Add a comment"),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: isReviewed ? "Already Submitted" : "Submit Review",
              color: green,
              txtcolor: Colors.white,
              onPressed: isReviewed ? null : submitReview,
            ),
          ),
        ],
      ),
    );
  }
}
