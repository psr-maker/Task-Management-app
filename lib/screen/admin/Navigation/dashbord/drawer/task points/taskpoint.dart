import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/task_score.dart';

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
  final bool framed;
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
    this.onReviewSubmitted,
    required this.staffId,
    this.framed = true,
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
    final ink = WebTheme.inkOf(context);
    final muted = WebTheme.mutedOf(context);
    final line = WebTheme.lineOf(context);
    final brand = WebTheme.brand;

    InputDecoration fieldDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: muted, fontSize: 13),
        filled: true,
        fillColor: WebTheme.canvasOf(context),
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brand, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
      );
    }

    Widget fieldLabel(String text) {
      return Text(
        text,
        style: TextStyle(
          color: ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "System points",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                "$systemPoints / $taskScoreMax",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "Delay justified",
            style: TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            "Adjust the final points when the delay is justified",
            style: TextStyle(color: muted, fontSize: 12),
          ),
          value: delayJustified,
          activeThumbColor: Colors.white,
          activeTrackColor: brand,
          inactiveThumbColor: WebTheme.surfaceOf(context),
          inactiveTrackColor: line,
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
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: fieldLabel("Final points")),
              Text(
                "$points / 100",
                style: TextStyle(
                  color: brand,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: brand,
              inactiveTrackColor: WebTheme.brandSoftOf(context),
              thumbColor: brand,
              overlayColor: brand.withValues(alpha: 0.12),
              valueIndicatorColor: brand,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Slider(
              value: points.clamp(0, 100).toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: "$points",
              onChanged: isReviewed
                  ? null
                  : (value) => setState(() => points = value.toInt()),
            ),
          ),
          fieldLabel("Reason"),
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
        fieldLabel("Comment"),
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
            text: isReviewed ? "Already submitted" : "Submit review",
            color: brand,
            txtcolor: Colors.white,
            onPressed: isReviewed ? null : submitReview,
          ),
        ),
      ],
    );
    if (!widget.framed) return form;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.card(context, radius: 16),
      child: form,
    );
  }
}
