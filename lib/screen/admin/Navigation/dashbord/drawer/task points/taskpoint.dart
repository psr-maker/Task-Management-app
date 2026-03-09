import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/admin_service.dart';

class TaskPointDetail extends StatefulWidget {
  final String taskName;
  final String assignedTo;
  final String taskId;

  final int systemPoints;
  final int? finalPoints;
  final bool isReviewed;
  final bool delayJustified;
  final String? delayReason;
  final String? comment;
  final Function(String message, {bool isError})? onShowMessage;
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
        managerPoints: points,
        isDelayJustified: delayJustified,
        delayReason: delayReasonController.text,
        comment: commentController.text,
      );
      widget.onShowMessage?.call(
        "Review submitted successfully",
        isError: false,
      );
    } catch (e) {
      widget.onShowMessage?.call(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.assignedTo, style: Theme.of(context).textTheme.bodySmall),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "System Points",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  "$systemPoints / 100",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Delay Justified",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Switch(
                value: delayJustified,
                activeColor: Colors.green,
                onChanged: isReviewed
                    ? null
                    : (value) {
                        setState(() {
                          delayJustified = value;

                          if (!delayJustified) {
                            points = systemPoints;
                          }
                        });
                      },
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (delayJustified) ...[
            Text(
              "Manager Final Points",
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 10),

            Slider(
              value: points.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: "$points",
              activeColor: Colors.amber,
              onChanged: isReviewed
                  ? null
                  : (value) {
                      setState(() {
                        points = value.toInt();
                      });
                    },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$points / 100",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              "delay reason",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),

            /// Delay Reason
            TextField(
              controller: delayReasonController,
              enabled: !isReviewed,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Enter delay reason...",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
          Text(
            "Manager comment",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),

          /// Manager Comment
          TextField(
            controller: commentController,
            enabled: !isReviewed,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Manager comment...",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// Submit Button
          Center(
            child: AppButton(
              text: isReviewed ? "Already Submitted" : "Submit Review",
              color: Theme.of(context).colorScheme.secondary,
              txtcolor: Theme.of(context).colorScheme.onPrimary,
              onPressed: isReviewed ? null : submitReview,
            ),
          ),
        ],
      ),
    );
  }
}
